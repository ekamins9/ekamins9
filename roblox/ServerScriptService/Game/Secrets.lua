--[[ SECRETS — walled-up caches in the dungeons (The Depths, Deadvault). Game ▸ Dungeon builds them
     (opts.secrets: a room's stretch of wall newer than the rest, cracked, a draft of dust seeping
     through it, and behind it a passage to a little cache: gold, bones, candles burnt low).

     Strike the cracked wall with a blade (Combat ▸ CombatServer.worldHitHooks): it shudders and
     sheds grit; the third blow brings it down, the stones tumbling into the room in a cloud of
     dust with a crash the dark hears (Combat ▸ Perception.noise). Then the mode's own reward
     appears in the cache (opts.reward(room, cf, plr): the Depths a chest, Deadvault an ornate
     container), and whoever broke it hears of it.

       Secrets.arm(map, layout, opts)   opts.reward, opts.banner(plr, t)
       Secrets.disarm() ]]

local Players = game:GetService("Players")
local ServerScriptService = game:GetService("ServerScriptService")
local Debris = game:GetService("Debris")
local TweenService = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Combat = ServerScriptService:WaitForChild("Combat")
local CombatServer = require(Combat:WaitForChild("CombatServer"))
local Perception = require(Combat:WaitForChild("Perception"))

local Secrets = {}
local BLOWS = 3
local live = {walls = {}, hooked = false, opts = nil}

local function sound(name, at, vol, speed)
	local src = ReplicatedStorage:FindFirstChild("WarAudio")
	src = src and src:FindFirstChild(name)
	if not (src and src:IsA("Sound")) then return end
	local a = Instance.new("Attachment")
	a.Position = at
	a.Parent = workspace.Terrain
	local s = src:Clone()
	s.Looped = false
	s.Volume = src.Volume * (vol or 1)
	s.PlaybackSpeed = speed or 1
	s.RollOffMode = Enum.RollOffMode.InverseTapered
	s.RollOffMinDistance, s.RollOffMaxDistance = 12, 160
	s.Parent = a
	s:Play()
	Debris:AddItem(a, 6)
end

local function dust(at, n, size)
	local p = Instance.new("Part")
	p.Anchored, p.CanCollide, p.CanQuery, p.CanTouch, p.Transparency = true, false, false, false, 1
	p.Size = Vector3.new(1, 1, 1)
	p.CFrame = CFrame.new(at)
	p.Parent = workspace.Terrain
	local e = Instance.new("ParticleEmitter")
	e.Texture = "rbxasset://textures/particles/smoke_main.dds"
	e.Color = ColorSequence.new(Color3.fromRGB(150, 140, 126))
	e.Size = NumberSequence.new(size or 2, (size or 2) * 3)
	e.Transparency = NumberSequence.new(0.3, 1)
	e.Lifetime = NumberRange.new(1.5, 3)
	e.Speed = NumberRange.new(4, 10)
	e.SpreadAngle = Vector2.new(180, 180)
	e.Acceleration = Vector3.new(0, 1, 0)
	e.Rate = 0
	e.Parent = p
	e:Emit(n or 12)
	Debris:AddItem(p, 4)
end

-- it gives way: the stones tumble into the room, the dust, the crash
local function collapse(w, plr)
	local panel = w.panel
	local cf, size, color, mat = panel.CFrame, panel.Size, panel.Color, panel.Material
	local into = -(w.out)
	panel:Destroy()
	local folder = Instance.new("Folder")
	folder.Name = "Rubble"
	folder.Parent = workspace
	for i = 0, 3 do
		for j = 0, 4 do
			local s = Vector3.new(size.X / 4 * 0.8, size.Y / 5 * 0.8, size.Z * 0.7)
			local at = cf * CFrame.new(-size.X / 2 + size.X / 4 * (i + 0.5), -size.Y / 2 + size.Y / 5 * (j + 0.5), 0)
			local st = Instance.new("Part")
			st.Size = s
			st.CFrame = at * CFrame.Angles(math.random() * 0.4, math.random() * 0.4, math.random() * 0.4)
			st.Color, st.Material = color, mat
			st.CanQuery, st.CanTouch = false, false
			st.Parent = folder
			st.AssemblyLinearVelocity = into * (8 + math.random() * 10) + Vector3.new((math.random() - 0.5) * 6, math.random() * 6, (math.random() - 0.5) * 6)
			st.AssemblyAngularVelocity = Vector3.new(math.random() * 6, math.random() * 6, math.random() * 6)
		end
	end
	-- (the stones settle where they fall and stop being in anyone's way; a while later they're gone)
	task.delay(1.6, function()
		for _, st in ipairs(folder:GetChildren()) do st.Anchored = true; st.CanCollide = false end
	end)
	task.delay(10, function()
		for _, st in ipairs(folder:GetChildren()) do
			TweenService:Create(st, TweenInfo.new(1.5), {Transparency = 1}):Play()
		end
		Debris:AddItem(folder, 1.7)
	end)
	dust(cf.Position, 26, 3)
	dust(cf.Position + into * 4, 14, 2)
	sound("Impact", cf.Position, 0.9, 0.55)
	sound("Gate", cf.Position, 0.5, 0.6)
	local c = plr and plr.Character
	Perception.noise(cf.Position, 40, c)
	if live.opts and live.opts.reward then
		local ok, err = pcall(live.opts.reward, w.room, CFrame.lookAt(w.chest, w.chest + w.face), plr)
		if not ok then warn("[Secrets] reward:", err) end
	end
	if plr and live.opts and live.opts.banner then
		live.opts.banner(plr, {text = "A SECRET!", sub = "SOMETHING WAS WALLED UP HERE", kind = "victory"})
	end
end

local function onHit(character, pos)
	local plr = Players:GetPlayerFromCharacter(character)
	if not plr then return end
	for i, w in ipairs(live.walls) do
		local panel = w.panel
		if panel.Parent then
			local rel = panel.CFrame:PointToObjectSpace(pos)
			local s = panel.Size
			if math.abs(rel.X) < s.X / 2 + 0.8 and math.abs(rel.Y) < s.Y / 2 + 0.8 and math.abs(rel.Z) < s.Z / 2 + 1.2 then
				w.hp -= 1
				if w.hp <= 0 then
					table.remove(live.walls, i)
					collapse(w, plr)
				else
					-- (it shudders and sheds grit)
					dust(pos, 6, 1)
					sound("Impact", pos, 0.45, 0.8 + math.random() * 0.2)
					local home = panel.CFrame
					panel.CFrame = home * CFrame.new(0, 0, 0.12)
					task.delay(0.08, function() if panel.Parent then panel.CFrame = home end end)
				end
				return
			end
		end
	end
end

function Secrets.disarm()
	live.walls, live.opts = {}, nil
end

function Secrets.arm(map, layout, opts)
	Secrets.disarm()
	live.opts = opts or {}
	if not live.hooked then
		live.hooked = true
		table.insert(CombatServer.worldHitHooks, onHit)
	end
	local folder = map and map:FindFirstChild("Secrets")
	if not (folder and layout) then return 0 end
	for _, r in ipairs(layout.rooms) do
		local panel = r.secret and folder:FindFirstChild("SecretWall" .. r.id)
		if panel and r.secret.chest then
			table.insert(live.walls, {panel = panel, room = r, hp = BLOWS, out = panel:GetAttribute("Out") or Vector3.new(0, 0, -1),
				chest = r.secret.chest, face = r.secret.face or Vector3.new(0, 0, 1)})
		end
	end
	return #live.walls
end

return Secrets
