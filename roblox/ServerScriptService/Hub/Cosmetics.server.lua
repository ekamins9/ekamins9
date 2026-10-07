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
