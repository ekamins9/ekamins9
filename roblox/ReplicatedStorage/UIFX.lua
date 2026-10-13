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
                                      (a spinning strip ticks per card)

     THE LOOK OF FIRE (the intro's embers, everywhere a moment deserves them):
       UIFX.embers(frame, opts) -> stop()   embers drifting up through a frame while it's on
                                      screen (opts: colors = palette name or {Color3}, rate =
                                      seconds between, size = {min, max} px, life = {min, max}
                                      s, top = {min, max} end height, z, alpha)
       UIFX.sparks(frame, at, opts)   a burst of sparks flying out from `at` (Vector2, the
                                      frame's scale; opts: n, colors, radius px, z, scale)
       UIFX.vignette(parent, color, k, z) -> holder   the edges darkened (four soft gradients;
                                      tween the holder's children's BackgroundTransparency)
       UIFX.camShake(secs, strength)  the camera shudders, falling off (degrees)
       UIFX.fadeOut(root, dur, destroy)    everything under it fades (frames, text, strokes)
       UIFX.PALETTES                  fire · gold · ash · blood · frost · holy ]]

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
	Thud     = {id = "rbxassetid://9046338796", vol = 0.6, speed = {0.62, 0.7}, cut = 0.5},            -- a crate landing
	Boom     = {id = "rbxassetid://1835337001", vol = 0.5, speed = {1.05, 1.15}, cut = 1.6},           -- a lid flung open
	-- the big moments of a fight
	Fallen   = {id = "rbxassetid://1835337001", vol = 0.55, speed = 0.62, cut = 2.6},                  -- a low boom: you fell
	Rise     = {id = "rbxassetid://9119742466", vol = 0.5, speed = {0.95, 1.05}},                      -- a blade drawn: back on your feet
	Horn     = {id = "rbxassetid://9114821239", vol = 0.4, speed = 0.78, cut = 3.2},                   -- a war horn: the round begins
	LevelUp  = {id = "rbxassetid://1840296036", vol = 0.55, cut = 3.2},                                -- a brass flourish
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

--------------------------------------------------------------------
--  THE LOOK OF FIRE
--------------------------------------------------------------------
UIFX.PALETTES = {
	fire  = {Color3.fromRGB(255, 120, 40), Color3.fromRGB(255, 160, 60), Color3.fromRGB(255, 205, 100)},
	gold  = {Color3.fromRGB(255, 206, 90), Color3.fromRGB(255, 236, 170), Color3.fromRGB(255, 176, 60)},
	ash   = {Color3.fromRGB(170, 158, 150), Color3.fromRGB(120, 110, 106), Color3.fromRGB(210, 120, 80)},
	blood = {Color3.fromRGB(210, 44, 40), Color3.fromRGB(255, 96, 64), Color3.fromRGB(150, 22, 26)},
	frost = {Color3.fromRGB(170, 220, 255), Color3.fromRGB(230, 246, 255), Color3.fromRGB(120, 190, 255)},
	holy  = {Color3.fromRGB(255, 244, 200), Color3.fromRGB(255, 220, 130), Color3.fromRGB(255, 255, 255)},
}
local rng = Random.new()
local function colorsOf(c) return type(c) == "table" and c or UIFX.PALETTES[c or "fire"] or UIFX.PALETTES.fire end
-- on screen? (every frame above it visible, its ScreenGui on): nothing is spawned for a hidden one
local function shown(obj)
	local o = obj
	while o and not o:IsA("LayerCollector") do
		if o:IsA("GuiObject") and not o.Visible then return false end
		o = o.Parent
	end
	return o ~= nil and o.Enabled
end
UIFX.shown = shown

function UIFX.embers(parent, o)
	o = o or {}
	local cols = colorsOf(o.colors)
	local alive = true
	task.spawn(function()
		while alive and parent.Parent do
			if shown(parent) then
				local e = Instance.new("Frame")
				local sz = rng:NextInteger(o.size and o.size[1] or 3, o.size and o.size[2] or 7)
				e.Size = UDim2.fromOffset(sz, sz)
				e.AnchorPoint = Vector2.new(0.5, 0.5)
				local x = rng:NextNumber(0.03, 0.97)
				e.Position = UDim2.fromScale(x, o.from or 1.02)
				e.BackgroundColor3 = cols[rng:NextInteger(1, #cols)]
				e.BackgroundTransparency = o.alpha or 0.15
				e.BorderSizePixel = 0
				e.ZIndex = o.z or 1
				Instance.new("UICorner", e).CornerRadius = UDim.new(1, 0)
				e.Parent = parent
				local dur = rng:NextNumber(o.life and o.life[1] or 4, o.life and o.life[2] or 7)
				local top = rng:NextNumber(o.top and o.top[1] or 0.15, o.top and o.top[2] or 0.55)
				TweenService:Create(e, TweenInfo.new(dur, Enum.EasingStyle.Sine, Enum.EasingDirection.Out),
					{Position = UDim2.fromScale(x + rng:NextNumber(-0.1, 0.1), top), BackgroundTransparency = 1}):Play()
				task.delay(dur, function() e:Destroy() end)
			end
			local r = o.rate or 0.12
			task.wait(rng:NextNumber(r * 0.6, r * 1.4))
		end
	end)
	return function() alive = false end
end

function UIFX.sparks(parent, at, o)
	o = o or {}
	if not (parent and parent.Parent) then return end
	local cols = colorsOf(o.colors)
	local n = o.n or 18
	local k = o.scale or 1
	for i = 1, n do
		local s = Instance.new("Frame")
		local len = rng:NextInteger(10, 22) * k
		s.Size = UDim2.fromOffset(len, math.max(2, math.floor(len / 5)))
		s.AnchorPoint = Vector2.new(0.5, 0.5)
		s.Position = UDim2.fromScale(at.X, at.Y)
		local a = (i / n) * math.pi * 2 + rng:NextNumber(-0.25, 0.25)
		s.Rotation = math.deg(a)
		s.BackgroundColor3 = cols[rng:NextInteger(1, #cols)]
		s.BorderSizePixel = 0
		s.ZIndex = o.z or 50
		Instance.new("UICorner", s).CornerRadius = UDim.new(1, 0)
		s.Parent = parent
		local dist = rng:NextNumber(0.55, 1) * (o.radius or 220)
		local dur = rng:NextNumber(0.45, 0.85)
		TweenService:Create(s, TweenInfo.new(dur, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
			Position = UDim2.new(at.X, math.cos(a) * dist, at.Y, math.sin(a) * dist),
			Size = UDim2.fromOffset(3, 3), BackgroundTransparency = 1}):Play()
		task.delay(dur + 0.05, function() s:Destroy() end)
	end
end

function UIFX.vignette(parent, color, k, z)
	local holder = Instance.new("Frame")
	holder.Name = "_Vignette"
	holder.BackgroundTransparency = 1
	holder.Size = UDim2.fromScale(1, 1)
	holder.ZIndex = z or 1
	holder.Parent = parent
	local edge = 1 - (k or 0.8)
	for _, d in ipairs({{UDim2.fromScale(0, 0), UDim2.fromScale(1, 0.34), 90}, {UDim2.fromScale(0, 0.66), UDim2.fromScale(1, 0.34), 270},
		{UDim2.fromScale(0, 0), UDim2.fromScale(0.3, 1), 0}, {UDim2.fromScale(0.7, 0), UDim2.fromScale(0.3, 1), 180}}) do
		local f = Instance.new("Frame")
		f.Position, f.Size = d[1], d[2]
		f.BackgroundColor3 = color or Color3.new(0, 0, 0)
		f.BackgroundTransparency = 1
		f.BorderSizePixel = 0
		f.ZIndex = z or 1
		local g = Instance.new("UIGradient")
		g.Rotation = d[3]
		g.Transparency = NumberSequence.new(edge, 1)
		g.Parent = f
		f.Parent = holder
	end
	return holder
end

local shakeN = 0
function UIFX.camShake(secs, strength)
	shakeN += 1
	local name = "UIFXShake" .. shakeN
	local t0 = os.clock()
	RunService:BindToRenderStep(name, Enum.RenderPriority.Camera.Value + 5, function()
		local cam = workspace.CurrentCamera
		local a = os.clock() - t0
		if a >= secs or not cam then RunService:UnbindFromRenderStep(name); return end
		local k = (1 - a / secs) * (strength or 1)
		cam.CFrame = cam.CFrame * CFrame.Angles(math.rad((math.random() - 0.5) * k), math.rad((math.random() - 0.5) * k), 0)
	end)
end

function UIFX.fadeOut(root, dur, destroyAfter)
	if not root then return end
	local info = TweenInfo.new(dur or 0.5)
	local function fade(d)
		if d:IsA("GuiObject") then
			local props = {}
			if d.BackgroundTransparency < 1 then props.BackgroundTransparency = 1 end
			if d:IsA("TextLabel") or d:IsA("TextButton") or d:IsA("TextBox") then props.TextTransparency = 1; props.TextStrokeTransparency = 1 end
			if d:IsA("ImageLabel") or d:IsA("ImageButton") then props.ImageTransparency = 1 end
			if next(props) then TweenService:Create(d, info, props):Play() end
		elseif d:IsA("UIStroke") then
			TweenService:Create(d, info, {Transparency = 1}):Play()
		end
	end
	fade(root)
	for _, d in ipairs(root:GetDescendants()) do fade(d) end
	if destroyAfter then task.delay((dur or 0.5) + 0.05, function() root:Destroy() end) end
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
