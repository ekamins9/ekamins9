# Updated scripts: no skin through armor, steady arm armor in first person, one whoosh per swing, real eggs

- **No skin through the gaps.** R6 limbs are boxes and the new armor is rounded, so a box's
  corners and edges showed skin between plates (torso corners, the sides, upper arms, legs).
  The Dresser now paints a limb under a garment a shade of that garment (the model's `Under`:
  the colour of its base garment, set on every armor model), so a gap reads as cloth in shadow.
  Where a garment leaves the hand or forearm bare on purpose (rolled sleeves, bare hands) a
  skin-coloured sleeve keeps that stretch skin. Works everywhere the Dresser dresses: spawns,
  bots, menu mannequins and shop cards.
- **Arm armor no longer blinks out when you attack** in first person. A sleeve is now one mesh
  as long as the arm, and the old "hide when near the camera" check used a sphere around it,
  which hid the whole sleeve on every swing. It now measures to the piece's own box, with a
  gap between hiding and showing again so it can't flicker.
- **Skin swing sounds play once per swing.** The aura sound restarted every 0.45 s while the
  blade moved, so a long Zweihander swing stuttered and played twice. It now starts once as
  the swing gets going and can't restart until the blade has come to rest; long sounds fade
  instead of snapping off.
- **Hatchery eggs** are egg-shaped and each egg has its own look: speckled, mossy with a sprout,
  ember with glowing cracks (smoulders in the world), royal with gold bands, gems and a crown
  (sparkles). Eggs pick a look with `look` in `Catalog ▸ Eggs`.

| File | Studio location | Type | Change |
|---|---|---|---|
| [Dresser.lua](ReplicatedStorage/Dresser.lua) | ReplicatedStorage ▸ Dresser | ModuleScript | GAPS: limbs under garments take the garment's shade; skin sleeves over bare ends; undress restores skin |
| [CameraRig.client.lua](StarterCharacterScripts/CameraRig.client.lua) | StarterPlayer ▸ StarterCharacterScripts ▸ CameraRig | LocalScript | first-person arm pieces hide by their box, with hysteresis |
| [SkinFX.client.lua](StarterPlayerScripts/SkinFX.client.lua) | StarterPlayer ▸ StarterPlayerScripts ▸ SkinFX | LocalScript | one swing sound per swing; fade-out for cut sounds |
| [Companions.lua](ReplicatedStorage/Companions.lua) | ReplicatedStorage ▸ Companions | ModuleScript | egg shape and the four egg looks |
| [Catalog/Eggs.lua](ReplicatedStorage/Catalog/Eggs.lua) | ReplicatedStorage ▸ Catalog ▸ Eggs | ModuleScript | `look` per egg |
| [Build/MeshArmor.lua](ServerScriptService/Build/MeshArmor.lua) | ServerScriptService ▸ Build ▸ MeshArmor | ModuleScript | `under` in a build spec sets the model's `Under` |
| [scripts/build_armor.py](../scripts/build_armor.py) | — | tool | computes each model's `Under` from its blueprint; `--under` writes `under_armor.lua` for models already built |
| [README.md](README.md), [CONTENT_GUIDE.md](CONTENT_GUIDE.md) | — | docs | gaps, eggs, swing sound |

**Studio-only changes (save the place):** every torso / arm / leg armor model in
`ServerStorage ▸ Armor ▸ <Set>` and `ReplicatedStorage ▸ Cosmetics ▸ Pieces` got its `Under`
attribute (`blender/out/armor/under_armor.lua`).
