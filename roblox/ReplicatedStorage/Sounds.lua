--[[ SOUNDS — tiny helper for one-shot and looped sounds. Works on server
     (replicated, positional when parented to a part) and client (local).
     Empty / "rbxassetid://0" ids are silently skipped, so every sound slot
     can stay unset until you have an asset for it. ]]

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

-- VOICE / VARIATION FOLDERS: SoundService.Voice/<kind>/ holds any number of
-- Sounds (grunts, yells…); one is picked at random. Kinds used by the game:
--   Swing  Hurt  Death  Kick  Parry  Dodge
-- Each Sound's own Volume / PlaybackSpeed is the baseline. Missing folder = silent.
local SoundService = game:GetService("SoundService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
function Sounds.voice(kind, parent, opts)
	if not parent then return nil end
	local root = SoundService:FindFirstChild("Voice") or ReplicatedStorage:FindFirstChild("Voice")
	local folder = root and root:FindFirstChild(kind)
	if not folder then return nil end
	local list = {}
	for _, c in ipairs(folder:GetChildren()) do
		if c:IsA("Sound") and valid(c.SoundId) then table.insert(list, c) end
	end
	if #list == 0 then return nil end
	local t = list[math.random(#list)]
	opts = opts or {}
	return Sounds.play(t.SoundId, parent, {
		Volume = t.Volume * (opts.Volume or 1),
		Speed  = t.PlaybackSpeed * (opts.Speed or 1),
		MaxDistance = opts.MaxDistance, Ttl = opts.Ttl,
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
