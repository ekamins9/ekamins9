--[[ ARMOR SET BLUEPRINTS — the clothing models of every set that ships
     without hand-made models. A set = {HeadClothing = specs, TorsoClothing =
     specs, LeftArmClothing = …, RightArmClothing = …, LeftLegClothing = …,
     RightLegClothing = …}; any slot may be missing. Every spec list sits in
     the LIMB'S frame: a part named Middle the size of the limb at the origin
     (Dresser welds Middle onto the limb and keeps every other part's offset).

     Color blocks: attrs = {ColorSlot = "Primary" | "Secondary" | "Accent" | "Metal"}
     take the player's colors (Primary = team color in team modes). Parts
     without ColorSlot keep their own color (leather, wood, mail, skin).

     Limb sizes (R6): Head 2×1×1 (visually a 1.25 cube), Torso 2×2×1,
     arms / legs 1×2×1. Front is -Z. ]]

local B = require(script.Parent:WaitForChild("Builder"))
local C, M = B.C, B.M
local cf, v = B.cf, B.v
local P, S, A, MT = {ColorSlot = "Primary"}, {ColorSlot = "Secondary"}, {ColorSlot = "Accent"}, {ColorSlot = "Metal"}

local A_ = {}

local function middle(size) return B.box("Middle", size, cf(), C.WHITE, M.PLASTIC, nil, {transparency = 1, shadow = false}) end
local HEAD, TORSO, LIMB = v(2, 1, 1), v(2, 2, 1), v(1, 2, 1)

--------------------------------------------------------------------
--  HEAD PIECES
--------------------------------------------------------------------
local function kettleHat(metal, trim)
	return {middle(HEAD),
		B.cyl("Brim", 2.1, 0.1, cf(0, 0.5, 0), metal or C.STEEL, M.METAL, MT),
		B.box("Crown", v(1.3, 0.55, 1.3), cf(0, 0.82, 0), metal or C.STEEL, M.METAL, MT),
		B.box("Top", v(0.8, 0.2, 0.8), cf(0, 1.15, 0), metal or C.STEEL, M.METAL, MT),
		B.cyl("Trim", 2.14, 0.04, cf(0, 0.56, 0), trim or C.GOLD, M.METAL, A),
	}
end
local function bascinet(metal, beak)
	local out = {middle(HEAD),
		B.box("Skull", v(1.4, 0.75, 1.42), cf(0, 0.42, 0), metal or C.STEEL, M.METAL, MT),
		B.box("Back", v(1.42, 0.8, 0.5), cf(0, -0.2, 0.47), metal or C.STEEL, M.METAL, MT),
		B.box("Cheek", v(0.3, 0.8, 1.0), cf(-0.57, -0.2, 0.1), metal or C.STEEL, M.METAL, MT),
		B.box("Cheek", v(0.3, 0.8, 1.0), cf(0.57, -0.2, 0.1), metal or C.STEEL, M.METAL, MT),
		B.box("Point", v(0.6, 0.3, 0.6), cf(0, 0.92, 0), metal or C.STEEL, M.METAL, MT),
	}
	if beak then
		out[#out + 1] = B.box("Visor", v(1.4, 0.45, 0.3), cf(0, 0.08, -0.78), metal or C.STEEL, M.METAL, MT)
		out[#out + 1] = B.wedge("Beak", v(1.3, 0.5, 0.5), cf(0, -0.4, -0.9, 90, 0, 0), metal or C.STEEL, M.METAL, MT)
		out[#out + 1] = B.box("Slit", v(1.1, 0.08, 0.05), cf(0, 0.1, -0.95), C.BLACK, M.PLASTIC)
	end
	return out
end
local function greatHelm(metal, cross)
	return {middle(HEAD),
		B.box("Helm", v(1.46, 1.5, 1.46), cf(0, 0.1, 0), metal or C.STEEL, M.METAL, MT),
		B.box("Rim", v(1.5, 0.12, 1.5), cf(0, 0.86, 0), cross or C.GOLD, M.METAL, A),
		B.box("Slit", v(1.3, 0.1, 0.05), cf(0, 0.2, -0.75), C.BLACK, M.PLASTIC),
		B.box("Cross", v(0.14, 0.7, 0.05), cf(0, -0.25, -0.75), cross or C.GOLD, M.METAL, A),
		B.box("Cross", v(0.8, 0.14, 0.05), cf(0, 0.2, -0.76), cross or C.GOLD, M.METAL, A),
	}
end
local function sallet(metal)
	return {middle(HEAD),
		B.box("Skull", v(1.42, 0.7, 1.46), cf(0, 0.45, 0), metal or C.STEEL, M.METAL, MT),
		B.wedge("Tail", v(1.2, 0.3, 0.7), cf(0, 0.25, 0.95, 0, 180, 0), metal or C.STEEL, M.METAL, MT),
		B.box("Brow", v(1.44, 0.2, 0.3), cf(0, 0.25, -0.65), metal or C.STEEL, M.METAL, MT),
		B.box("Ridge", v(0.16, 0.14, 1.3), cf(0, 0.86, 0), metal or C.STEEL, M.METAL, MT),
	}
end
local function armet(metal, plume)
	return {middle(HEAD),
		B.box("Skull", v(1.42, 0.9, 1.42), cf(0, 0.35, 0), metal or C.STEEL, M.METAL, MT),
		B.box("Back", v(1.42, 0.7, 0.5), cf(0, -0.3, 0.46), metal or C.STEEL, M.METAL, MT),
		B.box("Cheek", v(0.3, 0.7, 1.1), cf(-0.56, -0.3, 0.1), metal or C.STEEL, M.METAL, MT),
		B.box("Cheek", v(0.3, 0.7, 1.1), cf(0.56, -0.3, 0.1), metal or C.STEEL, M.METAL, MT),
		B.box("Visor", v(1.42, 0.35, 0.25), cf(0, 0.25, -0.76), metal or C.STEEL, M.METAL, MT),
		B.box("Trim", v(1.46, 0.1, 1.46), cf(0, 0.8, 0), C.GOLD, M.METAL, A),
		B.box("Plume", v(0.2, 0.9, 0.2), cf(0, 1.2, 0.15, 25, 0, 0), plume or C.RED, M.FABRIC, A),
		B.box("Plume", v(0.2, 0.7, 0.2), cf(0, 1.5, 0.55, 60, 0, 0), plume or C.RED, M.FABRIC, A),
	}
end
local function coif()
	return {middle(HEAD),
		B.box("Top", v(1.4, 0.35, 1.4), cf(0, 0.62, 0), C.MAIL, M.PLATE),
		B.box("Back", v(1.4, 1.2, 0.35), cf(0, -0.1, 0.55), C.MAIL, M.PLATE),
		B.box("Side", v(0.3, 1.2, 1.2), cf(-0.6, -0.1, 0.1), C.MAIL, M.PLATE),
		B.box("Side", v(0.3, 1.2, 1.2), cf(0.6, -0.1, 0.1), C.MAIL, M.PLATE),
		B.box("Chin", v(1.0, 0.3, 0.3), cf(0, -0.55, -0.6), C.MAIL, M.PLATE),
	}
end
local function hood(color, slot)
	return {middle(HEAD),
		B.box("Top", v(1.5, 0.4, 1.5), cf(0, 0.6, 0.05), color or C.GREEN, M.FABRIC, slot or P),
		B.box("Back", v(1.5, 1.3, 0.35), cf(0, -0.05, 0.62), color or C.GREEN, M.FABRIC, slot or P),
		B.box("Side", v(0.3, 1.3, 1.3), cf(-0.65, -0.05, 0.1), color or C.GREEN, M.FABRIC, slot or P),
		B.box("Side", v(0.3, 1.3, 1.3), cf(0.65, -0.05, 0.1), color or C.GREEN, M.FABRIC, slot or P),
		B.wedge("Peak", v(1.5, 0.4, 0.7), cf(0, 0.95, 0.25, 0, 180, 0), color or C.GREEN, M.FABRIC, slot or P),
		B.box("Brow", v(1.5, 0.18, 0.4), cf(0, 0.5, -0.6), color or C.GREEN, M.FABRIC, slot or P),
	}
end
local function cap(leather, feather)
	return {middle(HEAD),
		B.box("Cap", v(1.36, 0.42, 1.4), cf(0, 0.68, 0), leather or C.LEATHER, M.LEATHER),
		B.box("Band", v(1.42, 0.14, 1.46), cf(0, 0.5, 0), C.DARKLEATHER, M.LEATHER),
		B.box("Feather", v(0.08, 0.7, 0.25), cf(0.6, 0.95, 0.1, 0, 0, -25), feather or C.RED, M.FABRIC, A),
	}
end
local function bandana(color)
	return {middle(HEAD),
		B.box("Band", v(1.36, 0.22, 1.4), cf(0, 0.38, 0), color or C.RED, M.FABRIC, A),
		B.box("Knot", v(0.3, 0.2, 0.2), cf(0, 0.38, 0.75), color or C.RED, M.FABRIC, A),
		B.box("Tail", v(0.14, 0.5, 0.1), cf(0.1, 0.1, 0.8, 10, 0, 0), color or C.RED, M.FABRIC, A),
	}
end

--------------------------------------------------------------------
--  TORSO PIECES
--------------------------------------------------------------------
local function belt(y, buckle)
	return {B.box("Belt", v(2.26, 0.26, 1.22), cf(0, y or -0.7, 0), C.DARKLEATHER, M.LEATHER),
		B.box("Buckle", v(0.34, 0.3, 0.08), cf(0, y or -0.7, -0.64), buckle or C.BRASS, M.METAL, A)}
end
local function pauldrons(size, color, mat, slot, spiky)
	local out = {
		B.box("Pauldron", size, cf(-1.05, 0.9, 0), color, mat, slot),
		B.box("Pauldron", size, cf(1.05, 0.9, 0), color, mat, slot),
	}
	if spiky then
		out[#out + 1] = B.wedge("Spike", v(0.3, 0.5, 0.3), cf(-1.1, 1.3, 0), color, mat, slot)
		out[#out + 1] = B.wedge("Spike", v(0.3, 0.5, 0.3), cf(1.1, 1.3, 0), color, mat, slot)
	end
	return out
end
local function tabard(color, slot, cross, crossColor)
	local out = {
		B.box("Tabard", v(1.2, 2.3, 0.1), cf(0, -0.05, -0.62), color or C.CLOTH, M.FABRIC, slot or P),
		B.box("TabardBack", v(1.2, 2.3, 0.1), cf(0, -0.05, 0.62), color or C.CLOTH, M.FABRIC, slot or P),
	}
	if cross then
		out[#out + 1] = B.box("Cross", v(0.22, 1.1, 0.06), cf(0, 0.1, -0.69), crossColor or C.GOLD, M.FABRIC, A)
		out[#out + 1] = B.box("Cross", v(0.8, 0.22, 0.06), cf(0, 0.35, -0.69), crossColor or C.GOLD, M.FABRIC, A)
	end
	return out
end
local function plateTorso(metal, trim)
	return {middle(TORSO),
		B.box("Breastplate", v(2.2, 2.08, 1.16), cf(0, 0, 0), metal or C.STEEL, M.METAL, MT),
		B.box("Gorget", v(1.5, 0.3, 1.2), cf(0, 1.1, 0), metal or C.STEEL, M.METAL, MT),
		B.box("Fauld", v(2.26, 0.4, 1.22), cf(0, -0.9, 0), metal or C.STEEL, M.METAL, MT),
		B.box("Trim", v(2.24, 0.08, 1.2), cf(0, 0.55, 0), trim or C.GOLD, M.METAL, A),
	}
end
local function gambeson(color, quilt)
	local out = {middle(TORSO), B.box("Gambeson", v(2.16, 2.08, 1.14), cf(0, 0, 0), color or C.CLOTH, M.FABRIC, P)}
	for i = 1, 5 do
		out[#out + 1] = B.box("Quilt", v(2.18, 0.05, 1.16), cf(0, -0.85 + (i - 1) * 0.42, 0), quilt or C.CLOTH2, M.FABRIC, S)
	end
	return out
end
local function mailShirt()
	return {middle(TORSO), B.box("Mail", v(2.14, 2.06, 1.12), cf(0, 0, 0), C.MAIL, M.PLATE),
		B.box("Hem", v(2.16, 0.3, 1.14), cf(0, -1.1, 0), C.MAIL, M.PLATE)}
end
local function brigandine(color)
	local out = {middle(TORSO), B.box("Brigandine", v(2.18, 2.08, 1.16), cf(0, 0, 0), color or C.CLOTH2, M.FABRIC, S)}
	for row = 1, 4 do
		for col = 1, 4 do
			out[#out + 1] = B.box("Rivet", v(0.12, 0.12, 0.06), cf(-0.75 + (col - 1) * 0.5, 0.7 - (row - 1) * 0.45, -0.6), C.BRASS, M.METAL, A)
		end
	end
	return out
end
local function jerkin(color)
	return {middle(TORSO),
		B.box("Shirt", v(2.12, 2.06, 1.1), cf(0, 0, 0), color or C.LINEN, M.FABRIC, S),
		B.box("Vest", v(2.2, 1.5, 1.18), cf(0, -0.1, 0), C.LEATHER, M.LEATHER),
		B.box("Lapel", v(0.5, 1.5, 0.1), cf(-0.4, -0.1, -0.62), C.DARKLEATHER, M.LEATHER),
		B.box("Lapel", v(0.5, 1.5, 0.1), cf(0.4, -0.1, -0.62), C.DARKLEATHER, M.LEATHER),
	}
end
local function cloak(color, slot)
	return {B.box("Cloak", v(2.3, 2.4, 0.16), cf(0, -0.15, 0.62), color or C.GREEN, M.FABRIC, slot or P),
		B.box("Clasp", v(0.5, 0.2, 0.1), cf(0, 0.95, -0.6), C.BRASS, M.METAL, A),
		B.box("Strap", v(2.2, 0.18, 0.1), cf(0, 0.95, -0.58, 0, 0, 0), C.LEATHER, M.LEATHER)}
end

--------------------------------------------------------------------
--  ARM / LEG PIECES
--------------------------------------------------------------------
local function sleeve(color, slot, mat) return B.box("Sleeve", v(1.1, 2.04, 1.1), cf(0, 0, 0), color or C.CLOTH, mat or M.FABRIC, slot or P) end
local function mailSleeve() return B.box("Mail", v(1.1, 2.04, 1.1), cf(0, 0, 0), C.MAIL, M.PLATE) end
local function vambrace(metal) return B.box("Vambrace", v(1.16, 0.95, 1.16), cf(0, -0.45, 0), metal or C.STEEL, M.METAL, MT) end
local function rerebrace(metal) return B.box("Rerebrace", v(1.14, 0.8, 1.14), cf(0, 0.5, 0), metal or C.STEEL, M.METAL, MT) end
local function elbow(metal) return B.ball("Elbow", 0.62, cf(0, 0.02, 0.5), metal or C.STEEL, M.METAL, MT) end
local function gauntlet(metal) return B.box("Gauntlet", v(1.14, 0.6, 1.14), cf(0, -0.72, 0), metal or C.STEEL, M.METAL, MT) end
local function glove(color) return B.box("Glove", v(1.1, 0.55, 1.1), cf(0, -0.75, 0), color or C.LEATHER, M.LEATHER) end
local function bracer(color) return B.box("Bracer", v(1.12, 0.9, 1.12), cf(0, -0.4, 0), color or C.LEATHER, M.LEATHER) end
local function trousers(color, slot) return B.box("Trousers", v(1.08, 2.04, 1.08), cf(0, 0, 0), color or C.CLOTH2, M.FABRIC, slot or S) end
local function boot(color, high) return B.box("Boot", v(1.1, high and 1.1 or 0.75, 1.16), cf(0, high and -0.5 or -0.65, -0.02), color or C.DARKLEATHER, M.LEATHER) end
local function greave(metal) return B.box("Greave", v(1.14, 1.15, 1.14), cf(0, -0.4, 0), metal or C.STEEL, M.METAL, MT) end
local function cuisse(metal) return B.box("Cuisse", v(1.14, 0.8, 1.14), cf(0, 0.55, 0), metal or C.STEEL, M.METAL, MT) end
local function knee(metal) return B.ball("Knee", 0.62, cf(0, 0.1, -0.5), metal or C.STEEL, M.METAL, MT) end
local function sabaton(metal) return B.box("Sabaton", v(1.14, 0.45, 1.3), cf(0, -0.8, -0.1), metal or C.STEEL, M.METAL, MT) end

local function arm(...) return B.join({middle(LIMB)}, {...}) end
local function leg(...) return B.join({middle(LIMB)}, {...}) end
local function both(fn) return fn(), fn() end

--------------------------------------------------------------------
--  LIGHT SETS
--------------------------------------------------------------------
A_.MarshWarden = {
	HeadClothing = hood(C.GREEN, P),
	TorsoClothing = B.join(jerkin(C.GREEN), cloak(C.GREEN, P), belt(-0.7)),
	LeftArmClothing = arm(sleeve(C.GREEN, P), bracer()),
	RightArmClothing = arm(sleeve(C.GREEN, P), bracer()),
	LeftLegClothing = leg(trousers(C.DARKLEATHER, S), boot(nil, true)),
	RightLegClothing = leg(trousers(C.DARKLEATHER, S), boot(nil, true)),
}
A_.Brigand = {
	HeadClothing = bandana(C.RED),
	TorsoClothing = B.join({middle(TORSO), B.box("Shirt", v(2.12, 2.06, 1.1), cf(), C.CLOTH2, M.FABRIC, S),
		B.box("Vest", v(2.2, 1.6, 1.18), cf(0, -0.05, 0), C.DARKLEATHER, M.LEATHER)},
		B.ring("Stud", 8, 0.95, v(0.1, 0.1, 0.1), 0.45, C.IRON, M.METAL, MT), belt(-0.75, C.IRON)),
	LeftArmClothing = arm(sleeve(C.CLOTH2, S), bracer(C.DARKLEATHER), glove(C.DARKLEATHER)),
	RightArmClothing = arm(sleeve(C.CLOTH2, S), bracer(C.DARKLEATHER), glove(C.DARKLEATHER)),
	LeftLegClothing = leg(trousers(C.BLACK, S), boot(C.DARKLEATHER)),
	RightLegClothing = leg(trousers(C.BLACK, S), boot(C.DARKLEATHER)),
}
A_.Woodsman = {
	HeadClothing = cap(C.LEATHER, C.RED),
	TorsoClothing = B.join({middle(TORSO), B.box("Tunic", v(2.14, 2.08, 1.12), cf(), C.CLOTH, M.FABRIC, P),
		B.box("Collar", v(0.6, 0.6, 0.12), cf(0, 0.75, -0.6), C.LINEN, M.FABRIC, A)}, belt(-0.6)),
	LeftArmClothing = arm(sleeve(C.CLOTH, P), glove(C.LEATHER)),
	RightArmClothing = arm(sleeve(C.CLOTH, P), glove(C.LEATHER)),
	LeftLegClothing = leg(trousers(C.LEATHER, S), boot()),
	RightLegClothing = leg(trousers(C.LEATHER, S), boot()),
}

--------------------------------------------------------------------
--  MEDIUM SETS
--------------------------------------------------------------------
A_.GildedCourt = {
	HeadClothing = kettleHat(C.STEEL, C.GOLD),
	TorsoClothing = B.join(gambeson(C.CLOTH, C.GOLD), pauldrons(v(0.7, 0.45, 1.1), C.STEEL, M.METAL, MT), belt(-0.75, C.GOLD)),
	LeftArmClothing = arm(mailSleeve(), vambrace(), glove(C.CLOTH2)),
	RightArmClothing = arm(mailSleeve(), vambrace(), glove(C.CLOTH2)),
	LeftLegClothing = leg(trousers(C.CLOTH2, S), greave(), boot()),
	RightLegClothing = leg(trousers(C.CLOTH2, S), greave(), boot()),
}
A_.Sergeant = {
	HeadClothing = coif(),
	TorsoClothing = B.join(brigandine(C.CLOTH2), belt(-0.8, C.IRON)),
	LeftArmClothing = arm(mailSleeve(), bracer(C.DARKLEATHER)),
	RightArmClothing = arm(mailSleeve(), bracer(C.DARKLEATHER)),
	LeftLegClothing = leg(B.box("Chausses", v(1.08, 2.04, 1.08), cf(), C.MAIL, M.PLATE), boot(C.DARKLEATHER)),
	RightLegClothing = leg(B.box("Chausses", v(1.08, 2.04, 1.08), cf(), C.MAIL, M.PLATE), boot(C.DARKLEATHER)),
}
A_.Freelancer = {
	HeadClothing = sallet(C.STEEL),
	TorsoClothing = B.join(mailShirt(), tabard(C.CLOTH, P, false), pauldrons(v(0.7, 0.4, 1.1), C.STEEL, M.METAL, MT), belt(-0.75)),
	LeftArmClothing = arm(mailSleeve(), vambrace(), elbow()),
	RightArmClothing = arm(mailSleeve(), vambrace(), elbow()),
	LeftLegClothing = leg(trousers(C.CLOTH2, S), greave(), knee(), boot()),
	RightLegClothing = leg(trousers(C.CLOTH2, S), greave(), knee(), boot()),
}

--------------------------------------------------------------------
--  HEAVY SETS
--------------------------------------------------------------------
A_.IronCrow = {
	HeadClothing = bascinet(C.BLACKIRON, true),
	TorsoClothing = B.join(plateTorso(C.BLACKIRON, C.IRON), pauldrons(v(0.8, 0.5, 1.2), C.BLACKIRON, M.METAL, MT, true), tabard(C.CLOTH, P, false), belt(-0.75, C.IRON)),
	LeftArmClothing = arm(sleeve(C.BLACK, S), rerebrace(C.BLACKIRON), vambrace(C.BLACKIRON), elbow(C.BLACKIRON), gauntlet(C.BLACKIRON)),
	RightArmClothing = arm(sleeve(C.BLACK, S), rerebrace(C.BLACKIRON), vambrace(C.BLACKIRON), elbow(C.BLACKIRON), gauntlet(C.BLACKIRON)),
	LeftLegClothing = leg(trousers(C.BLACK, S), cuisse(C.BLACKIRON), greave(C.BLACKIRON), knee(C.BLACKIRON), sabaton(C.BLACKIRON)),
	RightLegClothing = leg(trousers(C.BLACK, S), cuisse(C.BLACKIRON), greave(C.BLACKIRON), knee(C.BLACKIRON), sabaton(C.BLACKIRON)),
}
A_.Templar = {
	HeadClothing = greatHelm(C.STEEL, C.GOLD),
	TorsoClothing = B.join(plateTorso(C.STEEL, C.GOLD), tabard(C.WHITE, P, true, C.RED), pauldrons(v(0.75, 0.45, 1.15), C.STEEL, M.METAL, MT), belt(-0.75, C.GOLD)),
	LeftArmClothing = arm(mailSleeve(), rerebrace(), vambrace(), elbow(), gauntlet()),
	RightArmClothing = arm(mailSleeve(), rerebrace(), vambrace(), elbow(), gauntlet()),
	LeftLegClothing = leg(B.box("Chausses", v(1.08, 2.04, 1.08), cf(), C.MAIL, M.PLATE), cuisse(), greave(), knee(), sabaton()),
	RightLegClothing = leg(B.box("Chausses", v(1.08, 2.04, 1.08), cf(), C.MAIL, M.PLATE), cuisse(), greave(), knee(), sabaton()),
}
A_.RoyalGuard = {
	HeadClothing = armet(C.BRIGHT, C.RED),
	TorsoClothing = B.join(plateTorso(C.BRIGHT, C.GOLD), pauldrons(v(0.85, 0.55, 1.25), C.BRIGHT, M.METAL, MT), tabard(C.CLOTH, P, false),
		{B.box("Trim", v(0.2, 2.1, 0.12), cf(-0.62, -0.05, -0.64), C.GOLD, M.METAL, A), B.box("Trim", v(0.2, 2.1, 0.12), cf(0.62, -0.05, -0.64), C.GOLD, M.METAL, A)}, belt(-0.75, C.GOLD)),
	LeftArmClothing = arm(sleeve(C.CLOTH2, S), rerebrace(C.BRIGHT), vambrace(C.BRIGHT), elbow(C.GOLD), gauntlet(C.BRIGHT)),
	RightArmClothing = arm(sleeve(C.CLOTH2, S), rerebrace(C.BRIGHT), vambrace(C.BRIGHT), elbow(C.GOLD), gauntlet(C.BRIGHT)),
	LeftLegClothing = leg(trousers(C.CLOTH2, S), cuisse(C.BRIGHT), greave(C.BRIGHT), knee(C.GOLD), sabaton(C.BRIGHT)),
	RightLegClothing = leg(trousers(C.CLOTH2, S), cuisse(C.BRIGHT), greave(C.BRIGHT), knee(C.GOLD), sabaton(C.BRIGHT)),
}

-- fallbacks for the three hand-made sets, used only if a set folder has no models
A_.KnightSkin = {
	HeadClothing = bascinet(C.STEEL, false),
	TorsoClothing = B.join(plateTorso(C.STEEL, C.IRON), pauldrons(v(0.75, 0.45, 1.15), C.STEEL, M.METAL, MT), belt(-0.75)),
	LeftArmClothing = arm(sleeve(C.CLOTH2, S), vambrace(), rerebrace(), gauntlet()),
	RightArmClothing = arm(sleeve(C.CLOTH2, S), vambrace(), rerebrace(), gauntlet()),
	LeftLegClothing = leg(trousers(C.CLOTH2, S), cuisse(), greave(), sabaton()),
	RightLegClothing = leg(trousers(C.CLOTH2, S), cuisse(), greave(), sabaton()),
}
A_.GambesonSkin = {
	HeadClothing = kettleHat(C.IRON, C.IRON),
	TorsoClothing = B.join(gambeson(C.CLOTH, C.CLOTH2), belt(-0.75)),
	LeftArmClothing = arm(sleeve(C.CLOTH, P), glove()),
	RightArmClothing = arm(sleeve(C.CLOTH, P), glove()),
	LeftLegClothing = leg(trousers(C.CLOTH2, S), boot()),
	RightLegClothing = leg(trousers(C.CLOTH2, S), boot()),
}
A_.PeasantSkin = {
	TorsoClothing = B.join({middle(TORSO), B.box("Tunic", v(2.12, 2.06, 1.1), cf(), C.LINEN, M.FABRIC, P)}, belt(-0.6, C.IRON)),
	LeftArmClothing = arm(sleeve(C.LINEN, P)),
	RightArmClothing = arm(sleeve(C.LINEN, P)),
}

return A_
