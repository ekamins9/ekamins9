-- LocalScript inside the Tool. All logic lives in ReplicatedStorage.Combat.RangedClient.
local RangedClient = require(game:GetService("ReplicatedStorage"):WaitForChild("Combat"):WaitForChild("RangedClient"))
RangedClient.attach(script.Parent, require(script.Parent:WaitForChild("Config")))
