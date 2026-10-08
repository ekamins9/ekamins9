--[[ WARD — the Mage's block (right mouse with a staff: Combat ▸ MagicServer
     raises it, the character's Warded attribute). A frontal blow — a blade, an
     arrow, a spell — loses MagicSpells.WARD.absorb of its damage, and what the
     ward soaks comes out of the Mage's mana (manaPerDamage a point). Out of
     mana, it breaks: the rest goes through. Blows from behind or the side (out
     of the WARD.cone) land clean. Anything that hurts someone asks here first:

       local dmg = Ward.scale(target, attackerCharacterOrPosition, dmg) ]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Spells = require(ReplicatedStorage:WaitForChild("MagicSpells"))

local Ward = {}

function Ward.scale(target, from, dmg)
	if not (target and dmg and dmg > 0) or target:GetAttribute("Warded") ~= true then return dmg end
	local root = target:FindFirstChild("HumanoidRootPart")
	if not root then return dmg end
	local at = typeof(from) == "Vector3" and from or (typeof(from) == "Instance" and from:FindFirstChild("HumanoidRootPart") and from.HumanoidRootPart.Position)
	if at then
		local to = at - root.Position
		to = Vector3.new(to.X, 0, to.Z)
		if to.Magnitude > 1e-3 and root.CFrame.LookVector:Dot(to.Unit) < math.cos(math.rad(Spells.WARD.cone)) then return dmg end
	end
	local mana = target:GetAttribute("Mana") or 0
	local soak = dmg * Spells.WARD.absorb
	local cost = soak * Spells.WARD.manaPerDamage
	if cost > mana then
		-- the ward breaks: it soaks what the mana covers, the rest gets through
		soak = mana / Spells.WARD.manaPerDamage
		target:SetAttribute("Mana", 0)
		target:SetAttribute("Warded", false)
		target:SetAttribute("WardBroke", os.clock())
	else
		target:SetAttribute("Mana", mana - cost)
	end
	target:SetAttribute("WardHit", os.clock())
	return dmg - soak
end

return Ward
