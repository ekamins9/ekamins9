--[[ RANGED CLIENT — the shooter's side of a bow or a crossbow (each ranged
     Tool's LocalScript calls RangedClient.attach(Tool, Config)). The server
     (Combat ▸ RangedServer) times the draw and flies the real arrow; here:

       • INPUT: bow — hold the Swing bind (left mouse) to draw, let go to loose;
         right mouse lets the draw down. Crossbow — HOLD RIGHT MOUSE to raise it
         to the shoulder and aim (zoom); click looses it, only while raised. Empty,
         it stays empty: the Reload bind (R), or a click, spans it again. Kick works
         too. On a touch screen: hold a SWING button to draw (bow) or fire / reload
         (crossbow); hold BLOCK to let down (bow) or to aim (crossbow).
       • THE AIM: the middle of the screen, through what's there, shaking a
         little (more held at full draw, on the move, or out of breath: the
         Config's SWAY_*). The reticle shows the shake and how far you've drawn.
         The arrow lands ON the point under the reticle: it's loosed on the arc
         that carries it there at its speed (Ballistics), here for your own
         arrow and on the server for the real one (it's sent the point).
       • THE POSE: local attributes the camera rig turns into arms and a stance
         everyone sees (RigPose: LocalRanged, LocalAim, LocalDraw, LocalReload)
         and a little zoom at full draw (LocalZoom).
       • Your arrow flies on your screen at once (ArrowFlight). ]]

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UIS = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local ClientSettings = require(ReplicatedStorage:WaitForChild("ClientSettings"))
local TouchInput = require(ReplicatedStorage:WaitForChild("TouchInput"))
local ArrowFlight = require(ReplicatedStorage:WaitForChild("ArrowFlight"))
local Ballistics = require(ReplicatedStorage:WaitForChild("Ballistics"))

local RangedClient = {}
RangedClient.DEFAULTS = {
	KIND = "bow", DRAW_TIME = 1.6, MIN_DRAW = 0.4, SPEED_MIN = 45, SPEED_MAX = 120, GRAVITY = 40, RELOAD = 5,
	SWAY_BASE = 0.012, SWAY_GROW = 0.025, SWAY_MAX = 0.07, HOLD_AFTER = 0.6,
}

local player = Players.LocalPlayer

--------------------------------------------------------------------
--  THE RETICLE (one, shared by every ranged weapon)
--------------------------------------------------------------------
local ret
local function reticle()
	if ret then return ret end
	local gui = Instance.new("ScreenGui")
	gui.Name = "RangedReticle"
	gui.ResetOnSpawn = false
	gui.IgnoreGuiInset = true
	gui.DisplayOrder = 30
	gui.Enabled = false
	gui.Parent = player:WaitForChild("PlayerGui")
	local root = Instance.new("Frame")
	root.AnchorPoint = Vector2.new(0.5, 0.5)
	root.Size = UDim2.fromOffset(0, 0)
	root.BackgroundTransparency = 1
	root.Parent = gui
	local dot = Instance.new("Frame")
	dot.AnchorPoint = Vector2.new(0.5, 0.5)
	dot.Size = UDim2.fromOffset(5, 5)
	dot.BackgroundColor3 = Color3.new(1, 1, 1)
	dot.BorderSizePixel = 0
	dot.Parent = root
	Instance.new("UICorner", dot).CornerRadius = UDim.new(1, 0)
	local ring = Instance.new("Frame")
	ring.AnchorPoint = Vector2.new(0.5, 0.5)
	ring.Size = UDim2.fromOffset(60, 60)
	ring.BackgroundTransparency = 1
	ring.Parent = root
	Instance.new("UICorner", ring).CornerRadius = UDim.new(1, 0)
	local stroke = Instance.new("UIStroke", ring)
	stroke.Color = Color3.new(1, 1, 1)
	stroke.Thickness = 2
	stroke.Transparency = 0.35
	local ammo = Instance.new("TextLabel")
	ammo.AnchorPoint = Vector2.new(0, 0.5)
	ammo.Position = UDim2.fromOffset(40, 26)
	ammo.Size = UDim2.fromOffset(160, 20)
	ammo.BackgroundTransparency = 1
	ammo.Font = Enum.Font.GothamBold
	ammo.TextSize = 15
	ammo.TextColor3 = Color3.new(1, 1, 1)
	ammo.TextStrokeTransparency = 0.4
	ammo.TextXAlignment = Enum.TextXAlignment.Left
	ammo.Parent = root
	ret = {gui = gui, root = root, ring = ring, stroke = stroke, ammo = ammo}
	return ret
end

function RangedClient.attach(Tool, cfgIn)
	local cfg = {}
	for k, v in pairs(RangedClient.DEFAULTS) do cfg[k] = v end
	for k, v in pairs(cfgIn or {}) do cfg[k] = v end
	local isBow = cfg.KIND ~= "crossbow"
	local remote = Tool:WaitForChild("RangedRemote", 10)
	if not remote then return end

	local equipped = false
	local drawing, drawAt = false, 0
	local lastShotAt = -1e9
	local zoom, zoomWant = 0, 0
	local aim = 0
	local reloadFrom, reloadFor = nil, cfg.RELOAD
	local aiming = false        -- crossbow: right mouse held
	local shotN = 0
	local sx, sy = 0, 0
	local conns = {}

	local function char() return player.Character end
	local function held()
		local c = char()
		return c and (c:GetAttribute("HoldUntil") or 0) > workspace:GetServerTimeNow()
	end

	-- the point under the (shaking) middle of the screen, and the way there from the head
	local aimParams = RaycastParams.new()
	aimParams.FilterType = Enum.RaycastFilterType.Exclude
	local function aimAt()
		local cam = workspace.CurrentCamera
		local c = char()
		local head = c and c:FindFirstChild("Head")
		if not (cam and head) then return nil end
		local look = (cam.CFrame * CFrame.Angles(sy, sx, 0)).LookVector
		aimParams.FilterDescendantsInstances = {c, workspace:FindFirstChild("ArrowFlights"), workspace:FindFirstChild("Arrows")}
		local res = workspace:Raycast(cam.CFrame.Position, look * 1500, aimParams)
		local target = res and res.Position or (cam.CFrame.Position + look * 1500)
		-- (nothing under it, the sky: no point to land on, it's loosed along the look)
		return res and (target - head.Position).Unit or look, target, head, res ~= nil
	end

	local function startDraw()
		if drawing or not equipped or held() then return end
		local c = char()
		if c and (c:GetAttribute("Ammo") or 1) <= 0 then return end
		if c and c:GetAttribute("Reloading") then return end   -- (still nocking the next arrow)
		drawing, drawAt = true, os.clock()
		remote:FireServer("Draw")
	end
	local function loose()
		if not equipped or held() then return end
		local c = char()
		if not c then return end
		local now = os.clock()
		local power, speed, g
		if isBow then
			if not drawing then return end
			drawing = false
			-- barely drawn: the server lets it down (no shot), so don't fly one here either
			if now - drawAt < cfg.DRAW_TIME * cfg.MIN_DRAW then remote:FireServer("Loose", Vector3.new(0, 0, -1), 0); return end
			power = math.clamp((now - drawAt) / cfg.DRAW_TIME, 0.2, 1)
			speed = cfg.SPEED_MIN + (cfg.SPEED_MAX - cfg.SPEED_MIN) * power
			g = cfg.GRAVITY * (1.4 - 0.4 * power)
		else
			if not c:GetAttribute("Loaded") or c:GetAttribute("Reloading") then return end
			speed, g = cfg.SPEED_MAX, cfg.GRAVITY
		end
		local dir, target, head, onSomething = aimAt()
		if not dir then return end
		local origin = head.Position + dir * 1.2 + Vector3.new(0, -0.2, 0)
		-- onto the arc that lands it where the reticle is
		if onSomething and (target - head.Position).Magnitude > 3 then dir, origin = Ballistics.launch(head.Position, target, speed, g) end
		shotN += 1
		remote:FireServer("Loose", dir, shotN, onSomething and target or nil)
		ArrowFlight.fly(player.UserId .. ":" .. shotN, origin, dir * speed, g, cfg.KIND, true, Tool:GetAttribute("ArrowFx"))
		lastShotAt = now
	end
	local function letDown()
		if drawing then drawing = false; remote:FireServer("Cancel") end
	end
	-- crossbow: span it again (only when it's empty and there's a bolt)
	local hintUntil, hintText = 0, ""
	local function hint(text) hintText, hintUntil = text, os.clock() + 1.6 end
	local function reload()
		if isBow or not equipped or held() then return end
		local c = char()
		if not c or c:GetAttribute("Loaded") or c:GetAttribute("Reloading") then return end
		if (c:GetAttribute("Ammo") or 0) <= 0 then hint("NO BOLTS"); return end
		remote:FireServer("Reload")
	end
	-- crossbow: a click looses it raised, reloads it empty, and asks you to raise it otherwise
	local function crossbowClick()
		local c = char()
		if not c or c:GetAttribute("Reloading") then return end
		if not c:GetAttribute("Loaded") then reload(); return end
		if not aiming or aim < 0.8 then hint("HOLD RIGHT MOUSE TO AIM"); return end
		loose()
	end

	local function swingInput(input)
		local a = ClientSettings.actionForInput(input)
		return a == "Swing" or (a == nil and input.UserInputType == Enum.UserInputType.MouseButton1)
	end
	table.insert(conns, UIS.InputBegan:Connect(function(input, gp)
		if gp or not equipped or UIS:GetFocusedTextBox() then return end
		if swingInput(input) then
			if isBow then startDraw() else crossbowClick() end
		elseif input.UserInputType == Enum.UserInputType.MouseButton2 then
			if isBow then letDown() else aiming = true end
		elseif ClientSettings.actionForInput(input) == "Reload" then
			reload()
		elseif ClientSettings.actionForInput(input) == "Kick" then
			remote:FireServer("Kick")
		end
	end))
	table.insert(conns, UIS.InputEnded:Connect(function(input)
		if not equipped then return end
		if swingInput(input) then
			if isBow then loose() end
		elseif input.UserInputType == Enum.UserInputType.MouseButton2 then
			aiming = false
		end
	end))
	table.insert(conns, TouchInput.changed:Connect(function(action, down)
		if not equipped then return end
		if action == "Swing" then
			if isBow then if down then startDraw() else loose() end
			elseif down then crossbowClick() end
		elseif action == "Block" then
			if isBow then if down then letDown() end else aiming = down end
		elseif action == "Kick" and down then
			remote:FireServer("Kick")
		end
	end))

	-- every frame: the shake, the pose, the zoom, the reticle
	table.insert(conns, RunService.RenderStepped:Connect(function(dt)
		local c = char()
		if not (equipped and c) then return end
		local now = os.clock()
		local draw = drawing and math.clamp((now - drawAt) / cfg.DRAW_TIME, 0, 1) or 0
		-- the shake
		local heldFor = drawing and math.max(0, now - drawAt - cfg.DRAW_TIME - cfg.HOLD_AFTER) or 0
		local amp = cfg.SWAY_BASE + math.min(cfg.SWAY_MAX, cfg.SWAY_GROW * heldFor)
		local hrp = c:FindFirstChild("HumanoidRootPart")
		if hrp and (hrp.AssemblyLinearVelocity * Vector3.new(1, 0, 1)).Magnitude > 2 then amp *= 1.8 end
		if c:GetAttribute("Crouching") then amp *= 0.6 end
		if (c:GetAttribute("BlockMeter") or 100) < 30 then amp *= 1.8 end
		if isBow and not drawing then amp *= 0.5 end
		-- (still pulling it back: the arm's working, the aim wanders more)
		if isBow and drawing and draw < 1 then amp *= 1.6 end
		sx = math.noise(now * 1.1, 3.7) * 2 * amp
		sy = math.noise(now * 1.3, 11.2) * 2 * amp
		-- the pose: aimed while drawing (or a moment after a shot), at the ready otherwise
		local reloading = c:GetAttribute("Reloading")
		if reloading and not reloadFrom then reloadFrom, reloadFor = now, tonumber(reloading) or cfg.RELOAD
		elseif not reloading then reloadFrom = nil end
		local aimWant
		if isBow then aimWant = (drawing or now - lastShotAt < 0.5) and 1 or 0
		else aimWant = (aiming and not reloadFrom) and 1 or 0 end   -- crossbow: raised while right mouse is held
		aim += (aimWant - aim) * math.clamp(dt * 12, 0, 1)
		c:SetAttribute("LocalRanged", isBow and 1 or 2)
		c:SetAttribute("LocalAim", aim)
		c:SetAttribute("LocalDraw", draw)
		c:SetAttribute("LocalReload", reloadFrom and math.clamp((now - reloadFrom) / reloadFor, 0, 1) or 0)
		-- the zoom: full draw (bow), the right mouse (crossbow)
		local zw = isBow and (draw >= 1 and 0.7 or draw * 0.35) or aim
		zoom += (zw - zoom) * math.clamp(dt * 8, 0, 1)
		c:SetAttribute("LocalZoom", zoom)
		-- the reticle: where the shaking aim points, a ring that closes as you draw
		local r = reticle()
		r.gui.Enabled = true
		local cam = workspace.CurrentCamera
		if cam then
			local p = cam:WorldToViewportPoint(cam.CFrame.Position + (cam.CFrame * CFrame.Angles(sy, sx, 0)).LookVector * 100)
			r.root.Position = UDim2.fromOffset(p.X, p.Y)
		end
		local ringD = isBow and (56 - 38 * draw) or 22
		r.ring.Size = UDim2.fromOffset(ringD, ringD)
		r.stroke.Color = (isBow and draw >= 1) and Color3.fromRGB(255, 214, 90) or Color3.new(1, 1, 1)
		local ammo = c:GetAttribute("Ammo") or 0
		local text, warn = nil, ammo <= 0
		if reloadFrom then text = isBow and "NOCKING…" or "RELOADING…"
		elseif now < hintUntil then text, warn = hintText, true
		elseif not isBow and not c:GetAttribute("Loaded") then
			text = ammo <= 0 and "NO BOLTS" or "EMPTY  ·  R TO RELOAD"; warn = true
		elseif ammo <= 0 then text = isBow and "NO ARROWS" or "NO BOLTS"
		else text = string.format("%d %s", ammo, isBow and "arrows" or "bolts") end
		r.ammo.Text = text
		r.ammo.TextColor3 = warn and Color3.fromRGB(255, 90, 90) or Color3.new(1, 1, 1)
		-- a crossbow not raised: a wide, dim ring (it's not pointing where you look yet)
		if not isBow then
			r.ring.Size = UDim2.fromOffset(22 + 30 * (1 - aim), 22 + 30 * (1 - aim))
			r.stroke.Transparency = 0.35 + 0.4 * (1 - aim)
		end
	end))

	local function clear()
		local c = char()
		if c then
			for _, a in ipairs({"LocalRanged", "LocalAim", "LocalDraw", "LocalReload", "LocalZoom"}) do c:SetAttribute(a, nil) end
		end
		if ret then ret.gui.Enabled = false end
	end
	table.insert(conns, Tool.Equipped:Connect(function() equipped = true; aim = 0 end))
	table.insert(conns, Tool.Unequipped:Connect(function()
		equipped = false
		letDown()
		zoomWant = 0
		aiming = false
		clear()
	end))
	if Tool.Parent == player.Character then equipped = true end
	table.insert(conns, Tool.AncestryChanged:Connect(function()
		local c = char()
		if Tool:IsDescendantOf(player) or (c and Tool:IsDescendantOf(c)) then return end
		equipped = false
		clear()
	end))
	table.insert(conns, Tool.Destroying:Connect(function()
		clear()
		for _, cn in ipairs(conns) do cn:Disconnect() end
	end))
end

return RangedClient
