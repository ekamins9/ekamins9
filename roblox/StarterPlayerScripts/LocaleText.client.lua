--[[ LOCALE TEXT — Roblox's automatic translation looks at every piece of text a
     screen shows, every time it changes. For a player who reads English (their Roblox
     language and their locale both English) there's nothing to translate, and a label
     is several times cheaper to build without it, so every screen of theirs opts out
     (AutoLocalize off on each ScreenGui as it arrives). Everyone else is left exactly
     as they were: their screens are still translated. ]]

local Players = game:GetService("Players")
local LocalizationService = game:GetService("LocalizationService")

local player = Players.LocalPlayer
local function english(id) return string.sub(tostring(id or ""), 1, 2) == "en" end
if not (english(LocalizationService.RobloxLocaleId) and english(player.LocaleId)) then return end
_G.EnglishText = true

local playerGui = player:WaitForChild("PlayerGui")
local function optOut(g) if g:IsA("LayerCollector") then g.AutoLocalize = false end end
playerGui.ChildAdded:Connect(optOut)
for _, g in ipairs(playerGui:GetChildren()) do optOut(g) end
