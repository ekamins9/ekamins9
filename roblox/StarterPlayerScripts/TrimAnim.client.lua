--[[ TRIM ANIM — the moving parts of a skin's trim (ReplicatedStorage ▸ StaffHeads: a
     staff's planets in orbit, a gyroscope's rings, a gem turning, wings beating, a heart
     that beats), on every weapon this client sees: in someone's hands, hung on their
     back, lying on the ground, and in the menus' previews. A Trim folder tagged
     "TrimAnim" holds parts with an Anim attribute; each frame each part's weld is set
     from its BaseC0 turned by its rotations (AnimC/A/S 1..n, innermost first), its
     swing (AnimOsc), its bob (AnimBob) and its glow's breath (AnimPulse: transparency).
     A preview (anchored, or not in the world) is moved by its CFrame instead.
     The head's lights breathe (Pulse), flicker (Flicker) or walk the rainbow (Hue), and
     its lightning (a Beam with Crackle) jumps about. Looks only, all local; weapons
     farther than FAR are left still. ]]

local CollectionService = game:GetService("CollectionService")
local RunService = game:GetService("RunService")

local UserInputService = game:GetService("UserInputService")
-- (a phone: heads move only close by, half as often; everywhere: only what's on screen)
local PHONE = UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled
local FAR = PHONE and 60 or 140   -- studs: past this the head stops moving (it can't be made out)
local frame = 0
local CRACKLE = 0.06     -- seconds between a lightning beam's jumps
local rng = Random.new()

local folders = {}   -- [Trim folder] = state

local function scanFx(st)
	st.lights, st.beams = {}, {}
	local tool = st.folder.Parent
	if not tool then return end
	for _, d in ipairs(tool:GetDescendants()) do
		if d:IsA("PointLight") and d.Name == "HeadLight" then
			table.insert(st.lights, {light = d, base = d:GetAttribute("BaseBrightness") or d.Brightness, pulse = d:GetAttribute("Pulse"), flicker = d:GetAttribute("Flicker"), hue = d:GetAttribute("Hue")})
		elseif d:IsA("Beam") and d:GetAttribute("Crackle") then
			table.insert(st.beams, {beam = d, w = d.Width0})
		end
	end
	st.scanAt = os.clock()
end

local function track(folder, again)
	if folders[folder] or not folder:IsA("Folder") then return end
	local list = {}
	for _, p in ipairs(folder:GetChildren()) do
		if p:IsA("BasePart") and p:GetAttribute("Anim") and typeof(p:GetAttribute("BaseC0")) == "CFrame" then
			local e = {part = p, weld = p:FindFirstChildOfClass("Weld"), base = p:GetAttribute("BaseC0"), rots = {},
				bob = p:GetAttribute("AnimBob"), pulse = p:GetAttribute("AnimPulse")}
			for k = 1, 4 do
				local c = p:GetAttribute("AnimC" .. k)
				if typeof(c) ~= "Vector3" then break end
				table.insert(e.rots, {c = c, a = p:GetAttribute("AnimA" .. k), s = p:GetAttribute("AnimS" .. k) or 0})
			end
			local oc = p:GetAttribute("AnimOscC")
			if typeof(oc) == "Vector3" then e.osc = {c = oc, a = p:GetAttribute("AnimOscA"), v = p:GetAttribute("AnimOsc")} end
			table.insert(list, e)
		end
	end
	local handle = folder.Parent and folder.Parent:FindFirstChild("Handle")
	if #list == 0 or not handle then
		-- (its parts still coming in over the wire: one more look in a moment)
		if not again then task.delay(0.5, function() if folder.Parent then track(folder, true) end end) end
		return
	end
	local st = {folder = folder, list = list, handle = handle, crackleAt = 0}
	folders[folder] = st
	scanFx(st)
end

CollectionService:GetInstanceAddedSignal("TrimAnim"):Connect(function(f) task.defer(track, f) end)
CollectionService:GetInstanceRemovedSignal("TrimAnim"):Connect(function(f) folders[f] = nil end)
for _, f in ipairs(CollectionService:GetTagged("TrimAnim")) do task.defer(track, f) end

RunService.RenderStepped:Connect(function()
	frame += 1
	if PHONE and frame % 2 == 1 then return end
	local t = os.clock()
	local cam = workspace.CurrentCamera
	local camPos = cam and cam.CFrame.Position or Vector3.zero
	for folder, st in pairs(folders) do
		local h = st.handle
		if not (folder.Parent and h.Parent) then
			folders[folder] = nil
		else
			local inWorld = folder:IsDescendantOf(workspace)
			local seen = not inWorld
			if inWorld and (h.Position - camPos).Magnitude < FAR then
				local _, onScreen = cam:WorldToViewportPoint(h.Position)
				seen = onScreen or (h.Position - camPos).Magnitude < 8
			end
			if seen then
				local byWeld = inWorld and not h.Anchored
				local hcf = (not byWeld) and h.CFrame or nil
				for _, e in ipairs(st.list) do
					local c0 = e.base
					if e.osc then
						local ang = e.osc.v.X * math.sin(t * e.osc.v.Y)
						c0 = CFrame.new(e.osc.c) * CFrame.fromAxisAngle(e.osc.a, ang) * CFrame.new(-e.osc.c) * c0
					end
					for _, r in ipairs(e.rots) do
						c0 = CFrame.new(r.c) * CFrame.fromAxisAngle(r.a, t * r.s) * CFrame.new(-r.c) * c0
					end
					if e.bob then c0 = CFrame.new(0, e.bob.X * math.sin(t * e.bob.Y + e.bob.Z), 0) * c0 end
					if byWeld and e.weld then e.weld.C0 = c0 else e.part.CFrame = hcf * c0 end
					if e.pulse then e.part.Transparency = e.pulse.X + (e.pulse.Y - e.pulse.X) * (0.5 + 0.5 * math.sin(t * e.pulse.Z)) end
				end
				-- the lights and the lightning (the effects come a moment after the parts: looked for again now and then)
				if t - st.scanAt > 1.5 then scanFx(st) end
				for _, l in ipairs(st.lights) do
					local b = l.base
					if l.pulse then b *= 0.75 + 0.25 * math.sin(t * l.pulse) end
					if l.flicker then b *= 0.8 + rng:NextNumber() * 0.35 end
					l.light.Brightness = b
					if l.hue then l.light.Color = Color3.fromHSV((t * 0.06) % 1, 0.3, 1) end
				end
				if #st.beams > 0 and t - st.crackleAt > CRACKLE then
					st.crackleAt = t
					for _, b in ipairs(st.beams) do
						local bm = b.beam
						bm.CurveSize0 = rng:NextNumber(-0.5, 0.5)
						bm.CurveSize1 = rng:NextNumber(-0.5, 0.5)
						local w = b.w * rng:NextNumber(0.5, 1.4)
						bm.Width0, bm.Width1 = w, w * rng:NextNumber(0.4, 1)
						bm.Transparency = NumberSequence.new(rng:NextNumber() < 0.15 and 1 or rng:NextNumber(0, 0.35))
					end
				end
			end
		end
	end
end)
