--[[ TOUCH CONTROLS — a phone or a tablet: the fight under the right thumb, few buttons, out of
     the way of the fight. Roblox's own stick under the left thumb moves you. Every button goes
     through ReplicatedStorage ▸ TouchInput, so it does exactly what its key does.

       right thumb (an arc round the corner):
         ATTACK     tap: a swing (the sides take turns) · SWIPE from it: ↑ an overhead,
                    ↓ a stab, ← → a swing from that side (arrows round it light up as you
                    swipe). With a bow or a crossbow it's simply held: draw, let go. With a
                    staff: held, a cast; swiped ↑ ↓, the spell before / after
         BLOCK      held
         DODGE      (the way you're moving)
         KICK       becomes FEINT while your own swing is coming; with a staff, MEDITATE
                    (held: mana back; a tap stops a cast)
         LOCK       lock onto the foe in front of you (ReplicatedStorage ▸ LockOn); swipe
                    across the screen while locked to move to the next one
         POWER / THROW   the orbs (Powers.client puts them in these two places on a touch
                    screen): tap the power, hold the throw to aim it, let go to throw
       left          SPRINT (on until you stop) and JUMP, above the stick
       top left      MENU, and ⋯ the rest: EMOTE, VIEW, CROUCH, SCORES, and with a staff
                    STAFF ⇄ (its melee self)
       anywhere else a drag turns the camera (the Touch look speed setting)

     Sized for the screen (ReplicatedStorage ▸ Device.touchScale, × the Touch button size
     setting). Shown only while you have a body and the menu is shut; Roblox's jump button is
     hidden (ours can't be hit by mistake). ]]

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local TouchInput = require(ReplicatedStorage:WaitForChild("TouchInput"))
local Device = require(ReplicatedStorage:WaitForChild("Device"))
local LockOn = require(ReplicatedStorage:WaitForChild("LockOn"))
local ClientSettings = require(ReplicatedStorage:WaitForChild("ClientSettings"))
local Theme = require(ReplicatedStorage:WaitForChild("Theme"))
local player = Players.LocalPlayer

local gui = Instance.new("ScreenGui")
gui.Name = "TouchControls"
gui.ResetOnSpawn = false
gui.DisplayOrder = 40
gui.Enabled = false
gui.Parent = player:WaitForChild("PlayerGui")
local scale = Instance.new("UIScale")
scale.Parent = gui

local WHITE = Color3.new(1, 1, 1)
local COL = {
	attack = Color3.fromRGB(205, 62, 54), block = Theme.BLUE, move = Color3.fromRGB(56, 64, 92),
	other = Color3.fromRGB(38, 44, 66), lock = Color3.fromRGB(150, 40, 40),
}

local function pad(anchor, pos, size)
	local f = Instance.new("Frame")
	f.BackgroundTransparency = 1
	f.AnchorPoint = anchor
	f.Position = pos
	f.Size = size
	f.Parent = gui
	return f
end
-- a round button centred (x, y) from its pad's bottom-right corner (x to the left, y up), d across
local function disc(parent, label, x, y, d, color, sub)
	local b = Instance.new("TextButton")
	b.Name = label
	b.AnchorPoint = Vector2.new(0.5, 0.5)
	b.Position = UDim2.new(1, -x, 1, -y)
	b.Size = UDim2.fromOffset(d, d)
	b.BackgroundColor3 = color
	b.BackgroundTransparency = 0.35
	b.AutoButtonColor = false
	b.Text = ""
	b:SetAttribute("Silent", true)   -- (no menu click sound: UIClicks)
	b.Parent = parent
	Instance.new("UICorner", b).CornerRadius = UDim.new(0.5, 0)
	local stroke = Instance.new("UIStroke", b)
	stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	stroke.Color = WHITE
	stroke.Transparency = 0.55
	stroke.Thickness = 2
	local t = Instance.new("TextLabel")
	t.BackgroundTransparency = 1
	t.AnchorPoint = Vector2.new(0.5, 0.5)
	t.Position = UDim2.fromScale(0.5, sub and 0.42 or 0.5)
	t.Size = UDim2.fromScale(0.78, 0.36)
	t.Font = Theme.FONT_TITLE
	t.TextScaled = true
	t.TextColor3 = WHITE
	t.Text = label
	t.Parent = b
	if sub then
		local s = Instance.new("TextLabel")
		s.BackgroundTransparency = 1
		s.AnchorPoint = Vector2.new(0.5, 0)
		s.Position = UDim2.fromScale(0.5, 0.62)
		s.Size = UDim2.fromScale(0.7, 0.16)
		s.Font = Theme.FONT
		s.TextScaled = true
		s.TextColor3 = Color3.fromRGB(230, 230, 240)
		s.Text = sub
		s.Name = "Sub"
		s.Parent = b
	end
	local function lit(on)
		b.BackgroundTransparency = on and 0.08 or 0.35
		stroke.Transparency = on and 0.05 or 0.55
	end
	return b, lit, t
end
local function isTouch(input) return input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 end
-- a plain button: hold = it reports being let go too; toggle = taps flip it on and off
local function button(parent, label, x, y, d, color, action, opts)
	opts = opts or {}
	local b, lit, t = disc(parent, label, x, y, d, color, opts.sub)
	local down, latched = false, false
	b.InputBegan:Connect(function(input)
		if not isTouch(input) or down then return end
		down = true
		if opts.toggle then
			latched = not latched
			lit(latched)
			TouchInput.press(action, latched, opts.side)
			return
		end
		lit(true)
		TouchInput.press(action, true, opts.side)
	end)
	b.InputEnded:Connect(function(input)
		if not isTouch(input) or not down then return end
		down = false
		if opts.toggle then return end
		lit(false)
		if opts.hold then TouchInput.press(action, false, opts.side) end
	end)
	local api = {button = b, label = t}
	function api.release()
		if opts.toggle and latched then latched = false; lit(false); TouchInput.press(action, false, opts.side) end
	end
	function api.latched() return latched end
	return api
end

--------------------------------------------------------------------
--  THE RIGHT THUMB
--------------------------------------------------------------------
local right = pad(Vector2.new(1, 1), UDim2.new(1, -8, 1, -8), UDim2.fromOffset(290, 228))

-- ATTACK: tap, or swipe for the kind of blow
local attack, attackLit = disc(right, "ATTACK", 80, 78, 90, COL.attack, "swipe ↑ ↓ ← →")
local arrows = {}
for _, a in ipairs({{"up", "▲", 0, -1}, {"down", "▼", 0, 1}, {"left", "◀", -1, 0}, {"right", "▶", 1, 0}}) do
	local l = Instance.new("TextLabel")
	l.BackgroundTransparency = 1
	l.AnchorPoint = Vector2.new(0.5, 0.5)
	l.Position = UDim2.new(0.5 + a[3] * 0.62, 0, 0.5 + a[4] * 0.62, 0)
	l.Size = UDim2.fromOffset(18, 18)
	l.Font = Theme.FONT_TITLE
	l.TextSize = 13
	l.Text = a[2]
	l.TextColor3 = WHITE
	l.TextTransparency = 0.55
	l.TextStrokeTransparency = 0.6
	l.Parent = attack
	arrows[a[1]] = l
end
local ACTION_OF = {up = "Overhead", down = "Stab", left = "Swing", right = "Swing"}
local SIDE_OF = {left = "Left", right = "Right"}
local SWIPE = 18          -- points a finger must travel to make a swipe
local TAP_WAIT = 0.12     -- a still finger: it's a tap (a swing) after this
local lastSide = "Left"
local lastAttackAt = -1
local held = nil          -- {input, start, action, side, sent}
local function lightArrow(which)
	for k, l in pairs(arrows) do l.TextTransparency = (k == which) and 0 or 0.55 end
end
local function held_()
	local c = player.Character
	return c and c:FindFirstChildOfClass("Tool")
end
local function ranged() local t = held_(); return t ~= nil and t:GetAttribute("Ranged") ~= nil end
local function magic() local t = held_(); return t ~= nil and t:GetAttribute("Magic") ~= nil end
local function send(h, action, side)
	if h.sent then return end
	h.sent = true
	h.action, h.side = action, side
	lastAttackAt = os.clock()
	TouchInput.press(action, true, side)
end
local function tapSwing(h)
	lastSide = lastSide == "Left" and "Right" or "Left"
	send(h, "Swing", lastSide)
end
-- (a staff: ← → are a cast like a tap; ↑ ↓ pick the spell: MagicClient's Overhead / Stab)
local MAGIC_OF = {up = "Overhead", down = "Stab", left = "Swing", right = "Swing"}
attack.InputBegan:Connect(function(input)
	if not isTouch(input) or held then return end
	held = {input = input, start = Vector2.new(input.Position.X, input.Position.Y), sent = false}
	attackLit(true)
	local h = held
	if ranged() then send(h, "Swing", nil); return end   -- (a bow: held, nothing to choose)
	task.delay(TAP_WAIT, function()
		-- (still there and hasn't moved: it's a swing)
		if held == h and not h.sent then tapSwing(h) end
	end)
end)
UserInputService.TouchMoved:Connect(function(touch)
	local h = held
	if not h or h.input ~= touch or h.sent then return end
	local d = (Vector2.new(touch.Position.X, touch.Position.Y) - h.start) / math.max(scale.Scale, 0.1)
	if d.Magnitude < SWIPE then return end
	local which
	if math.abs(d.Y) > math.abs(d.X) then which = d.Y < 0 and "up" or "down" else which = d.X < 0 and "left" or "right" end
	lightArrow(which)
	if magic() then send(h, MAGIC_OF[which], nil) else send(h, ACTION_OF[which], SIDE_OF[which]) end
end)
local function letGo(input)
	local h = held
	if not h or (input and h.input ~= input) then return end
	held = nil
	attackLit(false)
	if not h.sent then tapSwing(h) end
	TouchInput.press(h.action, false, h.side)
	task.delay(0.15, function() if not held then lightArrow(nil) end end)
end
attack.InputEnded:Connect(function(input) if isTouch(input) then letGo(input) end end)
UserInputService.TouchEnded:Connect(function(touch) if held and held.input == touch then letGo(touch) end end)

local block = button(right, "BLOCK", 178, 46, 70, COL.block, "Block", {hold = true})
local dodge = button(right, "DODGE", 50, 178, 52, COL.move, "Dodge")
local kick = button(right, "KICK", 152, 134, 50, COL.other, "Kick")
local feint = button(right, "FEINT", 152, 134, 50, Color3.fromRGB(150, 110, 40), "Feint")
feint.button.Visible = false
local meditate = button(right, "MEDITATE", 152, 134, 50, Color3.fromRGB(70, 60, 140), "Feint", {hold = true})
meditate.button.Visible = false
local lock = button(right, "LOCK", 132, 200, 42, COL.lock, "Lock")
-- the power and the throw: the orbs sit here (Powers.client)
local function slot(name, x, y, d)
	local f = Instance.new("Frame")
	f.Name = name
	f.BackgroundTransparency = 1
	f.AnchorPoint = Vector2.new(0.5, 0.5)
	f.Position = UDim2.new(1, -x, 1, -y)
	f.Size = UDim2.fromOffset(d, d)
	f.Parent = right
	return f
end
slot("PowerSlot", 254, 56, 50)
slot("ThrowSlot", 254, 126, 50)

--------------------------------------------------------------------
--  THE LEFT THUMB: SPRINT and JUMP, above the stick
--------------------------------------------------------------------
local left = pad(Vector2.new(0, 1), UDim2.new(0, 8, 1, -150), UDim2.fromOffset(64, 120))
local sprint = button(left, "SPRINT", 32, 88, 50, COL.move, "Sprint", {toggle = true})
local jump = button(left, "JUMP", 32, 28, 46, COL.move, "Jump")

--------------------------------------------------------------------
--  TOP LEFT: the menu, and the rest in a tray
--------------------------------------------------------------------
local function chip(label, x, w)
	local b = Instance.new("TextButton")
	b.Size = UDim2.fromOffset(w or 42, 36)
	b.Position = UDim2.fromOffset(x, 6)
	b.BackgroundColor3 = Theme.GLASS
	b.BackgroundTransparency = 0.2
	b.Text = label
	b.Font = Theme.FONT_TITLE
	b.TextSize = 18
	b.TextColor3 = WHITE
	b.Parent = gui
	Instance.new("UICorner", b).CornerRadius = UDim.new(0, 10)
	return b
end
local menu = chip("MENU", 10, 62)
menu.Name = "Menu"
menu.Activated:Connect(function() if _G.HubMenuToggle then _G.HubMenuToggle() end end)
local more = chip("⋯", 78)
more.Name = "More"
local tray = Instance.new("Frame")
tray.Name = "Tray"
tray.Position = UDim2.fromOffset(10, 48)
tray.Size = UDim2.fromOffset(0, 46)
tray.AutomaticSize = Enum.AutomaticSize.X
tray.BackgroundColor3 = Theme.GLASS
tray.BackgroundTransparency = 0.2
tray.Visible = false
tray.Parent = gui
Instance.new("UICorner", tray).CornerRadius = UDim.new(0, 12)
do
	local l = Instance.new("UIListLayout", tray); l.FillDirection = Enum.FillDirection.Horizontal; l.Padding = UDim.new(0, 6); l.VerticalAlignment = Enum.VerticalAlignment.Center
	local p = Instance.new("UIPadding", tray); p.PaddingLeft, p.PaddingRight = UDim.new(0, 6), UDim.new(0, 6)
end
local crouchOn = false
local trayButtons = {}
local function trayButton(label, fn)
	local b = Instance.new("TextButton")
	b.Size = UDim2.fromOffset(78, 34)
	b.BackgroundColor3 = COL.other
	b.Text = label
	b.Font = Theme.FONT_TITLE
	b.TextSize = 13
	b.TextColor3 = WHITE
	b.Parent = tray
	Instance.new("UICorner", b).CornerRadius = UDim.new(0, 8)
	b.Activated:Connect(fn)
	table.insert(trayButtons, b)
	return b
end
trayButton("EMOTE", function() tray.Visible = false; TouchInput.press("Emote", true) end)
trayButton("VIEW", function() TouchInput.press("View", true) end)
local crouchB = trayButton("CROUCH", function()
	crouchOn = not crouchOn
	TouchInput.press("Crouch", crouchOn)
end)
trayButton("SCORES", function() TouchInput.press("Board", true, "Toggle") end)
local stanceB = trayButton("STAFF ⇄", function() TouchInput.press("Stance", true) end)
more.Activated:Connect(function() tray.Visible = not tray.Visible end)
player.CharacterAdded:Connect(function()
	-- (a fresh body starts standing, walking)
	if crouchOn then crouchOn = false; TouchInput.press("Crouch", false) end
	sprint.release()
	if LockOn.target then LockOn.lock(nil) end
end)

--------------------------------------------------------------------
--  THE CAMERA: a drag on open screen (not on a button, not the stick's side)
--------------------------------------------------------------------
local looking = {}   -- [touch] = drag across while locked (a swipe moves the lock)
UserInputService.TouchStarted:Connect(function(touch, gp)
	if gp or not gui.Enabled then return end
	local w = workspace.CurrentCamera and workspace.CurrentCamera.ViewportSize.X or 1000
	-- (the left 40%: Roblox's stick)
	if touch.Position.X > w * 0.4 then looking[touch] = 0 end
end)
UserInputService.TouchMoved:Connect(function(touch)
	local acc = looking[touch]
	if acc == nil then return end
	local k = (ClientSettings.get("TouchLook") or 1) / Device.pixel()
	if LockOn.target then
		-- locked: a swipe across moves the lock to the next foe that way
		acc += touch.Delta.X / math.max(scale.Scale, 0.1)
		if math.abs(acc) > 70 then
			TouchInput.press("Lock", true, acc > 0 and "Next" or "Prev")
			acc = 0
		end
		looking[touch] = acc
	end
	TouchInput.addLook(touch.Delta.X * k, touch.Delta.Y * k)
end)
UserInputService.TouchEnded:Connect(function(touch) looking[touch] = nil end)

--------------------------------------------------------------------
--  WHEN TO SHOW, AND WHAT
--------------------------------------------------------------------
local function hideRobloxJump()
	local tg = player.PlayerGui:FindFirstChild("TouchGui")
	local frame = tg and tg:FindFirstChild("TouchControlFrame")
	local jb = frame and frame:FindFirstChild("JumpButton")
	if jb and jb.Visible then jb.Visible = false end
end
local function fit() scale.Scale = Device.touchScale() end
Device.changed:Connect(fit)
fit()

local stillSince = nil
RunService.RenderStepped:Connect(function()
	local active = TouchInput.active()
	gui.Enabled = active
	if not active then return end
	local char = player.Character
	local hum = char and char:FindFirstChildOfClass("Humanoid")
	local menuOpen = _G.HubMenuOpen and _G.HubMenuOpen() or false
	local on = hum ~= nil and hum.Health > 0 and not menuOpen
	right.Visible, left.Visible = on, on
	menu.Visible = not menuOpen
	more.Visible = on
	if not on then
		tray.Visible = false
		for t in pairs(looking) do looking[t] = nil end
		if held then letGo(nil) end
		return
	end
	-- FEINT in KICK's place while your own swing is coming; a staff's MEDITATE there instead
	local mage = magic()
	local swinging = not mage and (os.clock() - lastAttackAt < 0.6 or char:GetAttribute("Acting") == true)
	feint.button.Visible = swinging
	meditate.button.Visible = mage
	kick.button.Visible = not swinging and not mage
	stanceB.Visible = mage or (held_() ~= nil and held_():GetAttribute("Twin") ~= nil)
	local sub = attack:FindFirstChild("Sub", true)
	if sub then sub.Text = mage and "swipe ↑ ↓ spell" or (ranged() and "hold to draw" or "swipe ↑ ↓ ← →") end
	-- LOCK lit while locked
	lock.button.BackgroundTransparency = LockOn.target and 0.05 or 0.35
	lock.label.Text = LockOn.target and "LOCKED" or "LOCK"
	crouchB.BackgroundColor3 = crouchOn and Theme.BLUE or COL.other
	-- SPRINT stays on until you stop
	if sprint.latched() then
		if hum.MoveDirection.Magnitude < 0.1 then
			stillSince = stillSince or os.clock()
			if os.clock() - stillSince > 0.4 then sprint.release() end
		else stillSince = nil end
	else stillSince = nil end
	hideRobloxJump()
end)
