--[[ TAVERN AMBIENCE — the Gilded Rat sounds lived in (Game ▸ Modes ▸ Tavern, Game ▸ TavernMap),
     on your screen only:

       the room      the low murmur of the place: talk you can't make out, a laugh, mugs, a chair
                     (WarAudio ▸ TavernRoom, a loop over the whole hall)
       the hearth    the fire crackling, from the hearth itself (WarAudio ▸ Fire, a loop at its
                     mouth: louder as you come up to it)

     The tune by the hearth is Music's (WarAudio ▸ Tavern). A sound the place doesn't have is just
     quiet. Nothing here is sent to the server. ]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local WarFX = require(ReplicatedStorage:WaitForChild("WarFX"))
local round = ReplicatedStorage:WaitForChild("Round")

local on = nil   -- {room, hearth}

local SoundService = game:GetService("SoundService")
local function stop()
	if not on then return end
	if SoundService.AmbientReverb == Enum.ReverbType.Room then SoundService.AmbientReverb = Enum.ReverbType.NoReverb end
	if on.room then WarFX.stopLoop(on.room, 1.5) end
	if on.hearth then on.hearth.stop(1.5) end
	on = nil
end

local function start(map)
	if on then return end
	on = {}
	-- (a timbered hall: a warm room's echo)
	SoundService.AmbientReverb = Enum.ReverbType.Room
	on.room = WarFX.loop("TavernRoom", 0.55)
	local mouth = map:FindFirstChild("HearthMouth", true)
	if mouth and mouth:IsA("BasePart") then
		on.hearth = WarFX.loop3D("Fire", mouth.Position, {near = 8, range = 70, volume = 0.8})
	end
end

local want = 0
local function refresh()
	want += 1
	local w = want
	task.delay(0.8, function()
		if want ~= w then return end
		local map = workspace:FindFirstChild("Map")
		if round:GetAttribute("Mode") == "Tavern" and map then start(map) else stop() end
	end)
end
workspace.ChildAdded:Connect(function(c) if c.Name == "Map" then stop(); refresh() end end)
workspace.ChildRemoved:Connect(function(c) if c.Name == "Map" then refresh() end end)
round:GetAttributeChangedSignal("Mode"):Connect(refresh)
refresh()
