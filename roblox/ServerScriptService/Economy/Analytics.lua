--[[ ANALYTICS — what Roblox's Creator Dashboard (Analytics) shows about how people play:
     where newcomers drop off, where Marks / Crowns / Keys come from and go, and a few
     moments worth counting. Everything goes through AnalyticsService, wrapped so a
     failure never touches the game; nothing here changes play.

       Analytics.onboard(plr, step)          the newcomer's path (ONBOARDING below), each
                                             step once per player, ever (profile funnel)
       Analytics.source(plr, currency, amount, balance, kind, sku)   money in
       Analytics.sink(plr, currency, amount, balance, kind, sku)     money out
             currency "Marks" | "Crowns" | "Keys"; kind an Enum.AnalyticsEconomyTransactionType
             name ("Gameplay", "IAP", "Shop", "TimedReward", "Onboarding", "ContextualPurchase")
       Analytics.event(plr, name, value, a, b, c)   a custom event (a, b, c: up to three
                                             labels to split it by)
     Dashboard ▸ Analytics ▸ Onboarding Funnel / Economy / Custom Events. ]]

local AnalyticsService = game:GetService("AnalyticsService")
local ServerScriptService = game:GetService("ServerScriptService")

local Analytics = {}

-- the newcomer's path, in order (a step skipped, like training for someone who fought
-- first, just isn't counted: the funnel shows the rest)
Analytics.ONBOARDING = {
	"Joined",                 -- 1  a brand new player
	"Basic training begun",   -- 2
	"Ready for battle",       -- 3  trained, or chose to skip it
	"First battle fought",    -- 4  its round over: on to the Courtyard
	"First crate opened",     -- 5
	"Level 2",                -- 6
	"Level 5",                -- 7  the Archer and the Mage open
	"Level 10",               -- 8
}
local STEP = {}
for i, n in ipairs(Analytics.ONBOARDING) do STEP[n] = i end

local function profile(plr)
	local ok, Profile = pcall(require, ServerScriptService:WaitForChild("Loadout"):WaitForChild("Profile"))
	return ok and Profile or nil
end

function Analytics.onboard(plr, step)
	if type(step) == "string" then step = STEP[step] end
	if not (plr and plr.Parent and step and Analytics.ONBOARDING[step]) then return end
	local Profile = profile(plr)
	local p = Profile and Profile.get(plr)
	if not p then return end
	p.funnel = p.funnel or {}
	if p.funnel[tostring(step)] then return end
	p.funnel[tostring(step)] = true
	Profile.markDirty(plr)
	pcall(AnalyticsService.LogOnboardingFunnelStepEvent, AnalyticsService, plr, step, Analytics.ONBOARDING[step])
end

local function kindOf(kind)
	local ok, v = pcall(function() return Enum.AnalyticsEconomyTransactionType[kind or "Gameplay"] end)
	return (ok and v) and v.Name or (kind or "Gameplay")
end
local function econ(plr, flow, currency, amount, balance, kind, sku)
	if not (plr and plr.Parent) or type(amount) ~= "number" or amount <= 0 then return end
	pcall(AnalyticsService.LogEconomyEvent, AnalyticsService, plr, flow, currency, math.floor(amount), math.max(0, math.floor(balance or 0)), kindOf(kind), sku)
end
function Analytics.source(plr, currency, amount, balance, kind, sku)
	econ(plr, Enum.AnalyticsEconomyFlowType.Source, currency, amount, balance, kind, sku)
end
function Analytics.sink(plr, currency, amount, balance, kind, sku)
	econ(plr, Enum.AnalyticsEconomyFlowType.Sink, currency, amount, balance, kind, sku)
end

function Analytics.event(plr, name, value, a, b, c)
	if not (plr and plr.Parent) then return end
	local fields = {}
	if a ~= nil then fields[Enum.AnalyticsCustomFieldKeys.CustomField01.Name] = tostring(a) end
	if b ~= nil then fields[Enum.AnalyticsCustomFieldKeys.CustomField02.Name] = tostring(b) end
	if c ~= nil then fields[Enum.AnalyticsCustomFieldKeys.CustomField03.Name] = tostring(c) end
	pcall(AnalyticsService.LogCustomEvent, AnalyticsService, plr, name, value or 1, fields)
end

return Analytics
