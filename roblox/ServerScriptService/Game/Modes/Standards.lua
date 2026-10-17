--[[ CAPTURE THE STANDARD — each side's war banner stands at its camp, by its spawns a little
     toward the fight, a ring on the ground round it. Take theirs (touch it), carry it home and
     touch your own with it, standing there: a capture. Whoever carries one bears it on their back
     for all to see, a little slower (SpeedMult_Standard); a carrier who falls drops it where they
     fell. Its own side touches a dropped standard to send it home; left alone it goes home by
     itself after RETURN seconds. First to `captures` (GameConfig.MODES.Standards) wins; on the
     clock, more captures, else a draw.

     Each standard flies its side's house's arms (ReplicatedStorage ▸ Houses, the map's
     HouseSeed) and a marker over it that every screen sees through walls (its state with it).

     Round attributes: ObjKind "Standards" · StdA / StdB "home" | "carried" | "dropped" ·
     StdCarrierA / StdCarrierB (a name) · ScoreA / ScoreB (captures). The calls go through
     AdventureEvent "Banner" (StarterPlayerScripts ▸ Adventure).
     Bots (botOpts): a carrier makes for home; anyone whose standard is taken runs the thief down,
     a dropped one of theirs they fetch; otherwise a bit over half go for the enemy's (escorting
     their own carrier), the rest keep to their own. ]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Game = require(script.Parent.Parent:WaitForChild("Game"))
local GameConfig = require(ReplicatedStorage:WaitForChild("GameConfig"))
local Teams, MapLoader, node = Game.Teams, Game.MapLoader, Game.node

local Std = setmetatable({}, {__index = Game.Mode})
Std.__index = Std
function Std.new(def, id) return setmetatable(Game.Mode.new(def, id), Std) end

local TOUCH, HOME_R, RETURN, SLOW = 5.5, 8, 20, 0.85
local OTHER = {A = "B", B = "A"}
local ATTRS = {"ObjKind", "StdA", "StdB", "StdCarrierA", "StdCarrierB"}
local V3 = Vector3.new
local GOLD, WOOD = Color3.fromRGB(222, 178, 76), Color3.fromRGB(70, 46, 30)

local function event() return ReplicatedStorage:FindFirstChild("AdventureEvent") end
local function banner(t) local e = event(); if e then e:FireAllClients("Banner", t) end end
local function nameOf(model)
	local plr = Players:GetPlayerFromCharacter(model)
	return plr and plr.DisplayName or (model:GetAttribute("BotName") or model.Name)
end
local function alive(model)
	local h = model and model.Parent and model:FindFirstChildOfClass("Humanoid")
	return h ~= nil and h.Health > 0
end

-- the ground under a point (characters, bots and the standards themselves left out)
local function groundAt(p)
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	local skip = {}
	for _, pl in ipairs(Players:GetPlayers()) do if pl.Character then table.insert(skip, pl.Character) end end
	local npcs = workspace:FindFirstChild("NPCs")
	if npcs then table.insert(skip, npcs) end
	for _, k in ipairs({"A", "B"}) do local m = workspace:FindFirstChild("Map") and workspace.Map:FindFirstChild("Standard" .. k); if m then table.insert(skip, m) end end
	params.FilterDescendantsInstances = skip
	local r = workspace:Raycast(p + V3(0, 40, 0), V3(0, -120, 0), params)
	return r and r.Position or p
end

-- where a side's standard stands: the middle of its spawns, a little toward the map's middle
local function homeOf(key)
	local m = workspace:FindFirstChild("Map")
	local centre = m and m:GetAttribute("Centre") or V3()
	local sum, n = V3(), 0
	for _, cf in ipairs(MapLoader.spawns(key)) do sum += cf.Position; n += 1 end
	local at = n > 0 and sum / n or (centre + V3(key == "A" and -40 or 40, 0, 0))
	local toward = V3(centre.X - at.X, 0, centre.Z - at.Z)
	if toward.Magnitude > 1 then at += toward.Unit * math.min(12, toward.Magnitude * 0.3) end
	return groundAt(at)
end

-- the standard: a pole, a crossbar, the side's cloth with its house's arms both sides, a gilt
-- finial with a light, a marker over it; every piece welded to the pole (the pole is the root)
local function build(key, seed)
	local def = GameConfig.TEAMS[key]
	local m = Instance.new("Model")
	m.Name = "Standard" .. key
	local function part(name, size, cf, color, mat, shape)
		local p = Instance.new("Part")
		p.Name = name
		if shape then p.Shape = shape end
		p.Size, p.CFrame, p.Color, p.Material = size, cf, color, mat or Enum.Material.SmoothPlastic
		p.Anchored = false
		p.CanCollide, p.CanQuery, p.CanTouch, p.Massless = false, false, false, true
		p.TopSurface, p.BottomSurface = Enum.SurfaceType.Smooth, Enum.SurfaceType.Smooth
		p.Parent = m
		return p
	end
	local pole = part("Pole", V3(10, 0.32, 0.32), CFrame.new(0, 5, 0) * CFrame.Angles(0, 0, math.pi / 2), WOOD, Enum.Material.Wood, Enum.PartType.Cylinder)
	local fin = part("Finial", V3(0.7, 0.7, 0.7), CFrame.new(0, 10.2, 0), GOLD, Enum.Material.Metal, Enum.PartType.Ball)
	part("Spike", V3(0.3, 1, 0.3), CFrame.new(0, 10.9, 0), GOLD, Enum.Material.Metal)
	part("Crossbar", V3(3.6, 0.22, 0.22), CFrame.new(0, 9.3, -0.3), WOOD, Enum.Material.Wood, Enum.PartType.Cylinder)
	for _, x in ipairs({-1.85, 1.85}) do part("Knob", V3(0.36, 0.36, 0.36), CFrame.new(x, 9.3, -0.3), GOLD, Enum.Material.Metal, Enum.PartType.Ball) end
	local cloth = part("StandardCloth", V3(3, 3.8, 0.08), CFrame.new(0, 7.3, -0.42), def.rgb, Enum.Material.Fabric)
	part("Fringe", V3(3.06, 0.2, 0.12), CFrame.new(0, 5.4, -0.42), GOLD, Enum.Material.Metal)
	-- (the house's arms, both faces: outline and emblem in gold, as the banners on the map fly them)
	local okH, emblem = pcall(function() return require(ReplicatedStorage:WaitForChild("Houses")).forTeam(key, seed) end)
	local art = ReplicatedStorage:FindFirstChild("ShieldArt")
	if okH and emblem and art and art:FindFirstChild(emblem) then
		for _, back in ipairs({false, true}) do
			local cf = cloth.CFrame * CFrame.new(0, 0.25, back and 0.06 or -0.06) * (back and CFrame.Angles(0, math.pi, 0) or CFrame.new())
			local pl = part("StandardArms", V3(2.4, 2.4, 0.01), cf, Color3.new(), Enum.Material.SmoothPlastic)
			pl.Transparency = 1
			for z, l in ipairs({{emblem .. "_o", Color3.fromRGB(26, 20, 18)}, {emblem, Color3.new(1.06, 0.84, 0.4)}}) do
				local v = art:FindFirstChild(l[1])
				if v and v.Value ~= "" then
					local d = Instance.new("Decal")
					d.Face = Enum.NormalId.Front
					d.Texture, d.Color3, d.ZIndex = v.Value, l[2], z
					d.Parent = pl
				end
			end
		end
	end
	local light = Instance.new("PointLight")
	light.Color, light.Brightness, light.Range = def.rgb:Lerp(Color3.new(1, 1, 1), 0.3), 1.2, 14
	light.Parent = fin
	-- the marker: over it wherever it is, through walls
	local bb = Instance.new("BillboardGui")
	bb.Name = "Marker"
	bb.AlwaysOnTop, bb.LightInfluence, bb.MaxDistance = true, 0, 2000
	bb.Size = UDim2.fromOffset(240, 30)
	bb.StudsOffset = V3(0, 2.2, 0)
	bb.Parent = fin
	local t = Instance.new("TextLabel")
	t.Name = "Label"
	t.BackgroundTransparency = 1
	t.Size = UDim2.fromScale(1, 1)
	t.Font = Enum.Font.GothamBlack
	t.TextSize = 16
	t.TextColor3 = def.rgb:Lerp(Color3.new(1, 1, 1), 0.35)
	t.Text = string.upper(def.name) .. " STANDARD"
	local st = Instance.new("UIStroke"); st.Color = Color3.fromRGB(12, 10, 14); st.Thickness = 2; st.Parent = t
	t.Parent = bb
	for _, p in ipairs(m:GetDescendants()) do
		if p:IsA("BasePart") and p ~= pole then
			local w = Instance.new("WeldConstraint"); w.Part0, w.Part1 = pole, p; w.Parent = p
		end
	end
	m.PrimaryPart = pole
	return m, t
end

-- the ring on the ground round a side's home: a glowing dashed circle in its colour over a faint wash
local function ringAt(key, at)
	local def = GameConfig.TEAMS[key]
	local ring = Instance.new("Model")
	ring.Name = "StandardHome" .. key
	local function flat(name, size, cf, transp, shape)
		local p = Instance.new("Part")
		p.Name = name
		if shape then p.Shape = shape end
		p.Size, p.CFrame = size, cf
		p.Color, p.Material, p.Transparency = def.rgb, Enum.Material.Neon, transp
		p.Anchored, p.CanCollide, p.CanQuery, p.CanTouch, p.CastShadow = true, false, false, false, false
		p.Parent = ring
		return p
	end
	flat("Wash", V3(0.06, HOME_R * 2, HOME_R * 2), CFrame.new(at + V3(0, 0.06, 0)) * CFrame.Angles(0, 0, math.pi / 2), 0.9, Enum.PartType.Cylinder)
	local n = 28
	for i = 1, n do
		local a = i / n * 2 * math.pi
		local chord = 2 * math.pi * HOME_R / n * 0.6
		flat("Dash", V3(0.4, 0.12, chord), CFrame.new(at + V3(math.cos(a) * HOME_R, 0.1, math.sin(a) * HOME_R)) * CFrame.Angles(0, -a, 0), 0.25)
	end
	ring.Parent = workspace:FindFirstChild("Map") or workspace
	return ring
end

-- STATE
function Std:place(s, at)
	if s.weld then s.weld:Destroy(); s.weld = nil end
	s.model.PrimaryPart.Anchored = true
	s.model:PivotTo(CFrame.new(at) * CFrame.new(0, 5, 0) * CFrame.Angles(0, 0, math.pi / 2))
	s.at = at
end
function Std:label(key)
	local s = self.std[key]
	local def = GameConfig.TEAMS[key]
	if not s.text then return end
	s.text.Text = string.upper(def.name) .. " STANDARD" .. (s.state == "carried" and "  ·  TAKEN" or (s.state == "dropped" and "  ·  DOWN" or ""))
	node:SetAttribute("Std" .. key, s.state)
	node:SetAttribute("StdCarrier" .. key, s.carrier and nameOf(s.carrier) or "")
end
function Std:goHome(key, why)
	local s = self.std[key]
	if s.carrier then s.carrier:SetAttribute("SpeedMult_Standard", nil) end
	s.carrier, s.state, s.droppedAt = nil, "home", nil
	self:place(s, s.home)
	self:label(key)
	if why then banner({text = "THE " .. string.upper(GameConfig.TEAMS[key].name) .. " STANDARD IS HOME", sub = why, kind = "floor"}) end
	self:publishScores()
end
function Std:take(key, model)
	local s = self.std[key]
	local torso = model:FindFirstChild("Torso") or model:FindFirstChild("UpperTorso") or model:FindFirstChild("HumanoidRootPart")
	if not torso then return end
	local pole = s.model.PrimaryPart
	pole.Anchored = false
	-- (on the back, leaning a touch, the foot of the pole at the hips)
	local w = Instance.new("Weld")
	w.Part0, w.Part1 = torso, pole
	w.C0 = CFrame.new(0, -1.6, 0.75) * CFrame.Angles(math.rad(-12), 0, 0) * CFrame.new(0, 5, 0) * CFrame.Angles(0, 0, math.pi / 2)
	w.Parent = pole
	s.weld, s.carrier, s.state, s.droppedAt = w, model, "carried", nil
	model:SetAttribute("SpeedMult_Standard", SLOW)
	self:label(key)
	banner({text = "THE " .. string.upper(GameConfig.TEAMS[key].name) .. " STANDARD IS TAKEN", sub = string.upper(nameOf(model)) .. " HAS IT", kind = "fight"})
	self:publishScores()
end
function Std:drop(key)
	local s = self.std[key]
	local at = s.carrier and s.carrier:FindFirstChild("HumanoidRootPart") and s.carrier.HumanoidRootPart.Position or s.model.PrimaryPart.Position
	if s.carrier then s.carrier:SetAttribute("SpeedMult_Standard", nil) end
	s.carrier, s.state, s.droppedAt = nil, "dropped", os.clock()
	self:place(s, groundAt(at))
	self:label(key)
	banner({text = "THE " .. string.upper(GameConfig.TEAMS[key].name) .. " STANDARD IS DOWN", sub = "HOME BY ITSELF IN " .. RETURN .. "s", kind = "elite"})
	self:publishScores()
end

function Std:start(map)
	Game.Mode.start(self, map)
	self.scores = {A = 0, B = 0}
	self.std = {}
	local m = workspace:FindFirstChild("Map")
	local seed = m and m:GetAttribute("HouseSeed")
	for _, key in ipairs({"A", "B"}) do
		local home = homeOf(key)
		local model, text = build(key, seed)
		model.Parent = m or workspace
		local s = {key = key, model = model, text = text, home = home, at = home, state = "home", ring = ringAt(key, home)}
		self.std[key] = s
		self:place(s, home)
		self:label(key)
	end
	node:SetAttribute("ObjKind", "Standards")
	self:publishScores()
end

function Std:stop()
	for _, s in pairs(self.std or {}) do
		if s.carrier then s.carrier:SetAttribute("SpeedMult_Standard", nil) end
		if s.model then s.model:Destroy() end
		if s.ring then s.ring:Destroy() end
	end
	self.std = {}
	for _, k in ipairs(ATTRS) do node:SetAttribute(k, nil) end
end

function Std:tick()
	if not self.std or not self.std.A then return end
	for _, key in ipairs({"A", "B"}) do
		local s = self.std[key]
		if s.state == "carried" then
			if not alive(s.carrier) then
				self:drop(key)
			else
				-- home with it, their own standing there: a capture
				local side = OTHER[key]
				local mine = self.std[side]
				local hrp = s.carrier:FindFirstChild("HumanoidRootPart")
				if hrp and mine.state == "home" and (V3(hrp.Position.X, 0, hrp.Position.Z) - V3(mine.home.X, 0, mine.home.Z)).Magnitude < HOME_R and math.abs(hrp.Position.Y - mine.home.Y) < 12 then
					local who = s.carrier
					self.scores[side] += 1
					banner({text = string.upper(GameConfig.TEAMS[side].name) .. " CAPTURE THE " .. string.upper(GameConfig.TEAMS[key].name) .. " STANDARD",
						sub = string.format("%s  ·  %d – %d", string.upper(nameOf(who)), self.scores.A, self.scores.B), kind = "victory"})
					self:goHome(key)
				end
			end
		else
			-- the other side touches it: taken; its own side touches it where it lies: home
			for model, hrp in pairs(Teams.fighters(OTHER[key])) do
				if (hrp.Position - s.at).Magnitude < TOUCH then self:take(key, model); break end
			end
			if s.state == "dropped" then
				for _, hrp in pairs(Teams.fighters(key)) do
					if (hrp.Position - s.at).Magnitude < TOUCH then self:goHome(key, "SENT BACK"); break end
				end
				if s.state == "dropped" and os.clock() - (s.droppedAt or 0) > RETURN then self:goHome(key, "IT FOUND ITS WAY BACK") end
			end
		end
	end
end

-- the bots' part in it
function Std:botOpts(opts)
	local mode, team = self, opts.team
	if not team then return end
	local raider = math.random() < 0.55
	local post = V3(math.random(-7, 7), 0, math.random(-7, 7))   -- (a guard's own spot by the standard)
	opts.goal = function(bot)
		local std = mode.std
		if not (std and std.A) then return nil end
		local mine, theirs = std[team], std[OTHER[team]]
		local model = bot.model
		if theirs.carrier == model then return mine.home end
		if mine.state == "carried" and alive(mine.carrier) then
			local h = mine.carrier:FindFirstChild("HumanoidRootPart")
			if h then return h.Position end
		end
		if mine.state == "dropped" then return mine.at end
		if raider then
			if theirs.state == "carried" and alive(theirs.carrier) then
				local h = theirs.carrier:FindFirstChild("HumanoidRootPart")
				return h and h.Position or mine.home
			end
			return theirs.at
		end
		return mine.home + post
	end
end

function Std:objective()
	local s = self.std or {}
	local function st(key)
		local x = s[key]
		if not x then return "" end
		local n = GameConfig.TEAMS[key].name
		return x.state == "carried" and (n .. "'s taken") or (x.state == "dropped" and (n .. "'s down") or (n .. "'s home"))
	end
	return string.format("CAPTURE THE STANDARD  ·  %s  ·  %s  ·  first to %d", st("A"), st("B"), self.def.captures or 3)
end
function Std:isOver()
	local goal = self.def.captures or 3
	if self.scores.A >= goal then return self:teamResult("A") end
	if self.scores.B >= goal then return self:teamResult("B") end
	return nil
end
function Std:result()
	if self.scores.A == self.scores.B then return self:teamResult(nil) end
	return self:teamResult(self.scores.A > self.scores.B and "A" or "B")
end

return Std
