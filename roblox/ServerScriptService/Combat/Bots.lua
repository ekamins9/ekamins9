--[[ BOTS — AI fighters on the real combat system: a bot carries an ordinary
     weapon Tool, whose combat controller runs in NPC mode (server-side swings
     and blade sweeps, like the test dummies), so a bot's swing can be blocked,
     parried, chambered and dodged like a player's. Used by the training yard's
     sparring ring (and anything else that wants an opponent).

       Bots.spawn(opts) -> bot
           opts.at        CFrame where it appears
           opts.weapon    Tool name in ServerStorage ▸ Weapons (default Longsword)
           opts.skill     "Squire" | "Knight" | "Champion" (Bots.SKILLS)
           opts.name      shown over its head
           opts.loadout / appearance / weight / team   its look (Dresser)
           opts.target    the character to fight (default: the nearest player)
           opts.arena     {centre = Vector3, radius = n}: it keeps inside
           opts.onDeath   fn(bot, killerPlayer)
           opts.startDelay  seconds before it moves or strikes (a countdown)
           opts.invulnerable  never dies (a drill dummy)
       bot:destroy()      bot.model  bot.hum  bot.alive
       Bots.SKILLS

     Its brain thinks ten times a second: close in, circle at sword's length,
     strike (swings, stabs, overheads; feints and morphs when skilled), raise
     the guard against your windup (late enough to parry, when skilled), kick
     a turtle. Movement is server-side; clients animate its legs (NpcAnimator). ]]

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ServerStorage = game:GetService("ServerStorage")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CombatServer = require(script.Parent:WaitForChild("CombatServer"))
local Dresser = require(ReplicatedStorage:WaitForChild("Dresser"))
local Catalog = require(ReplicatedStorage:WaitForChild("Catalog"))

local Bots = {}
Bots.SKILLS = {
	-- reaction: seconds from your windup to its guard · parry: chance it tries · interval: seconds between its attacks
	Squire   = {reaction = 0.55, parry = 0.25, interval = {1.7, 2.7}, feint = 0.0,  morph = 0.0,  kick = 0.10, speed = 12, label = "Squire", weight = "Light"},
	Knight   = {reaction = 0.36, parry = 0.55, interval = {1.1, 1.9}, feint = 0.15, morph = 0.10, kick = 0.30, speed = 14, label = "Knight", weight = "Medium"},
	Champion = {reaction = 0.24, parry = 0.82, interval = {0.75, 1.35}, feint = 0.30, morph = 0.25, kick = 0.45, speed = 15, label = "Champion", weight = "Heavy"},
	-- the training yard's drill dummies: one throws slow, readable swings and
	-- overheads from where it stands; the other only ever holds its guard
	Drill    = {reaction = 9, parry = 0, interval = {2.3, 3.0}, feint = 0, morph = 0, kick = 0, speed = 0, label = "Drill Dummy", weight = "Light", kinds = {"Swing", "Overhead"}},
	Guard    = {reaction = 9, parry = 0, interval = {99, 99}, feint = 0, morph = 0, kick = 0, speed = 0, label = "Guard Dummy", weight = "Heavy", guard = true},
}

-- the free starter pieces of a weight, in a bot's colours
function Bots.loadoutFor(weight, colors)
	local lo = {colors = colors or {Primary = "Crimson", Secondary = "Slate", Accent = "Ochre", Metal = "Ash"}}
	for _, slot in ipairs(Catalog.SLOTS) do
		local p = Catalog.defaultPiece(slot, weight)
		lo[slot] = p and p.id or nil
	end
	return lo
end

local folder = workspace:FindFirstChild("NPCs")
if not folder then folder = Instance.new("Folder"); folder.Name = "NPCs"; folder.Parent = workspace end

local live = {}

local R6 = require(script.Parent:WaitForChild("R6"))

local function findWeapon(name)
	local f = ServerStorage:FindFirstChild("Weapons")
	local t = f and f:FindFirstChild(name or "Longsword")
	return t and t:IsA("Tool") and t or nil
end

local function attacksOf(tool)
	local out, cfg = {}, nil
	local mod = tool:FindFirstChild("Config")
	if mod then local ok, c = pcall(require, mod); if ok then cfg = c end end
	for n, a in pairs(cfg and cfg.ATTACKS or {}) do
		if type(a.anim) == "string" and a.anim ~= "" and a.anim ~= "rbxassetid://0" then table.insert(out, n) end
	end
	table.sort(out)
	return out, (cfg and cfg.REACH) or 6
end

--------------------------------------------------------------------
--  THE BRAIN
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
local function rand(r) return r[1] + math.random() * (r[2] - r[1]) end

-- a mix: mostly swings, some stabs and overheads (whatever the weapon has)
local function pickAttack(bot)
	local roll = math.random()
	local kind = roll < 0.5 and "Swing" or (roll < 0.75 and "Stab" or (roll < 0.95 and "Overhead" or "Underhand"))
	if bot.skill.kinds then kind = bot.skill.kinds[math.random(#bot.skill.kinds)] end
	local side = math.random() < 0.5 and "Left" or "Right"
	local want = side .. kind
	for _, n in ipairs(bot.attacks) do if n == want then return n end end
	for _, n in ipairs(bot.attacks) do if n:find(kind, 1, true) then return n end end
	return bot.attacks[math.random(#bot.attacks)]
end

local Bot = {}
Bot.__index = Bot

function Bot:destroy()
	self.alive = false
	for _, c in ipairs(self.conns) do c:Disconnect() end
	live[self] = nil
	if self.model.Parent then self.model:Destroy() end
end

function Bot:think()
	local hum, hrp, ctrl, sk = self.hum, self.hrp, self.ctrl, self.skill
	if not self.alive or hum.Health <= 0 or self.model:GetAttribute("Ragdolled") then hum:Move(Vector3.zero); return end
	local target = self.target
	if not (target and target.Parent) then target = nearestPlayer(hrp.Position, self.model:GetAttribute("Team")) end
	local thrp = target and target:FindFirstChild("HumanoidRootPart")
	local thum = target and target:FindFirstChildOfClass("Humanoid")
	if not (thrp and thum and thum.Health > 0) then hum:Move(Vector3.zero); self.facing = nil; return end
	self.facing = thrp
	if self.invulnerable then hum.Health = hum.MaxHealth end
	if os.clock() < self.startAt then hum:Move(Vector3.zero); return end
	-- the guard dummy: guard up, always (a kick knocks it down for a moment)
	if sk.guard then
		hum:Move(Vector3.zero)
		if ctrl and not self.model:GetAttribute("Blocking") and (ctrl.snapshot().phase == "idle") then ctrl.blockStart() end
		return
	end
	local to = thrp.Position - hrp.Position
	local flat = Vector3.new(to.X, 0, to.Z)
	local dist = flat.Magnitude
	local dir = dist > 0.01 and flat.Unit or Vector3.new(0, 0, -1)
	local now = os.clock()
	local snap = ctrl and ctrl.snapshot() or {phase = "idle"}
	local busy = snap.phase ~= "idle"

	-- footwork: close in, keep sword's length, circle
	local want
	if dist > self.reach + 1.5 then
		want = dir
	elseif dist < self.reach * 0.55 then
		want = -dir
	else
		if now > self.strafeUntil then
			self.strafe = math.random() < 0.5 and -1 or 1
			self.strafeUntil = now + 0.7 + math.random() * 1.5
		end
		want = Vector3.new(-dir.Z, 0, dir.X) * self.strafe * 0.85 + dir * (math.random() - 0.45) * 0.5
	end
	-- a swing steps in to land; recovery gives a little ground back
	if snap.phase == "windup" or snap.phase == "release" then
		want = dist > self.reach * 0.6 and dir or Vector3.zero
	elseif snap.phase == "recovery" then
		want = -dir * 0.6
	end
	if self.arena then
		local off = hrp.Position - self.arena.centre
		off = Vector3.new(off.X, 0, off.Z)
		if off.Magnitude > self.arena.radius - 2.5 then want = -off.Unit end
	end
	if sk.speed <= 0 then want = Vector3.zero end
	hum.WalkSpeed = busy and sk.speed * 0.55 or sk.speed
	hum:Move(want.Magnitude > 0.01 and want.Unit or Vector3.zero)

	-- defence: your windup is its cue
	local winding = target:GetAttribute("SpeedMult_Swing") ~= nil
	if winding and not self.sawWindup then
		self.sawWindup = true
		if not busy and dist < self.reach + 3 and math.random() < sk.parry and ctrl then
			task.delay(sk.reaction * (0.85 + math.random() * 0.3), function()
				if not self.alive or (ctrl.snapshot().phase ~= "idle") then return end
				ctrl.blockStart()
				task.delay(0.5 + math.random() * 0.2, function() if self.alive then ctrl.blockStop() end end)
			end)
		end
	elseif not winding then
		self.sawWindup = false
	end

	-- offence
	if ctrl and not busy and not self.model:GetAttribute("Blocking") and dist <= self.reach + 0.8 and now >= self.nextAttack then
		self.nextAttack = now + rand(sk.interval)
		if target:GetAttribute("Blocking") and math.random() < sk.kick then
			ctrl.kick()
		else
			ctrl.attack(pickAttack(self))
			local r = math.random()
			if r < sk.feint then
				task.delay(0.1 + math.random() * 0.1, function()
					if not self.alive then return end
					ctrl.feint()
					task.delay(0.12 + math.random() * 0.15, function() if self.alive then ctrl.attack(pickAttack(self)) end end)
				end)
			elseif r < sk.feint + sk.morph then
				task.delay(0.08 + math.random() * 0.08, function() if self.alive then ctrl.attack(pickAttack(self)) end end)
			end
		end
	end
end

function Bots.spawn(opts)
	opts = opts or {}
	local skill = Bots.SKILLS[opts.skill or "Squire"] or Bots.SKILLS.Squire
	local name = opts.name or (skill.label .. " Bot")
	local model, hum, hrp = R6.rig(name)
	model:SetAttribute("Bot", true)
	model:SetAttribute("BotSkill", opts.skill or "Squire")
	model:PivotTo(opts.at or CFrame.new(0, 3, 0))
	model.Parent = folder
	local weight = opts.weight or skill.weight or "Medium"
	pcall(Dresser.dress, model, {loadout = opts.loadout or Bots.loadoutFor(weight), appearance = opts.appearance or Catalog.BODY.defaults, weight = weight, team = opts.team})
	hum.AutoRotate = false
	-- it turns to face its opponent through a soft constraint (no teleporting the root)
	local att = Instance.new("Attachment"); att.Name = "FaceAttachment"; att.Parent = hrp
	local align = Instance.new("AlignOrientation")
	align.Mode = Enum.OrientationAlignmentMode.OneAttachment
	align.Attachment0 = att
	align.MaxTorque = 1e7
	align.Responsiveness = 40
	align.Parent = hrp
	hum.WalkSpeed = skill.speed
	hum.JumpPower = 0
	pcall(function() hrp:SetNetworkOwner(nil) end)
	if opts.team then model:SetAttribute("Team", opts.team) end

	local startAt = os.clock() + (opts.startDelay or 0)
	local bot = setmetatable({model = model, hum = hum, hrp = hrp, skill = skill, target = opts.target, arena = opts.arena,
		alive = true, conns = {}, nextAttack = startAt + 1.2, strafe = 1, strafeUntil = 0, sawWindup = false,
		startAt = startAt, invulnerable = opts.invulnerable == true}, Bot)
	if opts.invulnerable then hum.MaxHealth = 5000; hum.Health = 5000 end
	live[bot] = true

	local tool = findWeapon(opts.weapon)
	if tool then
		tool = tool:Clone()
		if opts.skin then pcall(Dresser.applySkin, tool, opts.skin) end
		bot.attacks, bot.reach = attacksOf(tool)
		tool.Parent = model
		for _ = 1, 60 do
			bot.ctrl = CombatServer.get(tool)
			if bot.ctrl then break end
			task.wait(0.05)
		end
	end
	bot.attacks = bot.attacks or {}
	bot.reach = bot.reach or 5
	if #bot.attacks == 0 then bot.ctrl = nil end

	-- face the opponent every frame (yaw only), unless down
	table.insert(bot.conns, RunService.Heartbeat:Connect(function()
		local f = bot.facing
		local down = not bot.alive or hum.Health <= 0 or model:GetAttribute("Ragdolled") == true
		align.Enabled = not down and f ~= nil and f.Parent ~= nil
		if not align.Enabled then return end
		local d = Vector3.new(f.Position.X - hrp.Position.X, 0, f.Position.Z - hrp.Position.Z)
		if d.Magnitude > 0.5 then align.CFrame = CFrame.lookAt(Vector3.zero, d.Unit) end
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
		local killer = Players:GetPlayerByUserId(model:GetAttribute("LastHitBy") or 0)
		if killer and _G.KillFxHook then task.spawn(_G.KillFxHook, killer, model) end
		if opts.onDeath then task.spawn(opts.onDeath, bot, killer) end
		task.delay(opts.corpseTime or 6, function() bot:destroy() end)
	end)
	return bot
end

function Bots.list()
	local out = {}
	for b in pairs(live) do table.insert(out, b) end
	return out
end

return Bots
