--[[ TRAINING — the training yard's people and lessons (the Tiltyard mode starts
     and stops it with the map). Reads the map's Spots (Build ▸ MapTraining):

       • STRAW DUMMIES on the posts (Dummy1..6): they take hits, never strike
         back, and pop back up a moment after they fall.
       • THE DRILL MASTER (DrillMaster): press E to pick a lesson. The lessons
         are Catalog ▸ Drills; each one watches for its move (a hit of a kind,
         a block, a parry, a feint, a kick…) through the combat system's own
         signals, and a lesson finished for the first time pays a drill
         (Economy earn.drill, the drill stat for tasks and the title).
       • DRILL DUMMIES for the guard lessons: one swings slowly at you
         (LessonAttacker), one never drops its guard (LessonBlocker).
       • THE SPARRING RING (Ring, RingPlayer, RingBot, RingSign): pick a
         Squire, Knight or Champion bot (Combat ▸ Bots), a three-second
         countdown, then a fight to the death. Leave the ring and you forfeit.
     The client side is StarterPlayerScripts ▸ Training. Players can't hurt
     each other here (the mode is peaceful); dummies and bots are fair game.
     Remote: ReplicatedStorage ▸ TrainingRemote
       client → server  "Lesson", id · "Spar", skill · "Leave"
       server → client  "Lessons" · "Ring", records · "Progress" · "Done", id, line · "Spar", what, … ]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
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
local ring = nil          -- {player, bot, skill, outSince}

local function spot(name) return spots[name] end
local watchTarget   -- forward (defined with the lessons)
local function tell(plr, ...) if plr.Parent then remote:FireClient(plr, ...) end end
local function toast(plr, text)
	local ev = ReplicatedStorage:FindFirstChild("HubEvent")
	if ev and plr.Parent then ev:FireClient(plr, "Toast", text) end
end

--------------------------------------------------------------------
--  LESSONS
--------------------------------------------------------------------
local function profileOf(plr)
	local p = Profile.get(plr)
	if type(p.drills) ~= "table" then p.drills = {} end
	if type(p.spars) ~= "table" then p.spars = {} end
	return p
end

local function publish(plr)
	local L = learners[plr]
	local l = L and LESSON[L.id]
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

local function complete(plr)
	local L = learners[plr]
	local l = L and LESSON[L.id]
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
	-- on to the next lesson not done yet (or stop at the end)
	local nextL
	for i = l.index + 1, #D.lessons do if not p.drills[D.lessons[i].id] then nextL = D.lessons[i]; break end end
	if not nextL then for _, x in ipairs(D.lessons) do if not p.drills[x.id] then nextL = x; break end end end
	if nextL then setLesson(plr, nextL.id) else learners[plr].id = nil; publish(plr) end
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
	local prompt = Instance.new("ProximityPrompt")
	prompt.ActionText = "Train"
	prompt.ObjectText = "Drill Master"
	prompt.KeyboardKeyCode = Enum.KeyCode.E
	prompt.MaxActivationDistance = 14
	prompt.RequiresLineOfSight = false
	prompt.Parent = hrp
	table.insert(conns, prompt.Triggered:Connect(function(plr) tell(plr, "Lessons") end))
	table.insert(stuff, m)
end

--------------------------------------------------------------------
--  THE SPARRING RING
--------------------------------------------------------------------
local function records(plr)
	local p = profileOf(plr)
	local out = {}
	for k, v in pairs(p.spars) do out[k] = v end
	return out
end

local function endSpar(result)
	local r = ring
	if not r then return end
	ring = nil
	local plr = r.player
	if r.bot and r.bot.alive then r.bot:destroy() end
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
			local order = {Squire = 1, Knight = 2, Champion = 3}
			if (order[r.skill] or 0) >= (order[l.skill] or 1) then L.n = l.goal; publish(plr); complete(plr) end
		end
	else
		tell(plr, "Spar", result, r.skill)
	end
end

local function startSpar(plr, skill)
	if not Bots.SKILLS[skill] or skill == "Drill" or skill == "Guard" then return end
	if ring then
		if ring.player == plr then return end
		toast(plr, ring.player.DisplayName .. " is in the ring right now: wait your turn")
		return
	end
	local char = plr.Character
	local hrp = char and char:FindFirstChild("HumanoidRootPart")
	local hum = char and char:FindFirstChildOfClass("Humanoid")
	local you, them, centre = spot("RingPlayer"), spot("RingBot"), spot("Ring")
	if not (hrp and hum and hum.Health > 0 and you and them and centre) then return end
	char:PivotTo(you.CFrame)
	local radius = centre:GetAttribute("Radius") or 14
	ring = {player = plr, skill = skill, outSince = nil}
	local weapons = {"Longsword", "ArmingSword", "Mace", "Falchion", "Spear", "BattleAxe"}
	ring.bot = Bots.spawn({at = them.CFrame, skill = skill, weapon = weapons[math.random(#weapons)], target = char,
		arena = {centre = centre.Position, radius = radius}, startDelay = 3.2, corpseTime = 4,
		onDeath = function() if ring and ring.player == plr then endSpar("win") end end})
	table.insert(stuff, ring.bot.model)
	watchTarget(ring.bot.model)
	tell(plr, "Spar", "start", skill)
	-- you fall: a loss
	hum.Died:Once(function() if ring and ring.player == plr then endSpar("lose") end end)
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
	-- learners: everyone here gets the first lesson they haven't done
	local function join(plr)
		local p = profileOf(plr)
		local first
		for _, l in ipairs(D.lessons) do if not p.drills[l.id] then first = l; break end end
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
		if ring and ring.player == plr then endSpar("left") end
	end))
	table.insert(conns, remote.OnServerEvent:Connect(function(plr, what, a)
		if not running then return end
		if what == "Lesson" and type(a) == "string" then setLesson(plr, a)
		elseif what == "Spar" and type(a) == "string" then startSpar(plr, a)
		elseif what == "Leave" and ring and ring.player == plr then endSpar("left") end
	end))
	-- the ring referee: leave the ring for a few seconds and you forfeit
	task.spawn(function()
		while running do
			task.wait(0.5)
			local r = ring
			if r then
				local centre = spot("Ring")
				local hrp = r.player.Character and r.player.Character:FindFirstChild("HumanoidRootPart")
				if centre and hrp and os.clock() > (r.bot and r.bot.startAt or 0) then
					local d = Vector3.new(hrp.Position.X - centre.Position.X, 0, hrp.Position.Z - centre.Position.Z).Magnitude
					if d > (centre:GetAttribute("Radius") or 14) + 3 then
						r.outSince = r.outSince or os.clock()
						if os.clock() - r.outSince > 4 then endSpar("forfeit") end
					else
						r.outSince = nil
					end
				end
			end
		end
	end)
end

function Training.stop()
	running = false
	if ring then endSpar("left") end
	for _, c in ipairs(conns) do c:Disconnect() end
	conns = {}
	for plr, L in pairs(learners) do
		for _, c in ipairs(L.conns) do c:Disconnect() end
		if plr.Parent then plr:SetAttribute("Drill", nil) end
	end
	learners = {}
	for _, m in ipairs(stuff) do if m.Parent then m:Destroy() end end
	stuff = {}
	drill = {}
end

return Training
