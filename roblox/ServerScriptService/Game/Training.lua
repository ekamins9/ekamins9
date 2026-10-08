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
       • TWO MORE TEACHERS, for the classes that open at level 5: WREN THE
         BOWMASTER at the archery range (Bowmaster, ArcheryTarget1..3,
         ArcheryLine / ArcheryFar, ArcheryCharge) and MAGISTER ORRIN at the
         arcane circle (Magister, MageTarget1..3, MageCircle, MageCharge). Their
         lessons (Catalog ▸ Drills, track = "archer" / "mage") dress you as the
         class, watch arrows (full draw, the head, the far line) and spells (a
         cast, a meditation, a ward, a leaping chain, the staff's melee self),
         and end with a Squire charging at you. A player sent here to learn one
         (the PLAY menu's "learn it" after level 5: profile trainTrack, or
         _G.TrainingTrack when already here) starts on its first open lesson.
       • BASIC TRAINING: a newcomer (profile tutorial 0) gets the short course
         (Catalog ▸ Drills, basic = true) and is put right in front of each
         step's dummy, facing it. Finished — or skipped — they're on their way
         to their first battle (HubServer, _G.HubTravel).
     Players can't hurt each other here (the mode is peaceful).
     Remote: ReplicatedStorage ▸ TrainingRemote
       client → server  "Lesson", id · "Restart", track · "Spar", skill · "Leave" ·
                        "Practice", skill, count · "ClearPractice" · "Gauntlet" ·
                        "Basic", control (Find Your Feet) · "SkipTraining"
       server → client  "Menu", info, track | "practice" · "Ring", records · "Progress" · "Done", id, line ·
                        "Course" (basic training begins) · "Graduated", skipped ·
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
local GameConfig = require(ReplicatedStorage:WaitForChild("GameConfig"))
local LESSON = {}
local TRACK = {}   -- track → its lessons, in order (l.step = its place in them)
for i, l in ipairs(D.lessons) do
	l.index = i; l.track = l.track or "knight"; LESSON[l.id] = l
	TRACK[l.track] = TRACK[l.track] or {}
	table.insert(TRACK[l.track], l)
	l.step = #TRACK[l.track]
end
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
	plr:SetAttribute("DrillProgress", L and math.floor(L.n or 0) or 0)
	plr:SetAttribute("DrillGoal", l and l.goal or 0)
	local done = {}
	for id in pairs(profileOf(plr).drills) do table.insert(done, id) end
	table.sort(done)
	plr:SetAttribute("DrillsDone", table.concat(done, ","))
	-- basic training: which step of how many
	local basic = L and L.course == "basic"
	plr:SetAttribute("Course", basic and "basic" or nil)
	if basic and l then
		local n, at = 0, 0
		for _, x in ipairs(D.lessons) do if x.basic then n += 1; if x.id == l.id then at = n end end end
		plr:SetAttribute("CourseStep", at)
		plr:SetAttribute("CourseSteps", n)
	end
end

-- put a newcomer right in front of what their step needs, facing it (the
-- camera turns with them: FaceYaw / FaceTick, CameraRig)
local placeFor   -- (defined with the ring, which the last step needs)
local function face(char, cf)
	char:PivotTo(cf)
	local look = cf.LookVector
	char:SetAttribute("FaceYaw", math.atan2(-look.X, -look.Z))
	char:SetAttribute("FaceTick", (char:GetAttribute("FaceTick") or 0) + 1)
end
local function standBefore(char, at, dist)
	local look = at.CFrame.LookVector
	look = Vector3.new(look.X, 0, look.Z)
	if look.Magnitude < 0.1 then look = Vector3.new(0, 0, -1) end
	local pos = at.Position + look.Unit * dist
	face(char, CFrame.lookAt(pos, Vector3.new(at.Position.X, pos.Y, at.Position.Z)))
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
	drill[kind].model:SetAttribute("Harmless", true)   -- (its blows teach, they don't hurt)
	table.insert(stuff, drill[kind].model)
	watchTarget(drill[kind].model)
end

-- is this track's class open to them? (the Archer and the Mage wait for level 5)
local function trackOpen(plr, track)
	local t = D.tracks and D.tracks[track]
	return not (t and t.class) or Catalog.classOpen(t.class, Profile.get(plr))
end
local spawnCharger, dropCharger   -- (below, with the ranges)
local function setLesson(plr, id)
	local l = LESSON[id]
	if not l then return end
	if not trackOpen(plr, l.track) then
		local t = D.tracks[l.track]
		local c = GameConfig.CLASSES[t.class]
		toast(plr, "The " .. (c and c.name or "class") .. " opens at " .. Catalog.unlockText(c and c.unlock) .. ": come back then!")
		return
	end
	learners[plr] = learners[plr] or {conns = {}}
	local L = learners[plr]
	dropCharger(plr)
	L.id, L.n, L.sides, L.tried = id, 0, {}, {}
	L.casts, L.chain, L.medFrom = {}, {}, nil
	if l.setup then ensureDrill(l.setup) end
	-- a track's lessons are fought as its class: dressed as one where you stand
	local t = D.tracks and D.tracks[l.track]
	local char = plr.Character
	local root = char and char:FindFirstChild("HumanoidRootPart")
	if t and t.class and char and char:GetAttribute("Class") ~= t.class and _G.Respawn then
		_G.Respawn(plr, t.class, root and root.CFrame)
	elseif l.track == "knight" and char and _G.Respawn then
		-- (Sir Aldric teaches steel: out of a bow or a staff, into your own class, or the default)
		local cd = GameConfig.CLASSES[char:GetAttribute("Class") or ""]
		if cd and (cd.ranged or cd.magic) then
			local own = GameConfig.CLASSES[Profile.get(plr).active]
			_G.Respawn(plr, (own and not own.ranged and not own.magic) and Profile.get(plr).active or GameConfig.DEFAULT_CLASS, root and root.CFrame)
		end
	end
	-- a Mage's lessons: a full mana bar, except the one that teaches you to win it back
	task.delay(0.8, function()
		local c = plr.Character
		if learners[plr] ~= L or L.id ~= id or not (c and c:GetAttribute("MaxMana")) then return end
		c:SetAttribute("Mana", l.event == "meditate" and 20 or c:GetAttribute("MaxMana"))
	end)
	if l.event == "charge" then task.delay(1.5, function() if learners[plr] == L and L.id == id then spawnCharger(plr, l) end end) end
	publish(plr)
	tell(plr, "Progress")
	if L.course == "basic" then task.delay(0.6, function() if learners[plr] == L and L.id == id then placeFor(plr) end end) end
end

-- the steps of basic training, in order
local function basicAfter(id)
	local seen = id == nil
	for _, l in ipairs(D.lessons) do
		if l.basic then
			if seen then return l end
			if l.id == id then seen = true end
		end
	end
	return nil
end

-- through basic training (or skipping it): to the first battle
local function graduate(plr, skipped)
	local L = learners[plr]
	if L then L.course, L.id = nil, nil end
	Profile.setTutorial(plr, 1)
	publish(plr)
	tell(plr, "Graduated", skipped == true)
	task.delay(skipped and 1.2 or 3.5, function()
		if plr.Parent and _G.HubTravel then _G.HubTravel(plr, "Warfront", {mode = "TDM", first = true}) end
	end)
end

local function firstOpen(p, track)
	for _, l in ipairs(TRACK[track or "knight"] or {}) do if not p.drills[l.id] then return l end end
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
	if L.course == "basic" then
		local nb = basicAfter(l.id)
		if nb then setLesson(plr, nb.id) else graduate(plr, false) end
		return
	end
	-- on to the next lesson: a replay walks the course in order; otherwise the
	-- next one not done yet. Past the end, the first one not done anywhere.
	dropCharger(plr)
	local list = TRACK[l.track]
	local nextL
	if L.replay then
		nextL = list[l.step + 1]
	else
		for i = l.step + 1, #list do if not p.drills[list[i].id] then nextL = list[i]; break end end
	end
	if not nextL then nextL = firstOpen(p, l.track) end
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
	elseif l.event == "arrow" and event == "hit" then
		-- an arrow in a target: at full draw, in the head, from the far line, as the lesson asks
		count = data.attack == "Arrow"
			and (not l.full or (data.power or 0) >= 0.95)
			and (not l.head or data.kind == "headshot")
			and (not l.far or (data.dist or 0) >= l.far)
	elseif l.event == "spell" and event == "hit" then
		count = data.kind == "Spell"
	elseif l.event == "chain" and event == "hit" then
		-- one Chain Lightning striking two targets (its strikes land together)
		if data.kind ~= "Spell" or data.with ~= "Chain Lightning" or not data.target then return end
		local now = os.clock()
		L.chain = L.chain or {}
		L.chain[data.target] = now
		local n = 0
		for _, at in pairs(L.chain) do if now - at < 0.5 then n += 1 end end
		count = n >= 2
		if count then L.chain = {} end
	elseif l.event == "staffhit" and event == "hit" then
		local c = plr.Character
		local tool = c and c:FindFirstChildOfClass("Tool")
		count = data.kind ~= "Spell" and tool ~= nil and tool.Name == "StaffMelee"
	elseif l.event == "cast" and event == "cast" then
		-- three DIFFERENT spells
		L.casts = L.casts or {}
		if not data.spell or L.casts[data.spell] then return end
		L.casts[data.spell] = true
		count = true
	elseif l.event == "meditate" and event == "meditate" then
		L.n = math.min(l.goal, L.n + (data.gained or 0))
		publish(plr)
		if L.n >= l.goal then complete(plr) end
		return
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
	-- a Mage's: a spell gone off (MagicServer: CastTick), a blow warded, mana won back meditating
	on("CastTick", function() note(plr, "cast", {spell = char:GetAttribute("LastCast")}) end)
	on("WardHit", function() note(plr, "ward") end)
	local lastMana = char:GetAttribute("Mana")
	on("Mana", function()
		local m = char:GetAttribute("Mana") or 0
		if lastMana and m > lastMana and char:GetAttribute("Meditating") then note(plr, "meditate", {gained = m - lastMana}) end
		lastMana = m
	end)
end

-- hits on any of our NPCs, credited to whoever struck
watchTarget = function(model)
	table.insert(conns, model:GetAttributeChangedSignal("LastHitAt"):Connect(function()
		local plr = Players:GetPlayerByUserId(model:GetAttribute("LastHitBy") or 0)
		if plr then
			local _, _, hrp = alive(plr)
			local mine = model:FindFirstChild("HumanoidRootPart") or model.PrimaryPart
			note(plr, "hit", {attack = model:GetAttribute("LastHitAttack"), kind = model:GetAttribute("LastHitKind"), target = model,
				with = model:GetAttribute("LastHitWith"), power = model:GetAttribute("LastHitPower"),
				dist = (hrp and mine) and (hrp.Position - mine.Position).Magnitude or 0})
		end
	end))
end

--------------------------------------------------------------------
--  THE STRAW DUMMIES AND THE DRILL MASTER
--------------------------------------------------------------------
local BURLAP = Color3.fromRGB(184, 150, 98)
-- spotName: where it stands (Dummy1..6 down the west side, ArcheryTarget1..3, MageTarget1..3);
-- range: "archery" / "arcane" for the Bowmaster's and the Magister's, nil for the Drill Master's
local function strawDummy(spotName, range)
	local at = spot(spotName)
	if not at or not running then return end
	local m, hum, hrp = R6.rig("Straw Dummy", {skin = BURLAP, anchored = true, noFace = true, material = Enum.Material.Fabric})
	m:SetAttribute("Straw", true)
	m:SetAttribute("Range", range)
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
			strawDummy(spotName, range)
		end)
	end)
end

local function menuInfo(plr, track)
	local p = profileOf(plr)
	local L = learners[plr]
	local spars = {}
	for k, v in pairs(p.spars) do spars[k] = v end
	local t = D.tracks and D.tracks[track or "knight"]
	local c = t and t.class and GameConfig.CLASSES[t.class]
	return {current = L and L.id or nil, records = spars, gauntlet = p.gauntlet, practicing = practice[plr] ~= nil,
		ringBusy = ring and ring.player ~= plr and ring.player.DisplayName or nil, perWave = (D.gauntlet and D.gauntlet.perWave) or 0,
		track = track or "knight", locked = (not trackOpen(plr, track or "knight")) and Catalog.unlockText(c and c.unlock) or nil}
end

-- THE TEACHERS: Sir Aldric (steel), Wren the Bowmaster (the bow), Magister Orrin (magic).
-- Each stands on its spot; E opens their menu (their track's lessons)
local TEACHERS = {
	knight = {rig = "Sir Aldric", weight = "Heavy", weapon = "Longsword", colors = {Primary = "Royal", Secondary = "Bone", Accent = "Gold", Metal = "Steel"}},
	archer = {rig = "Wren", weight = "Light", weapon = "Bow", colors = {Primary = "Forest", Secondary = "Bone", Accent = "Ochre", Metal = "Ash"}},
	mage   = {rig = "Orrin", weight = "Robe", weapon = "Staff", set = "ApprenticeRobes", colors = {Primary = "Royal", Secondary = "Bone", Accent = "Gold", Metal = "Ash"}},
}
local teacherPos = {}   -- track → where they stand
local function teacher(track)
	local T = TEACHERS[track]
	local tr = D.tracks[track]
	local at = spot(tr.spot)
	if not (T and at) then return end
	local m, hum, hrp = R6.rig(T.rig, {anchored = true})
	m:SetAttribute("Idle", true)
	m:SetAttribute("Instructor", track)
	if track == "knight" then m:SetAttribute("DrillMaster", true) end
	m:PivotTo(at.CFrame)
	m.Parent = npcFolder
	local lo = Bots.loadoutFor(T.weight, T.colors)
	if T.set then
		for _, slot in ipairs(Catalog.SLOTS) do local pc = Catalog.defaultPiece(slot, T.weight, T.set); if pc then lo[slot] = pc.id end end
	end
	pcall(Dresser.dress, m, {loadout = lo, appearance = Catalog.BODY.defaults, weight = T.weight, preview = true})
	pcall(Dresser.attachWeapon, m, T.weapon, T.weapon .. ":Default")
	hum.DisplayName = tr.master
	hum.MaxHealth, hum.Health = 1e6, 1e6
	hum.HealthDisplayType = Enum.HumanoidHealthDisplayType.AlwaysOff
	-- no one cuts the Drill Master: out of the NPC folder, and blades pass through him
	m.Parent = workspace:FindFirstChild("Map") or workspace
	for _, d in ipairs(m:GetDescendants()) do if d:IsA("BasePart") then d.CanQuery = false; d.CanTouch = false end end
	teacherPos[track] = hrp.Position
	if track == "knight" then masterPos = hrp.Position end
	local prompt = Instance.new("ProximityPrompt")
	prompt.ActionText = "Talk"
	prompt.ObjectText = (tr.short or "Teacher"):lower():gsub("^%l", string.upper):gsub(" %l", string.upper)
	prompt.KeyboardKeyCode = Enum.KeyCode.E
	prompt.MaxActivationDistance = 14
	prompt.RequiresLineOfSight = false
	prompt.Parent = hrp
	table.insert(conns, prompt.Triggered:Connect(function(plr) tell(plr, "Menu", menuInfo(plr, track), track) end))
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
	for _, b in ipairs(r.bots or {}) do
		-- the living vanish in a puff; the fallen are left to fall: their own death
		-- (Bots) ragdolls them, plays the kill effect and lays the corpse, then tidies up
		local dead = not b.alive or (b.hum and b.hum.Health <= 0)
		if b.model.Parent and not dead then poof(b.model); b:destroy() end
	end
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

-- THE COUNTDOWN: a fight starts with 3-2-1 (the client counts to the server
-- time it's given). You're held on your mark till FIGHT: no walking (SpeedMult_Hold),
-- no swings, kicks, dodges or hops (HoldUntil on the client, StunnedUntil here);
-- the bots start on the same tick (their startDelay).
local COUNT = 3
local function hold(char, seconds)
	local goAt = workspace:GetServerTimeNow() + seconds
	if not char then return goAt end
	char:SetAttribute("HoldUntil", goAt)
	char:SetAttribute("StunnedUntil", os.clock() + seconds)
	char:SetAttribute("SpeedMult_Hold", 0)
	char:SetAttribute("BlockMeter", char:GetAttribute("BlockMax") or 100)   -- a fresh breath for every start
	task.delay(seconds, function()
		if char.Parent and (char:GetAttribute("HoldUntil") or 0) <= workspace:GetServerTimeNow() + 0.02 then
			char:SetAttribute("SpeedMult_Hold", nil)
			char:SetAttribute("HoldUntil", nil)
		end
	end)
	return goAt
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
	local goAt = hold(char, COUNT)
	local radius = centre:GetAttribute("Radius") or 14
	ring = {player = plr, kind = "spar", skill = skill, bots = {}, outSince = nil}
	local r = ring
	local bot = Bots.spawn({at = them.CFrame, skill = skill, weapon = WEAPONS[math.random(#WEAPONS)], target = char,
		arena = {centre = centre.Position, radius = radius}, startDelay = goAt - workspace:GetServerTimeNow(), corpseTime = 4,
		onDeath = function() if ring == r then endSpar("win") end end})
	r.bots = {bot}
	r.startAt = bot.startAt
	table.insert(stuff, bot.model)
	watchTarget(bot.model)
	tell(plr, "Spar", "start", skill, goAt)
	-- you fall: a loss
	hum.Died:Once(function() if ring == r then endSpar("lose") end end)
end

-- (basic training) in front of this step's dummy; the last step's Squire meets you in the ring
placeFor = function(plr)
	local L = learners[plr]
	local l = L and LESSON[L.id or ""]
	local char = alive(plr)
	if not (l and char) then return end
	if ring and ring.player == plr then return end
	if l.event == "spar" then startSpar(plr, l.skill or "Squire"); return end
	if l.setup then
		local at = spot(l.setup == "attacker" and "LessonAttacker" or "LessonBlocker")
		if at then standBefore(char, at, 5.5) end
		return
	end
	-- a straw dummy of your own (newcomers spread over the six)
	local k = 1
	for i, p in ipairs(Players:GetPlayers()) do if p == plr then k = (i - 1) % 6 + 1 end end
	local at = spot("Dummy" .. k) or spot("Dummy1")
	if at then standBefore(char, at, 4.6) end
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
	local centre, them, you = spot("Ring"), spot("RingBot"), spot("RingPlayer")
	local char = r.player.Character
	if not (centre and them and char) then endGauntlet("left"); return end
	-- back on your mark, your wind back, held till FIGHT
	if you then char:PivotTo(you.CFrame) end
	local goAt = hold(char, COUNT)
	local radius = centre:GetAttribute("Radius") or 14
	r.left = #list
	for i, skill in ipairs(list) do
		local off = (i - (#list + 1) / 2) * 4.5
		local at = them.CFrame * CFrame.new(off, 0, 0)
		local bot = Bots.spawn({at = at, skill = skill, weapon = WEAPONS[math.random(#WEAPONS)], target = char,
			name = skill .. "  ·  wave " .. r.wave, arena = {centre = centre.Position, radius = radius}, startDelay = goAt - workspace:GetServerTimeNow(), corpseTime = 3,
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
	r.startAt = os.clock() + (goAt - workspace:GetServerTimeNow())
	tell(r.player, "Gauntlet", "wave", r.wave, list, goAt)
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
	local goAt = hold(char, COUNT)
	local P = {bots = {}, kills = 0, skill = skill, left = count}
	practice[plr] = P
	for i = 1, count do
		local a = -math.pi / 2 + (i - (count + 1) / 2) * 0.7
		local at = CFrame.lookAt(centre.Position + Vector3.new(math.cos(a) * (radius - 3), 2, math.sin(a) * (radius - 3)), centre.Position + Vector3.new(0, 2, 0))
		local bot = Bots.spawn({at = at, skill = skill, weapon = WEAPONS[math.random(#WEAPONS)], target = char, name = skill,
			arena = {centre = centre.Position, radius = radius + 3}, startDelay = goAt - workspace:GetServerTimeNow(), corpseTime = 3,
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
	tell(plr, "Practice", "start", skill, count, goAt)
	hum.Died:Once(function() if practice[plr] == P then clearPractice(plr, true); tell(plr, "Practice", "lost", skill) end end)
end

--------------------------------------------------------------------
--  WHERE TO GO, and the drill dummies coming and going
--------------------------------------------------------------------
local function nearestDummy(pos, range)
	local best, bd = nil, math.huge
	for _, m in ipairs(stuff) do
		if m.Parent and m:GetAttribute("Straw") and (range == nil or m:GetAttribute("Range") == range) then
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
	if l.event == "basics" or l.event == "meditate" or l.event == "cast" then return nil end   -- (right where you stand)
	-- the Bowmaster's: the line to shoot from (the far one for a long shot), then the targets
	if l.track == "archer" then
		local line = spot(l.far and "ArcheryFar" or "ArcheryLine")
		if line then
			local d = Vector3.new(hrp.Position.X - line.Position.X, 0, hrp.Position.Z - line.Position.Z).Magnitude
			if d > 6 then return line.Position, l.far and "THE FAR LINE" or "THE SHOOTING LINE" end
		end
		local t = nearestDummy(hrp.Position, "archery")
		return t and t.Position, "THE TARGETS"
	end
	-- the Magister's: the dummies beyond the circle (the staff lesson: any straw dummy)
	if l.track == "mage" and not l.setup then
		if l.event == "charge" then local c = spot("MageCircle"); return c and c.Position, "THE ARCANE CIRCLE" end
		local t = nearestDummy(hrp.Position, l.event ~= "staffhit" and "arcane" or nil)
		return t and t.Position, "STRAW DUMMY"
	end
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

-- HOLD THE LINE / SPELLBOUND: a bot comes at you down the range (or across the circle);
-- bring it down and the lesson's done. Gone if the lesson changes or you fall.
local chargers = {}   -- [player] = bot
dropCharger = function(plr)
	local b = chargers[plr]
	chargers[plr] = nil
	if b and b.model.Parent then poof(b.model); b:destroy() end
end
spawnCharger = function(plr, l)
	local char, hum = alive(plr)
	local at = spot(l.track == "archer" and "ArcheryCharge" or "MageCharge")
	if not (char and at) then return end
	dropCharger(plr)
	local bot
	bot = Bots.spawn({at = at.CFrame, skill = l.skill or "Squire", weapon = "Longsword", target = char, name = l.skill or "Squire",
		startDelay = 1.2, corpseTime = 3,
		onDeath = function()
			if chargers[plr] ~= bot then return end
			chargers[plr] = nil
			note(plr, "charge")
		end})
	poof(bot.model)
	chargers[plr] = bot
	table.insert(stuff, bot.model)
	toast(plr, "HERE HE COMES!")
	hum.Died:Once(function()
		if chargers[plr] == bot then
			dropCharger(plr)
			-- back on your feet: he comes again
			local L = learners[plr]
			local id = L and L.id
			task.delay(6, function() if learners[plr] == L and L.id == id and LESSON[id] and LESSON[id].event == "charge" then spawnCharger(plr, LESSON[id]) end end)
		end
	end)
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
	for i = 1, 6 do strawDummy("Dummy" .. i) end
	for i = 1, 3 do strawDummy("ArcheryTarget" .. i, "archery"); strawDummy("MageTarget" .. i, "arcane") end
	for track in pairs(TEACHERS) do teacher(track) end
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
		learners[plr] = learners[plr] or {conns = {}}
		local L = learners[plr]
		-- sent here to learn a class (the PLAY menu, after level 5): its first lesson not done
		local want = p.trainTrack
		if want then p.trainTrack = nil; Profile.markDirty(plr) end
		local wantL = want and TRACK[want] and trackOpen(plr, want) and (firstOpen(p, want) or TRACK[want][1])
		if (p.tutorial or 2) < 1 then
			-- a newcomer: basic training, from the first step
			L.course = "basic"
			tell(plr, "Course")
			setLesson(plr, basicAfter(nil).id)
		elseif wantL then
			-- straight in as that class, on its first lesson
			local cls = D.tracks[want].class
			if cls and _G.Respawn and not alive(plr) then _G.Respawn(plr, cls) end
			task.delay(1.5, function() if learners[plr] == L then setLesson(plr, wantL.id) end end)
		else
			local first = firstOpen(p, "knight")
			if first then setLesson(plr, first.id) else publish(plr) end
		end
		if plr.Character then watchCharacter(plr, plr.Character) end
		table.insert(conns, plr.CharacterAdded:Connect(function(c)
			watchCharacter(plr, c)
			-- a class lesson is fought as that class: back in the wrong body, dressed again
			local l = LESSON[L.id or ""]
			local tr = l and D.tracks[l.track]
			if tr and tr.class then
				task.delay(1, function()
					if plr.Character == c and learners[plr] == L and LESSON[L.id or ""] == l and c:GetAttribute("Class") ~= tr.class and _G.Respawn then
						local root = c:FindFirstChild("HumanoidRootPart")
						_G.Respawn(plr, tr.class, root and root.CFrame)
					end
				end)
			end
			-- (and a Mage's mana bar comes with the new body)
			if l and l.track == "mage" then task.delay(0.8, function() if plr.Character == c and c:GetAttribute("MaxMana") then c:SetAttribute("Mana", l.event == "meditate" and 20 or c:GetAttribute("MaxMana")) end end) end
			-- back on your feet in basic training: straight back to your step
			if L.course == "basic" then task.delay(1, function() if plr.Character == c then placeFor(plr) end end) end
		end))
	end
	for _, plr in ipairs(Players:GetPlayers()) do task.spawn(join, plr) end
	table.insert(conns, Players.PlayerAdded:Connect(function(plr) task.spawn(join, plr) end))
	table.insert(conns, Players.PlayerRemoving:Connect(function(plr)
		local L = learners[plr]
		if L then for _, c in ipairs(L.conns) do c:Disconnect() end end
		learners[plr] = nil
		dropCharger(plr)
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
			local list = TRACK[type(a) == "string" and a or "knight"] or TRACK.knight
			setLesson(plr, list[1].id)
		elseif what == "Spar" and type(a) == "string" then startSpar(plr, a)
		elseif what == "Gauntlet" then startGauntlet(plr)
		elseif what == "Practice" and type(a) == "string" then startPractice(plr, a, b)
		elseif what == "ClearPractice" then clearPractice(plr)
		elseif what == "Leave" and ring and ring.player == plr then endRing("left")
		elseif what == "Basic" and type(a) == "string" then
			-- Find Your Feet: a control tried (once each; it's only practice, so the client's word will do)
			local L = learners[plr]
			local l = L and LESSON[L.id or ""]
			if l and l.event == "basics" and table.find(l.controls or {}, a) and not (L.tried or {})[a] then
				L.tried = L.tried or {}
				L.tried[a] = true
				L.n = 0
				for _ in pairs(L.tried) do L.n += 1 end
				publish(plr)
				if L.n >= l.goal then complete(plr) end
			end
		elseif what == "SkipTraining" and (Profile.get(plr).tutorial or 2) < 2 then
			if ring and ring.player == plr then endRing("left") end
			graduate(plr, true)
		end
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

-- already in the yard and asking to learn a class (HubServer: the PLAY menu's "learn it")
_G.TrainingTrack = function(plr, track)
	if not running or not TRACK[track] then return false end
	local p = profileOf(plr)
	local l = firstOpen(p, track) or TRACK[track][1]
	local L = learners[plr] or {conns = {}}
	learners[plr] = L
	L.replay = nil
	setLesson(plr, l.id)
	return true
end

function Training.stop()
	running = false
	if ring then endRing("left") end
	for plr in pairs(practice) do clearPractice(plr, true) end
	for plr in pairs(chargers) do dropCharger(plr) end
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
	teacherPos = {}
end

return Training
