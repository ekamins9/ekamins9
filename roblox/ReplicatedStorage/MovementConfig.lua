-- ReplicatedStorage/MovementConfig  (ModuleScript)
-- Single source of truth for base WalkSpeed, shared by the server-side
-- WalkSpeed governor and the client-side camera/clunk rig so they can
-- never drift out of sync with each other.
return {
	BASE_SPEED = 10,  -- full-health, no-armor, no-modifiers WalkSpeed
}
