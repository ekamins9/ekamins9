# Updated scripts: GIFTS (send anything to anyone, online or not; buy anything as a gift)

- **GIFTS** (a new dock tile, with its own gift-box icon). It's a separate feature from trading: one way, by username, whether they're online or offline.
  1. **Who**: type their Roblox username (or pick someone in this server, or a friend online). It shows their face, name and level, and whether they're here.
  2. **What**: ITEMS (anything that trades, armor as full sets), MARKS, CROWNS, or FROM THE SHOP.
  3. **Send it**, with a card picked from a list ("GG!", "Happy birthday!"…), never typed.
- **Buy as a gift**: a 🎁 button by every purchase:
  - shelf skins;
  - packs and their pieces (the shop, the armory);
  - the season pass (GIFT THE PASS);
  - every Crowns bundle (🎁 AS A GIFT, paid in Robux; the receipt delivers to them).

  A player's profile has **SEND A GIFT**; inspecting something you own has **GIFT IT**.
- **The gift box** (`Gifts_v1`): every gift waits in it until they're here. It opens:
  - at once in this server;
  - on a nudge from another server;
  - when they next join, with a Roblox phone notification if set up (`Gift`, LAUNCH §8).

  Opening it twice can't duplicate anything: the profile remembers the ids it opened, and the box keeps a gift until that save lands. When it arrives:
  - a pop-up card shows each gift: who it's from, the card, what was in it;
  - something they already own comes as what was paid for it;
  - a skin is a copy of its own.
- **Rules**:
  - level 5 and up;
  - only where Roblox allows trading paid items (PolicyService `IsPaidItemTradingAllowed`). That's checked for the sender, and for the recipient as it arrives: where they can't receive it, it goes back to the sender whole;
  - their privacy: new setting **SETTINGS › Gifts from**: Everyone / Friends / Nobody;
  - daily caps: 25,000 Marks, 5,000 Crowns, 20 items, 30 gifts;
  - never crates, eggs or Keys.

  The sender's save lands before anything leaves; if the box can't be written, it all comes back. Logged in `GiftLog_v1`. Right-to-erasure covers the box, the log, and the sender's name on gifts still waiting.
- Trading's item check is now `Trading.checkItems`, shared with gifts.
- The dock tiles are a little smaller (92 px) so 11 fit. On a phone the dock is 2 × 6.
- Modal buttons now always sort below a pop-up's own content.
- Checked in Play (Studio's own data, with a Studio-only stand-in profile for the account builderman):
  - finding a player by username, and refusing yourself;
  - sending 500 Marks + 20 Crowns, and a Masterwork Saint's Mercy (gone from my inventory);
  - buying a shelf skin and the pass for him;
  - the daily cap refusing 999,999 Marks;
  - all four sat in his box;
  - the reverse (his four gifts to me): the wallet, the pass, both copies arrived, the box emptied, and the pop-up showed all four;
  - the GIFTS screen's layout.
- Not checked: a real Robux Crowns gift (it needs the live game), and a real second player online.

| File | Studio location | Type | Change |
|---|---|---|---|
| [Economy/Gifting.lua](ServerScriptService/Economy/Gifting.lua) (new) | ServerScriptService ▸ Economy | ModuleScript | the gift box, sending, buying for someone, Robux receipts |
| [Economy/Economy.lua](ServerScriptService/Economy/Economy.lua) | ServerScriptService ▸ Economy | ModuleScript | `giftQuote` (a purchase, packed to travel), `passGift` |
| [Economy/Trading.lua](ServerScriptService/Economy/Trading.lua) | ServerScriptService ▸ Economy | ModuleScript | `checkItems`, `policyOk` |
| [Economy/EconomyServer.server.lua](ServerScriptService/Economy/EconomyServer.server.lua) | ServerScriptService ▸ Economy | Script | a Crowns receipt bought as a gift goes to their box |
| [Hub/HubServer.server.lua](ServerScriptService/Hub/HubServer.server.lua) | ServerScriptService ▸ Hub | Script | the Gift ops; a Crowns buy for yourself forgets a waiting gift |
| [Hub/Reminders.server.lua](ServerScriptService/Hub/Reminders.server.lua) | ServerScriptService ▸ Hub | Script | `_G.NotifyGift` |
| [Safety/Erasure.lua](ServerScriptService/Safety/Erasure.lua) | ServerScriptService ▸ Safety | ModuleScript | Gifts_v1, GiftLog_v1 |
| [Loadout/Profile.lua](ServerScriptService/Loadout/Profile.lua) | ServerScriptService ▸ Loadout | ModuleScript | `giftsIn`, `giftDay` |
| [Catalog/Economy.lua](ReplicatedStorage/Catalog/Economy.lua), [ClientSettings.lua](ReplicatedStorage/ClientSettings.lua) | ReplicatedStorage | ModuleScript | `gifting` config; the Gifts from setting |
| [HubMenu.client.lua](StarterPlayerScripts/HubMenu.client.lua) | StarterPlayer ▸ StarterPlayerScripts | LocalScript | the GIFTS screen, 🎁 buttons, the gift cards pop-up, the dock |
| [../blender/ui_icons.py](../blender/ui_icons.py) | | Blender | the gift-box icon |
| [README.md](README.md), [../docs/LAUNCH.md](../docs/LAUNCH.md) | | doc | gifts; the Gift notification; RTBF table |

Studio only (save the place): ReplicatedStorage ▸ Cosmetics ▸ Icons ▸ **Gifts** (the icon); ServerStorage ▸ NotifyIds ▸ **Gift** (empty: the notification's id).

---

## Before that: the Showcase Director (one screen to film the game), GENERATE, custom battles, bots that look like players

- **The Showcase Director** (F4, or F2 › SHOWCASE › OPEN THE SHOWCASE DIRECTOR): one screen.
  1. **What to film**: GENERATE, CUSTOM BATTLE, the five ready-made battles, the Courtyard tour, the armor parade.
  2. **Set it up**: only the maps that showcase plays on (the old panel listed every map, and a map that didn't suit the showcase was quietly swapped for a random one). For a custom battle: the mode, the map, and a + / − for each of Squire, Knight, Champion, Archer and Mage (40 at most). For GENERATE: how long each battle lasts.
  3. **START FILMING.**
  - **TAB** while filming shows the control bar: camera style, fighter, next map (GENERATE: next battle), pick a map to stay on or rotate, menu, stop. TAB hides it again. The bar shows the map, how long until the next map, and who's being filmed.
- **GENERATE · AUTOPILOT**: a new battle every 2 / 3 / 5 minutes from a playlist of ten (siege assault, shield wall, bows & spells, champions' clash, king of the hill, last team standing, free for all, champion duel, mages at war, the levy), each on a map not played lately, never the same battle twice running.
- **Exact rosters**: BotFill's showcase override takes `roster` (so many of each kind, split evenly between the sides, the map's usual cap aside).
- **Bots that look like real players** (on unless switched off): an armor set of their weight (rarer ones less often), random colours, a skin on the weapon (staffs get their designed heads), and a kill effect that plays on whoever they bring down. About one kill in three, the killer stands and emotes. Name tags hide while filming. New hooks: `_G.KillFxPlay` and `_G.BotEmote` (Cosmetics), `FxEvent "EmoteModel"` (Cosmetics.client), NpcAnimator poses an emoting bot, and a bot stands still while it emotes.
- **A smoother camera**:
  - shots last 7-11 s;
  - a new shot nearby glides there instead of cutting (it only cuts when it's far);
  - the fighter's facing is smoothed, so hero and follow shots don't swing when they turn;
  - walls push the camera in quickly and let it ease back out (no jumping past posts);
  - when its fighter falls, it stays on them for 2 s;
  - it prefers action near where it already is.
- **Live game**: from a public server a battle opens a locked filming server of your own (HubServer `_G.HubReserveShowcase`, the trip's TeleportData `showcase`), and it starts by itself when you arrive. The Courtyard tour and the armor parade run in the live Courtyard.
- **Clean footage**: prompts ("Pick up", "Talk") and markers over the world hide too (CleanView). The director's own screen stays (`CleanViewKeep`). While filming, Ctrl+H does nothing.
- **Shorter breaks**: 4 s between rounds while filming (`Game.intermissionOverride`), not 15. STOP closes the Courtyard menu if you're in a battle, so the spawn screen shows.
- Checked in Play:
  - the director menu;
  - a custom TDM on Millfield with 2 Squires, 4 Knights, 4 Champions, 3 Archers and 3 Mages: exactly that, 8 a side, skins on the weapons (staffs with their heads), 12 of 16 bots with a kill effect;
  - picking Abbeyfield loaded it in 5 s; N twice changed the map each time;
  - GENERATE opened with Bows & Spells on Frosthollow, and N went to Shield Wall (14 Knights, 6 Champions) on Mistbridge;
  - in 25 s of fighting: 6 kill effects and a bot emote;
  - a field battle on ANY ran with a 4-minute clock;
  - STOP gave the screen back.
  - Not re-run after its last fix: STOP closing the Courtyard menu when it had already closed itself.

| File | Studio location | Type | Change |
|---|---|---|---|
| [Game/Showcase.lua](ServerScriptService/Game/Showcase.lua) | ServerScriptService ▸ Game | ModuleScript | GENERATE, CUSTOM, rosters, the bots' looks, filming servers, ShowcaseInfo, map history |
| [Showcase.client.lua](StarterPlayerScripts/Showcase.client.lua) | StarterPlayer ▸ StarterPlayerScripts | LocalScript | the Director menu, the TAB bar, F4, the smoother camera |
| [Game/BotFill.lua](ServerScriptService/Game/BotFill.lua) | ServerScriptService ▸ Game | ModuleScript | `roster`, `dress`, `onKill` |
| [Game/GameServer.server.lua](ServerScriptService/Game/GameServer.server.lua), [Game/Game.lua](ServerScriptService/Game/Game.lua) | ServerScriptService ▸ Game | Script, ModuleScript | the short break; a filming server's TeleportData |
| [Hub/Cosmetics.server.lua](ServerScriptService/Hub/Cosmetics.server.lua), [Cosmetics.client.lua](StarterPlayerScripts/Cosmetics.client.lua), [NpcAnimator.client.lua](StarterPlayerScripts/NpcAnimator.client.lua), [Combat/Bots.lua](ServerScriptService/Combat/Bots.lua) | ServerScriptService, StarterPlayerScripts | Script, LocalScript, ModuleScript | bots' kill effects and emotes |
| [Hub/HubServer.server.lua](ServerScriptService/Hub/HubServer.server.lua), [Admin/AdminServer.server.lua](ServerScriptService/Admin/AdminServer.server.lua) | ServerScriptService | Script | the filming server; the showcase loaded at start; the menu's options passed on |
| [CleanView.client.lua](StarterPlayerScripts/CleanView.client.lua), [NameTags.client.lua](StarterPlayerScripts/NameTags.client.lua), [AdminPanel.client.lua](StarterPlayerScripts/AdminPanel.client.lua), [HubMenu.client.lua](StarterPlayerScripts/HubMenu.client.lua) | StarterPlayer ▸ StarterPlayerScripts | LocalScript | prompts and markers hide; no name tags while filming; the tab opens the Director; CloseHub |
| [../docs/LAUNCH.md](../docs/LAUNCH.md) | | doc | the Director, recording |

---

## Before that: showcase fixes, the Magister's lessons, bots that stop hopping, and new wands and grimoires

- **Showcase fixes:**
  - **The director's camera never started** if a showcase began more than a minute after you joined. The server only makes the showcase's remote on the first SHOWCASE action, and the client waited 60 s for it then quit, so no camera, no keys and no hidden screens. It now waits however long it takes.
  - **1-5, Q, E did nothing:** the weapon bar takes 1 and 2 (and E is the prompts' key), and Roblox marks those presses as handled, which the showcase ignored. The showcase now takes its keys ahead of everything (ContextActionService, priority 4000) while it runs.
  - **The spawn screen showed** while you were filming. The server no longer sends it during a showcase, and sends it again when you stop, so you can join the match. It also stopped forcing the cursor on while hidden. The cursor is off in the footage.
  - **The map never changed:** a showcase on ANY now has 4-minute rounds and a different map each round. A picked map stays (no clock). **N** goes to the next map at once.
- **The Magister's lessons:**
  - Each lesson hands you the Staff carrying the spells it teaches (Firebolt, Chain Lightning, Frost Nova, Mend). The spell it's about is in slot 1 and picked, so "Lightning Leaps" has Chain Lightning ready. This is for that body only: your own Mage loadout and arsenal are untouched. It works for a Mage whose loadout is a Grimoire or a custom arsenal.
  - Switching lessons re-arms you in place, with the right weapon in hand.
  - **A lesson popup:** every lesson outside basic training opens with a big card in the middle for 7 s: the teacher, the lesson, what to do, and what's in your hand. The yard's banner now names all three teachers.
- **Bots:**
  - Archers and Mages hopped at random, mostly while reloading or meditating: the stuck check read standing still on purpose as stuck. Slowed or still on purpose no longer counts.
  - A Mage that lost sight of its target released its spell into the wall after 1.4 s. It now cancels it, and a caster or archer that hasn't seen its target for 1.5 s walks the path toward it until it has a shot.
- **Wands and grimoires:** every wand and grimoire skin is a new shape, built like the staff heads (StaffHeads designs, `head =` on the skin), with moving parts, lights and particles. The rarer, the more alive:
  - wands: Birch's moonstone, Holly's vine and turning gem, Ebony's diamond, Coral's pearl, Phoenix Feather's beating flame wings, Unicorn Hair's horn and rainbow halo, Willow Wisp's orbiting wisps, Elder Branch's star in a gyroscope, Thunderrod's lightning fork, Starfall's star, moon and comets;
  - grimoires: tooled covers and corners on all of them, plus Leatherbound's sigil, Blue Folio's orbiting pages, Herbarium's seedling, Ledger's circling coins and padlocked chain, Necronomicon's skull and watching eye, Book of Flames' burning pages, Frost Codex's ice and snowflake, Celestial Atlas's armillary sphere, Codex of Storms' storm cloud striking the pages, and The Burning Book's flame wings and self-turning pages of fire.
- Checked in Play:
  - showcase started 66 s after joining: camera on, no screens, no cursor; TDM with 24 bots and a 4-minute clock; N ended the round onto a new map (the map N names is now the one that loads);
  - the Magister's lessons with a Mage set to a Grimoire carrying Mend and Frost Nova: Staff with the lesson's arsenal, Chain Lightning picked for Lightning Leaps, the popup each time, out to a Knight lesson and back;
  - all 20 wand and grimoire designs built on a bench in edit mode, no errors.

| File | Studio location | Type | Change |
|---|---|---|---|
| [Showcase.client.lua](StarterPlayerScripts/Showcase.client.lua) | StarterPlayer ▸ StarterPlayerScripts | LocalScript | waits for its remote; keys via ContextActionService; N; no cursor |
| [Game/Showcase.lua](ServerScriptService/Game/Showcase.lua) | ServerScriptService ▸ Game | ModuleScript | ANY rotates maps (4-minute rounds); `nextMap`; spawn screen on stop |
| [Loadout/LoadoutServer.server.lua](ServerScriptService/Loadout/LoadoutServer.server.lua) | ServerScriptService ▸ Loadout | Script | no spawn screen while filming; `_G.ShowSpawnScreen`; a lesson's spells (`opts.spells`) |
| [LoadoutMenu.client.lua](StarterPlayerScripts/LoadoutMenu.client.lua) | StarterPlayer ▸ StarterPlayerScripts | LocalScript | frees the cursor only while it's really up |
| [Game/Training.lua](ServerScriptService/Game/Training.lua), [Training.client.lua](StarterPlayerScripts/Training.client.lua) | ServerScriptService ▸ Game; StarterPlayerScripts | ModuleScript, LocalScript | lesson arsenal and weapon in hand; the lesson popup |
| [Catalog/Drills.lua](ReplicatedStorage/Catalog/Drills.lua) | ReplicatedStorage ▸ Catalog | ModuleScript | `tracks.mage.spells`, a lesson's `spell` |
| [Combat/MagicClient.lua](ReplicatedStorage/Combat/MagicClient.lua) | ReplicatedStorage ▸ Combat | ModuleScript | a new arsenal picks its first spell |
| [Game/Modes/Tiltyard.lua](ServerScriptService/Game/Modes/Tiltyard.lua) | ServerScriptService ▸ Game ▸ Modes | ModuleScript | the banner names the three teachers |
| [Combat/Bots.lua](ServerScriptService/Combat/Bots.lua) | ServerScriptService ▸ Combat | ModuleScript | no hop when still on purpose; no casting into walls; finding a line of sight |
| [StaffHeads.lua](ReplicatedStorage/StaffHeads.lua), [Catalog/Skins.lua](ReplicatedStorage/Catalog/Skins.lua) | ReplicatedStorage | ModuleScript | 20 wand and grimoire designs; `head =` on their skins |
| [../docs/LAUNCH.md](../docs/LAUNCH.md) | | doc | the showcase's keys and maps |

---

## Before that: bringing players back (notifications, events) and Studio's own test data

- **Notifications** (Roblox's phone and desktop ones; setup in docs/LAUNCH.md §8):
  - a **Weekend** notification once, as a weekend event begins, to everyone seen in the last two weeks;
  - a **Daily** one about a day after someone leaves ("your day N gift is waiting").
  - Players opt in through Roblox's prompt, shown right after they claim the day's gift (from level 2, once a session).
  - Only one server sends each batch (a MemoryStore lock); never in Studio.
  - Who to remind: `RecentPlayers_v1` (when each player last left).
- **Events:** an UPCOMING EVENTS card at the top of the lobby's left column, filled from Roblox's experience events. **REMIND ME** RSVPs, so Roblox notifies them when the event starts. A live event shows LIVE NOW. With no events, there's no card.
- **Studio's own test data:** with Studio access to API services on, Studio's Play reached the live data stores. Every data store now opens through `Safety ▸ Stores`, which gives Studio `Studio_` copies. Studio saves between Plays, and its cheats never reach a live save.
  - `GameConfig.STUDIO_LIVE_DATA` points Studio at the live stores, on purpose only.
  - `STUDIO_NEWCOMER` now means a fresh, never-saved player every Play.
  - The panel's ERASE says when it only reached Studio's test data.
- **Erasure covers three more stores** with player data: `PlayerSettings_v1`, `SeasonGrants_v1` and `RecentPlayers_v1` (also added to the RTBF template table).
- Checked in Play:
  - Studio saved to `Studio_Profiles_v2`; the live profile was untouched (read only);
  - the events call answers in Studio (no events yet); the opt-in check answers;
  - the events card with two test events, one upcoming and one live, at the top of the column (the test events are removed);
  - the place has no injected scripts, and the counterfeit plugin is uninstalled.

| File | Studio location | Type | Change |
|---|---|---|---|
| [Safety/Stores.lua](ServerScriptService/Safety/Stores.lua) (new) | ServerScriptService ▸ Safety | ModuleScript | every data store; Studio's `Studio_` copies |
| [Hub/Reminders.server.lua](ServerScriptService/Hub/Reminders.server.lua) (new) | ServerScriptService ▸ Hub | Script | the notifications: who, when, sending |
| [HubMenu.client.lua](StarterPlayerScripts/HubMenu.client.lua) | StarterPlayer ▸ StarterPlayerScripts | LocalScript | UPCOMING EVENTS card and its fetch; the opt-in after the day's gift |
| [Safety/Erasure.lua](ServerScriptService/Safety/Erasure.lua) | ServerScriptService ▸ Safety | ModuleScript | three more stores; through Stores |
| [Loadout/Profile.lua](ServerScriptService/Loadout/Profile.lua) | ServerScriptService ▸ Loadout | ModuleScript | through Stores; `STUDIO_NEWCOMER` never saves |
| [Admin/AdminServer.server.lua](ServerScriptService/Admin/AdminServer.server.lua) | ServerScriptService ▸ Admin | Script | through Stores; ERASE in Studio says so |
| [SettingsServer.server.lua](ServerScriptService/SettingsServer.server.lua), [Scoreboard.server.lua](ServerScriptService/Scoreboard.server.lua), [Economy/Season.server.lua](ServerScriptService/Economy/Season.server.lua) | ServerScriptService | Script | through Stores |
| [Economy/Trading.lua](ServerScriptService/Economy/Trading.lua), [Economy/Collection.lua](ServerScriptService/Economy/Collection.lua), [Hub/Leaderboards.lua](ServerScriptService/Hub/Leaderboards.lua) | ServerScriptService | ModuleScript | through Stores |
| [GameConfig.lua](ReplicatedStorage/GameConfig.lua) | ReplicatedStorage | ModuleScript | `STUDIO_LIVE_DATA` |
| [README.md](README.md), [../docs/LAUNCH.md](../docs/LAUNCH.md) | | doc | §8 notifications and events setup; Studio's test data; RTBF table |

Studio only (save the place): ServerStorage ▸ **NotifyIds** with empty `Weekend` and `Daily` StringValues for the notification IDs.

---

## Before that: SHOWCASE mode (film the game with a camera that directs itself)

- **Admin panel (F2) › SHOWCASE**, for Owner and Admin. Seven showcases:
  - **siege**: two bot armies storm a castle;
  - **field battle**: Team Deathmatch;
  - **free for all**;
  - **bows & spells**: Archers and Mages;
  - **champion duel**;
  - **courtyard tour**;
  - **armor parade**: the 12 rarest sets on mannequins.

  A battle turns the server into a bot match on a real map, chosen or random. It's set up like a custom server with cheats: a better bot mix (fewer Squires), nobody earns anything, and no clock.
- **While it runs:**
  - your menus hide and you have no body (you can't spawn, and bots have nobody to chase);
  - the world streams in around the camera;
  - the camera directs itself: every 4-7 s it cuts to where the fighting is thickest, in orbit, hero, follow and aerial shots;
  - a new map opens with its establishing shots, and the camera never films through a wall.
- **Keys:** 1-5 pick a style (1 = auto), Q / E switch fighter, Ctrl+Shift+X stops (so does STOP in the panel). After a stop the match goes on, so you can spawn and play in it.
- It only runs in Studio or a custom/private server: it takes over the whole server.
- The footage is real gameplay, which is what Roblox wants for the game page's video.
- Checked in Play:
  - field battle on the Rose Court: bots filled both teams; follow and hero shots, no UI;
  - stop: the menus and the spawn screen came back;
  - armor parade: 12 mannequins, a push-in on each;
  - champion duel on the Sandpit: two Champions, the camera circling them;
  - the parade's mannequins were cleared on switching.

| File | Studio location | Type | Change |
|---|---|---|---|
| [Game/Showcase.lua](ServerScriptService/Game/Showcase.lua) (new) | ServerScriptService ▸ Game | ModuleScript | the kinds, staging, the parade, stop |
| [Showcase.client.lua](StarterPlayerScripts/Showcase.client.lua) (new) | StarterPlayer ▸ StarterPlayerScripts | LocalScript | the director's camera |
| [Game/BotFill.lua](ServerScriptService/Game/BotFill.lua) | ServerScriptService ▸ Game | ModuleScript | `BotFill.override` (a showcase's mix); the one filming takes no bot's place |
| [Game/GameServer.server.lua](ServerScriptService/Game/GameServer.server.lua), [Loadout/LoadoutServer.server.lua](ServerScriptService/Loadout/LoadoutServer.server.lua) | ServerScriptService | Script | their streaming focus left alone; no spawning while filming |
| [HubMenu.client.lua](StarterPlayerScripts/HubMenu.client.lua), [CleanView.client.lua](StarterPlayerScripts/CleanView.client.lua) | StarterPlayer ▸ StarterPlayerScripts | LocalScript | the menu camera holds off; `_G.SetCleanView` |
| [Admin/AdminServer.server.lua](ServerScriptService/Admin/AdminServer.server.lua), [Admin/Roles.lua](ServerScriptService/Admin/Roles.lua), [AdminPanel.client.lua](StarterPlayerScripts/AdminPanel.client.lua) | ServerScriptService ▸ Admin; StarterPlayerScripts | Script, ModuleScript, LocalScript | `showcase` / `showcase_stop`, the perm, the SHOWCASE tab |
| [README.md](README.md), [../docs/LAUNCH.md](../docs/LAUNCH.md) | | doc | showcases; recording the game page's video; sending footage to edit |

---

## Before that: up to code (rules posted, text filtered, data erasable)

- **The game's rules are posted, as Roblox's Terms require.** A game that enforces its own rules (this one kicks, bans and takes back items) must post them "and any consequences for violating them… clearly and conspicuously". The six rules:
  - be a good sport;
  - no cheating;
  - no farming;
  - trade fair;
  - play the mode;
  - respect staff.

  What happens to rule-breakers, and how to appeal, are in `ReplicatedStorage ▸ Rules`. They're shown in three places:
  - **a rules board beside the Notice Board** in the Courtyard, where everyone arrives (Read opens the menu's page);
  - **MENU › SETTINGS › THE RULES**;
  - **the kick and ban messages**, which now say it was for breaking the rules and how to appeal.
- **Everything typed that others read goes through Roblox's text filter** (`Safety ▸ TextFilter`). There was none before, and Roblox can take a game down for that. Filtered now:
  - custom server names;
  - staff announcements;
  - kick, ban and shutdown reasons;
  - titles given by staff.

  If the filter can't check something, it isn't shown.
- **Right to erasure** (Roblox forwards these data-deletion requests to your inbox): **ERASE ALL THEIR DATA** in the admin panel (Owner only). It kicks them everywhere, deletes their profile, queue, ban and leaderboard entries, and scrubs their ID from staff roles, the ban list, the action log and trade logs. `docs/LAUNCH.md` lists the RTBF deletion templates to set up once in Creator Hub, so Roblox deletes the keyed data by itself.
- **Checked and already fine:**
  - chat runs on TextChatService;
  - crate odds show as exact percentages before you open;
  - crates and trading follow Roblox's per-country rules (PolicyService);
  - the wishing fountain is free;
  - no off-platform links;
  - no personal info asked for.
- `docs/LAUNCH.md`: the rules, the May 2026 publishing tiers, and a new section 7 (Safety and privacy).
- Checked in Play: the board is built with all its text, Read opens RULES, the menu page has every rule, Settings links to it, and the filter returns clean text.

| File | Studio location | Type | Change |
|---|---|---|---|
| [Rules.lua](ReplicatedStorage/Rules.lua) (new) | ReplicatedStorage | ModuleScript | the rules, consequences, appeal |
| [Safety/TextFilter.lua](ServerScriptService/Safety/TextFilter.lua), [Safety/Erasure.lua](ServerScriptService/Safety/Erasure.lua) (new) | ServerScriptService ▸ Safety | ModuleScript | Roblox's filter; the right to erasure |
| [Courtyard.server.lua](ServerScriptService/Hub/Courtyard.server.lua) | ServerScriptService ▸ Hub | Script | the rules board |
| [HubMenu.client.lua](StarterPlayerScripts/HubMenu.client.lua) | StarterPlayer ▸ StarterPlayerScripts | LocalScript | the RULES screen; THE RULES in Settings |
| [HubServer.server.lua](ServerScriptService/Hub/HubServer.server.lua) | ServerScriptService ▸ Hub | Script | custom server names filtered |
| [AdminServer.server.lua](ServerScriptService/Admin/AdminServer.server.lua), [Roles.lua](ServerScriptService/Admin/Roles.lua) | ServerScriptService ▸ Admin | Script, ModuleScript | staff text filtered; kick and ban messages; `erase` |
| [AdminPanel.client.lua](StarterPlayerScripts/AdminPanel.client.lua) | StarterPlayer ▸ StarterPlayerScripts | LocalScript | ERASE ALL THEIR DATA (Owner) |
| [README.md](README.md), [../docs/LAUNCH.md](../docs/LAUNCH.md) | | doc | the above |

---

## Before that: ads, the trailer, clean view

- **Three ad pictures** (`store_art/ads/`, 1920×1080), made for Roblox's Sponsored row, where games show as small tiles:
  - **KNIGHT VS MAGE**: a Sun Knight and a Pyromancer split by a blade of light;
  - **PARRY!**: two blades meeting in a white-gold burst;
  - **35+ ARMOR SETS**: the Star Sage, the Phoenixborn and Obsidian, each in its rarity's light.
- **A 24-second trailer** (`store_art/video/trailer.mp4`, 1080p, silent, the words on screen) in seven shots:
  - aim every swing;
  - a parry;
  - a fireball;
  - a burning arrow;
  - the castle charge;
  - the five classes;
  - the end card.

  It's for video ads, YouTube and TikTok. The game page's own video has to be real gameplay, hence clean view.
- **Clean view: Ctrl+H** hides all UI (the game's and Roblox's: chat, the top bar), so anyone can film clean gameplay. Ctrl+H again restores exactly what was there (Roblox's player list stays replaced by ours).
- **docs/LAUNCH.md, section 6 (Ads):** what Roblox offers, what to upload, how to run a campaign (start small, read the CTR, fix the funnel before scaling), plus the game-page video rules.

| File | Studio location | Type | Change |
|---|---|---|---|
| [CleanView.client.lua](StarterPlayerScripts/CleanView.client.lua) (new) | StarterPlayer ▸ StarterPlayerScripts | LocalScript | Ctrl+H: all UI off / back |
| [../blender/store_ads.py](../blender/store_ads.py) (new) | | Blender script | the ad scenes: versus, parry, armory |
| [../blender/store_video.py](../blender/store_video.py) (new) | | Blender script | the trailer: seven animated shots, title cards, the edit to MP4 |
| [../blender/art_kit.py](../blender/art_kit.py) | | Blender script | `Rig` (a figure that moves), `blend_pose`, `ease`, `look` |
| [README.md](README.md), [../docs/LAUNCH.md](../docs/LAUNCH.md) | | doc | clean view; ads; the game-page video; Mild play-test |

---

## Before that: rated Mild (all ages)

**The game now fits Roblox's Mild content label**, so every age can play it: Roblox Kids (5-8), Select (9-15) and everyone older. Before, it had beheading, severed limbs, a head skewered on the blade, blood and bleeding out, plus a tavern. That made the honest questionnaire answer Strong violence and alcohol: Restricted, 18+ only, and that label can never be changed back.
- **One switch, `GameConfig.GORE = false`.** With it off:
  - a killing blow just drops them: the hit's flash, the hitstop, the ragdoll;
  - the body fades about 5 s later (kill-effect remains such as statues, graves and bones keep their time);
  - no blood: a clean hit flashes white and gold (not orange, so it never reads as a block);
  - nothing is severed or skewered, and nobody bleeds out screaming;
  - an arrow that hits someone flashes and is gone (it still sticks in walls);
  - no bone-crunch sounds.
- **Clean words:**
  - the death screen says STRUCK DOWN, HEADSHOT!, KICKED DOWN, OUTFOUGHT, KNOCKED OUT;
  - the kill feed says struck down, outfought, sniped, kicked down, defeated.
- **No alcohol:** the Courtyard's tavern is now the Hearth & Hound, an inn (sign, docs; the props in the place were renamed), and the Jig is "a village jig".
- **Blood-themed cosmetics are crimson magic now.** They keep their keys, so owned items still work:
  - Blood Arrows → Crimson Arrows: a glowing trail, a ring of light on impact instead of a red splash;
  - the "blood" weapon aura → Crimson glow: it rises, never drips;
  - Bloodlance → Crimson Lance;
  - Seraph's Kiss → Seraph's Grace;
  - the Bloodrage finish's wording.
- **Docs:**
  - `docs/LAUNCH.md` has the whole questionnaire with honest answers (Mild), and how to reach players under 16 (Audience Reach: age check, 2FA, a fee or Premium, 250 engaged plays in 60 days);
  - `CONTENT_GUIDE.md` has a "Keep it Mild" box for anything new.
- Checked in Play: no limb or head comes off, no stump, no bleeding, no skewer; a hit flashes white; a body is gone by 6 s.

| File | Studio location | Type | Change |
|---|---|---|---|
| [GameConfig.lua](ReplicatedStorage/GameConfig.lua) | ReplicatedStorage | ModuleScript | `GORE = false` and why |
| [Injury.lua](ServerScriptService/Combat/Injury.lua) | ServerScriptService ▸ Combat | ModuleScript | dismember / skewer / bleed only with GORE; `hitFlash` instead of blood |
| [CombatServer.lua](ServerScriptService/Combat/CombatServer.lua), [RangedServer.lua](ServerScriptService/Combat/RangedServer.lua) | ServerScriptService ▸ Combat | ModuleScript, Script | kills just kill; no bone crunch; arrows don't stay in bodies |
| [Corpses.lua](ServerScriptService/Combat/Corpses.lua) | ServerScriptService ▸ Combat | ModuleScript | `BODY_LIFE` 4 s |
| [DeathScreen.client.lua](StarterPlayerScripts/DeathScreen.client.lua), [Scoreboard.client.lua](StarterPlayerScripts/Scoreboard.client.lua) | StarterPlayer ▸ StarterPlayerScripts | LocalScript | clean titles and kill-feed words |
| [Courtyard.server.lua](ServerScriptService/Hub/Courtyard.server.lua), [MapCourtyard.lua](ServerScriptService/Build/MapCourtyard.lua) | ServerScriptService ▸ Hub; ▸ Build | Script, ModuleScript | the inn, not a tavern |
| [ArrowFX.lua](ReplicatedStorage/ArrowFX.lua), [SkinFX.lua](ReplicatedStorage/SkinFX.lua), [Emotes.lua](ReplicatedStorage/Emotes.lua) | ReplicatedStorage | ModuleScript | crimson, not blood; the village jig |
| [Catalog/ArmorFX.lua](ReplicatedStorage/Catalog/ArmorFX.lua), [Catalog/SpellSkins.lua](ReplicatedStorage/Catalog/SpellSkins.lua), [Catalog/Emotes.lua](ReplicatedStorage/Catalog/Emotes.lua) | ReplicatedStorage ▸ Catalog | ModuleScript | names and descriptions |
| [README.md](README.md), [CONTENT_GUIDE.md](CONTENT_GUIDE.md), [../docs/LAUNCH.md](../docs/LAUNCH.md) | | doc | the above; the questionnaire; Keep it Mild |

**Studio:** the Courtyard's three tankard props were renamed (ServerStorage ▸ Maps ▸ Courtyard). **Save the place.**

---

## Before that: store art (thumbnails, icon, badge pictures)

No game scripts changed. **Pictures for the store page and the badges, rendered in Blender from the game's own armor sets, weapons and staffs** (in `store_art/`, ready to upload: see [docs/LAUNCH.md](../docs/LAUNCH.md) sections 2 and 3):
- **Five thumbnails** (1920×1080):
  - the class line-up ("5 CLASSES / PICK YOUR FIGHTER");
  - the clash ("STEEL & GLORY");
  - the siege ("STORM THE CASTLE / 6 BATTLE MODES");
  - the mage ("MASTER MAGIC");
  - the archer ("HEADSHOT!").
- **The icon** (512×512).
- **Ten badge medallions** (512×512, one per key in `ServerStorage ▸ BadgeIds`).

| File | Studio location | Type | Change |
|---|---|---|---|
| [../blender/art_kit.py](../blender/art_kit.py) (new) | | Blender script | the toolkit:<br>• posed R6 fighters in any armor set, weapons, staffs, bows;<br>• fire (a hot core in a ragged rim), blazes, sparks, embers;<br>• castles, skies, haze;<br>• Cycles setup, bloom, colour grade;<br>• titles as a crisp layer laid over the render;<br>• `--layout` quick renders |
| [../blender/store_art.py](../blender/store_art.py) (new) | | Blender script | the scenes: clash, mage, archer, lineup, siege, icon, `badge:<Key>`, `badges` |
| `../store_art/*.png`, `../store_art/badges/*.png` (new) | | images | the finished pictures (the `work/` folders: the renders before titles, not kept in git) |
| [../docs/LAUNCH.md](../docs/LAUNCH.md) | | doc | which picture goes where, the thumbnails' order |

---

## Before that: launch-safe saving, analytics, badges, kill cam, weekend events

- **Saving is one server at a time (no more duplicates).** Before, a profile was read on join and written over on leave with nothing stopping two servers at once. Hop servers quickly after a trade and an item could exist in both places. Now:
  - A profile is claimed when it loads and let go when you leave.
  - A server finding it claimed waits for the other to finish, then takes it.
  - A server that lost it never writes over it again.
- **No more wiped saves on a bad day.** Before, if Roblox's data service failed when you joined, you got a fresh profile, and the next autosave overwrote your real one. Now that session is never saved, and you're asked to rejoin.
- **Purchases:** Crowns only count as delivered once they're safely saved. If the save fails, Roblox retries the receipt later, and it's never credited twice.
- **Analytics** (Creator Dashboard ▸ Analytics):
  - The newcomer's funnel: joined → training → ready → first battle → first crate → levels 2, 5 and 10.
  - Every Marks / Crowns / Keys source and sink.
  - The events RoundPlayed, CrateOpened and Trade.
- **Badges:** ten of them (Welcome, Graduate, First Blood, First Victory, Bow and Staff, Veteran, Champion Slayer, Iron Will, Touched by Legend, Beta Tester).
  - Make them on the dashboard, then type each id into Studio ▸ ServerStorage ▸ BadgeIds.
  - Anyone who already earned one gets it when they join.
- **Kill cam:** after you fall, the view turns to whoever got you and closes in on them, near or far. Settings ▸ Kill cam turns it off.
- **Weekend events, every weekend** (Friday 16:00 to Monday 08:00 UTC), in turn:
  - Double XP.
  - **Armory Roulette:** a random weapon pair every spawn in battle.
  - Raid Weekend: the Horde pays double.
  - War Chest Weekend: 1.5× Marks.
  - A dated event like Halloween takes the weekend instead.
- **Phones:** staff heads only animate when on screen, and on phones only up close and at half rate.
- **Studio:** BadgeIds was created in ServerStorage (Studio only). **Save the place.**
- See **docs/LAUNCH.md** for what's left for you.

| File | Studio location | Type | Change |
|---|---|---|---|
| [Profile.lua](ServerScriptService/Loadout/Profile.lua) | ServerScriptService ▸ Loadout ▸ Profile | ModuleScript | the session lock; unsafe loads never saved; save returns success; one load per player; the funnel field; badges and funnel hooks |
| [Analytics.lua](ServerScriptService/Economy/Analytics.lua), [Badges.lua](ServerScriptService/Economy/Badges.lua) (new) | ServerScriptService ▸ Economy | ModuleScript | the dashboard's events; the badges |
| [Economy.lua](ServerScriptService/Economy/Economy.lua), [Stats.lua](ServerScriptService/Economy/Stats.lua), [Trading.lua](ServerScriptService/Economy/Trading.lua) | ServerScriptService ▸ Economy | ModuleScript | money in and out counted; `spend(…, why)`; purchases wait for the save |
| [Training.lua](ServerScriptService/Game/Training.lua), [Scoreboard.server.lua](ServerScriptService/Scoreboard.server.lua) | ServerScriptService | ModuleScript, Script | funnel, ring and Gauntlet pay, badges; RoundPlayed |
| [LoadoutServer.server.lua](ServerScriptService/Loadout/LoadoutServer.server.lua) | ServerScriptService ▸ Loadout | Script | Armory Roulette |
| [Calendar.lua](ReplicatedStorage/Catalog/Calendar.lua), [Drops.lua](ReplicatedStorage/Drops.lua) | ReplicatedStorage | ModuleScript | the weekend rotation; `Drops.rule` |
| [CameraRig.client.lua](StarterCharacterScripts/CameraRig.client.lua), [ClientSettings.lua](ReplicatedStorage/ClientSettings.lua) | StarterCharacterScripts; ReplicatedStorage | LocalScript; ModuleScript | the kill cam and its setting |
| [TrimAnim.client.lua](StarterPlayerScripts/TrimAnim.client.lua) | StarterPlayer ▸ StarterPlayerScripts | LocalScript | on-screen only; phones lighter |
| [README.md](README.md), [../docs/LAUNCH.md](../docs/LAUNCH.md) (new) | | doc | all of the above; the launch checklist |

---

## Before that: archers' outfits

- **The Bowman: the Archer's own outfit.**
  - A hood with a long tail and a dagged capelet in your colours.
  - A leather jerkin, and a quiver over the right shoulder with arrows standing out.
  - A bracer on the bow arm and a shooting glove on the draw hand.
  - Wrapped calves and soft boots.
  - It comes with the Archer at level 5, and the unlock pop-up says so.
  - An Archer starts out in it, and any Light class may wear it once it's yours.
  - Saved Archers still in the old default outfit are moved into it.
- **Four more in the Fletcher's Crate**, a piece at a time, each a tradable copy:
  - **Greenwood Outlaws** (Rare): a feathered cap, Lincoln green with a pointed dagged hem, a hunting horn, a quiver behind the hip.
  - **Falcon Wardens** (Epic): a hood with a golden beak, amber eyes and a feather crest, a feather mantle, a falconer's gauntlet, talon boots, and a falcon perched on your shoulder.
  - **Moonshadow** (Legendary): a crescent moon on a silver circlet, a cloak edged in silver leaves, a leaf pauldron, arrows fletched with light. Wears the new **Moonlit** finish.
  - **Phoenixborn** (Mythic): a golden mask under a crest of burning feathers, folded wings of fire, a sun on the breast, burning arrows. Wears the new **Phoenixfire** finish.
  - Both finishes also drop from the crate on their own.
- **Armory:** the class outfits (the Bowman, the Apprentice's robes) have their own CLASS OUTFITS group that says which class they come with.
- **Dragonbone staff:** its wings now have real skin between the bones (they read as sticks before), and the skull is bigger.
- **Studio:** the outfits' meshes were uploaded and assembled into ServerStorage ▸ Armor ▸ \<set\> (Studio only). **Save the place.** Until it's saved, the sets build from their blueprints at server start, so they work either way.

| File | Studio location | Type | Change |
|---|---|---|---|
| [Armor.lua](ServerScriptService/Build/Armor.lua) | ServerScriptService ▸ Build ▸ Armor | ModuleScript | the five outfits' blueprints |
| [Bowman](ServerStorage/Armor/Bowman/Config.lua), [Greenwood](ServerStorage/Armor/Greenwood/Config.lua), [FalconWardens](ServerStorage/Armor/FalconWardens/Config.lua), [Moonshadow](ServerStorage/Armor/Moonshadow/Config.lua), [Phoenix](ServerStorage/Armor/Phoenix/Config.lua) (new) | ServerStorage ▸ Armor ▸ \<set\> ▸ Config | ModuleScript | the sets |
| [init.lua](ReplicatedStorage/Catalog/init.lua) (Catalog), [Packs.lua](ReplicatedStorage/Catalog/Packs.lua), [ArmorFX.lua](ReplicatedStorage/Catalog/ArmorFX.lua), [Crates.lua](ReplicatedStorage/Catalog/Crates.lua) | ReplicatedStorage ▸ Catalog | ModuleScript | a set's `Unlock`; a class starter as a default; the Bowman and Fletcher packs; Moonlit and Phoenixfire; the crate's line |
| [GameConfig.lua](ReplicatedStorage/GameConfig.lua), [Profile.lua](ServerScriptService/Loadout/Profile.lua) | ReplicatedStorage; ServerScriptService ▸ Loadout | ModuleScript | the Archer's starter; old Archers dressed in it (loadoutV 3) |
| [HubMenu.client.lua](StarterPlayerScripts/HubMenu.client.lua) | StarterPlayer ▸ StarterPlayerScripts | LocalScript | CLASS OUTFITS in the Armory, "comes with the Archer", the unlock pop-up |
| [StaffHeads.lua](ReplicatedStorage/StaffHeads.lua) | ReplicatedStorage ▸ StaffHeads | ModuleScript | triangles (`tri`), Dragonbone's wings |
| [skins_handmade.part](../scripts/skins_handmade.part) | (tool) | | the staff skins' `head`, so a regeneration keeps them |
| [README.md](README.md), [CONTENT_GUIDE.md](CONTENT_GUIDE.md) | | doc | all of the above |

---

## Before that: epic staffs, spells you can see, no weapon-swap cheese, no bot farming

- **Spells were invisible.** Your screen listened for spell effects for only 30 seconds after you joined, and the game sets that channel up only when someone first holds a staff. Pick the Mage later than that and no bolt, circle or blast was ever drawn. Now it waits as long as it takes. Siege and Horde banners had the same limit; fixed too.
- **Staff skins are whole new heads, not recolours.** The rarer, the wilder:
  - **Common:** Ashwood's pale crook over a breathing crystal; Oaken's gnarled branches round a turning amber.
  - **Rare:**
    - Emberwood: a burning coal in charred prongs, with embers circling it.
    - Frostbranch: a burst of ice round a spinning frost crystal.
    - Gilt Spire: a floating gem over a turning halo.
    - Bloodroot: a heart that beats in thorned roots and drips.
  - **Epic:**
    - Verdant Bough: leaves wheeling round a flower in bloom, with fireflies.
    - Stormcaller: real lightning crackling between the prongs of a fork, rune rings whirling.
    - Bonecaller: a skull with burning eyes and ghosts circling it.
    - Sunspire: a wheel of rays turning round a white sun.
  - **Legendary:**
    - Archmage's Rod: a crystal inside a gyroscope of three rings, each turning on its own axis.
    - Dragonbone: a dragon skull with fire in its jaws and bone wings that beat.
    - Voidstaff: a black hole with a whirling disc, orbiting shards, and light pulled in.
  - **Mythic:** the Staff of the Cosmos. A star on a golden astrolabe, three worlds in orbit (a moon going round the ringed one), their paths in dust, a wheel of constellations, a nebula, and light that walks the rainbow.
  - Spells now leave from the head's core.
- **Weapon swap exploit fixed.** Each weapon kept its own swing timer, so swapping and stabbing skipped the recovery. Now:
  - A drawn weapon can't strike for 0.35 s (two-handers 0.5 s).
  - The recovery you owe follows you to the next weapon.
  - The server decides this; a press in the last moment of the draw still goes off.
- **A draw animation.** Your arm reaches over your shoulder or to your hip and pulls the weapon out. Everyone sees it on players and bots. Settings ▸ Draw animation turns it off.
- **Holstered weapons show from the moment you spawn.** Before, they appeared only after you had equipped and put one away: the holster script was watching the old backpack.
- **Training yard:**
  - The Bowmaster's lessons hand you a bow even if your Archer carries a crossbow; the Magister's hand you the staff.
  - Sir Aldric no longer wears a pillar of light forever (the guide beacon pointed at him whenever no lesson was on).
  - The teachers and the Courtyard's bard wear our gold name tags (name, and what they do under it) instead of Roblox's.
- **Marks: no farming bots.**
  - Sparring wins in the ring pay only the first time per rank.
  - A match's bots pay 1 / 2 / 4 Marks by rank (a player pays 8).
  - Round pay is down a little (50 / 50).
  - Past 2500 Marks of battle pay in a day, rounds pay 40% for the rest of it ("A LONG DAY" on the pay card).

| File | Studio location | Type | Change |
|---|---|---|---|
| [StaffHeads.lua](ReplicatedStorage/StaffHeads.lua) (new) | ReplicatedStorage ▸ StaffHeads | ModuleScript | the 14 staff heads and their effects |
| [SkinTrims.lua](ReplicatedStorage/SkinTrims.lua), [SkinFX.lua](ReplicatedStorage/SkinFX.lua), [Dresser.lua](ReplicatedStorage/Dresser.lua) | ReplicatedStorage | ModuleScript | heads built, plain head hidden, spell tip moved; hidden parts restored first |
| [Skins.lua](ReplicatedStorage/Catalog/Skins.lua) | ReplicatedStorage ▸ Catalog ▸ Skins | ModuleScript | `head` on every staff skin |
| [TrimAnim.client.lua](StarterPlayerScripts/TrimAnim.client.lua) (new), [DrawFX.client.lua](StarterPlayerScripts/DrawFX.client.lua) (new) | StarterPlayer ▸ StarterPlayerScripts | LocalScript | the heads' motion, lights, lightning; the draw |
| [MagicFX.lua](ReplicatedStorage/MagicFX.lua), [Objectives.client.lua](StarterPlayerScripts/Objectives.client.lua) | ReplicatedStorage; StarterPlayerScripts | ModuleScript; LocalScript | wait for their remotes without a time limit |
| [CombatServer.lua](ServerScriptService/Combat/CombatServer.lua) | ServerScriptService ▸ Combat | ModuleScript | the draw time and the carried-over recovery |
| [Holsters.server.lua](ServerScriptService/Loadout/Holsters.server.lua) | ServerScriptService ▸ Loadout | Script | every Backpack watched |
| [LoadoutServer.server.lua](ServerScriptService/Loadout/LoadoutServer.server.lua), [Training.lua](ServerScriptService/Game/Training.lua), [Drills.lua](ReplicatedStorage/Catalog/Drills.lua) | ServerScriptService; ReplicatedStorage ▸ Catalog | Script; ModuleScript | a lesson's weapon; no idle beacon; teachers' tags; spar pays once |
| [NameTags.client.lua](StarterPlayerScripts/NameTags.client.lua), [Courtyard.server.lua](ServerScriptService/Hub/Courtyard.server.lua) | StarterPlayerScripts; ServerScriptService ▸ Hub | LocalScript; Script | map characters' tags |
| [Economy.lua](ReplicatedStorage/Catalog/Economy.lua) (catalog), [Economy.lua](ServerScriptService/Economy/Economy.lua), [Scoreboard.server.lua](ServerScriptService/Scoreboard.server.lua), [Horde.lua](ServerScriptService/Game/Modes/Horde.lua), [Scoreboard.client.lua](StarterPlayerScripts/Scoreboard.client.lua), [Training.client.lua](StarterPlayerScripts/Training.client.lua) | | | bot kills by rank, the daily cap, the pay card |
| [ClientSettings.lua](ReplicatedStorage/ClientSettings.lua) | ReplicatedStorage ▸ ClientSettings | ModuleScript | Draw animation On / Off |
| [README.md](README.md) | | doc | all of the above |

---

## Before that: armor in sets, previews that breathe, room for the Mage

- **Inventory shows armor as sets.** One card per set ("complete" or "1 of 3 pieces"), never a lone piece; a set's card opens the Armory on that set.
- **A quicker Inventory.** All the cards appear at once, and each 3D thumbnail is built only as it scrolls into view (a few a frame). A big collection opens without the hitch.
- **Armor trades only as a full set.** The server refuses an offer that has part of a set: every piece of it, one copy each, together. A set counts as one item toward the 8. The trade screen shows each set as one FULL SET card, and clicking it puts up or takes back every piece. Sets you only partly hold stay out of the picker, and its header says how many.
- **Previews breathe.** The knight on the inspect and Loadout stages breathes and glances about. This only runs while the stage is on screen.
- **SHOWING: PRIMARY ⇄** on those stages swaps the weapon in their hands for the loadout's secondary.
- **The Mage has room in the training yard.** The yard runs on east past the ring. Magister Orrin's arcane circle now stands there in open ground, with its three dummies beyond it, banners and two torches. No trees inside the new stretch.
- **From the commit before this one** (the ward, the steady staff, the bots):
  - The Mage's ward stops a frontal blow outright, like a block, paid in mana. Without the mana it breaks and the rest gets through.
  - The staff and the wand are held still on the walk again.
  - Archer, crossbow and Mage bots stand like players: the bow drawn, the crossbow shouldered, the staff in its stance.
  - A drop's announcement shows once per player, ever. The Beta's button opens your Trailblazer.
  - Clicks on the inspect panel no longer reach the cards behind it.
- **Studio:** the TrainingYard map was rebuilt (ServerStorage ▸ Maps, Studio only). **Save the place.**

| File | Studio location | Type | Change |
|---|---|---|---|
| [HubMenu.client.lua](StarterPlayerScripts/HubMenu.client.lua) | StarterPlayer ▸ StarterPlayerScripts | LocalScript | Inventory set cards and lazy thumbnails; trade full-set cards and picker; stage idle and PRIMARY / SECONDARY; (before) the crier once, the inspect click catcher |
| [Trading.lua](ServerScriptService/Economy/Trading.lua) | ServerScriptService ▸ Economy ▸ Trading | ModuleScript | armor only as full sets |
| [MapTraining.lua](ServerScriptService/Build/MapTraining.lua) | ServerScriptService ▸ Build ▸ MapTraining | ModuleScript | the yard's east end, the arcane circle moved there |
| [Ward.lua](ServerScriptService/Combat/Ward.lua), [CombatServer.lua](ServerScriptService/Combat/CombatServer.lua) | ServerScriptService ▸ Combat | ModuleScript | (before) the ward stops a frontal blow like a block |
| [MagicSpells.lua](ReplicatedStorage/MagicSpells.lua), [MagicFX.lua](ReplicatedStorage/MagicFX.lua) | ReplicatedStorage | ModuleScript | (before) the ward's numbers; its pane of light |
| [RangedFX.client.lua](StarterPlayerScripts/RangedFX.client.lua), [NpcAnimator.client.lua](StarterPlayerScripts/NpcAnimator.client.lua) | StarterPlayer ▸ StarterPlayerScripts | LocalScript | (before) still arms on the walk; bots posed like players |
| [RangedServer.lua](ServerScriptService/Combat/RangedServer.lua), [Bots.lua](ServerScriptService/Combat/Bots.lua) | ServerScriptService ▸ Combat | ModuleScript | (before) the draw and aim published for the pose |
| [Calendar.lua](ReplicatedStorage/Catalog/Calendar.lua), [Profile.lua](ServerScriptService/Loadout/Profile.lua), [HubServer.server.lua](ServerScriptService/Hub/HubServer.server.lua) | | | (before) `dropSeen`, the drop's `see` button |
| [README.md](README.md) | | doc | all of the above |

---

## Before that: emotes no longer bend backwards

- **The bug:** in the world, every emote had the weapon's own animation (its guard, the walk's arm swing) added on top of the emote's pose. That turned the salute and others back over the shoulder. Menu previews pose the mannequin directly, so they looked fine.
- **The causes:**
  - Emotes cleared the animation only just before drawing, but Roblox's Animator writes it back after that, before the body is put together. Now it is also cleared right after the Animator steps (`Stepped`), as the bow pose already did.
  - The emote loop was started when the module first loaded, which ties it to whichever script loaded it first. If that was a character's script, the loop died with the body. Now whoever plays or poses an emote restarts the loop if it has stopped.
- **The same restart fix** for arrow flight (arrows could hang in the air after a respawn) and input hints (keyboard vs controller could stop updating).

| File | Studio location | Type | Change |
|---|---|---|---|
| [Emotes.lua](ReplicatedStorage/Emotes.lua) | ReplicatedStorage ▸ Emotes | ModuleScript | animation dropped after the Animator steps; a loop that restarts itself |
| [ArrowFlight.lua](ReplicatedStorage/ArrowFlight.lua), [InputHints.lua](ReplicatedStorage/InputHints.lua) | ReplicatedStorage | ModuleScript | loops that restart themselves |

---

## Before that: the death screen, fire on the big moments, a clearer menu

- **No more black screen when you die.** First the fall: the world drains of colour, red closes in at the edges, a low boom, and the word lands (BEHEADED, SHOT THROUGH THE HEAD, YOU BLED OUT, BETRAYED…) with who did it and with what. Then a dark veil with rising embers and a countdown bar: BACK IN THE FIGHT IN 3, BACK TO THE COURTYARD, THE NEXT WAVE BRINGS YOU BACK, and so on. A new body lifts it with a golden flash.
- **FIGHT!** slams in when a match round begins, with a war horn, sparks and a shudder.
- **LEVEL UP** gets a gold moment of its own after the round's result.
- **Spawning in a match** throws a burst of embers at your feet.
- **More embers:** gold or ash behind VICTORY / DEFEAT, sparks off objective banners, and embers behind the class screen, across the travel screen and gently over the lobby.
- **TASKS badge:** it counted unfinished tasks in red, which read as "claim me", but tasks pay by themselves. It now shows a green **+N** for tasks finished since you last looked.
- **Leaderboards:**
  - A **RANKS** tile (a trophy) in the dock.
  - The lobby board has **VIEW ALL** and **FULL LEADERBOARD · TOP 100** buttons.
  - Rows end in "›", and the screen says up front that tapping a name opens a profile.
- **Profiles:**
  - Your card (top left) opens your profile and says VIEW PROFILE when you point at it.
  - Your profile has **CHANGE TITLE** and **LEADERBOARDS**.
  - The player you look at shows **[P] PROFILE** on their name tag.
- **Dock tooltips:** point at a tile and it says what's inside.
- **Class screen:** the hint said to change loadouts in ARMORY (it's LOADOUT); long descriptions end in "…" instead of being cut; the Mage card says MAGE ROBES.
- **Studio:** the new trophy icon is in Cosmetics ▸ Icons (Studio only). **Save the place.**

| File | Studio location | Type | Change |
|---|---|---|---|
| [DeathScreen.client.lua](StarterPlayerScripts/DeathScreen.client.lua) (new), [Celebrate.client.lua](StarterPlayerScripts/Celebrate.client.lua) (new) | StarterPlayer ▸ StarterPlayerScripts | LocalScript | the fall and the way back; FIGHT!, LEVEL UP, spawn embers |
| [UIFX.lua](ReplicatedStorage/UIFX.lua) | ReplicatedStorage ▸ UIFX | ModuleScript | embers, sparks, vignette, camera shake, fade-out; four new sounds |
| [CameraRig.client.lua](StarterCharacterScripts/CameraRig.client.lua) | StarterPlayer ▸ StarterCharacterScripts | LocalScript | only the death camera now (the screen is DeathScreen) |
| [LoadoutMenu.client.lua](StarterPlayerScripts/LoadoutMenu.client.lua) | StarterPlayer ▸ StarterPlayerScripts | LocalScript | waits for the fall, lifts the death screen; embers; the LOADOUT hint; MAGE ROBES |
| [RoundResult.client.lua](StarterPlayerScripts/RoundResult.client.lua), [Objectives.client.lua](StarterPlayerScripts/Objectives.client.lua), [TravelScreen.client.lua](StarterPlayerScripts/TravelScreen.client.lua) | StarterPlayer ▸ StarterPlayerScripts | LocalScript | embers and sparks |
| [HubMenu.client.lua](StarterPlayerScripts/HubMenu.client.lua) | StarterPlayer ▸ StarterPlayerScripts | LocalScript | RANKS tile, dock tooltips, tasks badge, leaderboard and profile entry points, lobby embers |
| [NameTags.client.lua](StarterPlayerScripts/NameTags.client.lua) | StarterPlayer ▸ StarterPlayerScripts | LocalScript | [P] PROFILE on the player you look at |
| [blender/ui_icons.py](../blender/ui_icons.py) | (tool) | Python | the trophy icon |
| [README.md](README.md), [CONTENT_GUIDE.md](CONTENT_GUIDE.md) | | doc | all of the above |

---

## Before that: first join, hoods that fit, team kill feed, the beta, a quicker menu

- **First join: no black screen.** The welcome cinematic was failing behind its black cover (a script loaded too late), so nothing showed until the 30-second fallback. Fixed. It also lets go of the screen if it ever fails again.
- **A loading screen from the first frame:** the game's name, embers and a sweeping bar. Arriving by teleport, the travel screen stays up until you have a body. The welcome film is louder too: bars slide in, embers drift, and the title slams down with a flash and a shake.
- **Hoods that fit.** A hood is now hollow and open at the front: the head sits inside with the face in its shadow, and nothing pokes through. Fixed on 15 head pieces: the four mage hoods, Shadowveil, Ranger, Marsh Wardens, the starter Gambeson coif, Road Levy, River Guard, Gilded Court, Corsair, Deathless, Berserker and the Wolf Pelt. New check tool: `blender/audit_heads.py`.
- **The kill feed shows team colours,** for players and bots alike. Your name is underlined, and rows you're in have a gold edge.
- **The beta:** everyone who plays before launch is a numbered **Beta Tester** and gets a title plus **Trailblazer**, a Mythic armor finish nobody else will ever have. The Founders' Forge and every drop after it are **TBD**: no dates until launch. When it launches, the founder window runs 30 days.
- **SHOP ▸ COLORS is gone.** Every armor colour is free now (finishes are the premium look), and hair and beards no longer exist.
- **🔒 LOCKED: SHOWN / HIDDEN** switch in the Loadout and the Armory, also in Settings and saved. It shows everything there is to get (the default) or only what you own, in every list at once.
- **The menu tour** says five classes, Mage included.
- **A quicker menu:**
  - Hidden tabs no longer pile up 3D previews (it went from 14 to 73 as you browsed; now it stays flat).
  - Loadout clicks and opening Pass, Loadout and Armory hitch about 60% less.
  - Mannequins and weapons are built once and copied after.
  - Previews and finish effects only animate on screen.
  - English readers skip automatic translation.
- **Studio:** the 15 rebaked head pieces are assembled. **Save the place.**

| File | Studio location | Type | Change |
|---|---|---|---|
| [ReplicatedFirst/Loading.client.lua](ReplicatedFirst/Loading.client.lua) (new), [default.project.json](../default.project.json) | ReplicatedFirst ▸ Loading | LocalScript | the first-frame loading screen; ReplicatedFirst synced |
| [Intro.client.lua](StarterPlayerScripts/Intro.client.lua), [TravelScreen.client.lua](StarterPlayerScripts/TravelScreen.client.lua) | StarterPlayer ▸ StarterPlayerScripts | LocalScript | the welcome fixed and louder; the travel screen holds till you're in |
| [Loadout/LoadoutServer.server.lua](ServerScriptService/Loadout/LoadoutServer.server.lua), [Loadout/Avatars.lua](ServerScriptService/Loadout/Avatars.lua) | ServerScriptService ▸ Loadout | Script / ModuleScript | a shorter wait for the avatar kit; re-dress only in the Courtyard |
| [Build/Armor.lua](ServerScriptService/Build/Armor.lua), [Build/Builder.lua](ServerScriptService/Build/Builder.lua) | ServerScriptService ▸ Build | ModuleScript | `openHood` / `skullcap`; the `"cowl"` shape; 15 head pieces |
| [blender/parts2mesh.py](../blender/parts2mesh.py), [blender/preview_armor.py](../blender/preview_armor.py), [blender/audit_heads.py](../blender/audit_heads.py) (new), [scripts/export_blueprints.lua](../scripts/export_blueprints.lua) | (tools) | Python / Lua | the cowl mesh; `--heads` close-ups; the clipping audit |
| [Scoreboard.server.lua](ServerScriptService/Scoreboard.server.lua), [Combat/CombatServer.lua](ServerScriptService/Combat/CombatServer.lua), [Scoreboard.client.lua](StarterPlayerScripts/Scoreboard.client.lua) | ServerScriptService · StarterPlayerScripts | Script / ModuleScript / LocalScript | team colours in the kill feed |
| [Catalog/Calendar.lua](ReplicatedStorage/Catalog/Calendar.lua), [Drops.lua](ReplicatedStorage/Drops.lua), [Catalog/ArmorFX.lua](ReplicatedStorage/Catalog/ArmorFX.lua), [Economy/Collection.lua](ServerScriptService/Economy/Collection.lua), [Loadout/Profile.lua](ServerScriptService/Loadout/Profile.lua) | ReplicatedStorage · ServerScriptService | ModuleScript | the Beta Tester gift; TBD drops; Trailblazer |
| [Catalog/Palette.lua](ReplicatedStorage/Catalog/Palette.lua) | ReplicatedStorage ▸ Catalog | ModuleScript | every colour free |
| [ClientSettings.lua](ReplicatedStorage/ClientSettings.lua), [HubMenu.client.lua](StarterPlayerScripts/HubMenu.client.lua), [MenuTour.client.lua](StarterPlayerScripts/MenuTour.client.lua) | ReplicatedStorage · StarterPlayerScripts | ModuleScript / LocalScript | the 🔒 switch; no COLORS tab; the tour's five classes; the menu's speed work |
| [PreviewRig.lua](ReplicatedStorage/PreviewRig.lua), [ArmorFX.client.lua](StarterPlayerScripts/ArmorFX.client.lua), [LoadoutMenu.client.lua](StarterPlayerScripts/LoadoutMenu.client.lua), [LocaleText.client.lua](StarterPlayerScripts/LocaleText.client.lua) (new) | ReplicatedStorage · StarterPlayerScripts | ModuleScript / LocalScript | dressed once per look; FX only on screen; no hidden spin; no translation work for English readers |
| [README.md](README.md), [CONTENT_GUIDE.md](CONTENT_GUIDE.md) | | doc | all of the above |

---

## Before that: nobody gets stuck in the tutorial

A report of players stuck in the tutorial. The whole newcomer path works in Studio: the welcome, all eight basic-training steps, graduation and spawning in the first battle. These are the ways a real player could still get stuck there, now fixed:

- **A step you can't manage** (the parry, say): after 75 seconds on a basic-training step, Sir Aldric waves you past it.
- **The last fight:** lose to the Squire in the ring twice and it counts anyway, and you're off to battle (before, you fought him again forever).
- **Find Your Feet on a controller:** the GOT IT button shows for controllers too, not only touch screens, so a control with no button can't hold you up.
- **The trip to the first battle failing on its way** (a live-server teleport hiccup): it's tried again twice, then sent to a fresh server, instead of leaving you in the yard with nothing to do. Any failed trip now says so ("try again from PLAY").

| File | Studio location | Type | Change |
|---|---|---|---|
| [Game/Training.lua](ServerScriptService/Game/Training.lua) | ServerScriptService ▸ Game ▸ Training | ModuleScript | `ASSIST` (75 s), `ASSIST_SPARS` (2) |
| [Training.client.lua](StarterPlayerScripts/Training.client.lua) | StarterPlayer ▸ StarterPlayerScripts ▸ Training | LocalScript | GOT IT for controllers |
| [Hub/HubServer.server.lua](ServerScriptService/Hub/HubServer.server.lua) | ServerScriptService ▸ Hub ▸ HubServer | Script | TeleportInitFailed: retried, then a fresh trip for a newcomer |
| [README.md](README.md) | | doc | the training yard |

---

## Before that: Mage robes and every mage cosmetic; Archer and Mage bots

- **Mage robes are their own category** (weight "Robe"): only a Mage wears them, and a Mage wears nothing else. Light classes no longer see the Apprentice Robes.
- **Seven new robe sets in the Arcana Crate**, a piece at a time: Druid, Necromancer, Pyromancer, Frost Witch, Archmage, Battlemage, and the Mythic Star Sage (a robe of glowing constellations under a crescent moon).
- **Finishes now show on robes.** On cloth, a finish recolours the robe and lights its trims. Four new cloth finishes: Spellwoven, Moonthread, Hexweave, Starweave.
- **34 weapon skins for the Mage:** 14 staffs, 10 grimoires and 10 wands. Skins now colour the orb, the wood and the brass fittings separately; Epic and up get auras, and each weapon has a Mythic.
- **Seven wand spell skins:** Pixie Dust, Firefly, Red Zap, Glass Dart, Will-o'-the-Wisp, Hellspark, Petal Storm. LOADOUT ▸ SPELLS ▸ LOOKS now lists the wand's spells too.
- **Archer and Mage bots.**
  - Archer: keeps its distance, draws, leads you and looses (a Champion goes for the head). Up close it draws its sword, then goes back to the bow at range.
  - Mage: in robes for its rank, it casts what fits, holds a spell charged until it has you, wards, and meditates when safe.
  - Where they appear: fill bots in matches (about 15% Archers, 10% Mages) and Horde (archers from wave 3, mages from wave 5).
  - In Studio, spawn them with `/bot Knight Archer` or `/bot Champion Mage`.
- **Fix (menu-wide overlap check):** the locked-class veil on the class cards is nearly opaque, so the stats no longer show through the lock ([HubMenu.client.lua](StarterPlayerScripts/HubMenu.client.lua), [LoadoutMenu.client.lua](StarterPlayerScripts/LoadoutMenu.client.lua)). Every other menu screen came back clean.
- **Studio:** the robe meshes are baked; run `blender/out/armor/assemble_armor.lua` in Studio (edit mode), then save. Until then the robes build from parts.

| File | Studio location | Type | Change |
|---|---|---|---|
| [Catalog/Weights.lua](ReplicatedStorage/Catalog/Weights.lua), [Catalog/Packs.lua](ReplicatedStorage/Catalog/Packs.lua), [GameConfig.lua](ReplicatedStorage/GameConfig.lua) | ReplicatedStorage | ModuleScript | the Robe weight; the Arcana and Apprentice packs; the Mage wears robes |
| [Build/Armor.lua](ServerScriptService/Build/Armor.lua) | ServerScriptService ▸ Build ▸ Armor | ModuleScript | seven robe blueprints |
| [ServerStorage/Armor/{Archmage,Battlemage,Necromancer,Pyromancer,FrostWitch,Druid,StarSage}](ServerStorage/Armor), [ApprenticeRobes](ServerStorage/Armor/ApprenticeRobes/Config.lua) | ServerStorage ▸ Armor | Model + Config | the new sets (new); the Apprentice is a Robe |
| [ArmorFX.lua](ReplicatedStorage/ArmorFX.lua), [Catalog/ArmorFX.lua](ReplicatedStorage/Catalog/ArmorFX.lua) | ReplicatedStorage | ModuleScript | finishes in a robe's cloth; four cloth finishes |
| [Catalog/Skins.lua](ReplicatedStorage/Catalog/Skins.lua) (from [scripts/skins_handmade.part](../scripts/skins_handmade.part)), [Dresser.lua](ReplicatedStorage/Dresser.lua), [Build/Weapons.lua](ServerScriptService/Build/Weapons.lua) | ReplicatedStorage · Build | ModuleScript | 34 staff / grimoire / wand skins; the "Metal" skin part |
| [Catalog/SpellSkins.lua](ReplicatedStorage/Catalog/SpellSkins.lua), [Catalog/Crates.lua](ReplicatedStorage/Catalog/Crates.lua) | ReplicatedStorage ▸ Catalog | ModuleScript | wand spell skins; the Arcana Crate's description |
| [Combat/Bots.lua](ServerScriptService/Combat/Bots.lua), [Combat/RangedServer.lua](ServerScriptService/Combat/RangedServer.lua), [Combat/MagicServer.lua](ServerScriptService/Combat/MagicServer.lua) | ServerScriptService ▸ Combat | ModuleScript | the archer's and the mage's minds; their weapons' `npc()` controllers |
| [Game/BotFill.lua](ServerScriptService/Game/BotFill.lua), [Game/Modes/Horde.lua](ServerScriptService/Game/Modes/Horde.lua), [Game/Training.lua](ServerScriptService/Game/Training.lua) | ServerScriptService ▸ Game | ModuleScript | archers and mages in matches and the horde; the Magister in robes |
| [Hub/Cheats.server.lua](ServerScriptService/Hub/Cheats.server.lua), [Admin/AdminServer.server.lua](ServerScriptService/Admin/AdminServer.server.lua) | ServerScriptService | Script | bots of a class |
| [HubMenu.client.lua](StarterPlayerScripts/HubMenu.client.lua) | StarterPlayer ▸ StarterPlayerScripts ▸ HubMenu | LocalScript | the Robe colour; the wand's spells in LOOKS |
| [README.md](README.md), [CONTENT_GUIDE.md](CONTENT_GUIDE.md) | | doc | robes, the mage's skins, the bots |

---

## Before that: the Archer and the Mage open at level 5, with teachers; a wand of little spells; spells you hold charged

- **Archer and Mage unlock at level 5.**
  - Before that the class is locked: veiled on the class screens, refused by the server, and your spawn falls back to the default class.
  - Reaching level 5 shows a toast in the fight, then an **"ARCHER & MAGE UNLOCKED!"** popup in the menu with a button that travels straight to that class's teacher in the Training Yard.
  - Picking either class before you've done its lessons offers them once.
- **Two new teachers in the Training Yard:**
  - **Wren the Bowmaster** on a new archery range: loose, full draw, between the eyes, the long shot, then a Squire charging at you.
  - **Magister Orrin** at a new arcane circle: first fire, three different spells, meditate, the ward, leaping lightning, the staff's melee form, then a charging Squire.
  - Their lessons dress you as the class.
  - Loadout and class changes in the yard now apply on the spot, like in the Courtyard.
- **Mage changes:**
  - **The wand is a sidearm with spells of its own**, two at a time, 3–10 mana each: Spark, Mote, Ember, Frost Dart, Zap, and Gust (throws everyone close away).
  - The Mage has 65 health and no blade; the wand is its only sidearm.
  - **Hold to cast:** a spell winds up, holds charged until you let go, and only then fires and costs mana. A quick tap fires as soon as it's ready.
  - A steadier walk with a magic weapon in hand: no wobbling staff.
- **Fixes:**
  - A staff and its melee form no longer both show on you; the staff hangs on your back.
  - The bow's and the spell bar's HUD no longer stay on screen after your body is replaced.
  - Only your class's weapons can be picked up: no bows or wands for a Knight, no swords for a Mage.
  - Meteor and Gust shoves now push properly.
  - The spell info line no longer breaks on fractional cooldowns.
- **Studio:** the training-yard map was rebuilt (new spots). **Save the place.**

| File | Studio location | Type | Change |
|---|---|---|---|
| [GameConfig.lua](ReplicatedStorage/GameConfig.lua), [Catalog/init.lua](ReplicatedStorage/Catalog/init.lua), [Catalog/Weapons.lua](ReplicatedStorage/Catalog/Weapons.lua) | ReplicatedStorage | ModuleScript | `unlock`, `tutor`; `Catalog.classOpen`; a magic class's sidearm is a wand |
| [Catalog/Drills.lua](ReplicatedStorage/Catalog/Drills.lua) | ReplicatedStorage ▸ Catalog ▸ Drills | ModuleScript | the Bowmaster's and the Magister's lessons, `tracks` |
| [MagicSpells.lua](ReplicatedStorage/MagicSpells.lua), [MagicFX.lua](ReplicatedStorage/MagicFX.lua) | ReplicatedStorage | ModuleScript | wand spells; the gust |
| [Combat/MagicClient.lua](ReplicatedStorage/Combat/MagicClient.lua), [Combat/RangedClient.lua](ReplicatedStorage/Combat/RangedClient.lua), [RigPose.lua](ReplicatedStorage/RigPose.lua) | ReplicatedStorage | ModuleScript | hold-to-cast, the wand's book; HUDs reset with the body; a steady Mage |
| [Combat/MagicServer.lua](ServerScriptService/Combat/MagicServer.lua), [Combat/RangedServer.lua](ServerScriptService/Combat/RangedServer.lua), [Combat/Pickup.lua](ServerScriptService/Combat/Pickup.lua) | ServerScriptService ▸ Combat | ModuleScript | charged casts, Release, a held push, CastTick; LastHitPower; pickups by class |
| [Game/Training.lua](ServerScriptService/Game/Training.lua), [Training.client.lua](StarterPlayerScripts/Training.client.lua) | ServerScriptService ▸ Game · StarterPlayerScripts | ModuleScript · LocalScript | three teachers, tracks, the new lessons and their menus |
| [Build/MapTraining.lua](ServerScriptService/Build/MapTraining.lua) | ServerScriptService ▸ Build ▸ MapTraining | ModuleScript | the archery range, the arcane circle |
| [Profile.lua](ServerScriptService/Loadout/Profile.lua), [LoadoutServer.server.lua](ServerScriptService/Loadout/LoadoutServer.server.lua), [Holsters.server.lua](ServerScriptService/Loadout/Holsters.server.lua) | ServerScriptService ▸ Loadout | ModuleScript · Script | locked classes, wand spells, `_G.Respawn`, the yard re-dress; holsters |
| [HubServer.server.lua](ServerScriptService/Hub/HubServer.server.lua), [Economy.lua](ServerScriptService/Economy/Economy.lua) | ServerScriptService | Script · ModuleScript | SetActive refused when locked, `UnlockSeen`, Play's track; the level-5 toast |
| [HubMenu.client.lua](StarterPlayerScripts/HubMenu.client.lua), [LoadoutMenu.client.lua](StarterPlayerScripts/LoadoutMenu.client.lua) | StarterPlayer ▸ StarterPlayerScripts | LocalScript | the pop-up, the locks, LOADOUT ▸ SPELLS ▸ WAND; the class cards |
| [Movement.client.lua](StarterCharacterScripts/Movement.client.lua) | StarterPlayer ▸ StarterCharacterScripts ▸ Movement | LocalScript | pickup prompts only for your class's weapons |
| [Tools/Wand/Config.lua](Tools/Wand/Config.lua) | ServerStorage ▸ Weapons ▸ Wand | ModuleScript | the wand: two wand spells |
| [README.md](README.md), [CONTENT_GUIDE.md](CONTENT_GUIDE.md) | | doc | all of the above |

---

## Before that: spell skins and the Arcana Crate — one Mage's Firebolt is a fireball, another's is a dragon

- **Twenty spell skins** in a new **Arcana Crate**, always in the shop. Looks only; every spell flies, hits and costs the same.
- **The skins, by rarity:**
  - **Rare** (recolours): Bluefire, Bloodlance, Red Storm (forked), Moonmotes, Golden Grace, Plague Fog, Quicksilver, Thornwall.
  - **Epic** (new shapes): Hellfire (a burning green skull), Starfall (spinning stars), Moonblade (a spinning crescent), Crystal Bloom (pink crystal novas), Shadowstep (a blink in black smoke), Witchmark.
  - **Legendary:** Dragonfire (a dragon's head of fire, roaring), Phoenix, Godstrike (golden lightning, and the sky strikes whoever it hits), Moonfall, Seraph's Kiss (a halo for whoever it heals).
  - **Mythic:** Wyrmfall, a winged dragon of violet fire diving out of the sky as your Meteor.
- **Wear them** per spell in LOADOUT ▸ SPELLS ▸ LOOKS, or straight from the crate or inspect screen. Everyone sees them, and your casting circle, spell bar and crosshair take their colours.
- **Copies of their own:** trade them, scrap them, see them in the INVENTORY (a SPELLS filter), with pictures on every card. The admin panel can give them, and "unlock everything" includes them (it also gains a FINISH kind).
- **Spell bar glyphs:** Meteor's and Miasma's now render (they showed as a droplet and a grey box).

| File | Studio location | Type | Change |
|---|---|---|---|
| [Catalog/SpellSkins.lua](ReplicatedStorage/Catalog/SpellSkins.lua) | ReplicatedStorage ▸ Catalog ▸ SpellSkins | ModuleScript | the skins (new) |
| [Catalog/init.lua](ReplicatedStorage/Catalog/init.lua), [Catalog/Crates.lua](ReplicatedStorage/Catalog/Crates.lua), [Catalog/Calendar.lua](ReplicatedStorage/Catalog/Calendar.lua), [CrateModels.lua](ReplicatedStorage/CrateModels.lua) | ReplicatedStorage | ModuleScript | `SPELLSKINS`, `spellSkinsFor`, crate items; the Arcana Crate, always on; its look (a staff emblem) |
| [MagicFX.lua](ReplicatedStorage/MagicFX.lua) | ReplicatedStorage ▸ MagicFX | ModuleScript | star, crescent, wyrm shapes; spinning; any shape falls as a meteor; thick, forked, sky-struck lightning; halos, smoke, crystal; the caster's skin on the casting circle; `MagicFX.preview` |
| [MagicSpells.lua](ReplicatedStorage/MagicSpells.lua), [Combat/MagicClient.lua](ReplicatedStorage/Combat/MagicClient.lua) | ReplicatedStorage | ModuleScript | glyphs; your skins' colours on the bar and crosshair |
| [Economy.lua](ServerScriptService/Economy/Economy.lua), [Collection.lua](ServerScriptService/Economy/Collection.lua), [Profile.lua](ServerScriptService/Loadout/Profile.lua) | ServerScriptService | ModuleScript | rolled and given as copies ("spell:"); tradable; kept per spell |
| [AdminServer.server.lua](ServerScriptService/Admin/AdminServer.server.lua), [AdminPanel.client.lua](StarterPlayerScripts/AdminPanel.client.lua) | ServerScriptService · StarterPlayerScripts | Script · LocalScript | give / unlock spell skins (and finishes) |
| [HubMenu.client.lua](StarterPlayerScripts/HubMenu.client.lua) | StarterPlayer ▸ StarterPlayerScripts ▸ HubMenu | LocalScript | pictures, crate page, reveal, inspect, inventory, trade, LOADOUT ▸ SPELLS ▸ LOOKS |
| [README.md](README.md), [CONTENT_GUIDE.md](CONTENT_GUIDE.md) | | doc | spell skins |

---

## Before that: Horde never leaves you behind, the break makes you whole, no bodies left standing

- **Horde auto-spawn:** when the break between waves runs out, anyone still on the class screen goes in automatically as the class they picked. Nobody gets locked out of a wave for not pressing SPAWN, and the class screen says so during the break.
- **Whole again between waves:** everyone standing gets full health, stamina and mana; burns and frost are cleared. If you lost a limb, are bleeding or had your weapon knocked away, you're rebuilt where you stand with every limb, your armor and your weapons.
- **No bodies left standing:** a player who left (or was rebuilt) while alive after losing a limb used to leave a standing copy of themselves behind; now nothing is left. A body still upright when its owner leaves is laid down flat.

| File | Studio location | Type | Change |
|---|---|---|---|
| [Game/Modes/Horde.lua](ServerScriptService/Game/Modes/Horde.lua) | ServerScriptService ▸ Game ▸ Modes ▸ Horde | ModuleScript | auto-spawn at the wave; made whole at the break |
| [LoadoutServer.server.lua](ServerScriptService/Loadout/LoadoutServer.server.lua) | ServerScriptService ▸ Loadout ▸ LoadoutServer | Script | the class you're on ("Pick"); `_G.AutoSpawn`; `_G.MakeWhole` (a rebuild in place) |
| [LoadoutMenu.client.lua](StarterPlayerScripts/LoadoutMenu.client.lua) | StarterPlayer ▸ StarterPlayerScripts ▸ LoadoutMenu | LocalScript | tells the server your class card; "or you go in as …" |
| [Combat/Corpses.lua](ServerScriptService/Combat/Corpses.lua) | ServerScriptService ▸ Combat ▸ Corpses | ModuleScript | only a dead body is laid out; a standing one is laid flat |
| [README.md](README.md) | | doc | Horde |

---

## Before that: the Mage, done properly — an arsenal, meditation, the grimoire and the wand, a staff that fights

- **Mana comes back only by meditating:** hold R (controller Y) standing still. Casting slows you to a crawl (20%) with no sprint. Mages stand behind the line, then have to stop.
- **Pick your arsenal** in the loadout (LOADOUT ▸ SPELLS). Twelve spells, more unlocking as you level: Firebolt, Ice Lance, Chain Lightning, Arcane Missiles, Meteor, Miasma, Frost Nova, Mend, Haste, Barrier, Hex, Blink.
- **Three weapons with real tradeoffs:**
  - **Arcane Staff:** four spells, full power, a Ward. Press H for its melee self, which fights with every quarterstaff swing.
  - **Grimoire:** five spells; casts faster and cheaper; no ward, no melee, softer hits.
  - **Wand:** a sidearm that sparks for free.
- **The staff stays planted** on the ground and rises slowly as you cast, ward or meditate, then sinks back. The grimoire is held open at your waist. Roblox's default stiff tool arm is gone.
- **A crosshair that knows each spell:** someone to hit, the ground, an ally, or nothing. It turns red out of reach.
- **New looks for everything:** meteor warning rings and falls, a green miasma, barrier shells, hex marks over the head, haste wind, a blink streak, a meditation circle.
- **Fix:** the lobby's right column no longer runs under the PLAY area.

| File | Studio location | Type | Change |
|---|---|---|---|
| [MagicSpells.lua](ReplicatedStorage/MagicSpells.lua) | ReplicatedStorage ▸ MagicSpells | ModuleScript | twelve spells, meditation, unlocks |
| [Combat/MagicServer.lua](ServerScriptService/Combat/MagicServer.lua), [Combat/Ward.lua](ServerScriptService/Combat/Ward.lua) | ServerScriptService ▸ Combat | ModuleScript | every spell kind, meditation, weapon tradeoffs; barriers and hexes |
| [Combat/MagicClient.lua](ReplicatedStorage/Combat/MagicClient.lua), [MagicFX.lua](ReplicatedStorage/MagicFX.lua) | ReplicatedStorage | ModuleScript | the arsenal bar, meditation, the lift, the crosshair; every look; holding a staff upright |
| [RigPose.lua](ReplicatedStorage/RigPose.lua) | ReplicatedStorage ▸ RigPose | ModuleScript | staff, tome and wand stances |
| [Tools/Staff](Tools/Staff), [Tools/Tome](Tools/Tome), [Tools/Wand](Tools/Wand), [Tools/StaffMelee](Tools/StaffMelee) | ServerStorage ▸ Weapons | Tool | the weapons (Tome, Wand, StaffMelee new) |
| [Build/Weapons.lua](ServerScriptService/Build/Weapons.lua) | ServerScriptService ▸ Build ▸ Weapons | ModuleScript | the grimoire, the wand, the staff's melee body |
| [Catalog/Weapons.lua](ReplicatedStorage/Catalog/Weapons.lua), [Catalog/init.lua](ReplicatedStorage/Catalog/init.lua), [GameConfig.lua](ReplicatedStorage/GameConfig.lua) | ReplicatedStorage | ModuleScript | the weapons; `Catalog.SPELLS`; a magic sidearm; the Mage's wand |
| [Profile.lua](ServerScriptService/Loadout/Profile.lua), [LoadoutServer.server.lua](ServerScriptService/Loadout/LoadoutServer.server.lua) | ServerScriptService ▸ Loadout | ModuleScript · Script | the arsenal checked and given; the twin; StanceSwap |
| [StanceSwap.client.lua](StarterPlayerScripts/StanceSwap.client.lua) | StarterPlayer ▸ StarterPlayerScripts ▸ StanceSwap | LocalScript | magic / melee (new) |
| [Hotbar.client.lua](StarterPlayerScripts/Hotbar.client.lua), [ClientSettings.lua](ReplicatedStorage/ClientSettings.lua), [InputHints.lua](ReplicatedStorage/InputHints.lua) | StarterPlayerScripts · ReplicatedStorage | LocalScript · ModuleScript | twins on the bar; the Stance bind |
| [HubMenu.client.lua](StarterPlayerScripts/HubMenu.client.lua) | StarterPlayer ▸ StarterPlayerScripts ▸ HubMenu | LocalScript | LOADOUT ▸ SPELLS; the lobby's right column |

---

## Before that: you under the armor, emotes that behave, a helmet you can pick back up

- **You are your own avatar under the armor.** Your real Roblox hair, face and skin colour show wherever your helmet doesn't cover, in battle and on every menu mannequin. Face accessories (beards, glasses) come along; hats and body accessories stay off, since armor goes there. Bots and NPCs keep the made-up looks.
- **The Wardrobe is gone.** Tap your player card (top left) to pick a title.
- **Emotes fixed:**
  - Looking down no longer bends emotes: the arms don't rotate backwards and the Blade Toss goes straight up.
  - Anything else you do ends an emote: drawing, putting away or swapping a weapon, jumping, getting hit, attacking, blocking, or walking off a whole-body emote. No more sword left floating.
  - Weapon emotes (Flourish, Blade Toss, Windmill, Champion, Thunderlord) need a weapon in hand; the Helmet Toss needs a helmet on. The wheel tells you why.
- **The Helmet Toss:** when the helmet comes off, your hair and face show. Thrown, it stays on the ground for a minute. Walk up and put it back on (E), or anyone without a helmet can wear it. While it's off, your head has no armor.
- Helmet cards in the loadout show their set, like the other pieces.

| File | Studio location | Type | Change |
|---|---|---|---|
| [Loadout/Avatars.lua](ServerScriptService/Loadout/Avatars.lua) | ServerScriptService ▸ Loadout ▸ Avatars | ModuleScript | each player's avatar kit (new) |
| [Dresser.lua](ReplicatedStorage/Dresser.lua) | ReplicatedStorage ▸ Dresser | ModuleScript | the avatar on the body; what a helmet hides stays on, hidden; `setHelmet`, `wearHelmet`, `helmetOn` |
| [LoadoutServer.server.lua](ServerScriptService/Loadout/LoadoutServer.server.lua) | ServerScriptService ▸ Loadout ▸ LoadoutServer | Script | dresses players as their avatar |
| [Emotes.lua](ReplicatedStorage/Emotes.lua), [RigPose.lua](ReplicatedStorage/RigPose.lua), [CameraRig.client.lua](StarterCharacterScripts/CameraRig.client.lua), [RigReplicator.client.lua](StarterPlayerScripts/RigReplicator.client.lua) | ReplicatedStorage · StarterCharacterScripts · StarterPlayerScripts | ModuleScript · LocalScript | `RigPose.calm`; emotes end on any action; the toss in the upright frame |
| [Catalog/Emotes.lua](ReplicatedStorage/Catalog/Emotes.lua), [Catalog/init.lua](ReplicatedStorage/Catalog/init.lua) | ReplicatedStorage ▸ Catalog | ModuleScript | `needs`, `Catalog.emoteBlock` |
| [Cosmetics.server.lua](ServerScriptService/Hub/Cosmetics.server.lua), [Cosmetics.client.lua](StarterPlayerScripts/Cosmetics.client.lua) | ServerScriptService ▸ Hub · StarterPlayerScripts | Script · LocalScript | the Helmet Toss pickup; emote checks |
| [Armor.lua](ServerScriptService/Loadout/Armor.lua), [Injury.lua](ServerScriptService/Combat/Injury.lua) | ServerScriptService | ModuleScript | a thrown helmet doesn't protect |
| [ArmorFX.client.lua](StarterPlayerScripts/ArmorFX.client.lua) | StarterPlayer ▸ StarterPlayerScripts ▸ ArmorFX | LocalScript | leaves a thrown-off helmet hidden |
| [HubMenu.client.lua](StarterPlayerScripts/HubMenu.client.lua) | StarterPlayer ▸ StarterPlayerScripts ▸ HubMenu | LocalScript | no wardrobe; title picker on the player card; mannequins as your avatar; helmet card subtitles |

---

## Before that: the Mage, the War Chest, armor in every drop crate, finishes that come alive

- **The Mage, a new class.** An Arcane Staff, a sidearm, and robes instead of armor: 80 health, no protection, a **mana bar** beside the stamina.
  - **Four spells** (scroll or RB/LB to pick; Swing casts):
    - **Firebolt:** a dodgeable fireball that burns and splashes.
    - **Chain Lightning:** hits who you aim at and leaps to one more.
    - **Frost Nova:** a ring of ice round you that slows everyone close.
    - **Mend:** heals you or the ally you aim at.
  - **The Ward** (Block): blows from the front cost mana instead of health until the mana runs out.
  - **Balance:** every cast takes a moment (magic circle, slower walk), and a hit breaks it.
  - **The look:** spells look the same to everyone (bolts, lightning, ice, healing light, flames, frost); the staff stands upright and tips forward to cast.
  - **Apprentice Robes**, the free starter: a floppy wizard hat, a long robe in your colours, gold stars.
- **The War Chest**, a second armor crate that's always in the shop. Six sets you can only find there, a piece at a time, each a tradable copy:
  - **Ranger** (Light, Rare): a forest hood with a red feather, a quiver of arrows.
  - **Berserker** (Light, Epic): a whole bear for a hood, its paws down your chest.
  - **Corsair** (Medium, Epic): a black tricorn with a plume, a captain's coat with gold epaulettes.
  - **Deathless** (Medium, Legendary): a skull helm with green fire in the eyes, a ribcage, skulls on the shoulders.
  - **Lionheart** (Heavy, Legendary): a crowned great helm with a lion's mane.
  - **Obsidian** (Heavy, Mythic): black volcanic plate with molten seams and a crown of shards.
- **Five new finishes in the War Chest:** Moonsilver, Oxblood, Bloodrage, Gravelight, Lionsmane.
- **Armor in every drop crate:** one finish each, in the crate's colours: Bonewhite, Hollowfire, Slagforged, Thornbound, Runecarved, Rimeglass, Hollyberry, Brineshell, Regalia.
- **Crate sets keep their own colours:** Seraph stays white-gold, Obsidian black, Dragonscale red. Your paint no longer turns them grey; team colours still apply in team modes.
- **Finishes are alive now,** in the world and on menu mannequins:
  - **Every finish:** the plates glint, and a kill flares it (a ring, a burst of its aura, a flash of the trims).
  - **Epic and up:** footprints in its element (frost, fire, sparks, petals, smoke, stars).
  - **Legendary and up:** light streaks off your arms and legs when you sprint or swing, and a surge ring every few seconds.
  - **Mythic:** three motes circle you and a rim of light outlines you. A kill throws up a pillar of light.
- **Crate cards** in the shop say what's inside (ARMOR · SKINS · FINISHES · KILL FX · EMOTES).
- **Fixes:**
  - A crate's strip labelled armor and finishes "EMOTE" and showed them locked even when owned.
  - Admin "unlock everything" now also gives finishes, premium hair, eye colours and face parts.

| File | Studio location | Type | Change |
|---|---|---|---|
| [MagicSpells.lua](ReplicatedStorage/MagicSpells.lua), [MagicFX.lua](ReplicatedStorage/MagicFX.lua) | ReplicatedStorage | ModuleScript | the spells; what magic looks like (new) |
| [Combat/MagicClient.lua](ReplicatedStorage/Combat/MagicClient.lua) | ReplicatedStorage ▸ Combat ▸ MagicClient | ModuleScript | casting, picking, the ward, the spell and mana bar (new) |
| [Combat/MagicServer.lua](ServerScriptService/Combat/MagicServer.lua), [Combat/Ward.lua](ServerScriptService/Combat/Ward.lua) | ServerScriptService ▸ Combat | ModuleScript | casts timed, paid and resolved; the ward (new) |
| [Tools/Staff](Tools/Staff) | ServerStorage ▸ Weapons ▸ Staff | Tool (Script · LocalScript · ModuleScript) | the Arcane Staff (new) |
| [MagicFX.client.lua](StarterPlayerScripts/MagicFX.client.lua) | StarterPlayer ▸ StarterPlayerScripts ▸ MagicFX | LocalScript | starts MagicFX (new) |
| [GameConfig.lua](ReplicatedStorage/GameConfig.lua), [Catalog/Weapons.lua](ReplicatedStorage/Catalog/Weapons.lua), [Catalog/init.lua](ReplicatedStorage/Catalog/init.lua) | ReplicatedStorage | ModuleScript | the Mage class; the staff; magic weapon fits; class starter sets |
| [RigPose.lua](ReplicatedStorage/RigPose.lua), [CameraRig.client.lua](StarterCharacterScripts/CameraRig.client.lua), [RangedFX.client.lua](StarterPlayerScripts/RangedFX.client.lua) | ReplicatedStorage · StarterCharacterScripts · StarterPlayerScripts | ModuleScript · LocalScript | the staff stance |
| [CombatServer.lua](ServerScriptService/Combat/CombatServer.lua), [RangedServer.lua](ServerScriptService/Combat/RangedServer.lua) | ServerScriptService ▸ Combat | ModuleScript | blades and arrows ask the ward |
| [LoadoutServer.server.lua](ServerScriptService/Loadout/LoadoutServer.server.lua), [Profile.lua](ServerScriptService/Loadout/Profile.lua) | ServerScriptService ▸ Loadout | Script · ModuleScript | mana at spawn (`classStats`), the Mage's robes by default |
| [Build/Weapons.lua](ServerScriptService/Build/Weapons.lua) | ServerScriptService ▸ Build ▸ Weapons | ModuleScript | the staff's body |
| [ServerStorage/Armor/ApprenticeRobes](ServerStorage/Armor/ApprenticeRobes) | ServerStorage ▸ Armor ▸ ApprenticeRobes | Model + ModuleScript | the robes (new) |
| [ArmorFX.client.lua](StarterPlayerScripts/ArmorFX.client.lua) | StarterPlayer ▸ StarterPlayerScripts ▸ ArmorFX | LocalScript | glints, kill flares, footprints, streaks, surges, motes, rims |
| [ArmorFX.lua](ReplicatedStorage/ArmorFX.lua) | ReplicatedStorage ▸ ArmorFX | ModuleScript | tags the wearer (`FinishWorn`, tier, accent, aura); aura rate by tier |
| [Catalog/ArmorFX.lua](ReplicatedStorage/Catalog/ArmorFX.lua) | ReplicatedStorage ▸ Catalog ▸ ArmorFX | ModuleScript | 14 new finishes |
| [Catalog/Crates.lua](ReplicatedStorage/Catalog/Crates.lua), [Catalog/Calendar.lua](ReplicatedStorage/Catalog/Calendar.lua), [Catalog/Packs.lua](ReplicatedStorage/Catalog/Packs.lua) | ReplicatedStorage ▸ Catalog | ModuleScript | the War Chest; drop crates name their finish |
| [Catalog/init.lua](ReplicatedStorage/Catalog/init.lua), [Dresser.lua](ReplicatedStorage/Dresser.lua) | ReplicatedStorage | ModuleScript | a set's own `Colors` |
| [CrateModels.lua](ReplicatedStorage/CrateModels.lua) | ReplicatedStorage ▸ CrateModels | ModuleScript | the War Chest's look, a helm emblem |
| [ServerStorage/Armor/Berserker…Obsidian](ServerStorage/Armor) (6 new), and the four Forge sets | ServerStorage ▸ Armor ▸ &lt;Set&gt; ▸ Config | ModuleScript | the new sets; `Colors` |
| [Build/Armor.lua](ServerScriptService/Build/Armor.lua) | ServerScriptService ▸ Build ▸ Armor | ModuleScript | the six sets' blueprints |
| [HubMenu.client.lua](StarterPlayerScripts/HubMenu.client.lua) | StarterPlayer ▸ StarterPlayerScripts ▸ HubMenu | LocalScript | crate card contents; the strip's labels and ownership |
| [AdminServer.server.lua](ServerScriptService/Admin/AdminServer.server.lua) | ServerScriptService ▸ Admin ▸ AdminServer | Script | unlock everything covers finishes and premium looks |

**Studio-only (save the place):** the meshes of the six War Chest sets and the Apprentice Robes (`assemble_armor.lua`).

---

## Before that: build your own face, eleven new hairstyles, no helmet, the Helmet Toss

- **Faces, redrawn and built in layers:**
  - eyes: 11 shapes, coloured irises with highlights, 10 eye colours
  - brows in your hair colour, 12 mouths
  - scars and marks: freckles, blush, stitches, a bandage, an eyepatch
  - war paint in seven colours
  - The old faces became presets, plus new ones: Happy, Cheeky, Warpaint. Every card in the wardrobe shows your face with that option.
- **Eleven new hairstyles** with real shape: spiky, swoop, curtains, ponytail, twin tails, man bun, afro and mohawk. Long & flowing, viking braids and dreadlocks are premium. Premium hairstyles, eye colours and face parts are bought once with Crowns.
- **No helmet** (LOADOUT ▸ HELMET): your face and hair on show in battle. A bare head has no armor, so it takes full damage.
- **The Helmet Toss** (an Epic emote, Relic Crate): pull it off, wind up and throw it. It flies for real, clangs off walls and stings whoever it hits, then a spare appears on your head.
- The four Forge Crate sets now have proper meshes, like every other set.

| File | Studio location | Type | Change |
|---|---|---|---|
| [Catalog/Body.lua](ReplicatedStorage/Catalog/Body.lua), [Catalog/init.lua](ReplicatedStorage/Catalog/init.lua) | ReplicatedStorage ▸ Catalog | ModuleScript | face parts, colours, presets, `Catalog.faceLayers`; the new hair |
| [Dresser.lua](ReplicatedStorage/Dresser.lua) | ReplicatedStorage ▸ Dresser | ModuleScript | the face as stacked decals; `noHelm` |
| [Profile.lua](ServerScriptService/Loadout/Profile.lua), [Economy.lua](ServerScriptService/Economy/Economy.lua), [AdminServer.server.lua](ServerScriptService/Admin/AdminServer.server.lua) | ServerScriptService | ModuleScript · Script | face / hair validation and buys; `noHelm`; armor rewards and gifts |
| [HubMenu.client.lua](StarterPlayerScripts/HubMenu.client.lua) | StarterPlayer ▸ StarterPlayerScripts ▸ HubMenu | LocalScript | the face builder (`HX.faceDisc`), premium hair, "No helmet" |
| [Build/Body.lua](ServerScriptService/Build/Body.lua) | ServerScriptService ▸ Build ▸ Body | ModuleScript | the new hair blueprints |
| [Emotes.lua](ReplicatedStorage/Emotes.lua), [EmoteFX.lua](ReplicatedStorage/EmoteFX.lua), [Catalog/Emotes.lua](ReplicatedStorage/Catalog/Emotes.lua), [Cosmetics.server.lua](ServerScriptService/Hub/Cosmetics.server.lua) | ReplicatedStorage · ServerScriptService ▸ Hub | ModuleScript · Script | the Helmet Toss |
| [blender/face_parts.py](../blender/face_parts.py), [blender/face_preview.py](../blender/face_preview.py) | (repo) | Python | the face layers' art and a preview |

**Studio-only (save the place):**
- 67 Decals in `ReplicatedStorage ▸ Cosmetics ▸ Body ▸ FaceParts`
- the meshes of the new hair and the four Forge sets (`assemble_armor.lua`)

---

## Before that: armor is collectable — the Forge Crate, finishes, four crate-only sets

- **Armor finishes** (13, Rare to Mythic): they recolour your plates, light your trims (breathing, crackling or walking the rainbow) and wrap you in an aura: embers, frost, leaves, petals, storm, smoke, holy light, stars, fire. They go on any set, one per class (LOADOUT › FINISH).
- **The Forge Crate** (always in rotation) drops finishes and **four sets you can only find there**, one piece at a time, each with its own finish:
  - **Dragonscale** (Heavy): skull helm, burning eyes, horns, scales.
  - **Frostwarden** (Medium): a crown of icicles and furs.
  - **Shadowveil** (Light): a hood, a mask, two glowing eyes, runes.
  - **Seraph** (Medium, Mythic): a halo, a winged helm and great wings of light.
- **Tradeable:** everything out of it is a copy of its own. Trade it, scrap it, collect the set.
- Armor shows on a mannequin everywhere: the crate's stage and reel, inspect, the inventory (new FINISHES filter), trade cards and try-on.
- The shop never sells a crate piece. Looks only: stats still come from the weight.

| File | Studio location | Type | Change |
|---|---|---|---|
| [Catalog/ArmorFX.lua](ReplicatedStorage/Catalog/ArmorFX.lua) | ReplicatedStorage ▸ Catalog ▸ ArmorFX | ModuleScript | **new**: the finishes |
| [ArmorFX.lua](ReplicatedStorage/ArmorFX.lua) | ReplicatedStorage ▸ ArmorFX | ModuleScript | **new**: puts a finish on dressed armor |
| [ArmorFX.client.lua](StarterPlayerScripts/ArmorFX.client.lua) | StarterPlayer ▸ StarterPlayerScripts ▸ ArmorFX | LocalScript | **new**: glowing trims breathe / crackle / cycle |
| [ServerStorage/Armor/Dragonscale · Frostwarden · Shadowveil · Seraph](ServerStorage/Armor) | ServerStorage ▸ Armor | Model + Config | **new** crate-only sets |
| [Build/Armor.lua](ServerScriptService/Build/Armor.lua) | ServerScriptService ▸ Build ▸ Armor | ModuleScript | their blueprints |
| [Catalog/init.lua](ReplicatedStorage/Catalog/init.lua), [Crates.lua](ReplicatedStorage/Catalog/Crates.lua), [Calendar.lua](ReplicatedStorage/Catalog/Calendar.lua), [Packs.lua](ReplicatedStorage/Catalog/Packs.lua) | ReplicatedStorage ▸ Catalog | ModuleScript | the Forge Crate, crate pieces and finishes in crates, never free |
| [Dresser.lua](ReplicatedStorage/Dresser.lua), [SkinFX.lua](ReplicatedStorage/SkinFX.lua), [CrateModels.lua](ReplicatedStorage/CrateModels.lua) | ReplicatedStorage | ModuleScript | the finish after the paint; shared auras; the Forge's chest |
| [Profile.lua](ServerScriptService/Loadout/Profile.lua), [Economy.lua](ServerScriptService/Economy/Economy.lua), [Collection.lua](ServerScriptService/Economy/Collection.lua) | ServerScriptService | ModuleScript | `armorFx` per class; armor copies out of crates, tradable, scrappable; never bought |
| [HubMenu.client.lua](StarterPlayerScripts/HubMenu.client.lua) | StarterPlayer ▸ StarterPlayerScripts ▸ HubMenu | LocalScript | FINISH picker, armor on stages / thumbs / inspect / inventory / trade |

---

## Before that: no more bare dummy in the previews

- **Wardrobe:** you stand in your active class's armor with only the helmet off, so the face and hair you're editing show (WITH HELMET still puts it on).
- **Every little preview window** (kill effects, emotes, the inventory, inspect) shows you as you are: your active class's armor and look, not a bare body. The dressed figure is built once per look and copied, so a screen full of looping thumbnails stays cheap.

| File | Studio location | Type | Change |
|---|---|---|---|
| [PreviewRig.lua](ReplicatedStorage/PreviewRig.lua) | ReplicatedStorage ▸ PreviewRig | ModuleScript | `helmet = false`: the armor without its helmet |
| [HubMenu.client.lua](StarterPlayerScripts/HubMenu.client.lua) | StarterPlayer ▸ StarterPlayerScripts ▸ HubMenu | LocalScript | previews dressed (cached); the wardrobe's helmet off |

---

## Before that: emotes, 10× — the rarer the cooler, and two Mythics

- **Every emote moves with weight now:** a small move the other way first, a hair past the pose and back, a held beat, a follow-through. The Bow sweeps a hand out first, the Cheer dips and pumps, the Kneel drops heavily, the Laugh throws the head back and slaps the knee, the Jig twirls and leaps, the War Cry gathers in and roars, the Windmill lifts off, the Champion raises the blade and drives it into the ground.
- **The rarer, the more it does (EmoteFX):**
  - Commons glint, puff dust or throw confetti.
  - Rares leave trails and kick up dust and embers.
  - Epics send shockwaves, music notes and a war horn.
  - Legendaries raise a whirlwind or a pillar of light.
- **Two Mythic emotes** in the Relic Crate:
  - **Thunderlord:** a storm gathers, three bolts strike your raised blade, then you drive it into the ground in a blast.
  - **Ascension:** you rise into the air on wings of light, with a halo and a choir.
- Effects play for everyone in step, and **the menu's previews show them** (inspect any emote).
- **Fix:** a crate's lid opens up instead of sinking into the box (the gallery hover and the burst).

| File | Studio location | Type | Change |
|---|---|---|---|
| [EmoteFX.lua](ReplicatedStorage/EmoteFX.lua) | ReplicatedStorage ▸ EmoteFX | ModuleScript | **new**: emote effects |
| [Emotes.lua](ReplicatedStorage/Emotes.lua) | ReplicatedStorage ▸ Emotes | ModuleScript | reworked motions, Thunderlord, Ascension, `Emotes.elapsed` |
| [Catalog/Emotes.lua](ReplicatedStorage/Catalog/Emotes.lua) | ReplicatedStorage ▸ Catalog ▸ Emotes | ModuleScript | the two Mythics |
| [Cosmetics.client.lua](StarterPlayerScripts/Cosmetics.client.lua) | StarterPlayer ▸ StarterPlayerScripts ▸ Cosmetics | LocalScript | starts the effects with every emote |
| [HubMenu.client.lua](StarterPlayerScripts/HubMenu.client.lua) | StarterPlayer ▸ StarterPlayerScripts ▸ HubMenu | LocalScript | previews play the effects; a wider stage |
| [CrateModels.lua](ReplicatedStorage/CrateModels.lua) | ReplicatedStorage ▸ CrateModels | ModuleScript | the lid opens the right way |

---

## Before that: phones and controllers, PETS, 3D crates, sounds that behave, swings that cut through

- **Phones:** the whole menu is bigger on a phone.
  - The dock moves to two columns on the left.
  - Screens scroll, with a "more below" chip until you do.
  - The egg shop, inventory and crate gallery fit the screen.
  - Pop-ups shrink to fit.
  - New touch buttons: EMOTE, VIEW, CROUCH and SCORES.
- **Controllers:** full Xbox / PlayStation support.
  - Triggers attack (aim with the right stick), bumpers stab and overhead, face buttons move you, the D-pad does emotes, crouch and weapons.
  - VIEW opens the menu (hold it for the scoreboard), and a cursor appears in every menu.
  - Every hint names your button (keyboard, controller or touch), including the tutorial.
- **PETS** replaces HATCHERY, with three tabs:
  - EGG SHOP: big egg cards with BUY and WHAT'S INSIDE. A bought egg goes straight into a nest.
  - MY NESTS and MY PETS. No more scrolling to find the shelf.
- **Crates are 3D chests:**
  - A gallery to pick one.
  - Its chest turns on its page.
  - Opening it, the chest thumps down, shakes and bursts open before the reel.
- **Own icons** for TRADE (two arrows round a coin and a gem) and INVENTORY (a satchel).
- **Weapon sounds:** swing sounds only play for real attacks, never from a weapon on your hip or back or from turning. The hum only plays from a weapon in your hands, and you hear your own in third person.
- **Wall hits:** wood, grass, marble, ice and the rest use the library sounds. An old folder was drowning them out. Marble rings, ice crackles.
- **Swings cut through:** a kill no longer freezes and resets the swing. The blade bites and carries on, and every hit lets the swing finish.

| File | Studio location | Type | Change |
|---|---|---|---|
| [HubMenu.client.lua](StarterPlayerScripts/HubMenu.client.lua) | StarterPlayer ▸ StarterPlayerScripts ▸ HubMenu | LocalScript | phone layout (`LAYOUT`, `HX.fitScreen`), PETS tabs + egg shop, crate gallery / burst (`HX.crateView`, `HX.crateGallery`, `HX.crateBurst`), new icons |
| [GamepadControls.client.lua](StarterPlayerScripts/GamepadControls.client.lua) | StarterPlayer ▸ StarterPlayerScripts ▸ GamepadControls | LocalScript | **new**: controllers |
| [InputHints.lua](ReplicatedStorage/InputHints.lua) | ReplicatedStorage ▸ InputHints | ModuleScript | **new**: control names per device, the controller layout |
| [CrateModels.lua](ReplicatedStorage/CrateModels.lua) | ReplicatedStorage ▸ CrateModels | ModuleScript | **new**: 3D chests |
| [TouchControls.client.lua](StarterPlayerScripts/TouchControls.client.lua) | StarterPlayer ▸ StarterPlayerScripts | LocalScript | EMOTE, VIEW, CROUCH, SCORES |
| [Cosmetics.client.lua](StarterPlayerScripts/Cosmetics.client.lua), [Scoreboard.client.lua](StarterPlayerScripts/Scoreboard.client.lua), [CameraRig.client.lua](StarterCharacterScripts/CameraRig.client.lua) | StarterPlayerScripts · StarterCharacterScripts | LocalScript | the action bus: emote wheel, board, view, crouch |
| [Training.client.lua](StarterPlayerScripts/Training.client.lua), [Intro.client.lua](StarterPlayerScripts/Intro.client.lua), [MenuTour.client.lua](StarterPlayerScripts/MenuTour.client.lua), [TravelScreen.client.lua](StarterPlayerScripts/TravelScreen.client.lua), [LoadoutMenu.client.lua](StarterPlayerScripts/LoadoutMenu.client.lua) | StarterPlayer ▸ StarterPlayerScripts | LocalScript | hints from InputHints |
| [SkinFX.client.lua](StarterPlayerScripts/SkinFX.client.lua) | StarterPlayer ▸ StarterPlayerScripts ▸ SkinFX | LocalScript | sounds only for real swings / held weapons; yours carries to the camera |
| [CombatClient.lua](ReplicatedStorage/Combat/CombatClient.lua) | ReplicatedStorage ▸ Combat ▸ CombatClient | ModuleScript | hitstop no longer cuts a swing short; a kill slices through |
| [CombatServer.lua](ServerScriptService/Combat/CombatServer.lua), [SoundBank.lua](ReplicatedStorage/SoundBank.lua) | ServerScriptService ▸ Combat · ReplicatedStorage | ModuleScript | wall-hit sounds: bank first, Ice family, Marble |
| [UIFX.lua](ReplicatedStorage/UIFX.lua), [ClientSettings.lua](ReplicatedStorage/ClientSettings.lua), [Catalog/Drills.lua](ReplicatedStorage/Catalog/Drills.lua) | ReplicatedStorage | ModuleScript | Thud / Boom sounds; Controller look speed; basics text |

**Studio-only (save the place):** two new Decals in `ReplicatedStorage ▸ Cosmetics ▸ Icons`: **Trade** and **Inventory**.

---

## Before that: our own weapon bar, CS-style crate reel, a tidy first-battle screen

- **The weapon bar** replaces Roblox's backpack bar:
  - a card per weapon: primary 1, sidearm 2, pickups after
  - each card shows a 3D picture of the weapon in its skin, edged in the skin's rarity colour, with its key and name
  - the weapon in your hands lifts, glows gold and slowly turns; a bow or crossbow shows its arrows left
  - 1–9, a click or a tap takes one out, and the same again puts it away; the D-pad steps through on a gamepad
  - hidden while you're dead, in a menu or travelling
- **The crate reel:**
  - the stage greys out to a big "?" while it rolls
  - a long strip of cards (filler drawn by the crate's own odds) rushes under a gold marker, ticking card by card
  - it creeps the last stretch, stops somewhere on the winner (never dead centre), then BOOM: the winner pops and glows, a flash, the rarity sting
  - crates from the pass and gifts get the same reel
- **The first-battle screen:** the stats line no longer runs across the loading bar.

| File | Studio location | Type | Change |
|---|---|---|---|
| [Hotbar.client.lua](StarterPlayerScripts/Hotbar.client.lua) | StarterPlayer ▸ StarterPlayerScripts ▸ Hotbar | LocalScript | **new**: the weapon bar |
| [LoadoutServer.server.lua](ServerScriptService/Loadout/LoadoutServer.server.lua) | ServerScriptService ▸ Loadout ▸ LoadoutServer | Script | weapons carry their `Slot` and `SkinId` |
| [HUD.client.lua](StarterCharacterScripts/HUD.client.lua) | StarterPlayer ▸ StarterCharacterScripts ▸ HUD | LocalScript | the bars sit above the weapon bar |
| [HubMenu.client.lua](StarterPlayerScripts/HubMenu.client.lua) | StarterPlayer ▸ StarterPlayerScripts ▸ HubMenu | LocalScript | `HX.crateReel`; a `Spin` test hook (attribute = crate id) |
| [TravelScreen.client.lua](StarterPlayerScripts/TravelScreen.client.lua) | StarterPlayer ▸ StarterPlayerScripts ▸ TravelScreen | LocalScript | first-battle stats below the bar |

---

## Before that: every Horde map in the vote again

- **Horde votes showed only The Wildwood, Ravenhold and Stormbreak.** The map-size rule counted a solo player and no bots, so the three Horde-only maps (which have no size rating) always ranked first. Horde now skips the size rule (the horde is its own crowd), so all 10 of its maps take turns: Colosseum, Hollow Grove, Pinewatch, Marshfen, Cinderfall, Bloodpit, Frosthollow and the rest.
- **Every vote (any mode) offers three maps the last one didn't**, instead of repeating two.

| File | Studio location | Type | Change |
|---|---|---|---|
| [GameServer.server.lua](ServerScriptService/Game/GameServer.server.lua) | ServerScriptService ▸ Game ▸ GameServer | Script | Horde skips the map-size rule; the vote's rotation steps by three |

---

## Before that: the inventory, inspect everywhere, eggs of their own, quieter skins, showing off in the Courtyard

- **Eggs:** every egg has its own companions, nothing hatches from every egg (the dragon only comes out of the Ember Egg). Speckled is farm and shore, Mossy woods and marsh, Ember fire and night, Royal the crown's beasts. WHAT'S INSIDE scrolls instead of running off the screen.
- **INVENTORY** (a new dock tile): everything you own (skins, kill effects, emotes, companions, armor, titles), with search, kind filters, four sorts, copy counts and finishes.
- **INSPECT** anything, anywhere: the inventory, pass and login rewards, both sides of a trade, an egg's contents. It shows:
  - a big live look at it, its rarity, effects and where it comes from
  - this copy and all your copies (number, finish, story, times traded, kills)
  - Equip, Open the crate and Trade it buttons
- **Skin sounds:** a swing sound only for a real swing, measured against your body, so walking never triggers it, and quieter. While held, a soft hum: fire crackles, storm hums like a lightsaber, holy shimmers. Only heard up close.
- **Showing off in the Courtyard:** change your class, armor, colours, skin, title or look and your character changes at once, no respawn.

| File | Studio location | Type | Change |
|---|---|---|---|
| [HubMenu.client.lua](StarterPlayerScripts/HubMenu.client.lua) | StarterPlayer ▸ StarterPlayerScripts ▸ HubMenu | LocalScript | INVENTORY screen, `HX.inspect`, inspect buttons, a 10-tile dock, scrolling egg contents |
| [Catalog/Companions.lua](ReplicatedStorage/Catalog/Companions.lua), [Catalog/Eggs.lua](ReplicatedStorage/Catalog/Eggs.lua) | ReplicatedStorage ▸ Catalog | ModuleScript | every companion in one egg; every egg exclusive |
| [SkinFX.lua](ReplicatedStorage/SkinFX.lua), [SkinFX.client.lua](StarterPlayerScripts/SkinFX.client.lua) | ReplicatedStorage ▸ SkinFX · StarterPlayerScripts ▸ SkinFX | ModuleScript · LocalScript | `HUM` loops; swings measured against the body |
| [LoadoutServer.server.lua](ServerScriptService/Loadout/LoadoutServer.server.lua), [HubServer.server.lua](ServerScriptService/Hub/HubServer.server.lua) | ServerScriptService | Script | `_G.CourtyardRedress` after SaveClass / SetActive / SaveAppearance |

---

## Before that: rare is rare — the daily shop, Mythics in every crate, Uniques, duplicates kept

- **The daily shop:** mostly Commons and Rares. An Epic headliner on about half the days, a Legendary on about one day in eight, never a Mythic or a Unique. Earned, pass and task skins never show there. Over 60 days: 109 Common, 91 Rare, 34 Epic, 6 Legendary.
- **Mythic in every crate**, at the lowest odds (0.3–0.5%), numbered. Odds and pity were rebalanced so a Legendary is a moment. New Mythics:
  - **Starforged** (Bladesmith): starlight aura.
  - **Worldbreaker** (Hafted): inferno aura.
  - **The Sovereign** (Royal): sovereign light.
  - **Phoenix** (Fletcher): a bow with phoenix fire and fire arrows.
  - Kill effects **Reaper's Toll** (Grim: a giant spectral scythe, souls rising) and **Supernova** (Relic: they collapse into a star that bursts).
- **Unique** (one of one, ever): never in a crate or the shop.
  - Season 1's rank-1 champions get **Crown of the First Season** (Warfront), **The Undefeated** (1v1), **Bloodmoon** (2v2) and **Stormbringer** (3v3).
  - Staff can give **Kingslayer** and **Aetherwind** (F2 ▸ item).
  - Two trims, an aura, and colours that walk through the rainbow. They trade; they can't be scrapped.
- **Duplicates are kept, never paid back:** kill effects and emotes out of crates are copies now too, and they trade.
- **Every crate spins:** a crate from the pass, a daily or a playtime gift opens on the crate screen with the drum and the reveal.
- **Short of Crowns or Marks:** a pop-up offers the Crown bundles (one click) or the Crowns › Marks exchange right there.

| File | Studio location | Type | Change |
|---|---|---|---|
| [Catalog/init.lua](ReplicatedStorage/Catalog/init.lua), [Catalog/Store.lua](ReplicatedStorage/Catalog/Store.lua) | ReplicatedStorage ▸ Catalog | ModuleScript | Unique tier, the shelf's rarity rules |
| [Catalog/Crates.lua](ReplicatedStorage/Catalog/Crates.lua) | ReplicatedStorage ▸ Catalog ▸ Crates | ModuleScript | Mythic odds everywhere, longer pity |
| [Catalog/Skins.lua](ReplicatedStorage/Catalog/Skins.lua), [scripts/gen_content.py](../scripts/gen_content.py) | ReplicatedStorage ▸ Catalog ▸ Skins | ModuleScript | Mythics, Uniques, `trim2`; bows keep their own looks |
| [Catalog/KillFX.lua](ReplicatedStorage/Catalog/KillFX.lua), [KillFX.lua](ReplicatedStorage/KillFX.lua) | ReplicatedStorage | ModuleScript | Reaper's Toll, Supernova |
| [Catalog/Economy.lua](ReplicatedStorage/Catalog/Economy.lua) | ReplicatedStorage ▸ Catalog ▸ Economy | ModuleScript | season champions' Uniques |
| [SkinFX.lua](ReplicatedStorage/SkinFX.lua), [SkinTrims.lua](ReplicatedStorage/SkinTrims.lua), [UIFX.lua](ReplicatedStorage/UIFX.lua) | ReplicatedStorage | ModuleScript | Mythic auras and glints, Unique prism, two trims |
| [Collection.lua](ServerScriptService/Economy/Collection.lua), [Economy.lua](ServerScriptService/Economy/Economy.lua), [Season.server.lua](ServerScriptService/Economy/Season.server.lua) | ServerScriptService ▸ Economy | ModuleScript · Script | one-of-one serials, fx/emote copies, no refunds, champion payouts, amounts in "not enough" |
| [Profile.lua](ServerScriptService/Loadout/Profile.lua), [AdminServer.server.lua](ServerScriptService/Admin/AdminServer.server.lua), [HubServer.server.lua](ServerScriptService/Hub/HubServer.server.lua) | ServerScriptService | ModuleScript · Script | copies count as owned; no Uniques in unlock-all |
| [HubMenu.client.lua](StarterPlayerScripts/HubMenu.client.lua), [Pastimes.client.lua](StarterPlayerScripts/Pastimes.client.lua) | StarterPlayer ▸ StarterPlayerScripts | LocalScript | `HX.spinCrate`, `HX.shortOf`, Unique colours, fx/emote trade cards |

---

## Before that: arrows land where you aim, and the bow shoots 1.5x farther

- **Arrows land on the point under the reticle**, near or far: they're loosed on the arc that carries them there at their speed.
  - The client sends the point; the server solves with the speed it timed itself, so the real arrow and the one you see agree.
  - Tested through the real server: shots at 73, 157, 305 and 504 studs all hit their target.
  - Out of reach, a shot lobs at the angle that carries furthest. Aimed at the open sky, it flies along your look.
  - The crossbow lands under its reticle too.
- **The longbow shoots 1.5x farther**: a full draw is 180 studs/s (was 147), about 800 studs at the longest lob. Arrows may fly 9 s.

| File | Studio location | Type | Change |
|---|---|---|---|
| [Ballistics.lua](ReplicatedStorage/Ballistics.lua) | ReplicatedStorage ▸ Ballistics | ModuleScript | **new**: the arc that lands an arrow on its aim |
| [RangedClient.lua](ReplicatedStorage/Combat/RangedClient.lua) | ReplicatedStorage ▸ Combat ▸ RangedClient | ModuleScript | sends the aimed point; your arrow flies the arc |
| [RangedServer.lua](ServerScriptService/Combat/RangedServer.lua) | ServerScriptService ▸ Combat ▸ RangedServer | ModuleScript | solves the arc at the server's speed |
| [Bow/Config.lua](Tools/Bow/Config.lua) | the Bow Tool ▸ Config | ModuleScript | 67–180 studs/s, 9 s flights |
| [ArrowFlight.lua](ReplicatedStorage/ArrowFlight.lua) | ReplicatedStorage ▸ ArrowFlight | ModuleScript | a lost arrow lasts 10 s |

---

## Before that: the newcomer's intro, no starting kill effect, the vote's cursor for good

- **The game has a name: Steel & Glory** (`GameConfig.GAME_NAME`).
- **The welcome** (new `Intro`):
  - A ~12 s cinematic over the Courtyard (any key skips), to its own heroic score.
  - Then WELCOME, SOLDIER! with BEGIN TRAINING (recommended) or SKIP TO BATTLE, which asks ARE YOU SURE? first.
  - The travel screen comes up the moment they choose.
- **Training:**
  - New players are a **Knight with a Greatsword**.
  - Training starts with **Find Your Feet**: a checklist of the camera (Z), sprint, crouch, hop, dodge and freeing the mouse (T), in their own binds, ticking as they press each.
  - **M** (or the button) asks SKIP TRAINING? first.
- **The first battle:**
  - It's always Team Deathmatch, Free-for-All or King of the Hill, never a siege.
  - A briefing card on arrival, then one-time tips: the first wound (block / parry), out of breath, FIRST KILL!, the first fall.
  - When the round ends, the travel screen appears **at once** with how it went (kills, deaths, Marks, XP), instead of a few seconds of the vote.
- **Back in the Courtyard** (new `MenuTour`):
  - A spotlight tour of the menu that ends on Settings (rebind any key) and the menu key.
  - Then the **recruit's gift** (500 Marks + a Key) with OPEN A CRATE, straight to the crates.
- **No kill effect to start with:** plain falls. Shatter moves to the Relic crate (whoever has it on keeps it), and ARMORY ▸ KILL FX has a *No effect* choice.
- **The vote's cursor:** forced on and free every frame of the vote, after everything else that touches the mouse.
- **No body, still a world:** players without a character stream the map's middle, so the menu's and the intro's camera see the Courtyard (it was empty haze before).

| File | Studio location | Type | Change |
|---|---|---|---|
| [Intro.client.lua](StarterPlayerScripts/Intro.client.lua) | StarterPlayer ▸ StarterPlayerScripts ▸ Intro | LocalScript | **new**: the welcome, the first battle's briefing and tips |
| [MenuTour.client.lua](StarterPlayerScripts/MenuTour.client.lua) | StarterPlayer ▸ StarterPlayerScripts ▸ MenuTour | LocalScript | **new**: the Courtyard welcome, the tour, the gift |
| [Training.client.lua](StarterPlayerScripts/Training.client.lua) | StarterPlayer ▸ StarterPlayerScripts ▸ Training | LocalScript | Find Your Feet, the skip question, M |
| [TravelScreen.client.lua](StarterPlayerScripts/TravelScreen.client.lua) | StarterPlayer ▸ StarterPlayerScripts ▸ TravelScreen | LocalScript | `_G.ShowTravel`, the first battle's summary |
| [HubMenu.client.lua](StarterPlayerScripts/HubMenu.client.lua) | StarterPlayer ▸ StarterPlayerScripts ▸ HubMenu | LocalScript | intro hooks, tour names, `_G.HubMenuGo`, *No effect* |
| [Scoreboard.client.lua](StarterPlayerScripts/Scoreboard.client.lua) | StarterPlayer ▸ StarterPlayerScripts ▸ Scoreboard | LocalScript | the vote's cursor, bound last |
| [Music.client.lua](StarterPlayerScripts/Music.client.lua), [MusicConfig.lua](ReplicatedStorage/MusicConfig.lua) | StarterPlayerScripts ▸ Music · ReplicatedStorage ▸ MusicConfig | LocalScript · ModuleScript | the Intro mood |
| [HubServer.server.lua](ServerScriptService/Hub/HubServer.server.lua) | ServerScriptService ▸ Hub ▸ HubServer | Script | the Intro and TourDone ops, first-battle modes, the trip home sooner, equip no kill effect |
| [Training.lua](ServerScriptService/Game/Training.lua), [Catalog/Drills.lua](ReplicatedStorage/Catalog/Drills.lua) | ServerScriptService ▸ Game ▸ Training · ReplicatedStorage ▸ Catalog ▸ Drills | ModuleScript | Find Your Feet |
| [Profile.lua](ServerScriptService/Loadout/Profile.lua) | ServerScriptService ▸ Loadout ▸ Profile | ModuleScript | `menuTour`, `starterGift`, no starting kill effect, Knight |
| [GameServer.server.lua](ServerScriptService/Game/GameServer.server.lua), [MapLoader.lua](ServerScriptService/Game/MapLoader.lua) | ServerScriptService ▸ Game | Script · ModuleScript | streaming focus for the bodiless, map shot attributes |
| [GameConfig.lua](ReplicatedStorage/GameConfig.lua), [Catalog/Economy.lua](ReplicatedStorage/Catalog/Economy.lua), [Catalog/KillFX.lua](ReplicatedStorage/Catalog/KillFX.lua) | ReplicatedStorage | ModuleScript | name, Knight default, the gift, Shatter in the Relic crate |

---

## Before that: the vote's cursor, bots that climb and hop, maps sized to the numbers

- **The cursor is back on the vote screen.** Players stay alive through the intermission and the camera kept locking and hiding the mouse every frame; it lets go while the vote is up, and the board keeps the cursor on for the dead and the spectating too.
- **Bots:**
  - They walk up hills and ramps. Their look-ahead used to take rising ground for a wall and turn away; Millfield's hill is the case that showed it.
  - They hop over anything low (under ~2.3 studs: rocks, logs, low walls).
  - Stuck for a second, they hop, then step aside and work out a fresh path.
  - Paths are narrower (agent radius 1.5, so they get out between a hay bale and a barn wall). When the goal itself is unreachable (the hill's middle is under the windmill), the path goes to open ground beside it.
- **Maps sized to the player count:**
  - Every map has a fighter range, players and bots together (`GameConfig.MAP_FIGHTERS`). Rose Court is 2–6 (1v1 to 3v3), the arenas 2–12, Sandpit 2–16, Highbridge 4–20, the baileys and bridges 6–24, the open fields 8–32 and the sieges 8–40.
  - The vote offers maps that suit the players there and the bots the mode brings.
  - Bots never fill a map past its most.
  - A public server's room shrinks to its map's most, so matchmaking won't pour 16 people into a garden.

| File | Studio location | Type | Change |
|---|---|---|---|
| [CameraRig.client.lua](StarterCharacterScripts/CameraRig.client.lua) | StarterPlayer ▸ StarterCharacterScripts ▸ CameraRig | LocalScript | frees the mouse during the vote |
| [Scoreboard.client.lua](StarterPlayerScripts/Scoreboard.client.lua) | StarterPlayer ▸ StarterPlayerScripts ▸ Scoreboard | LocalScript | keeps the cursor on while the vote is up |
| [Bots.lua](ServerScriptService/Combat/Bots.lua) | ServerScriptService ▸ Combat ▸ Bots | ModuleScript | slopes, hops, `unstick`, path fixes |
| [GameConfig.lua](ReplicatedStorage/GameConfig.lua) | ReplicatedStorage ▸ GameConfig | ModuleScript | `MAP_FIGHTERS`, `mapFighters`, `mapFit` |
| [GameServer.server.lua](ServerScriptService/Game/GameServer.server.lua) | ServerScriptService ▸ Game ▸ GameServer | Script | map candidates sized to the numbers |
| [BotFill.lua](ServerScriptService/Game/BotFill.lua) | ServerScriptService ▸ Game ▸ BotFill | ModuleScript | caps bots at the map's most; `BotFill.wanted(def)` |
| [HubServer.server.lua](ServerScriptService/Hub/HubServer.server.lua) | ServerScriptService ▸ Hub ▸ HubServer | Script | a public server's room is its map's most |

---

## Before that: bow and crossbow skins that look and sound different

- **Every bow and crossbow skin changes its silhouette.** A new ranged trim set is fitted to the limbs and the prod:
  - flame tongues, horn curls, thorns, crystal clusters, wings, feathers, ice spikes
  - a skull, gilded caps, storm zig-zags, venom drops, blood barbs, obsidian shards and a void core
  - a dragon's horns and dorsal ridge, a halo
- **Arrows look better:**
  - In flight: a wide colour trail with a hot core, particles, a light, and the kind's own touch (a halo, a flicker, smoke, wisps).
  - On landing, each kind has its own impact: a fire that keeps burning, ice shards, a lightning bolt from the sky, a pillar of light, an implosion, a splash of blood, a lingering poison cloud, a fountain of gold, rising spirits.
  - Two new kinds: **Void** and **Spirit**.
- **Arrows sound different:** each kind has its own release and impact sound (licensed library sounds) layered over the bow's own.
- **5 new skins in the Fletcher's Crate:** Seraph's Wing, Crystalline, Voidcaller (bows); Soulreaper, Runecaster (crossbows).

| File | Studio location | Type | Change |
|---|---|---|---|
| [SkinTrims.lua](ReplicatedStorage/SkinTrims.lua) | ReplicatedStorage ▸ SkinTrims | ModuleScript | the ranged trim set (`RT`) |
| [ArrowFX.lua](ReplicatedStorage/ArrowFX.lua) | ReplicatedStorage ▸ ArrowFX | ModuleScript | richer flight, impacts per kind, sounds, void / spirit |
| [RangedServer.lua](ServerScriptService/Combat/RangedServer.lua) | ServerScriptService ▸ Combat ▸ RangedServer | ModuleScript | plays each kind's release / impact sounds |
| [Catalog/Skins.lua](ReplicatedStorage/Catalog/Skins.lua), [scripts/skins_handmade.part](../scripts/skins_handmade.part), [scripts/gen_content.py](../scripts/gen_content.py) | ReplicatedStorage ▸ Catalog ▸ Skins | ModuleScript | trims on every ranged skin, 5 new skins |

---

## Before that: the crossbow — aim to shoot, reload yourself, new poses

- **Controls:**
  - Hold right mouse to raise the crossbow and aim; it zooms down the tiller. Click fires, but only while it's raised; otherwise a hint says to hold right mouse.
  - After a shot it **stays empty**. Press **R** (rebindable) or click to reload. The reticle says "EMPTY · R TO RELOAD".
  - Phones: hold BLOCK to aim, SWING fires or reloads.
- **Poses** (both hands, always):
  - **At ease:** carried low and diagonal across the body.
  - **Aimed:** shouldered, a little side-on, pointing where you look, the left hand under the stock.
  - **Reloading:** bent over, the nose down at the right foot in the stirrup, hauling the string up in three strokes.
  - Everyone sees the string follow the haul.
- **Fixes:** putting the crossbow away mid-reload no longer leaves you stuck at reload walking speed. A refilled bolt no longer loads it by itself.

| File | Studio location | Type | Change |
|---|---|---|---|
| [RangedServer.lua](ServerScriptService/Combat/RangedServer.lua) | ServerScriptService ▸ Combat ▸ RangedServer | ModuleScript | "Reload" action; no auto reload; `ReloadAt` |
| [RangedClient.lua](ReplicatedStorage/Combat/RangedClient.lua) | ReplicatedStorage ▸ Combat ▸ RangedClient | ModuleScript | hold to aim, click to fire / reload, R, hints |
| [RigPose.lua](ReplicatedStorage/RigPose.lua) | ReplicatedStorage ▸ RigPose | ModuleScript | crossbow at ease / aimed / spanning (`XBOW`) |
| [RangedFX.client.lua](StarterPlayerScripts/RangedFX.client.lua) | StarterPlayer ▸ StarterPlayerScripts ▸ RangedFX | LocalScript | others' string follows the haul |
| [ClientSettings.lua](ReplicatedStorage/ClientSettings.lua) | ReplicatedStorage ▸ ClientSettings | ModuleScript | Reload bind (R) |
| [Tools/Crossbow/Config.lua](Tools/Crossbow/Config.lua) | ServerStorage ▸ Weapons ▸ Crossbow ▸ Config | ModuleScript | description |

---

## Before that: the longbow shoots 1.5× farther

- **Longbow arrows fly faster:** a full draw goes from 120 to 147 studs/s, and a snap shot from 45 to 55. Gravity is the same, and range goes with speed squared, so every shot carries about 1.5× as far and hits a bit sooner.
- **Arrows may fly for up to 6 s** (was 4), so long lobs aren't dropped mid-air. The arrow everyone sees lasts 7 s.
- Damage is unchanged, and so is the crossbow.

| File | Studio location | Type | Change |
|---|---|---|---|
| [Tools/Bow/Config.lua](Tools/Bow/Config.lua) | ServerStorage ▸ Weapons ▸ Bow ▸ Config | ModuleScript | SPEED_MIN 55, SPEED_MAX 147, MAX_FLIGHT 6 |
| [ArrowFlight.lua](ReplicatedStorage/ArrowFlight.lua) | ReplicatedStorage ▸ ArrowFlight | ModuleScript | a lost arrow lasts 7 s |

---

## Before that: the whole game a touch quicker

- **Swings are 12% quicker:** every weapon's windup, swing and recovery (`GameConfig.TEMPO.swing` = 1.12, on top of each weapon's own speed). Bots, feints, morphs and parry windows follow, since they're all timed from the same numbers. The menu's windup figures match.
- **Movement is 10% quicker:** base walk speed 11 (was 10). Sprint, armor and weapon weight, the slow-downs while swinging and blocking, bots and footstep cadence all scale from it.
- Bows and crossbows are unchanged (they stay slow on purpose).

| File | Studio location | Type | Change |
|---|---|---|---|
| [GameConfig.lua](ReplicatedStorage/GameConfig.lua) | ReplicatedStorage ▸ GameConfig | ModuleScript | `TEMPO.swing` |
| [CombatServer.lua](ServerScriptService/Combat/CombatServer.lua) | ServerScriptService ▸ Combat ▸ CombatServer | ModuleScript | attack times × the tempo |
| [LoadoutServer.server.lua](ServerScriptService/Loadout/LoadoutServer.server.lua) | ServerScriptService ▸ Loadout ▸ LoadoutServer | Script | menu windups × the tempo |
| [MovementConfig.lua](ReplicatedStorage/MovementConfig.lua) | ReplicatedStorage ▸ MovementConfig | ModuleScript | BASE_SPEED 11 |

---

## Before that: maps verified, ready to publish

- **Every map checked:**
  - All 36 maps exist, and every mode has 10 or more.
  - Each map has what its modes need.
  - All 25 new maps have vote pictures.
- **Map fixes found while checking:**
  - Redgorge's gorge floor sat below its stored terrain and showed the void.
  - The forest clearings' ponds had no water.
  - Round fills thinner than a voxel row wrote nothing: the arena floors and the village squares.
  - Bots couldn't climb the 1-stud temple steps, so nobody ever reached the KOTH hill on the ruins maps. Invisible ramps now run along all four sides, and the arena dais and village platform are a low step.
  - The obelisk tips rendered as forked V shapes.
- **Played:** Siege on Emberkeep, KOTH on Cinderfall, TDM on Moonring, with no script errors.
- **Before publishing:** test rigs left in the place were removed. `/spawn` test dummies no longer work on live servers (only in Studio, or for the host of a cheat server).

| File | Studio location | Type | Change |
|---|---|---|---|
| [MapForge.lua](ServerScriptService/Build/MapForge.lua) | ServerScriptService ▸ Build ▸ MapForge | ModuleScript | the fixes above |
| [TestDummies.server.lua](ServerScriptService/TestDummies.server.lua) | ServerScriptService ▸ TestDummies | Script | Studio / cheat-server host only |
| [../docs/HANDOFF.md](../docs/HANDOFF.md) | (docs) | | publishing checklist |

---

## Before that: 25 new maps, every mode has 10 or more

- **A map forge:** each new map is one line, a layout in a theme.
  - **Layouts:** arena, castle courtyard, village, bridge, ruins, forest clearing, siege castle.
  - **Themes:** summer, autumn, winter, moonlit snow, desert noon, desert dusk, swamp mist, storm night, ember night, spring, dawn mist, ash, firefly forest.
  - Each theme sets the time of day, haze, colours, trees and weather (snow, rain, ash, falling leaves, petals, embers, fireflies, dust, mist).
- **25 new maps:**
  - **Siege:** Emberkeep, Sunspire, Thornwall, Mistmoor, Greenhollow, Stormhold, Ashenford, Rimeholt, Blossomgate. Each castle has its own champion.
  - **Arenas:** the Bloodpit, Moonring, the Dustbowl, Thornpit, Mirepit.
  - **Courtyards:** Abbeyfield, Blackwater.
  - **Villages:** Harvestvale, Frosthollow, Marshfen.
  - **Bridges:** Redgorge, Mistbridge.
  - **Ruins:** Cinderfall, Duneshrine.
  - **Clearings:** Hollow Grove, Pinewatch.
- **Every mode now lists 10 or more maps:** Siege 10, Lists 10, Duel 11, FFA 12, TDM 12, LTS 12, KOTH 11, Horde 10.
- **Fix:** the KOTH hill showed as a yellow drum in every other mode. The loader now hides it.
- **In Studio:** build them with `require(game.ServerScriptService.Build.Maps).buildForge()`, then **save the place**. The maps and their vote pictures live in the place.

| File | Studio location | Type | Change |
|---|---|---|---|
| [MapForge.lua](ServerScriptService/Build/MapForge.lua) | ServerScriptService ▸ Build ▸ MapForge | ModuleScript | **new**: themes, layouts, the 25 maps |
| [Maps.lua](ServerScriptService/Build/Maps.lua) | ServerScriptService ▸ Build ▸ Maps | ModuleScript | builds forge maps, `buildForge()` |
| [GameConfig.lua](ReplicatedStorage/GameConfig.lua) | ReplicatedStorage ▸ GameConfig | ModuleScript | map titles; every mode's maps |
| [MapLoader.lua](ServerScriptService/Game/MapLoader.lua) | ServerScriptService ▸ Game ▸ MapLoader | ModuleScript | zones hidden on load |

---

## Before that: leaderboards, season rewards, player profiles, privacy

- **A LEADERBOARDS screen** (open it from the lobby board's "TOP 100 · SEASON REWARDS"):
  - The Warfront and each ranked bracket, top 100 each.
  - Where you stand, and a search by name.
  - The season's rewards and how long is left, with your current line lit up.
- **Season rewards are real now:**
  - When the season ends, the top of each board is paid (titles, Crowns, Marks, Keys), and so is the ranked tier you finished in.
  - You're paid the next time you join.
  - A new season gets fresh boards.
- **Player profiles:** click anyone on a leaderboard, use PROFILE in the players-here list, or look at someone in the world and press P. A profile shows:
  - their record (kills, deaths, K/D, rounds, wins, win rate, parries, season kills)
  - their ranked tiers
  - every class dressed as they wear it
  - their collection and finest skins
  - buttons to trade, invite to your party, or send a Roblox friend request
- **Privacy settings:** who can send you party invites and trade requests (everyone, friends, nobody). The server enforces both.
- **Fix:** a cached board could be stuck at 10 rows.

| File | Studio location | Type | Change |
|---|---|---|---|
| [HubMenu.client.lua](StarterPlayerScripts/HubMenu.client.lua) | StarterPlayer ▸ StarterPlayerScripts ▸ HubMenu | LocalScript | LEADERBOARDS and PROFILE screens, ways in, the P key |
| [Season.server.lua](ServerScriptService/Economy/Season.server.lua) | ServerScriptService ▸ Economy ▸ Season | Script | **new**: the season's end and its payout |
| [HubServer.server.lua](ServerScriptService/Hub/HubServer.server.lua) | ServerScriptService ▸ Hub ▸ HubServer | Script | "Board", "PlayerProfile"; party invite privacy |
| [Leaderboards.lua](ServerScriptService/Hub/Leaderboards.lua) | ServerScriptService ▸ Hub ▸ Leaderboards | ModuleScript | season boards, places, saved profiles, cache fix |
| [Scoreboard.server.lua](ServerScriptService/Scoreboard.server.lua) | ServerScriptService ▸ Scoreboard | Script | writes the season's boards |
| [SettingsServer.server.lua](ServerScriptService/SettingsServer.server.lua) | ServerScriptService ▸ SettingsServer | Script | privacy onto the player |
| [Trading.lua](ServerScriptService/Economy/Trading.lua) | ServerScriptService ▸ Economy ▸ Trading | ModuleScript | trade request privacy |
| [ClientSettings.lua](ReplicatedStorage/ClientSettings.lua) | ReplicatedStorage ▸ ClientSettings | ModuleScript | privacy choices, the Profile bind |
| [Catalog/Economy.lua](ReplicatedStorage/Catalog/Economy.lua) | ReplicatedStorage ▸ Catalog ▸ Economy | ModuleScript | `seasonRewards` |

---

## Before that: custom server bots and the host's server panel

- **Custom servers have bots:**
  - Set them when you make the server: on or off, how many fighters in all (players plus bots), and their skill (Mixed, Squire, Knight or Champion).
  - Ranked never has bots.
- **The host's SERVER PANEL:** the host gets a YOUR SERVER card in the lobby. The panel:
  - **Players:** kick someone (they stay out while the server runs), or hand the server over.
  - **Bots:** fill on/off, how many and how good, changed live. Spawn practice bots where you stand (+1 / +3, pick their skill), or clear them.
  - **The round:** pick the next mode and map, or end the round now.
  - **Rules, changed live:** friendly fire, respawns, weapons on the ground, round length, player limit, who can join.
  - If the host leaves, whoever has been there longest takes over.
- **Fixes:**
  - A custom server's chosen map is now used (it always rotated).
  - "Weapons on the ground" now does something: off means a dropped weapon can't be picked up and goes in a few seconds.

| File | Studio location | Type | Change |
|---|---|---|---|
| [HostServer.server.lua](ServerScriptService/Hub/HostServer.server.lua) | ServerScriptService ▸ Hub ▸ HostServer | Script | **new**: the host's controls (HostRemote) |
| [HubMenu.client.lua](StarterPlayerScripts/HubMenu.client.lua) | StarterPlayer ▸ StarterPlayerScripts ▸ HubMenu | LocalScript | host card + SERVER PANEL; bot settings when creating |
| [BotFill.lua](ServerScriptService/Game/BotFill.lua) | ServerScriptService ▸ Game ▸ BotFill | ModuleScript | custom servers by their settings |
| [HubServer.server.lua](ServerScriptService/Hub/HubServer.server.lua) | ServerScriptService ▸ Hub ▸ HubServer | Script | bot settings checked |
| [GameServer.server.lua](ServerScriptService/Game/GameServer.server.lua) | ServerScriptService ▸ Game ▸ GameServer | Script | custom map used; Round GroundWeapons |
| [Pickup.lua](ServerScriptService/Combat/Pickup.lua) | ServerScriptService ▸ Combat ▸ Pickup | ModuleScript | no pickups when ground weapons are off |
| [GameConfig.lua](ReplicatedStorage/GameConfig.lua) | ReplicatedStorage ▸ GameConfig | ModuleScript | bot defaults, `BOT_SKILLS` |

---

## Before that: the bow flipped, a ready stance, no arm jolt; a warning before leaving a battle

- **The bow is in the right hand and the left draws.** With the camera over your right shoulder, the body now turns away from the view instead of across it, and the bow stands next to the crosshair.
- **A ready stance** when not drawing: the bow held low across the body, the string hand by it. It blends into the full draw.
- **No zombie arm, no jolt:**
  - Roblox's "holding a tool" arm (stuck straight out) is gone with a bow or crossbow in hand.
  - The walk animation's arm swing is gone too: the arms no longer jump up as you start walking and drop as you stop.
  - Everyone sees it the same way.
- **First person:** the bow arm stays visible, out in front; the string arm is hidden. With a crossbow, both arms are hidden.
- **Leaving a battle mid-round asks first:**
  - It says what you'd give up: the pay for finishing (win or lose), the win bonus, and your kills so far.
  - Losers still get paid for finishing a round; winners get double.

| File | Studio location | Type | Change |
|---|---|---|---|
| [RigPose.lua](ReplicatedStorage/RigPose.lua) | ReplicatedStorage ▸ RigPose | ModuleScript | bow mirrored to the right hand; `BOW_READY` stance |
| [RangedServer.lua](ServerScriptService/Combat/RangedServer.lua) | ServerScriptService ▸ Combat ▸ RangedServer | ModuleScript | the bow stays in the right hand |
| [RangedClient.lua](ReplicatedStorage/Combat/RangedClient.lua) | ReplicatedStorage ▸ Combat ▸ RangedClient | ModuleScript | rest pose is the ready stance |
| [RangedFX.client.lua](StarterPlayerScripts/RangedFX.client.lua) | StarterPlayer ▸ StarterPlayerScripts ▸ RangedFX | LocalScript | string to the left hand; Roblox arm animations off the shoulders |
| [CameraRig.client.lua](StarterCharacterScripts/CameraRig.client.lua) | StarterPlayer ▸ StarterCharacterScripts ▸ CameraRig | LocalScript | first person: the bow arm shows |
| [HubMenu.client.lua](StarterPlayerScripts/HubMenu.client.lua) | StarterPlayer ▸ StarterPlayerScripts ▸ HubMenu | LocalScript | leave-battle warning |

---

## Before that: bots on the board, bots that fight, an easier Siege, the result screen

- **Bots are on the scoreboard** (Tab, and during the intermission):
  - Each bot shows its kills and deaths, tagged BOT, sorted and team-coloured with the players.
  - A fallen bot comes back under the same name with the same score.
  - A bot's row goes when a player takes its place.
- **Bots fight the other side now:**
  - A crowd of bots used to cut its own side down and almost never kill an enemy.
  - A bot's swing now passes through bots on its own side.
  - It won't swing while a player on its side stands in the way.
- **A wrong-map bug is fixed:** a round could start on a map from the last vote that its mode doesn't use (Team Deathmatch behind Frostgate's shut gate). Now a round only loads a map its mode lists.
- **Siege is easier to attack:**
  - 5 minutes to start (was 4), and taking a stage adds 30% more time.
  - The ram is 30% faster, and creeps forward on a tie.
  - The gate takes 20% fewer blows.
  - Zones fill 25% faster, and outnumbering the defenders still fills them.
  - The final champion has 25% less health.
- **A big VICTORY / DEFEAT / DRAW screen** when a round ends, in the winning side's colour, with who won and why.

| File | Studio location | Type | Change |
|---|---|---|---|
| [BotFill.lua](ServerScriptService/Game/BotFill.lua) | ServerScriptService ▸ Game ▸ BotFill | ModuleScript | bot seats (ReplicatedStorage ▸ BotScores) |
| [Scoreboard.server.lua](ServerScriptService/Scoreboard.server.lua) | ServerScriptService ▸ Scoreboard | Script | counts bots' kills and deaths |
| [Scoreboard.client.lua](StarterPlayerScripts/Scoreboard.client.lua) | StarterPlayer ▸ StarterPlayerScripts ▸ Scoreboard | LocalScript | bot rows |
| [CombatServer.lua](ServerScriptService/Combat/CombatServer.lua) | ServerScriptService ▸ Combat ▸ CombatServer | ModuleScript | `LastHitBySeat`; `botFriends`: bot blades pass through their own side |
| [Bots.lua](ServerScriptService/Combat/Bots.lua) | ServerScriptService ▸ Combat ▸ Bots | ModuleScript | no swinging through a teammate player |
| [GameServer.server.lua](ServerScriptService/Game/GameServer.server.lua) | ServerScriptService ▸ Game ▸ GameServer | Script | a round only loads a map its mode lists |
| [Siege.lua](ServerScriptService/Game/Modes/Siege.lua) | ServerScriptService ▸ Game ▸ Modes ▸ Siege | ModuleScript | attacker easing, numbers win ground |
| [GameConfig.lua](ReplicatedStorage/GameConfig.lua) | ReplicatedStorage ▸ GameConfig | ModuleScript | Siege 5 min, `attack` table |
| [RoundResult.client.lua](StarterPlayerScripts/RoundResult.client.lua) | StarterPlayer ▸ StarterPlayerScripts ▸ RoundResult | LocalScript | **new**: the result screen |

---

## Before that: bows in first person, sounds, ranged skins with arrow effects

- **A new bow stance:**
  - The bow is held out in the left hand, and the torso turns side-on.
  - Drawing turns the torso further while the right arm pulls back along the arrow, not up.
  - In first person your own arms are hidden while a bow or crossbow is up, so only the bow, the string and the arrow show. The string is thinner.
- **Sounds:**
  - The draw creaks.
  - A new release: a low string thump plus a short whoosh, both louder the fuller the draw. The crossbow gets a click plus a whoosh.
  - Arrows hitting things sound like what they hit: stone and metal ring, wood thunks, earth thuds, flesh gets a stab.
  - **Arrows whiz by** you when someone else's shot passes within 9 studs of your head.
- **The Armory has a RANGED · ARCHER section** with the bow and the crossbow.
- **18 ranged skins** (12 bows, 6 crossbows). The Epics and Legendaries change the arrows: fire, frost, shadow, holy, storm, venom, gilded, blood. Each one gets:
  - in flight: a trail, a glowing head, particles and a light
  - where it lands: a burst
  - stuck in something: a smoulder
- **Where the skins come from:**
  - A new **Fletcher's Crate**, always in rotation.
  - Earned by kills: Venomstring, Heartseeker, Glacier.
  - The Royal crate: Stormcaller, Thunderbolt.
  - The shelf: the Gilded Longbow.
- **Fixes:**
  - A skinned arrow that stuck in something errored on the server.
  - In the Hub, the training script's "infinite yield" warning is gone.

| File | Studio location | Type | Change |
|---|---|---|---|
| [ArrowFX.lua](ReplicatedStorage/ArrowFX.lua) | ReplicatedStorage ▸ ArrowFX | ModuleScript | **new**: arrow effects by kind |
| [ArrowFlight.lua](ReplicatedStorage/ArrowFlight.lua) | ReplicatedStorage ▸ ArrowFlight | ModuleScript | arrow effects in flight, whiz-by |
| [RangedServer.lua](ServerScriptService/Combat/RangedServer.lua) | ServerScriptService ▸ Combat ▸ RangedServer | ModuleScript | release / creak / impact sounds, effect kind on every shot, smouldering stuck arrows, thinner string |
| [RangedClient.lua](ReplicatedStorage/Combat/RangedClient.lua) | ReplicatedStorage ▸ Combat ▸ RangedClient | ModuleScript | your own arrow wears the skin's effect |
| [RangedFX.client.lua](StarterPlayerScripts/RangedFX.client.lua) | StarterPlayer ▸ StarterPlayerScripts ▸ RangedFX | LocalScript | effects on everyone's arrows |
| [RigPose.lua](ReplicatedStorage/RigPose.lua) | ReplicatedStorage ▸ RigPose | ModuleScript | the side-on bow stance, pulling back |
| [CameraRig.client.lua](StarterCharacterScripts/CameraRig.client.lua) | StarterPlayer ▸ StarterCharacterScripts ▸ CameraRig | LocalScript | arms hidden in first person with a bow up |
| [LoadoutServer.server.lua](ServerScriptService/Loadout/LoadoutServer.server.lua) | ServerScriptService ▸ Loadout ▸ LoadoutServer | Script | `Skin` / `ArrowFx` on the Tool |
| [Catalog/Skins.lua](ReplicatedStorage/Catalog/Skins.lua), [scripts/skins_handmade.part](../scripts/skins_handmade.part), [scripts/gen_content.py](../scripts/gen_content.py) | ReplicatedStorage ▸ Catalog ▸ Skins | ModuleScript | 18 ranged skins, the `arrow` field |
| [Catalog/Crates.lua](ReplicatedStorage/Catalog/Crates.lua) | ReplicatedStorage ▸ Catalog ▸ Crates | ModuleScript | Fletcher's Crate |
| [Catalog/Calendar.lua](ReplicatedStorage/Catalog/Calendar.lua) | ReplicatedStorage ▸ Catalog ▸ Calendar | ModuleScript | Fletcher always in rotation |
| [SkinFX.lua](ReplicatedStorage/SkinFX.lua) | ReplicatedStorage ▸ SkinFX | ModuleScript | describes the arrow effect |
| [HubMenu.client.lua](StarterPlayerScripts/HubMenu.client.lua) | StarterPlayer ▸ StarterPlayerScripts ▸ HubMenu | LocalScript | Armory RANGED section |
| [Training.client.lua](StarterPlayerScripts/Training.client.lua) | StarterPlayer ▸ StarterPlayerScripts ▸ Training | LocalScript | quiet wait for its remote |

---

## Before that: bows toned down

- **Longbow:**
  - Slower to draw: 1.6 s to full, walking at 20%.
  - Slower arrows that drop more: 45–120 studs/s, more gravity.
  - Weaker: a full draw does 30 to the body and 60 to the head, never a one-shot.
  - A shakier aim: always wandering a little, more while pulling, and more after 0.6 s held.
  - Slower nock: 1.5 s. Fewer arrows: 16.
- **Crossbow:** 160 studs/s, 42 to the body and 84 to the head, a 5 s reload at 8% walking speed.

| File | Studio location | Type | Change |
|---|---|---|---|
| [Tools/Bow/Config.lua](Tools/Bow/Config.lua), [Tools/Crossbow/Config.lua](Tools/Crossbow/Config.lua) | ServerStorage ▸ Weapons ▸ Bow / Crossbow ▸ Config | ModuleScript | the numbers |
| [RangedServer.lua](ServerScriptService/Combat/RangedServer.lua) | ServerScriptService ▸ Combat ▸ RangedServer | ModuleScript | defaults, draw slowdown 20% |
| [RangedClient.lua](ReplicatedStorage/Combat/RangedClient.lua) | ReplicatedStorage ▸ Combat ▸ RangedClient | ModuleScript | shakier while pulling |

---

## Before that: the Archer

- **A new class, the Archer:** a bow or a crossbow plus a one-handed sidearm, and nothing big. It's the lightest class: 85 health, no armor protection, a bit faster.
- **Longbow** (free, held in the left hand):
  - Hold left mouse to draw. A full draw takes 1.2 s; meanwhile you walk at 35% and can't sprint.
  - Let go to loose. Letting go too early lets the string down without a shot.
  - Holding a full draw too long shakes the aim and costs stamina.
  - After every shot the archer reaches back and nocks the next arrow (1.3 s).
  - About 2.5–3 s between shots.
- **Crossbow** (level 3):
  - Click to loose: a steady aim, a hard hit.
  - Then a 4.5 s windlass reload at 10% walking speed. About 5 s between shots.
- **Arrows are real:**
  - Gravity, and the server decides every hit.
  - Headshots ×2.4. A full-draw headshot kills a Light or Medium; a bolt to the head kills anyone.
  - Armor resists by type. A raised guard facing the arrow blocks it.
  - Arrows stick in bodies and the world. The kill feed says "shot" / "shot through the head".
- **Everyone sees it:**
  - The bow string pulled back to your hand with an arrow on it.
  - The stances: side-on draw, reaching for the quiver, crossbow shouldered, the windlass crank.
  - Arrows in flight. The reticle shakes and closes as you draw.
- Phones: hold a SWING button to draw, BLOCK lets it down.

| File | Studio location | Type | Change |
|---|---|---|---|
| [RangedServer.lua](ServerScriptService/Combat/RangedServer.lua) | ServerScriptService ▸ Combat ▸ RangedServer | ModuleScript | **new** |
| [RangedClient.lua](ReplicatedStorage/Combat/RangedClient.lua) | ReplicatedStorage ▸ Combat ▸ RangedClient | ModuleScript | **new** |
| [ArrowFlight.lua](ReplicatedStorage/ArrowFlight.lua) | ReplicatedStorage ▸ ArrowFlight | ModuleScript | **new** |
| [RangedFX.client.lua](StarterPlayerScripts/RangedFX.client.lua) | StarterPlayer ▸ StarterPlayerScripts ▸ RangedFX | LocalScript | **new** |
| [Tools/Bow](Tools/Bow), [Tools/Crossbow](Tools/Crossbow) | ServerStorage ▸ Weapons ▸ Bow / Crossbow | Tool (Config, Server, Client) | **new** |
| [Build/Weapons.lua](ServerScriptService/Build/Weapons.lua) | ServerScriptService ▸ Build ▸ Weapons | ModuleScript | bow and crossbow bodies |
| [Catalog/Weapons.lua](ReplicatedStorage/Catalog/Weapons.lua), [scripts/gen_content.py](../scripts/gen_content.py) | ReplicatedStorage ▸ Catalog ▸ Weapons | ModuleScript | Bow, Crossbow (`ranged`) |
| [Catalog/init.lua](ReplicatedStorage/Catalog/init.lua) | ReplicatedStorage ▸ Catalog | ModuleScript | `Catalog.weaponFits` |
| [GameConfig.lua](ReplicatedStorage/GameConfig.lua) | ReplicatedStorage ▸ GameConfig | ModuleScript | the Archer |
| [RigPose.lua](ReplicatedStorage/RigPose.lua) | ReplicatedStorage ▸ RigPose | ModuleScript | bow / crossbow stances (new inputs) |
| [CameraRig.client.lua](StarterCharacterScripts/CameraRig.client.lua) | StarterPlayer ▸ StarterCharacterScripts ▸ CameraRig | LocalScript | ranged pose inputs, aim zoom |
| [Profile.lua](ServerScriptService/Loadout/Profile.lua) | ServerScriptService ▸ Loadout ▸ Profile | ModuleScript | slots by `weaponFits` |
| [LoadoutServer.server.lua](ServerScriptService/Loadout/LoadoutServer.server.lua) | ServerScriptService ▸ Loadout ▸ LoadoutServer | Script | class health / prot / speed |
| [Holsters.server.lua](ServerScriptService/Loadout/Holsters.server.lua) | ServerScriptService ▸ Loadout ▸ Holsters | Script | bows on the back |
| [MovementServer.server.lua](ServerScriptService/MovementServer.server.lua) | ServerScriptService ▸ MovementServer | Script | no sprint while drawing / winding |
| [HubMenu.client.lua](StarterPlayerScripts/HubMenu.client.lua) | StarterPlayer ▸ StarterPlayerScripts ▸ HubMenu | LocalScript | weapon slots by class, bows to the Archer |
| [Scoreboard.client.lua](StarterPlayerScripts/Scoreboard.client.lua) | StarterPlayer ▸ StarterPlayerScripts ▸ Scoreboard | LocalScript | "shot" |
| [TouchControls.client.lua](StarterPlayerScripts/TouchControls.client.lua) | StarterPlayer ▸ StarterPlayerScripts ▸ TouchControls | LocalScript | held SWING |

---

## Before that: newcomer path, bot fill, touch controls, class loadouts

- **A brand-new player never sees a menu first.**
  - The Courtyard sends them straight into **Basic Training**: 7 steps (swing, stab, overhead, block, parry, kick, beat a Squire).
  - For each step they're placed right in front of its dummy, facing it.
  - The lesson dummies' blows land and flinch, but don't hurt.
  - **SKIP TRAINING** is top right.
  - Then it's straight into a battle. After that first round they come back to the Courtyard with the full menu.
  - Studio: set `GameConfig.STUDIO_NEWCOMER = true` to test the path (Studio can't load saves, so it's off by default).
- **Bots fill every Warfront match.**
  - Fill targets: FFA 8, Duel 4, TDM 12, LTS 8, KOTH 10, Siege 12. Players take bots' places as they join.
  - Bots fight players and each other, head for the hill or the ram, and use pathfinding.
  - They cost tickets, count on objectives and pay like kills for the round, but stay off the lifetime kill count and the leaderboard.
  - Only Squires while a newcomer is on the server.
- **Phones and tablets get on-screen fight controls:** BLOCK, both SWING sides, STAB, OVERHEAD, KICK, FEINT, DODGE, SPRINT, JUMP and MENU. Dragging the screen turns the camera.
- **Each class starts with its own pair:**
  - Knight: Greatsword + War Hammer
  - Footman: Spear + Shortsword
  - Vanguard: Arming Sword + Shortsword

  Old saves with the lone Shortsword get them.

| File | Studio location | Type | Change |
|---|---|---|---|
| [BotFill.lua](ServerScriptService/Game/BotFill.lua) | ServerScriptService ▸ Game ▸ BotFill | ModuleScript | **new** |
| [TouchInput.lua](ReplicatedStorage/TouchInput.lua) | ReplicatedStorage ▸ TouchInput | ModuleScript | **new** |
| [TouchControls.client.lua](StarterPlayerScripts/TouchControls.client.lua) | StarterPlayer ▸ StarterPlayerScripts ▸ TouchControls | LocalScript | **new** |
| [Bots.lua](ServerScriptService/Combat/Bots.lua) | ServerScriptService ▸ Combat ▸ Bots | ModuleScript | fight bots, objective goal, pathfinding |
| [Game.lua](ServerScriptService/Game/Game.lua) | ServerScriptService ▸ Game ▸ Game | ModuleScript | onBotDeath, spawnCFrameForTeam, fielded |
| [Teams.lua](ServerScriptService/Game/Teams.lua) | ServerScriptService ▸ Game ▸ Teams | ModuleScript | object, botsAlive, fighters |
| [GameServer.server.lua](ServerScriptService/Game/GameServer.server.lua) | ServerScriptService ▸ Game ▸ GameServer | Script | starts BotFill; an asked-for mode isn't voted away |
| [TDM.lua](ServerScriptService/Game/Modes/TDM.lua), [LTS.lua](ServerScriptService/Game/Modes/LTS.lua), [KOTH.lua](ServerScriptService/Game/Modes/KOTH.lua), [Siege.lua](ServerScriptService/Game/Modes/Siege.lua) | ServerScriptService ▸ Game ▸ Modes | ModuleScript | count bots |
| [Tiltyard.lua](ServerScriptService/Game/Modes/Tiltyard.lua) | ServerScriptService ▸ Game ▸ Modes ▸ Tiltyard | ModuleScript | Studio can switch out of it |
| [Training.lua](ServerScriptService/Game/Training.lua) | ServerScriptService ▸ Game ▸ Training | ModuleScript | basic training, placing, skip, harmless dummies |
| [Catalog/Drills.lua](ReplicatedStorage/Catalog/Drills.lua) | ReplicatedStorage ▸ Catalog ▸ Drills | ModuleScript | `basic` steps, shorter goals |
| [CombatServer.lua](ServerScriptService/Combat/CombatServer.lua) | ServerScriptService ▸ Combat ▸ CombatServer | ModuleScript | `Harmless` attackers |
| [CombatClient.lua](ReplicatedStorage/Combat/CombatClient.lua) | ReplicatedStorage ▸ Combat ▸ CombatClient | ModuleScript | touch buttons |
| [HubServer.server.lua](ServerScriptService/Hub/HubServer.server.lua) | ServerScriptService ▸ Hub ▸ HubServer | Script | newcomer routing, first battle, `_G.HubTravel` |
| [LoadoutServer.server.lua](ServerScriptService/Loadout/LoadoutServer.server.lua) | ServerScriptService ▸ Loadout ▸ LoadoutServer | Script | newcomers spawn at once |
| [Profile.lua](ServerScriptService/Loadout/Profile.lua) | ServerScriptService ▸ Loadout ▸ Profile | ModuleScript | tutorial, class pairs, setTutorial |
| [Scoreboard.server.lua](ServerScriptService/Scoreboard.server.lua) | ServerScriptService ▸ Scoreboard | Script | bot kills pay |
| [GameConfig.lua](ReplicatedStorage/GameConfig.lua) | ReplicatedStorage ▸ GameConfig | ModuleScript | botFill, class pairs, STUDIO_NEWCOMER |
| [Training.client.lua](StarterPlayerScripts/Training.client.lua) | StarterPlayer ▸ StarterPlayerScripts ▸ Training | LocalScript | step card, skip, banners, button names |
| [HubMenu.client.lua](StarterPlayerScripts/HubMenu.client.lua) | StarterPlayer ▸ StarterPlayerScripts ▸ HubMenu | LocalScript | first battle note, `_G.HubMenuToggle` |
| [CameraRig.client.lua](StarterCharacterScripts/CameraRig.client.lua) | StarterPlayer ▸ StarterCharacterScripts ▸ CameraRig | LocalScript | FaceYaw, touch look |
| [Movement.client.lua](StarterCharacterScripts/Movement.client.lua) | StarterPlayer ▸ StarterCharacterScripts ▸ Movement | LocalScript | touch buttons |

---

## Before that: new finishers, more pets, everyone sees kill effects

- **Executions are gone** (the R finisher, its menu tab, clips and catalog), and half-sword was dropped. Armor-vs-damage-type from the same change stays.
- **Everyone sees everyone's kill effect.**
  - With streaming on, a client that hadn't streamed the dead body in got nothing, and the effect was lost.
  - The server now sends the body's id, where the effect stands and the body's colours. Without the body, the effect plays there in its colours.
- **Effects now move the body instead of fading it.** Each client hides the real body and moves a local copy of it. The server's ragdoll is never touched.
  - Dragged under by the kraken or a shadow rift
  - Sunk into quicksand or a grave
  - Carried off in the serpent's jaws
  - Sucked piece by piece into the black hole
  - Squashed flat by the anvil or the hand
  - Lifted into the light by Ascension
- **The Grim Crate** (permanent, 80 Crowns) holds 11 new kill effects, each with Pro Sound Effects sounds and its own remains:

  | Rarity | Kill effects |
  |---|---|
  | Common | Poof, Tombstone |
  | Rare | Anvil Drop, Petrify, Quicksand |
  | Epic | Kraken's Grasp, Overgrown, Meteor |
  | Legendary | Serpent's Maw (it spits out the bones), Hand of the Heavens, Black Hole |

- **New remains:** a headstone, a squashed body, a stone statue, a sand mound, a puddle, a flowering mound, a crater, a bone pile. Remains that don't need the body keep their timing even when a player respawns first.
- **16 new companions** with three new bodies (snake, tortoise, crab) and new looks (hedgehog spines, unicorn horn, cobra hood, a tree on a tortoise's shell):
  - Common: Duckling, Tortoise, Shore Crab, Grass Snake, Hedgehog
  - Rare: Corgi, Adder, Snapping Turtle, Red Panda
  - Epic: Royal Cobra, Ember Toad, Coral Crab
  - Legendary: Jade Serpent, Grove Tortoise, Unicorn Foal, and the Basilisk (Royal Egg only)

| File | Studio location | Type | Change |
|---|---|---|---|
| [KillFX.lua](ReplicatedStorage/KillFX.lua) | ReplicatedStorage ▸ KillFX | ModuleScript | 11 new effects, the body puppet, colours fallback |
| [Catalog/KillFX.lua](ReplicatedStorage/Catalog/KillFX.lua) | ReplicatedStorage ▸ Catalog ▸ KillFX | ModuleScript | the Grim Crate's effects |
| [Catalog/Crates.lua](ReplicatedStorage/Catalog/Crates.lua) | ReplicatedStorage ▸ Catalog ▸ Crates | ModuleScript | Grim Crate |
| [Catalog/Calendar.lua](ReplicatedStorage/Catalog/Calendar.lua) | ReplicatedStorage ▸ Catalog ▸ Calendar | ModuleScript | Grim always in rotation |
| [Catalog/Companions.lua](ReplicatedStorage/Catalog/Companions.lua) | ReplicatedStorage ▸ Catalog ▸ Companions | ModuleScript | 16 companions |
| [Companions.lua](ReplicatedStorage/Companions.lua) | ReplicatedStorage ▸ Companions | ModuleScript | snake, turtle, crab bodies; spines, horn, hood, grove |
| [Corpses.lua](ServerScriptService/Combat/Corpses.lua) | ServerScriptService ▸ Combat ▸ Corpses | ModuleScript | new remains; on-time remains after a respawn |
| [Cosmetics.server.lua](ServerScriptService/Hub/Cosmetics.server.lua) | ServerScriptService ▸ Hub ▸ Cosmetics | Script | kill effect sent by id, spot and colours |
| [Cosmetics.client.lua](StarterPlayerScripts/Cosmetics.client.lua) | StarterPlayer ▸ StarterPlayerScripts ▸ Cosmetics | LocalScript | finds the body by id, plays without it |
| [CombatServer.lua](ServerScriptService/Combat/CombatServer.lua) | ServerScriptService ▸ Combat ▸ CombatServer | ModuleScript | executions removed (armor vs damage type kept) |
| Catalog/init, Catalog/Crates, ClientSettings, RigPose, CombatClient, Profile, Economy, HubServer, AdminServer, AdminPanel, HubMenu, RigReplicator, CameraRig, Scoreboard | (as before) | | back to before executions |
| Catalog/Executions, ExecuteRule, Executions.client, Build/ExecutionAnims | | | **deleted** |

In Studio: `ReplicatedStorage ▸ ExecutionAnims` and `ServerStorage ▸ ExecutionAnims` were deleted too. **Save the place.**

---

## Before that: armor vs damage type

- Cuts glance off plate (Heavy ×1.35 protection, with sparks), blunt weapons go through it (Heavy ×0.55), stabs pierce (×0.85–0.9), axes and polearms chop. `CombatServer.ARMOR_VS`; a weapon can set `DAMAGE_TYPE`.

---

## Before that: holstered weapons

- **The weapons you carry are worn on you**, so everyone sees your kit:
  - two-handed swords across the back, hilt over the right shoulder
  - polearms head-up behind the left shoulder
  - one-handers at the left hip, hilt forward
  - a dagger at the right hip
- Each one is a look-only copy, skin included, with no scripts or hitbox.
- Drawing a weapon takes it off the body with a sword-draw sound; putting it away hangs it back on, with a softer sheathe.
- Positions: `SPOTS` in the script.

| File | Studio location | Type | Change |
|---|---|---|---|
| [Holsters.server.lua](ServerScriptService/Loadout/Holsters.server.lua) | ServerScriptService ▸ Loadout ▸ Holsters | Script | **new** |

---

## Before that: smaller themed crates, egg previews, "what's coming" timers

- **Crates are small and themed again.**
  - The permanent crates were finish × every-weapon grids: Hafted had 65 items with 12 legendaries, Bladesmith 46, Royal 24 with 14 legendaries.
  - Each now carries its finishes on a picked few weapons (`CRATE_PICKS` in `scripts/gen_content.py`):

    | Crate | Items | Commons | Rares | Epics | Legendaries |
    |---|---|---|---|---|---|
    | Bladesmith | 18 | 6 | 8 | 3 | 1 |
    | Hafted | 18 | 6 | 6 | 4 | 2 |
    | Royal | 12 | — | 4 | 3 | 5 |

  - The same finishes on other weapons moved to the daily WEAPONS shelf (priced by rarity), so nothing is lost. Skin ids are unchanged, so owned skins stay owned.
  - Every crate is now 11–18 items.
- **Eggs: WHAT'S INSIDE.** Each shelf egg opens a preview of everyone it can hatch: each companion's own chance, whether you have it, and the finish odds.
- **What's coming:** the crates list says "NEW CRATE IN 2d 21h · ROYAL ARMOURY", and the egg shelf "NEW EGG IN … · GRAVE EGG". These count down to the next weekly drop that brings one (`Drops.nextWith`). "Leaves in" timers were already there.

| File | Studio location | Type | Change |
|---|---|---|---|
| [scripts/gen_content.py](../scripts/gen_content.py) | — | Python | `CRATE_PICKS`, `SHELF_PRICE` |
| [Skins.lua](ReplicatedStorage/Catalog/Skins.lua) | ReplicatedStorage ▸ Catalog ▸ Skins | ModuleScript | regenerated |
| [Drops.lua](ReplicatedStorage/Drops.lua) | ReplicatedStorage ▸ Drops | ModuleScript | `nextWith` |
| [HubMenu.client.lua](StarterPlayerScripts/HubMenu.client.lua) | StarterPlayer ▸ StarterPlayerScripts ▸ HubMenu | LocalScript | egg WHAT'S INSIDE, next crate / egg lines |

---

## Before that: music, menu sounds, crate and egg openings

- **Music** (`StarterPlayerScripts ▸ Music`, tracks in `ReplicatedStorage ▸ MusicConfig`, all APM licensed):
  - calm courtly pieces in the Courtyard
  - a low underscore between rounds
  - battle cues in matches
  - frantic strings and drums when a horde wave comes, tense underscore in the breaks
  - a dark chant while a boss lives
  - a win or lose sting when a round ends
  - Moods crossfade, and each list shuffles. A track that won't load is skipped.
- **Menu sounds** (`ReplicatedStorage ▸ UIFX`, every id in one table):
  - every button clicks when pressed and ticks softly on hover (`UIClicks`); close / back has its own sound
- **Crate opening:** a snare roll under the spin and a tick per card that passes (rising as it slows). Then a beat of suspense, a flash in the rarity's colour, a banner ("LEGENDARY!") and a stinger that grows with the rarity.
  - Legendary / Mythic get a first low flash, a bigger banner and a screen shake.
  - A finish shows its own banner, and duplicates add coins.
- **Egg hatching:**
  - Menu: the egg on a dark stage rocks, cracks three times (harder each time, cracks spreading over it), bursts in a white flash, then the rarity reveal.
  - Courtyard Hatchery: the same three cracks, then shell bits fly, the rarity's light flashes and its sting plays.
- **Settings:** new "Music volume" and "Menu sounds" sliders.

| File | Studio location | Type | Change |
|---|---|---|---|
| [UIFX.lua](ReplicatedStorage/UIFX.lua) | ReplicatedStorage ▸ UIFX | ModuleScript | **new**: menu sounds, flash, banner, shake, ticker |
| [MusicConfig.lua](ReplicatedStorage/MusicConfig.lua) | ReplicatedStorage ▸ MusicConfig | ModuleScript | **new**: tracks by mood |
| [Music.client.lua](StarterPlayerScripts/Music.client.lua) | StarterPlayer ▸ StarterPlayerScripts ▸ Music | LocalScript | **new**: the score |
| [UIClicks.client.lua](StarterPlayerScripts/UIClicks.client.lua) | StarterPlayer ▸ StarterPlayerScripts ▸ UIClicks | LocalScript | **new**: button sounds |
| [HubMenu.client.lua](StarterPlayerScripts/HubMenu.client.lua) | StarterPlayer ▸ StarterPlayerScripts ▸ HubMenu | LocalScript | crate spin sounds + reveal, hatch sequence |
| [Pastimes.client.lua](StarterPlayerScripts/Pastimes.client.lua) | StarterPlayer ▸ StarterPlayerScripts ▸ Pastimes | LocalScript | Courtyard hatch: cracks, burst, sting |
| [ClientSettings.lua](ReplicatedStorage/ClientSettings.lua) | ReplicatedStorage ▸ ClientSettings | ModuleScript | Music / Menu sounds sliders |

---

## Before that: reeling after a clean hit

- **Reeling:** after a clean hit the victim can't attack or kick for 0.5 s (`HIT_STUN`), the same for every weapon.
  - They can still block and parry.
  - Example: you land a Zweihander stab, and they can't counter-swing while your sword is still coming back round. Your guard is up before their swing can reach you.
  - Bosses ignore it.

| File | Studio location | Type | Change |
|---|---|---|---|
| [CombatServer.lua](ServerScriptService/Combat/CombatServer.lua) | ServerScriptService ▸ Combat ▸ CombatServer | ModuleScript | `HIT_STUN`, `ReelUntil` gate on attacks and kicks |
| [README.md](README.md) | — | docs | reeling |

---

## Before that: back to the original animations; real sword clangs

- **Your original animations and combat code are back:**
  - The combat client and server, RigPose, CameraRig, NpcAnimator and Bots are restored from the backup (`combat-backup-2026-10-07`).
  - The new animations, arm aiming, hip counter-turn and the AnimSets / BladeSamples modules are gone. (`Build ▸ AnimForge` stays as an unused tool; the Studio folder `ReplicatedStorage ▸ Animations` is no longer read and can be deleted.)
- **Kept, because you asked for them:**
  - First hit wins: a clean hit interrupts the windup or the strike, but not the recovery.
  - Bosses don't flinch.
  - The zero-stamina error fix.
  - The KOTH / Siege rings and the training-ring fix.
- **Better clangs:** parries, blocks and chambers now use real sword-on-sword recordings (two sabres clashing, sword impacts) from the licensed library, instead of crowbar, railroad-hammer and skillet recordings.
  - Parry: bright and sharp.
  - Block: lower and heavier.
  - Chamber: a clash with the blades scraping along.
- **Two-handed swords swing like big blades:** Longsword, Greatsword, Zweihander, Estoc and Executioner use the sword swish (the rapier's family), deeper and fuller, instead of the generic heavy whoosh. Axes, mauls and polearms keep the whoosh.

| File | Studio location | Type | Change |
|---|---|---|---|
| [CombatClient.lua](ReplicatedStorage/Combat/CombatClient.lua), [CombatServer.lua](ServerScriptService/Combat/CombatServer.lua), [RigPose.lua](ReplicatedStorage/RigPose.lua), [CameraRig.client.lua](StarterCharacterScripts/CameraRig.client.lua), [NpcAnimator.client.lua](StarterPlayerScripts/NpcAnimator.client.lua), [Bots.lua](ServerScriptService/Combat/Bots.lua) | Combat / StarterCharacterScripts / StarterPlayerScripts | Module / LocalScript | restored; first-hit / boss rules re-applied |
| AnimSets.lua, BladeSamples.lua | ReplicatedStorage ▸ Combat | ModuleScript | **removed** |
| [SoundBank.lua](ReplicatedStorage/SoundBank.lua) | ReplicatedStorage ▸ SoundBank | ModuleScript | sword clangs; `SwingGreat` for two-handed swords |
| [README.md](README.md) | — | docs | animation sections removed |

---

## Before that (partly undone above)

**Arms stay on, swings across, smooth finish (newest; all 66 clips rebuilt):**
- **Arms never detach:**
  - They turn with your view about their own shoulders, not your eyes.
  - Their reach is held to a few hundredths of a stud. Measured in play: at most 0.07 from the socket.
  - Two-handers nudge both hands (up to 0.45 studs) so the left hand stays on the grip without stretching an arm.
- **Arms follow the camera** up and down. There's no exact crosshair convergence any more; it's close and natural.
- **Horizontal swings** run at shoulder height, arms straight across the body, perfectly level.
- **No drop at the end of a swing:** the follow-through stays nearly level and plays at its natural pace, then settles exactly into the idle pose.

**Attacks go where you aim (newest; all 66 clips rebuilt at 40 fps):**
- **Swings are level:** the blade cuts a flat plane at crosshair height, with the hands at 1.15.
- **Thrusts drive at the crosshair**, and **overheads chop straight down the middle**.
- **Aiming:**
  - With a forged weapon out, the arms and weapon turn with your view about your eyes (`RigPose.aimArms`), in pitch and yaw.
  - The target point is on the crosshair ray, 7 studs past you (`AIM_DIST`): in first person that's simply your look, and in third person (camera over the shoulder) it brings the attack onto the crosshair.
  - Relayed to other players (new `aim` / `aimP` / `aimY` inputs). Bots aim at their target's chest.
- **Measured in play (third person):** right swing 0.4°, stab 0.7°, left swing 2.6°, overhead 3.3° from the crosshair.

**Animation pass 3 (newest; all 66 clips rebuilt):**
- **Overhead:** the hands go up above the head (y 2.1), in front of it, never through it; the blade lies back over the top and chops down.
- **Stab:** the whole body coils to the right with the head on the target, then unwinds as the arms drive the point out.
  - The hips and legs now follow 30% of every torso turn (`AnimSets.HIP_FOLLOW`); feet stay planted.
  - Measured in play: swing torso −49°…+38°, legs ±15°, head ±7°.
- **Block:** a diagonal guard across the body, hands low to the right and the tip up to the left. It covers you without filling your own view.
- **No spin when going back to idle:** every attack starts and ends exactly on the idle pose.
- **Smoother:**
  - All hand motion interpolates through one continuous path. Thrusts used to jump between two hand rules.
  - The fades into, between and out of attacks are longer again: 0.08–0.24 s in, about 0.12 s or more out.

**Objective indicators and Training (newest):**
- **KOTH, Siege ram and capture zones:** a glowing ring on the ground that you can see from inside it.
  - The rim is the holder's colour and flashes when contested.
  - Segments show who's holding it, split by team; a capture fills as it's taken.
  - Dashes spin faster while it's moving or being taken.
  - A light pillar marks it from across the map (hidden while you're in it). The ring rolls with the ram.
  - The KOTH capture area is now the hill's real disc (it was a square box), and the marker reads TAKE / HOLD THE HILL or CONTESTED.
- **Training ring:** a bot you beat now ragdolls with its kill effect, instead of freezing (it was cleared away the moment it died).

| File | Studio location | Type | Change |
|---|---|---|---|
| [AnimForge.lua](ServerScriptService/Build/AnimForge.lua), [AnimSets.lua](ReplicatedStorage/Combat/AnimSets.lua), [CombatClient.lua](ReplicatedStorage/Combat/CombatClient.lua), [CombatServer.lua](ServerScriptService/Combat/CombatServer.lua) | Build / Combat | ModuleScript | animation pass 3 (above) |
| [RigPose.lua](ReplicatedStorage/RigPose.lua), [CameraRig.client.lua](StarterCharacterScripts/CameraRig.client.lua), [Bots.lua](ServerScriptService/Combat/Bots.lua) | ReplicatedStorage / StarterCharacterScripts / Combat | Module / LocalScript | attacks aim at the crosshair |
| [ObjectiveFX.client.lua](StarterPlayerScripts/ObjectiveFX.client.lua) | StarterPlayer ▸ StarterPlayerScripts ▸ ObjectiveFX | LocalScript | **new**: the ground rings |
| [KOTH.lua](ServerScriptService/Game/Modes/KOTH.lua) | ServerScriptService ▸ Game ▸ Modes ▸ KOTH | ModuleScript | disc capture, publishes the hill's state |
| [Siege.lua](ServerScriptService/Game/Modes/Siege.lua) | ServerScriptService ▸ Game ▸ Modes ▸ Siege | ModuleScript | publishes the objective's radius; capture box hidden |
| [Objectives.client.lua](StarterPlayerScripts/Objectives.client.lua) | StarterPlayer ▸ StarterPlayerScripts ▸ Objectives | LocalScript | KOTH marker |
| [Training.lua](ServerScriptService/Game/Training.lua) | ServerScriptService ▸ Game ▸ Training | ModuleScript | fallen ring bots die normally |
| [README.md](README.md) | — | docs | objective indicators |

---

## Before that: forged combat animations, first hit wins, sharper hit sampling

**Follow-up fixes (all 66 clips rebuilt and re-uploaded):**
- **Guard:** blades held upright (swords ~75°, polearms ~62°, daggers ~55°) and the hands low, at chest or belly, instead of a sword levelled at the enemy with the arms raised.
- **Legs:** they move again with a weapon out. The idle and block no longer key the legs, so Roblox's walk cycle drives them, and the hips still counter the torso's turn.
- **No more choppy turning:**
  - The weapon's roll is carried along its path frame to frame, then turned toward the leading edge at a capped rate. Swords lead with whichever edge is nearer.
  - The arms take the smallest turn from frame to frame (no flips) and are rate-limited.
  - Measured worst case per frame: roll 18°, right arm 40°, left arm 38°. Before: up to 170°.

- **New animations for every weapon class.**
  - Six classes, each with its own clips: one-handed blades, one-handed blunt, dagger, two-handed swords, heavy two-handers, polearms.
  - Each class has an idle, a block, a hit flinch, and eight attacks. Underhands now exist for every weapon.
  - The blade travels a real arc round the body, edge first. The left hand holds two-handed grips. The head stays on the target while the torso turns. The legs stay planted.
- **Each swing is timed in three parts.**
  - The windup plays over the real windup.
  - The strike plays over the active phase: 0.3 s at speed 1, the same as before, so balance is unchanged.
  - The follow-through returns to guard over the recovery.
  - Checked in play: the live blade follows the designed arc to within a few degrees.
- **Switch back any time.**
  - Studio: set `ReplicatedStorage ▸ Animations` attribute `Style` = `"Classic"`.
  - The repo backup is branch `backup/combat-before-overhaul` (tag `combat-backup-2026-10-07`).
- **First hit wins.**
  - A clean hit interrupts the target's windup *or* strike, and their own late hit is thrown away.
  - A hit during their recovery doesn't cancel it.
  - **Bosses** (Horde / Siege warlords) don't flinch at all.
- **Hit sampling:** the sweep traces the whole blade every ~0.45 studs. On wide heads (axes, halberds, mauls) it also traces the outer faces, so a hit lands when the leading steel arrives.
- **Fixed:** an error every frame at zero stamina (`InjuryFX`).

| File | Studio location | Type | Change |
|---|---|---|---|
| [AnimForge.lua](ServerScriptService/Build/AnimForge.lua) | ServerScriptService ▸ Build ▸ AnimForge | ModuleScript | **new**: the animations as data, solver, builder, preview; upright guard, frame-to-frame continuity |
| [AnimSets.lua](ReplicatedStorage/Combat/AnimSets.lua) | ReplicatedStorage ▸ Combat ▸ AnimSets | ModuleScript | **new**: weapon → class, Forged / Classic, timing marks, hip counter |
| [BladeSamples.lua](ReplicatedStorage/Combat/BladeSamples.lua) | ReplicatedStorage ▸ Combat ▸ BladeSamples | ModuleScript | **new**: hitbox sample points |
| [CombatClient.lua](ReplicatedStorage/Combat/CombatClient.lua) | ReplicatedStorage ▸ Combat ▸ CombatClient | ModuleScript | forged playback (windup / strike / follow-through), sampling |
| [CombatServer.lua](ServerScriptService/Combat/CombatServer.lua) | ServerScriptService ▸ Combat ▸ CombatServer | ModuleScript | forged NPC playback, strike-span timing, hit flinch for NPCs, first hit wins, bosses don't flinch |
| [RigPose.lua](ReplicatedStorage/RigPose.lua) | ReplicatedStorage ▸ RigPose | ModuleScript | hips counter the animated torso turn |
| [NpcAnimator.client.lua](StarterPlayerScripts/NpcAnimator.client.lua) | StarterPlayer ▸ StarterPlayerScripts ▸ NpcAnimator | LocalScript | same for bots |
| [InjuryFX.client.lua](StarterCharacterScripts/InjuryFX.client.lua) | StarterPlayer ▸ StarterCharacterScripts ▸ InjuryFX | LocalScript | zero-stamina error fixed |
| [scripts/anim_extract.py](../scripts/anim_extract.py), [scripts/upload_anims.py](../scripts/upload_anims.py), [scripts/anim_receiver.py](../scripts/anim_receiver.py), [scripts/upload_asset.py](../scripts/upload_asset.py) | — | Python | export → upload → Studio entries (ids stay out of git) |
| [README.md](README.md) | — | docs | forged animations, first hit wins, sampling |

**Save the place:** the 66 animations (`ReplicatedStorage ▸ Animations`) and the new map pictures (`ReplicatedStorage ▸ MapShots`) exist only in Studio.
