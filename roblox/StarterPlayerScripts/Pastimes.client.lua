--[[ PASTIMES (client) — what you see of Economy ▸ Pastimes:
       • COMPANIONS: everyone's companion (player attribute "Companion") follows
         them, built locally from ReplicatedStorage ▸ Companions. SETTINGS ▸
         Companions: All / Mine / None.
       • THE GIFT CHIP (top left): the next playtime gift and its countdown;
         click it when it's ready.
       • THE HATCHERY: your own eggs sit in its nests (each player sees theirs),
         with a timer over each; walk up and press E to hatch a ready egg, or
         to open the HATCHERY screen. While you stand there a line says your
         eggs are hatching faster. ]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local Debris = game:GetService("Debris")

local Catalog = require(ReplicatedStorage:WaitForChild("Catalog"))
local Companions = require(ReplicatedStorage:WaitForChild("Companions"))
local ClientSettings = require(ReplicatedStorage:WaitForChild("ClientSettings"))
local Theme = require(ReplicatedStorage:WaitForChild("Theme"))
local UIFX = require(ReplicatedStorage:WaitForChild("UIFX"))

local player = Players.LocalPlayer
local hubRemote = ReplicatedStorage:WaitForChild("HubRemote")
_G.MenuBus = _G.MenuBus or Instance.new("BindableEvent")

local RARITY = {Common = Color3.fromRGB(120, 134, 152), Rare = Color3.fromRGB(56, 140, 255), Epic = Color3.fromRGB(170, 80, 240), Legendary = Color3.fromRGB(255, 176, 40), Mythic = Color3.fromRGB(255, 52, 78)}

local function call(op, ...)
	local ok, res = pcall(hubRemote.InvokeServer, hubRemote, op, ...)
	if ok and type(res) == "table" then return res end
	return {ok = false, msg = ok and "no answer" or tostring(res)}
end
local function clock(sec)
	sec = math.max(0, math.floor(sec))
	local h, m, s = math.floor(sec / 3600), math.floor(sec % 3600 / 60), sec % 60
	if h > 0 then return string.format("%d:%02d:%02d", h, m, s) end
	return string.format("%d:%02d", m, s)
end
local function menuOpen()
	local m = player.PlayerGui:FindFirstChild("HubMenu")
	return m ~= nil and m.Enabled
end

local fx = Instance.new("Folder")
fx.Name = "LocalCompanions"
fx.Parent = workspace

--------------------------------------------------------------------
--  COMPANIONS
--------------------------------------------------------------------
local followers = {}     -- [player] = {rig, id, stars, pos, yaw, groundY, rayAt}
local rayParams = RaycastParams.new()
rayParams.FilterType = Enum.RaycastFilterType.Exclude
rayParams.IgnoreWater = true

local function wanted(plr)
	local id = plr:GetAttribute("Companion")
	if type(id) ~= "string" or id == "" or not Catalog.COMPANION[id] then return nil end
	local s = ClientSettings.get("Companions") or "All"
	if s == "None" or (s == "Mine" and plr ~= player) then return nil end
	return id
end

local function drop(plr)
	local f = followers[plr]
	if f then f.rig.model:Destroy(); followers[plr] = nil end
end

local function lerpAngle(a, b, k)
	local d = (b - a + math.pi) % (2 * math.pi) - math.pi
	return a + d * k
end

Players.PlayerRemoving:Connect(drop)

RunService.RenderStepped:Connect(function(dt)
	dt = math.min(dt, 0.1)
	local now = os.clock()
	local cam = workspace.CurrentCamera
	local camPos = cam and cam.CFrame.Position or Vector3.zero
	local exclude = {fx}
	for _, plr in ipairs(Players:GetPlayers()) do if plr.Character then table.insert(exclude, plr.Character) end end
	rayParams.FilterDescendantsInstances = exclude
	for _, plr in ipairs(Players:GetPlayers()) do
		local id = wanted(plr)
		local char = plr.Character
		local hrp = char and char:FindFirstChild("HumanoidRootPart")
		local hum = char and char:FindFirstChildOfClass("Humanoid")
		local f = followers[plr]
		local stars = plr:GetAttribute("CompanionStars") or 0
		local variant = plr:GetAttribute("CompanionVariant") or ""
		if not (id and hrp and hum and hum.Health > 0) then
			if f then drop(plr) end
		else
			if f and (f.id ~= id or f.stars ~= stars or f.variant ~= variant) then drop(plr); f = nil end
			if not f then
				local rig = Companions.build(id, {world = true, stars = stars, variant = variant ~= "" and variant or nil})
				if rig then
					rig.model.Parent = fx
					local start = (hrp.CFrame * CFrame.new(2.6, 0, 2.2)).Position
					f = {rig = rig, id = id, stars = stars, variant = variant, pos = start, yaw = 0, groundY = hrp.Position.Y - 3, rayAt = 0}
					followers[plr] = f
				end
			end
			if f then
				local far = (hrp.Position - camPos).Magnitude > 160
				f.rig.model.Parent = far and nil or fx
				if not far then
					local rig = f.rig
					local hcf = hrp.CFrame
					local flat = Vector3.new(hcf.LookVector.X, 0, hcf.LookVector.Z)
					local yaw = flat.Magnitude > 0.01 and math.atan2(-flat.X, -flat.Z) or f.yaw
					-- beside and a little behind you, on the right
					local target = (CFrame.new(hrp.Position) * CFrame.Angles(0, yaw, 0) * CFrame.new(2.7, 0, 2.3)).Position
					if rig.flying then
						target = Vector3.new(target.X, hrp.Position.Y + 0.9, target.Z)
					else
						if now - f.rayAt > 0.1 then
							f.rayAt = now
							local hit = workspace:Raycast(target + Vector3.new(0, 4, 0), Vector3.new(0, -14, 0), rayParams)
							f.groundY = hit and hit.Position.Y or (hrp.Position.Y - 3)
						end
						target = Vector3.new(target.X, f.groundY + rig.foot, target.Z)
					end
					if (f.pos - target).Magnitude > 40 then f.pos = target end
					local k = 1 - math.exp(-dt * (rig.flying and 4.5 or 6.5))
					local nextPos = f.pos:Lerp(target, k)
					local v = (nextPos - f.pos) / math.max(dt, 1e-3)
					f.pos = nextPos
					local speed = Vector3.new(v.X, 0, v.Z).Magnitude
					local wantYaw = speed > 1.2 and math.atan2(-v.X, -v.Z) or yaw
					f.yaw = lerpAngle(f.yaw, wantYaw, 1 - math.exp(-dt * 8))
					Companions.pose(rig, CFrame.new(f.pos) * CFrame.Angles(0, f.yaw, 0), now, math.clamp(speed / 9, 0, 1))
				end
			end
		end
	end
end)

--------------------------------------------------------------------
--  THE GIFT CHIP
--------------------------------------------------------------------
local hud = Instance.new("ScreenGui")
hud.Name = "Pastimes"
hud.ResetOnSpawn = false
hud.DisplayOrder = 40
hud.Parent = player:WaitForChild("PlayerGui")

local chip = Instance.new("TextButton")
chip.Name = "GiftChip"
chip.AutoButtonColor = false
chip.Text = ""
chip.Position = UDim2.fromOffset(14, 10)
chip.Size = UDim2.fromOffset(212, 44)
chip.BackgroundColor3 = Theme.GLASS
chip.BackgroundTransparency = 0.15
chip.Parent = hud
Instance.new("UICorner", chip).CornerRadius = UDim.new(0, 12)
local chipStroke = Instance.new("UIStroke", chip); chipStroke.Color = Color3.new(1, 1, 1); chipStroke.Transparency = 0.8; chipStroke.Thickness = 1.5
local chipIcon = Instance.new("TextLabel")
chipIcon.BackgroundTransparency = 1; chipIcon.Size = UDim2.fromOffset(40, 44); chipIcon.Text = "🎁"; chipIcon.TextSize = 24; chipIcon.Font = Theme.FONT
chipIcon.Parent = chip
local chipTitle = Instance.new("TextLabel")
chipTitle.BackgroundTransparency = 1; chipTitle.Position = UDim2.fromOffset(40, 4); chipTitle.Size = UDim2.new(1, -48, 0, 18)
chipTitle.Font = Theme.FONT_TITLE; chipTitle.TextSize = 15; chipTitle.TextColor3 = Color3.new(1, 1, 1); chipTitle.TextXAlignment = Enum.TextXAlignment.Left
chipTitle.Parent = chip
do local s = Instance.new("UIStroke", chipTitle); s.Color = Theme.OUTLINE; s.Thickness = 1.5 end
local barBack = Instance.new("Frame")
barBack.BackgroundColor3 = Color3.fromRGB(8, 10, 18); barBack.BackgroundTransparency = 0.2; barBack.BorderSizePixel = 0
barBack.Position = UDim2.fromOffset(40, 26); barBack.Size = UDim2.new(1, -50, 0, 10); barBack.Parent = chip
Instance.new("UICorner", barBack).CornerRadius = UDim.new(0, 5)
local bar = Instance.new("Frame")
bar.BackgroundColor3 = Theme.GREEN; bar.BorderSizePixel = 0; bar.Size = UDim2.fromScale(0, 1); bar.Parent = barBack
Instance.new("UICorner", bar).CornerRadius = UDim.new(0, 5)
local chipScale = Instance.new("UIScale", chip)

-- a line of news under the chip
local note = Instance.new("TextLabel")
note.BackgroundTransparency = 1; note.Position = UDim2.fromOffset(16, 58); note.Size = UDim2.fromOffset(420, 22)
note.Font = Theme.FONT_TITLE; note.TextSize = 15; note.TextColor3 = Color3.new(1, 1, 1); note.TextXAlignment = Enum.TextXAlignment.Left
note.Visible = false; note.Parent = hud
do local s = Instance.new("UIStroke", note); s.Color = Theme.OUTLINE; s.Thickness = 1.5 end
local noteAt = 0
local function say(text, color)
	note.Text = text; note.TextColor3 = color or Color3.new(1, 1, 1); note.Visible = true; noteAt = os.clock()
	task.delay(3.2, function() if os.clock() - noteAt >= 3.1 then note.Visible = false end end)
end

-- the Hatchery line (only while you stand by it)
local nestLine = Instance.new("TextLabel")
nestLine.BackgroundTransparency = 1; nestLine.Position = UDim2.fromOffset(16, 82); nestLine.Size = UDim2.fromOffset(520, 22)
nestLine.Font = Theme.FONT_TITLE; nestLine.TextSize = 15; nestLine.TextColor3 = Color3.fromRGB(255, 214, 120); nestLine.TextXAlignment = Enum.TextXAlignment.Left
nestLine.Visible = false; nestLine.Parent = hud
do local s = Instance.new("UIStroke", nestLine); s.Color = Theme.OUTLINE; s.Thickness = 1.5 end

local playAt, playBase = os.clock(), 0
local function syncPlay() playBase = player:GetAttribute("PlaySeconds") or 0; playAt = os.clock() end
player:GetAttributeChangedSignal("PlaySeconds"):Connect(syncPlay)
syncPlay()
local function claimedSet()
	local out = {}
	local s = player:GetAttribute("GiftsClaimed")
	if type(s) == "string" then for k in s:gmatch("[^,]+") do out[k] = true end end
	return out
end
-- the next gift: index, its gift, seconds left (<= 0 = ready)
local function nextGift()
	local played = playBase + math.min(20, os.clock() - playAt)
	local claimed = claimedSet()
	for i, g in ipairs(Catalog.GIFTS.gifts) do
		if not claimed[tostring(i)] then return i, g, g.minutes * 60 - played, played end
	end
	return nil
end
local function rewardName(r)
	if r.marks then return r.marks .. " Marks" end
	if r.crowns then return r.crowns .. " Crowns" end
	if r.egg and Catalog.EGG[r.egg] then return Catalog.EGG[r.egg].name end
	if r.crate and Catalog.CRATES[r.crate] then return "a free " .. Catalog.CRATES[r.crate].name end
	if r.companion and Catalog.COMPANION[r.companion] then return Catalog.COMPANION[r.companion].name end
	if r.emote and Catalog.EMOTE[r.emote] then return "the " .. Catalog.EMOTE[r.emote].name .. " emote" end
	if r.killfx and Catalog.KILLFX_BY[r.killfx] then return Catalog.KILLFX_BY[r.killfx].name end
	if r.title then return "the title " .. r.title end
	return "a gift"
end

local claiming = false
chip.MouseButton1Click:Connect(function()
	local i, g, left = nextGift()
	if not i then return end
	if left > 0 then say(string.format("Next: %s in %s of play", rewardName(g.reward), clock(left))); return end
	if claiming then return end
	claiming = true
	local r = call("GiftClaim", i)
	claiming = false
	say(r.msg or "", r.ok and Theme.GOOD or Theme.BAD)
	-- a crate in it: the spin, on the menu's crate screen
	if r.ok and r.crate and _G.HubCrateSpin then _G.HubCrateSpin(r.crate) end
	if r.ok and r.gifts then
		local list = {}
		for k in pairs(r.gifts.claimed or {}) do table.insert(list, k) end
		table.sort(list)
		player:SetAttribute("GiftsClaimed", table.concat(list, ","))   -- locally, until the server's next beat
	end
end)

--------------------------------------------------------------------
--  THE HATCHERY: your eggs in the nests
--------------------------------------------------------------------
local nestFolder = Instance.new("Folder")
nestFolder.Name = "LocalNests"
nestFolder.Parent = workspace
local nests = {}   -- [i] = {egg = id, readyAt, rig, gui, prompt, marker}

local function parseNests()
	local out = {}
	local s = player:GetAttribute("Nests")
	if type(s) ~= "string" then return out end
	local i = 0
	for part in (s .. ";"):gmatch("([^;]*);") do
		i += 1
		local id, at = part:match("^([^,]+),(%d+)$")
		if id and Catalog.EGG[id] then out[i] = {egg = id, readyAt = tonumber(at)} end
	end
	return out
end

local hatching = {}
-- the Hatchery model (looked up once a second, not every frame)
local hatchModel = nil
task.spawn(function()
	while true do
		if not (hatchModel and hatchModel.Parent) then hatchModel = workspace:FindFirstChild("Hatchery", true) end
		task.wait(1)
	end
end)
local function popCompanion(at, res)
	-- the shell bursts, a flash, and the newcomer jumps out
	local shell = Catalog.EGG[res.egg] and Catalog.EGG[res.egg].shell or Color3.new(1, 1, 1)
	for k = 1, 10 do
		local p = Instance.new("Part")
		p.Size = Vector3.new(0.35, 0.35, 0.12); p.Color = shell; p.Material = Enum.Material.SmoothPlastic
		p.CanCollide, p.CanQuery, p.CanTouch = false, false, false
		p.CFrame = CFrame.new(at.Position + Vector3.new(0, 0.9, 0)) * CFrame.Angles(math.random() * 6, math.random() * 6, math.random() * 6)
		p.AssemblyLinearVelocity = Vector3.new(math.random(-8, 8), math.random(10, 18), math.random(-8, 8))
		p.AssemblyAngularVelocity = Vector3.new(math.random(-12, 12), math.random(-12, 12), math.random(-12, 12))
		p.Parent = nestFolder
		Debris:AddItem(p, 1.6)
	end
	local flash = Instance.new("Part")
	flash.Shape = Enum.PartType.Ball; flash.Anchored = true; flash.CanCollide, flash.CanQuery, flash.CanTouch = false, false, false
	flash.Material = Enum.Material.Neon; flash.Color = RARITY[res.rarity] or Color3.new(1, 1, 1)
	flash.Size = Vector3.new(1, 1, 1); flash.CFrame = CFrame.new(at.Position + Vector3.new(0, 1, 0)); flash.Parent = nestFolder
	TweenService:Create(flash, TweenInfo.new(0.5), {Size = Vector3.new(7, 7, 7), Transparency = 1}):Play()
	Debris:AddItem(flash, 0.6)
	local rig = Companions.build(res.id, {world = true, stars = res.stars, variant = res.variant})
	if not rig then return end
	rig.model.Parent = nestFolder
	local bb = Instance.new("BillboardGui")
	bb.Size = UDim2.fromOffset(260, 60); bb.StudsOffsetWorldSpace = Vector3.new(0, 3.2, 0); bb.AlwaysOnTop = true; bb.Adornee = rig.root; bb.Parent = rig.model
	local t = Instance.new("TextLabel")
	t.BackgroundTransparency = 1; t.Size = UDim2.fromScale(1, 1); t.Font = Theme.FONT_TITLE; t.TextScaled = true
	t.TextColor3 = RARITY[res.rarity] or Color3.new(1, 1, 1)
	t.Text = string.upper(res.rarity) .. "!  " .. res.name .. (res.dup and ("  ★" .. tostring(res.stars or 1)) or "")
	t.Parent = bb
	do local s = Instance.new("UIStroke", t); s.Color = Theme.OUTLINE; s.Thickness = 2 end
	local t0 = os.clock()
	local conn
	conn = RunService.RenderStepped:Connect(function()
		local a = os.clock() - t0
		if a > 2.6 or not rig.model.Parent then conn:Disconnect(); rig.model:Destroy(); return end
		local up = math.min(1, a / 0.35)
		local y = 0.9 + math.sin(up * math.pi) * 1.6 + up * 0.6
		Companions.pose(rig, at * CFrame.new(0, y, 0) * CFrame.Angles(0, a * 2, 0), os.clock(), 0.2)
	end)
end

local function hatchAt(i)
	if hatching[i] then return end
	local n = nests[i]
	if not n or not n.marker then return end
	hatching[i] = true
	-- the roll first (so a refusal doesn't crack an egg for nothing), then the show:
	-- it rocks, cracks three times (harder each time), and bursts
	local r = call("Hatch", i)
	if not r.ok or not r.result then hatching[i] = nil; say(r.msg or "couldn't hatch", Theme.BAD); return end
	local res = r.result
	local base = n.marker.CFrame * CFrame.new(0, -0.25, 0)
	local function rock(dur, hard)
		local t0 = os.clock()
		while os.clock() - t0 < dur do
			if n.rig then Companions.poseEgg(n.rig, base, os.clock() * 2.5, hard) end
			RunService.RenderStepped:Wait()
		end
	end
	rock(0.35, 0.3)
	for k = 1, 3 do
		UIFX.play("EggCrack", {Speed = 1 + k * 0.08})
		rock(0.42 - k * 0.05, 0.45 + k * 0.25)
	end
	rock(0.3, 1.3)
	hatching[i] = nil
	-- the burst: shell bits fly, a flash of the rarity's colour
	local col = RARITY[res.rarity] or Color3.new(1, 1, 1)
	local at = Instance.new("Part")
	at.Anchored, at.CanCollide, at.CanQuery, at.CanTouch, at.Transparency = true, false, false, false, 1
	at.Size = Vector3.new(0.2, 0.2, 0.2); at.CFrame = n.marker.CFrame * CFrame.new(0, 0.6, 0); at.Parent = workspace
	local bits = Instance.new("ParticleEmitter")
	bits.Color = ColorSequence.new(Color3.fromRGB(250, 244, 226)); bits.Size = NumberSequence.new(0.35, 0.05)
	bits.Lifetime = NumberRange.new(0.5, 0.9); bits.Speed = NumberRange.new(8, 16); bits.SpreadAngle = Vector2.new(180, 180)
	bits.Acceleration = Vector3.new(0, -40, 0); bits.Rotation = NumberRange.new(0, 360); bits.RotSpeed = NumberRange.new(-300, 300)
	bits.Rate = 0; bits.Parent = at
	bits:Emit(26)
	local glow = Instance.new("PointLight"); glow.Color = col; glow.Range = 14; glow.Brightness = 6; glow.Parent = at
	TweenService:Create(glow, TweenInfo.new(0.9), {Brightness = 0}):Play()
	Debris:AddItem(at, 1.5)
	UIFX.play("EggBurst"); UIFX.play("Shells")
	task.delay(0.15, function() UIFX.reveal(res.rarity) end)
	if n.rig then n.rig.model:Destroy(); n.rig = nil end
	popCompanion(n.marker.CFrame, res)
	local line = res.dup and ((res.refund or 0) > 0 and string.format("%s again: +%d Marks", res.name, res.refund) or string.format("%s again: ★%d", res.name, res.stars or 1))
		or string.format("New companion: %s (%s)!", res.name, res.rarity)
	say(line, RARITY[res.rarity])
end

local function nestGui(i, marker)
	local bb = Instance.new("BillboardGui")
	bb.Name = "NestTimer" .. i
	bb.Size = UDim2.fromOffset(170, 46); bb.StudsOffsetWorldSpace = Vector3.new(0, 3.4, 0); bb.MaxDistance = 70; bb.Adornee = marker
	bb.Parent = nestFolder
	local a = Instance.new("TextLabel")
	a.Name = "Top"; a.BackgroundTransparency = 1; a.Size = UDim2.new(1, 0, 0, 20); a.Font = Theme.FONT_TITLE; a.TextSize = 16; a.TextColor3 = Color3.new(1, 1, 1)
	a.Parent = bb
	do local s = Instance.new("UIStroke", a); s.Color = Theme.OUTLINE; s.Thickness = 1.6 end
	local b = Instance.new("TextLabel")
	b.Name = "Bottom"; b.BackgroundTransparency = 1; b.Position = UDim2.fromOffset(0, 22); b.Size = UDim2.new(1, 0, 0, 22); b.Font = Theme.FONT_TITLE; b.TextSize = 20; b.TextColor3 = Color3.fromRGB(255, 214, 120)
	b.Parent = bb
	do local s = Instance.new("UIStroke", b); s.Color = Theme.OUTLINE; s.Thickness = 1.8 end
	local prompt = Instance.new("ProximityPrompt")
	prompt.KeyboardKeyCode = Enum.KeyCode.E
	prompt.MaxActivationDistance = 9
	prompt.RequiresLineOfSight = false
	prompt.ObjectText = "Nest " .. i
	prompt.Parent = marker
	prompt.Triggered:Connect(function()
		local n = nests[i]
		if n and n.egg and n.readyAt and workspace:GetServerTimeNow() >= n.readyAt then hatchAt(i)
		else _G.MenuBus:Fire("OpenHub", "HATCHERY") end
	end)
	return bb, prompt
end

RunService.RenderStepped:Connect(function()
	-- the gift chip
	local hidden = menuOpen()
	chip.Visible = not hidden
	note.Visible = note.Visible and not hidden
	if not hidden then
		local i, g, left, played = nextGift()
		if not i then
			chipTitle.Text = "ALL GIFTS TODAY ✔"
			bar.Size = UDim2.fromScale(1, 1)
			bar.BackgroundColor3 = Theme.DIM
			chipStroke.Color = Color3.new(1, 1, 1); chipStroke.Transparency = 0.8
			chipScale.Scale = 1
		elseif left <= 0 then
			chipTitle.Text = "GIFT READY!  CLICK"
			bar.Size = UDim2.fromScale(1, 1)
			bar.BackgroundColor3 = Theme.GREEN
			chipStroke.Color = Theme.GREEN; chipStroke.Transparency = 0
			chipScale.Scale = 1 + 0.05 * math.sin(os.clock() * 6)
		else
			local prev = i > 1 and Catalog.GIFTS.gifts[i - 1].minutes * 60 or 0
			chipTitle.Text = "NEXT GIFT  " .. clock(left)
			bar.Size = UDim2.fromScale(math.clamp((played - prev) / math.max(1, g.minutes * 60 - prev), 0, 1), 1)
			bar.BackgroundColor3 = Theme.BLUE
			chipStroke.Color = Color3.new(1, 1, 1); chipStroke.Transparency = 0.8
			chipScale.Scale = 1
		end
	end
	-- the Hatchery
	local hatch = hatchModel and hatchModel.Parent and hatchModel or nil
	local now = workspace:GetServerTimeNow()
	local want = parseNests()
	for i = 1, Catalog.EGGS.nests do
		local marker = hatch and hatch:FindFirstChild("Nest" .. i)
		local n = nests[i]
		if not marker then
			if n then if n.rig then n.rig.model:Destroy() end; if n.gui then n.gui:Destroy() end; if n.prompt then n.prompt:Destroy() end; nests[i] = nil end
		else
			if not n or n.marker ~= marker then
				if n then if n.rig then n.rig.model:Destroy() end; if n.gui then n.gui:Destroy() end; if n.prompt then n.prompt:Destroy() end end
				n = {marker = marker}
				n.gui, n.prompt = nestGui(i, marker)
				nests[i] = n
			end
			local w = want[i]
			if (w and w.egg) ~= n.egg and not hatching[i] then
				if n.rig then n.rig.model:Destroy(); n.rig = nil end
				n.egg = w and w.egg or nil
				if n.egg then
					n.rig = Companions.egg(n.egg, {world = true})
					if n.rig then n.rig.model.Parent = nestFolder end
				end
			end
			n.readyAt = w and w.readyAt or nil
			local top, bottom = n.gui.Top, n.gui.Bottom
			if n.egg then
				local left = (n.readyAt or now) - now
				local e = Catalog.EGG[n.egg]
				top.Text = e.name
				top.TextColor3 = RARITY[e.rarity] or Color3.new(1, 1, 1)
				if left <= 0 then
					bottom.Text = "READY!  [E] HATCH"; bottom.TextColor3 = Theme.GREEN
					n.prompt.ActionText = "Hatch"
				else
					bottom.Text = clock(left); bottom.TextColor3 = Color3.fromRGB(255, 214, 120)
					n.prompt.ActionText = "Check on it"
				end
				if n.rig and not hatching[i] then
					local wob = left <= 0 and 0.8 or (left < (e.minutes * 60) * 0.1 and 0.25 or 0.05)
					Companions.poseEgg(n.rig, marker.CFrame * CFrame.new(0, -0.25, 0), os.clock() + i, wob)
				end
			else
				top.Text = "EMPTY NEST"; top.TextColor3 = Theme.DIM
				local eggs = player:GetAttribute("EggCount") or 0
				bottom.Text = eggs > 0 and string.format("[E] SET AN EGG (%d)", eggs) or "[E] GET EGGS"
				bottom.TextColor3 = Color3.new(1, 1, 1)
				n.prompt.ActionText = eggs > 0 and "Set an egg" or "Get eggs"
			end
		end
	end
	-- standing by it
	if player:GetAttribute("AtHatchery") then
		local bits = {}
		for i = 1, Catalog.EGGS.nests do
			local n = nests[i]
			if n and n.egg then table.insert(bits, ((n.readyAt or now) - now) <= 0 and "READY" or clock((n.readyAt or now) - now)) end
		end
		nestLine.Text = string.format("THE HATCHERY  ·  EGGS HATCH %d× FASTER HERE", Catalog.EGGS.boost or 2) .. (#bits > 0 and ("  ·  " .. table.concat(bits, "  ·  ")) or "")
		nestLine.Visible = not hidden
	else
		nestLine.Visible = false
	end
end)
