--[[ RANGED SERVER — bows and crossbows (the Archer's primary). Every ranged
     Tool's Server script calls RangedServer.attach(Tool, Config).

     THE BOW: hold to draw (DRAW_TIME to full), let go to loose. The shot's
     power is the draw the SERVER timed (never the client's word): a snap shot
     is weak and drops fast, a full draw flies flat and hits hard. Held at full
     draw it costs stamina (HOLD_DRAIN) and the aim starts to shake (the client
     draws the shake; the server only checks the aim is roughly where you face).
     THE CROSSBOW: loaded, a click looses it at full power with a steady aim
     (the client only looses it raised: right mouse held). It stays empty
     until you span it again ("Reload": R, or a click while empty): a slow
     RELOAD, barely moving, bent over the stirrup hauling the string up.

     THE ARROW is the server's: it flies with gravity (stepped raycasts each
     frame) and decides what it hits. Clients only draw it (ReplicatedStorage ▸
     ArrowEvent: "Shot" id, origin, velocity, gravity · "Stop" id, position).
       • a body: damage × power × region (head HEAD_MULT, legs, arms), less
         the armor on that limb (a point: Combat ▸ CombatServer.ARMOR_VS pierce,
         and the weapon's ARMOR_PEN); the arrow sticks where it went in.
         A hit flinches and interrupts like a blade; credit "arrow" / "headshot".
       • a raised guard facing it: blocked (stamina, a clang), the arrow falls.
       • the world: it sticks there a while (a thunk by material).
     Ammo: QUIVER arrows, one back every REGEN seconds; a fresh life, a full quiver.
     Player attributes on the character: Ammo, Drawing (0..1 for everyone's pose),
     Loaded (crossbow), Reloading. ]]

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Debris = game:GetService("Debris")

local CombatServer = require(script.Parent:WaitForChild("CombatServer"))
local Ward = require(script.Parent:WaitForChild("Ward"))
local Injury = require(script.Parent:WaitForChild("Injury"))
local Sounds = require(ReplicatedStorage:WaitForChild("Sounds"))
local SoundBank = require(ReplicatedStorage:WaitForChild("SoundBank"))
local ArrowFX = require(ReplicatedStorage:WaitForChild("ArrowFX"))
local Ballistics = require(ReplicatedStorage:WaitForChild("Ballistics"))
local Armor do
	local loadout = script.Parent.Parent:FindFirstChild("Loadout")
	local mod = loadout and loadout:FindFirstChild("Armor")
	if mod then Armor = require(mod) end
end

local RangedServer = {}

RangedServer.DEFAULTS = {
	KIND        = "bow",     -- "bow" | "crossbow"
	DRAW_TIME   = 1.6,       -- bow: seconds to full draw
	MIN_DRAW    = 0.4,       -- …let go before this share of it and the string is let down, no shot
	NOCK_TIME   = 1.5,       -- bow: after a shot, reaching for the next arrow and nocking it (no drawing)
	MIN_POWER   = 0.2,       -- the weakest shot (a snap)
	SPEED_MIN   = 45,        -- studs/s at MIN_POWER…
	SPEED_MAX   = 120,       -- …and at full draw
	GRAVITY     = 40,        -- studs/s² the arrow falls
	DAMAGE      = 30,        -- a body hit at full power
	HEAD_MULT   = 2.0,       -- a headshot
	LEG_MULT    = 0.7,
	ARM_MULT    = 0.8,
	ARMOR_PEN   = 0.05,
	QUIVER      = 16,
	REGEN       = 6,         -- seconds per arrow back in the quiver
	COOLDOWN    = 0.35,      -- after a let-down, before the next draw
	DRAW_COST   = 6,         -- stamina to draw
	HOLD_AFTER  = 0.6,       -- seconds at full draw before holding it costs
	HOLD_DRAIN  = 5,         -- stamina a second, held past that
	RELOAD      = 5.0,       -- crossbow: seconds to wind the windlass and lay a bolt
	BLOCK_COST  = 18,        -- stamina an arrow takes off a guard that stops it
	DRAW_SLOW   = 0.2,       -- WalkSpeed while a bow is drawn (SpeedMult_Draw; no sprint either)…
	RELOAD_SLOW = 0.08,       -- …and while a crossbow is wound: next to standing still
	MAX_FLIGHT  = 4,         -- seconds before an arrow that hit nothing is dropped
	STICK_LIFE  = 20,        -- seconds a stuck arrow stays
	AIM_CONE    = 80,        -- degrees the aim may be off the way you face
	KICK_COOLDOWN = 1.3,
}

-- the arrow everyone sees (server copy: stuck in things)
local function arrowModel(kind)
	local m = Instance.new("Model")
	m.Name = kind == "crossbow" and "Bolt" or "Arrow"
	local len = kind == "crossbow" and 1.5 or 2.6
	local shaft = Instance.new("Part")
	shaft.Name = "Shaft"
	shaft.Size = Vector3.new(0.09, 0.09, len)
	shaft.Color = Color3.fromRGB(150, 110, 66)
	shaft.Material = Enum.Material.Wood
	shaft.CanCollide, shaft.CanQuery, shaft.CanTouch, shaft.Massless = false, false, false, true
	shaft.Parent = m
	local head = Instance.new("WedgePart")
	head.Name = "Head"
	head.Size = Vector3.new(0.05, 0.16, 0.32)
	head.Color = Color3.fromRGB(70, 72, 78)
	head.Material = Enum.Material.Metal
	head.CanCollide, head.CanQuery, head.CanTouch, head.Massless = false, false, false, true
	head.CFrame = shaft.CFrame * CFrame.new(0, 0, -len / 2 - 0.12)
	head.Parent = m
	for i, rot in ipairs({0, 120, 240}) do
		local f = Instance.new("Part")
		f.Name = "Fletch"
		f.Size = Vector3.new(0.02, 0.16, 0.4)
		f.Color = i == 1 and Color3.fromRGB(190, 40, 40) or Color3.fromRGB(235, 232, 220)
		f.CanCollide, f.CanQuery, f.CanTouch, f.Massless = false, false, false, true
		f.CFrame = shaft.CFrame * CFrame.new(0, 0, len / 2 - 0.25) * CFrame.Angles(0, 0, math.rad(rot)) * CFrame.new(0, 0.08, 0)
		f.Parent = m
	end
	m.PrimaryPart = shaft
	return m
end
RangedServer.arrowModel = arrowModel

-- the client-side flight + the stuck arrows
local arrowEvent = ReplicatedStorage:FindFirstChild("ArrowEvent")
if not arrowEvent then
	arrowEvent = Instance.new("RemoteEvent")
	arrowEvent.Name = "ArrowEvent"
	arrowEvent.Parent = ReplicatedStorage
end
local stuckFolder = workspace:FindFirstChild("Arrows")
if not stuckFolder then stuckFolder = Instance.new("Folder"); stuckFolder.Name = "Arrows"; stuckFolder.Parent = workspace end

-- leave an arrow standing in something: welded to a body part (it goes with
-- the body), anchored in the world
local function stick(kind, cf, part, life, fx)
	local m = arrowModel(kind)
	m:PivotTo(cf)
	-- a skin's arrows smoulder where they stand a moment (ArrowFX)
	if fx then ArrowFX.decorate(m.PrimaryPart, m:FindFirstChild("Head"), fx, {stuck = true}) end
	for _, p in ipairs(m:GetDescendants()) do
		if p:IsA("BasePart") and p ~= m.PrimaryPart then
			local w = Instance.new("WeldConstraint"); w.Part0, w.Part1 = m.PrimaryPart, p; w.Parent = p
		end
	end
	local body = part and part.Parent and not part.Anchored and part:FindFirstAncestorOfClass("Model")
	if body and body:FindFirstChildOfClass("Humanoid") then
		for _, p in ipairs(m:GetDescendants()) do if p:IsA("BasePart") then p.Anchored = false end end
		local w = Instance.new("WeldConstraint"); w.Part0, w.Part1 = part, m.PrimaryPart; w.Parent = m.PrimaryPart
		m.Parent = body
	else
		for _, p in ipairs(m:GetDescendants()) do if p:IsA("BasePart") then p.Anchored = true end end
		m.Parent = stuckFolder
	end
	Debris:AddItem(m, life or 20)
	return m
end

-- which body part a part is, as a region
local REGION = {Head = "head", Torso = "body", HumanoidRootPart = "body", ["Left Arm"] = "arm", ["Right Arm"] = "arm", ["Left Leg"] = "leg", ["Right Leg"] = "leg"}
local function regionOf(part, model)
	local n = part.Name
	if part.Parent ~= model then
		-- armor / hair / an accessory: the limb it's on
		local limb = part:GetAttribute("Limb") or (part.Parent and part.Parent:GetAttribute("Limb"))
		if limb then n = limb
		elseif part.Parent and part.Parent:IsA("Accessory") then n = "Head" end
	end
	return REGION[n] or "body", n
end

-- THE SOUNDS (Pro Sound Effects). A bow's release is two layered: the string
-- slapping home (a low leather thump) and the arrow leaving (a short airy whoosh).
local SND = {
	thump = "rbxassetid://9113506634", whoosh = "rbxassetid://9114159112",
	crossbow = "rbxassetid://9116669163", reload = "rbxassetid://9114424322",
	creak = "rbxassetid://9117979625",
	-- an arrow going into…
	flesh = "rbxassetid://9113502495", dirt = "rbxassetid://9118680937", wood = "rbxassetid://9120951616",
}
-- a sound from a point in the world (an invisible speck that goes after a moment)
local function speck(pos)
	local p = Instance.new("Part")
	p.Name = "ArrowSound"
	p.Anchored, p.CanCollide, p.CanQuery, p.CanTouch = true, false, false, false
	p.Transparency = 1
	p.Size = Vector3.one * 0.1
	p.CFrame = CFrame.new(pos)
	p.Parent = stuckFolder
	Debris:AddItem(p, 4)
	return p
end

function RangedServer.attach(Tool, cfgIn)
	local cfg = {}
	for k, v in pairs(RangedServer.DEFAULTS) do cfg[k] = v end
	for k, v in pairs(cfgIn or {}) do cfg[k] = v end
	local isBow = cfg.KIND ~= "crossbow"
	local weaponName = cfgIn.Name or Tool.Name
	Tool:SetAttribute("Ranged", cfg.KIND)

	local remote = Tool:FindFirstChild("RangedRemote")
	if not remote then remote = Instance.new("RemoteEvent"); remote.Name = "RangedRemote"; remote.Parent = Tool end

	-- the string: two beams through a nock point each client pulls back to the
	-- drawing hand (RangedFX); a crossbow's sits at the nut while it's spanned
	local handle = Tool:FindFirstChild("Handle")
	if handle and cfg.STRING and not handle:FindFirstChild("StringNock") then
		local function att(n, pos) local a = Instance.new("Attachment"); a.Name = n; a.Position = pos; a.Parent = handle; return a end
		local top, bottom = att("StringTop", cfg.STRING.top), att("StringBottom", cfg.STRING.bottom)
		local nock = att("StringNock", cfg.STRING.rest)
		nock:SetAttribute("Rest", cfg.STRING.rest)
		if cfg.STRING.spanned then nock:SetAttribute("Spanned", cfg.STRING.spanned) end
		for i, pair in ipairs({{top, nock}, {nock, bottom}}) do
			local b = Instance.new("Beam")
			b.Name = "String" .. i
			b.Attachment0, b.Attachment1 = pair[1], pair[2]
			b.Width0, b.Width1 = 0.025, 0.025   -- (thin: in first person it's right by your eye)
			b.Color = ColorSequence.new(Color3.fromRGB(232, 226, 206))
			b.FaceCamera = true
			b.Segments = 1
			b.Parent = handle
		end
	end
	local bolt = Tool:FindFirstChild("Bolt", true)

	local character, humanoid, player
	local drawStart, lastShot, lastKick = nil, -1e9, -1e9
	local holdCostFrom = nil
	local ammo = cfg.QUIVER
	local loaded = not isBow
	local reloadUntil = 0
	local regenAt = os.clock() + cfg.REGEN
	local shotSeq = 0
	local conns = {}

	local function setAttr(n, v) if character then character:SetAttribute(n, v) end end
	local function publish()
		setAttr("Ammo", ammo)
		setAttr("Loaded", isBow and nil or loaded)
		if bolt then bolt.Transparency = loaded and 0 or 1 end
		Tool:SetAttribute("Loaded", loaded)
	end
	local function stamina() return character and (character:GetAttribute("BlockMeter") or 100) or 0 end
	local creak
	local function cancelDraw()
		if creak then creak:Destroy(); creak = nil end
		drawStart, holdCostFrom = nil, nil
		setAttr("Drawing", nil)
		-- (a crossbow being wound stays slow till it's done)
		if os.clock() >= reloadUntil then setAttr("SpeedMult_Draw", nil) end
	end

	-- (the bow sits in the RIGHT hand like any weapon; the left draws the string: RigPose.ranged)
	local function onEquipped()
		character = Tool.Parent
		if not (character and character:IsA("Model")) then character = nil; return end
		player = Players:GetPlayerFromCharacter(character)
		humanoid = character:FindFirstChildOfClass("Humanoid")
		publish()
	end
	local function onUnequipped()
		cancelDraw()
		setAttr("Reloading", nil)
		setAttr("ReloadAt", nil)
		reloadUntil = 0   -- (a reload broken off by putting it away: still empty)
		setAttr("SpeedMult_Draw", nil)
		setAttr("Ammo", nil)
		setAttr("Loaded", nil)
		character = nil
	end
	table.insert(conns, Tool.Equipped:Connect(onEquipped))
	table.insert(conns, Tool.Unequipped:Connect(onUnequipped))
	if Tool.Parent and Tool.Parent:FindFirstChildOfClass("Humanoid") then task.defer(onEquipped) end
	-- a fresh life, a full quiver (the Tool is handed out new each spawn; this covers a reuse)
	table.insert(conns, Tool.AncestryChanged:Connect(function() if not Tool:IsDescendantOf(workspace) then cancelDraw() end end))

	-- what an arrow does to what it meets
	-- a skin's arrows have their own voice: a layer over the plain sounds (ArrowFX.sound)
local function kindSound(fx, which, at)
		local snd = fx and ArrowFX.sound(fx, which)
		if snd and at then Sounds.play(snd.id, at, {Volume = snd.Volume, Speed = snd.Speed, MaxDistance = 90, Ttl = 4}) end
	end

	local function onHit(shooter, shotWeapon, res, vel, power, shotKind, fx)
		local part = res.Instance
		local model = part and part:FindFirstAncestorOfClass("Model")
		local hum = model and model:FindFirstChildOfClass("Humanoid")
		while model and not hum do
			model = model.Parent and model.Parent:FindFirstAncestorOfClass("Model")
			hum = model and model:FindFirstChildOfClass("Humanoid")
		end
		local dir = vel.Magnitude > 0 and vel.Unit or Vector3.new(0, 0, -1)
		local at = CFrame.lookAt(res.Position - dir * 0.6, res.Position + dir)
		if not (hum and hum.Health > 0) then
			-- the world: it sticks, with the sound of what it went into (stone and metal
			-- ring and it glances; wood thunks; earth, sand and grass take it with a thud)
			local family = CombatServer.wallFamily(res.Material and res.Material.Name or "") or "Ground"
			local at2 = speck(res.Position)
			for _, pool in ipairs(SoundBank.WALL[family] or {"WallGround"}) do Sounds.bank(pool, at2, {Volume = 0.7}) end
			if family == "Ground" then Sounds.play(SND.dirt, at2, {Volume = 0.8, MaxDistance = 70})
			elseif family == "Wood" then Sounds.play(SND.wood, at2, {Volume = 0.8, Speed = 1.25, MaxDistance = 70}) end
			kindSound(fx, "impact", at2)
			stick(shotKind, at * CFrame.new(0, 0, 0.5), part, cfg.STICK_LIFE, fx)
			return
		end
		local target = model
		if CombatServer.peaceful(shooter, target) then return end
		-- a raised guard facing it stops it
		local look = target:FindFirstChild("HumanoidRootPart") and target.HumanoidRootPart.CFrame.LookVector or Vector3.zero
		if target:GetAttribute("Blocking") and look:Dot(-dir) > 0.35 then
			local parried = (target:GetAttribute("ParryUntil") or 0) > os.clock()
			Sounds.bank(parried and "Parry" or "Block", part)
			Injury.sparks(res.Position, 0.6)
			if not parried then CombatServer.drainStamina(target, cfg.BLOCK_COST, nil) end
			target:SetAttribute("GuardText", parried and "ARROW PARRIED" or "ARROW BLOCKED")
			target:SetAttribute("GuardTick", (target:GetAttribute("GuardTick") or 0) + 1)
			return
		end
		local region, limbName = regionOf(part, target)
		local mult = region == "head" and cfg.HEAD_MULT or (region == "leg" and cfg.LEG_MULT or (region == "arm" and cfg.ARM_MULT or 1))
		local dmg = cfg.DAMAGE * (0.35 + 0.65 * power) * mult
		-- armor on that limb, a point against it
		if Armor then
			local limb = REGION[limbName] and limbName or (region == "head" and "Head" or "Torso")
			local prot = Armor.protectionAt(target, limb) * (1 - math.clamp(cfg.ARMOR_PEN or 0, 0, 1))
			local vs = CombatServer.ARMOR_VS and CombatServer.ARMOR_VS.pierce
			local class = target:GetAttribute("ArmorType")
			if vs and vs[class] then prot *= vs[class] end
			if prot > 0 then dmg *= (1 - math.clamp(prot, 0, 0.95)) end
			if prot > 0.1 then Sounds.bank("HitPlate", part) end
		end
		local friendly = CombatServer.friendlyMult(shooter, target)
		dmg *= friendly
		dmg = Ward.scale(target, shooter, dmg)   -- (a Mage's ward soaks an arrow from the front)
		if dmg <= 0 then return end
		local lethal = hum.Health - dmg <= 0
		CombatServer.credit(target, shooter, shotWeapon, region == "head" and "headshot" or "arrow")
		target:SetAttribute("LastHitAttack", "Arrow")
		target:SetAttribute("LastHitPower", power)   -- (how far it was drawn: the training yard's full-draw lesson)
		CombatServer.showDamage(shooter, target, dmg, region == "head" and "head" or region, lethal, friendly < 1)
		CombatServer.markCombat(shooter)
		CombatServer.markCombat(target)
		CombatServer.flinch(target, dir)
		CombatServer.interrupt(target, "hit")
		Sounds.bank("HitStab", part)
		Sounds.play(SND.flesh, part, {Volume = 0.6, Speed = 1.1, MaxDistance = 70})
		kindSound(fx, "impact", part)
		if lethal then Sounds.bank("HitBone", part) else Sounds.voice("Hurt", target:FindFirstChild("Head") or part, {Who = target}) end
		if region == "head" and shooter and shooter.Parent then
			shooter:SetAttribute("GuardText", lethal and "HEADSHOT!" or "HEADSHOT")
			shooter:SetAttribute("GuardTick", (shooter:GetAttribute("GuardTick") or 0) + 1)
		end
		stick(shotKind, at * CFrame.new(0, 0, 0.9), part, cfg.STICK_LIFE, fx)
		hum:TakeDamage(dmg)
	end

	-- loose one: the server's own flight, stepped every frame
	local function loose(dirIn, shotId, target)
		local head = character:FindFirstChild("Head")
		local hrp = character:FindFirstChild("HumanoidRootPart")
		if not (head and hrp) then return end
		local power = 1
		if isBow then
			power = math.clamp((os.clock() - drawStart) / cfg.DRAW_TIME, cfg.MIN_POWER, 1)
		end
		local speed = cfg.SPEED_MIN + (cfg.SPEED_MAX - cfg.SPEED_MIN) * power
		local g = cfg.GRAVITY * (isBow and (1.4 - 0.4 * power) or 1)
		local dir = dirIn.Unit
		local origin
		-- the point under the shooter's reticle: onto the arc that lands it there, at the
		-- speed this server timed (the client only says where it aimed)
		if typeof(target) == "Vector3" and target == target and (target - head.Position).Magnitude > 3 and (target - head.Position).Magnitude < 2000 then
			dir, origin = Ballistics.launch(head.Position, target, speed, g)
		end
		-- the aim must be roughly where you face
		local flatLook = hrp.CFrame.LookVector * Vector3.new(1, 0, 1)
		local flatDir = dir * Vector3.new(1, 0, 1)
		if flatLook.Magnitude > 0.1 and flatDir.Magnitude > 0.1 and math.deg(math.acos(math.clamp(flatLook.Unit:Dot(flatDir.Unit), -1, 1))) > cfg.AIM_CONE then
			dir = (flatLook.Unit + Vector3.new(0, dir.Y, 0)).Unit
			origin = nil
		end
		origin = origin or (head.Position + dir * 1.2 + Vector3.new(0, -0.2, 0))
		local vel = dir * speed
		local shooter, shotWeapon, kind = character, weaponName, cfg.KIND
		local fx = Tool:GetAttribute("ArrowFx")
		shotSeq += 1
		local id = (player and player.UserId or 0) .. ":" .. tostring(type(shotId) == "number" and shotId or shotSeq)
		arrowEvent:FireAllClients("Shot", id, origin, vel, g, kind, player and player.UserId or 0, fx)
		if isBow then
			Sounds.play(SND.thump, head, {Volume = 0.5 + 0.4 * power, Speed = 0.62, MaxDistance = 90, Ttl = 2})
			Sounds.play(SND.whoosh, head, {Volume = 0.35 + 0.35 * power, Speed = 2.2, MaxDistance = 70, Ttl = 2})
		else
			Sounds.play(SND.crossbow, head, {Volume = 0.8, Speed = 1.45, MaxDistance = 100, Ttl = 2})
			Sounds.play(SND.whoosh, head, {Volume = 0.5, Speed = 2.6, MaxDistance = 70, Ttl = 2})
		end
		kindSound(fx, "release", head)
		local params = RaycastParams.new()
		params.FilterType = Enum.RaycastFilterType.Exclude
		params.FilterDescendantsInstances = {shooter, stuckFolder}
		local pos, t0 = origin, os.clock()
		local conn
		conn = RunService.Heartbeat:Connect(function(dt)
			local t = os.clock() - t0
			local nextVel = vel - Vector3.new(0, g * dt, 0)
			local step = (vel + nextVel) * 0.5 * dt
			local res = workspace:Raycast(pos, step, params)
			if res then
				conn:Disconnect()
				arrowEvent:FireAllClients("Stop", id, res.Position)
				local ok, err = pcall(onHit, shooter, shotWeapon, res, vel, power, kind, fx)
				if not ok then warn("[Ranged]", err) end
				return
			end
			pos += step
			vel = nextVel
			if t > cfg.MAX_FLIGHT or pos.Y < -200 then
				conn:Disconnect()
				arrowEvent:FireAllClients("Stop", id, nil)
			end
		end)
	end

	table.insert(conns, remote.OnServerEvent:Connect(function(who, action, a, b, c)
		if not character or who ~= player then return end
		local now = os.clock()
		local hum = character:FindFirstChildOfClass("Humanoid")
		if not hum or hum.Health <= 0 then return end
		local stunned = (character:GetAttribute("StunnedUntil") or 0) > now or (character:GetAttribute("HoldUntil") or 0) > workspace:GetServerTimeNow()
		if action == "Draw" and isBow then
			if drawStart or stunned or now - lastShot < cfg.COOLDOWN or now < reloadUntil or ammo <= 0 then return end
			if stamina() < cfg.DRAW_COST then character:SetAttribute("ExhaustedTick", (character:GetAttribute("ExhaustedTick") or 0) + 1); return end
			CombatServer.drainStamina(character, cfg.DRAW_COST, nil)
			drawStart = now
			setAttr("Drawing", 0.01)
			-- the bow creaks as it bends (stopped when it's loosed or let down)
			local head = character:FindFirstChild("Head")
			if head then creak = Sounds.play(SND.creak, head, {Volume = 0.45, Speed = 3.2 / cfg.DRAW_TIME * 0.6, MaxDistance = 35, Ttl = cfg.DRAW_TIME + 3}) end
			setAttr("SpeedMult_Draw", cfg.DRAW_SLOW)
		elseif action == "Loose" then
			if typeof(a) ~= "Vector3" or a.Magnitude < 0.5 or a ~= a then return end
			if isBow then
				if not drawStart or stunned then cancelDraw(); return end
				if ammo <= 0 then cancelDraw(); return end
				-- not drawn far enough: the string is let down, no shot
				if now - drawStart < cfg.DRAW_TIME * cfg.MIN_DRAW then cancelDraw(); lastShot = now; return end
				ammo -= 1
				loose(a, b, c)
				cancelDraw()
				-- the next arrow out of the quiver and onto the string
				reloadUntil = now + cfg.NOCK_TIME
				setAttr("Reloading", cfg.NOCK_TIME)
				local mine = character
				task.delay(cfg.NOCK_TIME, function()
					if character == mine and os.clock() >= reloadUntil - 0.01 then setAttr("Reloading", nil) end
				end)
			else
				if not loaded or stunned or now < reloadUntil or ammo <= 0 then return end
				ammo -= 1
				loaded = false
				loose(a, b, c)
				-- (empty now, until it's spanned again: "Reload")
			end
			lastShot = now
			publish()
		elseif action == "Reload" and not isBow then
			-- span it: bent over the stirrup, hauling the string back to the nut
			if loaded or stunned or now < reloadUntil or ammo <= 0 then return end
			reloadUntil = now + cfg.RELOAD
			setAttr("Reloading", cfg.RELOAD)
			setAttr("ReloadAt", workspace:GetServerTimeNow())   -- (everyone's string follows the haul)
			setAttr("SpeedMult_Draw", cfg.RELOAD_SLOW)
			local head = character:FindFirstChild("Head")
			if head then Sounds.play(SND.reload, head, {Volume = 0.4, MaxDistance = 40}) end
			local mine, began = character, reloadUntil
			task.delay(cfg.RELOAD, function()
				if character ~= mine or reloadUntil ~= began then return end
				loaded = ammo > 0
				setAttr("Reloading", nil)
				setAttr("ReloadAt", nil)
				setAttr("SpeedMult_Draw", nil)
				publish()
			end)
		elseif action == "Cancel" then
			cancelDraw()
		elseif action == "Kick" then
			if stunned or drawStart or now - lastKick < cfg.KICK_COOLDOWN then return end
			lastKick = now
			local kcfg = setmetatable({}, {__index = CombatServer.DEFAULTS})
			CombatServer.resolveKick(character, kcfg, {weaponName = weaponName, tell = function(...) remote:FireClient(player, ...) end})
		end
	end))

	-- the held draw: its weight on your stamina, and the pose everyone sees
	table.insert(conns, RunService.Heartbeat:Connect(function(dt)
		local now = os.clock()
		if character and drawStart then
			local d = math.clamp((now - drawStart) / cfg.DRAW_TIME, 0, 1)
			if math.abs((character:GetAttribute("Drawing") or 0) - d) > 0.05 or d >= 1 then setAttr("Drawing", d) end
			if d >= 1 and now - drawStart > cfg.DRAW_TIME + cfg.HOLD_AFTER then
				CombatServer.drainStamina(character, cfg.HOLD_DRAIN * dt, nil)
				-- out of breath: the arm gives out and the draw drops
				if stamina() <= 1 then cancelDraw() end
			end
		end
		-- the quiver fills back up slowly
		if now >= regenAt then
			regenAt = now + cfg.REGEN
			if ammo < cfg.QUIVER then
				ammo += 1
				if character then publish() end
			end
		end
	end))

	-- a hit breaks the draw (CombatServer.interrupt finds us here); bots read us as idle
	local IDLE = {phase = "idle", windupStart = -1, windupEnd = -1, releaseEnd = -1}
	local controller = {
		tool = Tool, ranged = true,
		interrupt = function(reason) if reason ~= "executed" then cancelDraw() end end,
		snapshot = function() return IDLE end,
		attack = function() end, cycle = function() end, feint = function() end,
		blockStart = function() end, blockStop = function() end, kick = function() end,
		chambered = function() end,
	}
	CombatServer.controllers[Tool] = controller
	table.insert(conns, Tool.Destroying:Connect(function()
		CombatServer.controllers[Tool] = nil
		for _, c in ipairs(conns) do c:Disconnect() end
	end))
	return controller
end

return RangedServer
