# Updated scripts: emotes that look right

Feedback fixed: on the Bow the legs didn't stay planted, emotes could play mid-swing and looked
wrong, and arm-only emotes stopped as soon as you walked.

- **Feet stay planted.** A bow, laugh or war cry now bends at the `waist`: the upper body pivots
  on the hip line and the legs are counter-posed to exactly where they were (the Bow: 42° bend,
  feet within 0.03 studs of the floor).
- **No emotes mid-fight.** An emote won't start while you attack, block, kick or dodge. Pressing
  any fight key ends it at once. For everyone else, the character's `Acting` / `Blocking` flags
  end it, and the server refuses a Play while you're busy.
- **Arm-only emotes play on the move.** Salute, Cheer, Flourish, Wave, Shrug, Beckon, Laugh, War
  Cry and Blade Toss keep going while you walk (the legs keep the walk animation; Cheer's hop
  only plays standing). Bow, Kneel, Jig, Windmill and Champion need you to stand still; the
  wheel says so, and moving ends them.
- **The weapon behaves for every blade length.** Emotes steer the blade's direction. Salute,
  Cheer and War Cry hold it upright. The Bow sweeps it out to the side and round behind you,
  never through the floor. Kneel and Champion plant the tip so it just meets the ground; the
  hands rise for longer blades. The Flourish twirls it like a wheel beside you, with the arm
  lifted so a greatsword clears the floor and the blade passes outside the arm. The Windmill
  spins it flat over your head and eases to a stop on a whole turn.
- **No snaps.** The weapon's idle animation fades out over the first 0.2 s of an emote and back
  in over the last, and every emote starts and ends on the resting grip.
- **The wheel:** hold B, point, let go (or tap B and click). The number keys are gone: 1–9 are the
  backpack's weapon slots and would also swap your weapon. Each slot says ON THE MOVE or STAND
  STILL.
- Checked automatically for all 14 emotes with a greatsword: no blade through the body, no
  weapon under the floor (planted tips just touch), feet on the floor. The live tests covered
  the swing cancel, walking, and the Bow's drawn blade path.

| File | Studio location | Type | Change |
|---|---|---|---|
| [Emotes.lua](ReplicatedStorage/Emotes.lua) | ReplicatedStorage ▸ Emotes | ModuleScript | waist bends with planted legs; upper / whole-body emotes; blade steering (blade, plantW, twirl, rotor) in the grip's frame, by weapon length; animation fade; busy check; all 14 motions retuned |
| [Cosmetics.client.lua](StarterPlayerScripts/Cosmetics.client.lua) | StarterPlayer ▸ StarterPlayerScripts ▸ Cosmetics | LocalScript | radial wheel (hold / point / release); fight keys and attack flags end emotes; whole-body emotes refuse to start on the move and end when you move |
| [Cosmetics.server.lua](ServerScriptService/Hub/Cosmetics.server.lua) | ServerScriptService ▸ Hub ▸ Cosmetics | Script | refuses an emote while Acting / Blocking |
| [README.md](README.md), [CONTENT_GUIDE.md](CONTENT_GUIDE.md) | (docs) | | how emotes work and how to write one |
