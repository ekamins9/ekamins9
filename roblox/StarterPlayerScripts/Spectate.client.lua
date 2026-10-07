--[[ SPECTATE — dead in a match, watch the fight until you spawn. SPECTATE on
     the class screen (LoadoutMenu) hands the screen over; the camera follows a
     fighter who is still standing — your killer first, then teammates, then
     everyone else, bots last — from behind and above, easing after them and
     never through a wall. The bar at the bottom says who you're watching
     (name in their team's colour, class · weapon · kills, health) and has
     SPAWN (straight back in, as your chosen class) and CLASS (the class
     screen again).

       Q / E, ◀ / ▶      the previous / next fighter
       scroll            closer / further
       right mouse drag  look round them

     It ends when you spawn, when the round is over (the vote has the screen),
     or with CLASS. Talks to LoadoutMenu over _G.MenuBus:
       in: "Spectate", true      out: "SpectateStarted" · "SpectateEnd" · "SpawnNow"
     and sets _G.SpectateActive (HubMenu's cinematic camera holds off). ]]

local Players           = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService  = game:GetService("UserInputService")
local RunService        = game:GetService("RunService")
local TweenService      = game:GetService("TweenService")

local GameConfig = require(ReplicatedStorage:WaitForChild("GameConfig"))
local Theme = require(ReplicatedStorage:WaitForChild("Theme"))
local Catalog = require(ReplicatedStorage:WaitForChild("Catalog"))

local player    = Players.LocalPlayer
local roundNode = ReplicatedStorage:WaitForChild("Round")
local event     = ReplicatedStorage:WaitForChild("LoadoutEvent")
_G.MenuBus = _G.MenuBus or Instance.new("BindableEvent")
local bus = _G.MenuBus

local DIST, DIST_MIN, DIST_MAX = 10, 5, 20   -- studs behind the fighter (scroll changes it)
local SWITCH_AFTER_DEATH = 1.6               -- seconds you watch your fighter fall before moving on
local BIND = "Spectate"

--------------------------------------------------------------------
--  THE BAR
--------------------------------------------------------------------
local gui = Instance.new("ScreenGui")
gui.Name = "Spectate"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = true
gui.DisplayOrder = 1900   -- under the class screen (2000) and the vote (2100)
gui.Enabled = false
gui.Parent = player:WaitForChild("PlayerGui")

local function label(parent, text, size, font, color)
	local l = Instance.new("TextLabel")
	l.BackgroundTransparency = 1
	l.Font = font or Theme.FONT
	l.TextSize = size
	l.TextColor3 = color or Theme.TEXT
	l.Text = text
	l.TextXAlignment = Enum.TextXAlignment.Left
	l.Parent = parent
	return l
end
local function button(parent, text, size, color)
	local b = Instance.new("TextButton")
	b.BackgroundColor3 = color
	b.BorderSizePixel = 0
	b.AutoButtonColor = true
	b.Font = Theme.FONT
	b.TextSize = size
	b.TextColor3 = Theme.textOn(color)
	b.Text = text
	b.Parent = parent
	Instance.new("UICorner", b).CornerRadius = UDim.new(0, 8)
	return b
end

local tag = label(gui, "SPECTATING", 14, Theme.FONT_TITLE, Theme.ACCENT)
tag.AnchorPoint = Vector2.new(0.5, 1)
tag.Position = UDim2.new(0.5, 0, 1, -128)
tag.Size = UDim2.fromOffset(300, 18)
tag.TextXAlignment = Enum.TextXAlignment.Center
tag.TextStrokeTransparency = 0.5

local bar = Instance.new("Frame")
bar.AnchorPoint = Vector2.new(0.5, 1)
bar.Position = UDim2.new(0.5, 0, 1, -26)
bar.Size = UDim2.fromOffset(720, 96)
bar.BackgroundColor3 = Theme.PANEL
bar.BackgroundTransparency = 0.12
bar.BorderSizePixel = 0
bar.Parent = gui
Instance.new("UICorner", bar).CornerRadius = UDim.new(0, 12)
local barStroke = Instance.new("UIStroke", bar)
barStroke.Color = Theme.ACCENT
barStroke.Transparency = 0.55
local sizeCap = Instance.new("UISizeConstraint", bar)
sizeCap.MaxSize = Vector2.new(720, 96)

local prevBtn = button(bar, "◀", 22, Theme.CARD)
prevBtn.Position = UDim2.fromOffset(12, 18)
prevBtn.Size = UDim2.fromOffset(44, 60)
local nextBtn = button(bar, "▶", 22, Theme.CARD)
nextBtn.Position = UDim2.fromOffset(392, 18)
nextBtn.Size = UDim2.fromOffset(44, 60)

-- who you're watching
local nameL = label(bar, "", 22, Theme.FONT_TITLE, Theme.TEXT)
nameL.Position = UDim2.fromOffset(68, 12)
nameL.Size = UDim2.fromOffset(316, 26)
nameL.TextTruncate = Enum.TextTruncate.AtEnd
nameL.TextStrokeTransparency = 0.7
local subL = label(bar, "", 13, Theme.FONT_BODY, Theme.DIM)
subL.Position = UDim2.fromOffset(68, 40)
subL.Size = UDim2.fromOffset(316, 18)
subL.TextTruncate = Enum.TextTruncate.AtEnd
local hpBack = Instance.new("Frame")
hpBack.Position = UDim2.fromOffset(68, 64)
hpBack.Size = UDim2.fromOffset(316, 12)
hpBack.BackgroundColor3 = Color3.fromRGB(30, 30, 36)
hpBack.BorderSizePixel = 0
hpBack.Parent = bar
Instance.new("UICorner", hpBack).CornerRadius = UDim.new(1, 0)
local hpFill = Instance.new("Frame")
hpFill.Size = UDim2.fromScale(1, 1)
hpFill.BackgroundColor3 = Theme.BAD
hpFill.BorderSizePixel = 0
hpFill.Parent = hpBack
Instance.new("UICorner", hpFill).CornerRadius = UDim.new(1, 0)

-- back in
local spawnBtn = button(bar, "SPAWN", 18, Theme.GO_ON)
spawnBtn.Position = UDim2.fromOffset(452, 14)
spawnBtn.Size = UDim2.fromOffset(160, 44)
local classL = label(bar, "", 12, Theme.FONT_BODY, Theme.DIM)
classL.Position = UDim2.fromOffset(452, 62)
classL.Size = UDim2.fromOffset(160, 18)
classL.TextXAlignment = Enum.TextXAlignment.Center
local classBtn = button(bar, "CLASS", 15, Theme.CARD)
classBtn.Position = UDim2.fromOffset(622, 14)
classBtn.Size = UDim2.fromOffset(86, 44)

local hint = label(gui, "Q / E  switch   ·   scroll  zoom   ·   right mouse  look around", 12, Theme.FONT_BODY, Theme.DIM)
hint.AnchorPoint = Vector2.new(0.5, 1)
hint.Position = UDim2.new(0.5, 0, 1, -6)
hint.Size = UDim2.fromOffset(500, 16)
hint.TextXAlignment = Enum.TextXAlignment.Center
hint.TextStrokeTransparency = 0.6

--------------------------------------------------------------------
--  WHO THERE IS TO WATCH
--------------------------------------------------------------------
local active = false
local target = nil          -- the fighter's model
local targetDiedAt = nil
local dist = DIST
local camPos = nil
local yawOffset = 0         -- right mouse drag turns round the fighter
local mouseConn
local hiddenHud = nil       -- the HUD we put away (back when we stop)

local function standing(m)
	local h = m and m.Parent and m:FindFirstChildOfClass("Humanoid")
	return h ~= nil and h.Health > 0 and m:FindFirstChild("HumanoidRootPart") ~= nil
end

-- killer first (if they're standing), then teammates, then everyone else, bots last
local function fighters()
	local mates, others, bots = {}, {}, {}
	for _, p in ipairs(Players:GetPlayers()) do
		if p ~= player and standing(p.Character) then
			if player.Team and p.Team == player.Team then table.insert(mates, p.Character) else table.insert(others, p.Character) end
		end
	end
	local npcs = workspace:FindFirstChild("NPCs")
	for _, m in ipairs(npcs and npcs:GetChildren() or {}) do
		if m:IsA("Model") and m:GetAttribute("Bot") and standing(m) then table.insert(bots, m) end
	end
	local out = {}
	for _, l in ipairs({mates, others, bots}) do for _, m in ipairs(l) do table.insert(out, m) end end
	return out
end

local function killerOf()
	local c = player.Character
	local id = c and c:GetAttribute("LastHitBy")
	local p = id and Players:GetPlayerByUserId(id)
	return p and standing(p.Character) and p.Character or nil
end

local function step(dir)
	local list = fighters()
	if #list == 0 then target = nil; return end
	local i = table.find(list, target) or 0
	i = ((i - 1 + dir) % #list) + 1
	target, targetDiedAt, camPos, yawOffset = list[i], nil, nil, 0
end

--------------------------------------------------------------------
--  THE CARD
--------------------------------------------------------------------
local function classOf(m)
	local w = m:GetAttribute("ArmorType")
	for _, id in ipairs(GameConfig.CLASS_ORDER or {}) do
		local d = GameConfig.CLASSES[id]
		if d and d.weight == w then return d.name end
	end
	return w or ""
end
local function refreshCard()
	local m = target
	if not (m and m.Parent) then
		nameL.Text = "Nobody left standing"
		nameL.TextColor3 = Theme.DIM
		subL.Text = "waiting for the fight to go on"
		hpFill.Size = UDim2.fromScale(0, 1)
		return
	end
	local p = Players:GetPlayerFromCharacter(m)
	local color = Theme.TEXT
	if p and p.Team then color = p.Team.TeamColor.Color
	elseif m:GetAttribute("Team") and GameConfig.TEAMS[m:GetAttribute("Team")] then color = GameConfig.TEAMS[m:GetAttribute("Team")].rgb end
	nameL.Text = p and p.DisplayName or (m:GetAttribute("TagName") or m.Name)
	nameL.TextColor3 = color
	local bits = {}
	local cls = classOf(m)
	if cls ~= "" then table.insert(bits, cls) end
	local tool = m:FindFirstChildOfClass("Tool")
	if tool then table.insert(bits, (Catalog.WEAPON[tool.Name] and Catalog.WEAPON[tool.Name].name) or tool.Name) end
	local ls = p and p:FindFirstChild("leaderstats")
	local k = ls and ls:FindFirstChild("Kills")
	if k then table.insert(bits, k.Value .. (k.Value == 1 and " kill" or " kills")) end
	if p == nil then table.insert(bits, "bot") end
	subL.Text = table.concat(bits, "  ·  ")
	local h = m:FindFirstChildOfClass("Humanoid")
	local f = h and h.MaxHealth > 0 and math.clamp(h.Health / h.MaxHealth, 0, 1) or 0
	hpFill.Size = UDim2.fromScale(f, 1)
	hpFill.BackgroundColor3 = f > 0.5 and Theme.GOOD or (f > 0.25 and Color3.fromRGB(230, 170, 60) or Theme.BAD)
	-- the spawn button reads like the class screen's (a wave, the next round…)
	local cs = _G.ClassScreen
	spawnBtn.Text = cs and cs.spawnText() or "SPAWN"
	spawnBtn.BackgroundColor3 = spawnBtn.Text == "SPAWN" and Theme.GO_ON or Theme.GO
	classL.Text = cs and ("as " .. cs.className()) or ""
end

--------------------------------------------------------------------
--  THE CAMERA
--------------------------------------------------------------------
local wallRay = RaycastParams.new()
wallRay.FilterType = Enum.RaycastFilterType.Exclude
local function cameraStep(dt)
	if not active then return end
	local cam = workspace.CurrentCamera
	cam.CameraType = Enum.CameraType.Scriptable
	-- the fighter fell: watch a moment, then the next one
	if target and not standing(target) then
		targetDiedAt = targetDiedAt or os.clock()
		if os.clock() - targetDiedAt > SWITCH_AFTER_DEATH then step(1) end
	elseif not target then
		step(1)
	end
	local hrp = target and target.Parent and target:FindFirstChild("HumanoidRootPart")
	if not hrp then return end
	local look = hrp.CFrame.LookVector
	look = Vector3.new(look.X, 0, look.Z)
	if look.Magnitude < 0.1 then look = Vector3.new(0, 0, -1) end
	look = (CFrame.Angles(0, yawOffset, 0) * look.Unit)
	local focus = hrp.Position + Vector3.new(0, 2.4, 0)
	local want = focus - look * dist + Vector3.new(0, dist * 0.34, 0)
	-- never through a wall: stop short of whatever is between
	local ignore = {target}
	if player.Character then table.insert(ignore, player.Character) end
	local npcs = workspace:FindFirstChild("NPCs"); if npcs then table.insert(ignore, npcs) end
	local fx = workspace:FindFirstChild("LocalFX"); if fx then table.insert(ignore, fx) end
	wallRay.FilterDescendantsInstances = ignore
	local hit = workspace:Raycast(focus, want - focus, wallRay)
	if hit then want = hit.Position + (focus - hit.Position).Unit * 0.6 end
	camPos = camPos and camPos:Lerp(want, math.clamp(dt * 7, 0, 1)) or want
	cam.CFrame = CFrame.lookAt(camPos, focus)
	cam.FieldOfView = 70
end

--------------------------------------------------------------------
--  ON / OFF
--------------------------------------------------------------------
local function stop(tellMenu)
	if not active then return end
	active = false
	_G.SpectateActive = false
	gui.Enabled = false
	if hiddenHud and hiddenHud.Parent then hiddenHud.Enabled = true end
	hiddenHud = nil
	pcall(RunService.UnbindFromRenderStep, RunService, BIND)
	if mouseConn then mouseConn:Disconnect(); mouseConn = nil end
	local cam = workspace.CurrentCamera
	if cam then cam.CameraType = Enum.CameraType.Custom end
	target = nil
	if tellMenu then bus:Fire("SpectateEnd") end
end

local function dead()
	local c = player.Character
	local h = c and c:FindFirstChildOfClass("Humanoid")
	return not (h and h.Health > 0)
end

local function start()
	if active or not dead() or roundNode:GetAttribute("State") == "Intermission" then
		if not active then bus:Fire("SpectateEnd") end
		return
	end
	active = true
	_G.SpectateActive = true   -- the Hub menu's cinematic camera holds off while this is up
	gui.Enabled = true
	bus:Fire("SpectateStarted")
	-- the dead body's HUD (health, stamina, weapon chip) is put away while we watch
	local hud = player:FindFirstChild("PlayerGui") and player.PlayerGui:FindFirstChild("HUD")
	if hud and hud:IsA("ScreenGui") and hud.Enabled then hud.Enabled = false; hiddenHud = hud end
	dist, camPos, yawOffset, targetDiedAt = DIST, nil, 0, nil
	target = killerOf()
	if not target then step(1) end
	RunService:BindToRenderStep(BIND, Enum.RenderPriority.Last.Value, cameraStep)
	-- the pointer stays free for the bar
	mouseConn = RunService.RenderStepped:Connect(function()
		if not UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton2) then
			UserInputService.MouseBehavior = Enum.MouseBehavior.Default
		end
		UserInputService.MouseIconEnabled = true
	end)
	refreshCard()
end

prevBtn.Activated:Connect(function() step(-1); refreshCard() end)
nextBtn.Activated:Connect(function() step(1); refreshCard() end)
spawnBtn.Activated:Connect(function() bus:Fire("SpawnNow") end)
classBtn.Activated:Connect(function() stop(true) end)

UserInputService.InputBegan:Connect(function(input, gp)
	if not active or UserInputService:GetFocusedTextBox() then return end
	if input.KeyCode == Enum.KeyCode.Q or input.KeyCode == Enum.KeyCode.Left then step(-1); refreshCard()
	elseif input.KeyCode == Enum.KeyCode.E or input.KeyCode == Enum.KeyCode.Right then step(1); refreshCard()
	elseif input.UserInputType == Enum.UserInputType.MouseButton2 then
		UserInputService.MouseBehavior = Enum.MouseBehavior.LockCurrentPosition
	end
end)
UserInputService.InputChanged:Connect(function(input)
	if not active then return end
	if input.UserInputType == Enum.UserInputType.MouseWheel then
		dist = math.clamp(dist - input.Position.Z * 1.5, DIST_MIN, DIST_MAX)
	elseif input.UserInputType == Enum.UserInputType.MouseMovement and UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton2) then
		yawOffset -= input.Delta.X * 0.006
	end
end)

-- the card keeps up a few times a second
local acc = 0
RunService.Heartbeat:Connect(function(dt)
	if not active then return end
	acc += dt
	if acc >= 0.2 then acc = 0; refreshCard() end
end)

bus.Event:Connect(function(what, on)
	if what == "Spectate" then
		if on then start() else stop(false) end
	end
end)
-- back in the fight, or the round is over: the screen goes back
event.OnClientEvent:Connect(function(what)
	if what == "Spawned" then stop(false) end
end)
player.CharacterAdded:Connect(function(c)
	local h = c:WaitForChild("Humanoid", 5)
	if h and h.Health > 0 then stop(false) end
end)
roundNode:GetAttributeChangedSignal("State"):Connect(function()
	if roundNode:GetAttribute("State") == "Intermission" then stop(true) end
end)

-- debug: the Spectate flag on ReplicatedStorage.Debug (client tab) starts / stops it
task.spawn(function()
	local dbg = ReplicatedStorage:WaitForChild("Debug", 30)
	if not dbg then return end
	dbg:GetAttributeChangedSignal("Spectate"):Connect(function()
		if dbg:GetAttribute("Spectate") then start() else stop(true) end
	end)
end)
