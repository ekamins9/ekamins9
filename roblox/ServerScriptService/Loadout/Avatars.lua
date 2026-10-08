--[[ AVATARS — you, under the armor: each player's own Roblox avatar, the parts of
     it that show round a helmet. When a player joins, their avatar is fetched
     (Players:GetHumanoidDescriptionFromUserId → an R6 model) and its kit kept in
     ReplicatedStorage ▸ Avatars ▸ <UserId>, where every client can read it:

       Accessory children   their hair and their face accessories (beards, glasses…),
                            attribute Kind = "hair" | "face"; hats and everything
                            worn on the body stay off (armor goes there)
       attribute Face       their face's texture ("" = the classic smile)
       attributes Head, Torso, LeftArm, RightArm, LeftLeg, RightLeg   their skin colours
       attribute Ready      the kit is complete

     The Dresser puts it on anyone whose appearance says avatar = <UserId> (a real
     spawn here, a menu mannequin on the client); bots and NPCs keep the made-up
     looks of Catalog ▸ Body. A helmet still hides what it covers.

       Avatars.ensure(plr, timeout)   the kit, waiting up to `timeout` s for it (nil if it failed)
       Avatars.appearanceOf(plr)      their saved appearance (the title) + avatar = UserId ]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Profile = require(script.Parent:WaitForChild("Profile"))

local Avatars = {}

local folder = ReplicatedStorage:FindFirstChild("Avatars")
if not folder then folder = Instance.new("Folder"); folder.Name = "Avatars"; folder.Parent = ReplicatedStorage end

local HAIR_AT = {HairAttachment = true}
local FACE_AT = {FaceFrontAttachment = true, FaceCenterAttachment = true}
-- which accessories come along: hair, and things worn on the face
local function kindOf(acc)
	local t = acc.AccessoryType
	if t == Enum.AccessoryType.Hair then return "hair" end
	if t == Enum.AccessoryType.Face then return "face" end
	if t == Enum.AccessoryType.Unknown or t == Enum.AccessoryType.Hat then
		-- (older items say nothing useful: their attachment does)
		local handle = acc:FindFirstChild("Handle")
		local a = handle and handle:FindFirstChildWhichIsA("Attachment")
		if a and HAIR_AT[a.Name] and t ~= Enum.AccessoryType.Hat then return "hair" end
		if a and FACE_AT[a.Name] then return "face" end
	end
	return nil
end

local building = {}
local function build(plr)
	if building[plr] then return end
	building[plr] = true
	local key = tostring(plr.UserId)
	local ok, desc = pcall(Players.GetHumanoidDescriptionFromUserId, Players, plr.UserId)
	if not ok or not desc then warn("[Avatars] no avatar for", plr.Name, desc); building[plr] = nil; return end
	local ok2, model = pcall(Players.CreateHumanoidModelFromDescription, Players, desc, Enum.HumanoidRigType.R6)
	if not ok2 or not model then warn("[Avatars] couldn't build", plr.Name, model); building[plr] = nil; return end
	if not plr.Parent then model:Destroy(); building[plr] = nil; return end
	local old = folder:FindFirstChild(key)
	if old then old:Destroy() end
	local kit = Instance.new("Folder")
	kit.Name = key
	for _, acc in ipairs(model:GetChildren()) do
		local kind = acc:IsA("Accessory") and kindOf(acc)
		if kind then
			local c = acc:Clone()
			for _, d in ipairs(c:GetDescendants()) do if d:IsA("JointInstance") or d:IsA("Script") or d:IsA("LocalScript") then d:Destroy() end end
			c:SetAttribute("Kind", kind)
			c.Parent = kit
		end
	end
	local head = model:FindFirstChild("Head")
	local face = head and (head:FindFirstChild("face") or head:FindFirstChildOfClass("Decal"))
	kit:SetAttribute("Face", face and face.Texture or "")
	local bc = model:FindFirstChildOfClass("BodyColors")
	if bc then
		kit:SetAttribute("Head", bc.HeadColor3); kit:SetAttribute("Torso", bc.TorsoColor3)
		kit:SetAttribute("LeftArm", bc.LeftArmColor3); kit:SetAttribute("RightArm", bc.RightArmColor3)
		kit:SetAttribute("LeftLeg", bc.LeftLegColor3); kit:SetAttribute("RightLeg", bc.RightLegColor3)
	end
	model:Destroy()
	kit:SetAttribute("Ready", true)
	kit.Parent = folder
	building[plr] = nil
	-- (already standing in the Courtyard in the stand-in look: dressed again, as themselves)
	if plr.Character and _G.CourtyardRedress then task.spawn(_G.CourtyardRedress, plr) end
end

function Avatars.ensure(plr, timeout)
	local key = tostring(plr.UserId)
	local kit = folder:FindFirstChild(key)
	if kit and kit:GetAttribute("Ready") then return kit end
	task.spawn(build, plr)
	local t0 = os.clock()
	while os.clock() - t0 < (timeout or 0) do
		kit = folder:FindFirstChild(key)
		if kit and kit:GetAttribute("Ready") then return kit end
		task.wait(0.1)
	end
	return nil
end

function Avatars.appearanceOf(plr)
	local a = {}
	for k, v in pairs(Profile.get(plr).appearance or {}) do a[k] = v end
	a.avatar = plr.UserId
	return a
end

Players.PlayerAdded:Connect(function(plr) task.spawn(build, plr) end)
for _, plr in ipairs(Players:GetPlayers()) do task.spawn(build, plr) end
Players.PlayerRemoving:Connect(function(plr)
	local kit = folder:FindFirstChild(tostring(plr.UserId))
	if kit then kit:Destroy() end
	building[plr] = nil
end)

return Avatars
