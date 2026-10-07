# Updated scripts: spectate while you're dead

- **Spectate.** Dead in a match, press SPECTATE on the class screen to watch the fight until you
  spawn. The camera follows a fighter still standing — your killer first, then teammates, then
  everyone else, bots last — from behind and above, easing after them and never through a wall;
  when they fall it watches a moment and moves on to the next.
- **The bar** at the bottom shows who you're watching (name in their team's colour, class ·
  weapon · kills, a health bar). ◀ ▶ or Q / E switch, scroll zooms, the right mouse looks round
  them. SPAWN gets you straight back in as your chosen class (it counts down a reinforcement wave
  or the next round, like the class screen) and CLASS brings the class screen back.
- While spectating, the dead body's HUD is put away and the Hub menu's cinematic camera holds
  off. Spectating ends when you spawn or the round ends.

| File | Studio location | Type | Change |
|---|---|---|---|
| [Spectate.client.lua](StarterPlayerScripts/Spectate.client.lua) | StarterPlayer ▸ StarterPlayerScripts ▸ Spectate | LocalScript | **new**: the spectator camera and bar |
| [LoadoutMenu.client.lua](StarterPlayerScripts/LoadoutMenu.client.lua) | StarterPlayer ▸ StarterPlayerScripts ▸ LoadoutMenu | LocalScript | SPECTATE button; steps aside while spectating; spawns for the bar's SPAWN |
| [HubMenu.client.lua](StarterPlayerScripts/HubMenu.client.lua) | StarterPlayer ▸ StarterPlayerScripts ▸ HubMenu | LocalScript | the cinematic camera holds off while spectating |
| [DebugFlags.lua](ReplicatedStorage/DebugFlags.lua) | ReplicatedStorage ▸ DebugFlags | ModuleScript | documents the `Spectate` flag |
| [README.md](README.md) | — | docs | spectating |
