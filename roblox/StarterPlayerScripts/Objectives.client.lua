--[[ OBJECTIVES (client) — the HUD for a mode that publishes Obj* attributes on
     ReplicatedStorage.Round (Game ▸ Modes ▸ Siege):
       • under the round strip: ATTACK or DEFEND for your side, the stage line,
         a bar in the attackers' colour with what's happening there ("PUSHING
         3 v 1", "CONTESTED", "BATTERING · GATE 4 / 10"…) and a pip per stage
       • a marker over the objective in the world, with how far it is
       • a banner when a stage falls ("THE GATE IS BROKEN  +2:30")
     ObjectiveEvent (server -> all): "Stage", {text, add, team, final} ]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local GameConfig = require(ReplicatedStorage:WaitForChild("GameConfig"))
local Theme = require(ReplicatedStorage:WaitForChild("Theme"))

local player = Players.LocalPlayer
local round = ReplicatedStorage:WaitForChild("Round")

local gui = Instance.new("ScreenGui")
gui.Name = "Objectives"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = true
gui.DisplayOrder = 29
gui.Parent = player:WaitForChild("PlayerGui")

local function label(parent, text, size, font, color, align)
	local l = Instance.new("TextLabel")
	l.BackgroundTransparency = 1
	l.Font = font or Theme.FONT
	l.TextSize = size or 14
	l.TextColor3 = color or Theme.TEXT
	l.TextXAlignment = align or Enum.TextXAlignment.Center
	l.TextStrokeTransparency = 0.6
	l.Text = text or ""
	l.Parent = parent
	return l
end
local function corner(o, r) local c = Instance.new("UICorner"); c.CornerRadius = UDim.new(0, r or 6); c.Parent = o; return c end

--------------------------------------------------------------------
--  THE PANEL (under the round strip)
--------------------------------------------------------------------
local panel = Instance.new("Frame")
panel.AnchorPoint = Vector2.new(0.5, 0)
panel.Position = UDim2.new(0.5, 0, 0, 80)
panel.Size = UDim2.fromOffset(460, 62)
panel.BackgroundColor3 = Theme.PANEL
panel.BackgroundTransparency = 0.25
panel.Visible = false
panel.Parent = gui
corner(panel, 10)

local role = Instance.new("TextLabel")
role.Position = UDim2.fromOffset(10, 8)
role.Size = UDim2.fromOffset(78, 20)
role.Font = Theme.FONT_TITLE
role.TextSize = 13
role.TextColor3 = Color3.new(1, 1, 1)
role.Parent = panel
corner(role, 5)

local line = label(panel, "", 14, Theme.FONT, Theme.TEXT, Enum.TextXAlignment.Left)
line.Position = UDim2.fromOffset(96, 8)
line.Size = UDim2.new(1, -106, 0, 20)
line.TextTruncate = Enum.TextTruncate.AtEnd

local barBack = Instance.new("Frame")
barBack.Position = UDim2.fromOffset(10, 33)
barBack.Size = UDim2.new(1, -20, 0, 18)
barBack.BackgroundColor3 = Color3.fromRGB(24, 22, 26)
barBack.BorderSizePixel = 0
barBack.Parent = panel
corner(barBack, 5)
local barFill = Instance.new("Frame")
barFill.Size = UDim2.fromScale(0, 1)
barFill.BorderSizePixel = 0
barFill.Parent = barBack
corner(barFill, 5)
local barText = label(barBack, "", 13, Theme.FONT_TITLE, Color3.new(1, 1, 1))
barText.Size = UDim2.fromScale(1, 1)
barText.ZIndex = 3

local pips = Instance.new("Frame")
pips.AnchorPoint = Vector2.new(0.5, 0)
pips.Position = UDim2.new(0.5, 0, 1, 4)
pips.Size = UDim2.fromOffset(200, 10)
pips.BackgroundTransparency = 1
pips.Parent = panel
local pl = Instance.new("UIListLayout")
pl.FillDirection = Enum.FillDirection.Horizontal
pl.HorizontalAlignment = Enum.HorizontalAlignment.Center
pl.Padding = UDim.new(0, 8)
pl.Parent = pips
local pipList = {}

--------------------------------------------------------------------
--  THE WORLD MARKER
--------------------------------------------------------------------
local anchor = Instance.new("Part")
anchor.Name = "ObjectiveMarker"
anchor.Anchored, anchor.CanCollide, anchor.CanQuery, anchor.CanTouch = true, false, false, false
anchor.Transparency = 1
anchor.Size = Vector3.new(0.2, 0.2, 0.2)
local bb = Instance.new("BillboardGui")
bb.Size = UDim2.fromOffset(170, 52)
bb.AlwaysOnTop = true
bb.LightInfluence = 0
bb.MaxDistance = 2000
bb.Adornee = anchor
bb.Enabled = false
bb.ResetOnSpawn = false
bb.Parent = player.PlayerGui   -- (a BillboardGui inside a ScreenGui doesn't draw)
local diamond = Instance.new("Frame")
diamond.AnchorPoint = Vector2.new(0.5, 0)
diamond.Position = UDim2.new(0.5, 0, 0, 0)
diamond.Size = UDim2.fromOffset(16, 16)
diamond.Rotation = 45
diamond.BorderSizePixel = 0
diamond.Parent = bb
local verb = label(bb, "", 15, Theme.FONT_TITLE, Color3.new(1, 1, 1))
verb.Position = UDim2.fromOffset(0, 18)
verb.Size = UDim2.new(1, 0, 0, 18)
verb.TextStrokeTransparency = 0.3
local dist = label(bb, "", 12, Theme.FONT, Color3.fromRGB(230, 226, 214))
dist.Position = UDim2.fromOffset(0, 35)
dist.Size = UDim2.new(1, 0, 0, 14)
dist.TextStrokeTransparency = 0.3

--------------------------------------------------------------------
--  THE BANNER (a stage falls)
--------------------------------------------------------------------
local banner = Instance.new("Frame")
banner.AnchorPoint = Vector2.new(0.5, 0.5)
banner.Position = UDim2.new(0.5, 0, 0.3, 0)
banner.Size = UDim2.fromOffset(640, 86)
banner.BackgroundTransparency = 1
banner.Visible = false
banner.Parent = gui
local bannerText = label(banner, "", 34, Theme.FONT_TITLE, Color3.new(1, 1, 1))
bannerText.Size = UDim2.new(1, 0, 0, 44)
bannerText.TextStrokeTransparency = 0.2
local bannerSub = label(banner, "", 18, Theme.FONT, Theme.ACCENT)
bannerSub.Position = UDim2.fromOffset(0, 48)
bannerSub.Size = UDim2.new(1, 0, 0, 24)
bannerSub.TextStrokeTransparency = 0.3
local bannerToken = 0

local function teamOf(key) return GameConfig.TEAMS[key] end
local function myKey()
	local t = player.Team
	if not t then return nil end
	for k, d in pairs(GameConfig.TEAMS) do if d.name == t.Name then return k end end
	return nil
end
local function fmtTime(s)
	s = math.max(0, math.floor(s))
	return string.format("%d:%02d", s // 60, s % 60)
end

local ok, objEvent = pcall(function() return ReplicatedStorage:WaitForChild("ObjectiveEvent", 30) end)
if ok and objEvent then
	objEvent.OnClientEvent:Connect(function(what, info)
		if what ~= "Stage" or type(info) ~= "table" then return end
		bannerToken += 1
		local token = bannerToken
		local mine = myKey() == info.team
		local col = teamOf(info.team) and teamOf(info.team).rgb or Theme.ACCENT
		bannerText.Text = tostring(info.text or "")
		bannerText.TextColor3 = col:Lerp(Color3.new(1, 1, 1), 0.35)
		if info.horde then
			-- the horde: a wave coming, or a wave beaten
			bannerText.TextColor3 = info.team == "B" and Color3.fromRGB(255, 120, 90) or Theme.GOOD
			bannerSub.Text = info.team == "B" and string.format("%d FOES ARE COMING", info.count or 0) or "THE FALLEN CAN SPAWN AGAIN  ·  GET READY"
		elseif info.final then
			bannerSub.Text = mine and "THE CASTLE IS OURS" or "THE CASTLE HAS FALLEN"
		elseif (info.add or 0) > 0 then
			bannerSub.Text = string.format("+%s ON THE CLOCK  ·  %s", fmtTime(info.add), mine and "PRESS ON!" or "FALL BACK AND HOLD!")
		else
			bannerSub.Text = mine and "PRESS ON!" or "FALL BACK!"
		end
		banner.Visible = true
		banner.Size = UDim2.fromOffset(560, 76)
		TweenService:Create(banner, TweenInfo.new(0.35, Enum.EasingStyle.Back), {Size = UDim2.fromOffset(640, 86)}):Play()
		bannerText.TextTransparency, bannerSub.TextTransparency = 0, 0
		task.delay(3.4, function()
			if bannerToken ~= token then return end
			TweenService:Create(bannerText, TweenInfo.new(0.6), {TextTransparency = 1}):Play()
			TweenService:Create(bannerSub, TweenInfo.new(0.6), {TextTransparency = 1}):Play()
			task.delay(0.65, function() if bannerToken == token then banner.Visible = false end end)
		end)
	end)
end

--------------------------------------------------------------------
--  EVERY FRAME
--------------------------------------------------------------------
local STATE = {
	moving = "PUSHING", contested = "CONTESTED", battering = "BATTERING", capturing = "CAPTURING",
	losing = "LOSING GROUND", fighting = "FIGHT", idle = "",
}
local function hubMenuUp()
	local h = player.PlayerGui:FindFirstChild("HubMenu")
	return h ~= nil and h.Enabled
end

RunService.RenderStepped:Connect(function()
	local kind = round:GetAttribute("ObjKind")
	local live = kind ~= nil and round:GetAttribute("State") == "Round"
	panel.Visible = live and not hubMenuUp()
	bb.Enabled = live and kind ~= "Horde"
	if not live then return end
	if kind == "Hill" then
		-- KOTH: the scoreboard has the points; here, just the marker over the hill
		panel.Visible = false
		local pos = round:GetAttribute("ObjPos")
		if typeof(pos) == "Vector3" then
			anchor.Position = pos + Vector3.new(0, 12, 0)
			if anchor.Parent ~= workspace then anchor.Parent = workspace end
			local cam = workspace.CurrentCamera
			local far = cam and (cam.CFrame.Position - pos).Magnitude or 0
			dist.Text = string.format("%dm", math.floor(far / 3.6 + 0.5))
			local owner, st, me = round:GetAttribute("ObjOwner") or "", round:GetAttribute("ObjState"), myKey()
			verb.Text = st == "contested" and "CONTESTED" or ((owner ~= "" and owner == me) and "HOLD THE HILL" or "TAKE THE HILL")
			local col = owner ~= "" and teamOf(owner) and teamOf(owner).rgb or Color3.fromRGB(240, 226, 190)
			if st == "contested" then col = Color3.fromRGB(255, 120, 90) end
			verb.TextColor3 = col:Lerp(Color3.new(1, 1, 1), 0.25)
			diamond.BackgroundColor3 = col
		end
		return
	end
	if kind == "Horde" then
		role.Text = "HORDE"
		role.BackgroundColor3 = Color3.fromRGB(150, 110, 60)
		line.Text = string.format("%s   ·   %d OF YOU STANDING", string.upper(round:GetAttribute("ObjLabel") or ""), round:GetAttribute("ObjAttack") or 0)
		barFill.BackgroundColor3 = round:GetAttribute("ObjState") == "break" and Theme.GOOD or Color3.fromRGB(230, 170, 60)
		barFill.Size = UDim2.fromScale(math.clamp(round:GetAttribute("ObjProgress") or 0, 0, 1), 1)
		barText.Text = round:GetAttribute("ObjNote") or ""
		for _, pp in ipairs(pipList) do pp:Destroy() end
		pipList = {}
		return
	end
	local atk = round:GetAttribute("Attackers") or "A"
	local def = atk == "A" and "B" or "A"
	local me = myKey()
	local attacking = me == atk
	local atkCol = teamOf(atk) and teamOf(atk).rgb or Theme.ACCENT
	local myCol = me and teamOf(me) and teamOf(me).rgb or Theme.DIM
	role.Text = me and (attacking and "ATTACK" or "DEFEND") or "WATCH"
	role.BackgroundColor3 = myCol
	local stage, stages = round:GetAttribute("ObjStage") or 1, round:GetAttribute("ObjStages") or 1
	line.Text = string.format("STAGE %d / %d  ·  %s", stage, stages, string.upper(round:GetAttribute("ObjLabel") or ""))
	local prog = round:GetAttribute("ObjProgress") or 0
	barFill.BackgroundColor3 = atkCol
	barFill.Size = UDim2.fromScale(math.clamp(prog, 0, 1), 1)
	local st = round:GetAttribute("ObjState") or "idle"
	local a, d = round:GetAttribute("ObjAttack") or 0, round:GetAttribute("ObjDefend") or 0
	local note = round:GetAttribute("ObjNote") or ""
	local text = STATE[st] or ""
	if st == "moving" or st == "contested" or st == "capturing" then text = string.format("%s   %d v %d", text, a, d) end
	if st == "idle" then text = kind == "Ram" and (note ~= "" and "THE RAM STANDS IDLE" or "THE RAM IS STOPPED") or "NOBODY ON THE POINT" end
	if note ~= "" and st ~= "idle" then text = text .. "   ·   " .. note end
	barText.Text = text
	-- stage pips
	if #pipList ~= stages then
		for _, p in ipairs(pipList) do p:Destroy() end
		pipList = {}
		for i = 1, stages do
			local p = Instance.new("Frame")
			p.Size = UDim2.fromOffset(10, 10)
			p.BorderSizePixel = 0
			p.LayoutOrder = i
			p.Parent = pips
			corner(p, 5)
			pipList[i] = p
		end
	end
	for i, p in ipairs(pipList) do
		p.BackgroundColor3 = i < stage and atkCol or (i == stage and Color3.new(1, 1, 1) or Color3.fromRGB(70, 68, 74))
		p.BackgroundTransparency = (i == stage) and (0.2 + 0.3 * math.abs(math.sin(os.clock() * 3))) or 0
	end
	-- the marker
	local pos = round:GetAttribute("ObjPos")
	if typeof(pos) == "Vector3" then
		anchor.Position = pos + Vector3.new(0, 9, 0)
		if anchor.Parent ~= workspace then anchor.Parent = workspace end
		local cam = workspace.CurrentCamera
		local far = cam and (cam.CFrame.Position - pos).Magnitude or 0
		dist.Text = string.format("%dm", math.floor(far / 3.6 + 0.5))   -- (studs to rough metres: a body is ~5 studs)
		local gate = note:sub(1, 4) == "GATE"
		local words
		if kind == "Ram" then words = attacking and (gate and "BREAK THE GATE" or "PUSH THE RAM") or (gate and "HOLD THE GATE" or "STOP THE RAM")
		elseif kind == "Capture" then words = attacking and "CAPTURE" or "DEFEND"
		elseif kind == "Slay" then words = attacking and "SLAY" or "PROTECT"
		else words = string.upper(kind) end
		verb.Text = words
		verb.TextColor3 = myCol:Lerp(Color3.new(1, 1, 1), 0.25)
		diamond.BackgroundColor3 = myCol
	end
end)
