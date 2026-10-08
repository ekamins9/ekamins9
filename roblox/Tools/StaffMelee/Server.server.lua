-- Script inside the Tool. All logic lives in ServerScriptService.Combat.CombatServer.
local CombatServer = require(game:GetService("ServerScriptService"):WaitForChild("Combat"):WaitForChild("CombatServer"))
CombatServer.attach(script.Parent, require(script.Parent:WaitForChild("Config")))
