--[[ LOADING — the very first thing a player sees (ReplicatedFirst runs before the rest
     of the game has arrived).

       • Arriving from another place (a trip from the Courtyard, training, a battle):
         the travel screen they left on (TeleportService's arriving GUI) stays up from
         the first frame; StarterPlayerScripts ▸ TravelScreen lets it go once there's
         something to see (_G.ArrivingTravelGui).
       • Joining fresh: the game's name over its key art (ReplicatedFirst ▸ KeyArt, a
         Studio-only StringValue holding the image; a dark field without it), embers, a
         sweeping bar and a line, until there's something to show — a newcomer's film (Intro:
         _G.IntroCinematic), the menu, the class screen or a body — then it fades.

     Roblox's own loading screen is let go of either way: never a blank black screen.
     (The name is written here, not read from GameConfig: nothing else has loaded yet.) ]]

local Players = game:GetService("Players")
local ReplicatedFirst = game:GetService("ReplicatedFirst")
local TeleportService = game:GetService("TeleportService")
local TweenService = game:GetService("TweenService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- ARRIVING: the travel screen carries on
local arriving
pcall(function() arriving = TeleportService:GetArrivingTeleportGui() end)
if arriving then
	_G.ArrivingTravelGui = arriving
	arriving.Parent = playerGui
	ReplicatedFirst:RemoveDefaultLoadingScreen()
	return
end

-- JOINING FRESH
local NAME, LINE = "STEEL & GLORY", "Every swing is yours to aim."
local GOLD, DIM = Color3.fromRGB(255, 206, 90), Color3.fromRGB(170, 180, 200)
local gui = Instance.new("ScreenGui")
gui.Name = "Loading"
gui.IgnoreGuiInset = true
gui.ResetOnSpawn = false
gui.DisplayOrder = 6000
gui.Parent = playerGui

local back = Instance.new("Frame")
back.BackgroundColor3 = Color3.new(1, 1, 1)
back.BorderSizePixel = 0
back.Size = UDim2.fromScale(1, 1)
back.Parent = gui
local grad = Instance.new("UIGradient", back)
grad.Rotation = 90
grad.Color = ColorSequence.new(Color3.fromRGB(26, 20, 34), Color3.fromRGB(6, 8, 14))
-- the key art behind it all, darkened round the middle so the name reads over it
task.spawn(function()
	-- (it may arrive a moment after this script starts; the screen doesn't wait for it)
	local art = ReplicatedFirst:FindFirstChild("KeyArt") or ReplicatedFirst:WaitForChild("KeyArt", 3)
	if art and art:IsA("StringValue") and art.Value ~= "" and back.Parent then
		local img = Instance.new("ImageLabel")
		img.Name = "KeyArt"
		img.BackgroundTransparency = 1
		img.Size = UDim2.fromScale(1, 1)
		img.Image = art.Value
		img.ScaleType = Enum.ScaleType.Crop
		img.ImageTransparency = 1
		img.ZIndex = 1   -- (this screen layers globally: the art over the backdrop, under the rest)
		img.Parent = back
		-- (faded in once it has loaded)
		task.spawn(function()
			local t0 = os.clock()
			while not img.IsLoaded and os.clock() - t0 < 6 do task.wait(0.1) end
			if img.Parent and back.BackgroundTransparency < 0.5 then TweenService:Create(img, TweenInfo.new(0.8), {ImageTransparency = 0.15}):Play() end
		end)
		local shade = Instance.new("Frame")
		shade.Name = "Shade"
		shade.BackgroundColor3 = Color3.new(0, 0, 0)
		shade.BorderSizePixel = 0
		shade.Size = UDim2.fromScale(1, 1)
		shade.ZIndex = 1
		shade.Parent = back
		local g = Instance.new("UIGradient", shade)
		g.Rotation = 90
		g.Transparency = NumberSequence.new({NumberSequenceKeypoint.new(0, 0.75), NumberSequenceKeypoint.new(0.45, 0.3),
			NumberSequenceKeypoint.new(0.6, 0.3), NumberSequenceKeypoint.new(1, 0.1)})
	end
end)

local function text(t, size, color, font, y)
	local l = Instance.new("TextLabel")
	l.BackgroundTransparency = 1
	l.AnchorPoint = Vector2.new(0.5, 0.5)
	l.Position = UDim2.fromScale(0.5, y)
	l.Size = UDim2.new(0.9, 0, 0, size + 16)
	l.Font = font
	l.TextSize = size
	l.TextColor3 = color
	l.Text = t
	l.TextScaled = false
	l.ZIndex = 3
	l.Parent = back
	local s = Instance.new("UIStroke", l)
	s.Color = Color3.fromRGB(20, 12, 4)
	s.Thickness = size > 40 and 4 or 1.5
	return l
end
local title = text(NAME, 76, GOLD, Enum.Font.FredokaOne, 0.44)
text(string.upper(LINE), 18, Color3.new(1, 1, 1), Enum.Font.GothamBold, 0.53)
local status = text("Loading the realm…", 14, DIM, Enum.Font.GothamBold, 0.68)
local titleScale = Instance.new("UIScale", title)
titleScale.Scale = 0.92
TweenService:Create(titleScale, TweenInfo.new(1.6, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true), {Scale = 1}):Play()

-- the sweeping bar
local track = Instance.new("Frame")
track.AnchorPoint = Vector2.new(0.5, 0.5)
track.Position = UDim2.fromScale(0.5, 0.62)
track.Size = UDim2.fromOffset(280, 6)
track.BackgroundColor3 = Color3.fromRGB(40, 40, 56)
track.BorderSizePixel = 0
track.ClipsDescendants = true
track.ZIndex = 3
track.Parent = back
Instance.new("UICorner", track).CornerRadius = UDim.new(1, 0)
local sweep = Instance.new("Frame")
sweep.Size = UDim2.fromScale(0.35, 1)
sweep.Position = UDim2.fromScale(-0.35, 0)
sweep.BackgroundColor3 = GOLD
sweep.BorderSizePixel = 0
sweep.ZIndex = 4
sweep.Parent = track
Instance.new("UICorner", sweep).CornerRadius = UDim.new(1, 0)
TweenService:Create(sweep, TweenInfo.new(1.1, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1), {Position = UDim2.fromScale(1, 0)}):Play()

-- embers drifting up
local rng = Random.new()
local alive = true
task.spawn(function()
	while alive do
		local e = Instance.new("Frame")
		local s = rng:NextInteger(3, 6)
		e.Size = UDim2.fromOffset(s, s)
		e.AnchorPoint = Vector2.new(0.5, 0.5)
		e.Position = UDim2.fromScale(rng:NextNumber(0.05, 0.95), 1.02)
		e.BackgroundColor3 = Color3.fromRGB(255, rng:NextInteger(120, 200), 60)
		e.BorderSizePixel = 0
		e.BackgroundTransparency = 0.2
		e.ZIndex = 2
		e.Parent = back
		Instance.new("UICorner", e).CornerRadius = UDim.new(1, 0)
		local dur = rng:NextNumber(4, 7)
		TweenService:Create(e, TweenInfo.new(dur, Enum.EasingStyle.Sine, Enum.EasingDirection.Out),
			{Position = UDim2.fromScale(e.Position.X.Scale + rng:NextNumber(-0.1, 0.1), rng:NextNumber(0.2, 0.6)), BackgroundTransparency = 1}):Play()
		task.delay(dur, function() e:Destroy() end)
		task.wait(rng:NextNumber(0.08, 0.2))
	end
end)

ReplicatedFirst:RemoveDefaultLoadingScreen()

-- until there's something to show
if not game:IsLoaded() then game.Loaded:Wait() end
status.Text = "Entering the Courtyard…"
local function ready()
	if _G.IntroCinematic then return true end
	local c = player.Character
	if c and c:FindFirstChild("HumanoidRootPart") then return true end
	for _, n in ipairs({"HubMenu", "LoadoutMenu"}) do
		local g = playerGui:FindFirstChild(n)
		if g and g:IsA("ScreenGui") and g.Enabled then return true end
	end
	return false
end
local t0 = os.clock()
while os.clock() - t0 < 20 and not ready() do task.wait(0.1) end
task.wait(0.3)

-- fade
for _, d in ipairs(back:GetDescendants()) do
	if d:IsA("TextLabel") then TweenService:Create(d, TweenInfo.new(0.5), {TextTransparency = 1}):Play()
	elseif d:IsA("UIStroke") then TweenService:Create(d, TweenInfo.new(0.5), {Transparency = 1}):Play()
	elseif d:IsA("Frame") then TweenService:Create(d, TweenInfo.new(0.5), {BackgroundTransparency = 1}):Play()
	elseif d:IsA("ImageLabel") then TweenService:Create(d, TweenInfo.new(0.5), {ImageTransparency = 1}):Play() end
end
TweenService:Create(back, TweenInfo.new(0.6), {BackgroundTransparency = 1}):Play()
task.wait(0.65)
alive = false
gui:Destroy()
