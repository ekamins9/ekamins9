--[[ SCOREBOARD (client) — the kill feed (top right, entries fade out), the
     round strip top-centre (mode · map · clock, the mode's objective line,
     team scores in team modes) and the leaderboard you see while HOLDING
     Tab: every player's kills, deaths and K/D, sorted by kills, team-coloured.
     During the intermission the board stays up, wide, with the result banner
     and the VOTE: three big cards with a picture of each map (ReplicatedStorage ▸
     MapShots ▸ <map>: a StringValue / Decal / ImageLabel with the image, made in
     Studio) › VoteRemote: battles on the Warfront, maps elsewhere. Replaces
     Roblox's own player list. Built from Instances. Lives in StarterPlayerScripts. ]]

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
local COL_GOLD   = Color3.fromRGB(255, 206, 84)    -- season pass holders
local COL_TITLE  = Color3.fromRGB(255, 226, 168)   -- titles
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
	arrow     = "shot",
	headshot  = "shot through the head",
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
	-- a name: yours in your colour, a team's in its colour, a pass holder's in gold with a
	-- crown; the killer's title after it (not the free Recruit)
	local function name(n, id, withTitle)
		local col = (id ~= 0 and id == player.UserId) and COL_ME or COL_TEXT
		local plr = id ~= 0 and Players:GetPlayerByUserId(id)
		local tc = plr and teamColorOf(plr)
		if tc and not (id == player.UserId) then col = tc end
		local pass = plr and plr:GetAttribute("PassHolder") == true
		if pass and not tc and id ~= player.UserId then col = COL_GOLD end
		local s = (pass and string.format('<font color="#%s">♛</font> ', COL_GOLD:ToHex()) or "") .. string.format('<font color="#%s"><b>%s</b></font>', col:ToHex(), n)
		local title = withTitle and plr and plr:GetAttribute("Title") or ""
		if title ~= "" and title ~= "Recruit" then s ..= string.format(' <font color="#%s" size="12"><i>%s</i></font>', COL_TITLE:ToHex(), title) end
		return s
	end
	local victim = name(e.victim or "?", e.victimId or 0)
	if e.kind == "bleed" and e.killer then
		t.Text = string.format('%s  <font color="#%s">bled out after</font>  %s%s', victim, COL_DIM:ToHex(), name(e.killer, e.killerId),
			e.weapon ~= "" and string.format('  <font color="#%s">(%s)</font>', COL_DIM:ToHex(), e.weapon) or "")
	elseif e.killer then
		local verb = VERB[e.kind] or "killed"
		if e.teamkill then verb = "TEAMKILLED" end
		t.Text = string.format('%s  <font color="#%s">%s</font>  %s%s', name(e.killer, e.killerId, true), (e.teamkill and COL_TK or COL_KILL):ToHex(), verb, victim,
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
-- your pay for the round (HubEvent "Rewards"), under the result
local payLine = label(board, "", 14, FONT, Color3.fromRGB(255, 214, 110))
payLine.Size = UDim2.new(1, 0, 0, 20)
payLine.LayoutOrder = -2
payLine.TextXAlignment = Enum.TextXAlignment.Center
payLine.Visible = false
local hubEvent = ReplicatedStorage:FindFirstChild("HubEvent") or ReplicatedStorage:WaitForChild("HubEvent", 10)
if hubEvent then
	hubEvent.OnClientEvent:Connect(function(what, r)
		if what ~= "Rewards" or type(r) ~= "table" then return end
		if r.blocked then payLine.Text = "NO REWARDS ON A CHEAT SERVER"
		else
			local bits = {}
			if r.won then table.insert(bits, r.firstWin and "VICTORY · FIRST WIN OF THE DAY" or "VICTORY") end
			table.insert(bits, string.format("+%d MARKS", r.marks or 0))
			table.insert(bits, string.format("+%d XP", r.xp or 0))
			if (r.levels or 0) > 0 then table.insert(bits, "LEVEL " .. tostring(r.level) .. "!") end
			if r.delta then table.insert(bits, string.format("RATING %s%d", r.delta >= 0 and "+" or "", r.delta)) end
			payLine.Text = table.concat(bits, "   ·   ")
		end
		payLine.Visible = true
	end)
end

-- the vote: three cards. On the Warfront each is a BATTLE (a mode on a map:
-- VoteMode1..3 + Vote1..3); elsewhere the cards are maps for the same mode
local CATEGORY_COL = {Objective = Color3.fromRGB(226, 172, 60), Battlefield = Color3.fromRGB(206, 70, 60), Arena = Color3.fromRGB(70, 140, 220), Horde = Color3.fromRGB(120, 180, 90)}
local VOTE_H = 236          -- the vote row's height (a card: the map's picture, its name over it)
local BOARD_W, BOARD_WIDE = 560, 1000   -- the board's width: held on Tab / in the intermission
local voteBox = Instance.new("Frame")
voteBox.BackgroundTransparency = 1
voteBox.Size = UDim2.new(1, 0, 0, VOTE_H + 30)
voteBox.LayoutOrder = -1
voteBox.Visible = false
voteBox.Parent = board
local voteTitle = label(voteBox, "VOTE FOR THE NEXT MAP", 16, FONT_BLACK, COL_ACCENT)
voteTitle.Name = "VoteTitle"
voteTitle.Size = UDim2.new(1, 0, 0, 22)
voteTitle.TextXAlignment = Enum.TextXAlignment.Center
local voteRow = Instance.new("Frame")
voteRow.BackgroundTransparency = 1
voteRow.Position = UDim2.new(0, 0, 0, 28)
voteRow.Size = UDim2.new(1, 0, 0, VOTE_H)
voteRow.Parent = voteBox
local vrl = Instance.new("UIListLayout", voteRow)
vrl.FillDirection = Enum.FillDirection.Horizontal
vrl.HorizontalAlignment = Enum.HorizontalAlignment.Center
vrl.Padding = UDim.new(0, 12)
vrl.SortOrder = Enum.SortOrder.LayoutOrder
local voteCards = {}
local myVote = nil
for i = 1, 3 do
	local b = Instance.new("TextButton")
	b.Size = UDim2.new(0.33, -8, 1, 0)
	b.LayoutOrder = i
	b.BackgroundColor3 = COL_ROW
	b.BorderSizePixel = 0
	b.AutoButtonColor = true
	b.Text = ""
	b.ClipsDescendants = true
	b.Parent = voteRow
	Instance.new("UICorner", b).CornerRadius = UDim.new(0, 10)
	local stroke = Instance.new("UIStroke", b)
	stroke.Color = COL_ACCENT
	stroke.Thickness = 3
	stroke.Enabled = false
	-- the map's picture fills the card
	local shot = Instance.new("ImageLabel")
	shot.Name = "Shot"
	shot.Size = UDim2.fromScale(1, 1)
	shot.BackgroundColor3 = COL_ROW
	shot.BorderSizePixel = 0
	shot.ScaleType = Enum.ScaleType.Crop
	shot.Image = ""
	shot.Parent = b
	Instance.new("UICorner", shot).CornerRadius = UDim.new(0, 10)
	-- a dark fade at the foot so the name reads over any picture
	local fade = Instance.new("Frame")
	fade.AnchorPoint = Vector2.new(0, 1)
	fade.Position = UDim2.fromScale(0, 1)
	fade.Size = UDim2.new(1, 0, 0.55, 0)
	fade.BackgroundColor3 = Color3.new(0, 0, 0)
	fade.BorderSizePixel = 0
	fade.Parent = b
	local fg = Instance.new("UIGradient", fade)
	fg.Rotation = 90
	fg.Transparency = NumberSequence.new({NumberSequenceKeypoint.new(0, 1), NumberSequenceKeypoint.new(0.45, 0.35), NumberSequenceKeypoint.new(1, 0.1)})
	Instance.new("UICorner", fade).CornerRadius = UDim.new(0, 10)
	local band = Instance.new("Frame")
	band.Size = UDim2.new(1, 0, 0, 6)
	band.BorderSizePixel = 0
	band.Parent = b
	local big = label(b, "", 24, FONT_BLACK, COL_TEXT)
	big.AnchorPoint = Vector2.new(0, 1)
	big.Position = UDim2.new(0, 14, 1, -40)
	big.Size = UDim2.new(1, -28, 0, 28)
	big.TextTruncate = Enum.TextTruncate.AtEnd
	big.TextStrokeTransparency = 0.6
	local small = label(b, "", 15, FONT, Color3.fromRGB(225, 225, 225))
	small.AnchorPoint = Vector2.new(0, 1)
	small.Position = UDim2.new(0, 14, 1, -20)
	small.Size = UDim2.new(1, -90, 0, 18)
	small.TextTruncate = Enum.TextTruncate.AtEnd
	local tag = label(b, "", 11, FONT_BODY, Color3.fromRGB(200, 200, 200))
	tag.AnchorPoint = Vector2.new(0, 1)
	tag.Position = UDim2.new(0, 14, 1, -6)
	tag.Size = UDim2.new(1, -90, 0, 14)
	tag.TextTruncate = Enum.TextTruncate.AtEnd
	-- the votes so far, in a badge in the corner
	local badge = Instance.new("Frame")
	badge.AnchorPoint = Vector2.new(1, 0)
	badge.Position = UDim2.new(1, -10, 0, 14)
	badge.Size = UDim2.fromOffset(46, 46)
	badge.BackgroundColor3 = Color3.fromRGB(16, 16, 20)
	badge.BackgroundTransparency = 0.2
	badge.Parent = b
	Instance.new("UICorner", badge).CornerRadius = UDim.new(1, 0)
	local count = label(badge, "0", 24, FONT_BLACK, COL_TEXT)
	count.Size = UDim2.fromScale(1, 1)
	count.TextXAlignment = Enum.TextXAlignment.Center
	b.Activated:Connect(function()
		if voteRemote and (roundNode:GetAttribute("Vote" .. i) or "") ~= "" then
			myVote = i
			voteRemote:FireServer("map", i)
		end
	end)
	voteCards[i] = {button = b, stroke = stroke, band = band, big = big, small = small, tag = tag, count = count, shot = shot}
end

-- a map's picture (Studio puts them in ReplicatedStorage ▸ MapShots ▸ <map>)
local function shotOf(map)
	local f = ReplicatedStorage:FindFirstChild("MapShots")
	local v = f and f:FindFirstChild(map)
	if not v then return "" end
	if v:IsA("StringValue") then return v.Value end
	if v:IsA("Decal") then return v.Texture end
	if v:IsA("ImageLabel") or v:IsA("ImageButton") then return v.Image end
	return v:GetAttribute("Image") or ""
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
		table.insert(list, {p = p, name = p.Name, k = k, d = d, team = p.Team and p.Team.Name or ""})
	end
	-- a match's fill bots, until a player takes their place (Game ▸ BotFill)
	local seats = ReplicatedStorage:FindFirstChild("BotScores")
	for _, s in ipairs(seats and seats:GetChildren() or {}) do
		local def = GameConfig.TEAMS[s:GetAttribute("Team") or ""]
		table.insert(list, {bot = s, name = s:GetAttribute("Name") or "Bot", k = s:GetAttribute("Kills") or 0,
			d = s:GetAttribute("Deaths") or 0, team = def and def.name or "", tc = def and def.rgb or nil})
	end
	table.sort(list, function(a, b)
		if teamMode and a.team ~= b.team then return a.team < b.team end
		if a.k ~= b.k then return a.k > b.k end
		if a.d ~= b.d then return a.d < b.d end
		return a.name < b.name
	end)
	for i, e in ipairs(list) do
		local r = rows[i]
		if not r then
			local row, cells, stripe = makeRow(i, false)
			r = {row = row, cells = cells, stripe = stripe}
			rows[i] = r
		end
		r.row.Visible = true
		local mine = e.p ~= nil and e.p == player
		r.cells[1].RichText = true
		local tc
		if e.bot then
			tc = teamMode and e.tc or nil
			r.cells[1].Text = e.name .. string.format('  <font color="#%s" size="12">BOT</font>', COL_DIM:ToHex())
			r.cells[1].TextColor3 = tc or COL_TEXT
		else
			tc = teamMode and teamColorOf(e.p) or nil
			-- the name, a crown for the pass, the title they wear (not the free Recruit)
			local title = e.p:GetAttribute("Title") or ""
			local pass = e.p:GetAttribute("PassHolder") == true
			r.cells[1].Text = (pass and string.format('<font color="#%s">♛</font> ', COL_GOLD:ToHex()) or "") .. e.p.DisplayName .. (mine and "  (you)" or "")
				.. ((title ~= "" and title ~= "Recruit") and string.format('  <font color="#%s" size="12"><i>%s</i></font>', COL_TITLE:ToHex(), title) or "")
			r.cells[1].TextColor3 = mine and COL_ME or (tc or (pass and COL_GOLD) or COL_TEXT)
		end
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
	local map = roundNode:GetAttribute("MapName") or roundNode:GetAttribute("Map") or ""
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
		-- vote: the cards
		local any, battles = false, false
		for i = 1, 3 do
			local map = roundNode:GetAttribute("Vote" .. i) or ""
			local modeId = roundNode:GetAttribute("VoteMode" .. i) or ""
			local n = roundNode:GetAttribute("Votes" .. i) or 0
			local c = voteCards[i]
			c.button.Visible = map ~= ""
			if map ~= "" then
				any = true
				local md = GameConfig.MODES[modeId]
				local title = GameConfig.mapTitle(map)
				local img = shotOf(map)
				c.shot.Image = img
				c.shot.BackgroundColor3 = img ~= "" and COL_ROW or ((md and CATEGORY_COL[md.category] or COL_ACCENT):Lerp(Color3.new(0, 0, 0), 0.55))
				if md then
					battles = true
					c.big.Text = string.upper(md.name)
					c.small.Text = title
					c.tag.Text = string.upper(md.category or "")
					c.band.BackgroundColor3 = CATEGORY_COL[md.category] or COL_ACCENT
				else
					c.big.Text = string.upper(title)
					c.small.Text = ""
					c.tag.Text = ""
					c.band.BackgroundColor3 = COL_ACCENT
				end
				c.count.Text = tostring(n)
				c.button.BackgroundColor3 = myVote == i and COL_ROW_ON or COL_ROW
				c.stroke.Enabled = myVote == i
				c.shot.ImageTransparency = (myVote and myVote ~= i) and 0.35 or 0
			end
		end
		voteTitle.Text = battles and "VOTE FOR THE NEXT BATTLE" or "VOTE FOR THE NEXT MAP"
		voteBox.Visible = any and voteRemote ~= nil
		if roundNode:GetAttribute("MatchOver") == true then
			voteBox.Visible = false
			timer.Text = "MATCH OVER  ·  back to the Courtyard"
		end
	else
		myVote = nil
		local clock = (roundNode:GetAttribute("Mode") == "Hub" or roundNode:GetAttribute("Mode") == "Tiltyard") and "" or string.format("   %d:%02d", m, sec)
		local bracket = roundNode:GetAttribute("Bracket") or ""
		local tag = bracket ~= "" and ("  ·  " .. bracket .. (roundNode:GetAttribute("Ranked") == true and " RANKED" or "")) or ""
		local server = roundNode:GetAttribute("ServerName") or ""
		if roundNode:GetAttribute("NoRewards") == true then tag = tag .. "  ·  NO REWARDS" end
		timer.Text = string.format("%s%s%s%s%s", server ~= "" and (string.upper(server) .. "  ·  ") or "", string.upper(modeName), map ~= "" and ("  ·  " .. string.upper(map)) or "", tag, clock)
		timer.TextColor3 = COL_TEXT
		objective.Text = obj
		banner.Visible = false
		payLine.Visible = false
		voteBox.Visible = false
		scoreRow.Visible = teams == 2
		if teams == 2 then
			scoreA.Text = string.format("%s  %d", string.upper(GameConfig.TEAMS.A.name), roundNode:GetAttribute("ScoreA") or 0)
			scoreB.Text = string.format("%d  %s", roundNode:GetAttribute("ScoreB") or 0, string.upper(GameConfig.TEAMS.B.name))
		end
	end
end

-- wide for the vote, narrow when it's just the scores on Tab
local function sizeBoard()
	local cam = workspace.CurrentCamera
	local w = intermission() and math.min(BOARD_WIDE, (cam and cam.ViewportSize.X or 1200) - 60) or BOARD_W
	if board.Size.X.Offset ~= w then board.Size = UDim2.fromOffset(w, 60) end
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
		sizeBoard()
		local show = holding or (intermission() and not hubMenuUp())
		if board.Visible ~= show then board.Visible = show end
		-- the class screen (DisplayOrder 2000) is up during the intermission: sit above it
		gui.DisplayOrder = intermission() and 2100 or 30
		if show then refreshBoard() end
	end
end)
refreshRound()
