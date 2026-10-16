--[[ LOCK-ON and AIM ASSIST — for thumbs and sticks (and the middle mouse, for anyone).

     LOCK-ON: the foe nearest the middle of your view (within RANGE) is locked: your camera and
     your body turn to keep them in front of you (CameraRig asks LockOn.steer each frame, before
     the swing's turn cap, so a lock never turns you faster than a swing allows); a reticle marks
     them (StarterPlayerScripts ▸ LockOn). It lets go when they fall, vanish, hide or get past
     LOST_AT. Flick the stick, or swipe, to move it to the next foe that way.

     AIM ASSIST (touch and controller, the Aim assist setting): no lock, but as you attack the
     nearest foe close in front of you (ASSIST_RANGE, within ASSIST_CONE) draws your aim toward
     them, gently, for the moment the swing is coming.

       LockOn.target                 the locked model, or nil
       LockOn.lock(model|nil)        LockOn.toggle()     LockOn.cycle(dir: -1 left, 1 right)
       LockOn.attacked()             an attack was pressed (the assist's moment)
       LockOn.steer(dt, from, yaw, pitch, assist) -> dYaw, dPitch     (CameraRig)
       LockOn.changed                :Connect(fn(model|nil)) ]]

local Players = game:GetService("Players")

local LockOn = {}
local ev = Instance.new("BindableEvent")
LockOn.changed = ev.Event
LockOn.target = nil

local RANGE, LOST_AT = 45, 60
local VIEW_CONE = math.rad(38)        -- (a lock is offered to what's near the middle of your view…)
local NEAR = 14                       -- (…or, failing that, to anyone this close)
local ASSIST_RANGE, ASSIST_CONE, ASSIST_FOR = 11, math.rad(55), 0.55
local attackAt = -1

local function rootOf(m) return m and (m:FindFirstChild("HumanoidRootPart") or m.PrimaryPart) end
local function me() return Players.LocalPlayer.Character end

-- may this one be locked onto (or drawn to)?
function LockOn.valid(m)
	local c = me()
	if not (m and m.Parent and c and m ~= c) then return false end
	local hum = m:FindFirstChildOfClass("Humanoid")
	if not (hum and hum.Health > 0) or m:GetAttribute("Ragdolled") then return false end
	if m:GetAttribute("Instructor") then return false end   -- (the yard's teachers)
	local team = c:GetAttribute("Team")
	if team and team ~= "" and m:GetAttribute("Team") == team then return false end
	if (m:GetAttribute("HiddenUntil") or 0) > workspace:GetServerTimeNow() then return false end
	return rootOf(m) ~= nil
end

local function candidates()
	local out = {}
	for _, p in ipairs(Players:GetPlayers()) do
		if p.Character and LockOn.valid(p.Character) then table.insert(out, p.Character) end
	end
	local npcs = workspace:FindFirstChild("NPCs")
	if npcs then for _, m in ipairs(npcs:GetChildren()) do if m:IsA("Model") and LockOn.valid(m) then table.insert(out, m) end end end
	return out
end

function LockOn.lock(m)
	if m == LockOn.target then return end
	LockOn.target = m
	ev:Fire(m)
end

-- the best foe to lock: near the middle of the view, else simply near
function LockOn.pick()
	local c = me()
	local cr = rootOf(c)
	local cam = workspace.CurrentCamera
	if not (cr and cam) then return nil end
	local look = cam.CFrame.LookVector
	local best, bestScore
	for _, m in ipairs(candidates()) do
		local r = rootOf(m)
		local d = r.Position - cr.Position
		local dist = d.Magnitude
		if dist <= RANGE then
			local toward = (r.Position - cam.CFrame.Position)
			local ang = math.acos(math.clamp(look:Dot(toward.Unit), -1, 1))
			local score
			if ang <= VIEW_CONE then score = ang * 30 + dist
			elseif dist <= NEAR then score = 200 + dist end
			if score and (not bestScore or score < bestScore) then best, bestScore = m, score end
		end
	end
	return best
end

function LockOn.toggle()
	if LockOn.target then LockOn.lock(nil) else LockOn.lock(LockOn.pick()) end
	return LockOn.target
end

-- the next foe to the left (-1) or the right (1) of the one locked, as you see them
function LockOn.cycle(dir)
	local cam = workspace.CurrentCamera
	local cr = rootOf(me())
	if not (cam and cr) then return end
	local cur = LockOn.target
	local function side(m)
		local p = cam.CFrame:PointToObjectSpace(rootOf(m).Position)
		return math.atan2(p.X, -p.Z)
	end
	local from = cur and side(cur) or 0
	local best, bestD
	for _, m in ipairs(candidates()) do
		if m ~= cur and (rootOf(m).Position - cr.Position).Magnitude <= RANGE then
			local d = (side(m) - from) * dir
			if d > 0.02 and (not bestD or d < bestD) then best, bestD = m, d end
		end
	end
	if best then LockOn.lock(best) end
end

function LockOn.attacked() attackAt = os.clock() end

local function wrap(a) return (a + math.pi) % (2 * math.pi) - math.pi end
-- the turn toward where `to` is, from `from`, as a yaw / pitch (CameraRig's: yaw = atan2(-x, -z))
local function anglesTo(from, to)
	local d = to - from
	return math.atan2(-d.X, -d.Z), math.atan2(d.Y, Vector2.new(d.X, d.Z).Magnitude)
end

function LockOn.steer(dt, from, yaw, pitch, assist)
	local t = LockOn.target
	if t and not LockOn.valid(t) then LockOn.lock(nil); t = nil end
	if t then
		local r = rootOf(t)
		if (r.Position - from).Magnitude > LOST_AT then LockOn.lock(nil); return 0, 0 end
		local wy, wp = anglesTo(from, r.Position + Vector3.new(0, 0.4, 0))
		local k = 1 - math.exp(-dt * 11)
		-- (pitch: most of the way, so the floor or the sky never fills the view)
		return wrap(wy - yaw) * k, (math.clamp(wp * 0.75, -0.6, 0.5) - pitch) * k * 0.6
	end
	-- the assist: only while an attack is coming, only what's close and in front
	if not assist or os.clock() - attackAt > ASSIST_FOR then return 0, 0 end
	local best, bestA
	for _, m in ipairs(candidates()) do
		local r = rootOf(m)
		local d = r.Position - from
		if Vector2.new(d.X, d.Z).Magnitude <= ASSIST_RANGE then
			local wy = anglesTo(from, r.Position)
			local a = math.abs(wrap(wy - yaw))
			if a <= ASSIST_CONE and (not bestA or a < bestA) then best, bestA = m, a end
		end
	end
	if not best then return 0, 0 end
	local wy = anglesTo(from, rootOf(best).Position)
	return wrap(wy - yaw) * (1 - math.exp(-dt * 7)), 0
end

return LockOn
