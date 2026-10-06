-- LocalScript inside the Tool. All logic lives in ReplicatedStorage.Combat.CombatClient.
local CombatClient = require(game:GetService("ReplicatedStorage"):WaitForChild("Combat"):WaitForChild("CombatClient"))
CombatClient.attach(script.Parent, require(script.Parent:WaitForChild("Config")))
