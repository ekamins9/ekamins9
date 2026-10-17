--[[ ROUND RESULT (client) — the moment a round ends, the screen says it big:
     VICTORY / DEFEAT / DRAW across the middle on a band in the winning side's
     colour, under it who won ("IRON WINS") and why ("FROSTGATE HAS FALLEN"),
     and when the match is over, the match. Behind the word, the winning side's arms rise in
     gold (the house its banners flew on the map: ReplicatedStorage ▸ Houses). A few seconds, then it gives way to
     the scoreboard and the vote (Scoreboard).

     Reads the Round node: State (Round → Intermission), Winner (a team's name
     or a player's), Objective (the result line), WinnerKills, MatchOver.
     Not in the Courtyard, the Tiltyard or Horde. ]]

local Players           = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService      = game:GetService("TweenService")

local GameConfig = require(ReplicatedStorage:WaitForChild("GameConfig"))
local Theme = require(ReplicatedStorage:WaitForChild("Theme"))
local UIFX = require(ReplicatedStorage:WaitForChild("UIFX"))

local player = Players.LocalPlayer
local round = ReplicatedStorage:WaitForChild("Round")

local HOLD = 5.5          -- seconds it stays up
local SKIP = {Hub = true, Tiltyard = true, Horde = true}
local COL_WIN, COL_LOSE, COL_DRAW = Color3.fromRGB(255, 206, 70), Color3.fromRGB(255, 80, 90), Color3.fromRGB(230, 230, 236)

local gui = Instance.new("ScreenGui")
gui.Name = "RoundResult"
gui.IgnoreGuiInset = true
gui.ResetOnSpawn = false
gui.DisplayOrder = 2200     -- over the intermission board (2100)
gui.Enabled = false
gui.Parent = player:WaitForChild("PlayerGui")

-- a dark wash over the view
local wash = Instance.new("Frame")
wash.Size = UDim2.fromScale(1, 1)
wash.BackgroundColor3 = Color3.new(0, 0, 0)
wash.BackgroundTransparency = 1
wash.BorderSizePixel = 0
wash.Parent = gui

-- embers rising behind the band (gold for a win, ash for a loss: UIFX)
local emberLayer = Instance.new("Frame")
emberLayer.BackgroundTransparency = 1
emberLayer.Size = UDim2.fromScale(1, 1)
emberLayer.ZIndex = 2
emberLayer.Parent = gui

-- the band across the middle, in the winners' colour, fading at both ends
local band = Instance.new("Frame")
band.ZIndex = 3
band.AnchorPoint = Vector2.new(0.5, 0.5)
band.Position = UDim2.fromScale(0.5, 0.42)
band.Size = UDim2.new(1, 0, 0, 190)
band.BorderSizePixel = 0
band.Parent = gui
local bandFade = Instance.new("UIGradient")
bandFade.Transparency = NumberSequence.new({NumberSequenceKeypoint.new(0, 1), NumberSequenceKeypoint.new(0.22, 0.25),
	NumberSequenceKeypoint.new(0.78, 0.25), NumberSequenceKeypoint.new(1, 1)})
bandFade.Parent = band

local function text(size, font, y, h)
	local t = Instance.new("TextLabel")
	t.BackgroundTransparency = 1
	t.AnchorPoint = Vector2.new(0.5, 0.5)
	t.Position = UDim2.new(0.5, 0, 0, y)
	t.Size = UDim2.new(1, -32, 0, h)
	t.Font = font
	t.TextSize = size
	t.TextColor3 = Color3.new(1, 1, 1)
	t.TextStrokeColor3 = Theme.OUTLINE
	t.TextStrokeTransparency = 0.2
	t.TextScaled = false
	t.Parent = band
	local cap = Instance.new("UITextSizeConstraint")
	cap.MaxTextSize = size
	cap.Parent = t
	t.TextScaled = true
	return t
end
-- the winning house's arms, big and gold behind the word (its outline under it)
local crest = Instance.new("Frame")
crest.BackgroundTransparency = 1
crest.AnchorPoint = Vector2.new(0.5, 0.5)
crest.Position = UDim2.new(0.5, 0, 0, 95)
crest.Size = UDim2.fromOffset(180, 180)   -- (inside the band's 190)
crest.Visible = false
crest.Parent = band
local crestScale = Instance.new("UIScale"); crestScale.Parent = crest
local crestLayers = {}
for z, col in ipairs({Color3.fromRGB(14, 10, 8), Color3.new(1.06, 0.84, 0.4)}) do
	local il = Instance.new("ImageLabel")
	il.BackgroundTransparency = 1
	il.Size = UDim2.fromScale(1, 1)
	il.ScaleType = Enum.ScaleType.Fit
	il.ImageColor3 = col
	il.ZIndex = z
	il.Parent = crest
	crestLayers[z] = il
end
local big = text(96, Theme.FONT_TITLE, 70, 100)       -- VICTORY
local who = text(30, Theme.FONT_TITLE, 132, 36)       -- IRON WINS
local why = text(18, Theme.FONT, 166, 22)             -- FROSTGATE HAS FALLEN · the match
local scale = Instance.new("UIScale")
scale.Parent = big

local function teamByName(name)
	for key, def in pairs(GameConfig.TEAMS) do if def.name == name then return key, def end end
	return nil
end

-- the team you were on while the round ran
local roundTeam
local function noteTeam()
	if player.Team and round:GetAttribute("State") == "Round" then roundTeam = player.Team.Name end
end
player:GetPropertyChangedSignal("Team"):Connect(noteTeam)
noteTeam()

local showing = 0
local function show()
	local winner = round:GetAttribute("Winner") or ""
	local result = round:GetAttribute("Objective") or ""
	-- (the side you fought on: teams may be cleared the moment the round ends)
	local myTeam = (player.Team and player.Team.Name) or roundTeam
	local key, def = teamByName(winner)
	local verdict, col
	if winner == "" then
		verdict, col = "DRAW", COL_DRAW
	elseif winner == player.DisplayName or (myTeam and winner == myTeam) then
		verdict, col = "VICTORY", COL_WIN
	elseif key and not (myTeam and teamByName(myTeam)) then
		verdict, col = string.upper(winner) .. " WINS", Color3.new(1, 1, 1)   -- (watching, on no side)
	else
		verdict, col = "DEFEAT", COL_LOSE
	end
	-- who won, and why (the mode's result line: "IRON WINS  ·  FROSTGATE HAS FALLEN")
	local whoText
	if winner == "" then whoText = "NOBODY TAKES IT"
	elseif key then whoText = string.upper(def.name) .. " WINS"
	else
		local wk = round:GetAttribute("WinnerKills") or 0
		whoText = string.upper(winner) .. " WINS" .. (wk > 0 and string.format("  ·  %d KILLS", wk) or "")
	end
	-- (a line with no "·" that isn't just the winner, "THE ROUND WAS ENDED BY STAFF": all of it)
	local reason = result:match("·%s*(.+)$") or ((result:find("WINS") or result == "DRAW") and "" or result)
	if round:GetAttribute("MatchOver") == true then
		reason = (reason ~= "" and (reason .. "   ·   ") or "") .. (verdict == "VICTORY" and "THE MATCH IS YOURS" or "THE MATCH IS OVER")
	end
	-- (the dungeon game: your own fate, and where you're going)
	local mode = round:GetAttribute("Mode") or ""
	local mdef = GameConfig.MODES[mode]
	if mdef and mdef.ownSpawn and mode ~= "Tavern" then
		local fate = player:GetAttribute("RaidFate")
		if mode == "Deadvault" then
			if fate == "out" then verdict, col = "YOU GOT OUT", COL_WIN
			elseif fate == "fell" then verdict, col = "YOU FELL", COL_LOSE
			else verdict, col = "THE RAID IS OVER", COL_DRAW end
		else
			if result:find("FELL") then verdict, col = "DEFEAT", COL_LOSE
			elseif result:find("GILDED RAT") or result == "" then verdict, col = "THE RUN IS OVER", COL_DRAW
			else verdict, col = "VICTORY", COL_WIN end
		end
		whoText = "BACK TO THE GILDED RAT"
		if reason == "BACK TO THE GILDED RAT" then reason = "" end
	end
	if verdict == whoText then whoText = "" end

	big.Text, big.TextColor3 = verdict, col
	who.Text = whoText
	who.TextColor3 = def and def.rgb:Lerp(Color3.new(1, 1, 1), 0.35) or Color3.new(1, 1, 1)
	why.Text = string.upper(reason)
	band.BackgroundColor3 = (def and def.rgb or Color3.fromRGB(40, 44, 60)):Lerp(Color3.new(0, 0, 0), 0.45)
	-- the winners' arms (a side's: its house on this map)
	local emblem
	if key then
		local map = workspace:FindFirstChild("Map")
		local ok, e = pcall(function() return require(ReplicatedStorage:WaitForChild("Houses")).forTeam(key, map and map:GetAttribute("HouseSeed")) end)
		emblem = ok and map and map:GetAttribute("HouseSeed") and e or nil
	end
	local art = ReplicatedStorage:FindFirstChild("ShieldArt")
	local o, f = art and emblem and art:FindFirstChild(emblem .. "_o"), art and emblem and art:FindFirstChild(emblem)
	crest.Visible = f ~= nil
	if f then
		crestLayers[1].Image = o and o.Value or ""
		crestLayers[2].Image = f.Value
		for _, il in ipairs(crestLayers) do il.ImageTransparency = 1 end
		crestScale.Scale = 0.6
	end

	-- in: the wash darkens, the band opens, the word lands
	showing += 1
	local me = showing
	gui.Enabled = true
	wash.BackgroundTransparency = 1
	band.Size = UDim2.new(1, 0, 0, 0)
	band.BackgroundTransparency = 0
	for _, t in ipairs({big, who, why}) do t.TextTransparency = 1; t.TextStrokeTransparency = 1 end
	scale.Scale = 1.6
	TweenService:Create(wash, TweenInfo.new(0.4), {BackgroundTransparency = 0.55}):Play()
	TweenService:Create(band, TweenInfo.new(0.35, Enum.EasingStyle.Quint), {Size = UDim2.new(1, 0, 0, 190)}):Play()
	task.delay(0.15, function()
		if crest.Visible then
			-- (it rises behind the word, half seen: the word stays the thing you read)
			TweenService:Create(crestScale, TweenInfo.new(0.7, Enum.EasingStyle.Quint), {Scale = 1}):Play()
			TweenService:Create(crestLayers[1], TweenInfo.new(0.6), {ImageTransparency = 0.45}):Play()
			TweenService:Create(crestLayers[2], TweenInfo.new(0.6), {ImageTransparency = 0.38}):Play()
		end
		TweenService:Create(scale, TweenInfo.new(0.45, Enum.EasingStyle.Back), {Scale = 1}):Play()
		TweenService:Create(big, TweenInfo.new(0.25), {TextTransparency = 0, TextStrokeTransparency = 0.2}):Play()
	end)
	-- the word lands: sparks in its colour, a flash and a shudder for a win
	local palette = verdict == "VICTORY" and "gold" or (verdict == "DEFEAT" and "ash" or "holy")
	task.delay(0.35, function()
		if showing ~= me then return end
		UIFX.sparks(gui, Vector2.new(0.5, 0.42), {n = verdict == "VICTORY" and 32 or 18, colors = verdict == "DEFEAT" and "blood" or palette, radius = 340, z = 6})
		if verdict == "VICTORY" then UIFX.flash(gui, Color3.fromRGB(255, 226, 150), 0.3, 0.6); UIFX.camShake(0.4, 3) end
	end)
	local stopEmbers = UIFX.embers(emberLayer, {colors = palette, rate = verdict == "VICTORY" and 0.035 or 0.08, z = 2})
	task.delay(HOLD, stopEmbers)
	task.delay(0.55, function()
		for _, t in ipairs({who, why}) do TweenService:Create(t, TweenInfo.new(0.4), {TextTransparency = 0, TextStrokeTransparency = 0.3}):Play() end
	end)
	-- out
	task.delay(HOLD, function()
		if showing ~= me then return end
		local info = TweenInfo.new(0.6)
		TweenService:Create(wash, info, {BackgroundTransparency = 1}):Play()
		TweenService:Create(band, info, {BackgroundTransparency = 1}):Play()
		for _, t in ipairs({big, who, why}) do TweenService:Create(t, info, {TextTransparency = 1, TextStrokeTransparency = 1}):Play() end
		for _, il in ipairs(crestLayers) do TweenService:Create(il, info, {ImageTransparency = 1}):Play() end
		task.delay(0.65, function() if showing == me then gui.Enabled = false end end)
	end)
end

local last = round:GetAttribute("State")
round:GetAttributeChangedSignal("State"):Connect(function()
	local st = round:GetAttribute("State")
	if st == "Round" then roundTeam = nil; noteTeam() end
	if last == "Round" and st == "Intermission" and not SKIP[round:GetAttribute("Mode") or ""] then
		-- (the result attributes land the same frame; give them a beat)
		task.delay(0.1, show)
	end
	last = st
end)

-- a test hook (the command bar / MCP): _G.ShowRoundResult()
_G.ShowRoundResult = show
