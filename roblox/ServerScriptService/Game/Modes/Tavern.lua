--[[ TAVERN — the dungeon game's own world (GameConfig.MODES.Tavern, DOORS.Tavern): The Gilded Rat,
     an adventurers' lodge at the top of the stairs to the dark (Game ▸ TavernMap, built fresh
     when its server starts). Its servers are its own, like the Courtyard's: you come here from the
     Courtyard's PLAY ▸ ADVENTURES (Deadvault, The Depths), you come back here out of a raid, and
     you leave by its door for the Courtyard.

     You walk in as your class (no fighting here). The dungeon game's lobby (DungeonMenu.client) is
     its menu (M), and its places open it where you stand:
       the merchants (Hrothgar the Smith at his forge, Old Brenna among her armour, Wendel the
       Alchemist by his cauldron, the Treasurer at the counter): TRADE → MERCHANTS
       your stash's chest: STASH · the notice board: CLASS (and perks)
       the Dungeon Gate: PLAY (your party, the dungeon, READY) · the door home: the Courtyard ]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local Catalog = require(ReplicatedStorage:WaitForChild("Catalog"))
local Dresser = require(ReplicatedStorage:WaitForChild("Dresser"))
local Game = require(script.Parent.Parent:WaitForChild("Game"))
local TavernMap = require(script.Parent.Parent:WaitForChild("TavernMap"))
local Dungeon = require(script.Parent.Parent:WaitForChild("Dungeon"))
local R6 = require(ServerScriptService:WaitForChild("Combat"):WaitForChild("R6"))
local MapLoader = Game.MapLoader
local node = Game.node

local Tavern = setmetatable({}, {__index = Game.Mode})
Tavern.__index = Tavern
function Tavern.new(def, id) return setmetatable(Game.Mode.new(def, id), Tavern) end

local function event() return ReplicatedStorage:FindFirstChild("AdventureEvent") end
local function open(plr, tab, extra)
	local e = event()
	if e then e:FireClient(plr, "OpenDungeon", {tab = tab, merchant = extra}) end
end

-- the merchants' looks (a set's pieces, a weapon in hand) and what they're called
local MERCHANTS = {
	Smith = {name = "Hrothgar", title = "WEAPONSMITH", set = "RoadLevy", weapon = "Hammer"},
	Armourer = {name = "Old Brenna", title = "ARMOURER", set = "IronCrow", weapon = "Mace"},
	Alchemist = {name = "Wendel", title = "ALCHEMIST", set = "Necromancer", weapon = "Staff"},
	Treasurer = {name = "The Treasurer", title = "TREASURER", set = "GildedCourt", weapon = nil},
}

function Tavern:buildMap()
	local name, layout = TavernMap.build()
	self.layout = layout
	Dungeon.sweep(name)
	return name
end

-- a prompt on a part of the map (an anchored, invisible marker where it stands)
function Tavern:point(cf, action, object, fn)
	local p = Instance.new("Part")
	p.Name = "TavernPoint"
	p.Anchored, p.CanCollide, p.CanQuery, p.CanTouch, p.Transparency = true, false, false, false, 1
	p.Size = Vector3.new(2, 2, 2)
	p.CFrame = cf
	p.Parent = MapLoader.current or workspace
	local pr = Instance.new("ProximityPrompt")
	pr.ActionText, pr.ObjectText = action, object
	pr.KeyboardKeyCode = Enum.KeyCode.E
	pr.HoldDuration = 0
	pr.MaxActivationDistance = 12
	pr.RequiresLineOfSight = false
	pr.Parent = p
	pr.Triggered:Connect(fn)
	table.insert(self.stuff, p)
	return p
end

-- a sign over a place (seen across the hall, not through walls)
function Tavern:sign(part, text, sub, color)
	local bb = Instance.new("BillboardGui")
	bb.Name = "Sign"
	bb.Size = UDim2.fromOffset(300, 70)
	bb.StudsOffsetWorldSpace = Vector3.new(0, 5, 0)
	bb.AlwaysOnTop = false
	bb.LightInfluence = 0
	bb.MaxDistance = 140
	bb.Adornee = part
	local t = Instance.new("TextLabel")
	t.BackgroundTransparency = 1
	t.Size = UDim2.new(1, 0, 0, 36)
	t.Font = Enum.Font.FredokaOne
	t.TextSize = 30
	t.TextColor3 = color or Color3.fromRGB(255, 214, 112)
	t.Text = text
	local st = Instance.new("UIStroke"); st.Color = Color3.fromRGB(8, 10, 20); st.Thickness = 2.4; st.Parent = t
	t.Parent = bb
	local s = Instance.new("TextLabel")
	s.BackgroundTransparency = 1
	s.Position = UDim2.fromOffset(0, 36); s.Size = UDim2.new(1, 0, 0, 22)
	s.Font = Enum.Font.GothamBold
	s.TextSize = 16
	s.TextColor3 = Color3.fromRGB(220, 226, 240)
	s.Text = sub or ""
	local st2 = Instance.new("UIStroke"); st2.Color = Color3.fromRGB(8, 10, 20); st2.Thickness = 1.6; st2.Parent = s
	s.Parent = bb
	bb.Parent = part
	return bb
end

function Tavern:merchant(id, cf)
	local def = MERCHANTS[id]
	if not def then return end
	local m, hum, hrp = R6.rig(def.name, {anchored = true})
	m:SetAttribute("Idle", true)
	m:SetAttribute("TagName", def.name)
	m:SetAttribute("TagTitle", def.title)
	m:PivotTo(cf)
	local lo = {}
	for _, pc in ipairs(Catalog.setPieces(def.set)) do lo[pc.slot] = pc.id end
	m.Parent = MapLoader.current or workspace
	pcall(Dresser.dress, m, {loadout = lo, appearance = Catalog.BODY.defaults, weight = "Medium", preview = true})
	if def.weapon then pcall(Dresser.attachWeapon, m, def.weapon, def.weapon .. ":Default") end
	hum.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None
	hum.HealthDisplayType = Enum.HumanoidHealthDisplayType.AlwaysOff
	hum.MaxHealth, hum.Health = 1e6, 1e6
	for _, d in ipairs(m:GetDescendants()) do if d:IsA("BasePart") then d.CanQuery = false; d.CanTouch = false end end
	local pr = Instance.new("ProximityPrompt")
	pr.ActionText, pr.ObjectText = "Trade", def.name
	pr.KeyboardKeyCode = Enum.KeyCode.E
	pr.MaxActivationDistance = 12
	pr.RequiresLineOfSight = false
	pr.Parent = hrp
	pr.Triggered:Connect(function(plr) open(plr, "Merchants", id) end)
	table.insert(self.stuff, m)
end

function Tavern:start(map)
	Game.Mode.start(self, map)
	self.stuff = {}
	if not self.layout then
		local name = self:buildMap()
		MapLoader.load(name)
	end
	local L = self.layout
	for _, n in ipairs(L.npcs) do self:merchant(n.id, n.cf) end
	self:point(L.points.board, "Read", "Class & Perks", function(plr) open(plr, "Class") end)
	local gate = self:point(L.points.gate, "Descend", "The Dungeon Gate", function(plr) open(plr, "Play") end)
	self:sign(gate, "THE DUNGEON GATE", "Your party, the dungeon, READY")
	local exit = self:point(L.points.exit, "Leave", "To the Courtyard", function(plr)
		if _G.HubTravel then pcall(_G.HubTravel, plr, "Courtyard", {}) end
	end)
	self:sign(exit, "TO THE COURTYARD", "Back to the main game", Color3.fromRGB(255, 120, 120))
	self:sign(self:point(L.points.stash, "Open", "Your Stash", function(plr) open(plr, "Stash") end), "YOUR STASH", "Kit and stash")
	-- everyone walks in (and back in, should anything happen)
	for _, p in ipairs(Players:GetPlayers()) do if _G.AutoSpawn then _G.AutoSpawn(p) end end
	if not self.joinConn then
		self.joinConn = Players.PlayerAdded:Connect(function(p)
			if Game.current ~= self then return end
			task.delay(2, function() if p.Parent and Game.current == self and _G.AutoSpawn then _G.AutoSpawn(p) end end)
		end)
	end
	node:SetAttribute("Objective", self:objective())
end

function Tavern:stop()
	for _, s in ipairs(self.stuff or {}) do if s.Parent then s:Destroy() end end
	self.stuff = {}
	self.layout = nil
end

-- nobody stands about without a body here: in you walk (on arrival, and after anything)
function Tavern:tick(dt)
	self.spawnCheck = (self.spawnCheck or 0) + dt
	if self.spawnCheck < 2 then return end
	self.spawnCheck = 0
	for _, p in ipairs(Players:GetPlayers()) do
		local c = p.Character
		local h = c and c:FindFirstChildOfClass("Humanoid")
		if not (h and h.Health > 0) and _G.AutoSpawn then _G.AutoSpawn(p) end
	end
end

function Tavern:onDeath(victimPlr)
	task.delay(1.5, function() if victimPlr.Parent and Game.current == self and _G.AutoSpawn then _G.AutoSpawn(victimPlr) end end)
end
function Tavern:spawnCFrame(plr)
	return Game.Mode.spawnCFrame(self, plr)
end
function Tavern:objective() return "THE GILDED RAT  ·  M FOR THE MENU" end
function Tavern:isOver()
	local nxt = node:GetAttribute("NextMode")
	if nxt ~= nil and nxt ~= "" and nxt ~= "Tavern" then return "INTO THE DARK" end
	return nil
end
function Tavern:result() return "" end

return Tavern
