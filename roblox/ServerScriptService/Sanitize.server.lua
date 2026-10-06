--[[ SANITIZE — a runtime safety net for injected "weld" scripts.

     Where they come from: a counterfeit "Studio Build Suite" plugin (Creator
     Store id 6542422966) adds one Script with `require(<asset>).weld()` to a
     random Workspace descendant every time Studio opens a place — under parts,
     joints ("… Strong Joint"), RobloxModel / RobloxStamper values. That
     require is a backdoor: harmless only while its asset stays deleted.
     Uninstall the plugin (Plugins ▸ Manage Plugins) and remove the scripts in
     edit mode (docs/HANDOFF.md has the snippet).

     Game scripts can't read Script.Source, so at runtime this can only catch
     the ones parked under joints and stamper values; it disables them the
     moment they appear and deletes them a frame later. ]]
local JUNK_PARENTS = {RobloxModel = true, RobloxStamper = true}

local function isJunk(d)
	if not d:IsA("Script") then return false end
	local p = d.Parent
	if not p then return false end
	if p:IsA("JointInstance") then return true end
	if JUNK_PARENTS[p.Name] then return true end
	return p.Name:find("Strong Joint", 1, true) ~= nil
end

local n = 0
local function sweep(root)
	for _, d in ipairs(root:GetDescendants()) do
		if isJunk(d) then d:Destroy(); n += 1 end
	end
end
sweep(workspace)
sweep(game:GetService("ServerStorage"))
workspace.DescendantAdded:Connect(function(d)
	if isJunk(d) then
		d.Enabled = false   -- synchronously, before it gets a chance to run
		task.defer(function() if d.Parent then d:Destroy() end end)
	end
end)
if n > 0 then print("[Sanitize] removed", n, "free-model weld scripts") end
