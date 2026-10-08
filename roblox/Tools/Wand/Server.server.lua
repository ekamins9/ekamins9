-- Script inside the Tool. All logic lives in ServerScriptService.Combat.MagicServer.
local MagicServer = require(game:GetService("ServerScriptService"):WaitForChild("Combat"):WaitForChild("MagicServer"))
MagicServer.attach(script.Parent, require(script.Parent:WaitForChild("Config")))
