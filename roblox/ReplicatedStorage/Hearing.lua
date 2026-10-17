--[[ HEARING — a blast close by leaves you half deaf for a few seconds, on your screen only: the
     world goes muffled and quieter, a thin ringing fills your ears (WarAudio ▸ EarRing), your eyes
     swim a moment, and it all comes back over a few seconds. The score plays on (Music keeps its
     own group).

     Every sound in the world (workspace) is routed through one SoundGroup, SoundService ▸ World,
     as it appears; the deafness is that group's equaliser and volume. Sounds already in a group
     are left where they are.

       Hearing.init()           once (StarterPlayerScripts ▸ Hearing.client): the World group,
                                and every world sound put in it as it comes
       Hearing.ring(k, secs?)   k 0..1, how hard; secs till it has all come back (2 + 3k). A harder
                                blast than the one still ringing takes over; a softer one doesn't

     WarFX.blast rings it for a blast near the camera, scaled by the Screen shake setting (shake
     off: no deafness either). Nothing here is sent to the server. ]]

local SoundService = game:GetService("SoundService")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Lighting = game:GetService("Lighting")

local Hearing = {}

local inited = false
local group, eq, blur, ring, ringBase
local level, untilT, len = 0, 0, 1
local conn

local function adopt(d)
	if d:IsA("Sound") and d.SoundGroup == nil then d.SoundGroup = group end
end

function Hearing.init()
	if inited then return end
	inited = true
	group = SoundService:FindFirstChild("World")
	if not (group and group:IsA("SoundGroup")) then
		group = Instance.new("SoundGroup")
		group.Name = "World"
		group.Parent = SoundService
	end
	group.Volume = 1
	eq = Instance.new("EqualizerSoundEffect")
	eq.Name = "Deafness"
	eq.LowGain, eq.MidGain, eq.HighGain = 0, 0, 0
	eq.Enabled = false
	eq.Parent = group
	workspace.DescendantAdded:Connect(adopt)
	-- (what's already there, a slice at a time)
	task.spawn(function()
		for i, d in ipairs(workspace:GetDescendants()) do
			adopt(d)
			if i % 3000 == 0 then task.wait() end
		end
	end)
end

local function reset()
	if conn then conn:Disconnect(); conn = nil end
	level = 0
	eq.Enabled = false
	eq.LowGain, eq.MidGain, eq.HighGain = 0, 0, 0
	group.Volume = 1
	if blur then blur.Size = 0; blur.Enabled = false end
	if ring then ring:Destroy(); ring = nil end
end

local function step()
	local u = math.clamp((untilT - os.clock()) / len, 0, 1)   -- 1 as it hits, 0 when it's all back
	if u <= 0 then reset(); return end
	-- (the worst of it held a moment, then easing back)
	local a = level * (u >= 0.7 and 1 or (u / 0.7) ^ 2)
	eq.Enabled = true
	eq.HighGain, eq.MidGain, eq.LowGain = -42 * a, -16 * a, 2 * a
	group.Volume = 1 - 0.6 * a
	if blur then blur.Enabled = true; blur.Size = 7 * a * a end
	if ring and ring.Parent then ring.Volume = ringBase * math.min(1, a * 1.4) end
end

function Hearing.ring(k, secs)
	if not inited then Hearing.init() end
	k = math.clamp(k or 1, 0, 1)
	if k < 0.12 then return end
	local now = os.clock()
	local cur = level * math.clamp((untilT - now) / len, 0, 1)
	if k <= cur then return end
	secs = secs or (2 + 3 * k)
	level, untilT, len = k, now + secs, secs
	if not (blur and blur.Parent) then
		blur = Instance.new("BlurEffect")
		blur.Name = "HearingDaze"
		blur.Size = 0
		blur.Parent = Lighting
	end
	local audio = ReplicatedStorage:FindFirstChild("WarAudio")
	local src = audio and audio:FindFirstChild("EarRing")
	if src and src:IsA("Sound") then
		if ring then ring:Destroy() end
		ring = src:Clone()
		ring.Looped = false
		ringBase = src.Volume * (0.4 + 0.6 * k)
		ring.Volume = ringBase
		ring.Parent = SoundService
		ring:Play()
	end
	if not conn then conn = RunService.RenderStepped:Connect(step) end
	step()
end

return Hearing
