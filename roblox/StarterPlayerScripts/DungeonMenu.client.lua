--[[ DUNGEON MENU — the dungeon game's lobby (The Depths, Deadvault), after Dark and Darker: its own
     dark, gold-lined screens over its own world (the Tavern: Game ▸ Modes ▸ Tavern; M there), or
     over the Courtyard's menu (PLAY ▸ ADVENTURES). Everything shown as itself, in 3D (DarkUI).

       PLAY        your party round a candle-lit table in the tavern's back room; the dungeon
                   (THE DEPTHS · DEADVAULT, its picture), READY (the leader: ENTER); invite, leave
       CLASS       the class list (their faces), you as that class in the middle, its story, its
                   skill, and its PERKS (two go in with you: Catalog ▸ Perks)
       STASH       you in your kit (its weapon in hand, its armour on), what you are (health,
                   armour, damage), the KIT (weapon, sidearm, armour, three relics, the belt's four
                   draughts) and the STASH (60). Drag a thing onto a slot (or click it, then
                   EQUIP / TAKE OFF / SELL, and the Smith's REFORGE / TEMPER)
       MERCHANTS   the Smith, the Armourer, the Alchemist, the Treasurer: their wares, and your
                   stash to sell from

     The server decides everything (VaultRemote: Hub ▸ VaultServer; the party: HubRemote). Opened by
     _G.OpenDungeon(tab, mode); _G.OpenVault opens the stash.

     PART OF THE MAIN GAME: top left, ◀ MAIN MENU (where every screen's back is) takes you back to
     the main menu (asked once: your stash, kit and gold stay here); top right, your level, Marks and
     Crowns (what every run pays into) beside the vault's gold. WALK AROUND (M) shuts the lobby and
     you're on your feet in the Gilded Rat (its own little bar at the top: LOBBY, ◀ MAIN MENU). And the dungeon game never shows the battle's class screen
     (LoadoutServer: a mode's ownSpawn): when you can't go back in, its own screen says why (YOU
     FELL · DOWN) with SPECTATE and BACK TO THE GILDED RAT. ]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local Lighting = game:GetService("Lighting")

local player = Players.LocalPlayer
local Catalog = require(ReplicatedStorage:WaitForChild("Catalog"))
local GameConfig = require(ReplicatedStorage:WaitForChild("GameConfig"))
local DarkUI = require(ReplicatedStorage:WaitForChild("DarkUI"))
local PreviewRig = require(ReplicatedStorage:WaitForChild("PreviewRig"))
local vaultRemote = ReplicatedStorage:WaitForChild("VaultRemote")
local hubRemote = ReplicatedStorage:WaitForChild("HubRemote")
local hubEvent = ReplicatedStorage:WaitForChild("HubEvent")
local round = ReplicatedStorage:WaitForChild("Round")
local advEvent = ReplicatedStorage:WaitForChild("AdventureEvent")

local C = DarkUI.C
local RAR = DarkUI.RARITY
local BOLD, SEMI = Enum.FontWeight.Bold, Enum.FontWeight.SemiBold
local TABS = {"Play", "Class", "Stash", "Merchants"}

local gui = Instance.new("ScreenGui")
gui.Name = "DungeonMenu"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = true
gui.DisplayOrder = 2100
gui.Enabled = false
gui.Parent = player:WaitForChild("PlayerGui")
local uiScale = Instance.new("UIScale"); uiScale.Parent = gui
local root = Instance.new("Frame")
root.BackgroundTransparency = 1
root.Size = UDim2.fromOffset(1600, 900)
root.AnchorPoint = Vector2.new(0.5, 0.5)
root.Position = UDim2.fromScale(0.5, 0.5)
root.Parent = gui
local tip = DarkUI.tooltip(gui)

local T = DarkUI.text
local function left(l) l.TextXAlignment = Enum.TextXAlignment.Left; return l end
local function frame(parent, color, t)
	local f = Instance.new("Frame")
	f.BackgroundColor3 = color or C.PANEL
	f.BackgroundTransparency = t or 0
	f.BorderSizePixel = 0
	f.Parent = parent
	return f
end

-- the backdrop (every tab but PLAY): black, a warm vignette
local backdrop = Instance.new("Frame")
backdrop.BorderSizePixel = 0
backdrop.BackgroundColor3 = C.BG
backdrop.Size = UDim2.fromScale(1, 1)
backdrop.ZIndex = 0
backdrop.Parent = gui
do
	local g = Instance.new("UIGradient")
	g.Color = ColorSequence.new({ColorSequenceKeypoint.new(0, Color3.fromRGB(26, 30, 48)), ColorSequenceKeypoint.new(0.5, Color3.fromRGB(14, 18, 32)), ColorSequenceKeypoint.new(1, Color3.fromRGB(6, 8, 16))})
	g.Rotation = 90
	g.Parent = backdrop
end

--------------------------------------------------------------------
--  THE TOP: the tabs, your gold, the way out
--------------------------------------------------------------------
local nav = frame(root, Color3.new(0, 0, 0), 0)
nav.Size = UDim2.new(1, 0, 0, 86)
nav.ZIndex = 5
do
	local g = Instance.new("UIGradient")
	g.Rotation = 90
	g.Transparency = NumberSequence.new({NumberSequenceKeypoint.new(0, 0), NumberSequenceKeypoint.new(0.75, 0.1), NumberSequenceKeypoint.new(1, 1)})
	g.Parent = nav
end
local homeBtn = DarkUI.button(nav, "◀  MAIN MENU", "blue", 17)
homeBtn.Position = UDim2.fromOffset(18, 16); homeBtn.Size = UDim2.fromOffset(180, 46); homeBtn.ZIndex = 8
do
	local logo = left(T(nav, "DEADVAULT", 24, C.GOLD2, BOLD))
	logo.Position = UDim2.fromOffset(214, 12); logo.Size = UDim2.fromOffset(200, 28); logo.ZIndex = 6
	local logoSub = left(T(nav, "THE DUNGEON GAME", 10, C.DIM, SEMI))
	logoSub.Position = UDim2.fromOffset(215, 42); logoSub.Size = UDim2.fromOffset(200, 14); logoSub.ZIndex = 6
end
local navRule = DarkUI.rule(nav, 72, 1180)
navRule.ZIndex = 6
for _, d in ipairs(navRule:GetChildren()) do if d:IsA("Frame") and d.Rotation == 45 then d.Visible = false end end
local tabBtns = {}
local glow = frame(nav, C.BLUE, 0.05)
glow.Size = UDim2.fromOffset(176, 54)
glow.AnchorPoint = Vector2.new(0.5, 0)
glow.ZIndex = 5
DarkUI.corner(glow, 14)
DarkUI.gradient(glow, Color3.new(1, 1, 1), Color3.fromRGB(170, 170, 176))
DarkUI.stroke(glow, Color3.fromRGB(20, 60, 140), 2, 0)
local glowDiamond = frame(nav, C.GOLD2, 0)
glowDiamond.AnchorPoint = Vector2.new(0.5, 0.5); glowDiamond.Size = UDim2.fromOffset(60, 4); glowDiamond.ZIndex = 7
DarkUI.corner(glowDiamond, 2)
for i, name in ipairs(TABS) do
	local b = Instance.new("TextButton")
	b.AutoButtonColor = false
	b.BackgroundTransparency = 1
	b.Text = name
	b.FontFace = DarkUI.font(BOLD)
	b.TextSize = 26
	b.TextColor3 = C.DIM
	b.TextStrokeTransparency = 1
	DarkUI.outline(b, 26)
	b.AnchorPoint = Vector2.new(0.5, 0)
	b.Position = UDim2.new(0.5, (i - (#TABS + 1) / 2) * 190, 0, 14)
	b.Size = UDim2.fromOffset(180, 48)
	b.ZIndex = 8
	b.Parent = nav
	tabBtns[name] = b
end
local goldLabel = T(nav, "", 20, C.GOLD2, BOLD)
goldLabel.AnchorPoint = Vector2.new(1, 0)
goldLabel.Position = UDim2.new(1, -150, 0, 24); goldLabel.Size = UDim2.fromOffset(220, 26); goldLabel.ZIndex = 6
goldLabel.TextXAlignment = Enum.TextXAlignment.Right
goldLabel.Position = UDim2.new(1, -24, 0, 62); goldLabel.Size = UDim2.fromOffset(300, 20); goldLabel.TextSize = 16
local leaveBtn = DarkUI.button(nav, "WALK AROUND  [M]", "stone", 15)
leaveBtn.AnchorPoint = Vector2.new(1, 0)
leaveBtn.Position = UDim2.new(1, -20, 0, 14); leaveBtn.Size = UDim2.fromOffset(176, 40); leaveBtn.ZIndex = 8
-- the main game's wallet (what every run pays into), beside the vault's gold
local wallet = {at = 0}
wallet.label = T(nav, "", 14, Color3.fromRGB(226, 230, 240), SEMI)
wallet.label.AnchorPoint = Vector2.new(1, 0)
wallet.label.Position = UDim2.new(1, -190, 0, 63); wallet.label.Size = UDim2.fromOffset(380, 18); wallet.label.ZIndex = 6
wallet.label.TextXAlignment = Enum.TextXAlignment.Right
function wallet.refresh()
	if os.clock() - wallet.at < 5 then return end
	wallet.at = os.clock()
	task.spawn(function()
		local ok, res = pcall(hubRemote.InvokeServer, hubRemote, "State")
		local prof = ok and type(res) == "table" and res.profile
		if not prof then return end
		local w = prof.wallet or {}
		local function n(v) v = math.floor(tonumber(v) or 0); local s = tostring(v); local k; repeat s, k = s:gsub("^(-?%d+)(%d%d%d)", "%1,%2") until k == 0; return s end
		wallet.label.Text = string.format("LVL %d   ·   %s MARKS   ·   %s CROWNS", prof.level or 1, n(w.marks), n(w.crowns))
	end)
end
local toast = T(root, "", 16, C.GOLD2, SEMI)
toast.AnchorPoint = Vector2.new(0.5, 1)
toast.Position = UDim2.new(0.5, 0, 1, -16); toast.Size = UDim2.fromOffset(900, 22); toast.ZIndex = 40
toast.TextStrokeTransparency = 0.3

local pages = {}
for _, name in ipairs(TABS) do
	local p = Instance.new("Frame")
	p.Name = name
	p.BackgroundTransparency = 1
	p.Position = UDim2.fromOffset(0, 92)
	p.Size = UDim2.new(1, 0, 1, -92)
	p.Visible = false
	p.Parent = root
	pages[name] = p
end

--------------------------------------------------------------------
--  STATE
--------------------------------------------------------------------
local view, party = nil, nil
local tab, mode = "Play", "Deadvault"
local selected = nil          -- {uid, where = "stash" | "kit", card}
local classSel = nil
local merchant = "Smith"
local open = false
local render                  -- (forward)

local function say(msg, good)
	toast.Text = msg or ""
	toast.TextColor3 = good == false and C.BAD or C.GOLD2
	task.delay(3, function() if toast.Text == msg then toast.Text = "" end end)
end
local function call(kind, arg)
	local ok, res = pcall(function() return vaultRemote:InvokeServer(kind, arg) end)
	if not ok or type(res) ~= "table" then say("The vault didn't answer", false); return nil end
	if res.msg then say(res.msg, res.ok) end
	if res.view then view = res.view end
	return res
end
local function hub(op, ...)
	local ok, res = pcall(hubRemote.InvokeServer, hubRemote, op, ...)
	if not ok or type(res) ~= "table" then return {ok = false} end
	return res
end
local function fmt(n) n = math.floor(n or 0); local s = tostring(n); local k; repeat s, k = s:gsub("^(-?%d+)(%d%d%d)", "%1,%2") until k == 0; return s end

-- a mannequin: you (or a party member) as a class, through the Courtyard's menu (HubMenu's _G.HubDressed)
local function dressed(userId, classId, o)
	if _G.HubDressed then
		local ok, m = pcall(_G.HubDressed, userId, classId, o)
		if ok and m then return m end
	end
	local lo = table.clone(o and o.loadout or {})
	local cdef = GameConfig.CLASSES[classId] or {}
	for _, slot in ipairs({"helmet", "top", "bottom"}) do
		if not lo[slot] then local pc = Catalog.defaultPiece(slot, cdef.weight or "Light", cdef.starter); lo[slot] = pc and pc.id or nil end
	end
	local ok2, m2 = pcall(PreviewRig.dressedRig, {loadout = lo, appearance = Catalog.BODY.defaults, weight = cdef.weight or "Light", weapon = o and o.weapon == true})
	return ok2 and m2 or nil
end
-- your kit as a loadout to dress in: its first weapon in hand, its armour's set on
local function kitLoadout()
	local lo = {}
	local w1 = nil
	for _, c in ipairs(view and view.kit or {}) do if c.slot == "weapon1" then w1 = c end end
	if w1 then lo.weapon, lo.weaponSkin = w1.weapon, w1.skin
	elseif view and view.freeIds and view.freeIds[1] then lo.weapon = view.freeIds[1] end
	for _, c in ipairs(view and view.kit or {}) do
		if c.slot == "armor" and c.armor then
			local a = Catalog.LOOT.ARMOR_BY[c.armor]
			if a and a.set then for _, pc in ipairs(Catalog.setPieces(a.set)) do lo[pc.slot] = pc.id end end
		end
	end
	return lo
end

-- a 3D stage in a frame: a mannequin, lit, slowly turning
local function stage(parent, model, opts)
	opts = opts or {}
	local vp = Instance.new("ViewportFrame")
	vp.BackgroundTransparency = 1
	vp.Size = opts.size or UDim2.fromScale(1, 1)
	vp.Position = opts.pos or UDim2.new()
	vp.Ambient = Color3.fromRGB(150, 150, 162)
	vp.LightColor = Color3.fromRGB(255, 246, 232)
	vp.LightDirection = Vector3.new(-0.5, -0.7, -1)
	vp.ZIndex = opts.z or 2
	vp.Parent = parent
	local world = Instance.new("WorldModel"); world.Parent = vp
	local cam = Instance.new("Camera"); cam.FieldOfView = opts.fov or 30; cam.Parent = vp
	vp.CurrentCamera = cam
	if model then
		model.Parent = world
		-- (a rig faces -Z: the camera's side; `yaw` turns it a little)
		local cf = opts.at or CFrame.Angles(0, math.rad(opts.yaw or 14), 0)
		model:PivotTo(cf)
		local bcf, size = model:GetBoundingBox()
		local focus = bcf.Position + Vector3.new(0, opts.lift or 0, 0)
		local h = (opts.bust and size.Y * 0.32) or size.Y * 0.62
		local d = h / math.tan(math.rad((opts.fov or 30) / 2))
		if opts.bust then focus = bcf.Position + Vector3.new(0, size.Y * 0.32, 0) end
		cam.CFrame = CFrame.lookAt(focus + Vector3.new(0, 0.2, -d), focus)
		if opts.spin then
			-- (a slow sway, never its back to you)
			local base = opts.yaw or 14
			local t0 = os.clock()
			local conn
			conn = RunService.RenderStepped:Connect(function()
				if not vp.Parent then conn:Disconnect(); return end
				if not open then return end
				model:PivotTo(CFrame.Angles(0, math.rad(base + math.sin((os.clock() - t0) * 0.6) * opts.spin), 0))
			end)
		end
	end
	-- a floor of light under them
	local floor = frame(parent, C.BLUE, 0.7)
	floor.AnchorPoint = Vector2.new(0.5, 1)
	floor.Position = UDim2.new(0.5, 0, 1, -6)
	floor.Size = UDim2.new(0.7, 0, 0, 30)
	floor.ZIndex = 1
	local fc = Instance.new("UICorner"); fc.CornerRadius = UDim.new(1, 0); fc.Parent = floor
	return vp
end

--------------------------------------------------------------------
--  PLAY: the back room of the tavern, your party at the table
--------------------------------------------------------------------
local PLAY = pages.Play
local tavern, tavernCam, seats = nil, nil, {}
local TAV = Vector3.new(4000, 1400, 4000)
local savedLight
local function buildTavern()
	if tavern then return end
	tavern = Instance.new("Model")
	tavern.Name = "DungeonLobby"
	local function p(size, cf, color, mat, shape)
		local q = Instance.new("Part")
		q.Anchored, q.CanCollide, q.CanQuery, q.CanTouch, q.CastShadow = true, false, false, false, true
		q.Size, q.CFrame, q.Color, q.Material = size, CFrame.new(TAV) * cf, color, mat or Enum.Material.WoodPlanks
		if shape then q.Shape = shape end
		q.TopSurface, q.BottomSurface = Enum.SurfaceType.Smooth, Enum.SurfaceType.Smooth
		q.Parent = tavern
		return q
	end
	local wood, dark, stone = Color3.fromRGB(86, 60, 40), Color3.fromRGB(46, 32, 22), Color3.fromRGB(70, 64, 58)
	p(Vector3.new(60, 1, 60), CFrame.new(0, -0.5, 0), Color3.fromRGB(60, 42, 28))
	p(Vector3.new(60, 22, 2), CFrame.new(0, 10, 18), stone, Enum.Material.Cobblestone)
	p(Vector3.new(2, 22, 60), CFrame.new(-22, 10, 0), stone, Enum.Material.Cobblestone)
	p(Vector3.new(2, 22, 60), CFrame.new(22, 10, 0), stone, Enum.Material.Cobblestone)
	p(Vector3.new(60, 1, 60), CFrame.new(0, 20, 0), dark)
	for x = -18, 18, 9 do p(Vector3.new(1.6, 1.6, 60), CFrame.new(x, 19, 0), dark, Enum.Material.Wood) end
	-- the round table, the candles on it
	p(Vector3.new(0.6, 10, 10), CFrame.new(0, 1.9, 8.5) * CFrame.Angles(0, 0, math.pi / 2), wood, Enum.Material.WoodPlanks, Enum.PartType.Cylinder)
	p(Vector3.new(1.6, 2.2, 2.2), CFrame.new(0, 0.8, 8.5) * CFrame.Angles(0, 0, math.pi / 2), dark, Enum.Material.Wood, Enum.PartType.Cylinder)
	local function candle(at, h)
		p(Vector3.new(h, 0.5, 0.5), CFrame.new(at + Vector3.new(0, h / 2, 0)) * CFrame.Angles(0, 0, math.pi / 2), Color3.fromRGB(236, 226, 196), Enum.Material.SmoothPlastic, Enum.PartType.Cylinder)
		local f = p(Vector3.new(0.3, 0.45, 0.3), CFrame.new(at + Vector3.new(0, h + 0.25, 0)), Color3.fromRGB(255, 200, 110), Enum.Material.Neon)
		local l = Instance.new("PointLight"); l.Color = Color3.fromRGB(255, 160, 80); l.Range = 13; l.Brightness = 1.25; l.Shadows = true; l.Parent = f
		local fire = Instance.new("Fire"); fire.Size = 0.6; fire.Heat = 3; fire.Color = Color3.fromRGB(255, 170, 80); fire.SecondaryColor = Color3.fromRGB(255, 90, 30); fire.Parent = f
	end
	candle(Vector3.new(3.4, 2.2, 7.7), 1.2)
	candle(Vector3.new(-3.6, 2.2, 7.3), 0.8)
	candle(Vector3.new(-12, 6.4, 15), 1.4)
	candle(Vector3.new(14, 6.4, 15), 1)
	-- (a lamp over the table: the faces round it lit warm)
	local lamp = p(Vector3.new(1.4, 1.4, 1.4), CFrame.new(0, 11, 2.5), Color3.fromRGB(255, 200, 120), Enum.Material.Neon, Enum.PartType.Ball)
	lamp.Transparency = 1
	local ll = Instance.new("SpotLight"); ll.Face = Enum.NormalId.Bottom; ll.Angle = 80; ll.Range = 24; ll.Brightness = 2.4; ll.Color = Color3.fromRGB(255, 196, 130); ll.Shadows = true; ll.Parent = lamp
	local fill = p(Vector3.new(0.5, 0.5, 0.5), CFrame.new(0, 6, -3), Color3.fromRGB(255, 200, 120), Enum.Material.SmoothPlastic, Enum.PartType.Ball)
	fill.Transparency = 1
	local fl = Instance.new("PointLight"); fl.Range = 18; fl.Brightness = 0.9; fl.Color = Color3.fromRGB(255, 190, 140); fl.Parent = fill
	-- a helm on the table, a map, mugs
	p(Vector3.new(2.2, 0.06, 1.6), CFrame.new(1.8, 2.23, 6.7) * CFrame.Angles(0, 0.4, 0), Color3.fromRGB(200, 180, 140), Enum.Material.SmoothPlastic)
	p(Vector3.new(1.3, 1.3, 1.3), CFrame.new(-2.6, 2.8, 8.9), Color3.fromRGB(120, 124, 130), Enum.Material.Metal, Enum.PartType.Ball)
	-- barrels, shelves, a hearth behind
	for i, x in ipairs({-17, -13.5, 15}) do p(Vector3.new(3.4, 2.6, 2.6), CFrame.new(x, 1.7, 14 - (i % 2) * 2) * CFrame.Angles(0, 0, math.pi / 2), wood, Enum.Material.Wood, Enum.PartType.Cylinder) end
	p(Vector3.new(10, 0.5, 2), CFrame.new(-14, 6, 16), dark, Enum.Material.Wood)
	p(Vector3.new(10, 0.5, 2), CFrame.new(14, 6, 16), dark, Enum.Material.Wood)
	-- the hearth: a stone surround, a mantle, embers deep in it
	p(Vector3.new(10, 9, 2), CFrame.new(9, 4.5, 17), stone, Enum.Material.Slate)
	p(Vector3.new(11, 0.8, 2.8), CFrame.new(9, 6.2, 16.4), dark, Enum.Material.Wood)
	p(Vector3.new(6, 4.6, 1.4), CFrame.new(9, 2.3, 16.2), Color3.fromRGB(14, 10, 8), Enum.Material.Slate)
	for i = -1, 1 do p(Vector3.new(0.7, 0.7, 2.4), CFrame.new(9 + i * 1.2, 0.6, 15.4) * CFrame.Angles(0, i * 0.5, 0), Color3.fromRGB(70, 44, 28), Enum.Material.Wood) end
	local hearth = p(Vector3.new(3.6, 0.5, 1.6), CFrame.new(9, 0.4, 15.6), Color3.fromRGB(190, 70, 20), Enum.Material.Neon)
	local hl = Instance.new("PointLight"); hl.Color = Color3.fromRGB(255, 110, 40); hl.Range = 22; hl.Brightness = 1; hl.Shadows = true; hl.Parent = hearth
	local hf = Instance.new("Fire"); hf.Size = 5; hf.Heat = 8; hf.Parent = hearth
	-- where the party stands: before the table, facing you
	seats = {}
	for i, x in ipairs({0, -4.8, 4.8}) do
		local z = i == 1 and 1.0 or 1.8
		-- (each turned to face the camera: a rig looks down its -Z)
		seats[i] = CFrame.lookAt(TAV + Vector3.new(x, 0, z), TAV + Vector3.new(0, 0, -8.5))
	end
	tavern.Parent = workspace
	tavernCam = CFrame.lookAt(TAV + Vector3.new(0, 4.4, -8.5), TAV + Vector3.new(0, 3.3, 3))
end

-- the scene's mood while you're in it (a client's own lighting: put back after)
local function moody(on)
	if on and not savedLight then
		savedLight = {ClockTime = Lighting.ClockTime, Brightness = Lighting.Brightness, Ambient = Lighting.Ambient, OutdoorAmbient = Lighting.OutdoorAmbient,
			ExposureCompensation = Lighting.ExposureCompensation}
		local atmo = Lighting:FindFirstChildOfClass("Atmosphere")
		if atmo then savedLight.atmo = {atmo, atmo.Density, atmo.Haze, atmo.Glare} ; atmo.Density, atmo.Haze, atmo.Glare = 0.12, 0, 0 end
		Lighting.ClockTime, Lighting.Brightness = 0, 0
		Lighting.Ambient, Lighting.OutdoorAmbient = Color3.fromRGB(62, 50, 42), Color3.fromRGB(40, 34, 30)
		Lighting.ExposureCompensation = 0
	elseif not on and savedLight then
		local atmo = savedLight.atmo
		savedLight.atmo = nil
		if atmo and atmo[1].Parent then atmo[1].Density, atmo[1].Haze, atmo[1].Glare = atmo[2], atmo[3], atmo[4] end
		for k, v in pairs(savedLight) do Lighting[k] = v end
		savedLight = nil
	end
end

local seatRigs, seatTags = {}, {}
local function seatTag(i, line1, line2, crown, ready)
	local bb = seatTags[i]
	-- (a respawn empties PlayerGui of anything that resets: these don't, and are remade if gone)
	if not (bb and bb.Parent) then
		bb = Instance.new("BillboardGui")
		bb.Name = "LobbySeatTag"
		bb.ResetOnSpawn = false
		bb.Size = UDim2.fromOffset(260, 64)
		bb.StudsOffsetWorldSpace = Vector3.new(0, 3.6, 0)
		bb.AlwaysOnTop = true
		bb.LightInfluence = 0
		bb.Parent = player.PlayerGui
		local a = T(bb, "", 15, C.GOLD, SEMI); a.Name = "A"; a.Size = UDim2.new(1, 0, 0, 20)
		local b = T(bb, "", 18, C.TEXT, BOLD); b.Name = "B"; b.Position = UDim2.fromOffset(0, 22); b.Size = UDim2.new(1, 0, 0, 22)
		local r = DarkUI.rule(bb, 50, 200)
		seatTags[i] = bb
	end
	bb.A.Text = line1
	bb.B.Text = (crown and "♛ " or "") .. line2 .. (ready and "  ✓" or "")
	bb.B.TextColor3 = ready and C.GOOD or C.TEXT
	return bb
end

local function memberList()
	if party and party.members then return party.members end
	local p = view and view.class or "Knight"
	return {{id = player.UserId, name = player.DisplayName, leader = true, ready = false, class = p, level = nil}}
end

local function drawSeats()
	buildTavern()
	for _, m in pairs(seatRigs) do m:Destroy() end
	seatRigs = {}
	local list = memberList()
	for i = 1, 3 do
		local m = list[i]
		local bb = seatTags[i]
		if m then
			local cls = m.class or "Knight"
			local rig = dressed(m.id, cls, {weapon = true, loadout = m.id == player.UserId and kitLoadout() or nil})
			if rig then
				for _, d in ipairs(rig:GetDescendants()) do if d:IsA("BasePart") then d.Anchored = true; d.CanCollide = false end end
				rig.Parent = workspace
				rig:PivotTo(seats[i] + Vector3.new(0, 3, 0))
				seatRigs[i] = rig
				local head = rig:FindFirstChild("Head")
				local tag = seatTag(i, "- Lobby -", string.format("%s%s · %s", m.level and ("Lv." .. m.level .. " ") or "", (GameConfig.CLASSES[cls] or {}).name or cls, m.name or "?"), m.leader, m.ready or m.leader)
				tag.Adornee = head
				tag.Enabled = true
			end
		elseif bb then
			bb.Enabled = false
		end
	end
end

-- the dungeon card, READY, the party's buttons
local dungeonCard = DarkUI.panel(PLAY, {corners = true})
dungeonCard.Position = UDim2.new(0, 28, 1, -270); dungeonCard.Size = UDim2.fromOffset(380, 172)
local dTitle = T(dungeonCard, "Select Dungeon", 14, C.DIM, SEMI)
dTitle.Position = UDim2.fromOffset(0, 10); dTitle.Size = UDim2.new(1, 0, 0, 18)
local dPic = Instance.new("ImageLabel")
dPic.BackgroundColor3 = C.INSET
dPic.BorderSizePixel = 0
dPic.Position = UDim2.fromOffset(14, 34); dPic.Size = UDim2.new(1, -28, 0, 92)
dPic.ScaleType = Enum.ScaleType.Crop
dPic.ImageColor3 = Color3.fromRGB(200, 190, 175)
dPic.Parent = dungeonCard
DarkUI.stroke(dPic, C.EDGE2, 1)
local dName = T(dPic, "", 20, C.TEXT, BOLD)
dName.AnchorPoint = Vector2.new(0.5, 1); dName.Position = UDim2.new(0.5, 0, 1, -6); dName.Size = UDim2.new(1, 0, 0, 24)
dName.TextStrokeTransparency = 0.2
local dMode = T(dungeonCard, "", 13, C.GOLD, SEMI)
dMode.Position = UDim2.fromOffset(0, 132); dMode.Size = UDim2.new(1, 0, 0, 18)
local prevD = DarkUI.button(dungeonCard, "<", "stone", 18)
prevD.Position = UDim2.fromOffset(18, 128); prevD.Size = UDim2.fromOffset(34, 28)
local nextD = DarkUI.button(dungeonCard, ">", "stone", 18)
nextD.AnchorPoint = Vector2.new(1, 0); nextD.Position = UDim2.new(1, -18, 0, 128); nextD.Size = UDim2.fromOffset(34, 28)
local readyBtn = DarkUI.button(PLAY, "Ready", "gold", 30)
readyBtn.Position = UDim2.new(0, 28, 1, -88); readyBtn.Size = UDim2.fromOffset(380, 70)
local riskLine = T(PLAY, "", 14, C.DIM, SEMI)
riskLine.AnchorPoint = Vector2.new(0.5, 1); riskLine.Position = UDim2.new(0.5, 0, 1, -54); riskLine.Size = UDim2.fromOffset(700, 20)
local sideBtns = Instance.new("Frame")
sideBtns.BackgroundTransparency = 1
sideBtns.AnchorPoint = Vector2.new(1, 1)
sideBtns.Position = UDim2.new(1, -28, 1, -24); sideBtns.Size = UDim2.fromOffset(520, 70)
sideBtns.Parent = PLAY
local sbl = Instance.new("UIListLayout"); sbl.FillDirection = Enum.FillDirection.Horizontal; sbl.HorizontalAlignment = Enum.HorizontalAlignment.Right; sbl.Padding = UDim.new(0, 10); sbl.Parent = sideBtns
local inviteBtn = DarkUI.button(sideBtns, "Invite", "stone", 16); inviteBtn.Size = UDim2.fromOffset(120, 64)
local exitPartyBtn = DarkUI.button(sideBtns, "Exit Party", "red", 16); exitPartyBtn.Size = UDim2.fromOffset(120, 64)
local classBtn = DarkUI.button(sideBtns, "Class Change", "stone", 16); classBtn.Size = UDim2.fromOffset(130, 64)
local stashBtn = DarkUI.button(sideBtns, "Stash", "stone", 16); stashBtn.Size = UDim2.fromOffset(110, 64)

local DUNGEONS = {
	{key = "Depths", name = "The Depths", sub = "PvE  ·  1–4  ·  three floors and a boss  ·  escape between floors", shot = "BoneCrypt"},
	{key = "Deadvault", name = "Deadvault", sub = "PvPvE  ·  parties  ·  loot it, get out alive", shot = "CrimsonManor"},
}
local function dungeonDef() for _, d in ipairs(DUNGEONS) do if d.key == mode then return d end end; return DUNGEONS[2] end
local function shotOf(key)
	local f = ReplicatedStorage:FindFirstChild("MapShots")
	local v = f and f:FindFirstChild(key)
	return v and v:IsA("StringValue") and v.Value or ""
end

local function drawPlay()
	local d = dungeonDef()
	dName.Text = d.name
	dMode.Text = d.sub
	dPic.Image = shotOf(d.shot)
	local list = memberList()
	local leader = not party or party.leaderId == player.UserId
	local me
	for _, m in ipairs(list) do if m.id == player.UserId then me = m end end
	readyBtn.Text = leader and ("Enter " .. d.name) or ((me and me.ready) and "Not Ready" or "Ready")
	exitPartyBtn.Visible = party ~= nil and #list > 1
	-- what's at risk
	local n = 0
	for _, c in ipairs(view and view.kit or {}) do if not c.free then n += 1 end end
	riskLine.Text = n > 0 and string.format("%d THING%s IN YOUR KIT GO IN WITH YOU  ·  GET OUT TO KEEP THEM", n, n == 1 and "" or "S") or "NO KIT: YOU GO IN WITH THE FREE ONE (NOTHING TO LOSE)"
	drawSeats()
end
prevD.Activated:Connect(function() mode = mode == "Depths" and "Deadvault" or "Depths"; drawPlay() end)
nextD.Activated:Connect(function() mode = mode == "Depths" and "Deadvault" or "Depths"; drawPlay() end)
readyBtn.Activated:Connect(function()
	local leader = not party or party.leaderId == player.UserId
	if leader then
		if _G.HubGoDoor then
			say("Into the dark…", true)
			local ok = pcall(_G.HubGoDoor, mode)
			if ok then task.delay(0.6, function() if open then _G.CloseDungeon() end end) end
		else
			local r = hub("Play", mode)
			if r.msg then say(r.msg, r.ok) end
		end
	else
		local me
		for _, m in ipairs(memberList()) do if m.id == player.UserId then me = m end end
		local r = hub("PartyReady", not (me and me.ready))
		if r.party then party = r.party end
		drawPlay()
	end
end)
exitPartyBtn.Activated:Connect(function() hub("PartyLeave"); party = nil; drawPlay() end)
classBtn.Activated:Connect(function() tab = "Class"; render() end)
stashBtn.Activated:Connect(function() tab = "Stash"; render() end)

-- the friends you can call to the table
local inviteBox = DarkUI.panel(root, {title = "Invite"})
inviteBox.AnchorPoint = Vector2.new(0.5, 0.5); inviteBox.Position = UDim2.fromScale(0.5, 0.52); inviteBox.Size = UDim2.fromOffset(420, 460)
inviteBox.Visible = false; inviteBox.ZIndex = 30
local inviteList = Instance.new("ScrollingFrame")
inviteList.BackgroundTransparency = 1; inviteList.BorderSizePixel = 0
inviteList.Position = UDim2.fromOffset(16, 54); inviteList.Size = UDim2.new(1, -32, 1, -112)
inviteList.CanvasSize = UDim2.new(); inviteList.AutomaticCanvasSize = Enum.AutomaticSize.Y; inviteList.ScrollBarThickness = 4
inviteList.ZIndex = 31
inviteList.Parent = inviteBox
local ill = Instance.new("UIListLayout"); ill.Padding = UDim.new(0, 6); ill.Parent = inviteList
local inviteClose = DarkUI.button(inviteBox, "Close", "stone", 15)
inviteClose.AnchorPoint = Vector2.new(0.5, 1); inviteClose.Position = UDim2.new(0.5, 0, 1, -14); inviteClose.Size = UDim2.fromOffset(140, 36); inviteClose.ZIndex = 31
inviteClose.Activated:Connect(function() inviteBox.Visible = false end)
inviteBtn.Activated:Connect(function()
	inviteBox.Visible = true
	for _, c in ipairs(inviteList:GetChildren()) do if c:IsA("GuiObject") then c:Destroy() end end
	local r = hub("Friends")
	local any = false
	for _, fd in ipairs(r.friends or {}) do
		any = true
		local row = DarkUI.button(inviteList, (fd.display or fd.name or "?") .. (fd.here and "   · here" or ""), "stone", 15)
		row.Size = UDim2.new(1, -6, 0, 40); row.ZIndex = 32
		row.TextXAlignment = Enum.TextXAlignment.Left
		local pad = Instance.new("UIPadding"); pad.PaddingLeft = UDim.new(0, 12); pad.Parent = row
		row.Activated:Connect(function()
			local res = hub("PartyInvite", fd.id, fd.name)
			say(res.msg or "", res.ok)
			if res.party then party = res.party; drawPlay() end
		end)
	end
	if not any then
		local l = T(inviteList, "No friends online. They can join you from the Courtyard's party panel.", 14, C.DIM)
		l.Size = UDim2.new(1, -6, 0, 60); l.TextWrapped = true; l.ZIndex = 32
	end
end)

--------------------------------------------------------------------
--  CLASS: the list, you as it, its story, its perks
--------------------------------------------------------------------
local CLASSP = pages.Class
local CLASS_INFO = {
	Knight = {motto = "'An Iron Wall'", lines = {"+ The most health and armour of anyone", "+ Great weapons, great blows", "- Slow, and short of breath", "- Clumsy, costly dodges"}},
	Footman = {motto = "'The Soldier's Soldier'", lines = {"+ Quick enough, tough enough", "+ Spear or sword, all the same to them", "+ A good back for a heavy bag", "- Master of nothing"}},
	Vanguard = {motto = "'First In, Last Out'", lines = {"+ The fastest on their feet", "+ Endless wind, long cheap dodges", "+ Born to sneak and strike first", "- No armour: one mistake from death"}},
	Archer = {motto = "'Death From the Dark'", lines = {"+ A bow or a crossbow, and a sidearm", "+ Light and quiet", "- Little health, nothing to stop a blade", "- Weak once they close in"}},
	Mage = {motto = "'The Last Word'", lines = {"+ Fire, frost, lightning, mending", "+ A ward that turns blows into mana", "- The least health of all", "- Only a wand at the hip"}},
}
local listPage = DarkUI.parchment(CLASSP)
listPage.Position = UDim2.fromOffset(30, 10); listPage.Size = UDim2.fromOffset(390, 760)
local listTitle = T(listPage, "Class List", 26, C.INK, BOLD)
listTitle.Position = UDim2.fromOffset(0, 18); listTitle.Size = UDim2.new(1, 0, 0, 32)
local listGrid = Instance.new("Frame")
listGrid.BackgroundTransparency = 1
listGrid.Position = UDim2.fromOffset(30, 80); listGrid.Size = UDim2.new(1, -60, 1, -110)
listGrid.Parent = listPage
local lgl = Instance.new("UIGridLayout"); lgl.CellSize = UDim2.fromOffset(150, 190); lgl.CellPadding = UDim2.fromOffset(30, 26); lgl.SortOrder = Enum.SortOrder.LayoutOrder; lgl.Parent = listGrid
local centre = Instance.new("Frame")
centre.BackgroundTransparency = 1
centre.Position = UDim2.fromOffset(440, 0); centre.Size = UDim2.fromOffset(720, 800)
centre.Parent = CLASSP
local selLine = T(centre, "SELECT CLASS", 14, C.GOLD, BOLD)
selLine.Position = UDim2.fromOffset(0, 8); selLine.Size = UDim2.new(1, 0, 0, 18)
local cName = T(centre, "", 44, C.TEXT, BOLD)
cName.Position = UDim2.fromOffset(0, 26); cName.Size = UDim2.new(1, 0, 0, 52)
DarkUI.rule(centre, 84, 520)
local cMotto = T(centre, "", 18, C.TEXT)
cMotto.Position = UDim2.fromOffset(0, 98); cMotto.Size = UDim2.new(1, 0, 0, 24)
local cStage = Instance.new("Frame")
cStage.BackgroundTransparency = 1
cStage.Position = UDim2.fromOffset(110, 130); cStage.Size = UDim2.fromOffset(500, 560)
cStage.Parent = centre
local confirmBtn = DarkUI.button(centre, "Confirm", "gold", 24)
confirmBtn.AnchorPoint = Vector2.new(0.5, 0); confirmBtn.Position = UDim2.new(0.5, 0, 0, 704); confirmBtn.Size = UDim2.fromOffset(300, 56)
local infoPage = DarkUI.parchment(CLASSP)
infoPage.AnchorPoint = Vector2.new(1, 0); infoPage.Position = UDim2.new(1, -30, 0, 10); infoPage.Size = UDim2.fromOffset(400, 760)
local infoTitle = T(infoPage, "Class Info", 26, C.INK, BOLD)
infoTitle.Position = UDim2.fromOffset(0, 18); infoTitle.Size = UDim2.new(1, 0, 0, 32)
local infoBody = T(infoPage, "", 15, C.INK)
infoBody.Position = UDim2.fromOffset(30, 64); infoBody.Size = UDim2.new(1, -60, 0, 250)
infoBody.TextWrapped = true; infoBody.TextXAlignment = Enum.TextXAlignment.Right; infoBody.TextYAlignment = Enum.TextYAlignment.Top
infoBody.TextStrokeTransparency = 1
local perkTitle = T(infoPage, "Perks", 24, C.INK, BOLD)
perkTitle.Position = UDim2.fromOffset(0, 326); perkTitle.Size = UDim2.new(1, 0, 0, 30)
local perkNote = T(infoPage, "", 13, C.INK)
perkNote.Position = UDim2.fromOffset(0, 356); perkNote.Size = UDim2.new(1, 0, 0, 18); perkNote.TextStrokeTransparency = 1
local perkGrid = Instance.new("Frame")
perkGrid.BackgroundTransparency = 1
perkGrid.Position = UDim2.fromOffset(30, 384); perkGrid.Size = UDim2.new(1, -60, 0, 250)
perkGrid.Parent = infoPage
local pgl = Instance.new("UIGridLayout"); pgl.CellSize = UDim2.fromOffset(100, 118); pgl.CellPadding = UDim2.fromOffset(16, 8); pgl.HorizontalAlignment = Enum.HorizontalAlignment.Center; pgl.Parent = perkGrid
local skillTitle = T(infoPage, "Skill", 24, C.INK, BOLD)
skillTitle.Position = UDim2.fromOffset(0, 640); skillTitle.Size = UDim2.new(1, 0, 0, 30)
local skillLine = T(infoPage, "", 14, C.INK)
skillLine.Position = UDim2.fromOffset(30, 672); skillLine.Size = UDim2.new(1, -60, 0, 60); skillLine.TextWrapped = true; skillLine.TextStrokeTransparency = 1

local function drawClass()
	classSel = classSel or (view and view.class) or "Knight"
	for _, c in ipairs(listGrid:GetChildren()) do if c:IsA("GuiObject") then c:Destroy() end end
	for i, cl in ipairs(view and view.classes or {}) do
		local cell = Instance.new("TextButton")
		cell.Text = ""
		cell.BackgroundTransparency = 1
		cell.LayoutOrder = i
		cell.Parent = listGrid
		local name = T(cell, cl.name, 18, cl.id == classSel and C.GOLD2 or C.DIM, BOLD)
		name.Size = UDim2.new(1, 0, 0, 20)
		local face = DarkUI.slot(cell)
		face.Position = UDim2.fromOffset(10, 24); face.Size = UDim2.fromOffset(130, 156)
		DarkUI.stroke(face, cl.id == classSel and C.GOLD2 or C.EDGE2, cl.id == classSel and 3 or 1.5)
		local rig = dressed(player.UserId, cl.id, {})
		if rig then stage(face, rig, {bust = true, yaw = 10, fov = 24}) end
		if not cl.open then
			local lock = frame(face, Color3.new(0, 0, 0), 0.45); lock.Size = UDim2.fromScale(1, 1); lock.ZIndex = 4
			local lt = T(lock, "Locked\nLevel 5", 14, C.TEXT, BOLD); lt.Size = UDim2.fromScale(1, 1); lt.ZIndex = 5
		end
		cell.Activated:Connect(function() classSel = cl.id; render() end)
	end
	local def = GameConfig.CLASSES[classSel] or {}
	local info = CLASS_INFO[classSel] or {motto = "", lines = {}}
	cName.Text = def.name or classSel
	cMotto.Text = info.motto
	for _, c in ipairs(cStage:GetChildren()) do c:Destroy() end
	local rig = dressed(player.UserId, classSel, {weapon = true})
	if rig then stage(cStage, rig, {yaw = 12, spin = 18, fov = 26}) end
	infoBody.Text = (def.description or "") .. "\n\n" .. table.concat(info.lines, "\n")
	-- its perks
	for _, c in ipairs(perkGrid:GetChildren()) do if c:IsA("GuiObject") then c:Destroy() end end
	local list = view and view.perks and view.perks[classSel] or {}
	local on = 0
	for _, pk in ipairs(list) do if pk.on then on += 1 end end
	perkNote.Text = string.format("%d of %d chosen  ·  they go into the dungeon with you", on, view and view.perkPick or 2)
	for _, pk in ipairs(list) do
		local cell = Instance.new("TextButton")
		cell.Text = ""; cell.BackgroundTransparency = 1
		cell.Parent = perkGrid
		local d = frame(cell, pk.on and Color3.fromRGB(86, 64, 22) or C.INSET)
		d.AnchorPoint = Vector2.new(0.5, 0); d.Position = UDim2.new(0.5, 0, 0, 10); d.Size = UDim2.fromOffset(62, 62); d.Rotation = 45
		DarkUI.corner(d, 10)
		DarkUI.stroke(d, pk.on and C.GOLD2 or C.EDGE2, pk.on and 3 or 1.5)
		local ic = DarkUI.icon(cell, pk.look or {kind = "relic"}, {size = UDim2.fromOffset(58, 58), pos = UDim2.new(0.5, -29, 0, 13), z = 3})
		local nm = T(cell, pk.name, 12, C.INK, BOLD); nm.Position = UDim2.fromOffset(0, 94); nm.Size = UDim2.new(1, 0, 0, 22); nm.TextWrapped = true; nm.TextStrokeTransparency = 1
		cell.MouseEnter:Connect(function() tip:show({name = pk.name, sub = pk.on and "Chosen" or "Click to choose", lines = {pk.text}}) end)
		cell.MouseLeave:Connect(function() tip:hide() end)
		cell.Activated:Connect(function() tip:hide(); call("Perk", {classSel, pk.id}); render() end)
	end
	-- its skill: the class's power
	local pw = Catalog.POWERS and Catalog.POWERS.byClass and Catalog.POWERS.byClass[classSel]
	local first = pw and pw[1]
	skillLine.Text = first and (first.name .. ": " .. (first.desc or first.description or "")) or ""
	confirmBtn.Text = (view and view.class == classSel) and "Chosen" or "Confirm"
end
confirmBtn.Activated:Connect(function()
	if view and view.class ~= classSel then call("Class", classSel); render() end
end)

--------------------------------------------------------------------
--  STASH: you in your kit, the kit, the stash
--------------------------------------------------------------------
local STASHP = pages.Stash
local charPanel = DarkUI.panel(STASHP)
charPanel.Position = UDim2.fromOffset(24, 6); charPanel.Size = UDim2.fromOffset(420, 780)
local charStage = Instance.new("Frame")
charStage.BackgroundTransparency = 1
charStage.Position = UDim2.fromOffset(20, 20); charStage.Size = UDim2.new(1, -40, 0, 440)
charStage.Parent = charPanel
local charName = T(charPanel, "", 22, C.GOLD2, BOLD)
charName.Position = UDim2.fromOffset(0, 466); charName.Size = UDim2.new(1, 0, 0, 28)
DarkUI.rule(charPanel, 498, 300)
local statList = Instance.new("Frame")
statList.BackgroundTransparency = 1
statList.Position = UDim2.fromOffset(30, 512); statList.Size = UDim2.new(1, -60, 0, 250)
statList.Parent = charPanel
local stl = Instance.new("UIListLayout"); stl.Padding = UDim.new(0, 2); stl.SortOrder = Enum.SortOrder.LayoutOrder; stl.Parent = statList

local kitPanel = DarkUI.panel(STASHP)
kitPanel.Position = UDim2.fromOffset(456, 6); kitPanel.Size = UDim2.fromOffset(500, 780)
local kitTitle = T(kitPanel, "YOUR KIT", 20, C.TEXT, BOLD)
kitTitle.Position = UDim2.fromOffset(0, 12); kitTitle.Size = UDim2.new(1, 0, 0, 26)
DarkUI.rule(kitPanel, 40, 360)
local SLOTDEF = {
	weapon1 = {x = 26, y = 58, w = 110, h = 236, label = "1", upright = true},
	weapon2 = {x = 364, y = 58, w = 110, h = 236, label = "2", upright = true},
	armor = {x = 175, y = 74, w = 150, h = 170, label = "ARMOUR"},
	relic1 = {x = 160, y = 258, w = 54, h = 54, label = "R"}, relic2 = {x = 223, y = 258, w = 54, h = 54, label = "R"}, relic3 = {x = 286, y = 258, w = 54, h = 54, label = "R"},
	potion1 = {x = 92, y = 352, w = 70, h = 70, label = "3"}, potion2 = {x = 172, y = 352, w = 70, h = 70, label = "4"},
	potion3 = {x = 252, y = 352, w = 70, h = 70, label = "5"}, potion4 = {x = 332, y = 352, w = 70, h = 70, label = "6"},
}
local beltLabel = T(kitPanel, "Belt  ·  keys 3 – 6 in the dungeon", 13, C.DIM, SEMI)
beltLabel.Position = UDim2.fromOffset(0, 428); beltLabel.Size = UDim2.new(1, 0, 0, 18)
local slotFrames = {}
local detail = frame(kitPanel, C.INSET, 0)
detail.Position = UDim2.fromOffset(22, 462); detail.Size = UDim2.new(1, -44, 0, 220)
DarkUI.corner(detail, 10)
DarkUI.stroke(detail, C.EDGE, 1)
local dTitleS = left(T(detail, "", 19, C.TEXT, BOLD)); dTitleS.Position = UDim2.fromOffset(14, 10); dTitleS.Size = UDim2.new(1, -28, 0, 24)
local dSub = left(T(detail, "", 13, C.DIM, SEMI)); dSub.Position = UDim2.fromOffset(14, 36); dSub.Size = UDim2.new(1, -28, 0, 16)
local dBody = left(T(detail, "", 13, C.TEXT)); dBody.Position = UDim2.fromOffset(14, 58); dBody.Size = UDim2.new(1, -28, 0, 90)
dBody.TextWrapped = true; dBody.TextYAlignment = Enum.TextYAlignment.Top
local actRow = Instance.new("Frame")
actRow.BackgroundTransparency = 1
actRow.Position = UDim2.fromOffset(12, 164); actRow.Size = UDim2.new(1, -24, 0, 44)
actRow.Parent = detail
local arl = Instance.new("UIListLayout"); arl.FillDirection = Enum.FillDirection.Horizontal; arl.Padding = UDim.new(0, 8); arl.Parent = actRow
local goldBar = frame(kitPanel, C.INSET, 0)
goldBar.Position = UDim2.fromOffset(22, 700); goldBar.Size = UDim2.new(1, -44, 0, 34)
DarkUI.corner(goldBar, 10)
DarkUI.stroke(goldBar, C.EDGE, 1)
local goldBarL = left(T(goldBar, "Gold :", 15, C.DIM, SEMI)); goldBarL.Position = UDim2.fromOffset(12, 0); goldBarL.Size = UDim2.new(0.5, 0, 1, 0)
local goldBarV = T(goldBar, "", 16, C.GOLD2, BOLD); goldBarV.AnchorPoint = Vector2.new(1, 0); goldBarV.Position = UDim2.new(1, -12, 0, 0); goldBarV.Size = UDim2.new(0.5, 0, 1, 0)
goldBarV.TextXAlignment = Enum.TextXAlignment.Right
local raidLine = T(kitPanel, "", 12, C.FAINT, SEMI)
raidLine.Position = UDim2.fromOffset(0, 742); raidLine.Size = UDim2.new(1, 0, 0, 16)

local stashPanel = DarkUI.panel(STASHP, {title = "Stash"})
stashPanel.Position = UDim2.fromOffset(968, 6); stashPanel.Size = UDim2.fromOffset(608, 780)
local stashGrid = Instance.new("Frame")
stashGrid.BackgroundTransparency = 1
stashGrid.Position = UDim2.fromOffset(24, 58); stashGrid.Size = UDim2.new(1, -48, 1, -80)
stashGrid.Parent = stashPanel
local sgl = Instance.new("UIGridLayout"); sgl.CellSize = UDim2.fromOffset(52, 52); sgl.CellPadding = UDim2.fromOffset(4, 4); sgl.SortOrder = Enum.SortOrder.LayoutOrder; sgl.Parent = stashGrid
local stashCount = T(stashPanel, "", 13, C.DIM, SEMI)
stashCount.AnchorPoint = Vector2.new(0.5, 1); stashCount.Position = UDim2.new(0.5, 0, 1, -10); stashCount.Size = UDim2.fromOffset(300, 16)

-- DRAGGING a thing (from the stash to a slot, from a slot back to the stash)
local drag = nil   -- {card, where, ghost, start}
local function inside(g, p)
	local a, s = g.AbsolutePosition, g.AbsoluteSize
	return p.X >= a.X and p.Y >= a.Y and p.X <= a.X + s.X and p.Y <= a.Y + s.Y
end
local function itemCell(parent, card, where, opts)
	opts = opts or {}
	local cell = DarkUI.slot(parent, card and card.rarity or nil)
	cell.Size = opts.size or UDim2.fromScale(1, 1)
	cell.LayoutOrder = opts.order or 0
	local sel = card and selected and selected.uid == card.uid
	if sel then DarkUI.stroke(cell, C.GOLD2, 2) end
	if card then DarkUI.icon(cell, card, {upright = opts.upright, zoom = opts.upright and 0.95 or 1.08}) end
	if card and card.free then
		local f = T(cell, "FREE", 9, C.DIM, BOLD); f.AnchorPoint = Vector2.new(1, 1); f.Position = UDim2.new(1, -3, 1, -2); f.Size = UDim2.fromOffset(40, 12); f.TextXAlignment = Enum.TextXAlignment.Right; f.ZIndex = 4
	end
	if opts.label and not card then
		local l = T(cell, opts.label, 13, C.FAINT, BOLD); l.Size = UDim2.fromScale(1, 1); l.ZIndex = 3
	end
	local btn = Instance.new("TextButton")
	btn.BackgroundTransparency = 1; btn.Text = ""; btn.Size = UDim2.fromScale(1, 1); btn.ZIndex = 6
	btn.Parent = cell
	btn.MouseEnter:Connect(function() if card and not drag then tip:show(card) end end)
	btn.MouseLeave:Connect(function() tip:hide() end)
	btn.InputBegan:Connect(function(input)
		if card and (input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch) then
			drag = {card = card, where = where, start = Vector2.new(input.Position.X, input.Position.Y)}
		end
	end)
	return cell
end
UserInputService.InputChanged:Connect(function(input)
	if not drag or input.UserInputType ~= Enum.UserInputType.MouseMovement and input.UserInputType ~= Enum.UserInputType.Touch then return end
	local p = Vector2.new(input.Position.X, input.Position.Y)
	if not drag.ghost and (p - drag.start).Magnitude > 7 then
		tip:hide()
		local g = DarkUI.slot(gui, drag.card.rarity)
		g.Size = UDim2.fromOffset(56, 56)
		g.ZIndex = 60
		DarkUI.icon(g, drag.card, {z = 61})
		drag.ghost = g
	end
	if drag.ghost then
		local k = uiScale.Scale
		drag.ghost.Position = UDim2.fromOffset(p.X / k - 28, p.Y / k - 28)
	end
end)
UserInputService.InputEnded:Connect(function(input)
	if not drag or (input.UserInputType ~= Enum.UserInputType.MouseButton1 and input.UserInputType ~= Enum.UserInputType.Touch) then return end
	local d = drag
	drag = nil
	if not d.ghost then
		-- a click: pick it
		selected = (selected and selected.uid == d.card.uid) and nil or {uid = d.card.uid, where = d.where, card = d.card}
		render()
		return
	end
	d.ghost:Destroy()
	local p = UserInputService:GetMouseLocation()
	p = Vector2.new(p.X, p.Y - 0)
	if d.where == "stash" then
		for _, f in pairs(slotFrames) do if inside(f, p) then call("Equip", d.card.uid); selected = nil; render(); return end end
	elseif d.where == "kit" and inside(stashPanel, p) then
		call("Unequip", d.card.uid); selected = nil; render(); return
	end
end)

local function statRow(order, label, value, good)
	local row = frame(statList, Color3.new(0, 0, 0), 1)
	row.Size = UDim2.new(1, 0, 0, 26)
	row.LayoutOrder = order
	local l = left(T(row, label, 15, C.TEXT)); l.Size = UDim2.new(0.6, 0, 1, 0)
	local v = T(row, value, 15, good and C.GOOD or C.GOLD2, BOLD); v.AnchorPoint = Vector2.new(1, 0); v.Position = UDim2.new(1, 0, 0, 0); v.Size = UDim2.new(0.4, 0, 1, 0)
	v.TextXAlignment = Enum.TextXAlignment.Right
	local line = frame(row, C.EDGE, 0.5); line.Position = UDim2.new(0, 0, 1, -1); line.Size = UDim2.new(1, 0, 0, 1)
end

local function drawStash()
	local cls = GameConfig.CLASSES[view.class] or {}
	-- you, in your kit
	for _, c in ipairs(charStage:GetChildren()) do c:Destroy() end
	local rig = dressed(player.UserId, view.class, {weapon = true, loadout = kitLoadout()})
	if rig then stage(charStage, rig, {yaw = 12, spin = 14, fov = 28}) end
	charName.Text = "· " .. (cls.name or view.class or "") .. " ·"
	-- what you are, in it
	for _, c in ipairs(statList:GetChildren()) do if c:IsA("GuiObject") then c:Destroy() end end
	local health = 100 + (cls.health or 0)
	local taken, dealt, speed = 1, 1, cls.speed or 1
	local relics = 0
	for _, c in ipairs(view.kit or {}) do
		if c.slot == "armor" and c.armor then
			local a = Catalog.LOOT.ARMOR_BY[c.armor]
			if a then taken *= a.taken; health += a.health or 0 end
		elseif c.kind == "relic" then
			relics += 1
			local r = Catalog.LOOT.RELIC[c.relic or ""]
			if r then
				if r.mods then taken *= r.mods.taken or 1; dealt *= r.mods.dealt or 1; speed *= r.mods.speed or 1 end
				health += r.health or 0
			end
		end
	end
	for _, pk in ipairs(view.perks and view.perks[view.class] or {}) do
		if pk.on then
			local def = Catalog.PERK[pk.id]
			if def then
				if def.mods then taken *= def.mods.taken or 1; dealt *= def.mods.dealt or 1; speed *= def.mods.speed or 1 end
				health += def.health or 0
			end
		end
	end
	local w1
	for _, c in ipairs(view.kit or {}) do if c.slot == "weapon1" then w1 = c end end
	statRow(1, "Health", tostring(health))
	statRow(2, "Damage taken", string.format("-%d%%", math.floor((1 - taken) * 100 + 0.5)), taken < 1)
	statRow(3, "Damage dealt", string.format("+%d%%", math.floor((dealt - 1) * 100 + 0.5)), dealt > 1)
	statRow(4, "Move speed", string.format("%d%%", math.floor(speed * 100 + 0.5)))
	statRow(5, "Main weapon", w1 and w1.name or ("Plain " .. tostring(view.free and view.free[1] or "")))
	local pk = {}
	for _, p in ipairs(view.perks and view.perks[view.class] or {}) do if p.on then table.insert(pk, p.name) end end
	statRow(6, "Perks", #pk > 0 and table.concat(pk, ", ") or "none (Class tab)")
	-- the kit
	for _, f in pairs(slotFrames) do f:Destroy() end
	slotFrames = {}
	local bySlot = {}
	for _, c in ipairs(view.kit or {}) do bySlot[c.slot] = c end
	for key, def in pairs(SLOTDEF) do
		local holder = Instance.new("Frame")
		holder.BackgroundTransparency = 1
		holder.Position = UDim2.fromOffset(def.x, def.y); holder.Size = UDim2.fromOffset(def.w, def.h)
		holder.Parent = kitPanel
		local card = bySlot[key]
		local label = def.label
		if not card and (key == "weapon1" or key == "weapon2") and view.free then
			local f = view.free[key == "weapon1" and 1 or 2]
			label = f and (def.label .. "\nFREE\n" .. string.upper(f)) or def.label
		end
		itemCell(holder, card, "kit", {upright = def.upright, label = label})
		slotFrames[key] = holder
	end
	-- the stash
	for _, c in ipairs(stashGrid:GetChildren()) do if c:IsA("GuiObject") then c:Destroy() end end
	for i = 1, view.max or 60 do
		local card = view.stash and view.stash[i]
		itemCell(stashGrid, card, "stash", {order = i})
	end
	stashCount.Text = string.format("%d / %d", #(view.stash or {}), view.max or 60)
	goldBarV.Text = fmt(view.gold)
	raidLine.Text = string.format("%d RAIDS  ·  %d TIMES OUT ALIVE", view.raids or 0, view.out or 0)
	-- what's picked, and what you can do with it
	for _, c in ipairs(actRow:GetChildren()) do if c:IsA("GuiObject") then c:Destroy() end end
	local s = selected and selected.card
	if s then
		dTitleS.Text = s.name or ""
		dTitleS.TextColor3 = RAR[s.rarity] or C.TEXT
		dSub.Text = (s.sub or "") .. ((s.value or 0) > 0 and ("  ·  worth " .. s.value .. " gold") or "")
		dBody.Text = table.concat(s.lines or {}, "\n")
		local function act(text, kind, fn) local b = DarkUI.button(actRow, text, kind, 14); b.Size = UDim2.fromOffset(text:len() > 14 and 160 or 110, 40); b.Activated:Connect(fn) end
		if selected.where == "stash" then
			if s.kind ~= "treasure" then act("Equip", "green", function() call("Equip", s.uid); selected = nil; render() end) end
			act("Sell  " .. tostring(s.value or 0), "gold", function() call("Sell", s.uid); selected = nil; render() end)
		else
			act("Take Off", "stone", function() call("Unequip", s.uid); selected = nil; render() end)
		end
		if s.kind == "weapon" and not s.free then
			if s.reforge then act("Reforge  " .. s.reforge, "stone", function() local r = call("Work", {s.uid, "reforge"}); if r and r.ok then selected = nil end; render() end) end
			if s.temper then act("Temper  " .. s.temper, "stone", function() local r = call("Work", {s.uid, "temper"}); if r and r.ok then selected = nil end; render() end) end
		end
	else
		dTitleS.Text = "Your kit is what you risk"
		dTitleS.TextColor3 = C.TEXT
		dSub.Text = "Drag a thing onto a slot, or click it"
		dBody.Text = "What you take in, you can lose; get out and it comes back with everything you found. An empty weapon slot goes in as your class's plain weapon: free, and never lost."
	end
end

--------------------------------------------------------------------
--  MERCHANTS
--------------------------------------------------------------------
local MERCHP = pages.Merchants
local MERCH_LOOK = {Smith = {set = "RoadLevy", weapon = "Hammer"}, Armourer = {set = "IronCrow", weapon = "Mace"}, Alchemist = {set = "Necromancer", weapon = "Staff"}, Treasurer = {set = "GildedCourt", weapon = "Dagger"}}
local mList = DarkUI.panel(MERCHP, {title = "Merchants"})
mList.Position = UDim2.fromOffset(24, 6); mList.Size = UDim2.fromOffset(330, 780)
local mListBox = Instance.new("Frame")
mListBox.BackgroundTransparency = 1
mListBox.Position = UDim2.fromOffset(18, 56); mListBox.Size = UDim2.new(1, -36, 1, -70)
mListBox.Parent = mList
local mll = Instance.new("UIListLayout"); mll.Padding = UDim.new(0, 10); mll.Parent = mListBox
local mPanel = DarkUI.panel(MERCHP)
mPanel.Position = UDim2.fromOffset(366, 6); mPanel.Size = UDim2.fromOffset(600, 780)
local mPortrait = DarkUI.slot(mPanel)
mPortrait.Position = UDim2.fromOffset(24, 24); mPortrait.Size = UDim2.fromOffset(170, 200)
local mName = left(T(mPanel, "", 28, C.GOLD2, BOLD)); mName.Position = UDim2.fromOffset(212, 30); mName.Size = UDim2.new(1, -236, 0, 34)
local mLine = left(T(mPanel, "", 15, C.TEXT)); mLine.Position = UDim2.fromOffset(212, 72); mLine.Size = UDim2.new(1, -236, 0, 90); mLine.TextWrapped = true
mLine.TextYAlignment = Enum.TextYAlignment.Top
local wareTitle = T(mPanel, "Wares", 20, C.GOLD2, BOLD); wareTitle.Position = UDim2.fromOffset(0, 236); wareTitle.Size = UDim2.new(1, 0, 0, 24)
DarkUI.rule(mPanel, 264, 420)
local wares = Instance.new("ScrollingFrame")
wares.BackgroundTransparency = 1; wares.BorderSizePixel = 0
wares.Position = UDim2.fromOffset(24, 280); wares.Size = UDim2.new(1, -48, 1, -300)
wares.CanvasSize = UDim2.new(); wares.AutomaticCanvasSize = Enum.AutomaticSize.Y; wares.ScrollBarThickness = 4
wares.Parent = mPanel
local wgl = Instance.new("UIGridLayout"); wgl.CellSize = UDim2.fromOffset(266, 92); wgl.CellPadding = UDim2.fromOffset(12, 12); wgl.Parent = wares
local sellPanel = DarkUI.panel(MERCHP, {title = "Sell from your Stash"})
sellPanel.Position = UDim2.fromOffset(978, 6); sellPanel.Size = UDim2.fromOffset(598, 780)
local sellGrid = Instance.new("Frame")
sellGrid.BackgroundTransparency = 1
sellGrid.Position = UDim2.fromOffset(20, 58); sellGrid.Size = UDim2.new(1, -40, 0, 560)
sellGrid.Parent = sellPanel
local sgl2 = Instance.new("UIGridLayout"); sgl2.CellSize = UDim2.fromOffset(52, 52); sgl2.CellPadding = UDim2.fromOffset(4, 4); sgl2.SortOrder = Enum.SortOrder.LayoutOrder; sgl2.Parent = sellGrid
local sellNote = T(sellPanel, "", 14, C.DIM, SEMI); sellNote.Position = UDim2.fromOffset(20, 640); sellNote.Size = UDim2.new(1, -40, 0, 50); sellNote.TextWrapped = true
local sellBtn = DarkUI.button(sellPanel, "Sell", "gold", 18)
sellBtn.AnchorPoint = Vector2.new(0.5, 1); sellBtn.Position = UDim2.new(0.5, 0, 1, -24); sellBtn.Size = UDim2.fromOffset(260, 48)

local portraitCache = {}
local function merchantRig(id)
	local look = MERCH_LOOK[id] or {}
	local lo = {weapon = look.weapon}
	for _, pc in ipairs(look.set and Catalog.setPieces(look.set) or {}) do lo[pc.slot] = pc.id end
	local ok, m = pcall(PreviewRig.dressedRig, {loadout = lo, appearance = Catalog.BODY.defaults, weight = "Medium", weapon = true})
	return ok and m or nil
end
local function drawMerchants()
	for _, c in ipairs(mListBox:GetChildren()) do if c:IsA("GuiObject") then c:Destroy() end end
	local cur
	for _, m in ipairs(view.merchants or {}) do
		if m.id == merchant then cur = m end
		local b = Instance.new("TextButton")
		b.Text = ""; b.AutoButtonColor = false
		b.BackgroundColor3 = m.id == merchant and Color3.fromRGB(40, 54, 92) or C.PANEL2
		DarkUI.corner(b, 12)
		b.Size = UDim2.new(1, 0, 0, 120)
		b.Parent = mListBox
		DarkUI.stroke(b, m.id == merchant and C.GOLD2 or C.EDGE, m.id == merchant and 2 or 1)
		local face = DarkUI.slot(b)
		face.Position = UDim2.fromOffset(8, 8); face.Size = UDim2.fromOffset(90, 104)
		local rig = merchantRig(m.id)
		if rig then stage(face, rig, {bust = true, yaw = 12, fov = 24}) end
		local n = left(T(b, m.name, 17, C.TEXT, BOLD)); n.Position = UDim2.fromOffset(110, 20); n.Size = UDim2.new(1, -120, 0, 22); n.TextWrapped = true
		local role = left(T(b, ({Smith = "Weaponsmith", Armourer = "Armourer", Alchemist = "Alchemist", Treasurer = "Treasurer"})[m.id] or "", 13, C.GOLD, SEMI))
		role.Position = UDim2.fromOffset(110, 70); role.Size = UDim2.new(1, -120, 0, 18)
		b.Activated:Connect(function() merchant = m.id; selected = nil; render() end)
	end
	for _, c in ipairs(mPortrait:GetChildren()) do if c:IsA("ViewportFrame") then c:Destroy() end end
	if not cur then return end
	local rig = merchantRig(cur.id)
	if rig then stage(mPortrait, rig, {bust = true, yaw = 8, fov = 26}) end
	mName.Text = cur.name
	mLine.Text = "“" .. (cur.line or "") .. "”"
	for _, c in ipairs(wares:GetChildren()) do if c:IsA("GuiObject") then c:Destroy() end end
	wareTitle.Text = cur.id == "Treasurer" and "Your Valuables" or "Wares"
	local list = cur.wares or {}
	if cur.id == "Treasurer" then
		list = {}
		for _, c in ipairs(view.stash or {}) do if c.kind == "treasure" then local cc = table.clone(c); cc.sellOnly = true; table.insert(list, cc) end end
	end
	for _, c in ipairs(list) do
		local row = DarkUI.slot(wares, c.rarity)
		local ic = DarkUI.slot(row, c.rarity)
		ic.Position = UDim2.fromOffset(8, 8); ic.Size = UDim2.fromOffset(76, 76)
		DarkUI.icon(ic, c)
		local n = left(T(row, c.name or "", 15, RAR[c.rarity] or C.TEXT, BOLD)); n.Position = UDim2.fromOffset(94, 8); n.Size = UDim2.new(1, -100, 0, 20)
		n.TextTruncate = Enum.TextTruncate.AtEnd; n.ZIndex = 3
		local b = DarkUI.button(row, c.sellOnly and ("Sell  " .. tostring(c.value or 0)) or (c.sold and "Sold" or ("Buy  " .. tostring(c.price or 0))), c.sold and "stone" or "gold", 14)
		b.Position = UDim2.fromOffset(94, 48); b.Size = UDim2.fromOffset(160, 34); b.ZIndex = 4
		b.Activated:Connect(function()
			if c.sellOnly then call("Sell", c.uid)
			elseif not c.sold then call("Buy", {cur.id, c.index}) end
			render()
		end)
		local hover = Instance.new("TextButton"); hover.BackgroundTransparency = 1; hover.Text = ""; hover.Size = UDim2.new(0, 90, 1, 0); hover.ZIndex = 5; hover.Parent = row
		hover.MouseEnter:Connect(function() tip:show(c, c.price and ("Costs " .. c.price .. " gold") or nil) end)
		hover.MouseLeave:Connect(function() tip:hide() end)
	end
	-- your stash, to sell from
	for _, c in ipairs(sellGrid:GetChildren()) do if c:IsA("GuiObject") then c:Destroy() end end
	for i = 1, math.min(view.max or 60, 90) do itemCell(sellGrid, view.stash and view.stash[i], "stash", {order = i}) end
	local s = selected and selected.where == "stash" and selected.card
	sellBtn.Visible = s ~= nil
	sellBtn.Text = s and ("Sell " .. (s.name or "") .. "  ·  " .. tostring(s.value or 0)) or "Sell"
	sellNote.Text = s and "" or "Pick something to sell. The Treasurer pays full worth for valuables; everything else sells for what it's worth."
end
sellBtn.Activated:Connect(function()
	local s = selected and selected.card
	if s then call("Sell", s.uid); selected = nil; render() end
end)

--------------------------------------------------------------------
--  DRAWING, OPENING, CLOSING
--------------------------------------------------------------------
local function setCamera(on)
	_G.DungeonLobby = on or nil
	local cam = workspace.CurrentCamera
	if on then
		buildTavern()
		cam.CameraType = Enum.CameraType.Scriptable
		cam.FieldOfView = 50
		cam.CFrame = tavernCam
	end
	moody(on)
	for i, bb in pairs(seatTags) do bb.Enabled = on and bb.Adornee ~= nil end
end

render = function()
	if not view then return end
	goldLabel.Text = "VAULT GOLD  " .. fmt(view.gold)
	wallet.refresh()
	for name, b in pairs(tabBtns) do
		b.TextColor3 = name == tab and C.TEXT or C.DIM
		b.TextSize = name == tab and 28 or 25
		pages[name].Visible = name == tab
	end
	local tb = tabBtns[tab]
	glow.Position = UDim2.new(tb.Position.X.Scale, tb.Position.X.Offset, 0, 4)
	glowDiamond.Position = UDim2.new(tb.Position.X.Scale, tb.Position.X.Offset, 0, 77)
	backdrop.Visible = tab ~= "Play"
	setCamera(open and tab == "Play")
	tip:hide()
	if tab == "Play" then drawPlay()
	elseif tab == "Class" then drawClass()
	elseif tab == "Stash" then drawStash()
	elseif tab == "Merchants" then drawMerchants() end
end
for name, b in pairs(tabBtns) do
	b.Activated:Connect(function() tab = name; selected = nil; render() end)
end

local hubWasOn = false
local hiddenGuis = nil
local function setOpen(on)
	if on == open then return end
	open = on
	gui.Enabled = on
	local h = player.PlayerGui:FindFirstChild("HubMenu")
	_G.DungeonMenuUp = on or nil
	-- (the rest of the screen steps aside: this is a world of its own)
	if on then
		hiddenGuis = {}
		for _, g in ipairs(player.PlayerGui:GetChildren()) do
			if g:IsA("ScreenGui") and g ~= gui and g.Enabled and g.Name ~= "HubMenu" and g.Name ~= "TouchGui" then
				hiddenGuis[g] = true
				g.Enabled = false
			end
		end
	else
		for g in pairs(hiddenGuis or {}) do if g.Parent then g.Enabled = true end end
		hiddenGuis = nil
	end
	if on then
		hubWasOn = h and h.Enabled or false
		if _G.HubMenuHide then pcall(_G.HubMenuHide) end
		if h then h.Enabled = false end
		task.spawn(function()
			call("View")
			local st = hub("State")
			party = st.party
			render()
		end)
	else
		setCamera(false)
		for _, m in pairs(seatRigs) do m:Destroy() end
		seatRigs = {}
		local cam = workspace.CurrentCamera
		local c = player.Character
		local hum = c and c:FindFirstChildOfClass("Humanoid")
		if hum then cam.CameraType = Enum.CameraType.Custom; cam.CameraSubject = hum end
		-- (back to the Courtyard's menu, if that's where you came from)
		if hubWasOn and _G.HubMenuGo then pcall(_G.HubMenuGo, "PLAY") end
		tip:hide()
	end
end
leaveBtn.Activated:Connect(function() setOpen(false) end)
-- (in the lodge, LEAVE shuts the menu and you walk about; its door goes home to the Courtyard)
_G.OpenDungeon = function(t, m)
	tab = (t and pages[t]) and t or "Play"
	if m == "Depths" or m == "Deadvault" then mode = m end
	if open then render() else setOpen(true) end
end
_G.CloseDungeon = function() setOpen(false) end

--------------------------------------------------------------------
--  THE WAYS OUT
--------------------------------------------------------------------
local WAYS = {}
do

local loadoutEvent = ReplicatedStorage:WaitForChild("LoadoutEvent")
local function menuBus() _G.MenuBus = _G.MenuBus or Instance.new("BindableEvent"); return _G.MenuBus end
local function inDungeonGame()
	local def = GameConfig.MODES[round:GetAttribute("Mode") or ""]
	return def ~= nil and def.ownSpawn == true
end

-- ◀ MAIN MENU: asked once, then home to the main menu (HubRemote Play ▸ Courtyard; the menu opens
-- there by itself)
local confirmBox = DarkUI.panel(root, {title = "Back to the main menu?"})
confirmBox.AnchorPoint = Vector2.new(0.5, 0.5); confirmBox.Position = UDim2.fromScale(0.5, 0.5); confirmBox.Size = UDim2.fromOffset(480, 230)
confirmBox.Visible = false; confirmBox.ZIndex = 40
local cbLine = T(confirmBox, "Your stash, your kit and your gold stay here in the Gilded Rat, safe. Come back any time from PLAY ▸ ADVENTURES.", 16, C.DIM, SEMI)
cbLine.Position = UDim2.fromOffset(28, 60); cbLine.Size = UDim2.new(1, -56, 0, 66); cbLine.TextWrapped = true
local cbGo = DarkUI.button(confirmBox, "MAIN MENU", "blue", 22)
cbGo.AnchorPoint = Vector2.new(1, 1); cbGo.Position = UDim2.new(0.5, -8, 1, -22); cbGo.Size = UDim2.fromOffset(190, 56)
local cbStay = DarkUI.button(confirmBox, "STAY", "stone", 22)
cbStay.AnchorPoint = Vector2.new(0, 1); cbStay.Position = UDim2.new(0.5, 8, 1, -22); cbStay.Size = UDim2.fromOffset(190, 56)
local function goCourtyard()
	confirmBox.Visible = false
	say("Back to the main menu…", true)
	local r = hub("Play", "Courtyard")
	if r and r.ok == false and r.msg then say(r.msg, false); return end
	task.delay(0.4, function() if open then setOpen(false) end end)
end
cbGo.Activated:Connect(goCourtyard)
cbStay.Activated:Connect(function() confirmBox.Visible = false end)
homeBtn.Activated:Connect(function() confirmBox.Visible = true end)

-- ON YOUR FEET IN THE GILDED RAT: a small bar at the top while the lobby is shut
local hudGui = Instance.new("ScreenGui")
hudGui.Name = "TavernHud"
hudGui.ResetOnSpawn = false
hudGui.DisplayOrder = 6
hudGui.Enabled = false
hudGui.Parent = player.PlayerGui
local hudBar = DarkUI.panel(hudGui)
hudBar.AnchorPoint = Vector2.new(0.5, 0); hudBar.Position = UDim2.new(0.5, 0, 0, 8); hudBar.Size = UDim2.fromOffset(600, 66)
local hudTitle = left(T(hudBar, "THE GILDED RAT", 22, C.GOLD2, BOLD)); hudTitle.Position = UDim2.fromOffset(18, 8); hudTitle.Size = UDim2.fromOffset(240, 26)
local hudSub = left(T(hudBar, "Walk to a merchant, your stash or the gate", 12, C.DIM, SEMI)); hudSub.Position = UDim2.fromOffset(18, 36); hudSub.Size = UDim2.fromOffset(250, 18)
local hudLobby = DarkUI.button(hudBar, "LOBBY  [M]", "blue", 16)
hudLobby.AnchorPoint = Vector2.new(1, 0.5); hudLobby.Position = UDim2.new(1, -190, 0.5, 0); hudLobby.Size = UDim2.fromOffset(130, 44)
local hudHome = DarkUI.button(hudBar, "◀  MAIN MENU", "blue", 15)
hudHome.AnchorPoint = Vector2.new(1, 0.5); hudHome.Position = UDim2.new(1, -12, 0.5, 0); hudHome.Size = UDim2.fromOffset(170, 44)
local hudScale = Instance.new("UIScale"); hudScale.Parent = hudBar
hudLobby.Activated:Connect(function() _G.OpenDungeon("Play") end)
hudHome.Activated:Connect(function() _G.OpenDungeon("Play"); confirmBox.Visible = true end)

-- DOWN (out of the raid, waiting for the room to be cleared): the dungeon game's own screen,
-- never the battle's class screen (LoadoutServer's "Down")
local downGui = Instance.new("ScreenGui")
downGui.Name = "DungeonDown"
downGui.ResetOnSpawn = false
downGui.IgnoreGuiInset = true
downGui.DisplayOrder = 2050
downGui.Enabled = false
downGui.Parent = player.PlayerGui
local downScale = Instance.new("UIScale"); downScale.Parent = downGui
local downShade = frame(downGui, Color3.new(0, 0, 0), 0.45); downShade.Size = UDim2.fromScale(1, 1)
local downBox = DarkUI.panel(downGui)
downBox.AnchorPoint = Vector2.new(0.5, 0.5); downBox.Position = UDim2.fromScale(0.5, 0.5); downBox.Size = UDim2.fromOffset(600, 290)
local downTitle = T(downBox, "", 44, C.BAD, BOLD); downTitle.Position = UDim2.fromOffset(0, 20); downTitle.Size = UDim2.new(1, 0, 0, 50)
DarkUI.rule(downBox, 76, 260)
local downWhy = T(downBox, "", 18, C.TEXT, SEMI); downWhy.Position = UDim2.fromOffset(30, 92); downWhy.Size = UDim2.new(1, -60, 0, 48); downWhy.TextWrapped = true
local downHint = T(downBox, "", 14, C.DIM, SEMI); downHint.Position = UDim2.fromOffset(30, 140); downHint.Size = UDim2.new(1, -60, 0, 40); downHint.TextWrapped = true
local downSpec = DarkUI.button(downBox, "SPECTATE", "stone", 20)
downSpec.AnchorPoint = Vector2.new(1, 1); downSpec.Position = UDim2.new(0.5, -8, 1, -24); downSpec.Size = UDim2.fromOffset(220, 58)
local downOut = DarkUI.button(downBox, "BACK TO THE GILDED RAT", "red", 18)
downOut.AnchorPoint = Vector2.new(0, 1); downOut.Position = UDim2.new(0.5, 8, 1, -24); downOut.Size = UDim2.fromOffset(250, 58)
local downReason = nil
local function bodyUp()
	local c = player.Character
	local h = c and c:FindFirstChildOfClass("Humanoid")
	return h ~= nil and h.Health > 0
end
local function hideDown() downGui.Enabled = false end
local function showDown()
	if not downReason or bodyUp() or not inDungeonGame() then hideDown(); return end
	local m = round:GetAttribute("Mode")
	local why = downReason
	if m == "Deadvault" then
		if why:find("got out") then
			downTitle.Text, downTitle.TextColor3 = "YOU GOT OUT", C.GOOD
			downHint.Text = "Everything you carried is in your vault. Back to the Gilded Rat to spend it."
		else
			downTitle.Text, downTitle.TextColor3 = "YOU FELL", C.BAD
			downHint.Text = "What you carried lies in your pack where you fell, for whoever finds it. Your stash at the Gilded Rat is safe."
		end
		downOut.Text = "BACK TO THE GILDED RAT"
	elseif m == "Depths" then
		downTitle.Text, downTitle.TextColor3 = "DOWN", C.GOLD2
		downHint.Text = "Your party fights on: you're back on your feet when the room is cleared."
		downOut.Text = "LEAVE THE DUNGEON"
	else
		downTitle.Text, downTitle.TextColor3 = "WAITING", C.GOLD2
		downHint.Text = ""
		downOut.Text = "BACK TO THE GILDED RAT"
	end
	downWhy.Text = why
	-- (the fall is seen first: DeathScreen's HoldUntil; then its veil lifts for this)
	local fade = player.PlayerGui:FindFirstChild("DeathFade")
	local hold = fade and fade:GetAttribute("HoldUntil")
	if hold and os.clock() < hold then task.delay(hold - os.clock() + 0.05, showDown); return end
	if fade and fade:GetAttribute("DeathScreen") then fade:SetAttribute("Lift", true) end
	pcall(RunService.UnbindFromRenderStep, RunService, "DeathCam")
	if not _G.SpectateActive then downGui.Enabled = true end
end
loadoutEvent.OnClientEvent:Connect(function(what, a)
	if what == "Down" then
		downReason = tostring(a or "")
		showDown()
	elseif what == "Spawned" or what == "Show" then
		downReason = nil
		hideDown()
	end
end)
downSpec.Activated:Connect(function()
	hideDown()
	menuBus():Fire("Spectate", true)
end)
downOut.Activated:Connect(function()
	hideDown()
	downReason = nil
	if _G.SpectateActive then menuBus():Fire("Spectate", false) end
	local r = hub("Hub")
	if r and r.ok == false and r.msg then say(r.msg, false) end
end)
-- (the spectate bar's BACK: this screen again, if still down)
menuBus().Event:Connect(function(what)
	if what == "SpectateEnd" and downReason then task.defer(showDown) end
end)
player.CharacterAdded:Connect(function(c)
	local h = c:WaitForChild("Humanoid", 5)
	if h and h.Health > 0 then downReason = nil; hideDown() end
end)
round:GetAttributeChangedSignal("Mode"):Connect(function()
	if not inDungeonGame() then downReason = nil; hideDown() end
	-- (the lobby is the Gilded Rat's: into a raid, or home to the main menu, it goes)
	local m = round:GetAttribute("Mode")
	if m ~= "Tavern" and _G.CloseDungeon then _G.CloseDungeon() end
	if m ~= "Tavern" then confirmBox.Visible = false; hudGui.Enabled = false end
end)
round:GetAttributeChangedSignal("State"):Connect(function() if round:GetAttribute("State") ~= "Round" then downReason = nil; hideDown() end end)
WAYS.confirmBox, WAYS.hudGui, WAYS.hudScale, WAYS.downGui, WAYS.downScale, WAYS.bodyUp = confirmBox, hudGui, hudScale, downGui, downScale, bodyUp
end
_G.OpenVault = function() _G.OpenDungeon("Stash") end
_G.DungeonMenuOpen = function() return open end
-- (test hooks: the Open and Tab attributes)
gui:GetAttributeChangedSignal("Open"):Connect(function() if gui:GetAttribute("Open") then _G.OpenDungeon(gui:GetAttribute("Tab")) else setOpen(false) end end)
gui:GetAttributeChangedSignal("Tab"):Connect(function() if open then tab = gui:GetAttribute("Tab") or tab; render() end end)

-- the lodge's places open it where you stand (Game ▸ Modes ▸ Tavern): a merchant, the stash, the gate…
advEvent.OnClientEvent:Connect(function(kind, data)
	if kind == "OpenDungeon" and type(data) == "table" then
		if data.merchant then merchant = data.merchant end
		_G.OpenDungeon(data.tab or "Play")
	end
end)
-- arriving in the lodge: the lobby opens on its PLAY (once a visit)
task.spawn(function()
	local greeted = false
	while true do
		task.wait(1)
		local inTavern = round:GetAttribute("Mode") == "Tavern"
		if inTavern and not greeted then
			-- (the Courtyard's menu has no place here: put away once, on arrival)
			if _G.HubMenuHide then pcall(_G.HubMenuHide) end
			local c = player.Character
			local h = c and c:FindFirstChildOfClass("Humanoid")
			if h and h.Health > 0 then
				greeted = true
				task.wait(1.5)
				if not open then _G.OpenDungeon("Play") end
			end
		elseif not inTavern then
			greeted = false
		end
	end
end)

hubEvent.OnClientEvent:Connect(function(what, a)
	if what == "Party" then
		party = a
		if open and tab == "Play" then drawPlay() end
	end
end)
UserInputService.InputBegan:Connect(function(input, processed)
	-- (the Tavern's menu key: M opens and shuts this, as it does the Courtyard's there)
	if input.KeyCode == Enum.KeyCode.M and not UserInputService:GetFocusedTextBox() and round:GetAttribute("Mode") == "Tavern" then
		if open then setOpen(false) else _G.OpenDungeon(tab) end
		return
	end
	if not open then return end
	if input.KeyCode == Enum.KeyCode.Escape or input.KeyCode == Enum.KeyCode.ButtonB then
		if WAYS.confirmBox.Visible then WAYS.confirmBox.Visible = false else setOpen(false) end
	elseif input.KeyCode == Enum.KeyCode.Q or input.KeyCode == Enum.KeyCode.ButtonL1 then
		local i = table.find(TABS, tab) or 1
		tab = TABS[(i - 2) % #TABS + 1]; selected = nil; render()
	elseif input.KeyCode == Enum.KeyCode.E or input.KeyCode == Enum.KeyCode.ButtonR1 then
		local i = table.find(TABS, tab) or 1
		tab = TABS[i % #TABS + 1]; selected = nil; render()
	end
end)
RunService:BindToRenderStep("DungeonMenu", Enum.RenderPriority.Camera.Value + 25, function()
	local vs0 = workspace.CurrentCamera and workspace.CurrentCamera.ViewportSize or Vector2.new(1600, 900)
	local k0 = math.clamp(math.min(vs0.X / 1600, vs0.Y / 900), 0.45, 1.4)
	WAYS.downScale.Scale = k0
	WAYS.hudScale.Scale = math.clamp(vs0.X / 1300, 0.55, 1)
	WAYS.hudGui.Enabled = not open and round:GetAttribute("Mode") == "Tavern" and WAYS.bodyUp() and not _G.SpectateActive
	if WAYS.downGui.Enabled then
		UserInputService.MouseBehavior = Enum.MouseBehavior.Default
		UserInputService.MouseIconEnabled = true
	end
	if not open then return end
	-- (a body arriving while it's up brings its bar: that steps aside too)
	local hb = player.PlayerGui:FindFirstChild("Hotbar")
	if hb and hb.Enabled and hiddenGuis then hb.Enabled = false; hiddenGuis[hb] = true end
	UserInputService.MouseBehavior = Enum.MouseBehavior.Default
	UserInputService.MouseIconEnabled = true
	local vs = workspace.CurrentCamera and workspace.CurrentCamera.ViewportSize or Vector2.new(1600, 900)
	uiScale.Scale = math.clamp(math.min(vs.X / 1600, vs.Y / 900), 0.45, 1.4)
	if tab == "Play" and tavernCam then
		local cam = workspace.CurrentCamera
		cam.CameraType = Enum.CameraType.Scriptable
		-- (a slow breath of the candles' room)
		local t = os.clock()
		cam.CFrame = tavernCam * CFrame.new(math.sin(t * 0.21) * 0.25, math.sin(t * 0.33) * 0.12, 0) * CFrame.Angles(0, math.sin(t * 0.17) * 0.012, 0)
	end
end)
