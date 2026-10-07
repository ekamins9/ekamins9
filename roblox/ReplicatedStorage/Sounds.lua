--[[ SOUNDS — tiny helper for one-shot and looped sounds. Works on server
     (replicated, positional when parented to a part) and client (local).
     Empty / "rbxassetid://0" ids are silently skipped, so every sound slot
     can stay unset until you have an asset for it.
       Sounds.play(id, part, opts)        one sound
       Sounds.bank(pool, part, opts)      a random take from a SoundBank pool
       Sounds.voice(kind, part, opts)     a fighter's grunt / cry (SoundBank voices)
       Sounds.loop(id, part, volume)      a looped sound the caller owns ]]

local Debris = game:GetService("Debris")

local Sounds = {}

local function valid(id)
	return type(id) == "string" and id ~= "" and id ~= "rbxassetid://0"
end

-- opts: Volume, Speed, Vary (±5% pitch, default true), MaxDistance, Ttl
function Sounds.play(id, parent, opts)
	if not valid(id) or not parent then return nil end
	opts = opts or {}
	local s = Instance.new("Sound")
	s.SoundId = id
	s.Volume = opts.Volume or 1
	local speed = opts.Speed or 1
	if opts.Vary ~= false then speed = speed * (0.95 + math.random() * 0.10) end
	s.PlaybackSpeed = speed
	s.RollOffMinDistance = 5
	s.RollOffMaxDistance = opts.MaxDistance or 80
	s.Parent = parent
	s:Play()
	Debris:AddItem(s, opts.Ttl or 8)
	return s
end

local SoundService = game:GetService("SoundService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

-- SOUND BANK: pools of takes (ReplicatedStorage ▸ SoundBank). One take at
-- random, never the same one twice running, pitch spread by the pool.
-- opts: Volume, Speed (multipliers), Chance (0..1: may stay quiet), MaxDistance
local bank
local lastTake = {}
function Sounds.bank(poolName, parent, opts)
	if not parent then return nil end
	bank = bank or require(ReplicatedStorage:WaitForChild("SoundBank"))
	local pool = bank.POOLS[poolName]
	local takes = pool and pool.takes
	if not takes or #takes == 0 then return nil end
	opts = opts or {}
	if opts.Chance and math.random() > opts.Chance then return nil end
	local i = math.random(#takes)
	if #takes > 1 and i == lastTake[poolName] then i = i % #takes + 1 end
	lastTake[poolName] = i
	local t = takes[i]
	if type(t) ~= "table" then t = {t} end
	local lo, hi = (pool.speed or {0.95, 1.05})[1], (pool.speed or {0.95, 1.05})[2]
	local s = Instance.new("Sound")
	s.SoundId = "rbxassetid://" .. tostring(t[1])
	s.Volume = (pool.volume or 0.7) * (t.vol or 1) * (opts.Volume or 1)
	s.PlaybackSpeed = (t.speed or 1) * (lo + math.random() * (hi - lo)) * (opts.Speed or 1)
	s.RollOffMode = Enum.RollOffMode.InverseTapered
	s.RollOffMinDistance = pool.near or 6
	s.RollOffMaxDistance = opts.MaxDistance or pool.far or 90
	s.Parent = parent
	s:Play()
	-- a cut take fades out at its mark (file time, so scaled by the pitch)
	local cut = t.cut or pool.cut
	if cut then
		local at = cut / math.max(s.PlaybackSpeed, 0.1)
		task.delay(at, function()
			if s.Parent then TweenService:Create(s, TweenInfo.new(0.12), {Volume = 0}):Play() end
		end)
		Debris:AddItem(s, at + 0.4)
	else
		Debris:AddItem(s, opts.Ttl or 6)
	end
	return s
end

-- VOICES: grunts, yells, cries. A folder SoundService.Voice/<kind>/ of Sounds
-- (one picked at random) overrides; otherwise the bank's Voice<kind> pool.
-- Kinds: Swing  Hurt  Death  Kick  Parry. With the bank, each fighter has their
-- own pitch (from their name), speaks up only part of the time (VOICE_CHANCE,
-- or opts.Chance) and never twice inside VOICE_GAP (a death always speaks).
local lastVoice = setmetatable({}, {__mode = "k"})
local function pitchOf(who)
	bank = bank or require(ReplicatedStorage:WaitForChild("SoundBank"))
	local h = 0
	for i = 1, #who.Name do h = (h * 31 + string.byte(who.Name, i)) % 997 end
	local lo, hi = bank.VOICE_PITCH[1], bank.VOICE_PITCH[2]
	return lo + (h / 996) * (hi - lo)
end
function Sounds.voice(kind, parent, opts)
	if not parent then return nil end
	opts = opts or {}
	local root = SoundService:FindFirstChild("Voice") or ReplicatedStorage:FindFirstChild("Voice")
	local folder = root and root:FindFirstChild(kind)
	if folder then
		local list = {}
		for _, c in ipairs(folder:GetChildren()) do
			if c:IsA("Sound") and valid(c.SoundId) then table.insert(list, c) end
		end
		if #list == 0 then return nil end
		local t = list[math.random(#list)]
		return Sounds.play(t.SoundId, parent, {
			Volume = t.Volume * (opts.Volume or 1),
			Speed  = t.PlaybackSpeed * (opts.Speed or 1),
			MaxDistance = opts.MaxDistance, Ttl = opts.Ttl,
		})
	end
	bank = bank or require(ReplicatedStorage:WaitForChild("SoundBank"))
	local who = opts.Who or parent:FindFirstAncestorOfClass("Model")
	if who then
		local now = os.clock()
		if kind ~= "Death" and lastVoice[who] and now - lastVoice[who] < bank.VOICE_GAP then return nil end
		local chance = opts.Chance or bank.VOICE_CHANCE[kind] or 1
		if math.random() > chance then return nil end
		lastVoice[who] = now
	end
	return Sounds.bank("Voice" .. kind, parent, {
		Volume = opts.Volume, Speed = (who and pitchOf(who) or 1) * (opts.Speed or 1), MaxDistance = opts.MaxDistance,
	})
end

-- returns a looped Sound the caller owns (adjust Volume/PlaybackSpeed, Destroy when done)
function Sounds.loop(id, parent, volume)
	if not valid(id) or not parent then return nil end
	local s = Instance.new("Sound")
	s.SoundId = id
	s.Volume = volume or 1
	s.Looped = true
	s.Parent = parent
	s:Play()
	return s
end

return Sounds
