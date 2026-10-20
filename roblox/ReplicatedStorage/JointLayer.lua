--[[ JOINT LAYER — procedural motion laid over the animation, on every screen. The effect scripts
     (HitReact, ClashFX, DrawFX, SwingMomentum) say what they want each frame; this lays it all
     down once, after everyone's clips have posed them, on top of the frame's animated pose.

     Why here and not in Stepped: a bot's clip is laid down on your screen after Stepped, so a turn
     made in Stepped never showed on a bot (your own body's clip runs before Stepped; the render
     step comes after both, so it shows on everyone).

       JointLayer.bind(name, fn)            fn(dt) every frame, before the layer goes down: where an
                                            effect works out what it wants
       JointLayer.turn(motor, r)            r, a rotation in the joint's frame (its C0 space), laid
                                            before the animation's Transform (r * Transform)
       JointLayer.blend(motor, target, w)   the Transform eased toward `target` by w (0..1)
       JointLayer.fresh(motor) -> bool      the animation (or anyone) has posed this joint since the
                                            layer last did: its parts show the clip, not the layer

     A joint the animation left alone this frame (no clip on it, a far body's throttled update) is
     rebuilt from its last animated pose, never laid on its own last frame, so a turn can't pile up
     into a spin; and a joint nobody asks for any more is put back to that pose. ]]

local RunService = game:GetService("RunService")

local JointLayer = {}
local PRE = Enum.RenderPriority.Character.Value + 5
local APPLY = Enum.RenderPriority.Character.Value + 40

local ops = {}                                   -- [motor] = {{r} | {nil, target, w}, …} this frame
local memo = setmetatable({}, {__mode = "k"})    -- [motor] = {written = CFrame, base = CFrame}

local function list(motor)
	local l = ops[motor]
	if not l then l = {}; ops[motor] = l end
	return l
end
function JointLayer.turn(motor, r)
	if motor then table.insert(list(motor), {r}) end
end
function JointLayer.blend(motor, target, w)
	if motor and w > 0 then table.insert(list(motor), {nil, target, math.min(w, 1)}) end
end
function JointLayer.fresh(motor)
	local m = memo[motor]
	return not (m and motor.Transform == m.written)
end
local bound = {}
function JointLayer.bind(name, fn)
	if bound[name] then RunService:UnbindFromRenderStep(name) end
	bound[name] = true
	RunService:BindToRenderStep(name, PRE, fn)
end

RunService:BindToRenderStep("JointLayer", APPLY, function()
	-- (laid last frame, nothing asked this frame: back to the animated pose, if the clip didn't)
	for motor, m in pairs(memo) do
		if not ops[motor] then
			if motor.Parent and motor.Transform == m.written then motor.Transform = m.base end
			memo[motor] = nil
		end
	end
	for motor, l in pairs(ops) do
		if motor.Parent then
			local cur = motor.Transform
			local m = memo[motor]
			local base = (m and cur == m.written) and m.base or cur
			local t = base
			for _, op in ipairs(l) do
				if op[1] then t = op[1] * t else t = t:Lerp(op[2], op[3]) end
			end
			motor.Transform = t
			memo[motor] = {written = t, base = base}
		end
	end
	table.clear(ops)
end)

return JointLayer
