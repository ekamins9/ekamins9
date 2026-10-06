--[[ COURTYARD (client) — your side of the hub's places (Hub ▸ Courtyard on the
     server):
       • THE GATES OF WAR: E at a gate travels (Warfront, the Training Yard) or
         opens PLAY's mode board (The Lists: pick a bracket first)
       • E at the Merchant's Stall opens the SHOP; at the Notice Board, TASKS
       • THE NOTICE BOARD shows YOUR tasks, the next playtime gift and your
         pass tier, written on its parchment just for you
       • a wish at the fountain: a coin flies into the water and the wisher's
         luck floats over their head, for everyone to see ]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ProximityPromptService = game:GetService("ProximityPromptService")
local TweenService = game:GetService("TweenService")
local Debris = game:GetService("Debris")

local Catalog = require(ReplicatedStorage:WaitForChild("Catalog"))

local player = Players.LocalPlayer
local hubRemote = ReplicatedStorage:WaitForChild("HubRemote")
local event = ReplicatedStorage:WaitForChild("CourtyardEvent")
_G.MenuBus = _G.MenuBus or Instance.new("BindableEvent")

local function call(op, ...)
	local ok, res = pcall(hubRemote.InvokeServer, hubRemote, op, ...)
	if ok and type(res) == "table" then return res end
	return {ok = false, msg = ok and "no answer" or tostring(res)}
end

--------------------------------------------------------------------
--  PROMPTS: gates, the stall, the board
--------------------------------------------------------------------
ProximityPromptService.PromptTriggered:Connect(function(prompt)
	local gate = prompt:GetAttribute("Gate")
	if gate == "Warfront" or gate == "Training" then
		-- through the menu, so a new player is offered the training first
		_G.MenuBus:Fire("PlayDoor", gate == "Training" and "Tiltyard" or "Warfront")
	elseif gate == "Lists" then
		_G.MenuBus:Fire("OpenHub", "MODES")
	end
	local open = prompt:GetAttribute("Open")
	if open then _G.MenuBus:Fire("OpenHub", open) end
end)

--------------------------------------------------------------------
--  THE NOTICE BOARD (your own parchment)
--------------------------------------------------------------------
local board = Instance.new("SurfaceGui")
board.Name = "NoticeBoard"
board.Face = Enum.NormalId.Front
board.CanvasSize = Vector2.new(470, 295)
board.LightInfluence = 0.4
board.ResetOnSpawn = false
board.Parent = player:WaitForChild("PlayerGui")

local INK = Color3.fromRGB(58, 38, 22)
local function ink(text, x, y, w, h, size, color, font, align)
	local l = Instance.new("TextLabel")
	l.BackgroundTransparency = 1
	l.Position, l.Size = UDim2.fromOffset(x, y), UDim2.fromOffset(w, h)
	l.Font = font or Enum.Font.Antique
	l.TextSize = size or 18
	l.TextColor3 = color or INK
	l.TextXAlignment = align or Enum.TextXAlignment.Left
	l.TextTruncate = Enum.TextTruncate.AtEnd
	l.Text = text
	l.Parent = board
	return l
end
local function bar(x, y, w, frac, done)
	local back = Instance.new("Frame")
	back.BackgroundColor3 = Color3.fromRGB(176, 150, 106); back.BorderSizePixel = 0
	back.Position, back.Size = UDim2.fromOffset(x, y), UDim2.fromOffset(w, 8)
	back.Parent = board
	local f = Instance.new("Frame")
	f.BackgroundColor3 = done and Color3.fromRGB(60, 140, 60) or Color3.fromRGB(150, 50, 40); f.BorderSizePixel = 0
	f.Size = UDim2.fromScale(math.clamp(frac, 0, 1), 1)
	f.Parent = back
end

local lastBoard = 0
local function drawBoard(st)
	board:ClearAllChildren()
	ink("NOTICES  ·  " .. string.upper(player.DisplayName), 16, 8, 440, 28, 24, Color3.fromRGB(120, 30, 24), Enum.Font.Antique, Enum.TextXAlignment.Center)
	local y = 44
	local daily = {}
	for _, ct in ipairs(st.contracts or {}) do if not ct.weekly then table.insert(daily, ct) end end
	for _, ct in ipairs(st.contracts or {}) do if ct.weekly then table.insert(daily, ct) end end
	if #daily == 0 then ink("No tasks posted yet.", 20, y, 420, 22, 18); y += 28 end
	for _, ct in ipairs(daily) do
		local goal = ct.goal or 1
		local n = math.min(ct.n or 0, goal)
		ink((ct.weekly and "WEEKLY: " or "• ") .. (ct.text or ct.id or "a task"), 20, y, 330, 22, 17, ct.done and Color3.fromRGB(60, 120, 60) or INK)
		ink(ct.done and "DONE" or string.format("%d / %d", n, goal), 352, y, 100, 22, 16, ct.done and Color3.fromRGB(60, 120, 60) or INK, Enum.Font.Antique, Enum.TextXAlignment.Right)
		bar(22, y + 23, 428, n / goal, ct.done)
		y += 38
	end
	-- the next playtime gift and the pass
	local claimed = {}
	for k in (player:GetAttribute("GiftsClaimed") or ""):gmatch("[^,]+") do claimed[k] = true end
	local played = player:GetAttribute("PlaySeconds") or 0
	local giftLine = "All of today's gifts are claimed."
	for i, g in ipairs(Catalog.GIFTS.gifts) do
		if not claimed[tostring(i)] then
			local left = g.minutes * 60 - played
			giftLine = left <= 0 and "A playtime gift is waiting! (top left)" or string.format("Next playtime gift in %d min.", math.ceil(left / 60))
			break
		end
	end
	ink(giftLine, 20, math.max(y + 6, 226), 430, 22, 17)
	local ps = st.pass
	if ps then ink(string.format("Season pass: tier %d%s", ps.tier or 0, ps.premium and " · premium" or ""), 20, math.max(y + 32, 252), 430, 22, 17) end
end

task.spawn(function()
	while true do
		local m = workspace:FindFirstChild("Map")
		local face = m and m:FindFirstChild("NoticeFace")
		board.Adornee = face
		board.Enabled = face ~= nil
		if face and os.clock() - lastBoard > 40 then
			lastBoard = os.clock()
			local st = call("State")
			if st.ok then drawBoard(st) end
		end
		task.wait(2)
	end
end)

--------------------------------------------------------------------
--  A WISH
--------------------------------------------------------------------
event.OnClientEvent:Connect(function(what, plr, line)
	if what ~= "Wish" or typeof(plr) ~= "Instance" then return end
	local char = plr.Character
	local hrp = char and char:FindFirstChild("HumanoidRootPart")
	local m = workspace:FindFirstChild("Map")
	local well = m and m:FindFirstChild("Spots") and m.Spots:FindFirstChild("WellSpot")
	if not (hrp and well) then return end
	-- the coin: an arc from the hand to the water
	local from = hrp.Position + Vector3.new(0, 1.5, 0)
	local to = Vector3.new(well.Position.X, well.Position.Y - 0.3, well.Position.Z) + (from - well.Position) * Vector3.new(0.35, 0, 0.35)
	local coin = Instance.new("Part")
	coin.Shape = Enum.PartType.Cylinder; coin.Size = Vector3.new(0.12, 0.6, 0.6); coin.Color = Color3.fromRGB(255, 200, 60); coin.Material = Enum.Material.Metal
	coin.Anchored, coin.CanCollide, coin.CanQuery, coin.CanTouch = true, false, false, false
	coin.Parent = workspace
	local t0 = os.clock()
	local conn
	conn = game:GetService("RunService").RenderStepped:Connect(function()
		local a = math.min(1, (os.clock() - t0) / 0.7)
		local p = from:Lerp(to, a) + Vector3.new(0, math.sin(a * math.pi) * 5, 0)
		coin.CFrame = CFrame.new(p) * CFrame.Angles(0, 0, a * 20)
		if a >= 1 then
			conn:Disconnect()
			coin:Destroy()
			-- the splash: a ring on the water and a sparkle
			local ring = Instance.new("Part")
			ring.Shape = Enum.PartType.Cylinder; ring.Size = Vector3.new(0.05, 1, 1); ring.Color = Color3.fromRGB(220, 240, 255); ring.Material = Enum.Material.Neon
			ring.Anchored, ring.CanCollide, ring.CanQuery = true, false, false
			ring.CFrame = CFrame.new(to + Vector3.new(0, 0.35, 0)) * CFrame.Angles(0, 0, math.pi / 2)
			ring.Transparency = 0.2
			ring.Parent = workspace
			TweenService:Create(ring, TweenInfo.new(0.9), {Size = Vector3.new(0.05, 7, 7), Transparency = 1}):Play()
			Debris:AddItem(ring, 1)
			local a0 = Instance.new("Attachment"); a0.WorldPosition = to + Vector3.new(0, 0.6, 0); a0.Parent = workspace.Terrain
			local e = Instance.new("ParticleEmitter"); e.Texture = "rbxasset://textures/particles/sparkles_main.dds"; e.Color = ColorSequence.new(Color3.fromRGB(255, 220, 120))
			e.Size = NumberSequence.new(0.4, 0); e.Lifetime = NumberRange.new(0.6, 1.1); e.Speed = NumberRange.new(4, 9); e.SpreadAngle = Vector2.new(40, 40); e.Rate = 0
			e.Acceleration = Vector3.new(0, -10, 0); e.LightEmission = 0.8; e.Parent = a0
			e:Emit(40)
			Debris:AddItem(a0, 2)
		end
	end)
	-- the luck, floating over the wisher
	if char:FindFirstChild("Head") then
		local bb = Instance.new("BillboardGui")
		bb.Size = UDim2.fromOffset(280, 40); bb.StudsOffsetWorldSpace = Vector3.new(0, 3, 0); bb.Adornee = char.Head; bb.AlwaysOnTop = true
		bb.Parent = player:WaitForChild("PlayerGui")
		local l = Instance.new("TextLabel")
		l.BackgroundTransparency = 1; l.Size = UDim2.fromScale(1, 1); l.Font = Enum.Font.FredokaOne; l.TextScaled = true
		l.TextColor3 = Color3.fromRGB(255, 220, 110); l.Text = "✨ " .. tostring(line or "") .. " ✨"; l.Parent = bb
		local s = Instance.new("UIStroke"); s.Color = Color3.fromRGB(40, 24, 8); s.Thickness = 2; s.Parent = l
		TweenService:Create(bb, TweenInfo.new(3, Enum.EasingStyle.Quad), {StudsOffsetWorldSpace = Vector3.new(0, 6, 0)}):Play()
		task.delay(2.4, function() TweenService:Create(l, TweenInfo.new(0.6), {TextTransparency = 1}):Play() end)
		Debris:AddItem(bb, 3.1)
	end
end)
