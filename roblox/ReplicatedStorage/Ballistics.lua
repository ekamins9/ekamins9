--[[ BALLISTICS — the way to loose an arrow so it lands where you aim. An arrow
     falls (gravity) as it flies, so pointing straight at a far target drops it
     short; this finds the launch that carries it there on its arc. RangedClient
     (your own arrow, at once) and RangedServer (the real one) both use it, each
     with its own speed.

       Ballistics.aim(origin, target, speed, gravity) → unit direction, reachable
         the flatter of the two arcs through `target`; out of reach, the arc that
         carries furthest toward it (reachable = false)
       Ballistics.launch(head, target, speed, gravity) → direction, origin
         the same from the head: the arrow leaves 1.2 studs out along its way
         (and a little low), so the origin is refined with the answer ]]

local Ballistics = {}

local OUT, DROP = 1.2, Vector3.new(0, -0.2, 0)

function Ballistics.aim(origin, target, speed, g)
	local d = target - origin
	local flat = Vector3.new(d.X, 0, d.Z)
	local x, y = flat.Magnitude, d.Y
	if x < 0.5 or g <= 0 or speed <= 0 then return d.Magnitude > 1e-3 and d.Unit or Vector3.new(0, 0, -1), true end
	local v2 = speed * speed
	local disc = v2 * v2 - g * (g * x * x + 2 * y * v2)
	local angle, reachable
	if disc >= 0 then
		angle, reachable = math.atan((v2 - math.sqrt(disc)) / (g * x)), true
	else
		-- too far: halfway between the line to it and straight up (45° on the flat), the arc
		-- that needs the least speed to get there, so it carries closest
		angle, reachable = (math.atan2(y, x) + math.pi / 2) / 2, false
	end
	angle = math.min(angle, math.rad(60))
	local h = flat.Unit
	return (h * math.cos(angle) + Vector3.new(0, math.sin(angle), 0)).Unit, reachable
end

function Ballistics.launch(headPos, target, speed, g)
	local dir = (target - headPos).Unit
	local origin = headPos + dir * OUT + DROP
	for _ = 1, 2 do
		dir = Ballistics.aim(origin, target, speed, g)
		origin = headPos + dir * OUT + DROP
	end
	return dir, origin
end

return Ballistics
