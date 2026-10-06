-- WEIGHTS — the only place armor stats live. Every piece of a weight uses
-- these numbers; looks never change them. Each weight trades something real:
--   Light   the quickest on its feet, the deepest lungs, long cheap dodges — and one mistake from death
--   Medium  the all-rounder
--   Heavy   the most health and armor (about 1.4× Light's staying power, not 2×) — slow, short of
--           breath, clumsy dodges: a Light that keeps moving and keeps the pressure on runs it dry
--
--   health     added to MaxHealth (base 100)      prot      damage removed on covered limbs (0..1)
--   speed      WalkSpeed multiplier               sprint    sprint multiplier (MovementConfig.SPRINT_MULT is Medium's)
--   stamina    max stamina multiplier (100 base)  regen     stamina regen multiplier
--   dodgeCost  dodge stamina multiplier           dodgeReach  dodge distance multiplier
--   clunk      footstep weight
return {
	Light  = {health = 0,  prot = 0.03, speed = 1.06, sprint = 1.55, stamina = 1.15, regen = 1.25, dodgeCost = 0.7, dodgeReach = 1.25, clunk = 0.90},
	Medium = {health = 6,  prot = 0.12, speed = 0.96, sprint = 1.45, stamina = 1.00, regen = 1.00, dodgeCost = 1.0, dodgeReach = 1.00, clunk = 1.15},
	Heavy  = {health = 12, prot = 0.22, speed = 0.87, sprint = 1.32, stamina = 0.85, regen = 0.80, dodgeCost = 1.4, dodgeReach = 0.80, clunk = 1.40},
}
