--[[ CLEAN VIEW — Ctrl+H hides every screen of the game's UI, plus Roblox's own (chat, the
     player list, the top bar), the prompts ("Pick up", "Talk") and the markers floating over
     the world (the training yard's arrow, a teacher's bubble), so a fight can be filmed clean:
     for the game page's video (Roblox wants real gameplay there) or anyone's YouTube. Ctrl+H
     again brings back exactly what was showing. Name tags over heads stay (they're part of the
     world). A screen marked CleanViewKeep stays (the showcase director's own controls, which
     hide themselves). ]]

local Players          = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local RunService       = game:GetService("RunService")
local StarterGui       = game:GetService("StarterGui")
local ProximityPromptService = game:GetService("ProximityPromptService")

local player = Players.LocalPlayer
local gui = player:WaitForChild("PlayerGui")

local clean = false
local was = {}       -- [ScreenGui / BillboardGui] = true: on before (or turned on by a script meanwhile)
local core = {}      -- [CoreGuiType] = was it on
local topbar = nil
local prompts = nil  -- were the prompts on

local function hideAll()
	for _, g in ipairs(gui:GetChildren()) do
		local hide = (g:IsA("ScreenGui") and not g:GetAttribute("CleanViewKeep"))
			or (g:IsA("BillboardGui") and g.Name:sub(1, 7) ~= "NameTag")
		if hide and g.Enabled then
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
		local okP, p = pcall(function() return ProximityPromptService.Enabled end)
		prompts = okP and p
		pcall(function() ProximityPromptService.Enabled = false end)
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
		if prompts ~= nil then pcall(function() ProximityPromptService.Enabled = prompts end); prompts = nil end
	end
end

-- (a staff showcase turns it on and off: Showcase.client)
_G.SetCleanView = function(on) if on ~= clean then setClean(on) end end

UserInputService.InputBegan:Connect(function(input, processed)
	if processed or input.KeyCode ~= Enum.KeyCode.H then return end
	if _G.ShowcaseActive then return end   -- (a showcase keeps it clean: its controls are on TAB)
	if UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) or UserInputService:IsKeyDown(Enum.KeyCode.RightControl) then
		setClean(not clean)
	end
end)

-- a screen a script turns back on while it's clean goes off again (and comes back after)
RunService.RenderStepped:Connect(function()
	if clean then hideAll() end
end)
