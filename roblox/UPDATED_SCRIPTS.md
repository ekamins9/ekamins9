# Updated scripts: War's armies stand deeper

- **Each army's host**: great blocks of men drawn up on the flanks by each camp (four blocks of 128), standing on the slopes properly (each man on the ground under him). They never march, so they cost nothing a frame after they're placed. About 20,400 crowd parts in War now; 42–48 fps in Studio play.

| File | Studio location | Type | Change |
|---|---|---|---|
| [War.client.lua](StarterPlayerScripts/War.client.lua) | StarterPlayer ▸ StarterPlayerScripts | LocalScript | the hosts |
| [WarCrowd.lua](ReplicatedStorage/WarCrowd.lua) | ReplicatedStorage | ModuleScript | `still` regiments (each man on his own ground) |
| [README.md](README.md) | | doc | |

---

## Before that: the garrison drills outside the Courtyard

- **Outside the walls**: on the east field two companies of the garrison drill against each other (charging, crashing together, pulling apart); on the west field an archery range, archers loosing at straw butts. Seen from the battlements and the menu's flyover.
- **Checked in Play** in the Courtyard.

| File | Studio location | Type | Change |
|---|---|---|---|
| [CourtyardGuards.client.lua](StarterPlayerScripts/CourtyardGuards.client.lua) | StarterPlayer ▸ StarterPlayerScripts | LocalScript | the drill, the archery range |
| [README.md](README.md) | | doc | |

---

## Before that: the cavalry are real knights

- **Cavalry riders** (War's charges, the warfields, the Prologue's dawn riders) are now real armoured knights of their side sitting in the saddle with their lances, instead of a coat and a helmet block.

| File | Studio location | Type | Change |
|---|---|---|---|
| [WarFX.lua](ReplicatedStorage/WarFX.lua) | ReplicatedStorage | ModuleScript | riders from WarCrowd (`opts.side`) |
| [WarCrowd.lua](ReplicatedStorage/WarCrowd.lua) | ReplicatedStorage | ModuleScript | `figure`, the riding pose |
| [War.client.lua](StarterPlayerScripts/War.client.lua), [Warfield.client.lua](StarterPlayerScripts/Warfield.client.lua), [Prologue.client.lua](StarterPlayerScripts/Prologue.client.lua) | StarterPlayer ▸ StarterPlayerScripts | LocalScript | pass the riders' side |
