--[[ SHOWCASE (client) — film the game. THE DIRECTOR (F4, or the admin panel's SHOWCASE tab)
     is one screen: 1 what to film, 2 set it up, 3 START FILMING.
       GENERATE        an autopilot: a new battle every few minutes on a new map
       CUSTOM BATTLE   the mode, the map, how many Squires / Knights / Champions / Archers / Mages
       the presets     a siege, a field battle, a free-for-all, bows & spells, a duel
       the Courtyard   a tour, the armor parade
     Bots look like real players unless that's switched off (Game ▸ Showcase dresses them).
     From a public server a battle opens a private filming server of your own and starts
     there by itself.

     While it runs the menus, prompts and name tags hide (CleanView, NameTags), you have no
     body, and the camera films the match by itself: it settles on wherever the fighting is
     thickest, holds each shot a good while, glides to the next when it's near and cuts only
     when it's far, follows a fighter's facing smoothly, eases in front of walls, and when its
     fighter falls it lingers a moment before moving on. The shots:
       orbit   circling a fighter
       hero    low and in front, looking up at them
       follow  behind them, over the shoulder
       aerial  high above the whole fight, turning slowly
     A duel circles the two; the Courtyard tour glides through the map's own camera shots;
     the armor parade visits each mannequin with a slow push-in, then sweeps the line.
     A new map opens with a glide through its establishing shots.

     TAB shows the control bar (and hides it again for a clean shot): the camera styles,
     the previous / next fighter, the next map (GENERATE: the next battle), a map to stay on
     (or rotate), the menu, stop. The keys work without it: 1 auto · 2 orbit · 3 hero ·
     4 follow · 5 aerial · Q / E fighter · N next · Ctrl+Shift+X stop. They're taken ahead of
     everything else while it runs (the weapon bar's 1 and 2, E's prompts). ]]

local Players           = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService        = game:GetService("RunService")
local UserInputService  = game:GetService("UserInputService")
local ContextActionService = game:GetService("ContextActionService")

-- (the server makes them as it starts: Admin ▸ AdminServer loads Game ▸ Showcase)
local remote = ReplicatedStorage:WaitForChild("ShowcaseRemote", math.huge)
local player = Players.LocalPlayer
local round = ReplicatedStorage:WaitForChild("Round")

local BIND = "ShowcaseCam"
local active, info, parade = false, nil, nil
local style = "auto"
local subject, shot, shotEnds, angle, diedAt, diedPos = nil, "orbit", 0, 0, nil, nil
local camPos, camLook, fov, cut = nil, nil, 60, true
local glideUntil = 0                 -- a gentle move to the next shot (no cut) lasts till then
local subjPos, subjFace = nil, nil   -- the fighter's position and facing, smoothed
local reach = 1                      -- how much of the shot's distance is clear of walls (smoothed)
local started, estUntil, lastMap, lastSend = 0, 0, nil, 0

local function ease(t) t = math.clamp(t, 0, 1); return t * t * (3 - 2 * t) end
local function damp(rate, dt) return 1 - math.exp(-rate * dt) end

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

-- where the action is: foes close by, and (Bows & Spells) the casters and archers; near where
-- the camera already is counts too (a glide, not a cut)
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
	if subjPos then s += math.max(0, 1 - (pos - subjPos).Magnitude / 50) * 2 end
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
	shotEnds = os.clock() + (shot == "aerial" and 9 or (7 + math.random() * 4))
	-- (near: a glide there; far, or nothing to glide from: a cut)
	glideUntil = os.clock() + 1.6
end
local function pickSubject(step)
	local list = fighters()
	if #list == 0 then subject = nil; return end
	local was = subject
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
	diedAt, diedPos = nil, nil
	newShot()
	-- far from where the camera is: cut (and the facing starts fresh)
	if subject and (not subjPos or (posOf(subject) - subjPos).Magnitude > 45) then
		cut, subjPos, subjFace = true, nil, nil
	elseif subject ~= was then
		subjFace = nil
	end
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
		local seg = 8
		local k = math.floor(t / seg) % #shots
		return shots[k + 1]:Lerp(shots[(k + 1) % #shots + 1], ease((t % seg) / seg))
	end
	local c = map and map:GetAttribute("Centre") or Vector3.zero
	local r = (map and map:GetAttribute("Radius") or 60) * 0.8
	local a = t * 0.05
	return CFrame.lookAt(c + Vector3.new(math.cos(a) * r, r * 0.45, math.sin(a) * r), c)
end

-- one shot of a fighter: where the camera stands, what it looks at, its field of view (from
-- the fighter's smoothed position and facing: a quick turn doesn't swing the camera)
local function aim(m, dt)
	local hrp = m.HumanoidRootPart
	local raw = hrp.CFrame.LookVector
	raw = Vector3.new(raw.X, 0, raw.Z)
	raw = raw.Magnitude > 0.01 and raw.Unit or Vector3.zAxis
	subjPos = subjPos and subjPos:Lerp(hrp.Position, damp(7, dt)) or hrp.Position
	subjFace = subjFace and subjFace:Lerp(raw, damp(1.3, dt)) or raw
	local F = subjFace.Magnitude > 0.01 and subjFace.Unit or raw
	local P = subjPos
	local side = F:Cross(Vector3.yAxis)
	if shot == "hero" then
		return P + F * 7.5 + side * 2.8 + Vector3.new(0, 0.6, 0), P + Vector3.new(0, 2.2, 0), 50
	elseif shot == "follow" then
		return P - F * 11 + side * 1.5 + Vector3.new(0, 5, 0), P + F * 5 + Vector3.new(0, 1.5, 0), 62
	elseif shot == "aerial" then
		local c, n = Vector3.zero, 0
		for _, o in ipairs(fighters()) do
			local q = posOf(o)
			if (q - P).Magnitude < 40 then c += q; n += 1 end
		end
		c = n > 0 and c / n or P
		angle += dt * 0.06
		return c + Vector3.new(math.cos(angle) * 34, 24, math.sin(angle) * 34), c, 55
	end
	angle += dt * 0.22
	return P + Vector3.new(math.cos(angle) * 11, 4.2, math.sin(angle) * 11), P + Vector3.new(0, 1.2, 0), 58
end

local function duelAim(dt)
	local list = fighters()
	local a, b = list[1], list[2]
	if not (a and b) then return nil end
	if shot == "hero" and subject and alive(subject) then return aim(subject, dt) end
	local M = (posOf(a) + posOf(b)) / 2
	subjPos = subjPos and subjPos:Lerp(M, damp(5, dt)) or M
	local r = math.max(9, (posOf(a) - posOf(b)).Magnitude * 0.8 + 6)
	angle += dt * 0.2
	return subjPos + Vector3.new(math.cos(angle) * r, 3.6, math.sin(angle) * r), subjPos + Vector3.new(0, 1.4, 0), 55
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

-- (never through a wall: the camera comes in front of whatever's between, quickly, and eases
-- back out once it's clear, so a post going by doesn't make it jump)
local rayParams = RaycastParams.new()
rayParams.FilterType = Enum.RaycastFilterType.Exclude
local function unblock(look, pos, dt, snap)
	local ignore = {}
	local npcs = workspace:FindFirstChild("NPCs")
	if npcs then table.insert(ignore, npcs) end
	for _, p in ipairs(Players:GetPlayers()) do if p.Character then table.insert(ignore, p.Character) end end
	for _, m in ipairs(workspace:GetChildren()) do if m:GetAttribute("Mannequin") then table.insert(ignore, m) end end
	rayParams.FilterDescendantsInstances = ignore
	local d = pos - look
	local len = d.Magnitude
	if len < 0.1 then return pos end
	-- (a ball, not a thin ray: hedges, railings and the edge of a pillar count)
	local hit = workspace:Spherecast(look, 0.7, d, rayParams)
	local want = hit and math.clamp((hit.Distance - 0.8) / len, 0.15, 1) or 1
	if snap then reach = want
	elseif want < reach then reach += (want - reach) * damp(12, dt)
	else reach += (want - reach) * damp(1.6, dt) end
	return look + d * reach
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
		subjPos, subjFace = nil, nil
		if #mapShots() >= 2 and info and info.shots ~= "tour" and info.shots ~= "parade" then estUntil = now + 6; cut = true end
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
		if subject and not alive(subject) then
			-- it fell: stay on it a moment, then on to the next
			diedAt = diedAt or now
			diedPos = diedPos or subjPos
			if now - diedAt > 2.2 or not subject.Parent then pickSubject() end
		elseif not subject then
			pickSubject()
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
		if not tp and subject and diedAt and diedPos then
			-- (the fall, from where the camera already was)
			tp, tl, tf = camPos or (diedPos + Vector3.new(8, 5, 8)), diedPos + Vector3.new(0, 0.5, 0), fov
		end
		if not tp and subject and subject:FindFirstChild("HumanoidRootPart") then tp, tl, tf = aim(subject, dt) end
		if not tp then
			local cf = tourCF(t)
			tp, tl, tf = cf.Position, cf.Position + cf.LookVector * 20, 60
		end
	end
	tp = unblock(tl, tp, dt, cut)
	-- steady: a slow, smooth follow; a glide to a new shot slower still; a far one a cut
	local gliding = now < glideUntil
	local kp = cut and 1 or damp(gliding and 1.4 or 2.4, dt)
	local kl = cut and 1 or damp(gliding and 2 or 3.4, dt)
	camPos = camPos and camPos:Lerp(tp, kp) or tp
	camLook = camLook and camLook:Lerp(tl, kl) or tl
	-- (where the camera really is after the smoothing: a glide never passes through a wall, a
	-- pillar or a hedge; it's brought out in front of it)
	do
		local d = camPos - camLook
		if d.Magnitude > 0.5 then
			local hit = workspace:Spherecast(camLook, 0.6, d, rayParams)
			if hit then camPos = camLook + d.Unit * math.max(1.5, hit.Distance - 0.4) end
		end
	end
	fov = fov + (tf - fov) * damp(1.5, dt)
	cut = false
	cam.CameraType = Enum.CameraType.Scriptable
	cam.CFrame = CFrame.lookAt(camPos, camLook)
	cam.FieldOfView = fov
	-- (the world streams in round the camera)
	if now - lastSend > 0.4 then lastSend = now; remote:FireServer("Cam", camPos) end
end

--------------------------------------------------------------------
--  THE DIRECTOR: one screen to film the game (staff with the showcase permission)
--------------------------------------------------------------------
local Theme = require(ReplicatedStorage:WaitForChild("Theme"))
local infoFn = ReplicatedStorage:WaitForChild("ShowcaseInfo", math.huge)
local admin = ReplicatedStorage:WaitForChild("AdminRemote", math.huge)
local WHITE = Color3.new(1, 1, 1)

local gui = Instance.new("ScreenGui")
gui.Name = "ShowcaseDirector"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = true
gui.DisplayOrder = 9600
gui:SetAttribute("CleanViewKeep", true)   -- (CleanView leaves it: it hides itself while you film)
gui.Parent = player:WaitForChild("PlayerGui")

local function corner(o, r) local c = Instance.new("UICorner"); c.CornerRadius = UDim.new(0, r or 10); c.Parent = o end
local function outline(o, th, tr) local s = Instance.new("UIStroke"); s.Color = WHITE; s.Thickness = th or 1.5; s.Transparency = tr or 0.85; s.ApplyStrokeMode = Enum.ApplyStrokeMode.Border; s.Parent = o; return s end
local function text(parent, t, size, color, font)
	local l = Instance.new("TextLabel")
	l.BackgroundTransparency = 1
	l.Font = font or Theme.FONT
	l.TextSize = size or 14
	l.TextColor3 = color or WHITE
	l.TextWrapped = true
	l.TextXAlignment = Enum.TextXAlignment.Left
	l.Text = t or ""
	l.Parent = parent
	local s = Instance.new("UIStroke"); s.Color = Theme.OUTLINE; s.Thickness = (size or 14) >= 24 and 2.2 or 1.4; s.Parent = l
	return l
end
local function btn(parent, t, color, size, pos, textSize)
	local b = Instance.new("TextButton")
	b.Text = t
	b.Font = Theme.FONT
	b.TextSize = textSize or 16
	b.TextColor3 = WHITE
	b.TextWrapped = true
	b.AutoButtonColor = true
	b.BackgroundColor3 = color or Theme.GLASS2
	b.Size = size or UDim2.new()
	if pos then b.Position = pos end
	b.Parent = parent
	corner(b, 10)
	local s = Instance.new("UIStroke"); s.ApplyStrokeMode = Enum.ApplyStrokeMode.Contextual; s.Color = Theme.OUTLINE; s.Thickness = 1.4; s.Parent = b
	return b
end
local function scaleOf(frame, w, h)
	local sc = Instance.new("UIScale"); sc.Parent = frame
	local function fit()
		local cam = workspace.CurrentCamera
		local vs = cam and cam.ViewportSize or Vector2.new(1600, 900)
		sc.Scale = math.clamp(math.min((vs.X - 32) / w, (vs.Y - 32) / h), 0.45, 1.15)
	end
	fit()
	if workspace.CurrentCamera then workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(fit) end
end

-- THE MENU
local menu = Instance.new("Frame")
menu.Name = "Menu"
menu.AnchorPoint = Vector2.new(0.5, 0.5)
menu.Position = UDim2.fromScale(0.5, 0.5)
menu.Size = UDim2.fromOffset(1040, 700)
menu.BackgroundColor3 = Theme.PANEL
menu.BackgroundTransparency = 0.03
menu.Active = true
menu.Visible = false
menu.Parent = gui
corner(menu, 18); outline(menu, 2, 0.8)
scaleOf(menu, 1040, 700)
do
	local t = text(menu, "FILM THE GAME", 34, WHITE, Theme.FONT_TITLE); t.Position = UDim2.fromOffset(28, 16); t.Size = UDim2.new(1, -120, 0, 42)
	local s = text(menu, "Pick what to film, set it up, press START FILMING, then start your recorder (Win+Alt+R, or OBS). Bots fight a real match and the camera films it by itself.", 15, Theme.DIM, Theme.FONT_BODY)
	s.Position = UDim2.fromOffset(28, 60); s.Size = UDim2.new(1, -120, 0, 40)
end
local closeB = btn(menu, "X", Theme.RED, UDim2.fromOffset(48, 44), UDim2.new(1, -66, 0, 18), 20)
local h1 = text(menu, "1   WHAT TO FILM", 20, Theme.ACCENT, Theme.FONT_TITLE); h1.Position = UDim2.fromOffset(28, 110); h1.Size = UDim2.fromOffset(440, 26)
local h2 = text(menu, "2   SET IT UP", 20, Theme.ACCENT, Theme.FONT_TITLE); h2.Position = UDim2.fromOffset(500, 110); h2.Size = UDim2.fromOffset(510, 26)
local function scroller(pos, size)
	local f = Instance.new("ScrollingFrame")
	f.BackgroundTransparency = 1; f.BorderSizePixel = 0
	f.Position, f.Size = pos, size
	f.CanvasSize = UDim2.new(); f.AutomaticCanvasSize = Enum.AutomaticSize.Y
	f.ScrollBarThickness = 6; f.ScrollingDirection = Enum.ScrollingDirection.Y
	f.Parent = menu
	local l = Instance.new("UIListLayout"); l.Padding = UDim.new(0, 8); l.SortOrder = Enum.SortOrder.LayoutOrder; l.Parent = f
	return f
end
local whatList = scroller(UDim2.fromOffset(28, 142), UDim2.fromOffset(452, 440))
local setList = scroller(UDim2.fromOffset(500, 142), UDim2.fromOffset(512, 440))
local goB = btn(menu, "▶   START FILMING", Theme.GREEN, UDim2.fromOffset(360, 66), UDim2.new(0, 28, 1, -94), 26)
goB.Font = Theme.FONT_TITLE
local note = text(menu, "", 14, Theme.DIM, Theme.FONT_BODY); note.Position = UDim2.new(0, 408, 1, -100); note.Size = UDim2.new(1, -436, 0, 80); note.TextYAlignment = Enum.TextYAlignment.Center

-- the choices
local menuData, pick = nil, nil
local choice = {map = "", mode = "TDM", real = true, segment = 180,
	roster = {Squire = 4, Knight = 8, Champion = 4, Archer = 2, Mage = 2}}
local ABOUT = {Squire = "green, slow to parry", Knight = "steady, parries half", Champion = "reads you, feints, ripostes",
	Archer = "bows and crossbows", Mage = "fire, frost, lightning"}
local function kindOf(id) for _, k in ipairs(menuData and menuData.kinds or {}) do if k.id == id then return k end end end
local function modeOf(id) for _, m in ipairs(menuData and menuData.modes or {}) do if m.id == id then return m end end end
local function rosterTotal() local n = 0; for _, k in pairs(choice.roster) do n += k end; return n end

local paintMenu
-- a heading and a grid of chips in the SET IT UP column
local setOrder = 0
local function section(title, cellW, cellH)
	setOrder += 1
	local h = text(setList, title, 14, Theme.DIM, Theme.FONT); h.Size = UDim2.new(1, -12, 0, 18); h.LayoutOrder = setOrder
	setOrder += 1
	local g = Instance.new("Frame"); g.BackgroundTransparency = 1; g.AutomaticSize = Enum.AutomaticSize.Y; g.Size = UDim2.new(1, -12, 0, 0); g.LayoutOrder = setOrder; g.Parent = setList
	local gl = Instance.new("UIGridLayout"); gl.CellSize = UDim2.fromOffset(cellW or 160, cellH or 46); gl.CellPadding = UDim2.fromOffset(8, 8); gl.SortOrder = Enum.SortOrder.LayoutOrder; gl.Parent = g
	return g
end
local function chip(parent, label, on, order, fn, size)
	local c = btn(parent, label, on and Theme.BLUE or Theme.GLASS2, nil, nil, size or 14)
	c.LayoutOrder = order or 0
	if fn then c.Activated:Connect(function() fn(); paintMenu() end) else c.AutoButtonColor = false end
	return c
end
local function mapChips(maps)
	local g = section("MAP", 160, 46)
	chip(g, "ANY  ·  NEW EVERY " .. math.floor((menuData.rotate or 240) / 60) .. " MIN", choice.map == "", 0, function() choice.map = "" end, 12)
	for i, m in ipairs(maps or {}) do chip(g, string.upper(m.title), choice.map == m.id, i, function() choice.map = m.id end) end
end
local function realChip()
	local g = section("THE BOTS", 496, 46)
	chip(g, choice.real and "✔  LOOK LIKE REAL PLAYERS: rare skins, kill effects, emotes, no name tags" or "LOOK LIKE REAL PLAYERS: OFF (plain bots)",
		choice.real, 0, function() choice.real = not choice.real end, 14)
end
local function paintSetup()
	for _, c in ipairs(setList:GetChildren()) do if c:IsA("GuiObject") then c:Destroy() end end
	setOrder = 0
	local k = kindOf(pick)
	if not k then return end
	if not k.battle then
		local g = section("WHERE", 300, 46)
		chip(g, string.upper(k.maps[1] and k.maps[1].title or "THE COURTYARD"), true, 0)
		return
	end
	if k.generate then
		local g = section("EACH BATTLE LASTS", 120, 46)
		for i, secs in ipairs({120, 180, 300}) do chip(g, (secs / 60) .. " MIN", choice.segment == secs, i, function() choice.segment = secs end, 16) end
		local about = text(setList, "It films, in turn: " .. table.concat(menuData.playlist or {}, " · ") .. ". Each on a new map, never the same twice running. N skips to the next one.", 13, Theme.DIM, Theme.FONT_BODY)
		setOrder += 1; about.LayoutOrder = setOrder; about.Size = UDim2.new(1, -12, 0, 0); about.AutomaticSize = Enum.AutomaticSize.Y
		realChip()
		return
	end
	if k.custom then
		local g = section("MODE", 120, 46)
		for i, m in ipairs(menuData.modes or {}) do
			chip(g, string.upper(m.name), choice.mode == m.id, i, function()
				if choice.mode ~= m.id then choice.mode, choice.map = m.id, "" end
			end, 12)
		end
		local md = modeOf(choice.mode)
		mapChips(md and md.maps or {})
		-- how many of each
		setOrder += 1
		local hdr = text(setList, string.format("BOTS  ·  %d IN ALL (UP TO %d)", rosterTotal(), menuData.maxBots or 40), 14, Theme.DIM, Theme.FONT)
		hdr.Size = UDim2.new(1, -12, 0, 18); hdr.LayoutOrder = setOrder
		for _, kind in ipairs(menuData.botKinds or {}) do
			setOrder += 1
			local r = Instance.new("Frame"); r.BackgroundColor3 = Theme.GLASS2; r.Size = UDim2.new(1, -12, 0, 48); r.LayoutOrder = setOrder; r.Parent = setList
			corner(r, 10)
			local a = text(r, string.upper(kind), 17, WHITE); a.Position = UDim2.fromOffset(14, 4); a.Size = UDim2.new(1, -200, 0, 22)
			local b = text(r, ABOUT[kind] or "", 12, Theme.DIM, Theme.FONT_BODY); b.Position = UDim2.fromOffset(14, 26); b.Size = UDim2.new(1, -200, 0, 16)
			local minus = btn(r, "−", Theme.GLASS, UDim2.fromOffset(44, 36), UDim2.new(1, -170, 0, 6), 24)
			local n = text(r, tostring(choice.roster[kind] or 0), 22, WHITE, Theme.FONT_TITLE); n.Position = UDim2.new(1, -120, 0, 6); n.Size = UDim2.fromOffset(56, 36)
			n.TextXAlignment = Enum.TextXAlignment.Center
			local plus = btn(r, "+", Theme.GLASS, UDim2.fromOffset(44, 36), UDim2.new(1, -58, 0, 6), 24)
			minus.Activated:Connect(function() choice.roster[kind] = math.max(0, (choice.roster[kind] or 0) - 1); paintMenu() end)
			plus.Activated:Connect(function()
				if rosterTotal() < (menuData.maxBots or 40) then choice.roster[kind] = math.min(20, (choice.roster[kind] or 0) + 1); paintMenu() end
			end)
		end
		realChip()
		return
	end
	mapChips(k.maps)
	realChip()
end
paintMenu = function()
	local y = setList.CanvasPosition
	for _, c in ipairs(whatList:GetChildren()) do if c:IsA("GuiObject") then c:Destroy() end end
	for i, k in ipairs(menuData and menuData.kinds or {}) do
		local on = k.id == pick
		local r = btn(whatList, "", on and Theme.BLUE or (k.generate and Color3.fromRGB(40, 92, 60) or Theme.GLASS2), UDim2.new(1, -10, 0, 64))
		r.LayoutOrder = i
		local a = text(r, k.label, 18, WHITE, Theme.FONT); a.Position = UDim2.fromOffset(14, 6); a.Size = UDim2.new(1, -28, 0, 22)
		local b = text(r, k.about, 13, on and WHITE or Theme.DIM, Theme.FONT_BODY); b.Position = UDim2.fromOffset(14, 30); b.Size = UDim2.new(1, -28, 0, 30); b.TextYAlignment = Enum.TextYAlignment.Top
		r.Activated:Connect(function()
			if pick ~= k.id then pick = k.id; choice.map = "" end
			paintMenu()
		end)
	end
	paintSetup()
	setList.CanvasPosition = y
	local k = kindOf(pick)
	local lines = {}
	if not k then
		table.insert(lines, "Pick something to film on the left.")
	elseif k.place == "travel" then
		table.insert(lines, "You'll be taken to a private filming server of your own: it starts by itself when you get there.")
	elseif k.place == "no" then
		table.insert(lines, "Go back to the Courtyard to film this (PLAY › COURTYARD).")
	elseif k.battle then
		table.insert(lines, "This server becomes a bot battle: nobody earns anything.")
	else
		table.insert(lines, "Films the Courtyard as it is.")
	end
	table.insert(lines, "While filming, TAB shows the controls and hides them again for a clean shot.")
	note.Text = table.concat(lines, "\n")
	note.TextColor3 = Theme.DIM
	local ready = k and k.place ~= "no" and not (k.custom and rosterTotal() == 0)
	goB.BackgroundColor3 = ready and Theme.GREEN or Theme.GLASS2
end

local function openMenu()
	local ok, d = pcall(infoFn.InvokeServer, infoFn)
	menuData = ok and type(d) == "table" and d or {kinds = {}}
	pick = (info and active and info.kind) or pick or (menuData.kinds[1] and menuData.kinds[1].id)
	if not modeOf(choice.mode) and menuData.modes and menuData.modes[1] then choice.mode = menuData.modes[1].id end
	paintMenu()
	menu.Visible = true
end
local function closeMenu() menu.Visible = false end
closeB.Activated:Connect(closeMenu)
_G.OpenShowcaseDirector = openMenu

goB.Activated:Connect(function()
	local k = kindOf(pick)
	if not k or k.place == "no" or (k.custom and rosterTotal() == 0) then return end
	goB.Text = "STARTING…"
	local args = {kind = pick, map = k.battle and choice.map or "", real = choice.real}
	if k.custom then args.mode, args.roster = choice.mode, choice.roster end
	if k.generate then args.segment = choice.segment end
	local ok, r = pcall(admin.InvokeServer, admin, "Act", "showcase", args)
	goB.Text = "▶   START FILMING"
	if ok and type(r) == "table" and r.ok then
		note.Text = tostring(r.msg or "")
		note.TextColor3 = Theme.GOOD
		task.delay(0.8, closeMenu)
	else
		note.Text = tostring(ok and type(r) == "table" and r.msg or r or "it didn't start")
		note.TextColor3 = Theme.BAD
	end
end)

-- THE CONTROL BAR (TAB)
local bar = Instance.new("Frame")
bar.Name = "Bar"
bar.AnchorPoint = Vector2.new(0.5, 1)
bar.Position = UDim2.new(0.5, 0, 1, -18)
bar.Size = UDim2.fromOffset(1240, 120)
bar.BackgroundColor3 = Theme.PANEL
bar.BackgroundTransparency = 0.05
bar.Active = true
bar.Visible = false
bar.Parent = gui
corner(bar, 16); outline(bar, 2, 0.8)
scaleOf(bar, 1240, 300)
local status = text(bar, "", 17, WHITE); status.Position = UDim2.fromOffset(18, 10); status.Size = UDim2.new(1, -36, 0, 24); status.TextTruncate = Enum.TextTruncate.AtEnd
local row = Instance.new("Frame"); row.BackgroundTransparency = 1; row.Position = UDim2.fromOffset(14, 46); row.Size = UDim2.new(1, -28, 0, 60); row.Parent = bar
do local l = Instance.new("UIListLayout"); l.FillDirection = Enum.FillDirection.Horizontal; l.Padding = UDim.new(0, 8); l.SortOrder = Enum.SortOrder.LayoutOrder; l.VerticalAlignment = Enum.VerticalAlignment.Center; l.Parent = row end
local styleB = {}
local order = 0
local function barBtn(t, color, w, fn)
	order += 1
	local b = btn(row, t, color, UDim2.fromOffset(w, 56), nil, 14)
	b.LayoutOrder = order
	b.Activated:Connect(fn)
	return b
end
for i, st in ipairs({"auto", "orbit", "hero", "follow", "aerial"}) do
	styleB[st] = barBtn(i .. "  " .. string.upper(st), Theme.GLASS2, 92, function() style = st; newShot(); estUntil = 0 end)
end
local function gap() order += 1; local g = Instance.new("Frame"); g.BackgroundTransparency = 1; g.Size = UDim2.fromOffset(6, 10); g.LayoutOrder = order; g.Parent = row end
gap()
barBtn("Q  ◀ FIGHTER", Theme.GLASS2, 118, function() pickSubject(-1) end)
barBtn("FIGHTER ▶  E", Theme.GLASS2, 118, function() pickSubject(1) end)
gap()
local nextB = barBtn("N  NEXT MAP", Theme.BLUE, 124, function() remote:FireServer("NextMap") end)
local mapsB = barBtn("MAPS ▾", Theme.BLUE, 96, function() end)
gap()
barBtn("MENU", Theme.GLASS2, 86, function() openMenu() end)
barBtn("■  STOP", Theme.RED, 100, function() remote:FireServer("Stop") end)

-- the maps, above the bar: one to stay on, or rotate
local mapsPop = Instance.new("Frame")
mapsPop.AnchorPoint = Vector2.new(0.5, 1)
mapsPop.Position = UDim2.new(0.5, 0, 1, -150)
mapsPop.Size = UDim2.fromOffset(720, 300)
mapsPop.BackgroundColor3 = Theme.PANEL
mapsPop.BackgroundTransparency = 0.03
mapsPop.Active = true
mapsPop.Visible = false
mapsPop.Parent = gui
corner(mapsPop, 14); outline(mapsPop, 2, 0.8)
scaleOf(mapsPop, 720, 700)
local mpT = text(mapsPop, "GO TO A MAP  ·  it stays until you pick another (or ROTATE)", 15, Theme.ACCENT); mpT.Position = UDim2.fromOffset(16, 10); mpT.Size = UDim2.new(1, -32, 0, 20)
local mpList = Instance.new("ScrollingFrame")
mpList.BackgroundTransparency = 1; mpList.BorderSizePixel = 0; mpList.Position = UDim2.fromOffset(14, 38); mpList.Size = UDim2.new(1, -28, 1, -50)
mpList.CanvasSize = UDim2.new(); mpList.AutomaticCanvasSize = Enum.AutomaticSize.Y; mpList.ScrollBarThickness = 6; mpList.Parent = mapsPop
do local g = Instance.new("UIGridLayout"); g.CellSize = UDim2.fromOffset(222, 46); g.CellPadding = UDim2.fromOffset(8, 8); g.SortOrder = Enum.SortOrder.LayoutOrder; g.Parent = mpList end
local function paintMaps()
	for _, c in ipairs(mpList:GetChildren()) do if c:IsA("GuiObject") then c:Destroy() end end
	if not info then return end
	local now = round:GetAttribute("Map")
	local rot = btn(mpList, "ROTATE  ·  NEW MAP EVERY " .. math.floor((info.rotate or 240) / 60) .. " MIN", (not info.fixed) and Theme.BLUE or Theme.GLASS2, nil, nil, 13)
	rot.LayoutOrder = 0
	rot.Activated:Connect(function() remote:FireServer("Map", ""); mapsPop.Visible = false end)
	for i, m in ipairs(info.maps or {}) do
		local c = btn(mpList, string.upper(m.title) .. (m.id == now and "  ·  NOW" or ""), (info.fixed and m.id == now) and Theme.BLUE or Theme.GLASS2, nil, nil, 14)
		c.LayoutOrder = i
		c.Activated:Connect(function() remote:FireServer("Map", m.id); mapsPop.Visible = false end)
	end
end
mapsB.Activated:Connect(function()
	if not (info and info.battle) then return end
	mapsPop.Visible = not mapsPop.Visible
	if mapsPop.Visible then paintMaps() end
end)

-- the hint as it starts (then everything hides: start recording after it's gone)
local hint = text(gui, "", 22, WHITE, Theme.FONT_TITLE)
hint.AnchorPoint = Vector2.new(0.5, 0); hint.Position = UDim2.new(0.5, 0, 0, 40); hint.Size = UDim2.fromOffset(900, 30)
hint.TextXAlignment = Enum.TextXAlignment.Center; hint.Visible = false
local function flashHint(t, secs)
	hint.Text = t
	hint.Visible = true
	local mine = os.clock()
	hint:SetAttribute("At", mine)
	task.delay(secs or 4.5, function() if hint:GetAttribute("At") == mine then hint.Visible = false end end)
end

local barOpen = false
local function setBar(on)
	barOpen = on and active
	bar.Visible = barOpen
	if not barOpen then mapsPop.Visible = false end
end

-- the bar's live line and highlights
RunService.Heartbeat:Connect(function()
	if not bar.Visible then return end
	for st, b in pairs(styleB) do b.BackgroundColor3 = (st == style) and Theme.BLUE or Theme.GLASS2 end
	local battle = info and info.battle
	nextB.Visible, mapsB.Visible = battle == true, battle == true
	nextB.Text = (info and info.generate) and "N  NEXT BATTLE" or "N  NEXT MAP"
	local bits = {info and info.label or "SHOWCASE", string.upper(round:GetAttribute("MapName") or round:GetAttribute("Map") or "")}
	if battle then
		local st, left = round:GetAttribute("State"), round:GetAttribute("TimeLeft") or 0
		if st ~= "Round" then table.insert(bits, "NEXT ROUND STARTING…")
		elseif info.generate then table.insert(bits, "AUTOPILOT")
		elseif info.fixed then table.insert(bits, "THIS MAP STAYS")
		else table.insert(bits, string.format("NEW MAP IN %d:%02d", math.floor(left / 60), left % 60)) end
	end
	if subject and subject.Parent then table.insert(bits, "FILMING " .. string.upper(subject:GetAttribute("TagName") or subject.Name)) end
	table.insert(bits, "TAB HIDES THIS")
	status.Text = table.concat(bits, "   ·   ")
end)

-- the cursor: free while a menu or the bar is up; gone from the footage otherwise
RunService:BindToRenderStep("ShowcaseMouse", Enum.RenderPriority.Last.Value + 11, function()
	if menu.Visible or (active and barOpen) then
		UserInputService.MouseBehavior = Enum.MouseBehavior.Default
		UserInputService.MouseIconEnabled = true
	elseif active then
		UserInputService.MouseIconEnabled = false
	end
end)

-- THE KEYS while it runs (taken first, ahead of the weapon bar and the prompts)
local STYLE = {[Enum.KeyCode.One] = "auto", [Enum.KeyCode.Two] = "orbit", [Enum.KeyCode.Three] = "hero", [Enum.KeyCode.Four] = "follow", [Enum.KeyCode.Five] = "aerial"}
local KEYS = {Enum.KeyCode.One, Enum.KeyCode.Two, Enum.KeyCode.Three, Enum.KeyCode.Four, Enum.KeyCode.Five, Enum.KeyCode.Q, Enum.KeyCode.E, Enum.KeyCode.N, Enum.KeyCode.X, Enum.KeyCode.Tab}
local function onKey(_, inputState, input)
	if inputState ~= Enum.UserInputState.Begin or UserInputService:GetFocusedTextBox() then return Enum.ContextActionResult.Pass end
	local k = input.KeyCode
	local ctrl = UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) or UserInputService:IsKeyDown(Enum.KeyCode.RightControl)
	local shift = UserInputService:IsKeyDown(Enum.KeyCode.LeftShift) or UserInputService:IsKeyDown(Enum.KeyCode.RightShift)
	if k == Enum.KeyCode.X then
		if not (ctrl and shift) then return Enum.ContextActionResult.Pass end
		remote:FireServer("Stop")
	elseif k == Enum.KeyCode.Tab then setBar(not barOpen)
	elseif STYLE[k] then style = STYLE[k]; newShot(); estUntil = 0
	elseif k == Enum.KeyCode.Q then pickSubject(-1)
	elseif k == Enum.KeyCode.E then pickSubject(1)
	elseif k == Enum.KeyCode.N then if info and info.battle then remote:FireServer("NextMap") end end
	return Enum.ContextActionResult.Sink
end

-- F4: the menu (staff with the showcase permission)
local mayFilm = nil
local function canFilm()
	if mayFilm ~= nil then return mayFilm end
	local ok, me = pcall(admin.InvokeServer, admin, "Me")
	local perms = ok and type(me) == "table" and me.perms
	mayFilm = type(perms) == "table" and (perms.showcase == true or table.find(perms, "showcase") ~= nil) or false
	return mayFilm
end
UserInputService.InputBegan:Connect(function(input, processed)
	if processed or input.KeyCode ~= Enum.KeyCode.F4 then return end
	if menu.Visible then closeMenu() elseif canFilm() then openMenu() end
end)

local function start(i)
	info, parade = i, nil
	active = true
	started = os.clock()
	style, subject, camPos, camLook, cut, estUntil, lastMap = "auto", nil, nil, nil, true, 0, nil
	subjPos, subjFace, reach, diedAt, diedPos = nil, nil, 1, nil, nil
	_G.ShowcaseActive = true
	if _G.SetCleanView then _G.SetCleanView(true) end
	pcall(function() RunService:UnbindFromRenderStep(BIND) end)
	RunService:BindToRenderStep(BIND, Enum.RenderPriority.Last.Value + 10, step)
	ContextActionService:BindActionAtPriority("ShowcaseKeys", onKey, false, 4000, table.unpack(KEYS))
	menu.Visible = false
	setBar(false)
	flashHint("FILMING  ·  TAB = CONTROLS  ·  start your recorder now")
end
local function stop()
	if not active then return end
	active = false
	setBar(false)
	hint.Visible = false
	pcall(function() RunService:UnbindFromRenderStep(BIND) end)
	ContextActionService:UnbindAction("ShowcaseKeys")
	_G.ShowcaseActive = false
	if _G.SetCleanView then _G.SetCleanView(false) end
	-- (the Courtyard's menu, up when filming began, doesn't come back over a battle: the spawn screen does)
	if round:GetAttribute("Mode") ~= "Hub" and _G.MenuBus then _G.MenuBus:Fire("CloseHub") end
	local cam = workspace.CurrentCamera
	if cam then cam.CameraType = Enum.CameraType.Custom; cam.FieldOfView = 70 end
	UserInputService.MouseIconEnabled = true
end

remote.OnClientEvent:Connect(function(what, data)
	if what == "Start" and type(data) == "table" then start(data)
	elseif what == "Info" and type(data) == "table" then
		info = info or {}
		local was = info.label
		for k, v in pairs(data) do info[k] = v end
		if mapsPop.Visible then paintMaps() end
		-- (GENERATE's next battle: a fresh start for the camera)
		if active and data.label and data.label ~= was then subject, subjPos, subjFace = nil, nil, nil end
	elseif what == "Parade" and type(data) == "table" then parade = data; started = os.clock(); cut = true
	elseif what == "Stop" then stop() end
end)
