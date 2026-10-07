--[[ CROSSBOW — ranged weapon config (ModuleScript inside the Tool). Both
     RangedServer and RangedClient read it; anything not here comes from
     RangedServer.DEFAULTS / RangedClient.DEFAULTS.
     The Tool's body is built from Build ▸ Weapons.Crossbow if it has no Handle. ]]

return {
	Name        = "Crossbow",
	Description = "A steel prod and a windlass. Point, click, and the bolt goes exactly where you meant; then a long, slow reload.",
	KIND        = "crossbow",

	SPEED_MIN   = 230,
	SPEED_MAX   = 230,
	GRAVITY     = 22,
	DAMAGE      = 55,     -- head ×2.2: a headshot kills anyone
	HEAD_MULT   = 2.2,
	ARMOR_PEN   = 0.3,
	QUIVER      = 14,
	REGEN       = 8,
	RELOAD      = 4.5,    -- the windlass: you barely move meanwhile
	BLOCK_COST  = 30,

	SWAY_BASE   = 0.0015,
	SWAY_GROW   = 0,
	SWAY_MAX    = 0.0015,

	-- the string: the prod's tips, where it rests when loosed (front) and spanned (at the nut)
	STRING = {top = Vector3.new(1.25, 0.6, -1.94), bottom = Vector3.new(-1.25, 0.6, -1.94), rest = Vector3.new(0, 0.62, -2.05), spanned = Vector3.new(0, 0.66, -0.62)},
}
