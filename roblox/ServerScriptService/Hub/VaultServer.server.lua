--[[ VAULT SERVER — the vault screen's questions (StarterPlayerScripts ▸ VaultMenu.client):
     ReplicatedStorage ▸ VaultRemote (RemoteFunction): "View" · "Equip" uid · "Unequip" uid ·
     "Sell" uid · "Buy" {merchant, index} · "Work" {uid, "reforge" | "temper"} · "Class" classId.
     Every answer is {ok, msg, view} (Game ▸ Vault does the work; the client only asks). Not while
     you're in a raid: what you carry there isn't in the vault. ]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local Vault = require(ServerScriptService:WaitForChild("Game"):WaitForChild("Vault"))
local Game = require(ServerScriptService:WaitForChild("Game"):WaitForChild("Game"))

local remote = ReplicatedStorage:FindFirstChild("VaultRemote")
if not remote then remote = Instance.new("RemoteFunction"); remote.Name = "VaultRemote"; remote.Parent = ReplicatedStorage end

local last = {}
remote.OnServerInvoke = function(plr, kind, arg)
	local now = os.clock()
	if now - (last[plr] or 0) < 0.15 then return {ok = false, msg = "slow down"} end
	last[plr] = now
	local inRaid = Game.modeId == "Deadvault" and Game.node:GetAttribute("State") == "Round"
	local ok, msg = true, nil
	if kind == "View" then
	elseif inRaid then ok, msg = false, "Not from inside a raid"
	elseif kind == "Equip" and type(arg) == "string" then ok, msg = Vault.equip(plr, arg)
	elseif kind == "Unequip" and type(arg) == "string" then ok, msg = Vault.unequip(plr, arg)
	elseif kind == "Sell" and type(arg) == "string" then
		local g
		ok, g = Vault.sell(plr, arg)
		msg = ok and ("+" .. tostring(g) .. " gold") or g
	elseif kind == "Buy" and type(arg) == "table" and type(arg[1]) == "string" and type(arg[2]) == "number" then
		local it
		ok, it = Vault.buy(plr, arg[1], arg[2])
		msg = ok and ("Bought " .. tostring(it and it.name or "")) or it
	elseif kind == "Work" and type(arg) == "table" and type(arg[1]) == "string" and (arg[2] == "reforge" or arg[2] == "temper") then
		local it
		ok, it = Vault.work(plr, arg[1], arg[2])
		msg = ok and ((arg[2] == "temper" and "Tempered: " or "Reforged: ") .. tostring(it and it.name or "")) or it
	elseif kind == "Class" and type(arg) == "string" then ok, msg = Vault.setClass(plr, arg)
	elseif kind == "Perk" and type(arg) == "table" and type(arg[1]) == "string" and type(arg[2]) == "string" then
		ok, msg = require(ServerScriptService.Game:WaitForChild("Perks")).set(plr, arg[1], arg[2])
	else ok, msg = false, "?" end
	return {ok = ok, msg = msg, view = Vault.view(plr)}
end
Players.PlayerRemoving:Connect(function(p) last[p] = nil end)
