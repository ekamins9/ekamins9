--[[ MODIFIERS — composable multipliers published as character attributes.

     Any system that wants to scale something writes ONE attribute named
     <Prefix>_<Source> and clears it (sets nil) when it no longer applies:

         char:SetAttribute("SpeedMult_Weapon", 0.85)   -- heavy pitchfork
         char:SetAttribute("SpeedMult_Armor",  0.70)   -- plate armor
         char:SetAttribute("ClunkMult_Armor",  1.80)
         char:SetAttribute("SpeedMult_Swing",  0.55)   -- while attacking

     Consumers ask for the product of every attribute with that prefix:

         Modifiers.product(char, "SpeedMult")   -->  0.85 * 0.70 * 0.55

     Sources never overwrite each other, unequipping one only removes its
     own factor, and a missing prefix is simply 1. A bare "SpeedMult"
     attribute (no source suffix) also counts, which is handy for testing
     by hand in the Properties panel. ]]

local Modifiers = {}

function Modifiers.product(instance, prefix)
	local p = 1
	local n = #prefix
	for name, value in pairs(instance:GetAttributes()) do
		if type(value) == "number" and string.sub(name, 1, n) == prefix then
			p = p * value
		end
	end
	return p
end

return Modifiers
