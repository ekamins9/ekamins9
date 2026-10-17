--[[ ENGINES (client) — what Game ▸ Engines fires, on your screen, in any mode that has them (War,
     Siege): the trebuchets' fire on its high arc (the scream of it coming down near you), the
     volleys, the battle-mages' meteors, chain lightning and frost (ReplicatedStorage ▸ WarFX); a
     call when the battle-mages cast; and a warning when something is coming down on you:
     TREBUCHET (get out of the red ring) · VOLLEY (raise your guard, or get under a roof) · METEORS ·
     LIGHTNING · FROST. War.client adds its armies' part (archers drawing, mages raising staffs).
     Remote: ReplicatedStorage ▸ WarEvent ("Treb", "Volley", "Barrage"; Game ▸ Engines' header). ]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local Theme = require(ReplicatedStorage:WaitForChild("Theme"))
local GameConfig = require(ReplicatedStorage:WaitForChild("GameConfig"))
local InputHints = require(ReplicatedStorage:WaitForChild("InputHints"))
local WarFX = require(ReplicatedStorage:WaitForChild("WarFX"))
local UIFX = require(ReplicatedStorage:WaitForChild("UIFX"))

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local remote = ReplicatedStorage:WaitForChild("WarEvent", math.huge)   -- (a mode with engines makes it)

local V3 = Vector3.new
local WHITE = Color3.new(1, 1, 1)
local SIDE = {A = Color3.fromRGB(70, 120, 240), B = Color3.fromRGB(226, 66, 54)}
local ARCANE = Color3.fromRGB(176, 96, 255)

local function mySide()
	local c = player.Character
	local t = c and c:GetAttribute("Team")
	if t == "A" or t == "B" then return t end
	local team = player.Team
	for k, d in pairs(GameConfig.TEAMS) do if team and d.name == team.Name then return k end end
	return nil
end
local function myPos()
	local c = player.Character
	local r = c and c:FindFirstChild("HumanoidRootPart")
	return r and r.Position or nil
end
local function near(at, r)
	local p = myPos()
	return p ~= nil and (V3(p.X, 0, p.Z) - V3(at.X, 0, at.Z)).Magnitude <= r
end

--------------------------------------------------------------------
--  THE SCREEN: a warning, a call
--------------------------------------------------------------------
local gui = Instance.new("ScreenGui")
gui.Name = "EngineWarnings"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = true
gui.DisplayOrder = 9
gui.Parent = playerGui
local function label(str, size, font, color)
	local l = Instance.new("TextLabel")
	l.BackgroundTransparency = 1
	l.Text, l.TextSize, l.Font, l.TextColor3 = str, size, font or Theme.FONT, color or WHITE
	l.AnchorPoint = Vector2.new(0.5, 0.5)
	l.Size = UDim2.new(0.9, 0, 0, size + 6)
	local s = Instance.new("UIStroke")
	s.Color, s.Thickness, s.ApplyStrokeMode = Theme.OUTLINE, size >= 24 and 2.4 or 1.6, Enum.ApplyStrokeMode.Contextual
	s.Parent = l
	l.Parent = gui
	return l
end
local warnLabel = label("", 30, Theme.FONT_TITLE, Color3.fromRGB(255, 90, 70)); warnLabel.Position = UDim2.fromScale(0.5, 0.44); warnLabel.Visible = false
local hint = label("", 16, Theme.FONT, WHITE); hint.Position = UDim2.new(0.5, 0, 0.44, 30); hint.Visible = false
local call = label("", 26, Theme.FONT_TITLE, WHITE); call.Position = UDim2.fromScale(0.5, 0.37); call.Visible = false
local sub = label("", 14, Theme.FONT, Color3.fromRGB(226, 230, 240)); sub.Position = UDim2.new(0.5, 0, 0.37, 24); sub.Visible = false

local warnTok, callTok = 0, 0
local function warning(text, hintText, dur)
	warnTok += 1
	local tok = warnTok
	warnLabel.Text, warnLabel.Visible = text, true
	hint.Text, hint.Visible = hintText or "", hintText ~= nil
	task.spawn(function()
		local t0 = os.clock()
		while warnTok == tok and os.clock() - t0 < (dur or 2) do
			warnLabel.TextTransparency = (math.floor((os.clock() - t0) * 6) % 2 == 0) and 0 or 0.35
			task.wait(0.05)
		end
		if warnTok == tok then warnLabel.Visible, hint.Visible = false, false end
	end)
	UIFX.play("Error")
end
local function shout(text, subText, color, dur)
	callTok += 1
	local tok = callTok
	call.Text, call.TextColor3, call.Visible = text, color or WHITE, true
	sub.Text, sub.Visible = subText or "", true
	call.Position = UDim2.fromScale(0.5, 0.38)
	TweenService:Create(call, TweenInfo.new(0.35, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {Position = UDim2.fromScale(0.5, 0.37)}):Play()
	task.delay(dur or 2.4, function() if callTok == tok then call.Visible, sub.Visible = false, false end end)
end
_G.EngineShout = shout   -- (War.client's banner calls use the same voice)

--------------------------------------------------------------------
--  THE SHOTS
--------------------------------------------------------------------
local EV = {}
function EV.Treb(d)
	WarFX.fireball(d.from, d.to, d.t, {big = true, whistle = near(d.to, d.r + 50), height = 120})
	if near(d.to, d.r + 6) then warning("TREBUCHET!", "GET OUT OF THE RED RING", d.t) end
end
function EV.Volley(d)
	WarFX.volley(d.from, d.to, d.n or 60, {flight = d.t, spread = d.r * 0.6, stagger = 0.4})
	if near(d.to, d.r + 4) and mySide() ~= d.side then
		warning("VOLLEY!", "RAISE YOUR GUARD  " .. InputHints.say("Block") .. "  ·  OR GET UNDER A ROOF", d.t)
	end
end
function EV.Barrage(d)
	local who = (d.side == "A" and "THE CROWN'S" or "THE IRON HOST'S") .. " BATTLE-MAGES"
	local mine = mySide() == d.side
	if d.kind == "meteors" then
		shout("METEOR STORM", who, mine and SIDE[d.side] or Color3.fromRGB(200, 130, 255), 2.6)
		for k, p in ipairs(d.points) do
			local from = d.from + V3((math.random() - 0.5) * 40, 80, (math.random() - 0.5) * 40)
			WarFX.fireball(from, p, d.t + k * d.step, {color = ARCANE, size = 4.4, height = 18, big = true, whistle = near(p, 40)})
		end
		for _, p in ipairs(d.points) do if near(p, d.r + 4) and not mine then warning("METEORS!", "MOVE!", d.t) break end end
	elseif d.kind == "lightning" then
		shout("CHAIN LIGHTNING", who, mine and SIDE[d.side] or Color3.fromRGB(160, 200, 255), 2.4)
		for k, p in ipairs(d.points) do task.delay(d.t + k * d.step, function() WarFX.strike(p) end) end
		for _, p in ipairs(d.points) do if near(p, d.r + 3) and not mine then warning("LIGHTNING!", "MOVE!", d.t) break end end
	else
		shout("FROST", who, mine and SIDE[d.side] or Color3.fromRGB(150, 210, 255), 2.4)
		local p = d.points[1]
		task.delay(d.t, function() WarFX.frost(p, d.r) end)
		if near(p, d.r + 3) and not mine then warning("FROST!", "GET CLEAR OR BE SLOWED", d.t) end
	end
end

remote.OnClientEvent:Connect(function(what, d)
	local f = EV[what]
	if f then
		local ok, err = pcall(f, d or {})
		if not ok then warn("[Engines] " .. tostring(what) .. ": " .. tostring(err)) end
	end
end)
