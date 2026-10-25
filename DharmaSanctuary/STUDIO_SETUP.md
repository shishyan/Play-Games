# Dirgantara — Roblox Studio Setup Guide

Complete, step-by-step instructions for configuring Roblox Studio and the game's
workspace from scratch. Follow every step in order. Do not skip any section.

---

## Prerequisites

Before opening Studio:

1. Install **Rojo** (≥ 7.x): https://rojo.space/docs/installation/
2. Run `wally install` in the project root to populate `Packages/`.
3. Create an empty `ServerPackages/` folder in the project root if it does not exist:
   ```
   mkdir ServerPackages
   ```
4. Generate the sourcemap (required for luau-lsp):
   ```
   rojo sourcemap default.project.json --output sourcemap.json
   ```

---

## Step 1 — Create or Open the Universe

1. Open **Roblox Studio** and go to **File → Publish to Roblox As…** (or **Open from Roblox** if the universe already exists).
2. This game uses **multiple places** (one per realm). Create the universe under **Creator Dashboard → My Creations → Games → Create**. Name it `Dirgantara`.
3. The **Hub / main place** (Pulau Fajar – `ISLE_DAWN`) is the starting place. All other realm places will be added as sub-places in later steps.

---

## Step 2 — Enable Required API Services

In Studio, go to **File → Game Settings → Security** and enable:

| Service | Reason |
|---|---|
| **Enable Studio Access to API Services** | DataStore access during Studio testing |
| **Allow HTTP Requests** | Reserved for future webhooks |

The following Roblox services are used by scripts and must be available in published games:

- `DataStoreService` — player data, season config, leaderboards, purchase history
- `MemoryStoreService` — Ikatan presence (real-time partner tracking)
- `TeleportService` — cross-realm travel between the 7 place IDs
- `MarketplaceService` — Musim Pass and Musim Pass+ developer products
- `BadgeService` — wing-level cycle badges (`WING_BADGE_1` through `WING_BADGE_N`)
- `PathfindingService` — Naga Gelap NPC navigation

These require no manual Studio action beyond having the game published under your account.

---

## Step 3 — Workspace Properties

In Studio, select **Workspace** in the Explorer and set these properties in the Properties panel:

| Property | Value | Notes |
|---|---|---|
| `StreamingEnabled` | `true` | **Must be set in Studio.** Cannot be changed by script. |
| `StreamingMinRadius` | *(leave as default)* | Script sets this to `256` at runtime. |
| `StreamingPauseMode` | *(leave as default)* | Script sets this to `ClientPhysicsPause` at runtime. |
| `Gravity` | `196.2` | Default Earth gravity. Do not change. |

**Do not** set `StreamingMinRadius` or `StreamingPauseMode` in Studio; `StreamingConfig.luau` writes those on server startup.

---

## Step 4 — Rojo Sync (Scripts)

Rojo syncs the following filesystem paths into Studio automatically:

| Filesystem path | → Studio location |
|---|---|
| `src/server/` | `ServerScriptService.Server` |
| `src/client/` | `StarterPlayer.StarterPlayerScripts.Client` |
| `src/shared/` | `ReplicatedStorage.Shared` |
| `Packages/` | `ReplicatedStorage.Packages` |
| `ServerPackages/` | `ServerScriptService.ServerPackages` |
| `src/assets/` | `ReplicatedStorage.Assets` (folder structure only) |

To sync:

1. In Studio, go to **Plugins → Rojo** (install the Roblox Studio plugin from the Rojo website if absent).
2. In a terminal at the project root, run:
   ```
   rojo serve default.project.json
   ```
3. Click **Connect** in the Rojo Studio plugin.
4. Rojo will create and populate all synced instances. **Do not rename or move** any of these instances in Explorer — Rojo will overwrite them on the next sync.

After Rojo sync completes, the following folders exist under `ReplicatedStorage.Assets` as **empty Folder** instances (their contents must be added manually in the following steps):

```
ReplicatedStorage.Assets
  ├── NPCs/
  ├── Props/
  ├── Spirits/
  ├── Wings/
  ├── Cosmetics/
  │   ├── Aura/
  │   ├── Cape/
  │   ├── Emote/
  │   ├── Hair/
  │   ├── Instrument/
  │   ├── Mask/
  │   ├── Outfit/
  │   ├── Prop/
  │   ├── Trail/
  │   └── WingSkin/
  └── VFX/
```

---

## Step 5 — ReplicatedStorage: Assets (Manual)

Everything in this step must be placed manually in Studio. Rojo only creates the folder skeletons.

### 5.1 — NPCs Folder

Inside `ReplicatedStorage.Assets.NPCs`, create one Model named **`NagaGelap`**.

The `NagaGelap` model requirements:

- Must be an **R15-compatible Model** (can use the default Roblox R15 rig as a base).
- Must contain a **BasePart** named exactly `HumanoidRootPart` (this is the PrimaryPart).
- Must contain a **Humanoid** instance.
- Optional: add a **Sound** instance anywhere inside the model, named `GrowlSound`, with `Looped = true`. Set `SoundId` to the Naga growl asset once available.
- **Do not** apply a CollectionService tag manually. `NagaGelapAI.luau` applies the `NagaGelap` tag at runtime when it spawns clones.

### 5.2 — Props Folder

Inside `ReplicatedStorage.Assets.Props`, create two models:

**`CahayaOrb`** — A glowing orb that players collect for Cahaya.
- Single **Part** (sphere, ~1.5 stud diameter), `CanCollide = false`.
- Add a **BillboardGui** named `OrbBillboard` with a glowing ImageLabel (texture from `Assets.Textures.OrbGlow` once the asset ID is known).
- Add a **ParticleEmitter** for idle sparkle (template will be cloned by script, so this is optional on the template itself).
- `CahayaService.luau` applies the `CahayaOrb` CollectionService tag at runtime; do not add it here.

**`PetiCahaya`** — A chest found inside Kegelapan zones.
- Single visible **Part** or **MeshPart** representing the chest.
- `CanCollide = true`.
- Does **not** need a CollectionService tag on this template. The placed instances in each realm must be tagged `PetiCahaya` (see Step 8).

### 5.3 — Spirits Folder

Inside `ReplicatedStorage.Assets.Spirits`, create two templates:

**`SpiritBase`** — Base Model used for all spirit NPCs (ancestor spirits, season spirits, daily spirits).
- Must be a **Model** with `PrimaryPart` set to a BasePart.
- The `SpiritService.luau` script applies the `Spirit` CollectionService tag to the PrimaryPart at runtime; do not pre-tag.
- Design the visual appearance (glow, shape) to be re-skinnable per spirit type.

**`Fragment`** — A collectible fragment part.
- Single **Part** or **MeshPart**, `CanCollide = false`, small (≤ 1 stud).
- `SpiritService.luau` applies the `SpiritFragment` tag at runtime.

### 5.4 — Wings Folder

Inside `ReplicatedStorage.Assets.Wings`, create **10 Models** named exactly:

```
WingL1   WingL2   WingL3   WingL4   WingL5
WingL6   WingL7   WingL8   WingL9   WingL10
```

Each wing model:
- Attach geometry so it pairs correctly when welded to `BodyBackAttachment` on the R15 character torso.
- Levels 1–5 have progressively larger/more elaborate designs (functional visual tiers).
- Levels 6–10 are cosmetic-only reskins; they share the same stats as Level 5 (no gameplay change).
- `CosmeticController.luau` looks for a `WingModel` child on the character; `WingService.luau` places the wing model there. Design wings to work with this attachment pattern.

### 5.5 — Cosmetics Folder

Inside each subfolder of `ReplicatedStorage.Assets.Cosmetics`, add the individual cosmetic item Models. Each item's name must match the `itemId` string defined in `CosmeticDefs.luau`.

Slot attachment rules (for cosmetic model welds):

| Category folder | Attachment point on character |
|---|---|
| `Cape/` | `BodyBackAttachment` |
| `Mask/` | `FaceFrontAttachment` |
| `Hair/` | `HairAttachment` |
| `Outfit/` | `BodyFrontAttachment` |
| `WingSkin/` | Swaps mesh on the existing `WingModel` (no weld) |
| `Instrument/` | `RightHandAttachment` |
| `Trail/` | `BodyBackAttachment` |
| `Aura/` | Parented to `HumanoidRootPart` |
| `Prop/` | `RightHandAttachment` |
| `Emote/` | No wearable model; handled by `EmoteController`. Leave folder empty. |

Season 1 cosmetics that must be present before launch (referenced in `SeasonDefs.luau`):

```
Cape/SEASON_01_CAPE
Emote/SEASON_01_EMOTE
Trail/SEASON_01_TRAIL
Mask/SEASON_01_MASK
Aura/SEASON_01_AURA
Cape/SEASON_01_FINALE_CAPE    ← quest S01_Q7 reward
```

Starter cosmetics from `CosmeticDefs.luau` must also be present. Check `CosmeticDefs.luau` for all `itemId` strings marked as starter/default items.

### 5.6 — VFX Folder

Inside `ReplicatedStorage.Assets.VFX`, create **one Model or Part** for each VFX template listed below. Each instance's name must match the string exactly (these strings come from `Assets.luau → Assets.VFX`):

```
OrbCollect          OrbIdle             Extinguished        Revived
CahayaGift          BoostBurst          GlideTrail          CarryLink
IkatanForm          IkatanTeleport      KegelapanFog        DimToggle
NagaAppear          NagaCatch           SpiritFragment      SpiritFree
DailySpiritGlow     CompanionFloat      HarmoniAura         NoteFloat
AuraDefault         TrailWingDefault    SkysPeakAscend      SkysPeakSacrifice
WingBadgeUnlock     SeasonLaunch        EventFirework
```

Each VFX template is a **Model** or **Part** containing a `ParticleEmitter`, `Beam`, `Trail`, or similar effect. Scripts clone the template and position it at runtime using `Debris:AddItem` for cleanup.

---

## Step 6 — SoundService

All audio instances described here must live **directly under `SoundService`** (not inside a folder). They must exist before the server starts; `AudioController.luau` reads them by name on `game:GetService("SoundService"):FindFirstChild(name)`.

### 6.1 — Ambient Tracks (3 Sounds)

Create three **Sound** instances under `SoundService`:

| Name | `Looped` | `Volume` | `SoundId` |
|---|---|---|---|
| `AmbientSolo` | `true` | `1` | *(set to `Assets.BGM.AmbientSolo` asset ID once known)* |
| `AmbientSocial` | `true` | `0` | *(set to `Assets.BGM.AmbientSocial` asset ID once known)* |
| `AmbientKegelapan` | `true` | `0` | *(set to `Assets.BGM.AmbientKegelapan` asset ID once known)* |

`AmbientSolo` starts at `Volume = 1` because it is the default state. The others start at `0`; `AudioController.luau` cross-fades them via `Sound:TweenVolume()`.

### 6.2 — Instrument Note Templates (25 Sounds)

Create **25 Sound** instances under `SoundService`. Naming pattern:
`NoteTemplate_{InstrumentKey}_{NoteIndex}`

Where `{InstrumentKey}` is one of: `Seruling`, `Kendang`, `Siter`, `Terompet`, `Angklung`  
And `{NoteIndex}` is `1` through `5` (pentatonic scale: C D E G A).

Full list of names to create:

```
NoteTemplate_Seruling_1    NoteTemplate_Seruling_2    NoteTemplate_Seruling_3
NoteTemplate_Seruling_4    NoteTemplate_Seruling_5

NoteTemplate_Kendang_1     NoteTemplate_Kendang_2     NoteTemplate_Kendang_3
NoteTemplate_Kendang_4     NoteTemplate_Kendang_5

NoteTemplate_Siter_1       NoteTemplate_Siter_2       NoteTemplate_Siter_3
NoteTemplate_Siter_4       NoteTemplate_Siter_5

NoteTemplate_Terompet_1    NoteTemplate_Terompet_2    NoteTemplate_Terompet_3
NoteTemplate_Terompet_4    NoteTemplate_Terompet_5

NoteTemplate_Angklung_1    NoteTemplate_Angklung_2    NoteTemplate_Angklung_3
NoteTemplate_Angklung_4    NoteTemplate_Angklung_5
```

Properties for every note template:
- `RollOffMaxDistance`: `40` (matches `Constants.INSTRUMENT_RELAY_RANGE`)
- `SoundId`: Set to the corresponding entry in `Assets.Instruments` once audio assets are ready
- `Looped`: `false` (except `NoteTemplate_Terompet_*` which should be `true` to support sustain; `InstrumentController` handles stopping it)

`AudioController.luau` clones these templates to the playing player's `HumanoidRootPart` and plays them spatially.

---

## Step 7 — Workspace: SeasonalExtensions Folder

In **Workspace**, create a **Folder** named exactly `SeasonalExtensions`.

Inside it, create one subfolder per realm that has `hasSeasonalExtension = true` in `RealmDefs.luau`. Currently those are:

```
Workspace
  SeasonalExtensions (Folder)
    GRASSLAND (Folder)    ← Season 1 extension area
    VALLEY    (Folder)    ← Future season extension
```

Each realm subfolder holds the season-specific geometry, decorations, and spawn points for the active season. For Season 1 (`SEASON_01_STARFALL`), build the Grassland seasonal extension inside `Workspace.SeasonalExtensions.GRASSLAND`.

`SeasonService.luau` applies the active season's CollectionService tag to all descendants of the matching folder. No manual tagging is required here.

---

## Step 8 — Kegelapan Zones

Kegelapan zones are standard **BaseParts** placed directly in each realm's workspace. They are invisible (set `Transparency = 1`) bounding volumes that define a darkness region.

### 8.1 — Zone Parts (Tag: `KegelapanZone`)

For each Kegelapan zone in every realm:

1. Insert a **Part** (box shape is fine) that covers the full volume of the darkness area.
2. Set `Transparency = 1`, `CanCollide = false`, `Anchored = true`.
3. In Studio's **Tag Editor** (or via `CollectionService` in the Command Bar), add the tag: **`KegelapanZone`**.
4. In the Properties panel, add these **Attributes** to the Part:

   | Attribute name | Type | Value |
   |---|---|---|
   | `ZoneId` | `string` | Unique identifier, e.g. `"GRASSLAND_ZONE_01"` |
   | `DrainRate` | `number` | Cahaya lost per tick (default: `1`) |
   | `DrainInterval` | `number` | Seconds per tick (default: `3`) |

### 8.2 — Peti Cahaya Chests (Tag: `PetiCahaya`)

Chests are placed as **instances of the `PetiCahaya` model** (cloned from `ReplicatedStorage.Assets.Props.PetiCahaya`) and placed in the Workspace inside or near a Kegelapan zone.

For each placed chest:

1. Add the CollectionService tag: **`PetiCahaya`**.
2. Add these **Attributes**:

   | Attribute name | Type | Value |
   |---|---|---|
   | `ChestId` | `string` | Unique identifier, e.g. `"GRASSLAND_CHEST_01"` |
   | `ZoneId` | `string` | Must match the `ZoneId` of the enclosing `KegelapanZone` part |

Realm zone counts (from `RealmDefs.luau`; use as a guide for how many zones to build):

| Realm | `kegelapanZoneCount` |
|---|---|
| ISLE_DAWN | 0 |
| GRASSLAND | 1 |
| FOREST | 2 |
| VALLEY | 3 |
| WASTELAND | 4 |
| VAULT | 2 |
| SKYS_PEAK | 1 (entire realm is one escalating zone) |

---

## Step 9 — Sky's Peak Geometry Tags

`SkysPeakService.luau` reads the Y-positions of two tagged parts to scale the altitude-based Cahaya drain rate. These parts must be placed in the Sky's Peak place.

### 9.1 — Summit Trigger (Tag: `SkysPeakSummit`)

1. Place an **invisible Part** at the topmost point of the Sky's Peak map (the altar / sacrifice spot).
2. `Transparency = 1`, `CanCollide = false`, `Anchored = true`.
3. Tag it: **`SkysPeakSummit`**.
4. Only one part with this tag should exist. The script uses the first one it finds.
5. Players within `20 studs` of this part's centre trigger the summit event.

### 9.2 — Floor Reference (Tag: `SkysPeakFloor`)

1. Place an **invisible Part** at the ground level of the Sky's Peak map (the realm entry point).
2. `Transparency = 1`, `CanCollide = false`, `Anchored = true`.
3. Tag it: **`SkysPeakFloor`**.
4. Only one part with this tag should exist. The script uses the first one it finds.

The drain rate scales linearly between the floor Y-position (`SKYS_PEAK_DRAIN_BASE = 1`) and the summit Y-position (`SKYS_PEAK_DRAIN_MAX = 3`).

---

## Step 10 — Spirit Models (In-Realm Placement)

Spirit models are **not pre-placed** in the workspace. `SpiritService.luau` clones `SpiritBase` from `ReplicatedStorage.Assets.Spirits.SpiritBase` and positions each spirit at runtime based on its spawn definition.

However, you must define **spirit spawn locations** in each realm. Place invisible **Part** instances at the desired spawn positions and name each one using the spirit's ID (e.g., `SEASON_01_SPIRIT_BINTANG`). The SpiritService reads these to know where to spawn.

Spirit fragment locations are similarly spawned by the service — no manual in-world fragments are needed.

Tags `Spirit` and `SpiritFragment` are applied at runtime. **Do not** pre-tag anything.

---

## Step 11 — NagaGelap NPC Template (ReplicatedStorage)

Already covered in **Step 5.1**. To summarise requirements:

- Location: `ReplicatedStorage.Assets.NPCs.NagaGelap` (Model)
- Required children: `HumanoidRootPart` (BasePart, set as `PrimaryPart`), `Humanoid`
- Optional: `GrowlSound` (Sound, `Looped = true`)
- **Do not tag with `NagaGelap`** — the AI script tags clones at runtime.
- `NagaGelapAI.luau` clones this template up to `NAGA_MAX_PER_ZONE = 3` times per active zone.

---

## Step 12 — Multi-Place Setup (Realm Place IDs)

All 7 realms are separate Roblox **places** within the same universe. Once each place is created in the Creator Dashboard:

1. Open `src/shared/RealmDefs.luau`.
2. Replace every `placeId = 0` with the actual integer place ID from the Creator Dashboard.

| Realm ID | Realm name | `placeId` field |
|---|---|---|
| `ISLE_DAWN` | Pulau Fajar (Hub) | Main place — use the universe's root place ID |
| `GRASSLAND` | Padang Bisikan | *(assign after creation)* |
| `FOREST` | Hutan Gaung | *(assign after creation)* |
| `VALLEY` | Lembah Kejayaan | *(assign after creation)* |
| `WASTELAND` | Tanah Tandus | *(assign after creation)* |
| `VAULT` | Kubah Pengetahuan | *(assign after creation)* |
| `SKYS_PEAK` | Puncak Langit | *(assign after creation)* |

`TeleportService:TeleportToPlaceInstance()` is used by `IkatanService.luau` and `SkysPeakService.luau` to move players between places. Place IDs of `0` will cause teleport failures.

---

## Step 13 — Developer Products & Badges

### 13.1 — Developer Products (Musim Pass)

1. In the Creator Dashboard, create two Developer Products for the game universe:
   - **Musim Pass** — one-time season pass purchase
   - **Musim Pass+** — premium tier season pass
2. Note the integer Product ID for each.
3. Open `src/shared/SeasonDefs.luau` and replace `0` with the real IDs for Season 1:
   ```lua
   musimPassProductId     = 0,    -- replace with real Robux product ID
   musimPassPlusProductId = 0,
   ```

### 13.2 — Wing Cycle Badges

`SkysPeakService.luau` grants badges named `WING_BADGE_{cycleNumber}` (e.g., `WING_BADGE_1`, `WING_BADGE_2`, …) using `BadgeService:AwardBadge()`.

For each badge:
1. Create it in the Creator Dashboard under the game's **Badges** section.
2. Note the integer Badge ID.
3. Update the badge ID lookup in `SkysPeakService.luau` (currently uses a string key convention; check the service for the exact lookup table location and update accordingly).

---

## Step 14 — Fill Placeholder Asset IDs

All asset IDs are `0` in `src/shared/Assets.luau` until real Roblox asset IDs are uploaded. Once audio/image/animation assets are uploaded to Roblox:

1. Open `src/shared/Assets.luau`.
2. Find each `= 0` entry in the relevant section (`Assets.Icons`, `Assets.SFX`, `Assets.BGM`, `Assets.Animations`, `Assets.Instruments`, `Assets.Textures`, `Assets.Fonts`).
3. Replace `0` with the integer asset ID (not the full `rbxassetid://...` URL — scripts prepend that prefix automatically).

**Do not hardcode asset IDs anywhere other than `Assets.luau`.** All scripts import `Assets` from this file.

---

## Step 15 — Remotes (No Manual Action Required)

All `RemoteEvent` and `RemoteFunction` instances are created at runtime by `Remotes.luau` under `ReplicatedStorage.Remotes`. **Do not create any Remote instances manually in Studio.** If you see a `Remotes` folder in Explorer after running the game once, that is correct — do not delete it.

---

## Step 16 — Localization Table (No Manual Action Required)

`LocalizationService.luau` creates `ReplicatedStorage.Localization.LocalizationTable` at runtime. **Do not create it manually.** The table is populated with locale strings defined in the service file.

---

## Step 17 — Regenerate Sourcemap After Changes

Whenever you add or rename a script file, regenerate the sourcemap so `luau-lsp` can resolve cross-module types:

```
rojo sourcemap default.project.json --output sourcemap.json
```

Run this after any filesystem change that adds, removes, or renames `.luau` files.

---

## Final Verification Checklist

Before testing in Studio, confirm every item:

- [ ] `workspace.StreamingEnabled` is `true` in Studio properties
- [ ] `ReplicatedStorage.Assets.NPCs.NagaGelap` model exists with `HumanoidRootPart` and `Humanoid`
- [ ] `ReplicatedStorage.Assets.Props.CahayaOrb` and `PetiCahaya` exist
- [ ] `ReplicatedStorage.Assets.Spirits.SpiritBase` and `Fragment` exist
- [ ] `ReplicatedStorage.Assets.Wings.WingL1` through `WingL10` exist (10 models)
- [ ] `ReplicatedStorage.Assets.VFX` contains all 27 named VFX templates
- [ ] `SoundService.AmbientSolo`, `AmbientSocial`, `AmbientKegelapan` exist with correct `Looped` and `Volume` values
- [ ] All 25 `NoteTemplate_{Instrument}_{1-5}` Sound instances exist under `SoundService`
- [ ] `Workspace.SeasonalExtensions.GRASSLAND` and `VALLEY` folders exist
- [ ] Each Kegelapan zone Part is tagged `KegelapanZone` with `ZoneId`, `DrainRate`, `DrainInterval` attributes
- [ ] Each Peti Cahaya instance is tagged `PetiCahaya` with `ChestId` and `ZoneId` attributes
- [ ] Sky's Peak place has one part tagged `SkysPeakSummit` and one tagged `SkysPeakFloor`
- [ ] `RealmDefs.luau` has real `placeId` values for all 7 realms (not `0`)
- [ ] `SeasonDefs.luau` has real `musimPassProductId` and `musimPassPlusProductId` values
- [ ] `Assets.luau` has real asset IDs (not `0`) for all uploaded assets
- [ ] `sourcemap.json` is up to date (run `rojo sourcemap` after any file change)
- [ ] API Services are enabled in Game Settings → Security

---

## Quick Reference: CollectionService Tags

| Tag | Applied by | Required attributes |
|---|---|---|
| `KegelapanZone` | **Manual (Studio)** | `ZoneId`, `DrainRate`, `DrainInterval` |
| `PetiCahaya` | **Manual (Studio)** | `ChestId`, `ZoneId` |
| `SkysPeakSummit` | **Manual (Studio)** | none |
| `SkysPeakFloor` | **Manual (Studio)** | none |
| `Spirit` | Runtime — `SpiritService.luau` | none |
| `SpiritFragment` | Runtime — `SpiritService.luau` | none |
| `NagaGelap` | Runtime — `NagaGelapAI.luau` | none |
| `CahayaOrb` | Runtime — `CahayaService.luau` | none |
