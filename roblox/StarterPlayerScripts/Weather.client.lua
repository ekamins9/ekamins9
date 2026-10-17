--[[ WEATHER — rain, storms, snow, embers and petals on the maps that have them (GameConfig ▸
     MAP_WEATHER, a mode's own MODE_WEATHER first), drawn round your camera by ReplicatedStorage ▸
     WarFX (none in your face under a roof). Changes with the map; War and the Prologue draw their
     own, the Hub and the dungeon game have none.
     COLD BREATH: where it's cold (snow falling, a winter map, War's Frostmere, the Frozen Depths)
     everyone's breath shows: a small white puff from each player's mouth every few seconds. ]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local GameConfig = require(ReplicatedStorage:WaitForChild("GameConfig"))
local WarFX = require(ReplicatedStorage:WaitForChild("WarFX"))
local round = ReplicatedStorage:WaitForChild("Round")

local OWN = {War = true, Prologue = true, Hub = true, Tavern = true, Deadvault = true, Depths = true}
local current = nil

local function want()
	local mode = round:GetAttribute("Mode") or ""
	if OWN[mode] then return false end
	return GameConfig.MODE_WEATHER[mode] or GameConfig.MAP_WEATHER[round:GetAttribute("Map") or ""]
end

local function apply()
	local w = want()
	if w == false then
		-- (a mode with its own weather: leave it be, only let go of ours)
		-- (only if what's up is still ours: the Prologue may have set its storm already)
		if current and WarFX.weatherKind() == current then WarFX.weather(nil, 2) end
		current = nil
		return
	end
	-- (still up? leaving War, say, clears all of WarFX's weather)
	if w == current and WarFX.weatherKind() == w then return end
	current = w
	WarFX.weather(w, 2)
end
round:GetAttributeChangedSignal("Map"):Connect(apply)
round:GetAttributeChangedSignal("Mode"):Connect(apply)
apply()

--------------------------------------------------------------------
--  COLD BREATH
--------------------------------------------------------------------
local Players = game:GetService("Players")
local COLD_THEME = {winter = true, winterNight = true, FrozenDepths = true, Frostmere = true}
local function cold()
	if WarFX.weatherKind() == "snow" then return true end
	local m = workspace:FindFirstChild("Map")
	if not m then return false end
	return COLD_THEME[m:GetAttribute("Theme") or ""] or COLD_THEME[m:GetAttribute("W_Theme") or ""] or false
end
local puffs = setmetatable({}, {__mode = "k"})   -- head -> emitter
local function emitterOn(head)
	local e = puffs[head]
	if e and e.Parent then return e end
	local a = Instance.new("Attachment")
	a.Name = "Breath"
	a.Position = Vector3.new(0, -0.25, -0.65)
	a.Parent = head
	e = Instance.new("ParticleEmitter")
	e.Texture = "rbxasset://textures/particles/smoke_main.dds"
	e.Rate = 0
	e.Lifetime = NumberRange.new(1, 1.6)
	e.Speed = NumberRange.new(1.2, 2)
	e.SpreadAngle = Vector2.new(14, 14)
	e.EmissionDirection = Enum.NormalId.Front
	e.Acceleration = Vector3.new(0, 0.6, 0)
	e.Drag = 2
	e.Size = NumberSequence.new({NumberSequenceKeypoint.new(0, 0.15), NumberSequenceKeypoint.new(1, 0.9)})
	e.Transparency = NumberSequence.new({NumberSequenceKeypoint.new(0, 0.55), NumberSequenceKeypoint.new(1, 1)})
	e.Color = ColorSequence.new(Color3.fromRGB(240, 244, 250))
	e.LightInfluence = 0.8
	e.Parent = a
	puffs[head] = e
	return e
end
task.spawn(function()
	local beat = {}
	while true do
		task.wait(0.5)
		if cold() then
			local now = os.clock()
			for _, p in ipairs(Players:GetPlayers()) do
				local c = p.Character
				local head = c and c:FindFirstChild("Head")
				local h = c and c:FindFirstChildOfClass("Humanoid")
				if head and h and h.Health > 0 and now >= (beat[p] or 0) then
					-- (a bit quicker when you're running)
					local fast = h.MoveDirection.Magnitude > 0.5
					beat[p] = now + (fast and 1.8 or 3.2) + math.random() * 0.8
					emitterOn(head):Emit(fast and 3 or 2)
				end
			end
		end
	end
end)
