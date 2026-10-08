--[[ MAGIC CLIENT — the caster's side of a magic weapon (each Staff / Tome / Wand Tool's
     LocalScript calls MagicClient.attach(Tool, Config)). The server (Combat ▸
     MagicServer) times and resolves every cast; here:

       • INPUT (the binds every weapon uses): SWING (left mouse) casts the chosen
         spell; STAB / OVERHEAD (the scroll wheel) pick the next / the last one;
         FEINT (Q) drops a cast; BLOCK (right mouse, held) raises a Staff's WARD;
         RELOAD (R, held) MEDITATES (stand still: the only way mana comes back); KICK
         kicks. A controller: RT casts, RB / LB pick, LT wards, Y cancels or (held)
         meditates; the touch buttons the same (TouchInput). A Staff's melee self is
         the Stance bind (H / D-pad ←: LoadoutServer swaps the twin in).
       • THE AIM: the middle of the screen. A spell goes where the crosshair points
         when the cast completes (sent again at its end: "Aim"). The crosshair says
         what the spell wants: someone to hit, the ground, an ally, or nothing (it's
         round you); red past its reach, dim while it can't be cast.
       • THE SPELL BAR: your arsenal (the Tool's Spells attribute: LOADOUT ▸ SPELLS),
         the chosen one lit, a sweep for each cooldown, the mana bar above them and,
         when it's low, how to meditate.
       • THE POSE: LocalRanged = the weapon's STANCE (RigPose: 3 staff, 4 tome, 5
         wand), LocalAim = the lift (it rises slowly while you cast, ward or meditate,
         and sinks when you stop: a staff comes up off the ground), LocalDraw = how
         far the cast has come. ]]

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UIS = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local ClientSettings = require(ReplicatedStorage:WaitForChild("ClientSettings"))
local TouchInput = require(ReplicatedStorage:WaitForChild("TouchInput"))
local Spells = require(ReplicatedStorage:WaitForChild("MagicSpells"))
local Theme = require(ReplicatedStorage:WaitForChild("Theme"))
local InputHints = require(ReplicatedStorage:WaitForChild("InputHints"))

local MagicClient = {}
local player = Players.LocalPlayer
local MAX_SLOTS = 5
local LIFT_UP, LIFT_DOWN = 2.6, 3.4   -- how fast the lift rises / sinks (per second, eased)

--------------------------------------------------------------------
--  THE SPELL BAR (one, shared by every magic weapon)
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
	root.Size = UDim2.fromOffset(MAX_SLOTS * 64 + (MAX_SLOTS - 1) * 8, 86)
	root.BackgroundTransparency = 1
	root.Parent = gui
	local sc = Instance.new("UIScale", root)
	-- the mana bar
	local mana = Instance.new("Frame")
	mana.AnchorPoint = Vector2.new(0.5, 0); mana.Position = UDim2.fromScale(0.5, 0)
	mana.Size = UDim2.new(0, 4 * 64 + 3 * 8, 0, 14)
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
	local row = Instance.new("Frame")
	row.BackgroundTransparency = 1; row.Position = UDim2.fromOffset(0, 22); row.Size = UDim2.new(1, 0, 0, 64)
	row.Parent = root
	local lay = Instance.new("UIListLayout", row); lay.FillDirection = Enum.FillDirection.Horizontal; lay.HorizontalAlignment = Enum.HorizontalAlignment.Center
	lay.Padding = UDim.new(0, 8); lay.SortOrder = Enum.SortOrder.LayoutOrder
	local slots = {}
	for i = 1, MAX_SLOTS do
		local s = Instance.new("Frame")
		s.LayoutOrder = i
		s.Size = UDim2.fromOffset(64, 64)
		s.BackgroundColor3 = Color3.fromRGB(16, 20, 36)
		s.BackgroundTransparency = 0.1
		s.Parent = row
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
	-- (the chosen spell's name over the mana bar: under the slots sit the health and energy bars)
	local name = Instance.new("TextLabel")
	name.BackgroundTransparency = 1; name.AnchorPoint = Vector2.new(0.5, 1); name.Position = UDim2.new(0.5, 0, 0, -4); name.Size = UDim2.new(1, 120, 0, 16)
	name.Font = Theme.FONT_TITLE; name.TextSize = 14; name.TextColor3 = Color3.new(1, 1, 1); name.Parent = root
	do local s = Instance.new("UIStroke", name); s.Color = Theme.OUTLINE; s.Thickness = 1.6 end
	-- how to get mana back (shown when it's low)
	local tip = Instance.new("TextLabel")
	tip.BackgroundTransparency = 1; tip.AnchorPoint = Vector2.new(0.5, 1); tip.Position = UDim2.new(0.5, 0, 0, -22); tip.Size = UDim2.new(1, 160, 0, 14)
	tip.Font = Theme.FONT_TITLE; tip.TextSize = 12; tip.TextColor3 = Color3.fromRGB(150, 200, 255); tip.Text = ""; tip.Parent = root
	do local s = Instance.new("UIStroke", tip); s.Color = Theme.OUTLINE; s.Thickness = 1.4 end
	-- THE CROSSHAIR, in the middle of the screen (where a spell goes): a ring in the chosen
	-- spell's colour with four ticks, closing as the cast fills; red past the spell's reach,
	-- dim while it can't be cast (cooling down, not enough mana)
	local ret = Instance.new("Frame")
	ret.Name = "Crosshair"; ret.AnchorPoint = Vector2.new(0.5, 0.5); ret.Position = UDim2.fromScale(0.5, 0.5)
	ret.Size = UDim2.fromOffset(34, 34); ret.BackgroundTransparency = 1
	ret.Parent = gui
	Instance.new("UICorner", ret).CornerRadius = UDim.new(1, 0)
	local retStroke = Instance.new("UIStroke", ret); retStroke.Thickness = 2; retStroke.Transparency = 0.2
	local dot = Instance.new("Frame")
	dot.AnchorPoint = Vector2.new(0.5, 0.5); dot.Position = UDim2.fromScale(0.5, 0.5); dot.Size = UDim2.fromOffset(4, 4)
	dot.BorderSizePixel = 0; dot.Parent = ret
	Instance.new("UICorner", dot).CornerRadius = UDim.new(1, 0)
	local ticks = {}
	for i = 0, 3 do
		local t = Instance.new("Frame")
		local horiz = i % 2 == 0
		t.AnchorPoint = Vector2.new(0.5, 0.5); t.Size = horiz and UDim2.fromOffset(8, 2) or UDim2.fromOffset(2, 8)
		t.BorderSizePixel = 0; t.Parent = ret
		ticks[i + 1] = {frame = t, dir = ({Vector2.new(1, 0), Vector2.new(0, 1), Vector2.new(-1, 0), Vector2.new(0, -1)})[i + 1]}
	end
	local note = Instance.new("TextLabel")
	note.BackgroundTransparency = 1; note.AnchorPoint = Vector2.new(0.5, 0); note.Position = UDim2.new(0.5, 0, 1, 10); note.Size = UDim2.fromOffset(220, 14)
	note.Font = Theme.FONT_TITLE; note.TextSize = 11; note.TextColor3 = Color3.fromRGB(255, 110, 110); note.Text = ""; note.Parent = ret
	do local s = Instance.new("UIStroke", note); s.Color = Theme.OUTLINE; s.Thickness = 1.4 end
	bar = {gui = gui, root = root, scale = sc, fill = fill, manaText = manaText, manaStroke = stroke, slots = slots, name = name, tip = tip,
		ret = ret, retStroke = retStroke, retDot = dot, retTicks = ticks, retNote = note}
	return bar
end

--------------------------------------------------------------------
--  A MAGIC WEAPON
--------------------------------------------------------------------
function MagicClient.attach(Tool, cfg)
	cfg = cfg or {}
	local remote = Tool:WaitForChild("MagicRemote", 10)
	if not remote then return end
	local manaMult = cfg.MANA_MULT or 1
	local castMult = cfg.CAST_MULT or 1
	-- the arsenal: the Tool's Spells attribute (your loadout), else the weapon's own
	local function bookNow()
		local out = {}
		if cfg.FIXED then for _, id in ipairs(cfg.FIXED) do if Spells[id] then table.insert(out, id) end end; return out end
		local s = Tool:GetAttribute("Spells")
		if type(s) == "string" then for id in s:gmatch("[^,]+") do if Spells[id] and #out < (cfg.SLOTS or 4) then table.insert(out, id) end end end
		if #out == 0 then for _, id in ipairs(cfg.SPELLS or Spells.DEFAULT) do if #out < (cfg.SLOTS or 4) then table.insert(out, id) end end end
		return out
	end
	local book = bookNow()
	Tool:GetAttributeChangedSignal("Spells"):Connect(function() book = bookNow() end)
	local chosen = 1
	local equipped = false
	local castUntil, castFrom, castId = 0, 0, nil
	local warding, meditating = false, false
	local readyAt = {}
	local noManaFlash = 0
	local lift = 0
	local feintAt = nil   -- (a controller's Y held: meditate)
	local toolAnimAt = 0
	local conns = {}
	local function char() return Tool.Parent and Tool.Parent:FindFirstChildOfClass("Humanoid") and Tool.Parent or nil end
	local function costOf(sp) return (sp.mana or 0) * manaMult end

	-- where the crosshair points (and who's there)
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	local function aimHit()
		local cam = workspace.CurrentCamera
		local c = char()
		if not (cam and c) then return nil end
		local ex = {c}
		for _, n in ipairs({"MagicFX", "ArmorFXLocal", "LocalFX", "EmoteFX"}) do local f = workspace:FindFirstChild(n); if f then table.insert(ex, f) end end
		params.FilterDescendantsInstances = ex
		local o, d = cam.CFrame.Position, cam.CFrame.LookVector
		return workspace:Raycast(o, d * 600, params), o + d * 600
	end
	local function aimPoint()
		local res, far = aimHit()
		return res and res.Position or far
	end

	-- meditating: while the key is held, ask (again whenever you're still and it isn't on)
	local medAsked = 0
	local function meditate(on)
		if meditating == on then return end
		meditating = on
		medAsked = os.clock()
		remote:FireServer("Meditate", on)
	end
	local function cast()
		if not equipped then return end
		local c = char()
		if not c or os.clock() < castUntil or warding then return end
		local id = book[chosen]
		local sp = id and Spells[id]
		if not sp then return end
		if os.clock() < (readyAt[id] or 0) then return end
		if (c:GetAttribute("Mana") or 0) < costOf(sp) then noManaFlash = os.clock(); return end
		meditate(false)
		local castTime = sp.cast * castMult
		castId, castFrom, castUntil = id, os.clock(), os.clock() + castTime
		remote:FireServer("Cast", id, aimPoint())
		-- the crosshair at the end of the cast is where it goes
		task.delay(math.max(0, castTime - 0.03), function()
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
		if not cfg.WARD then return end
		if warding == on then return end
		warding = on
		if on then cancel(); meditate(false) end
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
		if input.UserInputType.Name:find("^Gamepad") then return end   -- (a controller comes through TouchInput)
		local a = ClientSettings.actionForInput(input)
		if isSwing(input) then cast()
		elseif input.UserInputType == Enum.UserInputType.MouseButton2 then ward(true)
		elseif a == "Stab" then pick(1)
		elseif a == "Overhead" then pick(-1)
		elseif a == "Feint" then cancel()
		elseif a == "Reload" then meditate(true)
		elseif a == "Kick" then remote:FireServer("Kick") end
	end))
	table.insert(conns, UIS.InputEnded:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton2 then ward(false) end
		if ClientSettings.actionForInput(input) == "Reload" then meditate(false) end
	end))
	-- the scroll wheel picks
	table.insert(conns, UIS.InputChanged:Connect(function(input, gp)
		if gp or not equipped or input.UserInputType ~= Enum.UserInputType.MouseWheel then return end
		local a = ClientSettings.actionForInput(input)
		if a == "Stab" then pick(1) elseif a == "Overhead" then pick(-1) end
	end))
	-- a controller's or a touch screen's buttons (TouchInput); Y / FEINT held meditates
	table.insert(conns, TouchInput.changed:Connect(function(action, down)
		if not equipped then return end
		if action == "Block" then ward(down == true); return end
		if action == "Feint" then
			if down then cancel(); feintAt = os.clock() else feintAt = nil; meditate(false) end
			return
		end
		if not down then return end
		if action == "Swing" then cast()
		elseif action == "Stab" then pick(1)
		elseif action == "Overhead" then pick(-1)
		elseif action == "Kick" then remote:FireServer("Kick") end
	end))

	-- every frame: the lift, the pose, the spell bar, the crosshair
	table.insert(conns, RunService.RenderStepped:Connect(function(dt)
		local c = char()
		if not (equipped and c) then return end
		local now = os.clock()
		if feintAt and now - feintAt > 0.35 and not meditating then meditate(true) end
		-- (the server ended it — you moved, you cast — but the key's still held: when you're still, again)
		if meditating and not c:GetAttribute("Meditating") and now - medAsked > 0.5 then
			local r = c:FindFirstChild("HumanoidRootPart")
			local v = r and r.AssemblyLinearVelocity or Vector3.zero
			if Vector3.new(v.X, 0, v.Z).Magnitude < Spells.MEDITATE.still and now >= castUntil then
				medAsked = now
				remote:FireServer("Meditate", true)
			end
		end
		local casting = now < castUntil
		local raised = casting or warding or c:GetAttribute("Meditating") == true or (castId == nil and now - castFrom < 0.35)
		lift += ((raised and 1 or 0) - lift) * math.clamp(dt * (raised and LIFT_UP or LIFT_DOWN), 0, 1)
		-- (Roblox's "holding a tool" arm, stuck out in front: stopped, so the stance is RigPose's
		-- alone; stopping it here stops it on every screen, the character being yours)
		toolAnimAt -= dt
		if toolAnimAt <= 0 then
			toolAnimAt = 0.25
			local an = c:FindFirstChildOfClass("Humanoid") and c:FindFirstChildOfClass("Humanoid"):FindFirstChildOfClass("Animator")
			if an then for _, tr in ipairs(an:GetPlayingAnimationTracks()) do if tr.Name == "ToolNoneAnim" then tr:Stop(0.1) end end end
		end
		c:SetAttribute("LocalRanged", cfg.STANCE or 3)
		c:SetAttribute("LocalAim", lift)
		local sp = castId and Spells[castId]
		c:SetAttribute("LocalDraw", (casting and sp) and math.clamp((now - castFrom) / (sp.cast * castMult), 0, 1) or 0)
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
		b.manaStroke.Color = flash and Color3.fromRGB(255, 80, 80) or (c:GetAttribute("Meditating") and Color3.fromRGB(160, 230, 255) or Color3.fromRGB(120, 160, 255))
		b.manaStroke.Transparency = (flash or c:GetAttribute("Meditating")) and 0 or 0.4
		-- the meditation tip
		local key = InputHints.mode() == "Gamepad" and ("HOLD " .. InputHints.name("Feint")) or (InputHints.mode() == "Touch" and "HOLD FEINT" or ("HOLD " .. InputHints.name("Reload")))
		if c:GetAttribute("Meditating") then b.tip.Text = "MEDITATING…  STAY STILL"
		elseif not cfg.FIXED and mana < max * 0.5 then b.tip.Text = key .. " TO MEDITATE  ·  STAND STILL"
		else b.tip.Text = "" end
		b.tip.TextColor3 = flash and Color3.fromRGB(255, 120, 120) or Color3.fromRGB(150, 200, 255)
		for i, sl in ipairs(b.slots) do
			local id = book[i]
			local s = id and Spells[id]
			sl.frame.Visible = s ~= nil
			if s then
				sl.glyph.Text = s.glyph or "?"
				sl.cost.Text = costOf(s) > 0 and tostring(math.floor(costOf(s) + 0.5)) or "FREE"
				local on = i == chosen
				sl.stroke.Color = on and (s.color or Color3.new(1, 1, 1)) or Color3.new(1, 1, 1)
				sl.stroke.Transparency = on and 0 or 0.7
				sl.frame.BackgroundColor3 = on and Color3.fromRGB(34, 40, 70) or Color3.fromRGB(16, 20, 36)
				local left = math.max(0, (readyAt[id] or 0) - now)
				sl.cd.Size = UDim2.fromScale(1, math.clamp(left / math.max(s.cooldown or 1, 0.1), 0, 1))
				sl.glyph.TextTransparency = (mana < costOf(s)) and 0.6 or 0
			end
		end
		if chosen > #book then chosen = math.max(1, #book) end
		local cur = Spells[book[chosen] or ""]
		b.name.Text = cur and (string.upper(cur.name) .. (casting and "  ·  CASTING…" or "")) or ""
		b.name.TextColor3 = cur and (cur.glow or Color3.new(1, 1, 1)) or Color3.new(1, 1, 1)
		-- the crosshair
		local s = (casting and sp) or cur
		if s then
			local k = (casting and sp) and math.clamp((now - castFrom) / (sp.cast * castMult), 0, 1) or 0
			local d = casting and (44 - 28 * k) or (warding and 46 or 30)
			b.ret.Size = UDim2.fromOffset(d, d)
			local res, far = aimHit()
			local hitAt = res and res.Position or far
			local root = c:FindFirstChild("HumanoidRootPart")
			local reach = s.range or 999
			local dist = hitAt and root and (hitAt - root.Position).Magnitude or 0
			local tooFar = s.kind ~= "nova" and s.kind ~= "bolt" and s.kind ~= "blink" and dist > reach
			local ready = now >= (readyAt[(casting and castId) or book[chosen]] or 0) and mana >= costOf(s)
			local col = tooFar and Color3.fromRGB(255, 90, 90) or (s.color or Color3.new(1, 1, 1))
			if casting then col = col:Lerp(Color3.new(1, 1, 1), 0.35 * k) end
			b.retStroke.Color = col
			b.retStroke.Transparency = (ready or casting) and 0.15 or 0.65
			b.retDot.BackgroundColor3 = col
			for _, t in ipairs(b.retTicks) do
				t.frame.BackgroundColor3 = col
				t.frame.Position = UDim2.new(0.5, t.dir.X * (d / 2 + 6), 0.5, t.dir.Y * (d / 2 + 6))
				t.frame.BackgroundTransparency = (ready or casting) and 0 or 0.6
			end
			-- what it wants: someone, the ground, an ally, nothing
			local who = res and res.Instance and res.Instance:FindFirstAncestorOfClass("Model")
			local isChar = who and who:FindFirstChildOfClass("Humanoid") ~= nil
			local note, noteCol = "", Color3.fromRGB(200, 220, 255)
			if tooFar then note, noteCol = "OUT OF REACH", Color3.fromRGB(255, 110, 110)
			elseif s.target == "self" then note = "ROUND YOU"
			elseif s.target == "ground" then note = "ON THE GROUND THERE"
			elseif s.target == "ally" then
				local t = c:GetAttribute("Team")
				local ally = isChar and t and t ~= "" and who:GetAttribute("Team") == t
				note = ally and ("ON " .. string.upper(who.Name)) or "ON YOU"
			elseif s.kind == "blink" then note = "STEP THERE" end
			b.retNote.Text = note
			b.retNote.TextColor3 = noteCol
		end
		b.ret.Visible = s ~= nil
	end))

	local function clear()
		local c = char() or player.Character
		if c then for _, a in ipairs({"LocalRanged", "LocalAim", "LocalDraw"}) do c:SetAttribute(a, nil) end end
		if bar then bar.gui.Enabled = false end
	end
	table.insert(conns, Tool.Equipped:Connect(function() equipped = true; lift = 0; book = bookNow() end))
	table.insert(conns, Tool.Unequipped:Connect(function()
		equipped = false
		warding = false
		meditating = false
		feintAt = nil
		castUntil = 0; castId = nil
		clear()
	end))
	table.insert(conns, Tool.Destroying:Connect(function()
		clear()
		for _, cn in ipairs(conns) do cn:Disconnect() end
	end))
end

return MagicClient
