# Dirgantara — Product Requirements Document (Technical / Scripting)

**Version:** 0.1  
**Companion to:** GDD.md v0.1  
**Engine:** Roblox (Luau)  
**Toolchain:** Rojo + Wally + Selene + TestEZ  

---

## Table of Contents

1. [Architecture Overview](#1-architecture-overview)
2. [Data Layer — DataStore Schemas](#2-data-layer--datastore-schemas)
3. [Networking — Remotes Catalog](#3-networking--remotes-catalog)
4. [System: Flight](#4-system-flight)
5. [System: Cahaya (Light)](#5-system-cahaya-light)
6. [System: Wing Progression](#6-system-wing-progression)
7. [System: Kegelapan (Darkness)](#7-system-kegelapan-darkness)
8. [System: Naga Gelap AI](#8-system-naga-gelap-ai)
9. [System: Ikatan (Bond)](#9-system-ikatan-bond)
10. [System: Spirits](#10-system-spirits)
11. [System: Daily Tasks](#11-system-daily-tasks)
12. [System: Seasons](#12-system-seasons)
13. [System: Instruments & Harmoni](#13-system-instruments--harmoni)
14. [System: Emotes](#14-system-emotes)
15. [System: Cosmetics & Inventory](#15-system-cosmetics--inventory)
16. [System: Sky's Peak](#16-system-skys-peak)
17. [UI Layer](#17-ui-layer)
18. [Input Abstraction](#18-input-abstraction)
19. [Localization Integration](#19-localization-integration)
20. [Monetization (MarketplaceService)](#20-monetization-marketplaceservice)
21. [Multi-Place Architecture](#21-multi-place-architecture)
22. [Security & Anti-Exploit](#22-security--anti-exploit)
23. [Performance Requirements](#23-performance-requirements)
24. [Error Handling & DataStore Reliability](#24-error-handling--datastore-reliability)
25. [Testing Requirements](#25-testing-requirements)
26. [Dependency Map (Wally)](#26-dependency-map-wally)

---

## 1. Architecture Overview

### 1.1 Folder Structure

```
src/
├── server/
│   ├── init.server.luau          -- bootstraps all server services
│   ├── Services/
│   │   ├── CahayaService.luau
│   │   ├── WingService.luau
│   │   ├── FlightService.luau
│   │   ├── KegelapanService.luau
│   │   ├── IkatanService.luau
│   │   ├── SpiritService.luau
│   │   ├── DailyTaskService.luau
│   │   ├── SeasonService.luau
│   │   ├── InstrumentService.luau
│   │   ├── EmoteService.luau
│   │   ├── CosmeticService.luau
│   │   ├── SkysPeakService.luau
│   │   ├── MonetizationService.luau
│   │   └── DataService.luau
│   └── NPC/
│       └── NagaGelapAI.luau
├── client/
│   ├── init.client.luau
│   ├── Controllers/
│   │   ├── FlightController.luau
│   │   ├── CameraController.luau
│   │   ├── InputController.luau
│   │   ├── UIController.luau
│   │   ├── AudioController.luau
│   │   ├── InstrumentController.luau
│   │   ├── EmoteController.luau
│   │   └── CosmeticController.luau
│   └── UI/
│       ├── HUD.luau
│       ├── DailyTaskPanel.luau
│       ├── IkatanPanel.luau
│       ├── InventoryPanel.luau
│       ├── GaleriRohPanel.luau
│       ├── InstrumentUI.luau
│       ├── EmoteWheel.luau
│       ├── SeasonPanel.luau
│       └── Components/          -- reusable UI pieces
└── shared/
    ├── Types.luau               -- all exported Luau types
    ├── Constants.luau           -- game constants (no magic numbers)
    ├── Remotes.luau             -- typed remote wrappers
    ├── Format.luau              -- locale-aware number/date formatting
    ├── Fonts.luau               -- locale font dispatch
    ├── DailyTaskDefs.luau       -- task pool definitions
    ├── SpiritDefs.luau          -- all spirit static data
    ├── SeasonDefs.luau          -- season config
    ├── WingDefs.luau            -- wing level table
    ├── RealmDefs.luau           -- realm metadata
    └── CosmeticDefs.luau        -- all item definitions
```

### 1.2 Server Authority Principle

> The server owns all game state. The client owns all presentation.

- Client **never** writes to DataStore directly
- Client **never** modifies currency/wing level locally as truth — only as optimistic display pending server confirmation
- All gameplay events (collect orb, free spirit, form Ikatan) fire a `RemoteEvent` to the server; the server validates, mutates state, fires back a confirmation
- Client-side prediction is allowed for **flight only** (position/velocity) — everything else is server-authoritative

### 1.3 Service Boot Order (Server)

```
DataService → SeasonService → CahayaService → WingService →
FlightService → KegelapanService → SpiritService → IkatanService →
DailyTaskService → InstrumentService → EmoteService →
CosmeticService → SkysPeakService → MonetizationService
```

Each service exposes an `init(player: Player)` called by `DataService` on `Players.PlayerAdded`.

### 1.4 Module Pattern

All services follow this pattern:

```luau
-- Services/ExampleService.luau
local ExampleService = {}

function ExampleService.init(player: Player)
    -- called on player join, load player-specific state
end

function ExampleService.cleanup(player: Player)
    -- called on player leave, flush pending state
end

return ExampleService
```

---

## 2. Data Layer — DataStore Schemas

All data lives in one `DataStore` key per player: `"PlayerData_v1_{userId}"`. Using a versioned key allows schema migration without colliding with old data.

### 2.1 Top-Level Schema

```luau
type PlayerData = {
    -- Meta
    schemaVersion: number,         -- increment on breaking changes
    createdAt: number,             -- os.time() on first save
    lastLogin: number,             -- os.time() on each login

    -- Economy
    cahaya: number,                -- current Cahaya balance
    cahayaHati: number,            -- Cahaya Hati balance
    koinMusim: number,             -- seasonal currency
    bintangHati: number,           -- gifting currency

    -- Progression
    wingLevel: number,             -- 1–10
    awanXP: number,                -- total XP earned
    skysPeakCycles: number,        -- total Sky's Peak completions

    -- Daily
    dailyCahayaCollected: number,  -- resets daily; hard cap 150
    dailyResetTimestamp: number,   -- UTC timestamp of last daily reset
    loginStreak: number,           -- consecutive days logged in
    lastStreakDate: number,        -- date number (os.date("%Y%m%d"))
    graceDaysRemaining: number,    -- streak grace days

    -- Daily Tasks
    taskState: DailyTaskState,

    -- Weekly / Monthly
    weeklyState: WeeklyState,
    monthlyState: MonthlyState,

    -- Spirits
    freedSpiritIds: { [string]: true },   -- set of freed Ancestor Spirit IDs
    galeriRohOrder: { string },            -- order for Galeri Roh display

    -- Ikatan
    ikatanList: { string },               -- array of userId strings, max 30
    ikatanGiftsGivenToday: number,        -- resets daily

    -- Cosmetics / Inventory
    ownedItems: { [string]: true },        -- set of item IDs
    equippedItems: EquippedLoadout,

    -- Season
    activeSeasonId: string,
    seasonPassOwned: boolean,
    seasonPassPlusOwned: boolean,
    freedSeasonSpiritIds: { [string]: true },
    seasonQuestProgress: { [string]: number },
    dailyChestBonusUsedToday: boolean,    -- extra Robux chest

    -- Monetization
    starterPackClaimed: boolean,
}
```

### 2.2 Sub-Type Schemas

```luau
type DailyTaskState = {
    date: string,              -- "YYYYMMDD" — if stale, regenerate
    tasks: { DailyTask },      -- exactly 5: 3 easy + 1 medium + 1 hard
    completedIndices: { number },
    milestoneRewardsClaimed: { number },  -- which milestone tiers (1–5) claimed
}

type DailyTask = {
    id: string,                -- e.g. "EASY_COLLECT_CAHAYA"
    difficulty: "Easy" | "Medium" | "Hard",
    target: number,            -- goal count (e.g. 20 for collect 20 cahaya)
    progress: number,          -- current progress
    completed: boolean,
}

type WeeklyState = {
    weekNumber: number,        -- ISO week number
    fullClearDays: number,     -- days this week with 5/5 tasks done
    rewardClaimed: boolean,
}

type MonthlyState = {
    month: string,             -- "YYYY-MM"
    weeklyMilestonesMet: number, -- 0–4
    rewardClaimed: boolean,
}

type EquippedLoadout = {
    cape: string?,
    mask: string?,
    hair: string?,
    outfit: string?,
    wingSkin: string?,
    instrument: string?,
    emoteSlots: { string },    -- up to 8 emote slots
    trail: string?,
    aura: string?,
    prop: string?,
}
```

### 2.3 Shared / Global DataStores

| DataStore Name | Key Pattern | Purpose |
|---|---|---|
| `"SeasonConfig_v1"` | `"active"` | Current season definition (read-only from server) |
| `"IkatanGraph_v1"` | `"user_{userId}"` | Bidirectional bond list (mirrors PlayerData.ikatanList) |
| `"DailySpiritSpawn_v1"` | `"YYYYMMDD"` | Today's daily spirit spawn positions |
| `"Leaderboard_v1"` | `"skysPeakCycles"` | Ordered leaderboard (use `OrderedDataStore`) |

### 2.4 DataStore Keys — Naming Conventions

- All keys versioned: `_v1`, `_v2` on schema breaks
- Never use player name — use `userId` (string)
- `DailySpiritSpawn` key computed server-side once per UTC+7 day and cached in `MemoryStoreService` for fast reads

---

## 3. Networking — Remotes Catalog

All remotes defined in `shared/Remotes.luau` using typed wrappers (see `sleitnick/net` or manual typed wrapper pattern).

### Convention

```
Remote name format:  SystemName_ActionName
Direction suffix:    (none) = Client→Server event
                     _S2C    = Server→Client event
                     _Fn     = RemoteFunction (client calls, server responds)
```

### 3.1 Flight Remotes

| Remote | Direction | Payload | Notes |
|---|---|---|---|
| `Flight_RequestBoost` | C→S | `{ position: Vector3, velocity: Vector3 }` | Server validates position proximity, grants boost if charge available |
| `Flight_BoostResult_S2C` | S→C | `{ granted: boolean, newCharge: number }` | |
| `Flight_CarryRequest` | C→S | `{ targetUserId: number }` | Carrier initiates |
| `Flight_CarryAccept` | C→S | `{ carrierUserId: number }` | Carried player accepts |
| `Flight_CarryEnd` | C→S | `{}` | Either party can end |
| `Flight_CarryState_S2C` | S→C | `{ carrierId: number, carriedId: number, active: boolean }` | Broadcast to both players |

### 3.2 Cahaya Remotes

| Remote | Direction | Payload | Notes |
|---|---|---|---|
| `Cahaya_CollectOrb` | C→S | `{ orbId: string, position: Vector3 }` | Server validates proximity |
| `Cahaya_CollectResult_S2C` | S→C | `{ newTotal: number, dailyCollected: number, capReached: boolean }` | |
| `Cahaya_GiftRequest` | C→S | `{ targetUserId: number, amount: number }` | Max 3 gifts/day enforced server-side |
| `Cahaya_GiftResult_S2C` | S→C | `{ success: boolean, reason: string? }` | |
| `Cahaya_ReviveRequest` | C→S | `{ targetUserId: number }` | Rescuer initiates |
| `Cahaya_ReviveResult_S2C` | S→C | `{ success: boolean }` | |
| `Cahaya_Extinguished_S2C` | S→C | `{}` | Server tells client they were extinguished |
| `Cahaya_Restored_S2C` | S→C | `{ newTotal: number }` | After respawn |
| `Cahaya_SyncState_S2C` | S→C | `{ cahaya: number, cahayaHati: number }` | Full sync on join / after major event |

### 3.3 Wing Remotes

| Remote | Direction | Payload | Notes |
|---|---|---|---|
| `Wing_UpgradeRequest` | C→S | `{}` | Server checks Cahaya Hati, upgrades if possible |
| `Wing_UpgradeResult_S2C` | S→C | `{ success: boolean, newLevel: number, newCahayaHati: number }` | |
| `Wing_LevelSync_S2C` | S→C | `{ level: number }` | On join or level change |

### 3.4 Spirit Remotes

| Remote | Direction | Payload | Notes |
|---|---|---|---|
| `Spirit_CollectFragment` | C→S | `{ spiritId: string, fragmentIndex: number, position: Vector3 }` | |
| `Spirit_FreeRequest` | C→S | `{ spiritId: string }` | All fragments must be collected |
| `Spirit_FreeResult_S2C` | S→C | `{ success: boolean, reward: SpiritReward }` | |
| `Spirit_TouchDaily` | C→S | `{ spiritId: string, position: Vector3 }` | For daily spirits |
| `Spirit_DailyResult_S2C` | S→C | `{ cahayaGained: number, cahayaHatiGained: number }` | |

### 3.5 Ikatan Remotes

| Remote | Direction | Payload | Notes |
|---|---|---|---|
| `Ikatan_OfferRequest` | C→S | `{ targetUserId: number }` | Initiator |
| `Ikatan_OfferNotify_S2C` | S→C | `{ fromUserId: number, fromName: string }` | Sent to target |
| `Ikatan_AcceptRequest` | C→S | `{ fromUserId: number }` | Target accepts |
| `Ikatan_DeclineRequest` | C→S | `{ fromUserId: number }` | Target declines |
| `Ikatan_FormedResult_S2C` | S→C | `{ partnerId: number, newCahayaHati: number }` | Both players receive |
| `Ikatan_TeleportRequest` | C→S | `{ targetUserId: number }` | Cooldown enforced server-side |
| `Ikatan_GiftRequest` | C→S | `{ targetUserId: number, itemId: string }` | |
| `Ikatan_GiftNotify_S2C` | S→C | `{ fromUserId: number, itemId: string }` | |

### 3.6 Daily Task Remotes

| Remote | Direction | Payload | Notes |
|---|---|---|---|
| `DailyTask_Sync_S2C` | S→C | `{ taskState: DailyTaskState }` | On join, sends full task state |
| `DailyTask_Progress_S2C` | S→C | `{ taskId: string, newProgress: number, completed: boolean }` | Incremental update |
| `DailyTask_ClaimMilestone` | C→S | `{ tier: number }` | Client claims reward tier (1–5) |
| `DailyTask_MilestoneResult_S2C` | S→C | `{ tier: number, reward: TaskReward }` | |

### 3.7 Instrument / Harmoni Remotes

| Remote | Direction | Payload | Notes |
|---|---|---|---|
| `Instrument_PlayNote` | C→S | `{ instrumentId: string, noteIndex: number }` | Rate-limited: max 10/sec |
| `Instrument_NoteRelay_S2C` | S→C | `{ userId: number, instrumentId: string, noteIndex: number }` | Broadcast to nearby players |
| `Instrument_Strum` | C→S | `{ instrumentId: string }` | For Siter/Angklung |
| `Instrument_SustainStart` | C→S | `{ instrumentId: string, noteIndex: number }` | For Terompet |
| `Instrument_SustainEnd` | C→S | `{}` | |
| `Harmoni_Start_S2C` | S→C | `{ playerIds: { number } }` | Server detects 2+ players playing near each other |
| `Harmoni_End_S2C` | S→C | `{}` | |

### 3.8 Emote Remotes

| Remote | Direction | Payload | Notes |
|---|---|---|---|
| `Emote_PlayRequest` | C→S | `{ emoteId: string }` | Server validates ownership |
| `Emote_PlayRelay_S2C` | S→C | `{ userId: number, emoteId: string, isSynced: boolean }` | Broadcast to nearby |
| `Emote_SyncCheck_S2C` | S→C | `{ partnerId: number, emoteId: string }` | Server detects matching emote between bonded pair |

### 3.9 Cosmetic / Inventory Remotes

| Remote | Direction | Payload | Notes |
|---|---|---|---|
| `Cosmetic_EquipRequest` | C→S | `{ slot: string, itemId: string? }` | nil = unequip |
| `Cosmetic_EquipResult_S2C` | S→C | `{ success: boolean, loadout: EquippedLoadout }` | |
| `Cosmetic_LoadoutRelay_S2C` | S→C | `{ userId: number, loadout: EquippedLoadout }` | Broadcast to others in realm |
| `Cosmetic_InventorySync_S2C` | S→C | `{ ownedItems: { string } }` | On join |

### 3.10 Season / Monetization Remotes

| Remote | Direction | Payload | Notes |
|---|---|---|---|
| `Season_StateSync_S2C` | S→C | `{ seasonState: SeasonClientState }` | On join |
| `Season_QuestProgress_S2C` | S→C | `{ questId: string, progress: number }` | |
| `Monetization_PurchasePrompt` | C→S | `{ productId: number }` | Client requests server to open prompt |
| `Monetization_PassSync_S2C` | S→C | `{ seasonPassOwned: boolean, seasonPassPlusOwned: boolean }` | |

---

## 4. System: Flight

**Module locations:**
- Server: `Services/FlightService.luau`
- Client: `Controllers/FlightController.luau`

### 4.1 Requirements

**FR-FLT-01:** Client controls flight direction and timing. Server validates and authorizes each boost consumption.

**FR-FLT-02:** Wing charge bar segments per wing level:

| Wing Level | Segments |
|---|---|
| 1 | 3 |
| 2 | 3 |
| 3 | 4 |
| 4 | 4 |
| 5–10 | 5 |

**FR-FLT-03:** Charge refill rates (segments/second):

| Source | Rate |
|---|---|
| Standing on ground | 0.25 seg/sec |
| Near higher-level player (≤15 studs) | 0.75 seg/sec |
| Collect Cahaya orb | +1 seg (instant) |
| Harmoni active | +0.5 seg/sec bonus |

**FR-FLT-04:** Each boost (`Flight_RequestBoost`) costs exactly 1 segment. Server records last-known position and validates new position is within plausible flight distance (max 80 studs per boost at level 1–3, 100 at 4–5).

**FR-FLT-05:** In Kegelapan zones, charge refill rate is halved.

**FR-FLT-06:** Carry mechanic — carrier consumes 2 segments per boost. Carried player's `HumanoidRootPart` is welded to carrier's back attachment. Server creates/destroys `WeldConstraint` via `FlightService`.

**FR-FLT-07:** Level 1 wings: player launches into a short parabolic arc on boost (no sustained hover). Level 2+: player can maintain altitude while charge remains.

**FR-FLT-08:** On extinguishment (Cahaya = 0 in Kegelapan), `FlightService` sets `Humanoid.JumpHeight = 0` and `WalkSpeed = 8` (walk-only mode). Restored on revive or safe-zone return.

### 4.2 State Machine (Client FlightController)

```
IDLE
 ├─ [jump pressed + charge > 0] → BOOST
 ├─ [airborne + no boost] → GLIDE
BOOST
 ├─ [charge == 0] → GLIDE
 ├─ [land] → IDLE
GLIDE
 ├─ [land] → IDLE
 ├─ [jump pressed + charge > 0] → BOOST
EXTINGUISHED
 ├─ [revived] → IDLE
```

### 4.3 Anti-Exploit (Flight-specific)

- Server tracks per-player `lastValidPosition` updated each confirmed boost
- Any `Flight_RequestBoost` where submitted position deviates >150 studs from `lastValidPosition` is rejected and the player's position is force-reset server-side
- Max 3 boosts/second enforced via server-side rate limiter per player

---

## 5. System: Cahaya (Light)

**Module locations:**
- Server: `Services/CahayaService.luau`
- Client: `Controllers/` (HUD updates via `Cahaya_SyncState_S2C`)

### 5.1 Requirements

**FR-CAH-01:** Cahaya orbs are `Part` instances tagged `"CahayaOrb"` with an `ObjectValue` attribute `orbId` (UUID set at realm design time).

**FR-CAH-02:** Server tracks collected orb IDs per-session in a `{ [string]: true }` table (not persisted — resets on server restart/rejoin).

**FR-CAH-03:** On `Cahaya_CollectOrb`, server checks:
1. Player position within 10 studs of orb position
2. Orb not already collected this session by this player
3. `dailyCahayaCollected < 150`

If all pass: increment `cahaya` and `dailyCahayaCollected`, destroy orb part, fire `Cahaya_CollectResult_S2C`.

**FR-CAH-04:** Daily cap of 150 Cahaya from world orbs. Cahaya from social actions (revive reward, daily task reward, spirit freeing) does NOT count toward the daily cap.

**FR-CAH-05:** Orbs respawn server-side on a per-realm timer: 5 minutes after collected (do not respawn during same session for the same player — only if they change realm and return).

**FR-CAH-06:** Daily reset logic:
- On `PlayerAdded`, compare `dailyResetTimestamp` to current UTC+7 midnight
- If stale: zero `dailyCahayaCollected`, set new `dailyResetTimestamp`
- Same logic gates `DailyTaskService` reset

**FR-CAH-07:** Extinguishment trigger — `KegelapanService` calls `CahayaService.drain(player, amount)` every 3 seconds inside a darkness zone. When `cahaya` reaches 0: fire `Cahaya_Extinguished_S2C`, call `FlightService.extinguish(player)`, teleport to last safe checkpoint.

**FR-CAH-08:** Revive — `CahayaService.revive(rescuer, target)`: deducts 1 Cahaya from rescuer, sets target `cahaya = 10`, fires `Cahaya_Restored_S2C` to target, fires `Cahaya_SyncState_S2C` to rescuer. Both must be within 8 studs server-side.

**FR-CAH-09:** Gifting — `CahayaService.gift(giver, recipient, amount)`: deducts from giver `cahayaHati` (not raw cahaya), increments `ikatanGiftsGivenToday` on giver. Max 3 gifts/day, enforced server-side. Each gift: +0.5 `cahayaHati` for giver, +amount `cahayaHati` for recipient.

---

## 6. System: Wing Progression

**Module location:** `Services/WingService.luau`

### 6.1 Requirements

**FR-WNG-01:** Upgrade cost table stored in `shared/WingDefs.luau`:

```luau
-- shared/WingDefs.luau
export type WingDef = {
    level: number,
    name: string,            -- "Fajar", "Pagi", etc.
    cahayaHatiCost: number,
    chargeSegments: number,
    canCarry: boolean,
    canEnterSkysPeak: boolean,
}

local WingDefs: { WingDef } = {
    { level = 1, name = "Fajar",  cahayaHatiCost = 0,  chargeSegments = 3, canCarry = false, canEnterSkysPeak = false },
    { level = 2, name = "Pagi",   cahayaHatiCost = 3,  chargeSegments = 3, canCarry = false, canEnterSkysPeak = false },
    { level = 3, name = "Siang",  cahayaHatiCost = 6,  chargeSegments = 4, canCarry = false, canEnterSkysPeak = false },
    { level = 4, name = "Sore",   cahayaHatiCost = 12, chargeSegments = 4, canCarry = true,  canEnterSkysPeak = false },
    { level = 5, name = "Petang", cahayaHatiCost = 20, chargeSegments = 5, canCarry = true,  canEnterSkysPeak = true  },
    -- levels 6–10: cosmetic only, same stats as 5, different cahayaHatiCost
}
```

**FR-WNG-02:** Upgrade validation (server):
1. `wingLevel < 10`
2. `cahayaHati >= cost`
3. No active Sky's Peak run in progress

If valid: decrement `cahayaHati`, increment `wingLevel`, update `FlightService` charge config for player, fire `Wing_UpgradeResult_S2C`.

**FR-WNG-03:** Realm entry gate — on `TeleportService` arrival, server checks `wingLevel >= RealmDefs[realmId].minWingLevel`. If below threshold, reject teleport and fire an error notice to client.

**FR-WNG-04:** Wing skin is separate from wing level. Equipping a wing skin does not change functional level — only visual.

**FR-WNG-05:** Awan XP awarded on upgrade: `+50 * newLevel` XP.

---

## 7. System: Kegelapan (Darkness)

**Module location:** `Services/KegelapanService.luau`

### 7.1 Requirements

**FR-KEG-01:** Kegelapan zones are defined as `BasePart` instances tagged `"KegelapanZone"` in each realm's workspace. Each zone part has attributes:
- `DrainRate: number` — Cahaya drained per drain tick (default `1`)
- `DrainInterval: number` — seconds between drain ticks (default `3`)
- `ZoneId: string` — unique identifier

**FR-KEG-02:** `KegelapanService` uses `workspace:GetPartBoundsInBox()` or region overlap per player each heartbeat to detect zone entry/exit. On entry: start drain loop. On exit: stop loop.

**FR-KEG-03:** Server fires `Kegelapan_ZoneState_S2C` to the player on enter/exit so client can play visual/audio effects (fog, color grading, sound shift). Client never decides if it's in a zone — only reacts.

**FR-KEG-04:** Peti Cahaya (chests) inside zones: `Part` tagged `"PetiCahaya"` with attribute `chestId`. Server validates player is inside the zone when `PetiCahaya_Open` remote fires. One-time-per-account flag stored in `PlayerData` (not a daily reset — permanent unlock).

**FR-KEG-05:** "Extinguish own light" mechanic — player can toggle self-dim via `Kegelapan_DimRequest`. When dimmed: Naga Gelap ignores player, drain rate pauses for 5 seconds (grace), then resumes at 0.5x normal rate. Client shows dim visual. Server toggles a `isDimmed` flag per player.

---

## 8. System: Naga Gelap AI

**Module location:** `server/NPC/NagaGelapAI.luau`

### 8.1 Requirements

**FR-NGA-01:** Naga Gelap is a server-side NPC. Position is authoritative on server; replicated to clients via `ReplicatedStorage` `RemoteEvent` or `BindableEvent` to a client relay.

**FR-NGA-02:** AI state machine:

```
PATROL  → (player within 40 studs with cahaya > 20 AND not dimmed) → CHASE
CHASE   → (target > 60 studs OR target dimmed OR target extinguished) → PATROL
CHASE   → (catch: within 5 studs of target) → EXTINGUISH_PLAYER
```

**FR-NGA-03:** Chase uses `PathfindingService` on server. Recalculates path every 2 seconds or when blocked.

**FR-NGA-04:** On catch: server calls `CahayaService.extinguish(target)` directly. Naga returns to patrol.

**FR-NGA-05:** Max 3 Naga Gelap per Kegelapan zone. Spawned at zone-entry time, despawned when zone has no players.

**FR-NGA-06:** Naga Gelap cannot leave its assigned zone's bounding region. Hard boundary enforced by clamping movement target.

**FR-NGA-07:** Server fires `NagaGelap_StateRelay_S2C` every 0.1 seconds per Naga in view of a player (proximity-filtered: only broadcast to players within 80 studs). Client renders the Naga model and plays audio.

---

## 9. System: Ikatan (Bond)

**Module location:** `Services/IkatanService.luau`

### 9.1 Requirements

**FR-IKT-01:** Ikatan is bidirectional. Stored in both players' `PlayerData.ikatanList` and mirrored in `IkatanGraph_v1` DataStore.

**FR-IKT-02:** Offer flow (server):
1. `Ikatan_OfferRequest` received from Player A targeting Player B
2. Validate: A and B within 8 studs; B not already Ikatan'd to A; both have `ikatanList.length < 30`
3. Store pending offer: `pendingOffers[B.UserId] = A.UserId` (in-memory, 30-second TTL)
4. Fire `Ikatan_OfferNotify_S2C` to Player B

**FR-IKT-03:** Accept flow:
1. `Ikatan_AcceptRequest` received from Player B
2. Validate pending offer exists and hasn't expired
3. Add each to the other's `ikatanList`
4. Write both updated lists to DataStore (wrapped in `Promise.retryWithDelay`)
5. Award +2 `cahayaHati` to both
6. Fire `Ikatan_FormedResult_S2C` to both
7. Award Awan XP: +30 to both

**FR-IKT-04:** Teleport to Ikatan partner:
- Cooldown: 30 minutes per player (server-side timer, not persisted across sessions)
- Target must be in a realm the requesting player has access to (`wingLevel` check)
- Uses `TeleportService:TeleportToPlaceInstance` to the target's place/server

**FR-IKT-05:** Ikatan list persisted. On session end (`Players.PlayerRemoving`), `DataService.save(player)` flushes to DataStore.

**FR-IKT-06:** Online status of Ikatan partners — use `MessagingService` or `MemoryStoreService` to publish/subscribe to per-server player presence. Clients receive bonded-partner online status via `Ikatan_PresenceUpdate_S2C` when they join or a partner comes online.

---

## 10. System: Spirits

**Module location:** `Services/SpiritService.luau`

### 10.1 Spirit Definition Schema

```luau
-- shared/SpiritDefs.luau
export type SpiritDef = {
    id: string,                     -- unique e.g. "ISLE_WATCHER"
    realmId: string,
    spiritType: "Ancestor" | "Season" | "Daily",
    position: Vector3,              -- world position
    fragmentCount: number,          -- 3–5 for Ancestor, 0 for Daily
    fragmentPositions: { Vector3 },
    reward: SpiritReward,
    nameKey: string,                -- localization key
    vignettePath: string,           -- asset path for cutscene diorama
    seasonId: string?,              -- Season spirits only
}

export type SpiritReward = {
    cahaya: number,
    cahayaHati: number,
    itemId: string?,                -- cosmetic reward if any
    wingLevelBonus: number,         -- usually 0
}
```

### 10.2 Requirements

**FR-SPR-01:** `SpiritService` spawns spirit models on server startup for each realm. Uses `CollectionService:AddTag("Spirit", part)` for each spirit part.

**FR-SPR-02:** Fragment collection validation:
1. `Spirit_CollectFragment` fires with `spiritId` and `fragmentIndex`
2. Server checks player within 8 studs of the fragment's world position
3. Fragment not already collected this interaction (session-cache per player per spirit)
4. Fire visual confirm to client

**FR-SPR-03:** Free validation:
1. All fragments collected (checked via session cache)
2. Spirit not already freed (`PlayerData.freedSpiritIds[spiritId]` does not exist)
3. For Season Spirits: `seasonPassOwned == true`
4. On success: add to `freedSpiritIds`, grant reward via `CahayaService` + `CosmeticService`, fire `Spirit_FreeResult_S2C`

**FR-SPR-04:** Daily spirits respawn logic:
- `DailySpiritSpawn_v1` DataStore stores two random realm IDs + positions per UTC+7 day
- Generated once on first server boot of the day using `math.random` seeded by date hash
- Server checks if player has already touched today's daily spirits via `PlayerData.dailySpiritsTouched` (array of spirit IDs, cleared on daily reset)

**FR-SPR-05:** Season spirit companion toggle — `Spirit_ToggleCompanion` remote. Server stores `activeCompanionSpiritId` in session memory. Client renders the companion model following the player using a `Motor6D` or CFrame offset updated each heartbeat on client.

**FR-SPR-06:** Galeri Roh panel: client requests `GaleriRoh_GetList_Fn` (RemoteFunction). Server returns ordered list of freed spirit IDs. Client renders dioramas using `ViewportFrame`.

---

## 11. System: Daily Tasks

**Module location:** `Services/DailyTaskService.luau`

### 11.1 Task Pool Definition

```luau
-- shared/DailyTaskDefs.luau
export type TaskDef = {
    id: string,
    difficulty: "Easy" | "Medium" | "Hard",
    descriptionKey: string,          -- localization key
    target: number,
    trackingEvent: string,           -- internal event name this task listens to
    paramFilter: ({ [string]: any } -> boolean)?,  -- optional filter
}
```

Tasks listen to internal `BindableEvent`s fired by other services (not remotes):

| Task | Tracking Event | Notes |
|---|---|---|
| Collect N Cahaya | `"CahayaCollected"` | payload: `{ amount }` |
| Use N emotes near players | `"EmoteUsedNearPlayer"` | payload: `{ emoteId }` |
| Visit N realms | `"RealmVisited"` | payload: `{ realmId }` |
| Play instrument N seconds | `"InstrumentPlayed"` | payload: `{ duration }` |
| Revive N players | `"PlayerRevived"` | |
| Offer hand N times | `"IkatanOfferSent"` | |
| Find daily spirit | `"DailySpiritTouched"` | |
| Fly N seconds without ground | `"AirtimeAccumulated"` | payload: `{ seconds }` |
| Free a spirit | `"SpiritFreed"` | |
| Collect 60/100 Cahaya in session | `"CahayaCollected"` | session total tracked |
| Play music with 2+ players | `"HarmoniActive"` | payload: `{ playerCount }` |
| Navigate Kegelapan without extinguish | `"KegelapanExited"` | payload: `{ extinguished: false }` |
| Form Ikatan | `"IkatanFormed"` | |
| Carry player through realm | `"CarrySessionCompleted"` | server detects realm completion while carrying |
| 4-player Harmoni 2 minutes | `"HarmoniActive"` | payload: `{ playerCount >= 4, duration }` |
| Reach Sky's Peak | `"SkysPeakReached"` | |

### 11.2 Requirements

**FR-DTK-01:** On first login of the day (stale date check), `DailyTaskService` generates a new `DailyTaskState`:
- Randomly pick 3 from Easy pool, 1 from Medium pool, 1 from Hard pool
- Seed: `userId XOR dateHash` so each player gets a different set but it's deterministic for the same player on the same day (prevents re-roll exploit on rejoin)

**FR-DTK-02:** Task progress is incremented server-side only. Services fire `BindableEvent`s; `DailyTaskService` listens and calls `incrementProgress(player, event, payload)`.

**FR-DTK-03:** On task completion: fire `DailyTask_Progress_S2C` with `completed = true`. Do not auto-grant reward — client must explicitly call `DailyTask_ClaimMilestone` for each tier.

**FR-DTK-04:** Milestone tiers (1–5) grant rewards independently. Claiming tier 3 does not require claiming tiers 1–2 first, but server validates `completedIndices.length >= tierThreshold`.

**FR-DTK-05:** Daily Chest (tier 5 reward) — server picks reward from weighted table:

```luau
local DAILY_CHEST_TABLE = {
    { weight = 50, type = "cahaya",           amount = 30 },
    { weight = 25, type = "koinMusim",         amount = 30 },
    { weight = 15, type = "cosmeticFragment",  rarity = "Common" },
    { weight = 10, type = "koinMusim",         amount = 50 },
}
```

**FR-DTK-06:** Weekly state tracks `fullClearDays` per ISO week. Month state tracks `weeklyMilestonesMet` per calendar month. Both checked/reset on daily reset logic.

**FR-DTK-07:** Login streak — on `PlayerAdded`:
1. Compute today's date string `"YYYYMMDD"`
2. If `lastStreakDate == yesterday`: increment streak, update `lastStreakDate`
3. If `lastStreakDate == today`: no change (already counted)
4. If gap is 2+ days and `graceDaysRemaining > 0`: consume 1 grace day, treat as continuous
5. Else: reset streak to 1

**FR-DTK-08:** Login streak rewards dispatched through `CahayaService` and `CosmeticService` based on lookup table in `Constants.luau`.

---

## 12. System: Seasons

**Module location:** `Services/SeasonService.luau`

### 12.1 Season Config Schema

```luau
-- shared/SeasonDefs.luau
export type SeasonDef = {
    id: string,                       -- "SEASON_01_STARFALL"
    nameKey: string,
    startTimestamp: number,           -- UTC os.time()
    endTimestamp: number,
    realmExtensionId: string,         -- which realm gets seasonal area
    spirits: { string },             -- SpiritDef IDs
    questChain: { SeasonQuest },
    koinMusimShop: { KoinMusimItem },
    musimPassProductId: number,       -- Robux product ID
    musimPassPlusProductId: number,
}

export type SeasonQuest = {
    id: string,
    step: number,                     -- 1–7
    descriptionKey: string,
    completionEvent: string,
    target: number,
    reward: TaskReward,
}
```

### 12.2 Requirements

**FR-SEA-01:** `SeasonService` reads active season from `SeasonConfig_v1` DataStore on startup. If server-side config changes (new season deployed), existing servers pick it up within 5 minutes via polling.

**FR-SEA-02:** Season quest progress stored in `PlayerData.seasonQuestProgress: { [questId]: progress }`. Completion validated server-side, same pattern as daily tasks (BindableEvent listeners).

**FR-SEA-03:** Koin Musim earn rate: base `1` per daily task completed. Season Pass owners: `2` per daily task completed (multiplier applied in `DailyTaskService` at reward grant time).

**FR-SEA-04:** Season end transition:
- Spirit availability flag set to `false` server-side (Season Spirit `_FreeRequest` rejected if season ended)
- Owned cosmetics remain — only freeing new spirits disabled
- `koinMusim` balance carries over to next season
- New season auto-activates at `endTimestamp + 1 second`

**FR-SEA-05:** Seasonal realm extension enabled/disabled via `CollectionService` tag `"SeasonArea_SEASON_01"` on relevant parts. `SeasonService.activateSeason()` calls `CollectionService:AddTag` / `RemoveTag` at season boundaries.

---

## 13. System: Instruments & Harmoni

**Module locations:**
- Server: `Services/InstrumentService.luau`
- Client: `Controllers/InstrumentController.luau`, `UI/InstrumentUI.luau`

### 13.1 Requirements

**FR-INS-01:** Players can only play the instrument currently equipped in their loadout (`equippedItems.instrument`). Server validates instrument ownership on first note of a session.

**FR-INS-02:** Rate limit: server accepts max 10 `Instrument_PlayNote` events per second per player. Excess notes are dropped silently.

**FR-INS-03:** Server relays note events to all players within 40 studs (server-side distance check using `player.Character.PrimaryPart.Position`). Uses `Instrument_NoteRelay_S2C` fired to filtered player list.

**FR-INS-04:** Client `InstrumentController` plays note sounds using `SoundService`. Each instrument has 5 note sounds (C, D, E, G, A — pentatonic scale, culturally neutral and harmonically safe). Sounds loaded via asset IDs in `Constants.luau`.

**FR-INS-05:** Angklung gyro: `UserInputService.DeviceGravityChanged` on mobile fires `Instrument_Strum` if shake magnitude exceeds threshold `1.5`. Cooldown 0.3s between shakes.

**FR-INS-06:** Harmoni detection (server-side):
- Every 5 seconds, `InstrumentService` scans all players currently playing instruments
- If 2+ players are playing within 20 studs of each other: Harmoni activates for that cluster
- Fires `Harmoni_Start_S2C` to all players in cluster with their IDs
- Harmoni persists while 2+ players continue playing; checked every 5 seconds
- On drop below 2 players: fire `Harmoni_End_S2C`

**FR-INS-07:** Harmoni boost effect: `FlightService` applies `+0.5 seg/sec` refill bonus to all players in Harmoni. Effect removed when Harmoni ends.

**FR-INS-08:** Daily Task "play music with 2+ others" fires `"HarmoniActive"` BindableEvent on Harmoni start (payload: `{ playerCount }`).

---

## 14. System: Emotes

**Module locations:**
- Server: `Services/EmoteService.luau`
- Client: `Controllers/EmoteController.luau`, `UI/EmoteWheel.luau`

### 14.1 Requirements

**FR-EMT-01:** Each player has 8 emote slots in `equippedItems.emoteSlots`. Emote wheel UI shows 8 radial options (or fewer if slots are empty).

**FR-EMT-02:** `Emote_PlayRequest` server validation:
1. `emoteId` exists in `CosmeticDefs`
2. Player owns the emote (`ownedItems[emoteId]`)
3. Emote is in `equippedItems.emoteSlots`

**FR-EMT-03:** Server fires `Emote_PlayRelay_S2C` to all players within 30 studs. Client plays the `AnimationTrack` on the target character.

**FR-EMT-04:** Sync emote detection:
- When `Emote_PlayRequest` fires for Player A, server checks all Ikatan partners of A within 15 studs currently playing the same `emoteId`
- If found: fire `Emote_SyncCheck_S2C` to both — client plays the shared duo animation instead of solo animation
- Duo animation asset IDs stored in `CosmeticDefs` under `emote.syncAnimationId`

**FR-EMT-05:** Emotes cannot play while carrying or being carried (server rejects `Emote_PlayRequest` if carry state is active).

**FR-EMT-06:** Daily Task "use 3 emotes near other players" — fires `"EmoteUsedNearPlayer"` BindableEvent if at least one other player is within 15 studs when emote is played.

---

## 15. System: Cosmetics & Inventory

**Module locations:**
- Server: `Services/CosmeticService.luau`
- Client: `Controllers/CosmeticController.luau`, `UI/InventoryPanel.luau`

### 15.1 Cosmetic Definition Schema

```luau
-- shared/CosmeticDefs.luau
export type CosmeticDef = {
    id: string,
    nameKey: string,
    category: "Cape" | "Mask" | "Hair" | "Outfit" | "WingSkin" | "Instrument" |
              "Emote" | "Trail" | "Aura" | "Prop",
    rarity: "Biasa" | "Langka" | "Epik" | "Legendaris",
    assetId: number,                   -- Roblox asset / animation ID
    syncAnimationId: number?,          -- for emotes with duo version
    sourceType: "Task" | "Spirit" | "Season" | "Robux" | "Event",
    seasonId: string?,
    robuxProductId: number?,
}
```

### 15.2 Requirements

**FR-COS-01:** All item grants go through `CosmeticService.grantItem(player, itemId)`. This is the only function that writes to `ownedItems`. Never grant via any other code path.

**FR-COS-02:** `grantItem` is idempotent — granting an already-owned item is a no-op (no error, no duplicate).

**FR-COS-03:** Equip validation:
- Item must be owned
- Item category must match the slot
- Server applies loadout change to `PlayerData.equippedItems`
- Fires `Cosmetic_EquipResult_S2C` to client
- Fires `Cosmetic_LoadoutRelay_S2C` to all players in same realm

**FR-COS-04:** Cosmetic fragment system:
- Fragments are not full items — stored as `fragmentInventory: { [string]: number }` (itemId → count)
- 3 fragments of the same item = auto-craft to full item (server-side, happens in `grantItem` call flow)
- Notify client with `Cosmetic_FragmentCrafted_S2C`

**FR-COS-05:** Character rendering — `CosmeticController` applies cosmetics client-side by cloning cosmetic models from `ReplicatedStorage/Assets/Cosmetics/` and welding to character attachments. Server-side character manipulation is not used (performance). Trust that `Cosmetic_LoadoutRelay_S2C` is the authority.

**FR-COS-06:** Roblox character appearance: use default Roblox avatar under all cosmetics — do not replace Humanoid Description. Cosmetics layer over the avatar.

---

## 16. System: Sky's Peak

**Module location:** `Services/SkysPeakService.luau`

### 16.1 Requirements

**FR-SKP-01:** Entry requirement: `wingLevel >= 5`. Server enforces at place entry.

**FR-SKP-02:** Sky's Peak is a separate Roblox Place. Players teleport in from any realm via `TeleportService`. On arrival: server loads player data and registers the active run.

**FR-SKP-03:** Run state machine (server per player):

```
IDLE → (enter place) → ASCENDING
ASCENDING → (reach summit trigger zone) → SUMMIT
SUMMIT → (player confirms sacrifice) → SACRIFICING
SACRIFICING → (animation plays 5s) → COMPLETE
COMPLETE → (teleport back to last realm) → IDLE
```

**FR-SKP-04:** Sacrifice action (`SkysPeak_Sacrifice` remote):
1. Validate player is in `SUMMIT` state and within summit zone
2. Record `cahayaConsumed = PlayerData.cahaya`
3. Set `PlayerData.cahaya = 0`
4. Increment `PlayerData.skysPeakCycles`
5. Award +3 `cahayaHati`
6. Award `Sayap Lencana` cosmetic for this cycle number (cosmetic ID: `"WING_BADGE_{cycleNumber}"`)
7. Award Awan XP: `+200`
8. Teleport player back to last realm

**FR-SKP-05:** Kegelapan intensity scaling during ascent — `KegelapanService` receives altitude from player position and scales `DrainRate` from 1 at base to 3 at summit. Altitude read from `Player.Character.PrimaryPart.Position.Y` clamped to realm range.

**FR-SKP-06:** If player disconnects mid-run: on next login, check `skysPeakRunInProgress` flag (session-only, cleared on leave). If flag is true, clear it and resume normally — no penalty.

---

## 17. UI Layer

**Module locations:** `client/UI/`

### 17.1 UI Framework Requirements

**FR-UI-01:** All UI built with `ScreenGui` instances. No `SurfaceGui` for gameplay-critical information (not readable on all platforms).

**FR-UI-02:** UI renders in `PlayerGui`. Each major panel is its own `ScreenGui` with `ResetOnSpawn = false`.

**FR-UI-03:** Global `UIController` manages panel open/close state. Only one major panel open at a time (except HUD which is always visible).

**FR-UI-04:** All text labels created with `LocalizationService:GetTranslatorForPlayerAsync()` translator. Never set `TextLabel.Text` to a raw English string — always use translator or a string key constant.

**FR-UI-05:** `AutomaticSize` used on all text containers. No fixed-height text boxes.

**FR-UI-06:** RTL — `UIController` reads `LayoutDirection` (see Localization section) on init and applies mirror transform to all `UIListLayout` (`FillDirection` and `HorizontalAlignment`) and `UIPadding` offsets.

**FR-UI-07:** UI Scale — `UiScaleController` reads player's saved `uiScale` preference (0.75–1.5). Applies via `UIScale` instance under each `ScreenGui`.

**FR-UI-08:** HUD elements:

| Element | ScreenGui Name | Always Visible |
|---|---|---|
| Wing Charge Bar | `HUD_WingCharge` | Yes |
| Cahaya Counter | `HUD_Cahaya` | Yes |
| Realm Name / Compass | `HUD_Compass` | Yes |
| Social Pulse | `HUD_SocialPulse` | Yes |
| Notification Toast | `HUD_Toast` | Conditional |
| Daily Task Shortcut | `HUD_TaskBar` | Yes |

**FR-UI-09:** Mobile Floating Action Button (FAB) — context-sensitive. Priority order (highest wins):
1. Revive nearby extinguished player
2. Accept Ikatan offer
3. Collect nearby spirit fragment
4. Interact with nearby spirit
5. Open instrument (if instrument equipped and near other players)

FAB hidden on PC (keyboard shortcut shown instead).

**FR-UI-10:** Notification Toast system — queued, max 3 concurrent toasts, auto-dismiss after 4 seconds. Toast types: `info`, `success`, `warning`. No error toasts visible to player (errors log to `warn()`).

---

## 18. Input Abstraction

**Module location:** `client/Controllers/InputController.luau`

### 18.1 Requirements

**FR-INP-01:** All input routed through `InputController`. No direct `UserInputService` calls in game logic or UI code.

**FR-INP-02:** Action definitions:

```luau
-- shared/Constants.luau (input actions)
export type ActionId = 
    "FlyBoost" | "Interact" | "EmoteWheel" | "Instrument" |
    "Map" | "Menu" | "DimLight" | "CarryBail"
```

**FR-INP-03:** Platform detection on client startup:

```luau
local platform: "PC" | "Mobile" | "Console"
-- Detect via UserInputService.TouchEnabled, GamepadEnabled
```

**FR-INP-04:** Binding table:

| Action | PC | Mobile | Console |
|---|---|---|---|
| FlyBoost | Space | Jump button | A |
| Interact | E | FAB / Tap player | X |
| EmoteWheel | Q | Swipe up | D-pad Up |
| Instrument | T | Instrument icon | Y |
| Map | M | Map icon | View |
| Menu | Esc | Menu icon | Menu |
| DimLight | F | DimLight icon | D-pad Down |
| CarryBail | Space (while carried) | Bail button | B |

**FR-INP-05:** `InputController.onAction(actionId, callback)` — pub/sub pattern. Systems subscribe to actions, not raw inputs. `InputController` translates platform-specific input to action IDs.

**FR-INP-06:** Double-tap detection for mobile FlyBoost (double-tap jump = boost). Threshold: 250ms between taps.

**FR-INP-07:** Gamepad deadzone: 0.2 on left stick for movement. All analog inputs normalized.

---

## 19. Localization Integration

**Module locations:** `shared/Format.luau`, `shared/Fonts.luau`, `client/Controllers/UIController.luau`

### 19.1 Requirements

**FR-LOC-01:** `LocalizationTable` asset under `ReplicatedStorage/Localization/`. All string keys follow the `CATEGORY_SUBCATEGORY_KEY` convention from GDD §16.2.

**FR-LOC-02:** Translator obtained once on client init:

```luau
local translator = LocalizationService:GetTranslatorForPlayerAsync(player)
```

Stored in `UIController` as a module-level variable. All UI code calls:

```luau
UIController.translate(key, params)
-- internally: translator:FormatByKey(key, params)
```

**FR-LOC-03:** Named parameters only in format strings. Example:
```
key: "DAILY_TASK_COLLECT_CAHAYA"
value: "Collect {count} Cahaya"
call: translate("DAILY_TASK_COLLECT_CAHAYA", { count = 20 })
```

**FR-LOC-04:** `Format.luau` module:

```luau
-- shared/Format.luau
local Format = {}
local locale = LocalizationService.RobloxLocaleId

local SEPARATORS = {
    ["id"] = { thousands = ".", decimal = "," },
    ["ar"] = { thousands = "٬", decimal = "٫" },
    -- default: thousands = ",", decimal = "."
}

function Format.number(n: number): string
    -- format with locale-appropriate thousands separator
end

function Format.countdown(seconds: number): string
    -- returns localized "Xj Ym" / "Xh Ym" / "Xh Ym Zs"
end

function Format.date(timestamp: number): string
    -- returns locale-appropriate date string
end

return Format
```

**FR-LOC-05:** Font loading:

```luau
-- shared/Fonts.luau
local CJK_FONT_ID  = "rbxassetid://REPLACE_WITH_CJK_ASSET"
local AR_FONT_ID   = "rbxassetid://REPLACE_WITH_AR_ASSET"

local FONT_MAP = {
    ["ja"] = CJK_FONT_ID, ["zh-cn"] = CJK_FONT_ID,
    ["zh-tw"] = CJK_FONT_ID, ["ko"] = CJK_FONT_ID,
    ["ar"] = AR_FONT_ID,
}

function Fonts.get(): Font
    return Font.fromId(FONT_MAP[locale] or Font.fromEnum(Enum.Font.GothamSsm))
end
```

Called once on `UIController` init. Applied to all `TextLabel` and `TextButton` instances created thereafter.

**FR-LOC-06:** RTL layout direction:

```luau
-- client/Controllers/UIController.luau
local RTL_LOCALES = { ["ar"] = true }
UIController.isRTL = RTL_LOCALES[locale] == true
```

All `UIListLayout` instances created after init check `UIController.isRTL` and set:
```luau
layout.FillDirection = Enum.FillDirection.Horizontal
layout.HorizontalAlignment = isRTL 
    and Enum.HorizontalAlignment.Right 
    or  Enum.HorizontalAlignment.Left
```

**FR-LOC-07:** Expression bubble preset phrases stored as string keys only — never hardcoded text. The 20 preset phrases defined in `Constants.luau` as key arrays.

---

## 20. Monetization (MarketplaceService)

**Module location:** `Services/MonetizationService.luau`

### 20.1 Product ID Registry

All product IDs defined in `shared/Constants.luau`:

```luau
-- shared/Constants.luau
export const PRODUCTS = {
    MUSIM_PASS          = 000000001,  -- replace with real ID
    MUSIM_PASS_PLUS     = 000000002,
    STARTER_PACK        = 000000003,
    EXTRA_DAILY_CHEST   = 000000004,
    -- Cosmetic bundles: 000000010–000000099
    -- Single Legendaris: 000000100–000000199
}

export const GAMEPASSES = {
    -- (if any permanent passes added in future)
}
```

### 20.2 Requirements

**FR-MON-01:** `MonetizationService` implements `MarketplaceService.ProcessReceipt`. This is the sole purchase handler. Never process purchases outside this callback.

**FR-MON-02:** `ProcessReceipt` must be idempotent. Use `PurchaseHistory` in a separate DataStore (`"PurchaseHistory_v1_{userId}"`) keyed by `receiptInfo.PurchaseId`. If `purchaseId` already present: return `Enum.ProductPurchaseDecision.PurchaseGranted` without re-granting reward.

**FR-MON-03:** Receipt processing flow:

```
ProcessReceipt fires
  → Load player data (must be loaded; if player left, queue for next login)
  → Check PurchaseHistory[purchaseId] — if exists, return Granted
  → Match productId → grant handler
  → Write purchaseId to PurchaseHistory DataStore
  → Return Granted
```

**FR-MON-04:** If player is not in-game when purchase completes (bought from Roblox website): store grant in a `PendingGrants` DataStore. On next login, `DataService.init(player)` checks `PendingGrants` and applies all pending grants.

**FR-MON-05:** Season Pass grant:
- Set `seasonPassOwned = true` on player data
- If Musim Pass+: also set `seasonPassPlusOwned = true`, grant first 3 season spirits as freed
- Fire `Monetization_PassSync_S2C` to client

**FR-MON-06:** Starter Pack:
- Check `starterPackClaimed == false`
- If true: return Granted without granting (idempotent, they already claimed it)
- Grant: 50 Cahaya, 5 Cahaya Hati, 1 common cosmetic bundle
- Set `starterPackClaimed = true`

**FR-MON-07:** Never prompt purchases from server. Client-side `UIController` can call `Monetization_PurchasePrompt` remote which triggers `MarketplaceService:PromptProductPurchase` on the server (where the player object is available).

**FR-MON-08:** Roblox Premium detection:
- Server checks `player.MembershipType == Enum.MembershipType.Premium` on join
- If Premium: apply +10% Cahaya collection rate in `CahayaService`, grant daily +10 Cahaya bonus in daily reset logic

---

## 21. Multi-Place Architecture

### 21.1 Place Structure

| Place | Purpose | Player Capacity |
|---|---|---|
| **Hub (Main Place)** | Isle of Dawn + lobby + realm portal | 20 |
| **Padang Bisikan** | Grassland realm | 20 |
| **Hutan Gaung** | Forest realm | 20 |
| **Lembah Kejayaan** | Valley realm | 20 |
| **Tanah Tandus** | Wasteland realm | 16 |
| **Kubah Pengetahuan** | Vault realm | 16 |
| **Puncak Langit** | Sky's Peak endgame | 12 |

All places share the same `DataModel` Universe. Player data shared via DataStore (not cross-server memory).

### 21.2 Requirements

**FR-MLP-01:** Teleport between realms via `TeleportService:TeleportAsync`. Always pass `TeleportOptions` with `ReservedServerAccessCode` for Ikatan teleport (so bonded players join the same server).

**FR-MLP-02:** On teleport departure: `DataService.save(player)` called before `TeleportAsync` fires. Use `Players.PlayerRemoving` as fallback.

**FR-MLP-03:** On arrival: `DataService.load(player)` called in `Players.PlayerAdded`. All services call `service.init(player)` after data is loaded.

**FR-MLP-04:** Last realm tracking — `PlayerData.lastRealmId` updated on each realm arrival. Used by `SkysPeakService` to teleport player back after a cycle.

**FR-MLP-05:** Cross-server Ikatan presence (who's online): use `MemoryStoreService.SortedMap` with key `"OnlinePlayers"`. Each server writes its players' IDs on join/leave with a 60-second TTL. `IkatanService` queries this map to surface online bonded partners.

**FR-MLP-06:** Wing level gate enforced on arrival by the destination place's server, not the origin. Malicious clients cannot bypass by modifying teleport data.

---

## 22. Security & Anti-Exploit

### 22.1 Requirements

**FR-SEC-01:** Server never trusts client-reported counts or state. Every gameplay action validated by position, ownership, cooldown, and state checks.

**FR-SEC-02:** Rate limiters — per-player, reset each second:

| Remote | Max Calls/sec |
|---|---|
| `Cahaya_CollectOrb` | 5 |
| `Flight_RequestBoost` | 3 |
| `Instrument_PlayNote` | 10 |
| `Spirit_CollectFragment` | 5 |
| `Emote_PlayRequest` | 2 |
| `Ikatan_OfferRequest` | 1 |
| All others | 3 |

Violation: first offense → drop silently. Second offense in 60 seconds → kick player with message `"Unusual activity detected."`.

**FR-SEC-03:** Position validation threshold:
- Cahaya orb collect: player within 10 studs of orb
- Spirit fragment: within 8 studs
- Ikatan offer: within 8 studs of target
- Revive: within 8 studs of target
- Instrument relay: player within 40 studs of listener

**FR-SEC-04:** `RemoteEvent` and `RemoteFunction` instances not accessible by name from client scripts — wrapped in typed accessors in `shared/Remotes.luau`. This does not prevent exploiters from finding them, but keeps legitimate code clean and auditable.

**FR-SEC-05:** DataStore writes are server-only. `DataService` is a `ServerScriptService` module. Never placed in `ReplicatedStorage`.

**FR-SEC-06:** All string inputs from client (expression bubble picks, etc.) validated against an allowlist on server. Free text never accepted from client (Roblox filters text chat separately).

**FR-SEC-07:** `MarketplaceService.ProcessReceipt` is wrapped in `pcall`. Any error inside returns `NotProcessedYet` (Roblox will retry). Never return `PurchaseGranted` if the grant itself errored.

---

## 23. Performance Requirements

### 23.1 Frame Rate Targets

| Platform | Target | Minimum |
|---|---|---|
| PC (High) | 60 FPS | 45 FPS |
| PC (Low) / Console | 60 FPS | 30 FPS |
| Mobile (High-end) | 60 FPS | 30 FPS |
| Mobile (Low-end) | 30 FPS | 24 FPS |

### 23.2 LOD System

**FR-PER-01:** Voxel models use `LOD` via `StreamingEnabled`. Roblox `ModelStreamingMode = Atomic` for spirit models (load all parts or none). `Incremental` for terrain details.

**FR-PER-02:** Streaming radius: 256 studs (PC), 192 studs (mobile). Set via `Workspace.StreamingMinRadius`.

**FR-PER-03:** Particle effects (auras, trails) scaled back on low-end mobile: detect via `UserSettings().GameSettings.SavedQualityLevel <= 3` and disable non-essential `ParticleEmitter` instances.

**FR-PER-04:** Instrument sound relay throttled by distance. Server only broadcasts notes to players ≤40 studs. No global broadcast.

**FR-PER-05:** Naga Gelap AI pathfinding max 3 agents per zone, path recalculated max every 2 seconds.

**FR-PER-06:** `RunService.Heartbeat` used for continuous systems (Kegelapan drain, Harmoni check). `RunService.RenderStepped` used only for client-side cosmetic animations and camera. Never mix.

**FR-PER-07:** `MemoryStoreService` used for ephemeral cross-server data (online presence). `DataStore` used only for persistence. Never query DataStore per-heartbeat.

---

## 24. Error Handling & DataStore Reliability

### 24.1 Requirements

**FR-ERR-01:** All DataStore operations wrapped in a retry utility:

```luau
-- shared utility used by DataService
local function retryAsync(fn, maxAttempts, delaySeconds)
    for attempt = 1, maxAttempts do
        local ok, result = pcall(fn)
        if ok then return result end
        if attempt < maxAttempts then task.wait(delaySeconds) end
    end
    warn("[DataService] DataStore failed after", maxAttempts, "attempts")
    return nil
end
```

Max attempts: 5. Delay: 2 seconds. Used for all `GetAsync`, `SetAsync`, `UpdateAsync` calls.

**FR-ERR-02:** `UpdateAsync` preferred over `SetAsync` for all player data writes (prevents race conditions on multi-server writes, e.g. Ikatan list).

**FR-ERR-03:** Periodic auto-save every 60 seconds per player using `task.delay` loop in `DataService`. Saves on `Players.PlayerRemoving` as well (with `pcall` — do not yield past game close).

**FR-ERR-04:** If `DataService.load(player)` fails: give the player a blank-state session and `warn()`. Do not kick them. Show a toast: `"UI_TOAST_DATA_LOAD_ERROR"` (localized). Do not save on this session's exit (to avoid overwriting real data with blank state).

**FR-ERR-05:** `ProcessReceipt` errors: any `pcall` failure inside returns `Enum.ProductPurchaseDecision.NotProcessedYet`. Log the error to server with `warn()` including `receiptInfo.PurchaseId` for debugging.

**FR-ERR-06:** All `RemoteEvent:FireClient` calls wrapped in `pcall` to prevent one bad client from crashing a server-side loop.

---

## 25. Testing Requirements

**Tooling:** TestEZ (via Wally: `roblox/testez`)

### 25.1 Unit Test Coverage Requirements

Each service must have a companion test file at:
```
src/server/Services/__tests__/CahayaService.spec.luau
src/shared/__tests__/Format.spec.luau
```

Minimum required unit tests per system:

| System | Required Tests |
|---|---|
| `CahayaService` | daily cap enforcement, extinguish trigger, revive logic, gift limits |
| `WingService` | upgrade cost deduction, level gate, carry unlock at L4 |
| `DailyTaskService` | task generation seeding, progress increment, milestone claim, streak logic |
| `SeasonService` | season active check, quest progress, koin musim multiplier |
| `IkatanService` | offer TTL expiry, bidirectional write, max 30 cap |
| `SpiritService` | fragment count validation, re-free prevention, daily spirit daily-reset |
| `MonetizationService` | idempotent receipt, pending grant on re-login |
| `Format.luau` | number formatting per locale, countdown edge cases |

### 25.2 Integration Test Requirements

- Full daily task cycle: join → progress tasks → claim all milestones → verify DataStore state
- Sky's Peak cycle: enter → ascend → sacrifice → verify Cahaya zeroed + Cayaha Hati awarded + badge granted
- Ikatan formation: two mock players → offer → accept → verify bidirectional list + Cahaya Hati award
- Season pass grant: mock receipt → verify spirits freed, cosmetics granted, koin musim multiplier active

### 25.3 Manual QA Checklist (per build)

- [ ] New player tutorial flow completes without errors
- [ ] Daily reset fires at correct UTC+7 midnight
- [ ] Wing level gate blocks underpowered players at realm teleport
- [ ] Kegelapan drain triggers and extinguishes correctly
- [ ] Naga Gelap detects player, chases, extinguishes, patrols
- [ ] Ikatan offer/accept works cross-server (two separate test servers)
- [ ] MarketplaceService receipt fires and grants correct items
- [ ] Arabic RTL layout correct on all UI panels
- [ ] CJK font renders on instrument UI note buttons
- [ ] Mobile FAB shows correct context action
- [ ] Carry mechanic: weld attaches, 2x charge consumed, bail works

---

## 26. Dependency Map (Wally)

```toml
# wally.toml
[dependencies]
Promise        = "evaera/promise@4.0.0"
Signal         = "sleitnick/signal@1.5.0"
Component      = "sleitnick/component@2.2.0"
Maid           = "evaera/maid@1.0.0"
t              = "osyrisrblx/t@3.1.1"
TestEZ         = "roblox/testez@0.4.1"
```

### Dependency Usage Map

| Package | Used By |
|---|---|
| `Promise` | `DataService` (all async DataStore ops), `IkatanService` (Ikatan graph writes) |
| `Signal` | Internal BindableEvent replacement for service-to-service events (DailyTask tracking) |
| `Component` | Cahaya orb components, Spirit components, Kegelapan zone components |
| `Maid` | All service cleanup in `service.cleanup(player)` — connection teardown |
| `t` | Runtime validation of all incoming Remote payloads before processing |
| `TestEZ` | All `.spec.luau` test files |

### `t` Validation Example

```luau
-- in IkatanService, validating incoming remote payload
local Remotes = require(shared.Remotes)
local t = require(Packages.t)

local validateOffer = t.strictInterface({
    targetUserId = t.number,
})

Remotes.Ikatan_OfferRequest.OnServerEvent:Connect(function(player, payload)
    if not validateOffer(payload) then return end  -- silent drop on bad payload
    IkatanService.handleOffer(player, payload.targetUserId)
end)
```

---

*Dirgantara PRD v0.1 — Technical scripting specification. All system designs subject to iteration during implementation.*
