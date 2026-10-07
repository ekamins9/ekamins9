--[[ EXPORT BLUEPRINTS — the armor sets, earned pieces and body models of
     Build ▸ Armor / Build ▸ Body as JSON, for blender/parts2mesh.py.

     Run it in Studio edit mode through the Studio MCP (execute_luau with this
     file's text). It requires a fresh copy of the Build folder (so the source
     Rojo just synced is what gets exported), keeps the JSON in
     _G.BlueprintsJSON and returns its length. The MCP cuts results at 100k
     characters, so fetch it in slices,
         return "<<<" .. _G.BlueprintsJSON:sub(1, 80000) .. ">>>"
     and join them into blender/out/blueprints.json (scripts/join_blueprints.py).

     spec = {k = kind, n = name, s = size, cf = 12 CFrame components,
             c = color (0..1), m = material, t = transparency, a = attrs,
             tp = a cone's top ratio, bv = a box's bevel, pf = a lathe's profile} ]]

local HttpService = game:GetService("HttpService")
local ServerStorage = game:GetService("ServerStorage")

local function r4(x) return math.floor(x * 1000 + 0.5) / 1000 end

local function ser(s)
	local c = s.cf or CFrame.identity
	local comps = {c:GetComponents()}
	for i, x in ipairs(comps) do comps[i] = r4(x) end
	local col = s.color or Color3.new(0.8, 0.8, 0.8)
	return {
		k = s.kind or "box", n = s.name or "Part",
		s = {r4(s.size.X), r4(s.size.Y), r4(s.size.Z)},
		cf = comps,
		c = {r4(col.R), r4(col.G), r4(col.B)},
		m = (s.material or Enum.Material.SmoothPlastic).Name,
		t = s.transparency or 0,
		a = (s.attrs and next(s.attrs)) and s.attrs or nil,
		tp = s.top,
		bv = s.bevel,
		pf = s.profile,
	}
end
local function serList(list)
	local out = {}
	for i, s in ipairs(list) do out[i] = ser(s) end
	return out
end

local copy = game:GetService("ServerScriptService"):WaitForChild("Build"):Clone()
copy.Name = "_BlueprintExport"
copy.Parent = ServerStorage
local ok, result = pcall(function()
	local Armor = require(copy:WaitForChild("Armor"))
	local Body = require(copy:WaitForChild("Body"))
	local data = {sets = {}, pieces = {}, body = {}}
	for name, set in pairs(Armor) do
		if name ~= "PIECES" and type(set) == "table" then
			local slots = {}
			for slot, list in pairs(set) do slots[slot] = serList(list) end
			data.sets[name] = slots
		end
	end
	for id, piece in pairs(Armor.PIECES or {}) do
		local slots = {}
		for slot, list in pairs(piece) do slots[slot] = serList(list) end
		data.pieces[id] = slots
	end
	for kind, items in pairs(Body) do
		local group = {}
		for id, list in pairs(items) do group[id] = serList(list) end
		if next(group) then data.body[kind] = group end
	end
	return HttpService:JSONEncode(data)
end)
copy:Destroy()
if not ok then error(result) end
_G.BlueprintsJSON = result
return "BLUEPRINTS_JSON " .. #result
