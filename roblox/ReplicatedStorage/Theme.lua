--[[ THEME — the one place the UI's colors and fonts live. Bright and friendly
     on dark glass: outlined white text, green for the thing you should press
     (PLAY), bright blue for what is selected, gold for Crowns, red to close. Every menu script reads
     these (HubMenu, LoadoutMenu, Scoreboard, TravelScreen, HUD). Change a color
     here and every screen follows. ]]
local T = {}
T.FONT_TITLE = Enum.Font.FredokaOne     -- big friendly headings
T.FONT       = Enum.Font.GothamBold     -- buttons, labels
T.FONT_BODY  = Enum.Font.GothamMedium   -- body text

T.BACK     = Color3.fromRGB(6, 10, 20)      -- behind everything (over the 3D view)
T.PANEL    = Color3.fromRGB(14, 20, 36)     -- the big panels
T.SIDE     = Color3.fromRGB(11, 16, 30)     -- side bars
T.CARD     = Color3.fromRGB(30, 40, 66)     -- cards, rows
T.CARD2    = Color3.fromRGB(22, 30, 52)     -- quieter cards
T.CARD_ON  = Color3.fromRGB(46, 132, 255)   -- selected
T.TEXT     = Color3.fromRGB(255, 255, 255)
T.DIM      = Color3.fromRGB(170, 184, 214)
T.ACCENT   = Color3.fromRGB(255, 210, 63)   -- yellow: highlights, your row
T.GOLD     = Color3.fromRGB(255, 186, 36)   -- buy with Crowns / premium
T.GO       = Color3.fromRGB(64, 200, 92)    -- the big action: PLAY, SPAWN, EQUIP
T.GO_ON    = Color3.fromRGB(86, 222, 112)
T.GOOD     = Color3.fromRGB(74, 222, 128)
T.BAD      = Color3.fromRGB(255, 77, 109)
T.MARKS    = Color3.fromRGB(255, 210, 63)
T.CROWNS   = Color3.fromRGB(120, 200, 255)
T.INK      = Color3.fromRGB(24, 30, 52)     -- dark text on white
T.STROKE   = Color3.fromRGB(255, 255, 255)  -- card outlines (use with ~0.85 transparency)
T.TEAM_A   = Color3.fromRGB(70, 110, 220)
T.TEAM_B   = Color3.fromRGB(220, 60, 60)

-- the lobby look: chunky glossy buttons, outlined white text on dark glass
T.GLASS    = Color3.fromRGB(12, 16, 28)     -- dark see-through cards (~0.1 transparency)
T.GLASS2   = Color3.fromRGB(26, 33, 54)     -- rows / quieter cards inside them
T.OUTLINE  = Color3.fromRGB(8, 10, 20)      -- the outline around white text
T.GREEN    = Color3.fromRGB(64, 200, 92)    -- PLAY / go
T.BLUE     = Color3.fromRGB(46, 132, 255)   -- secondary actions, selected
T.RED      = Color3.fromRGB(236, 64, 72)    -- close, leave, cancel
T.YELLOW   = Color3.fromRGB(255, 196, 40)   -- searching, Crowns
T.PURPLE   = Color3.fromRGB(150, 90, 230)   -- ranked

-- dark text on near-white buttons, white (outlined) on everything else
function T.textOn(bg)
	local lum = 0.299 * bg.R + 0.587 * bg.G + 0.114 * bg.B
	return lum > 0.8 and T.INK or T.TEXT
end
return T
