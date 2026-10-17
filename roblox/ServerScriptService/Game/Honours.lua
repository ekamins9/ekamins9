--[[ HONOURS — the battle's notice of a fighter on a run: kills close together and kills without
     falling, called out on the killer's screen (StarterPlayerScripts ▸ Honours), and the big ones
     to everyone; so is the fall of someone on a long run, and who brought them down.

       a MULTI-KILL   kills each within WINDOW s of the last: DOUBLE KILL, TRIPLE KILL, RAMPAGE
       a RUN          kills without falling: BATTLE-HARDENED (3), CHAMPION OF THE FIELD (5),
                      WARLORD (8), BANE OF ARMIES (12), UNSTOPPABLE (16, and every 5 after);
                      from CHAMPION on, everyone hears of it
       a RUN ENDED    of 5 or more: everyone hears who ended it; the one who did gets STREAK BREAKER

     Game ▸ Game calls Honours.kill(killer, victimPlr) on every kill a player makes (bots too) and
     Honours.fell(plr, killer) on every player's death. Never in the Courtyard, a yard or a peaceful
     place; never a teammate. A new round starts everyone's count again. Looks only.

     HonoursEvent (ReplicatedStorage, made here): "Mine" {title, sub, big} to the one who earned it,
     "All" {text, sub, who = userId} to everyone. ]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Honours = {}
local WINDOW = 4.5
local QUIET = {Hub = true, Tiltyard = true, Training = true, Tavern = true}

local node = ReplicatedStorage:WaitForChild("Round")
local event = ReplicatedStorage:FindFirstChild("HonoursEvent")
if not event then
	event = Instance.new("RemoteEvent")
	event.Name = "HonoursEvent"
	event.Parent = ReplicatedStorage
end

local MULTI = {[2] = "DOUBLE KILL", [3] = "TRIPLE KILL"}
-- {count, its name, what everyone hears (none: only the one who earned it)}
local RUNS = {{3, "BATTLE-HARDENED"}, {5, "CHAMPION OF THE FIELD", "IS CHAMPION OF THE FIELD"}, {8, "WARLORD", "IS A WARLORD"},
	{12, "BANE OF ARMIES", "IS THE BANE OF ARMIES"}, {16, "UNSTOPPABLE", "IS UNSTOPPABLE"}}

local state = {}      -- [Player] = {run, multi, lastAt}
local round = nil

local function fresh()
	local n = node:GetAttribute("Number")
	if n ~= round then round = n; state = {} end
end
local function of(plr)
	local s = state[plr]
	if not s then s = {run = 0, multi = 0, lastAt = -math.huge}; state[plr] = s end
	return s
end
local function live()
	return node:GetAttribute("State") == "Round" and not QUIET[node:GetAttribute("Mode") or ""] and node:GetAttribute("Peaceful") ~= true
end
-- the run's name at this count (each milestone once; past the last, every 5)
local function runName(n)
	for _, r in ipairs(RUNS) do if r[1] == n then return r[2], r[3] end end
	local last = RUNS[#RUNS]
	if n > last[1] and (n - last[1]) % 5 == 0 then return last[2], last[3] end
	return nil
end

function Honours.kill(killer, victimPlr)
	if not (killer and killer.Parent) or not live() then return end
	fresh()
	-- (a teammate's death is no honour)
	if victimPlr and killer.Team and victimPlr.Team == killer.Team and not killer.Neutral then return end
	local s = of(killer)
	local now = os.clock()
	s.multi = (now - s.lastAt <= WINDOW) and s.multi + 1 or 1
	s.lastAt = now
	s.run += 1
	local multi = s.multi >= 4 and "RAMPAGE" or MULTI[s.multi]
	local run, loud = runName(s.run)
	if multi or run then
		local title = multi or run
		local sub = (multi and run) and (run .. "  ·  " .. s.run .. " IN A ROW") or (s.run >= 3 and (s.run .. " IN A ROW") or "")
		event:FireClient(killer, "Mine", {title = title, sub = sub, big = (s.multi >= 3) or loud ~= nil})
	end
	if loud then
		event:FireAllClients("All", {text = string.upper(killer.DisplayName) .. " " .. loud, sub = s.run .. " IN A ROW", who = killer.UserId})
	end
end

function Honours.fell(plr, killer)
	if not plr then return end
	fresh()
	local s = state[plr]
	local run = s and s.run or 0
	state[plr] = nil
	if run >= 5 and live() then
		local by = (killer and killer ~= plr) and killer or nil
		event:FireAllClients("All", {text = by and (string.upper(by.DisplayName) .. " ENDS " .. string.upper(plr.DisplayName) .. "'S RUN") or (string.upper(plr.DisplayName) .. "'S RUN IS OVER"),
			sub = "AT " .. run .. " IN A ROW", who = 0})
		if by then event:FireClient(by, "Mine", {title = "STREAK BREAKER", sub = string.upper(plr.DisplayName) .. " FELL AT " .. run, big = true}) end
	end
end

Players.PlayerRemoving:Connect(function(plr) state[plr] = nil end)

return Honours
