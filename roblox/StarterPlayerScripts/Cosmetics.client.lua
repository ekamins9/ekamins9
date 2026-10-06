--[[ COSMETICS (client) — plays what the server relays and drives the emote wheel.
       FxEvent "Kill"       → ReplicatedStorage ▸ KillFX on the fallen body
       FxEvent "Emote"      → ReplicatedStorage ▸ Emotes on that player's character
       FxEvent "EmoteStop"
     The emote wheel: hold the Emote key (B by default, rebindable in
     SETTINGS), point the mouse at an emote and let go — or tap B and click
     one. (No number keys: 1 – 9 belong to the backpack's weapon slots.) Your
     equipped emotes come from your profile (player attribute "Emotes", set
     by the server). Attacking, blocking, kicking or dodging ends an emote;
     moving ends a whole-body one, while arms-only ones play on the move. ]]

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
		-- b = the refused emote's id (the server said no): ours stops only then
		local plr = a
		if typeof(plr) == "Instance" and plr.Character and (plr ~= player or (b ~= nil and Emotes.playing(plr.Character) == b)) then Emotes.stop(plr.Character) end
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

local hintGui = Instance.new("ScreenGui")
hintGui.Name = "EmoteHint"
hintGui.ResetOnSpawn = false
hintGui.IgnoreGuiInset = true
hintGui.DisplayOrder = 2101
hintGui.Parent = player.PlayerGui

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
sub.Text = "point and let go of B"
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

-- a short line under the wheel's spot ("stand still to bow")
local hint = Instance.new("TextLabel")
hint.BackgroundTransparency = 1
hint.AnchorPoint = Vector2.new(0.5, 0)
hint.Position = UDim2.new(0.5, 0, 0.62, 0)
hint.Size = UDim2.fromOffset(500, 30)
hint.Font = Theme.FONT_TITLE
hint.TextSize = 22
hint.TextColor3 = Color3.new(1, 1, 1)
hint.Visible = false
hint.Parent = hintGui
do local s = Instance.new("UIStroke", hint); s.Color = Theme.OUTLINE; s.Thickness = 2 end
local hintAt = 0
local function say(text)
	hint.Text = text
	hint.Visible = true
	hintAt = os.clock()
	task.delay(1.6, function() if os.clock() - hintAt >= 1.55 then hint.Visible = false end end)
end

-- walking (the keys) or being carried along (anything else that moves you)
local function isMoving(char)
	local hum = char:FindFirstChildOfClass("Humanoid")
	if hum and hum.MoveDirection.Magnitude > 0.1 then return true end
	local hrp = char:FindFirstChild("HumanoidRootPart")
	local v = hrp and hrp.AssemblyLinearVelocity
	return v ~= nil and v.X * v.X + v.Z * v.Z > 6
end

local startedAt = 0
local function playEmote(id)
	local char = alive()
	if not char or not id then return end
	if Emotes.busy(char) then say("Not mid-fight"); return end
	-- whole-body emotes need you standing still; arms-only ones play on the move
	if not Emotes.isUpper(id) and isMoving(char) then
		local e = Catalog.EMOTE[id]
		say("Stand still for " .. (e and e.name or id))
		return
	end
	if not Emotes.play(char, id) then return end
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

local openedAt, hover = 0, nil
local function close()
	open = false
	hover = nil
	gui.Enabled = false
end

local function build()
	for _, s in ipairs(slots) do s.button:Destroy() end
	slots = {}
	hover = nil
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
		local t = Instance.new("TextLabel")
		t.BackgroundTransparency = 1; t.Size = UDim2.new(1, -12, 0, 44); t.Position = UDim2.fromOffset(6, 32)
		t.Font = Theme.FONT_TITLE; t.TextSize = 18; t.TextWrapped = true; t.TextColor3 = Color3.new(1, 1, 1); t.Text = string.upper(e.name)
		t.Parent = b
		do local s = Instance.new("UIStroke", t); s.Color = Theme.OUTLINE; s.Thickness = 1.6 end
		local tag = Instance.new("TextLabel")
		tag.BackgroundTransparency = 1; tag.Size = UDim2.new(1, -12, 0, 14); tag.Position = UDim2.fromOffset(6, 80)
		tag.Font = Theme.FONT; tag.TextSize = 11; tag.TextColor3 = RARITY[e.rarity] or Theme.DIM
		tag.Text = Emotes.isUpper(id) and "ON THE MOVE" or "STAND STILL"
		tag.Parent = b
		local sc = Instance.new("UIScale", b)
		b.MouseButton1Click:Connect(function() close(); playEmote(id) end)
		table.insert(slots, {button = b, scale = sc, stroke = st, id = id, angle = ang, e = e})
	end
end

local function openWheel()
	if not alive() then return end
	local menu = player.PlayerGui:FindFirstChild("HubMenu")
	if menu and menu.Enabled then return end
	build()
	open = true
	openedAt = os.clock()
	hover = nil
	hub.Text = "EMOTES"; sub.Text = "point and let go of B"
	gui.Enabled = true
	wheelScale.Scale = 0.8
	TweenService:Create(wheelScale, TweenInfo.new(0.15, Enum.EasingStyle.Back), {Scale = 1}):Play()
end
-- the slot the mouse points at, from the wheel's middle (nil near the middle)
local function pointed()
	local centre = wheel.AbsolutePosition + wheel.AbsoluteSize / 2
	local m = UserInputService:GetMouseLocation() - Vector2.new(0, game:GetService("GuiService"):GetGuiInset().Y)
	local d = m - centre
	if d.Magnitude < 46 * wheelScale.Scale or #slots == 0 then return nil end
	local a = math.atan2(d.Y, d.X)
	local best, bestD = nil, math.huge
	for _, sl in ipairs(slots) do
		local diff = math.abs((a - sl.angle + math.pi) % (2 * math.pi) - math.pi)
		if diff < bestD then best, bestD = sl, diff end
	end
	return best
end
local function setHover(sl)
	if sl == hover then return end
	if hover then TweenService:Create(hover.scale, TweenInfo.new(0.08), {Scale = 1}):Play(); hover.stroke.Thickness = 3 end
	hover = sl
	if sl then
		TweenService:Create(sl.scale, TweenInfo.new(0.08), {Scale = 1.13}):Play(); sl.stroke.Thickness = 5
		hub.Text = string.upper(sl.e.name); sub.Text = sl.e.description or ""
	else
		hub.Text = "EMOTES"; sub.Text = "point and let go of B"
	end
end
shade.MouseButton1Click:Connect(close)

-- the binds that fight: pressing any of them ends an emote at once (the
-- server's Acting / Blocking flags end it for everyone a moment later)
local FIGHT = {Swing = true, Stab = true, Overhead = true, Underhand = true, Feint = true, Kick = true, Dodge = true, Jump = true, Pickup = true}
local function fightInput(input)
	if input.UserInputType == Enum.UserInputType.MouseButton2 then return true end   -- block
	local name = ClientSettings.inputName(input)
	if not name then return false end
	for _, k in ipairs(ClientSettings.KEYS) do
		if FIGHT[k.key] and ClientSettings.get("Key_" .. k.key) == name then return true end
	end
	return false
end

UserInputService.InputBegan:Connect(function(input, gp)
	if UserInputService:GetFocusedTextBox() then return end
	if input.UserInputType == Enum.UserInputType.Keyboard then
		if input.KeyCode == ClientSettings.key("Emote") and input.KeyCode ~= Enum.KeyCode.Unknown then
			-- tapped open already: B again plays what you point at, or closes
			if open then local sl = hover; close(); if sl then playEmote(sl.id) end else openWheel() end
			return
		end
		if open then
			if input.KeyCode == Enum.KeyCode.Escape then close() end
			return
		end
	end
	if not open and not gp and fightInput(input) and os.clock() - startedAt > 0.15 then stopEmote() end
end)
-- held open: letting go of B plays what you point at (a quick tap leaves the
-- wheel open for a click)
UserInputService.InputEnded:Connect(function(input)
	if not open or input.UserInputType ~= Enum.UserInputType.Keyboard then return end
	if input.KeyCode ~= ClientSettings.key("Emote") then return end
	if os.clock() - openedAt < 0.2 and not hover then return end
	local sl = hover
	close()
	if sl then playEmote(sl.id) end
end)
-- the scroll wheel stabs / overheads
UserInputService.InputChanged:Connect(function(input, gp)
	if not open and not gp and input.UserInputType == Enum.UserInputType.MouseWheel and fightInput(input) then stopEmote() end
end)
-- an attack or a kick asked for by any other route
local function watchCharacter(char)
	for _, attr in ipairs({"LocalAttackName", "LocalKickAt", "Acting", "Blocking"}) do
		char:GetAttributeChangedSignal(attr):Connect(function()
			if attr == "Acting" or attr == "Blocking" then if not char:GetAttribute(attr) then return end end
			if os.clock() - startedAt > 0.1 then stopEmote() end
		end)
	end
end
player.CharacterAdded:Connect(watchCharacter)
if player.Character then watchCharacter(player.Character) end

RunService.RenderStepped:Connect(function()
	if open then
		UserInputService.MouseBehavior = Enum.MouseBehavior.Default
		UserInputService.MouseIconEnabled = true
		setHover(pointed())
	end
	-- walking away ends a whole-body emote (after a beat, so a tap doesn't
	-- cancel it); arms-only emotes keep playing on the move
	local char = player.Character
	local id = char and Emotes.playing(char)
	if id and not Emotes.isUpper(id) and os.clock() - startedAt > 0.25 and isMoving(char) then stopEmote() end
end)
