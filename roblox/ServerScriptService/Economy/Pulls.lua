--[[ PULLS — the big moments out of crates and eggs, seen by everyone. A Mythic nobody
     hears about is a database row; one the whole game sees is a story.

       Pulls.announce(plr, rec)   after a crate opens / an egg hatches. rec = {name, rarity,
                                  variant, serial, from (the crate or egg), kind}
         Legendary or better, or a top finish (Radiant; a Spectral companion): a banner for
         everyone in this server. A Mythic, a Unique, or a top-finish Legendary: every server (MessagingService
         "Pulls"), and in the Courtyard a pillar of light rises where the player stands.
         A player whose SETTINGS › Name on big pulls is Hide shows as "Someone".
       Pulls.recent()             the last big pulls game-wide, newest first (MemoryStore
                                  "RecentPulls", kept 3 days), for the crates page
       Pulls.made(keys)           how many of each numbered thing exist {key = n} (its serial
                                  counter, Economy ▸ Collection; cached a few minutes)

     HubEvent "Pull", rec  (rec.global = from another server, rec.mine = yours) ]]

local Players = game:GetService("Players")
local MessagingService = game:GetService("MessagingService")
local MemoryStoreService = game:GetService("MemoryStoreService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Debris = game:GetService("Debris")

local Pulls = {}
local RANK = {Common = 1, Rare = 2, Epic = 3, Legendary = 4, Mythic = 5, Unique = 6}
local TOP_FINISH = {Radiant = true, Spectral = true}   -- (a skin's best finish; a companion's)
local KEEP = 3 * 86400
local TOPIC = "Pulls"

local map
pcall(function() map = MemoryStoreService:GetSortedMap("RecentPulls") end)

local function event() return ReplicatedStorage:FindFirstChild("HubEvent") end
local function isHub()
	local round = ReplicatedStorage:FindFirstChild("Round")
	return round ~= nil and round:GetAttribute("Mode") == "Hub"
end

-- how big is it: nil (no banner), "server", "global"
function Pulls.size(rarity, variant)
	local r = RANK[rarity] or 0
	if r >= RANK.Mythic or (TOP_FINISH[variant] and r >= RANK.Legendary) then return "global" end
	if r >= RANK.Legendary or TOP_FINISH[variant] then return "server" end
	return nil
end

local function fire(rec, except)
	local ev = event()
	if not ev then return end
	for _, p in ipairs(Players:GetPlayers()) do
		if p ~= except then pcall(ev.FireClient, ev, p, "Pull", rec) end
	end
end

-- the pillar: light from the ground up through the clouds, the rarity's colour, a few seconds
local function pillar(plr, color)
	local root = plr.Character and plr.Character:FindFirstChild("HumanoidRootPart")
	if not root then return end
	local h = 160
	local base = root.Position - Vector3.new(0, 3, 0)
	local beam = Instance.new("Part")
	beam.Name = "PullPillar"
	beam.Anchored, beam.CanCollide, beam.CanQuery, beam.CanTouch, beam.CastShadow = true, false, false, false, false
	beam.Material = Enum.Material.Neon
	beam.Color = color
	beam.Shape = Enum.PartType.Cylinder
	beam.Size = Vector3.new(h, 3.2, 3.2)
	beam.CFrame = CFrame.new(base + Vector3.new(0, h / 2, 0)) * CFrame.Angles(0, 0, math.rad(90))
	beam.Transparency = 0.35
	local light = Instance.new("PointLight"); light.Color = color; light.Brightness = 6; light.Range = 28; light.Parent = beam
	local ring = Instance.new("ParticleEmitter")
	ring.Color = ColorSequence.new(color)
	ring.LightEmission = 1
	ring.Size = NumberSequence.new({NumberSequenceKeypoint.new(0, 1.2), NumberSequenceKeypoint.new(1, 0)})
	ring.Transparency = NumberSequence.new({NumberSequenceKeypoint.new(0, 0.1), NumberSequenceKeypoint.new(1, 1)})
	ring.Lifetime = NumberRange.new(1.2, 2)
	ring.Speed = NumberRange.new(14, 26)
	ring.SpreadAngle = Vector2.new(25, 25)
	ring.Rate = 60
	ring.Parent = beam
	beam.Parent = workspace
	task.spawn(function()
		for i = 1, 40 do
			if not beam.Parent then return end
			beam.Transparency = 0.35 + 0.15 * math.sin(i * 0.6)
			task.wait(0.1)
		end
		ring.Enabled = false
		for i = 1, 12 do
			if not beam.Parent then return end
			beam.Transparency = 0.5 + i / 24
			beam.Size = Vector3.new(h, 3.2 * (1 - i / 14), 3.2 * (1 - i / 14))
			task.wait(0.05)
		end
	end)
	Debris:AddItem(beam, 7)
end

local RARITY_COLOR = {
	Legendary = Color3.fromRGB(255, 196, 70), Mythic = Color3.fromRGB(255, 70, 90), Unique = Color3.fromRGB(255, 240, 160),
	Epic = Color3.fromRGB(190, 110, 255), Rare = Color3.fromRGB(90, 160, 255),
}

function Pulls.announce(plr, rec)
	local size = Pulls.size(rec.rarity, rec.variant)
	if not size then return end
	local hide = plr:GetAttribute("Priv_Pulls") == "Hide"
	local out = {
		who = hide and "Someone" or plr.DisplayName, user = hide and 0 or plr.UserId,
		name = tostring(rec.name or "?"), rarity = rec.rarity, variant = rec.variant, serial = rec.serial,
		from = rec.from, kind = rec.kind, at = os.time(), size = size,
	}
	fire(out, plr)
	local ev = event()
	if ev and plr.Parent then local mine = table.clone(out); mine.mine = true; pcall(ev.FireClient, ev, plr, "Pull", mine) end
	if size == "global" then
		if isHub() then pcall(pillar, plr, RARITY_COLOR[rec.rarity] or Color3.new(1, 1, 1)) end
		task.spawn(function()
			local msg = table.clone(out); msg.job = game.JobId
			pcall(MessagingService.PublishAsync, MessagingService, TOPIC, msg)
		end)
	end
	if map then
		task.spawn(function()
			local key = string.format("%011d_%d_%04d", out.at, plr.UserId, math.random(0, 9999))
			pcall(map.SetAsync, map, key, out, KEEP)
		end)
	end
	Pulls.cache = nil
end

-- the big pulls in other servers: a banner here too
task.spawn(function()
	pcall(function()
		MessagingService:SubscribeAsync(TOPIC, function(m)
			local d = m.Data
			if type(d) ~= "table" or d.job == game.JobId then return end
			d.job = nil; d.global = true
			fire(d, nil)
			Pulls.cache = nil
		end)
	end)
end)

-- the feed (one read every 20 s at most, per server). A read that hangs never holds a
-- caller up more than a few seconds: they get what there was, and the read finishes alone.
Pulls.cache, Pulls.cacheAt = nil, 0
local reading, readAt = false, 0
function Pulls.recent()
	if Pulls.cache and os.clock() - Pulls.cacheAt < 20 then return Pulls.cache end
	if not map then return Pulls.cache or {} end
	if not reading or os.clock() - readAt > 15 then   -- (one stuck for good: try again)
		reading, readAt = true, os.clock()
		local mine = readAt
		task.spawn(function()
			local ok, items = pcall(map.GetRangeAsync, map, Enum.SortDirection.Descending, 24)
			if readAt == mine then reading = false end
			if ok and type(items) == "table" then
				local out = {}
				for _, it in ipairs(items) do if type(it.value) == "table" then table.insert(out, it.value) end end
				Pulls.cache, Pulls.cacheAt = out, os.clock()
			end
		end)
	end
	local t0 = os.clock()
	while reading and os.clock() - t0 < 3 do task.wait(0.05) end
	return Pulls.cache or {}
end

-- how many exist (numbered things only: their serial counter is the count)
local made, madeAt = {}, {}
function Pulls.made(keys)
	local Collection = require(script.Parent:WaitForChild("Collection"))
	local out = {}
	for i, key in ipairs(type(keys) == "table" and keys or {}) do
		if i > 40 then break end
		if type(key) == "string" then
			if not made[key] or os.clock() - (madeAt[key] or 0) > 240 then
				made[key], madeAt[key] = Collection.count(key), os.clock()
			end
			out[key] = made[key]
		end
	end
	return out
end

return Pulls
