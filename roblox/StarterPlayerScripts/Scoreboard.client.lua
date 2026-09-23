--[[ SCOREBOARD (client) — the kill feed (top right, entries fade out) and
     the leaderboard you see while HOLDING Tab: every player's kills, deaths
     and K/D, sorted by kills. Replaces Roblox's own player list. Built from
     Instances. Lives in StarterPlayerScripts so it survives death. ]]

local Players           = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService  = game:GetService("UserInputService")
local RunService        = game:GetService("RunService")
local StarterGui        = game:GetService("StarterGui")
local TweenService      = game:GetService("TweenService")

local player = Players.LocalPlayer
local remote = ReplicatedStorage:WaitForChild("KillFeedRemote")

--------------------------------------------------------------------
local FEED_MAX     = 6
local FEED_TTL     = 7      -- seconds an entry stays
local BOARD_KEY    = Enum.KeyCode.Tab
local FONT, FONT_BODY = Enum.Font.GothamBold, Enum.Font.Gotham
local COL_TEXT   = Color3.fromRGB(235, 228, 214)
local COL_DIM    = Color3.fromRGB(160, 150, 135)
local COL_ACCENT = Color3.fromRGB(196, 150, 70)
local COL_ME     = Color3.fromRGB(120, 170, 100)
local COL_KILL   = Color3.fromRGB(215, 90, 70)
local COL_PANEL  = Color3.fromRGB(24, 22, 20)
local COL_ROW    = Color3.fromRGB(38, 35, 31)
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
		return string.format('<font color="#%s"><b>%s</b></font>', col:ToHex(), n)
	end
	local victim = name(e.victim or "?", e.victimId or 0)
	if e.kind == "bleed" and e.killer then
		t.Text = string.format('%s  <font color="#%s">bled out after</font>  %s%s', victim, COL_DIM:ToHex(), name(e.killer, e.killerId),
			e.weapon ~= "" and string.format('  <font color="#%s">(%s)</font>', COL_DIM:ToHex(), e.weapon) or "")
	elseif e.killer then
		local verb = VERB[e.kind] or "killed"
		t.Text = string.format('%s  <font color="#%s">%s</font>  %s%s', name(e.killer, e.killerId), COL_KILL:ToHex(), verb, victim,
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
--  LEADERBOARD (hold Tab)
--------------------------------------------------------------------
local board = Instance.new("Frame")
board.Name = "Leaderboard"
board.AnchorPoint = Vector2.new(0.5, 0)
board.Position = UDim2.new(0.5, 0, 0, 60)
board.Size = UDim2.fromOffset(520, 60)
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
	return row, cells
end
makeRow(0, true)
local rows = {}   -- [i] = {row=, cells=}

local function refreshBoard()
	local list = {}
	for _, p in ipairs(Players:GetPlayers()) do
		local ls = p:FindFirstChild("leaderstats")
		local k = ls and ls:FindFirstChild("Kills");  k = k and k.Value or 0
		local d = ls and ls:FindFirstChild("Deaths"); d = d and d.Value or 0
		table.insert(list, {p = p, k = k, d = d})
	end
	table.sort(list, function(a, b)
		if a.k ~= b.k then return a.k > b.k end
		if a.d ~= b.d then return a.d < b.d end
		return a.p.Name < b.p.Name
	end)
	for i, e in ipairs(list) do
		local r = rows[i]
		if not r then
			local row, cells = makeRow(i, false)
			r = {row = row, cells = cells}
			rows[i] = r
		end
		r.row.Visible = true
		local mine = e.p == player
		r.cells[1].Text = e.p.DisplayName .. (mine and "  (you)" or "")
		r.cells[1].TextColor3 = mine and COL_ME or COL_TEXT
		r.cells[1].Font = mine and FONT or FONT_BODY
		r.cells[2].Text = tostring(e.k)
		r.cells[3].Text = tostring(e.d)
		r.cells[4].Text = e.d > 0 and string.format("%.2f", e.k / e.d) or (e.k > 0 and "∞" or "–")
	end
	for i = #list + 1, #rows do rows[i].row.Visible = false end
end

--------------------------------------------------------------------
--  ROUND: timer top-centre; the board stays up through the intermission
--------------------------------------------------------------------
local roundNode = ReplicatedStorage:FindFirstChild("Round")
local timer = label(gui, "", 18, FONT, COL_TEXT)
timer.AnchorPoint = Vector2.new(0.5, 0)
timer.Position = UDim2.new(0.5, 0, 0, 14)
timer.Size = UDim2.fromOffset(420, 24)
timer.TextXAlignment = Enum.TextXAlignment.Center
timer.TextStrokeTransparency = 0.5
local banner = label(board, "", 16, FONT, COL_ACCENT)
banner.Size = UDim2.new(1, 0, 0, 24)
banner.LayoutOrder = -1
banner.TextXAlignment = Enum.TextXAlignment.Center
banner.Visible = false

local function intermission()
	return roundNode ~= nil and roundNode:GetAttribute("State") == "Intermission"
end

local function refreshRound()
	if not roundNode then
		roundNode = ReplicatedStorage:FindFirstChild("Round")
		if not roundNode then timer.Text = ""; return end
	end
	local left = roundNode:GetAttribute("TimeLeft") or 0
	local m, sec = math.floor(left / 60), left % 60
	if intermission() then
		local w = roundNode:GetAttribute("Winner") or ""
		timer.Text = string.format("NEXT ROUND IN %d", left)
		timer.TextColor3 = COL_ACCENT
		banner.Visible = true
		banner.Text = w ~= "" and string.format("ROUND %d OVER  ·  %s WINS WITH %d KILLS", (roundNode:GetAttribute("Number") or 1), string.upper(w), roundNode:GetAttribute("WinnerKills") or 0)
			or string.format("ROUND %d OVER  ·  NO KILLS", roundNode:GetAttribute("Number") or 1)
	else
		timer.Text = string.format("ROUND %d   %d:%02d", roundNode:GetAttribute("Number") or 1, m, sec)
		timer.TextColor3 = COL_TEXT
		banner.Visible = false
	end
end

local holding = false
local function setBoard(on)
	if holding == on then return end
	holding = on
	board.Visible = on or intermission()
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
	if acc > 0.5 then
		acc = 0
		refreshRound()
		local show = holding or intermission()
		if board.Visible ~= show then board.Visible = show end
		if show then refreshBoard() end
	end
end)
refreshRound()
