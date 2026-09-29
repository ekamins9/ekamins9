--[[ COMBAT SERVER — the shared melee system. One instance runs per equipped
     Tool; a weapon's Script is just:

        require(game.ServerScriptService.Combat.CombatServer)
            .attach(script.Parent, require(script.Parent.Config))

     Config = CombatServer.DEFAULTS overlaid with the weapon's Config module,
     so a weapon only lists what makes it different (animations, attacks,
     reach, tempo, weight). Anything in DEFAULTS can be overridden per weapon.

     RESPONSIBILITIES
       validates client-reported blade hits, resolves block / parry / damage,
       owns attack phases (windup → release → recovery), combos, feints,
       kicks, stamina, cooldowns, turn-cap, and publishes movement inputs
       (SpeedMult_Weapon / ClunkMult_Weapon while equipped, SpeedMult_Swing
       while attacking) for the WalkSpeed governor and camera rig to compose.
       It never writes WalkSpeed itself.

     HIT MODEL
       • The attacker's CLIENT sweeps raycasts along its blade every frame
         during release (CombatClient) and reports the FIRST thing each ray
         touched. Detecting on the swinger's machine is what makes swings
         feel instant; the server never trusts a report blindly.
       • This validates each report: same swing token, inside the release
         window (+ latency grace), target within weapon reach, hit point
         actually on the claimed part, one hit per target per swing.
       • Blocking is PHYSICAL. While a player holds block, a GuardHull box
         welded to their weapon's Hitbox becomes raycast-visible. The
         incoming blade must touch the hull BEFORE any body part or it is not
         a block: from behind, from the off-side, under or over the guard, it
         lands clean. A facing cone is checked on top so a hull that is
         geometrically in the way can't block a hit to the back.
       • Timed parry = a block landed inside PARRY_WINDOW after raising guard:
         attacker is stunned, defender gets a riposte speed buff.

     INJURY (see Injury / Ragdoll modules)
       • Head hits deal HEAD_DAMAGE_MULT × damage. A LETHAL hit to a limb
         severs that limb (DISMEMBER_ON_KILL); with BLEED_OUT_CHANCE the
         victim survives it on BLEED_HP and bleeds out instead of dying.
         A lethal head hit decapitates (DECAPITATE).
       • A lethal STAB (attack kind = "stab") to the HEAD skewers it: the
         head pops off and welds to the attacker's real blade (SKEWER) for
         a few seconds before falling — the rest of the corpse ragdolls
         normally. A lethal stab elsewhere just kills, no extra effect.
       • Blocking with a missing arm, or taking a guard hit at 0 stamina,
         flings the weapon out of the hand (a real pickup on the ground).
       • Losing the right arm drops the weapon; losing the left arm drops it
         only if the weapon is TWO_HANDED. Kicking needs the right leg.
       • Leg hits knock the target into a timed ragdoll.

     DEBUG (ReplicatedStorage.Debug attributes, live): Logs, GuardHull, Hitbox ]]

local Players    = game:GetService("Players")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local DebugFlags  = require(ReplicatedStorage:WaitForChild("DebugFlags"))
local Sounds      = require(ReplicatedStorage:WaitForChild("Sounds"))
local MovementConfig = require(ReplicatedStorage:WaitForChild("MovementConfig"))
local Injury      = require(script.Parent:WaitForChild("Injury"))
local Ragdoll     = require(script.Parent:WaitForChild("Ragdoll"))
-- optional: ServerScriptService.Loadout.Armor (damage reduction on armored limbs)
local Armor do
	local loadout = script.Parent.Parent:FindFirstChild("Loadout")
	local mod = loadout and loadout:FindFirstChild("Armor")
	if mod then Armor = require(mod) end
end

local CombatServer = {}

-- attach() registers a controller per Tool so server code (test dummies,
-- future AI) can drive a weapon: CombatServer.get(tool).cycle() etc.
CombatServer.controllers = {}
function CombatServer.get(tool) return CombatServer.controllers[tool] end

local function pointInBox(p, part, margin)
	local l = part.CFrame:PointToObjectSpace(p)
	local h = part.Size * 0.5 + Vector3.new(margin, margin, margin)
	return math.abs(l.X) <= h.X and math.abs(l.Y) <= h.Y and math.abs(l.Z) <= h.Z
end

--------------------------------------------------------------------
--  SHARED HELPERS (also used by MovementServer for unarmed kicks)
--------------------------------------------------------------------
-- every stamina event (and every hit taken) stamps LastCombatAt, which
-- holds off regen (CharacterSystems) for StaminaRegenDelay on that character
function CombatServer.markCombat(char) char:SetAttribute("LastCombatAt", os.clock()) end
function CombatServer.drainStamina(char, amount, max)
	char:SetAttribute("BlockMeter", math.max(0, (char:GetAttribute("BlockMeter") or max or 100) - amount))
	CombatServer.markCombat(char)
end
function CombatServer.refundStamina(char, amount)
	local max = char:GetAttribute("BlockMax") or 100
	char:SetAttribute("BlockMeter", math.min(max, (char:GetAttribute("BlockMeter") or max) + amount))
end
-- spawn protection (LoadoutServer parents a ForceField for a few seconds)
function CombatServer.isProtected(char)
	return char:FindFirstChildOfClass("ForceField") ~= nil
end
function CombatServer.dropProtection(char)
	local ff = char and char:FindFirstChildOfClass("ForceField")
	if ff then ff:Destroy() end
end
-- victim's client listens for HitTick to flinch the camera; HitDir says which way
function CombatServer.flinch(target, dir)
	target:SetAttribute("HitDir", dir)
	target:SetAttribute("HitTick", (target:GetAttribute("HitTick") or 0) + 1)
end
-- Break whatever someone else was in the middle of. Their own weapon owns
-- their action state, so go through its controller rather than poking
-- attributes — that way their client is told to stop the animation too.
function CombatServer.interrupt(targetChar, reason)
	local tool = targetChar and targetChar:FindFirstChildOfClass("Tool")
	local ctrl = tool and CombatServer.controllers[tool]
	if ctrl then ctrl.interrupt(reason) end
end
-- who hurt whom last, for kill credit (Scoreboard reads these on death)
function CombatServer.credit(target, attacker, weaponName, kind)
	local plr = attacker and Players:GetPlayerFromCharacter(attacker)
	target:SetAttribute("LastHitBy", plr and plr.UserId or 0)
	target:SetAttribute("LastHitByName", attacker and attacker.Name or "")
	target:SetAttribute("LastHitWith", weaponName or "")
	target:SetAttribute("LastHitKind", kind or "")
	target:SetAttribute("LastHitAt", os.clock())
end
function CombatServer.eachTarget(character, fn)
	for _, p in ipairs(Players:GetPlayers()) do
		if p.Character and p.Character ~= character then fn(p.Character) end
	end
	local npcs = workspace:FindFirstChild("NPCs")
	if npcs then
		for _, m in ipairs(npcs:GetChildren()) do
			if m:IsA("Model") then fn(m) end
		end
	end
end

-- Clip lengths, read once per animation id on the server (the timing model
-- must never trust a client's report of how long its own windup is).
local KeyframeSequenceProvider = game:GetService("KeyframeSequenceProvider")
local clipLength = {}   -- [id] = seconds | false (couldn't read)
function CombatServer.clipLength(id)
	if type(id) ~= "string" or id == "" or id == "rbxassetid://0" then return nil end
	local v = clipLength[id]
	if v ~= nil then return v or nil end
	local ok, seq = pcall(KeyframeSequenceProvider.GetKeyframeSequenceAsync, KeyframeSequenceProvider, id)
	if ok and seq then
		local len = 0
		for _, kf in ipairs(seq:GetKeyframes()) do len = math.max(len, kf.Time) end
		clipLength[id] = len > 0 and len or false
		seq:Destroy()
	else
		clipLength[id] = false
		warn("[CombatServer] can't read animation length for", id, "-", tostring(seq), "— using the Config fallback")
	end
	return clipLength[id] or nil
end

-- Is there world geometry between `from` (a character) and `pos`? Character
-- parts, non-solid parts, dropped weapons and debris are looked past.
local function humanoidModelOf(part)
	local m = part:FindFirstAncestorOfClass("Model")
	while m do
		if m:FindFirstChildOfClass("Humanoid") then return m end
		m = m:FindFirstAncestorOfClass("Model")
	end
	return nil
end
local wallParams = RaycastParams.new()
wallParams.FilterType = Enum.RaycastFilterType.Exclude
wallParams.IgnoreWater = true
function CombatServer.throughWall(fromChar, targetModel, pos)
	local head = fromChar:FindFirstChild("Head") or fromChar:FindFirstChild("HumanoidRootPart")
	if not head then return false end
	local origin = head.Position
	local exclude = {fromChar, targetModel}
	local dropped = workspace:FindFirstChild("DroppedWeapons")
	if dropped then table.insert(exclude, dropped) end
	for _ = 1, 4 do
		wallParams.FilterDescendantsInstances = exclude
		local res = workspace:Raycast(origin, pos - origin, wallParams)
		if not res then return false end
		local inst = res.Instance
		if inst.CanCollide and not humanoidModelOf(inst) then return true end
		table.insert(exclude, inst)   -- someone else's limb, a trophy, sparks…: look past it
	end
	return false
end
-- solid world right in front of a character (a kick into a wall is no whiff)
function CombatServer.wallAhead(char, dist)
	local hrp = char:FindFirstChild("HumanoidRootPart")
	if not hrp then return false end
	wallParams.FilterDescendantsInstances = {char}
	local res = workspace:Raycast(hrp.Position, hrp.CFrame.LookVector * (dist or 3), wallParams)
	return res ~= nil and res.Instance.CanCollide and not humanoidModelOf(res.Instance)
end

-- "RightOverhead" -> "Right", "Overhead";  "Stab" -> nil, "Stab"
function CombatServer.sideType(name)
	if type(name) ~= "string" then return nil, nil end
	local side = name:match("^(Left)") or name:match("^(Right)")
	return side, side and name:sub(#side + 1) or name
end

-- does `mine` (in windup) chamber `theirs` (in its swing)? Same type, opposite
-- side; an unsided attack matches either side; stabs chamber stabs regardless.
function CombatServer.chamberMatch(theirs, theirKind, mine, myKind)
	if theirKind == "stab" or myKind == "stab" then return theirKind == "stab" and myKind == "stab" end
	local ts, tt = CombatServer.sideType(theirs)
	local ms, mt = CombatServer.sideType(mine)
	if not tt or not mt or tt ~= mt then return false end
	if ts and ms then return ts ~= ms end
	return true
end

-- The kick's landing: everyone in range and in the cone. hooks = {sfx, tell, dprint}
-- (a weapon supplies its sounds; an unarmed kick uses the defaults)
function CombatServer.resolveKick(character, cfg, hooks)
	local hrp = character and character:FindFirstChild("HumanoidRootPart")
	if not hrp then return false end
	local cosCone = math.cos(math.rad(cfg.KICK_CONE_DEG))
	local now = os.clock()
	local landed, nearest = false, math.huge
	CombatServer.dropProtection(character)
	CombatServer.eachTarget(character, function(m)
		local hum, thrp = m:FindFirstChildOfClass("Humanoid"), m:FindFirstChild("HumanoidRootPart")
		if not (hum and thrp and hum.Health > 0) or CombatServer.isProtected(m) then return end
		local to = thrp.Position - hrp.Position
		to = Vector3.new(to.X, 0, to.Z)
		nearest = math.min(nearest, to.Magnitude)
		if to.Magnitude > cfg.KICK_RANGE or to.Magnitude < 1e-3 then return end
		if hrp.CFrame.LookVector:Dot(to.Unit) < cosCone then return end
		landed = true
		if hooks.sfx then hooks.sfx("KickHit", thrp) end
		Sounds.voice("Hurt", m:FindFirstChild("Head") or thrp)
		CombatServer.flinch(m, to.Unit)
		local wasBlocking = m:GetAttribute("Blocking") == true
		CombatServer.interrupt(m, "kicked")   -- stops their swing and drops their guard, animation included
		if wasBlocking then
			-- breaks a held block AND an open parry window
			m:SetAttribute("Blocking", false)
			m:SetAttribute("ParryUntil", 0)
			m:SetAttribute("StunnedUntil", now + cfg.KICK_STAGGER)
			CombatServer.drainStamina(m, cfg.KICK_BLOCK_DRAIN, cfg.BLOCK_MAX)
			if hooks.dprint then hooks.dprint("KICK staggered", m.Name) end
		else
			CombatServer.credit(m, character, hooks.weaponName or "", "kick")
			hum:TakeDamage(cfg.KICK_DAMAGE)
			CombatServer.markCombat(m)
			if hooks.dprint then hooks.dprint("kick hit", m.Name) end
		end
		if hooks.tell then hooks.tell("HitConfirm", "kick") end
	end)
	if not landed and hooks.dprint then
		hooks.dprint(string.format("kick missed — nearest target %.1f studs (range %.1f, cone ±%d°)",
			nearest, cfg.KICK_RANGE, cfg.KICK_CONE_DEG))
	end
	return landed
end

--------------------------------------------------------------------
--  DEFAULTS — global combat rules. A weapon Config overrides any key.
--------------------------------------------------------------------
CombatServer.DEFAULTS = {
	-- weapon identity (a weapon MUST provide these)
	IDLE_ID     = nil,
	BLOCK_ID    = nil,
	HIT_ID      = nil,   -- optional flinch clip, played (blended) when a hit interrupts us
	ATTACKS     = nil,   -- { <Side><Type> = {anim, kind="stab"|"slash", damage, blockCost, staminaCost, speed?, windup?} }
	                     --   Side = Left|Right, Type = Swing|Stab|Overhead|Underhand. Every attack is sided.
	                     --   `anim` is the SWING only: its first frame is the loaded pose.

	-- TIMING: the windup is a BLEND — the swing clip fades in from wherever the
	-- body is (idle, a block, another windup…) while frozen on its first frame,
	-- over WINDUP seconds; that fade IS the wind-up motion, no clip needed. Then
	-- the clip runs: active = its length. Both, and RECOVERY, divide by
	--     speed × TYPE_SPEED[type] × SPEED_MULT   (× RIPOSTE_SPEED after a parry)
	-- so morph / feint / chamber windows are the real windup at this tempo.
	SPEED_MULT  = 1.0,   -- whole-weapon tempo
	TYPE_SPEED  = {Swing = 1.0, Stab = 1.0, Overhead = 1.0, Underhand = 1.0},   -- per attack type
	WINDUP      = 0.15,  -- seconds (at speed 1) of blend into the loaded pose; an attack may set its own `windup`
	RECOVERY    = 0.15,  -- seconds (at speed 1) of hold after the swing clip ends
	DEFAULT_ACTIVE = 0.3,-- swing-clip length fallback when the server can't read the clip
	INPUT_GRACE = 0.08,  -- a morph / feint that arrives this long after the windup ended still
	                     --    counts (client→server latency), as long as the blade hit nothing yet
	REACH       = 8.0,   -- studs from attacker root to a valid hit point
	TWO_HANDED  = false, -- needs both arms to wield (losing the left arm drops it too)
	SpeedMult   = 1.0,   -- weight: WalkSpeed multiplier while equipped (published as SpeedMult_Weapon)
	ClunkMult   = 1.0,   -- weight: footstep clunk multiplier while equipped (published as ClunkMult_Weapon)
	SWING_SLOW  = 0.55,  -- WalkSpeed multiplier while attacking (published as SpeedMult_Swing)

	-- Sound slots. Every weapon uses these unless its Config has a SOUNDS table
	-- overriding a key (never with "rbxassetid://0" — that silences the slot).
	SOUNDS = {
		Equip   = "rbxassetid://80636916996187",
		Swing   = "rbxassetid://135315310485417",
		Hit     = "rbxassetid://135119591308242",
		Kick    = "rbxassetid://135708425496510",
		KickHit = "rbxassetid://105287234173928",
		Block   = "rbxassetid://112773782841691",
		Parry   = "rbxassetid://5763723309",
	},

	-- hit validation / lethality
	REACH_TOLERANCE  = 3.0,   -- latency slack on top of REACH
	HIT_GRACE        = 0.30,  -- accept reports this long after release ends (round-trip lag)
	MIN_PHASE        = 0.05,
	HEAD_DAMAGE_MULT = 2.0,   -- head hits hurt this much more (no longer an automatic kill)
	LEG_DAMAGE_MULT  = 0.85,  -- …and legs a little less. An attack may instead give
	                          --    damage = {head=, body=, legs=} for exact per-region numbers.
	FIT_ANIMS        = true,  -- the swing clip is stretched to the active phase (so a riposte or
	                          --    a slow weapon re-times the picture with the rules)
	FLINCH_ONLY_WINDUP = true,-- a clean hit only interrupts a target still in WINDUP; a swing
	                          --    already in release finishes (trades are a real choice)
	-- STAMINA LEDGER (Mordhau-style): the windup always costs staminaCost; every
	-- enemy the swing hits refunds HIT_REFUND (cut through three = three refunds);
	-- a swing that touches nothing costs MISS_COST_MULT × staminaCost extra; a
	-- swing that hits a wall / the floor stops there with no penalty and no refund.
	MISS_COST_MULT   = 0.75,
	HIT_REFUND       = 6,
	WALL_CHECK       = true,  -- reject hits whose line from you to the hit point passes through geometry,
	WALL_RECOVERY    = 0.35,  --    and a blade that hits a wall stops (this long before you can act)
	KICK_REFUND      = 8,     -- a kick that lands gives this back; one that misses costs KICK_MISS_COST;
	KICK_MISS_COST   = 8,     --    kicking a wall is neither
	MORPH_COST       = 10,    -- switch attack mid-windup (right swing -> stab…): stamina
	MORPHS_PER_SWING = 1,
	MORPH_NO_MIRROR  = true,  -- can't morph into the mirror of the same attack (RightSwing -> LeftSwing):
	                          --    the blade would have to cross the whole body
	MORPH_FORBID     = {Overhead = "Underhand", Underhand = "Overhead"},   -- type pairs too far apart to morph between
	MORPH_CUTOFF     = 1.0,   -- no morph past this fraction of the windup (1 = the whole windup)
	MORPH_WINDUP     = 1.0,   -- a morph plays this × the new attack's FULL windup, at normal speed
	                          --    (1 = a complete second windup; the morph's cost is the time)
	BLEND            = 0.08,  -- seconds (at speed 1) to cross-fade clips that aren't a windup: a combo's
	                          --    swing→swing, a swing ending, a feint back to idle. Divided by the speed.
	RECOIL           = 0.18,  -- seconds (at speed 1) a blocked / parried / chambered swing eases back to idle
	CHAMBER          = true,  -- be in WINDUP of the mirror of their attack while theirs is in
	                          --    its swing (same type, opposite side: their RightOverhead vs
	                          --    your LeftOverhead; any stab vs any stab), facing them, and
	                          --    their swing dies while yours goes on
	CHAMBER_WINDOW   = 2.0,   --    your windup must have started within this of the contact (a
	                          --    cap; in practice "you are in windup" is the rule)
	CHAMBER_STUN     = 0.5,   --    the attacker is stunned this long
	CHAMBER_COST_MULT= 0.15,  --    you pay this × the attack's blockCost
	CHAMBER_RELEASE  = 0.2,   --    your windup is cut to this — long enough to morph out of it
	CHAMBER_MORPH_FREE = true,--    a chamber resets your morph count: you can morph the chamber
	FEINT_ANYTIME    = true,  -- the feint key cancels a windup (no block needed)
	DECAPITATE       = true,  -- lethal slash to the head takes it off (death cam rides it)
	DISMEMBER_ON_KILL= true,  -- lethal slash to an arm/leg takes that limb off
	BLEED_OUT_CHANCE = 0.35,  -- …and this often the victim survives it, bleeding, instead of dying
	IMPALE           = true,  -- lethal face stab skewers the head on the attacker's real blade
	STAB_HEAD_EXECUTE= false, -- true = a stab to the face always kills. Off: it's a normal
	                          --    HEAD_DAMAGE_MULT hit, and only a LETHAL one skewers.
	HEAD_THROW_SPEED = 60,    -- a skewered head stays on the blade until your next swing, then
	HEAD_THROW_DAMAGE= 15,    --    flies off forward as a projectile: light damage + a stun on
	HEAD_THROW_STUN  = 1.0,   --    whoever it hits (can finish someone low)
	DISARM_STUN      = 0.60,  -- stagger after your weapon is knocked away
	SECONDARY        = false, -- true = this weapon may be carried as the secondary (see Pickup)

	-- guard / parry / stamina (the BlockMeter attribute IS the stamina bar)
	BLOCK_MAX         = 100,
	BLOCK_REGEN       = 15,    -- per second…
	STAMINA_REGEN_DELAY = 2.5, -- …but only this long after the last combat event (attack, feint,
	                           --    kick, block, parry, taking a hit), never while blocking or mid-swing
	BLOCK_BREAK_STUN  = 2.50,
	BLOCK_CONE_DEG    = 60,    -- must face the attacker within this half-angle to block (flank them!)
	BLOCK_GRACE       = 0.15,  -- a just-released block still counts for this long (lag)
	PARRY_WINDOW      = 0.35,
	BLOCK_COOLDOWN    = 0.50,  -- after lowering your guard, how long before you can raise it again
	PARRY_RETRY       = 0.90,  -- …and how long it must have been DOWN to earn a fresh parry window.
	                           --    Keep this above BLOCK_COOLDOWN or every re-guard is a free parry.
	PARRY_COST_MULT   = 0,     -- a timed parry costs this fraction of the attack's blockCost (0: parries are free;
	                           --    holding block still pays the full blockCost — the turtle tax)
	PARRY_REFUND      = 6,     -- …and REFUNDS this × your streak: parries within PARRY_STREAK_WINDOW of
	PARRY_STREAK_WINDOW = 2.0, --    each other stack (1vX: parry, parry, parry = 6, 12, 18…)
	PARRY_STREAK_MAX  = 5,
	PARRY_CHAIN_WINDOW= 1.5,   -- after a SUCCESSFUL parry you can re-guard at once with a fresh parry
	                           --    window (no BLOCK_COOLDOWN, no PARRY_RETRY) for this long; a missed
	                           --    parry keeps the normal cooldown
	PARRY_PUNISH_STUN = 1.50,
	RIPOSTE_DURATION  = 3.00,  -- after a parry, your attacks' WINDUP is RIPOSTE_SPEED × faster (the swing
	RIPOSTE_SPEED     = 1.6,   --    itself plays at normal speed — there's still a windup, just a quick one)
	FEINT_COST        = 12,
	FEINT_RECOVERY    = 0.25,

	-- kick: short, unblockable, staggers a held block. Leg animation is
	-- procedural in the camera rig (LocalKickAt / LocalKickRise attributes).
	KICK_RANGE       = 7.0,   -- sword fights happen at 6-8 studs; a kick must reach that
	KICK_CONE_DEG    = 60,
	KICK_WINDUP      = 0.22,
	KICK_RECOVERY    = 0.55,
	KICK_COOLDOWN    = 2.5,   -- minimum time between kicks
	KICK_DAMAGE      = 5,
	KICK_STAGGER     = 1.2,   -- a kicked guard (block OR parry window) drops and the victim is stunned this long
	KICK_COST        = 10,
	KICK_BLOCK_DRAIN = 15,
	KICK_MISS_EXTRA  = 0.45,  -- a kick that hits nobody recovers this much longer (punishable)

	-- geometry
	ANIMATED_GRIP  = true,   -- swap Roblox's RightGrip Weld for a "ToolGrip" Motor6D so animations can move the weapon
	HITBOX_NAME    = "Hitbox",
	GUARD_WIDTH    = 1.6,   -- hull cross-section around the blade while blocking — snug to the weapon
	GUARD_PAD      = 0.3,   -- extra hull length past each end of the blade
	GUARD_MARGIN   = 0.6,   -- server: blade or hit point this close inside a raised hull still counts as blocked
	TURN_CAP_EXTRA = 0.10,
}

--------------------------------------------------------------------
function CombatServer.attach(Tool, weaponConfig)
	local cfg = {}
	for k, v in pairs(CombatServer.DEFAULTS) do cfg[k] = v end
	for k, v in pairs(weaponConfig or {}) do cfg[k] = v end
	cfg.SOUNDS = {}
	for k, v in pairs(CombatServer.DEFAULTS.SOUNDS) do cfg.SOUNDS[k] = v end
	for k, v in pairs((weaponConfig and weaponConfig.SOUNDS) or {}) do cfg.SOUNDS[k] = v end

	local TAG = Tool.Name .. "/Server"
	local weaponName = cfg.Name or Tool.Name   -- kill feed
	local function dprint(...) DebugFlags.log(TAG, ...) end

	if not cfg.ATTACKS then
		warn("[" .. TAG .. "] Config needs ATTACKS")
		return
	end
	-- an attack with no swing clip yet (rbxassetid://0) can't be used
	local function usable(name)
		local a = cfg.ATTACKS[name]
		return a ~= nil and type(a.anim) == "string" and a.anim ~= "" and a.anim ~= "rbxassetid://0"
	end
	task.spawn(function()
		for name, a in pairs(cfg.ATTACKS) do
			if usable(name) then CombatServer.clipLength(a.anim) end
		end
	end)

	Tool.CanBeDropped = false   -- Backspace would dump it in workspace with no pickup prompt

	local remote = Tool:FindFirstChild("CombatRemote")
	if not remote then
		remote = Instance.new("RemoteEvent")
		remote.Name = "CombatRemote"
		remote.Parent = Tool
	end

	local character, humanoid, player
	local blockConn
	local limbConns = {}
	local conns = {}
	local state = {
		token = 0, phase = "idle",          -- idle | windup | release | recovery | kick
		attack = nil, attackName = nil, alreadyHit = {}, queued = nil,
		windupStart = 0, windupEnd = 0, releaseEnd = 0, nextActionTime = 0, nextKickTime = 0, nextBlockTime = 0,
		cycleIndex = 0, lastBlockStart = -1e9, guardStart = 0,
		morphs = 0, landed = false,         -- per swing: morphs used; touched anything (no miss penalty)
		chambered = false,                  -- this windup just chambered someone (morph allowed past the cutoff)
	}

	----------------------------------------------------------------
	--  HITBOX + GUARD HULL
	----------------------------------------------------------------
	local hitboxes, hulls, guardOn = {}, {}, false
	local origTransparency = {}
	for _, d in ipairs(Tool:GetDescendants()) do
		if d:IsA("BasePart") and d.Name == cfg.HITBOX_NAME then
			table.insert(hitboxes, d)
			origTransparency[d] = d.Transparency
		end
	end
	dprint("found", #hitboxes, cfg.HITBOX_NAME .. " part(s)")
	if #hitboxes == 0 then
		warn("[" .. TAG .. "] No part named '" .. cfg.HITBOX_NAME .. "' in the Tool — hits and blocks won't work.")
	end

	local function makeHull(box)
		local s = box.Size
		local size
		if s.X >= s.Y and s.X >= s.Z then size = Vector3.new(s.X + cfg.GUARD_PAD*2, cfg.GUARD_WIDTH, cfg.GUARD_WIDTH)
		elseif s.Y >= s.Z then          size = Vector3.new(cfg.GUARD_WIDTH, s.Y + cfg.GUARD_PAD*2, cfg.GUARD_WIDTH)
		else                            size = Vector3.new(cfg.GUARD_WIDTH, cfg.GUARD_WIDTH, s.Z + cfg.GUARD_PAD*2) end
		local hull = Instance.new("Part")
		hull.Name = "GuardHull"
		hull.Size = size
		hull.CFrame = box.CFrame
		hull.Transparency = 1
		hull.Color = Color3.fromRGB(80, 160, 255)
		hull.CanCollide, hull.CanTouch, hull.CanQuery = false, false, false
		hull.Massless = true
		local weld = Instance.new("WeldConstraint")
		weld.Part0, weld.Part1 = box, hull
		weld.Parent = hull
		hull.Parent = box
		return hull
	end
	for _, box in ipairs(hitboxes) do
		table.insert(hulls, box:FindFirstChild("GuardHull") or makeHull(box))
	end
	-- other players' blade rays pass through our weapon geometry and only ever
	-- stop on the GuardHull, and only while it's raised
	for _, d in ipairs(Tool:GetDescendants()) do
		if d:IsA("BasePart") and d.Name ~= "GuardHull" then d.CanQuery = false end
	end

	local function updateHullLook()
		local show = DebugFlags.get("GuardHull")
		for _, h in ipairs(hulls) do
			h.Transparency = show and (guardOn and 0.5 or 0.85) or 1
		end
	end
	local function setGuard(on)
		guardOn = on
		for _, h in ipairs(hulls) do h.CanQuery = on end
		updateHullLook()
	end

	-- sample points along each Hitbox's long axis (server-side view of our blade)
	local BLADE_SAMPLES = 6
	local blades = {}
	for _, box in ipairs(hitboxes) do
		local s = box.Size
		local axis, len
		if s.X >= s.Y and s.X >= s.Z then axis, len = Vector3.xAxis, s.X
		elseif s.Y >= s.Z then          axis, len = Vector3.yAxis, s.Y
		else                            axis, len = Vector3.zAxis, s.Z end
		local offsets = {}
		for i = 0, BLADE_SAMPLES - 1 do
			offsets[#offsets + 1] = axis * (len * (i / (BLADE_SAMPLES - 1) - 0.5))
		end
		table.insert(blades, {part = box, offsets = offsets})
	end
	local function bladeInside(hull, margin)
		for _, b in ipairs(blades) do
			for _, off in ipairs(b.offsets) do
				if pointInBox(b.part.CFrame:PointToWorldSpace(off), hull, margin) then return true end
			end
		end
		return false
	end
	table.insert(conns, DebugFlags.onChanged("GuardHull", updateHullLook))
	table.insert(conns, DebugFlags.onChanged("Hitbox", function(show)
		for _, b in ipairs(hitboxes) do
			b.Transparency = show and 0.5 or origTransparency[b]
		end
	end))

	----------------------------------------------------------------
	--  HELPERS
	----------------------------------------------------------------
	local function attr(n)      return character and character:GetAttribute(n) end
	local function setAttr(n,v) if character then character:SetAttribute(n,v) end end
	local function isStunned()  return (attr("StunnedUntil") or 0) > os.clock() end
	local function stamina()    return attr("BlockMeter") or cfg.BLOCK_MAX end
	local markCombat = CombatServer.markCombat
	local function drainStamina(char, amount) CombatServer.drainStamina(char, amount, cfg.BLOCK_MAX) end
	local function spend(n)     if character then drainStamina(character, n) end end
	local npcTell   -- server-side stand-in for the client when no player holds the tool; set below
	local function tell(...)
		if player then remote:FireClient(player, ...)
		elseif npcTell then npcTell(...) end
	end
	-- mid-attack / mid-kick: slower, and "Acting" tells other systems
	-- (dodge, sprint, stamina regen) that we're committed to something
	local function setSwinging(on)
		setAttr("SpeedMult_Swing", on and cfg.SWING_SLOW or nil)
		setAttr("Acting", on or nil)
	end
	local function handle()     return Tool:FindFirstChild("Handle") end
	local function sfx(slot, at, opts) Sounds.play(cfg.SOUNDS[slot], at or handle(), opts) end

	-- stunned, ragdolled, or dead: no actions
	local function isIncapacitated()
		if not character then return true end
		if isStunned() or Ragdoll.isRagdolled(character) then return true end
		local hum = character:FindFirstChildOfClass("Humanoid")
		return not hum or hum.Health <= 0
	end

	-- flat direction from us to a target's root, for flinging things and flinches
	local function dirTo(target)
		local myHRP, tHRP = character and character:FindFirstChild("HumanoidRootPart"), target:FindFirstChild("HumanoidRootPart")
		if not (myHRP and tHRP) then return Vector3.new(0, 0, -1) end
		local d = tHRP.Position - myHRP.Position
		d = Vector3.new(d.X, 0, d.Z)
		return d.Magnitude > 1e-3 and d.Unit or Vector3.new(0, 0, -1)
	end

	-- world direction of our blade's long axis, pointed toward the target
	local function bladeDirTo(target)
		local toward = dirTo(target)
		local box = hitboxes[1]
		if not box then return toward end
		local s = box.Size
		local axis = (s.X >= s.Y and s.X >= s.Z) and Vector3.xAxis or (s.Y >= s.Z and Vector3.yAxis or Vector3.zAxis)
		local v = box.CFrame:VectorToWorldSpace(axis)
		if v:Dot(toward) < 0 then v = -v end
		return v
	end

	local interrupt = CombatServer.interrupt
	local flinch    = CombatServer.flinch

	-- Roblox attaches tools with a Weld named RightGrip, which animations can't
	-- drive. Replace it with a Motor6D of the same pose so weapon animations work.
	local function installToolGrip(char)
		local arm = char:FindFirstChild("Right Arm")
		if not arm then return end
		local grip = arm:WaitForChild("RightGrip", 2)
		if not grip or character ~= char or not grip.Parent then return end
		local existing = arm:FindFirstChild("ToolGrip")
		if existing then existing:Destroy() end
		local motor = Instance.new("Motor6D")
		motor.Name  = "ToolGrip"
		motor.Part0 = grip.Part0
		motor.Part1 = grip.Part1
		motor.C0    = grip.C0
		motor.C1    = grip.C1
		motor.Parent = arm
		grip:Destroy()
		dprint("ToolGrip installed")
	end

	local function removeToolGrip(char)
		local arm = char and char:FindFirstChild("Right Arm")
		local motor = arm and arm:FindFirstChild("ToolGrip")
		if motor then motor:Destroy() end
	end

	local function knockAwayWeapon(target, dir, reason)
		if Injury.disarm(target, dir) then
			target:SetAttribute("StunnedUntil", os.clock() + cfg.DISARM_STUN)
			dprint("DISARMED", target.Name, "-", reason)
			return true
		end
		return false
	end

	local function cancelSwing(reason)
		state.token += 1
		state.phase, state.attack, state.attackName, state.queued = "idle", nil, nil, nil
		setSwinging(false)
		tell("Cancel", reason)
		dprint("swing cancelled:", reason)
	end

	local function regionOf(part, model)
		if part.Parent == model then
			if part.Name == "Head" then return "head" end
			local n = part.Name:lower()
			if n:find("leg") or n:find("foot") then return "legs" end
			return "body"
		end
		if part:FindFirstAncestorOfClass("Accessory") then
			local w = part:FindFirstChildOfClass("Weld")
			if w and ((w.Part1 and w.Part1.Name == "Head") or (w.Part0 and w.Part0.Name == "Head")) then
				return "head"
			end
		end
		return "body"
	end

	----------------------------------------------------------------
	--  HIT RESOLUTION
	----------------------------------------------------------------
	local function resolveHit(hum, target, part, hitPos, claimedGuard)
		local info = state.attack
		local now  = os.clock()
		local myHRP     = character:FindFirstChild("HumanoidRootPart")
		local targetHRP = target:FindFirstChild("HumanoidRootPart")
		if CombatServer.isProtected(target) then dprint(target.Name, "is spawn-protected"); return end
		state.landed = true   -- touched something: no miss penalty (a block still counts)

		local guardUp = target:GetAttribute("Blocking") == true
			or (now - (target:GetAttribute("BlockStoppedAt") or -1e9)) < cfg.BLOCK_GRACE
		local facing = true
		if myHRP and targetHRP then
			local to = myHRP.Position - targetHRP.Position
			to = Vector3.new(to.X, 0, to.Z)
			if to.Magnitude > 1e-3 then
				facing = targetHRP.CFrame.LookVector:Dot(to.Unit) >= math.cos(math.rad(cfg.BLOCK_CONE_DEG))
			end
		end

		local dir = dirTo(target)

		-- safety net, independent of what the client saw first: if the hit point
		-- OR any point of our blade is inside a raised, facing guard hull right
		-- now, the guard caught it. "Sword inside the box = blocked."
		if not claimedGuard and guardUp and facing then
			local tool = target:FindFirstChildOfClass("Tool")
			if tool then
				for _, h in ipairs(tool:GetDescendants()) do
					if h.Name == "GuardHull" and h:IsA("BasePart")
						and (pointInBox(hitPos, h, cfg.GUARD_MARGIN) or bladeInside(h, cfg.GUARD_MARGIN)) then
						claimedGuard = true
						dprint("blade inside", target.Name, "guard -> block")
						break
					end
				end
			end
		end

		-- a CONFIRMED touch of the guard hull (from the sweep itself, not the
		-- inferred fallback above) is an absolute block: no damage, full stop,
		-- regardless of facing — the weapon physically caught it. Facing only
		-- gates the fallback, which is inferring contact rather than reporting one.
		if claimedGuard and guardUp then
			-- a guard with no stamina behind it, or one arm, can't hold: the weapon flies
			local meter = target:GetAttribute("BlockMeter") or cfg.BLOCK_MAX
			markCombat(character)
			-- what the defender's HUD says happened (GuardTick makes it pop)
			local function guardText(text)
				target:SetAttribute("GuardText", text)
				target:SetAttribute("GuardTick", (target:GetAttribute("GuardTick") or 0) + 1)
			end
			if meter <= 0 or not Injury.canBlock(target) then
				markCombat(target)
				Injury.sparks(hitPos, 1)
				knockAwayWeapon(target, dir, meter <= 0 and "guard hit at 0 stamina" or "guard with a missing arm")
				sfx("Block", part)
				guardText("DISARMED")
				tell("Blocked", true)
				return
			end
			if (target:GetAttribute("ParryUntil") or 0) > now then
				-- PARRY: attacker punished, defender gets a riposte; costs a fraction of a block
				setAttr("StunnedUntil", now + cfg.PARRY_PUNISH_STUN)
				target:SetAttribute("FastUntil", now + cfg.RIPOSTE_DURATION)
				target:SetAttribute("ParryTick", (target:GetAttribute("ParryTick") or 0) + 1)
				-- streak: parries close together pay out more (1vX)
				local streak = (now - (target:GetAttribute("LastParryAt") or -1e9) <= cfg.PARRY_STREAK_WINDOW)
					and math.min((target:GetAttribute("ParryStreak") or 0) + 1, cfg.PARRY_STREAK_MAX) or 1
				target:SetAttribute("ParryStreak", streak)
				target:SetAttribute("LastParryAt", now)
				drainStamina(target, (info.blockCost or 0) * cfg.PARRY_COST_MULT)
				CombatServer.refundStamina(target, cfg.PARRY_REFUND * streak)
				dprint("parry streak", streak, "+" .. cfg.PARRY_REFUND * streak, "stamina to", target.Name)
				guardText(string.format("PARRY%s  +%d", streak > 1 and ("  ×" .. streak) or "", cfg.PARRY_REFUND * streak))
				Injury.sparks(hitPos, 2)   -- big, white: unmistakably a parry
				cancelSwing("parried")
				sfx("Parry", part)
				Sounds.voice("Parry", target:FindFirstChild("Head"))
				tell("Parried")
				dprint("PARRIED by", target.Name)
			else
				-- BLOCK: drains defender stamina by the attack's blockCost; empty = guard broken
				drainStamina(target, info.blockCost)
				local m = target:GetAttribute("BlockMeter") or 0
				sfx("Block", part)
				Injury.sparks(hitPos, 1)
				-- the blade stops dead on a guard, same as a parry — the parry's
				-- extra punish is the attacker's stun and the defender's riposte
				cancelSwing("blocked")
				if m <= 0 then
					target:SetAttribute("Blocking", false)
					-- run dry holding the guard and the weapon is jarred out of your hands
					knockAwayWeapon(target, dir, "guard broken at 0 stamina")
					-- set last: knockAwayWeapon's shorter DISARM_STUN must not cut this short
					target:SetAttribute("StunnedUntil", now + cfg.BLOCK_BREAK_STUN)
					guardText("GUARD BROKEN")
					tell("Blocked", true)
					dprint("BLOCK BROKEN on", target.Name)
				else
					guardText(string.format("BLOCK  −%d", info.blockCost or 0))
					tell("Blocked", false)
					dprint("blocked by", target.Name, "meter", math.floor(m))
				end
			end
			return
		end

		-- CHAMBER: they answered with the same KIND of attack (stab vs strike),
		-- facing us, and started it inside the window — our swing is caught on
		-- theirs and dies; theirs releases at once
		if cfg.CHAMBER and facing then
			local ttool = target:FindFirstChildOfClass("Tool")
			local tctrl = ttool and CombatServer.controllers[ttool]
			local snap  = tctrl and tctrl.snapshot and tctrl.snapshot()
			if snap and snap.phase == "windup"
				and CombatServer.chamberMatch(state.attackName, info.kind, snap.name, snap.kind)
				and now - snap.windupStart <= cfg.CHAMBER_WINDOW then
				markCombat(character)
				markCombat(target)
				setAttr("StunnedUntil", now + cfg.CHAMBER_STUN)
				drainStamina(target, (info.blockCost or 0) * cfg.CHAMBER_COST_MULT)
				target:SetAttribute("ParryTick", (target:GetAttribute("ParryTick") or 0) + 1)
				target:SetAttribute("GuardText", "CHAMBER")
				target:SetAttribute("GuardTick", (target:GetAttribute("GuardTick") or 0) + 1)
				cancelSwing("chambered")
				Injury.sparks(hitPos, 2)
				sfx("Parry", part)
				Sounds.voice("Parry", target:FindFirstChild("Head"))
				tell("Chambered")
				tctrl.chambered()
				dprint("CHAMBERED by", target.Name, "(" .. tostring(snap.name) .. ")")
				return
			end
		end

		-- CLEAN HIT: a lowered guard, a raised guard the blade got past, or from behind
		local region = claimedGuard and "body" or regionOf(part, target)
		if claimedGuard then dprint("guard touched but invalid (up:", guardUp, "facing:", facing, ") -> body hit") end
		sfx("Hit", part)
		Injury.bloodBurst(part)
		flinch(target, dir)
		-- a clean hit breaks whatever they were doing, so trades are rarer
		interrupt(target, "hit")
		markCombat(character)
		markCombat(target)
		CombatServer.credit(target, character, weaponName, info.kind == "stab" and (region == "head" and "facestab" or "stab") or (region == "head" and "headslash" or "slash"))

		-- damage: a number (× HEAD/LEG mult) or {head=, body=, legs=}
		local dmg
		if type(info.damage) == "table" then
			dmg = info.damage[region] or info.damage.body or info.damage.torso or 0
		else
			dmg = (info.damage or 0) * (region == "head" and cfg.HEAD_DAMAGE_MULT or (region == "legs" and cfg.LEG_DAMAGE_MULT or 1))
		end
		CombatServer.refundStamina(character, cfg.HIT_REFUND)
		Sounds.voice("Hurt", target:FindFirstChild("Head") or part)
		-- armor: the set's Protection applies only on limbs it actually covers.
		-- Hits on accessories/clothing count as the limb they're on.
		if Armor then
			local limbName = (part.Parent == target and Injury.LIMBS[part.Name]) and part.Name
				or (region == "head" and "Head") or "Torso"
			local prot = Armor.protectionAt(target, limbName)
			if prot > 0 then
				dmg = dmg * (1 - math.clamp(prot, 0, 0.95))
				dprint("armor on", limbName, "absorbed", math.floor(prot * 100) .. "%")
			end
		end
		local isStab = info.kind == "stab"
		-- a stab through the face is a finisher, not a damage roll
		if isStab and region == "head" and cfg.STAB_HEAD_EXECUTE then
			dmg = math.max(dmg, hum.Health)
		end
		local lethal = hum.Health - dmg <= 0
		-- the limb we actually struck (only real rig parts, not accessories)
		local limb = (part.Parent == target and Injury.LIMBS[part.Name]) and part.Name or nil

		if lethal then
			if isStab and region == "head" and cfg.IMPALE then
				-- kill first so the ragdoll captures a complete rig, then hide the
				-- real head and hang a clone off the blade (nothing of theirs welds
				-- into our assembly, so the corpse still flops normally)
				hum:TakeDamage(dmg)
				Injury.skewerHead(target, hitboxes[1], hitPos, bladeDirTo(target))
				dprint("SKEWERED", target.Name, "on the blade")
			elseif isStab then
				hum:TakeDamage(dmg)
				dprint("KILLED", target.Name, "with a stab", region)
			elseif limb == "Head" and cfg.DECAPITATE and Injury.hasLimb(target, "Head") then
				Injury.dismember(target, "Head", dir, true)
				dprint("DECAPITATED", target.Name)
			elseif limb and limb ~= "Head" and cfg.DISMEMBER_ON_KILL and Injury.hasLimb(target, limb) then
				local survives = target:GetAttribute("Bleeding") ~= true and math.random() < cfg.BLEED_OUT_CHANCE
				Injury.dismember(target, limb, dir, not survives)
				dprint(survives and "DISMEMBERED (bleeding out)" or "KILLED, severed", target.Name, limb)
			else
				hum:TakeDamage(dmg)
				dprint("KILLED", target.Name, region)
			end
			tell("HitConfirm", region)
			return
		end

		hum:TakeDamage(dmg)
		dprint("hit", target.Name, region, dmg)
		tell("HitConfirm", region)
	end

	local function onHitReport(token, model, part, hitPos, claimedGuard)
		local now = os.clock()
		if not character or token ~= state.token or not state.attack then dprint("hit rejected: stale swing"); return end
		if now < state.windupEnd - 0.05 or now > state.releaseEnd + cfg.HIT_GRACE then dprint("hit rejected: outside release"); return end
		if typeof(model) ~= "Instance" or not model:IsA("Model") or model == character then return end
		if typeof(part) ~= "Instance" or not part:IsA("BasePart") or not part:IsDescendantOf(model) then return end
		if typeof(hitPos) ~= "Vector3" then return end
		local hum = model:FindFirstChildOfClass("Humanoid")
		if not hum or hum.Health <= 0 or state.alreadyHit[hum] then return end
		local hrp = character:FindFirstChild("HumanoidRootPart")
		if not hrp then return end
		if (hrp.Position - hitPos).Magnitude > cfg.REACH + cfg.REACH_TOLERANCE then dprint("hit rejected: out of reach"); return end
		if (part.Position - hitPos).Magnitude > part.Size.Magnitude * 0.5 + 2 then dprint("hit rejected: point not on part"); return end
		if cfg.WALL_CHECK and CombatServer.throughWall(character, model, hitPos) then dprint("hit rejected: through a wall"); return end
		state.alreadyHit[hum] = true
		resolveHit(hum, model, part, hitPos, claimedGuard == true)
	end

	-- the client's blade met the world (a wall, the floor): the swing stops
	-- there — no whiff penalty, no refund, a short recovery
	local function onWall(token, pos)
		if not character or token ~= state.token or state.phase ~= "release" then return end
		if typeof(pos) ~= "Vector3" then return end
		local hrp = character:FindFirstChild("HumanoidRootPart")
		if not hrp or (hrp.Position - pos).Magnitude > cfg.REACH + cfg.REACH_TOLERANCE then return end
		state.landed = true
		Injury.sparks(pos)
		sfx("Block", handle(), {Volume = 0.7})
		cancelSwing("wall")
		state.nextActionTime = os.clock() + cfg.WALL_RECOVERY
		dprint("blade hit the world")
	end

	----------------------------------------------------------------
	--  NPC SUPPORT — with no player behind the tool (test dummies, AI),
	--  animations play server-side and the blade sweep runs here, using
	--  the same probe + swept-ray logic as CombatClient.
	----------------------------------------------------------------
	local npc = {tracks = {}, idle = nil, block = nil, current = nil, sweep = nil}
	local NPC_PROBE = Vector3.new(0.2, 0.2, 0.2)
	local npcRay = RaycastParams.new()
	npcRay.FilterType = Enum.RaycastFilterType.Exclude
	local npcOverlap = OverlapParams.new()
	npcOverlap.FilterType = Enum.RaycastFilterType.Exclude
	npcOverlap.MaxParts = 8

	local function npcTrack(id, priority, looped)
		if type(id) ~= "string" or id == "" or id == "rbxassetid://0" or not character then return nil end
		local hum = character:FindFirstChildOfClass("Humanoid")
		if not hum then return nil end
		local animator = hum:FindFirstChildOfClass("Animator")
		if not animator then
			animator = Instance.new("Animator")
			animator.Parent = hum
		end
		local anim = Instance.new("Animation")
		anim.AnimationId = id
		local ok, t = pcall(animator.LoadAnimation, animator, anim)
		if not ok then return nil end
		t.Priority, t.Looped = priority, looped or false
		return t
	end

	local function npcStopAll()
		npc.sweep = nil
		if npc.current then npc.current:Stop(); npc.current = nil end
		if npc.idle then npc.idle:Stop() end
		if npc.block then npc.block:Stop() end
		for _, t in pairs(npc.tracks) do t:Stop() end
	end

	local function humanoidModelOf(part)
		local m = part:FindFirstAncestorOfClass("Model")
		while m do
			if m:FindFirstChildOfClass("Humanoid") then return m end
			m = m:FindFirstAncestorOfClass("Model")
		end
		return nil
	end

	local function npcReport(sw, hum, e)
		sw.reported[hum] = true
		onHitReport(sw.token, e.model, e.part, e.pos, e.guard)
	end

	local function npcSweepStep()
		local sw = npc.sweep
		if not sw or not character then return end
		if os.clock() > sw.endsAt then
			for hum, p in pairs(sw.pending) do npcReport(sw, hum, p.e) end
			npc.sweep = nil
			return
		end
		local frameHits = {}
		-- priority per target: guard > surface entry (ray) > already-inside (probe)
		local function note(part, pos, viaRay)
			local model = humanoidModelOf(part)
			if not model or model == character then return end
			local hum = model:FindFirstChildOfClass("Humanoid")
			if not hum or hum.Health <= 0 or sw.reported[hum] then return end
			local isGuard = part.Name == "GuardHull"
			local e = frameHits[hum]
			if not e then
				frameHits[hum] = {model = model, part = part, pos = pos, guard = isGuard, ray = viaRay}
			elseif (isGuard and not e.guard) or (not e.guard and viaRay and not e.ray) then
				e.part, e.pos, e.guard, e.ray = part, pos, isGuard, viaRay
			end
		end
		for _, b in ipairs(blades) do
			local pts = sw.last[b]
			for i, off in ipairs(b.offsets) do
				local p, prev = b.part.CFrame:PointToWorldSpace(off), pts[i]
				for _, part in ipairs(workspace:GetPartBoundsInBox(CFrame.new(p), NPC_PROBE, npcOverlap)) do
					if pointInBox(p, part, 0) then note(part, p, false) end
				end
				local d = p - prev
				if d.Magnitude > 1e-3 then
					local res = workspace:Raycast(prev, d, npcRay)
					if res then
						if humanoidModelOf(res.Instance) or res.Instance.Name == "GuardHull" then
							note(res.Instance, res.Position, true)
						elseif res.Instance.CanCollide and not res.Instance:IsDescendantOf(workspace:FindFirstChild("DroppedWeapons") or workspace.Terrain) then
							npc.sweep = nil
							onWall(sw.token, res.Position)
							return
						end
					end
				end
				pts[i] = p
			end
		end
		-- same deferral as the player client: a blocking target's body touch
		-- waits for a guard touch (instant) or the swing to fully end; a
		-- non-blocking target reports on first contact, no delay
		for hum, e in pairs(frameHits) do
			if e.guard then
				sw.pending[hum] = nil
				npcReport(sw, hum, e)
			elseif e.model:GetAttribute("Blocking") then
				local p = sw.pending[hum]
				if p then
					if (e.guard and not p.e.guard) or (not p.e.guard and e.ray and not p.e.ray) then p.e = e end
				else
					sw.pending[hum] = {e = e}
				end
			else
				npcReport(sw, hum, e)
			end
		end
	end
	table.insert(conns, RunService.Heartbeat:Connect(npcSweepStep))

	-- the NPC's own playback (mirrors CombatClient's): the swing clip fades in
	-- frozen on its first frame over the windup, then runs over `active`
	local npcArm = 0
	local function blendFor(speed, phase)
		local b = cfg.BLEND / math.max(speed or 1, 0.05)
		return math.clamp(b, 0.02, math.max(0.02, (phase or 1) * 0.5))
	end
	local function npcCached(id)
		local t = npc.tracks[id]
		if t == nil then
			t = npcTrack(id, Enum.AnimationPriority.Action, false) or false
			npc.tracks[id] = t
		end
		return t or nil
	end
	local function npcArmRelease(releaseId, speed, windup, active, recovery, token)
		npcArm += 1
		local arm = npcArm
		local fadeA = blendFor(speed, active)
		local fadeIn = windup > 0 and windup or fadeA
		if npc.current then npc.current:Stop(fadeIn); npc.current = nil end
		local t = npcCached(releaseId)
		if not t then return end
		if t.IsPlaying then t:Stop(0) end
		t:Play(fadeIn)
		t.TimePosition = 0
		t:AdjustSpeed(0)              -- hold the loaded pose while it blends in
		npc.current = t
		local function release()
			if state.token ~= token or npcArm ~= arm or not character or npc.current ~= t then return end
			local sp = (cfg.FIT_ANIMS and t.Length > 0) and t.Length / active or speed
			t:AdjustSpeed(sp)
			npcRay.FilterDescendantsInstances = {character}
			npcOverlap.FilterDescendantsInstances = {character}
			local last = {}
			for _, bl in ipairs(blades) do
				local pts = {}
				for i, off in ipairs(bl.offsets) do pts[i] = bl.part.CFrame:PointToWorldSpace(off) end
				last[bl] = pts
			end
			npc.sweep = {token = token, endsAt = os.clock() + active, last = last, reported = {}, pending = {}}
			task.delay(math.max(active - 0.02, 0), function()
				if npc.current == t and npcArm == arm then t:AdjustSpeed(0); t:Stop(fadeA); npc.current = nil end
			end)
		end
		if windup > 0 then task.delay(windup, release) else release() end
	end

	npcTell = function(what, a, b, c, d, e, f, g, h)
		if what == "Setup" then
			npcStopAll()
			npc.tracks = {}
			npc.idle  = npcTrack(a, Enum.AnimationPriority.Idle, true)
			npc.block = npcTrack(b, Enum.AnimationPriority.Action, true)
			if npc.idle then npc.idle:Play() end

		elseif what == "PlayAttack" then
			-- a = swing anim, b = speed, c = windup, d = active, e = cap, f = token, g = recovery
			npcArmRelease(a, b or 1, c or 0, d or 0, g or 0, f)

		elseif what == "Morph" then
			-- a = swing anim, b = speed, c = new windup, d = active, e = recovery, f = token
			npcArmRelease(a, b or 1, c or 0, d or 0, e or 0, f)

		elseif what == "Retime" then
			-- a = remaining windup, b = active, c = recovery, d = token: the windup got cut (chamber)
			local t = npc.current
			if t and state.attack then
				npcArm += 1
				local arm, token = npcArm, d
				t:AdjustWeight(1, math.max(a or 0, 0.01))
				task.delay(a or 0, function()
					if state.token ~= token or npcArm ~= arm or not character or npc.current ~= t then return end
					local fadeA = blendFor(1, b)
					t:AdjustSpeed((t.Length > 0) and t.Length / math.max(b or 0.01, 0.01) or 1)
					npcRay.FilterDescendantsInstances = {character}
					npcOverlap.FilterDescendantsInstances = {character}
					local last = {}
					for _, bl in ipairs(blades) do
						local pts = {}
						for i, off in ipairs(bl.offsets) do pts[i] = bl.part.CFrame:PointToWorldSpace(off) end
						last[bl] = pts
					end
					npc.sweep = {token = token, endsAt = os.clock() + (b or 0), last = last, reported = {}, pending = {}}
					task.delay(b or 0, function() if npc.current == t and npcArm == arm then t:Stop(fadeA); npc.current = nil end end)
				end)
			end

		elseif what == "Block" then
			if npc.block then
				if a == true then npc.block:Play() else npc.block:Stop() end
			end
		elseif what == "Blocked" or what == "Parried" or what == "Chambered" then
			-- the blade stops on their guard, then eases back to idle
			npc.sweep = nil
			npcArm += 1
			local t = npc.current
			if t then
				t:AdjustSpeed(0)
				task.delay(cfg.HITSTOP or 0.15, function() if npc.current == t then t:Stop(cfg.RECOIL); npc.current = nil end end)
			end
		elseif what == "Cancel" or what == "Flinch" then
			npc.sweep = nil
			npcArm += 1
			if npc.current then npc.current:Stop(blendFor(1, 1)); npc.current = nil end
		elseif what == "Cleanup" then
			npcStopAll()
		end
	end

	----------------------------------------------------------------
	--  ATTACKS — windup → release → recovery. Phase boundaries can MOVE
	--  after they're scheduled (a morph lengthens the windup, a chamber cuts
	--  it), so every timer re-arms itself against the live state times.
	----------------------------------------------------------------
	local function at(token, getTime, fn)
		local function tick()
			if state.token ~= token then return end
			local remaining = getTime() - os.clock()
			if remaining > 0.004 then task.delay(remaining, tick); return end
			fn()
		end
		task.delay(math.max(getTime() - os.clock(), 0), tick)
	end

	-- an id left as "rbxassetid://0" / "" means "none"
	local function animId(id) if type(id) == "string" and id ~= "" and id ~= "rbxassetid://0" then return id end return nil end

	-- speed, windup, active, recovery — from the clips and the speed stack
	local function attackTimes(info, name)
		local _, atype = CombatServer.sideType(name)
		local speed = (info.speed or 1) * ((cfg.TYPE_SPEED or {})[atype or ""] or 1) * cfg.SPEED_MULT
		local wl = info.windup or cfg.WINDUP
		if (attr("FastUntil") or 0) > os.clock() then wl = wl / cfg.RIPOSTE_SPEED end   -- riposte: quicker windup only
		local al = CombatServer.clipLength(animId(info.anim)) or info.active or cfg.DEFAULT_ACTIVE
		local rl = info.recovery or cfg.RECOVERY
		return speed,
			math.max(cfg.MIN_PHASE, wl / speed),
			math.max(cfg.MIN_PHASE, al / speed),
			math.max(cfg.MIN_PHASE, rl / speed)
	end

	-- windup, or the first INPUT_GRACE of release with nothing hit yet (latency)
	local function inWindup()
		if state.phase == "windup" then return true end
		return state.phase == "release" and not state.landed and os.clock() - state.windupEnd <= cfg.INPUT_GRACE
	end

	local function headPart() return character and (character:FindFirstChild("Head") or handle()) end

	-- stamina back to anyone whose dodge made this swing miss: they dodged
	-- during the swing, were inside reach (+ a margin) and in front of us
	local function dodgeRefunds()
		local hrp = character and character:FindFirstChild("HumanoidRootPart")
		if not hrp then return end
		CombatServer.eachTarget(character, function(m)
			local hum, thrp = m:FindFirstChildOfClass("Humanoid"), m:FindFirstChild("HumanoidRootPart")
			if not (hum and thrp and hum.Health > 0) or state.alreadyHit[hum] then return end
			local dodgedAt = m:GetAttribute("LastDodgeAt") or -1e9
			if dodgedAt < state.windupStart - 0.05 or dodgedAt > state.releaseEnd then return end
			local to = thrp.Position - hrp.Position
			if to.Magnitude > cfg.REACH + MovementConfig.DODGE_REFUND_RANGE then return end
			if hrp.CFrame.LookVector:Dot(to.Unit) < 0.3 then return end
			CombatServer.refundStamina(m, MovementConfig.DODGE_REFUND)
			m:SetAttribute("DodgeRefundTick", (m:GetAttribute("DodgeRefundTick") or 0) + 1)
			dprint(m.Name, "dodged the swing (+" .. MovementConfig.DODGE_REFUND .. " stamina)")
		end)
	end

	-- combo = true: chained straight out of the previous release, so there is
	-- NO windup — the blade goes live now and the clip starts at its swing part
	local function startAttack(name, combo)
		local info = cfg.ATTACKS[name]
		if not info then return end
		local now = os.clock()
		local speed, windup, active, recovery = attackTimes(info, name)
		if combo then windup = 0 end   -- straight into the next swing

		state.token += 1
		local token = state.token
		state.attack, state.attackName, state.alreadyHit, state.queued = info, name, {}, nil
		state.phase       = "windup"
		state.windupStart = now
		state.windupEnd   = now + windup
		state.releaseEnd  = state.windupEnd + active
		state.nextActionTime = state.releaseEnd + recovery
		state.morphs, state.landed, state.chambered = 0, false, false
		spend(info.staminaCost or 0)
		CombatServer.dropProtection(character)

		setSwinging(true)
		setAttr("TurnCapUntil", state.releaseEnd + cfg.TURN_CAP_EXTRA)
		sfx("Swing", nil, {Speed = math.clamp(speed, 0.7, 1.4)})
		Sounds.voice("Swing", headPart())

		at(token, function() return state.windupEnd end, function()
			if isStunned() then cancelSwing("stunned"); return end
			state.phase = "release"
			-- a head still riding the blade comes off with the swing, forward,
			-- as a projectile: light damage and a stun on whoever it hits
			local box = hitboxes[1]
			local hrp = character:FindFirstChild("HumanoidRootPart")
			if box and hrp and Injury.hasSkewer(box) then
				local throwDir = hrp.CFrame.LookVector + Vector3.new(0, 0.12, 0)
				local thrower = character
				Injury.launchSkewer(box, throwDir, cfg.HEAD_THROW_SPEED, thrower, function(victim, part)
					local vh = victim:FindFirstChildOfClass("Humanoid")
					if not vh or CombatServer.isProtected(victim) then return end
					sfx("Hit", part)
					Injury.bloodBurst(part)
					flinch(victim, (part.Position - hrp.Position).Unit)
					interrupt(victim, "hit")
					victim:SetAttribute("Blocking", false)
					victim:SetAttribute("StunnedUntil", os.clock() + cfg.HEAD_THROW_STUN)
					markCombat(victim)
					CombatServer.credit(victim, thrower, weaponName, "head")
					vh:TakeDamage(cfg.HEAD_THROW_DAMAGE)
					dprint("thrown head hit", victim.Name)
				end)
				dprint("launched the skewered head")
			end
		end)
		at(token, function() return state.releaseEnd end, function()
			state.phase = "recovery"
			if not state.landed then
				-- whiffed: the extra stamina is what makes spam a bad idea
				spend(((state.attack and state.attack.staminaCost) or 0) * cfg.MISS_COST_MULT)
				dodgeRefunds()
			end
			if state.queued and not isStunned() then
				local q = state.queued
				state.queued = nil
				startAttack(q, true)   -- combo: straight into the next swing, no windup, no recovery
			end
		end)
		at(token, function() return state.nextActionTime end, function()
			state.phase = "idle"
			setSwinging(false)
		end)

		dprint(combo and "combo ->" or "attack ->", name, string.format("speed %.2f | windup %.2f release %.2f recovery %.2f", speed, windup, active, recovery))
		tell("PlayAttack", info.anim, speed, windup, active, windup + active + cfg.TURN_CAP_EXTRA, token, recovery)
	end

	-- MORPH: swap the attack during the windup (right swing -> stab, overhead -> underhand…)
	local function morph(name)
		local info = cfg.ATTACKS[name]
		if not info then return end
		if name == state.attackName then dprint("morph denied: same attack"); return end
		if cfg.MORPH_NO_MIRROR then
			local fs, ft = CombatServer.sideType(state.attackName)
			local ts, tt = CombatServer.sideType(name)
			if ft == tt and fs and ts and fs ~= ts then dprint("morph denied: mirror of the same attack"); return end
		end
		do
			local _, ft = CombatServer.sideType(state.attackName)
			local _, tt = CombatServer.sideType(name)
			if ft and (cfg.MORPH_FORBID or {})[ft] == tt then dprint("morph denied:", ft, "->", tt, "is too far"); return end
		end
		local now = os.clock()
		if state.morphs >= cfg.MORPHS_PER_SWING then dprint("morph denied: already morphed"); return end
		local span = state.windupEnd - state.windupStart
		-- a windup that just chambered may morph however late it is (chamber-morph)
		if not state.chambered and span > 0 and (now - state.windupStart) / span > cfg.MORPH_CUTOFF then dprint("morph denied: too late in the windup"); return end
		if stamina() < cfg.MORPH_COST then dprint("morph denied: stamina"); return end
		spend(cfg.MORPH_COST)
		local speed, windup, active, recovery = attackTimes(info, name)
		-- the new windup runs in full at its own speed (never squeezed into what was left)
		local remaining = math.max(cfg.MIN_PHASE, windup * cfg.MORPH_WINDUP)
		state.attack, state.attackName = info, name
		state.morphs += 1
		state.chambered = false
		state.phase = "windup"   -- a morph from the grace window steps back out of release
		state.windupEnd  = now + remaining
		state.releaseEnd = state.windupEnd + active
		state.nextActionTime = state.releaseEnd + recovery
		setAttr("TurnCapUntil", state.releaseEnd + cfg.TURN_CAP_EXTRA)
		dprint("MORPH ->", name, string.format("(%.2f windup left)", remaining))
		tell("Morph", info.anim, speed, remaining, active, recovery, state.token)
	end

	-- CHAMBERED someone: our windup is cut short and we release now
	local function chamberRelease()
		if state.phase ~= "windup" or not state.attack then return end
		local now = os.clock()
		local _, _, active, recovery = attackTimes(state.attack, state.attackName)
		state.chambered = true
		if cfg.CHAMBER_MORPH_FREE then state.morphs = 0 end
		state.windupEnd  = math.min(state.windupEnd, now + cfg.CHAMBER_RELEASE)
		state.releaseEnd = state.windupEnd + active
		state.nextActionTime = state.releaseEnd + recovery
		tell("Retime", state.windupEnd - now, active, recovery, state.token)
	end

	local function doAttack(name)
		if not character or not usable(name) then dprint("attack denied: no such attack / no clip:", tostring(name)); return end
		if isIncapacitated() then dprint("attack denied: incapacitated"); return end
		if attr("Blocking")   then dprint("attack denied: blocking");      return end
		if inWindup() then morph(name); return end
		if state.phase == "release" or state.phase == "recovery" then
			if not state.attack then return end
			if name == state.attackName then dprint("combo denied: same attack"); return end
			state.queued = name
			dprint("queued combo ->", name)
			return
		end
		if state.phase ~= "idle" or os.clock() < state.nextActionTime then dprint("attack denied: busy"); return end
		startAttack(name)
	end

	-- any usable attack, for NPCs
	local function randomAttack()
		local names = {}
		for n in pairs(cfg.ATTACKS) do if usable(n) then table.insert(names, n) end end
		if #names > 0 then doAttack(names[math.random(#names)]) end
	end

	-- FEINT (key): pull the swing during windup, no guard involved
	local function doFeint()
		if not character or not cfg.FEINT_ANYTIME then return end
		if not inWindup() then dprint("feint denied: not in windup (" .. state.phase .. ")"); return end
		if stamina() < cfg.FEINT_COST then dprint("feint denied: stamina"); return end
		spend(cfg.FEINT_COST)
		cancelSwing("feint")
		state.nextActionTime = os.clock() + cfg.FEINT_RECOVERY
		sfx("Swing", nil, {Speed = 1.5, Volume = 0.5})
		tell("Feinted")
		dprint("FEINT")
	end

	----------------------------------------------------------------
	--  BLOCK / FEINT
	----------------------------------------------------------------
	local function doBlockStart()
		if not character or isIncapacitated() then return end
		local now = os.clock()
		-- one arm can't brace a guard: trying flings the weapon away
		if not Injury.canBlock(character) then
			if state.phase ~= "idle" then cancelSwing("disarmed") end
			knockAwayWeapon(character, nil, "tried to block with a missing arm")
			return
		end
		-- WINDUP only: feint-to-parry — cancel the windup and raise guard in one
		-- motion. Release / kick are committed; recovery just blocks normally.
		local feinted = false
		if inWindup() then
			if stamina() < cfg.FEINT_COST then dprint("feint-to-parry denied: stamina"); return end
			spend(cfg.FEINT_COST)
			cancelSwing("feint")
			state.nextActionTime = now + cfg.FEINT_RECOVERY
			feinted = true
			sfx("Swing", nil, {Speed = 1.5, Volume = 0.5})
			tell("Feinted")
			dprint("FEINT -> parry")
		elseif state.phase == "release" or state.phase == "kick" then
			dprint("block denied: committed (" .. state.phase .. ")"); return
		end
		if attr("Blocking") then return end
		-- a successful parry just now: straight back up with a fresh window (parry, parry, parry)
		local chained = now - (attr("LastParryAt") or -1e9) <= cfg.PARRY_CHAIN_WINDOW
		-- a feint already paid for this guard: the re-guard cooldown doesn't apply
		if not feinted and not chained and now < state.nextBlockTime then dprint("block denied: cooldown"); return end
		CombatServer.dropProtection(character)
		setAttr("Blocking", true)
		if chained or now - state.lastBlockStart >= cfg.PARRY_RETRY then
			setAttr("ParryUntil", now + cfg.PARRY_WINDOW)
		end
		state.lastBlockStart = now
		state.guardStart = now   -- a guard that comes down without having parried ends the chain
		tell("Block", true)
		dprint("block start")
	end

	local function doBlockStop()
		if not character then return end
		if attr("Blocking") then
			setAttr("Blocking", false)
			state.nextBlockTime = os.clock() + cfg.BLOCK_COOLDOWN
			-- no parry happened while this guard was up: the chain is broken, normal
			-- cooldown and PARRY_RETRY apply again (no spamming right click off one parry)
			if (attr("LastParryAt") or -1e9) < (state.guardStart or 0) then
				if attr("LastParryAt") then dprint("parry chain broken") end
				setAttr("LastParryAt", nil)
				setAttr("ParryStreak", nil)
			end
		end
		setAttr("ParryUntil", 0)
		tell("Block", false)
	end

	-- being hit or kicked breaks our own action: mid-swing, mid-kick, or guard
	local function interruptSelf(reason)
		local cancelled = false
		if state.phase ~= "idle" then
			-- a hit only stops a swing that hasn't committed yet; a kick stops anything
			local committed = state.phase == "release" or state.phase == "recovery"
			if not (cfg.FLINCH_ONLY_WINDUP and reason == "hit" and committed) then
				cancelSwing(reason)
				cancelled = true
			end
		end
		if attr("Blocking") then doBlockStop() end
		-- the flinch clip plays whenever we aren't mid-swing (idle, blocking, or just cancelled)
		if cancelled or state.phase == "idle" then tell("Flinch", reason) end
	end

	----------------------------------------------------------------
	--  KICK
	----------------------------------------------------------------
	local function resolveKick()
		return CombatServer.resolveKick(character, cfg, {sfx = sfx, tell = tell, dprint = dprint, weaponName = weaponName})
	end

	local function doKick()
		if not character or isIncapacitated() or attr("Blocking") then return end
		if not Injury.hasLimb(character, "Right Leg") then dprint("kick denied: no right leg"); return end
		local now = os.clock()
		if state.phase ~= "idle" or now < state.nextActionTime then dprint("kick denied: busy"); return end
		if now < state.nextKickTime then dprint("kick denied: cooldown"); return end
		state.token += 1
		local token = state.token
		state.attack, state.attackName, state.phase = nil, nil, "kick"
		state.nextActionTime = now + cfg.KICK_WINDUP + cfg.KICK_RECOVERY
		state.nextKickTime   = now + cfg.KICK_COOLDOWN
		spend(cfg.KICK_COST)
		setSwinging(true)
		sfx("Kick")
		Sounds.voice("Kick", headPart())
		setAttr("TurnCapUntil", now + cfg.KICK_WINDUP + cfg.TURN_CAP_EXTRA)
		tell("PlayKick", cfg.KICK_WINDUP + cfg.TURN_CAP_EXTRA, cfg.KICK_WINDUP)
		task.delay(cfg.KICK_WINDUP, function()
			if state.token ~= token then return end
			local landed = false
			if not isStunned() then landed = resolveKick() end
			if landed then
				CombatServer.refundStamina(character, cfg.KICK_REFUND)
			elseif CombatServer.wallAhead(character, 3) then
				dprint("kicked a wall")   -- no refund, no penalty
			else
				-- whiffed kick: stamina and a longer recovery, so it's a commitment
				spend(cfg.KICK_MISS_COST)
				state.nextActionTime = state.nextActionTime + cfg.KICK_MISS_EXTRA
			end
		end)
		at(token, function() return state.nextActionTime end, function()
			state.phase = "idle"
			setSwinging(false)
		end)
	end

	----------------------------------------------------------------
	--  WIRING
	----------------------------------------------------------------
	table.insert(conns, remote.OnServerEvent:Connect(function(who, action, a, b, c, d, e)
		if who ~= player then return end
		if action == "Hit" then
			onHitReport(a, b, c, d, e)
			return
		elseif action == "Wall" then
			onWall(a, b)
			return
		end
		dprint("recv", action, a)
		if action == "Attack"         then doAttack(a)
		elseif action == "Feint"      then doFeint()
		elseif action == "BlockStart" then doBlockStart()
		elseif action == "BlockStop"  then doBlockStop()
		elseif action == "Kick"       then doKick() end
	end))

	local function onEquipped()
		character = Tool.Parent
		if not (character and character:IsA("Model")) then character = nil; return end
		player    = Players:GetPlayerFromCharacter(character)
		humanoid  = character:FindFirstChildOfClass("Humanoid")
		dprint("equipped by", player and player.Name or character.Name .. " (NPC)")
		if not humanoid then warn("[" .. TAG .. "] no Humanoid on equip"); return end
		-- can't hold it without the arm(s): it goes straight back to the ground
		if not Injury.canWield(character, cfg.TWO_HANDED) then
			local char = character
			task.defer(function() Injury.disarm(char) end)
			return
		end
		if character:GetAttribute("BlockMeter") == nil then
			character:SetAttribute("BlockMeter", cfg.BLOCK_MAX)
		end
		character:SetAttribute("BlockMax", cfg.BLOCK_MAX)   -- HUD scale
		-- stamina regen runs in CharacterSystems (so it keeps going when this
		-- weapon leaves the hand); it reads these
		character:SetAttribute("StaminaRegen", cfg.BLOCK_REGEN)
		character:SetAttribute("StaminaRegenDelay", cfg.STAMINA_REGEN_DELAY)
		character:SetAttribute("Blocking", false)
		setGuard(false)
		-- weapon weight: composes with armor etc. via ReplicatedStorage.Modifiers
		character:SetAttribute("SpeedMult_Weapon", cfg.SpeedMult)
		character:SetAttribute("ClunkMult_Weapon", cfg.ClunkMult)
		sfx("Equip")
		if cfg.ANIMATED_GRIP then task.spawn(installToolGrip, character) end
		-- losing an arm mid-fight drops the weapon
		for _, c in ipairs(limbConns) do c:Disconnect() end
		limbConns = {}
		local char = character
		for _, limb in ipairs({"LimbLost_RightArm", "LimbLost_LeftArm"}) do
			table.insert(limbConns, char:GetAttributeChangedSignal(limb):Connect(function()
				if char == character and not Injury.canWield(char, cfg.TWO_HANDED) then
					if state.phase ~= "idle" then cancelSwing("lost an arm") end
					Injury.disarm(char)
				end
			end))
		end
		-- any script that lowers our Blocking attribute (block break, kick,
		-- parry) also lowers the hull and stamps the release time for lag grace
		if blockConn then blockConn:Disconnect() end
		local char = character
		blockConn = char:GetAttributeChangedSignal("Blocking"):Connect(function()
			local on = char:GetAttribute("Blocking") == true
			setGuard(on)
			if not on then char:SetAttribute("BlockStoppedAt", os.clock()) end
		end)
		tell("Setup", cfg.IDLE_ID, cfg.BLOCK_ID, animId(cfg.HIT_ID))
	end
	table.insert(conns, Tool.Equipped:Connect(onEquipped))

	table.insert(conns, Tool.Unequipped:Connect(function()
		dprint("unequipped")
		npcStopAll()
		removeToolGrip(character)
		if state.phase ~= "idle" then cancelSwing("unequipped") end
		-- a weapon leaving the hand mid-guard must not leave the guard raised:
		-- clear it unconditionally, not just when the attribute still reads true
		doBlockStop()
		setAttr("Blocking", false)
		setSwinging(false)
		setAttr("SpeedMult_Weapon", nil)
		setAttr("ClunkMult_Weapon", nil)
		setGuard(false)
		if blockConn then blockConn:Disconnect(); blockConn = nil end
		for _, c in ipairs(limbConns) do c:Disconnect() end
		limbConns = {}
		tell("Cleanup")
		character = nil
	end))

	table.insert(conns, Tool.Destroying:Connect(function()
		CombatServer.controllers[Tool] = nil
		for _, c in ipairs(conns) do c:Disconnect() end
		for _, c in ipairs(limbConns) do c:Disconnect() end
		if blockConn then blockConn:Disconnect() end
	end))

	-- a tool parented straight into a character (test dummies) is equipped
	-- before this script could connect, so catch up
	if not character and Tool.Parent and Tool.Parent:FindFirstChildOfClass("Humanoid") then
		task.defer(onEquipped)
	end

	local controller = {
		tool = Tool,
		attack = doAttack, cycle = randomAttack, feint = doFeint,
		blockStart = doBlockStart, blockStop = doBlockStop,
		kick = doKick, interrupt = interruptSelf,
		-- for other weapons' hit resolution (chambers)
		snapshot = function()
			return {phase = state.phase, kind = state.attack and state.attack.kind, windupStart = state.windupStart, name = state.attackName}
		end,
		chambered = chamberRelease,
	}
	CombatServer.controllers[Tool] = controller
	return controller
end

return CombatServer
