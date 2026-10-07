# Updated scripts: your fighter on the class screen, a big picture vote, Highbridge over a river

- **Class screen shows your fighter.** Each class card has your character dressed in that
  class's saved loadout (armour, colours, hair, weapon), the chosen one turning slowly. The
  mannequin code the Hub menu used is now a shared module (`PreviewRig`), so both screens dress
  the same way.
- **The class screen steps aside for the vote** and comes back when the round starts.
- **The vote is big now**: the board widens to 1000 px and each choice is a large card with a
  picture of its map (from `ReplicatedStorage ▸ MapShots`, Studio-only), the name over a dark
  fade and the votes in a corner badge; the cards you didn't pick dim once you've voted. Maps
  without a picture yet get a card in their mode's colour.
- **Highbridge is over a river.** Water 16 studs under the deck with a sandy, stony bed, rock
  cliffs under both gatehouses with grass on top, hills fading into the morning fog, and the old
  far towers standing as ruins in the water. Going over the parapet into the river drowns you
  (new map attribute `DrownY`), and the kill still goes to whoever knocked you in.

| File | Studio location | Type | Change |
|---|---|---|---|
| [PreviewRig.lua](ReplicatedStorage/PreviewRig.lua) | ReplicatedStorage ▸ PreviewRig | ModuleScript | **new**: dressed mannequins for menus (moved out of HubMenu) |
| [HubMenu.client.lua](StarterPlayerScripts/HubMenu.client.lua) | StarterPlayer ▸ StarterPlayerScripts ▸ HubMenu | LocalScript | uses PreviewRig |
| [LoadoutMenu.client.lua](StarterPlayerScripts/LoadoutMenu.client.lua) | StarterPlayer ▸ StarterPlayerScripts ▸ LoadoutMenu | LocalScript | a preview of your fighter on each class card; hidden during the vote |
| [Scoreboard.client.lua](StarterPlayerScripts/Scoreboard.client.lua) | StarterPlayer ▸ StarterPlayerScripts ▸ Scoreboard | LocalScript | wide board and big picture cards for the vote |
| [Build/Maps.lua](ServerScriptService/Build/Maps.lua) | ServerScriptService ▸ Build ▸ Maps | ModuleScript | Highbridge: the river, banks and hills; `DrownY` |
| [CharacterSystems.server.lua](ServerScriptService/CharacterSystems.server.lua) | ServerScriptService ▸ CharacterSystems | Script | drowning below a map's `DrownY` |
| [README.md](README.md), [CONTENT_GUIDE.md](CONTENT_GUIDE.md) | — | docs | vote pictures, class previews, water |

**Studio-only changes (save the place):** `ServerStorage ▸ Maps ▸ Highbridge` rebuilt with its
river terrain (the old one kept in `ServerStorage ▸ _RetiredMaps ▸ Highbridge_beforeRiver`).
