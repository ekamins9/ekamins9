-- WEIGHTS — the only place armor stats live. Every piece of a weight uses
-- these numbers; looks never change them.
--   health  added to MaxHealth      speed  WalkSpeed multiplier
--   clunk   footstep weight         prot   damage removed on covered limbs (0..1)
return {
	-- Heavy used to be +50 health and half damage on covered limbs: a knight could eat
	-- a dozen hits. Now the gap is real but a Light can still cut one down.
	Light  = {health = 0,  speed = 1.00, clunk = 1.00, prot = 0.05},
	Medium = {health = 20, speed = 0.94, clunk = 1.15, prot = 0.20},
	Heavy  = {health = 35, speed = 0.86, clunk = 1.40, prot = 0.35},
}
