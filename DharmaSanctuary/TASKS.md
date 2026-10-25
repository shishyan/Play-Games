# Dirgantara — Technical Task Breakdown

**Based on:** GDD.md v0.1 + PRD.md v0.1  
**Coverage:** All `FR-XXX-NN` requirements  
**Format:** `[ ]` = todo · `[x]` = done  

> Tasks are ordered by dependency. **Phase 0 must be complete before any other phase.**  
> Each task lists: what to build, which file(s), and what "done" looks like.

---

## Phase 0 — Foundation (Prerequisite for Everything)

### T-000 · Project Scaffold

- [x] **T-001 · Create full folder structure**  
  Create all directories and empty `.luau` stub files matching the structure in PRD §1.1:  
  `src/server/Services/`, `src/server/NPC/`, `src/client/Controllers/`, `src/client/UI/Components/`, `src/shared/`.  
  **Output:** Rojo syncs cleanly with no missing path errors. `default.project.json` paths all resolve.

- [x] **T-002 · Install Wally dependencies**  
  Add all six packages to `wally.toml` (PRD §26): `evaera/promise`, `sleitnick/signal`, `sleitnick/component`, `evaera/maid`, `osyrisrblx/t`, `roblox/testez`. Run `wally install`.  
  **Output:** `Packages/` and `ServerPackages/` populated. All packages importable via `require(Packages.Promise)` etc.  
  *Note: Used available registry versions — Signal@2.0.3, Component@2.4.8, Maid→flamenco687/maid@3.2.2.*

- [x] **T-003 · Write `shared/Types.luau`**  
  Define and export every Luau type from PRD §2: `PlayerData`, `DailyTaskState`, `DailyTask`, `WeeklyState`, `MonthlyState`, `EquippedLoadout`, `SpiritDef`, `SpiritReward`, `WingDef`, `SeasonDef`, `SeasonQuest`, `CosmeticDef`, `TaskDef`, `TaskReward`.  
  **Output:** Any service can `require(shared.Types)` and use strict types. No `any` in type signatures.

- [x] **T-004 · Write `shared/Constants.luau`**  
  Define all game constants as named values (no magic numbers anywhere else): `DAILY_CAHAYA_CAP = 150`, `MAX_IKATAN = 30`, `IKATAN_OFFER_TTL = 30`, `IKATAN_TELEPORT_COOLDOWN = 1800`, wing level caps, orb respawn time, zone ranges, rate limits, product IDs (stubs), daily task tier thresholds, chest reward weights, Awan XP values per action. Asset references must NOT go here — use `Assets.luau` instead.  
  **Output:** All subsequent modules import constants from here — no raw numbers in logic code.

- [x] **T-004b · Write `shared/Assets.luau` — asset ID config** ✅ *(file created, IDs pending)*  
  Single source of truth for every asset reference in the game: icon image IDs, texture IDs, VFX model paths, SFX sound IDs, instrument note sound IDs (5 notes × 5 instruments), BGM track IDs, animation IDs, font asset IDs, model ReplicatedStorage paths, sprite sheet config. All unset assets default to `0` (numbers) or `""` (strings) as fill-in-later markers.  
  No other file may hardcode an `rbxassetid://` string or a model path — all must go through `Assets.KEY`.  
  **Output:** `Assets.SFX.OrbCollect`, `Assets.BGM.AmbientSolo`, `Assets.Animations.EmoteWave`, `Assets.Models.NagaGelap`, etc. all resolve correctly. Swapping any asset requires editing only this one file.

- [ ] **T-004c · Populate `Assets.luau` with real asset IDs**  
  Once artists/audio team deliver final assets, replace all `0` placeholder values with real Roblox asset IDs. Cover all 7 categories: Icons (~45 IDs), Textures (~15 IDs), SFX (~40 IDs), Instruments (25 note IDs + 3 variant IDs), BGM (~15 IDs), Animations (~30 IDs), Fonts (2 IDs). Update VFX model path strings to match final folder structure in `ReplicatedStorage`.  
  **Output:** Zero `0` values remaining in `Assets.luau`. `ContentProvider:PreloadAsync()` on all asset IDs completes without errors.

- [x] **T-005 · Write `shared/WingDefs.luau`**  
  Define the `WingDef` table for all 10 wing levels (PRD §6.1) with `level`, `name`, `cahayaHatiCost`, `chargeSegments`, `canCarry`, `canEnterSkysPeak`.  
  **Output:** `WingDefs[level]` returns correct config for any wing level 1–10.

- [x] **T-006 · Write `shared/RealmDefs.luau`**  
  Define metadata for all 7 realms: `id`, `placeId` (stub), `nameKey`, `minWingLevel`, `kegelapanZoneCount`, `hasSeasonalExtension`.  
  **Output:** `RealmDefs["ISLE_DAWN"]` returns correct config. Wing gate lookup works.

- [x] **T-007 · Write `shared/SpiritDefs.luau`**  
  Define `SpiritDef` entries for all Isle of Dawn Ancestor Spirits (3 stubs from GDD Appendix A) plus type definition. Include daily spirit type stubs. Full spirit roster populated per realm as content is built.  
  **Output:** `SpiritDefs["ISLE_WATCHER"]` returns a valid `SpiritDef`. Type errors caught at require time.

- [x] **T-008 · Write `shared/DailyTaskDefs.luau`**  
  Define the full task pool: Easy (9 tasks), Medium (6 tasks), Hard (5 tasks) as `TaskDef` entries per PRD §11.1 table. Each entry has `id`, `difficulty`, `descriptionKey`, `target`, `trackingEvent`.  
  **Output:** Arrays `EasyPool`, `MediumPool`, `HardPool` exported. Seeded random picks from these produce valid `DailyTask` objects.

- [x] **T-009 · Write `shared/CosmeticDefs.luau`**  
  Define `CosmeticDef` entries for at minimum: 3 starter cosmetics (cape, emote, trail), 3 Isle of Dawn spirit rewards. Full roster populated as content is created.  
  **Output:** `CosmeticDefs["STARTER_CAPE"]` returns valid `CosmeticDef`. Category and rarity fields correct.

- [x] **T-010 · Write `shared/SeasonDefs.luau`**  
  Define `SeasonDef` for Season 1 (Musim Hujan Bintang) with stub timestamps, spirit IDs, quest chain (7 steps), Koin Musim shop items.  
  **Output:** `SeasonDefs["SEASON_01_STARFALL"]` returns valid `SeasonDef`. Season timestamps are real UTC values.

- [x] **T-011 · Write `shared/Remotes.luau`**  
  Create all `RemoteEvent` and `RemoteFunction` instances (PRD §3.1–3.10, ~40 remotes). On server: create instances in `ReplicatedStorage.Remotes`. Export typed accessor functions so callers never reference remotes by raw string name.  
  **Output:** `Remotes.Cahaya_CollectOrb:FireServer(payload)` works from client. `Remotes.Cahaya_CollectOrb.OnServerEvent:Connect(fn)` works from server. All 40 remotes accessible.

---

### T-010 · Bootstrap

- [x] **T-012 · Write `server/init.server.luau`**  
  Require and boot all services in the order defined in PRD §1.3. Connect `Players.PlayerAdded` → call `service.init(player)` for each service in order. Connect `Players.PlayerRemoving` → call `service.cleanup(player)` + `DataService.save(player)`.  
  **Output:** Server boots without errors. Joining player triggers `init()` on all services in correct order. Leaving player triggers `cleanup()` + save.

- [x] **T-013 · Write `client/init.client.luau`**  
  Require and boot all controllers: `InputController` → `UIController` → `FlightController` → `CameraController` → `AudioController` → `CosmeticController` → `InstrumentController` → `EmoteController`. Wait for character load before starting gameplay controllers.  
  **Output:** Client starts without errors. All controllers initialized before player can interact.

---

## Phase 1 — Data Layer

- [x] **T-014 · Write `server/Services/DataService.luau` — load / save / retry**  
  Implement `load(player)`: fetch from `"PlayerData_v1_{userId}"` with `retryAsync` (5 attempts, 2s delay). If first-ever save: create default `PlayerData` from `Types.luau`. Cache in-memory. Implement `save(player)`: write via `UpdateAsync` with `retryAsync`. If load fails: use blank-state with `dataLoadFailed = true` flag — do not overwrite real data on exit.  
  **Output:** Player data loads on join, persists on leave. `DataService.get(player)` returns in-memory copy. Failed loads produce blank state without overwriting DataStore.

- [x] **T-015 · Write `DataService` — daily reset logic**  
  On `load(player)`, compare `dailyResetTimestamp` against current UTC+7 midnight (`os.time()` adjusted). If stale: zero `dailyCahayaCollected`, `ikatanGiftsGivenToday`, `dailyChestBonusUsedToday`; clear `dailySpiritsTouched`; update `dailyResetTimestamp`. Fire a `BindableEvent` `"DailyReset"` so `DailyTaskService` can react.  
  **Output:** Player logging in after midnight gets fresh daily counts. Same-day re-login does not reset.

- [x] **T-016 · Write `DataService` — auto-save loop**  
  Start a `task.delay` loop per player that calls `DataService.save(player)` every 60 seconds while the player is in-game.  
  **Output:** DataStore is written every 60 seconds per online player. Loop is cancelled in `cleanup(player)`.

- [x] **T-017 · Write `DataService` — global DataStore helpers**  
  Implement accessors for `IkatanGraph_v1`, `SeasonConfig_v1`, `DailySpiritSpawn_v1`, `PurchaseHistory_v1`, `PendingGrants_v1`, `Leaderboard_v1` (OrderedDataStore). All wrapped with same `retryAsync` utility.  
  **Output:** Other services can call `DataService.readGlobal(storeName, key)` and `DataService.writeGlobal(storeName, key, value)` without touching DataStore API directly.

- [x] **T-018 · Write `retryAsync` utility**  
  Standalone module in `shared/` or inline in `DataService`: `retryAsync(fn, maxAttempts, delaySeconds)` — pcall wraps `fn`, retries on failure, warns after all attempts exhausted, returns `nil` on total failure.  
  **Output:** Unit-testable. Used in DataService and IkatanService for all async DataStore calls.

---

## Phase 2 — Flight System

- [x] **T-019 · Write `server/Services/FlightService.luau` — boost validation**  
  On `Flight_RequestBoost`: check player's current charge > 0; validate submitted position within plausible range (≤80 studs from `lastValidPosition` at L1–3, ≤100 at L4–5, ≤150 absolute cap); deduct 1 charge segment; update `lastValidPosition`; fire `Flight_BoostResult_S2C { granted = true, newCharge }`. Reject outside-range requests, fire `{ granted = false }`, force-reset player position.  
  **Output:** Legitimate boosts confirmed. Teleport-exploit positions rejected and player snapped back.

- [x] **T-020 · Write `FlightService` — charge config per player**  
  Store per-player charge state: `{ current: number, max: number }` keyed by `userId`. Max segments determined by wing level (PRD §4.1 table). `FlightService.setWingLevel(player, level)` updates max. `FlightService.addCharge(player, amount)` clamps to max.  
  **Output:** Wing upgrade instantly updates charge max. `FlightService.getCharge(player)` returns accurate current charge.

- [x] **T-021 · Write `FlightService` — charge refill loop**  
  Server-side `RunService.Heartbeat` loop: for each player, detect if on ground (raycast downward ≤3 studs) → refill at 0.25 seg/sec; detect nearby higher-level player (≤15 studs) → refill at 0.75 seg/sec; apply Harmoni bonus (+0.5 seg/sec) if flagged; halve all refill if in Kegelapan zone. Fire `Flight_BoostResult_S2C` when charge changes.  
  **Output:** Charge refills at correct rates. Kegelapan halving active inside zones. Harmoni bonus applied while Harmoni active.

- [x] **T-022 · Write `FlightService` — extinguish / restore**  
  `FlightService.extinguish(player)`: set `Humanoid.JumpHeight = 0`, `WalkSpeed = 8`, store `isExtinguished = true`. `FlightService.restore(player)`: reverse Humanoid properties, set `isExtinguished = false`. Called by `CahayaService`.  
  **Output:** Extinguished players cannot fly or jump. Restored players regain full mobility.

- [x] **T-023 · Write `FlightService` — carry mechanic (server)**  
  On `Flight_CarryRequest`: validate carrier is wing level ≥4, within 8 studs of target, not already carrying. On `Flight_CarryAccept`: create `WeldConstraint` between carrier `BackAttachment` and carried `HumanoidRootPart`; set carry flags. Double charge cost per boost for carrier. On `Flight_CarryEnd` or either player leaves: destroy weld, clear flags, fire `Flight_CarryState_S2C { active = false }` to both.  
  **Output:** Carried player moves with carrier. Bail by either party cleanly destroys weld. Carrier charge depletes at 2x rate.

- [x] **T-024 · Write `client/Controllers/FlightController.luau` — state machine**  
  Implement the 4-state machine: `IDLE → BOOST → GLIDE → EXTINGUISHED`. On FlyBoost action: fire `Flight_RequestBoost` with current position + velocity. On `Flight_BoostResult_S2C`: if granted, apply impulse to character; update charge display. On `Cahaya_Extinguished_S2C`: enter EXTINGUISHED state. On `Cahaya_Restored_S2C`: exit to IDLE.  
  **Output:** Smooth flight. State machine correctly transitions. Server rejection snaps player back without jank. Extinguished state disables boost input.

- [x] **T-025 · Write `client/Controllers/CameraController.luau`**  
  Auto-orbit: camera follows movement direction on mobile (no input needed). Swipe-to-look on mobile, mouse-look on PC, right-stick on console. Smooth interpolation (`CFrame.lerp`, `RunService.RenderStepped`). No camera clipping through terrain (use Roblox default camera offset as base).  
  **Output:** Camera feels responsive on all three platforms. No jitter or clipping artifacts.

---

## Phase 3 — Cahaya System

- [x] **T-026 · Write `server/Services/CahayaService.luau` — orb collection**  
  On `Cahaya_CollectOrb`: validate player within 10 studs of orb position (server reads orb position from workspace by `orbId`); orb not already in per-session collected set; `dailyCahayaCollected < 150`. If pass: increment `cahaya` + `dailyCahayaCollected`, destroy orb part, fire `Cahaya_CollectResult_S2C`. Mark orb for respawn in 5 minutes.  
  **Output:** Orb collected → Cahaya increments → orb disappears. Cap of 150 enforced. Duplicate collection rejected.

- [x] **T-027 · Write `CahayaService` — orb respawn timer**  
  Track each destroyed orb by `orbId` with a `task.delay(300, respawnFn)`. `respawnFn` re-clones the orb Part from a template in `ReplicatedStorage.Assets.Orbs` and places it at the original position. Orb tagged `"CahayaOrb"` with original `orbId` attribute restored.  
  **Output:** Orbs reappear 5 minutes after collection. Re-entering the realm shows available orbs (server-side truth).

- [x] **T-028 · Write `CahayaService` — Cahaya sync on join**  
  In `CahayaService.init(player)`: fire `Cahaya_SyncState_S2C { cahaya, cahayaHati }` to the joining player immediately after data load.  
  **Output:** Client shows correct Cahaya values as soon as character spawns.

- [x] **T-029 · Write `CahayaService` — extinguish / revive**  
  `CahayaService.drain(player, amount)`: deduct `amount` from `cahaya`; if reaches 0, fire `Cahaya_Extinguished_S2C`, call `FlightService.extinguish(player)`, teleport to `lastSafeCheckpoint` (stored in session memory, updated every 10 seconds player is in a safe zone).  
  `CahayaService.revive(rescuer, target)`: validate both within 8 studs server-side; deduct 1 from `rescuer.cahaya`; set `target.cahaya = 10`; call `FlightService.restore(target)`; fire `Cahaya_Restored_S2C` to target; fire `Cahaya_SyncState_S2C` to rescuer. Fire `"PlayerRevived"` BindableEvent for daily task tracking.  
  **Output:** Extinguishment triggers flight lock + teleport. Revive restores target with 10 Cahaya. Rescuer's Cahaya decrements.

- [x] **T-030 · Write `CahayaService` — Cahaya Hati gifting**  
  `CahayaService.gift(giver, recipient, amount)`: validate `ikatanGiftsGivenToday < 3` (daily limit); deduct from giver `cahayaHati`, add to recipient `cahayaHati`; increment giver's gift count; award giver +0.5 `cahayaHati`; fire `Cahaya_GiftResult_S2C` to giver; fire notification to recipient.  
  **Output:** Gift succeeds ≤3 times/day. Giver gets partial return. Recipient balance updates.

- [x] **T-031 · Write `CahayaService` — safe checkpoint tracking**  
  Every 10 seconds (server `task.delay` loop per player), if player is NOT in a Kegelapan zone: record `lastSafeCheckpoint = character.PrimaryPart.Position`. Used by extinguishment respawn.  
  **Output:** Respawn after extinguishment places player at last known safe location, not world origin.

---

## Phase 4 — Wing Progression

- [x] **T-032 · Write `server/Services/WingService.luau` — upgrade flow**  
  On `Wing_UpgradeRequest`: validate `wingLevel < 10`, `cahayaHati >= WingDefs[level+1].cahayaHatiCost`, no active Sky's Peak run (`SkysPeakService.isRunActive(player)`). Deduct cost, increment `wingLevel`, update `FlightService` charge max, award Awan XP (`+50 * newLevel`), fire `Wing_UpgradeResult_S2C { success, newLevel, newCahayaHati }`.  
  **Output:** Upgrade succeeds when all conditions met. Insufficient Cahaya Hati returns `success = false`. Wing level persists in DataStore.

- [x] **T-033 · Write `WingService` — realm entry gate**  
  Expose `WingService.canEnterRealm(player, realmId): boolean`. Called on realm arrival (TeleportService). If `wingLevel < RealmDefs[realmId].minWingLevel`: fire `Wing_GateDenied_S2C` (add this remote to `Remotes.luau`) with required level; do NOT allow character to spawn in the realm (kick back to Hub).  
  **Output:** Under-leveled players are refused realm entry with a clear message. No way to enter gated realm through teleport manipulation.

- [x] **T-034 · Write `WingService` — join sync**  
  In `WingService.init(player)`: fire `Wing_LevelSync_S2C { level }` to player. Update `FlightService` charge max to match persisted wing level.  
  **Output:** Returning player's wing level is immediately correct on rejoin.

- [x] **T-035 · Write `WingService` — Awan XP + Awan Rank**  
  `WingService.awardAwanXP(player, amount)`: increment `awanXP`, check against rank thresholds (PRD §5.2 table), fire `AwanXP_Update_S2C { xp, rank }` if rank changed. Add remote to Remotes.luau.  
  **Output:** XP awards from all sources (wing upgrade, Ikatan, Sky's Peak) accumulate. Rank-up fires notification to client.

---

## Phase 5 — Kegelapan System

- [x] **T-036 · Write `server/Services/KegelapanService.luau` — zone detection**  
  On server startup, find all `BasePart` tagged `"KegelapanZone"`. For each zone: read `DrainRate`, `DrainInterval`, `ZoneId` attributes. On `RunService.Heartbeat`: check each player's position against each zone using `workspace:GetPartBoundsInBox()`. On zone entry: start drain loop, fire `Kegelapan_ZoneState_S2C { zoneId, entered = true }`. On exit: stop loop, fire `{ entered = false }`.  
  **Output:** Entering a Kegelapan zone starts Cahaya drain and fires client visual cue. Exiting stops drain. Multiple zones supported simultaneously.

- [x] **T-037 · Write `KegelapanService` — drain loop**  
  Per player per active zone: `task.delay(DrainInterval, fn)` loop that calls `CahayaService.drain(player, DrainRate)`. Loop cancels when player exits zone or is extinguished. Respect `isDimmed` flag: if true, drain pauses 5s then resumes at 0.5x rate.  
  **Output:** Drain ticks every N seconds inside zone. Dim toggle pauses then reduces drain. Extinguishment stops the loop.

- [x] **T-038 · Write `KegelapanService` — self-dim toggle**  
  On `Kegelapan_DimRequest`: toggle `isDimmed[player]`. Fire `Kegelapan_DimState_S2C { dimmed: boolean }` to player and nearby players (for visual cue). Add these two remotes to `Remotes.luau`.  
  **Output:** Player can toggle light dim. Naga Gelap AI reads `isDimmed` flag. Client shows dim visual.

- [x] **T-039 · Write `KegelapanService` — Peti Cahaya chests**  
  On `PetiCahaya_Open` remote: validate player is inside the chest's parent zone; chest not already opened (`PlayerData.openedChests[chestId]`). Grant reward (Cahaya + cosmetic fragment). Set `openedChests[chestId] = true` permanently. Add remote to `Remotes.luau`.  
  **Output:** Chest opens once per account. Reward granted. Re-opening returns no reward (flag persists in DataStore).

- [x] **T-040 · Write client-side Kegelapan visuals**  
  On `Kegelapan_ZoneState_S2C`: `AudioController` crossfades ambient music to tension track; apply `ColorCorrectionEffect` to `Lighting` (desaturated, dark). On zone exit: fade back to normal. On `Kegelapan_DimState_S2C { dimmed = true }`: reduce player character light emission (dim `SurfaceLight` or `PointLight` on character).  
  **Output:** Entering darkness zone is immediately apparent visually and audibly. Dim toggle visible to nearby players.

---

## Phase 6 — Naga Gelap AI

- [x] **T-041 · Write `server/NPC/NagaGelapAI.luau` — state machine**  
  Implement PATROL → CHASE → EXTINGUISH_PLAYER state machine (PRD §8.2). On zone entry (triggered by `KegelapanService`): spawn up to 3 Naga models from template asset. State transitions: scan players within 40 studs per tick, check `cahaya > 20` and `isDimmed == false` for detection. On catch (≤5 studs): call `CahayaService.extinguish(target)`, return to PATROL.  
  **Output:** Naga detects bright players, chases, catches, extinguishes, patrols again. Dim players are ignored.

- [x] **T-042 · Write `NagaGelapAI` — pathfinding**  
  Use `PathfindingService:CreatePath()` + `Path:ComputeAsync()` for chase. Recalculate path every 2 seconds or when path is blocked. Move Naga via `Humanoid:MoveTo()` following waypoints.  
  **Output:** Naga navigates around obstacles inside the zone. Does not get stuck on terrain.

- [x] **T-043 · Write `NagaGelapAI` — zone boundary clamping**  
  Each Naga has a `zoneBounds: Region3` set at spawn time (derived from the zone `BasePart` extents). Before every `MoveTo()`: clamp target position to `zoneBounds`. Naga never chases a player outside its zone boundary.  
  **Output:** Naga cannot leave its assigned zone, even if chasing a player who exits.

- [x] **T-044 · Write `NagaGelapAI` — client relay**  
  Server fires `NagaGelap_StateRelay_S2C { nagaId, position, state }` every 0.1 seconds to players within 80 studs. On despawn: fire `{ nagaId, despawned = true }`. Add remotes to `Remotes.luau`.  
  **Output:** Client receives Naga position updates at 10Hz for nearby Nagas. Client-side model moves smoothly via CFrame interpolation. Naga disappears when no players present.

- [x] **T-045 · Write client-side Naga rendering**  
  On `NagaGelap_StateRelay_S2C`: clone Naga model from `ReplicatedStorage.Assets.NPCs.NagaGelap`, place at received position. Interpolate CFrame each `RenderStepped` toward latest server position (smoothing factor 0.15). Play growl audio, intensity scaled inversely to distance from player. On despawn message: destroy model.  
  **Output:** Naga renders smoothly on client without snapping. Audio grows louder as Naga approaches.

---

## Phase 7 — Ikatan (Bond) System

- [x] **T-046 · Write `server/Services/IkatanService.luau` — offer flow**  
  On `Ikatan_OfferRequest { targetUserId }`: validate sender and target within 8 studs server-side; target not already in sender's `ikatanList`; both `ikatanList.length < 30`. Store `pendingOffers[targetUserId] = { fromUserId, expiresAt = os.time() + 30 }`. Fire `Ikatan_OfferNotify_S2C { fromUserId, fromName }` to target.  
  **Output:** Offer stored in-memory with TTL. Target receives notification. Expired offers are rejected on accept.

- [x] **T-047 · Write `IkatanService` — accept / decline flow**  
  On `Ikatan_AcceptRequest`: validate pending offer exists and `os.time() < expiresAt`. Write both `ikatanList` arrays via `DataService.writeGlobal("IkatanGraph_v1", ...)` using `UpdateAsync`. Award +2 `cahayaHati` to both via `CahayaService`. Award +30 Awan XP to both via `WingService`. Fire `Ikatan_FormedResult_S2C` to both. Fire `"IkatanFormed"` BindableEvent.  
  On `Ikatan_DeclineRequest`: clear pending offer silently.  
  **Output:** Bond is bidirectional and persisted. Both players' balances update. Daily task tracking fires.

- [x] **T-048 · Write `IkatanService` — teleport**  
  On `Ikatan_TeleportRequest { targetUserId }`: validate target in sender's `ikatanList`; cooldown not active (`lastTeleportTime[player] + 1800 < os.time()`); target's current realm wing level ≥ sender's wing level. Call `TeleportService:TeleportToPlaceInstance` with target's server instance code. Update `lastTeleportTime[player]`.  
  **Output:** Teleport to bonded partner works cross-server. 30-min cooldown enforced per session. Under-leveled destination blocked.

- [x] **T-049 · Write `IkatanService` — online presence via MemoryStore**  
  On `IkatanService.init(player)`: write `userId → serverJobId` to `MemoryStoreService.SortedMap("OnlinePlayers")` with 60s TTL. Refresh TTL every 45 seconds. On `cleanup(player)`: remove entry. On join: query MemoryStore for all Ikatan partners, fire `Ikatan_PresenceUpdate_S2C { onlinePartnerIds: { number } }` to player.  
  **Output:** Client knows which bonded partners are online. Presence updates within ~60 seconds of partner join/leave.

- [x] **T-050 · Write `IkatanService` — Ikatan gifting**  
  On `Ikatan_GiftRequest { targetUserId, itemId }`: validate `itemId` in sender's `ownedItems`; `targetUserId` in sender's `ikatanList`; item is giftable (`CosmeticDefs[itemId].giftable == true`). Remove from sender's inventory. Grant to recipient via `CosmeticService.grantItem`. Fire `Ikatan_GiftNotify_S2C` to recipient.  
  **Output:** Item transferred between bonded players. Sender loses item; recipient gains it. Non-giftable items rejected.

---

## Phase 8 — Spirits System

- [x] **T-051 · Write `server/Services/SpiritService.luau` — spawn + tagging**  
  On startup: iterate `SpiritDefs` for the current realm. Clone spirit model from `ReplicatedStorage.Assets.Spirits[spiritId]`, position at `def.position`. Tag with `CollectionService:AddTag("Spirit", model.PrimaryPart)`. Set `spiritId` attribute on primary part. Repeat for all fragment positions.  
  **Output:** All spirits for the realm spawn in-world at startup. Fragment parts are individually tagged and positioned correctly.

- [x] **T-052 · Write `SpiritService` — fragment collection validation**  
  On `Spirit_CollectFragment { spiritId, fragmentIndex, position }`: check player within 8 studs of `SpiritDefs[spiritId].fragmentPositions[fragmentIndex]`; fragment not already in per-player per-spirit session cache. Mark fragment collected. Fire visual confirmation remote to client. Fire `"SpiritFragmentCollected"` BindableEvent.  
  **Output:** Server validates proximity. Duplicate collection rejected. Client gets confirmation to play collect animation.

- [x] **T-053 · Write `SpiritService` — free spirit validation + reward**  
  On `Spirit_FreeRequest { spiritId }`: validate all fragments collected (check session cache count == `def.fragmentCount`); `PlayerData.freedSpiritIds[spiritId]` does not exist; if Season Spirit, `seasonPassOwned == true`. On success: set `freedSpiritIds[spiritId] = true`; call `CahayaService.add(player, def.reward.cahaya)`; call `WingService.awardAwanXP`; call `CosmeticService.grantItem(player, def.reward.itemId)` if present; fire `Spirit_FreeResult_S2C { success, reward }`; fire `"SpiritFreed"` BindableEvent.  
  **Output:** Spirit can only be freed once per account. All rewards granted in single atomic block. Daily task fires.

- [x] **T-054 · Write `SpiritService` — daily spirit spawn**  
  On first server boot of a UTC+7 day: check `DailySpiritSpawn_v1["YYYYMMDD"]`. If missing: generate 2 random realm + position pairs (seed: `tonumber(dateString)`), write to DataStore, cache in `MemoryStoreService`. All subsequent servers read from cache. On `Spirit_TouchDaily { spiritId, position }`: validate proximity; `spiritId` not in `PlayerData.dailySpiritsTouched`; grant +5 Cahaya + 0.5 Cahaya Hati; add to `dailySpiritsTouched`; fire `Spirit_DailyResult_S2C`.  
  **Output:** Same 2 daily spirit positions across all servers each day. Each player can touch each once per day.

- [x] **T-055 · Write `SpiritService` — companion toggle**  
  On `Spirit_ToggleCompanion { spiritId }`: validate spirit is freed (`freedSpiritIds[spiritId]`); toggle `activeCompanionSpiritId` in session memory. Fire `Spirit_CompanionState_S2C { spiritId, active }` to client.  
  **Output:** Server tracks which companion is active per player. Client uses this to render or dismiss companion model.

- [x] **T-056 · Write client-side companion rendering**  
  On `Spirit_CompanionState_S2C { spiritId, active = true }`: clone companion model from assets, attach to player character at fixed CFrame offset (1.5 studs to right, bobbing via `math.sin(tick())` offset on `RenderStepped`). On `active = false`: destroy model.  
  **Output:** Companion floats beside player, bobs smoothly. Dismissed cleanly.

- [x] **T-057 · Write `GaleriRohPanel` + RemoteFunction**  
  Add `GaleriRoh_GetList_Fn` (RemoteFunction) to `Remotes.luau`. Server returns `{ spiritIds: { string }, spiritDefs: { SpiritDef } }` for all freed spirits. Client panel opens as `ScreenGui`, renders each spirit in a `ViewportFrame` showing its diorama model. Clicking a spirit plays the vignette animation sequence.  
  **Output:** Panel opens, lists all freed spirits with thumbnails. Vignette plays on select. RTL-compatible layout.

---

## Phase 9 — Daily Task System

- [x] **T-058 · Write `server/Services/DailyTaskService.luau` — task generation**  
  On `init(player)` (after daily reset check): if `taskState.date != today`: generate new tasks. Seed = `player.UserId XOR tonumber(dateString)`. From seed: pick 3 from `EasyPool`, 1 from `MediumPool`, 1 from `HardPool` (no duplicates). Write to `PlayerData.taskState`. Fire `DailyTask_Sync_S2C { taskState }` to player.  
  **Output:** Each player gets a deterministic daily set (same on rejoin). Different players get different tasks. No duplicate tasks in one day's set.

- [x] **T-059 · Write `DailyTaskService` — BindableEvent listeners**  
  Subscribe to all tracking `BindableEvent`s (listed in PRD §11.1 table). On each event: find matching active (incomplete) tasks for the player; call `incrementProgress(player, taskDef, amount)`. If `progress >= target`: mark completed, fire `DailyTask_Progress_S2C { taskId, newProgress, completed = true }`.  
  **Output:** Every in-game action that maps to a task type increments the correct task. Multiple tasks can share the same event (e.g., two "collect Cahaya" tasks with different targets).

- [x] **T-060 · Write `DailyTaskService` — milestone claim**  
  On `DailyTask_ClaimMilestone { tier }`: validate `completedCount >= tierThreshold[tier]`; tier not already in `milestoneRewardsClaimed`. Grant reward: Cahaya via `CahayaService`, `cahayaHati` via direct data write, cosmetic fragment via `CosmeticService`. For tier 5 (Full Clear): roll Daily Chest from weighted table (PRD §11.2). Fire `DailyTask_MilestoneResult_S2C { tier, reward }`.  
  **Output:** Each milestone tier claimable exactly once per day. Full Clear reward randomly selects from weighted chest table.

- [x] **T-061 · Write `DailyTaskService` — login streak**  
  On `DataService` emit of `"PlayerLoaded"` BindableEvent: compute today's date string. Compare with `lastStreakDate`. If yesterday: increment streak. If today: no-op. If gap > 1 day: check `graceDaysRemaining > 0`, consume grace or reset streak to 1. Update `lastStreakDate`. Grant streak reward if milestone day (1, 3, 7, 14, 30, 60) via `CahayaService` + `CosmeticService`. Add grace day every 30-day streak up to max 3.  
  **Output:** Streak increments daily. Grace days consumed for misses. Milestone rewards granted once per milestone day.

- [x] **T-062 · Write `DailyTaskService` — weekly milestone tracking**  
  After each Full Clear: increment `weeklyState.fullClearDays`. On weekly reset (ISO week change): if `fullClearDays >= 5` and `rewardClaimed == false`: make reward available (client can claim via `DailyTask_ClaimWeekly` remote — add to Remotes). Grant 1 Rare cosmetic or 100 Koin Musim.  
  **Output:** Weekly milestone triggers after 5 full-clear days. Reward claimed once per week. New week resets counter.

- [x] **T-063 · Write `DailyTaskService` — monthly milestone tracking**  
  After each weekly milestone claim: increment `monthlyState.weeklyMilestonesMet`. On monthly reset (calendar month change): if `weeklyMilestonesMet >= 3` and `rewardClaimed == false`: make monthly reward available. Grant 1 Epic cosmetic.  
  **Output:** Monthly reward triggers after 3 weekly milestones in same month. Resets each new calendar month.

---

## Phase 10 — Season System

- [x] **T-064 · Write `server/Services/SeasonService.luau` — config loading**  
  On startup: read `SeasonConfig_v1["active"]` via `DataService.readGlobal`. Store active `SeasonDef` in memory. Poll for updates every 5 minutes (to pick up season transitions without server restart). Expose `SeasonService.getActiveSeason(): SeasonDef`.  
  **Output:** All services can read current season config. Season change detected within 5 minutes across all servers.

- [x] **T-065 · Write `SeasonService` — realm extension activation**  
  On startup (and on season change): activate seasonal realm extension by calling `CollectionService:AddTag("SeasonArea_\{seasonId}", part)` for all relevant `BasePart`s in the seasonal extension folder. Deactivate previous season's extension. Parts without the tag remain hidden (handled by designers tagging parts correctly).  
  **Output:** Seasonal area becomes accessible when season activates. Previous season area deactivates.

- [x] **T-066 · Write `SeasonService` — season quest progress**  
  Subscribe to BindableEvents matching each `SeasonQuest.completionEvent`. On event: find active season quest at current `step` for the player; increment `seasonQuestProgress[questId]`. On completion: fire `Season_QuestProgress_S2C { questId, progress }` to client; grant quest reward; advance quest pointer to next step.  
  **Output:** Quest chain advances step-by-step. Completion of step N unlocks step N+1. Rewards granted per step.

- [x] **T-067 · Write `SeasonService` — Koin Musim earn rate multiplier**  
  When `DailyTaskService` grants milestone rewards: call `SeasonService.getKoinMusimMultiplier(player)` → returns `2` if `seasonPassOwned`, else `1`. Multiply base Koin Musim earned. Add `koinMusim` increments via `DataService`.  
  **Output:** Pass owners earn double Koin Musim from daily tasks. Non-pass players earn base rate.

- [x] **T-068 · Write `SeasonService` — season end transition**  
  At `SeasonDef.endTimestamp`: set `seasonActive = false` internally. All `Spirit_FreeRequest` for season spirits rejected with `"Season has ended"`. New season `SeasonDef` loaded from DataStore. Fire `Season_StateSync_S2C` to all connected players with new season data.  
  **Output:** Old season spirits can no longer be freed. New season content activates. Owned cosmetics from old season remain.

- [x] **T-069 · Write `SeasonService` — Koin Musim Shop**  
  Add `KoinShop_BuyItem` remote to `Remotes.luau`. On purchase request: validate `koinMusim >= item.price`; item not already owned; item exists in active season's `koinMusimShop`. Deduct Koin Musim, grant item via `CosmeticService`. Fire confirmation to client.  
  **Output:** Players can spend Koin Musim on seasonal items. Correct price deducted. Duplicate purchase blocked.

---

## Phase 11 — Instruments & Harmoni

- [x] **T-070 · Write `server/Services/InstrumentService.luau` — note relay with rate limit**  
  On `Instrument_PlayNote { instrumentId, noteIndex }`: validate player owns instrument; validate `instrumentId == equippedItems.instrument`; enforce 10 notes/sec rate limit per player. Find all players within 40 studs. Fire `Instrument_NoteRelay_S2C { userId, instrumentId, noteIndex }` to each.  
  On `Instrument_Strum`: same flow, no rate limit check (strum is one event).  
  On `Instrument_SustainStart` / `Instrument_SustainEnd`: relay both to nearby players.  
  **Output:** Notes relay only to nearby players. Excess notes dropped silently. All 5 instrument types handled.

- [x] **T-071 · Write `InstrumentService` — Harmoni detection**  
  Every 5 seconds via `task.delay` loop: scan all online players; find clusters of 2+ players within 20 studs all playing instruments (tracked via `isPlaying[userId]` flag set on first note, cleared after 5s silence). For each cluster: fire `Harmoni_Start_S2C { playerIds }` to all in cluster; set `harmoniActive[userId] = true`; call `FlightService.applyHarmoniBonus(player)`. On cluster drop below 2: fire `Harmoni_End_S2C`, clear bonus.  
  **Output:** Harmoni triggers when 2+ musicians are close. Flight charge refill bonus applies. Ends when musicians separate or stop.

- [x] **T-072 · Write `client/Controllers/InstrumentController.luau`**  
  On `InputController` "Instrument" action: if instrument equipped, open `InstrumentUI`. On note button press: fire `Instrument_PlayNote`. On `Instrument_NoteRelay_S2C` received: play correct note sound via `SoundService` spatially at the source player's character position. Handle Strum (Siter/Angklung) and Sustain (Terompet) separately.  
  **Output:** Pressing note buttons fires remote and plays sound locally. Other players' notes play spatially. Sustain holds while button held.

- [x] **T-073 · Write `client/UI/InstrumentUI.luau`**  
  `ScreenGui` with 5 note buttons (pentatonic: C D E G A labels). On mobile: large tap targets (min 80px), visible only in instrument mode. On PC: also show keyboard hints (Z X C V B). On console: D-pad mapped. Strum instruments show a single strum button. Angklung shows shake indicator on mobile.  
  **Output:** UI opens when instrument action triggered. All 3 platforms have usable controls. Gyro shake fires strum on mobile when enabled in settings.

- [x] **T-074 · Write Angklung gyro input**  
  In `InputController`: subscribe to `UserInputService.DeviceGravityChanged` (mobile only). Compute shake magnitude from delta gravity vector. If magnitude > 1.5 and cooldown > 0.3s elapsed: fire `Instrument_Strum` remote. Show visual shake cue on screen.  
  **Output:** Shaking phone plays Angklung note on mobile. Threshold prevents accidental triggers. 0.3s cooldown prevents spam.

---

## Phase 12 — Emotes

- [x] **T-075 · Write `server/Services/EmoteService.luau` — play + relay**  
  On `Emote_PlayRequest { emoteId }`: validate ownership (`ownedItems[emoteId]`); emote in `equippedItems.emoteSlots`; not carrying or being carried. Fire `Emote_PlayRelay_S2C { userId, emoteId, isSynced = false }` to all players within 30 studs.  
  **Output:** Emote plays for nearby players. Non-owned or unequipped emotes rejected. Carry state blocks emote.

- [x] **T-076 · Write `EmoteService` — sync detection for bonded pairs**  
  After `Emote_PlayRequest` fires for Player A: query `ikatanList[A]` for any partner within 15 studs currently playing the same `emoteId`. If found: fire `Emote_PlayRelay_S2C { isSynced = true }` to both with partner's ID; fire `Emote_SyncCheck_S2C { partnerId, emoteId }` to both.  
  **Output:** Bonded pair using same emote near each other triggers duo animation instead of solo.

- [x] **T-077 · Write `client/Controllers/EmoteController.luau`**  
  On `Emote_PlayRelay_S2C`: find target character, load `AnimationTrack` from `CosmeticDefs[emoteId].assetId`. If `isSynced`: use `syncAnimationId` instead. Play on `Humanoid.Animator`. Track auto-stops at natural end.  
  **Output:** Emote animation plays on correct character. Synced animation plays when server flags it. No animation conflicts with flight.

- [x] **T-078 · Write `client/UI/EmoteWheel.luau`**  
  Radial wheel with 8 slots. Opens on EmoteWheel action (Q / swipe-up / D-pad up). Shows equipped emote icons from `equippedItems.emoteSlots`. Hover/tap fires emote. Closes on action release (PC/console) or tap elsewhere (mobile). RTL-compatible (wheel position mirrors).  
  **Output:** Wheel opens, shows correct emotes, fires on selection, closes cleanly. Works on all 3 platforms.

- [x] **T-079 · Write emote slot management (Inventory Panel integration)**  
  In `InventoryPanel`: show owned emotes. Allow drag-to-slot (PC) or tap-select (mobile) to equip to one of 8 slots. Fire `Cosmetic_EquipRequest { slot = "emoteSlot_N", itemId }` to server. Server validates and updates `equippedItems.emoteSlots[N]`.  
  **Output:** Players can assign emotes to wheel slots. Changes persist in DataStore.

---

## Phase 13 — Cosmetics & Inventory

- [x] **T-080 · Write `server/Services/CosmeticService.luau` — grantItem (idempotent)**  
  `CosmeticService.grantItem(player, itemId)`: if `ownedItems[itemId]` already exists, no-op and return. Validate `itemId` exists in `CosmeticDefs`. Add to `ownedItems`. Fire `Cosmetic_InventorySync_S2C` (partial update: `{ newItemId }`). Award Awan XP based on rarity tier.  
  **Output:** No duplicate items. Re-granting same item is safe. Client inventory updates immediately.

- [x] **T-081 · Write `CosmeticService` — equip validation + relay**  
  On `Cosmetic_EquipRequest { slot, itemId }`: validate slot is a valid `EquippedLoadout` key; if `itemId` is non-nil, validate owned. Update `equippedItems[slot]`. Fire `Cosmetic_EquipResult_S2C { success, loadout }` to player. Fire `Cosmetic_LoadoutRelay_S2C { userId, loadout }` to all players within 50 studs.  
  **Output:** Equip change persists. Nearby players see updated appearance within one relay cycle.

- [x] **T-082 · Write `CosmeticService` — fragment crafting**  
  `CosmeticService.grantFragment(player, itemId)`: increment `fragmentInventory[itemId]`. If count reaches 3: auto-call `grantItem(player, itemId)`; reset fragment count; fire `Cosmetic_FragmentCrafted_S2C { itemId }` to client.  
  **Output:** Three fragments auto-craft into one item. Player receives toast notification. Fragment count resets.

- [x] **T-083 · Write `CosmeticService` — inventory sync on join**  
  In `CosmeticService.init(player)`: fire `Cosmetic_InventorySync_S2C { ownedItems: { string } }` and `Cosmetic_EquipResult_S2C { loadout }` to the joining player.  
  **Output:** Client has full inventory and loadout data before character renders.

- [x] **T-084 · Write `client/Controllers/CosmeticController.luau` — character rendering**  
  On `Cosmetic_EquipResult_S2C` and `Cosmetic_LoadoutRelay_S2C`: for the relevant character, apply each equipped item by cloning its model from `ReplicatedStorage.Assets.Cosmetics[itemId]` and welding to the correct character attachment. Clear previous item in slot before applying new one. Wing skin: swap the mesh on the wing model.  
  **Output:** Character visually updates when loadout changes. Other players' characters also update on relay. No item models pile up.

- [x] **T-085 · Write `client/UI/InventoryPanel.luau`**  
  `ScreenGui` panel with category tabs (Cape, Mask, Hair, Outfit, Wing Skin, Instrument, Emote, Trail, Aura, Prop). List owned items per category with rarity color border. Tap/click to equip (fires `Cosmetic_EquipRequest`). Unequip button per slot. RTL-compatible tab order.  
  **Output:** Full inventory browsable by category. Equip/unequip works. Rarity visible. Localized category names.

---

## Phase 14 — Sky's Peak

- [x] **T-086 · Write `server/Services/SkysPeakService.luau` — run state machine**  
  States: `IDLE → ASCENDING → SUMMIT → SACRIFICING → COMPLETE`. On player arrival in Puncak Langit place: set state to `ASCENDING`. On reaching summit trigger zone (tagged `BasePart "SkysPeakSummit"`): set `SUMMIT`, fire `SkysPeak_SummitReached_S2C`. On `SkysPeak_Sacrifice` remote: validate state is `SUMMIT`. Begin `SACRIFICING` (5-second lock). On complete: execute reward flow, teleport back.  
  **Output:** State machine enforces correct flow. Sacrifice cannot be triggered outside summit zone. Disconnect mid-run clears state on next login.

- [x] **T-087 · Write `SkysPeakService` — sacrifice + reward flow**  
  On `SACRIFICING` completion: zero `PlayerData.cahaya`; increment `skysPeakCycles`; award +3 `cahayaHati`; award Awan XP +200; call `CosmeticService.grantItem(player, "WING_BADGE_\{cycleNumber}")`. Fire `SkysPeak_CycleComplete_S2C { cyclesTotal, reward }`. Set `lastRealmId` restore point. Teleport back via `TeleportService`.  
  **Output:** All rewards granted atomically. Cahaya zeroed. Badge ID is cycle-number-specific. Cosmetics unlocked persist.

- [x] **T-088 · Write `SkysPeakService` — Kegelapan altitude scaling**  
  During a run, on `RunService.Heartbeat`: read player's Y position. Map altitude from realm floor to summit into 0→1 range. Scale `DrainRate` from 1 to 3 using linear interpolation. Update the player's active Kegelapan zone drain rate dynamically.  
  **Output:** Darkness intensifies as player ascends. Near summit, drain is 3x baseline.

- [x] **T-089 · Write `SkysPeakService` — disconnect recovery**  
  In `SkysPeakService.init(player)`: check if `skysPeakRunInProgress` flag (session MemoryStore key `"SkysPeakRun_\{userId}"`). If true: clear flag, set state to `IDLE`. Player is in no-penalty state.  
  **Output:** Disconnecting mid-run does not lock or penalize the player on next login.

---

## Phase 15 — UI Layer

- [x] **T-090 · Write `client/Controllers/UIController.luau` — panel manager**  
  Track `activePanel: string?`. `UIController.openPanel(name)`: close current panel, open new one. `UIController.closePanel()`. Panels register themselves on creation. HUD always stays visible regardless of active panel.  
  **Output:** Only one major panel open at a time. Panel open/close is animated (tween fade). HUD never hides behind panels.

- [x] **T-091 · Write `UIController` — RTL direction system**  
  On init: read `LocalizationService.RobloxLocaleId`. If `"ar"`: set `UIController.isRTL = true`. Expose `UIController.applyLayout(listLayout)` which sets `HorizontalAlignment` and flips `UIPadding` for RTL. All UI modules call this after creating list layouts.  
  **Output:** Arabic players see fully mirrored horizontal UI. Latin/CJK players see standard LTR layout. Single toggle controls entire UI.

- [x] **T-092 · Write `UIController` — UI Scale system**  
  Read `PlayerData.uiScale` preference (0.75–1.5, default 1.0). Apply via `UIScale` instance as child of each `ScreenGui`. Expose settings panel slider that fires `Settings_SetUIScale` remote (add to Remotes). Server saves scale preference to PlayerData.  
  **Output:** UI shrinks/grows proportionally. Change persists across sessions. Works on all screen sizes.

- [x] **T-093 · Write `client/UI/HUD.luau` — wing charge bar**  
  `ScreenGui` with segment indicators (3–5 segments, count from `Wing_LevelSync_S2C`). Each segment fills/empties based on `Flight_BoostResult_S2C.newCharge`. Animate segment depletion with a brief flash on boost use. Halved-refill visual indicator when in Kegelapan.  
  **Output:** Charge bar reflects accurate charge count. Visual feedback on boost use. Kegelapan state shows dimmed bar.

- [x] **T-094 · Write `client/UI/HUD.luau` — Cahaya counter**  
  Show current `cahaya` value from `Cahaya_SyncState_S2C`. Animate number change with tween. Show daily cap indicator (progress bar 0–150) below counter. Glow effect when near cap. RTL: counter moves to top-right.  
  **Output:** Counter accurate after each orb collection. Daily cap progress visible. Correct position per layout direction.

- [x] **T-095 · Write `client/UI/HUD.luau` — compass + realm name**  
  Top-center label showing localized realm name. Small compass rose that rotates based on camera heading. Hidden in Sky's Peak (replaced by altitude indicator).  
  **Output:** Realm name shown in player's language. Compass rotates correctly. Sky's Peak shows altitude bar instead.

- [x] **T-096 · Write `client/UI/HUD.luau` — Social Pulse**  
  Bottom-right panel (bottom-left for RTL). Shows avatar icons of Ikatan partners online in same realm (from `Ikatan_PresenceUpdate_S2C`). Tapping an icon shows partner name. Glow pulses when partner is nearby (≤40 studs, provided via `Ikatan_NearbyUpdate_S2C` — add to Remotes).  
  **Output:** Up to 5 partner icons shown. Tap shows name. Glow indicates proximity. RTL: panel on left.

- [x] **T-097 · Write `client/UI/HUD.luau` — notification toast queue**  
  Toast manager: queue of messages, max 3 visible simultaneously. Each toast: icon + localized message + auto-dismiss after 4 seconds. Types: `info` (blue), `success` (gold), `warning` (orange). Stacks vertically, new toasts slide in from top.  
  **Output:** Toasts display without overlapping. Old toasts dismiss before new ones stack over limit. All messages use localization keys.

- [x] **T-098 · Write mobile FAB (Floating Action Button)**  
  Context-sensitive button, bottom-right on mobile only. Priority logic (PRD §17.9): checks for revivable player, Ikatan offer, spirit fragment, spirit interaction, instrument mode. Fires appropriate action on tap. Hidden on PC/console.  
  **Output:** FAB shows correct action label for nearest interactive element. Tapping fires the action. Disappears when no context available.

- [x] **T-099 · Write `client/UI/DailyTaskPanel.luau`**  
  Panel showing 5 tasks with progress bars, milestone reward indicators (5 tiers), Full Clear bonus highlight. Claim button per tier when completed. Daily/Weekly/Monthly tabs. Login streak display with day counter. All text localized. RTL-compatible layout.  
  **Output:** All task states visible. Milestone claim fires `DailyTask_ClaimMilestone`. Streak day and next reward visible. Opens from HUD shortcut.

- [x] **T-100 · Write `client/UI/IkatanPanel.luau`**  
  List of all Ikatan partners with online/offline indicator. Teleport button (30-min cooldown shown as countdown). Gift button. Remove Ikatan option. Shows pending incoming offer with Accept/Decline. Add-Ikatan prompt shown when near a non-bonded player.  
  **Output:** Full Ikatan management from one panel. Cooldown timer visible. Offer notification auto-opens panel.

- [x] **T-101 · Write `client/UI/SeasonPanel.luau`**  
  Show active season name, time remaining, spirit progress (freed/total), quest chain step tracker, Koin Musim balance and shop. Musim Pass buy button (fires `Monetization_PurchasePrompt`). All text localized.  
  **Output:** Season state fully visible. Purchase prompt fires correctly. Quest chain progress updates in real-time.

---

## Phase 16 — Input Abstraction

- [x] **T-102 · Write `client/Controllers/InputController.luau` — platform detection + binding**  
  On init: detect platform (`TouchEnabled`, `GamepadEnabled`). Build action binding map per PRD §18.4 table. `InputController.onAction(actionId, callback)` pub/sub. `InputController.offAction(actionId, callback)` cleanup.  
  **Output:** Any controller subscribes to an action ID. Platform-specific input correctly maps to shared action IDs. Adding new platforms requires changing only `InputController`.

- [x] **T-103 · Write `InputController` — double-tap detection (mobile)**  
  Track last FlyBoost tap timestamp. If second tap within 250ms: fire FlyBoost action. Prevent accidental triggers (require tap to land within 48px of button center).  
  **Output:** Double-tap reliably triggers boost on mobile without interfering with single-tap.

- [x] **T-104 · Write `InputController` — gamepad deadzone + analog normalization**  
  Apply 0.2 deadzone to left stick. Normalize to 0→1 range after deadzone. Pass normalized value to `FlightController` for movement direction. Right stick drives camera in `CameraController`.  
  **Output:** Gamepad movement feels smooth with no drift in neutral position. Analog values correctly normalized.

---

## Phase 17 — Audio

- [x] **T-105 · Write `client/Controllers/AudioController.luau` — adaptive ambient score**  
  Three ambient states: `SOLO` (sparse flute), `SOCIAL` (layered harmonic), `KEGELAPAN` (atonal tension). Crossfade between states using `Sound:TweenVolume()`. State determined by: players within 20 studs (solo→social), zone entry (→kegelapan). Kegelapan overrides social.  
  **Output:** Music transitions smoothly as context changes. No abrupt cuts. Kegelapan tension track plays inside dark zones.

- [x] **T-106 · Write `AudioController` — instrument note sounds**  
  Load 5 pentatonic note `Sound` instances (C D E G A) per instrument type from `Constants.luau` asset IDs. On `Instrument_NoteRelay_S2C`: play the note sound at the source player's position using `SoundService` with distance falloff. Spatial audio via `Sound.RollOffMaxDistance = 40`.  
  **Output:** Each instrument sounds distinct. Notes fade with distance. Playing instruments blends into ambient music naturally.

---

## Phase 18 — Localization Integration

- [x] **T-107 · Set up `LocalizationTable` in ReplicatedStorage**  
  Create `LocalizationTable` instance at `ReplicatedStorage.Localization.LocalizationTable`. Import base CSV with all string keys and English values (stubs initially). Add Indonesian (id) column with authored strings. Add Japanese, Arabic, Chinese Simplified columns (auto-translated stubs, flagged for review).  
  **Output:** `LocalizationService:GetTranslatorForPlayerAsync(player)` returns working translator. All defined keys resolve in English. Indonesian strings return correct Indonesian text.

- [x] **T-108 · Write `UIController.translate(key, params)` wrapper**  
  Wrap `translator:FormatByKey(key, params)`. Called by all UI modules. Never set `TextLabel.Text` to raw strings anywhere else. Log a warning (not an error) if key not found.  
  **Output:** All TextLabels set via this function. Missing keys show the key ID in debug mode instead of crashing.

- [x] **T-109 · Write `shared/Format.luau` — number, date, countdown**  
  `Format.number(n)`: locale-appropriate thousands separator and decimal mark. `Format.countdown(seconds)`: returns `"Xj Ym"` (id), `"Xh Ym"` (en), `"X時間Y分"` (ja), etc. `Format.date(timestamp)`: locale-appropriate date string.  
  **Output:** Numbers display correctly for id (1.500), ar (١٬٥٠٠), ja (1,500). Countdown timer localizes correctly. All UI that shows numbers calls these functions.

- [x] **T-110 · Write `shared/Fonts.luau` — locale font dispatch**  
  Map locale codes to font asset IDs (CJK font ID, Arabic font ID). Default to `GothamSsm`. Expose `Fonts.get(): Font`. Called once in `UIController` init, applied to all new TextLabels.  
  **Output:** Japanese/Chinese/Korean players see CJK glyphs correctly. Arabic players see correct Arabic font. Latin players see Gotham.

- [x] **T-111 · Implement RTL layout for all panels**  
  Apply `UIController.applyLayout()` to every `UIListLayout` in: HUD, DailyTaskPanel, IkatanPanel, InventoryPanel, SeasonPanel, GaleriRohPanel, EmoteWheel, InstrumentUI. Flip `AnchorPoint.X` on positioned elements. Reverse directional icons.  
  **Output:** Arabic locale shows fully mirrored UI in every panel. No elements clipped or overlapping after mirror.

- [x] **T-112 · Populate expression bubble preset phrases in LocalizationTable**  
  Add all 20 expression phrase keys (from GDD §16.9 table) for all Tier 1 languages (en, id, ja, ar, zh-cn). Verify with a native speaker sample for id, ar, ja before ship.  
  **Output:** Expression bubbles show correct phrase in player's language. All 20 phrases translated for 5 languages.

---

## Phase 19 — Monetization

- [x] **T-113 · Write `server/Services/MonetizationService.luau` — ProcessReceipt**  
  Implement `MarketplaceService.ProcessReceipt` callback. Load player data (or queue if offline). Check `PurchaseHistory_v1[receiptInfo.PurchaseId]` — if exists, return `PurchaseGranted`. Match `productId` to grant handler. Write `purchaseId` to `PurchaseHistory`. Return `PurchaseGranted`. Any error inside `pcall` returns `NotProcessedYet`.  
  **Output:** Receipt idempotent — re-delivered receipts do not double-grant. All errors recoverable by Roblox retry.

- [x] **T-114 · Write `MonetizationService` — Season Pass grant handlers**  
  Handler for `MUSIM_PASS`: set `seasonPassOwned = true`, grant seasonal cosmetic set, fire `Monetization_PassSync_S2C`. Handler for `MUSIM_PASS_PLUS`: same + set `seasonPassPlusOwned = true`, mark first 3 season spirits freed in `freedSeasonSpiritIds` + grant their cosmetic rewards via `CosmeticService`.  
  **Output:** Pass purchase immediately unlocks all season content for that player. Plus tier auto-frees first 3 spirits.

- [x] **T-115 · Write `MonetizationService` — Starter Pack handler**  
  On `STARTER_PACK` receipt: check `starterPackClaimed`. If true: return `PurchaseGranted` (no re-grant). Else: grant 50 Cahaya, 5 Cahaya Hati, 1 starter cosmetic bundle; set `starterPackClaimed = true`.  
  **Output:** Starter pack claimable exactly once per account. Refund attempt cannot re-grant.

- [x] **T-116 · Write `MonetizationService` — PendingGrants system**  
  If player not found in `Players` when `ProcessReceipt` fires (bought from website): write grant to `PendingGrants_v1[userId]` array. In `DataService.init(player)`: read `PendingGrants_v1[userId]`, apply each grant, clear the entry.  
  **Output:** Purchases made while offline are applied on next login without loss.

- [x] **T-117 · Write `MonetizationService` — Roblox Premium benefits**  
  In `MonetizationService.init(player)`: check `player.MembershipType`. If Premium: set `isPremium = true` in session. `CahayaService` checks this flag and applies +10% to each collection (multiply collected amount by 1.1, floor). Daily reset logic adds +10 bonus Cahaya.  
  **Output:** Premium players collect slightly more Cahaya per orb. Daily bonus applied at reset.

- [x] **T-118 · Write `Monetization_PurchasePrompt` remote handler**  
  Client fires `Monetization_PurchasePrompt { productId }`. Server validates `productId` is in allowed product list (whitelist from `Constants.luau`). Server calls `MarketplaceService:PromptProductPurchase(player, productId)`. Reject unknown product IDs silently.  
  **Output:** Purchase prompt opens correctly via server call. Clients cannot prompt arbitrary product IDs.

---

## Phase 20 — Multi-Place Architecture

- [x] **T-119 · Write TeleportService wrapper in `DataService`**  
  `DataService.safeTeleport(player, placeId, options)`: call `DataService.save(player)` first, await save confirmation (or timeout 3s), then call `TeleportService:TeleportAsync`. If save fails: warn and teleport anyway (do not block player).  
  **Output:** Player data saved before teleport. No data loss from realm transitions.

- [x] **T-120 · Write realm arrival handling**  
  In `WingService.init(player)`: after data load, check `RealmDefs[currentRealmId].minWingLevel`. If `wingLevel < min`: fire `Wing_GateDenied_S2C`, teleport player back to Hub (`RealmDefs["ISLE_DAWN"].placeId`). Update `PlayerData.lastRealmId` on successful entry.  
  **Output:** Under-leveled players bounced to Hub on arrival. Last realm ID persists for Sky's Peak return.

- [x] **T-121 · Write cross-server Ikatan presence (MemoryStore)**  
  (Covered in T-049.) Verify TTL refresh loop works. Test: Player A joins, B joins different server, A sees B online. B leaves, A sees B offline within ~60s.  
  **Output:** Online presence accurate cross-server within one TTL window.

---

## Phase 21 — Security & Anti-Exploit

- [x] **T-122 · Write shared rate limiter module**  
  `shared/RateLimiter.luau`: `RateLimiter.new(maxCalls, intervalSeconds)` returns a limiter. `limiter:check(userId): boolean` returns true if under limit, false if exceeded. Track per-userId call timestamps in a sliding window. On second offense within 60s: call `Players:GetPlayerByUserId(userId):Kick("Unusual activity detected.")`.  
  **Output:** Rate limiter correctly rejects calls above threshold. Second offense kicks player. Limiter resets correctly per interval.

- [x] **T-123 · Apply rate limiters to all remotes**  
  Instantiate `RateLimiter` per remote per the limits table in PRD §22.2. Apply in every `OnServerEvent` handler before any logic runs. Log first offense to `warn()`.  
  **Output:** Every C→S remote has a rate limit applied. Rapid-fire exploit attempts silently dropped then kick on repeat.

- [x] **T-124 · Write position validator module**  
  `shared/PositionValidator.luau`: `PositionValidator.isNear(playerPos, targetPos, maxStuds): boolean`. Used by all services that require proximity (orb collection, spirit, Ikatan, revive). Single source of truth for proximity logic.  
  **Output:** All proximity checks use this module. Changing the threshold requires editing one file.

- [x] **T-125 · Apply `t` payload validation to all remotes**  
  For each `OnServerEvent` handler: define a `t.strictInterface` validator for the expected payload shape. If validation fails: silently return (no error thrown to server). Prevents type-error exploits from sending malformed payloads.  
  **Output:** Malformed remote payloads are dropped before reaching any game logic. No Luau errors from bad client data.

---

## Phase 22 — Performance

- [x] **T-126 · Configure `StreamingEnabled` + LOD**  
  In `Workspace`: set `StreamingEnabled = true`. Set `ModelStreamingMode = Atomic` for spirit models and NPC models. Set `StreamingMinRadius` to 256 (PC), detect platform and set 192 for mobile via server `PlaceInfo` or client hint remote. Set `StreamingPauseMode = ClientPhysicsPause`.  
  **Output:** Distant content streams in/out. Spirit models load atomically (no partial spirit visible). Mobile loads smaller radius.

- [x] **T-127 · Write particle quality scaling**  
  In `CosmeticController` on init: read `UserSettings().GameSettings.SavedQualityLevel`. If ≤3: set `Enabled = false` on non-essential `ParticleEmitter` instances (auras, trails) after character spawns. Leave Cahaya orb sparkle and wing-boost particles enabled.  
  **Output:** Low-end mobile: no aura/trail particles. Gameplay-relevant particles (orbs, boost) always visible.

- [x] **T-128 · Enforce Heartbeat vs RenderStepped separation**  
  Audit all `RunService` connections: gameplay logic (Kegelapan drain check, Harmoni scan, charge refill) must use `Heartbeat`. Visual/cosmetic updates (companion bobbing, camera, Naga interpolation) must use `RenderStepped`. No gameplay reads in `RenderStepped`, no render writes in `Heartbeat`.  
  **Output:** Code review passes: no gameplay logic in `RenderStepped`. No `Heartbeat` doing CFrame writes.

---

## Phase 23 — Error Handling & DataStore Reliability

- [x] **T-129 · Wrap all DataStore calls in `retryAsync`**  
  Audit every `GetAsync`, `SetAsync`, `UpdateAsync`, `IncrementAsync` call. All must go through `retryAsync(fn, 5, 2)`. No bare DataStore calls anywhere.  
  **Output:** DataStore failures auto-retry 5 times. Permanent failure logs with `warn()`. No unhandled errors crash the server.

- [x] **T-130 · Implement blank-state fallback**  
  In `DataService.load(player)`: if all 5 retries fail, set `dataLoadFailed = true` on the session data object. In `DataService.cleanup(player)`: if `dataLoadFailed == true`, skip save (do not overwrite). Show `UI_TOAST_DATA_LOAD_ERROR` toast on client (fire a `DataService_LoadError_S2C` remote).  
  **Output:** Player can still join and play with default state. Their real data is not overwritten on exit.

- [x] **T-131 · Wrap all `FireClient` in `pcall`**  
  Audit every `RemoteEvent:FireClient` and `RemoteEvent:FireAllClients` call in server code. Wrap each in `pcall`. Log any error with `warn("[RemoteName] FireClient error: ", err)`.  
  **Output:** A disconnecting client does not crash a server `FireClient` loop. Server continues running for other players.

- [x] **T-132 · Wrap `ProcessReceipt` in `pcall`**  
  The `MarketplaceService.ProcessReceipt` callback body must be fully wrapped in `pcall`. Any error: log with `warn("[ProcessReceipt] Error for purchaseId:", receiptInfo.PurchaseId, err)`, return `NotProcessedYet`.  
  **Output:** Failed receipts do not crash the server and are retried by Roblox automatically.

---

## Phase 24 — Testing

- [x] **T-133 · Set up TestEZ runner**  
  Configure `testez.toml` to find all `*.spec.luau` files under `src/`. Add a test bootstrap script in `ServerScriptService` that runs tests in Studio only (`RunService:IsStudio()`). Print results to output.  
  **Output:** Running the game in Studio auto-executes all spec files. Pass/fail count reported in output.

- [x] **T-134 · Write `CahayaService` unit tests**  
  `src/server/Services/__tests__/CahayaService.spec.luau`. Test cases:
  - Daily cap: 150 orbs accepted, 151st rejected
  - Extinguish trigger at Cahaya = 0
  - Revive: deducts from rescuer, restores target to 10
  - Gift: daily limit enforced after 3 gifts
  - Gift: giver gets +0.5 Cahaya Hati  
  **Output:** All 5 test cases pass. Edge cases (exact cap, exact 0) covered.

- [x] **T-135 · Write `WingService` unit tests**  
  Test cases:
  - Upgrade succeeds with exact Cahaya Hati cost
  - Upgrade fails if Cahaya Hati below cost
  - Upgrade blocked at level 10
  - Carry unlocked at level 4
  - Sky's Peak access unlocked at level 5
  - Awan XP awarded correctly per level  
  **Output:** All 6 test cases pass.

- [x] **T-136 · Write `DailyTaskService` unit tests**  
  Test cases:
  - Seeded generation: same userId + date = same task set on multiple calls
  - Different userIds produce different task sets
  - Progress increment: correct task advances, others unchanged
  - Milestone tier 3 claim after 3 completed tasks succeeds
  - Milestone tier 3 claim after only 2 tasks fails
  - Streak increments on consecutive days
  - Streak resets after 2-day gap with no grace days
  - Grace day consumed for 2-day gap when available  
  **Output:** All 8 test cases pass.

- [x] **T-137 · Write `IkatanService` unit tests**  
  Test cases:
  - Offer expires after 30 seconds (mock `os.time`)
  - Accept rejected for expired offer
  - Bidirectional: both players' lists updated on form
  - Max 30 Ikatan: 31st offer rejected
  - Duplicate bond: re-offering already bonded player rejected  
  **Output:** All 5 test cases pass.

- [x] **T-138 · Write `MonetizationService` unit tests**  
  Test cases:
  - Idempotent receipt: second call with same `purchaseId` returns `Granted` without re-granting
  - Starter pack: second claim blocked by `starterPackClaimed` flag
  - Unknown product ID: handler returns `NotProcessedYet`
  - Pending grant applied on next login  
  **Output:** All 4 test cases pass.

- [x] **T-139 · Write `Format.luau` unit tests**  
  Test cases:
  - `Format.number(1500)` → `"1,500"` for en, `"1.500"` for id, `"١٬٥٠٠"` for ar
  - `Format.countdown(5400)` → `"1h 30m"` for en, `"1j 30m"` for id
  - `Format.countdown(45)` → `"45s"` for en
  - `Format.date(timestamp)` returns non-empty string for all 5 locales  
  **Output:** All locale-specific format cases pass.

- [x] **T-140 · Write integration test: Daily Task full cycle**  
  Simulate: player joins → tasks generated → progress events fire → all 5 tasks complete → claim all 5 milestone tiers → verify DataStore state: `completedIndices.length == 5`, `milestoneRewardsClaimed.length == 5`, `cahayaHati` increased, Daily Chest granted.  
  **Output:** Full integration test passes in Studio.

- [x] **T-141 · Write integration test: Ikatan cross-server teleport**  
  Simulate two mock players, form Ikatan, Player A requests teleport to Player B. Verify: cooldown set, `TeleportService:TeleportToPlaceInstance` called with correct place and server, wing-level gate checked.  
  **Output:** Teleport fires with correct arguments. Gate blocks under-leveled player.

- [x] **T-142 · Write integration test: Sky's Peak cycle**  
  Simulate: player enters Puncak Langit → ascends → summit trigger → sacrifice confirm → verify: `cahaya == 0`, `skysPeakCycles += 1`, `cahayaHati += 3`, wing badge cosmetic granted, teleport back fires.  
  **Output:** All post-cycle state correct after full run.

---

## Progress Summary

| Phase | Tasks | Done |
|---|---|---|
| Phase 0 — Foundation | T-001 → T-013, T-004b, T-004c | 14 / 15 |
| Phase 1 — Data Layer | T-014 → T-018 | 5 / 5 |
| Phase 2 — Flight | T-019 → T-025 | 7 / 7 |
| Phase 3 — Cahaya | T-026 → T-031 | 6 / 6 |
| Phase 4 — Wings | T-032 → T-035 | 4 / 4 |
| Phase 5 — Kegelapan | T-036 → T-040 | 5 / 5 |
| Phase 6 — Naga Gelap AI | T-041 → T-045 | 5 / 5 |
| Phase 7 — Ikatan | T-046 → T-050 | 5 / 5 |
| Phase 8 — Spirits | T-051 → T-057 | 7 / 7 |
| Phase 9 — Daily Tasks | T-058 → T-063 | 6 / 6 |
| Phase 10 — Seasons | T-064 → T-069 | 6 / 6 |
| Phase 11 — Instruments | T-070 → T-074 | 5 / 5 |
| Phase 12 — Emotes | T-075 → T-079 | 5 / 5 |
| Phase 13 — Cosmetics | T-080 → T-085 | 6 / 6 |
| Phase 14 — Sky's Peak | T-086 → T-089 | 4 / 4 |
| Phase 15 — UI Layer | T-090 → T-101 | 12 / 12 |
| Phase 16 — Input | T-102 → T-104 | 3 / 3 |
| Phase 17 — Audio | T-105 → T-106 | 2 / 2 |
| Phase 18 — Localization | T-107 → T-112 | 6 / 6 |
| Phase 19 — Monetization | T-113 → T-118 | 6 / 6 |
| Phase 20 — Multi-Place | T-119 → T-121 | 3 / 3 |
| Phase 21 — Security | T-122 → T-125 | 4 / 4 |
| Phase 22 — Performance | T-126 → T-128 | 3 / 3 |
| Phase 23 — Error Handling | T-129 → T-132 | 4 / 4 |
| Phase 24 — Testing | T-133 → T-142 | 10 / 10 |
| **TOTAL** | | **143 / 144** |
