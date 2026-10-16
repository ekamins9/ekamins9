--[[ PERKS — puts your class's chosen perks on you in the dungeon game (The Depths, Deadvault):
     Catalog ▸ Perks, chosen in the Deadvault lobby's CLASS tab (Profile ▸ vault.perks[class]).

       Perks.chosen(plr, classId) -> {perk…}   (only the ones the class may take, at most PICK)
       Perks.set(plr, classId, perkId) -> ok, msg   on / off
       Perks.apply(plr, char, classId) -> {bag = n}   on the body, for this life ]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local Catalog = require(ReplicatedStorage:WaitForChild("Catalog"))
local Profile = require(ServerScriptService:WaitForChild("Loadout"):WaitForChild("Profile"))
local Powers = require(ServerScriptService:WaitForChild("Combat"):WaitForChild("Powers"))
local Loot = require(script.Parent:WaitForChild("Loot"))

local Perks = {}
local FOREVER = 1e6
local PICK = Catalog.PERKS and Catalog.PERKS.PICK or 2

local function store(plr)
	local p = Profile.get(plr)
	p.vault = type(p.vault) == "table" and p.vault or {}
	p.vault.perks = type(p.vault.perks) == "table" and p.vault.perks or {}
	return p.vault.perks
end

function Perks.chosen(plr, classId)
	local ids = store(plr)[classId] or {}
	local out = {}
	for _, id in ipairs(ids) do
		local pk = Catalog.PERK[id]
		if pk and Catalog.perkFits(pk, classId) and #out < PICK then table.insert(out, pk) end
	end
	return out
end

function Perks.set(plr, classId, perkId)
	local pk = Catalog.PERK[perkId]
	if not (pk and Catalog.perkFits(pk, classId)) then return false, "not a perk of that class" end
	local all = store(plr)
	local ids = all[classId] or {}
	local at = table.find(ids, perkId)
	if at then
		table.remove(ids, at)
	else
		if #ids >= PICK then return false, "two perks at most: take one off first" end
		table.insert(ids, perkId)
	end
	all[classId] = ids
	Profile.markDirty(plr)
	return true
end

function Perks.apply(plr, char, classId)
	local out = {bag = 0}
	if not char then return out end
	local hum = char:FindFirstChildOfClass("Humanoid")
	for _, pk in ipairs(Perks.chosen(plr, classId)) do
		if pk.mods then Powers.addMods(char, pk.mods, FOREVER, "Perk_" .. pk.id) end
		if pk.health and Loot.setBonusHealth then Loot.setBonusHealth(char, "perk_" .. pk.id, pk.health) end
		if pk.quiet then char:SetAttribute("Quiet", true) end
		if pk.ambush then char:SetAttribute("Ambusher", true) end
		if pk.luck then char:SetAttribute("PerkLuck", (char:GetAttribute("PerkLuck") or 0) + pk.luck) end
		if pk.bag then out.bag += pk.bag end
		if pk.secondWind and hum then
			local used = false
			hum.HealthChanged:Connect(function(h)
				if used or h <= 0 or h > hum.MaxHealth * 0.25 then return end
				used = true
				hum.Health = math.min(hum.MaxHealth, h + hum.MaxHealth * pk.secondWind)
				char:SetAttribute("GuardText", "SECOND WIND")
				char:SetAttribute("GuardTick", (char:GetAttribute("GuardTick") or 0) + 1)
			end)
		end
	end
	char:SetAttribute("Perks", #Perks.chosen(plr, classId))
	return out
end

return Perks
