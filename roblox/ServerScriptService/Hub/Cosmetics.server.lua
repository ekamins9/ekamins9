--[[ COSMETICS SERVER — the server side of kill effects and emotes.
       ReplicatedStorage.FxEvent      (RemoteEvent, server → every client)
           "Kill", fxId, corpseId, origin, colours  the killer's equipped kill effect:
                 the body by its CorpseId attribute (a client that hasn't streamed it
                 in still plays the effect at `origin` in the body's `colours`)
           "Emote", player, emoteId, startedAt    a player started an emote
           "EmoteStop", player
       ReplicatedStorage.EmoteRemote  (RemoteEvent, client → server)
           "Play", emoteId  ·  "Stop"
     Kills come from Scoreboard (and the training dummies) through
     _G.KillFxHook(killerPlayer, victimCharacter). Only owned things play;
     everything here is looks, never stats. ]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local Catalog = require(ReplicatedStorage:WaitForChild("Catalog"))
local Profile = require(ServerScriptService:WaitForChild("Loadout"):WaitForChild("Profile"))
local Corpses = ServerScriptService:FindFirstChild("Combat") and ServerScriptService.Combat:FindFirstChild("Corpses")
Corpses = Corpses and require(Corpses)

local function remote(class, name)
	local r = ReplicatedStorage:FindFirstChild(name)
	if not r then r = Instance.new(class); r.Name = name; r.Parent = ReplicatedStorage end
	return r
end
local fx = remote("RemoteEvent", "FxEvent")
local emote = remote("RemoteEvent", "EmoteRemote")

-- the body falls first (and a head that came off rolls away); the effect plays on it a moment later
local KILL_FX_DELAY = 1.2

-- where the effect stands (upright over the fallen body, a standing torso's
-- height above the floor under it) and the body's colours
local floorRay = RaycastParams.new()
floorRay.FilterType = Enum.RaycastFilterType.Exclude
local function originOf(char)
	local torso = char:FindFirstChild("Torso") or char:FindFirstChild("HumanoidRootPart") or char:FindFirstChildWhichIsA("BasePart", true)
	if not torso then return nil end
	local pos = torso.Position
	floorRay.FilterDescendantsInstances = {char}
	local hit = workspace:Raycast(pos + Vector3.new(0, 1, 0), Vector3.new(0, -12, 0), floorRay)
	local look = torso.CFrame.LookVector
	return CFrame.new(pos.X, (hit and hit.Position.Y or pos.Y - 3) + 3, pos.Z) * CFrame.Angles(0, math.atan2(-look.X, -look.Z), 0)
end
local function coloursOf(char)
	local out, seen = {}, {}
	for _, d in ipairs(char:GetDescendants()) do
		if d:IsA("BasePart") and d.Transparency < 1 and d.Name ~= "HumanoidRootPart" then
			local key = d.Color:ToHex()
			if not seen[key] then seen[key] = true; table.insert(out, d.Color) end
			if #out >= 6 then break end
		end
	end
	return out
end

-- the killer's kill effect on the victim's body, for everyone
_G.KillFxHook = function(killer, victimChar)
	if not (killer and victimChar and victimChar.Parent) then return end
	local p = Profile.get(killer)
	local id = p and p.killfx
	if type(id) ~= "string" or not Catalog.KILLFX_BY[id] or not Profile.has(killer, "killfx", id) then return end
	-- what it leaves (Combat ▸ Corpses): booked now, laid when the effect hides the body
	local def = Catalog.KILLFX_BY[id]
	if Corpses then Corpses.pending(victimChar, def.remains or "body", KILL_FX_DELAY + (def.remainsAt or 1.5)) end
	task.wait(KILL_FX_DELAY)
	if not victimChar.Parent then return end
	local origin = originOf(victimChar)
	if not origin then return end
	-- (not the body itself: a client that hasn't streamed it in would get nil)
	fx:FireAllClients("Kill", id, Corpses and Corpses.idOf(victimChar) or victimChar:GetAttribute("CorpseId") or 0, origin, coloursOf(victimChar))
end

--------------------------------------------------------------------
--  THE HELMET TOSS (the emote HelmetToss): at 0.5 s a copy of your helmet comes off
--  your head into your left hand (a weld: every client sees it follow the posed arm),
--  at 1.12 s it's thrown — a real tumbling object — and a spare turns up on your
--  head at 2 s. It clangs off the world; it stings whoever it hits (HELM_DAMAGE,
--  friendly fire and peaceful places respected) and knocks them a little. A step,
--  an attack or a block before it's thrown puts it back.
--------------------------------------------------------------------
local HELM_LIFT, HELM_THROW, HELM_SPARE = 0.5, 1.12, 2.0
local HELM_DAMAGE = 8
local CLANG = {9116750726, 9116751108, 9119072660}
local thrownFolder
local CombatServer
local function clangAt(part, vol)
	local s = Instance.new("Sound")
	s.SoundId = "rbxassetid://" .. CLANG[math.random(#CLANG)]
	s.Volume = vol or 0.7
	s.PlaybackSpeed = 0.9 + math.random() * 0.25
	s.RollOffMinDistance = 8; s.RollOffMaxDistance = 90
	s.Parent = part
	s:Play()
	game:GetService("Debris"):AddItem(s, 3)
end
local function helmetToss(plr, char)
	local root = char:FindFirstChild("HumanoidRootPart")
	local hum = char:FindFirstChildOfClass("Humanoid")
	local armor = char:FindFirstChild("Armor")
	local helm = armor and armor:FindFirstChild("HeadClothing")
	local arm = char:FindFirstChild("Left Arm")
	if not (root and hum and helm and arm) then return end   -- (bareheaded: just the moves)
	local start = root.Position
	local function stillOn()
		return char.Parent ~= nil and hum.Health > 0 and not char:GetAttribute("Acting") and not char:GetAttribute("Blocking")
			and (root.Position - start).Magnitude < 2.5
	end
	task.wait(HELM_LIFT)
	if not stillOn() then return end
	-- the copy: one assembly round a hit box, in the left hand
	local copy = helm:Clone()
	for _, d in ipairs(copy:GetDescendants()) do
		if d:IsA("JointInstance") or d:IsA("Constraint") or d:IsA("ParticleEmitter") or d:IsA("Light") or d:IsA("Attachment") then d:Destroy() end
	end
	local box = Instance.new("Part")
	box.Name = "Hit"; box.Size = Vector3.new(1.5, 1.5, 1.5); box.Transparency = 1; box.CanCollide = true; box.Massless = true   -- (weightless in the hand)
	box.CFrame = arm.CFrame * CFrame.new(0, -1.5, 0)
	box.Parent = copy
	local offset = helm:FindFirstChild("Middle") and helm.Middle.CFrame or box.CFrame
	for _, p in ipairs(copy:GetDescendants()) do
		if p:IsA("BasePart") and p ~= box then
			p.Anchored, p.CanCollide, p.CanQuery, p.CanTouch, p.Massless = false, false, false, false, true
			local w = Instance.new("Weld"); w.Part0, w.Part1 = box, p
			w.C0 = CFrame.new(0, 0.2, 0) * offset:ToObjectSpace(p.CFrame); w.Parent = p
		end
	end
	copy.PrimaryPart = box
	thrownFolder = thrownFolder and thrownFolder.Parent and thrownFolder or Instance.new("Folder")
	thrownFolder.Name = "ThrownHelmets"; thrownFolder.Parent = workspace
	copy.Parent = thrownFolder
	local hold = Instance.new("Weld"); hold.Part0, hold.Part1 = arm, box; hold.C0 = CFrame.new(0, -1.5, 0); hold.Parent = box
	box.CanCollide = false
	-- your own helmet: off your head while it's in your hand and in the air
	local was = {}
	for _, p in ipairs(helm:GetDescendants()) do if p:IsA("BasePart") then was[p] = p.Transparency; p.Transparency = 1 end end
	local function spare()
		for p, t in pairs(was) do if p.Parent then p.Transparency = t end end
	end
	task.wait(HELM_THROW - HELM_LIFT)
	if not stillOn() then copy:Destroy(); spare(); return end
	-- the throw
	hold:Destroy()
	box.CanCollide = true
	box.Massless = false
	pcall(function() box:SetNetworkOwner(nil) end)
	local dir = root.CFrame.LookVector
	box.AssemblyLinearVelocity = dir * 58 + Vector3.new(0, 16, 0)
	box.AssemblyAngularVelocity = root.CFrame.RightVector * -16
	CombatServer = CombatServer or require(ServerScriptService:WaitForChild("Combat"):WaitForChild("CombatServer"))
	local hit, clangs, lastClang = false, 0, 0
	box.Touched:Connect(function(other)
		if other:IsDescendantOf(copy) or other:IsDescendantOf(char) then return end
		local model = other:FindFirstAncestorOfClass("Model")
		local th = model and model:FindFirstChildOfClass("Humanoid")
		if th and th.Health > 0 and not hit then
			hit = true
			local mult = CombatServer.peaceful(char, model) and 0 or CombatServer.friendlyMult(char, model)
			if mult > 0 then
				CombatServer.credit(model, char, "Helmet", "Thrown")
				th:TakeDamage(HELM_DAMAGE * mult)
				local r = model:FindFirstChild("HumanoidRootPart")
				if r then r.AssemblyLinearVelocity += dir * 14 + Vector3.new(0, 8, 0) end
			end
			clangAt(box, 0.9)
		elseif not th and os.clock() - lastClang > 0.15 and clangs < 4 and other.CanCollide then
			clangs += 1; lastClang = os.clock()
			clangAt(box, 0.75 - clangs * 0.12)
		end
	end)
	game:GetService("Debris"):AddItem(copy, 5)
	task.delay(HELM_SPARE - HELM_THROW, spare)
end

local last = {}
emote.OnServerEvent:Connect(function(plr, what, id)
	local now = os.clock()
	if now - (last[plr] or 0) < 0.4 then return end
	last[plr] = now
	if what == "Stop" then fx:FireAllClients("EmoteStop", plr); return end
	if what ~= "Play" or type(id) ~= "string" or not Catalog.EMOTE[id] then return end
	if not Profile.has(plr, "emotes", id) then return end
	local char = plr.Character
	local hum = char and char:FindFirstChildOfClass("Humanoid")
	if not (hum and hum.Health > 0) then return end
	-- not mid-swing, mid-kick, mid-dodge or behind a block
	if char:GetAttribute("Acting") or char:GetAttribute("Blocking") then fx:FireAllClients("EmoteStop", plr, id); return end
	fx:FireAllClients("Emote", plr, id, workspace:GetServerTimeNow())
	if id == "HelmetToss" then task.spawn(helmetToss, plr, char) end
end)
Players.PlayerRemoving:Connect(function(plr) last[plr] = nil end)

-- the emote wheel reads your equipped emotes from a player attribute
task.spawn(function()
	while true do
		for _, plr in ipairs(Players:GetPlayers()) do
			local p = Profile.get(plr)
			if p then
				local list = table.concat(type(p.emotes) == "table" and p.emotes or {}, ",")
				if plr:GetAttribute("Emotes") ~= list then plr:SetAttribute("Emotes", list) end
				if plr:GetAttribute("KillFx") ~= p.killfx then plr:SetAttribute("KillFx", p.killfx) end
			end
		end
		task.wait(1.5)
	end
end)
