--[[ STORES — every data store the game opens comes from here, so Studio plays on data of its
     own. With "Enable Studio access to API services" on (Game Settings › Security), Studio's
     Play reaches the live game's data stores: real profiles, leaderboards, serial numbers, the
     season's payout. So Studio opens "Studio_" copies instead (Studio_Profiles_v2 and so on):
     saves, cheats and test runs persist between Plays without ever touching a live save.
     (Memory stores need nothing: Roblox already keeps Studio's apart from the live game's.)

       Stores.get(name)       -> DataStore         (yields; may error: call it in a pcall)
       Stores.ordered(name)   -> OrderedDataStore
       Stores.TEST            -> true in Studio (its own data)

     GameConfig.STUDIO_LIVE_DATA = true points Studio at the live stores, on purpose only. ]]

local RunService = game:GetService("RunService")
local DataStoreService = game:GetService("DataStoreService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local GameConfig = require(ReplicatedStorage:WaitForChild("GameConfig"))

local Stores = {}
Stores.TEST = RunService:IsStudio() and GameConfig.STUDIO_LIVE_DATA ~= true

local function named(name) return Stores.TEST and ("Studio_" .. name) or name end

function Stores.get(name) return DataStoreService:GetDataStore(named(name)) end
function Stores.ordered(name) return DataStoreService:GetOrderedDataStore(named(name)) end

return Stores
