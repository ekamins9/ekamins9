--[[ SHOWCASE — staff stage the game for filming: real matches fought by bots on the real
     maps, the menus gone, and a director's camera flying through the action (the client's
     Showcase script). What comes out is real gameplay, the only kind Roblox allows as the
     video on the game's page; footage for ads and YouTube too.

       Showcase.KINDS / ORDER    what can be staged (the DIRECTOR menu lists them)
       Showcase.start(plr, kind, map?, opts?) -> ok, msg
           opts (CUSTOM BATTLE): mode, roster = {Squire, Knight, Champion, Archer, Mage},
           real (bots dressed like players: default on); (GENERATE): segment (seconds)
       Showcase.stop(plr) -> ok, msg

     THE KINDS:
       • GENERATE: an autopilot. A new battle every few minutes from PLAYLIST (sieges,
         shield walls, bows and spells, champions' clashes, king of the hill, duels…), each
         on a different map, never the same twice running; the camera picks its own angles.
       • CUSTOM BATTLE: your mode, your map (or ANY), exactly how many of each kind of bot.
       • The presets (siege · battle · brawl · magic · duel): a mode and a roster of their own.
       • The Courtyard tour and the armor parade.
     A battle turns the server into a bot match set up like a custom server with cheats
     (nobody earns anything), the break between rounds cut to a few seconds. A map picked
     stays (no clock); ANY brings a new map every ROUND seconds.

     BOTS THAT LOOK LIKE PLAYERS (on unless turned off): each bot comes in dressed like someone
     who's played a while: an armor set of its weight (the rarer, the less often), its colours,
     a skin on its weapon, a kill effect that plays on whoever it brings down, and now and
     then an emote over them. Name tags hide while filming (NameTags), so nothing gives them away.

     The one filming has no body (they can't spawn while it runs, and bots have nobody to
     chase), the world streams in around their camera, and their menus are hidden. STOP gives
     them back their screen; the match goes on, so they can spawn and join it.

     Where it runs:
       • Studio, or a custom / private server of yours: right there (it takes the server over).
       • A battle from a public server: a locked server of your own is opened for it
         (HubServer), you're taken there, and it starts by itself as you arrive
         (Game.server.showcase, from the trip's TeleportData).
       • The Courtyard tour and the armor parade: in the Courtyard as it is.
     The menu asks ShowcaseInfo what can be filmed and where; starting goes through the admin
     panel's "showcase" action (its permission). While it runs the filmer's client asks over
     ShowcaseRemote: "NextMap" (GENERATE: the next battle), "Map" (one to stay on, or "" to
     rotate), "Stop", "Cam". ]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local RunService = game:GetService("RunService")

local GameConfig = require(ReplicatedStorage:WaitForChild("GameConfig"))
local Catalog = require(ReplicatedStorage:WaitForChild("Catalog"))
local Dresser = require(ReplicatedStorage:WaitForChild("Dresser"))
local Game = require(script.Parent:WaitForChild("Game"))
local BotFill = require(script.Parent:WaitForChild("BotFill"))

local Showcase = {}

local ROUND = 4 * 60       -- a battle on ANY map: each round this long, then the next map
local BREAK = 4            -- seconds between rounds while filming (a match's is 15)
local MAX_BOTS = 40
local DUEL_MAPS = {"Colosseum", "Moonring", "RoseCourt", "Sandpit"}

Showcase.ORDER = {"generate", "custom", "siege", "battle", "brawl", "magic", "duel", "courtyard", "armory"}
Showcase.KINDS = {
	generate  = {label = "GENERATE  ·  AUTOPILOT", generate = true, shots = "battle",
		about = "Sit back: a new battle every few minutes on a new map (sieges, shield walls, spells, duels…), the camera choosing its own angles."},
	custom    = {label = "CUSTOM BATTLE", custom = true, shots = "battle",
		about = "Your mode, your map, and exactly how many Squires, Knights, Champions, Archers and Mages."},
	siege     = {label = "SIEGE ASSAULT",    mode = "Siege", shots = "battle", roster = {Squire = 6, Knight = 10, Champion = 4, Archer = 2, Mage = 2},
		about = "Two armies storm a castle: the ram, the walls, the keep."},
	battle    = {label = "FIELD BATTLE",     mode = "TDM",   shots = "battle", roster = {Squire = 6, Knight = 10, Champion = 6, Archer = 1, Mage = 1},
		about = "Team Deathmatch on an open field: a big brawl of blades."},
	brawl     = {label = "FREE FOR ALL",     mode = "FFA",   shots = "battle", roster = {Squire = 2, Knight = 5, Champion = 4, Archer = 1},
		about = "Every fighter for themselves."},
	magic     = {label = "BOWS & SPELLS",    mode = "TDM",   shots = "battle", prefer = "class", roster = {Knight = 4, Champion = 2, Archer = 5, Mage = 5},
		about = "Archers and Mages among the swords; the camera favours them."},
	duel      = {label = "CHAMPION DUEL",    mode = "FFA",   shots = "duel", roster = {Champion = 2}, maps = DUEL_MAPS,
		about = "Two Champions, one arena: parries, feints, ripostes up close."},
	courtyard = {label = "COURTYARD TOUR",   mode = "Hub",   shots = "tour",
		about = "A slow flight round the Courtyard: the gates, the stall, the fountain, the inn."},
	armory    = {label = "ARMOR PARADE",     mode = "Hub",   shots = "parade",
		about = "The rarest armor sets on a line of mannequins, one by one."},
}
-- what a CUSTOM BATTLE can be (the modes bots fight)
Showcase.MODES = {"TDM", "Siege", "KOTH", "LTS", "FFA"}
Showcase.KINDS_OF_BOT = {"Squire", "Knight", "Champion", "Archer", "Mage"}
-- GENERATE's playlist
Showcase.PLAYLIST = {
	{label = "SIEGE ASSAULT",       mode = "Siege", roster = {Squire = 6, Knight = 10, Champion = 4, Archer = 2, Mage = 2}},
	{label = "SHIELD WALL",         mode = "TDM",   roster = {Knight = 14, Champion = 6}},
	{label = "BOWS & SPELLS",       mode = "TDM",   roster = {Knight = 4, Champion = 2, Archer = 5, Mage = 5}, prefer = "class"},
	{label = "CHAMPIONS' CLASH",    mode = "TDM",   roster = {Champion = 12}},
	{label = "KING OF THE HILL",    mode = "KOTH",  roster = {Squire = 4, Knight = 8, Champion = 4, Archer = 2, Mage = 2}},
	{label = "LAST TEAM STANDING",  mode = "LTS",   roster = {Knight = 6, Champion = 4, Mage = 2}},
	{label = "FREE FOR ALL",        mode = "FFA",   roster = {Knight = 5, Champion = 3, Archer = 1, Mage = 1}},
	{label = "CHAMPION DUEL",       mode = "FFA",   roster = {Champion = 2}, maps = DUEL_MAPS, shots = "duel", short = true},
	{label = "MAGES AT WAR",        mode = "TDM",   roster = {Mage = 8, Knight = 4}, prefer = "class"},
	{label = "THE LEVY",            mode = "TDM",   roster = {Squire = 16, Knight = 4}},
}
-- the armor parade, rarest first (sets that aren't in this place are skipped)
local PARADE = {"Phoenix", "StarSage", "Obsidian", "Seraph", "Dragonscale", "Lionheart", "SunKnights", "Moonshadow",
	"Archmage", "WolfCompany", "Deathless", "Frostwarden"}
local PARADE_COLORS = {Primary = "Crimson", Secondary = "Slate", Accent = "Ochre", Metal = "Ash"}

local remote = ReplicatedStorage:FindFirstChild("ShowcaseRemote")
if not remote then
	remote = Instance.new("RemoteEvent")
	remote.Name = "ShowcaseRemote"
	remote.Parent = ReplicatedStorage
end

-- by: the filmer · kind · mode / only (the battle's mode, and the maps it keeps to) · fixed (the
-- map stays) · roster · real · label / shots / prefer (what the camera's told) · gen (GENERATE)
local state = {by = nil, kind = nil, saved = nil, focus = nil, stuff = {}}

--------------------------------------------------------------------
--  MAPS AND SETTINGS
--------------------------------------------------------------------
-- the maps a battle can be on (its own list, else its mode's; only those in this place)
local function poolFor(mode, only)
	local def = GameConfig.MODES[mode or ""]
	local pool = {}
	for _, m in ipairs(only or (def and def.maps) or {}) do
		if Game.MapLoader.exists(m) and def and table.find(def.maps or {}, m) then table.insert(pool, m) end
	end
	return pool
end
local function pickMap(mode, only, map)
	local pool = poolFor(mode, only)
	if map and table.find(pool, map) then return map end
	return pool[1] and pool[math.random(#pool)] or nil
end
-- another map than the ones just played (the footage wants every map)
local recent = {}   -- the last few maps, newest last
Game.roundStarted.Event:Connect(function(_, map)
	if recent[#recent] ~= map then table.insert(recent, map) end
	while #recent > 4 do table.remove(recent, 1) end
end)
local function otherMap(mode, only)
	local pool, now = poolFor(mode, only), Game.node:GetAttribute("Map")
	local fresh, others = {}, {}
	for _, m in ipairs(pool) do
		if m ~= now then
			table.insert(others, m)
			if not table.find(recent, m) then table.insert(fresh, m) end
		end
	end
	local list = #fresh > 0 and fresh or others
	return list[1] and list[math.random(#list)] or pool[1]
end
local function mapsOf(mode, only)
	local out = {}
	for _, m in ipairs(poolFor(mode, only)) do table.insert(out, {id = m, title = GameConfig.mapTitle(m)}) end
	return out
end

-- a roster from the menu: whole numbers, 0-20 a kind, 40 at most, at least one
local function cleanRoster(r)
	if type(r) ~= "table" then return nil end
	local out, total = {}, 0
	for _, k in ipairs(Showcase.KINDS_OF_BOT) do
		local n = math.clamp(math.floor(tonumber(r[k]) or 0), 0, 20)
		n = math.min(n, MAX_BOTS - total)
		out[k], total = n, total + n
	end
	return total > 0 and out or nil
end
local function rosterTotal(r) local n = 0; for _, k in ipairs(Showcase.KINDS_OF_BOT) do n += r[k] or 0 end; return n end

-- a battle's server settings: a custom server with cheats (bots fill it, nobody earns); a map
-- picked stays (no clock), ANY rotates every ROUND
local function settingsFor(mode, roster, map, fixed)
	local st = {}
	for key, v in pairs(GameConfig.CUSTOM_DEFAULTS) do st[key] = v end
	st.mode, st.map, st.bots, st.botCount, st.botSkill = mode, fixed and map or "", true, rosterTotal(roster), "Mixed"
	st.roundLength, st.respawns, st.friendlyFire, st.cheats, st.limit = fixed and 0 or ROUND, true, false, true, MAX_BOTS
	return st
end

--------------------------------------------------------------------
--  BOTS THAT LOOK LIKE PLAYERS
--------------------------------------------------------------------
local RARITY_W = {Common = 3, Rare = 4, Epic = 3, Legendary = 1.6, Mythic = 0.6}
local SLOT_SUFFIX = {helmet = "Helm", top = "Top", bottom = "Legs"}
local function weighted(list)
	local total = 0
	for _, x in ipairs(list) do total += RARITY_W[x.rarity] or 1 end
	local r = math.random() * total
	for _, x in ipairs(list) do r -= RARITY_W[x.rarity] or 1; if r <= 0 then return x end end
	return list[#list]
end
local SETS, SKINS, KILLFX, EMOTES = {}, {}, {}, {}
for _, p in ipairs(Catalog.PIECES or {}) do
	if p.set and p.slot == "top" and RARITY_W[p.rarity] then
		SETS[p.weight] = SETS[p.weight] or {}
		table.insert(SETS[p.weight], {set = p.set, rarity = p.rarity})
	end
end
for _, s in ipairs(Catalog.SKINS or {}) do
	if s.weapon and RARITY_W[s.rarity] and not s.unique and s.name ~= "Default" then
		SKINS[s.weapon] = SKINS[s.weapon] or {}
		table.insert(SKINS[s.weapon], {id = s.id or (s.weapon .. ":" .. s.name), rarity = s.rarity})
	end
end
for _, f in ipairs(Catalog.KILLFX or {}) do if RARITY_W[f.rarity] and not f.beta then table.insert(KILLFX, {id = f.id, rarity = f.rarity}) end end
for _, e in ipairs(Catalog.EMOTES or {}) do if e.id ~= "HelmetToss" then table.insert(EMOTES, e.id) end end
local PALETTE = {}
for _, c in ipairs(Catalog.PALETTE or {}) do table.insert(PALETTE, c.name) end
local function colour() return PALETTE[math.random(#PALETTE)] end

local botSkills
local function skillOf(name)
	botSkills = botSkills or require(ServerScriptService:WaitForChild("Combat"):WaitForChild("Bots")).SKILLS
	return botSkills[name or "Knight"]
end

-- each bot as it comes in (BotFill's dress hook)
local function dress(opts)
	local cls = opts.class and GameConfig.CLASSES[opts.class]
	local sk = skillOf(opts.skill)
	local weight = (cls and cls.weight) or (sk and sk.weight) or "Medium"
	-- (an Archer's or a Mage's weapon named here, so it can wear a skin)
	if cls and not opts.weapon then opts.weapon = cls.magic and "Staff" or (math.random() < 0.75 and "Bow" or "Crossbow") end
	local sets = SETS[weight] or {}
	if #sets > 0 and math.random() < 0.85 then
		local s = weighted(sets)
		local lo = {colors = {Primary = colour(), Secondary = colour(), Accent = colour(), Metal = colour()}}
		for slot, suffix in pairs(SLOT_SUFFIX) do
			local p = Catalog.PIECE[s.set .. "_" .. suffix]
			if not (p and p.weight == weight) then p = Catalog.defaultPiece(slot, weight) end
			lo[slot] = p and p.id or nil
		end
		opts.loadout = lo
	end
	local skins = opts.weapon and SKINS[opts.weapon] or {}
	if #skins > 0 and math.random() < 0.75 then opts.skin = weighted(skins).id end
	opts.attrs = {KillFx = (#KILLFX > 0 and math.random() < 0.75) and weighted(KILLFX).id or nil}
end
-- one bot brought another down (BotFill's onKill hook): its kill effect, now and then an emote
local function onKill(killer, victim)
	local id = killer:GetAttribute("KillFx")
	if id and _G.KillFxPlay then task.spawn(_G.KillFxPlay, id, victim) end
	if #EMOTES > 0 and math.random() < 0.3 and _G.BotEmote then
		task.delay(0.6, function() if killer.Parent then _G.BotEmote(killer, EMOTES[math.random(#EMOTES)]) end end)
	end
end

--------------------------------------------------------------------
--  STAGING
--------------------------------------------------------------------
-- where a showcase of this kind can run: "here", "travel" (a filming server of their own), or nil
local function placeFor(k)
	local sv = Game.server
	if RunService:IsStudio() or sv.custom or sv.access ~= "Public" then return "here" end
	if k.mode == "Hub" then
		if Game.modeId == "Hub" then return "here" end
		return nil, "film the Courtyard from the Courtyard: go back there first (PLAY › COURTYARD)"
	end
	return "travel"
end

local function clearStuff()
	for _, i in ipairs(state.stuff) do if i.Parent then i:Destroy() end end
	state.stuff = {}
end

-- the server's own settings, kept the first time a showcase changes them
local function save()
	if state.saved then return end
	local sv = Game.server
	state.saved = {door = sv.door, custom = sv.custom, settings = sv.settings, noRewards = sv.noRewards}
end
local function restore()
	local s = state.saved
	if not s then return end
	local sv = Game.server
	sv.door, sv.custom, sv.settings, sv.noRewards = s.door, s.custom, s.settings, s.noRewards
	state.saved = nil
end

-- the round under way ends now and the next is this mode on this map
local function switchTo(modeId, map, why)
	Game.node:SetAttribute("NextMode", modeId)
	Game.adminNextMap = map
	if Game.node:GetAttribute("State") == "Round" then Game.adminEnd = why or "A SHOWCASE IS STARTING" end
end

-- a battle: the server set up for it, its bots, and there (a new round) unless it's on already
local function stageBattle(mode, map, fixed, roster)
	local sv = Game.server
	sv.door, sv.custom, sv.settings, sv.noRewards = "Warfront", true, settingsFor(mode, roster, map, fixed), true
	BotFill.override = {roster = roster, dress = state.real ~= false and dress or nil, onKill = state.real ~= false and onKill or nil}
	Game.intermissionOverride = BREAK
	if not (Game.modeId == mode and Game.node:GetAttribute("Map") == map) then
		switchTo(mode, map, "NEXT: " .. string.upper(GameConfig.MODES[mode].name) .. "  ·  " .. string.upper(GameConfig.mapTitle(map)))
	end
end

-- what the filmer's controls show
local function infoFor()
	local k = Showcase.KINDS[state.kind or ""] or {}
	return {kind = state.kind, label = state.label or k.label, shots = state.shots or k.shots, prefer = state.prefer,
		maps = state.mode and mapsOf(state.mode, state.only) or {}, fixed = state.fixed == true, battle = state.mode ~= nil,
		rotate = ROUND, generate = state.gen ~= nil}
end
local function tell() if state.by and state.by.Parent then remote:FireClient(state.by, "Info", infoFor()) end end

-- the one filming: no body, the world streamed in round their camera
local function takeBody(plr)
	plr:SetAttribute("Showcase", state.kind)
	if plr.Character then plr.Character:Destroy() end
	if not state.focus then
		local f = Instance.new("Part")
		f.Name = "ShowcaseFocus"
		f.Anchored, f.CanCollide, f.CanQuery, f.CanTouch, f.Transparency = true, false, false, false, 1
		f.Size = Vector3.one
		f.Position = Vector3.new(0, 20, 0)
		f.Parent = workspace
		state.focus = f
	end
	plr.ReplicationFocus = state.focus
end

--------------------------------------------------------------------
--  GENERATE: the autopilot
--------------------------------------------------------------------
local function segmentNext()
	local g = state.gen
	if not g then return end
	local choices = {}
	for i, seg in ipairs(Showcase.PLAYLIST) do
		if i ~= g.last and GameConfig.MODES[seg.mode] and #poolFor(seg.mode, seg.maps) > 0 then table.insert(choices, i) end
	end
	if #choices == 0 then return end
	local i = choices[math.random(#choices)]
	local seg = Showcase.PLAYLIST[i]
	g.last = i
	local map = otherMap(seg.mode, seg.maps)
	state.mode, state.only, state.roster, state.fixed = seg.mode, seg.maps, seg.roster, true
	state.label, state.shots, state.prefer = "GENERATE  ·  " .. seg.label, seg.shots or "battle", seg.prefer
	stageBattle(seg.mode, map, true, seg.roster)
	g.untilAt = os.clock() + (seg.short and g.len * 0.6 or g.len) + BREAK + 3
	tell()
end
local function generate(len)
	local g = {len = math.clamp(tonumber(len) or 180, 60, 600), last = nil, untilAt = 0}
	state.gen = g
	segmentNext()
	task.spawn(function()
		while state.gen == g do
			task.wait(1)
			if state.gen == g and os.clock() > g.untilAt then segmentNext() end
		end
	end)
end

--------------------------------------------------------------------
--  ARMOR PARADE: mannequins in a row across the Courtyard's plaza, all facing the same way
--------------------------------------------------------------------
local function settle(model)
	for _ = 1, 5 do
		for _, w in ipairs(model:GetDescendants()) do
			if (w:IsA("Weld") or w:IsA("Motor6D")) and w.Part0 and w.Part1 and w.Part0 ~= w.Part1 then
				w.Part1.CFrame = w.Part0.CFrame * w.C0 * w.C1:Inverse()
			end
		end
	end
	for _, d in ipairs(model:GetDescendants()) do if d:IsA("BasePart") then d.Anchored = true end end
end
local function parade()
	local R6 = require(ServerScriptService:WaitForChild("Combat"):WaitForChild("R6"))
	local map = Game.MapLoader.current
	local centre = map and map:GetAttribute("Centre") or Vector3.zero
	local sets = {}
	for _, set in ipairs(PARADE) do
		local top = Catalog.PIECE[set .. "_Top"]
		if top then table.insert(sets, set) end
	end
	local n = #sets
	local gap = 4.2
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Include
	params.FilterDescendantsInstances = {map}
	local list = {}
	for i, set in ipairs(sets) do
		local x = (i - (n + 1) / 2) * gap
		local at = Vector3.new(centre.X + x, centre.Y + 40, centre.Z + 18)
		local hit = workspace:Raycast(at, Vector3.new(0, -120, 0), params)
		local floor = hit and hit.Position.Y or centre.Y
		local cf = CFrame.lookAt(Vector3.new(at.X, floor + 3, at.Z), Vector3.new(at.X, floor + 3, at.Z - 10))
		local top = Catalog.PIECE[set .. "_Top"]
		local lo = {colors = top.colors and {} or PARADE_COLORS}
		for slot, suffix in pairs(SLOT_SUFFIX) do
			local p = Catalog.PIECE[set .. "_" .. suffix]
			lo[slot] = p and p.id or nil
		end
		local m = R6.rig("Mannequin_" .. set, {anchored = true})
		m:PivotTo(cf)
		pcall(Dresser.dress, m, {loadout = lo, appearance = Catalog.BODY.defaults, weight = top.weight, preview = true})
		settle(m)
		for _, d in ipairs(m:GetDescendants()) do if d:IsA("BasePart") then d.CanCollide, d.CanQuery = false, false end end
		local hum = m:FindFirstChildOfClass("Humanoid")
		if hum then hum.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None end
		m:SetAttribute("Mannequin", i)
		m:SetAttribute("TagName", top.setName or set)
		m:SetAttribute("TagTitle", string.upper(top.rarity or ""))
		m.Parent = workspace
		table.insert(state.stuff, m)
		table.insert(list, {pos = cf.Position, look = cf.LookVector, name = top.setName or set, rarity = top.rarity})
	end
	return list
end

--------------------------------------------------------------------
--  START / STOP
--------------------------------------------------------------------
-- what a kind fights: mode, the maps it keeps to, roster (CUSTOM: the menu's)
local function planOf(k, opts)
	opts = type(opts) == "table" and opts or {}
	if k.custom then
		local mode = table.find(Showcase.MODES, opts.mode) and opts.mode or "TDM"
		return mode, nil, cleanRoster(opts.roster) or {Knight = 8, Champion = 4, Squire = 4}
	end
	return k.mode, k.maps, k.roster
end

function Showcase.start(plr, kindId, map, opts)
	local k = Showcase.KINDS[kindId]
	if not k then return false, "no such showcase" end
	opts = type(opts) == "table" and opts or {}
	local place, why = placeFor(k)
	if not place then return false, why end
	if place == "travel" then
		-- a public server: a locked one of their own, the showcase starting as they arrive
		if not _G.HubReserveShowcase then return false, "a filming server can't be opened from here" end
		local mode, only, roster = planOf(k, opts)
		if k.generate then mode, only, roster = "TDM", nil, Showcase.PLAYLIST[2].roster end
		local fixed = map ~= nil and table.find(poolFor(mode, only), map) ~= nil
		local first = pickMap(mode, only, map)
		if not first then return false, "no map for that in this place" end
		local carry = {mode = opts.mode, roster = cleanRoster(opts.roster), real = opts.real ~= false, segment = tonumber(opts.segment)}
		local ok, msg = _G.HubReserveShowcase(plr, mode, settingsFor(mode, roster, first, fixed),
			{kind = kindId, map = fixed and map or "", by = plr.UserId, opts = carry})
		return ok, ok and "opening a filming server just for you: it starts by itself when you arrive" or msg
	end
	if state.by and state.by ~= plr and state.by.Parent then return false, state.by.Name .. " is filming a showcase here" end
	clearStuff()
	save()
	state.by, state.kind, state.gen = plr, kindId, nil
	state.real = opts.real ~= false
	state.label, state.shots, state.prefer = k.label, k.shots, k.prefer
	local sv = Game.server
	if k.mode == "Hub" then
		sv.door, sv.custom, sv.settings, sv.noRewards = "Courtyard", false, nil, false
		BotFill.override = nil
		Game.intermissionOverride = nil
		state.mode, state.only, state.fixed = nil, nil, true
		if Game.modeId ~= "Hub" then switchTo("Hub", "Courtyard") end
	elseif k.generate then
		generate(opts.segment)
	else
		local mode, only, roster = planOf(k, opts)
		if k.custom then state.label = "CUSTOM  ·  " .. string.upper(GameConfig.MODES[mode].name) end
		local fixed = map ~= nil and table.find(poolFor(mode, only), map) ~= nil
		local first = pickMap(mode, only, map)
		if not first then return false, "no map for " .. mode .. " in this place" end
		state.mode, state.only, state.roster, state.fixed = mode, only, roster, fixed
		stageBattle(mode, first, fixed, roster)
	end
	takeBody(plr)
	remote:FireClient(plr, "Start", infoFor())
	-- the parade waits for the Courtyard to be the map
	if kindId == "armory" then
		task.spawn(function()
			local t0 = os.clock()
			while os.clock() - t0 < 40 and not (Game.modeId == "Hub" and Game.MapLoader.name == "Courtyard"
				and Game.node:GetAttribute("State") == "Round") do task.wait(0.5) end
			if state.kind ~= "armory" then return end
			task.wait(1.5)
			local list = parade()
			if state.by == plr and plr.Parent then remote:FireClient(plr, "Parade", list) end
		end)
	end
	return true, (state.label or k.label) .. "  ·  TAB for the controls"
end

-- N while filming: GENERATE's next battle, or the round ends and the next is on another map
-- (a picked map moves too)
function Showcase.nextMap(plr)
	if plr ~= state.by or not state.mode then return false end
	if state.gen then segmentNext(); return true end
	local m = otherMap(state.mode, state.only)
	if not m then return false end
	if state.fixed and Game.server.settings then Game.server.settings.map = m end
	Game.adminNextMap = m
	if Game.node:GetAttribute("State") == "Round" then Game.adminEnd = "NEXT: " .. string.upper(GameConfig.mapTitle(m)) end
	return true
end

-- the filmer picks a map: there now, and it stays ("" = back to a new map every few minutes).
-- (GENERATE: picking one takes over from the autopilot, on this battle)
function Showcase.setMap(plr, m)
	if plr ~= state.by or not state.mode then return false end
	state.gen = nil
	local st = Game.server.settings
	if m == "" then
		state.fixed = false
		if st then st.map, st.roundLength = "", ROUND end
	else
		if not table.find(poolFor(state.mode, state.only), m) then return false end
		state.fixed = true
		if st then st.map, st.roundLength = m, 0 end
		if Game.node:GetAttribute("Map") ~= m then
			Game.adminNextMap = m
			if Game.node:GetAttribute("State") == "Round" then Game.adminEnd = "NEXT: " .. string.upper(GameConfig.mapTitle(m)) end
		end
	end
	tell()
	return true
end

-- a battle on ANY map: every round's end, the next is on another map (unless one's already
-- picked: the showcase's first, or N's)
Game.roundEnded.Event:Connect(function()
	if state.by and state.mode and not state.fixed and not state.gen and not Game.adminNextMap then
		Game.adminNextMap = otherMap(state.mode, state.only)
	end
end)

function Showcase.stop(plr)
	local who = state.by
	if not who then return false, "no showcase running" end
	clearStuff()
	BotFill.override = nil
	Game.intermissionOverride = nil
	restore()
	if who.Parent then
		who:SetAttribute("Showcase", nil)
		who.ReplicationFocus = nil
		remote:FireClient(who, "Stop")
	end
	if state.focus then state.focus:Destroy(); state.focus = nil end
	state.by, state.kind, state.fixed, state.gen, state.mode, state.only, state.roster = nil, nil, nil, nil, nil, nil, nil
	-- (their spawn screen, held back while they filmed)
	if who.Parent and _G.ShowSpawnScreen then task.defer(_G.ShowSpawnScreen, who) end
	return true, "showcase over: the match goes on (spawn to join it)"
end

-- the camera reports where it is: the world streams in round it
local lastNext = 0
remote.OnServerEvent:Connect(function(plr, what, pos)
	if plr ~= state.by then return end
	if what == "Cam" and typeof(pos) == "Vector3" and state.focus and pos.Magnitude < 1e5 then
		state.focus.Position = pos
	elseif what == "Stop" then
		Showcase.stop(plr)
	elseif what == "NextMap" and os.clock() - lastNext > 3 then
		lastNext = os.clock()
		Showcase.nextMap(plr)
	elseif what == "Map" and type(pos) == "string" and os.clock() - lastNext > 3 then
		lastNext = os.clock()
		Showcase.setMap(plr, pos)
	end
end)
Players.PlayerRemoving:Connect(function(plr) if plr == state.by then Showcase.stop(plr) end end)

-- THE MENU's question: what can be filmed, on which maps, and where it would run
local infoFn = ReplicatedStorage:FindFirstChild("ShowcaseInfo")
if not infoFn then
	infoFn = Instance.new("RemoteFunction")
	infoFn.Name = "ShowcaseInfo"
	infoFn.Parent = ReplicatedStorage
end
infoFn.OnServerInvoke = function(plr)
	local kinds = {}
	for _, id in ipairs(Showcase.ORDER) do
		local k = Showcase.KINDS[id]
		local maps
		if k.mode == "Hub" then maps = {{id = "Courtyard", title = GameConfig.mapTitle("Courtyard")}}
		elseif k.mode then maps = mapsOf(k.mode, k.maps) end
		table.insert(kinds, {id = id, label = k.label, about = k.about, maps = maps or {}, battle = k.mode ~= "Hub",
			custom = k.custom == true, generate = k.generate == true, place = placeFor(k) or "no", roster = k.roster})
	end
	local modes = {}
	for _, m in ipairs(Showcase.MODES) do
		local def = GameConfig.MODES[m]
		if def and #poolFor(m) > 0 then table.insert(modes, {id = m, name = def.name, maps = mapsOf(m)}) end
	end
	local playlist = {}
	for _, seg in ipairs(Showcase.PLAYLIST) do table.insert(playlist, seg.label) end
	return {kinds = kinds, modes = modes, playlist = playlist, botKinds = Showcase.KINDS_OF_BOT, maxBots = MAX_BOTS,
		running = state.by == plr and state.kind or nil, rotate = ROUND}
end

-- A FILMING SERVER (opened by Showcase.start from a public server): its showcase starts as the
-- one who opened it arrives (nobody else can join it)
local function arrived(plr)
	local s = Game.identify(plr).showcase
	if type(s) ~= "table" or tonumber(s.by) ~= plr.UserId or not Showcase.KINDS[s.kind] then return end
	task.delay(4, function()
		if plr.Parent and not state.by then Showcase.start(plr, s.kind, (s.map ~= "" and s.map) or nil, s.opts) end
	end)
end
Players.PlayerAdded:Connect(arrived)
for _, plr in ipairs(Players:GetPlayers()) do task.spawn(arrived, plr) end

return Showcase
