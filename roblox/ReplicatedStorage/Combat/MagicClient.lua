--[[ MAGIC CLIENT — the caster's side of a staff (each staff Tool's LocalScript
     calls MagicClient.attach(Tool, Config)). The server (Combat ▸ MagicServer)
     times and resolves every cast; here:

       • INPUT (the binds every weapon uses): SWING (left mouse) casts the chosen
         spell; STAB / OVERHEAD (the scroll wheel) pick the next / the last one;
         FEINT (Q) drops a cast; BLOCK (right mouse, held) raises the WARD, which
         turns frontal blows into lost mana; KICK kicks. A controller's RT casts,
         RB / LB pick, LT wards; the touch buttons the same (TouchInput).
       • THE AIM: the middle of the screen. A bolt goes where the crosshair
         points when the cast completes (sent again at its end: "Aim").
       • THE SPELL BAR: the staff's four spells over the weapon bar, the chosen one
         lit, a sweep for each cooldown, the mana bar above them.
       • THE POSE: LocalRanged = 3 (RigPose's staff stance), LocalAim raised while
         casting or warding, LocalDraw = how far the cast has come. ]]

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UIS = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local ClientSettings = require(ReplicatedStorage:WaitForChild("ClientSettings"))
local TouchInput = require(ReplicatedStorage:WaitForChild("TouchInput"))
local Spells = require(ReplicatedStorage:WaitForChild("MagicSpells"))
local Theme = require(ReplicatedStorage:WaitForChild("Theme"))

local MagicClient = {}
local player = Players.LocalPlayer

--------------------------------------------------------------------
--  THE SPELL BAR (one, shared by every staff)
--------------------------------------------------------------------
local bar
local function spellBar()
	if bar then return bar end
	local gui = Instance.new("ScreenGui")
	gui.Name = "SpellBar"
	gui.ResetOnSpawn = false
	gui.IgnoreGuiInset = true
	gui.DisplayOrder = 29
	gui.Enabled = false
	gui.Parent = player:WaitForChild("PlayerGui")
	local root = Instance.new("Frame")
	root.AnchorPoint = Vector2.new(0.5, 1)
	root.Position = UDim2.new(0.5, 0, 1, -122)
	root.Size = UDim2.fromOffset(4 * 64 + 3 * 8, 86)
	root.BackgroundTransparency = 1
	root.Parent = gui
	local sc = Instance.new("UIScale", root)
	-- the mana bar
	local mana = Instance.new("Frame")
	mana.Size = UDim2.new(1, 0, 0, 14)
	mana.BackgroundColor3 = Color3.fromRGB(12, 14, 30)
	mana.BorderSizePixel = 0
	mana.Parent = root
	Instance.new("UICorner", mana).CornerRadius = UDim.new(1, 0)
	local stroke = Instance.new("UIStroke", mana); stroke.Color = Color3.fromRGB(120, 160, 255); stroke.Transparency = 0.4
	local fill = Instance.new("Frame")
	fill.Size = UDim2.fromScale(1, 1)
	fill.BackgroundColor3 = Color3.fromRGB(80, 140, 255)
	fill.BorderSizePixel = 0
	fill.Parent = mana
	Instance.new("UICorner", fill).CornerRadius = UDim.new(1, 0)
	do local g = Instance.new("UIGradient", fill); g.Color = ColorSequence.new(Color3.fromRGB(120, 90, 255), Color3.fromRGB(90, 200, 255)) end
	local manaText = Instance.new("TextLabel")
	manaText.BackgroundTransparency = 1; manaText.Size = UDim2.fromScale(1, 1); manaText.Font = Theme.FONT_TITLE; manaText.TextSize = 11
	manaText.TextColor3 = Color3.new(1, 1, 1); manaText.Text = "MANA"; manaText.ZIndex = 3; manaText.Parent = mana
	do local s = Instance.new("UIStroke", manaText); s.Color = Theme.OUTLINE; s.Thickness = 1.4 end
	-- the slots
	local slots = {}
	for i = 1, 4 do
		local s = Instance.new("Frame")
		s.Position = UDim2.fromOffset((i - 1) * 72, 22)
		s.Size = UDim2.fromOffset(64, 64)
		s.BackgroundColor3 = Color3.fromRGB(16, 20, 36)
		s.BackgroundTransparency = 0.1
		s.Parent = root
		Instance.new("UICorner", s).CornerRadius = UDim.new(0, 12)
		local st = Instance.new("UIStroke", s); st.Thickness = 2; st.Transparency = 0.5
		local glyph = Instance.new("TextLabel")
		glyph.BackgroundTransparency = 1; glyph.Size = UDim2.new(1, 0, 1, -14); glyph.Position = UDim2.fromOffset(0, 2)
		glyph.Font = Theme.FONT_TITLE; glyph.TextScaled = true; glyph.TextColor3 = Color3.new(1, 1, 1); glyph.Parent = s
		local cost = Instance.new("TextLabel")
		cost.BackgroundTransparency = 1; cost.AnchorPoint = Vector2.new(0.5, 1); cost.Position = UDim2.new(0.5, 0, 1, -2); cost.Size = UDim2.new(1, -6, 0, 13)
		cost.Font = Theme.FONT_TITLE; cost.TextSize = 11; cost.TextColor3 = Color3.fromRGB(150, 190, 255); cost.Parent = s
		local cd = Instance.new("Frame")
		cd.AnchorPoint = Vector2.new(0, 1); cd.Position = UDim2.fromScale(0, 1); cd.Size = UDim2.fromScale(1, 0)
		cd.BackgroundColor3 = Color3.new(0, 0, 0); cd.BackgroundTransparency = 0.35; cd.BorderSizePixel = 0; cd.ZIndex = 4; cd.Parent = s
		Instance.new("UICorner", cd).CornerRadius = UDim.new(0, 12)
		local scale = Instance.new("UIScale", s)
		slots[i] = {frame = s, stroke = st, glyph = glyph, cost = cost, cd = cd, scale = scale}
	end
	local name = Instance.new("TextLabel")
	-- (the chosen spell's name over the mana bar: under the slots sit the health and energy bars)
	name.BackgroundTransparency = 1; name.AnchorPoint = Vector2.new(0.5, 1); name.Position = UDim2.new(0.5, 0, 0, -4); name.Size = UDim2.new(1, 120, 0, 16)
	name.Font = Theme.FONT_TITLE; name.TextSize = 14; name.TextColor3 = Color3.new(1, 1, 1); name.Parent = root
	do local s = Instance.new("UIStroke", name); s.Color = Theme.OUTLINE; s.Thickness = 1.6 end
	bar = {gui = gui, root = root, scale = sc, fill = fill, manaText = manaText, manaStroke = stroke, slots = slots, name = name}
	return bar
end

--------------------------------------------------------------------
--  A STAFF
--------------------------------------------------------------------
function MagicClient.attach(Tool, cfg)
	cfg = cfg or {}
	local remote = Tool:WaitForChild("MagicRemote", 10)
	if not remote then return end
	local book = {}
	for _, id in ipairs(cfg.SPELLS or Spells.ORDER) do if Spells[id] then table.insert(book, id) end end
	local chosen = 1
	local equipped = false
	local castUntil, castFrom, castId = 0, 0, nil
	local warding = false
	local readyAt = {}
	local noManaFlash = 0
	local aim = 0
	local conns = {}
	local function char() return Tool.Parent and Tool.Parent:FindFirstChildOfClass("Humanoid") and Tool.Parent or nil end

	-- where the crosshair points
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	local function aimPoint()
		local cam = workspace.CurrentCamera
		local c = char()
		if not (cam and c) then return nil end
		params.FilterDescendantsInstances = {c}
		local o, d = cam.CFrame.Position, cam.CFrame.LookVector
		local res = workspace:Raycast(o, d * 600, params)
		return res and res.Position or (o + d * 600)
	end

	local function cast()
		if not equipped then return end
		local c = char()
		if not c or os.clock() < castUntil or warding then return end
		local id = book[chosen]
		local sp = id and Spells[id]
		if not sp then return end
		if os.clock() < (readyAt[id] or 0) then return end
		if (c:GetAttribute("Mana") or 0) < sp.mana then noManaFlash = os.clock(); return end
		castId, castFrom, castUntil = id, os.clock(), os.clock() + sp.cast
		remote:FireServer("Cast", id, aimPoint())
		-- the crosshair at the end of the cast is where it goes
		task.delay(math.max(0, sp.cast - 0.03), function()
			if castId == id and equipped then remote:FireServer("Aim", aimPoint()) end
		end)
	end
	local function cancel()
		if os.clock() < castUntil then castUntil = 0; castId = nil; remote:FireServer("Cancel") end
	end
	local function pick(step)
		if #book == 0 then return end
		chosen = (chosen - 1 + step) % #book + 1
		local b = spellBar()
		local sl = b.slots[chosen]
		if sl then sl.scale.Scale = 1.18; TweenService:Create(sl.scale, TweenInfo.new(0.18, Enum.EasingStyle.Back), {Scale = 1}):Play() end
	end
	local function ward(on)
		if warding == on then return end
		warding = on
		if on then cancel() end
		remote:FireServer("Ward", on)
	end

	table.insert(conns, remote.OnClientEvent:Connect(function(what, id, cd)
		if what == "Cast" then readyAt[id] = os.clock() + (tonumber(cd) or 0); castId = nil
		elseif what == "NoMana" then noManaFlash = os.clock(); castUntil = 0; castId = nil end
	end))

	local function isSwing(input)
		local a = ClientSettings.actionForInput(input)
		return a == "Swing" or (a == nil and input.UserInputType == Enum.UserInputType.MouseButton1)
	end
	table.insert(conns, UIS.InputBegan:Connect(function(input, gp)
		if gp or not equipped or UIS:GetFocusedTextBox() then return end
		local a = ClientSettings.actionForInput(input)
		if isSwing(input) then cast()
		elseif input.UserInputType == Enum.UserInputType.MouseButton2 then ward(true)
		elseif a == "Stab" or a == "Underhand" then pick(1)
		elseif a == "Overhead" then pick(-1)
		elseif a == "Feint" then cancel()
		elseif a == "Kick" then remote:FireServer("Kick") end
	end))
	table.insert(conns, UIS.InputEnded:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton2 then ward(false) end
	end))
	-- the scroll wheel picks
	table.insert(conns, UIS.InputChanged:Connect(function(input, gp)
		if gp or not equipped or input.UserInputType ~= Enum.UserInputType.MouseWheel then return end
		local a = ClientSettings.actionForInput(input)
		if a == "Stab" then pick(1) elseif a == "Overhead" then pick(-1) end
	end))
	-- a controller's or a touch screen's buttons (TouchInput)
	table.insert(conns, TouchInput.changed:Connect(function(action, down)
		if not equipped then return end
		if action == "Block" then ward(down == true); return end
		if not down then return end
		if action == "Swing" then cast()
		elseif action == "Stab" or action == "Underhand" then pick(1)
		elseif action == "Overhead" then pick(-1)
		elseif action == "Feint" then cancel()
		elseif action == "Kick" then remote:FireServer("Kick") end
	end))

	-- every frame: the pose and the spell bar
	table.insert(conns, RunService.RenderStepped:Connect(function(dt)
		local c = char()
		if not (equipped and c) then return end
		local now = os.clock()
		local casting = now < castUntil
		local want = (casting or warding or (castId == nil and now - castFrom < 0.35)) and 1 or 0
		aim += (want - aim) * math.clamp(dt * 12, 0, 1)
		c:SetAttribute("LocalRanged", 3)
		c:SetAttribute("LocalAim", aim)
		local sp = castId and Spells[castId]
		c:SetAttribute("LocalDraw", (casting and sp) and math.clamp((now - castFrom) / sp.cast, 0, 1) or 0)
		-- (no mana left to hold it: the ward drops)
		if warding and not c:GetAttribute("Warded") and (c:GetAttribute("Mana") or 0) <= 4 then warding = false end
		local b = spellBar()
		b.gui.Enabled = true
		local cam = workspace.CurrentCamera
		if cam then b.scale.Scale = math.clamp(cam.ViewportSize.Y / 900, 0.75, 1.3) end
		local max = c:GetAttribute("MaxMana") or Spells.MAX_MANA
		local mana = c:GetAttribute("Mana") or max
		b.fill.Size = UDim2.fromScale(math.clamp(mana / max, 0, 1), 1)
		b.manaText.Text = string.format("MANA  %d / %d", math.floor(mana + 0.5), max)
		local flash = now - noManaFlash < 0.6
		b.manaStroke.Color = flash and Color3.fromRGB(255, 80, 80) or Color3.fromRGB(120, 160, 255)
		b.manaStroke.Transparency = flash and 0 or 0.4
		for i, sl in ipairs(b.slots) do
			local id = book[i]
			local s = id and Spells[id]
			sl.frame.Visible = s ~= nil
			if s then
				sl.glyph.Text = s.glyph or "?"
				sl.cost.Text = tostring(s.mana)
				local on = i == chosen
				sl.stroke.Color = on and (s.color or Color3.new(1, 1, 1)) or Color3.new(1, 1, 1)
				sl.stroke.Transparency = on and 0 or 0.7
				sl.frame.BackgroundColor3 = on and Color3.fromRGB(34, 40, 70) or Color3.fromRGB(16, 20, 36)
				local left = math.max(0, (readyAt[id] or 0) - now)
				sl.cd.Size = UDim2.fromScale(1, math.clamp(left / math.max(s.cooldown or 1, 0.1), 0, 1))
				sl.glyph.TextTransparency = (mana < s.mana) and 0.6 or 0
			end
		end
		local cur = Spells[book[chosen] or ""]
		b.name.Text = cur and (string.upper(cur.name) .. (casting and "  ·  CASTING…" or "")) or ""
		b.name.TextColor3 = cur and (cur.glow or Color3.new(1, 1, 1)) or Color3.new(1, 1, 1)
	end))

	local function clear()
		local c = char() or player.Character
		if c then for _, a in ipairs({"LocalRanged", "LocalAim", "LocalDraw"}) do c:SetAttribute(a, nil) end end
		if bar then bar.gui.Enabled = false end
	end
	table.insert(conns, Tool.Equipped:Connect(function() equipped = true; aim = 0 end))
	table.insert(conns, Tool.Unequipped:Connect(function()
		equipped = false
		if warding then warding = false end
		castUntil = 0; castId = nil
		clear()
	end))
	table.insert(conns, Tool.Destroying:Connect(function()
		clear()
		for _, cn in ipairs(conns) do cn:Disconnect() end
	end))
end

return MagicClient
