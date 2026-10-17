--[[ HEARING — routes the world's sounds through SoundService ▸ World from the start, so a blast
     close by can leave you half deaf (ReplicatedStorage ▸ Hearing; WarFX.blast rings it). ]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
require(ReplicatedStorage:WaitForChild("Hearing")).init()
