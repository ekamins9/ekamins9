--[[ CLEAN VIEW — Ctrl+H hides every screen of the game's UI, plus Roblox's own (chat, the
     player list, the top bar), so a fight can be filmed clean: for the game page's video
     (Roblox wants real gameplay there) or anyone's YouTube. Ctrl+H again brings back exactly
     what was showing. Name tags over heads stay (they're part of the world). ]]

local Players          = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local RunService       = game:GetService("RunService")
local StarterGui       = game:GetService("StarterGui")

local player = Players.LocalPlayer
local gui = player:WaitForChild("PlayerGui")

local clean = false
local was = {}       -- [ScreenGui] = true: on before (or turned on by a script meanwhile)
local core = {}      -- [CoreGuiType] = was it on
local topbar = nil

local function hideAll()
	for _, g in ipairs(gui:GetChildren()) do
		if g:IsA("ScreenGui") and g.Enabled then
			was[g] = true
			g.Enabled = false
		end
	end
end

local function setClean(on)
	clean = on
	if on then
		hideAll()
		for _, t in ipairs(Enum.CoreGuiType:GetEnumItems()) do
			if t ~= Enum.CoreGuiType.All then
				local ok, v = pcall(StarterGui.GetCoreGuiEnabled, StarterGui, t)
				core[t] = ok and v or false
				if core[t] then pcall(StarterGui.SetCoreGuiEnabled, StarterGui, t, false) end
			end
		end
		local ok, v = pcall(StarterGui.GetCore, StarterGui, "TopbarEnabled")
		topbar = ok and v
		pcall(StarterGui.SetCore, StarterGui, "TopbarEnabled", false)
	else
		for g in pairs(was) do
			if g.Parent then g.Enabled = true end
		end
		table.clear(was)
		for t, v in pairs(core) do
			if v then pcall(StarterGui.SetCoreGuiEnabled, StarterGui, t, true) end
		end
		table.clear(core)
		if topbar ~= nil then pcall(StarterGui.SetCore, StarterGui, "TopbarEnabled", topbar) end
	end
end

-- (a staff showcase turns it on and off: Showcase.client)
_G.SetCleanView = function(on) if on ~= clean then setClean(on) end end

UserInputService.InputBegan:Connect(function(input, processed)
	if processed or input.KeyCode ~= Enum.KeyCode.H then return end
	if UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) or UserInputService:IsKeyDown(Enum.KeyCode.RightControl) then
		setClean(not clean)
	end
end)

-- a screen a script turns back on while it's clean goes off again (and comes back after)
RunService.RenderStepped:Connect(function()
	if clean then hideAll() end
end)
