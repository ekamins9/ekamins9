--[[ RANGED FX — what everyone sees of bows and crossbows (Combat ▸ RangedServer):
       • arrows in flight (ReplicatedStorage ▸ ArrowEvent → ArrowFlight); your
         own already fly from the moment you loosed them
       • every bow's STRING drawn back to the drawing hand (the left), with an arrow on it
         (the server publishes Drawing 0..1 on the character; your own draw is
         read straight from your client, so it's smooth)
       • a crossbow's string at the nut while it's spanned (Loaded), sliding
         back as it's reloaded ]]

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local ArrowFlight = require(ReplicatedStorage:WaitForChild("ArrowFlight"))
local arrowEvent = ReplicatedStorage:WaitForChild("ArrowEvent", math.huge)   -- (made when the first bow comes out: wait quietly)
local player = Players.LocalPlayer

arrowEvent.OnClientEvent:Connect(function(what, id, a, b, c, kind, shooterId, fx)
	if what == "Shot" then
		-- (our own shot flies already)
		if ArrowFlight.has(id) then return end
		ArrowFlight.fly(id, a, b, c, kind, false, fx)
	elseif what == "Stop" then
		ArrowFlight.stop(id, a)
	end
end)

--------------------------------------------------------------------
--  STRINGS AND NOCKED ARROWS
--------------------------------------------------------------------
local nocked = {}   -- [character] = arrow part

local function nockedArrow(char)
	local a = nocked[char]
	if a and a.Parent then return a end
	a = Instance.new("Part")
	a.Name = "NockedArrow"
	a.Size = Vector3.new(0.08, 0.08, 2.6)
	a.Color = Color3.fromRGB(150, 110, 66)
	a.Material = Enum.Material.Wood
	a.Anchored, a.CanCollide, a.CanQuery, a.CanTouch, a.CastShadow = true, false, false, false, false
	local tip = Instance.new("SpecialMesh") ; tip.MeshType = Enum.MeshType.Brick ; tip.Parent = a
	a.Parent = workspace:FindFirstChild("ArrowFlights") or workspace
	nocked[char] = a
	return a
end

local function update(char)
	local tool = char:FindFirstChildOfClass("Tool")
	local kind = tool and tool:GetAttribute("Ranged")
	local handle = tool and tool:FindFirstChild("Handle")
	local nock = handle and handle:FindFirstChild("StringNock")
	local arrow = nocked[char]
	if not (kind and nock) then
		if arrow then arrow:Destroy(); nocked[char] = nil end
		return
	end
	local rest = nock:GetAttribute("Rest")
	if typeof(rest) ~= "Vector3" then return end
	if kind == "bow" then
		local draw = char == player.Character and (char:GetAttribute("LocalDraw") or 0) or (char:GetAttribute("Drawing") or 0)
		local arm = char:FindFirstChild("Left Arm")   -- the string hand (the bow is in the right)
		if draw > 0.02 and arm then
			-- the string to the drawing hand
			local hand = (arm.CFrame * CFrame.new(0, -0.9, 0)).Position
			local pull = handle.CFrame:PointToObjectSpace(hand)
			nock.Position = rest:Lerp(pull, math.clamp(draw * 1.1, 0, 1))
			-- an arrow on the string, its point past the grip
			local from = nock.WorldPosition
			local to = handle.Position + (handle.Position - from).Unit * 0.5
			local a = nockedArrow(char)
			local mid = (from + to) / 2
			a.Size = Vector3.new(0.08, 0.08, math.max(0.5, (to - from).Magnitude))
			a.CFrame = CFrame.lookAt(mid, to)
			a.Transparency = 0
		else
			nock.Position = rest
			if arrow then arrow.Transparency = 1 end
		end
	else
		-- crossbow: spanned at the nut while loaded, sliding back from the front as it reloads
		local spanned = nock:GetAttribute("Spanned")
		if typeof(spanned) ~= "Vector3" then return end
		local reload = char == player.Character and (char:GetAttribute("LocalReload") or 0) or 0
		if char:GetAttribute("Loaded") or tool:GetAttribute("Loaded") then
			nock.Position = spanned
		elseif reload > 0 then
			nock.Position = rest:Lerp(spanned, reload)
		else
			nock.Position = rest
		end
	end
end

-- THE ARMS ARE THE POSE'S: with a bow or crossbow in hand, Roblox's own animations
-- (the "holding a tool" arm stuck straight out, the walk's arm swing) are taken off
-- the shoulders every frame before it draws, so only the archer's stance shows (it
-- used to jolt up as you walked off and drop as you stopped).
local IDENTITY = CFrame.identity
local function stillArms(c)
	local tool = c:FindFirstChildOfClass("Tool")
	if not (tool and tool:GetAttribute("Ranged")) then return end
	local torso = c:FindFirstChild("Torso")
	if not torso then return end
	for _, name in ipairs({"Right Shoulder", "Left Shoulder"}) do
		local m = torso:FindFirstChild(name)
		if m and m:IsA("Motor6D") then m.Transform = IDENTITY end
	end
end

-- (and again once the animations have stepped, whichever comes last before the frame draws)
RunService.Stepped:Connect(function()
	for _, p in ipairs(Players:GetPlayers()) do
		if p.Character then pcall(stillArms, p.Character) end
	end
end)

local acc = 0
RunService.RenderStepped:Connect(function(dt)
	acc += dt
	for _, p in ipairs(Players:GetPlayers()) do
		local c = p.Character
		if c then pcall(stillArms, c) end
		-- your own every frame (it's the one you watch); others ~30 times a second
		if c and (p == player or acc > 0.033) then pcall(update, c) end
	end
	if acc > 0.033 then acc = 0 end
	for c, a in pairs(nocked) do
		if not c.Parent then a:Destroy(); nocked[c] = nil end
	end
end)
