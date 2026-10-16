--[[ PROLOGUE — THE SIEGE OF STORMWATCH: a brand-new player's first minutes (GameConfig.MODES.Prologue,
     DOORS.Prologue). A dark, stormy night; the Iron Host is at the gate of Stormwatch; you're a
     soldier of its garrison, and you learn to fight in the middle of the battle. The castle is
     built fresh (Game ▸ StormwatchMap); the weather, the arrows over your head, the fire from the
     trebuchets, the cutscenes and the lesson card are Prologue.client's.

     THE STORY (STEPS, in order; each a line from Captain Hale, a lesson card, what counts):
       opening   (cutscene) the storm, the Host, a tower hit, Hale wakes you
       wake      run to the armoury (a marker), sprint
       swing / stab / overhead   raiders who came over the wall: land each kind of blow
       dodge     the trebuchets find the yard: when the ground glows red under you, dodge
       block / parry / riposte   a raider through the east breach swings at you (his blows teach,
                 they don't hurt: Harmless)
       kick / finish   a brute behind his shield: kick his guard open, cut him down
       gatehouse the ram's at the gate: run for the gatehouse while arrows fall
       breach    (cutscene) the ram, the gate splinters, the Host pours in
       hold      fight beside the garrison: the Host's soldiers come through the gate
       champion  (cutscene) Lord Varg, their champion · then the duel (a boss bar)
       victory   (cutscene) horns, the King's riders at dawn: STORMWATCH STANDS
     Before the battle you can't fall (a little health always left); in it, you come back at the
     gatehouse, and every fall weakens Varg a little. SKIP leaves at any time.

     The end: profile tutorial 2 (the newcomer's path is done; the Courtyard's menu tour follows),
     a welcome purse (Catalog ▸ Economy ▸ prologue), stats.prologue, then to the Courtyard.

     Remote: ReplicatedStorage ▸ PrologueEvent
       server → client  "Step", {id, title, text, n, goal, target} · "Progress", n, goal ·
                        "Line", {who, text, dur} · "Cine", name, data · "Fx", kind, data · "Done", info
       client → server  "CineDone", name · "Skip" · "Finish" ]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local TweenService = game:GetService("TweenService")
local Debris = game:GetService("Debris")

local Catalog = require(ReplicatedStorage:WaitForChild("Catalog"))
local Dresser = require(ReplicatedStorage:WaitForChild("Dresser"))
local Game = require(script.Parent.Parent:WaitForChild("Game"))
local StormwatchMap = require(script.Parent.Parent:WaitForChild("StormwatchMap"))
local Dungeon = require(script.Parent.Parent:WaitForChild("Dungeon"))
local Combat = ServerScriptService:WaitForChild("Combat")
local Bots = require(Combat:WaitForChild("Bots"))
local R6 = require(Combat:WaitForChild("R6"))
local Moves = require(Combat:WaitForChild("BossMoves"))
local Profile = require(ServerScriptService:WaitForChild("Loadout"):WaitForChild("Profile"))
local MapLoader = Game.MapLoader
local Teams = Game.Teams
local node = Game.node

local RED = Color3.fromRGB(255, 70, 40)
local SETS = {ally = "RiverGuard", captain = "Lionheart", host = "IronCrow", brute = "Blackguard", champion = "Obsidian"}

local Prologue = setmetatable({}, {__index = Game.Mode})
Prologue.__index = Prologue
function Prologue.new(def, id) return setmetatable(Game.Mode.new(def, id), Prologue) end

local remote = ReplicatedStorage:FindFirstChild("PrologueEvent")
if not remote then remote = Instance.new("RemoteEvent"); remote.Name = "PrologueEvent"; remote.Parent = ReplicatedStorage end

local function humOf(c) return c and c:FindFirstChildOfClass("Humanoid") end
local function rootOf(c) return c and c:FindFirstChild("HumanoidRootPart") end
local function all(...) remote:FireAllClients(...) end
local function setPieces(set)
	local lo = {}
	for _, pc in ipairs(Catalog.setPieces(set) or {}) do lo[pc.slot] = pc.id end
	return lo
end

--------------------------------------------------------------------
--  THE STORY
--------------------------------------------------------------------
local HALE = "CAPTAIN HALE"
local STEPS = {
	{id = "opening", cine = "opening"},
	{id = "wake", title = "ON YOUR FEET", text = "Follow Captain Hale to the armoury. Hold {Sprint} to run.", target = "armory", radius = 11,
		line = "Up, soldier! The Iron Host is at our gate and the walls are burning. To the armoury, now!"},
	{id = "swing", title = "CUT THEM DOWN", text = "Raiders came over the wall! Strike one with {Swing}.", goal = 3, event = "hit", kind = "Swing", setup = "raider", target = "raiders",
		line = "Raiders over the west wall! Get in there and cut them down!"},
	{id = "stab", title = "THE STAB", text = "Quick and straight: thrust with {Stab}.", goal = 2, event = "hit", kind = "Stab", setup = "raider", target = "raiders",
		line = "Another! A stab is fast and narrow. Run him through!"},
	{id = "overhead", title = "THE OVERHEAD", text = "Bring it down from above with {Overhead}. Slow, but it breaks a lazy guard.", goal = 2, event = "hit", kind = "Overhead", setup = "raider", target = "raiders",
		line = "From above! Overheads crush a guard that isn't ready!"},
	{id = "dodge", title = "INCOMING!", text = "Trebuchet fire! When the ground glows red under you, {Dodge} out of it.", goal = 2, event = "dodge", setup = "bombard",
		line = "TREBUCHETS! When the ground burns red under your feet, DODGE!"},
	{id = "block", title = "RAISE YOUR GUARD", text = "They're through the east breach! Hold {Block} to stop his blows.", goal = 2, event = "guard", setup = "attacker", target = "breach",
		line = "They're through the breach! Shields up, hold your guard!"},
	{id = "parry", title = "THE PARRY", text = "Raise your guard at the LAST moment, just as his blow lands. Parry once!", goal = 1, event = "parry", setup = "attacker",
		line = "Good! Now wait for it... guard at the last moment: a parry costs you nothing!"},
	{id = "riposte", title = "RIPOSTE!", text = "After a parry your blade glows gold: strike back at once, faster and free. Parry, then hit him!", goal = 1, event = "riposte", setup = "attacker",
		line = "A parry opens him up. Parry, then strike back before he recovers!"},
	{id = "kick", title = "BREAK HIS GUARD", text = "This brute hides behind his guard. {Kick} it open!", goal = 1, event = "kick", setup = "brute",
		line = "That brute won't drop his guard. Kick it open!"},
	{id = "finish", title = "FINISH HIM", text = "Kick his guard open and cut him down.", goal = 1, event = "kill", setup = "brute",
		line = "Now finish him!"},
	{id = "gatehouse", title = "TO THE GATE", text = "The ram is at the gate! Run for the gatehouse through the arrows.", target = "gate", radius = 16, setup = "volleys",
		line = "Hear that? Their ram! Everyone to the gatehouse. MOVE!"},
	{id = "breach", cine = "breach"},
	{id = "hold", title = "HOLD THE GATE", text = "Fight beside the garrison. Drive back the Iron Host!", goal = 6, event = "kill", setup = "battle",
		line = "HOLD THE LINE! FOR STORMWATCH!", battle = true},
	{id = "varg", cine = "champion"},
	{id = "champion", title = "LORD VARG", text = "Their champion. Parry his blows, kick his guard, keep moving!", goal = 1, event = "boss", setup = "boss",
		line = "It's Varg himself! Parry, kick, and don't stand still!", battle = true},
	{id = "victory", cine = "victory"},
}
local STEP_INDEX = {}
for i, s in ipairs(STEPS) do STEP_INDEX[s.id] = i end
-- where you come back if you fall (by how far you've got)
local function checkpointOf(stepId)
	local i = STEP_INDEX[stepId] or 1
	if i >= STEP_INDEX.gatehouse then return "gate" end
	if i >= STEP_INDEX.block then return "breach" end
	if i >= STEP_INDEX.swing then return "raiders" end
	return "wake"
end

--------------------------------------------------------------------
--  THE MAP, THE CAPTAIN
--------------------------------------------------------------------
function Prologue:buildMap()
	local name, layout = StormwatchMap.build()
	self.layout = layout
	Dungeon.sweep(name)
	return name
end

function Prologue:point(name)
	local p = self.layout and self.layout.points[name]
	return p or Vector3.zero
end

-- a body for the story (anchored: the captain, a raider who came over the wall)
function Prologue:figure(name, set, at, look, weapon)
	local m, hum, hrp = R6.rig(name, {anchored = true})
	m:SetAttribute("Idle", true)
	m:SetAttribute("TagName", name)
	m:PivotTo(CFrame.lookAt(at + Vector3.new(0, 3, 0), Vector3.new(look.X, at.Y + 3, look.Z)))
	m.Parent = self.folder
	pcall(Dresser.dress, m, {loadout = setPieces(set), appearance = Catalog.BODY.defaults, weight = "Medium", preview = true})
	if weapon then pcall(Dresser.attachWeapon, m, weapon, weapon .. ":Default") end
	hum.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None
	hum.HealthDisplayType = Enum.HumanoidHealthDisplayType.AlwaysOff
	return m, hum, hrp
end

function Prologue:moveCaptain(to, look)
	local m = self.captain
	if not (m and m.Parent) then return end
	m:PivotTo(CFrame.lookAt(to + Vector3.new(0, 3, 0), Vector3.new(look.X, to.Y + 3, look.Z)))
end

-- the hero: whoever's here first (the story is shared; anyone else tags along)
function Prologue:hero()
	for _, p in ipairs(Players:GetPlayers()) do
		local c = p.Character
		if humOf(c) and humOf(c).Health > 0 then return p, c end
	end
	return nil
end

--------------------------------------------------------------------
--  WHAT COUNTS: hits on our NPCs, the hero's own moves, deaths
--------------------------------------------------------------------
function Prologue:watchTarget(model)
	table.insert(self.conns, model:GetAttributeChangedSignal("LastHitAt"):Connect(function()
		local plr = Players:GetPlayerByUserId(model:GetAttribute("LastHitBy") or 0)
		if plr then self:note("hit", {attack = model:GetAttribute("LastHitAttack"), target = model, plr = plr}) end
	end))
end

function Prologue:watchCharacter(char)
	for _, c in ipairs(self.charConns or {}) do c:Disconnect() end
	self.charConns = {}
	local function on(attr, fn) table.insert(self.charConns, char:GetAttributeChangedSignal(attr):Connect(fn)) end
	on("GuardTick", function() if char:GetAttribute("GuardText") ~= "CHAMBER" then self:note("guard") end end)
	on("ParryTick", function() self:note("parry") end)
	on("KickTick", function() self:note("kick") end)
	on("LastDodgeAt", function() self:note("dodge") end)
end

function Prologue:note(event, data)
	local s = STEPS[self.step]
	if not s or not s.event or self.stepDone then return end
	data = data or {}
	local count = false
	if s.event == "hit" and event == "hit" then
		count = (data.attack or ""):find(s.kind, 1, true) ~= nil and data.target == self.lessonTarget
	elseif s.event == "riposte" and event == "hit" then
		local _, c = self:hero()
		count = c ~= nil and os.clock() <= (c:GetAttribute("FastUntil") or 0) + 0.15 and data.target == self.lessonTarget
	elseif s.event == "dodge" and event == "dodge" then
		-- (a dodge while the ring fills, or just as it lands)
		count = self.incoming ~= nil and os.clock() < self.incoming + 0.3
		if count then self.incoming = nil; self.dodged = true end
	elseif s.event == event then
		count = true
	end
	if not count then return end
	self.n += 1
	all("Progress", self.n, s.goal or 1)
	if self.n >= (s.goal or 1) then self:finishStep() end
end

--------------------------------------------------------------------
--  STEPS
--------------------------------------------------------------------
function Prologue:clearLesson()
	for _, b in ipairs(self.lessonBots or {}) do pcall(function() b:destroy() end) end
	self.lessonBots = {}
	if self.lessonTarget and self.lessonTarget.Parent and self.lessonTarget:GetAttribute("StoryFigure") then self.lessonTarget:Destroy() end
	self.lessonTarget = nil
	self.bombard, self.volleys = false, false
end

function Prologue:finishStep()
	if self.stepDone then return end
	self.stepDone = true
	local s = STEPS[self.step]
	-- a lesson's raider falls (in a puff of dust), a lesson's bot goes
	local t = self.lessonTarget
	if t and t.Parent and t:GetAttribute("StoryFigure") then
		local r = t:FindFirstChild("HumanoidRootPart")
		if r then all("Fx", "Dust", {pos = r.Position}) end
	end
	all("Fx", "Good", {text = s and s.title or ""})
	task.delay(1.2, function()
		if Game.current ~= self then return end
		local nextStep = STEPS[self.step + 1]
		-- (a lesson that needs the same raider again keeps him)
		if not (nextStep and nextStep.setup == s.setup and (s.setup == "attacker" or s.setup == "brute")) then self:clearLesson() end
		self:begin(self.step + 1)
	end)
end

function Prologue:begin(i)
	local s = STEPS[i]
	self.step, self.n, self.stepDone = i, 0, false
	if not s then return self:finish(false) end
	node:SetAttribute("PrologueStep", s.id)
	if s.cine then return self:cinematic(s.cine) end
	if s.line then all("Line", {who = HALE, text = s.line, dur = 5}) end
	local target = s.target and self:point(s.target)
	all("Step", {id = s.id, title = s.title, text = s.text, n = 0, goal = s.goal or 1, target = target})
	local setup = s.setup
	if setup == "raider" then self:raider()
	elseif setup == "bombard" then self:startBombard()
	elseif setup == "attacker" then self:lessonBot("attacker")
	elseif setup == "brute" then self:lessonBot("brute")
	elseif setup == "volleys" then self.volleys = true
	elseif setup == "battle" then self:battle()
	elseif setup == "boss" then self:boss() end
	-- (the captain goes where the fighting is)
	local here = target or (setup == "bombard" and self:point("yard")) or nil
	if here then self:moveCaptain(here + Vector3.new(-6, 0, 6), here) end
end

-- a raider who fell from the wall, staggering: he takes your blows (and doesn't hit back)
function Prologue:raider()
	if self.lessonTarget and self.lessonTarget.Parent then return end
	local at = self:point("raiders") + Vector3.new(math.random(-4, 4), 0, math.random(-4, 4))
	local m, hum = self:figure("Iron Host Raider", SETS.host, at, self:point("wake"), "Shortsword")
	m:SetAttribute("StoryFigure", true)
	m:SetAttribute("Team", "B")
	hum.MaxHealth, hum.Health = 1e5, 1e5
	self.lessonTarget = m
	self:watchTarget(m)
end

-- a raider through the breach who swings (Harmless: his blows teach), or a brute who never drops
-- his guard; the brute can fall (the finish)
function Prologue:lessonBot(kind)
	local b = self.lessonBots[1]
	if b and b.alive and b.kind == kind then return end
	self:clearLesson()
	local at = self:point("breach")
	local brute = kind == "brute"
	local bot = Bots.spawn({at = CFrame.lookAt(at + Vector3.new(0, 3, 0), self:point("yard") + Vector3.new(0, 3, 0)),
		skill = brute and "Guard" or "Drill", weapon = brute and "Mace" or "Longsword", name = brute and "Iron Host Brute" or "Iron Host Raider",
		invulnerable = not brute, corpseTime = 2, team = "B", loadout = setPieces(brute and SETS.brute or SETS.host), weight = brute and "Heavy" or "Medium",
		onDeath = function() if Game.current == self then self:note("kill") end end})
	if not bot then return end
	bot.kind = kind
	bot.model:SetAttribute("Harmless", true)
	if brute then
		bot.hum.MaxHealth, bot.hum.Health = 120, 120
		-- (a shield on his arm: a brute behind his guard)
		bot.model:SetAttribute("Unflinching", nil)
	end
	table.insert(self.lessonBots, bot)
	self.lessonTarget = bot.model
	self:watchTarget(bot.model)
end

-- THE TREBUCHETS FIND THE YARD: a red ring under the hero, a fireball, a blast
function Prologue:startBombard()
	self.bombard = true
	task.spawn(function()
		while Game.current == self and self.bombard do
			local _, c = self:hero()
			local r = rootOf(c)
			if r then
				local at = Vector3.new(r.Position.X, 0, r.Position.Z)
				Moves.circle(at, 9, RED, 1.7)
				self.incoming = os.clock() + 1.7   -- (when it lands)
				self.dodged = false
				all("Fx", "Incoming", {pos = at, t = 1.7, from = self.layout.trebuchets[math.random(#self.layout.trebuchets)]})
				task.wait(1.7)
				if not self.bombard then break end
				all("Fx", "Impact", {pos = at, big = true})
				local cr = rootOf(c)
				local h = humOf(c)
				if cr and h and not self.dodged and (Vector3.new(cr.Position.X, 0, cr.Position.Z) - at).Magnitude < 9 then
					h:TakeDamage(18)
					cr.AssemblyLinearVelocity = (Vector3.new(cr.Position.X, 0, cr.Position.Z) - at).Unit * 40 + Vector3.new(0, 30, 0)
				end
				self.incoming = nil
				task.wait(1.6)
			else
				task.wait(0.5)
			end
		end
	end)
end

-- THE BATTLE AT THE GATE: the garrison beside you, the Host through the gate in waves
function Prologue:spawnFighter(side, at, skill, name)
	local bot = Bots.spawn({at = CFrame.lookAt(at + Vector3.new(0, 3, 0), self:point(side == "A" and "gateOut" or "yard") + Vector3.new(0, 3, 0)),
		skill = skill, team = side, fightBots = true, name = name, corpseTime = 3,
		loadout = setPieces(side == "A" and SETS.ally or SETS.host), weight = "Medium",
		onDeath = function(b, killer)
			self.alive[b] = nil
			if side == "B" and Game.current == self then self:note("kill", {killer = killer}) end
		end})
	if bot then
		self.alive[bot] = side
		table.insert(self.battleBots, bot)
	end
	return bot
end

-- the garrison at the gate (they brace it while the ram works, then hold the line beside you)
function Prologue:garrison()
	if self.garrisoned then return end
	self.garrisoned = true
	local inside = self:point("gate") + Vector3.new(0, 0, 10)
	for i = 1, 4 do self:spawnFighter("A", inside + Vector3.new(-12 + i * 5, 0, 4), i <= 2 and "Knight" or "Squire", "Stormwatch Guard") end
end

function Prologue:battle()
	local gate = self:point("gate")
	self:garrison()
	local sent = 0
	task.spawn(function()
		while Game.current == self and STEPS[self.step] and STEPS[self.step].id == "hold" and sent < 9 do
			local hostUp = 0
			for _, s in pairs(self.alive) do if s == "B" then hostUp += 1 end end
			if hostUp < 3 then
				sent += 1
				self:spawnFighter("B", gate + Vector3.new(math.random(-6, 6), 0, -14), sent >= 6 and "Knight" or "Squire", "Iron Host Soldier")
				if sent == 1 or sent == 5 then all("Fx", "Charge", {pos = gate}) end
			end
			task.wait(2.5)
		end
	end)
end

function Prologue:boss()
	if self.varg and self.varg.alive then return end
	local gate = self:point("gate")
	local bot = Bots.spawn({at = CFrame.lookAt(gate + Vector3.new(0, 3, -10), self:point("yard") + Vector3.new(0, 3, 0)),
		-- (a newcomer's first champion: big and slow to read, not a duellist; the garrison helps)
		skill = "Squire", weapon = "Greatsword", team = "B", fightBots = false, name = "Lord Varg", corpseTime = 8,
		loadout = setPieces(SETS.champion), weight = "Heavy",
		onDeath = function() if Game.current == self then self:note("boss") end end})
	if not bot then return end
	bot.hum.MaxHealth, bot.hum.Health = 420, 420
	for k, v in pairs({Boss = true, BossName = "Lord Varg", TagName = "Lord Varg"}) do bot.model:SetAttribute(k, v) end
	self.varg = bot
	table.insert(self.battleBots, bot)
end

--------------------------------------------------------------------
--  CUTSCENES (the client plays them; the server does what happens in them)
--------------------------------------------------------------------
function Prologue:cinematic(name)
	self.cineWait = name
	local data = {}
	local len = ({opening = 19, breach = 9, champion = 6.5, victory = 13})[name] or 8
	for _, p in ipairs(Players:GetPlayers()) do
		local c = p.Character
		if c then c:SetAttribute("SpeedMult_Cine", 0) end
	end
	all("Cine", name, data)
	if name == "opening" then
		task.delay(10, function() all("Fx", "Impact", {pos = Vector3.new(76, 34, -56), big = true, far = true}) end)
	elseif name == "breach" then
		self:garrison()
		self:moveCaptain(self:point("gate") + Vector3.new(-7, 0, 6), self:point("gate") - Vector3.new(0, 0, 20))
		for _, t in ipairs({1.4, 3.0, 4.6}) do task.delay(t, function() all("Fx", "Ram", {pos = self:point("gate")}) end) end
		task.delay(5.4, function() self:breakGate() end)
	elseif name == "champion" then
		task.delay(1.5, function() self:boss() end)
	elseif name == "victory" then
		all("Fx", "Dawn", {})
		for _, b in ipairs(self.battleBots) do if self.alive[b] == "B" then pcall(function() b:destroy() end) end end
	end
	-- (on when the client says it's done, or after its length anyway)
	local t0 = os.clock()
	task.spawn(function()
		while Game.current == self and self.cineWait == name and os.clock() - t0 < len + 6 do task.wait(0.25) end
		if Game.current ~= self then return end
		self.cineWait = nil
		for _, p in ipairs(Players:GetPlayers()) do
			local c = p.Character
			if c then c:SetAttribute("SpeedMult_Cine", nil) end
		end
		if name == "victory" then return self:finish(true) end
		self:begin(self.step + 1)
	end)
end

function Prologue:breakGate()
	local map = MapLoader.current
	local gate = map and map:FindFirstChild("Gate")
	if not gate then return end
	all("Fx", "Breach", {pos = self:point("gate")})
	for _, d in ipairs(gate:GetDescendants()) do
		if d:IsA("BasePart") then
			d.Anchored = false
			d.CanCollide = true
			local side = d.Position.X < 0 and -1 or 1
			d.AssemblyLinearVelocity = Vector3.new(side * math.random(10, 30), math.random(15, 35), math.random(40, 80))
			d.AssemblyAngularVelocity = Vector3.new(math.random(-6, 6), math.random(-6, 6), math.random(-6, 6))
			Debris:AddItem(d, 25)
		end
	end
	-- the first of the Host through the gap
	for i = 1, 2 do self:spawnFighter("B", self:point("gate") + Vector3.new(-4 + i * 3, 0, -12), "Squire", "Iron Host Soldier") end
end

--------------------------------------------------------------------
--  THE ROUND
--------------------------------------------------------------------
function Prologue:start(map)
	Game.Mode.start(self, map)
	if not self.layout then
		local name = self:buildMap()
		MapLoader.load(name)
	end
	self.folder = Instance.new("Folder"); self.folder.Name = "PrologueCast"; self.folder.Parent = MapLoader.current or workspace
	self.conns, self.lessonBots, self.battleBots, self.alive = {}, {}, {}, {}
	self.deaths = 0
	node:SetAttribute("FriendlyFire", false)
	node:SetAttribute("OwnHud", true)
	node:SetAttribute("OwnTop", true)
	node:SetAttribute("ObjKind", "Prologue")
	for _, p in ipairs(Players:GetPlayers()) do Teams.set(p, "A") end
	-- the captain
	self.captain = self:figure("Captain Hale", SETS.captain, self:point("captain"), self:point("wake"), "Longsword")
	self.captain:SetAttribute("TagTitle", "STORMWATCH GARRISON")
	-- the clients' events
	table.insert(self.conns, remote.OnServerEvent:Connect(function(plr, what, a)
		if Game.current ~= self then return end
		if what == "CineDone" and a == self.cineWait then self.cineWait = nil
		elseif what == "Skip" then self:finish(false, plr)
		elseif what == "Finish" and self.over then self:sendHome(plr) end
	end))
	-- everyone in, then the story
	for _, p in ipairs(Players:GetPlayers()) do if _G.AutoSpawn then _G.AutoSpawn(p) end end
	task.spawn(function()
		for _ = 1, 40 do
			if self:hero() then break end
			task.wait(0.25)
		end
		task.wait(1.5)
		if Game.current == self then self:begin(1) end
	end)
end

function Prologue:stop()
	self:clearLesson()
	for _, b in ipairs(self.battleBots or {}) do pcall(function() b:destroy() end) end
	self.battleBots = {}
	for _, c in ipairs(self.conns or {}) do c:Disconnect() end
	for _, c in ipairs(self.charConns or {}) do c:Disconnect() end
	self.conns, self.charConns = {}, {}
	if self.folder then self.folder:Destroy(); self.folder = nil end
	self.layout = nil
	for _, k in ipairs({"OwnHud", "OwnTop", "ObjKind", "PrologueStep", "ObjLabel", "ObjNote"}) do node:SetAttribute(k, nil) end
end

-- you: a Knight of the garrison (your own looks), on the Crown's side
function Prologue:adjustLoadout(plr, lo, classId)
	Teams.set(plr, "A")
	lo.power, lo.thirdKind, lo.thirdId = nil, "none", nil
	lo.throwable = nil
end
function Prologue:noteSpawn(plr)
	local char = plr.Character
	if not char then return end
	Teams.mark(char, "A")
	task.defer(function() if char.Parent then self:watchCharacter(char) end end)
end
function Prologue:spawnCFrame(plr)
	local s = STEPS[self.step or 1]
	local at = self:point(checkpointOf(s and s.id or "wake"))
	return CFrame.lookAt(at + Vector3.new(0, 3, 0), self:point("yard") + Vector3.new(0, 3, 0))
end
function Prologue:canSpawn() return true end

-- a fall in the battle: back at the gatehouse, and Varg a little weaker for it
function Prologue:onDeath(plr)
	self.deaths += 1
	if self.varg and self.varg.alive then
		local h = self.varg.hum
		h.MaxHealth = math.max(160, h.MaxHealth - 60)
		h.Health = math.min(h.Health, h.MaxHealth)
		all("Line", {who = HALE, text = "Back on your feet! He's hurt, finish it!", dur = 4})
	end
end

function Prologue:tick(dt)
	-- before the battle nobody falls: a little health always left
	local s = STEPS[self.step or 1]
	if s and not s.battle then
		for _, p in ipairs(Players:GetPlayers()) do
			local h = humOf(p.Character)
			if h and h.Health > 0 and h.Health < h.MaxHealth * 0.3 then h.Health = h.MaxHealth * 0.3 end
		end
	end
	-- a place to reach
	if s and s.target and s.radius and not self.stepDone then
		local _, c = self:hero()
		local r = rootOf(c)
		local at = self:point(s.target)
		if r and (Vector3.new(r.Position.X, 0, r.Position.Z) - Vector3.new(at.X, 0, at.Z)).Magnitude < s.radius then self:finishStep() end
	end
	node:SetAttribute("Objective", self:objective())
end

-- THE END: the newcomer's path is done; the welcome purse; to the Courtyard
function Prologue:finish(won, who)
	if self.over then return end
	self.over = true
	self.bombard = false
	for _, p in ipairs(Players:GetPlayers()) do
		local prof = Profile.get(p)
		if (prof.tutorial or 0) < 2 then
			Profile.setTutorial(p, 2)
			prof.askedTraining = true
		end
		prof.stats = prof.stats or {}
		if won then prof.stats.prologue = (prof.stats.prologue or 0) + 1 end
		local line
		if won and not prof.prologuePaid then
			prof.prologuePaid = true
			local ok, Economy = pcall(require, ServerScriptService:WaitForChild("Economy"):WaitForChild("Economy"))
			if ok and Economy and Economy.grantReward then
				local okG, l = pcall(Economy.grantReward, p, (Catalog.ECONOMY and Catalog.ECONOMY.prologue) or {marks = 500})
				if okG then line = l end
			end
		end
		Profile.markDirty(p)
		remote:FireClient(p, "Done", {won = won, reward = line})
	end
	-- a skip goes straight home; a win waits for TO THE COURTYARD (or a while)
	if not won then
		for _, p in ipairs(Players:GetPlayers()) do self:sendHome(p) end
	else
		task.delay(40, function() for _, p in ipairs(Players:GetPlayers()) do if p.Parent and Game.current == self then self:sendHome(p) end end end)
	end
end
function Prologue:sendHome(plr)
	if plr:GetAttribute("PrologueHome") then return end
	plr:SetAttribute("PrologueHome", true)
	if _G.HubTravel then pcall(_G.HubTravel, plr, "Courtyard", {}) end
end

function Prologue:isOver()
	local nxt = node:GetAttribute("NextMode")
	if nxt and nxt ~= "" and nxt ~= "Prologue" then return "STORMWATCH STANDS" end
	return nil
end
function Prologue:result() return "STORMWATCH STANDS" end
function Prologue:objective()
	local s = STEPS[self.step or 1]
	return "THE SIEGE OF STORMWATCH" .. (s and s.title and ("  ·  " .. s.title) or "")
end

return Prologue
