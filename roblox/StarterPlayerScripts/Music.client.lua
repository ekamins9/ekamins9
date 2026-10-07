--[[ MUSIC — plays the score for where you are (ReplicatedStorage ▸ MusicConfig):
     the Courtyard, a match, the horde's waves and breaks, a boss fight, and a
     win / lose sting when a round ends. Changes of mood crossfade; a list plays
     shuffled, one track into the next. Volume: Settings ▸ Music volume. ]]

local Players = game:GetService("Players")
local SoundService = game:GetService("SoundService")
local TweenService = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage:WaitForChild("MusicConfig"))
local ClientSettings = require(ReplicatedStorage:WaitForChild("ClientSettings"))
local GameConfig = require(ReplicatedStorage:WaitForChild("GameConfig"))
local round = ReplicatedStorage:WaitForChild("Round")
local player = Players.LocalPlayer

local group = Instance.new("SoundGroup")
group.Name = "Music"
group.Parent = SoundService

local function userVolume()
	local v = ClientSettings.get("Music")
	return type(v) == "number" and v or 1
end
local function applyVolume() group.Volume = userVolume() end
applyVolume()
ClientSettings.onChanged(function(key) if key == "Music" then applyVolume() end end)

--------------------------------------------------------------------
--  WHAT SHOULD BE PLAYING
--------------------------------------------------------------------
local function bossAlive()
	local npcs = workspace:FindFirstChild("NPCs")
	if not npcs then return false end
	for _, m in ipairs(npcs:GetChildren()) do
		if m:GetAttribute("Boss") then
			local hum = m:FindFirstChildOfClass("Humanoid")
			if hum and hum.Health > 0 then return true end
		end
	end
	return false
end

local function moodNow()
	local mode, state = round:GetAttribute("Mode"), round:GetAttribute("State")
	if mode == nil or mode == "Hub" or mode == "Tiltyard" then return "Hub" end
	if state ~= "Round" then return "Intermission" end
	if bossAlive() then return "Boss" end
	if round:GetAttribute("ObjKind") == "Horde" then
		return round:GetAttribute("ObjState") == "break" and "HordeBreak" or "HordeWave"
	end
	return "Battle"
end

--------------------------------------------------------------------
--  PLAYBACK: one track at a time, crossfaded
--------------------------------------------------------------------
local current = nil        -- {sound, mood}
local mood = nil
local bag = {}             -- shuffled ids left to play, per mood

local function nextId(m)
	local list = Config.TRACKS[m]
	if not list or #list == 0 then return nil end
	local b = bag[m]
	if not b or #b == 0 then
		b = table.clone(list)
		for i = #b, 2, -1 do local j = math.random(i); b[i], b[j] = b[j], b[i] end
		bag[m] = b
	end
	return table.remove(b)
end

local function fadeOut(entry)
	if not entry or not entry.sound.Parent then return end
	local s = entry.sound
	TweenService:Create(s, TweenInfo.new(Config.FADE, Enum.EasingStyle.Sine), {Volume = 0}):Play()
	task.delay(Config.FADE + 0.1, function() s:Destroy() end)
end

local playToken = 0
local function play(m)
	playToken += 1
	local token = playToken
	fadeOut(current)
	current = nil
	local tries = #(Config.TRACKS[m] or {})
	task.spawn(function()
		for _ = 1, math.max(tries, 1) do
			local id = nextId(m)
			if not id then return end
			local s = Instance.new("Sound")
			s.SoundId = "rbxassetid://" .. tostring(id)
			s.Volume = 0
			s.SoundGroup = group
			s.Parent = SoundService
			-- a track that won't load is skipped
			local t0 = os.clock()
			while not s.IsLoaded and os.clock() - t0 < 6 do task.wait(0.2) end
			if token ~= playToken then s:Destroy(); return end
			if s.IsLoaded and s.TimeLength > 1 then
				s:Play()
				TweenService:Create(s, TweenInfo.new(Config.FADE, Enum.EasingStyle.Sine), {Volume = Config.VOLUME}):Play()
				current = {sound = s, mood = m}
				-- at the end: the next track of the same mood
				s.Ended:Once(function()
					if token == playToken and mood == m then play(m) end
				end)
				return
			end
			s:Destroy()
		end
	end)
end

--------------------------------------------------------------------
--  A ROUND ENDS: a sting (did you win?)
--------------------------------------------------------------------
local function myTeamName()
	local t = player.Team
	return t and t.Name or nil
end

local function sting(kind)
	local list = Config.STINGS[kind]
	if not list or #list == 0 then return end
	local s = Instance.new("Sound")
	s.SoundId = "rbxassetid://" .. tostring(list[math.random(#list)])
	s.Volume = Config.VOLUME * 1.6
	s.SoundGroup = group
	s.Parent = SoundService
	s:Play()
	-- duck the score under it
	if current and current.sound.Parent then
		local cs = current.sound
		TweenService:Create(cs, TweenInfo.new(0.4), {Volume = Config.VOLUME * 0.25}):Play()
		task.delay(6, function() if cs.Parent then TweenService:Create(cs, TweenInfo.new(2), {Volume = Config.VOLUME}):Play() end end)
	end
	task.delay(16, function() if s.Parent then s:Destroy() end end)
end

local lastState = round:GetAttribute("State")
round:GetAttributeChangedSignal("State"):Connect(function()
	local st = round:GetAttribute("State")
	local mode = round:GetAttribute("Mode")
	if lastState == "Round" and st == "Intermission" and mode ~= "Hub" and mode ~= "Tiltyard" then
		local winner = round:GetAttribute("Winner") or ""
		if winner ~= "" then
			local won = winner == player.DisplayName or winner == myTeamName()
			sting(won and "Win" or "Lose")
		end
	end
	lastState = st
end)

--------------------------------------------------------------------
--  FOLLOW THE MOOD (twice a second is plenty)
--------------------------------------------------------------------
task.spawn(function()
	while true do
		local m = moodNow()
		if m ~= mood then
			mood = m
			play(m)
		end
		task.wait(0.5)
	end
end)
