-- HUB — the courtyard: free roam, no clock, no teams, spawn anywhere. Live it
-- never ends; in Studio it ends the moment a mode is requested (GameServer
-- sees NextMode and moves on).
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Game = require(script.Parent.Parent:WaitForChild("Game"))

local HubBackdrop = require(script.Parent.Parent:WaitForChild("HubBackdrop"))
local BannerArt = require(script.Parent.Parent:WaitForChild("BannerArt"))
local Players = game:GetService("Players")

local Hub = setmetatable({}, {__index = Game.Mode})
Hub.__index = Hub
function Hub.new(def, id) return setmetatable(Game.Mode.new(def, id), Hub) end

-- the world round the walls (Game ▸ HubBackdrop): hills, a village, woods, a war camp far off
function Hub:start(map)
	Game.Mode.start(self, map)
	local ok, err = pcall(HubBackdrop.build, Game.MapLoader.current)
	if not ok then warn("[Hub] backdrop:", err) end
	self.hallOn = true
	task.spawn(function() self:hall() end)
end
function Hub:stop() self.hallOn = false; HubBackdrop.clear() end

-- THE HALL OF ARMS: the Courtyard's small banners (the Banner cloths, not the keep's great ones) fly
-- the arms of those here who bear them (LOOK ▸ YOUR ARMS), the highest level first, each with the
-- name under it; the rest fly the house's. Looked at every 15 s; a banner is repainted only when
-- whose it is changes (Game ▸ BannerArt.fly)
function Hub:hall()
	local Profile = require(game:GetService("ServerScriptService"):WaitForChild("Loadout"):WaitForChild("Profile"))
	local ShieldPaint = require(ReplicatedStorage:WaitForChild("ShieldPaint"))
	local flying = {}   -- cloth -> whose ("" the house)
	while self.hallOn do
		local map = Game.MapLoader.current
		local seed = map and map:GetAttribute("HouseSeed")
		local cloths = {}
		for _, d in ipairs(map and map:GetDescendants() or {}) do
			if d:IsA("BasePart") and d.Name == "Banner" and d:GetAttribute("BannerArt") then table.insert(cloths, d) end
		end
		-- (the same order every time: along the north wall, then the south)
		table.sort(cloths, function(a, b)
			if math.abs(a.Position.Z - b.Position.Z) > 4 then return a.Position.Z < b.Position.Z end
			return a.Position.X < b.Position.X
		end)
		local bearers = {}
		for _, plr in ipairs(Players:GetPlayers()) do
			local okP, p = pcall(Profile.get, plr)
			local arms = okP and p and ShieldPaint.armsOf(p.appearance)
			if arms then table.insert(bearers, {plr = plr, arms = arms, level = p.level or 1}) end
		end
		table.sort(bearers, function(a, b) if a.level ~= b.level then return a.level > b.level end return a.plr.Name < b.plr.Name end)
		for i, cloth in ipairs(cloths) do
			local b = bearers[i]
			local key = b and (b.plr.UserId .. "|" .. b.arms.emblem .. "|" .. tostring(b.arms.field) .. "|" .. tostring(b.arms.metal)) or ""
			if flying[cloth] ~= key then
				flying[cloth] = key
				pcall(BannerArt.fly, cloth, b and b.arms, b and b.plr.DisplayName, seed)
			end
		end
		task.wait(15)
	end
end

function Hub:objective() return "HUB  ·  {Menu} for the menu" end
function Hub:isOver()
	local nxt = Game.node:GetAttribute("NextMode")
	if nxt ~= nil and nxt ~= "" and nxt ~= "Hub" then return "TO BATTLE" end
	return nil
end
function Hub:result() return "" end

return Hub
