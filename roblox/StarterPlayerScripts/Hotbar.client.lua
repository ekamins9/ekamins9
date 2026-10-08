--[[ HOTBAR — our own weapon bar in place of Roblox's backpack bar. A slot per
     weapon you carry (your primary 1, your sidearm 2: LoadoutServer's Slot
     attribute; anything you pick up after them), each a little 3D picture of
     the weapon itself in its skin, edged in the skin's rarity colour, with its
     key and its name; a bow or a crossbow in hand shows the arrows / bolts left.
     The one in your hands lifts, glows and turns slowly.
     1–9 (or a click / a tap) takes one out; the same key again puts it away. A
     gamepad's D-pad steps through them. Hidden while you're dead, in a menu, or
     travelling. ]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local StarterGui = game:GetService("StarterGui")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")

local Catalog = require(ReplicatedStorage:WaitForChild("Catalog"))
local Theme = require(ReplicatedStorage:WaitForChild("Theme"))

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local SLOT_W, SLOT_H, GAP = 82, 74, 10
local RARITY = {Common = Color3.fromRGB(150, 160, 175), Rare = Color3.fromRGB(56, 140, 255), Epic = Color3.fromRGB(170, 80, 240),
	Legendary = Color3.fromRGB(255, 176, 40), Mythic = Color3.fromRGB(255, 52, 78), Unique = Color3.fromRGB(255, 236, 190)}
local KEYS = {Enum.KeyCode.One, Enum.KeyCode.Two, Enum.KeyCode.Three, Enum.KeyCode.Four, Enum.KeyCode.Five,
	Enum.KeyCode.Six, Enum.KeyCode.Seven, Enum.KeyCode.Eight, Enum.KeyCode.Nine}
local WHITE = Color3.new(1, 1, 1)

-- Roblox's own bar goes (it can refuse until the core scripts are up: keep asking)
task.spawn(function()
	for _ = 1, 20 do
		if pcall(StarterGui.SetCoreGuiEnabled, StarterGui, Enum.CoreGuiType.Backpack, false) then break end
		task.wait(0.5)
	end
end)

--------------------------------------------------------------------
--  THE BAR
--------------------------------------------------------------------
local gui = Instance.new("ScreenGui")
gui.Name = "Hotbar"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = true
gui.DisplayOrder = 11
gui.Parent = playerGui

local bar = Instance.new("Frame")
bar.Name = "Bar"
bar.AnchorPoint = Vector2.new(0.5, 1)
bar.Position = UDim2.new(0.5, 0, 1, -12)
bar.Size = UDim2.fromOffset(0, SLOT_H)
bar.AutomaticSize = Enum.AutomaticSize.X
bar.BackgroundTransparency = 1
bar.Parent = gui
do
	local l = Instance.new("UIListLayout", bar)
	l.FillDirection = Enum.FillDirection.Horizontal
	l.HorizontalAlignment = Enum.HorizontalAlignment.Center
	l.VerticalAlignment = Enum.VerticalAlignment.Bottom
	l.Padding = UDim.new(0, GAP)
	l.SortOrder = Enum.SortOrder.LayoutOrder
end

local function textLabel(parent, text, size, color, font)
	local t = Instance.new("TextLabel")
	t.BackgroundTransparency = 1
	t.Font = font or Theme.FONT_TITLE
	t.TextSize = size
	t.TextColor3 = color or WHITE
	t.Text = text or ""
	t.Parent = parent
	local st = Instance.new("UIStroke"); st.Color = Theme.OUTLINE; st.Thickness = size >= 16 and 2 or 1.4; st.Parent = t
	return t
end

-- a little 3D picture of the weapon itself (its skin, its trim): a still copy in a ViewportFrame
local STRIP = {Script = true, LocalScript = true, ModuleScript = true, Sound = true, ParticleEmitter = true, Trail = true,
	PointLight = true, SpotLight = true, Beam = true, Fire = true, Smoke = true, Sparkles = true, ProximityPrompt = true}
local function weaponPicture(holder, tool)
	for _, c in ipairs(holder:GetChildren()) do if c:IsA("ViewportFrame") then c:Destroy() end end
	local vp = Instance.new("ViewportFrame")
	vp.BackgroundTransparency = 1
	vp.Size = UDim2.fromScale(1, 1)
	vp.Ambient = Color3.fromRGB(160, 154, 146)
	vp.LightColor = Color3.fromRGB(255, 244, 228)
	vp.LightDirection = Vector3.new(-0.5, -1, 0.6)
	vp.Parent = holder
	local world = Instance.new("WorldModel"); world.Parent = vp
	local cam = Instance.new("Camera"); cam.Parent = vp
	vp.CurrentCamera = cam
	local ok, copy = pcall(function()
		local was = tool.Archivable
		tool.Archivable = true
		local c = tool:Clone()
		tool.Archivable = was
		return c
	end)
	if not ok or not copy then return vp end
	local m = Instance.new("Model")
	for _, d in ipairs(copy:GetDescendants()) do
		if STRIP[d.ClassName] then d:Destroy() end
	end
	for _, d in ipairs(copy:GetChildren()) do d.Parent = m end
	copy:Destroy()
	for _, d in ipairs(m:GetDescendants()) do
		if d:IsA("BasePart") then d.Anchored = true; d.CanCollide = false end
	end
	m.Parent = world
	local okB, cf, sz = pcall(m.GetBoundingBox, m)
	if not okB then return vp end
	-- the longest side across the slot, tipped a little
	local axis = (sz.X >= sz.Y and sz.X >= sz.Z) and Vector3.xAxis or (sz.Y >= sz.Z and Vector3.yAxis or Vector3.zAxis)
	local longest = math.max(sz.X, sz.Y, sz.Z, 0.5)
	local along = cf:VectorToWorldSpace(axis)
	local up = math.abs(along.Y) < 0.9 and Vector3.yAxis or Vector3.zAxis
	local vy = (up - along * up:Dot(along)).Unit
	local box = CFrame.fromMatrix(cf.Position, along, vy)
	m:PivotTo(CFrame.Angles(0, 0, math.rad(-32)) * box:Inverse() * m:GetPivot())
	local dist = (longest * 0.47) / math.tan(math.rad(15))
	cam.FieldOfView = 30
	cam.CFrame = CFrame.lookAt(Vector3.new(0, dist * 0.2, -dist), Vector3.zero)
	vp:SetAttribute("Dist", dist)
	return vp
end

local function displayName(tool)
	local cfgM = tool:FindFirstChild("Config")
	local ok, cfg = pcall(function() return cfgM and require(cfgM) end)
	return (ok and type(cfg) == "table" and cfg.Name) or tool.Name
end
local function rarityOf(tool)
	local s = Catalog.SKIN[tool:GetAttribute("SkinId") or ""]
	return s and s.name ~= "Default" and s.rarity or nil
end

--------------------------------------------------------------------
--  THE SLOTS: one per tool, kept in order (the primary 1, the sidearm 2, pickups after)
--------------------------------------------------------------------
local slots = {}          -- [tool] = {card, stroke, scale, vp, ...}
local order = {}          -- tools, in the bar's order
local seenAt, seq = {}, 0

local function character() return player.Character end
local function humanoid() local c = character(); return c and c:FindFirstChildOfClass("Humanoid") end

local function toggle(tool)
	local hum, c = humanoid(), character()
	if not (hum and c and hum.Health > 0 and tool and tool.Parent) then return end
	if tool.Parent == c then hum:UnequipTools() else hum:EquipTool(tool) end
end

local function makeSlot(tool)
	local card = Instance.new("TextButton")
	card.Name = "Slot"
	card.Text = ""
	card.AutoButtonColor = false
	card.Size = UDim2.fromOffset(SLOT_W, SLOT_H)
	card.BackgroundColor3 = Color3.fromRGB(12, 16, 28)
	card.BackgroundTransparency = 0.18
	card.Parent = bar
	Instance.new("UICorner", card).CornerRadius = UDim.new(0, 14)
	local grad = Instance.new("UIGradient", card)
	grad.Rotation = 90
	grad.Color = ColorSequence.new(Color3.fromRGB(70, 80, 110), Color3.fromRGB(20, 24, 40))
	local stroke = Instance.new("UIStroke", card)
	stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	stroke.Thickness = 2
	local scale = Instance.new("UIScale", card)
	local pic = Instance.new("Frame")
	pic.BackgroundTransparency = 1
	pic.Position = UDim2.fromOffset(4, 2)
	pic.Size = UDim2.new(1, -8, 1, -20)
	pic.Parent = card
	local key = textLabel(card, "", 13, WHITE)
	key.BackgroundTransparency = 0.1
	key.BackgroundColor3 = Color3.fromRGB(8, 10, 20)
	key.Position = UDim2.fromOffset(-6, -6)
	key.Size = UDim2.fromOffset(22, 22)
	key.ZIndex = 3
	Instance.new("UICorner", key).CornerRadius = UDim.new(1, 0)
	local name = textLabel(card, displayName(tool), 12, WHITE)
	name.AnchorPoint = Vector2.new(0.5, 1)
	name.Position = UDim2.new(0.5, 0, 1, -3)
	name.Size = UDim2.new(1, -8, 0, 14)
	name.TextTruncate = Enum.TextTruncate.AtEnd
	local ammo = textLabel(card, "", 13, Color3.fromRGB(255, 214, 90))
	ammo.AnchorPoint = Vector2.new(1, 0)
	ammo.Position = UDim2.new(1, -6, 0, 3)
	ammo.Size = UDim2.fromOffset(40, 16)
	ammo.TextXAlignment = Enum.TextXAlignment.Right
	ammo.ZIndex = 3
	local s = {card = card, stroke = stroke, scale = scale, pic = pic, key = key, name = name, ammo = ammo, out = nil, spin = 0}
	s.vp = weaponPicture(pic, tool)
	card.Activated:Connect(function() toggle(tool) end)
	card.MouseEnter:Connect(function() if not s.out then TweenService:Create(scale, TweenInfo.new(0.1), {Scale = 1.05}):Play() end end)
	card.MouseLeave:Connect(function() if not s.out then TweenService:Create(scale, TweenInfo.new(0.1), {Scale = 1}):Play() end end)
	-- a new skin on it (the Courtyard re-dresses): a new picture
	tool:GetAttributeChangedSignal("SkinId"):Connect(function() if slots[tool] then s.vp = weaponPicture(pic, tool) end end)
	return s
end

local function paint(tool, s, out)
	local col = RARITY[rarityOf(tool) or ""] or Color3.fromRGB(200, 210, 230)
	s.stroke.Color = out and Color3.fromRGB(255, 214, 90) or col
	s.stroke.Transparency = out and 0 or (rarityOf(tool) and 0.15 or 0.7)
	s.stroke.Thickness = out and 3 or 2
	if s.out == out then return end
	s.out = out
	TweenService:Create(s.card, TweenInfo.new(0.15, Enum.EasingStyle.Back), {BackgroundTransparency = out and 0.02 or 0.18}):Play()
	TweenService:Create(s.scale, TweenInfo.new(0.15, Enum.EasingStyle.Back), {Scale = out and 1.12 or 1}):Play()
	s.name.TextColor3 = out and Color3.fromRGB(255, 226, 120) or WHITE
end

local function collect()
	local list = {}
	local c = character()
	for _, holder in ipairs({c, player:FindFirstChildOfClass("Backpack")}) do
		for _, t in ipairs(holder and holder:GetChildren() or {}) do
			if t:IsA("Tool") then
				if not seenAt[t] then seq += 1; seenAt[t] = seq end
				table.insert(list, t)
			end
		end
	end
	table.sort(list, function(a, b)
		local sa, sb = a:GetAttribute("Slot") or 100, b:GetAttribute("Slot") or 100
		if sa ~= sb then return sa < sb end
		return seenAt[a] < seenAt[b]
	end)
	return list
end

local function rebuild()
	local list = collect()
	local keep = {}
	for _, t in ipairs(list) do keep[t] = true end
	for t, s in pairs(slots) do if not keep[t] then s.card:Destroy(); slots[t] = nil; seenAt[t] = nil end end
	order = list
	for i, t in ipairs(list) do
		local s = slots[t] or makeSlot(t)
		slots[t] = s
		s.card.LayoutOrder = i
		s.key.Text = i <= #KEYS and tostring(i) or ""
	end
end

local pending = false
local function soon()
	if pending then return end
	pending = true
	task.defer(function() pending = false; rebuild() end)
end
local conns = {}
local function watch(holder)
	if not holder then return end
	table.insert(conns, holder.ChildAdded:Connect(function(t) if t:IsA("Tool") then soon() end end))
	table.insert(conns, holder.ChildRemoved:Connect(function(t) if t:IsA("Tool") then soon() end end))
end
local function onCharacter(c)
	for _, cn in ipairs(conns) do cn:Disconnect() end
	conns = {}
	watch(c)
	watch(player:WaitForChild("Backpack", 10))
	soon()
end
if player.Character then task.spawn(onCharacter, player.Character) end
player.CharacterAdded:Connect(onCharacter)

--------------------------------------------------------------------
--  KEYS: 1–9 take one out (the same again puts it away); the D-pad steps through
--------------------------------------------------------------------
UserInputService.InputBegan:Connect(function(input, gp)
	if UserInputService:GetFocusedTextBox() then return end
	for i, k in ipairs(KEYS) do
		if input.KeyCode == k then
			if order[i] then toggle(order[i]) end
			return
		end
	end
	if input.KeyCode == Enum.KeyCode.DPadRight or input.KeyCode == Enum.KeyCode.DPadLeft then
		if #order == 0 then return end
		local c = character()
		local at = 0
		for i, t in ipairs(order) do if c and t.Parent == c then at = i end end
		local step = input.KeyCode == Enum.KeyCode.DPadRight and 1 or -1
		local nextI = ((at - 1 + step) % #order) + 1
		if at == 0 then nextI = step == 1 and 1 or #order end
		toggle(order[nextI])
	end
end)

--------------------------------------------------------------------
--  EVERY FRAME: which is out, the ammo, the turning, whether the bar shows at all
--------------------------------------------------------------------
local function menuUp()
	for _, n in ipairs({"HubMenu", "LoadoutMenu", "TravelScreen", "Intro"}) do
		local g = playerGui:FindFirstChild(n)
		if g and g:IsA("ScreenGui") and g.Enabled then return true end
	end
	return false
end
RunService.RenderStepped:Connect(function(dt)
	local c = character()
	local hum = humanoid()
	local show = hum ~= nil and hum.Health > 0 and #order > 0 and not menuUp()
	gui.Enabled = show
	if not show then return end
	for _, t in ipairs(order) do
		local s = slots[t]
		if s then
			local out = t.Parent == c
			paint(t, s, out)
			-- a bow or a crossbow in hand: what's left in the quiver
			s.ammo.Text = (out and t:GetAttribute("Ranged")) and tostring(c:GetAttribute("Ammo") or "") or ""
			-- the one in your hands turns slowly
			local vp = s.vp
			local cam = vp and vp.CurrentCamera
			if cam and vp:GetAttribute("Dist") then
				s.spin = out and (s.spin + dt * 0.9) or (s.spin * (1 - math.min(dt * 6, 1)))
				local d = vp:GetAttribute("Dist")
				cam.CFrame = CFrame.lookAt(Vector3.new(math.sin(s.spin) * d, d * 0.2, -math.cos(s.spin) * d), Vector3.zero)
			end
		end
	end
end)
