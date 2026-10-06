# Updated scripts: weapons held edge-first

- **Every weapon turns 90° in the hand** so its edge, axe head, hammer face or spike faces the
  front, not its flat side. Measured on a War Axe in the guard: the head pointed to your right with
  the flat facing the camera; now the head points straight ahead (players and bots alike).
- It's one setting, `GRIP_ROLL = -90` in CombatServer's defaults, applied to each weapon's
  `Tool.Grip` once (a picked-up weapon keeps it). The menu's weapon previews and the Hall of
  Champions' statues use the same roll.

| File | Studio location | Type | Change |
|---|---|---|---|
| [CombatServer.lua](ServerScriptService/Combat/CombatServer.lua) | ServerScriptService ▸ Combat ▸ CombatServer | ModuleScript | `GRIP_ROLL`, applied once per weapon |
| [Dresser.lua](ReplicatedStorage/Dresser.lua) | ReplicatedStorage ▸ Dresser | ModuleScript | previews hold weapons the same way |
