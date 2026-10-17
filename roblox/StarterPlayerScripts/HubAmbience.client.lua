--[[ HUB AMBIENCE — the war beyond the Courtyard's walls (Game ▸ HubBackdrop builds the camp): now
     and then one of the far camp's trebuchets lobs its fire further off still, a long arc low over
     the eastern hills and a deep boom a moment later. Far enough to be scenery, never on anyone.
     Only in the Hub, and only while its map has the camp (Map BD_Treb1/2). ]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local WarFX = require(ReplicatedStorage:WaitForChild("WarFX"))
local round = ReplicatedStorage:WaitForChild("Round")

task.spawn(function()
	task.wait(15)
	while true do
		task.wait(28 + math.random() * 24)
		local map = workspace:FindFirstChild("Map")
		local from = map and map:GetAttribute("BD_Treb" .. math.random(2))
		local camp = map and map:GetAttribute("BD_Camp")
		if round:GetAttribute("Mode") == "Hub" and typeof(from) == "Vector3" and typeof(camp) == "Vector3" then
			-- (eastward, away from the castle: over the far hills)
			local to = camp + Vector3.new(240 + math.random() * 120, 0, (math.random() - 0.5) * 300)
			pcall(WarFX.fireball, from, to, 6, {far = true, big = true, height = 160})
		end
	end
end)
