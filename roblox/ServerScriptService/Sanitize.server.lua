--[[ SANITIZE — the stamped castle models came with free-model "weld" scripts
     (a Script under every "… Strong Joint" ManualWeld / RobloxModel /
     RobloxStamper value that requires a dead asset). They do nothing but
     throw in the Output, and more appear whenever a stamped model is cloned
     or re-welded. This removes them from the world as soon as they exist:
     at start, and for anything added later (maps are cloned at runtime). ]]
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
	if isJunk(d) then task.defer(function() if d.Parent then d:Destroy() end end) end
end)
if n > 0 then print("[Sanitize] removed", n, "free-model weld scripts") end
