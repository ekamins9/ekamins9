--[[ POWERS (client) — the third slot on your screen and everyone's powers in the world.

     YOU: the Power key (ClientSettings Key_Power, E; a controller's D-pad ↑ tap; the ✦ button
     on a phone) asks Combat ▸ Powers to use what's in your third slot, aimed where your
     crosshair is. The orb right of your energy bar shows it: its symbol, its cooldown
     wiping down, the seconds left, a throwable's charges. A class level-up gets a banner.

     EVERYONE (from the character attributes Combat ▸ Powers / Shields / Throwing publish):
       an imbue's flames (or frost, venom, light…) on the weapon in hand · a buff's aura ·
       a stealthy character fades (yours to a ghost, theirs nearly gone) · a familiar at the
       shoulder · poison and roots · a shield raised in front while they block (ShieldGrip
       IdleC0 / BlockC0) · and from PowerFX / ThrowFX: circles on the ground (fire, frost,
       smoke, a dome, a gravity well, a rain of arrows), dashes, slams, decoys, and every
       thrown thing in flight. Colours come from the power's look and its skin (MagicFX.lookOf). ]]

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

local player = Players.LocalPlayer
local remote = ReplicatedStorage:WaitForChild("PowerRemote", 60)
local round = ReplicatedStorage:WaitForChild("Round")
local WHITE = Color3.new(1, 1, 1)
local TEX = {spark = "rbxasset://textures/particles/sparkles_main.dds", fire = "rbxasset://textures/particles/fire_main.dds", smoke = "rbxasset://textures/particles/smoke_main.dds"}
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
local function emitter(parent, c1, c2, o)
	o = o or {}
	local e = Instance.new("ParticleEmitter")
	e.Texture = o.texture or TEX.spark
	e.Color = ColorSequence.new(c1, c2 or c1)
	e.LightEmission = o.light or 0.8
	e.Size = NumberSequence.new({NumberSequenceKeypoint.new(0, o.size or 0.4), NumberSequenceKeypoint.new(1, 0)})
	e.Transparency = NumberSequence.new({NumberSequenceKeypoint.new(0, o.alpha or 0.15), NumberSequenceKeypoint.new(1, 1)})
	e.Lifetime = NumberRange.new(o.life or 0.5, (o.life or 0.5) * 1.6)
	e.Speed = NumberRange.new(o.speed or 2, (o.speed or 2) * 1.8)
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
--  THE ORB (your third slot)
--------------------------------------------------------------------
local gui = Instance.new("ScreenGui")
gui.Name = "PowerHUD"
gui.ResetOnSpawn = false
gui.DisplayOrder = 11
gui.IgnoreGuiInset = false
gui.Parent = player:WaitForChild("PlayerGui")

local orb = Instance.new("Frame")
orb.AnchorPoint = Vector2.new(0, 1)
orb.Position = UDim2.new(0.5, 352, 1, -96)
orb.Size = UDim2.fromOffset(64, 64)
orb.BackgroundColor3 = Color3.fromRGB(18, 20, 30)
orb.BackgroundTransparency = 0.2
orb.Visible = false
orb.Parent = gui
Instance.new("UICorner", orb).CornerRadius = UDim.new(1, 0)
local ring = Instance.new("UIStroke", orb); ring.Thickness = 3; ring.Color = Theme.ACCENT
local glyph = Instance.new("TextLabel")
glyph.BackgroundTransparency = 1; glyph.Size = UDim2.fromScale(1, 1); glyph.Font = Theme.FONT_TITLE; glyph.TextSize = 30
glyph.TextColor3 = WHITE; glyph.Text = "✨"; glyph.ZIndex = 2
glyph.Parent = orb
local wipe = Instance.new("Frame")
wipe.AnchorPoint = Vector2.new(0, 1); wipe.Position = UDim2.fromScale(0, 1); wipe.Size = UDim2.fromScale(1, 0)
wipe.BackgroundColor3 = Color3.new(0, 0, 0); wipe.BackgroundTransparency = 0.35; wipe.BorderSizePixel = 0; wipe.ZIndex = 3
wipe.Parent = orb
Instance.new("UICorner", wipe).CornerRadius = UDim.new(1, 0)
local secs = Instance.new("TextLabel")
secs.BackgroundTransparency = 1; secs.Size = UDim2.fromScale(1, 1); secs.Font = Theme.FONT_TITLE; secs.TextSize = 24
secs.TextColor3 = WHITE; secs.TextStrokeTransparency = 0.3; secs.ZIndex = 4; secs.Text = ""
secs.Parent = orb
local keyTag = Instance.new("TextLabel")
keyTag.AnchorPoint = Vector2.new(0.5, 0.5); keyTag.Position = UDim2.new(1, -6, 1, -6); keyTag.Size = UDim2.fromOffset(24, 20)
keyTag.BackgroundColor3 = Color3.fromRGB(30, 34, 50); keyTag.Font = Theme.FONT_TITLE; keyTag.TextSize = 13; keyTag.TextColor3 = WHITE; keyTag.ZIndex = 5
keyTag.Parent = orb
Instance.new("UICorner", keyTag).CornerRadius = UDim.new(0, 5)
local nameTag = Instance.new("TextLabel")
nameTag.AnchorPoint = Vector2.new(0.5, 0); nameTag.Position = UDim2.new(0.5, 0, 1, 2); nameTag.Size = UDim2.fromOffset(140, 16)
nameTag.BackgroundTransparency = 1; nameTag.Font = Theme.FONT; nameTag.TextSize = 12; nameTag.TextColor3 = Color3.fromRGB(220, 220, 230)
nameTag.TextStrokeTransparency = 0.4; nameTag.Parent = orb
local pips = Instance.new("Frame")
pips.AnchorPoint = Vector2.new(0.5, 1); pips.Position = UDim2.new(0.5, 0, 0, -3); pips.Size = UDim2.fromOffset(60, 8); pips.BackgroundTransparency = 1
pips.Parent = orb
do local l = Instance.new("UIListLayout", pips); l.FillDirection = Enum.FillDirection.Horizontal; l.HorizontalAlignment = Enum.HorizontalAlignment.Center; l.Padding = UDim.new(0, 4) end
local pipList = {}

-- a phone's button (the orb itself is the button)
local tap = Instance.new("TextButton")
tap.BackgroundTransparency = 1; tap.Size = UDim2.fromScale(1, 1); tap.Text = ""; tap.ZIndex = 6
tap.Parent = orb

local function keyName()
	local k = ClientSettings.get and ClientSettings.get("Key_Power") or "E"
	return tostring(k or "E")
end

-- where you're aiming: what the middle of the screen looks at
local function aimPoint()
	local cam = workspace.CurrentCamera
	if not cam then return nil end
	local ray = cam:ViewportPointToRay(cam.ViewportSize.X / 2, cam.ViewportSize.Y / 2)
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	params.FilterDescendantsInstances = {player.Character, fxFolder}
	local hit = workspace:Raycast(ray.Origin, ray.Direction * 300, params)
	return hit and hit.Position or (ray.Origin + ray.Direction * 300)
end
local function menuUp()
	local h = player.PlayerGui:FindFirstChild("HubMenu")
	return h ~= nil and h.Enabled and _G.HubMenuOpen and _G.HubMenuOpen()
end
local lastAsk = 0
local deniedUntil = 0   -- (a refusal shows under the orb a moment)
local function use()
	local c = player.Character
	if not c or not (c:GetAttribute("Power") or c:GetAttribute("Throwable")) then return end
	if round:GetAttribute("Mode") == "Hub" then return end
	if os.clock() - lastAsk < 0.18 then return end
	lastAsk = os.clock()
	if remote then remote:FireServer("Use", aimPoint()) end
	-- a little punch on the orb
	local s = orb:FindFirstChildOfClass("UIScale") or Instance.new("UIScale", orb)
	s.Scale = 0.85
	TweenService:Create(s, TweenInfo.new(0.2, Enum.EasingStyle.Back), {Scale = 1}):Play()
end
tap.Activated:Connect(use)
UserInputService.InputBegan:Connect(function(input, processed)
	if processed or UserInputService:GetFocusedTextBox() or menuUp() then return end
	local k = keyName()
	local ok, code = pcall(function() return Enum.KeyCode[k] end)
	if ok and input.KeyCode == code then use() end
end)
TouchInput.changed:Connect(function(action, down) if action == "Power" and down then use() end end)
if remote then
	remote.OnClientEvent:Connect(function(what, why)
		if what == "Denied" and why and why ~= "" then
			nameTag.Text = why
			nameTag.TextColor3 = Color3.fromRGB(255, 150, 140)
			deniedUntil = os.clock() + 1.6
		end
	end)
end

RunService.RenderStepped:Connect(function()
	local c = player.Character
	local power = c and c:GetAttribute("Power")
	local thr = c and c:GetAttribute("Throwable")
	local hub = round:GetAttribute("Mode") == "Hub"
	orb.Visible = (power ~= nil or thr ~= nil) and not hub
	if not orb.Visible then return end
	keyTag.Text = UserInputService.GamepadEnabled and not UserInputService.KeyboardEnabled and "↑" or keyName()
	keyTag.Visible = not TouchInput.active()
	local t = snow()
	if power then
		local pw = Catalog.POWER[power]
		local col = look(c:GetAttribute("PowerSpell"), c:GetAttribute("PowerSkin"))
		glyph.Text = pw and pw.glyph or "✨"
		ring.Color = col
		local readyAt, cd = c:GetAttribute("PowerReadyAt") or 0, c:GetAttribute("PowerCD") or 1
		local left = readyAt - t
		wipe.Size = UDim2.fromScale(1, math.clamp(left / math.max(cd, 0.1), 0, 1))
		secs.Text = left > 0 and tostring(math.ceil(left)) or ""
		if os.clock() > deniedUntil then nameTag.Text = pw and string.upper(pw.name) or ""; nameTag.TextColor3 = Color3.fromRGB(220, 220, 230) end
		for _, p in ipairs(pipList) do p:Destroy() end
		pipList = {}
		local ench, n = c:GetAttribute("ArrowEnchant"), c:GetAttribute("ArrowLeft")
		if ench and n then
			for i = 1, n do
				local p = Instance.new("Frame"); p.Size = UDim2.fromOffset(8, 8); p.BackgroundColor3 = col; p.BorderSizePixel = 0; p.LayoutOrder = i; p.Parent = pips
				Instance.new("UICorner", p).CornerRadius = UDim.new(1, 0)
				table.insert(pipList, p)
			end
		end
	else
		local def = Catalog.WEAPON[thr]
		local n, max = c:GetAttribute("ThrowCharges") or 0, c:GetAttribute("ThrowMax") or 1
		local GLYPH = {blade = "🗡", axe = "🪓", spear = "🔱", dart = "🎯", flask = "🧪", bomb = "💣", bolas = "🪢"}
		glyph.Text = def and GLYPH[def.look] or "✨"
		ring.Color = n > 0 and Theme.ACCENT or Color3.fromRGB(120, 120, 130)
		local nextAt = c:GetAttribute("ThrowNextAt")
		local left = nextAt and (nextAt - t) or 0
		wipe.Size = UDim2.fromScale(1, n > 0 and 0 or math.clamp(left / math.max(def and def.recharge or 15, 1), 0, 1))
		secs.Text = (n == 0 and left > 0) and tostring(math.ceil(left)) or ""
		if os.clock() > deniedUntil then nameTag.Text = def and string.upper(def.name) or ""; nameTag.TextColor3 = Color3.fromRGB(220, 220, 230) end
		if #pipList ~= max then
			for _, p in ipairs(pipList) do p:Destroy() end
			pipList = {}
			for i = 1, max do
				local p = Instance.new("Frame"); p.Size = UDim2.fromOffset(8, 8); p.BorderSizePixel = 0; p.LayoutOrder = i; p.Parent = pips
				Instance.new("UICorner", p).CornerRadius = UDim.new(1, 0)
				table.insert(pipList, p)
			end
		end
		for i, p in ipairs(pipList) do p.BackgroundColor3 = i <= n and Theme.ACCENT or Color3.fromRGB(60, 60, 70) end
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
local AURA = {
	stone = {texture = TEX.smoke, size = 0.8, rate = 14, speed = 1, life = 0.9, alpha = 0.55, light = 0},
	holy = {size = 0.35, rate = 30, speed = 2.5, life = 0.8},
	wind = {size = 0.25, rate = 40, speed = 9, life = 0.4, spread = 30},
	night = {texture = TEX.smoke, size = 1.4, rate = 20, speed = 1.5, life = 1.2, alpha = 0.45, light = 0},
	tempest = {size = 0.5, rate = 45, speed = 6, life = 0.35},
	avatar = {size = 0.5, rate = 50, speed = 3, life = 0.9},
	arcane = {size = 0.35, rate = 30, speed = 2, life = 0.8},
	glow = {size = 0.3, rate = 20, speed = 2, life = 0.7},
}
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
				local e = emitter(p, col, glow, {texture = fire and TEX.fire or TEX.spark, size = fire and 0.55 or 0.3, rate = fire and 40 or 30, speed = 1.5, life = 0.45,
					accel = Vector3.new(0, fire and 4 or 1, 0), box = true, light = 1})
				local l = Instance.new("PointLight"); l.Color = col; l.Range = 9; l.Brightness = 1.6; l.Parent = p
				table.insert(L.imbue, e); table.insert(L.imbue, l)
			end
		end
	end
	-- the aura of a buff
	local au = (c:GetAttribute("AuraUntil") or 0) > t and c:GetAttribute("Aura") or nil
	local auKey = au and (au .. tostring(c:GetAttribute("AuraSkin"))) or nil
	if auKey ~= L.auKey then
		clearKey(L, "aura")
		L.auKey = auKey
		local root = c:FindFirstChild("HumanoidRootPart")
		if auKey and root then
			local col, glow, Lk = look(c:GetAttribute("AuraSpell"), c:GetAttribute("AuraSkin"))
			local o = table.clone(AURA[au] or AURA.glow)
			o.box = true
			local a = Instance.new("Attachment"); a.Name = "PowerAura"; a.Parent = root
			local e = emitter(root, col, glow, o)
			local l = Instance.new("PointLight"); l.Color = col; l.Range = 12; l.Brightness = au == "night" and 0 or 1.2; l.Parent = root
			L.aura = {a, e, l}
			if au == "avatar" or (Lk and Lk.wings) then for _, w in ipairs(wings(c, col, glow, Lk and Lk.wings or 2)) do table.insert(L.aura, w) end end
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
	-- poison (green bubbles) and a root (vines at the feet)
	local function status(key, on, make)
		if on and not L[key] then L[key] = make() elseif not on and L[key] then for _, x in ipairs(L[key]) do x:Destroy() end; L[key] = nil end
	end
	local root = c:FindFirstChild("HumanoidRootPart")
	if root then
		status("poison", c:GetAttribute("Poisoned") == true, function()
			return {emitter(root, Color3.fromRGB(110, 220, 70), Color3.fromRGB(200, 255, 150), {size = 0.35, rate = 16, speed = 1.5, life = 0.8, accel = Vector3.new(0, 3, 0), box = true})}
		end)
		status("snare", c:GetAttribute("Snared") == true, function()
			local out = {}
			for k = 1, 6 do
				local a = k / 6 * math.pi * 2
				local v = part({Name = "Vine", Size = Vector3.new(0.25, 2.4, 0.25), Material = Enum.Material.Grass, Color = Color3.fromRGB(60, 130, 50),
					CFrame = root.CFrame * CFrame.new(math.cos(a) * 1.1, -2.2, math.sin(a) * 1.1) * CFrame.Angles(math.cos(a) * 0.5, 0, math.sin(a) * 0.5)})
				table.insert(out, v)
			end
			return out
		end)
	end
	-- a shield up while they block
	local sm = c:FindFirstChild("ShieldModel")
	local grip = sm and sm.PrimaryPart and sm.PrimaryPart:FindFirstChild("ShieldGrip")
	if grip then
		local idle, block = grip:GetAttribute("IdleC0"), grip:GetAttribute("BlockC0")
		if typeof(idle) == "CFrame" and typeof(block) == "CFrame" then
			local want = c:GetAttribute("Blocking") and 1 or 0
			L.raise = (L.raise or 0) + (want - (L.raise or 0)) * 0.35
			grip.C0 = idle:Lerp(block, L.raise)
		end
	end
end

RunService.RenderStepped:Connect(function()
	local me = player.Character
	for _, p in ipairs(Players:GetPlayers()) do
		local c = p.Character
		if c then local ok, err = pcall(drawOn, c, c == me); if not ok then warn("[Powers.client]", err) end end
	end
	for c, L in pairs(looks) do
		if not c.Parent then
			for _, k in ipairs({"imbue", "aura", "poison", "snare"}) do clearKey(L, k) end
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
local SPIN = {blade = 22, axe = 14, flask = 8, bomb = 6, bolas = 18}
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
	tfx.OnClientEvent:Connect(function(what, id, a, b, c, d, e)
		if what == "Throw" then
			-- (id, origin, velocity, gravity, weaponId, skin)
			local def = Catalog.WEAPON[d]
			local m = displayOf(d, e)
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
			flying[id] = {m = m, pos = a, vel = b, g = c, look = def and def.look or "blade", t0 = os.clock(), spin = 0}
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
		if SPIN[f.look] then cf = CFrame.new(f.pos) * CFrame.lookAt(Vector3.zero, dir).Rotation * CFrame.Angles(-f.spin, 0, 0) * CFrame.Angles(math.rad(-90), 0, 0) end
		if f.m.Parent then f.m:PivotTo(cf) end
		if os.clock() - f.t0 > 7 then f.m:Destroy(); flying[id] = nil end
	end
end)
