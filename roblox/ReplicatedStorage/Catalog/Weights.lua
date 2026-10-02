-- WEIGHTS — the only place armor stats live. Every piece of a weight uses
-- these numbers; looks never change them.
--   health  added to MaxHealth      speed  WalkSpeed multiplier
--   clunk   footstep weight         prot   damage removed on covered limbs (0..1)
return {
	Light  = {health = 0,  speed = 1.00, clunk = 1.00, prot = 0.10},
	Medium = {health = 25, speed = 0.94, clunk = 1.15, prot = 0.30},
	Heavy  = {health = 50, speed = 0.86, clunk = 1.40, prot = 0.50},
}
