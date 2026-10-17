--[[ WAR (client) — the War mode on your screen (Game ▸ Modes ▸ War runs it; Game ▸ WarMap builds the
     field). Only while the round's Mode is "War":
       • THE HUD (top): each side's reinforcements (a number and a bar), the clock, the five banners
         as chips in their holder's colour, filling as they swing, the ones your side is fighting
         for ringed in gold; at a banner, what's happening there (TAKING · HOLDING · LOSING IT ·
         CAN'T TAKE IT YET) and its bar; big calls when a banner falls; warnings when something is
         coming down on you (VOLLEY: raise your guard · TREBUCHET · METEORS · LIGHTNING · FROST)
       • THE BANNERS on the field: each flag in its holder's colour, a ring on the ground, a beam
         of light over the ones being fought for
       • THE ARMIES on the flanks (ReplicatedStorage ▸ WarFX regiments: cheap figures, nothing
         replicated): foot regiments of both sides marching to the front (Round WarFront) and
         clashing there, each side's archer companies and battle-mages, cavalry charges
       • THE ENGINES the server fires (ReplicatedStorage ▸ WarEvent): trebuchet fire, volleys,
         the battle-mages' meteors, lightning and frost, all drawn here; distant war on the flanks
         between them; the theme's weather (Map W_Weather); the battle's roar
       • ARRIVING: your first time in a round, a few seconds' flight over the field with the
         battle's name (any key skips) ]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")

local Theme = require(ReplicatedStorage:WaitForChild("Theme"))
local GameConfig = require(ReplicatedStorage:WaitForChild("GameConfig"))
local InputHints = require(ReplicatedStorage:WaitForChild("InputHints"))
local WarFX = require(ReplicatedStorage:WaitForChild("WarFX"))
local UIFX = require(ReplicatedStorage:WaitForChild("UIFX"))
local Device = require(ReplicatedStorage:WaitForChild("Device"))

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local round = ReplicatedStorage:WaitForChild("Round")
local remote = ReplicatedStorage:WaitForChild("WarEvent", math.huge)   -- (the War mode makes it)

local V3, CF = Vector3.new, CFrame.new
local WHITE = Color3.new(1, 1, 1)
local GOLD = Color3.fromRGB(255, 200, 70)
local SIDE = {A = Color3.fromRGB(70, 120, 240), B = Color3.fromRGB(226, 66, 54)}
local NEUTRAL = Color3.fromRGB(226, 222, 210)
local ARCANE = Color3.fromRGB(176, 96, 255)
local NUMERAL = {"I", "II", "III", "IV", "V"}
local NAMES = {
	Redfield = {"SOUTH FIELDS", "THE ORCHARD", "THE VILLAGE", "THE MILL", "NORTH FIELDS"},
	Ironridge = {"THE LOW PASS", "THE CAIRN", "THE OLD FORT", "THE SCREES", "THE HIGH PASS"},
	Frostmere = {"THE SOUTH SHORE", "THE PINES", "THE FROZEN LAKE", "THE DRIFTS", "THE NORTH SHORE"},
	Ashvale = {"THE CINDERS", "THE BURNT FARM", "THE ASH ROAD", "THE BLACK OAKS", "THE EMBERS"},
	Kingsbridge = {"THE SOUTH MEADOW", "THE CHAPEL ROAD", "THE FORD", "THE MILLRACE", "THE NORTH MEADOW"},
}
local function inWar() return round:GetAttribute("Mode") == "War" end
local function sideName(k) local d = GameConfig.TEAMS[k]; return d and string.upper(d.name) or "" end
local function mySide()
	local c = player.Character
	local t = c and c:GetAttribute("Team")
	if t == "A" or t == "B" then return t end
	local team = player.Team
	for k, d in pairs(GameConfig.TEAMS) do if team and d.name == team.Name then return k end end
	return nil
end
local function mapModel() return workspace:FindFirstChild("Map") end
local function W(name)
	local m = mapModel()
	return m and m:GetAttribute("W_" .. name)
end
local function bannerName(i)
	local list = NAMES[W("Theme") or ""] or {}
	return list[i] or ("BANNER " .. NUMERAL[i])
end
local function myPos()
	local c = player.Character
	local r = c and c:FindFirstChild("HumanoidRootPart")
	return r and r.Position or nil
end

--------------------------------------------------------------------
--  THE SCREEN
--------------------------------------------------------------------
local ui = {}
local gui = Instance.new("ScreenGui")
gui.Name = "WarHud"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = true
gui.DisplayOrder = 8
gui.Enabled = false
gui.Parent = playerGui

local function corner(o, r) local c = Instance.new("UICorner"); c.CornerRadius = UDim.new(0, r or 12); c.Parent = o; return c end
local function outline(o, t)
	local s = Instance.new("UIStroke")
	s.Color, s.Thickness, s.ApplyStrokeMode = Theme.OUTLINE, t or 2, Enum.ApplyStrokeMode.Contextual
	s.Parent = o
	return s
end
local function label(parent, str, size, font, color)
	local l = Instance.new("TextLabel")
	l.BackgroundTransparency = 1
	l.Text, l.TextSize, l.Font, l.TextColor3 = str, size, font or Theme.FONT, color or WHITE
	l.Size = UDim2.new(1, 0, 0, size + 4)
	outline(l, size >= 24 and 2.4 or 1.6)
	l.Parent = parent
	return l
end
local function glass(parent, size, pos, anchor)
	local f = Instance.new("Frame")
	f.BackgroundColor3, f.BackgroundTransparency = Theme.GLASS, 0.18
	f.Size, f.Position, f.AnchorPoint = size, pos, anchor or Vector2.new(0.5, 0)
	corner(f, 14)
	local s = Instance.new("UIStroke"); s.Color, s.Transparency, s.Thickness = WHITE, 0.84, 1.5; s.Parent = f
	f.Parent = parent
	return f
end
local function bar(parent, color, size, pos)
	local track = Instance.new("Frame")
	track.BackgroundColor3, track.BorderSizePixel = Color3.fromRGB(30, 34, 50), 0
	track.Size, track.Position = size, pos
	corner(track, 4)
	track.Parent = parent
	local fill = Instance.new("Frame")
	fill.BackgroundColor3, fill.BorderSizePixel = color, 0
	fill.Size = UDim2.fromScale(1, 1)
	corner(fill, 4)
	fill.Parent = track
	return track, fill
end

-- THE TOP: reinforcements, the clock, the banners
do
	local top = glass(gui, UDim2.new(0.94, 0, 0, 104), UDim2.new(0.5, 0, 0, 10))
	local lim = Instance.new("UISizeConstraint"); lim.MaxSize = Vector2.new(620, 104); lim.Parent = top
	ui.top = top
	for _, k in ipairs({"A", "B"}) do
		local left = k == "A"
		local name = label(top, sideName(k), 14, Theme.FONT, SIDE[k]:Lerp(WHITE, 0.35))
		name.Size = UDim2.new(0.3, 0, 0, 16)
		name.Position = left and UDim2.fromOffset(16, 8) or UDim2.new(0.7, -16, 0, 8)
		name.TextXAlignment = left and Enum.TextXAlignment.Left or Enum.TextXAlignment.Right
		local n = label(top, "300", 30, Theme.FONT_TITLE, WHITE)
		n.Size = UDim2.new(0.3, 0, 0, 32)
		n.Position = left and UDim2.fromOffset(16, 22) or UDim2.new(0.7, -16, 0, 22)
		n.TextXAlignment = name.TextXAlignment
		local track, fill = bar(top, SIDE[k], UDim2.new(0.3, 0, 0, 7), left and UDim2.fromOffset(16, 58) or UDim2.new(0.7, -16, 0, 58))
		if not left then fill.AnchorPoint = Vector2.new(1, 0); fill.Position = UDim2.fromScale(1, 0) end
		ui["tickets" .. k], ui["fill" .. k] = n, fill
	end
	local clock = label(top, "15:00", 20, Theme.FONT_TITLE, WHITE)
	clock.AnchorPoint = Vector2.new(0.5, 0); clock.Position = UDim2.new(0.5, 0, 0, 6); clock.Size = UDim2.fromOffset(120, 22)
	ui.clock = clock
	-- the five banners
	local row = Instance.new("Frame"); row.BackgroundTransparency = 1
	row.AnchorPoint = Vector2.new(0.5, 0); row.Position = UDim2.new(0.5, 0, 0, 32); row.Size = UDim2.fromOffset(5 * 42, 40)
	row.Parent = top
	ui.chips = {}
	for i = 1, 5 do
		local chip = Instance.new("Frame")
		chip.Size = UDim2.fromOffset(34, 34)
		chip.Position = UDim2.fromOffset((i - 1) * 42 + 4, 0)
		chip.BackgroundColor3 = Color3.fromRGB(40, 44, 60)
		chip.ClipsDescendants = true
		corner(chip, 17)
		chip.Parent = row
		local fill = Instance.new("Frame")
		fill.BorderSizePixel = 0
		fill.AnchorPoint = Vector2.new(0, 1)
		fill.Position = UDim2.fromScale(0, 1)
		fill.Size = UDim2.fromScale(1, 0)
		fill.BackgroundColor3 = NEUTRAL
		fill.Parent = chip
		local ring = Instance.new("UIStroke"); ring.Thickness = 2; ring.Color = WHITE; ring.Transparency = 0.6; ring.Parent = chip
		local t = label(chip, NUMERAL[i], 15, Theme.FONT_TITLE, WHITE)
		t.Size = UDim2.fromScale(1, 1)
		t.ZIndex = 2
		local you = Instance.new("Frame")
		you.Size = UDim2.fromOffset(8, 8); you.AnchorPoint = Vector2.new(0.5, 0); you.Position = UDim2.new(0, (i - 1) * 42 + 21, 0, 37)
		you.BackgroundColor3 = GOLD; you.Visible = false
		corner(you, 4)
		you.Parent = row
		ui.chips[i] = {chip = chip, fill = fill, ring = ring, you = you}
	end
	local front = label(top, "", 12, Theme.FONT, Color3.fromRGB(214, 220, 236))
	front.AnchorPoint = Vector2.new(0.5, 0); front.Position = UDim2.new(0.5, 0, 0, 82); front.Size = UDim2.new(0.6, 0, 0, 16)
	ui.front = front
end
-- AT A BANNER
do
	local p = glass(gui, UDim2.new(0.6, 0, 0, 64), UDim2.new(0.5, 0, 0, 124))
	local lim = Instance.new("UISizeConstraint"); lim.MaxSize = Vector2.new(420, 64); lim.Parent = p
	local name = label(p, "", 18, Theme.FONT_TITLE, WHITE); name.Position = UDim2.fromOffset(0, 6); name.Size = UDim2.new(1, 0, 0, 20)
	local state = label(p, "", 13, Theme.FONT, GOLD); state.Position = UDim2.fromOffset(0, 26); state.Size = UDim2.new(1, 0, 0, 16)
	local track = Instance.new("Frame"); track.BackgroundColor3 = Color3.fromRGB(30, 34, 50); track.BorderSizePixel = 0
	track.Size = UDim2.new(1, -40, 0, 8); track.Position = UDim2.new(0, 20, 0, 46); corner(track, 4); track.Parent = p
	local fill = Instance.new("Frame"); fill.BorderSizePixel = 0; fill.Size = UDim2.fromScale(0, 1); fill.Parent = track; corner(fill, 4)
	local mid = Instance.new("Frame"); mid.BackgroundColor3 = WHITE; mid.BorderSizePixel = 0; mid.Size = UDim2.new(0, 2, 1, 4); mid.Position = UDim2.new(0.5, -1, 0, -2); mid.Parent = track
	p.Visible = false
	ui.at, ui.atName, ui.atState, ui.atFill = p, name, state, fill
end
-- CALLS (a banner falls) and WARNINGS (something coming down on you)
do
	local call = label(gui, "", 34, Theme.FONT_TITLE, WHITE)
	call.AnchorPoint = Vector2.new(0.5, 0.5); call.Position = UDim2.fromScale(0.5, 0.3); call.Size = UDim2.new(0.9, 0, 0, 40)
	call.TextScaled = true
	local c1 = Instance.new("UITextSizeConstraint"); c1.MaxTextSize = 38; c1.Parent = call
	call.TextTransparency = 1; call:FindFirstChildOfClass("UIStroke").Transparency = 1
	local sub = label(gui, "", 16, Theme.FONT, Color3.fromRGB(226, 230, 240))
	sub.AnchorPoint = Vector2.new(0.5, 0); sub.Position = UDim2.new(0.5, 0, 0.3, 24); sub.Size = UDim2.new(0.9, 0, 0, 20)
	sub.TextTransparency = 1; sub:FindFirstChildOfClass("UIStroke").Transparency = 1
	local warn = label(gui, "", 30, Theme.FONT_TITLE, Color3.fromRGB(255, 90, 70))
	warn.AnchorPoint = Vector2.new(0.5, 0.5); warn.Position = UDim2.fromScale(0.5, 0.44); warn.Size = UDim2.new(0.9, 0, 0, 36)
	warn.Visible = false
	local hint = label(gui, "", 16, Theme.FONT, WHITE)
	hint.AnchorPoint = Vector2.new(0.5, 0); hint.Position = UDim2.new(0.5, 0, 0.44, 22); hint.Size = UDim2.new(0.9, 0, 0, 20)
	hint.Visible = false
	ui.call, ui.callSub, ui.warn, ui.warnHint = call, sub, warn, hint
end

local function fadeText(l, to, t)
	TweenService:Create(l, TweenInfo.new(t or 0.3), {TextTransparency = to}):Play()
	TweenService:Create(l:FindFirstChildOfClass("UIStroke"), TweenInfo.new(t or 0.3), {Transparency = to}):Play()
end
local function bigCall(text, sub, color, dur)
	ui.callTok = (ui.callTok or 0) + 1
	local tok = ui.callTok
	ui.call.Text, ui.call.TextColor3 = text, color or WHITE
	ui.callSub.Text = sub or ""
	fadeText(ui.call, 0, 0.25); fadeText(ui.callSub, 0, 0.25)
	ui.call.Position = UDim2.fromScale(0.5, 0.31)
	TweenService:Create(ui.call, TweenInfo.new(0.4, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {Position = UDim2.fromScale(0.5, 0.3)}):Play()
	task.delay(dur or 3, function()
		if ui.callTok == tok then fadeText(ui.call, 1, 0.5); fadeText(ui.callSub, 1, 0.5) end
	end)
end
local function warning(text, hintText, dur)
	ui.warnTok = (ui.warnTok or 0) + 1
	local tok = ui.warnTok
	ui.warn.Text, ui.warn.Visible = text, true
	ui.warnHint.Text, ui.warnHint.Visible = hintText or "", hintText ~= nil
	task.spawn(function()
		local t0 = os.clock()
		while ui.warnTok == tok and os.clock() - t0 < (dur or 2) do
			ui.warn.TextTransparency = (math.floor((os.clock() - t0) * 6) % 2 == 0) and 0 or 0.35
			task.wait(0.05)
		end
		if ui.warnTok == tok then ui.warn.Visible, ui.warnHint.Visible = false, false end
	end)
	UIFX.play("Error")
end

--------------------------------------------------------------------
--  THE BANNERS ON THE FIELD
--------------------------------------------------------------------
local field = {rings = {}, beams = {}}
local function colorOf(owner) return owner == "A" and SIDE.A or (owner == "B" and SIDE.B or NEUTRAL) end
local function buildField()
	for _, p in pairs(field.rings) do p:Destroy() end
	for _, p in pairs(field.beams) do p:Destroy() end
	field.rings, field.beams = {}, {}
	local R = W("Radius") or 18
	for i = 1, 5 do
		local pos = W("Banner" .. i)
		if typeof(pos) == "Vector3" then
			local g = pos   -- (banners stand on level ground: WarMap keeps the swells away from them)
			local ring = WarFX.part(V3(0.25, R * 2, R * 2), NEUTRAL, Enum.Material.Neon, 0.82)
			ring.Shape = Enum.PartType.Cylinder
			ring.CFrame = CF(g + V3(0, 0.7, 0)) * CFrame.Angles(0, 0, math.rad(90))
			ring.Parent = workspace
			field.rings[i] = ring
			local beam = WarFX.part(V3(1.6, 220, 1.6), NEUTRAL, Enum.Material.Neon, 1)
			beam.CFrame = CF(g + V3(0, 110, 0))
			beam.Parent = workspace
			field.beams[i] = beam
		end
	end
end
local function paintField()
	local m = mapModel()
	local me = mySide()
	for i = 1, 5 do
		local owner = round:GetAttribute("WarBanner" .. i) or ""
		local col = colorOf(owner)
		local flag = m and m:FindFirstChild("WarFlag_" .. i, true)
		if flag and flag.Color ~= col then flag.Color = col end
		local ring = field.rings[i]
		if ring then ring.Color = col end
		-- a beam over the banners being fought for
		local c = round:GetAttribute("WarCount" .. i) or "0:0"
		local a, b = c:match("(%d+):(%d+)")
		a, b = tonumber(a) or 0, tonumber(b) or 0
		local beam = field.beams[i]
		if beam then
			local fought = (a > 0 and b > 0) or (owner ~= "A" and a > 0) or (owner ~= "B" and b > 0)
			beam.Transparency = fought and 0.82 or 1
			beam.Color = (a > b) and SIDE.A or ((b > a) and SIDE.B or GOLD)
		end
	end
end

--------------------------------------------------------------------
--  THE HUD, EVERY FRAME (cheap)
--------------------------------------------------------------------
local function frontFor(side)
	if side == "A" then
		for i = 1, 5 do if (round:GetAttribute("WarBanner" .. i) or "") ~= "A" then return i end end
		return 5
	end
	for i = 5, 1, -1 do if (round:GetAttribute("WarBanner" .. i) or "") ~= "B" then return i end end
	return 1
end
local function canTake(side, i)
	local o = function(k) return round:GetAttribute("WarBanner" .. k) or "" end
	if o(i) == side then return true end
	if side == "A" then return i == 1 or o(i - 1) == "A" end
	return i == 5 or o(i + 1) == "B"
end
local lastHud = 0
local function hud()
	local t0 = round:GetAttribute("WarTickets") or 300
	for _, k in ipairs({"A", "B"}) do
		local n = round:GetAttribute("WarTickets" .. k) or t0
		ui["tickets" .. k].Text = tostring(n)
		ui["fill" .. k].Size = UDim2.fromScale(math.clamp(n / math.max(t0, 1), 0, 1), 1)
	end
	local left = round:GetAttribute("TimeLeft") or 0
	ui.clock.Text = string.format("%d:%02d", math.floor(left / 60), left % 60)
	local me = mySide()
	local myFront = me and frontFor(me)
	local pos = myPos()
	local R = W("Radius") or 18
	local here = nil
	for i = 1, 5 do
		local c = ui.chips[i]
		local owner = round:GetAttribute("WarBanner" .. i) or ""
		local p = round:GetAttribute("WarProg" .. i) or 0
		c.chip.BackgroundColor3 = owner == "" and Color3.fromRGB(40, 44, 60) or colorOf(owner):Lerp(Color3.new(), 0.45)
		c.fill.BackgroundColor3 = p >= 0 and SIDE.A or SIDE.B
		c.fill.Size = UDim2.fromScale(1, math.abs(p))
		local fighting = i == myFront
		c.ring.Color = fighting and GOLD or WHITE
		c.ring.Transparency = fighting and 0 or 0.6
		c.ring.Thickness = fighting and 3 or 2
		local bp = W("Banner" .. i)
		local inside = pos and typeof(bp) == "Vector3" and (V3(pos.X, 0, pos.Z) - V3(bp.X, 0, bp.Z)).Magnitude <= R
		c.you.Visible = inside == true
		if inside then here = i end
	end
	ui.front.Text = myFront and ("FIGHTING FOR  " .. bannerName(myFront)) or ""
	-- at a banner: what's happening there
	if here and me then
		local owner = round:GetAttribute("WarBanner" .. here) or ""
		local p = round:GetAttribute("WarProg" .. here) or 0
		local c = round:GetAttribute("WarCount" .. here) or "0:0"
		local a, b = c:match("(%d+):(%d+)")
		a, b = tonumber(a) or 0, tonumber(b) or 0
		local mine, theirs = me == "A" and a or b, me == "A" and b or a
		local state
		if owner == me and theirs == 0 then state = math.abs(p) >= 0.99 and "HOLDING" or "WINNING IT BACK"
		elseif not canTake(me, here) and owner ~= me then state = "CAN'T TAKE IT YET  ·  TAKE " .. bannerName(frontFor(me)) .. " FIRST"
		elseif mine > theirs then state = string.format("TAKING IT  ·  %d vs %d", mine, theirs)
		elseif theirs > mine then state = string.format("LOSING IT!  ·  %d vs %d", mine, theirs)
		else state = string.format("CONTESTED  ·  %d vs %d", mine, theirs) end
		ui.atName.Text = bannerName(here)
		ui.atState.Text = state
		ui.atState.TextColor3 = (theirs > mine) and Color3.fromRGB(255, 110, 90) or GOLD
		ui.atFill.BackgroundColor3 = p >= 0 and SIDE.A or SIDE.B
		ui.atFill.AnchorPoint = Vector2.new(p >= 0 and 0 or 1, 0)
		ui.atFill.Position = UDim2.fromScale(0.5, 0)
		ui.atFill.Size = UDim2.fromScale(math.abs(p) / 2, 1)
		ui.at.Visible = true
	else
		ui.at.Visible = false
	end
end

--------------------------------------------------------------------
--  THE ARMIES ON THE FLANKS
--------------------------------------------------------------------
local war = {on = false}
local function phone() return Device.kind() == "phone" end
local function buildArmies()
	if war.army then war.army:stop() end
	local army = WarFX.army()
	war.army = army
	local lanes = {W("Lane1") or 150, W("Lane2") or 198, W("Lane3") or 246}
	if phone() then lanes = {lanes[1]} end
	local fz = round:GetAttribute("WarFront") or 0
	local n = 0
	for _, s in ipairs({-1, 1}) do
		for li, x in ipairs(lanes) do
			for _, side in ipairs({"A", "B"}) do
				n += 1
				local f = side == "A" and 1 or -1
				local id = side .. s .. li
				army:regiment(id, {color = SIDE[side]:Lerp(Color3.new(), 0.15), at = V3(s * x, 0, fz - f * 40), facing = f,
					cols = phone() and 6 or 10, ranks = phone() and 3 or 5, kind = (li == 2) and "pike" or "foot", spacing = 3.1})
			end
		end
	end
	-- archers on both flanks, a battle-mage circle a side
	for _, side in ipairs({"A", "B"}) do
		local f = side == "A" and 1 or -1
		for k = 1, 2 do
			local at = W("Arch" .. side .. k)
			if typeof(at) == "Vector3" then
				army:regiment("arch" .. side .. k, {color = SIDE[side]:Lerp(Color3.fromRGB(90, 80, 60), 0.4), at = at, facing = f,
					cols = phone() and 5 or 8, ranks = phone() and 2 or 3, kind = "archer", spacing = 2.8, banner = true})
			end
		end
		local mg = W("Mage" .. side)
		if typeof(mg) == "Vector3" then
			army:regiment("mage" .. side, {color = side == "A" and Color3.fromRGB(70, 90, 220) or Color3.fromRGB(150, 50, 160), at = mg + V3(0, 0, -f * 4), facing = f,
				cols = 3, ranks = 2, kind = "mage", spacing = 4, banner = false})
		end
	end
	war.lanes = lanes
end
-- every half second: the regiments march to the front and clash there
local function armiesFollow()
	local army = war.army
	if not army then return end
	local fz = round:GetAttribute("WarFront") or 0
	local t = os.clock()
	for _, s in ipairs({-1, 1}) do
		for li in ipairs(war.lanes or {}) do
			-- (each lane's line wavers a little on its own)
			local sway = math.sin(t * 0.13 + li * 1.7 + s) * 10
			local zA, zB = fz + sway - 2, fz + sway + 2
			army:march("A" .. s .. li, zA)
			army:march("B" .. s .. li, zB)
			local ra, rb = army.regs["A" .. s .. li], army.regs["B" .. s .. li]
			local meet = ra and rb and math.abs(ra.z - rb.z) < 10
			army:clash("A" .. s .. li, meet)
			army:clash("B" .. s .. li, meet)
			if meet and math.random() < 0.08 then
				WarFX.dust(V3(s * (war.lanes[li]), 1, (ra.z + rb.z) / 2), 1.6, Color3.fromRGB(150, 136, 116))
			end
		end
	end
	-- the archers keep a fixed distance behind their side's line
	for _, side in ipairs({"A", "B"}) do
		local f = side == "A" and 1 or -1
		for k = 1, 2 do
			local r = army.regs["arch" .. side .. k]
			if r then army:march("arch" .. side .. k, math.clamp(fz - f * 110, -330, 330)) end
		end
	end
end

--------------------------------------------------------------------
--  THE ENGINES (what the server fires)
--------------------------------------------------------------------
local function near(at, r)
	local p = myPos()
	return p and (V3(p.X, 0, p.Z) - V3(at.X, 0, at.Z)).Magnitude <= r
end
local EV = {}
function EV.Treb(d)
	local close = near(d.to, d.r + 50)
	WarFX.fireball(d.from, d.to, d.t, {big = true, whistle = close, height = 120})
	if near(d.to, d.r + 6) then warning("TREBUCHET!", "GET OUT OF THE RED RING", d.t) end
end
function EV.Volley(d)
	local army = war.army
	local k = d.to.X < 0 and 1 or 2
	if army then army:loose("arch" .. d.side .. k) end
	WarFX.volley(d.from, d.to, d.n or 60, {flight = d.t, spread = d.r * 0.6, stagger = 0.4})
	if near(d.to, d.r + 4) and mySide() ~= d.side then
		warning("VOLLEY!", "RAISE YOUR GUARD  " .. InputHints.say("Block") .. "  ·  OR GET UNDER A ROOF", d.t)
	end
end
function EV.Barrage(d)
	if war.army then war.army:loose("mage" .. d.side) end
	local who = (d.side == "A" and "THE CROWN'S" or "THE IRON HOST'S") .. " BATTLE-MAGES"
	local mine = mySide() == d.side
	if d.kind == "meteors" then
		bigCall("METEOR STORM", who, mine and SIDE[d.side] or Color3.fromRGB(200, 130, 255), 2.6)
		for k, p in ipairs(d.points) do
			local from = d.from + V3((math.random() - 0.5) * 40, 80, (math.random() - 0.5) * 40)
			WarFX.fireball(from, p, d.t + k * d.step, {color = ARCANE, size = 4.4, height = 18, big = true, whistle = near(p, 40)})
		end
		for _, p in ipairs(d.points) do if near(p, d.r + 4) and not mine then warning("METEORS!", "MOVE!", d.t) break end end
	elseif d.kind == "lightning" then
		bigCall("CHAIN LIGHTNING", who, mine and SIDE[d.side] or Color3.fromRGB(160, 200, 255), 2.4)
		for k, p in ipairs(d.points) do task.delay(d.t + k * d.step, function() if war.on then WarFX.strike(p) end end) end
		for _, p in ipairs(d.points) do if near(p, d.r + 3) and not mine then warning("LIGHTNING!", "MOVE!", d.t) break end end
	else
		bigCall("FROST", who, mine and SIDE[d.side] or Color3.fromRGB(150, 210, 255), 2.4)
		local p = d.points[1]
		task.delay(d.t, function() if war.on then WarFX.frost(p, d.r) end end)
		if near(p, d.r + 3) and not mine then warning("FROST!", "GET CLEAR OR BE SLOWED", d.t) end
	end
end
function EV.Captured(d)
	local me = mySide()
	local name = bannerName(d.id)
	if d.side then
		local ours = d.side == me
		bigCall((d.side == "A" and "THE CROWN" or "THE IRON HOST") .. " TOOK " .. name, ours and "PUSH ON!" or "TAKE IT BACK!", SIDE[d.side], 3)
		WarFX.sound(ours and "Horn" or "Charge", nil, {volume = ours and 0.8 or 0.6})
	elseif d.lost then
		local ours = d.lost == me
		bigCall((ours and "WE'RE LOSING " or "THEY'RE LOSING ") .. name, ours and "HOLD IT!" or "PUSH!", ours and Color3.fromRGB(255, 110, 90) or GOLD, 2.4)
	end
	paintField()
end
function EV.Charge(d)
	local fz = round:GetAttribute("WarFront") or 0
	local f = d.side == "A" and 1 or -1
	-- (up the gap between the second and third lanes, into the enemy's flank)
	local x = d.lane * (((W("Lane2") or 198) + (W("Lane3") or 246)) / 2)
	local path = {}
	for _, z in ipairs({-f * 420, fz - f * 120, fz + f * 10, fz + f * 90}) do table.insert(path, WarFX.ground(V3(x, 0, z))) end
	WarFX.riders(path, phone() and 9 or 15, {color = SIDE[d.side], speed = 52})
	WarFX.sound("Horn", path[1], {range = 1500, near = 200, volume = 0.9})
	task.delay(5, function() if war.on then WarFX.sound("Charge", path[3], {range = 1500, near = 160}) end end)
	if mySide() == d.side then bigCall("THE CAVALRY CHARGES", d.lane < 0 and "ON THE LEFT FLANK" or "ON THE RIGHT FLANK", SIDE[d.side], 2.4) end
end

-- the distant war: volleys and fire out on the flanks between the server's own
local function distantWar()
	local fz = round:GetAttribute("WarFront") or 0
	local lanes = war.lanes or {152}
	local s = math.random() < 0.5 and -1 or 1
	local x = s * lanes[math.random(#lanes)]
	local roll = math.random()
	if roll < 0.45 then
		local side = math.random() < 0.5 and "A" or "B"
		local f = side == "A" and 1 or -1
		WarFX.volley(V3(x + (math.random() - 0.5) * 20, 6, fz - f * 110), V3(x, 0, fz + f * (6 + math.random() * 20)), 40, {flight = 2.6, spread = 14, stick = false, range = 260})
	elseif roll < 0.75 then
		local side = math.random() < 0.5 and "A" or "B"
		local arm = W("Treb" .. side .. math.random(2))
		if typeof(arm) == "Vector3" then
			local f = side == "A" and 1 or -1
			WarFX.fireball(arm, WarFX.ground(V3(x + (math.random() - 0.5) * 30, 0, fz + f * (10 + math.random() * 40))), 4.2, {big = math.random() < 0.5})
		end
	else
		WarFX.sound("Charge", V3(x, 0, fz), {volume = 0.5, range = 1200, near = 180})
	end
end

--------------------------------------------------------------------
--  ARRIVING: a few seconds over the field, the battle's name
--------------------------------------------------------------------
local arrive = {}
local function arrival()
	local me = mySide()
	local camp = W("Camp" .. (me or "A"))
	if typeof(camp) ~= "Vector3" then return end
	local f = (me == "B") and -1 or 1
	local fz = round:GetAttribute("WarFront") or 0
	local a = CFrame.lookAt(camp + V3(60, 80, -f * 80), V3(0, 0, fz))
	local b = CFrame.lookAt(camp + V3(20, 34, f * 30), V3(0, 4, fz))
	local t0 = os.clock()
	local len = 5.2
	arrive.on = true
	_G.CinematicUp = true
	local theme = W("Theme") or ""
	bigCall("THE BATTLE OF " .. string.upper(GameConfig.mapTitle(theme)), (me and sideName(me) or "") .. "  ·  TAKE THE BANNERS  ·  HOLD THE LINE", me and SIDE[me] or WHITE, 4.6)
	WarFX.sound("Horn", nil, {volume = 0.9})
	RunService:BindToRenderStep("WarArrival", Enum.RenderPriority.Camera.Value + 5, function()
		local u = math.clamp((os.clock() - t0) / len, 0, 1)
		u = u * u * (3 - 2 * u)
		local cam = workspace.CurrentCamera
		cam.CameraType = Enum.CameraType.Scriptable
		cam.CFrame = a:Lerp(b, u)
		if u >= 1 then arrive.stop() end
	end)
	arrive.stop = function()
		if not arrive.on then return end
		arrive.on = false
		_G.CinematicUp = nil
		pcall(function() RunService:UnbindFromRenderStep("WarArrival") end)
	end
end
UserInputService.InputBegan:Connect(function(input, gp)
	if arrive.on and not gp and input.UserInputType ~= Enum.UserInputType.MouseMovement then arrive.stop() end
end)

--------------------------------------------------------------------
--  COMING AND GOING
--------------------------------------------------------------------
remote.OnClientEvent:Connect(function(what, d)
	if not war.on then return end
	local f = EV[what]
	if f then
		local ok, err = pcall(f, d or {})
		if not ok then warn("[War] " .. tostring(what) .. ": " .. tostring(err)) end
	end
end)

local function enter()
	if war.on then return end
	war.on = true
	war.token = (war.token or 0) + 1
	local token = war.token
	gui.Enabled = true
	task.spawn(function()
		-- the field's description arrives with the map
		for _ = 1, 80 do if typeof(W("Banner1")) == "Vector3" then break end task.wait(0.25) end
		if war.token ~= token then return end
		buildField()
		buildArmies()
		local wk = W("Weather")
		if type(wk) == "string" and wk ~= "" then WarFX.weather(wk) end
		war.roar = WarFX.loop("Battle", 0.7)
		paintField()
		-- the field's life
		local nextDistant = os.clock() + 3
		while war.on and war.token == token do
			armiesFollow()
			paintField()
			if os.clock() >= nextDistant then
				nextDistant = os.clock() + 4 + math.random() * 4
				pcall(distantWar)
			end
			task.wait(0.5)
		end
	end)
	-- the HUD, ten times a second
	task.spawn(function()
		while war.on and war.token == token do
			gui.Enabled = round:GetAttribute("State") == "Round" and not _G.CinematicUp
			pcall(hud)
			task.wait(0.1)
		end
	end)
end
local function leave()
	if not war.on then return end
	war.on = false
	war.token = (war.token or 0) + 1
	gui.Enabled = false
	if arrive.stop then arrive.stop() end
	if war.army then war.army:stop(); war.army = nil end
	for _, p in pairs(field.rings) do p:Destroy() end
	for _, p in pairs(field.beams) do p:Destroy() end
	field.rings, field.beams = {}, {}
	WarFX.stopLoop(war.roar, 1)
	war.roar = nil
	WarFX.clear()
end

-- a new round (a new field): everything again
round:GetAttributeChangedSignal("Map"):Connect(function()
	if war.on then leave(); task.wait(0.5); if inWar() then enter() end end
end)
round:GetAttributeChangedSignal("Mode"):Connect(function() if inWar() then enter() else leave() end end)
if inWar() then enter() end

-- your first body of a round: the flight over the field
local arrivedRound = nil
player.CharacterAdded:Connect(function()
	if not inWar() then return end
	local n = round:GetAttribute("Number")
	if arrivedRound == n then return end
	arrivedRound = n
	task.wait(0.6)
	if inWar() and round:GetAttribute("State") == "Round" then pcall(arrival) end
end)
