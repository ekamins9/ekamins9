# Updated scripts: bots that walk, fumble and take turns; one-armed pickups; screams; heavier stamina

- **Bot legs move.** The walk was written each frame before the Animator ran, and the weapon's
  idle pose reset the hips before the legs ever moved. It now runs after the animation step.
- **Bots fight like people:**
  - They sometimes don't read a swing at all, and their timing is looser (worse when winded).
  - A feint can fool them: they drop the guard they raised, and your real swing lands inside
    their re-guard cooldown. Squires nearly always fall for it, Champions rarely.
  - Each gets a temper: brute, duelist, wary, or flanker (works round behind you).
  - **They take turns**: round each player only the nearest two (a brute: three) fight. The
    rest hold a ring 10–15 studs out and circle until a gap opens.
- **A bug that froze fighters**: a combo queued behind a missed swing called a function before
  it existed. That errored every frame and locked the swinger. Fixed.
- **One arm, one-handed weapons.** Without a right arm you can pick up nothing; with one arm,
  only one-handers. You aren't offered the prompt, the server refuses the pickup, and bots
  don't go for them. No more pick-up / drop loop.
- **Bleeding out**: long screams of agony every 3–4 s, weaker as the blood runs out, gasps at
  the end. No health comes back while bleeding: Roblox's built-in 1 %/s regen was healing
  everyone and is switched off now.
- **Stamina bites**:
  - A landed hit now about breaks even (bonus 8 → 2); kills give back 20 % (was 35 %).
  - Parries refund 5 (was 10); feints cost 18.
  - A held guard drains 5/s; regen is 13/s, from 1.6 s after combat, 20 % inside that.
  - **Heavy pays 20 % more for everything**, has 75 stamina and regens 35 % slower; Light pays
    10 % less, has 120 stamina and regens 30 % faster.

| File | Studio location | Type | Change |
|---|---|---|---|
| [NpcAnimator.client.lua](StarterPlayerScripts/NpcAnimator.client.lua) | StarterPlayer ▸ StarterPlayerScripts ▸ NpcAnimator | LocalScript | PreSimulation: the legs swing |
| [Bots.lua](ServerScriptService/Combat/Bots.lua) | ServerScriptService ▸ Combat ▸ Bots | ModuleScript | miss / fooled / fatigue, tempers, turn-taking ring, one-armed rearm |
| [CombatServer.lua](ServerScriptService/Combat/CombatServer.lua) | ServerScriptService ▸ Combat ▸ CombatServer | ModuleScript | stamina numbers, `StaminaCostMult`, the queued-combo fix |
| [Pickup.lua](ServerScriptService/Combat/Pickup.lua) | ServerScriptService ▸ Combat ▸ Pickup | ModuleScript | `canHold`; take / takeNpc / nearest respect it |
| [Movement.client.lua](StarterCharacterScripts/Movement.client.lua) | StarterPlayer ▸ StarterCharacterScripts ▸ Movement | LocalScript | hides pickups you can't hold |
| [Injury.lua](ServerScriptService/Combat/Injury.lua) | ServerScriptService ▸ Combat ▸ Injury | ModuleScript | screams while bleeding out |
| [CharacterSystems.server.lua](ServerScriptService/CharacterSystems.server.lua) | ServerScriptService ▸ CharacterSystems | Script | no regen while bleeding; stamina numbers |
| [Health.server.lua](StarterCharacterScripts/Health.server.lua) | StarterPlayer ▸ StarterCharacterScripts ▸ Health | Script | **new**, empty: turns off Roblox's regen |
| [SoundBank.lua](ReplicatedStorage/SoundBank.lua) | ReplicatedStorage ▸ SoundBank | ModuleScript | `VoiceScream`, `VoiceGasp` |
| [Weights.lua](ReplicatedStorage/Catalog/Weights.lua) | ReplicatedStorage ▸ Catalog ▸ Weights | ModuleScript | `cost`; Heavy / Light retuned |
| [Dresser.lua](ReplicatedStorage/Dresser.lua) | ReplicatedStorage ▸ Dresser | ModuleScript | publishes `StaminaCostMult` |
| [README.md](README.md), [CONTENT_GUIDE.md](CONTENT_GUIDE.md) | — | docs | all of the above |
