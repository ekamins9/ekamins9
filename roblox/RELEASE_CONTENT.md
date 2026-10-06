# First release — everything to build in Studio

> **Already built for you, for now.** Every item on this page has a **blueprint** in
> `ServerScriptService ▸ Build` (Weapons / Armor / Body): when the server starts, anything
> without a hand-made model is built from parts, so the whole catalog is playable today. These
> are placeholders in the game's blocky style; replace any of them with a hand-made model of
> the same name whenever you like and the builder leaves it alone. To get editable copies into
> Studio, run `require(game.ServerScriptService.Build.Blueprints).ensureAll()` in the command
> bar (edit mode). Details: [CONTENT_GUIDE.md](CONTENT_GUIDE.md) §0.

The catalog already lists all of this (prices, odds, unlocks). Each line below is a model to
make; until it exists the item either hides (sets) or shows with no model (pieces, hair, skins
fall back to colour tints). Check the Output on play: `[Catalog]` warns per missing model.

## Armor sets  →  `ServerStorage ▸ Armor ▸ <Set>` (Models already there, each with its Config)

Build `HeadClothing`, `TorsoClothing`, `LeftArmClothing`, `RightArmClothing`,
`LeftLegClothing`, `RightLegClothing` inside each, every one around a part named `Middle`.
Paint parts with attribute `ColorSlot` = Primary / Secondary / Accent / Metal where the player
should get to colour them. A set may skip slots.

| Set (Model name) | Pack | Weight | Tier | Price per piece | Helmet covers |
|---|---|---|---|---|---|
| `RoadLevy` | Road Levy | Light | Common | 250 M | hair |
| `MarshWardens` | Marsh Wardens | Light | Rare | 450 M or 25 C | hair |
| `CoastHarriers` | Harriers of the Coast | Light | Epic | 45 C | hair |
| `NightHunters` | Night Hunters | Light | Legendary | 90 C | hair + face |
| `Sellswords` | Sellswords | Medium | Common | 250 M | hair |
| `RiverGuard` | River Guard | Medium | Rare | 450 M or 25 C | hair |
| `GildedCourt` | The Gilded Court | Medium | Epic | 45 C | hair |
| `WolfCompany` | Wolf Company | Medium | Legendary | 90 C | hair + face |
| `TourneyKnight` | Tourney Knight | Heavy | Common | 250 M | hair + face |
| `IronCrow` | The Iron Crow (featured) | Heavy | Rare | 450 M or 25 C | hair + face |
| `Blackguard` | The Blackguard | Heavy | Epic | 45 C | hair + face |
| `SunKnights` | Knights of the Sun | Heavy | Legendary | 90 C | hair + face |

Piece names (helm / top / legs) are in each set's `Config`. Buying the whole pack is 15 % off
(20 % for Legendary packs). Five packs also bundle a weapon skin (see Skins, column "pack").

## Earned pieces  →  `ReplicatedStorage ▸ Cosmetics ▸ Pieces ▸ <id>`

One folder per piece holding only that slot's models (helmet: `HeadClothing` · top:
`TorsoClothing` + both arms · bottom: both legs). Never sold; the shop's EARNED IN BATTLE
panel shows progress.

| Folder `<id>` | Piece | Weight / slot | Earned by |
|---|---|---|---|
| `WolfPeltHood` | Wolf Pelt Hood | Light helmet | 100 polearm kills |
| `RunnersWraps` | Runner's Wraps | Light bottom | 200 parries |
| `HuntersCloak` | Hunter's Cloak | Light top | level 10 |
| `BloodiedKettle` | Bloodied Kettle Helm | Medium helmet | 150 one-handed kills |
| `SergeantsSurcoat` | Sergeant's Surcoat | Medium top | 25 round wins |
| `DuelistsSallet` | Duelist's Sallet | Medium helmet | 10 wins in 1v1 |
| `ChampionsGreatHelm` | Champion's Great Helm | Heavy helmet | 200 two-handed kills |
| `BanneretsTabard` | Banneret's Tabard | Heavy top | level 25 |
| `VeteransChausses` | Veteran's Chausses | Heavy bottom | 500 kills |

## Weapon display models  →  `ReplicatedStorage ▸ Cosmetics ▸ Weapons ▸ <Tool>`

`Shortsword`, `Greatsword`, `Pitchfork`, `Hammer`: a Model with a part named `Handle` (copy
the Tool's visible parts). Used by the menu mannequin and the 3D crate cards. Give blade and
grip parts the attribute `SkinPart` = `"Blade"` / `"Grip"` on the real Tools too, so skins
tint them.

## Weapon skins (40)  →  optional models in `Cosmetics ▸ Skins ▸ <Weapon> ▸ <Skin>`

Every skin works with tints alone. A model (with its own `Handle`) replaces the weapon's
visible parts. Worth modelling first: the four Legendaries of the Royal Armoury and the
400-kill ones.

| Weapon | Crate: Bladesmith / Hafted | Shop | In a pack | Royal Armoury | Earned (kills) |
|---|---|---|---|---|---|
| Shortsword | Pitted C · Bluesteel R · Crowfeather E | Whetted C 300 M · Gilt Hilt E 60 C | Sellsword's Edge R (Sellswords) | Heraldic R · Saint's Mercy L | Bloodletter E 150 · Hundredfold L 400 |
| Greatsword | Notched C · Blackened R · Gilded L | Grey Iron C 300 M · Executioner E 70 C | Crow-black R (Iron Crow) · Sunforged L (Sun Knights) | Heraldic R · Flamberge Wave L | Veteran E 150 · Oathkeeper L 400 |
| Pitchfork | Hayfork C · Ember R | Tarred C 250 M · Boarspear Red E 55 C | Marsh Reed R (Marsh Wardens) | Heraldic R · Serpent Tine L | Reaper E 150 · Peasant's Pride L 400 |
| War Hammer | Dented C · Tourney Gilt R · Bronze E | Ironhead C 300 M · Blackguard's Maul E (Blackguard pack) | Riverstone R (River Guard) | Heraldic R · Kingsbane L | Skullsplitter E 150 · Thunderhead L 400 |

Crates: Bladesmith's 60 C and Hafted 60 C (60 / 28 / 10 / 2, Legendary within 20), Royal
Armoury 120 C (Rare 50 / Epic 38 / Legendary 12, Legendary within 10, no Commons).

## Hair & beards  →  `Cosmetics ▸ Body ▸ Hair ▸ <id>`, `Cosmetics ▸ Body ▸ Beard ▸ <id>`

Hair: `Cropped`, `SweptBack`, `LongTied`, `BowlCut`, `Tonsure`, `ShavedSides`, `Topknot`
(free), `WildMane`, `BraidedCrown` (40 C). `Bald` needs no model.
Beards: `Stubble`, `Full`, `Goatee`, `MuttonChops` (free), `Braided`, `Forked` (40 C).
Faces (`Stern`, `Grin`, `Scarred`, `Weary`, `Fierce`, `OneEyed`): paste a decal id into
`Catalog ▸ Body` `texture` for each, or leave `""` to keep the rig's face.

## Nothing to build

Colors (18 free, 7 premium), hair colors (7 free, 4 premium), 12 earned titles and 24
contracts are config only and already live.
