--[[ THEME — the one place the UI's colors and fonts live. Bright and friendly:
     deep blue panels, white text, yellow for the thing you should press, bright
     blue for what is selected, green good / red bad. Every menu script reads
     these (HubMenu, LoadoutMenu, Scoreboard, TravelScreen, HUD). Change a color
     here and every screen follows. ]]
local T = {}
T.FONT_TITLE = Enum.Font.FredokaOne     -- big friendly headings
T.FONT       = Enum.Font.GothamBold     -- buttons, labels
T.FONT_BODY  = Enum.Font.GothamMedium   -- body text

T.BACK     = Color3.fromRGB(7, 18, 40)      -- behind everything (over the 3D view)
T.PANEL    = Color3.fromRGB(13, 30, 64)     -- the big panel
T.SIDE     = Color3.fromRGB(10, 24, 52)     -- side bar
T.CARD     = Color3.fromRGB(23, 50, 100)    -- cards, rows
T.CARD2    = Color3.fromRGB(17, 40, 82)     -- quieter cards
T.CARD_ON  = Color3.fromRGB(47, 123, 255)   -- selected
T.TEXT     = Color3.fromRGB(255, 255, 255)
T.DIM      = Color3.fromRGB(168, 190, 230)
T.ACCENT   = Color3.fromRGB(255, 210, 63)   -- yellow: headings, your row, highlights
T.GOLD     = Color3.fromRGB(255, 196, 40)   -- buy with Crowns / premium
T.GO       = Color3.fromRGB(255, 210, 63)   -- the big action (dark text on it)
T.GO_ON    = Color3.fromRGB(255, 226, 96)
T.GOOD     = Color3.fromRGB(74, 222, 128)
T.BAD      = Color3.fromRGB(255, 77, 109)
T.MARKS    = Color3.fromRGB(255, 210, 63)
T.CROWNS   = Color3.fromRGB(120, 200, 255)
T.INK      = Color3.fromRGB(24, 30, 52)     -- dark text on yellow / white
T.STROKE   = Color3.fromRGB(255, 255, 255)  -- card outlines (use with ~0.85 transparency)
T.TEAM_A   = Color3.fromRGB(70, 110, 220)
T.TEAM_B   = Color3.fromRGB(220, 60, 60)

-- dark text on bright buttons, white on dark ones
function T.textOn(bg)
	local lum = 0.299 * bg.R + 0.587 * bg.G + 0.114 * bg.B
	return lum > 0.55 and T.INK or T.TEXT
end
return T
