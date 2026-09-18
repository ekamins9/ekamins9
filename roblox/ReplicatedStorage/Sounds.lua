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
