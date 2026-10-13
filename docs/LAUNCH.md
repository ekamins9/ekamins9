# Launch checklist: Steel & Glory

What's left before launch is for you: things in the Creator Dashboard, and things that need a person playing. The code side is done (see `roblox/UPDATED_SCRIPTS.md`).

## 1. Save and publish

- [ ] In Studio: **File ▸ Save to Roblox**. This saves the Studio-only pieces:
  - the archer outfit meshes;
  - the rebuilt training yard;
  - the Ranks icon;
  - the badge-id slots.
- [ ] **Game Settings ▸ Security ▸ Allow Studio access to API services: ON**. Without it, Studio can't load or save profiles, so you can't test saving, trading or crates in Studio. Live servers don't need it.
- [ ] Publish.

## 2. Badges (Creator Dashboard ▸ your experience ▸ Monetization ▸ Badges)

Create these, each with its picture from **`store_art/badges/badge_<Key>.png`** (512×512; Roblox shows badges in a circle, and the medallions are drawn for that). Then put each badge's id into Studio: **ServerStorage ▸ BadgeIds ▸ \<key\>**, in the IntValue's Value. A badge left at 0 is simply skipped. Players who already earned one get it the next time they join.

| Key (IntValue) | Badge name | Description | Picture |
|---|---|---|---|
| Welcome | Welcome to Steel & Glory | You came to fight. | a keep flying a flag (bronze) |
| Graduate | Graduate | Finished basic training with Sir Aldric. | sword and round shield (bronze) |
| FirstBlood | First Blood | Your first kill in battle. | a sword striking down, red sparks (silver) |
| FirstWin | First Victory | Your first round won. | a gold trophy (gold) |
| Level5 | Bow and Staff | Reached level 5: the Archer and the Mage are yours. | a bow and the Stormcaller staff (silver) |
| Level25 | Veteran | Reached level 25. | the Lionheart helm, "25" (gold) |
| Champion | Champion Slayer | Beat a Champion in the sparring ring. | a crown run through by a sword (gold) |
| Gauntlet10 | Iron Will | Survived ten waves of the Gauntlet. | an iron shield, "10", in flames (iron) |
| Mythic | Touched by Legend | Pulled a Mythic out of a crate. | a burning red crystal (mythic red) |
| BetaTester | Beta Tester | Played Steel & Glory before the gates opened. | a war hammer, "BETA" (silver) |

## 3. Store page

- [ ] **Maturity & compliance questionnaire** (Creator Dashboard ▸ your experience ▸ Audience). The game is built to be **Mild**, which means all ages: Roblox Kids (5-8), Roblox Select (9-15) and everyone older. The honest answers for the game as it is:

  | Question | Answer | Why |
  |---|---|---|
  | Violence | **Yes · Mild · Repeated** | Sword fights all round, but nothing comes off, nothing bleeds, nobody is impaled. A body drops and fades in seconds. |
  | Blood | **No** | A hit flashes white and gold. The "Crimson" items glow like magic, and names like the Bloodpit aren't blood shown. |
  | Fear | **Yes · Mild · Occasional** | The heartbeat near death, skeleton and reaper kill effects, skull-themed gear. "Repeated" gives the same label if you'd rather. |
  | Crude humor, strong language, romance, alcohol | **No** | The Courtyard's inn is the Hearth & Hound, a cookhouse. No drink anywhere. |
  | Unplayable gambling | **No** | No casino pictures. Crates are a separate question. |
  | Social hangout | **No** | The Courtyard is a lobby; fighting is the game. |
  | Free-form user creation, media sharing, AI | **No** | |
  | Paid random items | **Yes** | Crates open for Crowns, which are bought with Robux; the odds are shown. Where Roblox restricts them (PolicyService), crates open only with Keys earned by playing. |
  | Paid item trading | **Yes** | Items from crates can be traded. Where Roblox restricts it (PolicyService), trading is off. |

  **Never answer Strong.** It makes the game Restricted (age-verified 18+ only), and a Restricted label can never be changed back. If you ever turn `GameConfig.GORE` on, the honest answer becomes Strong, so it has to stay off.

- [ ] **Reach players under 16** (Creator Hub ▸ Audience Reach). A Mild label alone isn't enough: Roblox Kids and Select accounts only see games that passed an extra evaluation. You need:
  - your account age-checked (government ID if you're 18+, a face age estimate if you're under 18);
  - 2-Step Verification on;
  - either Roblox Plus/Premium, or the one-time refundable fee (1,000 Robux, refunded after 90 days).

  (Since May 19, 2026, Roblox's publishing tiers are: **16+ and trusted friends** for an age-checked account in good standing that's 2+ days old; **all ages** on top of that needs ID verification, 2FA, Plus/Premium or the fee, and the evaluation below.)

  Then the game runs a trial with age-checked players 16+ and has to reach **250 unique plays from engaged players within 60 days**. A small sponsored campaign (section 6) is a quick way to get there.
- [ ] **Icon** (512×512): `store_art/icon.png` (the Lionheart helm, eyes burning in the visor, swords crossed behind).
- [ ] **Thumbnails** (1920×1080), in this order (the first one is what most people see):
  1. `store_art/thumb4_classes.png`: "5 CLASSES / PICK YOUR FIGHTER", the line-up, each class named.
  2. `store_art/thumb1_clash.png`: "STEEL & GLORY / EVERY SWING IS YOURS", two knights' blades locked at sunset.
  3. `store_art/thumb5_siege.png`: "STORM THE CASTLE / 6 BATTLE MODES", the Crown's charge, the castle burning.
  4. `store_art/thumb2_mage.png`: "MASTER MAGIC / FIRE • LIGHTNING • FROST", the Star Sage's fireball.
  5. `store_art/thumb3_archer.png`: "HEADSHOT! / BOWS • CROSSBOWS", Phoenixborn drawing a burning arrow.

  They're rendered in Blender from the game's own armor sets, weapons and staffs (`blender/store_art.py`, see its header to re-render one or change a title). Once real players are in, a screenshot of a packed Courtyard or Siege makes a good sixth.

  - **Keep all five "active"** on the Home tab (thumbnail personalization). Roblox shows each to different players and leans toward whichever gets played most; that averages about +8.5% more plays.
  - Roblox's rules: show the real game ("representative of the actual in-game visuals"), nothing important at the bottom edge (the name and rating cover it), and no "best", "#1", prices or offers. These follow them.
- [ ] **Video on the game page** (the first thing people see there): Roblox wants **real gameplay** here, not a rendered trailer. Up to 60 s, 1080p, 100 MB; 3 uploads a month, free.
  - No voice-over and no songs with lyrics; music from Roblox's own library is fine.
  - Record it yourself: in a live server press **Ctrl+H** (all UI hides; again to bring it back) and record with **Win+Alt+R** (Windows Game Bar) or OBS.
  - Good moments to get: a Siege charge, a duel full of parries, a Mage's fireball, a crate opening.
- [ ] **Genre**: Fighting. Max players to match your servers.

**Title:** Steel & Glory

**Description:**

> Every swing is yours to aim. Steel & Glory is a medieval melee game where you aim every swing yourself, then block, parry, feint and kick: the better fighter wins, not the bigger number.
>
> ⚔️ Five classes: the heavy Knight, the Footman, the quick Vanguard, the Archer (bow or crossbow) and the Mage (fire, lightning, frost and a ward of mana)
> 🏰 Siege castles, Team Deathmatch, Free for All, King of the Hill, Last Team Standing, the Horde, and ranked duels in the Lists
> 🛡️ Dozens of armor sets and hundreds of weapon skins, from a peasant's tunic to a phoenix's wings. Crates, a season pass, daily tasks, login gifts, companions and trading
> 🎯 A training yard with three teachers, a sparring ring and the Gauntlet
> 🔥 Weekend events: Double XP, Armory Roulette, Raid Weekends
>
> Learn the basics in two minutes. Spend a lifetime mastering them.
>
> 📜 Play fair: the game's rules are on the board beside the Notice Board in the Courtyard, and in MENU › SETTINGS › THE RULES.

- [ ] **The game's own rules are posted** (done in the game). Roblox's Terms: when a game enforces its own rules, as this one does (staff kick, ban and can take back items), those rules "and any consequences for violating them must be clearly and conspicuously posted within an Experience". They're in three places, all written in `ReplicatedStorage ▸ Rules`:
  - a board beside the Notice Board, where everyone arrives;
  - MENU › SETTINGS › THE RULES;
  - the kick and ban messages themselves.

  **Set the appeal line** (`Rules.APPEAL`): right now it says to message you on Roblox. If you make a group or a support page, put it there. Roblox doesn't handle appeals for a game's own bans; you do.

## 4. Play-test (what I couldn't see)

Studio's window was minimized while I worked, so these were checked in code and Blender renders but never seen moving in a live game:

- [ ] **Staff skins:** equip each (Inventory or Armory ▸ inspect). Do the heads move (orbits, rings, wings, the beating heart, the lightning)? Do spells leave from the head?
- [ ] **Draw animation:** switch weapons. Does the arm reach over the shoulder or to the hip and pull the weapon out cleanly?
- [ ] **Weapon-switch exploit:** spam switch + stab. You should get no faster attacks than with one weapon.
- [ ] **Kill-cam:** die to a bot and to a player. Does the view turn to them smoothly before the death screen?
- [ ] **Archer outfits:** the Bowman on a new Archer; the four Fletcher sets (grant them from the admin panel); the falcon on the shoulder; the Phoenix wings.
- [ ] **Trading with a friend:** trade an armor set and a skin, then both rejoin. Is everything where it should be? (This exercises the new session lock.)
- [ ] **Two servers:** join, buy something, leave and quickly join a different server. Your purchase should be there.
- [ ] **A phone:** the Courtyard and a battle on a cheap phone. Smooth enough?
- [ ] **Newcomer:** a fresh account (or a friend) through the intro, training and the first battle.
- [ ] **Mild kills:** fight bots with every weapon and a bow. A killing blow should drop them with a white-and-gold flash: nothing comes off, no blood, no arrow left in them, and the body gone after a few seconds. Does it still feel good to land?
- [ ] **Clean view:** Ctrl+H in the Courtyard and in a battle. Everything should hide, then come back exactly as it was, with Roblox's own player list still hidden.

## 5. After launch: what to watch (Creator Dashboard ▸ Analytics)

- **Onboarding funnel:** Joined → Basic training begun → Ready for battle → First battle fought → First crate opened → Level 2 → Level 5 → Level 10. The biggest drop is the first thing to fix.
- **Economy:** where Marks, Crowns and Keys come from and go (rounds, tasks, level-ups, rewards; crates, the shop, the pass).
- **Custom events:**
  - `RoundPlayed`, by mode / won or lost / server type;
  - `CrateOpened`, by crate / rarity / kind;
  - `Trade`.

## 6. Ads (Creator Hub ▸ Ads Manager)

**What there is:**
- **Sponsored game:** your tile in the Sponsored row on the Home page and in Discover. Images are 16:9, up to 10 per campaign; Roblox splits views among them and checks each one (usually within a day).
- **Search ads:** your tile on top of search results for words you pick: sword, sword fight, knight, medieval, castle, pvp, fighting, mage, archer.
- **Ads inside other games:**
  - images: 16:9 PNG/JPG, at least 500 px wide;
  - video: MP4/MOV, 15-30 s, 16:9, 720p-1080p, under 100 MB. It plays muted, so the words have to be on screen.

**What to upload** (all in `store_art/`):

| Use | Files |
|---|---|
| Sponsored campaign (all 8; let Roblox find the winners) | `ads/ad_versus.png` (KNIGHT VS MAGE), `ads/ad_parry.png` (PARRY!), `ads/ad_armory.png` (35+ ARMOR SETS), and the five `thumb*.png` |
| Video ads, YouTube, TikTok | `video/trailer.mp4`: 24 s, 1080p, silent, the words on screen (add Roblox-library music if you want sound) |

The ads follow what works on Roblox:
- one subject, big;
- one to three words a child can read at a glance;
- bright colours;
- nothing important at the bottom edge;
- no blood, no "best" or "#1", no prices;
- only the game's real armour, weapons and spells.

**How to run it:**
1. **Start small:** the minimum daily budget for 3-5 days, all eight images, all devices. Roblox says to give a campaign 3-5 days before judging it.
2. **Read the click-through rate (CTR) per image:**
   - about 2-2.5% is average, 3%+ is good, 4%+ is excellent (third-party guides);
   - then watch how many who clicked actually play (qualified play-through rate).
   - Turn off the weakest images and keep 3-5 running.
3. **Fix before you scale.** Roblox recommends games that keep players, so a big spend on a leaky funnel (section 5) is wasted. Raise the budget only once Level 2 and Level 5 in the funnel look healthy.
4. **Early on, aim a small campaign at 16+.** The under-16 evaluation (section 3) needs 250 engaged plays from age-checked 16+ players within 60 days.

New ad pictures: `blender/store_ads.py` (its header says how). The trailer: `blender/store_video.py` (shots, title cards, the edit).

## 7. Safety and privacy (already in the game; what's on you)

**In the game:**
- **Text filtering.** Everything a person types that someone else reads goes through Roblox's filter first (`Safety ▸ TextFilter`): a custom server's name, staff announcements, kick, ban and shutdown reasons, and a title given by staff. Chat is Roblox's own TextChatService, filtered already. Roblox can take down a game that shows unfiltered text, so any new place players can type (clan names, signs, pet names) must use `TextFilter` too.
- **Paid random items and trading** respect Roblox's per-country rules (PolicyService): where restricted, crates open only with Keys earned by playing, and trading is off. The odds show before every open.
- **No off-platform links**, no personal information asked for, and the Mild content rules (section 3).

**On you:**
- [ ] **Data deletion requests (right to be forgotten).** Roblox sends these to your inbox, naming a user ID, and you must delete that player's data. Two parts:
  1. **Once:** set up Roblox's automatic deletion (Creator Hub › your game › Configurations › Data stores manager › **RTBF Deletion** › Create Template). Add one template per row:

     | Type | Data store | Key |
     |---|---|---|
     | Standard Key | Profiles_v2 | `u{UserId}` |
     | Standard Key | Profiles_v1 | `u{UserId}` |
     | Standard Key | AdminQueue_v1 | `u{UserId}` |
     | Standard Key | Bans_v1 | `u{UserId}` |
     | Ordered Key | LB_Warfront | `{UserId}` |
     | Ordered Key | LB_1v1 | `{UserId}` |
     | Ordered Key | LB_2v2 | `{UserId}` |
     | Ordered Key | LB_3v3 | `{UserId}` |

     (From Season 2 the boards are `LB_<season>_Warfront` and so on: add those too.)
  2. **For each request:** their ID also sits inside shared records that no template reaches (staff roles, the ban list, the action log, trade logs). Open the admin panel (F2) › PLAYERS, look up the ID, then **ERASE ALL THEIR DATA**. Only the Owner sees this button. It kicks them everywhere, deletes their keys and scrubs their ID from everything. The log records only that an erasure happened.
- [ ] **Reports.** Check Creator Hub's Safety dashboard now and then for abuse reports.
- [ ] Recommended, not required: Roblox's own Ban API (`Players:BanAsync`) also catches alt accounts. The panel's bans are this game's own; say if you want them moved over.
