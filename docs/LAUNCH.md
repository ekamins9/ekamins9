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

- [ ] **Maturity & compliance questionnaire** (Creator Dashboard ▸ your experience ▸ Audience). Answer it honestly:
  - Violence: melee combat and blood; heads come off.
  - Paid random items: crates for Crowns, with odds shown. In regions that bar them, crates open only with Keys earned by play.
- [ ] **Icon** (512×512): `store_art/icon.png` (the Lionheart helm, eyes burning in the visor, swords crossed behind).
- [ ] **Thumbnails** (1920×1080), in this order (the first one is what most people see):
  1. `store_art/thumb4_classes.png`: "5 CLASSES / PICK YOUR FIGHTER", the line-up, each class named.
  2. `store_art/thumb1_clash.png`: "STEEL & GLORY / EVERY SWING IS YOURS", two knights' blades locked at sunset.
  3. `store_art/thumb5_siege.png`: "STORM THE CASTLE / 6 BATTLE MODES", the Crown's charge, the castle burning.
  4. `store_art/thumb2_mage.png`: "MASTER MAGIC / FIRE • LIGHTNING • FROST", the Star Sage's fireball.
  5. `store_art/thumb3_archer.png`: "HEADSHOT! / BOWS • CROSSBOWS", Phoenixborn drawing a burning arrow.

  They're rendered in Blender from the game's own armor sets, weapons and staffs (`blender/store_art.py`, see its header to re-render one or change a title). Once real players are in, a screenshot of a packed Courtyard or Siege makes a good sixth.
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

## 5. After launch: what to watch (Creator Dashboard ▸ Analytics)

- **Onboarding funnel:** Joined → Basic training begun → Ready for battle → First battle fought → First crate opened → Level 2 → Level 5 → Level 10. The biggest drop is the first thing to fix.
- **Economy:** where Marks, Crowns and Keys come from and go (rounds, tasks, level-ups, rewards; crates, the shop, the pass).
- **Custom events:**
  - `RoundPlayed`, by mode / won or lost / server type;
  - `CrateOpened`, by crate / rarity / kind;
  - `Trade`.
