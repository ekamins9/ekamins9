--[[ BATTLE'S END — a two-sided battle won (TDM, the Standard, the hill, LTS…; the massive battle's
     finale is War.client's, a siege's SiegeEpic's): before the board and the vote, a few seconds on
     the field. The camera glides down from wherever it was to the winning side as they raise their
     weapons and roar (their bots cheer, the beaten go to a knee: Game ▸ BotFill), and a horn
     sounds. _G.FinaleCamera holds the Hub menu's orbit off meanwhile; _G.BoardHoldUntil holds back
     the board and the class screen (Scoreboard, LoadoutMenu). The result's band (RoundResult) is
     over it all. Nothing is sent to the server. ]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local GameConfig = require(ReplicatedStorage:WaitForChild("GameConfig"))
local WarFX = require(ReplicatedStorage:WaitForChild("WarFX"))

local player = Players.LocalPlayer
local round = ReplicatedStorage:WaitForChild("Round")
local HOLD = 4.6
local OWN_FINALE = {War = true, Siege = true}

local on = false
local function stop()
	if not on then return end
	on = false
	_G.FinaleCamera = nil
	pcall(function() RunService:UnbindFromRenderStep("BattleEnd") end)
	local cam = workspace.CurrentCamera
	if cam then cam.FieldOfView = 70 end
end

-- where the winners stand thickest: the middle of the biggest knot of them, and which way they face
local function winnersAt(key)
	local pts, looks = {}, {}
	local npcs = workspace:FindFirstChild("NPCs")
	for _, m in ipairs(npcs and npcs:GetChildren() or {}) do
		local h, r = m:FindFirstChildOfClass("Humanoid"), m:FindFirstChild("HumanoidRootPart")
		if h and r and h.Health > 0 and m:GetAttribute("Team") == key then table.insert(pts, r.Position); table.insert(looks, r.CFrame.LookVector) end
	end
	for _, p in ipairs(Players:GetPlayers()) do
		local c = p.Character
		local h, r = c and c:FindFirstChildOfClass("Humanoid"), c and c:FindFirstChild("HumanoidRootPart")
		if h and r and h.Health > 0 and c:GetAttribute("Team") == key then table.insert(pts, r.Position); table.insert(looks, r.CFrame.LookVector) end
	end
	local best, bestN, bestLook = nil, 0, nil
	for _, a in ipairs(pts) do
		local sum, n, look = Vector3.zero, 0, Vector3.zero
		for i, b in ipairs(pts) do
			if (a - b).Magnitude < 16 then sum += b; n += 1; look += looks[i] end
		end
		if n > bestN then best, bestN, bestLook = sum / n, n, look end
	end
	return best, bestN, bestLook
end

local function start()
	local mode = round:GetAttribute("Mode") or ""
	local def = GameConfig.MODES[mode]
	if not def or def.teams ~= 2 or def.ownSpawn or OWN_FINALE[mode] then return end
	local winner = round:GetAttribute("Winner") or ""
	local key = nil
	for k, d in pairs(GameConfig.TEAMS) do if d.name == winner then key = k end end
	if not key then return end
	_G.BoardHoldUntil = math.max(_G.BoardHoldUntil or 0, os.clock() + HOLD)
	WarFX.sound("Horn", nil, {volume = 0.75})
	local centre, _, facing = winnersAt(key)
	if not centre then return end
	local cam = workspace.CurrentCamera
	if not cam then return end
	on = true
	_G.FinaleCamera = true
	-- (down to them from where the camera was, to a little way off in front of them, at about
	-- head height: the way they face, or failing that from where the camera was)
	local from = cam.CFrame
	local away = facing and Vector3.new(facing.X, 0, facing.Z) or Vector3.zero
	if away.Magnitude < 0.5 then away = Vector3.new(from.Position.X - centre.X, 0, from.Position.Z - centre.Z) end
	if away.Magnitude < 1e-3 then away = Vector3.new(1, 0, 1) end
	local yaw0 = math.atan2(away.Z, away.X)
	local t0 = os.clock()
	RunService:BindToRenderStep("BattleEnd", Enum.RenderPriority.Camera.Value + 6, function()
		local c = workspace.CurrentCamera
		if not c then return end
		local t = os.clock() - t0
		if t > HOLD then stop(); return end
		local yaw = yaw0 + t * 0.07
		local shot = CFrame.lookAt(centre + Vector3.new(math.cos(yaw) * 13, 5 - t * 0.25, math.sin(yaw) * 13), centre + Vector3.new(0, 2.2, 0))
		local k = math.clamp(t / 1.4, 0, 1)
		k = k * k * (3 - 2 * k)
		c.CameraType = Enum.CameraType.Scriptable
		c.CFrame = from:Lerp(shot, k)
		c.FieldOfView = 70 + (52 - 70) * k
	end)
end

round:GetAttributeChangedSignal("State"):Connect(function()
	if round:GetAttribute("State") == "Intermission" then
		-- (the result attributes land the same frame: a beat for them)
		task.delay(0.05, start)
	else
		stop()
	end
end)
