--[[ POWERS (client) — the third slot on your screen and everyone's powers in the world.

     YOU: the Power key (ClientSettings Key_Power, E; a controller's D-pad ↑ tap; the ✦ button
     on a phone) asks Combat ▸ Powers to use what's in your third slot, aimed where your
     crosshair is. The orb right of your energy bar shows it: its symbol, its cooldown
     wiping down, the seconds left, a throwable's charges. A class level-up gets a banner.
     THROW YOUR OWN STEEL (Key_Hurl, Y; a controller's D-pad → held; on a phone its orb, held):
     the same aim as a throwable, and away goes your shield off your arm, or once that's gone
     the one-hander in your hand (Combat ▸ Hurl); a third orb shows what would go.

     EVERYONE (from the character attributes Combat ▸ Powers / Shields / Throwing publish):
       the gesture as a power winds up or goes off, and a throw's fling (ReplicatedStorage ▸
       PowerPoses) · an imbue's flames (or frost, venom, light…) on the weapon in hand, flaring
       up as it catches · a buff's aura · an ultimate's shockwave · a stealthy character fades
       (yours to a ghost, theirs nearly gone) · a familiar at the shoulder · a shield raised in
       front while they block (ShieldGrip IdleC0 / BlockC0) · and from PowerFX / ThrowFX:
       circles on the ground (fire, frost, smoke, a dome, a gravity well, a rain of arrows),
       dashes, slams, decoys, an imbued blow's burst where it lands (Strike: fire, frost, a
       gust, venom, a pillar of light; a draining blow's life flowing back), and every thrown
       thing in flight. Colours come from the power's look and its skin (MagicFX.lookOf).
       What's been done to a body (burning, frozen, poisoned, rooted, dazed, shocked) is
       StatusFX's. ]]

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local Debris = game:GetService("Debris")

local Catalog = require(ReplicatedStorage:WaitForChild("Catalog"))
local Spells = require(ReplicatedStorage:WaitForChild("MagicSpells"))
local MagicFX = require(ReplicatedStorage:WaitForChild("MagicFX"))
local ClientSettings = require(ReplicatedStorage:WaitForChild("ClientSettings"))
local TouchInput = require(ReplicatedStorage:WaitForChild("TouchInput"))
local Theme = require(ReplicatedStorage:WaitForChild("Theme"))
local Dresser = require(ReplicatedStorage:WaitForChild("Dresser"))
local PowerPoses = require(ReplicatedStorage:WaitForChild("PowerPoses"))
local Ballistics = require(ReplicatedStorage:WaitForChild("Ballistics"))
local PowerAuras = require(ReplicatedStorage:WaitForChild("PowerAuras"))

local player = Players.LocalPlayer
local remote = ReplicatedStorage:WaitForChild("PowerRemote", 60)
local round = ReplicatedStorage:WaitForChild("Round")
local WHITE = Color3.new(1, 1, 1)
local TEX = {spark = "rbxasset://textures/particles/sparkles_main.dds", fire = "rbxasset://textures/particles/fire_main.dds", smoke = "rbxasset://textures/particles/smoke_main.dds"}
local SND = {cast = 9125899162, boom = 1835337001, whoosh = 9120709477, zap2 = 9116275998, ice = 9119577515, shing = 9119742466, thud = 9046338796}
local function snow() return workspace:GetServerTimeNow() end

local fxFolder = workspace:FindFirstChild("PowerFX")
if not fxFolder then fxFolder = Instance.new("Folder"); fxFolder.Name = "PowerFX"; fxFolder.Parent = workspace end

-- a power's colours (its own, or its skin's)
local function look(spellId, skin)
	local L = MagicFX.lookOf(spellId, skin)
	return L.color or WHITE, L.glow or WHITE, L
end
-- element colours for things without a power's look (a throwable's burst)
local ELEMENT = {
	fire = {Color3.fromRGB(255, 120, 40), Color3.fromRGB(255, 220, 140)}, frost = {Color3.fromRGB(150, 220, 255), WHITE},
	smoke = {Color3.fromRGB(90, 90, 96), Color3.fromRGB(160, 160, 166)}, ground = {Color3.fromRGB(90, 80, 70), Color3.fromRGB(160, 150, 130)},
	holy = {Color3.fromRGB(255, 220, 120), WHITE}, venom = {Color3.fromRGB(120, 220, 80), Color3.fromRGB(210, 255, 170)},
}

local function part(props)
	local p = Instance.new("Part")
	p.Anchored, p.CanCollide, p.CanQuery, p.CanTouch, p.CastShadow = true, false, false, false, false
	p.TopSurface, p.BottomSurface = Enum.SurfaceType.Smooth, Enum.SurfaceType.Smooth
	for k, v in pairs(props) do p[k] = v end
	p.Parent = props.Parent or fxFolder
	return p
end
local function sound(id, at, vol, speed)
	local holder = at
	if typeof(at) == "Vector3" then
		holder = Instance.new("Attachment"); holder.WorldPosition = at; holder.Parent = workspace.Terrain
		Debris:AddItem(holder, 4)
	end
	local snd = Instance.new("Sound"); snd.SoundId = "rbxassetid://" .. id; snd.Volume = vol or 0.5; snd.PlaybackSpeed = speed or 1
	snd.RollOffMaxDistance = 100; snd.Parent = holder; snd:Play()
	Debris:AddItem(snd, 4)
end
local function emitter(parent, c1, c2, o)
	o = o or {}
	local e = Instance.new("ParticleEmitter")
	e.Texture = o.texture or TEX.spark
	e.Color = ColorSequence.new(c1, c2 or c1)
	e.LightEmission = o.light or 0.8
	e.Size = NumberSequence.new({NumberSequenceKeypoint.new(0, o.size or 0.4), NumberSequenceKeypoint.new(1, 0)})
	e.Transparency = NumberSequence.new({NumberSequenceKeypoint.new(0, o.alpha or 0.15), NumberSequenceKeypoint.new(1, 1)})
	e.Lifetime = NumberRange.new(o.life or 0.5, (o.life or 0.5) * 1.6)
	local sp = o.speed or 2
	e.Speed = NumberRange.new(math.min(sp, sp * 1.8), math.max(sp, sp * 1.8))   -- (an inward swirl: a negative speed)
	e.SpreadAngle = Vector2.new(o.spread or 180, o.spread or 180)
	e.Rate = o.rate or 30
	e.Acceleration = o.accel or Vector3.zero
	e.RotSpeed = NumberRange.new(-90, 90)
	if o.shape then e.Shape = o.shape end
	if o.box then e.Shape = Enum.ParticleEmitterShape.Box end
	e.Parent = parent
	return e
end

--------------------------------------------------------------------
--  THE ORBS: your POWER (E) and your THROWABLE (C), side by side right of the energy bar
--------------------------------------------------------------------
local gui = Instance.new("ScreenGui")
gui.Name = "PowerHUD"
gui.ResetOnSpawn = false
gui.DisplayOrder = 11
gui.IgnoreGuiInset = false
gui.Parent = player:WaitForChild("PlayerGui")

local function makeOrb()
	local o = {pipList = {}, deniedUntil = 0}
	local orb = Instance.new("Frame")
	orb.AnchorPoint = Vector2.new(0, 1)
	orb.Position = UDim2.new(0.5, 352, 1, -96)
	orb.Size = UDim2.fromOffset(64, 64)
	orb.BackgroundColor3 = Color3.fromRGB(18, 20, 30)
	orb.BackgroundTransparency = 0.2
	orb.Visible = false
	orb.Parent = gui
	Instance.new("UICorner", orb).CornerRadius = UDim.new(1, 0)
	o.frame = orb
	o.ring = Instance.new("UIStroke", orb); o.ring.Thickness = 3; o.ring.Color = Theme.ACCENT
	o.glyph = Instance.new("TextLabel")
	o.glyph.BackgroundTransparency = 1; o.glyph.Size = UDim2.fromScale(1, 1); o.glyph.Font = Theme.FONT_TITLE; o.glyph.TextSize = 30
	o.glyph.TextColor3 = WHITE; o.glyph.Text = "✨"; o.glyph.ZIndex = 2
	o.glyph.Parent = orb
	o.wipe = Instance.new("Frame")
	o.wipe.AnchorPoint = Vector2.new(0, 1); o.wipe.Position = UDim2.fromScale(0, 1); o.wipe.Size = UDim2.fromScale(1, 0)
	o.wipe.BackgroundColor3 = Color3.new(0, 0, 0); o.wipe.BackgroundTransparency = 0.35; o.wipe.BorderSizePixel = 0; o.wipe.ZIndex = 3
	o.wipe.Parent = orb
	Instance.new("UICorner", o.wipe).CornerRadius = UDim.new(1, 0)
	o.secs = Instance.new("TextLabel")
	o.secs.BackgroundTransparency = 1; o.secs.Size = UDim2.fromScale(1, 1); o.secs.Font = Theme.FONT_TITLE; o.secs.TextSize = 24
	o.secs.TextColor3 = WHITE; o.secs.TextStrokeTransparency = 0.3; o.secs.ZIndex = 4; o.secs.Text = ""
	o.secs.Parent = orb
	o.keyTag = Instance.new("TextLabel")
	o.keyTag.AnchorPoint = Vector2.new(0.5, 0.5); o.keyTag.Position = UDim2.new(1, -6, 1, -6); o.keyTag.Size = UDim2.fromOffset(24, 20)
	o.keyTag.BackgroundColor3 = Color3.fromRGB(30, 34, 50); o.keyTag.Font = Theme.FONT_TITLE; o.keyTag.TextSize = 13; o.keyTag.TextColor3 = WHITE; o.keyTag.ZIndex = 5
	o.keyTag.Parent = orb
	Instance.new("UICorner", o.keyTag).CornerRadius = UDim.new(0, 5)
	o.nameTag = Instance.new("TextLabel")
	o.nameTag.AnchorPoint = Vector2.new(0.5, 0); o.nameTag.Position = UDim2.new(0.5, 0, 1, 2); o.nameTag.Size = UDim2.fromOffset(74, 16)
	o.nameTag.BackgroundTransparency = 1; o.nameTag.Font = Theme.FONT; o.nameTag.TextSize = 12; o.nameTag.TextColor3 = Color3.fromRGB(220, 220, 230)
	o.nameTag.TextStrokeTransparency = 0.4; o.nameTag.Parent = orb
	-- (two orbs side by side: a long name shrinks to its own orb's width)
	o.nameTag.TextScaled = true
	do local k = Instance.new("UITextSizeConstraint"); k.MaxTextSize = 12; k.MinTextSize = 7; k.Parent = o.nameTag end
	o.pips = Instance.new("Frame")
	o.pips.AnchorPoint = Vector2.new(0.5, 1); o.pips.Position = UDim2.new(0.5, 0, 0, -3); o.pips.Size = UDim2.fromOffset(60, 8); o.pips.BackgroundTransparency = 1
	o.pips.Parent = orb
	do local l = Instance.new("UIListLayout", o.pips); l.FillDirection = Enum.FillDirection.Horizontal; l.HorizontalAlignment = Enum.HorizontalAlignment.Center; l.Padding = UDim.new(0, 4) end
	-- (on a phone the orb itself is the button)
	o.tap = Instance.new("TextButton")
	o.tap.BackgroundTransparency = 1; o.tap.Size = UDim2.fromScale(1, 1); o.tap.Text = ""; o.tap.ZIndex = 6
	o.tap.Parent = orb
	return o
end
local powerOrb, throwOrb, hurlOrb = makeOrb(), makeOrb(), makeOrb()
local function setPips(o, n, col)
	if #o.pipList ~= n then
		for _, p in ipairs(o.pipList) do p:Destroy() end
		o.pipList = {}
		for i = 1, n do
			local p = Instance.new("Frame"); p.Size = UDim2.fromOffset(8, 8); p.BorderSizePixel = 0; p.LayoutOrder = i; p.Parent = o.pips
			Instance.new("UICorner", p).CornerRadius = UDim.new(1, 0)
			table.insert(o.pipList, p)
		end
	end
	if col then for _, p in ipairs(o.pipList) do p.BackgroundColor3 = col end end
end
local function punch(o)
	local s = o.frame:FindFirstChildOfClass("UIScale") or Instance.new("UIScale", o.frame)
	s.Scale = 0.85
	TweenService:Create(s, TweenInfo.new(0.2, Enum.EasingStyle.Back), {Scale = 1}):Play()
end
local function deny(o, why)
	if not why or why == "" then return end
	o.nameTag.Text = why
	o.nameTag.TextColor3 = Color3.fromRGB(255, 150, 140)
	o.deniedUntil = os.clock() + 1.6
end

local function keyName(action)
	local k = ClientSettings.get and ClientSettings.get("Key_" .. action)
	return tostring(k or ({Throw = "C", Hurl = "Y"})[action] or "E")
end
local function keyCode(action)
	local ok, code = pcall(function() return Enum.KeyCode[keyName(action)] end)
	return ok and code or nil
end

-- where you're aiming: what the middle of the screen looks at
local arcFolder = Instance.new("Folder"); arcFolder.Name = "ThrowArc"; arcFolder.Parent = workspace
local function aimRay()
	local cam = workspace.CurrentCamera
	if not cam then return nil end
	return cam:ViewportPointToRay(cam.ViewportSize.X / 2, cam.ViewportSize.Y / 2)
end
local function aimPoint()
	local ray = aimRay()
	if not ray then return nil end
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	params.FilterDescendantsInstances = {player.Character, fxFolder, arcFolder}
	local hit = workspace:Raycast(ray.Origin, ray.Direction * 300, params)
	return hit and hit.Position or (ray.Origin + ray.Direction * 300)
end
local function menuUp()
	local h = player.PlayerGui:FindFirstChild("HubMenu")
	return h ~= nil and h.Enabled and _G.HubMenuOpen and _G.HubMenuOpen()
end
local function inHub() return round:GetAttribute("Mode") == "Hub" end

-- THE POWER: a press
local lastAsk = 0
local function usePower()
	local c = player.Character
	if not c or not c:GetAttribute("Power") or inHub() then return end
	if os.clock() - lastAsk < 0.18 then return end
	lastAsk = os.clock()
	if remote then remote:FireServer("Use", aimPoint()) end
	punch(powerOrb)
end
powerOrb.tap.Activated:Connect(usePower)

--------------------------------------------------------------------
--  THE THROW: held to aim (the arm draws back, the arc and where it lands are drawn, filling
--  as the wind-up comes round), let go to throw; right mouse (block) puts it away
--------------------------------------------------------------------
local ELEMENT_COL = {fire = Color3.fromRGB(255, 130, 50), frost = Color3.fromRGB(150, 220, 255), smoke = Color3.fromRGB(190, 190, 196),
	ground = Color3.fromRGB(200, 170, 120), heal = Color3.fromRGB(255, 226, 130)}
local READY = Color3.fromRGB(255, 214, 110)
local FOE = Color3.fromRGB(255, 80, 70)
local aiming = nil      -- {t0, def, windup, how ("key" | "touch" | "pad")}
local dots = {}
local marker, markerCore, markerLight
local hint = Instance.new("TextLabel")
hint.AnchorPoint = Vector2.new(0.5, 0); hint.Position = UDim2.new(0.5, 0, 0.5, 40); hint.Size = UDim2.fromOffset(360, 18)
hint.BackgroundTransparency = 1; hint.Font = Theme.FONT_TITLE; hint.TextSize = 14; hint.TextColor3 = WHITE; hint.TextStrokeTransparency = 0.35
hint.Visible = false; hint.Parent = gui
local holdBar = Instance.new("Frame")
holdBar.AnchorPoint = Vector2.new(0.5, 0); holdBar.Position = UDim2.new(0.5, 0, 0.5, 60); holdBar.Size = UDim2.fromOffset(120, 5)
holdBar.BackgroundColor3 = Color3.fromRGB(20, 20, 26); holdBar.BackgroundTransparency = 0.3; holdBar.BorderSizePixel = 0; holdBar.Visible = false; holdBar.Parent = gui
Instance.new("UICorner", holdBar).CornerRadius = UDim.new(1, 0)
local holdFill = Instance.new("Frame"); holdFill.Size = UDim2.fromScale(0, 1); holdFill.BackgroundColor3 = READY; holdFill.BorderSizePixel = 0; holdFill.Parent = holdBar
Instance.new("UICorner", holdFill).CornerRadius = UDim.new(1, 0)

local function clearArc()
	for _, d in ipairs(dots) do d.Transparency = 1 end
	if marker then marker.Transparency = 1; markerCore.Transparency = 1; markerLight.Enabled = false end
	hint.Visible, holdBar.Visible = false, false
end
local function dot(i)
	local d = dots[i]
	if not d then
		d = Instance.new("Part")
		d.Name = "ArcDot"; d.Shape = Enum.PartType.Ball; d.Material = Enum.Material.Neon; d.Anchored = true
		d.CanCollide, d.CanQuery, d.CanTouch, d.CastShadow = false, false, false, false
		d.Parent = arcFolder
		dots[i] = d
	end
	return d
end
local function ensureMarker()
	if marker then return end
	marker = Instance.new("Part")
	marker.Name = "ArcRing"; marker.Shape = Enum.PartType.Cylinder; marker.Material = Enum.Material.Neon; marker.Anchored = true
	marker.CanCollide, marker.CanQuery, marker.CanTouch, marker.CastShadow = false, false, false, false
	marker.Parent = arcFolder
	markerCore = marker:Clone(); markerCore.Name = "ArcCore"; markerCore.Parent = arcFolder
	markerLight = Instance.new("PointLight"); markerLight.Range = 8; markerLight.Brightness = 1.5; markerLight.Shadows = false; markerLight.Parent = markerCore
end

local function startAim(how)
	local c = player.Character
	local thr = c and c:GetAttribute("Throwable")
	if aiming or not thr or inHub() or menuUp() then return end
	local hum = c:FindFirstChildOfClass("Humanoid")
	if not (hum and hum.Health > 0) then return end
	if (c:GetAttribute("ThrowCharges") or 0) <= 0 then
		local nextAt = c:GetAttribute("ThrowNextAt")
		deny(throwOrb, nextAt and string.format("back in %d", math.ceil(nextAt - snow())) or "none left")
		return
	end
	local def = Catalog.WEAPON[thr]
	if not def then return end
	aiming = {t0 = os.clock(), def = def, windup = Catalog.throwWindup(def), how = how}
	if remote then remote:FireServer("ThrowAim") end
	PowerPoses.play(c, PowerPoses.AIM)
end
local function release()
	if not aiming then return end
	local hurl = aiming.hurl
	aiming = nil
	clearArc()
	if remote then remote:FireServer(hurl and "Hurl" or "Throw", aimPoint()) end
	punch(hurl and hurlOrb or throwOrb)
end
local function cancelAim()
	if not aiming then return end
	local hurl = aiming.hurl
	aiming = nil
	clearArc()
	if remote then remote:FireServer(hurl and "HurlCancel" or "ThrowCancel") end
	PowerPoses.stop(player.Character, PowerPoses.AIM)
end

-- YOUR OWN STEEL (Combat ▸ Hurl): held the same way, on the same arc; what goes is the shield
-- on your arm first, then the one-hander in your hand (not in the Courtyard, the tavern or the
-- loot games, where the gear lives in the bag, nor the Lists: pure swordsmanship)
local NO_HURL = {Hub = true, Tavern = true, Crownfall = true, Deadvault = true, Lists = true}
local function hurlable(c)
	if not c or NO_HURL[round:GetAttribute("Mode") or ""] then return nil end
	local sid = c:GetAttribute("ShieldId")
	if sid and not c:GetAttribute("ShieldSlung") and c:FindFirstChild("ShieldModel") then
		local def = Catalog.WEAPON[sid]
		local h = def and Catalog.hurlOf(def)
		if h then return "shield", h end
	end
	local t = c:FindFirstChildOfClass("Tool")
	local def = t and not t:GetAttribute("TwinHidden") and Catalog.WEAPON[t.Name]
	local h = def and Catalog.hurlOf(def)
	if h then return "weapon", h end
	return nil
end
local function startHurl(how)
	local c = player.Character
	if aiming or not c or menuUp() then return end
	local hum = c:FindFirstChildOfClass("Humanoid")
	if not (hum and hum.Health > 0) then return end
	local kind, h = hurlable(c)
	if not kind then return end
	aiming = {t0 = os.clock(), def = h, windup = h.windup or 0.4, how = how, hurl = kind}
	if remote then remote:FireServer("HurlAim") end
	PowerPoses.play(c, PowerPoses.AIM)
end

-- the flight it would take: the server's own launch (Ballistics), stepped until it hits
local arcParams = RaycastParams.new()
arcParams.FilterType = Enum.RaycastFilterType.Exclude
local function flight(c, def, aim)
	local head = c:FindFirstChild("Head")
	if not (head and aim) then return nil end
	local g, speed = def.gravity or 40, def.speed or 90
	local dir, origin = Ballistics.launch(head.Position, aim, speed, g)
	local ignore = {c, arcFolder, fxFolder}
	for _, n in ipairs({"StuckArrows", "MagicFX", "DroppedWeapons"}) do local f = workspace:FindFirstChild(n); if f then table.insert(ignore, f) end end
	arcParams.FilterDescendantsInstances = ignore
	local pts, pos, vel = {origin}, origin, dir * speed
	local dt = 1 / 45
	for _ = 1, 45 * 4 do
		local nextVel = vel - Vector3.new(0, g * dt, 0)
		local step = (vel + nextVel) * 0.5 * dt
		local res = workspace:Raycast(pos, step, arcParams)
		if res then
			table.insert(pts, res.Position)
			local model = res.Instance:FindFirstAncestorOfClass("Model")
			local who = model and model:FindFirstChildOfClass("Humanoid") and model or nil
			return pts, res.Position, res.Normal, who
		end
		pos += step
		vel = nextVel
		table.insert(pts, pos)
	end
	return pts, pos, Vector3.yAxis, nil
end

-- every frame while aiming: the dotted arc, drawn out from the hand as the wind-up fills,
-- and a ring where it lands (as wide as what it bursts into); gold when it's ready to go, red
-- on someone
RunService.RenderStepped:Connect(function()
	if not aiming then return end
	local c = player.Character
	local hum = c and c:FindFirstChildOfClass("Humanoid")
	if not (hum and hum.Health > 0) or c:GetAttribute("Ragdolled") or c:GetAttribute("Blocking") or menuUp() then cancelAim(); return end
	-- (held this long the server has put it away: so do we)
	if os.clock() - aiming.t0 > 9.5 then cancelAim(); return end
	local def = aiming.def
	local k = math.clamp((os.clock() - aiming.t0) / math.max(aiming.windup, 0.05), 0, 1)
	local ready = k >= 1
	local pts, land, normal, who = flight(c, def, aimPoint())
	if not pts then return end
	local burst = def.burst
	local elem = burst and ((burst.fire and "fire") or (burst.frost and "frost") or (burst.smoke and "smoke") or (burst.ground and "ground") or ((burst.heal or 0) > 0 and "heal"))
	local col = who and not burst and FOE or (elem and ELEMENT_COL[elem]) or READY
	if not ready then col = col:Lerp(WHITE, 0.55) end
	-- the dots: one every ~1.6 studs along the flight, as far along as the wind-up has come
	local spaced, run = {}, 0
	for i = 2, #pts do
		run += (pts[i] - pts[i - 1]).Magnitude
		if run >= 1.6 then run = 0; table.insert(spaced, pts[i]) end
	end
	local shown = math.max(1, math.floor(#spaced * (0.25 + 0.75 * k)))
	local t = os.clock()
	for i = 1, math.max(#spaced, #dots) do
		local d = dot(i)
		if i <= shown and spaced[i] then
			d.Position = spaced[i]
			local pulse = ready and (0.5 + 0.5 * math.sin(t * 10 - i * 0.6)) or 0
			d.Size = Vector3.one * (0.18 + 0.08 * pulse)
			d.Color = col
			d.Transparency = 0.15 + 0.5 * (i / math.max(#spaced, 1)) * (ready and 0.4 or 1)
		else
			d.Transparency = 1
		end
	end
	-- where it lands: a ring the size of its burst, flat on the ground under where it breaks (that's
	-- where the pool, the cloud, the spikes will be); a blade's a small mark on what it hits
	ensureMarker()
	local radius = burst and burst.radius or 1.4
	local r = radius * (0.35 + 0.65 * k)
	local up = (normal and normal.Magnitude > 0.1) and normal or Vector3.yAxis
	if burst then
		-- (straight down to the ground, through anyone standing there)
		local ex = table.clone(arcParams.FilterDescendantsInstances)
		for _ = 1, 3 do
			local dp = RaycastParams.new()
			dp.FilterType = Enum.RaycastFilterType.Exclude
			dp.FilterDescendantsInstances = ex
			local down = workspace:Raycast(land + Vector3.new(0, 1, 0), Vector3.new(0, -40, 0), dp)
			if not down then break end
			local m = down.Instance:FindFirstAncestorOfClass("Model")
			if m and m:FindFirstChildOfClass("Humanoid") then table.insert(ex, m)
			else land, up = down.Position, Vector3.yAxis; break end
		end
	end
	local face = CFrame.lookAt(land, land + up) * CFrame.Angles(0, math.rad(90), 0)
	marker.CFrame = face * CFrame.new(0.05, 0, 0)
	marker.Size = Vector3.new(0.06, r * 2, r * 2)
	marker.Color = col
	marker.Transparency = ready and 0.55 or 0.75
	markerCore.CFrame = face * CFrame.new(0.07, 0, 0) * CFrame.Angles(t * 2, 0, 0)
	markerCore.Size = Vector3.new(0.08, math.min(0.9, r * 0.5), math.min(0.9, r * 0.5))
	markerCore.Color = col
	markerCore.Transparency = 0.2
	markerLight.Color = col
	markerLight.Enabled = true
	-- under the crosshair: what you're throwing, and whether it's ready
	hint.Visible, holdBar.Visible = true, not ready
	hint.Text = string.upper(def.name) .. (ready and "  ·  LET GO TO THROW" or "  ·  WINDING UP…")
	hint.TextColor3 = ready and col or WHITE
	holdFill.Size = UDim2.fromScale(k, 1)
end)

UserInputService.InputBegan:Connect(function(input, processed)
	if UserInputService:GetFocusedTextBox() then return end
	-- (right mouse is the block: it puts a throw away)
	if input.UserInputType == Enum.UserInputType.MouseButton2 and aiming then cancelAim(); return end
	if processed or menuUp() then return end
	if input.KeyCode == keyCode("Power") then usePower()
	elseif input.KeyCode == keyCode("Throw") then startAim("key")
	elseif input.KeyCode == keyCode("Hurl") then startHurl("key") end
end)
UserInputService.InputEnded:Connect(function(input)
	if not (aiming and aiming.how == "key") then return end
	if input.KeyCode == keyCode(aiming.hurl and "Hurl" or "Throw") then release() end
end)
-- a controller's (GamepadControls: D-pad ↑ tap the power, D-pad ↓ held the throw) and the bus
TouchInput.changed:Connect(function(action, down)
	if action == "Power" and down then usePower()
	elseif action == "Throw" then if down then startAim("pad") elseif aiming and not aiming.hurl then release() end
	elseif action == "Hurl" then if down then startHurl("pad") elseif aiming and aiming.hurl then release() end end
end)
hurlOrb.tap.MouseButton1Down:Connect(function() startHurl("touch") end)
hurlOrb.tap.MouseButton1Up:Connect(function() if aiming and aiming.how == "touch" then release() end end)
-- a phone: hold the throw orb, let go to throw
throwOrb.tap.MouseButton1Down:Connect(function() startAim("touch") end)
throwOrb.tap.MouseButton1Up:Connect(function() if aiming and aiming.how == "touch" then release() end end)
UserInputService.TouchEnded:Connect(function() if aiming and aiming.how == "touch" then task.defer(function() if aiming and aiming.how == "touch" then release() end end) end end)
player.CharacterAdded:Connect(function() aiming = nil; clearArc() end)

if remote then
	remote.OnClientEvent:Connect(function(what, why, which)
		if what == "Denied" then
			deny((which == "throw" and throwOrb) or (which == "hurl" and hurlOrb) or powerOrb, why)
			if which == "throw" or which == "hurl" then aiming = nil; clearArc() end
		end
	end)
end

local GLYPH = {blade = "🗡", axe = "🪓", spear = "🔱", dart = "🎯", flask = "🧪", bomb = "💣", bolas = "⛓"}
RunService.RenderStepped:Connect(function()
	local c = player.Character
	local power = c and c:GetAttribute("Power")
	local thr = c and c:GetAttribute("Throwable")
	local hub = inHub()
	powerOrb.frame.Visible = power ~= nil and not hub
	throwOrb.frame.Visible = thr ~= nil and not hub
	local hk = (c and not hub) and hurlable(c) or nil
	hurlOrb.frame.Visible = hk ~= nil
	-- (on a touch screen the orbs sit in the right thumb's arc: TouchControls' PowerSlot and
	-- ThrowSlot; else side by side right of the energy bar, one alone where the first would be)
	local tc = TouchInput.active() and player.PlayerGui:FindFirstChild("TouchControls")
	local function place(o, slotName, x)
		local slotF = tc and tc:FindFirstChild(slotName, true)
		if slotF then
			if o.frame.Parent ~= slotF then
				o.frame.Parent = slotF
				o.frame.AnchorPoint = Vector2.new(0.5, 0.5)
				o.frame.Position = UDim2.fromScale(0.5, 0.5)
				o.frame.Size = UDim2.fromScale(1, 1)
			end
		else
			if o.frame.Parent ~= gui then
				o.frame.Parent = gui
				o.frame.AnchorPoint = Vector2.new(0, 1)
				o.frame.Size = UDim2.fromOffset(64, 64)
			end
			o.frame.Position = UDim2.new(0.5, x, 1, -96)
		end
	end
	place(powerOrb, "PowerSlot", 352)
	place(throwOrb, "ThrowSlot", power and 428 or 352)
	place(hurlOrb, "HurlSlot", 352 + 76 * ((power and 1 or 0) + (thr and 1 or 0)))
	local pad = UserInputService.GamepadEnabled and not UserInputService.KeyboardEnabled
	local touch = TouchInput.active()
	local t = snow()
	if powerOrb.frame.Visible then
		local o = powerOrb
		o.keyTag.Text = pad and "↑" or keyName("Power")
		o.keyTag.Visible = not touch
		local pw = Catalog.POWER[power]
		local col = look(c:GetAttribute("PowerSpell"), c:GetAttribute("PowerSkin"))
		o.glyph.Text = pw and pw.glyph or "✨"
		o.ring.Color = col
		local readyAt, cd = c:GetAttribute("PowerReadyAt") or 0, c:GetAttribute("PowerCD") or 1
		local left = readyAt - t
		o.wipe.Size = UDim2.fromScale(1, math.clamp(left / math.max(cd, 0.1), 0, 1))
		o.secs.Text = left > 0 and tostring(math.ceil(left)) or ""
		if os.clock() > o.deniedUntil then o.nameTag.Text = pw and string.upper(pw.name) or ""; o.nameTag.TextColor3 = Color3.fromRGB(220, 220, 230) end
		local ench, n = c:GetAttribute("ArrowEnchant"), c:GetAttribute("ArrowLeft")
		setPips(o, (ench and n) or 0, col)
	end
	if throwOrb.frame.Visible then
		local o = throwOrb
		o.keyTag.Text = pad and "↓" or keyName("Throw")
		o.keyTag.Visible = not touch
		local def = Catalog.WEAPON[thr]
		local n, max = c:GetAttribute("ThrowCharges") or 0, c:GetAttribute("ThrowMax") or 1
		o.glyph.Text = def and GLYPH[def.look] or "✨"
		o.ring.Color = aiming and READY or (n > 0 and Theme.ACCENT or Color3.fromRGB(120, 120, 130))
		local nextAt = c:GetAttribute("ThrowNextAt")
		local left = nextAt and (nextAt - t) or 0
		o.wipe.Size = UDim2.fromScale(1, n > 0 and 0 or math.clamp(left / math.max(def and def.recharge or 15, 1), 0, 1))
		o.secs.Text = (n == 0 and left > 0) and tostring(math.ceil(left)) or ""
		if os.clock() > o.deniedUntil then o.nameTag.Text = def and string.upper(def.name) or ""; o.nameTag.TextColor3 = Color3.fromRGB(220, 220, 230) end
		setPips(o, max)
		for i, p in ipairs(o.pipList) do p.BackgroundColor3 = i <= n and Theme.ACCENT or Color3.fromRGB(60, 60, 70) end
	end
	if hurlOrb.frame.Visible then
		local o = hurlOrb
		o.keyTag.Text = pad and "→" or keyName("Hurl")
		o.keyTag.Visible = not touch
		o.glyph.Text = hk == "shield" and "🛡" or "⚔"
		o.ring.Color = (aiming and aiming.hurl) and READY or Color3.fromRGB(200, 205, 220)
		o.wipe.Size = UDim2.fromScale(1, 0)
		o.secs.Text = ""
		if os.clock() > o.deniedUntil then o.nameTag.Text = hk == "shield" and "THROW SHIELD" or "THROW WEAPON"; o.nameTag.TextColor3 = Color3.fromRGB(220, 220, 230) end
		setPips(o, 0)
	end
end)

--------------------------------------------------------------------
--  A CLASS LEVEL-UP (Economy.addClassXP)
--------------------------------------------------------------------
do
	local hubEvent = ReplicatedStorage:WaitForChild("HubEvent", 60)
	local banner = Instance.new("Frame")
	banner.AnchorPoint = Vector2.new(0.5, 0)
	banner.Position = UDim2.new(0.5, 0, 0, 140)
	banner.Size = UDim2.fromOffset(560, 0)
	banner.AutomaticSize = Enum.AutomaticSize.Y
	banner.BackgroundColor3 = Color3.fromRGB(16, 18, 28)
	banner.BackgroundTransparency = 0.1
	banner.Visible = false
	banner.Parent = gui
	Instance.new("UICorner", banner).CornerRadius = UDim.new(0, 14)
	local stroke = Instance.new("UIStroke", banner); stroke.Thickness = 2.5; stroke.Color = Theme.ACCENT
	local pad = Instance.new("UIPadding", banner); pad.PaddingTop = UDim.new(0, 12); pad.PaddingBottom = UDim.new(0, 14)
	local list = Instance.new("UIListLayout", banner); list.HorizontalAlignment = Enum.HorizontalAlignment.Center; list.Padding = UDim.new(0, 4); list.SortOrder = Enum.SortOrder.LayoutOrder
	local function line(text, size, color, order)
		local l = Instance.new("TextLabel")
		l.BackgroundTransparency = 1; l.Size = UDim2.new(1, -24, 0, size + 6); l.Font = Theme.FONT_TITLE; l.TextSize = size
		l.TextColor3 = color or WHITE; l.Text = text; l.LayoutOrder = order; l.TextStrokeTransparency = 0.5
		l.Parent = banner
		return l
	end
	local token = 0
	if hubEvent then
		hubEvent.OnClientEvent:Connect(function(what, info)
			if what ~= "ClassLevel" or type(info) ~= "table" then return end
			token += 1
			local mine = token
			for _, ch in ipairs(banner:GetChildren()) do if ch:IsA("TextLabel") then ch:Destroy() end end
			local cls = (require(ReplicatedStorage:WaitForChild("GameConfig")).CLASSES[info.class] or {}).name or info.class
			line(string.upper(tostring(cls)) .. " · CLASS LEVEL " .. tostring(info.level), 28, Theme.ACCENT, 1)
			for i, n in ipairs(info.news or {}) do line(n.text or "", 18, n.kind == "power" and Color3.fromRGB(150, 220, 255) or WHITE, i + 1) end
			if #(info.news or {}) == 0 then line("Keep fighting as a " .. tostring(cls) .. " to open its next power", 15, Color3.fromRGB(200, 200, 210), 2) end
			banner.Visible = true
			local s = banner:FindFirstChildOfClass("UIScale") or Instance.new("UIScale", banner)
			s.Scale = 0.7
			TweenService:Create(s, TweenInfo.new(0.35, Enum.EasingStyle.Back), {Scale = 1}):Play()
			task.delay(5, function() if token == mine then banner.Visible = false end end)
		end)
	end
end

--------------------------------------------------------------------
--  ON EVERYONE: imbues, auras, stealth, familiars, poison, roots, shields
--------------------------------------------------------------------
local looks = setmetatable({}, {__mode = "k"})   -- [character] = what's drawn on it
local function bladeParts(tool)
	local out = {}
	for _, p in ipairs(tool:GetDescendants()) do
		if p:IsA("BasePart") and (p:GetAttribute("SkinPart") == "Blade" or p.Name == "Hitbox") and #out < 3 then table.insert(out, p) end
	end
	return out
end
local function clearKey(L, key)
	for _, x in ipairs(L[key] or {}) do if x.Parent then x:Destroy() end end
	L[key] = nil
end
local function wings(c, col, glow, n)
	local torso = c:FindFirstChild("Torso")
	if not torso then return {} end
	local out = {}
	for s = -1, 1, 2 do
		for k = 1, math.max(1, math.floor((n or 2) / 2)) do
			local w = Instance.new("Part")
			w.Name = "PowerWing"; w.Material = Enum.Material.Neon; w.Color = k == 1 and glow or col
			w.Size = Vector3.new(0.15, 1.1 - k * 0.15, 3.4 - k * 0.6)
			w.CanCollide, w.CanQuery, w.CanTouch, w.Massless, w.CastShadow = false, false, false, true, false
			w.Transparency = 0.25
			local weld = Instance.new("Weld")
			weld.Part0, weld.Part1 = torso, w
			weld.C0 = CFrame.new(s * (0.7 + k * 0.1), 0.6 + k * 0.4, 0.8) * CFrame.Angles(math.rad(-20 + k * 18), s * math.rad(28), s * math.rad(-25 - k * 10)) * CFrame.new(0, 0, 1.4)
			weld.Parent = w
			w.Parent = c
			table.insert(out, w)
		end
	end
	return out
end
local function drawOn(c, isMe)
	local L = looks[c]
	if not L then L = {}; looks[c] = L end
	local t = snow()
	-- the imbue on the weapon in hand
	local tool = c:FindFirstChildOfClass("Tool")
	local im = (c:GetAttribute("ImbueUntil") or 0) > t and c:GetAttribute("Imbue") or nil
	local imKey = im and tool and (im .. tostring(tool) .. tostring(c:GetAttribute("ImbueSkin"))) or nil
	if imKey ~= L.imKey then
		clearKey(L, "imbue")
		L.imKey = imKey
		if imKey then
			local col, glow = look(c:GetAttribute("ImbueSpell"), c:GetAttribute("ImbueSkin"))
			L.imbue = {}
			for _, p in ipairs(bladeParts(tool)) do
				local fire = im == "fire" or im == "holy"
				local e = emitter(p, glow, col, {texture = fire and TEX.fire or TEX.spark, size = fire and 0.75 or 0.3, rate = fire and 50 or 30, speed = 1.5, life = 0.45,
					accel = Vector3.new(0, fire and 4 or 1, 0), box = true, light = fire and 0.7 or 1})
				e.ZOffset = 0.4
				local l = Instance.new("PointLight"); l.Color = col; l.Range = 9; l.Brightness = 1.6; l.Parent = p
				table.insert(L.imbue, e); table.insert(L.imbue, l)
			end
		end
	end
	-- a fresh imbue CATCHES: the blade flares up, a burst off its whole length, a whoosh
	local imUntil = im and c:GetAttribute("ImbueUntil") or nil
	if imUntil ~= L.imUntil then
		local fresh = imUntil ~= nil and L.imSeen
		L.imUntil, L.imSeen = imUntil, true
		if fresh and L.imbue then
			local col, glow = look(c:GetAttribute("ImbueSpell"), c:GetAttribute("ImbueSkin"))
			for _, x in ipairs(L.imbue) do
				if x:IsA("ParticleEmitter") then
					local burst = emitter(x.Parent, glow, col, {texture = x.Texture, size = 0.9, rate = 0, speed = 7, life = 0.45, box = true, light = 1})
					burst:Emit(26)
					Debris:AddItem(burst, 1.2)
				elseif x:IsA("PointLight") then
					x.Brightness = 3.5; x.Range = 13
					TweenService:Create(x, TweenInfo.new(0.7, Enum.EasingStyle.Quad), {Brightness = 1.6, Range = 9}):Play()
				end
			end
			local blade = L.imbue[1] and L.imbue[1].Parent
			if blade then sound(SND.whoosh, blade, 0.6, im == "frost" and 1.3 or (im == "fire" and 0.85 or 1.05)) end
		end
	elseif not im then
		L.imSeen = true
	end
	-- the aura of a power that lasts, on the body itself for as long as it does (ReplicatedStorage ▸
	-- PowerAuras: Iron Skin's stone plates, a halo, wind trails, a shroud, orbiting runes…)
	local au = (c:GetAttribute("AuraUntil") or 0) > t and c:GetAttribute("Aura") or nil
	local auKey = au and (au .. tostring(c:GetAttribute("AuraSkin")) .. tostring(c:GetAttribute("AuraUntil"))) or nil
	-- (a renewed aura of the same kind just goes on)
	if auKey and L.auKind == au and L.auSkin == c:GetAttribute("AuraSkin") and L.auraFx then auKey = L.auKey end
	if auKey ~= L.auKey then
		if L.auraFx then pcall(L.auraFx.finish); L.auraFx = nil end
		clearKey(L, "aura")
		L.auKey, L.auKind, L.auSkin = auKey, au, au and c:GetAttribute("AuraSkin") or nil
		if auKey then
			local col, glow, Lk = look(c:GetAttribute("AuraSpell"), c:GetAttribute("AuraSkin"))
			L.auraFx = PowerAuras.build(c, au, col, glow)
			L.aura = {}
			if au == "avatar" or (Lk and Lk.wings) then for _, w in ipairs(wings(c, col, glow, Lk and Lk.wings or 2)) do table.insert(L.aura, w) end end
		end
	end
	if L.auraFx and L.auraFx.step then pcall(L.auraFx.step, os.clock()) end
	-- an archer's enchanted arrows: the bow glows with them while any are left
	local ench = c:GetAttribute("ArrowEnchant")
	local enchKey = ench and tool and (ench .. tostring(tool)) or nil
	if enchKey ~= L.enchKey then
		clearKey(L, "ench")
		L.enchKey = enchKey
		if enchKey then
			local pw = Catalog.POWER[ench]
			local col, glow = look("Pw_" .. ench, c:GetAttribute("PowerSkin"))
			if pw and not c:GetAttribute("PowerSkin") then col, glow = pw.color or col, pw.glow or glow end
			L.ench = {}
			local n = 0
			for _, p in ipairs(tool:GetDescendants()) do
				if p:IsA("BasePart") and p.Transparency < 1 and n < 3 then
					n += 1
					local e = emitter(p, glow, col, {size = 0.3, rate = 30, speed = 1, life = 0.45, box = true, light = 1})
					e.ZOffset = 0.5
					table.insert(L.ench, e)
				end
			end
			local h = tool:FindFirstChild("Handle")
			if h then local l = Instance.new("PointLight"); l.Color = col; l.Range = 8; l.Brightness = 1.6; l.Parent = h; table.insert(L.ench, l) end
		end
	end
	-- stealth: theirs nearly gone, yours a ghost
	local hidden = (c:GetAttribute("HiddenUntil") or 0) > t
	if hidden ~= (L.hidden or false) then
		L.hidden = hidden
		for _, p in ipairs(c:GetDescendants()) do
			if p:IsA("BasePart") or p:IsA("Decal") then p.LocalTransparencyModifier = hidden and (isMe and 0.55 or 0.92) or 0 end
		end
	end
	-- a familiar at the shoulder
	local fam = (c:GetAttribute("Familiar") or 0) > t
	if fam and not L.familiar then
		local col, glow = look(c:GetAttribute("FamiliarSpell"), c:GetAttribute("FamiliarSkin"))
		local core = part({Name = "Familiar", Shape = Enum.PartType.Ball, Size = Vector3.one * 0.8, Material = Enum.Material.Neon, Color = glow})
		emitter(core, col, glow, {size = 0.3, rate = 30, speed = 0.6, life = 0.6})
		local l = Instance.new("PointLight"); l.Color = col; l.Range = 10; l.Brightness = 2; l.Parent = core
		L.familiar = core
	elseif not fam and L.familiar then
		L.familiar:Destroy(); L.familiar = nil
	end
	if L.familiar then
		local head = c:FindFirstChild("Head")
		if head then
			local bob = math.sin(os.clock() * 3) * 0.3
			L.familiar.CFrame = L.familiar.CFrame:Lerp(head.CFrame * CFrame.new(2, 1.2 + bob, 0.6), 0.2)
		end
	end
	-- the body's part: a gesture as a power winds up (ReplicatedStorage ▸ PowerPoses)
	local casting = c:GetAttribute("PowerCasting")
	if casting ~= L.casting then
		L.casting = casting
		if casting then
			PowerPoses.play(c, PowerPoses.gestureFor(Catalog.POWER[casting]))
			L.posedAt = os.clock()
		end
	end
	-- a throw: the arm drawn back while they aim (yours is drawn the moment you press), and
	-- the fling from there as it goes
	local aimingNow = c:GetAttribute("ThrowAiming") == true
	if aimingNow ~= (L.aiming or false) then
		L.aiming = aimingNow
		if not isMe then
			if aimingNow then PowerPoses.play(c, PowerPoses.AIM)
			else task.delay(0.15, function() if not L.aiming then PowerPoses.stop(c, PowerPoses.AIM) end end) end
		end
	end
	local tt = c:GetAttribute("ThrowTick")
	if L.seen and tt ~= L.throwTick then PowerPoses.play(c, PowerPoses.THROW, snow() - PowerPoses.THROW_FROM) end
	L.throwTick = tt
	-- the moment a power goes off: a burst of its light and a ring of sound (an ultimate's
	-- a shockwave and a column of light); its gesture now, if it had no wind-up to start in
	local tick = c:GetAttribute("PowerTick")
	if tick ~= L.tick then
		local first = not L.seen
		L.tick = tick
		local root = c:FindFirstChild("HumanoidRootPart")
		local d = Catalog.POWER[c:GetAttribute("LastPower") or ""]
		if not first and d and os.clock() - (L.posedAt or 0) > 0.7 then PowerPoses.play(c, PowerPoses.gestureFor(d)) end
		if not first and root and d and d.ultimate then
			local col, glow = look(c:GetAttribute("PowerSpell"), c:GetAttribute("PowerSkin"))
			local ground = root.Position - Vector3.new(0, 2.9, 0)
			for k = 0, 1 do
				local r = part({Name = "UltimateWave", Shape = Enum.PartType.Cylinder, Size = Vector3.new(0.2, 2, 2), Material = Enum.Material.Neon, Color = k == 0 and glow or col,
					CFrame = CFrame.new(ground + Vector3.new(0, 0.2 + k * 0.1, 0)) * CFrame.Angles(0, 0, math.rad(90)), Transparency = 0.1})
				TweenService:Create(r, TweenInfo.new(0.6 + k * 0.25, Enum.EasingStyle.Quart), {Size = Vector3.new(0.2, 34 - k * 8, 34 - k * 8), Transparency = 1}):Play()
				Debris:AddItem(r, 1)
			end
			local beam = part({Name = "UltimateColumn", Shape = Enum.PartType.Cylinder, Size = Vector3.new(40, 3, 3), Material = Enum.Material.Neon, Color = glow,
				CFrame = CFrame.new(ground + Vector3.new(0, 20, 0)) * CFrame.Angles(0, 0, math.rad(90)), Transparency = 0.2})
			TweenService:Create(beam, TweenInfo.new(0.7, Enum.EasingStyle.Quad), {Size = Vector3.new(40, 0.2, 0.2), Transparency = 1}):Play()
			Debris:AddItem(beam, 0.8)
			sound(SND.boom, root, 0.55, 0.8)
		end
		if not first and root then
			local col, glow = look(c:GetAttribute("PowerSpell"), c:GetAttribute("PowerSkin"))
			local b = part({Name = "PowerBurst", Size = Vector3.new(2, 4, 2), Transparency = 1, CFrame = root.CFrame})
			local e = emitter(b, col, glow, {size = 0.45, rate = 0, speed = 10, life = 0.5, light = 1})
			e:Emit(36)
			local l = Instance.new("PointLight"); l.Color = col; l.Range = 16; l.Brightness = 3; l.Parent = b
			TweenService:Create(l, TweenInfo.new(0.5), {Brightness = 0}):Play()
			local snd = Instance.new("Sound"); snd.SoundId = "rbxassetid://9125899162"; snd.Volume = 0.5; snd.PlaybackSpeed = 1.15
			snd.RollOffMaxDistance = 90; snd.Parent = b; snd:Play()
			Debris:AddItem(b, 2)
		end
	end
	-- a shield up while they block
	local sm = c:FindFirstChild("ShieldModel")
	local grip = sm and sm.PrimaryPart and sm.PrimaryPart:FindFirstChild("ShieldGrip")
	-- (slung on the back while a two-hander's in hand: Combat ▸ Shields, its weld is the server's)
	if grip and not c:GetAttribute("ShieldSlung") then
		local idle, block = grip:GetAttribute("IdleC0"), grip:GetAttribute("BlockC0")
		if typeof(idle) == "CFrame" and typeof(block) == "CFrame" then
			local want = c:GetAttribute("Blocking") and 1 or 0
			L.raise = (L.raise or 0) + (want - (L.raise or 0)) * 0.35
			grip.C0 = idle:Lerp(block, L.raise)
		end
	end
	L.seen = true
end

RunService.RenderStepped:Connect(function()
	local me = player.Character
	for _, p in ipairs(Players:GetPlayers()) do
		local c = p.Character
		if c then local ok, err = pcall(drawOn, c, c == me); if not ok then warn("[Powers.client]", err) end end
	end
	-- (bots too: their powers, and what yours did to them: poison, roots)
	local npcs = workspace:FindFirstChild("NPCs")
	for _, c in ipairs(npcs and npcs:GetChildren() or {}) do
		if c:IsA("Model") then pcall(drawOn, c, false) end
	end
	for c, L in pairs(looks) do
		if not c.Parent then
			if L.auraFx then pcall(L.auraFx.finish); L.auraFx = nil end
			for _, k in ipairs({"imbue", "aura", "ench"}) do clearKey(L, k) end
			if L.familiar then L.familiar:Destroy() end
			looks[c] = nil
		end
	end
end)

--------------------------------------------------------------------
--  POWERFX: circles, dashes, slams, decoys
--------------------------------------------------------------------
local function ring(at, radius, col, glow, life)
	local r = part({Name = "PowerRing", Shape = Enum.PartType.Cylinder, Size = Vector3.new(0.15, 1, 1), Material = Enum.Material.Neon, Color = glow,
		CFrame = CFrame.new(at + Vector3.new(0, 0.15, 0)) * CFrame.Angles(0, 0, math.rad(90)), Transparency = 0.2})
	TweenService:Create(r, TweenInfo.new(life or 0.45, Enum.EasingStyle.Quad), {Size = Vector3.new(0.15, radius * 2, radius * 2), Transparency = 1}):Play()
	Debris:AddItem(r, (life or 0.45) + 0.1)
end
local EVENTS = {}
function EVENTS.Zone(id, at, radius, time, delay, flags, spellId, skin)
	flags = flags or {}
	local col, glow
	if spellId then col, glow = look(spellId, skin)
	else
		local e = flags.fire and ELEMENT.fire or (flags.frost and ELEMENT.frost or (flags.smoke and ELEMENT.smoke or (flags.ground and ELEMENT.ground or ELEMENT.holy)))
		col, glow = e[1], e[2]
	end
	local life = (delay or 0) + math.max(time or 0, 0.5)
	local disc = part({Name = "PowerZone", Shape = Enum.PartType.Cylinder, Size = Vector3.new(0.12, radius * 2, radius * 2), Material = Enum.Material.Neon,
		Color = col, Transparency = 0.75, CFrame = CFrame.new(at + Vector3.new(0, 0.08, 0)) * CFrame.Angles(0, 0, math.rad(90))})
	local edge = part({Name = "PowerZoneEdge", Shape = Enum.PartType.Cylinder, Size = Vector3.new(0.14, radius * 2 + 0.3, radius * 2 + 0.3), Material = Enum.Material.Neon,
		Color = glow, Transparency = 0.55, CFrame = CFrame.new(at + Vector3.new(0, 0.06, 0)) * CFrame.Angles(0, 0, math.rad(90))})
	local holder = part({Name = "PowerZoneFX", Size = Vector3.new(radius * 1.6, 0.5, radius * 1.6), Transparency = 1, CFrame = CFrame.new(at + Vector3.new(0, 0.6, 0))})
	local list = {disc, edge, holder}
	if flags.fire then emitter(holder, ELEMENT.fire[1], ELEMENT.fire[2], {texture = TEX.fire, size = 1.4, rate = 60, speed = 3, life = 0.6, accel = Vector3.new(0, 6, 0), box = true, light = 1}) end
	if flags.frost then emitter(holder, ELEMENT.frost[1], WHITE, {texture = TEX.smoke, size = 2, rate = 30, speed = 1, life = 1.2, alpha = 0.5, box = true, light = 0.3}) end
	if flags.smoke then
		holder.Size = Vector3.new(radius * 1.6, 4, radius * 1.6)
		emitter(holder, Color3.fromRGB(70, 70, 76), Color3.fromRGB(120, 120, 126), {texture = TEX.smoke, size = 7, rate = 40, speed = 2, life = 2.6, alpha = 0.05, box = true, light = 0})
	end
	if flags.ground then
		for k = 1, math.floor(radius * 3) do
			local a, d = math.random() * math.pi * 2, math.random() * radius
			table.insert(list, part({Name = "Caltrop", Size = Vector3.new(0.35, 0.35, 0.35), Material = Enum.Material.Metal, Color = Color3.fromRGB(80, 80, 86),
				CFrame = CFrame.new(at + Vector3.new(math.cos(a) * d, 0.2, math.sin(a) * d)) * CFrame.Angles(math.random() * 3, math.random() * 3, math.random() * 3)}))
		end
	end
	if flags.heal or flags.holy then emitter(holder, glow, WHITE, {size = 0.4, rate = 40, speed = 4, life = 1, accel = Vector3.new(0, 4, 0), box = true}) end
	if flags.hurt and not flags.fire and not flags.arrows then emitter(holder, col, glow, {size = 0.5, rate = 30, speed = 2, life = 0.8, accel = Vector3.new(0, 3, 0), box = true}) end
	if flags.dome then
		table.insert(list, part({Name = "PowerDome", Shape = Enum.PartType.Ball, Size = Vector3.one * radius * 2, Material = Enum.Material.ForceField, Color = glow,
			Transparency = 0.15, CFrame = CFrame.new(at)}))
	end
	if flags.pull then
		local swirl = part({Name = "PowerWell", Shape = Enum.PartType.Ball, Size = Vector3.one * 3, Material = Enum.Material.Neon, Color = col, Transparency = 0.1, CFrame = CFrame.new(at + Vector3.new(0, 2, 0))})
		emitter(swirl, col, glow, {size = 0.6, rate = 80, speed = -10, life = 0.6, light = 1})
		table.insert(list, swirl)
		task.spawn(function()
			local t0 = os.clock()
			while swirl.Parent and os.clock() - t0 < life do
				swirl.CFrame = CFrame.new(at + Vector3.new(0, 2, 0)) * CFrame.Angles(0, (os.clock() - t0) * 6, 0)
				task.wait()
			end
		end)
	end
	if flags.arrows then
		task.spawn(function()
			task.wait(delay or 0)
			local t0 = os.clock()
			while os.clock() - t0 < (time or 3) do
				for _ = 1, 3 do
					local a, d = math.random() * math.pi * 2, math.random() * radius
					local from = at + Vector3.new(math.cos(a) * d + 4, 40, math.sin(a) * d)
					local to = at + Vector3.new(math.cos(a) * d, 0.3, math.sin(a) * d)
					local arrow = part({Name = "RainArrow", Size = Vector3.new(0.12, 0.12, 2.6), Material = Enum.Material.Neon, Color = glow,
						CFrame = CFrame.lookAt(from, to)})
					local tw = TweenService:Create(arrow, TweenInfo.new(0.45, Enum.EasingStyle.Linear), {CFrame = CFrame.lookAt(to, to + (to - from).Unit)})
					tw:Play()
					Debris:AddItem(arrow, 1.6)
				end
				task.wait(0.12)
			end
		end)
	end
	for _, p in ipairs(list) do Debris:AddItem(p, life + 0.6) end
	task.delay(life, function()
		for _, p in ipairs(list) do
			if p.Parent then
				for _, e in ipairs(p:GetChildren()) do if e:IsA("ParticleEmitter") then e.Enabled = false end end
				if p.Name ~= "PowerZoneFX" then TweenService:Create(p, TweenInfo.new(0.5), {Transparency = 1}):Play() end
			end
		end
	end)
	ring(at, radius, col, glow, 0.5)
end
function EVENTS.Dash(c, time, spellId, skin)
	local root = c and c:FindFirstChild("HumanoidRootPart")
	if not root then return end
	local col, glow = look(spellId, skin)
	local e = emitter(root, col, glow, {size = 0.8, rate = 120, speed = 1, life = 0.35, box = true, light = 1})
	task.delay(time or 0.4, function() e.Enabled = false; Debris:AddItem(e, 1) end)
end
function EVENTS.Slam(at, radius, spellId, skin)
	local col, glow = look(spellId, skin)
	ring(at, radius, col, glow, 0.4)
	local dust = part({Name = "SlamDust", Size = Vector3.new(radius, 0.5, radius), Transparency = 1, CFrame = CFrame.new(at + Vector3.new(0, 0.5, 0))})
	local e = emitter(dust, Color3.fromRGB(140, 120, 100), Color3.fromRGB(200, 190, 170), {texture = TEX.smoke, size = 2.5, rate = 0, speed = 8, life = 0.8, alpha = 0.4, light = 0, spread = 70})
	e:Emit(30)
	local e2 = emitter(dust, col, glow, {size = 0.5, rate = 0, speed = 14, life = 0.4})
	e2:Emit(40)
	Debris:AddItem(dust, 1.5)
end
-- an imbued blow lands: a flash where it struck and the element bursting off it; holy light
-- comes down in a pillar, wind blows out in a ring, frost shatters in shards, and a draining
-- blow's life flows back to the striker
local STRIKE_SND = {fire = {SND.whoosh, 0.8}, frost = {SND.ice, 1.1}, holy = {SND.shing, 0.9}, wind = {SND.whoosh, 1.35},
	venom = {SND.whoosh, 0.65}, blood = {SND.zap2, 0.7}, shadow = {SND.zap2, 0.55}}
function EVENTS.Strike(attacker, target, at, element, spellId, skin, drain)
	if typeof(at) ~= "Vector3" then return end
	local col, glow = look(spellId, skin)
	local cam = workspace.CurrentCamera
	if cam and (cam.CFrame.Position - at).Magnitude > 220 then return end
	-- the flash
	local flash = part({Name = "StrikeFlash", Shape = Enum.PartType.Ball, Size = Vector3.one * 0.6, Material = Enum.Material.Neon, Color = glow, CFrame = CFrame.new(at), Transparency = 0.05})
	TweenService:Create(flash, TweenInfo.new(0.22, Enum.EasingStyle.Quad), {Size = Vector3.one * 3.6, Transparency = 1}):Play()
	local l = Instance.new("PointLight"); l.Color = col; l.Range = 14; l.Brightness = 5; l.Parent = flash
	TweenService:Create(l, TweenInfo.new(0.35), {Brightness = 0}):Play()
	Debris:AddItem(flash, 0.5)
	-- the element
	local holder = part({Name = "StrikeBurst", Size = Vector3.one * 0.8, Transparency = 1, CFrame = CFrame.new(at)})
	Debris:AddItem(holder, 2)
	if element == "fire" then
		emitter(holder, col, Color3.fromRGB(200, 50, 10), {texture = TEX.fire, size = 1.4, rate = 0, speed = 9, life = 0.45, accel = Vector3.new(0, 10, 0), light = 1}):Emit(30)
		emitter(holder, glow, col, {size = 0.3, rate = 0, speed = 18, life = 0.6, accel = Vector3.new(0, -12, 0)}):Emit(24)
	elseif element == "frost" then
		emitter(holder, glow, col, {size = 0.5, rate = 0, speed = 12, life = 0.5}):Emit(30)
		for k = 1, 7 do
			local dir = (Vector3.new(math.random() - 0.5, math.random() * 0.8, math.random() - 0.5)).Unit
			local shard = part({Name = "IceShard", Size = Vector3.new(0.18, 0.18, 0.6 + math.random() * 0.5), Material = Enum.Material.Glass, Color = Color3.fromRGB(190, 235, 255),
				Transparency = 0.15, CFrame = CFrame.lookAt(at, at + dir)})
			TweenService:Create(shard, TweenInfo.new(0.45, Enum.EasingStyle.Quad), {CFrame = CFrame.lookAt(at + dir * 4, at + dir * 5) * CFrame.Angles(math.random() * 3, 0, 0), Transparency = 1}):Play()
			Debris:AddItem(shard, 0.5)
		end
	elseif element == "holy" then
		emitter(holder, glow, col, {size = 0.45, rate = 0, speed = 10, life = 0.7}):Emit(34)
		local ground = at - Vector3.new(0, 3, 0)
		local pillar = part({Name = "HolyPillar", Shape = Enum.PartType.Cylinder, Size = Vector3.new(30, 2.4, 2.4), Material = Enum.Material.Neon, Color = glow,
			CFrame = CFrame.new(ground + Vector3.new(0, 15, 0)) * CFrame.Angles(0, 0, math.rad(90)), Transparency = 0.15})
		TweenService:Create(pillar, TweenInfo.new(0.55, Enum.EasingStyle.Quad), {Size = Vector3.new(30, 0.2, 0.2), Transparency = 1}):Play()
		Debris:AddItem(pillar, 0.6)
		ring(ground, 7, col, glow, 0.45)
	elseif element == "wind" then
		emitter(holder, glow, col, {size = 0.35, rate = 0, speed = 22, life = 0.3, spread = 20}):Emit(28)
		local r = part({Name = "Gust", Shape = Enum.PartType.Cylinder, Size = Vector3.new(0.1, 1, 1), Material = Enum.Material.Neon, Color = glow,
			CFrame = CFrame.new(at) * CFrame.Angles(0, 0, math.rad(90)), Transparency = 0.3})
		TweenService:Create(r, TweenInfo.new(0.3, Enum.EasingStyle.Quad), {Size = Vector3.new(0.1, 9, 9), Transparency = 1}):Play()
		Debris:AddItem(r, 0.35)
	elseif element == "venom" then
		emitter(holder, col, glow, {size = 0.45, rate = 0, speed = 10, life = 0.7, accel = Vector3.new(0, -24, 0)}):Emit(26)
		emitter(holder, col, glow, {texture = TEX.smoke, size = 1.6, rate = 0, speed = 2, life = 0.9, alpha = 0.5, light = 0.2}):Emit(6)
	elseif element == "shadow" or element == "blood" then
		emitter(holder, col, glow, {texture = TEX.smoke, size = 1.4, rate = 0, speed = 5, life = 0.6, alpha = 0.35, light = 0.4}):Emit(12)
		emitter(holder, glow, col, {size = 0.4, rate = 0, speed = 12, life = 0.4}):Emit(20)
	else
		emitter(holder, glow, col, {size = 0.45, rate = 0, speed = 12, life = 0.5}):Emit(30)
	end
	local sd = STRIKE_SND[element]
	sound(sd and sd[1] or SND.cast, at, 0.45, sd and sd[2] or 1.2)
	-- a draining blow: motes of life flowing from them to the striker
	local back = drain and typeof(attacker) == "Instance" and attacker:FindFirstChild("HumanoidRootPart")
	if back then
		for k = 1, 8 do
			local mote = part({Name = "LifeMote", Shape = Enum.PartType.Ball, Size = Vector3.one * 0.35, Material = Enum.Material.Neon, Color = k % 2 == 0 and glow or col, CFrame = CFrame.new(at)})
			local bend = Vector3.new(math.random() - 0.5, 0.6 + math.random(), math.random() - 0.5) * 3
			local t0, dur = os.clock() + k * 0.04, 0.5
			local conn
			conn = RunService.RenderStepped:Connect(function()
				local x = math.clamp((os.clock() - t0) / dur, 0, 1)
				if x >= 1 or not back.Parent then conn:Disconnect(); mote:Destroy(); return end
				local to = back.Position
				local mid = (at + to) / 2 + bend
				local a, b = at:Lerp(mid, x), mid:Lerp(to, x)
				mote.CFrame = CFrame.new(a:Lerp(b, x))
				mote.Size = Vector3.one * (0.35 * (1 - x * 0.6))
			end)
		end
		task.delay(0.6, function()
			if back.Parent then
				local e = emitter(back, glow, col, {size = 0.4, rate = 0, speed = 3, life = 0.6, box = true})
				e:Emit(16)
				Debris:AddItem(e, 1)
			end
		end)
	end
end
function EVENTS.Decoy(model, time, spellId, skin)
	if not model then return end
	local col = look(spellId, skin)
	for _, p in ipairs(model:GetDescendants()) do
		if p:IsA("BasePart") then
			p.LocalTransparencyModifier = 0.25
			TweenService:Create(p, TweenInfo.new(time or 3, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {LocalTransparencyModifier = 1}):Play()
		end
	end
	local root = model:FindFirstChild("HumanoidRootPart") or model:FindFirstChild("Torso")
	if root then emitter(root, col, WHITE, {size = 0.3, rate = 25, speed = 1, life = 0.8, box = true}) end
end
task.spawn(function()
	local pfx = ReplicatedStorage:WaitForChild("PowerFX", math.huge)
	pfx.OnClientEvent:Connect(function(what, ...)
		local fn = EVENTS[what]
		if fn then local ok, err = pcall(fn, ...); if not ok then warn("[Powers.client]", what, err) end end
	end)
end)

--------------------------------------------------------------------
--  THROWFX: a thrown thing in flight, the same arc the server flies
--------------------------------------------------------------------
local flying = {}
local SPIN = {blade = 22, axe = 14, flask = 8, bomb = 6, bolas = 18, blunt = 15, shield = 17}
-- (a shield flies flat, face to the sky, spinning: its Handle's -Z up)
local FLAT = CFrame.fromMatrix(Vector3.zero, Vector3.xAxis, Vector3.zAxis) * CFrame.Angles(math.rad(10), 0, 0)
-- a copy of the very thing thrown (a shield off an arm, a sword out of a hand: Combat ▸ Hurl),
-- skin, paint and glow and all, to fly: its visible parts, nothing that ties it to anyone
local function copyOf(src)
	if typeof(src) ~= "Instance" or not src.Parent then return nil end
	local handle = src:FindFirstChild("Handle")
	if not (handle and handle:IsA("BasePart")) then return nil end
	local m = Instance.new("Model")
	m.Name = "Thrown"
	local hc
	for _, d in ipairs(src:GetDescendants()) do
		if d:IsA("BasePart") and d.Name ~= "Hitbox" and d.Name ~= "GuardHull" and (d.Transparency < 1 or d == handle) then
			local p = d:Clone()
			for _, x in ipairs(p:GetDescendants()) do
				if x:IsA("JointInstance") or x:IsA("Constraint") or x:IsA("WeldConstraint") or x:IsA("LuaSourceContainer")
					or x:IsA("ProximityPrompt") or x:IsA("Sound") or x:IsA("BasePart") then x:Destroy() end
			end
			p.Anchored, p.CanCollide, p.CanQuery, p.CanTouch = true, false, false, false
			p.Parent = m
			if d == handle then hc = p end
		end
	end
	if not hc then m:Destroy(); return nil end
	m.PrimaryPart = hc
	m.Parent = fxFolder
	return m
end
local function displayOf(weaponId, skin)
	local src = Catalog.weaponModel(weaponId)
	if not src then return nil end
	local m = src:Clone()
	pcall(Dresser.applySkin, m, skin)
	for _, p in ipairs(m:GetDescendants()) do
		if p:IsA("BasePart") then p.Anchored = true; p.CanCollide = false; p.CanQuery = false; p.CanTouch = false end
	end
	m.Parent = fxFolder
	return m
end
task.spawn(function()
	local tfx = ReplicatedStorage:WaitForChild("ThrowFX", math.huge)
	tfx.OnClientEvent:Connect(function(what, id, a, b, c, d, e, _thrower, source, lookAs)
		if what == "Throw" then
			-- (id, origin, velocity, gravity, weaponId, skin; a thrown shield or weapon: the thing
			-- itself, to copy, and how it flies)
			local def = Catalog.WEAPON[d]
			local m = copyOf(source) or displayOf(d, e)
			if not m then return end
			local trail
			local h = m.PrimaryPart or m:FindFirstChild("Handle")
			if h then
				local a0, a1 = Instance.new("Attachment"), Instance.new("Attachment")
				a0.Position, a1.Position = Vector3.new(0, 0.3, 0), Vector3.new(0, -0.3, 0)
				a0.Parent, a1.Parent = h, h
				trail = Instance.new("Trail"); trail.Attachment0, trail.Attachment1 = a0, a1
				trail.Lifetime = 0.25; trail.Transparency = NumberSequence.new(0.4, 1); trail.Color = ColorSequence.new(WHITE)
				trail.Parent = h
			end
			flying[id] = {m = m, pos = a, vel = b, g = c, look = lookAs or (def and def.look) or "blade", t0 = os.clock(), spin = 0}
		elseif what == "Land" then
			local f = flying[id]
			if not f then return end
			flying[id] = nil
			if a and b and (f.look == "blade" or f.look == "axe" or f.look == "spear" or f.look == "dart") then
				-- it sticks where it went in, a while
				local h = f.m.PrimaryPart or f.m:FindFirstChild("Handle")
				if h then f.m:PivotTo(CFrame.lookAt(a, a + f.vel.Unit) * CFrame.Angles(math.rad(-90), 0, 0) * CFrame.new(0, -0.6, 0)) end
				Debris:AddItem(f.m, 6)
			else
				if a and (f.look == "flask" or f.look == "bomb") then
					local burst = part({Name = "Shatter", Size = Vector3.one, Transparency = 1, CFrame = CFrame.new(a)})
					local em = emitter(burst, Color3.fromRGB(220, 220, 220), WHITE, {size = 0.3, rate = 0, speed = 12, life = 0.4})
					em:Emit(24)
					Debris:AddItem(burst, 1)
				end
				f.m:Destroy()
			end
		end
	end)
end)
RunService.RenderStepped:Connect(function(dt)
	for id, f in pairs(flying) do
		local nextVel = f.vel - Vector3.new(0, f.g * dt, 0)
		f.pos += (f.vel + nextVel) * 0.5 * dt
		f.vel = nextVel
		f.spin += dt * (SPIN[f.look] or 0)
		local dir = f.vel.Magnitude > 0.1 and f.vel.Unit or Vector3.yAxis
		local cf = CFrame.lookAt(f.pos, f.pos + dir) * CFrame.Angles(math.rad(-90), 0, 0)
		if f.look == "shield" then cf = CFrame.new(f.pos) * CFrame.Angles(0, f.spin, 0) * FLAT
		elseif SPIN[f.look] then cf = CFrame.new(f.pos) * CFrame.lookAt(Vector3.zero, dir).Rotation * CFrame.Angles(-f.spin, 0, 0) * CFrame.Angles(math.rad(-90), 0, 0) end
		if f.m.Parent then f.m:PivotTo(cf) end
		if os.clock() - f.t0 > 7 then f.m:Destroy(); flying[id] = nil end
	end
end)
