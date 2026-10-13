--[[ SHOWCASE — staff stage the game for filming: real matches fought by bots on the real
     maps, the menus gone, and a director's camera flying through the action (the client's
     Showcase script). What comes out is real gameplay, the only kind Roblox allows as the
     video on the game's page; footage for ads and YouTube too.

       Showcase.KINDS            what can be staged (the admin panel's SHOWCASE tab lists them)
       Showcase.start(plr, kind, map?) -> ok, msg
       Showcase.stop(plr) -> ok, msg

     A battle (siege · battle · brawl · magic · duel):
       • the server becomes a bot match: the mode on a map (yours, or one that suits it),
         filled with bots of the showcase's own mix (more Knights and Champions than usual:
         better fights). It ends the round under way to get there.
       • the server is set up like a custom one with cheats (nobody earns anything) and no clock.
     A Courtyard showcase (courtyard · armory): back to the Hub; for armory, a line of
     mannequins in the rarest sets.
     The one filming has no body (they can't spawn while it runs, and bots have nobody to
     chase), the world streams in around their camera, and their menus are hidden.
     STOP (or Ctrl+Shift+X) gives them back their screen. The match goes on, so they can spawn
     and join it.

     Only in Studio, a custom server or a private one: a showcase takes over the whole server. ]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local ServerStorage = game:GetService("ServerStorage")
local RunService = game:GetService("RunService")

local GameConfig = require(ReplicatedStorage:WaitForChild("GameConfig"))
local Catalog = require(ReplicatedStorage:WaitForChild("Catalog"))
local Dresser = require(ReplicatedStorage:WaitForChild("Dresser"))
local Game = require(script.Parent:WaitForChild("Game"))
local BotFill = require(script.Parent:WaitForChild("BotFill"))

local Showcase = {}

-- (a better mix than a normal match's: fewer Squires, so most fights are parries and feints)
local SHOW_MIX = {{"Squire", 0.2}, {"Knight", 0.5}, {"Champion", 0.3}}

Showcase.ORDER = {"siege", "battle", "brawl", "magic", "duel", "courtyard", "armory"}
Showcase.KINDS = {
	siege     = {label = "SIEGE ASSAULT",    mode = "Siege", bots = 24, shots = "battle",
		about = "Two armies of bots storm a castle: the ram, the walls, the keep."},
	battle    = {label = "FIELD BATTLE",     mode = "TDM",   bots = 24, shots = "battle",
		about = "Team Deathmatch on an open field: a big brawl of blades."},
	brawl     = {label = "FREE FOR ALL",     mode = "FFA",   bots = 12, shots = "battle",
		about = "Every bot for itself."},
	magic     = {label = "BOWS & SPELLS",    mode = "TDM",   bots = 16, shots = "battle", prefer = "class",
		classMix = {{false, 0.4}, {"Archer", 0.3}, {"Mage", 0.3}},
		about = "Archers and Mages among the swords; the camera favours them."},
	duel      = {label = "CHAMPION DUEL",    mode = "FFA",   bots = 2, shots = "duel", mix = {{"Champion", 1}},
		maps = {"Colosseum", "Moonring", "RoseCourt", "Sandpit"},
		about = "Two Champions, one arena: parries, feints, ripostes up close."},
	courtyard = {label = "COURTYARD TOUR",   mode = "Hub",   shots = "tour",
		about = "A slow flight round the Courtyard: the gates, the stall, the fountain, the inn."},
	armory    = {label = "ARMOR PARADE",     mode = "Hub",   shots = "parade",
		about = "The rarest armor sets on a line of mannequins, one by one."},
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

local state = {by = nil, kind = nil, saved = nil, focus = nil, stuff = {}}

local function allowed()
	local sv = Game.server
	return RunService:IsStudio() or sv.custom or sv.access ~= "Public"
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

local function pickMap(k, map)
	local def = GameConfig.MODES[k.mode]
	local pool = {}
	for _, m in ipairs(k.maps or (def and def.maps) or {}) do
		if Game.MapLoader.exists(m) and (not def or table.find(def.maps or {}, m)) then table.insert(pool, m) end
	end
	if map and table.find(pool, map) then return map end
	return pool[1] and pool[math.random(#pool)] or nil
end

-- the round under way ends now and the next is this mode on this map
local function switchTo(modeId, map)
	Game.node:SetAttribute("NextMode", modeId)
	Game.adminNextMap = map
	if Game.node:GetAttribute("State") == "Round" then Game.adminEnd = "A SHOWCASE IS STARTING" end
end

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

-- ARMOR PARADE: mannequins in a row across the Courtyard's plaza, all facing the same way
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
		for slot, suffix in pairs({helmet = "Helm", top = "Top", bottom = "Legs"}) do
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

function Showcase.start(plr, kindId, map)
	local k = Showcase.KINDS[kindId]
	if not k then return false, "no such showcase" end
	if not allowed() then return false, "showcases take over the whole server: run them in Studio, or in a custom or private server of yours" end
	if state.by and state.by ~= plr and state.by.Parent then return false, state.by.Name .. " is filming a showcase here" end
	clearStuff()
	save()
	state.by, state.kind = plr, kindId
	local sv = Game.server
	local info = {kind = kindId, label = k.label, shots = k.shots, prefer = k.prefer}
	if k.mode == "Hub" then
		sv.door, sv.custom, sv.settings, sv.noRewards = "Courtyard", false, nil, false
		BotFill.override = nil
		if Game.modeId ~= "Hub" then switchTo("Hub", "Courtyard") end
	else
		local def = GameConfig.MODES[k.mode]
		map = pickMap(k, map)
		if not (def and map) then return false, "no map for " .. k.mode .. " in this place" end
		-- a custom server with cheats: bots fill it, nobody earns, and the round never runs out
		local st = {}
		for key, v in pairs(GameConfig.CUSTOM_DEFAULTS) do st[key] = v end
		st.mode, st.map, st.bots, st.botCount, st.botSkill = k.mode, map, true, k.bots, "Mixed"
		st.roundLength, st.respawns, st.friendlyFire, st.cheats, st.limit = 0, true, false, true, 24
		sv.door, sv.custom, sv.settings, sv.noRewards = "Warfront", true, st, true
		BotFill.override = {mix = k.mix or SHOW_MIX, classMix = k.classMix}
		switchTo(k.mode, map)
		info.map = map
	end
	takeBody(plr)
	remote:FireClient(plr, "Start", info)
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
	return true, k.label .. (info.map and ("  ·  " .. GameConfig.mapTitle(info.map)) or "") .. "  ·  Ctrl+Shift+X or STOP to end"
end

function Showcase.stop(plr)
	local who = state.by
	if not who then return false, "no showcase running" end
	clearStuff()
	BotFill.override = nil
	restore()
	if who.Parent then
		who:SetAttribute("Showcase", nil)
		who.ReplicationFocus = nil
		remote:FireClient(who, "Stop")
	end
	if state.focus then state.focus:Destroy(); state.focus = nil end
	state.by, state.kind = nil, nil
	return true, "showcase over: the match goes on (spawn to join it)"
end

-- the camera reports where it is: the world streams in round it
remote.OnServerEvent:Connect(function(plr, what, pos)
	if plr ~= state.by then return end
	if what == "Cam" and typeof(pos) == "Vector3" and state.focus and pos.Magnitude < 1e5 then
		state.focus.Position = pos
	elseif what == "Stop" then
		Showcase.stop(plr)
	end
end)
Players.PlayerRemoving:Connect(function(plr) if plr == state.by then Showcase.stop(plr) end end)

return Showcase
