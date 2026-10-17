--[[ ARSENAL BLUEPRINTS — the bodies of the shields and the throwables (Catalog ▸ Arsenal),
     added to Build ▸ Weapons' list, so Blueprints builds each Tool (ServerStorage ▸ Weapons ▸
     <id>) and its menu display the same way as any weapon's.

     A SHIELD's frame: the Handle (its grip) at the origin, the face in front of it (toward -Z)
     standing upright (+Y), so a menu shows it face on. The main board carries ShieldFace =
     true (ReplicatedStorage ▸ Heraldry paints arms on it); the board is SkinPart "Blade" (a
     skin's field colour), the rim and the boss "Grip" (its metal).
     A THROWABLE is laid out like a blade: the Handle at the origin, the business end up (+Y). ]]

return function(W, B)
	local C, M = B.C, B.M
	local cf, v = B.cf, B.v
	local RIM = {SkinPart = "Grip"}
	-- the main board: where Heraldry paints (its size and where its front is, in the Handle's frame)
	-- (shape: the board's outline, for a skin's ornaments to follow: ReplicatedStorage ▸ ShieldDress)
	local function FACE(w, h, y, z, isRound, shape)
		return {SkinPart = "Blade", ShieldFace = true, FaceW = w, FaceH = h, FaceY = y, FaceZ = z, FaceRound = isRound or nil,
			FaceShape = shape or (isRound and "round") or "rect"}
	end
	local BOARD = {SkinPart = "Blade"}

	-- the grip behind the board, and the arm strap
	local function grip()
		return {
			B.box("Handle", v(0.22, 0.7, 0.22), cf(0, 0, 0), C.DARKLEATHER, M.LEATHER, {SkinPart = "Grip"}),
			B.box("Strap", v(0.9, 0.16, 0.06), cf(0, 0.55, 0.05), C.LEATHER, M.LEATHER),
		}
	end
	-- a round shield: a board of diameter d, a rim behind it, a boss in the middle
	local function round(d, thick, faceColor, faceMat, rimColor, bossD)
		local out = grip()
		table.insert(out, B.cyl("Face", d, thick, cf(0, 0, -0.3, 90, 0, 0), faceColor, faceMat, FACE(d, d, 0, -0.3 - thick / 2, true)))
		table.insert(out, B.cyl("Rim", d + 0.12, thick * 0.6, cf(0, 0, -0.27, 90, 0, 0), rimColor or C.IRON, M.METAL, RIM))
		if bossD then table.insert(out, B.ball("Boss", bossD, cf(0, 0, -0.3 - thick / 2), C.STEEL, M.METAL, RIM)) end
		return out
	end

	W.Buckler = function()
		local out = round(1.4, 0.1, C.STEEL, M.METAL, C.DARKSTEEL, 0.5)
		return out
	end
	W.Targe = function()
		local out = round(2.2, 0.12, C.LEATHER, M.LEATHER, C.BRASS, 0.5)
		for i = 1, 8 do
			local a = i / 8 * math.pi * 2
			table.insert(out, B.ball("Stud", 0.14, cf(math.cos(a) * 0.78, math.sin(a) * 0.78, -0.38), C.BRASS, M.METAL, RIM))
		end
		return out
	end
	W.RoundShield = function()
		local out = round(2.8, 0.14, C.WOOD, M.WOOD, C.IRON, 0.6)
		-- the planks, seen through the paint
		for i = -2, 2 do table.insert(out, B.box("Plank", v(0.03, 2.5 - math.abs(i) * 0.35, 0.02), cf(i * 0.5, 0, -0.38), C.DARKWOOD, M.WOOD)) end
		return out
	end
	W.SpikedShield = function()
		local out = round(2.5, 0.14, C.DARKWOOD, M.WOOD, C.BLACKIRON, 0.62)
		table.insert(out, B.cone("Spike", 0.34, 0.9, cf(0, 0, -0.85, -90, 0, 0), C.STEEL, M.METAL, RIM))
		for i = 1, 6 do
			local a = i / 6 * math.pi * 2
			table.insert(out, B.cone("Stud", 0.16, 0.22, cf(math.cos(a) * 0.95, math.sin(a) * 0.95, -0.45, -90, 0, 0), C.STEEL, M.METAL, RIM))
		end
		return out
	end
	-- the heater: a flat top, straight sides, and a point (the lower half is a diamond tucked
	-- behind the top board)
	W.Heater = function()
		local out = grip()
		table.insert(out, B.box("Face", v(2.3, 1.55, 0.14), cf(0, 0.55, -0.3), C.CLOTH, M.WOOD, FACE(2.3, 2.6, 0.05, -0.37, false, "heater")))
		table.insert(out, B.box("Point", v(1.63, 1.63, 0.14), cf(0, -0.2, -0.29, 0, 0, 45), C.CLOTH, M.WOOD, BOARD))
		table.insert(out, B.box("Rim", v(2.42, 0.12, 0.2), cf(0, 1.34, -0.3), C.IRON, M.METAL, RIM))
		for _, s in ipairs({-1, 1}) do
			table.insert(out, B.box("Rim", v(0.1, 1.7, 0.2), cf(s * 1.16, 0.52, -0.3), C.IRON, M.METAL, RIM))
			-- (and down the point's two edges, so the rim runs all the way round)
			table.insert(out, B.box("Rim", v(1.7, 0.1, 0.2), cf(s * 0.585, -0.785, -0.3, 0, 0, s * 45), C.IRON, M.METAL, RIM))
		end
		return out
	end
	W.Kite = function()
		local out = grip()
		table.insert(out, B.cyl("Crown", 2.2, 0.14, cf(0, 0.75, -0.31, 90, 0, 0), C.CLOTH, M.WOOD, BOARD))
		table.insert(out, B.box("Face", v(2.2, 1.25, 0.14), cf(0, 0.125, -0.3), C.CLOTH, M.WOOD, FACE(2.0, 3.2, 0.1, -0.38, false, "kite")))
		-- the long point: two wedges meeting at x = 0, from the board's foot (y -0.5) down to y -2
		local down = CFrame.new(0, 0, -0.3) * CFrame.Angles(0, 0, math.pi)
		for _, s in ipairs({-1, 1}) do
			table.insert(out, B.wedge("Point", v(0.14, 1.5, 1.1), down * cf(s * 0.55, 1.25, 0, 0, -s * 90, 0), C.CLOTH, M.WOOD, BOARD))
		end
		table.insert(out, B.ball("Boss", 0.4, cf(0, 0.3, -0.4), C.STEEL, M.METAL, RIM))
		-- the iron rim all round: over the top in short lengths, down the sides, down the point
		for k = 0, 7 do
			local a = math.pi * (k + 0.5) / 8
			table.insert(out, B.box("Rim", v(0.46, 0.1, 0.2), cf(math.cos(a) * 1.13, 0.75 + math.sin(a) * 1.13, -0.31, 0, 0, math.deg(a) + 90), C.IRON, M.METAL, RIM))
		end
		for _, s in ipairs({-1, 1}) do
			table.insert(out, B.box("Rim", v(0.1, 1.3, 0.2), cf(s * 1.13, 0.125, -0.3), C.IRON, M.METAL, RIM))
			table.insert(out, B.box("Rim", v(1.92, 0.1, 0.2), cf(s * 0.565, -1.25, -0.3, 0, 0, s * math.deg(math.atan2(1.5, 1.1))), C.IRON, M.METAL, RIM))
		end
		return out
	end
	-- the scutum: a tall board bent round you (a middle panel and two angled sides)
	W.Scutum = function()
		local out = grip()
		table.insert(out, B.box("Face", v(1.3, 3.6, 0.14), cf(0, 0, -0.32), C.RED, M.WOOD, FACE(1.3, 3.4, 0, -0.39, false, "scutum")))
		for _, s in ipairs({-1, 1}) do
			table.insert(out, B.box("Side", v(0.75, 3.6, 0.14), cf(s * 0.98, 0, -0.18, 0, s * -28, 0), C.RED, M.WOOD, BOARD))
			table.insert(out, B.box("Rim", v(0.08, 3.7, 0.18), cf(s * 1.32, 0, -0.02, 0, s * -28, 0), C.BRASS, M.METAL, RIM))
		end
		table.insert(out, B.ball("Boss", 0.62, cf(0, 0, -0.4), C.BRASS, M.METAL, RIM))
		table.insert(out, B.box("Spine", v(0.22, 3.4, 0.06), cf(0, 0, -0.41), C.BRASS, M.METAL, RIM))
		return out
	end
	W.Pavise = function()
		local out = grip()
		-- (its paint lies on the board itself, under the ridge: PaintZ, ReplicatedStorage ▸ ShieldPaint)
		local face = FACE(2.5, 3.9, 0.2, -0.55, false, "rect")
		face.PaintZ = -0.425
		table.insert(out, B.box("Face", v(2.6, 4.0, 0.2), cf(0, 0.2, -0.32), C.CLOTH, M.WOOD, face))
		table.insert(out, B.box("Ridge", v(0.42, 4.0, 0.14), cf(0, 0.2, -0.47), C.CLOTH, M.WOOD, BOARD))
		for _, s in ipairs({-1, 1}) do
			table.insert(out, B.box("Rim", v(0.12, 4.1, 0.24), cf(s * 1.3, 0.2, -0.32), C.IRON, M.METAL, RIM))
		end
		table.insert(out, B.box("Rim", v(2.7, 0.12, 0.24), cf(0, 2.22, -0.32), C.IRON, M.METAL, RIM))
		table.insert(out, B.box("Rim", v(2.7, 0.12, 0.24), cf(0, -1.82, -0.32), C.IRON, M.METAL, RIM))
		return out
	end

	--------------------------------------------------------------------
	--  THROWABLES
	--------------------------------------------------------------------
	local BLADE, GRIP, METAL = {SkinPart = "Blade"}, {SkinPart = "Grip"}, {SkinPart = "Metal"}
	W.ThrowingKnives = function()
		return {
			B.box("Handle", v(0.13, 0.42, 0.06), cf(0, 0, 0), C.DARKLEATHER, M.LEATHER, GRIP),
			B.box("Blade", v(0.2, 0.72, 0.04), cf(0, 0.56, 0), C.STEEL, M.METAL, BLADE),
			B.box("Tip", v(0.14, 0.14, 0.04), cf(0, 0.92, 0, 0, 0, 45), C.STEEL, M.METAL, BLADE),
			B.ball("Ring", 0.14, cf(0, -0.27, 0), C.IRON, M.METAL, METAL),
		}
	end
	W.ThrowingAxe = function()
		return {
			B.box("Handle", v(0.15, 1.5, 0.15), cf(0, 0, 0), C.WOOD, M.WOOD, GRIP),
			B.box("Head", v(0.62, 0.42, 0.08), cf(0.26, 0.6, 0), C.STEEL, M.METAL, BLADE),
			B.box("Edge", v(0.1, 0.66, 0.06), cf(0.58, 0.58, 0), C.BRIGHT, M.METAL, BLADE),
			B.box("Socket", v(0.22, 0.36, 0.2), cf(0, 0.62, 0), C.IRON, M.METAL, METAL),
		}
	end
	W.Plumbata = function()
		return {
			B.box("Handle", v(0.1, 0.4, 0.1), cf(0, 0, 0), C.WOOD, M.WOOD, GRIP),
			B.cyl("Shaft", 0.08, 1.2, cf(0, 0.6, 0), C.WOOD, M.WOOD, GRIP),
			B.ball("Weight", 0.24, cf(0, 0.95, 0), C.DARKSTEEL, M.METAL, METAL),
			B.cone("Spike", 0.12, 0.4, cf(0, 1.3, 0), C.STEEL, M.METAL, BLADE),
			B.box("Fletch", v(0.3, 0.32, 0.02), cf(0, -0.32, 0), C.LINEN, M.FABRIC, BLADE),
			B.box("Fletch", v(0.02, 0.32, 0.3), cf(0, -0.32, 0), C.LINEN, M.FABRIC, BLADE),
		}
	end
	W.Javelin = function()
		return {
			B.box("Handle", v(0.14, 0.5, 0.14), cf(0, 0, 0), C.DARKLEATHER, M.LEATHER, GRIP),
			B.cyl("Shaft", 0.12, 4.0, cf(0, 0.4, 0), C.WOOD, M.WOOD, GRIP),
			B.box("Head", v(0.22, 0.7, 0.05), cf(0, 2.65, 0), C.STEEL, M.METAL, BLADE),
			B.box("Point", v(0.16, 0.16, 0.05), cf(0, 3.0, 0, 0, 0, 45), C.STEEL, M.METAL, BLADE),
			B.cyl("Socket", 0.16, 0.3, cf(0, 2.25, 0), C.IRON, M.METAL, METAL),
		}
	end
	-- a flask: the neck is the grip, the body hangs below
	local function flask(body, bodyMat, extra)
		local out = {
			B.box("Handle", v(0.18, 0.3, 0.18), cf(0, 0, 0), body, bodyMat, BLADE),
			B.ball("Body", 0.62, cf(0, -0.38, 0), body, bodyMat, BLADE),
			B.cyl("Cork", 0.16, 0.14, cf(0, 0.2, 0), C.WOOD, M.WOOD, GRIP),
		}
		for _, e in ipairs(extra or {}) do table.insert(out, e) end
		return out
	end
	W.Firebomb = function()
		return flask(Color3.fromRGB(150, 96, 60), M.SLATE, {B.box("Rag", v(0.14, 0.34, 0.06), cf(0.04, 0.38, 0, 0, 0, 15), C.LINEN, M.FABRIC, GRIP)})
	end
	W.FrostFlask = function() return flask(Color3.fromRGB(150, 210, 255), Enum.Material.Glass) end
	W.HolyWater = function()
		return flask(Color3.fromRGB(230, 240, 255), Enum.Material.Glass, {B.box("Cross", v(0.22, 0.06, 0.04), cf(0, -0.36, -0.31), C.GOLD, M.METAL, METAL),
			B.box("Cross", v(0.06, 0.3, 0.04), cf(0, -0.36, -0.31), C.GOLD, M.METAL, METAL)})
	end
	W.SmokeBomb = function()
		return {
			B.box("Handle", v(0.14, 0.2, 0.14), cf(0, 0, 0), C.DARKSTEEL, M.METAL, GRIP),
			B.ball("Body", 0.6, cf(0, -0.36, 0), Color3.fromRGB(70, 70, 76), M.SLATE, BLADE),
			B.cyl("Fuse", 0.06, 0.28, cf(0, 0.2, 0), C.ROPE, M.FABRIC, GRIP),
		}
	end
	W.Caltrops = function()
		local out = {
			B.box("Handle", v(0.16, 0.2, 0.16), cf(0, 0, 0), C.LEATHER, M.LEATHER, GRIP),
			B.ball("Pouch", 0.55, cf(0, -0.35, 0), C.LEATHER, M.LEATHER, GRIP),
		}
		for i = 1, 4 do
			local a = i / 4 * math.pi * 2
			table.insert(out, B.cone("Spike", 0.1, 0.32, cf(math.cos(a) * 0.22, -0.2, math.sin(a) * 0.22, 0, 0, 0), C.IRON, M.METAL, BLADE))
		end
		return out
	end
	W.Bolas = function()
		local out = {B.box("Handle", v(0.16, 0.16, 0.16), cf(0, 0, 0), C.ROPE, M.FABRIC, GRIP)}
		for i = 1, 3 do
			local a = i / 3 * math.pi * 2
			local x, z = math.cos(a) * 0.55, math.sin(a) * 0.55
			table.insert(out, B.box("Cord", v(0.04, 0.6, 0.04), cf(x / 2, -0.25, z / 2, math.deg(-z) * 0.9, 0, math.deg(x) * 0.9), C.ROPE, M.FABRIC, GRIP))
			table.insert(out, B.ball("Weight", 0.26, cf(x, -0.5, z), C.DARKSTEEL, M.METAL, BLADE))
		end
		return out
	end
end
