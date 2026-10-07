--[[ UI CLICKS — every button in your UI clicks when pressed and ticks softly
     when the mouse comes over it (UIFX sounds, at the "Menu sounds" volume).
     Close / back buttons get their own sound. A button with attribute Silent
     stays quiet. Buttons the menu rebuilds are picked up as they appear. ]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local UIFX = require(ReplicatedStorage:WaitForChild("UIFX"))
local player = Players.LocalPlayer
local pg = player:WaitForChild("PlayerGui")

local bound = setmetatable({}, {__mode = "k"})
local lastHover = 0

local function isBack(b)
	local n = string.lower(b.Name)
	if n:find("close") or n:find("back") then return true end
	local t = b:IsA("TextButton") and string.upper(b.Text) or ""
	return t == "✕" or t == "X" or t == "BACK" or t == "CLOSE" or t == "‹ BACK" or t == "< BACK"
end

local function bind(b)
	if bound[b] or not b:IsA("GuiButton") then return end
	bound[b] = true
	b.MouseEnter:Connect(function()
		if b:GetAttribute("Silent") or not b.Active then return end
		local now = os.clock()
		if now - lastHover < 0.05 then return end
		lastHover = now
		UIFX.play("Hover")
	end)
	b.Activated:Connect(function()
		if b:GetAttribute("Silent") then return end
		UIFX.play(isBack(b) and "Back" or "Click")
	end)
end

for _, d in ipairs(pg:GetDescendants()) do bind(d) end
pg.DescendantAdded:Connect(bind)
