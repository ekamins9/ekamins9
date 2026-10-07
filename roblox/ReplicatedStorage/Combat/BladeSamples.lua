--[[ BLADE SAMPLES — the points on a weapon's Hitbox that the sweep traces
     every frame (CombatClient for players, CombatServer for NPCs).

     The spine runs down the box's long axis, one point per ~0.45 studs (at
     least `min`), so a long blade can't slip a thin target between samples.
     A wide striking head (an axe bit, a halberd, a maul) also gets lines along
     the outer faces of the box: the edge that actually leads the swing is
     traced, not just the haft's centre line — the hit lands when the steel
     arrives, not a stud later. ]]

local BladeSamples = {}

BladeSamples.SPACING = 0.45   -- studs between points along the spine
BladeSamples.WIDE    = 0.7    -- a cross dimension above this gets edge lines
BladeSamples.INSET   = 0.1    -- edge lines sit this far inside the box faces
BladeSamples.MAX_PER_LINE = 12

-- offsets (box space) and the spine's two ends (for the trail)
function BladeSamples.offsets(size, min, maxLines)
	local dims = {{Vector3.xAxis, size.X}, {Vector3.yAxis, size.Y}, {Vector3.zAxis, size.Z}}
	table.sort(dims, function(a, b) return a[2] > b[2] end)
	local axis, len = dims[1][1], dims[1][2]
	local n = math.clamp(math.ceil(len / BladeSamples.SPACING) + 1, min or 6, math.max(min or 6, BladeSamples.MAX_PER_LINE))
	local spine = {}
	for i = 0, n - 1 do
		spine[#spine + 1] = axis * (len * (n > 1 and (i / (n - 1) - 0.5) or 0))
	end
	local lines = {Vector3.zero}
	for k = 2, 3 do
		local w = dims[k][2]
		if w > BladeSamples.WIDE then
			local o = dims[k][1] * (w / 2 - BladeSamples.INSET)
			table.insert(lines, o)
			table.insert(lines, -o)
		end
	end
	maxLines = maxLines or 5
	local offsets = {}
	for li = 1, math.min(#lines, maxLines) do
		for _, s in ipairs(spine) do offsets[#offsets + 1] = lines[li] + s end
	end
	return offsets, spine[1], spine[#spine]
end

return BladeSamples
