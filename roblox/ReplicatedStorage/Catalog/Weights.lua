-- WEIGHTS — the only place armor stats live. Every piece of a weight uses
-- these numbers; looks never change them. Each weight trades something real:
--   Light   the quickest on its feet, the deepest lungs, long cheap dodges — and one mistake from death
--   Medium  the all-rounder
--   Heavy   the most health and armor (about 1.4× Light's staying power, not 2×) — slow, short of
--           breath, clumsy dodges: a Light that keeps moving and keeps the pressure on runs it dry
--   Robe    a Mage's: cloth, nothing to stop a blade, light on the feet (only magic classes wear it,
--           and they wear nothing else: GameConfig.CLASSES weight)
--
--   health     added to MaxHealth (base 100)      prot      damage removed on covered limbs (0..1)
--   speed      WalkSpeed multiplier               sprint    sprint multiplier (MovementConfig.SPRINT_MULT is Medium's)
--   stamina    max stamina multiplier (100 base)  regen     stamina regen multiplier
--   dodgeCost  dodge stamina multiplier           dodgeReach  dodge distance multiplier
--   cost       stamina cost multiplier on everything else: swings, feints, kicks, misses,
--              blocked blows, a held guard (plate is heavy to swing in)
--   clunk      footstep weight
return {
	Light  = {health = 0,  prot = 0.03, speed = 1.06, sprint = 1.55, stamina = 1.20, regen = 1.30, cost = 0.9, dodgeCost = 0.7, dodgeReach = 1.25, clunk = 0.90},
	Medium = {health = 6,  prot = 0.12, speed = 0.96, sprint = 1.45, stamina = 1.00, regen = 1.00, cost = 1.0, dodgeCost = 1.0, dodgeReach = 1.00, clunk = 1.15},
	Robe   = {health = 0,  prot = 0,    speed = 1.04, sprint = 1.5,  stamina = 1.10, regen = 1.20, cost = 0.9, dodgeCost = 0.75, dodgeReach = 1.20, clunk = 0.60},
	Heavy  = {health = 12, prot = 0.22, speed = 0.87, sprint = 1.32, stamina = 0.75, regen = 0.65, cost = 1.2, dodgeCost = 1.6, dodgeReach = 0.80, clunk = 1.40},
}
