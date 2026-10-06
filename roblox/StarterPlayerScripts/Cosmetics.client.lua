--[[ COSMETICS (client) — plays what the server relays and drives the emote wheel.
       FxEvent "Kill"       → ReplicatedStorage ▸ KillFX on the fallen body
       FxEvent "Emote"      → ReplicatedStorage ▸ Emotes on that player's character
       FxEvent "EmoteStop"
     The emote wheel: the Emote key (B by default, rebindable in SETTINGS)
     opens it; click an emote or press its number. Your equipped emotes come
     from your profile (player attribute "Emotes", set by the server); moving
     or attacking ends an emote. ]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

local KillFX = require(ReplicatedStorage:WaitForChild("KillFX"))
local Emotes = require(ReplicatedStorage:WaitForChild("Emotes"))
local Catalog = require(ReplicatedStorage:WaitForChild("Catalog"))
local ClientSettings = require(ReplicatedStorage:WaitForChild("ClientSettings"))
local Theme = require(ReplicatedStorage:WaitForChild("Theme"))

local player = Players.LocalPlayer
local fx = ReplicatedStorage:WaitForChild("FxEvent")
local emoteRemote = ReplicatedStorage:WaitForChild("EmoteRemote")

--------------------------------------------------------------------
--  KILL EFFECTS
--------------------------------------------------------------------
local fxFolder = Instance.new("Folder")
fxFolder.Name = "LocalFX"
fxFolder.Parent = workspace

local function bodyParts(char)
	local out = {}
	for _, d in ipairs(char:GetDescendants()) do
		if (d:IsA("BasePart") and d.Name ~= "HumanoidRootPart") or d:IsA("Decal") then table.insert(out, d) end
	end
	return out
end

fx.OnClientEvent:Connect(function(what, a, b, c)
	if what == "Kill" then
		local char = b
		if typeof(char) ~= "Instance" or not char.Parent then return end
		local torso = char:FindFirstChild("Torso") or char:FindFirstChild("HumanoidRootPart")
		if not torso then return end
		KillFX.play(a, fxFolder, torso.CFrame, {body = bodyParts(char), world = true})
	elseif what == "Emote" then
		local plr, id, startedAt = a, b, c
		if typeof(plr) ~= "Instance" or not plr.Character then return end
		-- our own emote already started the moment we pressed it
		if plr == player and Emotes.playing(plr.Character) == id then return end
		Emotes.play(plr.Character, id, startedAt)
	elseif what == "EmoteStop" then
		local plr = a
		if typeof(plr) == "Instance" and plr.Character and plr ~= player then Emotes.stop(plr.Character) end
	end
end)

--------------------------------------------------------------------
--  THE EMOTE WHEEL
--------------------------------------------------------------------
local gui = Instance.new("ScreenGui")
gui.Name = "EmoteWheel"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = true
gui.DisplayOrder = 2100
gui.Enabled = false
gui.Parent = player:WaitForChild("PlayerGui")

local RARITY = {Common = Color3.fromRGB(120, 134, 152), Rare = Color3.fromRGB(56, 140, 255), Epic = Color3.fromRGB(170, 80, 240), Legendary = Color3.fromRGB(255, 176, 40)}

local shade = Instance.new("TextButton")
shade.Text = ""
shade.AutoButtonColor = false
shade.BackgroundColor3 = Theme.BACK
shade.BackgroundTransparency = 0.55
shade.Size = UDim2.fromScale(1, 1)
shade.Parent = gui

local wheel = Instance.new("Frame")
wheel.AnchorPoint = Vector2.new(0.5, 0.5)
wheel.Position = UDim2.fromScale(0.5, 0.5)
wheel.Size = UDim2.fromOffset(460, 460)
wheel.BackgroundColor3 = Theme.GLASS
wheel.BackgroundTransparency = 0.15
wheel.Parent = gui
Instance.new("UICorner", wheel).CornerRadius = UDim.new(1, 0)
do local s = Instance.new("UIStroke", wheel); s.Color = Color3.new(1, 1, 1); s.Transparency = 0.8; s.Thickness = 2 end
local wheelScale = Instance.new("UIScale", wheel)

local hub = Instance.new("TextLabel")
hub.BackgroundTransparency = 1
hub.AnchorPoint = Vector2.new(0.5, 0.5)
hub.Position = UDim2.fromScale(0.5, 0.5)
hub.Size = UDim2.fromOffset(160, 60)
hub.Font = Theme.FONT_TITLE
hub.TextSize = 24
hub.TextColor3 = Color3.new(1, 1, 1)
hub.Text = "EMOTES"
hub.Parent = wheel
do local s = Instance.new("UIStroke", hub); s.Color = Theme.OUTLINE; s.Thickness = 2 end
local sub = Instance.new("TextLabel")
sub.BackgroundTransparency = 1
sub.AnchorPoint = Vector2.new(0.5, 0)
sub.Position = UDim2.new(0.5, 0, 0.5, 18)
sub.Size = UDim2.fromOffset(200, 18)
sub.Font = Theme.FONT
sub.TextSize = 12
sub.TextColor3 = Theme.DIM
sub.Text = "click or press 1 – 6"
sub.Parent = wheel

local slots = {}
local current = {}
local open = false

local function equipped()
	local s = player:GetAttribute("Emotes")
	local list = {}
	if type(s) == "string" then for id in s:gmatch("[^,]+") do if Catalog.EMOTE[id] then table.insert(list, id) end end end
	if #list == 0 then for _, e in ipairs(Catalog.EMOTES) do if e.free then table.insert(list, e.id) end end end
	return list
end

local function alive()
	local c = player.Character
	local h = c and c:FindFirstChildOfClass("Humanoid")
	return h and h.Health > 0 and c or nil
end

local startedAt = 0
local function playEmote(id)
	local char = alive()
	if not char or not id then return end
	Emotes.play(char, id)
	startedAt = os.clock()
	emoteRemote:FireServer("Play", id)
end
local function stopEmote()
	local char = player.Character
	if char and Emotes.playing(char) then
		Emotes.stop(char)
		emoteRemote:FireServer("Stop")
	end
end

local function close()
	open = false
	gui.Enabled = false
end

local function build()
	for _, s in ipairs(slots) do s:Destroy() end
	slots = {}
	current = equipped()
	local n = math.max(#current, 1)
	for i, id in ipairs(current) do
		local e = Catalog.EMOTE[id]
		local ang = (i - 1) / n * math.pi * 2 - math.pi / 2
		local b = Instance.new("TextButton")
		b.AnchorPoint = Vector2.new(0.5, 0.5)
		b.Position = UDim2.new(0.5, math.cos(ang) * 158, 0.5, math.sin(ang) * 158)
		b.Size = UDim2.fromOffset(124, 124)
		b.BackgroundColor3 = Theme.GLASS2
		b.AutoButtonColor = false
		b.Text = ""
		b.Parent = wheel
		Instance.new("UICorner", b).CornerRadius = UDim.new(1, 0)
		local st = Instance.new("UIStroke", b); st.Color = RARITY[e.rarity] or Color3.new(1, 1, 1); st.Thickness = 3; st.Transparency = 0.2
		local num = Instance.new("TextLabel")
		num.BackgroundTransparency = 1; num.Size = UDim2.new(1, 0, 0, 30); num.Position = UDim2.fromOffset(0, 18)
		num.Font = Theme.FONT_TITLE; num.TextSize = 26; num.TextColor3 = RARITY[e.rarity] or Theme.ACCENT; num.Text = tostring(i)
		num.Parent = b
		do local s = Instance.new("UIStroke", num); s.Color = Theme.OUTLINE; s.Thickness = 2 end
		local t = Instance.new("TextLabel")
		t.BackgroundTransparency = 1; t.Size = UDim2.new(1, -12, 0, 40); t.Position = UDim2.fromOffset(6, 52)
		t.Font = Theme.FONT_TITLE; t.TextSize = 17; t.TextWrapped = true; t.TextColor3 = Color3.new(1, 1, 1); t.Text = string.upper(e.name)
		t.Parent = b
		do local s = Instance.new("UIStroke", t); s.Color = Theme.OUTLINE; s.Thickness = 1.6 end
		local sc = Instance.new("UIScale", b)
		b.MouseEnter:Connect(function() TweenService:Create(sc, TweenInfo.new(0.1), {Scale = 1.1}):Play(); hub.Text = string.upper(e.name); sub.Text = e.description or "" end)
		b.MouseLeave:Connect(function() TweenService:Create(sc, TweenInfo.new(0.1), {Scale = 1}):Play(); hub.Text = "EMOTES"; sub.Text = "click or press 1 – 6" end)
		b.Activated:Connect(function() close(); playEmote(id) end)
		table.insert(slots, b)
	end
end

local function toggle()
	if open then close(); return end
	if not alive() then return end
	local menu = player.PlayerGui:FindFirstChild("HubMenu")
	if menu and menu.Enabled then return end
	build()
	open = true
	gui.Enabled = true
	wheelScale.Scale = 0.8
	TweenService:Create(wheelScale, TweenInfo.new(0.15, Enum.EasingStyle.Back), {Scale = 1}):Play()
end
shade.Activated:Connect(close)

UserInputService.InputBegan:Connect(function(input, gp)
	if UserInputService:GetFocusedTextBox() then return end
	if input.UserInputType == Enum.UserInputType.Keyboard then
		if input.KeyCode == ClientSettings.key("Emote") and input.KeyCode ~= Enum.KeyCode.Unknown then toggle(); return end
		if open then
			local n = ({[Enum.KeyCode.One] = 1, [Enum.KeyCode.Two] = 2, [Enum.KeyCode.Three] = 3, [Enum.KeyCode.Four] = 4, [Enum.KeyCode.Five] = 5, [Enum.KeyCode.Six] = 6})[input.KeyCode]
			if n and current[n] then close(); playEmote(current[n]) end
			if input.KeyCode == Enum.KeyCode.Escape then close() end
		end
	end
	-- attacking ends an emote
	if not open and not gp and input.UserInputType == Enum.UserInputType.MouseButton1 and os.clock() - startedAt > 0.2 then stopEmote() end
end)

RunService.RenderStepped:Connect(function()
	if open then
		UserInputService.MouseBehavior = Enum.MouseBehavior.Default
		UserInputService.MouseIconEnabled = true
	end
	-- walking away ends an emote (after a beat, so a tap doesn't cancel it)
	local char = player.Character
	if char and Emotes.playing(char) and os.clock() - startedAt > 0.25 then
		local hum = char:FindFirstChildOfClass("Humanoid")
		if hum and hum.MoveDirection.Magnitude > 0.1 then stopEmote() end
	end
end)
