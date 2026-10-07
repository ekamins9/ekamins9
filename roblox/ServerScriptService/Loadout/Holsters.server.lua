--[[ HOLSTERS — the weapons you carry but aren't holding are worn on you, so
     everyone sees your kit: two-handers and polearms across your back, one-
     handers at your left hip, a dagger at your right. A worn weapon is a
     look-only copy of the Tool (skin and all; no scripts, no hitbox), welded to
     the torso. Drawing it takes it off the body with the sound of a blade
     leaving its scabbard; putting it away hangs it back on.

     Where each sits: SPOTS below (torso space; the weapon's blade runs along
     its Handle's +Y). ]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Catalog = require(ReplicatedStorage:WaitForChild("Catalog"))
local Sounds  = require(ReplicatedStorage:WaitForChild("Sounds"))

local DRAW_SOUND = "rbxassetid://9119742466"   -- a sabre leaving its scabbard (Pro Sound Effects)
local SHEATHE_SOUND = "rbxassetid://9119742690"

local r = math.rad
-- the Handle's frame on the torso (the blade along the Handle's +Y)
local SPOTS = {
	-- across the back, hilt over the right shoulder, blade down to the left hip
	Back   = CFrame.new(0.55, 0.55, 0.62) * CFrame.Angles(0, 0, r(145)),
	-- a polearm: head up behind the left shoulder, the haft down the back
	Pole   = CFrame.new(0.3, -0.3, 0.66) * CFrame.Angles(0, 0, r(22)),
	-- at the left hip, hilt forward, blade down and back
	Hip    = CFrame.new(-1.12, -0.85, -0.15) * CFrame.Angles(r(150), 0, r(-8)),
	-- a dagger at the right hip, point down
	Dagger = CFrame.new(1.1, -0.85, 0.15) * CFrame.Angles(r(170), 0, r(10)),
	-- a bow slung across the back, string out; a crossbow across the back, prod up
	Bow      = CFrame.new(-0.2, 0.1, 0.62) * CFrame.Angles(0, 0, r(-28)),
	Crossbow = CFrame.new(0, 0.2, 0.7) * CFrame.Angles(r(-90), 0, r(35)),
}

local function spotFor(weaponId)
	if weaponId == "Dagger" then return SPOTS.Dagger end
	if weaponId == "Bow" or weaponId == "Crossbow" then return SPOTS[weaponId] end
	local w = Catalog.WEAPON[weaponId]
	local fam = w and w.family
	if fam == "Polearm" then return SPOTS.Pole end
	if fam == "TwoHanded" then return SPOTS.Back end
	return SPOTS.Hip
end

local STRIP = {Script = true, LocalScript = true, ModuleScript = true, RemoteEvent = true, RemoteFunction = true,
	BindableEvent = true, Sound = true, ProximityPrompt = true, Trail = true}

-- a look-only copy of a Tool, welded to the torso at its spot
local function wear(char, tool)
	local torso = char:FindFirstChild("Torso")
	local handle = tool:FindFirstChild("Handle")
	if not (torso and handle) then return nil end
	local copy = tool:Clone()
	local model = Instance.new("Model")
	model.Name = "Holster_" .. tool.Name
	for _, c in ipairs(copy:GetChildren()) do c.Parent = model end
	copy:Destroy()
	for _, d in ipairs(model:GetDescendants()) do
		if STRIP[d.ClassName] then
			d:Destroy()
		elseif d:IsA("BasePart") then
			if d.Name == "Hitbox" or d.Name == "GuardHull" then
				d:Destroy()
			else
				d.CanCollide, d.CanQuery, d.CanTouch, d.Massless, d.Anchored = false, false, false, true, false
			end
		end
	end
	local h = model:FindFirstChild("Handle")
	if not h then model:Destroy(); return nil end
	model.PrimaryPart = h
	local weld = Instance.new("Weld")
	weld.Name = "HolsterWeld"
	weld.Part0, weld.Part1 = torso, h
	weld.C0 = spotFor(tool.Name)
	weld.Parent = h
	model.Parent = char
	return model
end

local function isWeapon(t) return t:IsA("Tool") and t:FindFirstChild("Config") ~= nil end

local function track(plr, char)
	local worn = {}   -- [Tool] = holster model
	local function sync()
		if not char.Parent then return end
		local backpack = plr:FindFirstChildOfClass("Backpack")
		local inPack = {}
		for _, t in ipairs(backpack and backpack:GetChildren() or {}) do
			if isWeapon(t) then inPack[t] = true end
		end
		-- off the body: drawn, dropped, gone
		for t, m in pairs(worn) do
			if not inPack[t] then
				m:Destroy()
				worn[t] = nil
				if t.Parent == char then Sounds.play(DRAW_SOUND, char:FindFirstChild("Torso"), {Volume = 0.55, MaxDistance = 50}) end
			end
		end
		-- on the body: carried, not held
		for t in pairs(inPack) do
			if not worn[t] then
				local m = wear(char, t)
				if m then
					worn[t] = m
					-- (a weapon put away, not one handed out at spawn: the sheathe)
					if t:GetAttribute("WasHeld") then Sounds.play(SHEATHE_SOUND, char:FindFirstChild("Torso"), {Volume = 0.35, MaxDistance = 40}) end
				end
			end
		end
	end
	local function watch(container)
		container.ChildAdded:Connect(function(c)
			if isWeapon(c) and container == char then c:SetAttribute("WasHeld", true) end
			task.defer(sync)
		end)
		container.ChildRemoved:Connect(function() task.defer(sync) end)
	end
	watch(char)
	local backpack = plr:WaitForChild("Backpack", 10)
	if backpack then watch(backpack) end
	task.defer(sync)
end

Players.PlayerAdded:Connect(function(plr)
	plr.CharacterAdded:Connect(function(char)
		char:WaitForChild("Torso", 10)
		track(plr, char)
	end)
	if plr.Character then track(plr, plr.Character) end
end)
for _, plr in ipairs(Players:GetPlayers()) do
	plr.CharacterAdded:Connect(function(char) char:WaitForChild("Torso", 10); track(plr, char) end)
	if plr.Character then track(plr, plr.Character) end
end
