--[[ KINGSLAYER — everyone against the King (GameConfig.MODES.Kingslayer: a free-for-all with bots).

     A few seconds in, THE CROWN appears in the middle of the field: whoever takes it is the
     King. The King is hard to kill (60% of the damage, unflinching, +150 health, a little harder
     hitting, a little slower) and impossible to miss: crowned, glowing gold through walls, a
     crown over their head. Every second as King is a point (a kill as King, 5 more).
     KILL THE KING AND YOU ARE THE KING (and 10 points for it). If the King falls to anything else
     — a bot, the world — the crown drops where they fell, for anyone to take.

     EVERYONE AGAINST THE KING: the bots (BotFill) go for the King when they're within reach of
     them (anyone else only when they're in the way), and gather on the crown when it's lying on
     the ground. The longer someone's King, the brighter they burn: every 30 seconds of a reign
     the King's glow goes up a step and the field is told (THE KING HAS REIGNED 1:00…).

     First to `pointsToWin`, or the most when the clock runs out, rules the field.
     On screen: Adventure.client (OwnHud): who's King, the leader, your points (your chip). ]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local Debris = game:GetService("Debris")

local Game = require(script.Parent.Parent:WaitForChild("Game"))
local Combat = ServerScriptService:WaitForChild("Combat")
local Powers = require(Combat:WaitForChild("Powers"))
local MapLoader = Game.MapLoader
local node = Game.node

local FOREVER = 1e6
local GOLD = Color3.fromRGB(255, 205, 60)
local KING_HEALTH = 150

local Kingslayer = setmetatable({}, {__index = Game.Mode})
Kingslayer.__index = Kingslayer
function Kingslayer.new(def, id) return setmetatable(Game.Mode.new(def, id), Kingslayer) end

local function event() return ReplicatedStorage:FindFirstChild("AdventureEvent") end
local function banner(t) local e = event(); if e then e:FireAllClients("Banner", t) end end
local function humOf(c) return c and c:FindFirstChildOfClass("Humanoid") end

-- the crown on a head, the gold about them
local function crownOn(char)
	local head = char:FindFirstChild("Head")
	if not head then return end
	local f = Instance.new("Folder"); f.Name = "KingsCrown"; f.Parent = char
	local function bit(size, cf, color, mat)
		local p = Instance.new("Part")
		p.Size, p.Color, p.Material = size, color, mat or Enum.Material.Metal
		p.CanCollide, p.CanQuery, p.CanTouch, p.Massless = false, false, false, true
		p.CFrame = head.CFrame * cf
		local w = Instance.new("Weld"); w.Part0 = head; w.Part1 = p; w.C0 = cf; w.Parent = p
		p.Parent = f
		return p
	end
	for i = 0, 7 do
		local a = i / 8 * math.pi * 2
		local cf = CFrame.new(math.cos(a) * 0.66, 0.86, math.sin(a) * 0.66) * CFrame.Angles(0, -a + math.pi / 2, 0)
		bit(Vector3.new(0.55, 0.3, 0.08), cf, GOLD)
		local spike = bit(Vector3.new(0.12, 0.42, 0.12), cf * CFrame.new(0, 0.32, 0), GOLD)
		if i % 2 == 0 then bit(Vector3.new(0.16, 0.16, 0.16), cf * CFrame.new(0, 0.05, -0.06), Color3.fromRGB(220, 30, 60), Enum.Material.Neon) end
		spike.Shape = Enum.PartType.Block
	end
	local hl = Instance.new("Highlight")
	hl.Name = "KingGlow"
	hl.FillColor, hl.OutlineColor = GOLD, GOLD
	hl.FillTransparency, hl.OutlineTransparency = 0.75, 0
	hl.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
	hl.Parent = char
	local bb = Instance.new("BillboardGui")
	bb.Name = "KingMark"
	bb.Size = UDim2.fromOffset(120, 40)
	bb.StudsOffset = Vector3.new(0, 4.2, 0)
	bb.AlwaysOnTop = true
	bb.LightInfluence = 0
	bb.MaxDistance = 400
	bb.Adornee = head
	local t = Instance.new("TextLabel")
	t.BackgroundTransparency = 1; t.Size = UDim2.fromScale(1, 1)
	t.Font = Enum.Font.FredokaOne; t.TextSize = 26; t.TextColor3 = GOLD
	t.TextStrokeTransparency = 0.2; t.Text = "👑 KING"
	t.Parent = bb
	bb.Parent = char
	local torso = char:FindFirstChild("Torso")
	if torso then
		local pe = Instance.new("ParticleEmitter")
		pe.Name = "KingSparks"
		pe.Color = ColorSequence.new(GOLD)
		pe.LightEmission = 1; pe.Rate = 10
		pe.Lifetime = NumberRange.new(0.8, 1.4); pe.Speed = NumberRange.new(1, 3)
		pe.SpreadAngle = Vector2.new(180, 180); pe.Acceleration = Vector3.new(0, 3, 0)
		pe.Size = NumberSequence.new(0.3, 0)
		pe.Parent = torso
	end
end

function Kingslayer:crown(plr)
	local char = plr and plr.Character
	local hum = humOf(char)
	if not (hum and hum.Health > 0) then return false end
	self:uncrown()
	self.king, self.kingChar = plr, char
	char:SetAttribute("King", true)
	crownOn(char)
	Powers.addMods(char, {taken = 0.6, dealt = 1.15, speed = 0.94, unflinching = true}, FOREVER, "King")
	hum.MaxHealth += KING_HEALTH
	hum.Health = hum.MaxHealth
	if self.drop then self.drop:Destroy(); self.drop = nil end
	self.reignAt, self.reignStep = os.clock(), 0
	node:SetAttribute("KingName", plr.DisplayName)
	banner({text = string.upper(plr.DisplayName) .. " IS KING", sub = "KILL THE KING TO TAKE THE CROWN", kind = "victory"})
	return true
end
function Kingslayer:uncrown()
	local c = self.kingChar
	if c and c.Parent then
		c:SetAttribute("King", nil)
		for _, n in ipairs({"KingsCrown", "KingGlow", "KingMark"}) do local x = c:FindFirstChild(n); if x then x:Destroy() end end
		local torso = c:FindFirstChild("Torso")
		local s = torso and torso:FindFirstChild("KingSparks")
		if s then s:Destroy() end
		Powers.clearMods(c, "King")
		local h = humOf(c)
		if h and h.Health > 0 then h.MaxHealth = math.max(10, h.MaxHealth - KING_HEALTH); h.Health = math.min(h.Health, h.MaxHealth) end
	end
	self.king, self.kingChar = nil, nil
	node:SetAttribute("KingName", "")
end

-- the crown on the ground: a gold glow and a prompt
function Kingslayer:dropCrown(pos)
	if self.drop then self.drop:Destroy() end
	local m = Instance.new("Model")
	m.Name = "FallenCrown"
	local base = Instance.new("Part")
	base.Name = "Base"
	base.Anchored, base.CanCollide, base.CanQuery = true, false, false
	base.Shape = Enum.PartType.Cylinder
	base.Size = Vector3.new(0.3, 2.4, 2.4)
	base.Color = GOLD
	base.Material = Enum.Material.Neon
	base.CFrame = CFrame.new(pos + Vector3.new(0, 1.8, 0)) * CFrame.Angles(0, 0, math.pi / 2)
	base.Parent = m
	for i = 0, 7 do
		local a = i / 8 * math.pi * 2
		local s = Instance.new("Part")
		s.Anchored, s.CanCollide, s.CanQuery = true, false, false
		s.Size = Vector3.new(0.22, 0.7, 0.22); s.Color = GOLD; s.Material = Enum.Material.Metal
		s.CFrame = CFrame.new(pos + Vector3.new(math.cos(a) * 1.05, 2.3, math.sin(a) * 1.05))
		s.Parent = m
	end
	local beam = Instance.new("Part")
	beam.Anchored, beam.CanCollide, beam.CanQuery = true, false, false
	beam.Shape = Enum.PartType.Cylinder
	beam.Size = Vector3.new(40, 0.6, 0.6); beam.Color = GOLD; beam.Material = Enum.Material.Neon; beam.Transparency = 0.5
	beam.CFrame = CFrame.new(pos + Vector3.new(0, 22, 0)) * CFrame.Angles(0, 0, math.pi / 2)
	beam.Parent = m
	local l = Instance.new("PointLight"); l.Color = GOLD; l.Range = 18; l.Brightness = 2; l.Parent = base
	local pr = Instance.new("ProximityPrompt")
	pr.ActionText = "Take the crown"; pr.ObjectText = "The Crown"
	pr.HoldDuration = 0.4; pr.MaxActivationDistance = 10; pr.RequiresLineOfSight = false
	pr:SetAttribute("PickupKey", true)
	pr.Parent = base
	pr.Triggered:Connect(function(plr) if self.drop == m then self:crown(plr) end end)
	m.Parent = MapLoader.current or workspace
	self.drop = m
	node:SetAttribute("CrownPos", pos)
end

-- EVERYONE AGAINST THE KING: the bots' say (BotFill asks before each one comes in)
local HUNT = 110   -- a bot this near the King goes for them
function Kingslayer:botOpts(opts)
	opts.goal = function(bot)
		if Game.current ~= self then return nil end
		local kc = self.kingChar
		local kr = kc and kc.Parent and kc:FindFirstChild("HumanoidRootPart")
		if kr and bot.model ~= kc and bot.hrp and (kr.Position - bot.hrp.Position).Magnitude < HUNT then return kr.Position end
		local c = self.drop and self.drop:FindFirstChild("Base")
		return c and c.Position or nil
	end
	opts.engage = function(bot, foe)
		if Game.current ~= self then return true end
		local kc = self.kingChar
		if not (kc and kc.Parent) or foe == kc then return true end
		local kr = kc:FindFirstChild("HumanoidRootPart")
		local fr = foe and foe:FindFirstChild("HumanoidRootPart")
		if not (kr and fr and bot.hrp) then return true end
		-- (someone in the way, or the King too far off to bother: fight them)
		return (fr.Position - bot.hrp.Position).Magnitude < 12 or (kr.Position - bot.hrp.Position).Magnitude >= HUNT
	end
end

function Kingslayer:start(map)
	Game.Mode.start(self, map)
	self.points = {}
	self.king, self.kingChar, self.drop = nil, nil, nil
	self.crownAt = os.clock() + 8
	node:SetAttribute("OwnHud", true)
	node:SetAttribute("ObjKind", "King")
	node:SetAttribute("KingName", "")
	for _, p in ipairs(Players:GetPlayers()) do p:SetAttribute("KingScore", 0); p:SetAttribute("AdvChip", "👑 0") end
	task.delay(2, function() banner({text = "KINGSLAYER", sub = "TAKE THE CROWN  ·  KILL THE KING", kind = "floor"}) end)
end

function Kingslayer:stop()
	self:uncrown()
	if self.drop then self.drop:Destroy(); self.drop = nil end
	for _, k in ipairs({"OwnHud", "ObjKind", "KingName", "CrownPos", "ObjLabel", "ObjNote"}) do node:SetAttribute(k, nil) end
	for _, p in ipairs(Players:GetPlayers()) do p:SetAttribute("AdvChip", nil) end
end

function Kingslayer:addPoints(plr, n)
	if not plr then return end
	self.points[plr] = (self.points[plr] or 0) + n
	local v = math.floor(self.points[plr])
	plr:SetAttribute("KingScore", v)
	plr:SetAttribute("AdvChip", "👑 " .. v)
end

function Kingslayer:onKill(killerPlr, victimPlr, victimChar)
	Game.Mode.onKill(self, killerPlr, victimPlr, victimChar)
	if killerPlr and killerPlr == self.king then self:addPoints(killerPlr, 5) end
	if victimChar and victimChar == self.kingChar then
		local fell = victimChar:FindFirstChild("HumanoidRootPart")
		local pos = fell and fell.Position or Vector3.zero
		self:uncrown()
		if killerPlr and killerPlr ~= victimPlr then
			self:addPoints(killerPlr, 10)
			self:crown(killerPlr)
		else
			task.delay(1, function() self:dropCrown(pos) end)
		end
	end
end
function Kingslayer:onDeath(victimPlr)
	-- (a King who fell to a bot or the world: Game.onDeath with no killer)
	if victimPlr == self.king and self.kingChar then
		local r = self.kingChar:FindFirstChild("HumanoidRootPart")
		local pos = r and r.Position or Vector3.zero
		self:uncrown()
		task.delay(1, function() if not self.king then self:dropCrown(pos) end end)
	end
end

function Kingslayer:tick(dt)
	local now = os.clock()
	if not self.king and not self.drop and self.crownAt and now >= self.crownAt then
		self.crownAt = nil
		-- (open ground near the middle, not a rooftop: the Horde's own finder)
		local m = MapLoader.current
		local ok, pos = pcall(require(script.Parent.Parent:WaitForChild("HordeObjective")).place, m, 8)
		self:dropCrown(ok and typeof(pos) == "Vector3" and pos or (m and m:GetAttribute("Centre")) or Vector3.zero)
		banner({text = "THE CROWN", sub = "IT LIES IN THE MIDDLE OF THE FIELD: TAKE IT", kind = "victory"})
	end
	-- the King left, or their body is gone
	if self.king and (not self.king.Parent or not (self.kingChar and self.kingChar.Parent)) then
		local r = self.kingChar and self.kingChar:FindFirstChild("HumanoidRootPart")
		local pos = r and r.Position
		self:uncrown()
		if pos then self:dropCrown(pos) end
	end
	if self.king then
		self:addPoints(self.king, dt)
		-- a long reign burns brighter (and the field hears of it)
		local step = math.floor((os.clock() - (self.reignAt or os.clock())) / 30)
		if step > (self.reignStep or 0) then
			self.reignStep = step
			local hl = self.kingChar and self.kingChar:FindFirstChild("KingGlow")
			if hl then hl.FillTransparency = math.max(0.35, 0.75 - step * 0.1) end
			local secs = step * 30
			banner({text = string.format("THE KING HAS REIGNED %d:%02d", secs // 60, secs % 60), sub = string.upper(self.king.DisplayName) .. "  ·  BRING THEM DOWN", kind = "elite"})
		end
	end
	-- the screen
	local best, bestN = nil, -1
	for p, n in pairs(self.points) do if p.Parent and n > bestN then best, bestN = p, n end end
	node:SetAttribute("ObjLabel", self.king and ("👑 " .. string.upper(self.king.DisplayName) .. " IS KING") or (self.drop and "THE CROWN LIES WAITING" or "THE CROWN IS COMING"))
	node:SetAttribute("ObjNote", string.format("FIRST TO %d%s", self.def.pointsToWin or 150, best and string.format("  ·  LEADER %s %d", string.upper(best.DisplayName), math.floor(bestN)) or ""))
	node:SetAttribute("Objective", self:objective())
end

function Kingslayer:isOver()
	for p, n in pairs(self.points) do
		if p.Parent and n >= (self.def.pointsToWin or 150) then return self:result() end
	end
	return nil
end
function Kingslayer:result()
	local best, bestN = nil, -1
	for p, n in pairs(self.points or {}) do if p.Parent and n > bestN then best, bestN = p, n end end
	node:SetAttribute("Winner", best and best.DisplayName or "")
	node:SetAttribute("WinnerKills", 0)
	return best and string.format("%s RULES THE FIELD  ·  %d POINTS", string.upper(best.DisplayName), math.floor(bestN)) or "NOBODY HELD THE CROWN"
end
function Kingslayer:objective()
	return self.king and ("KINGSLAYER  ·  " .. string.upper(self.king.DisplayName) .. " IS KING") or "KINGSLAYER  ·  TAKE THE CROWN"
end

return Kingslayer
