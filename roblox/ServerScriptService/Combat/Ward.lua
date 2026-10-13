--[[ WARD — every blow on a character asks here first (blades: CombatServer, arrows:
     RangedServer, spells and thrown things: MagicServer), and three kinds of magic
     change it (ReplicatedStorage ▸ MagicSpells):

       HEX       an attacker who's hexed (HexUntil, HexWeaken) deals that much less;
                 a hexed target (HexExpose) takes that much more, from anyone
       BARRIER   a shell of light (Shield = points left, ShieldUntil) soaks a blow first,
                 point for point, until it's spent (ShieldHit for the look)
       THE WARD  a Mage's staff raised (Warded): a blow from the front (within WARD.cone)
                 is STOPPED, like a block, paid from the Mage's mana (manaPerDamage a
                 point); without the mana for it the ward breaks (WardBroke) and what
                 the mana couldn't cover gets through. From behind or the side: clean.

       local dmg, stopped = Ward.scale(target, attackerCharacterOrPosition, dmg)
       (stopped: the ward took all of it — a melee blow bounces off: CombatServer) ]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Spells = require(ReplicatedStorage:WaitForChild("MagicSpells"))

local Ward = {}

local function now() return workspace:GetServerTimeNow() end
local function hexed(c) return typeof(c) == "Instance" and (c:GetAttribute("HexUntil") or 0) > now() end

function Ward.scale(target, from, dmg)
	if not (target and dmg and dmg > 0) then return dmg end
	-- the hex: the curse weakens who strikes, and opens who's struck
	if hexed(from) then dmg *= 1 - math.clamp(from:GetAttribute("HexWeaken") or 0, 0, 0.9) end
	if hexed(target) then dmg *= 1 + math.clamp(target:GetAttribute("HexExpose") or 0, 0, 1) end
	-- the barrier soaks first
	local shield = target:GetAttribute("Shield")
	if shield and shield > 0 and (target:GetAttribute("ShieldUntil") or 0) > now() then
		local soak = math.min(shield, dmg)
		dmg -= soak
		shield -= soak
		target:SetAttribute("Shield", shield > 0.05 and shield or nil)
		target:SetAttribute("ShieldHit", os.clock())
		if dmg <= 0 then return 0 end
	end
	if target:GetAttribute("Warded") ~= true then return dmg end
	local root = target:FindFirstChild("HumanoidRootPart")
	if not root then return dmg end
	local at = typeof(from) == "Vector3" and from or (typeof(from) == "Instance" and from:FindFirstChild("HumanoidRootPart") and from.HumanoidRootPart.Position)
	if at then
		local to = at - root.Position
		to = Vector3.new(to.X, 0, to.Z)
		if to.Magnitude > 1e-3 and root.CFrame.LookVector:Dot(to.Unit) < math.cos(math.rad(Spells.WARD.cone)) then return dmg end
	end
	local mana = target:GetAttribute("Mana") or 0
	local cost = dmg * Spells.WARD.manaPerDamage
	target:SetAttribute("WardHit", os.clock())
	if cost > mana then
		-- the ward breaks: it soaks what the mana covers, the rest gets through
		local soak = mana / Spells.WARD.manaPerDamage
		target:SetAttribute("Mana", 0)
		target:SetAttribute("Warded", false)
		target:SetAttribute("WardBroke", os.clock())
		return dmg - soak, false
	end
	target:SetAttribute("Mana", mana - cost)
	return 0, true
end

return Ward
