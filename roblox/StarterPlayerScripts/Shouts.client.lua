--[[ SHOUTS — the fighters round you call out, on your screen only: a soldier bot charging
     ("FOR THE CROWN!", "AT THEM!"), holding ("SHIELDS UP!", "STEADY!"), badly hurt ("I'M HIT!"),
     felling a foe ("NEXT!"), seeing a friend fall ("AVENGE THEM!"); a goblin's "SHINIES!", an orc's
     "SMASH!", an elf's "BEGONE!". The undead, beasts and the like keep their silence.

     A shout pops over the speaker's head in its side's colour and fades. Only fighters within 40
     studs and in view; a few at a time (fewer on a phone), each speaker now and then. Not in the
     Hub. Nothing here is sent to the server. ]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

local GameConfig = require(ReplicatedStorage:WaitForChild("GameConfig"))
local Theme = require(ReplicatedStorage:WaitForChild("Theme"))
local Device = require(ReplicatedStorage:WaitForChild("Device"))
local round = ReplicatedStorage:WaitForChild("Round")
local player = Players.LocalPlayer

local NEAR = 40
local GAP = 2.2            -- seconds between any two shouts (a battle, not a crowd talking)
local EACH = 12            -- seconds before the same one shouts again
local MAX_UP = Device.kind() == "phone" and 2 or 3
local ALLY_DOWN = 16       -- a friend falling this near is noticed

-- what each kind says, by moment
local SOLDIER = {
	charge = {"FOR THE %s!", "CHARGE!", "AT THEM!", "WITH ME!", "FORWARD!", "FOR GLORY!", "FOR THE %s!"},
	fight = {"HOLD THE LINE!", "SHIELDS UP!", "STEADY!", "PUSH THEM BACK!", "STAND FAST!", "COME ON THEN!", "FACE ME!", "BREAK THEM!"},
	hurt = {"I'M HIT!", "STILL STANDING!", "IS THAT ALL?", "NOT YET!", "HOLD... HOLD!"},
	kill = {"NEXT!", "STAY DOWN!", "WHO'S NEXT?", "ONE LESS!", "FOR THE %s!"},
	ally = {"WE'VE LOST ONE!", "AVENGE THEM!", "CLOSE THE GAP!", "THEY'RE THROUGH!"},
}
local BANDIT = {
	charge = {"CHARGE!", "AT THEM!", "GET THEM!", "NO WITNESSES!"},
	fight = {"COME ON THEN!", "FACE ME!", "YOUR PURSE OR YOUR LIFE!", "HOLD THEM!"},
	hurt = {"I'M HIT!", "NOT YET!", "FALL BACK!"},
	kill = {"NEXT!", "STAY DOWN!", "EASY PICKINGS!"},
	ally = {"WE'VE LOST ONE!", "THEY'LL PAY FOR THAT!"},
}
local FACTION = {
	Human = BANDIT,
	Goblin = {charge = {"SHINIES!", "GET THEM!", "STAB STAB STAB!", "HEHEHE!"}, fight = {"HEHEHE!", "POKEY POKEY!", "MINE! ALL MINE!"},
		hurt = {"RUN AWAY!", "NOT THE FACE!", "OWWW!"}, kill = {"MINE NOW!", "HEHEHE!", "SHINIES!"}, ally = {"MORE FOR ME!", "OOPS!"}},
	Orc = {charge = {"SMASH!", "CRUSH THEM!", "HRAAH!", "FIGHT ME!"}, fight = {"HRAAH!", "WEAK!", "MORE!", "SMASH!"},
		hurt = {"HURTS GOOD!", "MORE!", "HRAAH!"}, kill = {"WEAK!", "NEXT ONE!", "HRAAH!"}, ally = {"WEAKLING!", "HRAAH!"}},
	Elf = {charge = {"FOR THE FOREST!", "SWIFTLY!", "YOU DO NOT BELONG HERE!"}, fight = {"BEGONE!", "LEAVE THIS PLACE!", "STAND AND FALL!"},
		hurt = {"I WILL NOT FALL!", "STILL I STAND!"}, kill = {"BEGONE!", "AS IT SHOULD BE"}, ally = {"KIN! NO!", "THEY WILL PAY!"}},
}
local MONSTER_COLOR = {Goblin = Color3.fromRGB(150, 210, 80), Orc = Color3.fromRGB(230, 120, 60), Elf = Color3.fromRGB(150, 230, 200), Human = Color3.fromRGB(226, 222, 210)}

local folder = workspace:WaitForChild("NPCs", math.huge)
local state = {}        -- [model] = {hp, last, foe, alive, charged}
local downed = setmetatable({}, {__mode = "k"})   -- [a player's body] = true once it has fallen
local live = 0
local lastAny = 0

local function sideOf(m) return m:GetAttribute("Team") end
local function linesFor(m)
	if m:GetAttribute("Bot") and not m:GetAttribute("Monster") then return SOLDIER end
	return FACTION[m:GetAttribute("Faction") or ""]
end
local function colorFor(m)
	if m:GetAttribute("Monster") then return MONSTER_COLOR[m:GetAttribute("Faction") or ""] or Color3.new(1, 1, 1) end
	local t = GameConfig.TEAMS[sideOf(m) or ""]
	return t and t.rgb or Color3.new(1, 1, 1)
end

local function say(m, kind)
	local now = os.clock()
	local st = state[m]
	if not st or now - st.last < EACH or now - lastAny < GAP or live >= MAX_UP then return end
	local pool = linesFor(m)
	pool = pool and pool[kind]
	local head = m:FindFirstChild("Head")
	if not (pool and head) then return end
	local cam = workspace.CurrentCamera
	if not cam or (cam.CFrame.Position - head.Position).Magnitude > NEAR then return end
	local _, onScreen = cam:WorldToViewportPoint(head.Position)
	if not onScreen then return end
	st.last, lastAny = now, now
	local side = GameConfig.TEAMS[sideOf(m) or ""]
	local text = string.format(pool[math.random(#pool)], side and string.upper(side.name) or "KING")
	local bb = Instance.new("BillboardGui")
	bb.Name = "Shout"
	bb.Size = UDim2.fromOffset(260, 34)
	bb.StudsOffsetWorldSpace = Vector3.new(0, 2.6, 0)
	bb.MaxDistance = NEAR + 10
	bb.LightInfluence = 0
	local t = Instance.new("TextLabel")
	t.BackgroundTransparency = 1
	t.Size = UDim2.fromScale(1, 1)
	t.Font = Theme.FONT_TITLE
	t.TextSize = 20
	t.Text = text
	t.TextColor3 = Color3.new(1, 1, 1)
	t.TextStrokeColor3 = colorFor(m):Lerp(Color3.new(0, 0, 0), 0.35)
	t.TextStrokeTransparency = 0.15
	t.TextTransparency = 1
	t.Parent = bb
	local sc = Instance.new("UIScale"); sc.Scale = 0.6; sc.Parent = t
	bb.Adornee = head
	bb.Parent = head
	live += 1
	TweenService:Create(sc, TweenInfo.new(0.22, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {Scale = 1}):Play()
	TweenService:Create(t, TweenInfo.new(0.12), {TextTransparency = 0}):Play()
	TweenService:Create(bb, TweenInfo.new(2.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {StudsOffsetWorldSpace = Vector3.new(0, 3.4, 0)}):Play()
	task.delay(1.7, function()
		TweenService:Create(t, TweenInfo.new(0.5), {TextTransparency = 1, TextStrokeTransparency = 1}):Play()
		task.delay(0.55, function() bb:Destroy(); live -= 1 end)
	end)
end

-- two fighters on opposite sides (by Team; a monster and anyone who isn't one are always foes)
local function hostile(a, b)
	local ma, mb = a:GetAttribute("Monster") ~= nil, b:GetAttribute("Monster") ~= nil
	if ma ~= mb then return true end
	local sa, sb = sideOf(a), sideOf(b)
	return sa ~= nil and sb ~= nil and sa ~= sb
end

-- the nearest foe of a fighter, and how near
local function foeOf(m, root, everyone)
	local best, bd = nil, math.huge
	for _, o in ipairs(everyone) do
		if o ~= m then
			local h = o:FindFirstChildOfClass("Humanoid")
			local r = o:FindFirstChild("HumanoidRootPart")
			if h and h.Health > 0 and r and hostile(m, o) then
				local d = (r.Position - root.Position).Magnitude
				if d < bd then best, bd = o, d end
			end
		end
	end
	return best, bd
end

local acc = 0
RunService.Heartbeat:Connect(function(dt)
	acc += dt
	if acc < 0.25 then return end
	acc = 0
	if round:GetAttribute("Mode") == "Hub" then return end
	local cam = workspace.CurrentCamera
	if not cam then return end
	local eye = cam.CFrame.Position
	-- who's about: the fighters near enough, and everyone they might be fighting
	local near, everyone = {}, {}
	for _, p in ipairs(Players:GetPlayers()) do if p.Character then table.insert(everyone, p.Character) end end
	for _, m in ipairs(folder:GetChildren()) do
		local r = m:FindFirstChild("HumanoidRootPart")
		if r and (r.Position - eye).Magnitude < NEAR + 25 then
			table.insert(everyone, m)
			if (r.Position - eye).Magnitude < NEAR and linesFor(m) then table.insert(near, m) end
		end
	end
	local now = os.clock()
	-- a friend falling near a fighter (and a player felled: the one fighting them crows)
	local fallen = {}
	for _, p in ipairs(Players:GetPlayers()) do
		local c = p.Character
		local h = c and c:FindFirstChildOfClass("Humanoid")
		if h and h.Health <= 0 and not downed[c] then
			downed[c] = true
			local r = c:FindFirstChild("HumanoidRootPart")
			if r then table.insert(fallen, {pos = r.Position, side = sideOf(c)}) end
			for k, kst in pairs(state) do
				if kst.foe == c and k.Parent then say(k, "kill") end
			end
		end
	end
	for m, st in pairs(state) do
		local h = m.Parent and m:FindFirstChildOfClass("Humanoid")
		if not h or h.Health <= 0 then
			if st.alive ~= false and m.Parent then
				local r = m:FindFirstChild("HumanoidRootPart")
				if r then table.insert(fallen, {pos = r.Position, side = sideOf(m)}) end
				-- (the one who was fighting it: a kill)
				for k, kst in pairs(state) do
					if kst.foe == m and k.Parent then say(k, "kill") end
				end
			end
			st.alive = false
			if not m.Parent then state[m] = nil end
		end
	end
	for _, m in ipairs(near) do
		local h = m:FindFirstChildOfClass("Humanoid")
		local r = m:FindFirstChild("HumanoidRootPart")
		if h and r and h.Health > 0 then
			local st = state[m]
			if not st then st = {hp = h.Health, last = now - EACH + math.random() * 4, alive = true}; state[m] = st end
			local foe, fd = foeOf(m, r, everyone)
			st.foe = (fd < 10) and foe or nil
			local speed = Vector3.new(r.AssemblyLinearVelocity.X, 0, r.AssemblyLinearVelocity.Z).Magnitude
			local hurt = h.Health < st.hp - 1
			st.hp = h.Health
			if hurt and h.Health < h.MaxHealth * 0.35 then say(m, "hurt")
			elseif foe and fd < 26 and fd > 9 and speed > 10 and not st.charged then st.charged = true; say(m, "charge")
			elseif foe and fd < 9 and math.random() < 0.04 then say(m, "fight") end
			if not foe or fd > 30 then st.charged = false end
			for _, f in ipairs(fallen) do
				if f.side and f.side == sideOf(m) and (f.pos - r.Position).Magnitude < ALLY_DOWN then say(m, "ally"); break end
			end
		end
	end
end)
