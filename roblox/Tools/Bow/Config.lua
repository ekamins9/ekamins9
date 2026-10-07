--[[ LONGBOW — ranged weapon config (ModuleScript inside the Tool). Both
     RangedServer and RangedClient read it; anything not here comes from
     RangedServer.DEFAULTS / RangedClient.DEFAULTS.
     The Tool's body is built from Build ▸ Weapons.Bow if it has no Handle. ]]

return {
	Name        = "Longbow",
	Description = "Yew, linen string, a quiver at the hip. Draw it all the way for a flat, hard shot; hold it too long and your arm starts to shake.",
	KIND        = "bow",

	DRAW_TIME   = 1.2,    -- seconds to full draw (let go before 40% of it: the string's let down)
	NOCK_TIME   = 1.3,    -- after a shot: the next arrow out of the quiver and onto the string
	SPEED_MIN   = 70,     -- studs/s: a snap shot…
	SPEED_MAX   = 200,    -- …a full draw
	GRAVITY     = 32,
	DAMAGE      = 42,     -- a body hit at full draw (head ×2.4: a full-draw headshot kills a Light or a Medium)
	HEAD_MULT   = 2.4,
	ARMOR_PEN   = 0.1,
	QUIVER      = 24,
	REGEN       = 6,

	-- the shake of the aim (radians): a little always, more held at full draw past
	-- HOLD_AFTER (growing SWAY_GROW a second up to SWAY_MAX), more on the move or winded
	SWAY_BASE   = 0.004,
	SWAY_GROW   = 0.014,
	SWAY_MAX    = 0.05,
	HOLD_AFTER  = 1.4,

	-- the string, in the Handle's space: the two tips and where it rests
	STRING = {top = Vector3.new(0, 2.125, 0.61), bottom = Vector3.new(0, -2.125, 0.61), rest = Vector3.new(0, 0, 0.61)},
}
