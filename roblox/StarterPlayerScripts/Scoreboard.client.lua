--[[ SCOREBOARD (client) — the kill feed (top right, entries fade out), the
     round strip top-centre (mode · map · clock, the mode's objective line,
     team scores in team modes) and the leaderboard you see while HOLDING
     Tab: every player's kills, deaths and K/D, sorted by kills, team-coloured.
     During the intermission the board stays up with the result banner and
     the MAP VOTE (three buttons › VoteRemote). Replaces Roblox's own player
     list. Built from Instances. Lives in StarterPlayerScripts. ]]

local Players           = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService  = game:GetService("UserInputService")
local RunService        = game:GetService("RunService")
local StarterGui        = game:GetService("StarterGui")
local TweenService      = game:GetService("TweenService")

local GameConfig = require(ReplicatedStorage:WaitForChild("GameConfig"))
local Theme = require(ReplicatedStorage:WaitForChild("Theme"))

local player = Players.LocalPlayer
local remote = ReplicatedStorage:WaitForChild("KillFeedRemote")
local roundNode = ReplicatedStorage:WaitForChild("Round")
local voteRemote = ReplicatedStorage:FindFirstChild("VoteRemote")

--------------------------------------------------------------------
local FEED_MAX     = 6
local FEED_TTL     = 7      -- seconds an entry stays
local BOARD_KEY    = Enum.KeyCode.Tab
local FONT, FONT_BODY, FONT_BLACK = Theme.FONT, Theme.FONT_BODY, Theme.FONT_TITLE
local COL_TEXT   = Theme.TEXT
local COL_DIM    = Theme.DIM
local COL_ACCENT = Theme.ACCENT
local COL_ME     = Theme.GOOD
local COL_KILL   = Theme.BAD
local COL_TK     = Color3.fromRGB(255, 170, 60)
local COL_PANEL  = Theme.PANEL
local COL_ROW    = Theme.CARD
local COL_ROW_ON = Theme.CARD_ON
--------------------------------------------------------------------

-- ours replaces the core list (which would also pop on Tab)
pcall(function() StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.PlayerList, false) end)

local gui = Instance.new("ScreenGui")
gui.Name = "Scoreboard"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = true
gui.DisplayOrder = 30
gui.Parent = player:WaitForChild("PlayerGui")

local function label(parent, text, size, font, color)
	local t = Instance.new("TextLabel")
	t.BackgroundTransparency = 1
	t.Font = font or FONT_BODY
	t.TextSize = size or 15
	t.TextColor3 = color or COL_TEXT
	t.TextXAlignment = Enum.TextXAlignment.Left
	t.Text = text or ""
	t.Parent = parent
	return t
end

local function teamColorOf(plr)
	local t = plr.Team
	if not t then return nil end
	for _, def in pairs(GameConfig.TEAMS) do if def.name == t.Name then return def.rgb end end
	return t.TeamColor.Color
end

--------------------------------------------------------------------
--  KILL FEED
--------------------------------------------------------------------
local feed = Instance.new("Frame")
feed.Name = "KillFeed"
feed.AnchorPoint = Vector2.new(1, 0)
feed.Position = UDim2.new(1, -20, 0, 48)
feed.Size = UDim2.fromOffset(360, 200)
feed.BackgroundTransparency = 1
feed.Parent = gui
local feedLayout = Instance.new("UIListLayout", feed)
feedLayout.HorizontalAlignment = Enum.HorizontalAlignment.Right
feedLayout.Padding = UDim.new(0, 4)
feedLayout.SortOrder = Enum.SortOrder.LayoutOrder

local VERB = {
	facestab  = "ran through",
	headslash = "beheaded",
	stab      = "skewered",
	slash     = "cut down",
	kick      = "kicked to death",
	head      = "brained",       -- hit by a thrown head
	bleed     = "bled out",
}

local feedOrder = 0
local function pushFeed(e)
	feedOrder += 1
	local row = Instance.new("Frame")
	row.BackgroundColor3 = COL_PANEL
	row.BackgroundTransparency = 0.35
	row.BorderSizePixel = 0
	row.AutomaticSize = Enum.AutomaticSize.X
	row.Size = UDim2.fromOffset(0, 26)
	row.LayoutOrder = -feedOrder   -- newest on top
	row.Parent = feed
	Instance.new("UICorner", row).CornerRadius = UDim.new(0, 6)
	local pad = Instance.new("UIPadding", row)
	pad.PaddingLeft, pad.PaddingRight = UDim.new(0, 10), UDim.new(0, 10)
	local t = label(row, "", 14, FONT_BODY, COL_TEXT)
	t.RichText = true
	t.AutomaticSize = Enum.AutomaticSize.X
	t.Size = UDim2.new(0, 0, 1, 0)
	local function name(n, id)
		local col = (id ~= 0 and id == player.UserId) and COL_ME or COL_TEXT
		local plr = id ~= 0 and Players:GetPlayerByUserId(id)
		local tc = plr and teamColorOf(plr)
		if tc and not (id == player.UserId) then col = tc end
		return string.format('<font color="#%s"><b>%s</b></font>', col:ToHex(), n)
	end
	local victim = name(e.victim or "?", e.victimId or 0)
	if e.kind == "bleed" and e.killer then
		t.Text = string.format('%s  <font color="#%s">bled out after</font>  %s%s', victim, COL_DIM:ToHex(), name(e.killer, e.killerId),
			e.weapon ~= "" and string.format('  <font color="#%s">(%s)</font>', COL_DIM:ToHex(), e.weapon) or "")
	elseif e.killer then
		local verb = VERB[e.kind] or "killed"
		if e.teamkill then verb = "TEAMKILLED" end
		t.Text = string.format('%s  <font color="#%s">%s</font>  %s%s', name(e.killer, e.killerId), (e.teamkill and COL_TK or COL_KILL):ToHex(), verb, victim,
			e.weapon ~= "" and string.format('  <font color="#%s">%s</font>', COL_DIM:ToHex(), e.weapon) or "")
	else
		t.Text = string.format('%s  <font color="#%s">%s</font>', victim, COL_DIM:ToHex(), e.kind == "bleed" and "bled out" or "died")
	end
	-- trim
	local rows = {}
	for _, c in ipairs(feed:GetChildren()) do if c:IsA("Frame") then table.insert(rows, c) end end
	table.sort(rows, function(a, b) return a.LayoutOrder < b.LayoutOrder end)
	for i = FEED_MAX + 1, #rows do rows[i]:Destroy() end
	task.delay(FEED_TTL, function()
		if not row.Parent then return end
		TweenService:Create(row, TweenInfo.new(0.5), {BackgroundTransparency = 1}):Play()
		TweenService:Create(t, TweenInfo.new(0.5), {TextTransparency = 1}):Play()
		task.delay(0.5, function() if row.Parent then row:Destroy() end end)
	end)
end

remote.OnClientEvent:Connect(function(what, e)
	if what == "Kill" and type(e) == "table" then pushFeed(e) end
end)

--------------------------------------------------------------------
--  ROUND STRIP (top centre): mode · map · clock / objective / team scores
--------------------------------------------------------------------
local strip = Instance.new("Frame")
strip.AnchorPoint = Vector2.new(0.5, 0)
strip.Position = UDim2.new(0.5, 0, 0, 10)
strip.Size = UDim2.fromOffset(460, 64)
strip.BackgroundTransparency = 1
strip.Parent = gui
local timer = label(strip, "", 18, FONT, COL_TEXT)
timer.Size = UDim2.new(1, 0, 0, 24)
timer.TextXAlignment = Enum.TextXAlignment.Center
timer.TextStrokeTransparency = 0.5
local objective = label(strip, "", 13, FONT, COL_DIM)
objective.Position = UDim2.new(0, 0, 0, 24)
objective.Size = UDim2.new(1, 0, 0, 18)
objective.TextXAlignment = Enum.TextXAlignment.Center
objective.TextStrokeTransparency = 0.6
local scoreRow = Instance.new("Frame")
scoreRow.BackgroundTransparency = 1
scoreRow.Position = UDim2.new(0, 0, 0, 42)
scoreRow.Size = UDim2.new(1, 0, 0, 22)
scoreRow.Visible = false
scoreRow.Parent = strip
local scoreA = label(scoreRow, "", 18, FONT_BLACK, GameConfig.TEAMS.A.rgb)
scoreA.Size = UDim2.new(0.5, -30, 1, 0)
scoreA.TextXAlignment = Enum.TextXAlignment.Right
scoreA.TextStrokeTransparency = 0.5
local scoreDash = label(scoreRow, "—", 14, FONT, COL_DIM)
scoreDash.AnchorPoint = Vector2.new(0.5, 0)
scoreDash.Position = UDim2.new(0.5, 0, 0, 0)
scoreDash.Size = UDim2.fromOffset(40, 22)
scoreDash.TextXAlignment = Enum.TextXAlignment.Center
local scoreB = label(scoreRow, "", 18, FONT_BLACK, GameConfig.TEAMS.B.rgb)
scoreB.Position = UDim2.new(0.5, 30, 0, 0)
scoreB.Size = UDim2.new(0.5, -30, 1, 0)
scoreB.TextStrokeTransparency = 0.5

--------------------------------------------------------------------
--  LEADERBOARD (hold Tab; forced up during the intermission)
--------------------------------------------------------------------
local board = Instance.new("Frame")
board.Name = "Leaderboard"
board.AnchorPoint = Vector2.new(0.5, 0)
board.Position = UDim2.new(0.5, 0, 0, 84)
board.Size = UDim2.fromOffset(560, 60)
board.AutomaticSize = Enum.AutomaticSize.Y
board.BackgroundColor3 = COL_PANEL
board.BackgroundTransparency = 0.1
board.BorderSizePixel = 0
board.Visible = false
board.Parent = gui
Instance.new("UICorner", board).CornerRadius = UDim.new(0, 10)
local bStroke = Instance.new("UIStroke", board)
bStroke.Color = COL_ACCENT
bStroke.Transparency = 0.5
local bPad = Instance.new("UIPadding", board)
bPad.PaddingLeft, bPad.PaddingRight, bPad.PaddingTop, bPad.PaddingBottom = UDim.new(0, 14), UDim.new(0, 14), UDim.new(0, 10), UDim.new(0, 12)
local bLayout = Instance.new("UIListLayout", board)
bLayout.Padding = UDim.new(0, 4)
bLayout.SortOrder = Enum.SortOrder.LayoutOrder

local banner = label(board, "", 17, FONT_BLACK, COL_ACCENT)
banner.Size = UDim2.new(1, 0, 0, 26)
banner.LayoutOrder = -3
banner.TextXAlignment = Enum.TextXAlignment.Center
banner.Visible = false

-- map vote: three buttons, live counts
local voteBox = Instance.new("Frame")
voteBox.BackgroundTransparency = 1
voteBox.Size = UDim2.new(1, 0, 0, 62)
voteBox.LayoutOrder = -1
voteBox.Visible = false
voteBox.Parent = board
local voteTitle = label(voteBox, "VOTE FOR THE NEXT MAP", 12, FONT, COL_DIM)
voteTitle.Name = "VoteTitle"
voteTitle.Size = UDim2.new(1, 0, 0, 16)
voteTitle.TextXAlignment = Enum.TextXAlignment.Center
local voteRow = Instance.new("Frame")
voteRow.BackgroundTransparency = 1
voteRow.Position = UDim2.new(0, 0, 0, 20)
voteRow.Size = UDim2.new(1, 0, 0, 40)
voteRow.Parent = voteBox
local vrl = Instance.new("UIListLayout", voteRow)
vrl.FillDirection = Enum.FillDirection.Horizontal
vrl.HorizontalAlignment = Enum.HorizontalAlignment.Center
vrl.Padding = UDim.new(0, 8)
vrl.SortOrder = Enum.SortOrder.LayoutOrder
local voteBtns = {}
local myVote = nil
for i = 1, 3 do
	local b = Instance.new("TextButton")
	b.Size = UDim2.new(0.33, -8, 1, 0)
	b.LayoutOrder = i
	b.BackgroundColor3 = COL_ROW
	b.BorderSizePixel = 0
	b.Font = FONT
	b.TextSize = 14
	b.TextColor3 = COL_TEXT
	b.Text = ""
	b.Parent = voteRow
	Instance.new("UICorner", b).CornerRadius = UDim.new(0, 6)
	b.Activated:Connect(function()
		if voteRemote and roundNode:GetAttribute("Vote" .. i) ~= "" then
			myVote = i
			voteRemote:FireServer("map", i)
		end
	end)
	voteBtns[i] = b
end

-- Warfront: the next MODE is voted too (ModeVote1..3), above the map vote
local modeBox = Instance.new("Frame")
modeBox.BackgroundTransparency = 1
modeBox.Size = UDim2.new(1, 0, 0, 62)
modeBox.LayoutOrder = -2
modeBox.Visible = false
modeBox.Parent = board
local modeTitle = label(modeBox, "VOTE FOR THE NEXT MODE", 12, FONT, COL_DIM)
modeTitle.Size = UDim2.new(1, 0, 0, 16)
modeTitle.TextXAlignment = Enum.TextXAlignment.Center
local modeRow = Instance.new("Frame")
modeRow.BackgroundTransparency = 1
modeRow.Position = UDim2.new(0, 0, 0, 20)
modeRow.Size = UDim2.new(1, 0, 0, 40)
modeRow.Parent = modeBox
local mrl = Instance.new("UIListLayout", modeRow)
mrl.FillDirection = Enum.FillDirection.Horizontal
mrl.HorizontalAlignment = Enum.HorizontalAlignment.Center
mrl.Padding = UDim.new(0, 8)
mrl.SortOrder = Enum.SortOrder.LayoutOrder
local modeBtns = {}
local myModeVote = nil
for i = 1, 3 do
	local b = Instance.new("TextButton")
	b.Size = UDim2.new(0.33, -8, 1, 0)
	b.LayoutOrder = i
	b.BackgroundColor3 = COL_ROW
	b.BorderSizePixel = 0
	b.Font = FONT
	b.TextSize = 14
	b.TextColor3 = COL_TEXT
	b.Text = ""
	b.Parent = modeRow
	Instance.new("UICorner", b).CornerRadius = UDim.new(0, 6)
	b.Activated:Connect(function()
		if voteRemote and roundNode:GetAttribute("ModeVote" .. i) ~= "" then
			myModeVote = i
			voteRemote:FireServer("mode", i)
		end
	end)
	modeBtns[i] = b
end

local COLS = {{"PLAYER", 0.52, Enum.TextXAlignment.Left}, {"KILLS", 0.16, Enum.TextXAlignment.Right},
	{"DEATHS", 0.16, Enum.TextXAlignment.Right}, {"K/D", 0.16, Enum.TextXAlignment.Right}}

local function makeRow(order, header)
	local row = Instance.new("Frame")
	row.Size = UDim2.new(1, 0, 0, header and 26 or 30)
	row.BackgroundColor3 = COL_ROW
	row.BackgroundTransparency = header and 1 or 0.2
	row.BorderSizePixel = 0
	row.LayoutOrder = order
	row.Parent = board
	if not header then Instance.new("UICorner", row).CornerRadius = UDim.new(0, 6) end
	local pad = Instance.new("UIPadding", row)
	pad.PaddingLeft, pad.PaddingRight = UDim.new(0, 10), UDim.new(0, 10)
	local cells, x = {}, 0
	for i, c in ipairs(COLS) do
		local t = label(row, header and c[1] or "", header and 12 or 15, header and FONT or FONT_BODY, header and COL_DIM or COL_TEXT)
		t.Position = UDim2.new(x, 0, 0, 0)
		t.Size = UDim2.new(c[2], 0, 1, 0)
		t.TextXAlignment = c[3]
		cells[i] = t
		x += c[2]
	end
	-- a team stripe on the left edge
	local stripe = Instance.new("Frame")
	stripe.Name = "Stripe"
	stripe.Position = UDim2.new(0, -10, 0, 0)
	stripe.Size = UDim2.new(0, 4, 1, 0)
	stripe.BorderSizePixel = 0
	stripe.Visible = false
	stripe.Parent = row
	return row, cells, stripe
end
makeRow(0, true)
local rows = {}   -- [i] = {row=, cells=, stripe=}

local function refreshBoard()
	local teamMode = (roundNode:GetAttribute("Teams") or 0) == 2
	local list = {}
	for _, p in ipairs(Players:GetPlayers()) do
		local ls = p:FindFirstChild("leaderstats")
		local k = ls and ls:FindFirstChild("Kills");  k = k and k.Value or 0
		local d = ls and ls:FindFirstChild("Deaths"); d = d and d.Value or 0
		table.insert(list, {p = p, k = k, d = d, team = p.Team and p.Team.Name or ""})
	end
	table.sort(list, function(a, b)
		if teamMode and a.team ~= b.team then return a.team < b.team end
		if a.k ~= b.k then return a.k > b.k end
		if a.d ~= b.d then return a.d < b.d end
		return a.p.Name < b.p.Name
	end)
	for i, e in ipairs(list) do
		local r = rows[i]
		if not r then
			local row, cells, stripe = makeRow(i, false)
			r = {row = row, cells = cells, stripe = stripe}
			rows[i] = r
		end
		r.row.Visible = true
		local mine = e.p == player
		local tc = teamMode and teamColorOf(e.p) or nil
		r.cells[1].Text = e.p.DisplayName .. (mine and "  (you)" or "")
		r.cells[1].TextColor3 = mine and COL_ME or (tc or COL_TEXT)
		r.cells[1].Font = mine and FONT or FONT_BODY
		r.cells[2].Text = tostring(e.k)
		r.cells[3].Text = tostring(e.d)
		r.cells[4].Text = e.d > 0 and string.format("%.2f", e.k / e.d) or (e.k > 0 and "∞" or "–")
		r.stripe.Visible = tc ~= nil
		if tc then r.stripe.BackgroundColor3 = tc end
	end
	for i = #list + 1, #rows do rows[i].row.Visible = false end
end

--------------------------------------------------------------------
--  ROUND STATE
--------------------------------------------------------------------
local function intermission() return roundNode:GetAttribute("State") == "Intermission" end
local function hubMenuUp()
	local pg = player:FindFirstChild("PlayerGui")
	local h = pg and pg:FindFirstChild("HubMenu")
	return h ~= nil and h.Enabled
end

local function refreshRound()
	-- the menu has its own top bar (the wallet sits where this strip is)
	strip.Visible = not hubMenuUp()
	local left = roundNode:GetAttribute("TimeLeft") or 0
	local m, sec = math.floor(left / 60), left % 60
	local modeName = roundNode:GetAttribute("ModeName") or ""
	local map = roundNode:GetAttribute("Map") or ""
	local teams = roundNode:GetAttribute("Teams") or 0
	local obj = roundNode:GetAttribute("Objective") or ""
	local number = roundNode:GetAttribute("Number") or 1
	if intermission() then
		timer.Text = string.format("NEXT ROUND IN %d", left)
		timer.TextColor3 = COL_ACCENT
		local nxt = GameConfig.MODES[roundNode:GetAttribute("NextMode") or ""]
		objective.Text = nxt and ("next:  " .. string.upper(nxt.name)) or ""
		scoreRow.Visible = false
		banner.Visible = true
		local w = roundNode:GetAttribute("Winner") or ""
		local wk = roundNode:GetAttribute("WinnerKills") or 0
		local result = obj
		if result == "" then result = w ~= "" and string.format("%s WINS%s", string.upper(w), wk > 0 and string.format(" WITH %d KILLS", wk) or "") or "NO KILLS" end
		banner.Text = string.format("ROUND %d OVER  ·  %s", number, result)
		-- vote
		local any = false
		for i = 1, 3 do
			local name = roundNode:GetAttribute("Vote" .. i) or ""
			local n = roundNode:GetAttribute("Votes" .. i) or 0
			voteBtns[i].Visible = name ~= ""
			if name ~= "" then
				any = true
				voteBtns[i].Text = string.format("%s   %d", name, n)
				voteBtns[i].BackgroundColor3 = myVote == i and COL_ROW_ON or COL_ROW
			end
		end
		voteBox.Visible = any and voteRemote ~= nil
		local anyMode = false
		for i = 1, 3 do
			local name = roundNode:GetAttribute("ModeVote" .. i) or ""
			local n = roundNode:GetAttribute("ModeVotes" .. i) or 0
			modeBtns[i].Visible = name ~= ""
			if name ~= "" then
				anyMode = true
				modeBtns[i].Text = string.format("%s   %d", name, n)
				modeBtns[i].BackgroundColor3 = myModeVote == i and COL_ROW_ON or COL_ROW
			end
		end
		modeBox.Visible = anyMode and voteRemote ~= nil
		if roundNode:GetAttribute("MatchOver") == true then
			voteBox.Visible = false; modeBox.Visible = false
			timer.Text = "MATCH OVER  ·  back to the Courtyard"
		end
	else
		myVote = nil
		myModeVote = nil
		local clock = (roundNode:GetAttribute("Mode") == "Hub" or roundNode:GetAttribute("Mode") == "Tiltyard") and "" or string.format("   %d:%02d", m, sec)
		local bracket = roundNode:GetAttribute("Bracket") or ""
		local tag = bracket ~= "" and ("  ·  " .. bracket .. (roundNode:GetAttribute("Ranked") == true and " RANKED" or "")) or ""
		local server = roundNode:GetAttribute("ServerName") or ""
		if roundNode:GetAttribute("NoRewards") == true then tag = tag .. "  ·  NO REWARDS" end
		timer.Text = string.format("%s%s%s%s%s", server ~= "" and (string.upper(server) .. "  ·  ") or "", string.upper(modeName), map ~= "" and ("  ·  " .. string.upper(map)) or "", tag, clock)
		timer.TextColor3 = COL_TEXT
		objective.Text = obj
		banner.Visible = false
		voteBox.Visible = false
		scoreRow.Visible = teams == 2
		if teams == 2 then
			scoreA.Text = string.format("%s  %d", string.upper(GameConfig.TEAMS.A.name), roundNode:GetAttribute("ScoreA") or 0)
			scoreB.Text = string.format("%d  %s", roundNode:GetAttribute("ScoreB") or 0, string.upper(GameConfig.TEAMS.B.name))
		end
	end
end

local holding = false
local function setBoard(on)
	if holding == on then return end
	holding = on
	board.Visible = on or (intermission() and not hubMenuUp())
	if board.Visible then refreshBoard() end
end
UserInputService.InputBegan:Connect(function(input, gp)
	if input.KeyCode == BOARD_KEY and not UserInputService:GetFocusedTextBox() then setBoard(true) end
end)
UserInputService.InputEnded:Connect(function(input)
	if input.KeyCode == BOARD_KEY then setBoard(false) end
end)
UserInputService.WindowFocusReleased:Connect(function() setBoard(false) end)
-- live while held (or during the intermission)
local acc = 0
RunService.RenderStepped:Connect(function(dt)
	acc += dt
	if acc > 0.25 then
		acc = 0
		refreshRound()
		local show = holding or (intermission() and not hubMenuUp())
		if board.Visible ~= show then board.Visible = show end
		-- the class screen (DisplayOrder 2000) is up during the intermission: sit above it
		gui.DisplayOrder = intermission() and 2100 or 30
		if show then refreshBoard() end
	end
end)
refreshRound()
