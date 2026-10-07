--[[ JANITOR — keeps the field clear of what a fight leaves behind: severed
     limbs, heads, dropped weapons, corpses (Combat ▸ Corpses). Everything is kept in workspace ▸ Remains
     (weapons stay in DroppedWeapons, where Pickup looks), lives a while, and
     fades out instead of popping: when its time is up, when there are more of
     its kind than LIMIT (the oldest goes first), and all of it between rounds.

       Janitor.add(inst, kind, opts)   kind: "Corpse" | "Limb" | "Head" | "Weapon" | "Gore"
           opts.life      seconds (default LIFE[kind])
           opts.still     fn() -> bool: is it still lying here? (a weapon someone
                          picked up is not: the janitor leaves it alone)
           opts.parent    false = leave it where it is (default: Remains)
       Janitor.forget(inst)           stop looking after it
       Janitor.clear(kind)            fade out all of a kind (nil = everything)
       Janitor.folder()               workspace ▸ Remains ]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local Janitor = {}
Janitor.CONFIG = {
	LIFE  = {Corpse = 30, Limb = 15, Head = 18, Weapon = 25, Gore = 12},   -- seconds before it fades
	LIMIT = {Corpse = 8, Limb = 10, Head = 6, Weapon = 8, Gore = 20},       -- at most this many lying around
	FADE  = 0.8,                                              -- seconds to fade out
}
local C = Janitor.CONFIG

local tracked = {}   -- [inst] = {kind, born, still}
local order = {}     -- kind -> {inst, ...} oldest first

function Janitor.folder()
	local f = workspace:FindFirstChild("Remains")
	if not f then
		f = Instance.new("Folder")
		f.Name = "Remains"
		f.Parent = workspace
	end
	return f
end

local function unlist(inst)
	local t = tracked[inst]
	if not t then return end
	tracked[inst] = nil
	local list = order[t.kind]
	if list then
		local i = table.find(list, inst)
		if i then table.remove(list, i) end
	end
end

-- fade every visible part out, then destroy it (unless it was picked up meanwhile)
local function fadeOut(inst)
	local t = tracked[inst]
	unlist(inst)
	if not inst.Parent then return end
	if t and t.still and not t.still() then return end
	local parts = inst:IsA("BasePart") and {inst} or {}
	for _, d in ipairs(inst:GetDescendants()) do
		if d:IsA("BasePart") then table.insert(parts, d) end
		if d:IsA("ProximityPrompt") then d.Enabled = false end   -- no grabbing a fading weapon
		if d:IsA("ParticleEmitter") then d.Enabled = false end
	end
	for _, p in ipairs(parts) do
		if p.Transparency < 1 then
			TweenService:Create(p, TweenInfo.new(C.FADE, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {Transparency = 1}):Play()
		end
		for _, d in ipairs(p:GetChildren()) do
			if d:IsA("Decal") or d:IsA("Texture") then
				TweenService:Create(d, TweenInfo.new(C.FADE), {Transparency = 1}):Play()
			end
		end
	end
	task.delay(C.FADE + 0.05, function()
		if inst.Parent and not (t and t.still and not t.still()) then inst:Destroy() end
	end)
end

function Janitor.add(inst, kind, opts)
	if not (inst and inst.Parent) then return end
	opts = opts or {}
	kind = C.LIFE[kind] and kind or "Gore"
	unlist(inst)
	if opts.parent ~= false and kind ~= "Weapon" then inst.Parent = Janitor.folder() end
	local entry = {kind = kind, born = os.clock(), still = opts.still}
	tracked[inst] = entry
	order[kind] = order[kind] or {}
	table.insert(order[kind], inst)
	-- too many of its kind: the oldest go
	local list = order[kind]
	while #list > (C.LIMIT[kind] or 20) do fadeOut(list[1]) end
	task.delay(opts.life or C.LIFE[kind], function()
		if tracked[inst] == entry then fadeOut(inst) end
	end)
	inst.AncestryChanged:Connect(function(_, parent)
		if parent == nil and tracked[inst] == entry then unlist(inst) end
	end)
end

function Janitor.forget(inst) unlist(inst) end

function Janitor.clear(kind)
	local all = {}
	for inst, t in pairs(tracked) do
		if kind == nil or t.kind == kind then table.insert(all, inst) end
	end
	for _, inst in ipairs(all) do fadeOut(inst) end
end

-- between rounds the field is swept clean
task.spawn(function()
	local node = ReplicatedStorage:WaitForChild("Round", 30)
	if not node then return end
	local last = node:GetAttribute("State")
	node:GetAttributeChangedSignal("State"):Connect(function()
		local now = node:GetAttribute("State")
		if now ~= last and (now == "Intermission" or now == "Round") then Janitor.clear() end
		last = now
	end)
end)

return Janitor
