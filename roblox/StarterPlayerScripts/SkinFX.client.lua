--[[ SKIN FX (client) — brings the skin effects that ReplicatedStorage ▸
     SkinFX builds on a weapon to life (every weapon in the world tagged
     "SkinFX", anyone's). It watches how fast each blade's tip is moving, and
     while it swings:
       • the aura flares (its emitters run up to four times their rate),
       • sparks fly off the tip (the skin's SkinBurst),
       • the blade's light swells (and a storm flickers),
       • the swing makes its sound (SkinFX.SWING: a whoosh of fire, a crackle
         of frost, a hum of shadow… from Roblox's licensed sound library).
     Everything here is local and looks only; nothing is sent anywhere. ]]

local CollectionService = game:GetService("CollectionService")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local SkinFX = require(ReplicatedStorage:WaitForChild("SkinFX"))

local SWING_SPEED = 26     -- studs/s at the tip that start a swing (and its sound)…
local SWING_END = 12       -- …which is over once the tip has stayed under this speed
local SWING_REST = 0.3     -- for this long (a windup's turn into the release is one swing)
local SWING_GAP = 0.6      -- seconds at least between two swing sounds
local FADE = 0.18          -- seconds a cut swing sound takes to fade out
local FLARE_FROM = 10      -- the aura starts to flare from this tip speed…
local FLARE_FULL = 40      -- …and is at its fullest here
local NEAR = 150           -- studs: farther weapons are left alone
local rng = Random.new()

local tracked = {}   -- [handle] = state

local function untrack(h)
	local st = tracked[h]
	if not st then return end
	tracked[h] = nil
	if st.sound then st.sound:Destroy() end
end

local function track(h)
	if tracked[h] or not h:IsA("BasePart") then return end
	-- give replication a moment to bring the effect's pieces in
	task.delay(0.2, function()
		if not h.Parent or tracked[h] then return end
		local tool = h.Parent
		local st = {tip = h:FindFirstChild("TrailTip"), emitters = {}, boost = 0, burstAt = 0, soundAt = 0, seed = rng:NextNumber(0, 6.28), radiant = {}}
		for _, d in ipairs(tool:GetDescendants()) do
			if d:GetAttribute("Radiant") then table.insert(st.radiant, d) end
			if d:IsA("ParticleEmitter") and d:GetAttribute("SkinFX") then
				if d.Name == "SkinBurst" then st.burst, st.burstCount = d, d:GetAttribute("Count") or 5
				else st.emitters[d] = d:GetAttribute("BaseRate") or d.Rate end
			elseif d:IsA("PointLight") and d:GetAttribute("SkinFX") then
				st.light, st.lightBase, st.flicker = d, d:GetAttribute("BaseBrightness") or d.Brightness, d:GetAttribute("Flicker") == true
			end
		end
		local swing = SkinFX.SWING[h:GetAttribute("SkinAura") or ""]
		if swing and swing.sound then
			local s = Instance.new("Sound")
			s.Name = "SkinSwing"
			s.SoundId = "rbxassetid://" .. tostring(swing.sound)
			s.Volume = swing.volume or 0.25
			s.RollOffMode = Enum.RollOffMode.InverseTapered
			s.RollOffMinDistance = 6
			s.RollOffMaxDistance = 70
			s.Parent = h
			st.sound, st.pitch, st.cut, st.volume = s, swing.pitch or 1, swing.cut, s.Volume
		end
		tracked[h] = st
	end)
end

CollectionService:GetInstanceAddedSignal("SkinFX"):Connect(track)
CollectionService:GetInstanceRemovedSignal("SkinFX"):Connect(untrack)
for _, h in ipairs(CollectionService:GetTagged("SkinFX")) do track(h) end

RunService.Heartbeat:Connect(function(dt)
	local cam = workspace.CurrentCamera
	if not cam then return end
	local eye = cam.CFrame.Position
	local now = os.clock()
	for h, st in pairs(tracked) do
		-- a Radiant finish: every glowing bit walks through the colours
		if #st.radiant > 0 and h.Parent then
			local c = Color3.fromHSV((now * 0.18 + st.seed) % 1, 0.65, 1)
			local c2 = Color3.fromHSV((now * 0.18 + st.seed + 0.25) % 1, 0.65, 1)
			for _, d in ipairs(st.radiant) do
				if d:IsA("BasePart") or d:IsA("PointLight") then d.Color = c
				elseif d:IsA("Trail") or d:IsA("ParticleEmitter") then d.Color = ColorSequence.new(c, c2) end
			end
		end
		if not h.Parent then
			untrack(h)
		elseif st.tip and st.tip.Parent and h:IsDescendantOf(workspace) then
			local pos = st.tip.WorldPosition
			local speed = st.last and (pos - st.last).Magnitude / math.max(dt, 1 / 240) or 0
			st.last = pos
			if (pos - eye).Magnitude <= NEAR and speed < 400 then   -- (a teleport is not a swing)
				local flare = math.clamp((speed - FLARE_FROM) / (FLARE_FULL - FLARE_FROM), 0, 1)
				st.boost = math.max(flare, st.boost - dt * 2.5)
				for pe, base in pairs(st.emitters) do
					if pe.Parent then pe.Rate = base * (1 + 3 * st.boost) end
				end
				if st.burst and flare > 0.35 and now - st.burstAt > 0.035 then
					st.burst:Emit(st.burstCount)
					st.burstAt = now
				end
				if st.light then
					local wave = st.flicker and (rng:NextNumber() < 0.15 and rng:NextNumber(0.2, 1.6) or 1) or (1 + 0.2 * math.sin(now * 3 + st.seed))
					st.light.Brightness = st.lightBase * wave * (1 + 1.6 * st.boost)
				end
				-- one sound per swing: it starts as the tip gets going and isn't
				-- started again until the tip has come to rest, so a long swing
				-- plays its whoosh once, through, instead of restarting it
				if speed > SWING_SPEED then
					st.slowFor = 0
					if not st.swinging then
						st.swinging = true
						if st.sound and now - st.soundAt > SWING_GAP then
							st.soundAt = now
							st.sound.PlaybackSpeed = st.pitch * rng:NextNumber(0.95, 1.05)
							st.sound.TimePosition = 0
							st.sound.Volume = st.volume
							st.sound:Play()
						end
					end
				elseif speed < SWING_END then
					st.slowFor = (st.slowFor or 0) + dt
					if st.swinging and st.slowFor > SWING_REST then st.swinging = false end
				end
				-- a skin whose sound runs long (cut) fades it out instead of snapping it off
				if st.sound and st.cut and st.sound.IsPlaying then
					local t = now - st.soundAt - st.cut
					if t > 0 then
						if t >= FADE then st.sound:Stop() else st.sound.Volume = st.volume * (1 - t / FADE) end
					end
				end
			end
		end
	end
end)
