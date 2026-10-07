-- Script inside the Tool. All logic lives in ServerScriptService.Combat.RangedServer.
local RangedServer = require(game:GetService("ServerScriptService"):WaitForChild("Combat"):WaitForChild("RangedServer"))
RangedServer.attach(script.Parent, require(script.Parent:WaitForChild("Config")))
