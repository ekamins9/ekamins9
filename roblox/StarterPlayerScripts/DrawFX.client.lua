--[[ DRAW FX — taking a weapon in hand is a motion, not a pop: the right arm reaches
     to where the weapon hangs (Loadout ▸ Holsters: over the shoulder for a two-hander,
     a bow or a staff, the left hip for a one-hander or a grimoire, the right hip for
     a dagger or a wand) and sweeps it out into the weapon's own idle. Played here on
     every character this client sees (players and bots), laid over their animation
     for a moment (the arm's Transform, after the Animator, eased in and out: ReplicatedStorage
     ▸ JointLayer), so the clips themselves are untouched. Settings ▸ "Draw animation" turns it off.

     The server holds the blow until the weapon is out (Combat ▸ CombatServer
     DRAW_TIME), so the motion is also the time a swap costs. ]]

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Catalog = require(ReplicatedStorage:WaitForChild("Catalog"))
local ClientSettings = require(ReplicatedStorage:WaitForChild("ClientSettings"))
local JointLayer = require(ReplicatedStorage:WaitForChild("JointLayer"))

local DUR, DUR_2H = 0.4, 0.52   -- seconds (CombatServer DRAW_TIME / DRAW_TIME_2H)
local REACH = 0.11              -- the hand gets to the weapon this fast, then pulls it out
-- the arm at the weapon (radians: raise forward, ½π = level, π = straight up, past π
-- behind the head; across the chest)
local POSE = {
	Back   = {raise = 3.45, across = 0.25},    -- up and back over the right shoulder
	Pole   = {raise = 3.3, across = 0.1},      -- a haft down the back
	Hip    = {raise = 0.95, across = 1.3},     -- across the belly to the left hip
	Dagger = {raise = -0.3, across = -0.2},    -- down at the right hip
}

local function kindOf(id)
	if id == "Dagger" or id == "Wand" then return "Dagger" end
	if id == "Staff" or id == "StaffMelee" then return "Pole" end
	if id == "Tome" then return "Hip" end
	if id == "Bow" or id == "Crossbow" then return "Back" end
	local w = Catalog.WEAPON[id]
	local fam = w and w.family
	if fam == "Polearm" then return "Pole" end
	if fam == "TwoHanded" then return "Back" end
	return "Hip"
end
local function twoHanded(id)
	local w = Catalog.WEAPON[id]
	return w ~= nil and (w.family == "TwoHanded" or w.family == "Polearm")
end

local draws = {}      -- [character] = {t0, dur, pose, two}
local lastOff = {}    -- [character] = {name, at}: the weapon that just left the hand

local function ease(x) return x < 0.5 and 4 * x * x * x or 1 - (-2 * x + 2) ^ 3 / 2 end
local function weight(t, dur)
	if t < REACH then local x = t / REACH; return 1 - (1 - x) * (1 - x) end
	return 1 - ease(math.clamp((t - REACH) / (dur - REACH), 0, 1))
end

local function watch(char)
	if not char:IsA("Model") then return end
	char.ChildAdded:Connect(function(c)
		if not (c:IsA("Tool") and c:FindFirstChild("Handle")) then return end
		if ClientSettings.get("DrawAnim") == "Off" then return end
		-- (a staff turning into its melee self and back is a change of grip, not a draw)
		local off = lastOff[char]
		if off and os.clock() - off.at < 0.4 and (c:GetAttribute("Twin") == off.name or off.twin == c.Name) then return end
		local id = c.Name
		draws[char] = {t0 = os.clock(), dur = twoHanded(id) and DUR_2H or DUR, pose = POSE[kindOf(id)], two = twoHanded(id)}
	end)
	char.ChildRemoved:Connect(function(c)
		if c:IsA("Tool") then lastOff[char] = {name = c.Name, twin = c:GetAttribute("Twin"), at = os.clock()} end
	end)
	char.AncestryChanged:Connect(function()
		if not char:IsDescendantOf(workspace) then draws[char] = nil; lastOff[char] = nil end
	end)
end

local function watchPlayer(plr)
	plr.CharacterAdded:Connect(watch)
	if plr.Character then watch(plr.Character) end
end
Players.PlayerAdded:Connect(watchPlayer)
for _, p in ipairs(Players:GetPlayers()) do watchPlayer(p) end
task.spawn(function()
	local npcs = workspace:WaitForChild("NPCs", 60)
	if not npcs then return end
	npcs.ChildAdded:Connect(watch)
	for _, m in ipairs(npcs:GetChildren()) do watch(m) end
end)

-- after the Animator has written this frame's pose: the arm drawn toward the weapon
JointLayer.bind("DrawFX", function()
	if not next(draws) then return end
	local now = os.clock()
	for char, d in pairs(draws) do
		local t = now - d.t0
		local torso = char:FindFirstChild("Torso")
		if t >= d.dur or not (torso and char.Parent) then
			draws[char] = nil
		else
			local w = weight(t, d.dur)
			local rs = torso:FindFirstChild("Right Shoulder")
			if rs and rs:IsA("Motor6D") then
				local target = CFrame.Angles(0, d.pose.across, 0) * CFrame.Angles(0, 0, d.pose.raise)
				JointLayer.blend(rs, target, w)
			end
			-- (a two-hander: the off hand lets go of where the grip will be until it's out)
			if d.two then
				local ls = torso:FindFirstChild("Left Shoulder")
				if ls and ls:IsA("Motor6D") then JointLayer.blend(ls, CFrame.Angles(0, 0, -0.15), w * 0.75) end
			end
		end
	end
end)
