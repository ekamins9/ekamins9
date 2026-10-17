--[[ WARCROWD — the armies a battle is fought in the middle of, on each screen only (never fighters:
     no humanoid, no collisions, nothing replicated). Every soldier is a copy of the game's own
     dressed soldier (Dresser through PreviewRig: a real armour set, the side's colours on its
     tabard, a real weapon and shield), moved limb by limb: they stand, march, charge, fight face to
     face along a line (swing, block, lunge), loose arrows, cast, cheer, fall, and are thrown through
     the air by a blast; the fallen stay on the field a while.

     LEVELS OF DETAIL (a soldier's, by where it stands; parts under the camera, outside physics):
       full   every piece of armour, the weapon, the shield (~25 parts): the rank nearest the action
       lite   the main piece on each limb, the helmet, the weapon (~8): the next ranks
       mass   helmet, body, legs, weapon (4): the ranks behind, the reserves
     Only what moves is moved (a standing rank costs nothing), a regiment out of sight only marches,
     a far one updates less often, and the whole crowd shrinks on a phone (WarCrowd.SCALE).

       local c = WarCrowd.new()
       c:regiment(id, {side = "A"|"B", kind = "foot"|"pike"|"archer"|"knight"|"mage", at = Vector3
                       (front-centre), facing = 1 | -1 (towards +z / -z), cols, ranks, spacing,
                       detail = "full" | "lite" | "mass" (its front rank's), banner = true,
                       fixed = true: stands at at.Y exactly (a wall's walk), not on the ground below,
                       still = true: never marches, so each man stands on the ground under him
                       (a block on a hillside), torches = true: every fourth man of the second
                       rank holds a burning torch up (a night battle))
       WarCrowd.night()       is it dark out (Lighting's clock): what passes torches = true
       c:march(id, z, run)    its front rank heads for this line (run: at a charge)
       c:clash(id, on)        its front rank fights the enemy's (pairs face to face)
       c:lane(idA, idB, z, now, f)  two lines fighting along z (wavering, pulling apart and
                              charging again): call it twice a second; returns the crash point
       c:loose(id)            archers draw and loose · mages raise their staves
       c:cheer(side)          every regiment of a side raises its weapons
       c:hold(id, state)      what its men do while idle: nil (stand) | "cover" (shields raised
                              over their heads, waiting under the walls) | "brace"
       c:blast(pos, r)        soldiers within r are thrown and fall
       c:hit(pos, r, n)       up to n soldiers within r fall (a volley)
       c:ladder(id, {side, kind, from = Vector3 (its foot), to = Vector3 (its top, at the wall),
                     n, speed, rate})
                              men run to a ladder and swarm up it one after another; at the top
                              they go over the wall (and fight there a moment), now and then one is
                              thrown off backwards (rate: how often, a second)
       c:overrun(id)          a ladder's men all go over now (the wall is taken)
       c:audience(id, {side, kind, spots = {CFrame…} (where each stands, facing the show),
                       detail = "mass", unarmed = true})
                              a crowd watching (an arena's stands): still, and on c:roar(secs) a
                              good part of it on its feet, arms up, cheering
       c:rout(id, secs)       a regiment cut down: all fall within secs, none steps up after
       c:crew(part, {side, kind, spots = {CFrame…} (offsets from the part, at the men's feet)})
                              men riding along with a moving thing (a ram's crew under its roof):
                              they walk while it moves, lean into it when it stops; c:crewCheer(secs)
       c:sentry({side, kind, from, to, out, speed})
                              one man walking his stretch (a wall's walk: from → to and back),
                              stopping at each end a few seconds to look out (`out`)
       c:stop()
       WarCrowd.answer(side, pos, r)  every crowd's regiments (and audiences) of that side within r
                              of pos raise their weapons and cheer: a war cry answered
       WarCrowd.figure(side, kind, state, level, home, unarmed) -> {{p, off}…}
                              a dressed soldier's parts held in one pose (offsets from his
                              feet), for something else to carry: a rider on WarFX's horses
       WarCrowd.ghost(at, {side, kind, dir, speed, secs, color})
                              an apparition: a pale see-through man walking from `at` along `dir`,
                              fading in and out over `secs` (a dungeon's dark: DungeonMood) ]]

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Catalog = require(ReplicatedStorage:WaitForChild("Catalog"))
local Sounds   -- (the fight's own sound bank, loaded the first time a line fights near you)
local WarFX    -- (for the dust a charge kicks up, loaded the first time one runs)
local DUST_OF = {
	[Enum.Material.Snow] = Color3.fromRGB(236, 240, 246), [Enum.Material.Sand] = Color3.fromRGB(214, 186, 140),
	[Enum.Material.Sandstone] = Color3.fromRGB(200, 170, 128), [Enum.Material.Mud] = Color3.fromRGB(96, 80, 62),
}
local PreviewRig = require(ReplicatedStorage:WaitForChild("PreviewRig"))

local WarCrowd = {}
WarCrowd.__index = WarCrowd

local V3, CF, ANG = Vector3.new, CFrame.new, CFrame.Angles
local RAD = math.rad
local FAR = CF(0, -5000, 0)

-- what each side's kinds wear and carry
WarCrowd.LOOKS = {
	A = {
		foot = {{set = "RiverGuard", weapon = "Longsword", shield = "Kite"}, {set = "KnightSkin", weapon = "ArmingSword", shield = "Heater"}},
		pike = {{set = "RoadLevy", weapon = "Spear"}, {set = "GambesonSkin", weapon = "Halberd"}},
		archer = {{set = "Bowman", weapon = "Bow"}},
		knight = {{set = "Lionheart", weapon = "Greatsword"}, {set = "SunKnights", weapon = "Longsword", shield = "Heater"}},
		mage = {{set = "Battlemage", weapon = "Staff"}},
	},
	B = {
		foot = {{set = "IronCrow", weapon = "WarAxe", shield = "RoundShield"}, {set = "Sellswords", weapon = "Falchion", shield = "Kite"}},
		pike = {{set = "WolfCompany", weapon = "Halberd"}, {set = "PeasantSkin", weapon = "Spear"}},
		archer = {{set = "NightHunters", weapon = "Bow"}},
		knight = {{set = "Blackguard", weapon = "Mace", shield = "Heater"}, {set = "Obsidian", weapon = "Greatsword"}},
		mage = {{set = "Pyromancer", weapon = "Staff"}},
	},
}
-- how many soldiers a regiment really has (a phone shrinks it)
WarCrowd.SCALE = 1
-- how many parts a frame moves before the rest of the regiments wait a frame (× SCALE)
WarCrowd.BUDGET = 900

local LIMBS = {"Torso", "Head", "Left Arm", "Right Arm", "Left Leg", "Right Leg"}
local LIMB_INDEX = {}
for i, n in ipairs(LIMBS) do LIMB_INDEX[n] = i end
local T, H, LA, RA, LL, RL = 1, 2, 3, 4, 5, 6

--------------------------------------------------------------------
--  TEMPLATES: a dressed soldier, taken apart limb by limb
--------------------------------------------------------------------
local templates = {}   -- key -> {full = {[limb] = {{proto, off}}}, lite = …, mass = …}
local function volume(p) return p.Size.X * p.Size.Y * p.Size.Z end

local function build(side, look)
	local lo = {}
	for _, pc in ipairs(Catalog.setPieces(look.set) or {}) do lo[pc.slot] = pc.id end
	lo.weapon, lo.shield = look.weapon, look.shield
	local ok, m = pcall(PreviewRig.dressedRig, {loadout = lo, weight = "Medium", team = side})
	if not ok or not m then return nil end
	-- (its plain shield already carries its side, the house its banners fly on this map: Dresser.
	-- attachShield → ShieldPaint.plain; built once here, so every man has it for nothing)
	local limbPart = {}
	for i, n in ipairs(LIMBS) do limbPart[i] = m:FindFirstChild(n) end
	if not limbPart[T] then m:Destroy(); return nil end
	local groups = {}   -- limb -> list of {part, off, vol, role}
	for i = 1, 6 do groups[i] = {} end
	local function take(part, limb, role)
		-- (a shield's painted plates are clear parts carrying its arms: kept, for the front rank)
		if not part:IsA("BasePart") or not limbPart[limb] then return end
		if role == "shield" and (part.Name == "Paint" or part.Name == "Emblem") then role = part.Name == "Emblem" and "emblem" or "paint"
		elseif part.Transparency >= 0.95 then return end
		table.insert(groups[limb], {proto = part, off = limbPart[limb].CFrame:ToObjectSpace(part.CFrame), vol = volume(part), role = role})
	end
	local armor = m:FindFirstChild("Armor")
	for _, model in ipairs(armor and armor:GetChildren() or {}) do
		local limb = LIMB_INDEX[model:GetAttribute("Limb") or ""]
		if limb then for _, d in ipairs(model:GetDescendants()) do take(d, limb, "armor") end end
	end
	local body = m:FindFirstChild("Body")
	for _, d in ipairs(body and body:GetDescendants() or {}) do take(d, H, "body") end
	for _, d in ipairs((m:FindFirstChild("WeaponPreview") or Instance.new("Folder")):GetDescendants()) do take(d, RA, "weapon") end
	for _, d in ipairs((m:FindFirstChild("ShieldPreview") or Instance.new("Folder")):GetDescendants()) do take(d, LA, "shield") end
	-- the bare limbs themselves (seen between the plates)
	for i = 1, 6 do
		local p = limbPart[i]
		table.insert(groups[i], {proto = p, off = CFrame.identity, vol = volume(p), role = "limb"})
	end
	local function pick(n, roles)
		local out = {}
		for i = 1, 6 do
			local list = {}
			for _, e in ipairs(groups[i]) do if roles[e.role] then table.insert(list, e) end end
			table.sort(list, function(a, b) return a.vol > b.vol end)
			out[i] = {}
			for k = 1, math.min(n[i] or 0, #list) do table.insert(out[i], list[k]) end
		end
		return out
	end
	local t = {}
	t.full = pick({40, 40, 40, 40, 40, 40}, {armor = true, weapon = true, shield = true, limb = true, body = true, paint = true, emblem = true})
	-- lite: the whole helmet and body armour (what you see of a man), the main piece on each limb,
	-- the weapon and the shield; mass: the body's shell, the helmet, bare arms and legs, the weapon
	local SHELL = {Primary = 1, Fixed = 2, Secondary = 3, Metal = 4, Accent = 5}
	local function sorted(i, role, byShell)
		local list = {}
		for _, e in ipairs(groups[i]) do if e.role == role then table.insert(list, e) end end
		table.sort(list, function(a, b)
			if byShell then
				local ra, rb = SHELL[a.proto.Name] or 9, SHELL[b.proto.Name] or 9
				if ra ~= rb then return ra < rb end
			end
			return a.vol > b.vol
		end)
		return list
	end
	local function bare(i) return groups[i][#groups[i]] end
	local function first(list, n, into)
		for k = 1, math.min(n, #list) do table.insert(into, list[k]) end
		return into
	end
	t.lite = {}
	for i = 1, 6 do
		local cap = (i == T and 4) or (i == H and 3) or ((i == LL or i == RL) and 2) or 1
		local list = first(sorted(i, "armor"), cap, {})
		if #list == 0 then table.insert(list, bare(i)) end
		if i == RA then first(sorted(i, "weapon"), 2, list) end
		if i == LA then first(sorted(i, "shield"), 2, list); first(sorted(i, "emblem"), 1, list) end
		t.lite[i] = list
	end
	t.mass = {}
	for i = 1, 6 do
		local list = {}
		if i == T then first(sorted(i, "armor", true), 2, list)
		elseif i == H then first(sorted(i, "armor"), 2, list) end
		if #list == 0 then table.insert(list, bare(i)) end
		if i == RA then first(sorted(i, "weapon"), 1, list) end
		if i == LA then first(sorted(i, "shield"), 1, list) end
		t.mass[i] = list
	end
	t.model = m   -- (kept: the protos live in it)
	return t
end

local function template(side, kind, variant)
	local looks = (WarCrowd.LOOKS[side] or WarCrowd.LOOKS.A)[kind] or WarCrowd.LOOKS.A.foot
	local look = looks[(variant - 1) % #looks + 1]
	local map = workspace:FindFirstChild("Map")
	local key = side .. kind .. look.set .. "|" .. tostring(map and map:GetAttribute("HouseSeed") or "")
	if templates[key] == nil then templates[key] = build(side, look) or false end
	return templates[key] or nil
end
-- (build them ahead, a frame apart, so the first regiment doesn't stall the screen)
function WarCrowd.warm(sides, kinds)
	for _, side in ipairs(sides) do
		for _, kind in ipairs(kinds) do
			for v = 1, 2 do template(side, kind, v); RunService.Heartbeat:Wait() end
		end
	end
end

--------------------------------------------------------------------
--  A SOLDIER
--------------------------------------------------------------------
local function newSoldier(home, t, level, unarmed)
	-- (his own beat: where he is in a swing, how long his swings take; anyone may come to fight)
	local s = {limbs = {}, offs = {}, parts = {}, ph = math.random() * 6.28, period = 1.2 + math.random() * 0.7}
	for i = 1, 6 do
		s.limbs[i], s.offs[i] = {}, {}
		for _, e in ipairs(t[level][i]) do
			if unarmed and (e.role == "weapon" or e.role == "shield") then continue end
			local p = e.proto:Clone()
			for _, d in ipairs(p:GetChildren()) do
				if not (d:IsA("SurfaceAppearance") or d:IsA("SpecialMesh") or d:IsA("Decal") or d:IsA("Texture")) then d:Destroy() end
			end
			p.Anchored, p.CanCollide, p.CanQuery, p.CanTouch = true, false, false, false
			local clear = e.role == "paint" or e.role == "emblem"
			p.CastShadow = level == "full" and not clear
			p.Transparency = clear and 1 or 0
			p.CFrame = FAR
			p.Parent = home
			table.insert(s.limbs[i], p)
			table.insert(s.offs[i], e.off)
			table.insert(s.parts, p)
		end
	end
	return s
end

-- the pose: six limb frames in the soldier's own space (origin on the ground, facing -z)
local L = {}
local function pose(s, now, kind, out)
	local st = s.state
	local t = now + s.ph
	local bob, lean, twist = 0, 0, 0
	local ra, la, raz, laz, rl, ll = 90, 15, 0, 0, 0, 0
	local headPitch = 0
	if kind == "pike" then ra, la = 90, 70 end
	if kind == "archer" then ra, la = 10, 20 end
	if kind == "mage" then ra, la = 70, 10 end
	if st == "march" or st == "run" then
		local fast = st == "run"
		local w = fast and 11 or 7
		local a = math.sin(t * w)
		rl, ll = a * (fast and 45 or 26), -a * (fast and 45 or 26)
		bob = math.abs(math.cos(t * w)) * (fast and 0.4 or 0.2)
		la = la + a * 18
		lean = fast and 14 or 3
		if fast and kind == "pike" then ra = 20 end      -- (pikes levelled at a charge)
		if fast and kind ~= "pike" and kind ~= "archer" then ra = 120 end   -- (weapons up)
	elseif st == "fight" then
		-- swing (wind up, strike, recover) and guard by turns, each on its own beat
		local period = s.period
		local u = (t % period) / period
		if s.guard then
			la, ra = 95, 110
			lean = 4
		else
			if u < 0.45 then ra = 90 + 80 * (u / 0.45); lean = -4
			elseif u < 0.58 then ra = 170 - 150 * ((u - 0.45) / 0.13); lean = 14; twist = 10
			else ra = 20 + 70 * ((u - 0.58) / 0.42); lean = 6 end
			la = 60
		end
		rl, ll = 12, -10
		if math.floor(t / period) % 3 == 2 then s.guard = true else s.guard = false end
	elseif st == "loose" then
		if kind == "archer" then la, ra, laz, raz, headPitch = 120, 115, 0, 0, 20
		else ra, la = 175, 160 end
	elseif st == "cheer" then
		ra, la = 175 + math.sin(t * 9) * 8, 170 + math.cos(t * 9) * 8
		bob = math.abs(math.sin(t * 9)) * 0.4
	elseif st == "brace" then
		la, ra = 100, 100
	elseif st == "cover" then
		-- (the shield held flat over the head, the weapon low: waiting out the arrows under the walls)
		la, laz, ra, lean, bob = 168, 10, 70, 8, -0.35
		rl, ll = 14, -6
	elseif st == "ride" then
		-- (in the saddle: knees up and forward, the lance arm out, the other on the reins)
		rl, ll = 62, 62
		ra, la = 95, 40
		lean = 8
	elseif st == "climb" then
		-- (hand over hand, a foot up a rung at a time)
		local a = math.sin(t * 6)
		ra, la = 150 + a * 22, 150 - a * 22
		rl, ll = 38 + a * 28, 38 - a * 28
		lean = 6
	end
	local hips = CF(0, 3 + bob, 0) * ANG(0, RAD(twist * 0.3), 0)
	local torso = hips * ANG(RAD(-lean), RAD(twist), 0)
	out[T] = torso
	out[H] = torso * CF(0, 1, 0) * ANG(RAD(headPitch), 0, 0) * CF(0, 0.5, 0)
	out[RA] = torso * CF(1, 0.5, 0) * ANG(RAD(ra), 0, RAD(raz)) * CF(0.5, -0.5, 0)
	out[LA] = torso * CF(-1, 0.5, 0) * ANG(RAD(la), 0, RAD(-laz)) * CF(-0.5, -0.5, 0)
	out[RL] = hips * CF(0.5, -1, 0) * ANG(RAD(rl), 0, 0) * CF(0, -1, 0)
	out[LL] = hips * CF(-0.5, -1, 0) * ANG(RAD(ll), 0, 0) * CF(0, -1, 0)
	return out
end

-- RIGID: a soldier moved as one piece in its standing pose (cached once): what a man far off, or
-- walking in a rear rank, needs; a fraction of the cost of posing every limb
local function placeRigid(s, base, kind, put)
	local rig = s.rig
	if not rig then
		local keep = s.state
		s.state = "stand"
		local Ls = {}
		pose(s, 0, kind, Ls)
		s.state = keep
		rig = {}
		for i = 1, 6 do
			for j, p in ipairs(s.limbs[i]) do table.insert(rig, {p, Ls[i] * s.offs[i][j]}) end
		end
		s.rig = rig
	end
	for k = 1, #rig do local e = rig[k]; put(e[1], base * e[2]) end
end

-- the same, in another held pose (arms up: a cheering man far off), cached per pose
local function placeHeld(s, base, kind, put, state)
	s.held = s.held or {}
	local rig = s.held[state]
	if not rig then
		local keep = s.state
		s.state = state
		local Ls = {}
		pose(s, 0, kind, Ls)
		s.state = keep
		rig = {}
		for i = 1, 6 do
			for j, p in ipairs(s.limbs[i]) do table.insert(rig, {p, Ls[i] * s.offs[i][j]}) end
		end
		s.held[state] = rig
	end
	for k = 1, #rig do local e = rig[k]; put(e[1], base * e[2]) end
end

local function place(s, base, now, kind, put)
	-- fallen: laid on the ground (backwards, or where a blast flung it), still once settled
	if s.state == "dead" or s.state == "falling" then
		local k = s.state == "dead" and 1 or math.clamp((now - s.since) / 0.55, 0, 1)
		k = k * k
		base = base * CF(0, 0.55 * k, 0) * ANG(RAD(88 * k) * s.fallDir, 0, RAD(s.fallRoll * k))
		if s.state == "falling" and k >= 1 then s.state = "dead"; s.dirty = true end
	end
	pose(s, now, kind, L)
	for i = 1, 6 do
		local limbs = s.limbs[i]
		if #limbs > 0 then
			local f = base * L[i]
			local offs = s.offs[i]
			for j = 1, #limbs do put(limbs[j], f * offs[j]) end
		end
	end
end

--------------------------------------------------------------------
--  THE CROWD
--------------------------------------------------------------------
local crowds = {}
local loopConn
local bulkP, bulkC = {}, {}

function WarCrowd.new()
	local self = setmetatable({regs = {}, list = {}, flying = {}, dead = false}, WarCrowd)
	local cam = workspace.CurrentCamera
	self.home = Instance.new("Folder")
	self.home.Name = "WarCrowd"
	self.home.Parent = cam or workspace
	self.ray = RaycastParams.new()
	self.ray.FilterType = Enum.RaycastFilterType.Exclude
	table.insert(crowds, self)
	if not (loopConn and loopConn.Connected) then
		loopConn = RunService.RenderStepped:Connect(function(dt)
			local now = os.clock()
			for i = #crowds, 1, -1 do
				local c = crowds[i]
				if c.dead then table.remove(crowds, i)
				else
					local ok, err = pcall(c.step, c, now, dt)
					if not ok then warn("[WarCrowd] " .. tostring(err)) end
				end
			end
		end)
	end
	return self
end

function WarCrowd:groundAt(x, z, fallback)
	self.ray.FilterDescendantsInstances = {self.home, workspace:FindFirstChild("WarFX")}
	local r = workspace:Raycast(V3(x, 300, z), V3(0, -600, 0), self.ray)
	return r and r.Position.Y or fallback or 0
end

function WarCrowd:regiment(id, o)
	local scale = WarCrowd.SCALE
	local cols = math.max(2, math.floor((o.cols or 12) * (scale < 1 and 0.6 or 1)))
	local ranks = math.max(1, math.floor((o.ranks or 5) * (scale < 1 and 0.6 or 1)))
	local reg = {id = id, side = o.side or "A", kind = o.kind or "foot", facing = o.facing or 1, x = o.at.X, z = o.at.Z,
		target = o.at.Z, run = false, cols = cols, ranks = ranks, sp = o.spacing or 3, men = {}, clash = false,
		looseUntil = 0, cheerUntil = 0, y0 = o.at.Y, nextGround = 0, dirty = true, hidden = false, corpses = {}}
	-- (on the ground below them, or exactly where they're put: on a wall's walk)
	reg.fixed = o.fixed
	if not o.fixed then reg.y0 = self:groundAt(reg.x, reg.z, o.at.Y) end
	local frontLevel = o.detail or "lite"
	for r = 1, ranks do
		for c = 1, cols do
			-- (the second rank is lite behind a full front, mass behind a lite one: what moves when a
			-- whole line marches is what costs)
			local level = r == 1 and frontLevel or ((r == 2 and frontLevel == "full") and "lite" or "mass")
			local t = template(reg.side, reg.kind, (c + r) % 2 + 1)
			if t then
				local s = newSoldier(self.home, t, level)
				s.r, s.c, s.level = r, c, level
				s.ph = math.random() * 6.28
				s.period = 1.2 + math.random() * 0.7
				s.jx, s.jz = (math.random() - 0.5) * 0.9, (math.random() - 0.5) * 0.9
				s.yaw = (math.random() - 0.5) * 0.25
				s.state = "stand"
				table.insert(reg.men, s)
				if o.still then
					-- (each man on the ground under his own feet)
					local x = reg.x + (c - (cols + 1) / 2) * reg.sp + s.jx
					local z = reg.z - reg.facing * (r - 1) * reg.sp + s.jz
					s.gy = self:groundAt(x, z, reg.y0) - reg.y0
				end
			end
		end
	end
	-- torches held up in the second rank (one a man in four), their light on the men round them
	if o.torches and ranks >= 2 then
		reg.torchAt = {}
		for c = 2, cols, 4 do
			local fire = Instance.new("Part")
			fire.Name = "Torch"
			fire.Shape = Enum.PartType.Ball
			fire.Size = V3(0.8, 0.8, 0.8)
			fire.Material = Enum.Material.Neon
			fire.Color = Color3.fromRGB(255, 150, 60)
			fire.Anchored, fire.CanCollide, fire.CanQuery, fire.CanTouch, fire.CastShadow = true, false, false, false, false
			fire.CFrame = FAR
			local l = Instance.new("PointLight")
			l.Name = "Flicker"
			l.Color, l.Range, l.Brightness = Color3.fromRGB(255, 150, 70), 14, 1.3
			l.Parent = fire
			fire.Parent = self.home
			reg.torchAt[c] = fire
		end
	end
	if o.banner ~= false then
		local col = reg.side == "A" and Color3.fromRGB(56, 92, 206) or Color3.fromRGB(190, 50, 44)
		local pole = Instance.new("Part"); pole.Size = V3(0.25, 14, 0.25); pole.Color = Color3.fromRGB(90, 70, 50); pole.Material = Enum.Material.Wood
		local flag = Instance.new("Part"); flag.Size = V3(0.12, 3.6, 4.6); flag.Color = col; flag.Material = Enum.Material.Fabric
		for _, p in ipairs({pole, flag}) do
			p.Anchored, p.CanCollide, p.CanQuery, p.CanTouch, p.CastShadow = true, false, false, false, false
			p.CFrame = FAR
			p.Parent = self.home
		end
		reg.standard = {pole, flag}
	end
	self.regs[id] = reg
	table.insert(self.list, reg)
	return reg
end

function WarCrowd:march(id, z, run)
	local r = self.regs[id]
	if not r then return end
	r.target = z
	r.run = run and true or false
end
function WarCrowd:clash(id, on)
	local r = self.regs[id]
	if not r or r.clash == (on and true or false) then return end
	r.clash = on and true or false
	r.dirty = true
end
function WarCrowd:loose(id)
	local r = self.regs[id]
	if not r then return end
	r.looseUntil = os.clock() + 2.4
	r.dirty = true
end
-- TWO LINES FIGHTING: regiment idA (facing +f along z) and idB (facing -f) meet along `front`;
-- they waver, and now and then pull apart and charge again. Call it every half second or so.
-- Returns where they crashed together (just now; nil otherwise) and where they fight.
function WarCrowd:lane(idA, idB, front, now, f)
	local ra, rb = self.regs[idA], self.regs[idB]
	if not (ra and rb) then return nil, nil end
	f = f or 1
	local sg = ra.surge
	if not sg then sg = {next = now + 25 + math.random() * 45, ph = math.random() * 6}; ra.surge = sg end
	local apart = 0
	if sg.phase == "back" then
		apart = 20
		if now > sg.til then sg.phase, sg.til = "in", now + 6 end
	elseif sg.phase == "in" then
		if now > sg.til then sg.phase, sg.next = nil, now + 35 + math.random() * 45 end
	elseif now > sg.next then
		sg.phase, sg.til = "back", now + 7
	end
	local sway = math.sin(now * 0.12 + sg.ph) * 7
	local zA, zB = front + f * (sway - 2.7 - apart), front + f * (sway + 2.7 + apart)
	self:march(idA, zA, math.abs(zA - ra.z) > 10)
	self:march(idB, zB, math.abs(zB - rb.z) > 10)
	local meet = math.abs(ra.z - rb.z) < 7.5
	local at = V3(ra.x, ra.y0 or 0, (ra.z + rb.z) / 2)
	local crash = (meet and not sg.met) and at or nil
	sg.met = meet
	self:clash(idA, meet)
	self:clash(idB, meet)
	return crash, at
end

function WarCrowd:hold(id, state)
	local r = self.regs[id]
	if not r or r.hold == state then return end
	r.hold = state
	r.dirty = true
end
function WarCrowd:cheer(side)
	for _, r in ipairs(self.list) do
		if r.side == side then r.cheerUntil = os.clock() + 5; r.dirty = true end
	end
end

-- where a soldier of a regiment stands in the world (and the frame it faces)
local function slotCF(reg, s)
	local f = reg.facing
	local x = reg.x + (s.c - (reg.cols + 1) / 2) * reg.sp + s.jx
	local z = reg.z - f * (s.r - 1) * reg.sp + s.jz
	return x, z
end

-- a soldier falls (on the spot, or flung by a blast); its place is taken by the one behind it a
-- moment later (the fallen stay a while, at most a dozen to a regiment)
-- (a man going down near the camera: a cry, and the thud of him hitting the ground in his armour)
local function fallSound(s, flung)
	local p = s.parts[1]
	local cam = workspace.CurrentCamera
	if not (p and cam) or (p.Position - cam.CFrame.Position).Magnitude > 50 then return end
	Sounds = Sounds or require(ReplicatedStorage:WaitForChild("Sounds"))
	if math.random() < 0.6 then pcall(Sounds.bank, flung and "VoiceHurt" or (math.random() < 0.5 and "VoiceDeath" or "VoiceHurt"), p, {Volume = 0.45, MaxDistance = 60}) end
	task.delay(flung and 0.9 or 0.45, function() if p.Parent then pcall(Sounds.bank, "BodyFallArmor", p, {Volume = 0.6, MaxDistance = 50}) end end)
end

local function fall(self, reg, s, now, fling)
	if s.corpse or s.state == "dead" or s.state == "falling" or s.state == "flying" then return end
	fallSound(s, fling ~= nil)
	-- (the fallen keep the spot they fell on, whatever their regiment does next)
	do
		local x, z = slotCF(reg, s)
		s.at = CF(x, reg.y0, z) * CFrame.lookAt(Vector3.zero, V3(0, 0, reg.facing)) * ANG(0, s.yaw, 0)
	end
	if fling then
		local x, z = slotCF(reg, s)
		s.fly = {pos = V3(x, reg.y0, z), vel = fling, spin = V3(math.random() * 8 - 4, math.random() * 8 - 4, math.random() * 8 - 4), t = 0, yaw = s.yaw}
		s.state = "flying"
		table.insert(self.flying, {reg = reg, s = s})
	else
		s.state = "falling"
	end
	s.since = now
	s.fallDir = (math.random() < 0.5) and 1 or -1
	s.fallRoll = math.random(-25, 25)
	s.deadAt = now
	reg.dirty = true
	-- the dead stay where they fell; a fresh soldier steps into the place soon
	table.insert(reg.corpses, s)
	s.corpse = true
	local key = s.r .. ":" .. s.c
	task.delay(2.5 + math.random() * 2, function()
		if self.dead or not reg.men or reg.routed then return end
		-- (the oldest of the fallen, past a dozen, stands up as the new man: parts are reused)
		local fresh
		if #reg.corpses > 12 then
			fresh = table.remove(reg.corpses, 1)
		end
		local idx = table.find(reg.men, s)
		if not idx then return end
		if fresh and fresh ~= s then
			fresh.corpse, fresh.at = nil, nil
			fresh.r, fresh.c, fresh.jx, fresh.jz = s.r, s.c, s.jx, s.jz
			fresh.state = "stand"
			fresh.fly = nil
			reg.men[idx] = fresh
			s.slotLost = true
		else
			-- (no corpse to spare yet: the fallen one stays down, the place stays empty a while longer)
			s.slotLost = true
			reg.men[idx] = nil
			reg.holes = reg.holes or {}
			table.insert(reg.holes, {idx = idx, key = key, r = s.r, c = s.c, jx = s.jx, jz = s.jz})
		end
		reg.dirty = true
	end)
end

local ladderAt, knockOff   -- (the ladders, below)

-- a regiment cut down: every man falls over the next few seconds, and none steps up after
function WarCrowd:rout(id, secs)
	local reg = self.regs[id]
	if not reg or reg.routed then return end
	reg.routed = true
	for _, s in pairs(reg.men) do
		if s and not s.corpse then
			task.delay(math.random() * (secs or 4), function()
				if not self.dead and not s.corpse then fall(self, reg, s, os.clock()) end
			end)
		end
	end
end

function WarCrowd:hit(pos, r, n)
	local now = os.clock()
	local hits = 0
	for _, reg in ipairs(self.list) do
		for _, s in pairs(reg.men) do
			if s and not s.corpse then
				local x, z = slotCF(reg, s)
				if (V3(x, 0, z) - V3(pos.X, 0, pos.Z)).Magnitude < r and math.random() < 0.35 then
					fall(self, reg, s, now)
					hits += 1
					if hits >= (n or 4) then return end
				end
			end
		end
	end
end

function WarCrowd:blast(pos, r)
	local now = os.clock()
	for _, lad in pairs(self.ladders or {}) do
		for _, s in ipairs(lad.men) do
			if s.state == "climb" and not s.over and s.u > 0 and (ladderAt(lad, s) - pos).Magnitude < r then knockOff(self, lad, s, now) end
		end
	end
	for _, reg in ipairs(self.list) do
		if math.abs(reg.x - pos.X) < r + reg.cols * reg.sp and math.abs(reg.z - pos.Z) < r + reg.ranks * reg.sp + 10 then
			for _, s in pairs(reg.men) do
				if s and not s.corpse then
					local x, z = slotCF(reg, s)
					local d = V3(x - pos.X, 0, z - pos.Z)
					local m = d.Magnitude
					if m < r then
						local k = 1 - m / r
						local away = m > 0.1 and d.Unit or V3(1, 0, 0)
						fall(self, reg, s, now, away * (18 + 30 * k) + V3(0, 25 + 40 * k, 0))
					end
				end
			end
		end
	end
end

--------------------------------------------------------------------
--  LADDERS: men swarming up against a wall
--------------------------------------------------------------------
function WarCrowd:ladder(id, o)
	local from, to = o.from, o.to
	local up = to - from
	local flat = V3(up.X, 0, up.Z)
	local lad = {id = id, side = o.side or "A", kind = o.kind or "foot", from = from, to = to, up = up, len = up.Magnitude,
		fwd = flat.Magnitude > 0.1 and flat.Unit or V3(0, 0, -1), men = {}, y0 = from.Y, speed = o.speed or 3.6,
		rate = o.rate or 0.05, acc = 0}
	lad.yaw = math.atan2(-lad.fwd.X, -lad.fwd.Z)
	local n = math.max(2, math.floor((o.n or 5) * (WarCrowd.SCALE < 1 and 0.6 or 1)))
	for k = 1, n do
		local t = template(lad.side, lad.kind, k % 2 + 1)
		if t then
			local s = newSoldier(self.home, t, o.detail or "lite")
			s.ph = math.random() * 6.28
			s.u = 1.05 - k * (1.5 / n)     -- (spread up the ladder, the rest coming up behind)
			s.state = s.u >= 0 and "climb" or "run"
			table.insert(lad.men, s)
		end
	end
	self.ladders = self.ladders or {}
	self.ladders[id] = lad
	return lad
end

function WarCrowd:overrun(id)
	local lad = self.ladders and self.ladders[id]
	if lad then lad.overrun = true end
end

-- where a man on (or coming to) a ladder stands: his feet on its rung, or on the ground behind it
function ladderAt(lad, s)
	if s.u >= 0 then return lad.from + lad.up * math.min(s.u, 1) - lad.fwd * 0.5 end
	local back = lad.from - lad.fwd * (-s.u * lad.len * 0.7)
	return V3(back.X, lad.y0, back.Z)
end

function knockOff(self, lad, s, now)
	local at = ladderAt(lad, s)
	s.fly = {pos = at + V3(0, 3, 0), vel = -lad.fwd * (10 + math.random() * 10) + V3(0, 10 + math.random() * 10, 0),
		spin = V3(math.random() * 6 - 3, math.random() * 4 - 2, math.random() * 6 - 3), t = 0, yaw = lad.yaw}
	s.state = "flying"
	s.since, s.deadAt = now, now
	s.fallDir = -1
	s.fallRoll = math.random(-25, 25)
	table.insert(self.flying, {reg = lad, s = s})
end

function WarCrowd:stepLadders(now, dt, put, cam, c, vs)
	for _, lad in pairs(self.ladders or {}) do
		local mid = lad.from + lad.up * 0.5
		local d = (mid - c).Magnitude
		lad.acc += dt
		local every = d < 110 and 0.05 or (d < 300 and 0.12 or 0.25)
		if lad.acc >= every then
			local step = lad.acc
			lad.acc = 0
			local visible = d < 70
			if not visible and cam then
				local v = cam:WorldToViewportPoint(mid)
				visible = v.Z > 0 and v.X > -vs.X * 0.5 and v.X < vs.X * 1.5 and v.Y > -vs.Y * 0.8 and v.Y < vs.Y * 1.8
			end
			local face = ANG(0, lad.yaw, 0)
			for _, s in ipairs(lad.men) do
				local st = s.state
				if st == "flying" then
					-- (the flight is the crowd's: nothing to do)
				elseif st == "dead" then
					-- (thrown off: lies at the foot a while, then he's one of those coming up again)
					if now - (s.deadAt or now) > 7 then s.u = -0.5 - math.random() * 0.5; s.state = "run" end
				elseif s.over then
					-- (over the wall: fighting on the walk a moment, then gone; another comes up behind)
					if now - s.over > 2.6 then
						if not s.hidden then
							s.hidden = true
							for _, p in ipairs(s.parts) do put(p, FAR) end
						end
						if now - s.over > 4 + math.random() * 3 and not lad.overrun then s.over = nil; s.hidden = nil; s.u = -0.6 - math.random() * 0.4; s.state = "run" end
					elseif visible then
						s.state = "fight"
						local at = lad.to + lad.fwd * 2.2
						place(s, CF(at.X, lad.to.Y - 1, at.Z) * face, now, lad.kind, put)
					end
				else
					local sp = s.u < 0 and 9 or lad.speed * (lad.overrun and 1.6 or 1)
					s.u += sp * step / lad.len
					s.state = s.u < 0 and "run" or "climb"
					if s.u >= 1 then
						s.over = now
					elseif s.u > 0.35 and not lad.overrun and math.random() < lad.rate * step then
						knockOff(self, lad, s, now)
					elseif visible then
						local at = ladderAt(lad, s)
						local base = CF(at) * face
						if d < 300 then place(s, base, now, lad.kind, put) else placeRigid(s, base, lad.kind, put) end
					end
				end
			end
		end
	end
end

--------------------------------------------------------------------
--  AN AUDIENCE: men standing where they're put, watching; on a roar most of them cheer
--------------------------------------------------------------------
function WarCrowd:audience(id, o)
	local a = {id = id, kind = o.kind or "pike", men = {}, cheerUntil = 0, acc = math.random() * 0.1, dirty = true, centre = Vector3.zero}
	local sides = type(o.side) == "table" and o.side or {o.side or "A"}
	for k, cf in ipairs(o.spots or {}) do
		local side = sides[(k - 1) % #sides + 1]
		local t = template(side, a.kind, k % 2 + 1)
		if t then
			local s = newSoldier(self.home, t, o.detail or "mass", o.unarmed ~= false)
			s.at = cf * ANG(0, (math.random() - 0.5) * 0.4, 0)
			s.ph = math.random() * 6.28
			s.state = "stand"
			s.keen = 0.5 + math.random() * 0.5   -- (how readily this one gets up and shouts)
			table.insert(a.men, s)
			a.centre += cf.Position
		end
	end
	if #a.men > 0 then a.centre /= #a.men end
	self.audiences = self.audiences or {}
	self.audiences[id] = a
	return a
end

function WarCrowd:roar(secs, share)
	local now = os.clock()
	for _, a in pairs(self.audiences or {}) do
		a.cheerUntil = now + (secs or 3)
		for _, s in ipairs(a.men) do s.cheering = math.random() < (share or 0.75) * s.keen end
		a.dirty = true
	end
end

function WarCrowd:stepAudiences(now, dt, put, cam, c)
	for _, a in pairs(self.audiences or {}) do
		a.acc += dt
		local d = (a.centre - c).Magnitude
		local cheering = now < a.cheerUntil
		local every = cheering and (d < 90 and 0.07 or 0.14) or 0.5
		if a.acc >= every and (cheering or a.dirty or a.wasCheering) then
			a.acc = 0
			for _, s in ipairs(a.men) do
				local want = (cheering and s.cheering) and "cheer" or "stand"
				if want == "cheer" then
					s.state = "cheer"
					-- (arms and all near the camera; further off they jump up and down as one piece)
					if (s.at.Position - c).Magnitude < 50 then place(s, s.at, now, a.kind, put)
					else placeHeld(s, s.at * CF(0, math.abs(math.sin((now + s.ph) * 9)) * 0.4, 0), a.kind, put, "cheer") end
				elseif s.state ~= "stand" or a.dirty then
					s.state = "stand"
					placeRigid(s, s.at, a.kind, put)
				end
			end
			a.dirty = false
			a.wasCheering = cheering
		end
	end
end

--------------------------------------------------------------------
--  A CREW: men moving with a moving thing (under a ram's roof), walking or leaning into it
--------------------------------------------------------------------
function WarCrowd:crew(part, o)
	local kind = o.kind or "foot"
	local cr = {part = part, kind = kind, men = {}, acc = 0, cheerUntil = 0}
	for k, off in ipairs(o.spots or {}) do
		local t = template(o.side or "A", kind, k % 2 + 1)
		if t then
			local s = newSoldier(self.home, t, o.detail or "lite", true)
			s.ph = math.random() * 6.28
			s.state = "brace"
			table.insert(cr.men, {s = s, off = off})
		end
	end
	self.crews = self.crews or {}
	table.insert(self.crews, cr)
	return cr
end
function WarCrowd:crewCheer(secs)
	for _, cr in ipairs(self.crews or {}) do cr.cheerUntil = os.clock() + (secs or 4) end
end

function WarCrowd:stepCrews(now, dt, put, c)
	for _, cr in ipairs(self.crews or {}) do
		local p = cr.part
		if p and p.Parent then
			cr.acc += dt
			local cf = p.CFrame
			local d = (cf.Position - c).Magnitude
			local every = d < 120 and 0.05 or 0.25
			if cr.acc >= every then
				local moved = cr.last and (cf.Position - cr.last).Magnitude / cr.acc or 0
				cr.acc = 0
				cr.last = cf.Position
				local st = now < cr.cheerUntil and "cheer" or (moved > 0.4 and "march" or "brace")
				for _, e in ipairs(cr.men) do
					e.s.state = st
					local base = cf * e.off
					if d < 120 then place(e.s, base, now, cr.kind, put) else placeRigid(e.s, base, cr.kind, put) end
				end
			end
		end
	end
end

--------------------------------------------------------------------
--  A SENTRY: one man walking his stretch of wall and back, looking out at each end
--------------------------------------------------------------------
function WarCrowd:sentry(o)
	local kind = o.kind or "pike"
	local t = template(o.side or "A", kind, math.random(2))
	if not t then return nil end
	local s = newSoldier(self.home, t, o.detail or "lite")
	s.ph = math.random() * 6.28
	s.state = "march"
	local se = {s = s, a = o.from, b = o.to, len = math.max((o.to - o.from).Magnitude, 1), u = math.random(), dir = math.random() < 0.5 and 1 or -1,
		speed = o.speed or 3.6, kind = kind, out = o.out, waitUntil = 0, acc = math.random() * 0.2, placed = false}
	self.sentries = self.sentries or {}
	table.insert(self.sentries, se)
	return se
end

function WarCrowd:stepSentries(now, dt, put, c)
	for _, se in ipairs(self.sentries or {}) do
		se.acc += dt
		local at = se.a:Lerp(se.b, se.u)
		local d = (at - c).Magnitude
		local every = d < 80 and 0.05 or (d < 250 and 0.15 or 0.4)
		if se.acc >= every then
			local step = se.acc
			se.acc = 0
			local s = se.s
			if now < se.waitUntil then
				-- (at the end of his stretch: stands and looks out a while)
				if s.state ~= "stand" or not se.placed then
					s.state = "stand"
					local out = se.out or (se.b - se.a)
					placeRigid(s, CFrame.lookAt(at, at + V3(out.X, 0, out.Z)), se.kind, put)
					se.placed = true
				end
			else
				se.u += se.dir * se.speed * step / se.len
				if se.u >= 1 or se.u <= 0 then
					se.u = math.clamp(se.u, 0, 1)
					se.dir = -se.dir
					se.waitUntil = now + 3 + math.random() * 4
				end
				s.state = "march"
				at = se.a:Lerp(se.b, se.u)
				local ahead = (se.b - se.a) * se.dir
				local base = CFrame.lookAt(at, at + V3(ahead.X, 0, ahead.Z))
				if d < 80 then place(s, base, now, se.kind, put)
				else placeRigid(s, base * CF(0, math.abs(math.sin((now + s.ph) * 7)) * 0.2, 0), se.kind, put) end
				se.placed = false
			end
		end
	end
end

--------------------------------------------------------------------
--  A FIGURE: a dressed soldier held in one pose, for something else to move (a horse's rider)
--------------------------------------------------------------------
function WarCrowd.figure(side, kind, state, level, home, unarmed)
	kind = kind or "knight"
	local t = template(side or "A", kind, math.random(2))
	if not t then return nil end
	local s = newSoldier(home or workspace.CurrentCamera or workspace, t, level or "lite", unarmed)
	s.state, s.ph = state or "stand", 0
	local Ls = {}
	pose(s, 0, kind, Ls)
	local out = {}
	for i = 1, 6 do
		for j, p in ipairs(s.limbs[i]) do table.insert(out, {p = p, off = Ls[i] * s.offs[i][j]}) end
	end
	return out
end

--------------------------------------------------------------------
--  AN APPARITION: a pale see-through man walking a few steps through the dark, then gone
--------------------------------------------------------------------
function WarCrowd.ghost(at, o)
	o = o or {}
	local t = template(o.side or "A", o.kind or "foot", math.random(2))
	if not t then return nil end
	local home = Instance.new("Folder")
	home.Name = "WarCrowdGhost"
	home.Parent = workspace.CurrentCamera or workspace
	local s = newSoldier(home, t, o.detail or "lite", true)
	local col = o.color or Color3.fromRGB(196, 236, 226)
	for _, p in ipairs(s.parts) do
		for _, d in ipairs(p:GetChildren()) do
			if d:IsA("SurfaceAppearance") or d:IsA("Decal") or d:IsA("Texture") then d:Destroy() end
		end
		if p:IsA("MeshPart") then p.TextureID = "" end
		p.Color = col
		p.Material = Enum.Material.Neon
		p.CastShadow = false
		p.Transparency = 1
	end
	s.ph = math.random() * 6.28
	s.state = "march"
	local dir = o.dir or at.LookVector
	dir = V3(dir.X, 0, dir.Z)
	dir = dir.Magnitude > 0.01 and dir.Unit or V3(0, 0, -1)
	local face = CFrame.lookAt(Vector3.zero, dir)
	local speed, secs = o.speed or 4, o.secs or 3.4
	local t0 = os.clock()
	local Ls = {}
	local conn
	conn = RunService.RenderStepped:Connect(function()
		local u = (os.clock() - t0) / secs
		if u >= 1 or not home.Parent then
			conn:Disconnect()
			home:Destroy()
			return
		end
		-- (fades in, holds faintly glowing, fades out)
		local alpha = 1 - math.min(u / 0.25, 1, (1 - u) / 0.3) * 0.3
		local base = CF(at.Position + dir * speed * secs * u) * face
		pose(s, os.clock(), o.kind or "foot", Ls)
		for i = 1, 6 do
			local f = base * Ls[i]
			for j, p in ipairs(s.limbs[i]) do
				p.CFrame = f * s.offs[i][j]
				p.Transparency = alpha
			end
		end
	end)
	return home
end

function WarCrowd.night()
	local t = game:GetService("Lighting").ClockTime
	return t < 6.3 or t > 18.7
end

function WarCrowd.answer(side, pos, r)
	local now, n = os.clock(), 0
	local at = V3(pos.X, 0, pos.Z)
	for _, c in ipairs(crowds) do
		if not c.dead then
			for _, reg in ipairs(c.list) do
				if reg.side == side and (V3(reg.x, 0, reg.z) - at).Magnitude < r then
					reg.cheerUntil = now + 3.2
					reg.dirty = true
					n += 1
				end
			end
		end
	end
	return n
end

function WarCrowd:stop()
	if self.dead then return end
	self.dead = true
	self.home:Destroy()
	self.list, self.regs, self.flying, self.ladders, self.audiences, self.sentries, self.crews = {}, {}, {}, nil, nil, nil, nil
end

-- one regiment: march (always), then its men where they need moving
function WarCrowd:placeReg(reg, now, dt, put, visible, lod)
	local f = reg.facing
	local gap = reg.target - reg.z
	-- (a small drift isn't a march: it starts past 2.6 studs off and stops within 0.3)
	if reg.moving then
		if math.abs(gap) < 0.3 then reg.moving = false; reg.dirty = true end
	elseif math.abs(gap) > 2.6 then
		reg.moving = true
	end
	local moving = reg.moving
	local speed = reg.run and 16 or 5
	if moving then reg.z += math.clamp(gap, -speed * dt, speed * dt); reg.dirty = true end
	if not visible then reg.hidden = true; return end
	if reg.hidden then reg.hidden = false; reg.dirty = true end
	if moving and not reg.fixed and now > reg.nextGround then
		reg.nextGround = now + 0.6
		reg.y0 = self:groundAt(reg.x, reg.z, reg.y0)
	end
	-- a regiment at a run kicks up a trail of dust behind it (the ground's colour)
	if moving and reg.run and not reg.fixed and now >= (reg.dustAt or 0) then
		reg.dustAt = now + 0.45
		if not reg.dustColor then
			self.ray.FilterDescendantsInstances = {self.home}
			local r = workspace:Raycast(V3(reg.x, reg.y0 + 50, reg.z), V3(0, -100, 0), self.ray)
			reg.dustColor = (r and DUST_OF[r.Material]) or Color3.fromRGB(150, 136, 116)
		end
		WarFX = WarFX or require(ReplicatedStorage:WaitForChild("WarFX"))
		local back = reg.z - reg.facing * (reg.ranks * reg.sp)
		pcall(WarFX.dust, V3(reg.x + (math.random() - 0.5) * reg.cols * reg.sp, reg.y0 + 0.5, back), 1.6, reg.dustColor)
	end
	-- a hole in the front line: the man behind steps up (a fresh one from the back)
	if reg.holes and #reg.holes > 0 and #reg.corpses > 6 then
		local h = table.remove(reg.holes, 1)
		local fresh = table.remove(reg.corpses, 1)
		if fresh then
			fresh.corpse, fresh.at = nil, nil
			fresh.r, fresh.c, fresh.jx, fresh.jz = h.r, h.c, h.jx, h.jz
			fresh.state = "stand"
			reg.men[h.idx] = fresh
			reg.dirty = true
		end
	end
	local cheering = now < reg.cheerUntil
	local loosing = now < reg.looseUntil
	local animate = moving or reg.clash or cheering or loosing or reg.dirty
	local rot = CFrame.lookAt(Vector3.zero, V3(0, 0, f))
	for idx, s in pairs(reg.men) do
		if s and not s.corpse then
			local want
			if s.state == "dead" or s.state == "falling" then want = s.state
			elseif cheering then want = "cheer"
			elseif loosing then want = "loose"
			elseif reg.clash and s.r == 1 then want = "fight"
			elseif reg.clash and s.r == 2 then want = "brace"
			elseif moving then want = reg.run and "run" or "march"
			else want = reg.hold or "stand" end
			if want ~= s.state then s.state = want; s.since = now end
			local live = s.state ~= "stand" and s.state ~= "dead" and s.state ~= "brace" and s.state ~= "cover"
			if animate and (live or reg.dirty or s.state == "falling") then
				local x, z = slotCF(reg, s)
				local base = CF(x, reg.y0 + (s.gy or 0), z) * rot * ANG(0, s.yaw, 0)
				local st = s.state
				-- (a man in the front rank fighting lunges at his man)
				if st == "fight" then base = base * CF(0, 0, -math.max(0, math.sin((now + s.ph) * 2.2)) * 0.8) end
				-- every limb posed near the camera; further off only the fighting front rank and the
				-- falling are, the rest move as one piece (bobbing as they walk); far off, all of them
				-- (a held pose, shields up, is placed limb by limb once, near or mid: it doesn't move after)
				local full = lod == 1 or (lod == 2 and (st == "fight" or st == "cheer" or st == "loose") and s.r == 1)
					or ((st == "cover" or st == "brace") and lod <= 2 and not moving)
				if full then
					place(s, base, now, reg.kind, put)
				else
					if st == "march" or st == "run" then base = base * CF(0, math.abs(math.sin((now + s.ph) * (st == "run" and 11 or 7))) * 0.3, 0) end
					placeRigid(s, base, reg.kind, put)
				end
				-- (a torch held up over his head)
				local torch = reg.torchAt and s.r == 2 and reg.torchAt[s.c]
				if torch then put(torch, base * CF(1.1, 7.3, -0.4)) end
				-- now and then one in the fight goes down
				if st == "fight" and math.random() < dt * 0.012 then fall(self, reg, s, now) end
			end
		end
	end
	-- the fallen: moved only while they go down, then left where they lie
	for _, s in ipairs(reg.corpses) do
		if s.state == "falling" and s.at then place(s, s.at, now, reg.kind, put) end
	end
	if reg.standard and (reg.dirty or moving or reg.clash) then
		local sway = math.sin(now * 2) * 0.08
		local cf = CF(reg.x + reg.sp * 0.5, reg.y0, reg.z - f * reg.sp * 1.5) * rot * ANG(0, 0, sway)
		put(reg.standard[1], cf * CF(0.6, 7, 0))
		put(reg.standard[2], cf * CF(0.6, 12, 2.4))
	end
	reg.dirty = false
end

function WarCrowd:step(now, dt)
	if self.dead then return end
	local n = 0
	local function put(p, cf) n += 1; bulkP[n] = p; bulkC[n] = cf end
	-- the flung, every frame
	for i = #self.flying, 1, -1 do
		local e = self.flying[i]
		local s = e.s
		local fl = s.fly
		if not fl or s.state ~= "flying" then table.remove(self.flying, i)
		else
			fl.t += dt
			fl.vel += V3(0, -90 * dt, 0)
			fl.pos += fl.vel * dt
			if fl.pos.Y <= e.reg.y0 and fl.t > 0.2 then
				-- (down: lying where it landed)
				s.state = "dead"
				s.fly = nil
				local landed = CF(fl.pos.X, e.reg.y0, fl.pos.Z) * ANG(0, fl.yaw + fl.t, 0) * CF(0, 0.55, 0) * ANG(RAD(88) * s.fallDir, 0, 0)
				pose(s, now, e.reg.kind, L)
				for li = 1, 6 do
					local f = landed * L[li]
					for j, p in ipairs(s.limbs[li]) do put(p, f * s.offs[li][j]) end
				end
				table.remove(self.flying, i)
			else
				local base = CF(fl.pos) * ANG(fl.spin.X * fl.t, fl.spin.Y * fl.t, fl.spin.Z * fl.t)
				pose(s, now, e.reg.kind, L)
				for li = 1, 6 do
					local f = base * CF(0, -3, 0) * L[li]
					for j, p in ipairs(s.limbs[li]) do put(p, f * s.offs[li][j]) end
				end
			end
		end
	end
	local nFly = n
	-- the regiments by distance: near ~20 times a second (every limb), mid ~6, far ~3; out of
	-- sight they only march. Each keeps its own time (they don't all land on the same frame),
	-- and a frame that's already moved its share puts the rest off a little (WarCrowd.BUDGET
	-- parts; one that's waited three of its turns goes anyway)
	local t0 = os.clock()
	local cam = workspace.CurrentCamera
	local c = cam and cam.CFrame.Position or Vector3.zero
	local vs = cam and cam.ViewportSize or Vector2.new(1, 1)
	local budget = WarCrowd.BUDGET * WarCrowd.SCALE
	for _, reg in ipairs(self.list) do
		reg.acc = (reg.acc or math.random() * 0.1) + dt
		local m = V3(reg.x, reg.y0 + 3, reg.z)
		local d = (m - c).Magnitude
		local lod = d < 110 and 1 or (d < 300 and 2 or 3)
		local every = lod == 1 and 0.05 or (lod == 2 and 0.16 or 0.3)
		if reg.acc >= every and (n < budget or reg.acc >= every * 3) then
			local visible = d < 70
			if not visible and cam then
				local v = cam:WorldToViewportPoint(m)
				visible = v.Z > 0 and v.X > -vs.X * 0.5 and v.X < vs.X * 1.5 and v.Y > -vs.Y * 0.8 and v.Y < vs.Y * 1.8
			end
			self:placeReg(reg, now, reg.acc, put, visible, lod)
			reg.acc = 0
		end
	end
	if self.crews then
		local camC = workspace.CurrentCamera
		self:stepCrews(now, dt, put, camC and camC.CFrame.Position or Vector3.zero)
	end
	if self.sentries then
		local camS = workspace.CurrentCamera
		self:stepSentries(now, dt, put, camS and camS.CFrame.Position or Vector3.zero)
	end
	if self.audiences then
		local camA = workspace.CurrentCamera
		self:stepAudiences(now, dt, put, camA, camA and camA.CFrame.Position or Vector3.zero)
	end
	if self.ladders then
		local cam = workspace.CurrentCamera
		self:stepLadders(now, dt, put, cam, cam and cam.CFrame.Position or Vector3.zero, cam and cam.ViewportSize or Vector2.new(1, 1))
	end
	if n > 0 then
		for k = n + 1, #bulkP do bulkP[k] = nil; bulkC[k] = nil end
		workspace:BulkMoveTo(bulkP, bulkC, Enum.BulkMoveMode.FireCFrameChanged)
	end
	-- the steel of it close up: near the camera, a man fighting in a front rank now and then rings
	-- out (a clash, a parry, a block, a blow on plate) from where he stands
	self.ringAt = self.ringAt or 0
	if now >= self.ringAt then
		self.ringAt = now + 0.22 + math.random() * 0.3
		local cam = workspace.CurrentCamera
		local c = cam and cam.CFrame.Position
		if c then
			local pick
			for _, reg in ipairs(self.list) do
				if reg.clash and not reg.hidden and (V3(reg.x, reg.y0, reg.z) - c).Magnitude < 70 then
					local s = reg.men[math.random(1, math.max(1, reg.cols))]
					if s and s.state == "fight" and s.parts[1] and (s.parts[1].Position - c).Magnitude < 55 then pick = s; break end
				end
			end
			if pick then
				Sounds = Sounds or require(ReplicatedStorage:WaitForChild("Sounds"))
				local pools = {"Clash", "Parry", "Block", "HitPlate", "Block"}
				pcall(Sounds.bank, pools[math.random(#pools)], pick.parts[1], {Volume = 0.55, MaxDistance = 70})
			end
		end
	end
	-- (in a heavy frame, which regiments were busy and why: the folder's Busy attribute)
	if n > 1500 and now - (self.busyAt or 0) > 2 then
		self.busyAt = now
		local why = {}
		for _, reg in ipairs(self.list) do
			local tag = (reg.moving and (reg.run and "run" or "march") or "") .. (reg.clash and "+clash" or "") .. (now < reg.cheerUntil and "+cheer" or "") .. (now < reg.looseUntil and "+loose" or "")
			if tag ~= "" and not reg.hidden then table.insert(why, reg.id .. ":" .. tag) end
		end
		self.home:SetAttribute("Busy", table.concat(why, " "))
	end
	-- (what it cost, smoothed: the crowd's folder carries it for a look in Studio)
	self.ms = (self.ms or 0) * 0.95 + (os.clock() - t0) * 1000 * 0.05
	self.moved = (self.moved or 0) * 0.95 + n * 0.05
	self.movedFly = (self.movedFly or 0) * 0.95 + nFly * 0.05
	if now - (self.msAt or 0) > 1 then
		self.msAt = now
		self.home:SetAttribute("Ms", math.floor(self.ms * 100) / 100)
		self.home:SetAttribute("Moved", math.floor(self.moved))
		self.home:SetAttribute("MovedFlying", math.floor(self.movedFly))
		self.home:SetAttribute("Flying", #self.flying)
	end
end

return WarCrowd
