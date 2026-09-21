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
local Injury      = require(script.Parent:WaitForChild("Injury"))
local Ragdoll     = require(script.Parent:WaitForChild("Ragdoll"))

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
--  DEFAULTS — global combat rules. A weapon Config overrides any key.
--------------------------------------------------------------------
CombatServer.DEFAULTS = {
	-- weapon identity (a weapon MUST provide these)
	IDLE_ID     = nil,
	BLOCK_ID    = nil,
	ATTACKS     = nil,   -- { Name = {anim, kind="slash"|"stab", damage, windup, active, recovery, blockCost, staminaCost, speed} }
	CYCLE_ORDER = nil,   -- { "Stab", "LeftSwing", ... } for left-click cycling

	-- weapon feel
	SPEED_MULT  = 1.0,   -- whole-weapon tempo; scales windup/release/recovery of every attack
	REACH       = 8.0,   -- studs from attacker root to a valid hit point
	TWO_HANDED  = false, -- needs both arms to wield (losing the left arm drops it too)
	SpeedMult   = 1.0,   -- weight: WalkSpeed multiplier while equipped (published as SpeedMult_Weapon)
	ClunkMult   = 1.0,   -- weight: footstep clunk multiplier while equipped (published as ClunkMult_Weapon)
	SWING_SLOW  = 0.55,  -- WalkSpeed multiplier while attacking (published as SpeedMult_Swing)

	-- Sound slots (a weapon Config's SOUNDS table overrides per key). These
	-- default to Roblox's built-in rbxasset:// content so everything is audible
	-- out of the box — swap in your own asset ids per weapon.
	SOUNDS = {
		Equip = "rbxasset://sounds/unsheath.wav",
		Swing = "rbxasset://sounds/swordslash.wav",  -- at the Handle when the windup starts
		Hit   = "rbxasset://sounds/swordlunge.wav",  -- at the struck part
		Block = "rbxasset://sounds/metal.ogg",
		Parry = "rbxasset://sounds/metal.ogg",
		Kick    = "rbxasset://sounds/swordlunge.wav",  -- the kick itself, at the kicker
		KickHit = "rbxasset://sounds/metal.ogg",      -- …and the impact, at whoever caught it
	},

	-- hit validation / lethality
	REACH_TOLERANCE  = 3.0,   -- latency slack on top of REACH
	HIT_GRACE        = 0.30,  -- accept reports this long after release ends (round-trip lag)
	MIN_PHASE        = 0.05,
	HEAD_DAMAGE_MULT = 2.0,   -- head hits hurt this much more (no longer an automatic kill)
	DECAPITATE       = true,  -- lethal slash to the head takes it off (death cam rides it)
	DISMEMBER_ON_KILL= true,  -- lethal slash to an arm/leg takes that limb off
	BLEED_OUT_CHANCE = 0.35,  -- …and this often the victim survives it, bleeding, instead of dying
	IMPALE           = true,  -- lethal face stab skewers the head on the attacker's real blade
	STAB_HEAD_EXECUTE= true,  -- …and a stab to the face always kills, so the skewer always happens.
	                          --    Slashes to the head still only kill if the damage gets there.
	DISARM_STUN      = 0.60,  -- stagger after your weapon is knocked away

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
	PARRY_COST_MULT   = 0.3,   -- a timed parry costs this fraction of the attack's blockCost
	PARRY_PUNISH_STUN = 1.50,
	RIPOSTE_DURATION  = 3.00,  -- after a parry, your attacks run at RIPOSTE_SPEED tempo
	RIPOSTE_SPEED     = 1.6,
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
	local function dprint(...) DebugFlags.log(TAG, ...) end

	if not (cfg.ATTACKS and cfg.CYCLE_ORDER) then
		warn("[" .. TAG .. "] Config needs ATTACKS and CYCLE_ORDER")
		return
	end

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
		windupEnd = 0, releaseEnd = 0, nextActionTime = 0, nextKickTime = 0, nextBlockTime = 0,
		cycleIndex = 0, lastBlockStart = -1e9,
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
	-- every stamina event (and every hit taken) stamps LastCombatAt, which
	-- holds off regen for STAMINA_REGEN_DELAY on whichever character it's on
	local function markCombat(char) char:SetAttribute("LastCombatAt", os.clock()) end
	local function drainStamina(char, amount)
		char:SetAttribute("BlockMeter", math.max(0, (char:GetAttribute("BlockMeter") or cfg.BLOCK_MAX) - amount))
		markCombat(char)
	end
	local function spend(n)     if character then drainStamina(character, n) end end
	local npcTell   -- server-side stand-in for the client when no player holds the tool; set below
	local function tell(...)
		if player then remote:FireClient(player, ...)
		elseif npcTell then npcTell(...) end
	end
	local function setSwinging(on) setAttr("SpeedMult_Swing", on and cfg.SWING_SLOW or nil) end
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

	-- Break whatever someone else was in the middle of. Their own weapon owns
	-- their action state, so go through its controller rather than poking
	-- attributes — that way their client is told to stop the animation too.
	local function interrupt(targetChar, reason)
		local tool = targetChar and targetChar:FindFirstChildOfClass("Tool")
		local ctrl = tool and CombatServer.controllers[tool]
		if ctrl then ctrl.interrupt(reason) end
	end

	-- victim's client listens for HitTick to flinch the camera; HitDir says which way
	local function flinch(target, dir)
		target:SetAttribute("HitDir", dir)
		target:SetAttribute("HitTick", (target:GetAttribute("HitTick") or 0) + 1)
	end

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

	local function eachTarget(fn)
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

	----------------------------------------------------------------
	--  HIT RESOLUTION
	----------------------------------------------------------------
	local function resolveHit(hum, target, part, hitPos, claimedGuard)
		local info = state.attack
		local now  = os.clock()
		local myHRP     = character:FindFirstChild("HumanoidRootPart")
		local targetHRP = target:FindFirstChild("HumanoidRootPart")

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
			if meter <= 0 or not Injury.canBlock(target) then
				markCombat(target)
				knockAwayWeapon(target, dir, meter <= 0 and "guard hit at 0 stamina" or "guard with a missing arm")
				sfx("Block", part)
				tell("Blocked", true)
				return
			end
			if (target:GetAttribute("ParryUntil") or 0) > now then
				-- PARRY: attacker punished, defender gets a riposte; costs a fraction of a block
				setAttr("StunnedUntil", now + cfg.PARRY_PUNISH_STUN)
				target:SetAttribute("FastUntil", now + cfg.RIPOSTE_DURATION)
				drainStamina(target, info.blockCost * cfg.PARRY_COST_MULT)
				cancelSwing("parried")
				sfx("Parry", part)
				tell("Parried")
				dprint("PARRIED by", target.Name)
			else
				-- BLOCK: drains defender stamina by the attack's blockCost; empty = guard broken
				drainStamina(target, info.blockCost)
				local m = target:GetAttribute("BlockMeter") or 0
				sfx("Block", part)
				-- the blade stops dead on a guard, same as a parry — the parry's
				-- extra punish is the attacker's stun and the defender's riposte
				cancelSwing("blocked")
				if m <= 0 then
					target:SetAttribute("Blocking", false)
					-- run dry holding the guard and the weapon is jarred out of your hands
					knockAwayWeapon(target, dir, "guard broken at 0 stamina")
					-- set last: knockAwayWeapon's shorter DISARM_STUN must not cut this short
					target:SetAttribute("StunnedUntil", now + cfg.BLOCK_BREAK_STUN)
					tell("Blocked", true)
					dprint("BLOCK BROKEN on", target.Name)
				else
					tell("Blocked", false)
					dprint("blocked by", target.Name, "meter", math.floor(m))
				end
			end
			return
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

		local dmg    = info.damage * (region == "head" and cfg.HEAD_DAMAGE_MULT or 1)
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
		state.alreadyHit[hum] = true
		resolveHit(hum, model, part, hitPos, claimedGuard == true)
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
					if res then note(res.Instance, res.Position, true) end
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

	npcTell = function(what, a, b, c, d, e, f)
		if what == "Setup" then
			npcStopAll()
			npc.tracks = {}
			npc.idle  = npcTrack(a, Enum.AnimationPriority.Idle, true)
			npc.block = npcTrack(b, Enum.AnimationPriority.Action, true)
			if npc.idle then npc.idle:Play() end

		elseif what == "PlayAttack" then
			local id, speed, windup, active, token = a, b or 1, c or 0, d or 0, f
			local t = npc.tracks[id]
			if not t then
				t = npcTrack(id, Enum.AnimationPriority.Action, false)
				npc.tracks[id] = t
			end
			if npc.current and npc.current ~= t then npc.current:Stop() end
			if t then t:Stop(); t:Play(); t:AdjustSpeed(speed) end
			npc.current = t
			task.delay(windup, function()
				if state.token ~= token or not character then return end
				npcRay.FilterDescendantsInstances = {character}
				npcOverlap.FilterDescendantsInstances = {character}
				local last = {}
				for _, bl in ipairs(blades) do
					local pts = {}
					for i, off in ipairs(bl.offsets) do pts[i] = bl.part.CFrame:PointToWorldSpace(off) end
					last[bl] = pts
				end
				npc.sweep = {token = token, endsAt = os.clock() + active, last = last, reported = {}, pending = {}}
			end)

		elseif what == "Block" then
			if npc.block then
				if a == true then npc.block:Play() else npc.block:Stop() end
			end
		elseif what == "Blocked" then
			npc.sweep = nil
		elseif what == "Parried" or what == "Cancel" then
			npc.sweep = nil
			if npc.current then npc.current:Stop(); npc.current = nil end
		elseif what == "Cleanup" then
			npcStopAll()
		end
	end

	----------------------------------------------------------------
	--  ATTACKS
	----------------------------------------------------------------
	local function startAttack(name)
		local info = cfg.ATTACKS[name]
		if not info then return end
		local now = os.clock()

		local speed = (info.speed or 1) * cfg.SPEED_MULT
		if (attr("FastUntil") or 0) > now then speed = speed * cfg.RIPOSTE_SPEED end
		local windup   = math.max(cfg.MIN_PHASE, info.windup   / speed)
		local active   = math.max(cfg.MIN_PHASE, info.active   / speed)
		local recovery = math.max(cfg.MIN_PHASE, info.recovery / speed)

		state.token += 1
		local token = state.token
		state.attack, state.attackName, state.alreadyHit, state.queued = info, name, {}, nil
		state.phase      = "windup"
		state.windupEnd  = now + windup
		state.releaseEnd = now + windup + active
		state.nextActionTime = now + windup + active + recovery
		spend(info.staminaCost or 0)

		setSwinging(true)
		local cap = windup + active + cfg.TURN_CAP_EXTRA
		setAttr("TurnCapUntil", now + cap)
		sfx("Swing", nil, {Speed = math.clamp(speed, 0.7, 1.4)})

		task.delay(windup, function()
			if state.token ~= token then return end
			if isStunned() then cancelSwing("stunned"); return end
			state.phase = "release"
		end)
		task.delay(windup + active, function()
			if state.token ~= token then return end
			state.phase = "recovery"
			if state.queued and not isStunned() then
				local q = state.queued
				state.queued = nil
				startAttack(q)   -- combo: chain straight out of release, skipping recovery
			end
		end)
		task.delay(windup + active + recovery, function()
			if state.token ~= token then return end
			state.phase = "idle"
			setSwinging(false)
		end)

		dprint("attack ->", name, string.format("speed %.2f | windup %.2f release %.2f recovery %.2f", speed, windup, active, recovery))
		tell("PlayAttack", info.anim, speed, windup, active, cap, token)
	end

	local function doAttack(name)
		if not character or not cfg.ATTACKS[name] then return end
		if isIncapacitated() then dprint("attack denied: incapacitated"); return end
		if attr("Blocking")   then dprint("attack denied: blocking");      return end
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

	local function doCycle()
		state.cycleIndex = (state.cycleIndex % #cfg.CYCLE_ORDER) + 1
		doAttack(cfg.CYCLE_ORDER[state.cycleIndex])
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
		if state.phase == "windup" then
			-- feint-to-parry: cancel the windup and raise guard in one motion
			if stamina() < cfg.FEINT_COST then dprint("feint denied: stamina"); return end
			spend(cfg.FEINT_COST)
			cancelSwing("feint")
			state.nextActionTime = now + cfg.FEINT_RECOVERY
		elseif state.phase == "release" or state.phase == "kick" then
			dprint("block denied: committed"); return
		end
		if attr("Blocking") then return end
		if now < state.nextBlockTime then dprint("block denied: cooldown"); return end
		setAttr("Blocking", true)
		if now - state.lastBlockStart >= cfg.PARRY_RETRY then
			setAttr("ParryUntil", now + cfg.PARRY_WINDOW)
		end
		state.lastBlockStart = now
		tell("Block", true)
		dprint("block start")
	end

	local function doBlockStop()
		if not character then return end
		if attr("Blocking") then
			setAttr("Blocking", false)
			state.nextBlockTime = os.clock() + cfg.BLOCK_COOLDOWN
		end
		setAttr("ParryUntil", 0)
		tell("Block", false)
	end

	-- being hit or kicked breaks our own action: mid-swing, mid-kick, or guard
	local function interruptSelf(reason)
		if state.phase ~= "idle" then cancelSwing(reason) end
		if attr("Blocking") then doBlockStop() end
	end

	----------------------------------------------------------------
	--  KICK
	----------------------------------------------------------------
	local function resolveKick()
		local hrp = character and character:FindFirstChild("HumanoidRootPart")
		if not hrp then return end
		local cosCone = math.cos(math.rad(cfg.KICK_CONE_DEG))
		local now = os.clock()
		local landed, nearest = false, math.huge
		eachTarget(function(m)
			local hum, thrp = m:FindFirstChildOfClass("Humanoid"), m:FindFirstChild("HumanoidRootPart")
			if not (hum and thrp and hum.Health > 0) then return end
			local to = thrp.Position - hrp.Position
			to = Vector3.new(to.X, 0, to.Z)
			nearest = math.min(nearest, to.Magnitude)
			if to.Magnitude > cfg.KICK_RANGE or to.Magnitude < 1e-3 then return end
			if hrp.CFrame.LookVector:Dot(to.Unit) < cosCone then return end
			landed = true
			sfx("KickHit", thrp)
			flinch(m, to.Unit)
			local wasBlocking = m:GetAttribute("Blocking") == true
			interrupt(m, "kicked")   -- stops their swing and drops their guard, animation included
			if wasBlocking then
				-- breaks a held block AND an open parry window
				m:SetAttribute("Blocking", false)
				m:SetAttribute("ParryUntil", 0)
				m:SetAttribute("StunnedUntil", now + cfg.KICK_STAGGER)
				drainStamina(m, cfg.KICK_BLOCK_DRAIN)
				dprint("KICK staggered", m.Name)
			else
				hum:TakeDamage(cfg.KICK_DAMAGE)
				markCombat(m)
				dprint("kick hit", m.Name)
			end
			tell("HitConfirm", "kick")
		end)
		if not landed then
			dprint(string.format("kick missed — nearest target %.1f studs (range %.1f, cone ±%d°)",
				nearest, cfg.KICK_RANGE, cfg.KICK_CONE_DEG))
		end
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
		setAttr("TurnCapUntil", now + cfg.KICK_WINDUP + cfg.TURN_CAP_EXTRA)
		tell("PlayKick", cfg.KICK_WINDUP + cfg.TURN_CAP_EXTRA, cfg.KICK_WINDUP)
		task.delay(cfg.KICK_WINDUP, function()
			if state.token ~= token then return end
			if not isStunned() then resolveKick() end
		end)
		task.delay(cfg.KICK_WINDUP + cfg.KICK_RECOVERY, function()
			if state.token ~= token then return end
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
		end
		dprint("recv", action, a)
		if action == "Cycle"          then doCycle()
		elseif action == "Attack"     then doAttack(a)
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
		tell("Setup", cfg.IDLE_ID, cfg.BLOCK_ID)
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

	table.insert(conns, RunService.Heartbeat:Connect(function(dt)
		-- no regen while blocking, mid-action, stunned, or within the delay of any combat event
		if not character or isStunned() or attr("Blocking") or state.phase ~= "idle" then return end
		if os.clock() - (attr("LastCombatAt") or -1e9) < cfg.STAMINA_REGEN_DELAY then return end
		local m = stamina()
		if m < cfg.BLOCK_MAX then
			setAttr("BlockMeter", math.min(cfg.BLOCK_MAX, m + cfg.BLOCK_REGEN * dt))
		end
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
		attack = doAttack, cycle = doCycle,
		blockStart = doBlockStart, blockStop = doBlockStop,
		kick = doKick, interrupt = interruptSelf,
	}
	CombatServer.controllers[Tool] = controller
	return controller
end

return CombatServer
