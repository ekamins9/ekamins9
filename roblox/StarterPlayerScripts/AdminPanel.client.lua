--[[ ADMIN PANEL (client) — for staff only (the server sets StaffRole on you;
     Admin ▸ AdminServer decides everything). F2 or the ADMIN button opens it.
       PLAYERS  everyone here, or look anyone up by name or id: kick, ban,
                unban, freeze, go to, bring, heal, kill, give / take Marks and
                Crowns, set level, give / take any item, unlock everything,
                wipe their data
       SERVER   end the round, pick the next mode and map, announce (this
                server or every server), spawn / clear bots, shut down
       STAFF    who has which role; give and take roles below your own
       BANS     who's banned, until when, why; unban
       LOG      every staff action
     Buttons your role can't use aren't shown. The announcement banner
     (AdminEvent "Announce") shows for everyone. ]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

local Catalog = require(ReplicatedStorage:WaitForChild("Catalog"))
local GameConfig = require(ReplicatedStorage:WaitForChild("GameConfig"))
local Theme = require(ReplicatedStorage:WaitForChild("Theme"))

local player = Players.LocalPlayer
local remote = ReplicatedStorage:WaitForChild("AdminRemote", 30)
local event = ReplicatedStorage:WaitForChild("AdminEvent", 30)
if not (remote and event) then return end

local WHITE = Color3.new(1, 1, 1)
local gui = Instance.new("ScreenGui")
gui.Name = "AdminPanel"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = true
gui.DisplayOrder = 9000   -- above every menu (the hub menu, the class screen)
gui.Parent = player:WaitForChild("PlayerGui")

local function call(op, ...)
	local ok, res = pcall(remote.InvokeServer, remote, op, ...)
	if ok and type(res) == "table" then return res end
	return {ok = false, msg = ok and "no answer" or tostring(res)}
end

--------------------------------------------------------------------
--  BUILDING BLOCKS
--------------------------------------------------------------------
local function corner(o, r) local c = Instance.new("UICorner"); c.CornerRadius = UDim.new(0, r or 8); c.Parent = o end
local function label(parent, text, size, color, font, align)
	local l = Instance.new("TextLabel")
	l.BackgroundTransparency = 1
	l.Font = font or Theme.FONT
	l.TextSize = size or 14
	l.TextColor3 = color or WHITE
	l.TextXAlignment = align or Enum.TextXAlignment.Left
	l.TextWrapped = true
	l.Text = text or ""
	l.Size = UDim2.new(1, 0, 0, (size or 14) + 6)
	l.Parent = parent
	return l
end
local function button(parent, text, color, w, h)
	local b = Instance.new("TextButton")
	b.Text = text
	b.Font = Theme.FONT
	b.TextSize = 14
	b.TextColor3 = WHITE
	b.AutoButtonColor = true
	b.BackgroundColor3 = color or Theme.GLASS2
	b.Size = UDim2.fromOffset(w or 120, h or 32)
	b.Parent = parent
	corner(b, 7)
	return b
end
local function box(parent, placeholder, w, h)
	local t = Instance.new("TextBox")
	t.PlaceholderText = placeholder or ""
	t.Text = ""
	t.ClearTextOnFocus = false
	t.Font = Theme.FONT_BODY
	t.TextSize = 14
	t.TextColor3 = WHITE
	t.PlaceholderColor3 = Theme.DIM
	t.BackgroundColor3 = Color3.fromRGB(8, 10, 20)
	t.Size = UDim2.fromOffset(w or 160, h or 32)
	t.TextXAlignment = Enum.TextXAlignment.Left
	t.Parent = parent
	corner(t, 7)
	local pad = Instance.new("UIPadding"); pad.PaddingLeft = UDim.new(0, 8); pad.Parent = t
	return t
end
local function flow(parent, height, gap)
	local f = Instance.new("Frame")
	f.BackgroundTransparency = 1
	f.Size = UDim2.new(1, 0, 0, height or 34)
	f.AutomaticSize = Enum.AutomaticSize.Y
	f.Parent = parent
	local l = Instance.new("UIGridLayout")
	l.CellPadding = UDim2.fromOffset(gap or 6, gap or 6)
	l.CellSize = UDim2.fromOffset(126, 32)
	l.SortOrder = Enum.SortOrder.LayoutOrder
	l.Parent = f
	return f, l
end
local function hrow(parent, height)
	local f = Instance.new("Frame")
	f.BackgroundTransparency = 1
	f.Size = UDim2.new(1, 0, 0, height or 34)
	f.Parent = parent
	local l = Instance.new("UIListLayout")
	l.FillDirection = Enum.FillDirection.Horizontal
	l.Padding = UDim.new(0, 6)
	l.VerticalAlignment = Enum.VerticalAlignment.Center
	l.SortOrder = Enum.SortOrder.LayoutOrder
	l.Parent = f
	return f
end
local function vlist(parent, gap)
	local l = Instance.new("UIListLayout")
	l.Padding = UDim.new(0, gap or 6)
	l.SortOrder = Enum.SortOrder.LayoutOrder
	l.Parent = parent
	return l
end
local function scroller(parent)
	local s = Instance.new("ScrollingFrame")
	s.BackgroundTransparency = 1
	s.BorderSizePixel = 0
	s.ScrollBarThickness = 5
	s.CanvasSize = UDim2.new()
	s.AutomaticCanvasSize = Enum.AutomaticSize.Y
	s.Size = UDim2.fromScale(1, 1)
	s.Parent = parent
	return s
end
-- (layouts go too: each render adds its own)
local function clear(o) for _, c in ipairs(o:GetChildren()) do c:Destroy() end end
local function heading(parent, text) local l = label(parent, text, 13, Theme.ACCENT, Theme.FONT); return l end

--------------------------------------------------------------------
--  WHO AM I
--------------------------------------------------------------------
local me = {perms = {}, roles = {}, order = {}}
local function can(perm) for _, p in ipairs(me.perms or {}) do if p == perm then return true end end return false end
local function roleColor(role) local r = role and me.roles[role]; return r and r.color or Theme.DIM end

--------------------------------------------------------------------
--  THE PANEL
--------------------------------------------------------------------
local toggle = button(gui, "ADMIN  ·  F2", Color3.fromRGB(150, 40, 40), 100, 26)
toggle.AnchorPoint = Vector2.new(1, 0)
toggle.Position = UDim2.new(1, -12, 0, 10)
toggle.TextSize = 12
toggle.Visible = false

local panel = Instance.new("Frame")
panel.AnchorPoint = Vector2.new(0.5, 0.5)
panel.Position = UDim2.fromScale(0.5, 0.52)
panel.Size = UDim2.fromOffset(1010, 640)
panel.BackgroundColor3 = Theme.GLASS
panel.BackgroundTransparency = 0.04
panel.Visible = false
panel.Parent = gui
corner(panel, 14)
local stroke = Instance.new("UIStroke"); stroke.Color = WHITE; stroke.Transparency = 0.8; stroke.Thickness = 1.5; stroke.Parent = panel

local title = label(panel, "ADMIN PANEL", 24, WHITE, Theme.FONT_TITLE)
title.Position = UDim2.fromOffset(18, 12); title.Size = UDim2.fromOffset(300, 30)
local badge = label(panel, "", 14, WHITE, Theme.FONT)
badge.Position = UDim2.fromOffset(200, 18); badge.Size = UDim2.fromOffset(200, 20)
local closeB = button(panel, "X", Theme.RED, 40, 34); closeB.Position = UDim2.new(1, -54, 0, 12)

local tabsRow = hrow(panel, 34); tabsRow.Position = UDim2.fromOffset(18, 52); tabsRow.Size = UDim2.new(1, -36, 0, 34)
local body = Instance.new("Frame"); body.BackgroundTransparency = 1; body.Position = UDim2.fromOffset(18, 96); body.Size = UDim2.new(1, -36, 1, -140); body.Parent = panel
local status = label(panel, "", 14, Theme.DIM, Theme.FONT_BODY); status.Position = UDim2.new(0, 18, 1, -36); status.Size = UDim2.new(1, -36, 0, 22)
local function say(res)
	status.Text = tostring(res.msg or (res.ok and "done" or "failed"))
	status.TextColor3 = res.ok and Theme.GOOD or Theme.BAD
end

local tabs, tabButtons, current = {}, {}, nil
local function showTab(name)
	current = name
	for n, b in pairs(tabButtons) do b.BackgroundColor3 = (n == name) and Theme.BLUE or Theme.GLASS2 end
	clear(body)
	if tabs[name] then tabs[name]() end
end

--------------------------------------------------------------------
--  PLAYERS
--------------------------------------------------------------------
local picked = nil   -- {userId, name, …}
local ITEM_KINDS = {
	{key = "piece", label = "PIECE", list = function() local t = {} for _, p in ipairs(Catalog.PIECES) do table.insert(t, {id = p.id, name = p.name or p.id}) end return t end},
	{key = "skin", label = "SKIN", list = function() local t = {} for _, s in ipairs(Catalog.SKINS) do table.insert(t, {id = s.id, name = s.id}) end return t end},
	{key = "weapon", label = "WEAPON", list = function() local t = {} for _, w in ipairs(Catalog.WEAPONS) do table.insert(t, {id = w.id, name = w.name or w.id}) end return t end},
	{key = "emote", label = "EMOTE", list = function() local t = {} for _, e in ipairs(Catalog.EMOTES) do table.insert(t, {id = e.id, name = e.name or e.id}) end return t end},
	{key = "killfx", label = "KILL FX", list = function() local t = {} for _, f in ipairs(Catalog.KILLFX) do table.insert(t, {id = f.id, name = f.name or f.id}) end return t end},
	{key = "armorfx", label = "FINISH", list = function() local t = {} for _, f in ipairs(Catalog.ARMORFX or {}) do table.insert(t, {id = f.id, name = f.name or f.id}) end return t end},
	{key = "spellfx", label = "SPELL SKIN", list = function() local t = {} for _, s in ipairs(Catalog.SPELLSKINS or {}) do table.insert(t, {id = s.id, name = ((Catalog.SPELLS[s.spell] or {}).name or s.spell) .. " · " .. s.name}) end return t end},
	{key = "companion", label = "COMPANION", list = function() local t = {} for _, c in ipairs(Catalog.COMPANIONS) do table.insert(t, {id = c.id, name = c.name or c.id}) end return t end},
	{key = "egg", label = "EGG", list = function() local t = {} for _, e in ipairs(Catalog.EGGS.eggs) do table.insert(t, {id = e.id, name = e.name or e.id}) end return t end},
	{key = "crate", label = "CRATE", list = function() local t = {} for _, c in ipairs(Catalog.CRATES) do table.insert(t, {id = c.id, name = c.name or c.id}) end return t end},
	{key = "title", label = "TITLE", list = function()
		local t = {}
		for _, x in ipairs(Catalog.BODY.titles or {}) do table.insert(t, {id = x, name = x}) end
		for _, x in ipairs(Catalog.BODY.earnedTitles or {}) do table.insert(t, {id = x.title, name = x.title}) end
		return t end},
	{key = "color", label = "COLOUR", list = function() local t = {} for _, c in ipairs(Catalog.PALETTE) do table.insert(t, {id = c.name, name = c.name}) end return t end},
}
local itemKind, itemId = ITEM_KINDS[1], nil
local armed = {}   -- a dangerous button needs a second press
local function confirm(key, fn)
	if armed[key] and os.clock() - armed[key] < 3 then armed[key] = nil; fn()
	else armed[key] = os.clock(); status.Text = "press again to confirm"; status.TextColor3 = Theme.ACCENT end
end

local function playerCard(area)
	clear(area)
	vlist(area, 8)
	if not picked then label(area, "Pick a player on the left, or look one up by name or id.", 15, Theme.DIM); return end
	local p = picked
	local head = label(area, string.format("%s  (@%s · %d)", p.display or p.name, p.name, p.userId), 20, roleColor(p.role), Theme.FONT_TITLE)
	head.LayoutOrder = 1
	local info = {}
	if p.role then table.insert(info, string.upper(p.role)) end
	table.insert(info, p.here == false and "NOT IN THIS SERVER" or "IN THIS SERVER")
	if p.level then table.insert(info, "level " .. p.level) end
	if p.marks then table.insert(info, p.marks .. " Marks · " .. (p.crowns or 0) .. " Crowns") end
	if p.kills then table.insert(info, p.kills .. " kills") end
	if p.ban then table.insert(info, "BANNED: " .. tostring(p.ban.reason or "")) end
	local inf = label(area, table.concat(info, "   ·   "), 13, Theme.DIM, Theme.FONT_BODY); inf.LayoutOrder = 2
	local function act(action, args)
		args = args or {}
		args.userId = p.userId
		args.name = p.name
		local res = call("Act", action, args)
		say(res)
		return res
	end
	local order = 3
	local function section(name) local h = heading(area, name); h.LayoutOrder = order; order += 1 end
	-- moderation
	if can("kick") or can("ban") or can("tempban") or can("teleport") or can("health") then
		section("MODERATION")
		local r1 = hrow(area); r1.LayoutOrder = order; order += 1
		local reason = box(r1, "reason", 230)
		local hours = box(r1, "hours (0 = for good)", 140)
		if can("kick") then button(r1, "KICK", Theme.RED, 90).Activated:Connect(function() act("kick", {reason = reason.Text}) end) end
		if can("ban") or can("tempban") then
			button(r1, "BAN", Color3.fromRGB(150, 30, 30), 90).Activated:Connect(function() act("ban", {reason = reason.Text, hours = tonumber(hours.Text) or 0}) end)
			if can("ban") then button(r1, "UNBAN", Theme.GLASS2, 90).Activated:Connect(function() act("unban") end) end
		end
		if can("teleport") or can("health") then
			local r2 = hrow(area); r2.LayoutOrder = order; order += 1
			if can("teleport") then
				button(r2, "GO TO", Theme.BLUE, 100).Activated:Connect(function() act("goto") end)
				button(r2, "BRING", Theme.BLUE, 100).Activated:Connect(function() act("bring") end)
				button(r2, "FREEZE", Theme.GLASS2, 100).Activated:Connect(function() act("freeze", {on = true}) end)
				button(r2, "UNFREEZE", Theme.GLASS2, 100).Activated:Connect(function() act("freeze", {on = false}) end)
			end
			if can("health") then
				button(r2, "HEAL", Theme.GREEN, 90).Activated:Connect(function() act("heal") end)
				button(r2, "KILL", Theme.RED, 90).Activated:Connect(function() act("kill") end)
			end
		end
	end
	-- money and level
	if can("currency") or can("progress") then
		section("MARKS · CROWNS · LEVEL")
		local r = hrow(area); r.LayoutOrder = order; order += 1
		if can("currency") then
			local amt = box(r, "amount", 84)
			local function go(kind, sign) local n = math.floor(tonumber(amt.Text) or 0); act("currency", {kind = kind, amount = n * sign}) end
			button(r, "+ MARKS", Theme.GREEN, 84).Activated:Connect(function() go("marks", 1) end)
			button(r, "− MARKS", Theme.GLASS2, 84).Activated:Connect(function() go("marks", -1) end)
			button(r, "+ CROWNS", Theme.GOLD, 90).Activated:Connect(function() go("crowns", 1) end)
			button(r, "− CROWNS", Theme.GLASS2, 90).Activated:Connect(function() go("crowns", -1) end)
		end
		if can("progress") then
			local lvl = box(r, "level", 64)
			button(r, "SET LEVEL", Theme.BLUE, 96).Activated:Connect(function() act("level", {level = tonumber(lvl.Text)}) end)
		end
	end
	-- items
	if can("items") then
		section("ITEMS")
		local kinds, _ = flow(area); kinds.LayoutOrder = order; order += 1
		local listHolder = Instance.new("Frame"); listHolder.BackgroundColor3 = Color3.fromRGB(8, 10, 20); listHolder.Size = UDim2.new(1, 0, 0, 120); listHolder.LayoutOrder = order + 1; listHolder.Parent = area
		corner(listHolder, 8)
		local controls = hrow(area); controls.LayoutOrder = order; order += 2
		local filter = box(controls, "filter", 180)
		local chosen = label(controls, "", 13, Theme.DIM, Theme.FONT_BODY); chosen.Size = UDim2.fromOffset(300, 30)
		local give = button(controls, "GIVE", Theme.GREEN, 90)
		local take = button(controls, "TAKE", Theme.GLASS2, 90)
		local sc = scroller(listHolder)
		local function fill()
			clear(sc)
			local g = Instance.new("UIGridLayout"); g.CellSize = UDim2.fromOffset(170, 26); g.CellPadding = UDim2.fromOffset(4, 4); g.Parent = sc
			local f = string.lower(filter.Text)
			for _, it in ipairs(itemKind.list()) do
				if f == "" or string.lower(it.id):find(f, 1, true) or string.lower(it.name):find(f, 1, true) then
					local b = button(sc, it.name, it.id == itemId and Theme.BLUE or Theme.GLASS2)
					b.TextSize = 12
					b.TextTruncate = Enum.TextTruncate.AtEnd
					b.Activated:Connect(function() itemId = it.id; chosen.Text = itemKind.label .. ": " .. it.id; fill() end)
				end
			end
		end
		for i, k in ipairs(ITEM_KINDS) do
			local b = button(kinds, k.label, k == itemKind and Theme.BLUE or Theme.GLASS2)
			b.LayoutOrder = i
			b.Activated:Connect(function()
				itemKind, itemId = k, nil
				chosen.Text = ""
				for _, c in ipairs(kinds:GetChildren()) do if c:IsA("TextButton") then c.BackgroundColor3 = Theme.GLASS2 end end
				b.BackgroundColor3 = Theme.BLUE
				fill()
			end)
		end
		filter:GetPropertyChangedSignal("Text"):Connect(fill)
		give.Activated:Connect(function() if itemId then act("item", {kind = itemKind.key, id = itemId}) else say({ok = false, msg = "pick an item"}) end end)
		take.Activated:Connect(function() if itemId then act("item", {kind = itemKind.key, id = itemId, take = true}) else say({ok = false, msg = "pick an item"}) end end)
		fill()
	end
	-- the big ones
	if can("unlock") or can("reset") then
		section("EVERYTHING")
		local r = hrow(area); r.LayoutOrder = order; order += 1
		if can("unlock") then button(r, "UNLOCK EVERYTHING", Theme.GOLD, 190).Activated:Connect(function() confirm("unlock" .. p.userId, function() act("unlockall") end) end) end
		if can("reset") then button(r, "WIPE SAVED DATA", Color3.fromRGB(150, 30, 30), 190).Activated:Connect(function() confirm("reset" .. p.userId, function() act("reset") end) end) end
	end
end

tabs.PLAYERS = function()
	local left = Instance.new("Frame"); left.BackgroundTransparency = 1; left.Size = UDim2.new(0, 250, 1, 0); left.Parent = body
	local right = Instance.new("Frame"); right.BackgroundTransparency = 1; right.Position = UDim2.fromOffset(266, 0); right.Size = UDim2.new(1, -266, 1, 0); right.Parent = body
	local rightScroll = scroller(right)
	local look = hrow(left); look.Size = UDim2.new(1, 0, 0, 34)
	local q = box(look, "name or user id", 164)
	local go = button(look, "LOOK UP", Theme.BLUE, 80)
	local listHolder = Instance.new("Frame"); listHolder.BackgroundTransparency = 1; listHolder.Position = UDim2.fromOffset(0, 44); listHolder.Size = UDim2.new(1, 0, 1, -44); listHolder.Parent = left
	local list = scroller(listHolder)
	vlist(list, 4)
	local function render()
		clear(list)
		vlist(list, 4)
		local res = call("Players")
		if not res.ok then say(res); return end
		for i, row in ipairs(res.players) do
			local b = button(list, "", picked and picked.userId == row.userId and Theme.BLUE or Theme.GLASS2, 240, 36)
			b.LayoutOrder = i
			local n = label(b, row.display .. (row.role and ("  [" .. row.role .. "]") or ""), 14, roleColor(row.role)); n.Position = UDim2.fromOffset(10, 2); n.Size = UDim2.new(1, -20, 0, 18)
			local s = label(b, string.format("@%s · lvl %d%s", row.name, row.level or 1, row.frozen and " · FROZEN" or ""), 11, Theme.DIM, Theme.FONT_BODY); s.Position = UDim2.fromOffset(10, 18); s.Size = UDim2.new(1, -20, 0, 14)
			b.Activated:Connect(function()
				picked = row; picked.here = true
				render()
				playerCard(rightScroll)
			end)
		end
	end
	go.Activated:Connect(function()
		local res = call("Lookup", q.Text)
		if not res.ok then say(res); return end
		picked = res.row or {userId = res.userId, name = res.name, display = res.name, role = res.role}
		picked.here, picked.ban = res.here, res.ban
		say({ok = true, msg = "found " .. res.name})
		playerCard(rightScroll)
	end)
	render()
	playerCard(rightScroll)
end

--------------------------------------------------------------------
--  SERVER
--------------------------------------------------------------------
tabs.SERVER = function()
	local s = scroller(body)
	vlist(s, 8)
	local function act(action, args) local res = call("Act", action, args or {}); say(res); return res end
	local round = ReplicatedStorage:FindFirstChild("Round")
	local info = label(s, string.format("Mode: %s   ·   Map: %s   ·   Players: %d", round and tostring(round:GetAttribute("ModeName")) or "?", round and tostring(round:GetAttribute("MapName") or round:GetAttribute("Map")) or "?", #Players:GetPlayers()), 15, WHITE, Theme.FONT)
	info.LayoutOrder = 1
	local order = 2
	local function section(name) local h = heading(s, name); h.LayoutOrder = order; order += 1 end
	if can("rounds") then
		section("ROUNDS")
		local r = hrow(s); r.LayoutOrder = order; order += 1
		button(r, "END THE ROUND NOW", Theme.RED, 190).Activated:Connect(function() act("endround") end)
		label(r, "then the next round uses the mode and map below", 12, Theme.DIM, Theme.FONT_BODY).Size = UDim2.fromOffset(360, 30)
		section("NEXT MODE")
		local modes = flow(s); modes.LayoutOrder = order; order += 1
		local ids = {}
		for id in pairs(GameConfig.MODES) do table.insert(ids, id) end
		table.sort(ids)
		for i, id in ipairs(ids) do
			local b = button(modes, string.upper(GameConfig.MODES[id].name), Theme.GLASS2); b.LayoutOrder = i; b.TextSize = 12
			b.Activated:Connect(function() act("nextmode", {mode = id}) end)
		end
		section("NEXT MAP")
		local maps = flow(s); maps.LayoutOrder = order; order += 1
		local seen, list = {}, {}
		for _, def in pairs(GameConfig.MODES) do for _, m in ipairs(def.maps or {}) do if not seen[m] then seen[m] = true; table.insert(list, m) end end end
		table.sort(list)
		for i, m in ipairs(list) do
			local b = button(maps, string.upper(GameConfig.mapTitle(m)), Theme.GLASS2); b.LayoutOrder = i; b.TextSize = 12
			b.Activated:Connect(function() act("nextmap", {map = m}) end)
		end
	end
	if can("drops") then
		-- the Calendar's drops: each goes live by itself at its time; release one early
		-- or hold one back here, on every server at once
		section("DROPS  ·  RELEASE EARLY / HOLD BACK")
		local Drops = require(game:GetService("ReplicatedStorage"):WaitForChild("Drops"))
		local dl = flow(s); dl.LayoutOrder = order; order += 1
		for i, d in ipairs(Drops.list()) do
			local out = Drops.released(d.id)
			local b = button(dl, (out and "✔ " or "") .. string.upper(d.name), out and Theme.GLASS2 or Theme.BLUE); b.LayoutOrder = i; b.TextSize = 12
			b.Activated:Connect(function()
				confirm("drop" .. d.id, function() act("drop", {op = out and "hold" or "now", id = d.id}) end)
			end)
		end
		local r = hrow(s); r.LayoutOrder = order; order += 1
		button(r, "BACK TO THE CALENDAR (CLEAR OVERRIDES)", Theme.GLASS2, 340).Activated:Connect(function() act("drop", {op = "clear"}) end)
	end
	if can("announce") then
		section("ANNOUNCE")
		local r = hrow(s); r.LayoutOrder = order; order += 1
		local text = box(r, "message", 420)
		button(r, "THIS SERVER", Theme.BLUE, 120).Activated:Connect(function() act("announce", {text = text.Text}) end)
		if can("announce_all") then button(r, "EVERY SERVER", Theme.GOLD, 130).Activated:Connect(function() act("announce", {text = text.Text, all = true}) end) end
	end
	if can("bots") then
		section("BOTS")
		local r = hrow(s); r.LayoutOrder = order; order += 1
		local skill = "Knight"
		local chips = {}
		for _, k in ipairs({"Squire", "Knight", "Champion"}) do
			local b = button(r, string.upper(k), k == skill and Theme.BLUE or Theme.GLASS2, 110)
			chips[k] = b
			b.Activated:Connect(function() skill = k; for n, c in pairs(chips) do c.BackgroundColor3 = n == k and Theme.BLUE or Theme.GLASS2 end end)
		end
		local count = box(r, "how many (1-10)", 130)
		button(r, "SPAWN", Theme.GREEN, 90).Activated:Connect(function() act("bots", {skill = skill, count = tonumber(count.Text) or 1}) end)
		button(r, "CLEAR BOTS", Theme.RED, 110).Activated:Connect(function() act("clearbots") end)
	end
	if can("shutdown") then
		section("SHUT DOWN THIS SERVER")
		local r = hrow(s); r.LayoutOrder = order; order += 1
		local reason = box(r, "reason", 320)
		button(r, "SHUT DOWN", Color3.fromRGB(150, 30, 30), 140).Activated:Connect(function() confirm("shutdown", function() act("shutdown", {reason = reason.Text}) end) end)
	end
end

--------------------------------------------------------------------
--  STAFF
--------------------------------------------------------------------
tabs.STAFF = function()
	local s = scroller(body)
	vlist(s, 6)
	if can("staff") then
		local r = hrow(s); r.LayoutOrder = 1
		local who = box(r, "name or user id", 200)
		local pick = nil
		local chips = {}
		for _, roleName in ipairs(me.order or {}) do
			local rr = me.roles[roleName]
			if rr and rr.rank < (me.rank or 0) then
				local b = button(r, string.upper(roleName), Theme.GLASS2, 110)
				chips[roleName] = b
				b.Activated:Connect(function() pick = roleName; for n, c in pairs(chips) do c.BackgroundColor3 = n == roleName and rr.color or Theme.GLASS2 end end)
			end
		end
		button(r, "GIVE ROLE", Theme.GREEN, 110).Activated:Connect(function()
			if not pick then say({ok = false, msg = "pick a role"}); return end
			local look = call("Lookup", who.Text)
			if not look.ok then say(look); return end
			say(call("Act", "setrole", {userId = look.userId, name = look.name, role = pick}))
			task.wait(0.3)
			showTab("STAFF")
		end)
	end
	local res = call("Staff")
	if not res.ok then say(res); return end
	for i, row in ipairs(res.staff) do
		local r = hrow(s, 36); r.LayoutOrder = 10 + i
		local n = label(r, string.format("%s  ·  %s", row.name or tostring(row.userId), string.upper(row.role or "")), 15, roleColor(row.role)); n.Size = UDim2.fromOffset(420, 30)
		local by = label(r, row.by and ("given by " .. row.by) or "", 12, Theme.DIM, Theme.FONT_BODY); by.Size = UDim2.fromOffset(200, 30)
		local rr = me.roles[row.role]
		if can("staff") and rr and rr.rank < (me.rank or 0) then
			button(r, "TAKE ROLE", Theme.RED, 110).Activated:Connect(function()
				say(call("Act", "setrole", {userId = row.userId, name = row.name, role = ""}))
				task.wait(0.3)
				showTab("STAFF")
			end)
		end
	end
end

--------------------------------------------------------------------
--  BANS, LOG
--------------------------------------------------------------------
tabs.BANS = function()
	local s = scroller(body)
	vlist(s, 6)
	local res = call("Bans")
	if not res.ok then say(res); return end
	if #res.bans == 0 then label(s, "Nobody is banned.", 15, Theme.DIM) end
	for i, b in ipairs(res.bans) do
		local r = hrow(s, 36); r.LayoutOrder = i
		local when = b["until"] == 0 and "FOR GOOD" or ("until " .. os.date("%Y-%m-%d %H:%M", b["until"]))
		local n = label(r, string.format("%s  ·  %s  ·  %s", b.name or tostring(b.id), when, b.reason ~= "" and b.reason or "(no reason)"), 14, WHITE); n.Size = UDim2.fromOffset(600, 30)
		local by = label(r, "by " .. tostring(b.by or "?"), 12, Theme.DIM, Theme.FONT_BODY); by.Size = UDim2.fromOffset(120, 30)
		if can("ban") then
			button(r, "UNBAN", Theme.GREEN, 90).Activated:Connect(function()
				say(call("Act", "unban", {userId = b.id, name = b.name}))
				task.wait(0.3)
				showTab("BANS")
			end)
		end
	end
end

tabs.LOG = function()
	local s = scroller(body)
	vlist(s, 3)
	local res = call("Log")
	if not res.ok then say(res); return end
	if #res.log == 0 then label(s, "Nothing yet.", 15, Theme.DIM) end
	for i, e in ipairs(res.log) do
		local l = label(s, string.format("%s   %s   %s %s %s", os.date("%m-%d %H:%M", e.at or 0), tostring(e.byName or "?"), string.upper(tostring(e.action or "")),
			e.targetName and tostring(e.targetName) or "", e.detail and ("· " .. tostring(e.detail)) or ""), 13, WHITE, Theme.FONT_BODY)
		l.LayoutOrder = i
	end
end

--------------------------------------------------------------------
--  OPEN / CLOSE
--------------------------------------------------------------------
local function setOpen(on)
	panel.Visible = on
	if on then
		local res = call("Me")
		if res.ok then me = res end
		badge.Text = string.upper(me.role or "") .. (me.studio and "   ·   STUDIO" or "")
		badge.TextColor3 = roleColor(me.role)
		for _, b in pairs(tabButtons) do b:Destroy() end
		tabButtons = {}
		local names = {"PLAYERS", "SERVER", "STAFF"}
		if can("ban") or can("tempban") then table.insert(names, "BANS") end
		if can("log") then table.insert(names, "LOG") end
		for i, n in ipairs(names) do
			local b = button(tabsRow, n, Theme.GLASS2, 120)
			b.LayoutOrder = i
			tabButtons[n] = b
			b.Activated:Connect(function() showTab(n) end)
		end
		showTab(current and tabButtons[current] and current or "PLAYERS")
	end
end
closeB.Activated:Connect(function() setOpen(false) end)
toggle.Activated:Connect(function() setOpen(not panel.Visible) end)
UserInputService.InputBegan:Connect(function(input, gp)
	if gp or UserInputService:GetFocusedTextBox() then return end
	if input.KeyCode == Enum.KeyCode.F2 and player:GetAttribute("StaffRole") then setOpen(not panel.Visible) end
end)
-- the mouse is free while the panel is up
RunService.RenderStepped:Connect(function()
	if panel.Visible then UserInputService.MouseBehavior = Enum.MouseBehavior.Default; UserInputService.MouseIconEnabled = true end
end)
local function refreshRole()
	local role = player:GetAttribute("StaffRole")
	toggle.Visible = role ~= nil
	if not role then panel.Visible = false end
end
player:GetAttributeChangedSignal("StaffRole"):Connect(refreshRole)
refreshRole()

--------------------------------------------------------------------
--  ANNOUNCEMENTS (everyone sees them)
--------------------------------------------------------------------
local banner = Instance.new("Frame")
banner.AnchorPoint = Vector2.new(0.5, 0)
banner.Position = UDim2.new(0.5, 0, 0, 150)
banner.Size = UDim2.fromOffset(720, 72)
banner.BackgroundColor3 = Color3.fromRGB(14, 12, 22)
banner.BackgroundTransparency = 0.1
banner.Visible = false
banner.Parent = gui
corner(banner, 12)
local bStroke = Instance.new("UIStroke"); bStroke.Color = Theme.ACCENT; bStroke.Thickness = 2; bStroke.Parent = banner
local bText = label(banner, "", 20, WHITE, Theme.FONT_TITLE, Enum.TextXAlignment.Center); bText.Position = UDim2.fromOffset(12, 8); bText.Size = UDim2.new(1, -24, 0, 30)
local bBy = label(banner, "", 13, Theme.ACCENT, Theme.FONT, Enum.TextXAlignment.Center); bBy.Position = UDim2.new(0, 12, 1, -26); bBy.Size = UDim2.new(1, -24, 0, 18)
local shown = 0
event.OnClientEvent:Connect(function(what, text, by, role)
	if what ~= "Announce" then return end
	shown += 1
	local mine = shown
	bText.Text = tostring(text)
	bBy.Text = "ANNOUNCEMENT  ·  " .. tostring(by) .. (role and role ~= "" and ("  (" .. tostring(role) .. ")") or "")
	banner.Visible = true
	local sc = banner:FindFirstChildOfClass("UIScale") or Instance.new("UIScale", banner)
	sc.Scale = 0.85
	TweenService:Create(sc, TweenInfo.new(0.25, Enum.EasingStyle.Back), {Scale = 1}):Play()
	task.delay(7, function() if shown == mine then banner.Visible = false end end)
end)
