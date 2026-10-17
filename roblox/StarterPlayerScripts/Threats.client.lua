--[[ THREATS (client) — a bot drawing a bow or casting a spell AT YOU (Combat ▸ Bots sets
     its Threat attribute to your user id while it does): on screen, a red mark over it with
     what's coming (the spell's symbol, or a bow); off screen, a red arrow round the middle
     of the screen pointing at it. A soft tick when a new one starts. So a fireball from
     behind is never a surprise: turn, dodge, or break the cast. ]]

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Theme = require(ReplicatedStorage:WaitForChild("Theme"))
local Spells = require(ReplicatedStorage:WaitForChild("MagicSpells"))
local UIFX = require(ReplicatedStorage:WaitForChild("UIFX"))

local player = Players.LocalPlayer
local RED = Color3.fromRGB(255, 70, 60)
local MAX = 4

local gui = Instance.new("ScreenGui")
gui.Name = "Threats"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = true
gui.DisplayOrder = 28
gui.Parent = player:WaitForChild("PlayerGui")

-- a mark (over the bot) and an arrow (at the edge) per threat
local slots = {}
for i = 1, MAX do
	local mark = Instance.new("Frame")
	mark.AnchorPoint = Vector2.new(0.5, 1)
	mark.Size = UDim2.fromOffset(34, 34)
	mark.BackgroundColor3 = RED
	mark.BackgroundTransparency = 0.1
	mark.Visible = false
	mark.Parent = gui
	Instance.new("UICorner", mark).CornerRadius = UDim.new(1, 0)
	local st = Instance.new("UIStroke", mark); st.Color = Color3.new(1, 1, 1); st.Thickness = 2
	local mt = Instance.new("TextLabel")
	mt.BackgroundTransparency = 1; mt.Size = UDim2.fromScale(1, 1); mt.Font = Theme.FONT_TITLE; mt.TextSize = 18
	mt.TextColor3 = Color3.new(1, 1, 1); mt.Text = "!"
	mt.Parent = mark
	local arrow = Instance.new("TextLabel")
	arrow.AnchorPoint = Vector2.new(0.5, 0.5)
	arrow.Size = UDim2.fromOffset(46, 46)
	arrow.BackgroundTransparency = 1
	arrow.Font = Theme.FONT_TITLE
	arrow.TextSize = 40
	arrow.TextColor3 = RED
	arrow.TextStrokeTransparency = 0.2
	arrow.Text = "▲"
	arrow.Visible = false
	arrow.Parent = gui
	local at = Instance.new("TextLabel")
	at.AnchorPoint = Vector2.new(0.5, 0.5)
	at.Size = UDim2.fromOffset(40, 24)
	at.BackgroundTransparency = 1
	at.Font = Theme.FONT_TITLE
	at.TextSize = 18
	at.TextColor3 = Color3.new(1, 1, 1)
	at.TextStrokeTransparency = 0.3
	at.Visible = false
	at.Parent = gui
	slots[i] = {mark = mark, text = mt, arrow = arrow, glyph = at}
end

local seen = {}   -- bots that were already a threat last frame (for the tick)
local function what(m)
	local id = m:GetAttribute("Casting")
	local sp = id and Spells[id]
	if sp then return sp.glyph or "✨" end
	return "🏹"
end

RunService.RenderStepped:Connect(function()
	local cam = workspace.CurrentCamera
	local npcs = workspace:FindFirstChild("NPCs")
	local list = {}
	if cam and npcs then
		local me = player.UserId
		for _, m in ipairs(npcs:GetChildren()) do
			if m:GetAttribute("Threat") == me then
				local hum = m:FindFirstChildOfClass("Humanoid")
				local head = m:FindFirstChild("Head")
				if hum and head and hum.Health > 0 then table.insert(list, {m = m, head = head}) end
			end
		end
	end
	local now = {}
	local pulse = 0.5 + 0.5 * math.sin(os.clock() * 12)
	local vp = cam and cam.ViewportSize or Vector2.new(1, 1)
	for i, s in ipairs(slots) do
		local t = list[i]
		if not t then
			s.mark.Visible, s.arrow.Visible, s.glyph.Visible = false, false, false
		else
			now[t.m] = true
			if not seen[t.m] then pcall(UIFX.play, "Tick", {Volume = 0.8, Speed = 0.7}) end
			local pos = t.head.Position + Vector3.new(0, 2.2, 0)
			local sp, on = cam:WorldToViewportPoint(pos)
			local inside = on and sp.X > 30 and sp.X < vp.X - 30 and sp.Y > 30 and sp.Y < vp.Y - 30
			if inside then
				s.arrow.Visible, s.glyph.Visible = false, false
				s.mark.Visible = true
				s.mark.Position = UDim2.fromOffset(sp.X, sp.Y)
				s.text.Text = what(t.m)
				s.mark.BackgroundTransparency = 0.05 + 0.3 * pulse
			else
				-- round the middle of the screen, at its bearing from where you look
				s.mark.Visible = false
				local v = cam.CFrame:VectorToObjectSpace(pos - cam.CFrame.Position)
				local a = math.atan2(v.X, -v.Z)
				local cx, cy = vp.X / 2, vp.Y / 2
				local rx, ry = math.min(vp.X * 0.32, 340), math.min(vp.Y * 0.32, 240)
				s.arrow.Visible, s.glyph.Visible = true, true
				s.arrow.Position = UDim2.fromOffset(cx + math.sin(a) * rx, cy - math.cos(a) * ry)
				s.arrow.Rotation = math.deg(a)
				s.arrow.TextTransparency = 0.1 + 0.35 * pulse
				s.glyph.Text = what(t.m)
				s.glyph.Position = UDim2.fromOffset(cx + math.sin(a) * (rx - 38), cy - math.cos(a) * (ry - 30))
			end
		end
	end
	seen = now
end)
