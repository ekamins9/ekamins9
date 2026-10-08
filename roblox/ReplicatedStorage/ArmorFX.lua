--[[ ARMOR FX — puts an armor finish (Catalog ▸ ArmorFX) on a dressed
     character: called by the Dresser after it paints, so a real spawn (the
     server) and a menu mannequin (the client) wear it the same.

       ArmorFX.apply(container, char, finishId, preview, builtIn)
         container   the character's Armor folder (the Dresser's)
         preview     a menu rig: colours and glow only (a ViewportFrame shows no
                     particles or lights)
         builtIn     a crate set's own finish: it keeps the set's own metal and
                     cloth, and only lights the trims and brings the aura

     The plates (the Metal colour slot, or any metal part) take the finish's
     metal; the trims (the Accent slot, gilt bits, the small metal bits on a set
     that has no trim) its accent, glowing; cloth and leather are tinted. The
     aura's particles come off the shoulders, the arms and the legs, the light
     sits on the chest. Glowing trims are tagged "ArmorGlow" (attribute Mode =
     pulse | flicker | radiant) and StarterPlayerScripts ▸ ArmorFX makes them
     breathe. Looks only. ]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CollectionService = game:GetService("CollectionService")
local Catalog = require(ReplicatedStorage:WaitForChild("Catalog"))
local SkinFX = require(ReplicatedStorage:WaitForChild("SkinFX"))

local ArmorFX = {}

local METAL = {[Enum.Material.Metal] = true, [Enum.Material.DiamondPlate] = true, [Enum.Material.CorrodedMetal] = true, [Enum.Material.Foil] = true}
local function gilt(c) return c.R > 0.65 and c.G > 0.45 and c.B < 0.42 and c.R - c.B > 0.3 end

-- where the particles come off: the shoulders, the forearms, the shins (a garment's
-- Middle part is the size of the limb it's on)
local SPOTS = {
	TorsoClothing = {Vector3.new(-0.9, 0.9, 0), Vector3.new(0.9, 0.9, 0)},
	LeftArmClothing = {Vector3.new(0, -0.6, 0)}, RightArmClothing = {Vector3.new(0, -0.6, 0)},
	LeftLegClothing = {Vector3.new(0, -0.5, 0)}, RightLegClothing = {Vector3.new(0, -0.5, 0)},
}
local RATE = {0.22, 0.22, 0.3, 0.4}   -- × the weapon aura's rates, per spot (a whole body of it), by tier
local TIER = {Common = 1, Rare = 1, Epic = 2, Legendary = 3, Mythic = 4}
ArmorFX.TIER = TIER

function ArmorFX.def(id) return id and Catalog.ARMORFX_BY and Catalog.ARMORFX_BY[id] or nil end

function ArmorFX.apply(container, char, id, preview, builtIn)
	local def = ArmorFX.def(id)
	if not (def and container) then return false end
	local L = def.look or {}
	if builtIn then L = {accent = L.accent, glow = L.glow, pulse = L.pulse, flicker = L.flicker, radiant = L.radiant, aura = L.aura, light = L.light} end
	local metals, accents = {}, {}
	for _, p in ipairs(container:GetDescendants()) do
		if p:IsA("BasePart") and p.Transparency < 1 and p.Name ~= "Middle" then
			local slot = p:GetAttribute("ColorSlot")
			if slot == "Accent" or (not slot and METAL[p.Material] and gilt(p.Color)) then
				table.insert(accents, p)
			elseif slot == "Metal" or (not slot and METAL[p.Material]) then
				table.insert(metals, p)
			elseif (slot == "Primary" or slot == "Secondary" or not slot) then
				if L.tint then p.Color = p.Color:Lerp(L.tint[1], L.tint[2]) end
				if L.body and (slot == "Primary" or slot == "Secondary") then p.Material = Enum.Material[L.body] end
			end
		end
	end
	-- (a set with no trims at all: its smallest metal bits — rivets, studs, edges — become them)
	if #accents == 0 and #metals > 0 and L.accent then
		table.sort(metals, function(a, b) return a.Size.Magnitude < b.Size.Magnitude end)
		local n = math.max(1, math.floor(#metals * 0.25))
		for i = 1, n do table.insert(accents, table.remove(metals, 1)) end
	end
	for _, p in ipairs(metals) do
		if L.metal then p.Color = L.metal end
		if L.metalMaterial then p.Material = Enum.Material[L.metalMaterial] end
	end
	-- (a glowing part shows far brighter than its colour: it's dimmed, so a trim glows instead of glaring)
	local glowCol = L.accent and L.accent:Lerp(Color3.new(0, 0, 0), 0.32)
	for _, p in ipairs(accents) do
		if L.accent then p.Color = L.accent end
		if L.glow then
			p.Material = Enum.Material.Neon
			p.Color = glowCol
			p:SetAttribute("GlowColor", glowCol)
			p:SetAttribute("Mode", L.radiant and "radiant" or (L.flicker and "flicker" or (L.pulse and "pulse" or nil)))
			if L.radiant or L.flicker or L.pulse then CollectionService:AddTag(p, "ArmorGlow") end
		end
	end
	container:SetAttribute("Finish", id)
	-- what StarterPlayerScripts ▸ ArmorFX needs for the rest: footprints, streaks, surges,
	-- motes and a rim, by the finish's rarity (on menu mannequins too)
	container:SetAttribute("FinishTier", TIER[def.rarity] or 1)
	container:SetAttribute("FinishAccent", glowCol or L.accent or Color3.new(1, 1, 1))
	container:SetAttribute("FinishAura", L.aura)
	container:SetAttribute("FinishRadiant", L.radiant == true)
	CollectionService:AddTag(container, "FinishWorn")
	if preview then return true end
	-- the aura: particles off the shoulders, arms and legs
	local aura = L.aura and SkinFX.AURA_DEF and SkinFX.AURA_DEF[L.aura]
	if aura then
		for _, m in ipairs(container:GetChildren()) do
			local spots = SPOTS[m.Name]
			local mid = spots and m:FindFirstChild("Middle")
			if mid and mid:IsA("BasePart") then
				for i, pos in ipairs(spots) do
					local a = Instance.new("Attachment"); a.Name = "FinishFX" .. i; a.Position = pos; a.Parent = mid
					for j, e in ipairs(aura.emit or {}) do
						if not e.locked then
							local pe = SkinFX.makeEmitter(e, "Finish" .. j)
							pe.Rate = (e.rate or 0) * RATE[TIER[def.rarity] or 1]
							pe:SetAttribute("BaseRate", pe.Rate)
							pe.Parent = a
						end
					end
				end
			end
		end
	end
	-- the glow on the chest
	if L.light then
		local torso = container:FindFirstChild("TorsoClothing")
		local mid = torso and torso:FindFirstChild("Middle")
		if mid then
			local l = Instance.new("PointLight"); l.Name = "FinishLight"; l.Color = L.light; l.Brightness = 0.9; l.Range = 9; l.Shadows = false
			l.Parent = mid
		end
	end
	return true
end

return ArmorFX
