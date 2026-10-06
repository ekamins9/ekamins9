--[[ NAME TAGS — the names over other fighters' heads, drawn here (Roblox's
     own are switched off: LoadoutServer for players, Bots for bots).

     For immersion a name only shows when you look right at someone near
     enough to read it — your aim (the middle of the screen, or the mouse
     when it's free) on their body, with a clear line of sight — or when
     they're right next to you. In the Courtyard, a place to talk, everyone
     near you shows anyway. Names fade in quickly and out slowly.

       the name      DisplayName (a bot: its name). Your team mates and foes in
                     their team's colour (team modes); otherwise:
                       • the season pass: gold with a slow shimmer and a crown
                       • staff: their role's colour and a badge (OWNER · ADMIN · MOD · HELPER)
       the title     under the name: the title they wear (player attribute Title,
                     the free "Recruit" left out); a bot shows its rank
       the level     a small badge before the name (player attribute Level)
     Player attributes come from Hub ▸ Pastimes (Title, Level, PassHolder) and
     Admin ▸ AdminServer (StaffRole). ]]

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Theme = require(ReplicatedStorage:WaitForChild("Theme"))
local GameConfig = require(ReplicatedStorage:WaitForChild("GameConfig"))

local player = Players.LocalPlayer
local roundNode = ReplicatedStorage:WaitForChild("Round")
local pgui = player:WaitForChild("PlayerGui")

local RANGE = 45            -- studs: past this nobody's name shows
local NEAR = 9              -- this close a name shows wherever you look
local HUB_RANGE = 24        -- the Courtyard: names this near show anyway
local AIM_BASE = 0.03       -- aim slack, a share of the screen's height, on top of the body's own size
local FADE_IN, FADE_OUT = 0.12, 0.45
local SIGHT_EVERY = 0.15    -- seconds between line-of-sight checks per tag
local FREE_TITLES = {Recruit = true}

local GOLD = Color3.fromRGB(255, 206, 84)
local GOLD2 = Color3.fromRGB(255, 244, 200)
local TITLE_COL = Color3.fromRGB(255, 226, 168)
local ROLE = {
	Owner = {"OWNER", Color3.fromRGB(255, 196, 60)}, Admin = {"ADMIN", Color3.fromRGB(235, 84, 72)},
	Moderator = {"MOD", Color3.fromRGB(84, 150, 245)}, Helper = {"HELPER", Color3.fromRGB(110, 205, 120)},
}
local RANK = {Squire = Color3.fromRGB(214, 190, 150), Knight = Color3.fromRGB(150, 182, 255), Champion = Color3.fromRGB(255, 120, 96),
	Drill = Color3.fromRGB(200, 200, 200), Guard = Color3.fromRGB(200, 200, 200)}

local tags = {}   -- [model] = tag

local function text(parent, size, font)
	local t = Instance.new("TextLabel")
	t.BackgroundTransparency = 1
	t.Font = font or Theme.FONT_TITLE
	t.TextSize = size
	t.TextColor3 = Color3.new(1, 1, 1)
	t.AutomaticSize = Enum.AutomaticSize.X
	t.Size = UDim2.fromOffset(0, size + 4)
	t.Parent = parent
	local s = Instance.new("UIStroke")
	s.Color = Theme.OUTLINE or Color3.fromRGB(20, 16, 24)
	s.Thickness = size >= 18 and 2 or 1.4
	s.Parent = t
	return t, s
end

local function chip(parent, label, color)
	local c = Instance.new("TextLabel")
	c.BackgroundColor3 = color
	c.Font = Theme.FONT_TITLE
	c.TextSize = 11
	c.TextColor3 = Color3.new(1, 1, 1)
	c.Text = label
	c.AutomaticSize = Enum.AutomaticSize.X
	c.Size = UDim2.fromOffset(0, 16)
	c.Parent = parent
	Instance.new("UICorner", c).CornerRadius = UDim.new(0, 5)
	local p = Instance.new("UIPadding", c); p.PaddingLeft = UDim.new(0, 5); p.PaddingRight = UDim.new(0, 5)
	local s = Instance.new("UIStroke"); s.Color = Color3.fromRGB(20, 16, 24); s.Thickness = 1; s.ApplyStrokeMode = Enum.ApplyStrokeMode.Border; s.Parent = c
	return c
end

local function teamColor(team)
	local def = team and GameConfig.TEAMS[team]
	return def and def.rgb or nil
end

-- (re)draw a tag's contents from the model's / player's attributes
local function paint(tag)
	local model, plr = tag.model, tag.plr
	for _, c in ipairs(tag.row:GetChildren()) do if c:IsA("GuiObject") then c:Destroy() end end
	tag.fadeList = {}
	local function fades(obj, stroke) table.insert(tag.fadeList, {obj = obj, stroke = stroke}) end
	local name, title, color, gold = "", "", Color3.new(1, 1, 1), false
	local teamMode = (roundNode:GetAttribute("Teams") or 0) == 2
	local tc = teamMode and teamColor(model:GetAttribute("Team")) or nil
	if plr then
		name = plr.DisplayName
		local t = plr:GetAttribute("Title") or model:GetAttribute("Title") or ""
		title = FREE_TITLES[t] and "" or t
		local lvl = plr:GetAttribute("Level")
		if lvl then
			local lv = chip(tag.row, "Lv " .. tostring(lvl), Color3.fromRGB(46, 52, 74)); lv.LayoutOrder = 1
			fades(lv)
		end
		local role = ROLE[plr:GetAttribute("StaffRole") or ""]
		if role then
			local rc = chip(tag.row, role[1], role[2]); rc.LayoutOrder = 2
			fades(rc)
			color = role[2]
		end
		if plr:GetAttribute("PassHolder") then
			gold = true
			local crown, cs = text(tag.row, 18); crown.Text = "♛"; crown.TextColor3 = GOLD; crown.LayoutOrder = 3
			fades(crown, cs)
			if not role then color = GOLD end
		end
	else
		local hum = model:FindFirstChildOfClass("Humanoid")
		name = model:GetAttribute("TagName") or (hum and hum.DisplayName ~= "" and hum.DisplayName) or model.Name
		local rank = model:GetAttribute("BotSkill")
		title = rank and string.upper(rank) or ""
		color = RANK[rank or ""] or Color3.fromRGB(220, 220, 220)
		if model:GetAttribute("Boss") then gold = true; color = GOLD; title = "WARLORD" end
	end
	if tc then color = tc end
	local nm, ns = text(tag.row, 20); nm.Text = name; nm.TextColor3 = color; nm.LayoutOrder = 4
	fades(nm, ns)
	tag.gradient = nil
	if gold and not tc then
		-- the pass (or a boss): a slow shimmer runs along the name
		nm.TextColor3 = Color3.new(1, 1, 1)
		local g = Instance.new("UIGradient")
		g.Color = ColorSequence.new({ColorSequenceKeypoint.new(0, GOLD), ColorSequenceKeypoint.new(0.45, GOLD), ColorSequenceKeypoint.new(0.5, GOLD2),
			ColorSequenceKeypoint.new(0.55, GOLD), ColorSequenceKeypoint.new(1, GOLD)})
		g.Parent = nm
		tag.gradient = g
	end
	tag.titleLabel.Text = title
	tag.titleLabel.Visible = title ~= ""
	tag.titleLabel.TextColor3 = plr and TITLE_COL or Color3.fromRGB(200, 200, 210)
end

local function makeTag(model, plr)
	local head = model:FindFirstChild("Head")
	if not head then return end
	local bb = Instance.new("BillboardGui")
	bb.Name = "NameTag"
	bb.Size = UDim2.fromOffset(300, 46)
	bb.StudsOffsetWorldSpace = Vector3.new(0, 2.7, 0)
	bb.AlwaysOnTop = true
	bb.LightInfluence = 0
	bb.MaxDistance = RANGE + 5
	bb.ResetOnSpawn = false
	bb.Enabled = false
	bb.Adornee = head
	local list = Instance.new("UIListLayout", bb)
	list.HorizontalAlignment = Enum.HorizontalAlignment.Center
	list.SortOrder = Enum.SortOrder.LayoutOrder
	list.Padding = UDim.new(0, 0)
	local row = Instance.new("Frame")
	row.BackgroundTransparency = 1
	row.AutomaticSize = Enum.AutomaticSize.X
	row.Size = UDim2.fromOffset(0, 24)
	row.LayoutOrder = 1
	row.Parent = bb
	local rl = Instance.new("UIListLayout", row)
	rl.FillDirection = Enum.FillDirection.Horizontal
	rl.VerticalAlignment = Enum.VerticalAlignment.Center
	rl.SortOrder = Enum.SortOrder.LayoutOrder
	rl.Padding = UDim.new(0, 5)
	local tl, ts = text(bb, 13, Enum.Font.GothamMedium)
	tl.LayoutOrder = 2
	bb.Parent = pgui
	local tag = {model = model, plr = plr, bb = bb, row = row, titleLabel = tl, titleStroke = ts, alpha = 0, want = false, sightAt = 0, sight = false}
	tags[model] = tag
	paint(tag)
	-- what changes the look
	local conns = {}
	local function repaint() if tags[model] == tag then paint(tag) end end
	for _, a in ipairs({"Team", "Title", "Boss", "TagName"}) do table.insert(conns, model:GetAttributeChangedSignal(a):Connect(repaint)) end
	if plr then
		for _, a in ipairs({"Title", "Level", "PassHolder", "StaffRole"}) do table.insert(conns, plr:GetAttributeChangedSignal(a):Connect(repaint)) end
	end
	table.insert(conns, roundNode:GetAttributeChangedSignal("Teams"):Connect(repaint))
	tag.conns = conns
	return tag
end

local function dropTag(model)
	local tag = tags[model]
	if not tag then return end
	tags[model] = nil
	for _, c in ipairs(tag.conns or {}) do c:Disconnect() end
	tag.bb:Destroy()
end

-- who gets a tag: other players' characters, and bots
local function watchCharacter(plr, char)
	if plr == player then return end
	char:WaitForChild("Head", 10)
	if char.Parent then makeTag(char, plr) end
	char.AncestryChanged:Connect(function() if not char:IsDescendantOf(workspace) then dropTag(char) end end)
end
local function watchPlayer(plr)
	plr.CharacterAdded:Connect(function(c) task.spawn(watchCharacter, plr, c) end)
	if plr.Character then task.spawn(watchCharacter, plr, plr.Character) end
end
Players.PlayerAdded:Connect(watchPlayer)
for _, p in ipairs(Players:GetPlayers()) do watchPlayer(p) end
Players.PlayerRemoving:Connect(function(p) if p.Character then dropTag(p.Character) end end)

local function watchNpc(m)
	if not m:IsA("Model") then return end
	task.spawn(function()
		for _ = 1, 40 do
			if m:GetAttribute("Bot") and m:FindFirstChild("Head") then break end
			if not m.Parent then return end
			task.wait(0.1)
		end
		if m.Parent and m:GetAttribute("Bot") and not tags[m] then makeTag(m, nil) end
	end)
end
task.spawn(function()
	local npcs = workspace:WaitForChild("NPCs", 60)
	if not npcs then return end
	npcs.ChildAdded:Connect(watchNpc)
	npcs.ChildRemoved:Connect(dropTag)
	for _, m in ipairs(npcs:GetChildren()) do watchNpc(m) end
end)

--------------------------------------------------------------------
--  WHO SHOWS
--------------------------------------------------------------------
local sightRay = RaycastParams.new()
sightRay.FilterType = Enum.RaycastFilterType.Exclude

local function aimPoint(cam)
	if UserInputService.MouseBehavior == Enum.MouseBehavior.LockCenter then return cam.ViewportSize / 2 end
	return UserInputService:GetMouseLocation()
end

RunService.RenderStepped:Connect(function(dt)
	local cam = workspace.CurrentCamera
	if not cam then return end
	local camPos = cam.CFrame.Position
	local myChar = player.Character
	local myRoot = myChar and myChar:FindFirstChild("HumanoidRootPart")
	local from = myRoot and myRoot.Position or camPos
	local hub = roundNode:GetAttribute("Mode") == "Hub"
	local aim = aimPoint(cam)
	local tanHalf = math.tan(math.rad(cam.FieldOfView) / 2)
	local now = os.clock()
	for model, tag in pairs(tags) do
		local head = tag.bb.Adornee
		local hum = model:FindFirstChildOfClass("Humanoid")
		local want = false
		if head and head.Parent and hum and hum.Health > 0 and model.Parent then
			local dist = (head.Position - from).Magnitude
			if dist <= RANGE then
				want = dist <= NEAR or (hub and dist <= HUB_RANGE)
				if not want then
					-- the aim on their body: the body's own size on screen, plus a little slack
					local body = head.Position - Vector3.new(0, 1.2, 0)
					local sp, onScreen = cam:WorldToViewportPoint(body)
					if onScreen and sp.Z > 0 then
						local off = (Vector2.new(sp.X, sp.Y) - aim).Magnitude / cam.ViewportSize.Y
						local size = 2.8 / (2 * sp.Z * tanHalf)   -- half a body's height, as a share of the screen
						want = off <= size + AIM_BASE
					end
				end
				if want then
					-- a clear line of sight (checked a few times a second)
					if now - tag.sightAt > SIGHT_EVERY then
						tag.sightAt = now
						sightRay.FilterDescendantsInstances = {myChar, model, workspace:FindFirstChild("LocalFX")}
						local to = head.Position - camPos
						local hit = workspace:Raycast(camPos, to, sightRay)
						tag.sight = not hit or (hit.Instance and hit.Instance:FindFirstAncestorOfClass("Model") and hit.Instance:FindFirstAncestorOfClass("Model"):FindFirstChildOfClass("Humanoid") ~= nil)
					end
					want = tag.sight
				end
			end
		end
		-- fade
		local goal = want and 1 or 0
		if tag.alpha ~= goal then
			local step = dt / (want and FADE_IN or FADE_OUT)
			tag.alpha = goal > tag.alpha and math.min(goal, tag.alpha + step) or math.max(goal, tag.alpha - step)
			local tr = 1 - tag.alpha
			for _, f in ipairs(tag.fadeList or {}) do
				if f.obj:IsA("TextLabel") then
					f.obj.TextTransparency = tr
					if f.obj.BackgroundTransparency < 1 or f.obj:GetAttribute("Chip") then f.obj.BackgroundTransparency = tr; f.obj:SetAttribute("Chip", true) end
				end
				if f.stroke then f.stroke.Transparency = tr end
				local cs = f.obj:FindFirstChildOfClass("UIStroke")
				if cs and cs ~= f.stroke then cs.Transparency = tr end
			end
			tag.titleLabel.TextTransparency = tr
			tag.titleStroke.Transparency = tr
		end
		tag.bb.Enabled = tag.alpha > 0.01
		if tag.gradient and tag.bb.Enabled then
			-- the shimmer: a bright band sweeping along the name every two seconds
			tag.gradient.Offset = Vector2.new(((now * 0.5) % 2) - 1, 0)
		end
	end
end)
