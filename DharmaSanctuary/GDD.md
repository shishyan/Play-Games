# Dirgantara — Game Design Document

**Version:** 0.1  
**Engine:** Roblox  
**Genre:** Social Exploration / Adventure  
**Art Style:** Voxel / Block Art (pixel-accurate palette)  
**Target Audience:** Roblox players aged 10–24, casual to social gamers  
**Tagline:** *"Fly together. Light the sky."*

---

## Table of Contents

1. [Vision & Pillars](#1-vision--pillars)
2. [Core Concept](#2-core-concept)
3. [World Structure](#3-world-structure)
4. [Core Mechanics](#4-core-mechanics)
5. [Player Progression](#5-player-progression)
6. [Social Systems](#6-social-systems)
7. [Items & Cosmetics](#7-items--cosmetics)
8. [Spirits & Unlocks](#8-spirits--unlocks)
9. [Seasons](#9-seasons)
10. [Daily Tasks & Rewards](#10-daily-tasks--rewards)
11. [Monetization](#11-monetization)
12. [Cross-Platform UI](#12-cross-platform-ui)
13. [Audio Design](#13-audio-design)
14. [Economy Overview](#14-economy-overview)
15. [Technical Notes (Roblox)](#15-technical-notes-roblox)
16. [Localization](#16-localization)

---

## 1. Vision & Pillars

**Dirgantara** is a cooperative sky-world exploration game on Roblox. Players become Children of the Sky — luminous beings who fly through voxel realms, collect light, free lost spirits, and form bonds with other players. It draws heavy inspiration from *Sky: Children of the Light* but is rebuilt ground-up for Roblox with a voxel/block art aesthetic.

### Four Core Pillars

| Pillar | What it means |
|---|---|
| **Exploration** | Each realm is a hand-crafted voxel world with secrets, puzzles, and vertical space to fly through |
| **Social** | Cooperation is rewarded. Helping others gives light. Emotes, instruments, and bonding create emergent moments |
| **Progression** | Wings grow stronger. Cosmetics unlock. Bonds deepen. No grind gate — progression feels earned, not purchased |
| **Mastery** | Skilled fliers reach hidden areas. Spirit puzzles reward observation. Endgame is repeatable and meaningful |

---

## 2. Core Concept

Players begin with a dim cape and weak wings. They enter a living sky world, collect **Cahaya** (light), free **Ancestor Spirits** to unlock abilities/cosmetics, and earn **Bintang** (stars) as premium-adjacent currency. Players can form **Ikatan** (bonds) with others — a friendship mechanic that unlocks cooperative rewards.

The game has no combat. Tension comes from **Kegelapan** (darkness zones) that drain light and force cooperation. The endgame — **Puncak Langit** (Sky's Peak) — consumes all Cahaya but yields powerful rewards and resets the journey.

### Core Loop (30-second)
```
Fly → Collect Cahaya → Find Spirits → Unlock Rewards → Bond with Players → Reach Sky's Peak
```

### Session Loop (20-minute)
```
Login → Check Daily Task → Explore Realm → Collect Cahaya → Visit Spirit Shrine → 
Complete 1 Daily Task → Attempt Sky's Peak OR explore seasonal content → Logout
```

---

## 3. World Structure

The world is a vertical sky archipelago. Islands float at different altitude tiers. Players gain altitude as their wings grow stronger.

### Realms (in order of unlock)

| # | Realm Name | Indonesian Name | Vibe | Unlock Condition |
|---|---|---|---|---|
| 1 | **Isle of Dawn** | Pulau Fajar | Tutorial, warm sunrise, gentle winds | Starting area |
| 2 | **Grassland of Whispers** | Padang Bisikan | Rolling voxel hills, firefly fields, hidden caves | Complete Isle of Dawn |
| 3 | **Forest of Echoes** | Hutan Gaung | Dense voxel canopy, light beams, ancient ruins | 2 Wing Levels |
| 4 | **Valley of Triumph** | Lembah Kejayaan | Ruined civilization, large open spaces, darkness zones | 4 Wing Levels |
| 5 | **Wasteland of Bone** | Tanah Tandus | Dark, dangerous, high Kegelapan concentration | 6 Wing Levels |
| 6 | **Vault of Knowledge** | Kubah Pengetahuan | Ancient library in the clouds, glyphs everywhere | 8 Wing Levels |
| 7 | **Sky's Peak** | Puncak Langit | Endgame realm, sacrifice Cahaya for Wing Ascension | 10 Wing Levels |

### Isle of Dawn (Tutorial Realm) — Detail
- Linear path teaching flight, Cahaya collection, spirit interaction
- 3 Ancestor Spirits hidden here
- No Kegelapan
- Ends with first Ikatan opportunity (NPC guide / another real player)

### Sky's Peak (Endgame)
- Players fly upward through storm-like voxel clouds
- Kegelapan intensifies at higher altitudes
- At the summit: sacrifice all Cahaya → wings ascend one tier → earn **Sayap Lencana** (Wing Badge cosmetic)
- Resets the journey without resetting cosmetics — pure prestige loop

---

## 4. Core Mechanics

### 4.1 Flight

Wings are the primary locomotion. All players fly.

| Wing Level | Behavior |
|---|---|
| 1 (Fajar) | Short glide, no sustained flight |
| 2 (Pagi) | Sustained flight, moderate speed |
| 3 (Siang) | Longer boost charge, can reach mid-altitude islands |
| 4 (Sore) | Double boost, can carry one other player |
| 5 (Petang) | Triple boost, enters Sky's Peak range |
| 6–10 (Malam–Puncak) | Cosmetic wings, same as Level 5 flight with visual distinction |

**Boost System:** Wings have a **charge bar** (3–5 segments by level). Each press of Jump/Flap consumes one segment. Charge refills by:
- Walking/standing on ground (slow)
- Being near another player with higher wing level (medium)
- Collecting Cahaya orbs (fast, one charge per orb)

**Carry Mechanic:** Level 4+ players can grab the hand of lower-level players to fly together. Carrier uses 2x charge per boost. Carried player cannot control flight direction but can bail anytime.

### 4.2 Cahaya (Light)

Cahaya is both the resource and the health system.

- Collected as glowing voxel orbs scattered in each realm
- Also collected from freed Ancestor Spirits (one-time per spirit per account, daily respawn for common ones)
- **Kegelapan zones** drain Cahaya at ~1 orb per 3 seconds
- Reaching 0 Cahaya in Kegelapan: player is "extinguished" — cape dims, flight disabled, respawns at last safe area
- Other players can revive extinguished players by standing near them and pressing E/Tap — costs the rescuer 1 Cahaya

**Daily Cahaya Cap:** Players can collect up to **150 Cahaya per day** from world orbs. No cap on Cahaya from bonds/social actions.

### 4.3 Kegelapan (Darkness)

Kegelapan is the primary environmental challenge.

- Dark storm zones visible as voxel shadow-fog
- Some areas require 2+ players to traverse (one carries light, one navigates)
- **Kegelapan Creatures (Naga Gelap):** Shadowy voxel creatures that detect light. If a player has high Cahaya near one, it chases them. Outrun it, or extinguish your own light temporarily to hide. No combat — stealth only.
- Kegelapan zones have hidden chests (Peti Cahaya) with bonus Cahaya/cosmetics

### 4.4 Instruments

Players can equip instruments and perform music in-world. Instruments are cosmetic/social items with real musical function.

| Instrument | Type | Play Style |
|---|---|---|
| Seruling | Flute | Hold instrument, tap notes on screen (5 note buttons) |
| Kendang | Drum | Tap rhythm pads |
| Siter | Plucked string (like kecapi) | Strum animation, melodic |
| Terompet | Trumpet | Hold and blow (hold button = sustain) |
| Angklung | Shaken chime | Shake gesture (mobile gyro) / key press (PC) |

Nearby players hear the music spatially. Playing together with others within range creates **Harmoni** — an aura effect that slowly recharges wing boost for all players in range.

### 4.5 Emotes

Emotes are cosmetic expressions unlocked from spirits or purchased.

Each emote has:
- **Solo version** — plays alone
- **Sync version** — when two bonded players use matching emotes near each other, a shared animation plays

Examples: wave, bow, sit, meditate, point-to-sky, clap, dance.

---

## 5. Player Progression

### 5.1 Wing Levels

Wings are upgraded using **Cahaya Hati** (Heart Light) — a secondary currency earned through social actions and daily tasks (not world collection).

| Level | Cahaya Hati Cost | Unlocks |
|---|---|---|
| 1→2 | 3 | Sustained flight |
| 2→3 | 6 | Mid-altitude access, Forest of Echoes |
| 3→4 | 12 | Carry mechanic |
| 4→5 | 20 | Sky's Peak access |
| 5→6 | 15 | Sayap Tier 2 cosmetics |
| 6→7 | 15 | — |
| 7→8 | 20 | — |
| 8→9 | 20 | — |
| 9→10 | 25 | Puncak Lencana (title + cosmetic badge) |

**Earning Cahaya Hati:**
- Complete a daily task: +1
- Bond (Ikatan) with a new player: +2
- Gift a Cahaya to another player: +0.5 (max 3 per day)
- Revive an extinguished player: +1
- Complete Sky's Peak cycle: +3

### 5.2 Account Levels (Awan Rank)

Separate cosmetic rank displayed on profile. Earns **Awan XP** from all activities.

| Rank | Required XP |
|---|---|
| Awan 1 — Kumulus | 0 |
| Awan 2 — Sirrus | 500 |
| Awan 3 — Nimbus | 1,500 |
| Awan 4 — Cumulonimbus | 4,000 |
| Awan 5 — Altus | 10,000 |

Awan Rank unlocks cosmetic profile borders and lobby emote slots.

---

## 6. Social Systems

### 6.1 Ikatan (Bond)

Ikatan is the core social mechanic — equivalent to friendship/linking.

**Forming an Ikatan:**
1. Approach another player
2. Offer hand (hold E / tap player icon on mobile)
3. Other player accepts
4. Both glow briefly — Ikatan formed
5. Both receive +2 Cahaya Hati

**Ikatan Benefits:**
- See bonded players' glow on the minimap
- Teleport to bonded player's realm (once per 30 min)
- Shared Harmoni radius when near each other
- Gift **Bintang Hati** (Heart Stars) to Ikatan partners only
- Unlock Ikatan-exclusive dual emotes

**Ikatan Limit:** 30 Ikatan max (prevents farming).

### 6.2 Gifts

Players can gift:
- Cahaya Hati (max 3/day to any player)
- Seasonal cosmetic items (if they own multiples via season pass)
- Bintang Hati (special gifting currency, earned via Ikatan milestones)

Gifting UI shows a floating voxel package — visual moment in-world.

### 6.3 Realm Chat & Expressions

No free text chat by default (Roblox policy safe for under-13). Communication via:
- Expression bubbles (preset phrases + emoji-like icons)
- Emotes
- Instruments
- Pointing (look-direction + point gesture)
- Nod / Shake head (simple social cue)

Players with verified age in Roblox settings get access to safe text chat (filtered by Roblox's own system).

---

## 7. Items & Cosmetics

All cosmetics are purely visual. No pay-to-win.

### Categories

| Category | Examples |
|---|---|
| **Cape** | Size, shape, pattern, particle trail |
| **Mask / Face** | Carved voxel masks, face paint |
| **Hair** | Block-style hair, crown shapes |
| **Outfit** | Full body voxel costume |
| **Wing Skin** | Visual skin over any wing level |
| **Instrument Skin** | Reskin instrument appearance |
| **Emote** | Animation cosmetic |
| **Trail** | Light trail left behind when flying |
| **Aura** | Standing/idle particle glow |
| **Prop** | Lanterns, banners, parasols (held or floating) |

### Rarity Tiers

| Tier | Color | Source |
|---|---|---|
| Biasa (Common) | White | Daily tasks, world exploration |
| Langka (Rare) | Blue | Season pass, Ancestor Spirits |
| Epik (Epic) | Purple | Sky's Peak reward, event |
| Legendaris (Legendary) | Gold | Limited-time event, Robux purchase |

---

## 8. Spirits & Unlocks

### 8.1 Ancestor Spirits

Fixed spirits scattered across all realms. Each grants a cosmetic OR ability emote when freed. Freeing = find the spirit (glowing voxel silhouette), collect its memory fragments (3–5 scattered nearby), return to the spirit to free it.

Each realm has ~6–10 Ancestor Spirits. Total: ~60 across all realms.

**Freeing reward:** Cahaya orbs + one cosmetic/emote/wing upgrade.

Freed spirits appear in the player's **Galeri Roh** (Spirit Gallery) — a personal museum where they can re-watch the spirit's story vignette (short cutscene told through voxel diorama).

### 8.2 Season Spirits

Each season adds 5–7 new spirits tied to the seasonal story. Season spirits:
- Follow the player around when summoned (toggle in menu)
- Grant seasonal cosmetics
- Unlock seasonal emotes
- Expire in availability when season ends (but unlocked items stay)

### 8.3 Daily Spirits

Two spirits respawn every day in random realm locations. Finding and touching them grants:
- +5 Cahaya
- +0.5 Cahaya Hati

These do not give cosmetics. They are pure resource nodes for daily players.

---

## 9. Seasons

Seasons last ~10 weeks. Each season has:

- **Seasonal Realm Extension:** A new area added to an existing realm with seasonal theme
- **5–7 Season Spirits:** Each with cosmetics and a story beat
- **Season Pass** (see Monetization)
- **Season Quest Chain:** 7-step narrative quest line (one quest per seasonal area visit)
- **Limited-time Events:** Mid-season 3-day special event with unique cosmetics

### Season Structure

| Week | Content Beat |
|---|---|
| 1–2 | Season launch, seasonal realm unlocks, first 2 spirits |
| 3–4 | Spirits 3–4, mid-season event preview |
| 5–6 | Mid-season event (3-day), spirit 5 |
| 7–8 | Spirits 6–7, season finale quest unlocks |
| 9–10 | Season finale, final cosmetics, teardown preview |

### Example Season Names (thematic)
- Musim Hujan Bintang (Season of Starfall)
- Musim Fajar Abadi (Season of Eternal Dawn)
- Musim Kabut Pelangi (Season of Rainbow Mist)

---

## 10. Daily Tasks & Rewards

Daily tasks reset at **00:00 UTC+7 (WIB)** — localized display per player timezone.

### 10.1 Task Structure

Each day players get **5 Daily Tasks** (3 easy, 1 medium, 1 hard). Complete all 5 for a **Full Clear Bonus**.

### 10.2 Task Examples

**Easy Tasks (any 3 from pool):**
- Collect 20 Cahaya orbs
- Use 3 emotes near other players
- Visit 2 different realms
- Play any instrument for 30 seconds
- Revive 1 extinguished player
- Offer hand to 1 new player
- Find 1 Daily Spirit
- Fly for 60 seconds without touching ground
- Complete 1 spirit memory fragment set

**Medium Tasks (any 1 from pool):**
- Collect 60 Cahaya in one session
- Play music with 2+ other players at once
- Navigate through a Kegelapan zone without being extinguished
- Form 1 new Ikatan
- Find all Daily Spirits today
- Free 1 Ancestor Spirit

**Hard Tasks (any 1 from pool):**
- Reach Sky's Peak and descend
- Complete a full realm without being extinguished
- Carry another player through a full realm
- Create a 4-player music session with Harmoni active for 2 minutes
- Collect 100 Cahaya in one session

### 10.3 Daily Reward Table

| Completion | Reward |
|---|---|
| 1 task | +5 Cahaya |
| 2 tasks | +10 Cahaya |
| 3 tasks | +1 Cahaya Hati |
| 4 tasks | +15 Cahaya + cosmetic fragment |
| 5 tasks (Full Clear) | +2 Cahaya Hati + **Daily Chest** |

**Daily Chest** contains one of:
- Common cosmetic item
- Seasonal currency (Koin Musim, 20–50)
- Rare cosmetic fragment (3 fragments = 1 Rare cosmetic)
- Extra Cahaya bundle (30)

### 10.4 Weekly & Monthly Milestones

**Weekly Milestone:** Complete Full Clear 5 out of 7 days → **Hadiah Mingguan** (Weekly Gift): 1 Rare cosmetic item or 100 Koin Musim.

**Monthly Milestone:** Complete Weekly Milestone 3 out of 4 weeks → **Hadiah Bulanan** (Monthly Gift): 1 Epic cosmetic item.

### 10.5 Daily Login Streak

Separate from tasks. Just logging in counts.

| Streak Day | Reward |
|---|---|
| Day 1 | 10 Cahaya |
| Day 3 | 20 Cahaya |
| Day 7 | 50 Cahaya + 1 Cahaya Hati |
| Day 14 | 100 Cahaya + 1 Rare cosmetic |
| Day 30 | 200 Cahaya + 3 Cahaya Hati + 1 Epic cosmetic |
| Day 60 | Legendaris cosmetic (cape) |

Streak breaks if player misses a calendar day. Streak grace period: 1 day per 30-day streak (earned, max 3 grace days).

---

## 11. Monetization

Dirgantara uses ethical monetization — no pay-to-win, no loot box gambling, no Cahaya/wing-level purchases.

### 11.1 Robux Purchases

| Item | Robux | Notes |
|---|---|---|
| **Musim Pass** (Season Pass) | 499 R$ | See below |
| **Musim Pass+** (Premium Season Pass) | 899 R$ | Instant unlock of first 3 spirits |
| **Bintang Pack** (cosmetic bundles) | 99–499 R$ | Curated 2–5 item bundles, no random |
| **Single Legendary cosmetic** | 299–599 R$ | Clearly shown before purchase |
| **Starter Pack** (one-time) | 199 R$ | Only offered to new players first 7 days |
| **Extra Daily Chest** (once per day) | 49 R$ | Guaranteed Rare+ |

**No:** random loot boxes, Cahaya for Robux, wing level purchases, realm unlock purchases.

### 11.2 Season Pass — Musim Pass

Two tiers:

**Musim Pass (499 R$):**
- Access to all 5–7 Season Spirits
- Season cosmetic set (outfit, cape, trail)
- 2x Koin Musim earn rate from daily tasks
- Exclusive seasonal instrument skin

**Musim Pass+ (899 R$):**
- All Musim Pass rewards
- Instant unlock of Spirits 1–3 (no need to find them in-world — still get story vignettes)
- Bonus exclusive "Legendaris" seasonal cosmetic
- 1 extra Daily Chest per day during season

Free players:
- Can still find and interact with Season Spirits in-world but cannot free them without the pass
- Earn seasonal cosmetics at 1/3 the rate via Koin Musim from daily tasks (can buy seasonal items from Musim Shop)

### 11.3 Musim Shop (Seasonal Currency Shop)

**Koin Musim** earned from daily tasks (even without pass). Cannot be purchased directly.

Seasonal items in Koin Musim shop:
- 3–5 cosmetics per season available for Koin Musim
- Prices: 80–300 Koin Musim per item
- Free players earn ~150 Koin Musim/week with consistent daily tasks → can buy 1–2 seasonal items per season

### 11.4 Roblox Premium Integration

Players with **Roblox Premium** subscription get:
- +10% Cahaya collection rate
- Exclusive monthly cosmetic frame (profile border)
- Daily login bonus: +10 Cahaya extra
- Premium badge in-game (visual only, no gameplay advantage)

### 11.5 Limited-Time Events (Robux)

During mid-season events (3 days):
- Special event cosmetics available for Robux (clear price, not random)
- These are not re-released until anniversary events
- Event quests still completable for free

---

## 12. Cross-Platform UI

Dirgantara targets: **PC, Mobile (Phone & Tablet), Console (Xbox)**. UI scales and adapts per platform.

### 12.1 UI Design Principles

- **Large touch targets** on mobile (minimum 48x48 px logical)
- **No mandatory hover states** — all info accessible on tap/click
- **Minimal persistent HUD** — world is the UI
- **Voxel-style UI panels** — UI matches game art (chunky pixels, block borders)
- **High contrast** — accessible color palette, no red/green-only distinctions

### 12.2 HUD Elements (always visible)

| Element | Position | Mobile | PC | Console |
|---|---|---|---|---|
| Wing Charge Bar | Bottom center | Large segmented bar | Same | Same |
| Cahaya Counter | Top left | Icon + number | Same | Same |
| Compass / Realm Name | Top center | Minimal text | Same | Same |
| Social Pulse | Bottom right | Avatar icons | Same | Same |

Social Pulse: shows nearby bonded players with their glow color. Tap/click to see name.

### 12.3 Controls

| Action | PC | Mobile | Console (Xbox) |
|---|---|---|---|
| Fly / Flap | Space | Jump button (right side) | A button |
| Sprint / Boost | Shift | Hold Jump | RT |
| Interact / Offer Hand | E | Tap player | X button |
| Emote Wheel | Q | Swipe up on avatar | D-pad up |
| Instrument | T | Instrument icon | Y button |
| Map | M | Map icon (top right) | View button |
| Menu / Inventory | Esc | Menu icon | Menu button |

### 12.4 Mobile-Specific UI

- **Floating Action Button** (bottom right): Context-sensitive — shows relevant action for nearest interactable
- **Swipe navigation** for menus instead of tabs
- **Pinch-zoom** minimap
- **Auto-orbit camera** — camera follows movement direction, player can swipe to look around
- **Instrument mode**: takes over screen with large note buttons / rhythm pads
- **Gyroscope Angklung**: optional setting (default off)

### 12.5 Tablet UI

Tablet gets wider layout:
- Left side: wing charge + movement
- Right side: action buttons
- More minimap real-estate
- Instrument mode shows full layout (all 5 note buttons comfortable)

### 12.6 Accessibility

- UI Scale slider (75%–150%)
- Colorblind modes: Protanopia, Deuteranopia, Tritanopia presets
- Reduce Motion toggle (disables screen shake, reduces particle volume)
- Text size override (Small / Default / Large)
- All emotes labeled with text tooltip
- Subtitles for all story vignettes

---

## 13. Audio Design

### Music Philosophy
Adaptive, generative ambient score. Music shifts based on realm, altitude, and whether other players are near.

- **Solo:** Sparse, melodic — solo flute/seruling lead
- **Near other players:** Adds harmonic layers, percussion builds
- **Kegelapan zones:** Music inverts — atonal drones, tension
- **Sky's Peak:** Full orchestral swell with gamelan undertones
- **Instrument sessions:** Player instruments blend into the ambient track in real-time

### Sound Design
- All world objects have voxel-appropriate sounds (chunky block impacts, bubbly Cahaya collection chimes)
- Wing flap has satisfying whoosh scaled to wing level
- Kegelapan creatures emit low, resonant growl that grows as they approach
- Revive animation plays warm bell tone

---

## 14. Economy Overview

### Currencies Summary

| Currency | Earn Method | Spend Method | Can Buy with Robux? |
|---|---|---|---|
| **Cahaya** | World orbs, daily tasks | Wing level upgrades (Cahaya Hati conversion), Galeri Roh | No |
| **Cahaya Hati** | Social actions, daily tasks, Sky's Peak | Wing level upgrades | No |
| **Koin Musim** | Daily tasks, season quests | Musim Shop seasonal items | No |
| **Bintang Hati** | Ikatan milestones | Gift to Ikatan partners only | No |
| **Robux** | Real money | Musim Pass, Legendaris cosmetics, Bintang Packs | — |

### Economy Health Targets
- A free daily player completes Wing Level 5 in ~3–4 weeks of consistent play
- A free casual player (3 days/week) completes Wing Level 5 in ~8 weeks
- Paid players get cosmetics faster but reach the same gameplay milestones at the same speed
- No currency exchange between players (prevents inflation/farming exploits)

---

## 15. Technical Notes (Roblox)

### 15.1 Project Structure
```
src/
  server/       — DataStore, economy, session management, anti-cheat
  client/       — UI, input, camera, flight, audio
  shared/       — Constants, types, realm configs, spirit data
src/assets/     — Voxel models, sound IDs, particle configs
```

### 15.2 Key Systems to Implement

| System | Notes |
|---|---|
| **Flight Controller** | Client-side prediction, server validation of position. Prevents teleport exploits |
| **Cahaya DataStore** | Per-player daily cahaya counter with UTC+7 reset. Server-authoritative |
| **Wing Level DataStore** | Persistent, server-only writes |
| **Realm Loading** | Each realm is a separate Place via Teleport Service. Shared DataStore across places |
| **Ikatan Graph** | Server-side adjacency list stored per player. Max 30, bidirectional |
| **Daily Task Engine** | Server generates task set from pool at first login each day. Tracks per-player progress |
| **Season Manager** | Server-side config drives season state. One active season at a time |
| **Instrument Audio** | Client-side instrument playback, SoundService remote events broadcast to nearby clients |
| **Kegelapan Zone** | Server-defines zones via Region3 or Part detection. Client dims visuals. Server tracks drain |

### 15.3 Anti-Exploit

- All Cahaya collection validated server-side (position check — player must be near orb)
- Wing charge bar replicated server-side; client cannot self-grant boost
- Daily task completion server-validated (not just client-reported)
- Ikatan formation requires server handshake (both players must be in range and active)

### 15.4 Performance Targets

| Platform | Target FPS | LOD Strategy |
|---|---|---|
| PC (High) | 60 FPS | Full voxel detail |
| PC (Low) / Console | 30–60 FPS | Reduce distant voxel chunk count |
| Mobile (High-end) | 30–60 FPS | Medium chunk render distance |
| Mobile (Low-end) | 30 FPS | Aggressive LOD, reduced particles |

Voxel models use **MeshPart** or **Union** with simplified collision. Large realm terrain uses **Terrain API** for ground surfaces.

### 15.5 Wally Packages (recommended)

| Package | Use |
|---|---|
| `roblox/promise` | Async operations |
| `sleitnick/signal` | Custom events |
| `sleitnick/component` | Component pattern for game objects |
| `evaera/maid` | Cleanup/lifecycle |
| `osyrisrblx/t` | Runtime type checking |

---

## 16. Localization

Dirgantara uses **Roblox's built-in LocalizationService** as the foundation. All player-facing strings go through the localization pipeline — no hardcoded text anywhere in UI or scripts.

### 16.1 Supported Languages

Two tiers. Tier 1 ships at launch. Tier 2 ships within Season 1 window.

| Tier | Language | Locale Code | Script | Direction | Notes |
|---|---|---|---|---|---|
| **1** | English | `en` | Latin | LTR | Default / fallback |
| **1** | Indonesian | `id` | Latin | LTR | Primary culture of game |
| **1** | Japanese | `ja` | CJK (Kanji + Kana) | LTR (vertical alt) | Large Roblox JP playerbase |
| **1** | Arabic | `ar` | Arabic | **RTL** | Full RTL layout flip required |
| **1** | Chinese Simplified | `zh-cn` | CJK (Hanzi) | LTR | Mainland China playerbase |
| **2** | Chinese Traditional | `zh-tw` | CJK (Hanzi) | LTR | Taiwan / HK |
| **2** | Korean | `ko` | Hangul | LTR | |
| **2** | Portuguese (Brazil) | `pt-br` | Latin | LTR | Largest Roblox market in LAM |
| **2** | Spanish | `es` | Latin | LTR | |
| **2** | French | `fr` | Latin | LTR | |
| **2** | German | `de` | Latin | LTR | |

### 16.2 Roblox Localization Setup

**LocalizationTable** lives in `ReplicatedStorage`. All string keys are loaded client-side via `LocalizationService:GetTranslatorForPlayerAsync()`.

```
ReplicatedStorage/
  Localization/
    LocalizationTable   ← Roblox LocalizationTable instance
```

**String key convention:** `CATEGORY_SUBCATEGORY_KEY`

```
UI_HUD_CAHAYA           → "Cahaya"
UI_HUD_WING_CHARGE      → "Wing Charge"
UI_MENU_DAILY_TASKS     → "Daily Tasks"
REALM_NAME_ISLE_DAWN    → "Isle of Dawn"
SPIRIT_ISLE_WATCHER_NAME → "Spirit of the Watcher"
DAILY_TASK_COLLECT_CAHAYA → "Collect {count} Cahaya"
NOTIFY_IKATAN_FORMED    → "{playerName} formed a bond with you!"
SEASON_PASS_TITLE       → "Musim Pass"
ERROR_WING_TOO_LOW      → "Reach Wing Level {level} to enter this realm."
```

All keys use **named parameters** in braces `{paramName}` — never positional `%1` — because word order differs across languages.

### 16.3 Translation Workflow

```
Developers write strings in English (en)
       ↓
Export CSV from Roblox LocalizationTable
       ↓
Manual translation: id, ar (Tier 1 priority)
       ↓
Roblox AutoTranslate: ja, zh-cn, zh-tw, ko, pt-br, es, fr, de
       ↓
Native speaker review pass (especially ja, ar, zh-cn)
       ↓
Import back to LocalizationTable
       ↓
QA: text overflow, RTL layout, encoding
```

**Indonesian (id)** strings are written by the dev team directly — it is the game's source culture. English is the technical default/fallback, but Indonesian strings get human-authored treatment equal to English.

**Auto-translate caveat:** Roblox AutoTranslate is adequate for UI labels. All narrative strings (spirit vignette subtitles, season quest text) require human review before shipping.

### 16.4 Font Strategy

Roblox's `Font` enum does not support all scripts natively. Use `FontFace` with fallback chains.

| Script | Recommended Font | Fallback |
|---|---|---|
| Latin (en, id, pt-br, es, fr, de) | `GothamSsm` (default Roblox) | `Arial` |
| CJK (ja, zh-cn, zh-tw, ko) | `SourceHanSans` (via AssetID) | `Arial` (glyphs missing — avoid) |
| Arabic (ar) | `NotoSansArabic` (via AssetID) | No good fallback — must load asset |

**Implementation:** Load locale-appropriate font on `LocalizationService.RobloxLocaleId` change. Font assets preloaded via `ContentProvider:PreloadAsync()` on startup.

```lua
-- shared/Fonts.luau
local FONTS = {
    ["ar"] = "rbxassetid://ARABIC_FONT_ID",
    ["ja"] = "rbxassetid://CJK_FONT_ID",
    ["zh-cn"] = "rbxassetid://CJK_FONT_ID",
    ["zh-tw"] = "rbxassetid://CJK_FONT_ID",
    ["ko"] = "rbxassetid://CJK_FONT_ID",
}
-- All others: default GothamSsm
```

### 16.5 RTL Layout (Arabic)

Arabic requires **full UI mirror**. Every horizontal layout flips.

**Rules:**
- All `HorizontalAlignment` values flip: `Left` ↔ `Right`
- All `AnchorPoint` X values flip: `0` ↔ `1`
- Flex/list layouts set `FillDirection` based on locale
- Icons that convey direction (arrows, "next" chevrons) flip horizontally
- Icons that are symbolic (star, heart, wing) do NOT flip
- HUD element positions mirror (Cahaya counter moves to top right, Social Pulse to bottom left)
- Text alignment inside labels: always `RichText` with `TextXAlignment.Left` for LTR, `Right` for RTL — never `Center` for body text

**Implementation pattern:** A global `LayoutDirection` value in `ReplicatedStorage` set to `"LTR"` or `"RTL"` on client startup. All UI components read this and adjust. Never hardcode pixel offsets — use constraints.

```lua
-- client/UI/LayoutDirection.luau
local locale = LocalizationService.RobloxLocaleId
local RTL_LOCALES = { ["ar"] = true }
return RTL_LOCALES[locale] and "RTL" or "LTR"
```

### 16.6 Text Expansion Budget

Translated text is almost always longer than English. UI must not clip or overflow.

| Source Language | Typical Expansion vs English |
|---|---|
| Indonesian | +10–20% |
| German | +20–35% |
| French | +15–25% |
| Arabic | +20–30% (also taller due to diacritics) |
| Japanese | −10 to +5% (dense glyphs, usually shorter) |
| Chinese | −20 to −10% (very dense, shorter) |

**Design rules:**
- All UI text containers use `AutomaticSize = Y` (vertical expansion) — never fixed height for text
- Button widths use `AutomaticSize = X` with a `UIPadding` constraint — never fixed-width label buttons
- HUD counters (Cahaya count, wing charge segments) are number-only — no expansion risk
- Max line width on mobile: 80% screen width. Text wraps, never clips.
- Any string longer than 40 characters (English) must be tested in German and Arabic before shipping

### 16.7 Number, Date & Currency Formatting

Use locale-aware formatting — never raw `tostring()`.

| Data | English (en) | Indonesian (id) | Arabic (ar) | Japanese (ja) |
|---|---|---|---|---|
| Large number | 1,500 | 1.500 | ١٬٥٠٠ | 1,500 |
| Decimal | 1.5 | 1,5 | ١٫٥ | 1.5 |
| Date (reset timer) | May 9, 2026 | 9 Mei 2026 | ٩ مايو ٢٠٢٦ | 2026年5月9日 |
| Time | 11:30 PM | 23.30 | ١١:٣٠ م | 23:30 |

Arabic numerals in `ar` locale use **Eastern Arabic numerals** (٠١٢٣٤٥٦٧٨٩) by default. Provide a setting to switch to Western (0–9) for players who prefer it.

**Implementation:** A shared `Format.luau` module wraps all number/date formatting with locale dispatch.

```lua
-- shared/Format.luau
local Format = {}

function Format.number(n: number): string
    local locale = LocalizationService.RobloxLocaleId
    -- dispatch to locale-specific formatter
end

function Format.countdown(seconds: number): string
    -- returns "2h 30m" localized
end

return Format
```

### 16.8 In-World Text

- **Realm names** displayed in HUD compass: localized via string key
- **Spirit names** in Galeri Roh: localized
- **Floating damage/effect numbers** (Cahaya collected): numbers only, no localization needed
- **Instrument note labels** (if shown): use universal musical notation (A, B, C…) — not localized, music is universal
- **NPC expression bubbles / preset phrases:** fully localized (these are the primary "chat" for under-13 players)
- **Player-entered names** (Ikatan gift messages, if added later): pass through Roblox text filter per locale — never bypass

### 16.9 Preset Expression Phrases (Localized)

The expression bubble system (Section 6.3) ships with 20 preset phrases. All must be localized across all Tier 1 languages.

| Key | English | Indonesian | Japanese | Arabic | Chinese (Simplified) |
|---|---|---|---|---|---|
| `EXPR_HELLO` | Hello! | Halo! | こんにちは！ | مرحباً! | 你好！ |
| `EXPR_FOLLOW_ME` | Follow me! | Ikuti aku! | ついてきて！ | تعال معي! | 跟我来！ |
| `EXPR_THANK_YOU` | Thank you! | Terima kasih! | ありがとう！ | شكراً! | 谢谢！ |
| `EXPR_HELP_ME` | Help me! | Tolong aku! | 助けて！ | ساعدني! | 帮帮我！ |
| `EXPR_WAIT_HERE` | Wait here! | Tunggu di sini! | ここで待って！ | انتظر هنا! | 在这等！ |
| `EXPR_GOOD_JOB` | Good job! | Bagus! | よくやった！ | أحسنت! | 干得好！ |
| `EXPR_LETS_FLY` | Let's fly! | Ayo terbang! | 飛ぼう！ | لنطر! | 一起飞！ |
| `EXPR_SO_PRETTY` | So pretty! | Cantik sekali! | きれい！ | جميل! | 好美！ |

Remaining 12 phrases cover: directions (left/right/up/down), social (come here, look at this, I'll carry you, you carry me), and reactions (wow, amazing, oops, sorry).

### 16.10 Cultural Considerations

| Culture | Consideration |
|---|---|
| **Indonesian (id)** | Game's primary theme. Gamelan instruments, wayang shadow aesthetics in spirit designs. Ramadan seasonal event candidate. |
| **Japanese (ja)** | Vertical text optional for spirit vignette titles (decorative only). Torii gate motifs in seasonal realm extension. Avoid white-only death screens — associate white with mourning in some contexts. |
| **Arabic (ar)** | Avoid imagery of chess pieces, dogs, or bare-limb characters in cosmetics marketed to this region. Ramadan event resonates strongly. Prayer time notification opt-in (system-level, not in-game). |
| **Chinese (zh-cn / zh-tw)** | Red = luck/positive (use for rewards, not danger). White = mourning (avoid for "success" banners). Number 4 considered unlucky — avoid "4-player" featured bundle pricing. |
| **All** | No religious iconography in core cosmetics. Seasonal events use nature/celestial themes, not religious ones, to stay inclusive. |

### 16.11 QA Checklist for Localization

Before each season launch, run through:

- [ ] All new string keys have translations for all Tier 1 languages
- [ ] Arabic layout tested on portrait mobile (RTL flip complete)
- [ ] No text overflow on German or Arabic strings in any UI panel
- [ ] CJK font loaded and renders correctly on mobile (low-end device test)
- [ ] Countdown timers show correct locale date format
- [ ] Preset expression phrases reviewed by native speaker (at least id, ar, ja)
- [ ] Spirit vignette subtitles reviewed by native speaker (id, ar, ja)
- [ ] Eastern Arabic numeral toggle tested
- [ ] No hardcoded English strings introduced in new UI components
- [ ] `Format.number()` and `Format.countdown()` called for all displayed numbers

---

## Appendix A — Spirit Story Themes (Isle of Dawn)

| Spirit | Theme | Cosmetic Reward |
|---|---|---|
| Spirit of the Watcher | Observation, patience | Binocular prop / Telescope emote |
| Spirit of First Flight | Courage, leaping into the unknown | Trail: Feather Burst |
| Spirit of the Lantern | Guiding others through darkness | Prop: Lantern (floating) |

---

## Appendix B — Seasonal Roadmap (Year 1)

| Season | Theme | Duration |
|---|---|---|
| Season 1 | Musim Hujan Bintang (Starfall) | Weeks 1–10 |
| Season 2 | Musim Fajar Abadi (Eternal Dawn) | Weeks 11–20 |
| Season 3 | Musim Kabut Pelangi (Rainbow Mist) | Weeks 21–30 |
| Season 4 | Musim Bayang Langit (Sky Shadow) | Weeks 31–40 |

---

*Dirgantara GDD v0.1 — Draft for development kickoff. All names, values, and structures subject to iteration.*
