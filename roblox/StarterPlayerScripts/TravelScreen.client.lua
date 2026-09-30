--[[ TRAVEL SCREEN — the full-screen "Travelling…" you see from the moment a
     teleport is requested until the new server has loaded: a sweeping bar,
     where you're going, and a rotating gameplay hint. The same ScreenGui is
     registered as the teleport GUI, so Roblox keeps showing it during the
     load on the other side, and on arrival this script fades that copy out.

       ReplicatedStorage.HubEvent  server -> "Travel", destinationText
       Players.LocalPlayer.OnTeleport / TeleportService.TeleportInitFailed ]]

local Players           = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TeleportService   = game:GetService("TeleportService")
local TweenService      = game:GetService("TweenService")
local RunService        = game:GetService("RunService")
local UserInputService  = game:GetService("UserInputService")

local player    = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

--------------------------------------------------------------------
local HINT_EVERY   = 3.5
local HINTS = {
	"Feint (Q) during the windup to bait a parry, then hit the real one.",
	"A parry is a block raised at the last moment — it refunds stamina and opens a riposte.",
	"Chamber: start the mirror of their attack while they swing, and yours goes through.",
	"Morph a swing into a stab mid-windup. The stab comes out on the opposite side.",
	"Kick (G) breaks a held block. Miss, and it costs you.",
	"Missed swings cost more stamina than hits. Hit something.",
	"Guard raised without a parry clears your parry chain — commit or don't.",
	"Heavy armor turns cuts into bruises. Light armor turns you into a ghost.",
	"A stab to the face is a finisher, whatever the health bar says.",
	"Sprint is forward only. Backpedalling is slow — turn and run.",
	"Dodge (Space) sideways out of an overhead. It costs stamina; don't spam it.",
	"Look down: yes, those are your own legs.",
	"Friendly fire is on. Half damage, no kill credit, and everyone sees the feed.",
	"Hold Tab for the board. Press M for the menu, anywhere.",
	"Parties land on the same team. Bring friends, or make enemies.",
	"A locked match can't be joined, even by a friend. Ranked is ranked.",
	"Wall hits are free — no stamina lost, no stamina gained.",
	"Chain parries: each one in a row refunds more stamina, up to five.",
	"Pick up weapons off the ground with V. A dropped greatsword is still a greatsword.",
	"The clunk of your boots gets heavier with armor. So do you.",
}
--------------------------------------------------------------------

local FONT, FONT_BLACK, FONT_BODY = Enum.Font.GothamBold, Enum.Font.GothamBlack, Enum.Font.Gotham
local COL_BACK   = Color3.fromRGB(8, 7, 6)
local COL_TEXT   = Color3.fromRGB(235, 228, 214)
local COL_DIM    = Color3.fromRGB(160, 150, 135)
local COL_ACCENT = Color3.fromRGB(196, 150, 70)
local COL_TRACK  = Color3.fromRGB(30, 27, 24)

local function build(name)
	local gui = Instance.new("ScreenGui")
	gui.Name = name
	gui.ResetOnSpawn = false
	gui.IgnoreGuiInset = true
	gui.DisplayOrder = 5000
	gui.Enabled = false

	local back = Instance.new("Frame")
	back.Name = "Back"
	back.Size = UDim2.fromScale(1, 1)
	back.BackgroundColor3 = COL_BACK
	back.BorderSizePixel = 0
	back.Active = true
	back.Parent = gui
	local vignette = Instance.new("UIGradient", back)
	vignette.Rotation = 90
	vignette.Color = ColorSequence.new(Color3.fromRGB(14, 12, 10), Color3.fromRGB(4, 4, 3))

	local title = Instance.new("TextLabel")
	title.Name = "Title"
	title.AnchorPoint = Vector2.new(0.5, 0.5)
	title.Position = UDim2.fromScale(0.5, 0.42)
	title.Size = UDim2.new(0.8, 0, 0, 52)
	title.BackgroundTransparency = 1
	title.Font = FONT_BLACK
	title.TextSize = 42
	title.TextColor3 = COL_ACCENT
	title.Text = "TRAVELLING"
	title.Parent = back

	local dest = Instance.new("TextLabel")
	dest.Name = "Dest"
	dest.AnchorPoint = Vector2.new(0.5, 0.5)
	dest.Position = UDim2.fromScale(0.5, 0.42 + 0.06)
	dest.Size = UDim2.new(0.8, 0, 0, 24)
	dest.BackgroundTransparency = 1
	dest.Font = FONT
	dest.TextSize = 18
	dest.TextColor3 = COL_TEXT
	dest.Text = ""
	dest.Parent = back

	local track = Instance.new("Frame")
	track.Name = "Track"
	track.AnchorPoint = Vector2.new(0.5, 0.5)
	track.Position = UDim2.fromScale(0.5, 0.54)
	track.Size = UDim2.new(0, 420, 0, 6)
	track.BackgroundColor3 = COL_TRACK
	track.BorderSizePixel = 0
	track.ClipsDescendants = true
	track.Parent = back
	Instance.new("UICorner", track).CornerRadius = UDim.new(1, 0)
	local bar = Instance.new("Frame")
	bar.Name = "Bar"
	bar.Size = UDim2.new(0.35, 0, 1, 0)
	bar.Position = UDim2.new(-0.35, 0, 0, 0)
	bar.BackgroundColor3 = COL_ACCENT
	bar.BorderSizePixel = 0
	bar.Parent = track
	Instance.new("UICorner", bar).CornerRadius = UDim.new(1, 0)
	local g = Instance.new("UIGradient", bar)
	g.Transparency = NumberSequence.new({NumberSequenceKeypoint.new(0, 1), NumberSequenceKeypoint.new(0.5, 0), NumberSequenceKeypoint.new(1, 1)})

	local hint = Instance.new("TextLabel")
	hint.Name = "Hint"
	hint.AnchorPoint = Vector2.new(0.5, 1)
	hint.Position = UDim2.new(0.5, 0, 1, -60)
	hint.Size = UDim2.new(0.7, 0, 0, 44)
	hint.BackgroundTransparency = 1
	hint.Font = FONT_BODY
	hint.TextSize = 16
	hint.TextColor3 = COL_DIM
	hint.TextWrapped = true
	hint.Text = HINTS[math.random(#HINTS)]
	hint.Parent = back
	local hintTag = Instance.new("TextLabel")
	hintTag.AnchorPoint = Vector2.new(0.5, 1)
	hintTag.Position = UDim2.new(0.5, 0, 1, -104)
	hintTag.Size = UDim2.new(0.7, 0, 0, 16)
	hintTag.BackgroundTransparency = 1
	hintTag.Font = FONT
	hintTag.TextSize = 11
	hintTag.TextColor3 = COL_ACCENT
	hintTag.Text = "TIP"
	hintTag.Parent = back
	return gui
end

-- the live one (animated here) and a static copy Roblox shows during the load
local gui = build("TravelScreen")
gui.Parent = playerGui
pcall(function()
	local copy = build("TravelScreen")
	copy.Enabled = true
	copy.Back.Bar.Position = UDim2.new(0.3, 0, 0, 0)
	TeleportService:SetTeleportGui(copy)
end)

local back  = gui.Back
local bar   = back.Track.Bar
local hint  = back.Hint
local dest  = back.Dest

local showing = false
local hintIdx = math.random(#HINTS)
local mouseConn

local function setHint()
	hintIdx = hintIdx % #HINTS + 1
	TweenService:Create(hint, TweenInfo.new(0.25), {TextTransparency = 1}):Play()
	task.delay(0.25, function()
		hint.Text = HINTS[hintIdx]
		TweenService:Create(hint, TweenInfo.new(0.35), {TextTransparency = 0}):Play()
	end)
end

local function show(where)
	dest.Text = where or ""
	if showing then return end
	showing = true
	gui.Enabled = true
	back.BackgroundTransparency = 1
	TweenService:Create(back, TweenInfo.new(0.35), {BackgroundTransparency = 0}):Play()
	-- everything else steps aside
	for _, name in ipairs({"HubMenu", "LoadoutMenu", "HubToasts", "Scoreboard", "HUD"}) do
		local g = playerGui:FindFirstChild(name)
		if g and g:IsA("ScreenGui") then g.Enabled = false end
	end
	mouseConn = RunService.RenderStepped:Connect(function()
		UserInputService.MouseBehavior = Enum.MouseBehavior.Default
		UserInputService.MouseIconEnabled = true
	end)
	task.spawn(function()
		local t0 = os.clock()
		while showing do
			-- the bar sweeps (a teleport has no real progress to report)
			local t = (os.clock() - t0) % 1.6 / 1.6
			bar.Position = UDim2.new(-0.35 + t * 1.35, 0, 0, 0)
			RunService.RenderStepped:Wait()
		end
	end)
	task.spawn(function()
		while showing do
			task.wait(HINT_EVERY)
			if showing then setHint() end
		end
	end)
end

local function hide(reason)
	if not showing then return end
	showing = false
	if mouseConn then mouseConn:Disconnect(); mouseConn = nil end
	TweenService:Create(back, TweenInfo.new(0.3), {BackgroundTransparency = 1}):Play()
	task.delay(0.3, function() if not showing then gui.Enabled = false end end)
	for _, name in ipairs({"HubToasts", "Scoreboard", "HUD"}) do
		local g = playerGui:FindFirstChild(name)
		if g and g:IsA("ScreenGui") then g.Enabled = true end
	end
	-- the menus decide for themselves; give the class screen / hub menu back
	local lm = playerGui:FindFirstChild("LoadoutMenu")
	local hm = playerGui:FindFirstChild("HubMenu")
	local ev = ReplicatedStorage:FindFirstChild("LoadoutEvent")
	if ev then ev:FireServer("Ready") end   -- "Show" comes back if we have no body
	if hm and _G.MenuBus then _G.MenuBus:Fire("HubClosed") end
end

-- the server tells us before it teleports; Roblox tells us as it goes
local hubEvent = ReplicatedStorage:WaitForChild("HubEvent", 10)
if hubEvent then
	hubEvent.OnClientEvent:Connect(function(what, a)
		if what == "Travel" then show(a) elseif what == "TravelFailed" then hide("failed") end
	end)
end
player.OnTeleport:Connect(function(state)
	if state == Enum.TeleportState.Started or state == Enum.TeleportState.WaitingForServer or state == Enum.TeleportState.InProgress then
		show(dest.Text ~= "" and dest.Text or nil)
	elseif state == Enum.TeleportState.Failed then
		hide("failed")
	end
end)
TeleportService.TeleportInitFailed:Connect(function(_, result, msg)
	hide("failed")
	warn("[Travel] teleport failed:", tostring(result), tostring(msg))
end)

-- ARRIVAL: Roblox parents its copy under CoreGui; we show our own briefly while
-- the world streams in, then let it go
pcall(function()
	local arriving = TeleportService:GetArrivingTeleportGui()
	if arriving then
		arriving.Parent = playerGui
		show("")
		task.spawn(function()
			local round = ReplicatedStorage:WaitForChild("Round", 15)
			if round then
				local t0 = os.clock()
				while os.clock() - t0 < 10 and (round:GetAttribute("Mode") or "") == "" do task.wait(0.1) end
				dest.Text = (round:GetAttribute("ModeName") or "") .. ((round:GetAttribute("Map") or "") ~= "" and ("  ·  " .. round:GetAttribute("Map")) or "")
			end
			task.wait(0.6)
			hide("arrived")
			task.delay(0.4, function() if arriving.Parent then arriving:Destroy() end end)
		end)
	end
end)
