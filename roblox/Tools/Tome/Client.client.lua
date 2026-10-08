-- LocalScript inside the Tool. All logic lives in ReplicatedStorage.Combat.MagicClient.
local MagicClient = require(game:GetService("ReplicatedStorage"):WaitForChild("Combat"):WaitForChild("MagicClient"))
MagicClient.attach(script.Parent, require(script.Parent:WaitForChild("Config")))
