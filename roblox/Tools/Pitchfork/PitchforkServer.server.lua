--[[ PITCHFORK — SERVER authority. Validates client-reported blade hits,
     resolves block / parry / damage, owns attack phases (windup → release →
     recovery), combos, feints, kicks, stamina, cooldowns, turn-cap, and the
     "Swinging" input to the WalkSpeed governor (this never writes WalkSpeed).

     HIT MODEL
       • The attacker's CLIENT sweeps raycasts along its blade every frame
         during release (see client script) and reports the FIRST thing each
         ray touched. Detecting on the swinger's machine is what makes swings
         feel instant; the server never trusts a report blindly.
       • This script validates each report: same swing token, inside the
         release window (+ latency grace), target within weapon reach, hit
         point actually on the claimed part, one hit per target per swing.
       • Blocking is PHYSICAL. While a player holds block, a GuardHull box
         welded to their weapon's Hitbox becomes raycast-visible. The
         incoming blade must touch the hull BEFORE any body part or it is not
         a block: from behind, from the off-side, under or over the guard, it
         lands clean. A facing cone is checked on top so a hull that is
         geometrically in the way can't block a hit to the back.
       • Timed parry = a block landed inside PARRY_WINDOW after raising guard:
         attacker is stunned, defender gets a riposte speed buff. ]]

local Tool       = script.Parent
local Players    = game:GetService("Players")
local RunService = game:GetService("RunService")

local DEBUG      = true
local DEBUG_HULL = true    -- tint the GuardHull so you can see your guard while tuning
local function dprint(...) if DEBUG then print("[Pitchfork/Server]", ...) end end

--------------------------------------------------------------------
--  CONFIG
--------------------------------------------------------------------
local IDLE_ID  = "rbxassetid://135659407369438"
local BLOCK_ID = "rbxassetid://130536914016941"

local SPEED_MULT = 0.5   -- whole-weapon tempo; scales windup/release/recovery of every attack

-- phase times are seconds at speed 1.0; all three divide by (attack.speed * SPEED_MULT)
local ATTACKS = {
	Stab       = {anim="rbxassetid://119395054343039", damage=18, windup=0.12, active=0.14, recovery=0.14, blockCost=20, staminaCost=8,  speed=1.0},
	LeftSwing  = {anim="rbxassetid://89500144760778",  damage=15, windup=0.14, active=0.16, recovery=0.15, blockCost=18, staminaCost=8,  speed=1.0},
	RightSwing = {anim="rbxassetid://82652664048008",  damage=15, windup=0.14, active=0.16, recovery=0.15, blockCost=18, staminaCost=8,  speed=1.0},
	Overhead   = {anim="rbxassetid://101285628758246", damage=30, windup=0.20, active=0.18, recovery=0.20, blockCost=40, staminaCost=12, speed=0.8},
}
local CYCLE_ORDER = {"Stab","LeftSwing","RightSwing","Overhead"}

local REACH           = 9.0    -- studs from attacker root to a valid hit point
local REACH_TOLERANCE = 3.0    -- latency slack on top of REACH
local HIT_GRACE       = 0.30   -- accept reports this long after release ends (round-trip lag)
local MIN_PHASE       = 0.05

-- guard / parry / stamina (the BlockMeter attribute IS the stamina bar)
local BLOCK_MAX         = 100
local BLOCK_REGEN       = 15
local BLOCK_BREAK_STUN  = 2.50
local BLOCK_CONE_DEG    = 75     -- must face the attacker within this half-angle to block
local BLOCK_GRACE       = 0.15   -- a just-released block still counts for this long (lag)
local PARRY_WINDOW      = 0.35
local PARRY_RETRY       = 0.45   -- re-tapping block sooner than this gives no new parry window
local PARRY_COST        = 5      -- timed parry costs less stamina than a held block
local PARRY_PUNISH_STUN = 1.50
local RIPOSTE_DURATION  = 3.00   -- after a parry, your attacks run at RIPOSTE_SPEED tempo
local RIPOSTE_SPEED     = 1.6
local FEINT_COST        = 12
local FEINT_RECOVERY    = 0.25

-- kick: short, unblockable, staggers a held block. The leg animation is
-- procedural in the camera rig (LocalKickAt / LocalKickRise attributes).
local KICK_RANGE, KICK_CONE_DEG   = 5.5, 50
local KICK_WINDUP, KICK_RECOVERY  = 0.22, 0.55
local KICK_DAMAGE, KICK_STAGGER   = 5, 0.9
local KICK_COST, KICK_BLOCK_DRAIN = 10, 15

local KNOCKDOWN_TIME = 2.00
local HEAD_ONESHOT   = true

local HITBOX_NAME    = "Hitbox"
local GUARD_WIDTH    = 4.5    -- hull cross-section around the blade while blocking
local GUARD_PAD      = 0.75   -- extra hull length past each end of the blade
local TURN_CAP_EXTRA = 0.10
local SWING_SLOW     = 0.55   -- WalkSpeed multiplier while swinging (published to governor)
--------------------------------------------------------------------

local remote = Tool:FindFirstChild("CombatRemote")
if not remote then
	remote = Instance.new("RemoteEvent")
	remote.Name = "CombatRemote"
	remote.Parent = Tool
end

local character, humanoid, player
local blockConn
local state = {
	token = 0, phase = "idle",          -- idle | windup | release | recovery | kick
	attack = nil, attackName = nil, alreadyHit = {}, queued = nil,
	windupEnd = 0, releaseEnd = 0, nextActionTime = 0,
	cycleIndex = 0, lastBlockStart = -1e9,
}

--------------------------------------------------------------------
--  HITBOX + GUARD HULL
--------------------------------------------------------------------
local hitboxes, hulls = {}, {}
for _, d in ipairs(Tool:GetDescendants()) do
	if d:IsA("BasePart") and d.Name == HITBOX_NAME then table.insert(hitboxes, d) end
end
dprint("found", #hitboxes, HITBOX_NAME.." part(s)")
if #hitboxes == 0 then
	warn("[Pitchfork/Server] No part named '"..HITBOX_NAME.."' in the Tool — hits and blocks won't work.")
end

local function makeHull(box)
	local s = box.Size
	local size
	if s.X >= s.Y and s.X >= s.Z then size = Vector3.new(s.X + GUARD_PAD*2, GUARD_WIDTH, GUARD_WIDTH)
	elseif s.Y >= s.Z then          size = Vector3.new(GUARD_WIDTH, s.Y + GUARD_PAD*2, GUARD_WIDTH)
	else                            size = Vector3.new(GUARD_WIDTH, GUARD_WIDTH, s.Z + GUARD_PAD*2) end
	local hull = Instance.new("Part")
	hull.Name = "GuardHull"
	hull.Size = size
	hull.CFrame = box.CFrame
	hull.Transparency = DEBUG_HULL and 0.85 or 1
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

local function setGuard(on)
	for _, h in ipairs(hulls) do
		h.CanQuery = on
		if DEBUG_HULL then h.Transparency = on and 0.5 or 0.85 end
	end
end

--------------------------------------------------------------------
--  HELPERS
--------------------------------------------------------------------
local function attr(n)      return character and character:GetAttribute(n) end
local function setAttr(n,v) if character then character:SetAttribute(n,v) end end
local function isStunned()  return (attr("StunnedUntil") or 0) > os.clock() end
local function stamina()    return attr("BlockMeter") or BLOCK_MAX end
local function spend(n)     setAttr("BlockMeter", math.max(0, stamina() - n)) end
local function tell(...)    if player then remote:FireClient(player, ...) end end

local function cancelSwing(reason)
	state.token += 1
	state.phase, state.attack, state.attackName, state.queued = "idle", nil, nil, nil
	setAttr("Swinging", false)
	tell("Cancel", reason)
	dprint("swing cancelled:", reason)
end

local function knockdown(hum)
	hum.PlatformStand = true
	task.delay(KNOCKDOWN_TIME, function()
		if hum and hum.Parent then hum.PlatformStand = false end
	end)
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

--------------------------------------------------------------------
--  HIT RESOLUTION
--------------------------------------------------------------------
local function resolveHit(hum, target, part, hitPos, claimedGuard)
	local info = state.attack
	local now  = os.clock()
	local myHRP     = character:FindFirstChild("HumanoidRootPart")
	local targetHRP = target:FindFirstChild("HumanoidRootPart")

	local guardUp = target:GetAttribute("Blocking") == true
		or (now - (target:GetAttribute("BlockStoppedAt") or -1e9)) < BLOCK_GRACE
	local facing = true
	if myHRP and targetHRP then
		local to = myHRP.Position - targetHRP.Position
		to = Vector3.new(to.X, 0, to.Z)
		if to.Magnitude > 1e-3 then
			facing = targetHRP.CFrame.LookVector:Dot(to.Unit) >= math.cos(math.rad(BLOCK_CONE_DEG))
		end
	end

	if claimedGuard and guardUp and facing then
		if (target:GetAttribute("ParryUntil") or 0) > now then
			-- PARRY: attacker punished, defender gets a riposte
			setAttr("StunnedUntil", now + PARRY_PUNISH_STUN)
			target:SetAttribute("FastUntil", now + RIPOSTE_DURATION)
			target:SetAttribute("BlockMeter", math.max(0, (target:GetAttribute("BlockMeter") or BLOCK_MAX) - PARRY_COST))
			cancelSwing("parried")
			tell("Parried")
			dprint("PARRIED by", target.Name)
		else
			-- BLOCK: drains defender stamina; empty = guard broken
			local m = (target:GetAttribute("BlockMeter") or BLOCK_MAX) - info.blockCost
			if m <= 0 then
				target:SetAttribute("BlockMeter", 0)
				target:SetAttribute("Blocking", false)
				target:SetAttribute("StunnedUntil", now + BLOCK_BREAK_STUN)
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
	if region == "head" and HEAD_ONESHOT then
		hum:TakeDamage(hum.MaxHealth)
		dprint("HEADSHOT on", target.Name)
	else
		hum:TakeDamage(info.damage)
		if region == "legs" then knockdown(hum) end
		dprint("hit", target.Name, region, info.damage)
	end
	tell("HitConfirm", region)
end

local function onHitReport(token, model, part, hitPos, claimedGuard)
	local now = os.clock()
	if not character or token ~= state.token or not state.attack then dprint("hit rejected: stale swing"); return end
	if now < state.windupEnd - 0.05 or now > state.releaseEnd + HIT_GRACE then dprint("hit rejected: outside release"); return end
	if typeof(model) ~= "Instance" or not model:IsA("Model") or model == character then return end
	if typeof(part) ~= "Instance" or not part:IsA("BasePart") or not part:IsDescendantOf(model) then return end
	if typeof(hitPos) ~= "Vector3" then return end
	local hum = model:FindFirstChildOfClass("Humanoid")
	if not hum or hum.Health <= 0 or state.alreadyHit[hum] then return end
	local hrp = character:FindFirstChild("HumanoidRootPart")
	if not hrp then return end
	if (hrp.Position - hitPos).Magnitude > REACH + REACH_TOLERANCE then dprint("hit rejected: out of reach"); return end
	if (part.Position - hitPos).Magnitude > part.Size.Magnitude * 0.5 + 2 then dprint("hit rejected: point not on part"); return end
	state.alreadyHit[hum] = true
	resolveHit(hum, model, part, hitPos, claimedGuard == true)
end

--------------------------------------------------------------------
--  ATTACKS
--------------------------------------------------------------------
local function startAttack(name)
	local info = ATTACKS[name]
	if not info then return end
	local now = os.clock()

	local speed = (info.speed or 1) * SPEED_MULT
	if (attr("FastUntil") or 0) > now then speed = speed * RIPOSTE_SPEED end
	local windup   = math.max(MIN_PHASE, info.windup   / speed)
	local active   = math.max(MIN_PHASE, info.active   / speed)
	local recovery = math.max(MIN_PHASE, info.recovery / speed)

	state.token += 1
	local token = state.token
	state.attack, state.attackName, state.alreadyHit, state.queued = info, name, {}, nil
	state.phase      = "windup"
	state.windupEnd  = now + windup
	state.releaseEnd = now + windup + active
	state.nextActionTime = now + windup + active + recovery
	spend(info.staminaCost or 0)

	setAttr("Swinging", true)
	setAttr("SwingSlow", SWING_SLOW)
	local cap = windup + active + TURN_CAP_EXTRA
	setAttr("TurnCapUntil", now + cap)

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
		setAttr("Swinging", false)
	end)

	dprint("attack ->", name, string.format("speed %.2f | windup %.2f release %.2f recovery %.2f", speed, windup, active, recovery))
	tell("PlayAttack", info.anim, speed, windup, active, cap, token)
end

local function doAttack(name)
	if not character or not ATTACKS[name] then return end
	if isStunned()      then dprint("attack denied: stunned");  return end
	if attr("Blocking") then dprint("attack denied: blocking"); return end
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
	state.cycleIndex = (state.cycleIndex % #CYCLE_ORDER) + 1
	doAttack(CYCLE_ORDER[state.cycleIndex])
end

--------------------------------------------------------------------
--  BLOCK / FEINT
--------------------------------------------------------------------
local function doBlockStart()
	if not character or isStunned() then return end
	local now = os.clock()
	if state.phase == "windup" then
		-- feint-to-parry: cancel the windup and raise guard in one motion
		if stamina() < FEINT_COST then dprint("feint denied: stamina"); return end
		spend(FEINT_COST)
		cancelSwing("feint")
		state.nextActionTime = now + FEINT_RECOVERY
	elseif state.phase == "release" or state.phase == "kick" then
		dprint("block denied: committed"); return
	end
	if attr("Blocking") then return end
	setAttr("Blocking", true)
	if now - state.lastBlockStart >= PARRY_RETRY then
		setAttr("ParryUntil", now + PARRY_WINDOW)
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

--------------------------------------------------------------------
--  KICK
--------------------------------------------------------------------
local function resolveKick()
	local hrp = character and character:FindFirstChild("HumanoidRootPart")
	if not hrp then return end
	local cosCone = math.cos(math.rad(KICK_CONE_DEG))
	local now = os.clock()
	eachTarget(function(m)
		local hum, thrp = m:FindFirstChildOfClass("Humanoid"), m:FindFirstChild("HumanoidRootPart")
		if not (hum and thrp and hum.Health > 0) then return end
		local to = thrp.Position - hrp.Position
		to = Vector3.new(to.X, 0, to.Z)
		if to.Magnitude > KICK_RANGE or to.Magnitude < 1e-3 then return end
		if hrp.CFrame.LookVector:Dot(to.Unit) < cosCone then return end
		if m:GetAttribute("Blocking") then
			m:SetAttribute("Blocking", false)
			m:SetAttribute("StunnedUntil", now + KICK_STAGGER)
			m:SetAttribute("BlockMeter", math.max(0, (m:GetAttribute("BlockMeter") or BLOCK_MAX) - KICK_BLOCK_DRAIN))
			dprint("KICK staggered", m.Name)
		else
			hum:TakeDamage(KICK_DAMAGE)
			dprint("kick hit", m.Name)
		end
		tell("HitConfirm", "kick")
	end)
end

local function doKick()
	if not character or isStunned() or attr("Blocking") then return end
	local now = os.clock()
	if state.phase ~= "idle" or now < state.nextActionTime then dprint("kick denied: busy"); return end
	state.token += 1
	local token = state.token
	state.attack, state.attackName, state.phase = nil, nil, "kick"
	state.nextActionTime = now + KICK_WINDUP + KICK_RECOVERY
	spend(KICK_COST)
	setAttr("Swinging", true)
	setAttr("SwingSlow", SWING_SLOW)
	setAttr("TurnCapUntil", now + KICK_WINDUP + TURN_CAP_EXTRA)
	tell("PlayKick", KICK_WINDUP + TURN_CAP_EXTRA, KICK_WINDUP)
	task.delay(KICK_WINDUP, function()
		if state.token ~= token then return end
		if not isStunned() then resolveKick() end
	end)
	task.delay(KICK_WINDUP + KICK_RECOVERY, function()
		if state.token ~= token then return end
		state.phase = "idle"
		setAttr("Swinging", false)
	end)
end

--------------------------------------------------------------------
--  WIRING
--------------------------------------------------------------------
remote.OnServerEvent:Connect(function(who, action, a, b, c, d, e)
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
end)

Tool.Equipped:Connect(function()
	character = Tool.Parent
	player    = Players:GetPlayerFromCharacter(character)
	humanoid  = character:FindFirstChildOfClass("Humanoid")
	dprint("equipped by", player and player.Name)
	if not humanoid then warn("[Pitchfork/Server] no Humanoid on equip"); return end
	if character:GetAttribute("BlockMeter") == nil then
		character:SetAttribute("BlockMeter", BLOCK_MAX)
	end
	character:SetAttribute("Blocking", false)
	setGuard(false)
	-- any script that lowers our Blocking attribute (block break, kick,
	-- parry) also lowers the hull and stamps the release time for lag grace
	if blockConn then blockConn:Disconnect() end
	local char = character
	blockConn = char:GetAttributeChangedSignal("Blocking"):Connect(function()
		local on = char:GetAttribute("Blocking") == true
		setGuard(on)
		if not on then char:SetAttribute("BlockStoppedAt", os.clock()) end
	end)
	tell("Setup", IDLE_ID, BLOCK_ID)
end)

Tool.Unequipped:Connect(function()
	dprint("unequipped")
	if state.phase ~= "idle" then cancelSwing("unequipped") end
	doBlockStop()
	setAttr("Swinging", false)
	setGuard(false)
	if blockConn then blockConn:Disconnect(); blockConn = nil end
	tell("Cleanup")
	character = nil
end)

RunService.Heartbeat:Connect(function(dt)
	if not character or isStunned() or attr("Blocking") then return end
	local m = stamina()
	if m < BLOCK_MAX then
		setAttr("BlockMeter", math.min(BLOCK_MAX, m + BLOCK_REGEN * dt))
	end
end)
