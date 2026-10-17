--[[ HONOR DUELS — a challenge and a bout in the Courtyard. Play the CHALLENGE emote facing someone
     (within 18 studs, in front of you) and they're asked: ACCEPT or DECLINE (15 s). Accepted, the
     two square off where they stand, in a ring of light everyone can see: a salute, 3-2-1, FIGHT,
     and the first to THREE clean touches wins. Their blades meet each other's and nobody else's
     (DuelWith / DuelLive on both bodies: Combat ▸ CombatServer.duelPair); a clean hit is a touch
     scored, never a wound, so nobody falls in the Courtyard, and every block, parry, riposte, kick
     and clash plays as in battle. Leave the ring, fall, or let 90 seconds pass and it's over (the
     time's leader wins, or it's a draw). The loser kneels, the winner cheers, and the Courtyard
     hears of it. Looks and honour only: no Marks, nothing to farm.

       ReplicatedStorage ▸ DuelEvent
         server → client  "Ask" {from, fromId} · "Start" {a, b, aName, bName, centre} · "Count" n ·
                          "Live" · "Score" {a, b, sa, sb, by} · "End" {a, b, aName, bName, sa, sb, winner, why}
         client → server  "Answer", yes
       Toasts go through HubEvent "Toast" (HubMenu shows them). ]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local CombatServer = require(ServerScriptService:WaitForChild("Combat"):WaitForChild("CombatServer"))

local REACH, ASK_FOR, TOUCHES, RING, LIMIT = 18, 15, 3, 22, 90

local event = ReplicatedStorage:FindFirstChild("DuelEvent")
if not event then event = Instance.new("RemoteEvent"); event.Name = "DuelEvent"; event.Parent = ReplicatedStorage end
local round = ReplicatedStorage:WaitForChild("Round")

local function toast(plr, text)
	local hub = ReplicatedStorage:FindFirstChild("HubEvent")
	if hub and plr and plr.Parent then hub:FireClient(plr, "Toast", text) end
end
local function inCourtyard() return round:GetAttribute("Mode") == "Hub" end
local function rootOf(plr)
	local c = plr and plr.Character
	local h = c and c:FindFirstChildOfClass("Humanoid")
	return (h and h.Health > 0) and c:FindFirstChild("HumanoidRootPart") or nil
end

local duels = {}        -- {a, b, centre, sa, sb, live, t0, ca, cb}
local duelOf = {}       -- [Player] = duel
local asks = {}         -- [asked Player] = {from = Player, at}

-- who's in front of you to challenge: the nearest player you face, near enough, not in a bout
local function facing(plr)
	local r = rootOf(plr)
	if not r then return nil end
	local best, bestD = nil, REACH
	for _, other in ipairs(Players:GetPlayers()) do
		local o = other ~= plr and not duelOf[other] and rootOf(other)
		if o then
			local to = Vector3.new(o.Position.X - r.Position.X, 0, o.Position.Z - r.Position.Z)
			local d = to.Magnitude
			if d < bestD and d > 0.1 and r.CFrame.LookVector:Dot(to.Unit) > 0.6 then best, bestD = other, d end
		end
	end
	return best
end

local function setBody(plr, with, live)
	local c = plr and plr.Character
	if not c then return end
	c:SetAttribute("DuelWith", with)
	c:SetAttribute("DuelLive", live)
end

local function finish(d, winner, why)
	if d.over then return end
	d.over = true
	for i, x in ipairs(duels) do if x == d then table.remove(duels, i) break end end
	duelOf[d.a], duelOf[d.b] = nil, nil
	setBody(d.a, nil, nil)
	setBody(d.b, nil, nil)
	local loser = winner and (winner == d.a and d.b or d.a) or nil
	event:FireAllClients("End", {a = d.a.UserId, b = d.b.UserId, aName = d.a.DisplayName, bName = d.b.DisplayName,
		sa = d.sa, sb = d.sb, winner = winner and winner.UserId or 0, why = why or ""})
	if winner and _G.PlayerEmote then
		task.delay(0.3, function()
			pcall(_G.PlayerEmote, winner, "Cheer")
			if loser and loser.Parent then pcall(_G.PlayerEmote, loser, "Kneel") end
		end)
	end
	-- the Courtyard hears of it
	if winner and loser then
		local line = string.format("%s defeated %s in an honor duel, %d to %d", winner.DisplayName, loser.DisplayName, math.max(d.sa, d.sb), math.min(d.sa, d.sb))
		for _, p in ipairs(Players:GetPlayers()) do if p ~= winner and p ~= loser then toast(p, line) end end
	end
end

local function start(pa, pb)
	if not inCourtyard() or duelOf[pa] or duelOf[pb] then return end
	local ra, rb = rootOf(pa), rootOf(pb)
	if not (ra and rb) then return end
	local mid = (ra.Position + rb.Position) / 2
	local axis = Vector3.new(rb.Position.X - ra.Position.X, 0, rb.Position.Z - ra.Position.Z)
	axis = axis.Magnitude > 0.1 and axis.Unit or Vector3.new(1, 0, 0)
	-- square off: five studs each side of the middle, face to face
	local pA, pB = mid - axis * 5, mid + axis * 5
	pa.Character:PivotTo(CFrame.lookAt(Vector3.new(pA.X, ra.Position.Y, pA.Z), Vector3.new(pB.X, ra.Position.Y, pB.Z)))
	pb.Character:PivotTo(CFrame.lookAt(Vector3.new(pB.X, rb.Position.Y, pB.Z), Vector3.new(pA.X, rb.Position.Y, pA.Z)))
	-- (the camera turns with the body: CameraRig's FaceYaw)
	for _, x in ipairs({{pa, axis}, {pb, -axis}}) do
		local c = x[1].Character
		c:SetAttribute("FaceYaw", math.atan2(-x[2].X, -x[2].Z))
		c:SetAttribute("FaceTick", (c:GetAttribute("FaceTick") or 0) + 1)
	end
	local ground = Vector3.new(mid.X, math.min(ra.Position.Y, rb.Position.Y) - 3, mid.Z)
	local d = {a = pa, b = pb, centre = ground, sa = 0, sb = 0, live = false, t0 = os.clock(), ca = pa.Character, cb = pb.Character}
	table.insert(duels, d)
	duelOf[pa], duelOf[pb] = d, d
	setBody(pa, pb.UserId, false)
	setBody(pb, pa.UserId, false)
	event:FireAllClients("Start", {a = pa.UserId, b = pb.UserId, aName = pa.DisplayName, bName = pb.DisplayName, centre = ground})
	if _G.PlayerEmote then pcall(_G.PlayerEmote, pa, "Salute"); pcall(_G.PlayerEmote, pb, "Salute") end
	task.spawn(function()
		task.wait(1.6)
		for n = 3, 1, -1 do
			if d.over then return end
			event:FireClient(pa, "Count", n); event:FireClient(pb, "Count", n)
			task.wait(0.8)
		end
		if d.over then return end
		d.live, d.t0 = true, os.clock()
		setBody(pa, pb.UserId, true)
		setBody(pb, pa.UserId, true)
		event:FireClient(pa, "Live"); event:FireClient(pb, "Live")
	end)
end

-- a touch: CombatServer calls this for a duel pair's clean hit
CombatServer.onDuelTouch = function(attackerChar, targetChar)
	local pa = Players:GetPlayerFromCharacter(attackerChar)
	local d = pa and duelOf[pa]
	if not (d and d.live and not d.over) then return end
	if pa == d.a then d.sa += 1 else d.sb += 1 end
	event:FireAllClients("Score", {a = d.a.UserId, b = d.b.UserId, sa = d.sa, sb = d.sb, by = pa.UserId})
	if d.sa >= TOUCHES or d.sb >= TOUCHES then
		task.delay(0.6, function() finish(d, d.sa > d.sb and d.a or d.b, "touches") end)
	end
end

-- the Challenge emote
_G.EmotePlayed = function(plr, id)
	if id ~= "Challenge" or not inCourtyard() or duelOf[plr] then return end
	local target = facing(plr)
	if not target then toast(plr, "Face someone to challenge them to an honor duel"); return end
	local a = asks[target]
	if a and os.clock() - a.at < ASK_FOR and a.from ~= plr then toast(plr, target.DisplayName .. " is answering another challenge"); return end
	asks[target] = {from = plr, at = os.clock()}
	event:FireClient(target, "Ask", {from = plr.DisplayName, fromId = plr.UserId})
	toast(plr, "You challenge " .. target.DisplayName .. " to an honor duel")
end

event.OnServerEvent:Connect(function(plr, what, yes)
	if what ~= "Answer" then return end
	local a = asks[plr]
	asks[plr] = nil
	if not a or os.clock() - a.at > ASK_FOR + 1 or not a.from.Parent then return end
	if yes ~= true then toast(a.from, plr.DisplayName .. " declines your challenge"); return end
	start(a.from, plr)
end)

-- the bout's watch: out of the ring, fallen, gone, or out of time
task.spawn(function()
	while true do
		task.wait(0.25)
		for i = #duels, 1, -1 do
			local d = duels[i]
			if d and not d.over then
				local ra, rb = rootOf(d.a), rootOf(d.b)
				local function out(r) return not r or (Vector3.new(r.Position.X, 0, r.Position.Z) - Vector3.new(d.centre.X, 0, d.centre.Z)).Magnitude > RING end
				if not inCourtyard() then finish(d, nil, "the Courtyard closed")
				elseif not d.a.Parent or d.a.Character ~= d.ca or not ra then finish(d, d.b, d.a.DisplayName .. " left the bout")
				elseif not d.b.Parent or d.b.Character ~= d.cb or not rb then finish(d, d.a, d.b.DisplayName .. " left the bout")
				elseif d.live and out(ra) then finish(d, d.b, d.a.DisplayName .. " left the ring")
				elseif d.live and out(rb) then finish(d, d.a, d.b.DisplayName .. " left the ring")
				elseif d.live and os.clock() - d.t0 > LIMIT then
					finish(d, d.sa > d.sb and d.a or (d.sb > d.sa and d.b or nil), "time")
				end
			end
		end
	end
end)

Players.PlayerRemoving:Connect(function(plr) asks[plr] = nil end)
