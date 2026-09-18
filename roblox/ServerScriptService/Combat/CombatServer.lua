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
       • A lethal hit to an arm or leg has DISMEMBER_CHANCE to sever it
         instead of killing: the victim survives on BLEED_HP and bleeds out.
         Lethal head hits decapitate when DECAPITATE is on.
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
local SoundConfig = require(ReplicatedStorage:WaitForChild("SoundConfig"))
local Injury      = require(script.Parent:WaitForChild("Injury"))
local Ragdoll     = require(script.Parent:WaitForChild("Ragdoll"))

local CombatServer = {}

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
	ATTACKS     = nil,   -- { Name = {anim, damage, windup, active, recovery, blockCost, staminaCost, speed} }
	CYCLE_ORDER = nil,   -- { "Stab", "LeftSwing", ... } for left-click cycling

	-- weapon feel
	SPEED_MULT  = 1.0,   -- whole-weapon tempo; scales windup/release/recovery of every attack
	REACH       = 8.0,   -- studs from attacker root to a valid hit point
	TWO_HANDED  = false, -- needs both arms to wield (losing the left arm drops it too)
	SpeedMult   = 1.0,   -- weight: WalkSpeed multiplier while equipped (published as SpeedMult_Weapon)
	ClunkMult   = 1.0,   -- weight: footstep clunk multiplier while equipped (published as ClunkMult_Weapon)
	SWING_SLOW  = 0.55,  -- WalkSpeed multiplier while attacking (published as SpeedMult_Swing)

	-- sound slots (a weapon Config's SOUNDS table overrides per key)
	SOUNDS = {
		Equip = "rbxassetid://0",
		Swing = "rbxassetid://0",   -- at the Handle when the windup starts
		Hit   = "rbxassetid://0",   -- at the struck part
		Block = "rbxassetid://0",
		Parry = "rbxassetid://0",
		Kick  = "rbxassetid://0",
	},

	-- hit validation / lethality
	REACH_TOLERANCE  = 3.0,   -- latency slack on top of REACH
	HIT_GRACE        = 0.30,  -- accept reports this long after release ends (round-trip lag)
	MIN_PHASE        = 0.05,
	HEAD_ONESHOT     = true,
	DECAPITATE       = true,  -- lethal head hits take the head off (death cam rides it)
	DISMEMBER_CHANCE = 0.35,  -- lethal arm/leg hits: chance to sever + bleed instead of kill
	KNOCKDOWN_TIME   = 2.00,  -- ragdoll time after a leg hit
	DISARM_STUN      = 0.60,  -- stagger after your weapon is knocked away

	-- guard / parry / stamina (the BlockMeter attribute IS the stamina bar)
	BLOCK_MAX         = 100,
	BLOCK_REGEN       = 15,
	BLOCK_BREAK_STUN  = 2.50,
	BLOCK_CONE_DEG    = 75,    -- must face the attacker within this half-angle to block
	BLOCK_GRACE       = 0.15,  -- a just-released block still counts for this long (lag)
	PARRY_WINDOW      = 0.35,
	PARRY_RETRY       = 0.45,  -- re-tapping block sooner than this gives no new parry window
	PARRY_COST        = 5,     -- timed parry costs less stamina than a held block
	PARRY_PUNISH_STUN = 1.50,
	RIPOSTE_DURATION  = 3.00,  -- after a parry, your attacks run at RIPOSTE_SPEED tempo
	RIPOSTE_SPEED     = 1.6,
	FEINT_COST        = 12,
	FEINT_RECOVERY    = 0.25,

	-- kick: short, unblockable, staggers a held block. Leg animation is
	-- procedural in the camera rig (LocalKickAt / LocalKickRise attributes).
	KICK_RANGE       = 5.5,
	KICK_CONE_DEG    = 50,
	KICK_WINDUP      = 0.22,
	KICK_RECOVERY    = 0.55,
	KICK_DAMAGE      = 5,
	KICK_STAGGER     = 0.9,
	KICK_COST        = 10,
	KICK_BLOCK_DRAIN = 15,

	-- geometry
	ANIMATED_GRIP  = true,   -- swap Roblox's RightGrip Weld for a "ToolGrip" Motor6D so animations can move the weapon
	HITBOX_NAME    = "Hitbox",
	GUARD_WIDTH    = 4.5,   -- hull cross-section around the blade while blocking
	GUARD_PAD      = 0.75,  -- extra hull length past each end of the blade
	GUARD_MARGIN   = 0.5,   -- server: a body hit this close inside a raised hull still counts as blocked
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
		windupEnd = 0, releaseEnd = 0, nextActionTime = 0,
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
	local function spend(n)     setAttr("BlockMeter", math.max(0, stamina() - n)) end
	local function tell(...)    if player then remote:FireClient(player, ...) end end
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

		-- the client's ray can start inside a hull and never "enter" it; if the
		-- body hit's point lies inside a raised, facing guard hull, it's a block
		if not claimedGuard and guardUp and facing then
			local tool = target:FindFirstChildOfClass("Tool")
			if tool then
				for _, h in ipairs(tool:GetDescendants()) do
					if h.Name == "GuardHull" and h:IsA("BasePart") and pointInBox(hitPos, h, cfg.GUARD_MARGIN) then
						claimedGuard = true
						dprint("hit point inside", target.Name, "guard -> block")
						break
					end
				end
			end
		end

		if claimedGuard and guardUp and facing then
			-- a guard with no stamina behind it, or one arm, can't hold: the weapon flies
			local meter = target:GetAttribute("BlockMeter") or cfg.BLOCK_MAX
			if meter <= 0 or not Injury.canBlock(target) then
				knockAwayWeapon(target, dir, meter <= 0 and "guard hit at 0 stamina" or "guard with a missing arm")
				sfx("Block", part)
				tell("Blocked", true)
				return
			end
			if (target:GetAttribute("ParryUntil") or 0) > now then
				-- PARRY: attacker punished, defender gets a riposte
				setAttr("StunnedUntil", now + cfg.PARRY_PUNISH_STUN)
				target:SetAttribute("FastUntil", now + cfg.RIPOSTE_DURATION)
				target:SetAttribute("BlockMeter", math.max(0, meter - cfg.PARRY_COST))
				cancelSwing("parried")
				sfx("Parry", part)
				tell("Parried")
				dprint("PARRIED by", target.Name)
			else
				-- BLOCK: drains defender stamina; empty = guard broken
				local m = meter - info.blockCost
				sfx("Block", part)
				if m <= 0 then
					target:SetAttribute("BlockMeter", 0)
					target:SetAttribute("Blocking", false)
					target:SetAttribute("StunnedUntil", now + cfg.BLOCK_BREAK_STUN)
					tell("Blocked", true)
					dprint("BLOCK BROKEN on", target.Name)
				else
					target:SetAttribute("BlockMeter", m)
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

		if region == "head" and cfg.HEAD_ONESHOT then
			if cfg.DECAPITATE and Injury.dismember(target, "Head", dir) then
				dprint("DECAPITATED", target.Name)
			else
				hum:TakeDamage(hum.MaxHealth)
				dprint("HEADSHOT on", target.Name)
			end
			tell("HitConfirm", region)
			return
		end

		-- lethal limb hit: chance to take the limb instead of the life
		local lethal = hum.Health - info.damage <= 0
		local limb = (part.Parent == target and Injury.LIMBS[part.Name] and part.Name ~= "Head") and part.Name or nil
		if lethal and limb and target:GetAttribute("Bleeding") ~= true
			and Injury.hasLimb(target, limb) and math.random() < cfg.DISMEMBER_CHANCE then
			if Injury.dismember(target, limb, dir) then
				dprint("DISMEMBERED", target.Name, limb)
				tell("HitConfirm", region)
				return
			end
		end

		hum:TakeDamage(info.damage)
		if region == "legs" and hum.Health > 0 then
			Ragdoll.knockdown(target, cfg.KNOCKDOWN_TIME)
			Sounds.play(SoundConfig.BodyFall, target:FindFirstChild("Torso"))
		end
		dprint("hit", target.Name, region, info.damage)
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
		if attr("Blocking") then setAttr("Blocking", false) end
		tell("Block", false)
	end

	----------------------------------------------------------------
	--  KICK
	----------------------------------------------------------------
	local function resolveKick()
		local hrp = character and character:FindFirstChild("HumanoidRootPart")
		if not hrp then return end
		local cosCone = math.cos(math.rad(cfg.KICK_CONE_DEG))
		local now = os.clock()
		eachTarget(function(m)
			local hum, thrp = m:FindFirstChildOfClass("Humanoid"), m:FindFirstChild("HumanoidRootPart")
			if not (hum and thrp and hum.Health > 0) then return end
			local to = thrp.Position - hrp.Position
			to = Vector3.new(to.X, 0, to.Z)
			if to.Magnitude > cfg.KICK_RANGE or to.Magnitude < 1e-3 then return end
			if hrp.CFrame.LookVector:Dot(to.Unit) < cosCone then return end
			sfx("Kick", thrp)
			flinch(m, to.Unit)
			if m:GetAttribute("Blocking") then
				m:SetAttribute("Blocking", false)
				m:SetAttribute("StunnedUntil", now + cfg.KICK_STAGGER)
				m:SetAttribute("BlockMeter", math.max(0, (m:GetAttribute("BlockMeter") or cfg.BLOCK_MAX) - cfg.KICK_BLOCK_DRAIN))
				dprint("KICK staggered", m.Name)
			else
				hum:TakeDamage(cfg.KICK_DAMAGE)
				dprint("kick hit", m.Name)
			end
			tell("HitConfirm", "kick")
		end)
	end

	local function doKick()
		if not character or isIncapacitated() or attr("Blocking") then return end
		if not Injury.hasLimb(character, "Right Leg") then dprint("kick denied: no right leg"); return end
		local now = os.clock()
		if state.phase ~= "idle" or now < state.nextActionTime then dprint("kick denied: busy"); return end
		state.token += 1
		local token = state.token
		state.attack, state.attackName, state.phase = nil, nil, "kick"
		state.nextActionTime = now + cfg.KICK_WINDUP + cfg.KICK_RECOVERY
		spend(cfg.KICK_COST)
		setSwinging(true)
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

	table.insert(conns, Tool.Equipped:Connect(function()
		character = Tool.Parent
		player    = Players:GetPlayerFromCharacter(character)
		humanoid  = character:FindFirstChildOfClass("Humanoid")
		dprint("equipped by", player and player.Name)
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
	end))

	table.insert(conns, Tool.Unequipped:Connect(function()
		dprint("unequipped")
		removeToolGrip(character)
		if state.phase ~= "idle" then cancelSwing("unequipped") end
		doBlockStop()
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
		if not character or isStunned() or attr("Blocking") then return end
		local m = stamina()
		if m < cfg.BLOCK_MAX then
			setAttr("BlockMeter", math.min(cfg.BLOCK_MAX, m + cfg.BLOCK_REGEN * dt))
		end
	end))

	table.insert(conns, Tool.Destroying:Connect(function()
		for _, c in ipairs(conns) do c:Disconnect() end
		for _, c in ipairs(limbConns) do c:Disconnect() end
		if blockConn then blockConn:Disconnect() end
	end))
end

return CombatServer
