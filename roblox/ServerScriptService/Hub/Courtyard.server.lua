--[[ COURTYARD (server) — the hub's living places, built from the Courtyard
     map's Spots (Build ▸ MapCourtyard) whenever the Hub is up:

       • THE HALL OF CHAMPIONS: statues of the season's top three in Warfront
         kills, wearing their own armor and weapon (their active class), cast in
         gold, silver and bronze, posed, with plaques; and two boards: Warfront
         kills, and the Lists' ranked brackets. Refreshed every few minutes.
       • THE MERCHANT'S STALL: today's packs on two mannequins, today's skins on
         the rack (Catalog.storeFor / skinOffers); refreshed when the day turns.
       • THE WISHING FOUNTAIN: one wish a day (Economy ▸ Pastimes.wish).
       • THE GATES OF WAR: prompts (the client acts on them) and their signs.
       • THE NOTICE BOARD: a face the client writes your tasks on.
       • A BARD by the tavern.
     Remote: ReplicatedStorage ▸ CourtyardEvent (server → clients): "Wish",
     player, line. The client side is StarterPlayerScripts ▸ Courtyard. ]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local Catalog = require(ReplicatedStorage:WaitForChild("Catalog"))
local Dresser = require(ReplicatedStorage:WaitForChild("Dresser"))
local Emotes = require(ReplicatedStorage:WaitForChild("Emotes"))
local R6 = require(ServerScriptService:WaitForChild("Combat"):WaitForChild("R6"))
local Bots = require(ServerScriptService:WaitForChild("Combat"):WaitForChild("Bots"))
local Pastimes = require(ServerScriptService:WaitForChild("Economy"):WaitForChild("Pastimes"))
local Leaderboards = require(script.Parent:WaitForChild("Leaderboards"))

local round = ReplicatedStorage:WaitForChild("Round")
local event = ReplicatedStorage:FindFirstChild("CourtyardEvent")
if not event then event = Instance.new("RemoteEvent"); event.Name = "CourtyardEvent"; event.Parent = ReplicatedStorage end

local map, spots, made = nil, {}, {}
local function spot(n) return spots[n] end
local function keep(i) table.insert(made, i); return i end
local function toast(plr, text)
	local ev = ReplicatedStorage:FindFirstChild("HubEvent")
	if ev and plr.Parent then ev:FireClient(plr, "Toast", text) end
end
local function fmt(n)
	local s = tostring(math.floor(tonumber(n) or 0))
	while true do local k; s, k = s:gsub("^(-?%d+)(%d%d%d)", "%1,%2"); if k == 0 then break end end
	return s
end

-- a flat panel at a spot with a SurfaceGui on its front
local function face(at, size, color, name)
	local p = Instance.new("Part")
	p.Name = name or "Face"
	p.Size = Vector3.new(size.X, size.Y, 0.12)
	p.CFrame = at.CFrame
	p.Anchored, p.CanCollide, p.CanQuery, p.CanTouch = true, false, false, false
	p.Color = color or Color3.fromRGB(40, 30, 22)
	p.Material = Enum.Material.SmoothPlastic
	p.Parent = map
	local sg = Instance.new("SurfaceGui")
	sg.Face = Enum.NormalId.Front
	sg.CanvasSize = Vector2.new(size.X * 50, size.Y * 50)
	sg.LightInfluence = 0.3
	sg.Parent = p
	return keep(p), sg
end
local function label(parent, text, y, h, color, font, align)
	local l = Instance.new("TextLabel")
	l.BackgroundTransparency = 1
	l.Position = UDim2.new(0, 12, 0, y)
	l.Size = UDim2.new(1, -24, 0, h)
	l.Font = font or Enum.Font.FredokaOne
	l.TextScaled = true
	l.TextColor3 = color or Color3.new(1, 1, 1)
	l.TextXAlignment = align or Enum.TextXAlignment.Center
	l.Text = text
	l.Parent = parent
	local s = Instance.new("UIStroke"); s.Color = Color3.fromRGB(20, 14, 8); s.Thickness = 2; s.Parent = l
	return l
end

-- weld every joint into place (anchored models: no physics to do it)
local function settle(model)
	for _ = 1, 5 do
		for _, w in ipairs(model:GetDescendants()) do
			if (w:IsA("Weld") or w:IsA("Motor6D")) and w.Part0 and w.Part1 and w.Part0 ~= w.Part1 then
				w.Part1.CFrame = w.Part0.CFrame * w.C0 * w.C1:Inverse()
			end
		end
	end
	for _, d in ipairs(model:GetDescendants()) do if d:IsA("BasePart") then d.Anchored = true end end
end

--------------------------------------------------------------------
--  THE HALL OF CHAMPIONS
--------------------------------------------------------------------
local METAL = {
	{color = Color3.fromRGB(236, 190, 72), name = "GOLD", pose = "WarCry", t = 1.0},
	{color = Color3.fromRGB(206, 212, 222), name = "SILVER", pose = "Salute", t = 1.0},
	{color = Color3.fromRGB(200, 128, 70), name = "BRONZE", pose = "Champion", t = 1.6},
}
local hall = {}
local function statue(rank, row)
	local at = spot("Statue" .. rank)
	if not at then return end
	if hall[rank] then hall[rank]:Destroy() end
	local look = row and Leaderboards.lookOf(row.id) or nil
	local m = R6.rig("Statue" .. rank, {anchored = true})
	m:PivotTo(at.CFrame)
	local lo = look and look.loadout or Bots.loadoutFor(rank == 1 and "Heavy" or (rank == 2 and "Medium" or "Light"))
	pcall(Dresser.dress, m, {loadout = lo, appearance = look and look.appearance or Catalog.BODY.defaults, weight = look and look.weight or "Medium", preview = true})
	pcall(Dresser.attachWeapon, m, lo.weapon or "Longsword", lo.weaponSkin)
	-- larger than life: scale it up, feet still on the plinth
	local SCALE = 1.6
	pcall(function() m:ScaleTo(SCALE) end)
	local hrp = m:FindFirstChild("HumanoidRootPart")
	if hrp then m:PivotTo(at.CFrame * CFrame.new(0, 3 * (SCALE - 1), 0) * hrp.CFrame:ToObjectSpace(m:GetPivot())) end
	local origins = {}
	pcall(Emotes.poseRig, m, METAL[rank].pose, METAL[rank].t, origins)
	settle(m)
	-- cast it in metal
	for _, d in ipairs(m:GetDescendants()) do
		if d:IsA("BasePart") then
			d.Color = METAL[rank].color
			d.Material = Enum.Material.Metal
			d.CanCollide, d.CanQuery, d.CanTouch = false, false, false
			if d:IsA("MeshPart") then pcall(function() d.TextureID = "" end) end
		elseif d:IsA("Decal") or d:IsA("Texture") or d:IsA("SurfaceAppearance") then
			d:Destroy()
		end
	end
	local hum = m:FindFirstChildOfClass("Humanoid")
	if hum then hum.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None end
	m.Parent = map
	hall[rank] = keep(m)
end

local plaques, boards = {}, {}
local function refreshHall()
	local rows = Leaderboards.top("Warfront", 10)
	for rank = 1, 3 do
		local row = rows[rank]
		statue(rank, row)
		local at = spot("Plaque" .. rank)
		if at then
			if not plaques[rank] then
				local p, sg = face(at, Vector2.new(5.8, 1.7), Color3.fromRGB(44, 34, 24), "Plaque" .. rank)
				plaques[rank] = {part = p, top = label(sg, "", 4, 46, METAL[rank].color), bottom = label(sg, "", 50, 30, Color3.fromRGB(240, 230, 210), Enum.Font.GothamBold)}
			end
			local pl = plaques[rank]
			pl.top.Text = string.format("#%d  %s", rank, row and string.upper(row.name) or "UNCLAIMED")
			pl.bottom.Text = row and (fmt(row.value) .. " KILLS THIS SEASON") or "be the one who claims it"
		end
	end
	-- the boards
	local function board(name, title)
		if boards[name] then return boards[name] end
		local at = spot(name)
		if not at then return nil end
		local p, sg = face(at, Vector2.new(14, 10), Color3.fromRGB(30, 22, 16), name)
		local b = {part = p, sg = sg, title = label(sg, title, 10, 54, Color3.fromRGB(255, 214, 110)), rows = {}}
		for i = 1, 11 do
			local r = label(sg, "", 70 + (i - 1) * 38, 32, Color3.new(1, 1, 1), Enum.Font.GothamBold, Enum.TextXAlignment.Left)
			b.rows[i] = r
		end
		boards[name] = b
		return b
	end
	local kills = board("BoardKills", "WARFRONT  ·  MOST KILLS")
	if kills then
		for i = 1, 11 do
			local r = rows[i]
			kills.rows[i].Text = (i <= 10 and r) and string.format("%2d.   %s   ·   %s", i, r.name, fmt(r.value)) or ""
			kills.rows[i].TextColor3 = i <= 3 and METAL[i].color or Color3.new(1, 1, 1)
		end
	end
	local ranked = board("BoardRanked", "THE LISTS  ·  RANKED")
	if ranked then
		local lines = {}
		for _, br in ipairs({"1v1", "2v2", "3v3"}) do
			table.insert(lines, {text = string.upper(br), head = true})
			local rr = Leaderboards.top(br, 3)
			for i = 1, 3 do
				local r = rr[i]
				table.insert(lines, {text = r and string.format("   %d.   %s   ·   %s", i, r.name, fmt(r.value)) or "   —"})
			end
		end
		for i = 1, 11 do
			local l = lines[i]
			ranked.rows[i].Text = l and l.text or ""
			ranked.rows[i].TextColor3 = (l and l.head) and Color3.fromRGB(255, 214, 110) or Color3.new(1, 1, 1)
		end
	end
end

--------------------------------------------------------------------
--  THE MERCHANT'S STALL
--------------------------------------------------------------------
local stallDay, stallStuff = nil, {}
local function packLoadout(key)
	local lo = {colors = {Primary = "Crimson", Secondary = "Bone", Accent = "Gold", Metal = "Steel"}}
	for _, p in ipairs(Catalog.PIECES) do
		if p.pack == key and not lo[p.slot] then lo[p.slot] = p.id end
	end
	return lo, (Catalog.PACKS[key] and Catalog.PACKS[key].weight) or "Medium"
end
local function tag(parent, text, color)
	local bb = Instance.new("BillboardGui")
	bb.Size = UDim2.fromOffset(180, 34)
	bb.StudsOffsetWorldSpace = Vector3.new(0, 4, 0)
	bb.MaxDistance = 45
	bb.Parent = parent
	local l = Instance.new("TextLabel")
	l.BackgroundTransparency = 1; l.Size = UDim2.fromScale(1, 1); l.Font = Enum.Font.FredokaOne; l.TextScaled = true
	l.TextColor3 = color or Color3.new(1, 1, 1); l.Text = text; l.Parent = bb
	local s = Instance.new("UIStroke"); s.Color = Color3.fromRGB(20, 14, 8); s.Thickness = 2; s.Parent = l
	return bb
end
local function refreshStall()
	local packs, day = Catalog.storeFor()
	if day == stallDay then return end
	stallDay = day
	for _, i in ipairs(stallStuff) do if i.Parent then i:Destroy() end end
	stallStuff = {}
	for i = 1, 2 do
		local key, at = packs[i], spot("StallMannequin" .. i)
		if key and at and Catalog.PACKS[key] then
			local lo, weight = packLoadout(key)
			local m = R6.rig("Mannequin", {anchored = true})
			m:PivotTo(at.CFrame)
			pcall(Dresser.dress, m, {loadout = lo, appearance = Catalog.BODY.defaults, weight = weight, preview = true})
			settle(m)
			for _, d in ipairs(m:GetDescendants()) do if d:IsA("BasePart") then d.CanCollide, d.CanQuery = false, false end end
			local hum = m:FindFirstChildOfClass("Humanoid")
			if hum then hum.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None end
			m.Parent = map
			tag(m.Head, string.upper(Catalog.PACKS[key].name or key), Color3.fromRGB(255, 214, 110))
			table.insert(stallStuff, keep(m))
		end
	end
	local rack = spot("StallRack")
	if rack then
		for i, skinId in ipairs(Catalog.skinOffers(day)) do
			if i > 4 then break end
			local s = Catalog.SKIN[skinId]
			local t = s and Catalog.weaponModel(s.weapon)
			if t then
				local w = t:Clone()
				pcall(Dresser.applySkin, w, skinId)
				local handle = w:FindFirstChild("Handle", true)
				for _, d in ipairs(w:GetDescendants()) do
					if d:IsA("BasePart") then d.Anchored = true; d.CanCollide, d.CanQuery, d.CanTouch = false, false, false end
					if d:IsA("BaseScript") then d:Destroy() end
				end
				if handle then
					local want = rack.CFrame * CFrame.new((i - 2.5) * 2.2, 1.6, 0) * CFrame.Angles(0, math.rad(90), 0)
					w:PivotTo(want * handle.CFrame:ToObjectSpace(w:GetPivot()))
				end
				w.Name = "ShelfWeapon"
				w.Parent = map
				local rarity = {Common = Color3.fromRGB(200, 205, 215), Rare = Color3.fromRGB(90, 160, 255), Epic = Color3.fromRGB(190, 110, 255), Legendary = Color3.fromRGB(255, 186, 60)}
				if handle then tag(handle, s.name, rarity[s.rarity]) end
				table.insert(stallStuff, keep(w))
			end
		end
	end
end

--------------------------------------------------------------------
--  SETUP: signs, prompts, the bard
--------------------------------------------------------------------
local function prompt(at, action, object, attrs, dist)
	local p = Instance.new("ProximityPrompt")
	p.ActionText = action
	p.ObjectText = object
	p.KeyboardKeyCode = Enum.KeyCode.E
	p.MaxActivationDistance = dist or 12
	p.RequiresLineOfSight = false
	for k, v in pairs(attrs or {}) do p:SetAttribute(k, v) end
	p.Parent = at
	return p
end
local function sign(name, title, sub, size, color)
	local at = spot(name)
	if not at then return end
	local _, sg = face(at, size or Vector2.new(11.4, 2.1), Color3.fromRGB(60, 42, 26), name .. "Face")
	label(sg, title, sub and 4 or 8, sub and 62 or 90, color or Color3.fromRGB(255, 226, 150))
	if sub then label(sg, sub, 66, 34, Color3.new(1, 1, 1), Enum.Font.GothamBold) end
end

local function bard()
	local at = spot("BardSpot")
	if not at then return end
	local m = R6.rig("Bard", {anchored = true})
	m:SetAttribute("Idle", true)
	m:PivotTo(at.CFrame)
	pcall(Dresser.dress, m, {loadout = {colors = {Primary = "Forest", Secondary = "Ochre", Accent = "Wine", Metal = "Ash"}}, appearance = Catalog.BODY.defaults, weight = "Light", preview = true})
	-- the lute: a round body and a neck, held across the chest
	local torso = m.Torso
	local body = Instance.new("Part"); body.Name = "Lute"; body.Shape = Enum.PartType.Ball; body.Size = Vector3.new(1.6, 1.6, 1.6); body.Color = Color3.fromRGB(150, 96, 52); body.Material = Enum.Material.Wood
	body.CFrame = torso.CFrame * CFrame.new(0.3, -0.4, -0.9); body.Anchored = true; body.CanCollide = false; body.Parent = m
	local neck = Instance.new("Part"); neck.Name = "LuteNeck"; neck.Size = Vector3.new(0.3, 0.2, 2.2); neck.Color = Color3.fromRGB(90, 56, 30); neck.Material = Enum.Material.Wood
	neck.CFrame = body.CFrame * CFrame.new(-1.2, 0.5, 0) * CFrame.Angles(0, math.rad(90), math.rad(30)); neck.Anchored = true; neck.CanCollide = false; neck.Parent = m
	local rs, ls = torso:FindFirstChild("Right Shoulder"), torso:FindFirstChild("Left Shoulder")
	if rs then rs.C0 = rs.C0 * CFrame.Angles(0, 0, math.rad(60)) end
	if ls then ls.C0 = ls.C0 * CFrame.Angles(0, 0, math.rad(-80)) end
	settle(m)
	local hum = m:FindFirstChildOfClass("Humanoid")
	if hum then hum.DisplayName = "Wendel the Bard"; hum.HealthDisplayType = Enum.HumanoidHealthDisplayType.AlwaysOff end
	for _, d in ipairs(m:GetDescendants()) do if d:IsA("BasePart") then d.CanQuery = false end end
	m.Parent = map
	local notes = tag(m.Head, "♪", Color3.fromRGB(255, 230, 160))
	notes.StudsOffsetWorldSpace = Vector3.new(0, 2.6, 0)
	keep(m)
	task.spawn(function()
		local seq = {"♪", "♪ ♫", "♫ ♪ ♫", "♪ ♫"}
		local i = 0
		while m.Parent do
			i = i % #seq + 1
			local l = notes:FindFirstChildOfClass("TextLabel")
			if l then l.Text = seq[i] end
			task.wait(0.7)
		end
	end)
end

local function setup(newMap)
	for _, i in ipairs(made) do if i.Parent then i:Destroy() end end
	made, hall, plaques, boards, stallDay, stallStuff = {}, {}, {}, {}, nil, {}
	map, spots = newMap, {}
	local f = map:FindFirstChild("Spots")
	for _, s in ipairs(f and f:GetChildren() or {}) do spots[s.Name] = s end
	-- signs
	sign("GateTrainingSign", "TRAINING YARD", "lessons · dummies · the ring", nil, Color3.fromRGB(140, 230, 150))
	sign("GateWarfrontSign", "WARFRONT", "the big battles", nil, Color3.fromRGB(255, 130, 110))
	sign("GateListsSign", "THE LISTS", "1v1 · 2v2 · 3v3 · ranked", nil, Color3.fromRGB(255, 214, 110))
	sign("StallSign", "TODAY'S WARES", nil, Vector2.new(8.6, 1.8))
	sign("TavernSign", "THE RUSTY TANKARD", nil, Vector2.new(5.8, 2.4))
	-- the gates (the client travels), the stall, the board
	for name, door in pairs({GateTraining = "Training", GateWarfront = "Warfront", GateLists = "Lists"}) do
		local at = spot(name)
		if at then keep(prompt(at, "Enter", ({Training = "Training Yard", Warfront = "Warfront", Lists = "The Lists"})[door], {Gate = door}, 10)) end
	end
	local stallSign = spot("StallSign")
	if stallSign then keep(prompt(spot("StallRack") or stallSign, "Browse", "Merchant's Stall", {Open = "SHOP"}, 14)) end
	local nb = spot("NoticeBoard")
	if nb then
		local p = face(nb, Vector2.new(9.4, 5.9), Color3.fromRGB(226, 208, 168), "NoticeFace")
		p.Material = Enum.Material.Fabric
		local sg = p:FindFirstChildOfClass("SurfaceGui"); if sg then sg:Destroy() end   -- each player writes their own (client)
		keep(prompt(nb, "Read", "Notice Board", {Open = "TASKS"}, 12))
	end
	-- the wishing fountain
	local well = spot("WellSpot")
	if well then
		local p = keep(prompt(well, "Make a wish", "Wishing Fountain", nil, 14))
		p.HoldDuration = 0.6
		p.Triggered:Connect(function(plr)
			local ok, line = Pastimes.wish(plr)
			if ok then
				event:FireAllClients("Wish", plr, line)
				toast(plr, "YOUR WISH  ·  " .. line)
			else
				toast(plr, line)
			end
		end)
	end
	bard()
	task.spawn(refreshHall)
	task.spawn(refreshStall)
end

--------------------------------------------------------------------
--  THE LOOP: set up with the map, keep things fresh
--------------------------------------------------------------------
local lastHall = 0
task.spawn(function()
	while true do
		task.wait(2)
		local m = workspace:FindFirstChild("Map")
		local hub = round:GetAttribute("Mode") == "Hub" and m ~= nil and m:FindFirstChild("Spots") ~= nil and m.Spots:FindFirstChild("WellSpot") ~= nil
		if hub and m ~= map then
			setup(m)
			lastHall = os.clock()
		elseif not hub and map then
			for _, i in ipairs(made) do if i.Parent then i:Destroy() end end
			made, map = {}, nil
		end
		if map then
			if os.clock() - lastHall > 180 then lastHall = os.clock(); task.spawn(refreshHall) end
			task.spawn(refreshStall)
		end
	end
end)
Players.PlayerAdded:Connect(function() if map then task.delay(5, refreshHall) end end)
