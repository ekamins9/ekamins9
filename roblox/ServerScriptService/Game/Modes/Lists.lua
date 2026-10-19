-- THE LISTS — arena brackets. Two sides from the teleport data (Game.server
-- sides), best of 5 rounds (roundsToWin 3), no respawns, 90 s rounds. Honor
-- rules: a hit on someone already engaged by your teammate is a warning the
-- first time and loses the round the second (CombatServer reports through
-- _G.HonorHook). Ranked results are written by Scoreboard (ratings + boards).
-- PURE SWORDSMANSHIP (the mode's meleeOnly): no powers, no throwables, no spells, no bows or
-- magic, no thrown steel (Combat ▸ Hurl); a bow or a staff in your loadout gives way to your
-- melee secondary, else a melee weapon your class carries. The bots fight the same way.
-- THE FENCE: only the small arenas (GameConfig), and nobody walks or glitches out of one: an
-- invisible wall round the fighting ground (FENCE, else a MapForge arena's ring, else a ring
-- round the two spawn lines), and anyone found outside it, or fallen through the floor, is
-- put back in (Lists:tick).
-- THE ROUNDS: every round on the same map (sameMap), each starting HELD for fightCountdown s
-- (everyone frozen where they spawned; ListsFlow.client greys the screen and counts 3 · 2 · 1 ·
-- FIGHT; the round's clock gets the time back). THE END: the winners on a podium in the middle
-- of the arena, emoting (players brought back to stand on it, the bots that won copied onto it);
-- the screen says VICTORY or DEFEAT with RE-QUEUE / RETURN TO MENU (HubServer).
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Catalog = require(ReplicatedStorage:WaitForChild("Catalog"))
local GameConfig = require(ReplicatedStorage:WaitForChild("GameConfig"))
local MapLoader = require(script.Parent.Parent:WaitForChild("MapLoader"))
local ServerScriptService = game:GetService("ServerScriptService")
local Profile = require(ServerScriptService:WaitForChild("Loadout"):WaitForChild("Profile"))
local Game  = require(script.Parent.Parent:WaitForChild("Game"))
local Teams = Game.Teams
local LTS = require(script.Parent:WaitForChild("LTS"))

local Lists = setmetatable({}, {__index = LTS})
Lists.__index = Lists
function Lists.new(def, id)
	local self = setmetatable(LTS.new(def, id), Lists)
	self.honor = {}   -- [plr] = warnings
	return self
end

function Lists:start(map)
	Game.Mode.start(self, map)
	-- sides come from the matchmaker, never balanced by count
	local sides = Game.server.sides
	if sides then
		for _, p in ipairs(Players:GetPlayers()) do
			local key = (sides.A and sides.A[p.UserId]) and "A" or ((sides.B and sides.B[p.UserId]) and "B" or nil)
			Teams.set(p, key or Teams.assign(p))
		end
	else
		Teams.assignAll()
	end
	self.startedAt = os.clock()
	self.spawnedOnce = {}
	self.scores = {A = self.roundWins.A, B = self.roundWins.B}
	self:publishScores()
	self:fence(map)
	-- held for the countdown (the round's clock gets the time back)
	self.roundNo = (self.roundNo or 0) + 1
	local cd = self.def.fightCountdown or 5
	self.fightAt = os.clock() + cd
	self.held = {}
	self.bonusTime = (self.bonusTime or 0) + cd
	local node = Game.node
	node:SetAttribute("FightAt", workspace:GetServerTimeNow() + cd)
	node:SetAttribute("ListsRound", self.roundNo)
	node:SetAttribute("RoundsToWin", self.def.roundsToWin or 3)
	node:SetAttribute("MatchWinner", "")
	node:SetAttribute("PodiumCam", nil)
end

-- THE FENCE (the fighting ground's edge: half a box's side, or a ring's radius, from the middle)
local FENCE = {RoseCourt = {box = 22.4}, Sandpit = {ring = 68}, Colosseum = {ring = 45.5}}
local ARENA_RING = 46     -- a MapForge arena's wall (Build ▸ MapForge arena: A = 46)
local FENCE_H = 120
function Lists:fence(mapName)
	self.bounds = nil
	local m = MapLoader.current
	local sp = m and m:FindFirstChild("Spawns")
	if not sp then return end
	local A, B, na, nb, floor = Vector3.zero, Vector3.zero, 0, 0, math.huge
	for _, s in ipairs(sp:GetChildren()) do
		if s:IsA("BasePart") then
			local t = s:GetAttribute("Team")
			if t == "A" then A += s.Position; na += 1 elseif t == "B" then B += s.Position; nb += 1 end
			floor = math.min(floor, s.Position.Y)
		end
	end
	if na == 0 or nb == 0 then return end
	A, B = A / na, B / nb
	local c = (A + B) / 2
	local spec = FENCE[mapName or ""] or (m:GetAttribute("Layout") == "arena" and {ring = ARENA_RING}) or {ring = (A - B).Magnitude / 2 + 12}
	local f = Instance.new("Folder")
	f.Name = "ArenaFence"
	local midY = floor - 20 + FENCE_H / 2
	local function wall(cf, size)
		local p = Instance.new("Part")
		p.Name = "Fence"
		p.Anchored, p.CanCollide, p.CanQuery, p.CanTouch, p.CastShadow = true, true, false, false, false
		p.Transparency = 1
		p.Size = size
		p.CFrame = cf
		p.Parent = f
	end
	if spec.box then
		local h = spec.box
		for _, d in ipairs({{1, 0}, {-1, 0}, {0, 1}, {0, -1}}) do
			local size = d[1] ~= 0 and Vector3.new(2, FENCE_H, h * 2 + 4) or Vector3.new(h * 2 + 4, FENCE_H, 2)
			wall(CFrame.new(c.X + d[1] * (h + 1), midY, c.Z + d[2] * (h + 1)), size)
		end
	else
		local r, n = spec.ring, 48
		local w = 2 * (r + 1) * math.tan(math.pi / n) + 0.6
		for i = 0, n - 1 do
			local a = i / n * 2 * math.pi
			local pos = Vector3.new(c.X + math.cos(a) * (r + 1), midY, c.Z + math.sin(a) * (r + 1))
			wall(CFrame.lookAt(pos, Vector3.new(c.X, midY, c.Z)), Vector3.new(w, FENCE_H, 2))
		end
	end
	f.Parent = m
	self.bounds = {c = c, box = spec.box, ring = spec.ring, floor = floor}
end
-- where someone outside the fence goes back to (nil: they're inside)
local function backInside(b, p)
	local dx, dz = p.X - b.c.X, p.Z - b.c.Z
	if b.box then
		local h = b.box
		if math.abs(dx) <= h + 1.5 and math.abs(dz) <= h + 1.5 then return nil end
		return Vector3.new(b.c.X + math.clamp(dx, -(h - 2), h - 2), p.Y, b.c.Z + math.clamp(dz, -(h - 2), h - 2))
	end
	local d = math.sqrt(dx * dx + dz * dz)
	if d <= b.ring + 1.5 then return nil end
	local k = (b.ring - 3) / d
	return Vector3.new(b.c.X + dx * k, p.Y, b.c.Z + dz * k)
end
function Lists:tick(dt)
	LTS.tick(self, dt)
	-- THE COUNTDOWN: everyone held where they spawned until FIGHT
	if self.fightAt then
		local npcs = workspace:FindFirstChild("NPCs")
		if os.clock() < self.fightAt then
			local function hold(model)
				local root = model and model:FindFirstChild("HumanoidRootPart")
				if root and self.held[root] == nil then self.held[root] = root.Anchored; root.Anchored = true end
			end
			for _, plr in ipairs(Players:GetPlayers()) do hold(plr.Character) end
			for _, m in ipairs(npcs and npcs:GetChildren() or {}) do hold(m) end
		else
			self:letGo()
		end
	end
	local b = self.bounds
	if not b then return end
	local function check(model)
		local root = model and model:FindFirstChild("HumanoidRootPart")
		local hum = model and model:FindFirstChildOfClass("Humanoid")
		if not (root and hum and hum.Health > 0) then return end
		local p = root.Position
		local to = backInside(b, p)
		if p.Y < b.floor - 30 then to = Vector3.new((to or b.c).X, b.floor + 4, (to or b.c).Z) end   -- (fell through the floor)
		if to then model:PivotTo(CFrame.new(to + Vector3.new(0, 1, 0)) * (root.CFrame - root.Position)) end
	end
	for _, plr in ipairs(Players:GetPlayers()) do check(plr.Character) end
	local npcs = workspace:FindFirstChild("NPCs")
	if npcs then for _, m in ipairs(npcs:GetChildren()) do check(m) end end
end

function Lists:objective()
	return string.format("THE LISTS  ·  %s%s  ·  first to %d", Game.server.bracket or "duel", Game.server.ranked and "  ·  RANKED" or "", self.def.roundsToWin or 3)
end
-- a side with nobody left (a leaver) forfeits
function Lists:isOver()
	local before = self.roundWins
	local text = LTS.isOver(self)
	if text and self.roundWins ~= before then self.matchDone = true end   -- LTS swaps in a fresh table when the match is won
	if text then return text end
	if self.startedAt and os.clock() - self.startedAt > 5 then
		-- (a side of bots, a casual match the queue filled: Game ▸ BotFill, is a side)
		local a = Teams.count("A") + (Game.fielded.A or 0)
		local b = Teams.count("B") + (Game.fielded.B or 0)
		if a == 0 and b > 0 then self.matchDone = true; return self:teamResult("B") .. " BY FORFEIT" end
		if b == 0 and a > 0 then self.matchDone = true; return self:teamResult("A") .. " BY FORFEIT" end
	end
	return nil
end
-- the clock ran out: the round goes to the side with more alive; that may end the match too
function Lists:result()
	local text = LTS.result(self)
	local need = self.def.roundsToWin or 3
	if self.roundWins.A >= need or self.roundWins.B >= need then
		self.matchDone = true
		text = text:gsub("THE ROUND", "THE MATCH")
	end
	return text
end
-- PURE SWORDSMANSHIP: steel in the hand and nothing else
local MELEE = {OneHanded = true, TwoHanded = true, Polearm = true}
local BOT_MELEE = {"Longsword", "ArmingSword", "Mace", "Falchion", "Spear", "BattleAxe", "Shortsword", "Greatsword"}
local function melee(id)
	local w = id and Catalog.WEAPON[id]
	return w ~= nil and MELEE[w.family] == true
end
function Lists:adjustLoadout(plr, lo, classId)
	lo.power, lo.throwable, lo.throwableSkin = "none", "none", nil
	lo.thirdKind, lo.thirdId, lo.thirdSkin = "none", nil, nil
	lo.spells, lo.wandSpells = {}, {}
	if not melee(lo.secondary) then lo.secondary, lo.secondarySkin = nil, nil end
	if not melee(lo.weapon) then
		if lo.secondary then
			lo.weapon, lo.weaponSkin, lo.secondary, lo.secondarySkin = lo.secondary, lo.secondarySkin, nil, nil
		else
			local cls, pick = GameConfig.CLASSES[classId], nil
			for _, w in ipairs(Catalog.WEAPONS) do
				if MELEE[w.family] and cls and Catalog.weaponFits(cls, w, "primary") then pick = w.id; break end
			end
			lo.weapon = pick or "Shortsword"
			lo.weaponSkin = lo.weapon .. ":Default"
		end
	end
end
function Lists:botOpts(opts)
	opts.power, opts.powerSkin = nil, nil
	opts.class = nil
	if not melee(opts.weapon) then opts.weapon = BOT_MELEE[math.random(#BOT_MELEE)] end
end

function Lists:letGo()
	for root, was in pairs(self.held or {}) do if root.Parent then root.Anchored = was end end
	self.held, self.fightAt = {}, nil
end

-- THE PODIUM: the winners on it in the middle of the arena, emoting, until everyone has gone
local SPOTS = {{0, 2.6}, {-5.4, 1.7}, {5.4, 1.1}}           -- across, and how high
local CHEERS = {"Thunderlord", "Ascension", "Champion", "Windmill", "WarCry", "WarDrum", "Flourish", "BladeToss", "Jig", "Cheer", "Salute"}
local BOT_CHEERS = {"Cheer", "Flourish", "Salute", "Pledge", "Bow"}   -- (free ones: a bot never shows off what's paid for)
local function cheersOf(plr)
	local have, out = {}, {}
	for _, id in ipairs(string.split(plr:GetAttribute("Emotes") or "", ",")) do have[id] = true end
	for _, id in ipairs(CHEERS) do if have[id] then table.insert(out, id) end end
	return #out > 0 and out or {"Cheer", "Salute"}
end
function Lists:podium(plrs, bots)
	local b, m = self.bounds, MapLoader.current
	if not (b and m) then return end
	-- the ground in the middle (a pit's floor, a dais)
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	local skip = {m:FindFirstChild("ArenaFence"), workspace:FindFirstChild("NPCs")}
	for _, p in ipairs(Players:GetPlayers()) do if p.Character then table.insert(skip, p.Character) end end
	params.FilterDescendantsInstances = skip
	local hit = workspace:Raycast(Vector3.new(b.c.X, b.floor + 60, b.c.Z), Vector3.new(0, -140, 0), params)
	local ground = hit and hit.Position.Y or (b.floor - 1)
	local mid = Vector3.new(b.c.X, ground, b.c.Z)
	local face = Vector3.new(0, 0, 1)
	local base = CFrame.lookAt(mid, mid + face)
	local f = Instance.new("Model")
	f.Name = "Podium"
	local function block(size, cf, color, mat)
		local p = Instance.new("Part")
		p.Anchored, p.Size, p.CFrame, p.Color, p.Material = true, size, cf, color, mat
		p.TopSurface, p.BottomSurface = Enum.SurfaceType.Smooth, Enum.SurfaceType.Smooth
		p.Parent = f
		return p
	end
	local n = math.min(#SPOTS, #plrs + #bots)
	block(Vector3.new(19, 0.6, 9), base * CFrame.new(0, 0.3, 0), Color3.fromRGB(120, 28, 36), Enum.Material.Fabric)
	local tops = {}
	for i = 1, math.max(1, n) do
		local x, h = SPOTS[i][1], SPOTS[i][2]
		block(Vector3.new(5, h, 5), base * CFrame.new(x, 0.6 + h / 2, 0), Color3.fromRGB(228, 222, 208), Enum.Material.Marble)
		block(Vector3.new(5.3, 0.25, 5.3), base * CFrame.new(x, 0.6 + h - 0.12, 0), Color3.fromRGB(214, 170, 64), Enum.Material.Metal)
		local top = (base * CFrame.new(x, 0.6 + h + 3.05, 0)).Position
		tops[i] = CFrame.lookAt(top, top + face)
	end
	f.Parent = m
	Game.node:SetAttribute("PodiumCam", CFrame.lookAt(mid + face * 15 + Vector3.new(0, 5.2, 0), mid + Vector3.new(0, 4.4, 0)))
	local function stillOver() return Game.node:GetAttribute("MatchOver") == true end
	local k = 0
	-- the players: brought back to stand on it
	for _, plr in ipairs(plrs) do
		k += 1
		if k > #tops then break end
		local at = tops[k]
		if plr.Parent and _G.Respawn then
			local okP, p = pcall(Profile.get, plr)
			_G.Respawn(plr, okP and p and p.active or nil, at)
			task.spawn(function()
				local t0, root = os.clock(), nil
				while os.clock() - t0 < 10 and plr.Parent do
					local ch = plr.Character
					root = ch and ch:FindFirstChild("HumanoidRootPart")
					if root and (root.Position - at.Position).Magnitude < 8 then break end
					root = nil
					task.wait(0.2)
				end
				if not root then return end
				root.Anchored = true
				root.CFrame = at
				local list, i = cheersOf(plr), 0
				task.wait(0.8)
				while stillOver() and plr.Parent and root.Parent do
					i = i % #list + 1
					if _G.PlayerEmote then pcall(_G.PlayerEmote, plr, list[i]) end
					task.wait(4.5)
				end
			end)
		end
	end
	-- the bots that won: copied onto it as they stood
	for _, c in ipairs(bots) do
		k += 1
		if k > #tops then c:Destroy(); continue end
		for _, d in ipairs(c:GetDescendants()) do if d:IsA("BaseScript") then d:Destroy() end end
		c:SetAttribute("FillBot", nil)
		local root = c:FindFirstChild("HumanoidRootPart")
		c.Parent = f
		c:PivotTo(tops[k])
		if root then root.Anchored = true end
		task.spawn(function()
			local i = math.random(#BOT_CHEERS)
			task.wait(1 + math.random())
			while stillOver() and c.Parent do
				i = i % #BOT_CHEERS + 1
				if _G.BotEmote then pcall(_G.BotEmote, c, BOT_CHEERS[i]) end
				task.wait(4.5)
			end
		end)
	end
end

-- after the match the server is done: everyone is sent home by HubServer (MatchOver attribute),
-- or goes when they like (the end screen's RE-QUEUE / RETURN TO MENU)
function Lists:stop()
	self:letGo()
	if not self.matchDone then return end
	-- who won (the side named in Winner), and who stands on the podium: its players, then its
	-- bots still standing (copied now, before the bodies are cleared away)
	local w, key = Game.node:GetAttribute("Winner") or "", nil
	for _, k in ipairs({"A", "B"}) do if GameConfig.TEAMS[k] and GameConfig.TEAMS[k].name == w then key = k end end
	Game.node:SetAttribute("MatchWinner", key or "")
	Game.node:SetAttribute("MatchOver", true)
	if not key then return end
	local plrs, bots = {}, {}
	for _, p in ipairs(Players:GetPlayers()) do if Game.teamOf(p) == key then table.insert(plrs, p) end end
	local npcs = workspace:FindFirstChild("NPCs")
	for _, m in ipairs(npcs and npcs:GetChildren() or {}) do
		local hum = m:FindFirstChildOfClass("Humanoid")
		if m:GetAttribute("FillBot") and m:GetAttribute("Team") == key and hum and hum.Health > 0 and #plrs + #bots < #SPOTS then
			m.Archivable = true
			local ok, c = pcall(function() return m:Clone() end)
			if ok and c then table.insert(bots, c) end
		end
	end
	task.delay(1.2, function() self:podium(plrs, bots) end)
end
return Lists
