--[[ BOTS — AI fighters on the real combat system: a bot carries an ordinary
     weapon Tool, whose combat controller runs in NPC mode (server-side swings
     and blade sweeps, like the test dummies), so a bot's swing can be blocked,
     parried, chambered and dodged like a player's. Used by the training yard,
     Horde, Siege's champions and the admin panel.

       Bots.spawn(opts) -> bot
           opts.at        CFrame where it appears
           opts.weapon    Tool name in ServerStorage ▸ Weapons (default Longsword)
           opts.skill     "Squire" | "Knight" | "Champion" (Bots.SKILLS)
           opts.name      shown over its head
           opts.loadout / appearance / weight / team   its look (Dresser)
           opts.target    the character to fight (default: the nearest player)
           opts.fightBots also fights other bots not on its team (a match's
                          bot fill: Game ▸ BotFill); default players only
           opts.goal      fn() -> Vector3 | nil: where to head when no foe is
                          near (an objective: the hill, the ram)
           opts.arena     {centre = Vector3, radius = n}: it keeps inside
           opts.onDeath   fn(bot, killerPlayer)
           opts.startDelay  seconds before it moves or strikes (a countdown)
           opts.invulnerable  never dies (a drill dummy)
           opts.spare     a secondary it draws when disarmed (a weapon name; false = none;
                          default: by skill, a random secondary)
           opts.class     "Archer" | "Mage": it fights as one (GameConfig.CLASSES: its health,
                          its look; a bow or a crossbow and a sidearm, or a staff and spells)
       bot:destroy()      bot.model  bot.hum  bot.alive
       Bots.SKILLS        Bots.list()

     It plays by the players' rules: the same walk speed (armor weight, slower
     sideways and backwards, a sprint to close distance), the same turn cap
     while it swings, the same stamina. Ten times a second it decides where to
     stand and when to swing; every frame its reflexes watch the foe's weapon:
       • a windup it parries: a good fighter raises its guard so the blade
         arrives mid-way through the parry window (and learns how long each
         of your attacks takes to land), so only a late feint baits it;
       • its own parry it answers with a riposte, a whiff it punishes, a guard
         held up too long it kicks, a guard raised early it feints or morphs
         around, a swing that landed it chains into a combo;
       • it keeps stamina in reserve and backs off to get it back when low;
       • disarmed, it draws its spare or goes and picks a weapon up.
     AN ARCHER keeps its distance, draws (a good one to the full), leads you and looses
     (a Champion goes for the head); too close, it draws its sidearm, and steps back out
     to the bow. A MAGE keeps back, casts what fits (Mend when hurt, Frost Nova up close,
     lightning, a meteor, fire), holds it charged till it has you, wards a blow coming in
     and meditates when nobody's near. Both work their weapon through its controller's
     npc() (RangedServer / MagicServer): the players' own rules.
     Movement is server-side; clients animate its legs (NpcAnimator). ]]

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local PathfindingService = game:GetService("PathfindingService")
local ServerStorage = game:GetService("ServerStorage")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CombatServer = require(script.Parent:WaitForChild("CombatServer"))
local Pickup = require(script.Parent:WaitForChild("Pickup"))
local Corpses = require(script.Parent:WaitForChild("Corpses"))
local Dresser = require(ReplicatedStorage:WaitForChild("Dresser"))
local Catalog = require(ReplicatedStorage:WaitForChild("Catalog"))
local MC = require(ReplicatedStorage:WaitForChild("MovementConfig"))
local Modifiers = require(ReplicatedStorage:WaitForChild("Modifiers"))
local GameConfig = require(ReplicatedStorage:WaitForChild("GameConfig"))
local Spells = require(ReplicatedStorage:WaitForChild("MagicSpells"))

local Bots = {}
-- react     seconds from a foe's windup before it can answer it at all
-- parry     chance it meets a swing with a parry (else it steps back out of the way)
-- read      it times its guard to when the blade will arrive (and learns each attack's timing
--           as the fight goes on); without it, it raises its guard as soon as it sees a windup
-- bait      chance it raises its guard early anyway, before the windup ends (a feint baits that)
-- jitter    ± seconds of error in that timing
-- riposte   chance it answers its own parry with a swing at once
-- punish    chance it swings into a foe's recovery (a whiff, a parried swing)
-- chamber   chance it meets a swing with the mirror attack instead (a chamber)
-- feint / morph   chance its swing is feinted or morphed when the foe raises a guard early
-- combo     chance a swing of its that lands chains into another
-- kick      chance it kicks a guard held up too long
-- reserve   stamina it keeps back; below it, it backs off and gets its wind back
-- interval  seconds between its own swings when nothing better comes up
-- pace      its speed against a player's in the same armor (1 = the same)
-- step      chance it steps back and aside from a swing it doesn't parry (else it stands its
--           ground: it trades, or eats the blow) — a short step, after its reaction time
-- aggression  how often its footwork presses in (else it circles, watches, or gives ground)
-- hesitate  how often it just stands and watches for a moment
-- spare     chance it carries a secondary to draw when disarmed
-- miss      chance it doesn't read a swing at all (no guard, no step: it eats it or trades)
-- fooled    chance a feint gets it: the guard it raised for a swing that never came drops,
--           and the real one finds it in its re-guard cooldown
-- (winded — under 30 stamina — it misses more and its timing goes loose)
Bots.SKILLS = {
	Squire   = {react = 0.32, parry = 0.3,  read = false, bait = 1,    jitter = 0.16,  riposte = 0.2,  punish = 0.25, chamber = 0,    feint = 0,    morph = 0,    combo = 0,
		kick = 0.10, reserve = 0,  interval = {1.7, 2.7}, pace = 0.95, spare = 0.3, label = "Squire",   weight = "Light",
		step = 0.3, aggression = 0.35, hesitate = 0.25, miss = 0.3, fooled = 0.85},
	Knight   = {react = 0.21, parry = 0.6,  read = true,  bait = 0.5,  jitter = 0.1,   riposte = 0.5,  punish = 0.55, chamber = 0.05, feint = 0.12, morph = 0.12, combo = 0.15,
		kick = 0.35, reserve = 22, interval = {1.1, 1.9}, pace = 1,    spare = 0.8, label = "Knight",   weight = "Medium",
		step = 0.35, aggression = 0.45, hesitate = 0.15, miss = 0.14, fooled = 0.55},
	Champion = {react = 0.14, parry = 0.8,  read = true,  bait = 0.3,  jitter = 0.06,  riposte = 0.8,  punish = 0.85, chamber = 0.15, feint = 0.28, morph = 0.22, combo = 0.35,
		kick = 0.6,  reserve = 35, interval = {0.8, 1.4}, pace = 1,    spare = 1,   label = "Champion", weight = "Heavy",
		step = 0.3, aggression = 0.55, hesitate = 0.1, miss = 0.06, fooled = 0.3},
	-- the training yard's drill dummies: one throws slow, readable swings and
	-- overheads from where it stands; the other only ever holds its guard
	Drill    = {react = 9, parry = 0, read = false, bait = 0, jitter = 0, riposte = 0, punish = 0, chamber = 0, feint = 0, morph = 0, combo = 0,
		kick = 0, reserve = 0, interval = {2.3, 3.0}, pace = 0, spare = 0, label = "Drill Dummy", weight = "Light", kinds = {"Swing", "Overhead"}, dummy = true},
	Guard    = {react = 9, parry = 0, read = false, bait = 0, jitter = 0, riposte = 0, punish = 0, chamber = 0, feint = 0, morph = 0, combo = 0,
		kick = 0, reserve = 0, interval = {99, 99}, pace = 0, spare = 0, label = "Guard Dummy", weight = "Heavy", guard = true, dummy = true},
}
local SPARES = {"Shortsword", "ArmingSword", "Falchion", "Mace", "WarAxe", "Dagger", "Hammer", "Cleaver"}
local TURN_DPS = 720        -- how fast it turns to keep facing you (degrees per second)…
local TURN_CAP_DPS = 400    -- …and while it swings: the players' turn cap (CameraRig)
local FEINT_COST = CombatServer.DEFAULTS.FEINT_COST or 16
local MORPH_COST = CombatServer.DEFAULTS.MORPH_COST or 10
local IDLE = {phase = "idle", windupStart = -1, windupEnd = -1, releaseEnd = -1}

-- TEMPERS: no two bots fight quite alike. Each gets one at random (opts.temper picks):
-- agg / hes shift how often it presses in or stands and watches; engage is how many
-- may fight one foe at once before it waits its turn (a brute barely waits); a
-- flanker, waiting, works its way round behind you
Bots.TEMPERS = {
	brute   = {agg = 0.25,  hes = -0.1, engage = 3},
	duelist = {agg = 0,     hes = 0,    engage = 2},
	wary    = {agg = -0.2,  hes = 0.15, engage = 2},
	flanker = {agg = -0.05, hes = 0,    engage = 2, flank = true},
}
local TEMPER_NAMES = {"brute", "duelist", "duelist", "wary", "flanker"}

-- THE CROWD: round each foe, bots are ranked by how near they stand; only the
-- first few (the temper's `engage`) fight, the rest keep a ring a few strides out
-- and circle, waiting for a gap. A crowd that all rushes in at once is a blender,
-- not a fight. (Ranked a few times a second, for every bot at once.)
local live = {}
local slotCache, slotAt = {}, 0
local function slotOf(bot)
	local now = os.clock()
	if now - slotAt > 0.4 then
		slotAt = now
		slotCache = {}
		local by = {}
		for b in pairs(live) do
			if b.alive and b.ctrl and b.foe and b.foe.Parent then
				by[b.foe] = by[b.foe] or {}
				table.insert(by[b.foe], b)
			end
		end
		for _, list in pairs(by) do
			table.sort(list, function(a, c) return (a.dist or 99) < (c.dist or 99) end)
			for i, b in ipairs(list) do slotCache[b] = i end
		end
	end
	return slotCache[bot] or 1
end

-- what each rank wears, so you can tell them apart at a glance: a set picked
-- from its list (armor sets of its weight: Catalog ▸ Pieces "<Set>_Helm/Top/Legs"),
-- in its colours. Levy cloth for Squires, mail and surcoats for Knights, full
-- plate in black and blood for Champions.
local LOOKS = {
	Squire   = {sets = {"PeasantSkin", "RoadLevy", "CoastHarriers"}, colors = {Primary = "Umber", Secondary = "Moss", Accent = "Sand", Metal = "Ash"}},
	Knight   = {sets = {"RiverGuard", "Sellswords", "WolfCompany", "GildedCourt"}, colors = {Primary = "Navy", Secondary = "White", Accent = "Gold", Metal = "Steel"}},
	Champion = {sets = {"Blackguard", "IronCrow", "SunKnights", "TourneyKnight"}, colors = {Primary = "Jet", Secondary = "Blood", Accent = "Gold", Metal = "Steel"}},
}
local SLOT_SUFFIX = {helmet = "Helm", top = "Top", bottom = "Legs"}
-- ARCHERS AND MAGES (opts.class): how far off it aims (studs, at forty paces), the gap between
-- its shots / casts, what a Mage carries, and the robes it wears by rank
local CASTER = {
	aim  = {Squire = 2.8, Knight = 1.4, Champion = 0.6},
	gap  = {Squire = {1.8, 3.0}, Knight = {1.1, 2.0}, Champion = {0.7, 1.3}},
	book = {Squire = "Firebolt,FrostNova,Mend,ChainLightning", Knight = "Firebolt,IceLance,ChainLightning,FrostNova",
		Champion = "Firebolt,ChainLightning,Meteor,FrostNova"},
	robes = {Squire = {"ApprenticeRobes"}, Knight = {"Druid", "Pyromancer", "FrostWitch", "Necromancer"}, Champion = {"Archmage", "Battlemage", "Necromancer"}},
}

-- a bot's pieces: its rank's look when it has one (and the pieces exist at this
-- weight), else the weight's free starter pieces; in its rank's colours
function Bots.loadoutFor(weight, colors, skill)
	local look = skill and LOOKS[skill]
	local lo = {colors = colors or (look and look.colors) or {Primary = "Crimson", Secondary = "Slate", Accent = "Ochre", Metal = "Ash"}}
	local set = look and look.sets[math.random(#look.sets)]
	for _, slot in ipairs(Catalog.SLOTS) do
		local p = set and SLOT_SUFFIX[slot] and Catalog.PIECE[set .. "_" .. SLOT_SUFFIX[slot]]
		if not p or p.weight ~= weight then p = Catalog.defaultPiece(slot, weight) end
		lo[slot] = p and p.id or nil
	end
	return lo
end

local folder = workspace:FindFirstChild("NPCs")
if not folder then folder = Instance.new("Folder"); folder.Name = "NPCs"; folder.Parent = workspace end


local R6 = require(script.Parent:WaitForChild("R6"))

local function findWeapon(name)
	local f = ServerStorage:FindFirstChild("Weapons")
	local t = f and f:FindFirstChild(name or "Longsword")
	return t and t:IsA("Tool") and t or nil
end

local function configOf(tool)
	local mod = tool:FindFirstChild("Config")
	if mod then local ok, c = pcall(require, mod); if ok and type(c) == "table" then return c end end
	return {}
end

local function attacksOf(tool)
	local out, cfg = {}, configOf(tool)
	for n, a in pairs(cfg.ATTACKS or {}) do
		if type(a.anim) == "string" and a.anim ~= "" and a.anim ~= "rbxassetid://0" then table.insert(out, n) end
	end
	table.sort(out)
	return out, cfg.REACH or 6, cfg
end

-- how far whatever the foe holds reaches (cached per tool)
local reachCache = setmetatable({}, {__mode = "k"})
local function reachOf(char)
	local tool = char and char:FindFirstChildOfClass("Tool")
	if not tool then return 3 end
	local r = reachCache[tool]
	if not r then r = configOf(tool).REACH or CombatServer.DEFAULTS.REACH or 6; reachCache[tool] = r end
	return r
end

local function controllerOf(char)
	local tool = char and char:FindFirstChildOfClass("Tool")
	return tool and CombatServer.controllers[tool] or nil
end
local function staminaOf(char) return char:GetAttribute("BlockMeter") or char:GetAttribute("BlockMax") or 100 end
local function rand(r) return r[1] + math.random() * (r[2] - r[1]) end
local function handleOf(tool) return tool:FindFirstChild("Handle") or tool:FindFirstChildWhichIsA("BasePart", true) end

--------------------------------------------------------------------
--  ATTACKS
--------------------------------------------------------------------
-- the nearest living player not on `team` (a bot's own side)
local function nearestPlayer(pos, team)
	local best, bestD = nil, math.huge
	for _, p in ipairs(Players:GetPlayers()) do
		local c = p.Character
		if team and c and c:GetAttribute("Team") == team then c = nil end
		local hrp = c and c:FindFirstChild("HumanoidRootPart")
		local hum = c and c:FindFirstChildOfClass("Humanoid")
		if hrp and hum and hum.Health > 0 then
			local d = (hrp.Position - pos).Magnitude
			if d < bestD then best, bestD = c, d end
		end
	end
	return best
end

-- the nearest foe for a bot that also fights bots: players and living bots
-- not on its team (no team: everyone but itself). Dummies and the
-- invulnerable aren't foes.
local function nearestFoe(self, pos, team)
	local best, bestD = nearestPlayer(pos, team), math.huge
	if best then bestD = (best.HumanoidRootPart.Position - pos).Magnitude end
	for b in pairs(live) do
		if b ~= self and b.alive and not b.invulnerable and not b.skill.dummy and b.model.Parent and b.hum.Health > 0 then
			local t = b.model:GetAttribute("Team")
			if team == nil or t ~= team then
				local d = (b.hrp.Position - pos).Magnitude
				if d < bestD then best, bestD = b.model, d end
			end
		end
	end
	return best, bestD
end

-- a teammate PLAYER standing in its swing (in front, inside the arc, nearer than
-- the foe): it doesn't swing through them. (Its blade passes through the bots on
-- its side: CombatServer.botFriends.)
local function friendInTheWay(self, dir, dist, reach)
	local team = self.model:GetAttribute("Team")
	if team == nil then return false end
	local pos = self.hrp.Position
	local function inTheWay(c)
		if not c or c == self.model or c:GetAttribute("Team") ~= team then return false end
		local hrp = c:FindFirstChild("HumanoidRootPart")
		local hum = c:FindFirstChildOfClass("Humanoid")
		if not (hrp and hum and hum.Health > 0) then return false end
		local off = hrp.Position - pos
		off = Vector3.new(off.X, 0, off.Z)
		local d = off.Magnitude
		return d < math.min(reach, dist + 0.5) and (d < 1.5 or off.Unit:Dot(dir) > 0.35)
	end
	for _, p in ipairs(Players:GetPlayers()) do if inTheWay(p.Character) then return true end end
	return false
end

-- a swing may not turn into (or chain after) the mirror of itself, or an
-- overhead into an underhand (CombatServer's morph rules)
local FORBID = {Overhead = "Underhand", Underhand = "Overhead"}
local function canFollow(prev, n)
	if not prev then return true end
	if n == prev then return false end
	local ps, pt = CombatServer.sideType(prev)
	local ns, nt = CombatServer.sideType(n)
	if pt == nt and ps and ns and ps ~= ns then return false end
	return FORBID[pt] ~= nt
end

-- the weapon's attacks weighted by what they do: a spear mostly stabs, an axe mostly cuts
local function weightsOf(bot)
	if bot.weights then return bot.weights end
	local w = {}
	for _, n in ipairs(bot.attacks) do
		local info = (bot.cfg.ATTACKS or {})[n] or {}
		local d = type(info.damage) == "table" and (info.damage.body or info.damage.torso or 20) or (info.damage or 20)
		w[n] = math.max(1, d) ^ 1.6
	end
	bot.weights = w
	return w
end

local function pickAttack(bot, after)
	if #bot.attacks == 0 then return nil end
	if bot.skill.kinds then
		local kind = bot.skill.kinds[math.random(#bot.skill.kinds)]
		local want = (math.random() < 0.5 and "Left" or "Right") .. kind
		for _, n in ipairs(bot.attacks) do if n == want then return n end end
		for _, n in ipairs(bot.attacks) do if n:find(kind, 1, true) then return n end end
		return bot.attacks[math.random(#bot.attacks)]
	end
	local w, total = weightsOf(bot), 0
	for _, n in ipairs(bot.attacks) do if canFollow(after, n) then total += w[n] end end
	if total <= 0 then return nil end
	local x = math.random() * total
	for _, n in ipairs(bot.attacks) do
		if canFollow(after, n) then
			x -= w[n]
			if x <= 0 then return n end
		end
	end
	return nil
end

local function costOf(bot, name)
	local info = name and (bot.cfg.ATTACKS or {})[name]
	return info and info.staminaCost or 8
end

-- the attack that chambers theirs: the same type from the other side; any stab answers a stab
local function mirrorOf(bot, theirName, theirKind)
	for _, n in ipairs(bot.attacks) do
		local info = (bot.cfg.ATTACKS or {})[n]
		if info and CombatServer.chamberMatch(theirName, theirKind, n, info.kind) then return n end
	end
	return nil
end

--------------------------------------------------------------------
--  THE BOT
--------------------------------------------------------------------
local Bot = {}
Bot.__index = Bot

function Bot:destroy()
	self.alive = false
	if self.hum and self.hum.Health <= 0 then Corpses.lay(self.model, self.model:GetAttribute("RemainsPending") or "body") end
	for _, c in ipairs(self.conns) do c:Disconnect() end
	live[self] = nil
	if self.model.Parent then self.model:Destroy() end
end

-- take up a weapon: into the hand, then wait for its combat controller
function Bot:adopt(tool)
	self.arming = true
	self.tool = tool
	self.attacks, self.reach, self.cfg = attacksOf(tool)
	self.weights, self.ctrl, self.disarmedAt = nil, nil, nil
	if tool.Parent ~= self.model then tool.Parent = self.model end
	for _ = 1, 60 do
		self.ctrl = CombatServer.get(tool)
		if self.ctrl or not self.alive then break end
		task.wait(0.05)
	end
	if #self.attacks == 0 and not (self.ctrl and (self.ctrl.ranged or self.ctrl.magic)) then self.ctrl = nil end
	self.arming = false
end
-- (an archer's bow and sidearm: the one not in hand waits in its Stash, worn on the body — a
-- loose tool would fall through the world)
local STASH_AT = {Bow = CFrame.new(-0.2, 0.1, 0.62) * CFrame.Angles(0, 0, math.rad(-28)), Crossbow = CFrame.new(0, 0.2, 0.7) * CFrame.Angles(math.rad(-90), 0, math.rad(35))}
local function stashTool(model, tool)
	local stash = model:FindFirstChild("Stash")
	if not stash then stash = Instance.new("Folder"); stash.Name = "Stash"; stash.Parent = model end
	tool.Parent = stash
	local torso, handle = model:FindFirstChild("Torso"), tool:FindFirstChild("Handle")
	if torso and handle then
		local w = Instance.new("Weld")
		w.Name = "StashWeld"; w.Part0, w.Part1 = torso, handle
		w.C0 = STASH_AT[tool.Name] or (CFrame.new(-1.12, -0.85, -0.15) * CFrame.Angles(math.rad(150), 0, math.rad(-8)))
		w.Parent = handle
	end
end
local function unstash(tool)
	local h = tool:FindFirstChild("Handle")
	local w = h and h:FindFirstChild("StashWeld")
	if w then w:Destroy() end
end
function Bot:swapTo(tool)
	if self.arming or not tool or tool == self.tool or not tool.Parent then return end
	if self.tool and self.tool.Parent == self.model then stashTool(self.model, self.tool) end
	unstash(tool)
	task.spawn(self.adopt, self, tool)
end

-- disarmed: draw the spare, or go and get a weapon off the floor. Returns
-- where to walk (nil: nothing to be had, keep away)
function Bot:rearm(now)
	if self.arming then return Vector3.zero end
	self.disarmedAt = self.disarmedAt or now
	local best, d = Pickup.nearest(self.hrp.Position, 45, self.model)   -- (one-armed: one-handers only)
	local spareSrc = self.spare and findWeapon(self.spare)
	if spareSrc and not Pickup.canHold(self.model, spareSrc) then self.spare = nil end
	if self.spare and (not best or d > 14 or now - self.disarmedAt > 2.5) then
		local name = self.spare
		self.spare = nil
		self.arming = true
		task.spawn(function()
			task.wait(0.7)   -- reaching for it
			local src = findWeapon(name)
			if src and self.alive then self:adopt(src:Clone()) end
			self.arming = false
		end)
		return Vector3.zero
	end
	if not best then return nil end
	if d <= 4.5 then
		self.arming = true
		task.spawn(function()
			task.wait(0.35)   -- stooping for it
			if self.alive and best.Parent and Pickup.takeNpc(self.model, best) then self:adopt(best) end
			self.arming = false
		end)
		return Vector3.zero
	end
	local h = handleOf(best)
	if not h then return nil end
	local to = h.Position - self.hrp.Position
	self.lookAt = Vector3.new(to.X, 0, to.Z)
	return self.lookAt.Magnitude > 0.01 and self.lookAt.Unit or Vector3.zero
end

-- WalkSpeed by the players' rules (MovementConfig, the armor's SpeedMult, the weapon's, a
-- swing's): full speed forward, slower sideways and backwards, a sprint to close distance
function Bot:speedFor(mv, far, busy)
	local look = self.hrp.CFrame.LookVector
	local fwd = Vector3.new(look.X, 0, look.Z)
	local dot = (mv.Magnitude > 0.01 and fwd.Magnitude > 0.01) and mv.Unit:Dot(fwd.Unit) or 1
	local facing = 1
	if dot < -MC.BACKPEDAL_DOT then facing = MC.BACKPEDAL_MULT elseif dot < MC.FORWARD_DOT then facing = MC.STRAFE_MULT end
	local sprint = 1
	if far and not busy and dot >= MC.SPRINT_MIN_DOT then sprint = self.model:GetAttribute("SprintMult") or MC.SPRINT_MULT end
	return MC.BASE_SPEED * Modifiers.product(self.model, "SpeedMult") * facing * sprint * (self.skill.pace or 1)
end

-- how to meet the foe's new swing
function Bot:choosePlan(f, me)
	local sk = self.skill
	local st = staminaOf(self.model)
	if me.phase == "release" or me.phase == "kick" then return "none" end     -- committed: it trades
	if me.phase == "windup" then
		-- swinging into their swing: pull ours into a parry if theirs lands first (a feint it pays for)
		if f.windupEnd < me.windupEnd and math.random() < sk.parry * 0.7 and st >= FEINT_COST + 4 then return "parry" end
		return "none"
	end
	-- it didn't read that one (more often when it's winded)
	if math.random() < (sk.miss or 0) * (st < 30 and 1.8 or 1) then return "none" end
	if sk.chamber > 0 and math.random() < sk.chamber and st >= sk.reserve * 0.5 + 8 and mirrorOf(self, f.name, f.kind) then return "chamber" end
	if math.random() < sk.parry then return "parry" end
	if math.random() < (sk.step or 0.3) then return "step" end
	return "none"
end

-- FOOTWORK MOODS: for a second or two at a time it presses in, circles at the
-- edge of reach, stands and watches, or gives ground — not a perfect spacing
-- held ten times a second
local MOODS = {press = {1.0, 2.2}, circle = {1.0, 2.4}, wait = {0.4, 1.1}, back = {0.6, 1.2}}
function Bot:pickMood(soon)
	local sk = self.skill
	local mood
	if soon then mood = "press"
	elseif self.recovering then mood = math.random() < 0.6 and "back" or "circle"
	else
		local t = self.temper or Bots.TEMPERS.duelist
		local agg = math.clamp((sk.aggression or 0.45) + t.agg, 0.05, 0.9)
		local hes = math.max(0, (sk.hesitate or 0.15) + t.hes)
		local r = math.random()
		mood = r < agg and "press" or (r < agg + 0.3 and "circle") or (r < agg + 0.3 + hes and "wait") or "back"
	end
	self.mood, self.moodUntil = mood, os.clock() + rand(MOODS[mood])
end

-- after starting a swing: feint or morph it if the foe guards early, chain it if it lands
function Bot:armTricks(feint, morph, combo)
	local me = self.ctrl and self.ctrl.snapshot()
	if not me or me.phase ~= "windup" then return end
	local r = math.random()
	self.trickFor, self.trickKind = nil, nil
	if r < feint then self.trickFor, self.trickKind = me.windupStart, "feint"
	elseif r < feint + morph then self.trickFor, self.trickKind = me.windupStart, "morph" end
	self.comboFor = (math.random() < combo) and me.windupStart or nil
end

-- REFLEXES, every frame: the foe's weapon and its own
function Bot:reflex()
	local sk, ctrl, model = self.skill, self.ctrl, self.model
	if not (self.alive and ctrl) or sk.dummy or self.arming then return end
	if ctrl.ranged or ctrl.magic then return end
	local foe = self.foe
	if not (foe and foe.Parent) or self.hum.Health <= 0 or model:GetAttribute("Ragdolled") then return end
	local now = os.clock()
	if now < self.startAt then return end
	local me = ctrl.snapshot()
	local blocking = model:GetAttribute("Blocking") == true
	local fc = controllerOf(foe)
	local f = fc and fc.snapshot() or IDLE

	-- a parry of ours just landed: the riposte (a quicker windup), straight away
	local pt = model:GetAttribute("ParryTick") or 0
	if pt ~= self.parryTick then
		self.parryTick = pt
		if blocking and math.random() < sk.riposte then
			local name = pickAttack(self)
			if name and staminaOf(model) >= costOf(self, name) then
				ctrl.blockStop()
				self.guardAt = nil
				ctrl.attack(name)
				self:armTricks(sk.feint * 0.6, 0, 0)
				self.nextAttack = now + rand(sk.interval)
				return
			end
		end
	end

	-- learn when each of the foe's attacks lands: the moment a guard of ours is
	-- struck (block, parry, chamber) or we're cut, measured from the end of its windup
	local gt, hitAt = model:GetAttribute("GuardTick") or 0, model:GetAttribute("LastHitAt") or 0
	if gt ~= self.guardTick or hitAt ~= self.hitAt then
		local obs = self.trackEnd and now - self.trackEnd
		if obs and obs > -0.05 and obs < 1.5 and self.trackKey then
			local old = self.learned[self.trackKey]
			self.learned[self.trackKey] = old and (old * 0.6 + math.max(obs, 0) * 0.4) or math.max(obs, 0)
		end
		self.guardTick, self.hitAt = gt, hitAt
	end

	-- the foe's swing
	local live_ = (f.phase == "windup" or f.phase == "release") and (self.dist or 99) < math.max(self.reach, reachOf(foe)) + 4
	if live_ then
		local ftool = foe:FindFirstChildOfClass("Tool")
		self.trackKey, self.trackEnd = (ftool and ftool.Name or "?") .. ":" .. tostring(f.name), f.windupEnd
		if f.windupStart ~= self.seenStart then
			self.seenStart = f.windupStart
			self.plan = self:choosePlan(f, me)
			self.jit = (math.random() * 2 - 1) * sk.jitter * (staminaOf(model) < 30 and 1.7 or 1)
			self.early = not sk.read or math.random() < sk.bait
			if self.plan == "step" then
				-- it has to see the swing coming first, and then it's a step, not a retreat
				self.stepAt = f.windupStart + sk.react + math.abs(self.jit) + math.random() * 0.12
				self.stepUntil = self.stepAt + 0.35 + math.random() * 0.25
				self.stepSide = math.random() < 0.5 and -1 or 1
			end
		end
		if self.plan == "parry" and not blocking then
			-- a reader puts the blade's arrival in the middle of the parry window (a learned
			-- arrival, or a guess from the swing's length); an early guard goes up before
			-- the windup ends (a late feint baits it); one who can't read raises it on sight
			local at
			if not sk.read then
				at = f.windupStart + sk.react + math.abs(self.jit)
			elseif self.early then
				at = f.windupEnd - 0.1 + self.jit
			else
				local arrive = self.learned[self.trackKey] or 0.45 * math.max(f.releaseEnd - f.windupEnd, 0.1)
				at = f.windupEnd + arrive - 0.2 + self.jit
			end
			at = math.max(at, f.windupStart + sk.react)
			if now >= at and now >= (self.fooledUntil or 0) and (me.phase ~= "windup" or staminaOf(model) >= FEINT_COST) then
				ctrl.blockStart()
				if model:GetAttribute("Blocking") then self.guardAt, self.guardFor, self.sawRelease = now, f.windupStart, false end
			end
		elseif self.plan == "chamber" and me.phase == "idle" and not blocking then
			if now >= f.windupEnd - 0.08 + self.jit * 0.5 then
				local m = mirrorOf(self, f.name, f.kind)
				if m and staminaOf(model) >= costOf(self, m) then ctrl.attack(m) end
				self.plan = "none"
			end
		end
	end

	-- the guard comes down once the swing it went up for is over (a combo's next swing keeps it up)
	if blocking then
		self.guardAt = self.guardAt or now
		if self.guardFor == f.windupStart and f.phase == "release" then self.sawRelease = true end
		-- a feint: the swing it raised its guard for never came (they went idle, or into a
		-- new windup). Taken in, it drops its guard like a startled player would, and the
		-- real swing finds it inside the re-guard cooldown
		if self.guardFor and not self.sawRelease and (f.phase == "idle" or f.windupStart ~= self.guardFor) then
			self.guardFor = nil
			if math.random() < (sk.fooled or 0) then
				ctrl.blockStop()
				self.guardAt = nil
				self.fooledUntil = now + 0.3 + math.random() * 0.35
				return
			end
		end
		if (not live_ and now - self.guardAt > 0.15) or now - self.guardAt > 1.2 then
			ctrl.blockStop()
			self.guardAt = nil
		end
	else
		self.guardAt = nil
	end

	-- our own swing: the foe raised a guard early → feint it (and swing again
	-- through their re-guard cooldown) or morph past it
	if me.phase == "windup" and self.trickFor == me.windupStart and foe:GetAttribute("Blocking") then
		local span = math.max(0.05, me.windupEnd - me.windupStart)
		local t = (now - me.windupStart) / span
		if t > 0.3 and t < 0.85 then
			local kind = self.trickKind
			self.trickFor = nil
			if kind == "feint" and staminaOf(model) >= FEINT_COST + sk.reserve * 0.4 then
				ctrl.feint()
				task.delay(0.27 + math.random() * 0.1, function()
					if self.alive and self.ctrl == ctrl then
						local n = pickAttack(self)
						if n then ctrl.attack(n) end
					end
				end)
			elseif kind == "morph" and staminaOf(model) >= MORPH_COST + sk.reserve * 0.4 then
				local n = pickAttack(self, me.name)
				if n then ctrl.attack(n) end
			end
		end
	end
	-- a swing of ours landed: chain the next one (a combo has no windup)
	if me.phase == "release" and me.landed and self.comboFor == me.windupStart then
		self.comboFor = nil
		local n = pickAttack(self, me.name)
		if n and staminaOf(model) >= costOf(self, n) + sk.reserve * 0.4 then ctrl.attack(n) end
	end
end

-- feet that find a way round: a tree, a wagon or a wall across its path turns
-- it aside, to whichever side is open, and it keeps to that side a moment so it
-- doesn't dither; boxed in, it backs out. Characters don't count (that's the fight).
-- Rising ground (a hill, a ramp) is no wall: it walks up it. Something low (a
-- rock, a log, a low wall) it hops over
local STEER_ANGLES = {35, 70, 105}
local BOT_JUMP = 32          -- its hop: ≈ 2.6 studs (a player's is a little lower)
local HOP_CLEAR = 2.3        -- the tallest thing it tries to hop
local FEET = 3               -- root to soles (R6)
local steerParams = RaycastParams.new()
steerParams.FilterType = Enum.RaycastFilterType.Exclude
steerParams.RespectCanCollide = true
local function walkable(inst) return inst:IsA("Terrain") or inst:IsA("WedgePart") or inst:IsA("CornerWedgePart") end
-- what's ahead along d: nil when the way's open, else the hit and how high its top stands over the feet
local function ahead(origin, d, feet)
	local hit = workspace:Spherecast(origin, 1.1, d * 4.5, steerParams)
	if not hit then return nil end
	if hit.Normal.Y > 0.6 and walkable(hit.Instance) then return nil end      -- a slope: up it goes
	-- in the way at head height too: a wall, a tree, a crate stack — no hopping that
	if workspace:Spherecast(origin + Vector3.new(0, 2.6, 0), 1.1, d * 4.5, steerParams) then return hit, 99 end
	-- something low: how high its top stands
	local over = Vector3.new(hit.Position.X, feet + 3.6, hit.Position.Z) + d * 0.6
	local top = workspace:Raycast(over, Vector3.new(0, -5, 0), steerParams)
	local rise = top and (top.Position.Y - feet) or 0
	if rise <= 1 then return nil end                                          -- a lip it steps over
	return hit, rise
end
function Bot:hop(now)
	if now < (self.hopAt or 0) or self.hum.FloorMaterial == Enum.Material.Air then return end
	self.hopAt = now + 1
	self.hum.JumpPower = BOT_JUMP
	self.hum.Jump = true
end
function Bot:steer(want, now)
	local flat = Vector3.new(want.X, 0, want.Z)
	if flat.Magnitude < 0.05 then return want end
	local mag, w = math.min(flat.Magnitude, 1), flat.Unit
	local ignore = {self.model}
	if folder then table.insert(ignore, folder) end
	for _, p in ipairs(Players:GetPlayers()) do if p.Character then table.insert(ignore, p.Character) end end
	steerParams.FilterDescendantsInstances = ignore
	local origin = self.hrp.Position - Vector3.new(0, 1.2, 0)   -- knee height: crates and logs count too
	local feet = self.hrp.Position.Y - FEET
	local function open(d) return ahead(origin, d, feet) == nil end
	local hit, rise = ahead(origin, w, feet)
	if not hit then return want end
	if rise <= HOP_CLEAR then self:hop(now); return want end
	local first = (self.steerUntil and now < self.steerUntil) and self.steerSide or (math.random() < 0.5 and 1 or -1)
	for _, a in ipairs(STEER_ANGLES) do
		for _, sgn in ipairs({first, -first}) do
			local d = CFrame.Angles(0, math.rad(a * sgn), 0):VectorToWorldSpace(w)
			if open(d) then
				self.steerSide, self.steerUntil = sgn, now + 0.8
				return d * mag
			end
		end
	end
	return -w * 0.6
end

-- THE LONG WAY ROUND: to somewhere far (an objective, a foe across the map) it
-- follows a path (PathfindingService), worked out in the background and walked
-- point by point, and worked out again when the place moves or every few
-- seconds. Nil while there's none yet (then it just steers).
local pathParams = RaycastParams.new()
pathParams.FilterType = Enum.RaycastFilterType.Exclude
pathParams.FilterDescendantsInstances = {folder}
pathParams.RespectCanCollide = true
function Bot:pathDir(dest, now)
	local P = self.path
	if (not P or (P.dest - dest).Magnitude > 10 or now - P.at > 4) and not self.pathing then
		self.pathing = true
		local from = self.hrp.Position
		task.spawn(function()
			-- (1.5: an R6 body fits between a hay bale and a barn wall)
			local path = PathfindingService:CreatePath({AgentRadius = 1.5, AgentHeight = 5, AgentCanJump = false, WaypointSpacing = 6})
			local points
			-- the place itself may be inside something (a hill's middle under a windmill):
			-- then open ground beside it, on the near side first
			local back = Vector3.new(from.X - dest.X, 0, from.Z - dest.Z)
			back = back.Magnitude > 0.1 and back.Unit or Vector3.new(1, 0, 0)
			for _, off in ipairs({false, 0, 60, -60}) do
				local to = dest
				if off then
					local d = CFrame.Angles(0, math.rad(off), 0):VectorToWorldSpace(back) * 10
					local ground = workspace:Raycast(dest + d + Vector3.new(0, 30, 0), Vector3.new(0, -60, 0), pathParams)
					to = ground and ground.Position + Vector3.new(0, 1, 0) or dest + d
				end
				local ok = pcall(path.ComputeAsync, path, from, to)
				if ok and path.Status == Enum.PathStatus.Success then points = path:GetWaypoints(); break end
			end
			self.path = {dest = dest, at = os.clock(), points = points, i = 2}
			self.pathing = false
		end)
	end
	P = self.path
	if not (P and P.points) then return nil end
	while P.i <= #P.points do
		local to = P.points[P.i].Position - self.hrp.Position
		to = Vector3.new(to.X, 0, to.Z)
		if to.Magnitude > 2.5 then return to.Unit end
		P.i += 1
	end
	return nil
end

-- STUCK: told to walk but it's hardly moved for a second (snagged on a corner, a
-- prop the steering missed). First it hops; still stuck, it steps off to one side
-- for a moment and works out a fresh path, and keeps to paths a while even for a
-- foe close by
function Bot:unstick(want, now)
	local p = self.hrp.Position
	if want.Magnitude < 0.3 then self.stuckAt, self.stuckN = nil, 0; return want end
	if not self.stuckAt or (p - self.stuckFrom).Magnitude > 1.5 then
		self.stuckAt, self.stuckFrom, self.stuckN = now, p, 0
	elseif now - self.stuckAt > 0.9 then
		self.stuckAt, self.stuckN = now, (self.stuckN or 0) + 1
		if self.stuckN == 1 then
			self:hop(now)
		else
			local flat = Vector3.new(want.X, 0, want.Z)
			flat = flat.Magnitude > 0.05 and flat.Unit or Vector3.new(0, 0, -1)
			local side = math.random() < 0.5 and 1 or -1
			self.detour = (Vector3.new(-flat.Z, 0, flat.X) * side - flat * 0.4).Unit
			self.detourUntil = now + 0.7 + math.random() * 0.5
			self.path, self.pathUntil = nil, now + 5
			self:hop(now)
		end
	end
	if self.detourUntil and now < self.detourUntil then return self.detour end
	return want
end

-- THE BRAIN, ten times a second: where to stand, when to swing
function Bot:think()
	local hum, hrp, sk, model = self.hum, self.hrp, self.skill, self.model
	if not self.alive or hum.Health <= 0 or model:GetAttribute("Ragdolled") then hum:Move(Vector3.zero); return end
	local target = self.target
	local foeDist = 0
	if not (target and target.Parent) then
		if self.fightBots then target, foeDist = nearestFoe(self, hrp.Position, model:GetAttribute("Team"))
		else target = nearestPlayer(hrp.Position, model:GetAttribute("Team")) end
	end
	local thrp = target and target:FindFirstChild("HumanoidRootPart")
	local thum = target and target:FindFirstChildOfClass("Humanoid")
	-- nobody near enough to bother with: head for the objective, if there is one
	local goal = self.goal and (not thrp or (foeDist or 0) > 38) and self.goal()
	if goal and os.clock() >= self.startAt then
		local to = goal - hrp.Position
		to = Vector3.new(to.X, 0, to.Z)
		self.facing, self.foe, self.lookAt = nil, nil, to
		if to.Magnitude > 4 then
			local w = self:unstick(self:steer(self:pathDir(goal, os.clock()) or to.Unit, os.clock()), os.clock())
			hum.WalkSpeed = self:speedFor(w, true, false)
			hum:Move(w)
		else
			hum:Move(Vector3.zero)
		end
		return
	end
	if not (thrp and thum and thum.Health > 0) then hum:Move(Vector3.zero); self.facing, self.foe = nil, nil; return end
	self.facing, self.foe = thrp, target
	if self.invulnerable then hum.Health = hum.MaxHealth end
	local now = os.clock()
	if now < self.startAt then hum:Move(Vector3.zero); return end

	-- its weapon: the one in its hand, or none (knocked away)
	local held = model:FindFirstChildOfClass("Tool")
	if held ~= self.tool and not self.arming then
		if held then task.spawn(self.adopt, self, held) else self.tool, self.ctrl = nil, nil end
	end
	local ctrl = self.ctrl

	-- the guard dummy: guard up, always (a kick knocks it down for a moment)
	if sk.guard then
		hum:Move(Vector3.zero)
		if ctrl and not model:GetAttribute("Blocking") and ctrl.snapshot().phase == "idle" then ctrl.blockStart() end
		return
	end

	if ctrl and (ctrl.ranged or ctrl.magic) then return self:thinkCaster(target, thrp, now) end

	local to = thrp.Position - hrp.Position
	local flat = Vector3.new(to.X, 0, to.Z)
	local dist = flat.Magnitude
	self.dist = dist
	local dir = dist > 0.01 and flat.Unit or Vector3.new(0, 0, -1)
	local me = ctrl and ctrl.snapshot() or IDLE
	-- an archer with its sidearm out: back to the bow once there's room
	if self.bowTool and self.tool ~= self.bowTool and self.bowTool.Parent and dist > 15 and me.phase == "idle" and not self.arming then
		self:swapTo(self.bowTool)
		return
	end
	local busy = me.phase ~= "idle"
	local blocking = model:GetAttribute("Blocking") == true
	local fc = controllerOf(target)
	local f = fc and fc.snapshot() or IDLE
	local st = staminaOf(model)
	local foeReach = reachOf(target)
	self.lookAt = nil

	-- stamina: under its reserve it backs off and gets its wind back
	if sk.reserve > 0 then
		if st < sk.reserve * 0.7 then self.recovering = true elseif st > sk.reserve + 25 then self.recovering = false end
	end
	local foeOpen = f.phase == "recovery" or f.phase == "kick"
	local foeWeak = staminaOf(target) < 22 or (target:GetAttribute("StunnedUntil") or 0) > now
	local threat = (f.phase == "windup" or f.phase == "release") and dist < foeReach + 3
	if target:GetAttribute("Blocking") then self.foeGuardAt = self.foeGuardAt or now else self.foeGuardAt = nil end

	-- footwork. A weapon's REACH is the furthest a hit may be from the root (the
	-- server's check); the blade's arc itself lands nearer: about 0.72 of it
	local want
	local hitDist = math.clamp(self.reach * 0.72, 2.2, 8)          -- where the blade lands
	local strike = hitDist + 1.0                                   -- where it starts a swing (it steps in during the windup)
	local hold = math.max(hitDist, foeReach * 0.72) + 2            -- just out of reach while it waits
	if self.recovering and not foeOpen then hold += 3 end
	local soon = (now >= self.nextAttack - 0.4 and not self.recovering) or foeOpen or foeWeak
	if now >= (self.moodUntil or 0) or (soon and self.mood ~= "press") then self:pickMood(soon) end
	local side = Vector3.new(-dir.Z, 0, dir.X)
	-- not its turn: someone nearer is fighting this foe (unless the foe's wide open)
	local waiting = ctrl ~= nil and slotOf(self) > ((self.temper and self.temper.engage) or 2) and not foeOpen
	self.waiting = waiting
	if not ctrl then
		-- nothing in hand: go and get something (or draw the spare), else keep away
		want = self:rearm(now) or -dir
	elseif self.stepUntil and now >= self.stepAt and now < self.stepUntil then
		want = -dir * 0.75 + side * self.stepSide * 0.65         -- a step back and aside from their swing
	elseif me.phase == "windup" or me.phase == "release" then
		want = dist > hitDist and dir or Vector3.zero            -- step into our swing
	elseif me.phase == "recovery" then
		want = -dir * 0.4
	elseif waiting then
		-- keep the ring, circling; a flanker works its way round behind them
		if now > self.strafeUntil then
			self.strafe = math.random() < 0.5 and -1 or 1
			self.strafeUntil = now + 1.2 + math.random() * 2
		end
		local around = side * self.strafe
		if self.temper and self.temper.flank then
			local lk = thrp.CFrame.LookVector
			local back = Vector3.new(-lk.X, 0, -lk.Z)
			if back.Magnitude > 0.1 then
				local to = thrp.Position + back.Unit * self.ring - hrp.Position
				to = Vector3.new(to.X, 0, to.Z)
				if to.Magnitude > 3 then around = to.Unit end
			end
		end
		want = around * 0.55 + dir * math.clamp((dist - self.ring) / 4, -1, 1)
	else
		local mood = self.mood or "circle"
		local goal = mood == "press" and strike or (mood == "back" and hold + 3) or hold
		if now > self.strafeUntil then
			self.strafe = math.random() < 0.5 and -1 or 1
			self.strafeUntil = now + 0.6 + math.random() * 1.4
		end
		if mood == "wait" then
			-- stands and watches, shifting its feet; only someone walking right up moves it
			want = dist < hitDist - 0.5 and -dir * 0.6 or side * self.strafe * 0.25
		elseif dist > goal + 1.5 then
			want = dir
		elseif dist < goal - 1.5 then
			want = -dir * 0.8
		else
			-- circle at that distance, changing direction now and then
			want = side * self.strafe * (mood == "press" and 0.5 or 1) + dir * math.clamp(dist - goal, -1, 1) * 0.5
		end
	end
	if self.arena then
		local off = hrp.Position - self.arena.centre
		off = Vector3.new(off.X, 0, off.Z)
		if off.Magnitude > self.arena.radius - 2.5 then want = -off.Unit end
	end
	-- a foe far off (across the map, round a wall), or it's been stuck: the path there
	if (dist > 22 or now < (self.pathUntil or 0)) and dist > hitDist + 3 and not self.arena and not waiting then
		local pd = self:pathDir(thrp.Position, now)
		if pd then want = pd end
	end
	if want.Magnitude > 0.3 and dist > hitDist + 3 then want = self:unstick(self:steer(want, now), now)
	else self.stuckAt = nil end
	if (sk.pace or 0) <= 0 then want = Vector3.zero end
	-- a body carries its momentum: it eases from one heading into the next
	local w = want.Magnitude > 1 and want.Unit or want
	self.mv = self.mv and self.mv:Lerp(w, 0.4) or w
	local mag = math.min(self.mv.Magnitude, 1)
	local mv = mag > 0.05 and self.mv.Unit or Vector3.zero
	-- it doesn't break into a run the moment you step away: a beat of walking,
	-- then a burst of sprint, a breather, another burst — and not when winded
	local far = dist > math.max(self.reach, foeReach) + 6 and not (waiting and dist < self.ring + 8)
	if far then
		self.farSince = self.farSince or now
		local t = now - self.farSince - (self.chaseBeat or 0.9)
		far = t > 0 and (t % 4) < 2.6 and st > 30
	else
		self.farSince = nil
		self.chaseBeat = 0.6 + math.random() * 0.8
	end
	hum.WalkSpeed = self:speedFor(mv, far or self.lookAt ~= nil, busy or blocking) * math.max(mag, 0.35)
	hum:Move(mv)

	-- offence
	if not ctrl or busy or blocking or self.arming then return end
	if threat and self.plan ~= "none" then return end            -- that swing is being met (or dodged)
	if waiting and dist > hitDist then return end                 -- not its turn
	-- a guard held up too long: kick it
	if self.foeGuardAt and now - self.foeGuardAt > 0.45 and dist <= 6.5 and now >= (self.nextKick or 0) then
		self.nextKick = now + 1.5
		if math.random() < sk.kick and st >= 10 + sk.reserve * 0.3 then ctrl.kick(); return end
	end
	if dist > strike then return end
	local punish = foeOpen and self.punished ~= f.windupStart
	if punish then
		self.punished = f.windupStart
		punish = math.random() < sk.punish
	end
	if not (punish or (foeWeak and now >= self.nextAttack - 0.5) or now >= self.nextAttack) then return end
	if friendInTheWay(self, dir, dist, self.reach + 1) then
		-- a friend in the way: step round them for a better angle instead
		if now > self.strafeUntil then self.strafe, self.strafeUntil = -self.strafe, now + 0.8 end
		return
	end
	local name = pickAttack(self)
	if not name then return end
	local need = costOf(self, name) + ((punish or foeWeak) and 0 or (self.recovering and 1e3 or sk.reserve * 0.5))
	if st < need then return end
	self.nextAttack = now + rand(sk.interval) * (foeWeak and 0.6 or 1)
	ctrl.attack(name)
	self:armTricks(st > 45 and sk.feint or 0, st > 30 and sk.morph or 0, sk.combo)
end

--------------------------------------------------------------------
--  AN ARCHER'S, A MAGE'S MIND
--------------------------------------------------------------------
local sightParams = RaycastParams.new()
sightParams.FilterType = Enum.RaycastFilterType.Exclude
local function clearShot(from, to, me, foe)
	local ignore = {me, foe}
	for _, n in ipairs({"MagicFX", "StuckArrows", "DroppedWeapons"}) do local f = workspace:FindFirstChild(n); if f then table.insert(ignore, f) end end
	sightParams.FilterDescendantsInstances = ignore
	return workspace:Raycast(from, to - from, sightParams) == nil
end
-- where to send it: the body (a Champion's, half the time, the head), led by how they're moving
function Bot:aimAt(target, speed, ground)
	local thrp = target:FindFirstChild("HumanoidRootPart")
	local head = target:FindFirstChild("Head")
	local rank = self.model:GetAttribute("BotSkill") or "Squire"
	local spot = ground and (thrp.Position - Vector3.new(0, 2.6, 0))
		or ((rank == "Champion" and head and math.random() < 0.5) and head.Position or (thrp.Position + Vector3.new(0, 0.5, 0)))
	local d = (spot - self.hrp.Position).Magnitude
	local t = (speed and speed > 0) and d / speed or 0.6
	local v = thrp.AssemblyLinearVelocity * Vector3.new(1, 0, 1)
	local err = (CASTER.aim[rank] or 2) * math.clamp(d / 40, 0.4, 1.6)
	local off = Vector3.new(math.random() - 0.5, (math.random() - 0.5) * 0.6, math.random() - 0.5) * 2 * err
	return spot + v * t * (self.skill.read and 1 or 0.6) + off
end
function Bot:thinkCaster(target, thrp, now)
	local hum, hrp, ctrl, model = self.hum, self.hrp, self.ctrl, self.model
	local st = ctrl.state()
	local to = thrp.Position - hrp.Position
	local flat = Vector3.new(to.X, 0, to.Z)
	local dist = flat.Magnitude
	self.dist = dist
	local dir = dist > 0.01 and flat.Unit or Vector3.new(0, 0, -1)
	local side = Vector3.new(-dir.Z, 0, dir.X)
	local rank = model:GetAttribute("BotSkill") or "Squire"
	-- too close for a bow: the sidearm, and it fights like anyone (back to the bow at range)
	if ctrl.ranged and dist < 8 and self.spareTool and self.spareTool.Parent and not st.drawing then
		self:swapTo(self.spareTool)
		return
	end
	-- footwork: keep its distance, circling; still while it meditates
	local near, far = ctrl.magic and 15 or 13, ctrl.magic and 34 or 42
	if now > self.strafeUntil then
		self.strafe = math.random() < 0.5 and -1 or 1
		self.strafeUntil = now + 1 + math.random() * 2
	end
	local busy = st.drawing or st.casting ~= nil
	local want
	if dist < near then want = -dir + side * self.strafe * 0.3
	elseif dist > far then want = dir
	else want = side * self.strafe * 0.6 + dir * math.clamp((dist - (near + far) / 2) / 10, -0.5, 0.5) end
	if self.arena then
		local off = hrp.Position - self.arena.centre
		off = Vector3.new(off.X, 0, off.Z)
		if off.Magnitude > self.arena.radius - 2.5 then want = -off.Unit end
	end
	if dist > far and (dist > 22 or now < (self.pathUntil or 0)) and not self.arena then
		local pd = self:pathDir(thrp.Position, now)
		if pd then want = pd end
	end
	if want.Magnitude > 0.3 then want = self:unstick(self:steer(want, now), now) end
	if self.meditating or (self.skill.pace or 0) <= 0 then want = Vector3.zero end
	local w = want.Magnitude > 1 and want.Unit or want
	self.mv = self.mv and self.mv:Lerp(w, 0.4) or w
	local mag = math.min(self.mv.Magnitude, 1)
	local mv = mag > 0.05 and self.mv.Unit or Vector3.zero
	hum.WalkSpeed = self:speedFor(mv, dist > far + 10, busy) * math.max(mag, 0.35) * (busy and 0.35 or 1)
	hum:Move(mv)
	if now < self.startAt then return end
	local head = model:FindFirstChild("Head")
	local foeHead = target:FindFirstChild("Head")
	if not (head and foeHead) then return end
	local seen = clearShot(head.Position, foeHead.Position, model, target)
	local gap = CASTER.gap[rank] or CASTER.gap.Squire

	if ctrl.ranged then
		local cfg = ctrl.cfg
		if ctrl.isBow then
			if st.drawing then
				if not seen then
					if now - (self.drawAt or now) > 2.5 then ctrl.npc("Cancel") end
				elseif now - (self.drawAt or now) >= (self.drawFor or cfg.DRAW_TIME) then
					local aim = self:aimAt(target, cfg.SPEED_MAX)
					ctrl.npc("Loose", (aim - head.Position).Unit, nil, aim)
					self.nextShot = now + rand(gap)
				end
			elseif seen and st.ready and st.ammo > 0 and now >= (self.nextShot or 0) and dist < 110 then
				ctrl.npc("Draw")
				self.drawAt = now
				-- (a good archer draws to the full; a green one lets fly early)
				self.drawFor = cfg.DRAW_TIME * (self.skill.read and (1 + math.random() * 0.2) or (0.7 + math.random() * 0.35))
			end
		else
			if not st.loaded and not st.reloading and st.ammo > 0 then ctrl.npc("Reload")
			elseif st.loaded and seen and now >= (self.nextShot or 0) and dist < 120 then
				local aim = self:aimAt(target, cfg.SPEED_MAX)
				ctrl.npc("Loose", (aim - head.Position).Unit, nil, aim)
				self.nextShot = now + rand(gap)
			end
		end
		return
	end

	-- A MAGE
	local hp = hum.Health / math.max(hum.MaxHealth, 1)
	local mana = st.mana or 0
	if self.meditating then
		if mana > 85 or dist < 20 or hp < 0.3 then ctrl.npc("Meditate", false); self.meditating = false end
		return
	end
	if st.casting then
		if st.charged then
			-- held, charged: let go once it has a shot (or it's held too long)
			self.chargedAt = self.chargedAt or now
			local sp = Spells[st.casting] or {}
			local aim
			if sp.kind == "heal" or sp.kind == "buff" or sp.target == "self" then aim = hrp.Position
			elseif sp.target == "ground" then aim = self:aimAt(target, nil, true)
			else aim = self:aimAt(target, sp.speed) end
			if seen or sp.target ~= "aim" or now - self.chargedAt > 1.4 then
				ctrl.npc("Release", aim)
				self.chargedAt = nil
			end
		end
		return
	end
	if mana < 25 and dist > 26 then ctrl.npc("Meditate", true); self.meditating = true; return end
	-- a staff's ward against a blow on its way in
	if st.ward then
		local fc = controllerOf(target)
		local f = fc and fc.snapshot() or IDLE
		local threat = (f.phase == "windup" or f.phase == "release") and dist < reachOf(target) + 3
		if threat and mana > 15 and not self.warding then ctrl.npc("Ward", true); self.warding = true
		elseif self.warding and not threat then ctrl.npc("Ward", false); self.warding = false end
		if self.warding then return end
	end
	if now < (self.nextCast or 0) then return end
	local can = st.ready
	local pick
	if hp < 0.5 and can.Mend then pick = "Mend"
	elseif dist < 10 and can.FrostNova then pick = "FrostNova"
	elseif seen and dist < 40 and can.ChainLightning and math.random() < 0.5 then pick = "ChainLightning"
	elseif seen and dist > 14 and dist < 60 and can.Meteor then pick = "Meteor"
	elseif seen then
		for _, id in ipairs({"Firebolt", "IceLance", "ArcaneMissiles", "ChainLightning"}) do if can[id] then pick = id; break end end
	end
	if pick then
		ctrl.npc("Cast", pick)
		self.nextCast = now + rand(gap)
		self.chargedAt = nil
	end
end

function Bots.spawn(opts)
	opts = opts or {}
	local skill = Bots.SKILLS[opts.skill or "Squire"] or Bots.SKILLS.Squire
	local name = opts.name or (skill.label .. " Bot")
	local model, hum, hrp = R6.rig(name)
	-- its name is drawn by NameTags (when you look right at it), not by Roblox
	hum.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None
	hum.HealthDisplayType = Enum.HumanoidHealthDisplayType.AlwaysOff
	model:SetAttribute("TagName", name)
	model:SetAttribute("BotSkill", opts.skill or "Squire")
	model:SetAttribute("Bot", true)
	model:PivotTo(opts.at or CFrame.new(0, 3, 0))
	model.Parent = folder
	local cls = opts.class and GameConfig.CLASSES[opts.class]
	local rank = opts.skill or "Squire"
	local weight = opts.weight or (cls and cls.weight) or skill.weight or "Medium"
	local lo = opts.loadout
	if not lo and cls and cls.magic then
		-- a Mage in robes for its rank
		local sets = CASTER.robes[rank] or CASTER.robes.Squire
		local set = sets[math.random(#sets)]
		lo = Bots.loadoutFor(weight, nil, rank)
		for _, slot in ipairs(Catalog.SLOTS) do
			local pc = Catalog.PIECE[set .. "_" .. SLOT_SUFFIX[slot]] or Catalog.defaultPiece(slot, weight)
			lo[slot] = pc and pc.id or nil
		end
	end
	pcall(Dresser.dress, model, {loadout = lo or Bots.loadoutFor(weight, nil, rank), appearance = opts.appearance or Catalog.BODY.defaults, weight = weight, team = opts.team})
	if cls then
		model:SetAttribute("Class", opts.class)
		if cls.health then hum.MaxHealth = math.max(10, hum.MaxHealth + cls.health); hum.Health = hum.MaxHealth end
		if cls.magic then model:SetAttribute("MaxMana", Spells.MAX_MANA); model:SetAttribute("Mana", Spells.MAX_MANA) end
		if not opts.weapon then opts.weapon = cls.magic and "Staff" or (math.random() < 0.25 and "Crossbow" or "Bow") end
		if cls.ranged and opts.spare == nil then opts.spare = "Shortsword" end
	end
	hum.AutoRotate = false
	-- it turns to face its opponent through a soft constraint (no teleporting the root),
	-- no faster than a player can (the heartbeat below steps the goal)
	local att = Instance.new("Attachment"); att.Name = "FaceAttachment"; att.Parent = hrp
	local align = Instance.new("AlignOrientation")
	align.Mode = Enum.OrientationAlignmentMode.OneAttachment
	align.Attachment0 = att
	align.MaxTorque = 1e7
	align.Responsiveness = 40
	align.Parent = hrp
	hum.WalkSpeed = MC.BASE_SPEED
	hum.UseJumpPower = true
	hum.JumpPower = BOT_JUMP   -- (it only jumps when its feet decide to: Bot:hop)
	pcall(function() hrp:SetNetworkOwner(nil) end)
	if opts.team then model:SetAttribute("Team", opts.team) end

	local startAt = os.clock() + (opts.startDelay or 0)
	local bot = setmetatable({model = model, hum = hum, hrp = hrp, skill = skill, target = opts.target, arena = opts.arena,
		fightBots = opts.fightBots == true, goal = opts.goal,
		alive = true, conns = {}, nextAttack = startAt + 1.2, strafe = 1, strafeUntil = 0, learned = {},
		startAt = startAt, invulnerable = opts.invulnerable == true, attacks = {}, reach = 5, cfg = {}}, Bot)
	bot.temper = Bots.TEMPERS[opts.temper] or Bots.TEMPERS[TEMPER_NAMES[math.random(#TEMPER_NAMES)]]
	bot.ring = 10 + math.random() * 5          -- how far out it waits its turn
	if opts.invulnerable then hum.MaxHealth = 5000; hum.Health = 5000 end
	-- a secondary on its belt for when it's disarmed
	if opts.spare ~= false and not skill.dummy then
		local spare = type(opts.spare) == "string" and opts.spare
			or (math.random() < (skill.spare or 0) and SPARES[math.random(#SPARES)] or nil)
		if spare and spare ~= opts.weapon and findWeapon(spare) then bot.spare = spare end
	end
	live[bot] = true

	local tool = findWeapon(opts.weapon)
	if tool then
		tool = tool:Clone()
		if opts.skin then pcall(Dresser.applySkin, tool, opts.skin) end
		-- a Mage's arsenal, by rank
		if cls and cls.magic then tool:SetAttribute("Spells", CASTER.book[rank] or CASTER.book.Squire) end
		bot:adopt(tool)
		-- an archer's sidearm waits in its stash (drawn when you close in)
		if cls and cls.ranged and bot.spare then
			local side = findWeapon(bot.spare)
			if side then
				bot.spareTool = side:Clone()
				stashTool(model, bot.spareTool)
				bot.bowTool = tool
			end
		end
	end
	bot.parryTick = model:GetAttribute("ParryTick") or 0

	-- face the opponent (or the weapon it's going for) every frame, yaw only, at a
	-- player's turn rate; then the reflexes
	local lastWarn = 0
	table.insert(bot.conns, RunService.Heartbeat:Connect(function(dt)
		local f = bot.facing
		local down = not bot.alive or hum.Health <= 0 or model:GetAttribute("Ragdolled") == true
		local look = bot.lookAt or (f and f.Parent and Vector3.new(f.Position.X - hrp.Position.X, 0, f.Position.Z - hrp.Position.Z)) or nil
		align.Enabled = not down and look ~= nil
		if not align.Enabled then bot.yaw = nil; return end
		if look.Magnitude > 0.5 then
			local goal = math.atan2(-look.X, -look.Z)
			local cur = bot.yaw or goal
			local diff = (goal - cur + math.pi) % (2 * math.pi) - math.pi
			local capped = os.clock() < (model:GetAttribute("TurnCapUntil") or 0)
			local step = math.rad(capped and TURN_CAP_DPS or TURN_DPS) * dt
			bot.yaw = cur + math.clamp(diff, -step, step)
			align.CFrame = CFrame.Angles(0, bot.yaw, 0)
		end
		local ok, err = pcall(bot.reflex, bot)
		if not ok and os.clock() - lastWarn > 2 then lastWarn = os.clock(); warn("[Bots] reflex:", err) end
	end))
	task.spawn(function()
		while bot.alive and model.Parent do
			local ok, err = pcall(bot.think, bot)
			if not ok then warn("[Bots]", err) end
			task.wait(0.1)
		end
	end)
	hum.Died:Once(function()
		bot.alive = false
		-- (the killer's kill effect comes from Scoreboard, which watches workspace.NPCs)
		local killer = Players:GetPlayerByUserId(model:GetAttribute("LastHitBy") or 0)
		if opts.onDeath then task.spawn(opts.onDeath, bot, killer) end
		-- (the corpse is a copy, laid out by Corpses: the bot itself goes once that's done)
		task.delay(math.max(opts.corpseTime or 6, Corpses.CONFIG.HOLD), function() bot:destroy() end)
	end)
	return bot
end

function Bots.list()
	local out = {}
	for b in pairs(live) do table.insert(out, b) end
	return out
end

return Bots
