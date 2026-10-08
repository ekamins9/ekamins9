--[[ UI FX — the menus' sounds and juice (client only).

     SOUNDS below is the one place every menu sound lives: swap an id and it
     changes everywhere. Sounds play flat (no position), at the player's
     "Menu sounds" volume (ClientSettings ▸ UISounds); all are from Roblox's
     licensed libraries (Pro Sound Effects, APM Music) or Roblox's own.

       UIFX.play(name, opts)          a sound by name (opts: Volume, Speed)
       UIFX.reveal(rarity)            the stinger for a pull of that rarity
       UIFX.flash(gui, color, peak, dur)   a full-screen flash on a ScreenGui
       UIFX.banner(gui, text, color, big)  a word that punches in and fades
       UIFX.shake(guiObject, amp, dur)     shake a frame (big pulls)
       UIFX.ticker(name)              returns tick(index): plays when index changes
                                      (a spinning strip ticks per card) ]]

local SoundService = game:GetService("SoundService")
local TweenService = game:GetService("TweenService")
local RunService   = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local UIFX = {}

--   id, vol, speed (or {lo, hi}), cut = seconds before a quick fade-out
UIFX.SOUNDS = {
	Click    = {id = "rbxassetid://9114215212", vol = 0.32, speed = {1.35, 1.5}, cut = 0.09},   -- a hard button press
	Hover    = {id = "rbxasset://sounds/volume_slider.ogg", vol = 0.18, speed = {1.5, 1.7}},     -- a soft tick
	Back     = {id = "rbxassetid://9114215389", vol = 0.28, speed = {1.0, 1.1}, cut = 0.09},
	Error    = {id = "rbxasset://sounds/volume_slider.ogg", vol = 0.5, speed = 0.55},
	Tick     = {id = "rbxasset://sounds/volume_slider.ogg", vol = 0.55, speed = {1.15, 1.25}},  -- a crate card passing the marker
	DrumRoll = {id = "rbxassetid://9042819052", vol = 0.45},                                     -- snare roll under the spin
	Coins    = {id = "rbxassetid://9113849583", vol = 0.45, cut = 1.4},
	EggCrack = {id = "rbxassetid://9119577515", vol = 0.9, speed = {1.05, 1.25}, cut = 0.3},    -- crisp snaps
	EggBurst = {id = "rbxassetid://9120968196", vol = 0.9, speed = {1.1, 1.2}, cut = 0.55},
	Shells   = {id = "rbxassetid://9114863539", vol = 0.35, speed = {1.2, 1.3}, cut = 1.0},     -- bits scattering
	Unsheath = {id = "rbxassetid://9119742466", vol = 0.55},
	Whoosh   = {id = "rbxassetid://9120709477", vol = 0.4, speed = {1.1, 1.25}},
}
-- the reveal, by rarity: bigger pulls, bigger brass
UIFX.REVEAL = {
	Common    = {id = "rbxassetid://9042819908", vol = 0.45, cut = 1.2},     -- a drum-kit hit
	Uncommon  = {id = "rbxassetid://9042819908", vol = 0.5, cut = 1.2},
	Rare      = {id = "rbxassetid://1835324771", vol = 0.55, cut = 2.6},     -- Battleforce sting
	Epic      = {id = "rbxassetid://1840296036", vol = 0.6, cut = 3.2},      -- brass flourish
	Legendary = {id = "rbxassetid://1835295052", vol = 0.65, cut = 4.2},     -- Forging the Army sting
	Mythic    = {id = "rbxassetid://83315768373322", vol = 0.7, cut = 6},    -- Conquering Heroes
	Unique    = {id = "rbxassetid://83315768373322", vol = 0.85, cut = 9},   -- (the same, longer: there is only one)
}
UIFX.BIG = {Legendary = true, Mythic = true, Unique = true}

local settings = nil
local function volume()
	if settings == nil then
		local ok, m = pcall(function() return require(ReplicatedStorage:WaitForChild("ClientSettings", 2)) end)
		settings = ok and m or false
	end
	local v = settings and settings.get("UISounds")
	return type(v) == "number" and v or 1
end

local function playSpec(spec, opts)
	if not spec or not spec.id then return nil end
	opts = opts or {}
	local vol = (opts.Volume or spec.vol or 0.5) * volume()
	if vol <= 0.001 then return nil end
	local s = Instance.new("Sound")
	s.SoundId = spec.id
	s.Volume = vol
	local sp = opts.Speed or spec.speed or 1
	if type(sp) == "table" then sp = sp[1] + math.random() * (sp[2] - sp[1]) end
	s.PlaybackSpeed = sp
	s.Parent = SoundService
	s:Play()
	local cut = opts.Cut or spec.cut
	if cut then
		task.delay(cut / sp, function()
			if s.Parent then
				TweenService:Create(s, TweenInfo.new(0.12), {Volume = 0}):Play()
				task.delay(0.14, function() s:Destroy() end)
			end
		end)
	else
		s.Ended:Once(function() s:Destroy() end)
		task.delay(12, function() if s.Parent then s:Destroy() end end)
	end
	return s
end

function UIFX.play(name, opts) return playSpec(UIFX.SOUNDS[name], opts) end
function UIFX.reveal(rarity) return playSpec(UIFX.REVEAL[rarity] or UIFX.REVEAL.Common) end

-- the ScreenGui an object sits in (for a flash over everything)
local function screenOf(obj)
	return obj and (obj:IsA("ScreenGui") and obj or obj:FindFirstAncestorOfClass("ScreenGui")) or nil
end

function UIFX.flash(gui, color, peak, dur)
	local sg = screenOf(gui)
	if not sg then return end
	local f = Instance.new("Frame")
	f.Name = "_Flash"
	f.BackgroundColor3 = color or Color3.new(1, 1, 1)
	f.BackgroundTransparency = 1 - (peak or 0.6)
	f.BorderSizePixel = 0
	f.Size = UDim2.fromScale(1, 1)
	f.ZIndex = 1000
	f.Parent = sg
	TweenService:Create(f, TweenInfo.new(dur or 0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {BackgroundTransparency = 1}):Play()
	task.delay((dur or 0.5) + 0.05, function() f:Destroy() end)
end

-- a big word that punches in (overshoot), holds, then floats up and fades
function UIFX.banner(gui, text, color, big)
	local sg = screenOf(gui)
	if not sg then return end
	local t = Instance.new("TextLabel")
	t.Name = "_Banner"
	t.BackgroundTransparency = 1
	t.AnchorPoint = Vector2.new(0.5, 0.5)
	t.Position = UDim2.fromScale(0.5, 0.36)
	t.Size = UDim2.fromScale(0.9, big and 0.2 or 0.13)
	t.Font = Enum.Font.GothamBlack
	t.TextScaled = true
	t.Text = text
	t.TextColor3 = color or Color3.new(1, 1, 1)
	t.ZIndex = 1001
	t.Parent = sg
	local s = Instance.new("UIStroke"); s.Thickness = big and 5 or 3; s.Color = Color3.fromRGB(20, 16, 24); s.Parent = t
	local sc = Instance.new("UIScale"); sc.Scale = 2.4; sc.Parent = t
	t.TextTransparency = 1
	TweenService:Create(sc, TweenInfo.new(0.32, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {Scale = 1}):Play()
	TweenService:Create(t, TweenInfo.new(0.16), {TextTransparency = 0}):Play()
	task.delay(big and 1.5 or 0.9, function()
		if not t.Parent then return end
		TweenService:Create(t, TweenInfo.new(0.45, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {Position = UDim2.fromScale(0.5, 0.3), TextTransparency = 1}):Play()
		TweenService:Create(s, TweenInfo.new(0.45), {Transparency = 1}):Play()
		task.delay(0.5, function() t:Destroy() end)
	end)
end

function UIFX.shake(obj, amp, dur)
	if not obj or not obj:IsA("GuiObject") then return end
	local base = obj.Position
	local t0 = os.clock()
	local conn
	conn = RunService.RenderStepped:Connect(function()
		local a = os.clock() - t0
		if a >= (dur or 0.4) or not obj.Parent then conn:Disconnect(); obj.Position = base; return end
		local k = (1 - a / (dur or 0.4)) * (amp or 8)
		obj.Position = base + UDim2.fromOffset((math.random() * 2 - 1) * k, (math.random() * 2 - 1) * k)
	end)
end

function UIFX.ticker(name)
	local last = nil
	return function(index, speed)
		if index ~= last then
			last = index
			UIFX.play(name or "Tick", speed and {Speed = speed} or nil)
		end
	end
end

return UIFX
