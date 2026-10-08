--[[ LONGBOW — ranged weapon config (ModuleScript inside the Tool). Both
     RangedServer and RangedClient read it; anything not here comes from
     RangedServer.DEFAULTS / RangedClient.DEFAULTS.
     The Tool's body is built from Build ▸ Weapons.Bow if it has no Handle. ]]

return {
	Name        = "Longbow",
	Description = "Yew, linen string, a quiver at the hip. Draw it all the way for a flat, hard shot; hold it too long and your arm starts to shake.",
	KIND        = "bow",

	DRAW_TIME   = 1.6,    -- seconds to full draw (let go before 40% of it: the string's let down)
	NOCK_TIME   = 1.5,    -- after a shot: the next arrow out of the quiver and onto the string
	SPEED_MIN   = 55,     -- studs/s: a snap shot…
	SPEED_MAX   = 147,    -- …a full draw (range goes with speed²: ×1.22 speed = ×1.5 range)
	GRAVITY     = 40,
	MAX_FLIGHT  = 6,      -- seconds an arrow may fly (a long lob takes ~5)
	DAMAGE      = 30,     -- a body hit at full draw (head ×2: 60, never a one-shot)
	HEAD_MULT   = 2.0,
	ARMOR_PEN   = 0.05,
	QUIVER      = 16,
	REGEN       = 6,

	-- the shake of the aim (radians): a little always, more held at full draw past
	-- HOLD_AFTER (growing SWAY_GROW a second up to SWAY_MAX), more on the move or winded
	SWAY_BASE   = 0.012,
	SWAY_GROW   = 0.025,
	SWAY_MAX    = 0.07,
	HOLD_AFTER  = 0.6,

	-- the string, in the Handle's space: the two tips and where it rests
	STRING = {top = Vector3.new(0, 2.125, 0.61), bottom = Vector3.new(0, -2.125, 0.61), rest = Vector3.new(0, 0, 0.61)},
}
