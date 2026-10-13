--[[ SHOWCASE (client) — the director's camera for a staff showcase (Game ▸ Showcase): the
     menus hide (CleanView) and the camera films the match by itself, cutting every few
     seconds to wherever the fighting is thickest, in a mix of shots:
       orbit   circling a fighter
       hero    low and in front, looking up at them
       follow  behind them, over the shoulder
       aerial  high above the whole fight, turning slowly
     A duel circles the two; the Courtyard tour glides through the map's own camera shots;
     the armor parade visits each mannequin with a slow push-in, then sweeps the line.
     A new map opens with a glide through its establishing shots.

     Keys while it runs (no buttons on screen: it's being filmed):
       1 auto · 2 orbit · 3 hero · 4 follow · 5 aerial     Q / E  the previous / next fighter
       N  the next map now (a battle)      Ctrl+Shift+X  stop (the panel's STOP too)
     They're taken ahead of everything else while it runs (the weapon bar's 1 and 2, E's
     prompts): the one filming has no body to use them. ]]

local Players           = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService        = game:GetService("RunService")
local UserInputService  = game:GetService("UserInputService")
local ContextActionService = game:GetService("ContextActionService")

-- (the server makes it the first time staff open a showcase: however long that takes)
local remote = ReplicatedStorage:WaitForChild("ShowcaseRemote", math.huge)
local player = Players.LocalPlayer
local round = ReplicatedStorage:WaitForChild("Round")

local BIND = "ShowcaseCam"
local active, info, parade = false, nil, nil
local style = "auto"
local subject, shot, shotEnds, angle, diedAt = nil, "orbit", 0, 0, nil
local camPos, camLook, fov, cut = nil, nil, 60, true
local started, estUntil, lastMap, lastSend = 0, 0, nil, 0

local function ease(t) t = math.clamp(t, 0, 1); return t * t * (3 - 2 * t) end

local function alive(m)
	if not (m and m.Parent) then return false end
	local h = m:FindFirstChildOfClass("Humanoid")
	return h ~= nil and h.Health > 0 and m:FindFirstChild("HumanoidRootPart") ~= nil
end
local function fighters()
	local out = {}
	local npcs = workspace:FindFirstChild("NPCs")
	for _, m in ipairs(npcs and npcs:GetChildren() or {}) do if m:IsA("Model") and alive(m) then table.insert(out, m) end end
	for _, p in ipairs(Players:GetPlayers()) do if p ~= player and alive(p.Character) then table.insert(out, p.Character) end end
	return out
end
local function posOf(m) return m.HumanoidRootPart.Position end

-- where the action is: foes close by, and (Bows & Spells) the casters and archers
local function score(m, list)
	local pos, team = posOf(m), m:GetAttribute("Team")
	local near, closest = 0, math.huge
	for _, o in ipairs(list) do
		if o ~= m and (team == nil or o:GetAttribute("Team") ~= team) then
			local d = (posOf(o) - pos).Magnitude
			if d < 12 then near += 1 end
			closest = math.min(closest, d)
		end
	end
	local s = near * 2 + (closest < 8 and 1.5 or 0) + math.random() * 0.8
	local cls = m:GetAttribute("Class")
	if info and info.prefer == "class" and (cls == "Archer" or cls == "Mage") then s += 2.5 end
	return s
end

local function newShot()
	if style ~= "auto" then
		shot = style
	else
		local r = math.random()
		shot = r < 0.34 and "orbit" or (r < 0.6 and "hero" or (r < 0.85 and "follow" or "aerial"))
	end
	angle = math.random() * math.pi * 2
	shotEnds = os.clock() + (shot == "aerial" and 5 or (4 + math.random() * 3))
	cut = true
end
local function pickSubject(step)
	local list = fighters()
	if #list == 0 then subject = nil; return end
	if step and subject then
		table.sort(list, function(a, b) return a.Name < b.Name end)
		local i = table.find(list, subject) or 0
		subject = list[(i - 1 + step) % #list + 1]
	else
		local best, bestS = nil, -1
		for _, m in ipairs(list) do
			if m ~= subject or #list == 1 then
				local s = score(m, list)
				if s > bestS then best, bestS = m, s end
			end
		end
		subject = best
	end
	diedAt = nil
	newShot()
end

-- the map's own establishing shots (MapLoader puts them on the Map as Shot1, Shot2…)
local function mapShots()
	local map = workspace:FindFirstChild("Map")
	local out = {}
	if map then
		local i = 1
		while map:GetAttribute("Shot" .. i) do table.insert(out, map:GetAttribute("Shot" .. i)); i += 1 end
	end
	return out, map
end
local function tourCF(t)
	local shots, map = mapShots()
	if #shots >= 2 then
		local seg = 7
		local k = math.floor(t / seg) % #shots
		return shots[k + 1]:Lerp(shots[(k + 1) % #shots + 1], ease((t % seg) / seg))
	end
	local c = map and map:GetAttribute("Centre") or Vector3.zero
	local r = (map and map:GetAttribute("Radius") or 60) * 0.8
	local a = t * 0.06
	return CFrame.lookAt(c + Vector3.new(math.cos(a) * r, r * 0.45, math.sin(a) * r), c)
end

-- one shot of a fighter: where the camera stands, what it looks at, its field of view
local function aim(m, dt)
	local hrp = m.HumanoidRootPart
	local P = hrp.Position
	local F = hrp.CFrame.LookVector
	F = Vector3.new(F.X, 0, F.Z)
	F = F.Magnitude > 0.01 and F.Unit or Vector3.zAxis
	local side = F:Cross(Vector3.yAxis)
	if shot == "hero" then
		return P + F * 7 + side * 2.6 + Vector3.new(0, 0.4, 0), P + Vector3.new(0, 2.4, 0), 50
	elseif shot == "follow" then
		return P - F * 11 + Vector3.new(0, 5, 0), P + F * 5 + Vector3.new(0, 1.5, 0), 62
	elseif shot == "aerial" then
		local c, n = Vector3.zero, 0
		for _, o in ipairs(fighters()) do
			local q = posOf(o)
			if (q - P).Magnitude < 40 then c += q; n += 1 end
		end
		c = n > 0 and c / n or P
		angle += dt * 0.08
		return c + Vector3.new(math.cos(angle) * 34, 24, math.sin(angle) * 34), c, 55
	end
	angle += dt * 0.32
	return P + Vector3.new(math.cos(angle) * 11, 4.2, math.sin(angle) * 11), P + Vector3.new(0, 1.2, 0), 58
end

local function duelAim(dt)
	local list = fighters()
	local a, b = list[1], list[2]
	if not (a and b) then return nil end
	if shot == "hero" and subject and alive(subject) then return aim(subject, dt) end
	local pa, pb = posOf(a), posOf(b)
	local M = (pa + pb) / 2
	local r = math.max(9, (pa - pb).Magnitude * 0.8 + 6)
	angle += dt * 0.28
	return M + Vector3.new(math.cos(angle) * r, 3.6, math.sin(angle) * r), M + Vector3.new(0, 1.4, 0), 55
end

local function paradeAim(t)
	local n = parade and #parade or 0
	if n == 0 then return nil end
	local each, sweep = 4, 9
	local cycle = n * each + sweep
	local u = t % cycle
	if u < n * each then
		local i = math.floor(u / each) + 1
		local k = (u % each) / each
		if k < 0.02 then cut = true end
		local m = parade[i]
		local side = m.look:Cross(Vector3.yAxis)
		local d = 7 - 1.8 * ease(k)
		return m.pos + m.look * d + side * 1.4 + Vector3.new(0, 0.4, 0), m.pos + Vector3.new(0, 1.7, 0), 48
	end
	local k = ease((u - n * each) / sweep)
	local first, last = parade[1], parade[n]
	if k < 0.02 then cut = true end
	local along = first.pos:Lerp(last.pos, k)
	return along + first.look * 13 + Vector3.new(0, 3.5, 0), along + Vector3.new(0, 1.5, 0), 60
end

-- (never through a wall: the camera comes in front of whatever's between)
local rayParams = RaycastParams.new()
rayParams.FilterType = Enum.RaycastFilterType.Exclude
local function unblock(look, pos)
	local ignore = {}
	local npcs = workspace:FindFirstChild("NPCs")
	if npcs then table.insert(ignore, npcs) end
	for _, p in ipairs(Players:GetPlayers()) do if p.Character then table.insert(ignore, p.Character) end end
	for _, m in ipairs(workspace:GetChildren()) do if m:GetAttribute("Mannequin") then table.insert(ignore, m) end end
	rayParams.FilterDescendantsInstances = ignore
	local d = pos - look
	local hit = d.Magnitude > 0.1 and workspace:Raycast(look, d, rayParams)
	return hit and (hit.Position - d.Unit * 0.6) or pos
end

local function step(dt)
	local cam = workspace.CurrentCamera
	if not cam then return end
	local now = os.clock()
	local t = now - started
	local tp, tl, tf
	local map = round:GetAttribute("Map")
	if map ~= lastMap then
		lastMap = map
		if #mapShots() >= 2 and info and info.shots ~= "tour" and info.shots ~= "parade" then estUntil = now + 5; cut = true end
	end
	if info.shots == "tour" or (info.shots == "parade" and not parade) then
		local cf = tourCF(t)
		tp, tl, tf = cf.Position, cf.Position + cf.LookVector * 20, 60
	elseif info.shots == "parade" then
		tp, tl, tf = paradeAim(t)
	elseif now < estUntil or round:GetAttribute("State") ~= "Round" or #fighters() == 0 then
		local cf = tourCF(t)
		tp, tl, tf = cf.Position, cf.Position + cf.LookVector * 20, 60
	else
		if not (subject and alive(subject)) then
			diedAt = diedAt or now
			if now - diedAt > 1.5 or not subject or not subject.Parent then pickSubject() end
		elseif now > shotEnds then
			if info.shots == "duel" then
				local list = fighters()
				subject = (list[1] == subject) and list[2] or list[1]
				newShot()
			else
				pickSubject()
			end
		end
		if info.shots == "duel" then tp, tl, tf = duelAim(dt) end
		if not tp and subject and subject:FindFirstChild("HumanoidRootPart") then tp, tl, tf = aim(subject, dt) end
		if not tp then
			local cf = tourCF(t)
			tp, tl, tf = cf.Position, cf.Position + cf.LookVector * 20, 60
		end
	end
	tp = unblock(tl, tp)
	local kp = cut and 1 or (1 - math.exp(-dt * 3.2))
	local kl = cut and 1 or (1 - math.exp(-dt * 5))
	camPos = camPos and camPos:Lerp(tp, kp) or tp
	camLook = camLook and camLook:Lerp(tl, kl) or tl
	fov = fov + (tf - fov) * math.clamp(dt * 3, 0, 1)
	cut = false
	cam.CameraType = Enum.CameraType.Scriptable
	cam.CFrame = CFrame.lookAt(camPos, camLook)
	cam.FieldOfView = fov
	UserInputService.MouseIconEnabled = false   -- (no cursor in the footage)
	-- (the world streams in round the camera)
	if now - lastSend > 0.4 then lastSend = now; remote:FireServer("Cam", camPos) end
end

-- THE KEYS (taken first, ahead of the weapon bar and the prompts)
local STYLE = {[Enum.KeyCode.One] = "auto", [Enum.KeyCode.Two] = "orbit", [Enum.KeyCode.Three] = "hero", [Enum.KeyCode.Four] = "follow", [Enum.KeyCode.Five] = "aerial"}
local KEYS = {Enum.KeyCode.One, Enum.KeyCode.Two, Enum.KeyCode.Three, Enum.KeyCode.Four, Enum.KeyCode.Five, Enum.KeyCode.Q, Enum.KeyCode.E, Enum.KeyCode.N, Enum.KeyCode.X}
local function onKey(_, inputState, input)
	if inputState ~= Enum.UserInputState.Begin or UserInputService:GetFocusedTextBox() then return Enum.ContextActionResult.Pass end
	local k = input.KeyCode
	local ctrl = UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) or UserInputService:IsKeyDown(Enum.KeyCode.RightControl)
	local shift = UserInputService:IsKeyDown(Enum.KeyCode.LeftShift) or UserInputService:IsKeyDown(Enum.KeyCode.RightShift)
	if k == Enum.KeyCode.X then
		if not (ctrl and shift) then return Enum.ContextActionResult.Pass end
		remote:FireServer("Stop")
	elseif STYLE[k] then style = STYLE[k]; newShot(); estUntil = 0
	elseif k == Enum.KeyCode.Q then pickSubject(-1)
	elseif k == Enum.KeyCode.E then pickSubject(1)
	elseif k == Enum.KeyCode.N then remote:FireServer("NextMap") end
	return Enum.ContextActionResult.Sink
end

local function start(i)
	info, parade = i, nil
	active = true
	started = os.clock()
	style, subject, camPos, camLook, cut, estUntil, lastMap = "auto", nil, nil, nil, true, 0, nil
	_G.ShowcaseActive = true
	if _G.SetCleanView then _G.SetCleanView(true) end
	pcall(function() RunService:UnbindFromRenderStep(BIND) end)
	RunService:BindToRenderStep(BIND, Enum.RenderPriority.Last.Value + 10, step)
	ContextActionService:BindActionAtPriority("ShowcaseKeys", onKey, false, 4000, table.unpack(KEYS))
end
local function stop()
	if not active then return end
	active = false
	pcall(function() RunService:UnbindFromRenderStep(BIND) end)
	ContextActionService:UnbindAction("ShowcaseKeys")
	_G.ShowcaseActive = false
	if _G.SetCleanView then _G.SetCleanView(false) end
	local cam = workspace.CurrentCamera
	if cam then cam.CameraType = Enum.CameraType.Custom; cam.FieldOfView = 70 end
	UserInputService.MouseIconEnabled = true
end

remote.OnClientEvent:Connect(function(what, data)
	if what == "Start" and type(data) == "table" then start(data)
	elseif what == "Parade" and type(data) == "table" then parade = data; started = os.clock(); cut = true
	elseif what == "Stop" then stop() end
end)
