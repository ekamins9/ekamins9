--[[ PROLOGUE — THE SIEGE OF STORMWATCH: a brand-new player's first minutes (GameConfig.MODES.Prologue,
     DOORS.Prologue). A dark, stormy night; the Iron Host is at the gate of Stormwatch; you're a
     soldier of its garrison, and you learn to fight in the middle of the battle. The castle is
     built fresh (Game ▸ StormwatchMap); the weather, the arrows over your head, the fire from the
     trebuchets, the cutscenes and the lesson card are Prologue.client's.

     THE STORY (STEPS, in order; each a line from Captain Hale, a lesson card, what counts):
       opening   (cutscene) the storm, the Host, a tower hit, Hale wakes you: you open your
                 eyes in the barracks, in first person
       arm       take a sword from the rack by the door (its prompt); you have nothing till then
       view      your eyes: the View key switches first and third person (press it)
       cursor    the mouse: the Cursor key frees it for menus and maps, and again locks it to fight
       out       follow Hale out into the storm (the view pulls back to third person at the door)
       duel      YOUR FIRST FIGHT, IN SLOW TIME: a raider comes at you out of the dark and the
                 world slows (his Tempo); each beat stops the moment (his Hold) with the key to
                 press on your screen, and runs on into what it teaches when you press it:
                 BLOCK his blow · STRIKE · STAB · OVERHEAD · PARRY his next (at the last moment)
                 · RIPOSTE · KICK his raised guard open · the blow after it, and he falls. His
                 blows can't hurt you (Harmless); every beat waits for you and comes again if it
                 went wrong. Then full speed.
       dodge     the trebuchets find the yard: when the ground glows red under you, dodge
       power     Hale's oil: the Flameblade on your Power key (yours for the rest of the night);
                 light it and strike a raider while it burns
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
                        "Line", {who, text, dur} · "Cine", name, data · "Fx", kind, data · "Done", info ·
                        "Prompt", {action, verb, sub} (the key to press, big) · "PromptDone", {text} ·
                        "PromptMiss", {text}
       Round ▸ PrologueSlow  true while the duel runs in slow time (the client's look of it)
       a character's ViewWant "First" / "Third" (CameraRig): first person in the barracks
       client → server  "CineDone", name · "Skip" · "Finish" · "Did", "view" | "cursor" (a key the
                        lesson asked for: the server can't see your camera or your mouse) ]]

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
	{id = "arm", title = "TAKE UP A SWORD", text = "The rack by the door: take a sword.", setup = "rack", captainAt = "captain",
		line = "Up, soldier! The Iron Host is at our gate and the walls are burning. Grab a blade from the rack!"},
	{id = "view", title = "YOUR EYES", text = "{View} switches between first and third person. Try it.", goal = 1, event = "view",
		prompt = {action = "View", verb = "SWITCH VIEW", sub = "first and third person"},
		line = "Get your bearings, soldier. Look about you, both ways."},
	{id = "cursor", title = "THE MOUSE", text = "{Cursor} frees your mouse for menus and the map. Press it again to fight.", goal = 2, event = "cursor",
		prompt = {action = "Cursor", verb = "FREE THE MOUSE", sub = "then press it again to lock it"},
		line = "Orders come on parchment too. Free your hand for them, then back to the blade."},
	{id = "out", title = "INTO THE STORM", text = "Follow Captain Hale out into the yard. Hold {Sprint} to run.", target = "duel", radius = 9, captainAt = "duel",
		line = "With me! Out, out!"},
	{id = "duel", title = "YOUR FIRST FIGHT", text = "Watch his blade. Do what the moment asks.", goal = 8, setup = "duel",
		line = "Raider! He's over the wall. Steady now, watch his blade..."},
	{id = "dodge", title = "INCOMING!", text = "Trebuchet fire! When the ground glows red under you, {Dodge} out of it.", goal = 2, event = "dodge", setup = "bombard",
		line = "TREBUCHETS! When the ground burns red under your feet, DODGE!"},
	{id = "power", title = "THE FLAMEBLADE", text = "Your POWER: {Power} sets your blade alight. Burn a raider with it!", goal = 1, setup = "power",
		prompt = {action = "Power", verb = "FLAMEBLADE", sub = "set your blade alight"},
		line = "Here: oil from the gatehouse fires. Light your blade and burn him!"},
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
	if i >= STEP_INDEX.duel then return "duel" end
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
		if count then self.incoming = nil; self.dodged = true; all("PromptDone", {text = "DODGED!"}) end
	elseif s.event == event then
		count = true
	end
	if not count then return end
	-- (the cursor's lesson: first it frees, then it locks again)
	if s.id == "cursor" and self.n == 0 then all("Prompt", {action = "Cursor", verb = "LOCK IT AGAIN", sub = "the mouse is yours: press it again to fight"}) end
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
	self.duelToken = nil
	node:SetAttribute("PrologueSlow", nil)
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
	if s and s.prompt and s.id ~= "power" then all("PromptDone", {text = "DONE"}) end
	task.delay(1.2, function()
		if Game.current ~= self then return end
		local nextStep = STEPS[self.step + 1]
		-- (a lesson that needs the same raider again keeps him)
		self:clearLesson()
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
	if s.prompt then all("Prompt", s.prompt) end
	local setup = s.setup
	if setup == "rack" then self:rack()
	elseif setup == "power" then self:powerLesson()
	elseif setup == "duel" then self:duel()
	elseif setup == "bombard" then self:startBombard()
	elseif setup == "volleys" then self.volleys = true
	elseif setup == "battle" then self:battle()
	elseif setup == "boss" then self:boss() end
	-- (the captain goes where the fighting is: or where the step puts him)
	if s.captainAt then
		local at = self:point(s.captainAt)
		if s.captainAt == "captain" then self:moveCaptain(at, self:point("wake"))
		else self:moveCaptain(at + Vector3.new(-6, 0, 6), at) end
		return
	end
	local here = target or (setup == "bombard" and self:point("yard")) or nil
	if here then self:moveCaptain(here + Vector3.new(-6, 0, 6), here) end
end

-- THE RACK BY THE BARRACKS DOOR: you wake with nothing in your hands (adjustLoadout keeps your
-- weapons back); its prompt hands you yours
function Prologue:rack()
	local map = MapLoader.current
	local part = map and map:FindFirstChild("SwordRack", true)
	if not part or part:FindFirstChildOfClass("ProximityPrompt") then return end
	local pp = Instance.new("ProximityPrompt")
	pp.ActionText = "Take a sword"
	pp.ObjectText = "Weapon rack"
	pp.HoldDuration = 0.3
	pp.MaxActivationDistance = 9
	pp.RequiresLineOfSight = false
	pp.Parent = part
	table.insert(self.conns, pp.Triggered:Connect(function(plr) self:takeSword(plr) end))
end
function Prologue:takeSword(plr)
	if self.armed[plr] then return end
	self.armed[plr] = true
	local kit = self.kit[plr]
	if kit and _G.GiveWeapon then
		if kit.secondary then pcall(_G.GiveWeapon, plr, kit.secondary, kit.secondarySkin, 2, false) end
		if kit.weapon then pcall(_G.GiveWeapon, plr, kit.weapon, kit.weaponSkin, 1, true) end
	end
	remote:FireClient(plr, "Fx", "Armed", {})
	local s = STEPS[self.step]
	if s and s.id == "arm" then
		all("Line", {who = HALE, text = "Good. Now follow me, and keep that blade up!", dur = 3})
		self:finishStep()
	end
end

-- THE FLAMEBLADE: the power on your Power key, and a raider to burn with it (he doesn't hit back)
function Prologue:powerLesson()
	self.powerTaught = true
	local _, c = self:hero()
	local plr = c and Players:GetPlayerFromCharacter(c)
	if c and plr then
		local Powers = require(Combat:WaitForChild("Powers"))
		Powers.equip(c, plr, {power = "Flameblade"})
	end
	local at = self:point("raiders")
	local bot = Bots.spawn({at = CFrame.lookAt(at + Vector3.new(0, 3, 0), self:point("duel") + Vector3.new(0, 3, 0)),
		skill = "Squire", weapon = "Shortsword", name = "Iron Host Raider", team = "B", scripted = true, scriptedRange = 4.3,
		invulnerable = true, corpseTime = 3, spare = false, loadout = setPieces(SETS.host), weight = "Medium"})
	if not bot then return end
	bot.model:SetAttribute("Harmless", true)
	table.insert(self.lessonBots, bot)
	self.lessonTarget = bot.model
	local m = bot.model
	local last = m:GetAttribute("LastHitAt")
	table.insert(self.conns, m:GetAttributeChangedSignal("LastHitAt"):Connect(function()
		local s = STEPS[self.step]
		if not (s and s.id == "power") or self.stepDone or m:GetAttribute("LastHitAt") == last then return end
		last = m:GetAttribute("LastHitAt")
		local _, hc = self:hero()
		if hc and (hc:GetAttribute("ImbueUntil") or 0) > workspace:GetServerTimeNow() then
			bot.invulnerable = false
			bot.hum.Health = 0
			all("PromptDone", {text = "BURNED!"})
			self:finishStep()
		else
			all("PromptMiss", {text = "Light your blade first: {Power}"})
		end
	end))
end

--------------------------------------------------------------------
--  THE DUEL IN THE YARD: your first fight, in slow time
--------------------------------------------------------------------
-- A raider comes at you out of the dark and the world slows (his Tempo: Combat ▸ CombatServer).
-- Each beat stops the moment (his Hold) with the key to press on your screen ("Prompt"); press it
-- and the moment runs on into what it teaches. His blows can't hurt (Harmless); he can't fall till
-- the last beat. Every beat waits for you, and comes again if it went wrong.
local TEMPO = 0.3
local BEATS = 8
local function bladeOf(model)
	local tool = model and model:FindFirstChildOfClass("Tool")
	return tool and tool:FindFirstChild("Hitbox", true)
end
function Prologue:duel()
	if self.duelBot and self.duelBot.alive then return end
	local at = self:point("raiders")
	local bot = Bots.spawn({at = CFrame.lookAt(at + Vector3.new(0, 3, 0), self:point("duel") + Vector3.new(0, 3, 0)),
		skill = "Squire", weapon = "Longsword", name = "Iron Host Raider", team = "B", scripted = true, scriptedRange = 4.3,
		invulnerable = true, corpseTime = 3, spare = false, loadout = setPieces(SETS.host), weight = "Medium"})
	if not bot then return end
	bot.model:SetAttribute("Harmless", true)
	bot.model:SetAttribute("Tempo", TEMPO)
	self.duelBot = bot
	table.insert(self.lessonBots, bot)
	self.lessonTarget = bot.model
	node:SetAttribute("PrologueSlow", true)
	local token = {}
	self.duelToken = token
	task.spawn(function()
		local ok, err = pcall(self.runDuel, self, bot, token)
		if not ok then warn("[Prologue] duel:", err) end
	end)
end

function Prologue:runDuel(bot, token)
	local m = bot.model
	local function live() return Game.current == self and self.duelToken == token and bot.alive and m.Parent ~= nil end
	local function hero() local _, c = self:hero(); return c end
	local function heroAttr(k) local c = hero(); return c and c:GetAttribute(k) end
	local function waitUntil(fn, timeout)
		local t0 = os.clock()
		while live() do
			if fn() then return true end
			if timeout and os.clock() - t0 > timeout then return false end
			task.wait(0.03)
		end
		return false
	end
	local function ctrl() return bot.ctrl end
	local function hold(on) m:SetAttribute("Hold", on or nil) end
	local function say(text, dur) all("Line", {who = HALE, text = text, dur = dur or 4}) end
	local function prompt(action, verb, subText) all("Prompt", {action = action, verb = verb, sub = subText}) end
	local n = 0
	local function done(text) n += 1; all("PromptDone", {text = text}); all("Progress", n, BEATS); task.wait(1.1) end
	local function miss(text) all("PromptMiss", {text = text}); task.wait(1.4) end
	local function swingOver(c)
		local s = c.snapshot()
		return s.phase == "idle" or s.phase == "recovery"
	end

	-- he comes on: armed, close, facing you
	if not waitUntil(function()
		local hr, r = rootOf(hero()), bot.hrp
		return ctrl() ~= nil and hr ~= nil and r ~= nil and (hr.Position - r.Position).Magnitude < 7.5
	end, 30) then return end
	task.wait(0.8)

	-- his blow: wound up, and the moment held at its top
	local function hisBlow(name)
		local c = ctrl()
		if not c then return nil end
		hold(false)
		waitUntil(function() local s = c.snapshot(); return s.phase == "idle" and os.clock() >= (s.nextAction or 0) end, 6)
		c.attack(name)
		waitUntil(function() local s = c.snapshot(); return s.phase ~= "windup" or os.clock() >= (s.windupEnd or 0) - 0.05 end, 10)
		hold(true)
		return c
	end
	-- your blow on him (`kind`: Swing, Stab, Overhead; nil: any)
	local NAMES = {Swing = "a swing", Stab = "a stab", Overhead = "an overhead"}
	local function yourBlow(kind)
		local last = m:GetAttribute("LastHitAt")
		while live() do
			if not waitUntil(function() return m:GetAttribute("LastHitAt") ~= last end) then return false end
			last = m:GetAttribute("LastHitAt")
			local a = tostring(m:GetAttribute("LastHitAttack") or "")
			if not kind or a:find(kind, 1, true) then return true end
			all("PromptMiss", {text = "That was " .. (NAMES[a:gsub("^Left", ""):gsub("^Right", "")] or "another blow") .. ". " .. string.upper(kind) .. "!"})
		end
		return false
	end

	-- 1 · BLOCK his blow
	while live() do
		say("Here it comes! Raise your guard, and HOLD it till his blade lands!", 5)
		local c = hisBlow("RightSwing")
		if not c then return end
		prompt("Block", "BLOCK", "Hold it till his blade lands")
		waitUntil(function() return heroAttr("Blocking") == true end)
		local g0 = heroAttr("GuardTick") or 0
		hold(false)
		waitUntil(function() return (heroAttr("GuardTick") or 0) ~= g0 or swingOver(c) end, 10)
		if (heroAttr("GuardTick") or 0) ~= g0 then done("BLOCKED!"); break end
		miss("Keep your guard up until his blade lands!")
	end
	-- 2-4 · YOUR BLOWS: he's open after it
	hold(false)
	say("He's open! Cut him!", 3)
	prompt("Swing", "STRIKE", "He's open: cut him")
	if not yourBlow("Swing") then return end
	done("HIT!")
	say("A stab: quick and straight.", 3)
	prompt("Stab", "STAB", "Quick and straight")
	if not yourBlow("Stab") then return end
	done("HIT!")
	say("From above! Slow, but it crushes a lazy guard.", 3)
	prompt("Overhead", "OVERHEAD", "From above")
	if not yourBlow("Overhead") then return end
	done("HIT!")
	-- 5 · PARRY his next: a guard raised at the last moment
	while live() do
		say("Now the parry. Wait for it... and raise your guard just as his blade comes in.", 5)
		local c = hisBlow("LeftSwing")
		if not c then return end
		task.wait(0.5)
		-- (it comes on, slow, until it's nearly on you; then the moment stops again)
		hold(false)
		local blade = bladeOf(m)
		waitUntil(function()
			local s = c.snapshot()
			if s.phase ~= "windup" and s.phase ~= "release" then return true end
			if s.phase ~= "release" then return false end
			local hr = rootOf(hero())
			if blade and hr and (blade.Position - hr.Position).Magnitude < 4.2 then return true end
			return os.clock() >= s.windupEnd + (s.releaseEnd - s.windupEnd) * 0.4
		end, 10)
		hold(true)
		prompt("Block", "PARRY", "NOW! Guard as it lands")
		waitUntil(function() return heroAttr("Blocking") == true end)
		-- (a lesson's grace: the guard you raised counts as a parry until his blade arrives)
		local hc = hero()
		if hc then hc:SetAttribute("ParryUntil", os.clock() + 3) end
		local p0 = heroAttr("ParryTick") or 0
		hold(false)
		waitUntil(function() return (heroAttr("ParryTick") or 0) ~= p0 or swingOver(c) end, 10)
		if (heroAttr("ParryTick") or 0) ~= p0 then done("PARRIED!"); break end
		miss("Raise your guard as the prompt says, and hold it!")
	end
	-- 6 · RIPOSTE: your blade glows gold; strike back
	do
		local hc = hero()
		if hc then
			hc:SetAttribute("FastUntil", os.clock() + 10)
			hc:SetAttribute("RiposteUntil", workspace:GetServerTimeNow() + 10)
			hc:SetAttribute("RiposteLen", 10)
		end
		say("A parry leaves him wide open. Strike back, now!", 4)
		prompt("Swing", "RIPOSTE", "Strike back before he recovers")
		if not yourBlow(nil) then return end
		hc = hero()
		if hc then hc:SetAttribute("FastUntil", 0); hc:SetAttribute("RiposteUntil", 0) end
		done("RIPOSTE!")
	end
	-- 7 · KICK his guard open
	say("He's hiding behind his guard now. Kick it open!", 4)
	while live() do
		local c = ctrl()
		if not c then return end
		hold(false)
		c.blockStart()
		prompt("Kick", "KICK", "Break his guard open")
		local k0 = heroAttr("KickTick") or 0
		waitUntil(function() return (heroAttr("KickTick") or 0) ~= k0 end)
		if (m:GetAttribute("StunnedUntil") or 0) > os.clock() then done("GUARD BROKEN!"); break end
		miss("Get close, and kick while his guard is up!")
	end
	-- 8 · THE BLOW AFTER IT: he reels (and the moment waits for you), then falls
	m:SetAttribute("StunnedUntil", os.clock() + 60)
	say("Now! While he reels!", 3)
	prompt("Swing", "STRIKE", "While he reels")
	if not yourBlow(nil) then return end
	m:SetAttribute("StunnedUntil", 0)
	n += 1
	all("PromptDone", {text = "HE FALLS"})
	all("Progress", n, BEATS)
	bot.invulnerable = false
	bot.hum.Health = 0
	task.wait(1.4)
	if not (Game.current == self and self.duelToken == token) then return end
	-- FULL SPEED
	node:SetAttribute("PrologueSlow", nil)
	all("Fx", "FullSpeed", {})
	all("Line", {who = HALE, text = "That's how it's done, soldier! Now it all comes at full speed. Stay sharp!", dur = 4})
	self:finishStep()
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
				all("Prompt", {action = "Dodge", verb = "DODGE", sub = "Out of the red, before it lands"})
				task.wait(1.7)
				if not self.bombard then break end
				all("Fx", "Impact", {pos = at, big = true})
				if not self.dodged then all("PromptMiss", {text = "Dodge out of the red, before it lands!"}) end
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
	self.armed, self.kit, self.outside = {}, {}, {}
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
		elseif what == "Finish" and self.over then self:sendHome(plr)
		elseif what == "Did" and (a == "view" or a == "cursor") then self:note(a) end
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
	for _, k in ipairs({"OwnHud", "OwnTop", "ObjKind", "PrologueStep", "ObjLabel", "ObjNote", "PrologueSlow"}) do node:SetAttribute(k, nil) end
end

-- you: a Knight of the garrison (your own looks), on the Crown's side. No shield, power or
-- throwable; and until you take a sword from the rack, nothing in your hands (kept for the rack)
function Prologue:adjustLoadout(plr, lo, classId)
	Teams.set(plr, "A")
	lo.power, lo.thirdKind, lo.thirdId = self.powerTaught and "Flameblade" or nil, "none", nil
	lo.throwable = nil
	lo.shield, lo.shieldSkin = nil, nil
	-- (the siege is learned with steel: a bow or a staff in your loadout is a longsword here, and a
	-- wand at the hip goes)
	local function melee(id) local w = id and Catalog.WEAPON[id]; return w and not w.ranged and not w.magic end
	if lo.weapon and not melee(lo.weapon) then lo.weapon, lo.weaponSkin = "Longsword", "Longsword:Default" end
	if lo.secondary and not melee(lo.secondary) then lo.secondary, lo.secondarySkin = nil, nil end
	if self.armed and not self.armed[plr] and (self.step or 1) <= STEP_INDEX.arm then
		self.kit[plr] = {weapon = lo.weapon, weaponSkin = lo.weaponSkin, secondary = lo.secondary, secondarySkin = lo.secondarySkin}
		lo.weapon, lo.weaponSkin, lo.secondary, lo.secondarySkin = nil, nil, nil, nil
	end
end
function Prologue:noteSpawn(plr)
	local char = plr.Character
	if not char then return end
	Teams.mark(char, "A")
	-- (first person in the barracks; third once you're out of its door)
	char:SetAttribute("ViewWant", (self.outside and not self.outside[plr]) and "First" or nil)
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
	-- out of the barracks' door: the view pulls back
	for _, p in ipairs(Players:GetPlayers()) do
		if self.outside and not self.outside[p] then
			local r = rootOf(p.Character)
			local wake, door = self:point("wake"), self:point("door")
			if r and (r.Position - wake).Magnitude > (door - wake).Magnitude - 3.5 then
				self.outside[p] = true
				p.Character:SetAttribute("ViewWant", "Third")
			end
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
