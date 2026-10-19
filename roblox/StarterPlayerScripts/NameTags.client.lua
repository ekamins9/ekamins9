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
       their arms    a little shield of their own coat of arms beside it (player attribute Arms,
                     "emblem|metal|field": Profile.publishArms; Catalog ▸ Arms)
     Characters of the map (the training yard's teachers, the Courtyard's bard) get one
     too: any Model in workspace ▸ Map with a TagName attribute (TagTitle under it).
     Player attributes come from Hub ▸ Pastimes (Title, Level, PassHolder) and
     Admin ▸ AdminServer (StaffRole). ]]

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Theme = require(ReplicatedStorage:WaitForChild("Theme"))
local GameConfig = require(ReplicatedStorage:WaitForChild("GameConfig"))
local InputHints = require(ReplicatedStorage:WaitForChild("InputHints"))
local Catalog = require(ReplicatedStorage:WaitForChild("Catalog"))

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
	-- (a fill bot in guise is drawn as a player is, from its own attributes: Game ▸ Guise)
	local src = plr or (model:GetAttribute("Guise") and model) or nil
	if src then
		name = plr and plr.DisplayName or (model:GetAttribute("TagName") or model.Name)
		local t = src:GetAttribute("Title") or model:GetAttribute("Title") or ""
		title = FREE_TITLES[t] and "" or t
		local lvl = src:GetAttribute("Level")
		if lvl then
			local lv = chip(tag.row, "Lv " .. tostring(lvl), Color3.fromRGB(46, 52, 74)); lv.LayoutOrder = 1
			fades(lv)
		end
		-- their own coat of arms, a little shield (Catalog ▸ Arms; the pictures in ShieldArt)
		local arms = src:GetAttribute("Arms")
		if type(arms) == "string" then
			local emblem, metalId, fieldName = string.match(arms, "^([^|]+)|([^|]*)|(.*)$")
			local A = Catalog.ARMS
			local art = ReplicatedStorage:FindFirstChild("ShieldArt")
			if emblem and A and art and art:FindFirstChild(emblem) then
				local metal = A.METAL[metalId] or A.METALS[1]
				local field = Catalog.COLOR[fieldName or ""]
				local badge = Instance.new("Frame")
				badge.BackgroundColor3 = field and field.color or Color3.fromRGB(56, 60, 78)
				badge.Size = UDim2.fromOffset(18, 21)
				badge.LayoutOrder = 1
				Instance.new("UICorner", badge).CornerRadius = UDim.new(0, 5)
				local bs = Instance.new("UIStroke"); bs.Color = Color3.fromRGB(20, 16, 24); bs.Thickness = 1; bs.ApplyStrokeMode = Enum.ApplyStrokeMode.Border; bs.Parent = badge
				for z, layer in ipairs({{emblem .. "_o", metal.edge}, {emblem, metal.color}}) do
					local v = art:FindFirstChild(layer[1])
					if v then
						local il = Instance.new("ImageLabel")
						il.BackgroundTransparency = 1
						il.Size = UDim2.new(1, -2, 1, -2); il.Position = UDim2.fromOffset(1, 1)
						il.ScaleType = Enum.ScaleType.Fit
						il.Image = v.Value; il.ImageColor3 = layer[2]; il.ZIndex = z
						il.Parent = badge
					end
				end
				badge.Parent = tag.row
				fades(badge)
			end
		end
		local role = plr and ROLE[plr:GetAttribute("StaffRole") or ""]
		if role then
			local rc = chip(tag.row, role[1], role[2]); rc.LayoutOrder = 2
			fades(rc)
			color = role[2]
		end
		if plr and plr:GetAttribute("PassHolder") then
			gold = true
			local crown, cs = text(tag.row, 18); crown.Text = "👑"; crown.TextColor3 = GOLD; crown.LayoutOrder = 3
			fades(crown, cs)
			if not role then color = GOLD end
		end
	else
		local hum = model:FindFirstChildOfClass("Humanoid")
		name = model:GetAttribute("TagName") or (hum and hum.DisplayName ~= "" and hum.DisplayName) or model.Name
		local rank = model:GetAttribute("BotSkill")
		title = rank and string.upper(rank) or ""
		color = RANK[rank or ""] or Color3.fromRGB(220, 220, 220)
		-- (a character of the map: a teacher, the bard; gold, what they do under the name)
		if model:GetAttribute("TagTitle") then title = model:GetAttribute("TagTitle"); color = GOLD end
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
	tag.titleLabel.TextColor3 = (src or model:GetAttribute("TagTitle")) and TITLE_COL or Color3.fromRGB(200, 200, 210)
end

local function makeTag(model, plr)
	local head = model:FindFirstChild("Head")
	if not head then return end
	local bb = Instance.new("BillboardGui")
	bb.Name = "NameTag"
	bb.Size = UDim2.fromOffset(300, 62)
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
	-- (a player you're looking straight at: the key that opens their profile)
	local hl, hs
	if plr then
		hl, hs = text(bb, 11, Theme.FONT_TITLE)
		hl.LayoutOrder = 3
		hl.TextColor3 = Color3.fromRGB(150, 200, 255)
		hl.TextTransparency, hs.Transparency = 1, 1
	end
	bb.Parent = pgui
	local tag = {model = model, plr = plr, bb = bb, row = row, titleLabel = tl, titleStroke = ts, hintLabel = hl, hintStroke = hs, hint = 0,
		alpha = 0, want = false, sightAt = 0, sight = false}
	tags[model] = tag
	paint(tag)
	-- what changes the look
	local conns = {}
	local function repaint() if tags[model] == tag then paint(tag) end end
	for _, a in ipairs({"Team", "Title", "Boss", "TagName", "Guise", "Level", "Arms"}) do table.insert(conns, model:GetAttributeChangedSignal(a):Connect(repaint)) end
	if plr then
		for _, a in ipairs({"Title", "Level", "PassHolder", "StaffRole", "Arms"}) do table.insert(conns, plr:GetAttributeChangedSignal(a):Connect(repaint)) end
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
-- the map's characters (a TagName on a Model in workspace ▸ Map), whichever map is up
local function watchMap(map)
	if not (map:IsA("Model") or map:IsA("Folder")) or map.Name ~= "Map" then return end
	local function maybe(m)
		if m:IsA("Model") and m:GetAttribute("TagName") and not tags[m] then
			task.spawn(function()
				m:WaitForChild("Head", 5)
				if m.Parent and not tags[m] then
					makeTag(m, nil)
					-- (gone with its map, however it goes)
					local c; c = m.AncestryChanged:Connect(function()
						if not m:IsDescendantOf(workspace) then c:Disconnect(); dropTag(m) end
					end)
				end
			end)
		end
	end
	map.ChildAdded:Connect(maybe)
	map.ChildRemoved:Connect(dropTag)
	for _, m in ipairs(map:GetChildren()) do maybe(m) end
end
workspace.ChildAdded:Connect(watchMap)
for _, c in ipairs(workspace:GetChildren()) do watchMap(c) end
task.spawn(function()
	local npcs = workspace:WaitForChild("NPCs", 60)
	if not npcs then return end
	npcs.ChildAdded:Connect(watchNpc)
	-- (a map's character starts out here and moves onto the map: its tag stays)
	npcs.ChildRemoved:Connect(function(m)
		if not (m:GetAttribute("TagName") and m:IsDescendantOf(workspace)) then dropTag(m) end
	end)
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
	-- the player in the middle of the screen (what the Profile key opens): their tag says so
	local centre = cam.ViewportSize / 2
	local pointed, pointedOff = nil, math.huge
	for model, tag in pairs(tags) do
		local head = tag.bb.Adornee
		local hum = model:FindFirstChildOfClass("Humanoid")
		local want = false
		-- (filming a showcase: no names over anyone, they'd give the bots away)
		if not _G.ShowcaseActive and head and head.Parent and hum and hum.Health > 0 and model.Parent then
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
		-- (the profile hint: a player whose tag shows, nearest the middle of the screen)
		if want and tag.plr and tag.hintLabel then
			local sp, onScreen = cam:WorldToViewportPoint(head.Position - Vector3.new(0, 1.2, 0))
			if onScreen and sp.Z > 0 then
				local off = (Vector2.new(sp.X, sp.Y) - centre).Magnitude / cam.ViewportSize.Y
				local size = 2.8 / (2 * sp.Z * tanHalf)
				if off <= size + AIM_BASE and off < pointedOff then pointed, pointedOff = tag, off end
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
				elseif f.obj:IsA("Frame") then
					-- (the arms badge: its field and its pictures)
					f.obj.BackgroundTransparency = tr
					for _, im in ipairs(f.obj:GetChildren()) do if im:IsA("ImageLabel") then im.ImageTransparency = tr end end
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
	-- the profile hint on the one you're looking at (a keyboard: a controller or a touch
	-- screen opens profiles from the menu)
	local keyboard = InputHints.mode() == "Keyboard"
	for _, tag in pairs(tags) do
		if tag.hintLabel then
			local goal = (keyboard and tag == pointed) and math.min(tag.alpha, 1) or 0
			if tag.hint ~= goal then
				tag.hint = goal > tag.hint and math.min(goal, tag.hint + dt / 0.2) or math.max(goal, tag.hint - dt / 0.2)
				if goal > 0 then tag.hintLabel.Text = string.format("[%s]  PROFILE", InputHints.name("Profile")) end
				tag.hintLabel.TextTransparency = 1 - tag.hint * 0.9
				tag.hintStroke.Transparency = 1 - tag.hint * 0.8
			end
		end
	end
end)
