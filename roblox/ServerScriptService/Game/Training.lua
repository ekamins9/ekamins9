--[[ TRAINING — the training yard's people, lessons and fights (the Tiltyard
     mode starts and stops it with the map). Reads the map's Spots (Build ▸
     MapTraining):

       • STRAW DUMMIES on the posts (Dummy1..6): they take hits, never strike
         back, and pop back up a moment after they fall.
       • THE DRILL MASTER (DrillMaster): E opens his menu: carry on with the
         lessons, start them over, pick any lesson, spar in the ring, call up
         practice bots, or run the Gauntlet. The lessons are Catalog ▸ Drills;
         each watches for its move (a hit of a kind, a block, a parry…)
         through the combat system's own signals, and a lesson finished for
         the first time pays a drill (Economy earn.drill, the drill stat).
       • DRILL DUMMIES for the guard lessons (LessonAttacker swings slowly,
         LessonBlocker never drops its guard): they come when someone's lesson
         needs them and go when nobody's does.
       • WHERE TO GO: each player's next place (the straw dummy, the drill
         dummy, the ring, the Drill Master) is published as DrillTarget /
         DrillTargetName; the client draws a beacon and an arrow to it.
       • THE SPARRING RING (Ring, RingPlayer, RingBot, RingSign): a Squire,
         Knight or Champion bot, 3-2-1, to the death; leave and you forfeit.
         The last lesson's Squire comes the moment you step into the ring.
       • THE GAUNTLET, in the ring: waves of bots, each harder, until you
         fall. Your best wave is kept (profile gauntlet); each new best wave
         pays D.gauntlet.perWave Marks.
       • THE PRACTICE GROUND (Practice): one to three bots of a chosen skill
         come at you together, as often as you like.
     Players can't hurt each other here (the mode is peaceful).
     Remote: ReplicatedStorage ▸ TrainingRemote
       client → server  "Lesson", id · "Restart" · "Spar", skill · "Leave" ·
                        "Practice", skill, count · "ClearPractice" · "Gauntlet"
       server → client  "Menu", info · "Ring", records · "Progress" · "Done", id, line ·
                        "Spar", what, … · "Gauntlet", what, … · "Practice", what, … ]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local Debris = game:GetService("Debris")
local Catalog = require(ReplicatedStorage:WaitForChild("Catalog"))
local Dresser = require(ReplicatedStorage:WaitForChild("Dresser"))
local Profile = require(ServerScriptService:WaitForChild("Loadout"):WaitForChild("Profile"))
local Economy = require(ServerScriptService:WaitForChild("Economy"):WaitForChild("Economy"))
local Stats = require(ServerScriptService:WaitForChild("Economy"):WaitForChild("Stats"))
local Bots = require(ServerScriptService:WaitForChild("Combat"):WaitForChild("Bots"))
local R6 = require(ServerScriptService:WaitForChild("Combat"):WaitForChild("R6"))

local Training = {}
local D = Catalog.DRILLS
local LESSON = {}
for i, l in ipairs(D.lessons) do l.index = i; LESSON[l.id] = l end
local SKILL_ORDER = {Squire = 1, Knight = 2, Champion = 3}
local WEAPONS = {"Longsword", "ArmingSword", "Mace", "Falchion", "Spear", "BattleAxe"}

local remote = ReplicatedStorage:FindFirstChild("TrainingRemote")
if not remote then remote = Instance.new("RemoteEvent"); remote.Name = "TrainingRemote"; remote.Parent = ReplicatedStorage end

local npcFolder = workspace:FindFirstChild("NPCs") or Instance.new("Folder")
npcFolder.Name = "NPCs"; npcFolder.Parent = workspace

local running = false
local spots = {}
local stuff = {}          -- every NPC we made (cleared on stop)
local conns = {}
local learners = {}       -- [player] = {id, n, sides = {}, conns = {}}
local drill = {}          -- "attacker" / "blocker" -> bot
local ring = nil          -- {player, kind = "spar"|"gauntlet", skill, bots = {}, wave, outSince}
local practice = {}       -- [player] = {bots = {}, kills, skill}
local masterPos = nil

local function spot(name) return spots[name] end
local watchTarget   -- forward (defined with the lessons)
local function tell(plr, ...) if plr.Parent then remote:FireClient(plr, ...) end end
local function toast(plr, text)
	local ev = ReplicatedStorage:FindFirstChild("HubEvent")
	if ev and plr.Parent then ev:FireClient(plr, "Toast", text) end
end
local function alive(plr)
	local c = plr.Character
	local hum = c and c:FindFirstChildOfClass("Humanoid")
	local hrp = c and c:FindFirstChild("HumanoidRootPart")
	if hum and hrp and hum.Health > 0 then return c, hum, hrp end
	return nil
end
-- a puff of dust where an NPC leaves
local function poof(model)
	local hrp = model and model:FindFirstChild("HumanoidRootPart")
	if not hrp then return end
	local a0 = Instance.new("Attachment"); a0.WorldPosition = hrp.Position; a0.Parent = workspace.Terrain
	local e = Instance.new("ParticleEmitter")
	e.Color = ColorSequence.new(Color3.fromRGB(214, 196, 160)); e.Size = NumberSequence.new(1.2, 2.6)
	e.Transparency = NumberSequence.new(0.3, 1); e.Lifetime = NumberRange.new(0.5, 0.9); e.Speed = NumberRange.new(4, 9)
	e.SpreadAngle = Vector2.new(180, 180); e.Rate = 0; e.Parent = a0
	e:Emit(18)
	Debris:AddItem(a0, 1.2)
end

--------------------------------------------------------------------
--  LESSONS
--------------------------------------------------------------------
local function profileOf(plr)
	local p = Profile.get(plr)
	if type(p.drills) ~= "table" then p.drills = {} end
	if type(p.spars) ~= "table" then p.spars = {} end
	if type(p.gauntlet) ~= "number" then p.gauntlet = 0 end
	return p
end

local function publish(plr)
	local L = learners[plr]
	local l = L and LESSON[L.id or ""]
	plr:SetAttribute("Drill", l and l.id or "")
	plr:SetAttribute("DrillProgress", L and L.n or 0)
	plr:SetAttribute("DrillGoal", l and l.goal or 0)
	local done = {}
	for id in pairs(profileOf(plr).drills) do table.insert(done, id) end
	table.sort(done)
	plr:SetAttribute("DrillsDone", table.concat(done, ","))
end

-- the drill dummies a lesson needs, where it needs them
local function ensureDrill(kind)
	local b = drill[kind]
	if b and b.alive and b.model.Parent then return end
	local at = spot(kind == "attacker" and "LessonAttacker" or "LessonBlocker")
	if not at then return end
	drill[kind] = Bots.spawn({at = at.CFrame, skill = kind == "attacker" and "Drill" or "Guard", weapon = "Longsword",
		name = kind == "attacker" and "Drill Dummy" or "Guard Dummy", invulnerable = true, corpseTime = 1})
	poof(drill[kind].model)
	table.insert(stuff, drill[kind].model)
	watchTarget(drill[kind].model)
end

local function setLesson(plr, id)
	local l = LESSON[id]
	if not l then return end
	learners[plr] = learners[plr] or {conns = {}}
	local L = learners[plr]
	L.id, L.n, L.sides = id, 0, {}
	if l.setup then ensureDrill(l.setup) end
	publish(plr)
	tell(plr, "Progress")
end

local function firstOpen(p)
	for _, l in ipairs(D.lessons) do if not p.drills[l.id] then return l end end
	return nil
end

local function complete(plr)
	local L = learners[plr]
	local l = L and LESSON[L.id or ""]
	if not l then return end
	local p = profileOf(plr)
	local first = not p.drills[l.id]
	local line = "LESSON DONE  ·  " .. l.title
	if first then
		p.drills[l.id] = true
		Profile.markDirty(plr)
		pcall(Economy.award, plr, {drill = 1})
		pcall(Stats.add, plr, "drill", 1)
		local pay = Catalog.ECONOMY.earn and Catalog.ECONOMY.earn.drill
		if pay then line ..= string.format("  ·  +%d Marks  +%d XP", pay.marks or 0, pay.xp or 0) end
	end
	tell(plr, "Done", l.id, line)
	toast(plr, line)
	-- on to the next lesson: a replay walks the course in order; otherwise the
	-- next one not done yet. Past the end, the first one not done anywhere.
	local nextL
	if L.replay then
		nextL = D.lessons[l.index + 1]
	else
		for i = l.index + 1, #D.lessons do if not p.drills[D.lessons[i].id] then nextL = D.lessons[i]; break end end
	end
	if not nextL then nextL = firstOpen(p) end
	if nextL then
		setLesson(plr, nextL.id)
	else
		L.id, L.replay = nil, nil
		publish(plr)
		tell(plr, "Progress")
	end
end

-- something happened that a lesson might care about
local function note(plr, event, data)
	local L = learners[plr]
	local l = L and LESSON[L.id or ""]
	if not l then return end
	local count = false
	if l.event == "hit" and event == "hit" then
		count = (data.attack or ""):find(l.kind, 1, true) ~= nil
	elseif l.event == "sides" and event == "hit" then
		local side = (data.attack or ""):match("^(Left)") or (data.attack or ""):match("^(Right)")
		if side and not L.sides[side] then L.sides[side] = true; L.n = 0; for _ in pairs(L.sides) do L.n += 1 end; publish(plr) end
		if L.n >= l.goal then complete(plr) end
		return
	elseif l.event == "riposte" and event == "hit" then
		local c = plr.Character
		count = c ~= nil and os.clock() <= (c:GetAttribute("FastUntil") or 0) + 0.15
	elseif l.event == event then
		count = true
	end
	if not count then return end
	L.n += 1
	publish(plr)
	if L.n >= l.goal then complete(plr) end
end

-- a player's own signals (on their character)
local function watchCharacter(plr, char)
	local L = learners[plr] or {conns = {}}
	learners[plr] = L
	for _, c in ipairs(L.conns) do c:Disconnect() end
	L.conns = {}
	local function on(attr, fn) table.insert(L.conns, char:GetAttributeChangedSignal(attr):Connect(fn)) end
	on("GuardTick", function()
		local text = char:GetAttribute("GuardText")
		if text == "CHAMBER" then note(plr, "chamber") else note(plr, "guard") end
	end)
	on("ParryTick", function() if char:GetAttribute("GuardText") ~= "CHAMBER" then note(plr, "parry") end end)
	on("FeintTick", function() note(plr, "feint") end)
	on("MorphTick", function() note(plr, "morph") end)
	on("KickTick", function() note(plr, "kick") end)
	on("LastDodgeAt", function() note(plr, "dodge") end)
end

-- hits on any of our NPCs, credited to whoever struck
watchTarget = function(model)
	table.insert(conns, model:GetAttributeChangedSignal("LastHitAt"):Connect(function()
		local plr = Players:GetPlayerByUserId(model:GetAttribute("LastHitBy") or 0)
		if plr then note(plr, "hit", {attack = model:GetAttribute("LastHitAttack"), kind = model:GetAttribute("LastHitKind"), target = model}) end
	end))
end

--------------------------------------------------------------------
--  THE STRAW DUMMIES AND THE DRILL MASTER
--------------------------------------------------------------------
local BURLAP = Color3.fromRGB(184, 150, 98)
local function strawDummy(i)
	local at = spot("Dummy" .. i)
	if not at or not running then return end
	local m, hum, hrp = R6.rig("Straw Dummy", {skin = BURLAP, anchored = true, noFace = true, material = Enum.Material.Fabric})
	m:SetAttribute("Straw", true)
	m:PivotTo(at.CFrame)
	-- a rope belt and a painted target on the chest
	local torso = m.Torso
	local belt = Instance.new("Part"); belt.Name = "Rope"; belt.Size = Vector3.new(2.1, 0.25, 1.1); belt.Color = Color3.fromRGB(120, 90, 50); belt.Material = Enum.Material.Fabric; belt.CanCollide = false; belt.Massless = true
	belt.CFrame = torso.CFrame * CFrame.new(0, -0.6, 0); belt.Parent = m
	local w = Instance.new("WeldConstraint"); w.Part0 = torso; w.Part1 = belt; w.Parent = belt
	local mark = Instance.new("Part"); mark.Name = "Target"; mark.Shape = Enum.PartType.Cylinder; mark.Size = Vector3.new(0.05, 1.1, 1.1); mark.Color = Color3.fromRGB(190, 40, 36); mark.CanCollide = false; mark.Massless = true
	mark.CFrame = torso.CFrame * CFrame.new(0, 0.2, -0.52) * CFrame.Angles(0, math.pi / 2, 0); mark.Parent = m
	local w2 = Instance.new("WeldConstraint"); w2.Part0 = torso; w2.Part1 = mark; w2.Parent = mark
	hum.MaxHealth = 400; hum.Health = 400
	hum.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None
	hum.WalkSpeed, hum.JumpPower = 0, 0
	m.Parent = npcFolder
	table.insert(stuff, m)
	watchTarget(m)
	hum.Died:Once(function()
		task.delay(2.5, function()
			if m.Parent then m:Destroy() end
			strawDummy(i)
		end)
	end)
end

local function menuInfo(plr)
	local p = profileOf(plr)
	local L = learners[plr]
	local spars = {}
	for k, v in pairs(p.spars) do spars[k] = v end
	return {current = L and L.id or nil, records = spars, gauntlet = p.gauntlet, practicing = practice[plr] ~= nil,
		ringBusy = ring and ring.player ~= plr and ring.player.DisplayName or nil, perWave = (D.gauntlet and D.gauntlet.perWave) or 0}
end

local function drillMaster()
	local at = spot("DrillMaster")
	if not at then return end
	local m, hum, hrp = R6.rig("Sir Aldric", {anchored = true})
	m:SetAttribute("Idle", true)
	m:SetAttribute("DrillMaster", true)
	m:PivotTo(at.CFrame)
	m.Parent = npcFolder
	pcall(Dresser.dress, m, {loadout = Bots.loadoutFor("Heavy", {Primary = "Royal", Secondary = "Bone", Accent = "Gold", Metal = "Steel"}), appearance = Catalog.BODY.defaults, weight = "Heavy", preview = true})
	pcall(Dresser.attachWeapon, m, "Longsword", "Longsword:Default")
	hum.DisplayName = "Sir Aldric, Drill Master"
	hum.MaxHealth, hum.Health = 1e6, 1e6
	hum.HealthDisplayType = Enum.HumanoidHealthDisplayType.AlwaysOff
	-- no one cuts the Drill Master: out of the NPC folder, and blades pass through him
	m.Parent = workspace:FindFirstChild("Map") or workspace
	for _, d in ipairs(m:GetDescendants()) do if d:IsA("BasePart") then d.CanQuery = false; d.CanTouch = false end end
	masterPos = hrp.Position
	local prompt = Instance.new("ProximityPrompt")
	prompt.ActionText = "Talk"
	prompt.ObjectText = "Drill Master"
	prompt.KeyboardKeyCode = Enum.KeyCode.E
	prompt.MaxActivationDistance = 14
	prompt.RequiresLineOfSight = false
	prompt.Parent = hrp
	table.insert(conns, prompt.Triggered:Connect(function(plr) tell(plr, "Menu", menuInfo(plr)) end))
	table.insert(stuff, m)
end

--------------------------------------------------------------------
--  THE SPARRING RING: a duel, or the Gauntlet
--------------------------------------------------------------------
local function records(plr)
	local p = profileOf(plr)
	local out = {}
	for k, v in pairs(p.spars) do out[k] = v end
	return out
end

local function clearRingBots(r)
	for _, b in ipairs(r.bots or {}) do if b.model.Parent then poof(b.model); b:destroy() end end
	r.bots = {}
end

local function endSpar(result)
	local r = ring
	if not r or r.kind ~= "spar" then return end
	ring = nil
	local plr = r.player
	clearRingBots(r)
	if not plr.Parent then return end
	if result == "win" then
		local p = profileOf(plr)
		local first = (p.spars[r.skill] or 0) == 0
		p.spars[r.skill] = (p.spars[r.skill] or 0) + 1
		local pay = D.spar[r.skill] or {}
		local marks = first and (pay.first or 0) or (pay.again or 0)
		p.wallet.marks += marks
		Profile.markDirty(plr)
		Economy.changed:Fire(plr)
		pcall(Stats.add, plr, "spar", 1)
		tell(plr, "Spar", "win", r.skill, marks, first)
		note(plr, "spar", {skill = r.skill})
		-- the ring lesson: a win at its skill or above counts
		local L = learners[plr]
		local l = L and LESSON[L.id or ""]
		if l and l.event == "spar" and L.n < l.goal then
			if (SKILL_ORDER[r.skill] or 0) >= (SKILL_ORDER[l.skill] or 1) then L.n = l.goal; publish(plr); complete(plr) end
		end
	else
		tell(plr, "Spar", result, r.skill)
	end
end

local function startSpar(plr, skill)
	if not SKILL_ORDER[skill] then return end
	if ring then
		if ring.player == plr then return end
		toast(plr, ring.player.DisplayName .. " is in the ring right now: wait your turn")
		return
	end
	local char, hum = alive(plr)
	local you, them, centre = spot("RingPlayer"), spot("RingBot"), spot("Ring")
	if not (char and you and them and centre) then return end
	char:PivotTo(you.CFrame)
	local radius = centre:GetAttribute("Radius") or 14
	ring = {player = plr, kind = "spar", skill = skill, bots = {}, outSince = nil}
	local r = ring
	local bot = Bots.spawn({at = them.CFrame, skill = skill, weapon = WEAPONS[math.random(#WEAPONS)], target = char,
		arena = {centre = centre.Position, radius = radius}, startDelay = 3.2, corpseTime = 4,
		onDeath = function() if ring == r then endSpar("win") end end})
	r.bots = {bot}
	r.startAt = bot.startAt
	table.insert(stuff, bot.model)
	watchTarget(bot.model)
	tell(plr, "Spar", "start", skill)
	-- you fall: a loss
	hum.Died:Once(function() if ring == r then endSpar("lose") end end)
end

-- the Gauntlet: wave after wave until you fall
local WAVES = {
	{"Squire"}, {"Squire", "Squire"}, {"Knight"}, {"Knight", "Squire"}, {"Knight", "Knight"},
	{"Champion"}, {"Champion", "Squire"}, {"Champion", "Knight"}, {"Champion", "Champion"},
}
local function waveOf(n)
	if WAVES[n] then return WAVES[n] end
	local t = {}
	for i = 1, math.min(4, 2 + math.floor((n - #WAVES) / 2)) do t[i] = (i % 3 == 0) and "Knight" or "Champion" end
	return t
end

local function endGauntlet(result)
	local r = ring
	if not r or r.kind ~= "gauntlet" then return end
	ring = nil
	local plr = r.player
	clearRingBots(r)
	if not plr.Parent then return end
	local cleared = math.max(0, (r.wave or 1) - 1)
	local p = profileOf(plr)
	local old = p.gauntlet
	local marks = 0
	if cleared > old then
		local per = (D.gauntlet and D.gauntlet.perWave) or 0
		marks = per * (math.min(cleared, (D.gauntlet and D.gauntlet.payTo) or 20) - math.min(old, (D.gauntlet and D.gauntlet.payTo) or 20))
		p.gauntlet = cleared
		p.wallet.marks += marks
		Profile.markDirty(plr)
		Economy.changed:Fire(plr)
	end
	tell(plr, "Gauntlet", "over", cleared, p.gauntlet, marks, result)
end

local function gauntletWave(r)
	if ring ~= r then return end
	r.wave = (r.wave or 0) + 1
	local list = waveOf(r.wave)
	local centre, them = spot("Ring"), spot("RingBot")
	local char = r.player.Character
	if not (centre and them and char) then endGauntlet("left"); return end
	local radius = centre:GetAttribute("Radius") or 14
	r.left = #list
	for i, skill in ipairs(list) do
		local off = (i - (#list + 1) / 2) * 4.5
		local at = them.CFrame * CFrame.new(off, 0, 0)
		local bot = Bots.spawn({at = at, skill = skill, weapon = WEAPONS[math.random(#WEAPONS)], target = char,
			name = skill .. "  ·  wave " .. r.wave, arena = {centre = centre.Position, radius = radius}, startDelay = 2.2, corpseTime = 3,
			onDeath = function()
				if ring ~= r then return end
				r.left -= 1
				if r.left <= 0 then
					-- the wave is down: a breath, a little health back, then the next
					local _, hum = alive(r.player)
					if hum then hum.Health = math.min(hum.MaxHealth, hum.Health + hum.MaxHealth * 0.35) end
					tell(r.player, "Gauntlet", "cleared", r.wave)
					task.delay(3, function() gauntletWave(r) end)
				end
			end})
		poof(bot.model)
		table.insert(r.bots, bot)
		table.insert(stuff, bot.model)
		watchTarget(bot.model)
	end
	r.startAt = os.clock() + 2.2
	tell(r.player, "Gauntlet", "wave", r.wave, list)
end

local function startGauntlet(plr)
	if ring then
		if ring.player ~= plr then toast(plr, ring.player.DisplayName .. " is in the ring right now: wait your turn") end
		return
	end
	local char, hum = alive(plr)
	local you, centre = spot("RingPlayer"), spot("Ring")
	if not (char and you and centre) then return end
	char:PivotTo(you.CFrame)
	ring = {player = plr, kind = "gauntlet", bots = {}, wave = 0, outSince = nil}
	local r = ring
	hum.Died:Once(function() if ring == r then endGauntlet("lose") end end)
	tell(plr, "Gauntlet", "start", profileOf(plr).gauntlet)
	task.delay(1, function() gauntletWave(r) end)
end

local function endRing(result)
	if ring and ring.kind == "gauntlet" then endGauntlet(result) else endSpar(result) end
end

--------------------------------------------------------------------
--  THE PRACTICE GROUND
--------------------------------------------------------------------
local PRACTICE_MAX = 3
local function clearPractice(plr, quiet)
	local P = practice[plr]
	if not P then return end
	practice[plr] = nil
	for _, b in ipairs(P.bots) do if b.model.Parent then poof(b.model); b:destroy() end end
	if not quiet then tell(plr, "Practice", "cleared") end
end

local function startPractice(plr, skill, count)
	if not SKILL_ORDER[skill] then return end
	count = math.clamp(math.floor(tonumber(count) or 1), 1, PRACTICE_MAX)
	local centre = spot("Practice")
	local char, hum = alive(plr)
	if not (centre and char) then return end
	clearPractice(plr, true)
	local radius = centre:GetAttribute("Radius") or 12
	char:PivotTo(CFrame.lookAt(centre.Position + Vector3.new(0, 2, 4), centre.Position + Vector3.new(0, 2, -4)))
	local P = {bots = {}, kills = 0, skill = skill, left = count}
	practice[plr] = P
	for i = 1, count do
		local a = -math.pi / 2 + (i - (count + 1) / 2) * 0.7
		local at = CFrame.lookAt(centre.Position + Vector3.new(math.cos(a) * (radius - 3), 2, math.sin(a) * (radius - 3)), centre.Position + Vector3.new(0, 2, 0))
		local bot = Bots.spawn({at = at, skill = skill, weapon = WEAPONS[math.random(#WEAPONS)], target = char, name = skill,
			arena = {centre = centre.Position, radius = radius + 3}, startDelay = 2, corpseTime = 3,
			onDeath = function()
				if practice[plr] ~= P then return end
				P.kills += 1
				P.left -= 1
				if P.left <= 0 then practice[plr] = nil; tell(plr, "Practice", "won", skill, count) end
			end})
		poof(bot.model)
		table.insert(P.bots, bot)
		table.insert(stuff, bot.model)
		watchTarget(bot.model)
	end
	tell(plr, "Practice", "start", skill, count)
	hum.Died:Once(function() if practice[plr] == P then clearPractice(plr, true); tell(plr, "Practice", "lost", skill) end end)
end

--------------------------------------------------------------------
--  WHERE TO GO, and the drill dummies coming and going
--------------------------------------------------------------------
local function nearestDummy(pos)
	local best, bd = nil, math.huge
	for _, m in ipairs(stuff) do
		if m.Parent and m:GetAttribute("Straw") then
			local hum, hrp = m:FindFirstChildOfClass("Humanoid"), m:FindFirstChild("HumanoidRootPart")
			if hum and hrp and hum.Health > 0 then
				local d = (hrp.Position - pos).Magnitude
				if d < bd then best, bd = hrp, d end
			end
		end
	end
	return best
end

local function targetFor(plr)
	local _, _, hrp = alive(plr)
	if not hrp then return nil end
	if (ring and ring.player == plr) or practice[plr] then return nil end   -- you're fighting
	local L = learners[plr]
	local l = L and LESSON[L.id or ""]
	if not l then return masterPos, "DRILL MASTER" end
	if l.event == "spar" then
		local c = spot("Ring")
		return c and c.Position, "THE RING"
	end
	if l.setup then
		local b = drill[l.setup]
		if b and b.alive and b.hrp then return b.hrp.Position, l.setup == "attacker" and "DRILL DUMMY" or "GUARD DUMMY" end
	end
	local d = nearestDummy(hrp.Position)
	if d then return d.Position, "STRAW DUMMY" end
	return nil
end

local function guide()
	for _, plr in ipairs(Players:GetPlayers()) do
		local pos, name = targetFor(plr)
		plr:SetAttribute("DrillTarget", pos)
		plr:SetAttribute("DrillTargetName", name or "")
	end
end

local function tidyDrills()
	local need = {}
	for _, L in pairs(learners) do
		local l = LESSON[L.id or ""]
		if l and l.setup then need[l.setup] = true end
	end
	for kind, b in pairs(drill) do
		if b and not need[kind] then
			poof(b.model)
			b:destroy()
			drill[kind] = nil
		end
	end
end

--------------------------------------------------------------------
--  START / STOP
--------------------------------------------------------------------
function Training.start(map)
	if running then Training.stop() end
	running = true
	spots = {}
	local f = map and map:FindFirstChild("Spots")
	for _, s in ipairs(f and f:GetChildren() or {}) do spots[s.Name] = s end
	for i = 1, 6 do strawDummy(i) end
	drillMaster()
	-- the challenge sign
	local sign = spot("RingSign")
	if sign then
		local prompt = Instance.new("ProximityPrompt")
		prompt.ActionText = "Challenge"
		prompt.ObjectText = "Sparring Ring"
		prompt.KeyboardKeyCode = Enum.KeyCode.E
		prompt.MaxActivationDistance = 14
		prompt.RequiresLineOfSight = false
		prompt.Parent = sign
		table.insert(conns, prompt.Triggered:Connect(function(plr) tell(plr, "Ring", records(plr)) end))
	end
	-- the practice ground's sign
	local psign = spot("PracticeSign")
	if psign then
		local prompt = Instance.new("ProximityPrompt")
		prompt.ActionText = "Call up bots"
		prompt.ObjectText = "Practice Ground"
		prompt.KeyboardKeyCode = Enum.KeyCode.E
		prompt.MaxActivationDistance = 14
		prompt.RequiresLineOfSight = false
		prompt.Parent = psign
		table.insert(conns, prompt.Triggered:Connect(function(plr) tell(plr, "Menu", menuInfo(plr), "practice") end))
	end
	-- learners: everyone here gets the first lesson they haven't done
	local function join(plr)
		local p = profileOf(plr)
		local first = firstOpen(p)
		learners[plr] = learners[plr] or {conns = {}}
		if first then setLesson(plr, first.id) else publish(plr) end
		if plr.Character then watchCharacter(plr, plr.Character) end
		table.insert(conns, plr.CharacterAdded:Connect(function(c) watchCharacter(plr, c) end))
	end
	for _, plr in ipairs(Players:GetPlayers()) do task.spawn(join, plr) end
	table.insert(conns, Players.PlayerAdded:Connect(function(plr) task.spawn(join, plr) end))
	table.insert(conns, Players.PlayerRemoving:Connect(function(plr)
		local L = learners[plr]
		if L then for _, c in ipairs(L.conns) do c:Disconnect() end end
		learners[plr] = nil
		clearPractice(plr, true)
		if ring and ring.player == plr then endRing("left") end
	end))
	table.insert(conns, remote.OnServerEvent:Connect(function(plr, what, a, b)
		if not running then return end
		if what == "Lesson" and type(a) == "string" then
			local L = learners[plr] or {conns = {}}
			learners[plr] = L
			L.replay = true   -- picked by hand: walk on from there
			setLesson(plr, a)
		elseif what == "Restart" then
			local L = learners[plr] or {conns = {}}
			learners[plr] = L
			L.replay = true
			setLesson(plr, D.lessons[1].id)
		elseif what == "Spar" and type(a) == "string" then startSpar(plr, a)
		elseif what == "Gauntlet" then startGauntlet(plr)
		elseif what == "Practice" and type(a) == "string" then startPractice(plr, a, b)
		elseif what == "ClearPractice" then clearPractice(plr)
		elseif what == "Leave" and ring and ring.player == plr then endRing("left") end
	end))
	-- four times a second: where everyone should go; the ring's referee; the
	-- last lesson's Squire meets you in the ring; drill dummies nobody needs leave
	task.spawn(function()
		local beat = 0
		while running do
			task.wait(0.25)
			beat += 1
			guide()
			if beat % 4 == 0 then tidyDrills() end
			local centre = spot("Ring")
			local radius = centre and (centre:GetAttribute("Radius") or 14) or 14
			local r = ring
			if r and centre then
				local _, _, hrp = alive(r.player)
				if hrp and os.clock() > (r.startAt or 0) then
					local d = Vector3.new(hrp.Position.X - centre.Position.X, 0, hrp.Position.Z - centre.Position.Z).Magnitude
					if d > radius + 3 then
						r.outSince = r.outSince or os.clock()
						if os.clock() - r.outSince > 4 then endRing("forfeit") end
					else
						r.outSince = nil
					end
				end
			elseif centre then
				for plr, L in pairs(learners) do
					local l = LESSON[L.id or ""]
					local _, _, hrp = alive(plr)
					if l and l.event == "spar" and hrp and not practice[plr] then
						local d = Vector3.new(hrp.Position.X - centre.Position.X, 0, hrp.Position.Z - centre.Position.Z).Magnitude
						if d < radius then startSpar(plr, l.skill or "Squire"); break end
					end
				end
			end
		end
	end)
end

function Training.stop()
	running = false
	if ring then endRing("left") end
	for plr in pairs(practice) do clearPractice(plr, true) end
	for _, c in ipairs(conns) do c:Disconnect() end
	conns = {}
	for plr, L in pairs(learners) do
		for _, c in ipairs(L.conns) do c:Disconnect() end
		if plr.Parent then plr:SetAttribute("Drill", nil); plr:SetAttribute("DrillTarget", nil); plr:SetAttribute("DrillTargetName", nil) end
	end
	learners = {}
	for _, m in ipairs(stuff) do if m.Parent then m:Destroy() end end
	stuff = {}
	drill = {}
	masterPos = nil
end

return Training
