--[[ ANIM SETS — which animations a weapon plays.

     Two styles, switched by the Style attribute on ReplicatedStorage ▸ Animations
     (Studio-only folder; nothing in code holds an animation id):
       "Forged"   the AnimForge clips: ReplicatedStorage ▸ Animations ▸ <Class> ▸ <Clip>
                  (idle, block, hit flinch and the eight attacks, per weapon class)
       "Classic"  the clips named in each weapon's Config (the original set)
     A clip missing from the forged set falls back to the Config's. Change the
     style and the next weapon equipped uses it.

     Forged attack clips carry three timing marks as attributes (seconds):
       Load     the windup ends (the telegraph)
       Through  the strike ends (Load → Through is the active, damaging phase)
       Settle   the follow-through is back at guard (played over the recovery)
     CombatClient / CombatServer time the clip by them: the windup segment plays
     over the real windup, the strike over the active phase, the follow-through
     over the recovery — so the motion never freezes, snaps or lerps.

     FORGED clips twist the torso freely and expect the legs to stay planted:
     RigPose / NpcAnimator counter the hips by the RootJoint's animated turn
     (AnimSets.counterHips) while the forged style is on. ]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local AnimSets = {}

-- weapon → class (a Config can say ANIM_CLASS = "…" instead)
AnimSets.CLASS = {
	ArmingSword = "Blade1H", Shortsword = "Blade1H", Falchion = "Blade1H", Messer = "Blade1H", Rapier = "Blade1H",
	Cleaver = "Blunt1H", Mace = "Blunt1H", Hammer = "Blunt1H", MorningStar = "Blunt1H", WarAxe = "Blunt1H",
	Dagger = "Dagger",
	Longsword = "Blade2H", Greatsword = "Blade2H", Zweihander = "Blade2H", Estoc = "Blade2H",
	Executioner = "Heavy2H", Maul = "Heavy2H", BattleAxe = "Heavy2H",
	Halberd = "Polearm", Glaive = "Polearm", Bardiche = "Polearm", Poleaxe = "Polearm", Billhook = "Polearm",
	Spear = "Polearm", Pitchfork = "Polearm", Quarterstaff = "Polearm",
}

local function root() return ReplicatedStorage:FindFirstChild("Animations") end

function AnimSets.style()
	local r = root()
	return r and r:GetAttribute("Style") or "Classic"
end

function AnimSets.forged() return AnimSets.style() == "Forged" end

function AnimSets.classOf(weaponName, cfg)
	return (cfg and cfg.ANIM_CLASS) or AnimSets.CLASS[weaponName or ""] or (cfg and AnimSets.CLASS[cfg.Name or ""])
end

local function clip(class, name)
	local r = root()
	local f = r and class and r:FindFirstChild(class)
	local a = f and f:FindFirstChild(name)
	return a and a:IsA("Animation") and a.AnimationId ~= "" and a or nil
end

-- the weapon's config with the forged ids swapped in (a copy; the original is untouched)
function AnimSets.apply(cfg, weaponName)
	if not cfg or not AnimSets.forged() then return cfg end
	local class = AnimSets.classOf(weaponName, cfg)
	if not class then return cfg end
	local out = table.clone(cfg)
	out.ANIM_CLASS = class
	local function swap(key, name)
		local a = clip(class, name)
		if a then out[key] = a.AnimationId end
	end
	swap("IDLE_ID", "Idle"); swap("BLOCK_ID", "Block"); swap("HIT_ID", "Hit")
	if cfg.ATTACKS then
		out.ATTACKS = {}
		for name, info in pairs(cfg.ATTACKS) do
			local a = clip(class, name)
			if a then
				local i = table.clone(info); i.anim = a.AnimationId; out.ATTACKS[name] = i
			else
				out.ATTACKS[name] = info
			end
		end
		-- attacks the forged set adds (e.g. underhands the classic set never had)
		for _, name in ipairs({"LeftUnderhand", "RightUnderhand"}) do
			local a = clip(class, name)
			if a and out.ATTACKS[name] == nil then
				local base = out.ATTACKS["LeftSwing"] or out.ATTACKS["RightSwing"]
				if base then local i = table.clone(base); i.anim = a.AnimationId; out.ATTACKS[name] = i end
			end
		end
	end
	return out
end

-- timing marks of a forged clip by id: {Load, Through, Settle} or nil (classic)
local marksById = nil
function AnimSets.marks(id)
	if type(id) ~= "string" then return nil end
	if not marksById then
		marksById = {}
		local r = root()
		if r then
			for _, a in ipairs(r:GetDescendants()) do
				if a:IsA("Animation") and a:GetAttribute("Through") then
					marksById[a.AnimationId] = {Load = a:GetAttribute("Load"), Through = a:GetAttribute("Through"), Settle = a:GetAttribute("Settle")}
				end
			end
			r.DescendantAdded:Connect(function() marksById = nil end)
		end
	end
	return marksById[id]
end

-- the hips' counter-turn for a torso the animation has twisted: multiply a
-- hip's C0 by this and the leg hangs as if the torso had not turned
-- (root = the RootJoint Motor6D)
-- (HIP_FOLLOW of the turn is let through: the hips and legs turn a little with
-- the body, so a stab or a big swing moves the whole body, feet still planted)
AnimSets.HIP_FOLLOW = 0.3
function AnimSets.counterHips(rootJoint)
	local c1 = rootJoint.C1
	local t = rootJoint.Transform
	return CFrame.identity:Lerp(c1 * t:Inverse() * c1:Inverse(), 1 - AnimSets.HIP_FOLLOW)
end

return AnimSets
