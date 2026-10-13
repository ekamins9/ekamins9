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

Create these (an icon each; 512×512 works). Then put each badge's id into Studio: **ServerStorage ▸ BadgeIds ▸ \<key\>**, in the IntValue's Value. A badge left at 0 is simply skipped. Players who already earned one get it the next time they join.

| Key (IntValue) | Badge name | Description |
|---|---|---|
| Welcome | Welcome to Steel & Glory | You came to fight. |
| Graduate | Graduate | Finished basic training with Sir Aldric. |
| FirstBlood | First Blood | Your first kill in battle. |
| FirstWin | First Victory | Your first round won. |
| Level5 | Bow and Staff | Reached level 5: the Archer and the Mage are yours. |
| Level25 | Veteran | Reached level 25. |
| Champion | Champion Slayer | Beat a Champion in the sparring ring. |
| Gauntlet10 | Iron Will | Survived ten waves of the Gauntlet. |
| Mythic | Touched by Legend | Pulled a Mythic out of a crate. |
| BetaTester | Beta Tester | Played Steel & Glory before the gates opened. |

## 3. Store page

- [ ] **Maturity & compliance questionnaire** (Creator Dashboard ▸ your experience ▸ Audience). Answer it honestly:
  - Violence: melee combat and blood; heads come off.
  - Paid random items: crates for Crowns, with odds shown. In regions that bar them, crates open only with Keys earned by play.
- [ ] **Icon** (512×512) and **thumbnails** (1920×1080). Take Studio screenshots, for example:
  - a clash in the Colosseum;
  - a Mage with the Staff of the Cosmos;
  - an archer in Phoenixborn;
  - the Courtyard full of players.
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
