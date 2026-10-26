# Samsara: Journey of Star Seeds (Roblox)

A Dharmic action-RPG for Roblox built from the *Samsara* GDD. There are **no levels**: you grow along the
four Purusharthas (Dharma, Artha, Kama, Moksha), fight with the classical Dhanurveda weapon classes,
invoke Astras by rhythm, keep the world's **Rta** in balance, and when you die you pass through the
**Bardo** and are judged by your Karma.

> **Status: vertical-slice prototype. It has not been run inside Roblox Studio yet.**
> It builds with Rojo, type-checks cleanly against the full Roblox API, and its game logic passes 488
> automated checks — but nothing here has been play-tested in the engine. Expect first-run bugs
> (see [Known risks](#known-risks)).

## Run it

1. Install [Rojo](https://rojo.space) (the repo already ships `../DharmaSanctuary/rojo.exe`, 7.7.1) and the Rojo Studio plugin.
2. `rojo serve default.project.json` in this folder, then connect from Studio's Rojo plugin (or `rojo build -o Samsara.rbxl`).
3. In **Game Settings → Security**, enable *Studio Access to API Services* if you want saves to persist.
4. Press **Play**. Pick a Dhanurveda discipline, then talk to **Acharya Satyadev** by the temple.

Tester chat commands (Studio, or the game's creator): `/yuga 1-4`, `/karma N`, `/path dharma|artha|kama|moksha N`, `/gold N`.

## Controls

| Input | Action |
|---|---|
| WASD / Space | Move / jump (Roblox default character + camera) |
| LMB | Basic attack; **hold to draw a bow**, release to loose |
| 1–3 | Weapon abilities · **4–6** Agneyastra / Varunastra / Vayuvastra |
| 7 / 8 | Best remedy / Amrita |
| Tab, click | Target · **V** pacify a weakened corrupt creature |
| Z / X / C | Strike the beats of a mantra (also tappable on screen) |
| C B L H | Character · Bags · Quests · Help |

## GDD → implementation

| GDD system | State | Where |
|---|---|---|
| Four Purusharthas, no levels; balance-gated Moksha | ✅ | `shared/Purusharthas`, `Profile` |
| Dharma → Kavacha armour, corruption resistance, celestial access | ✅ | `Purusharthas.stats`, `Karma.canEnterSvarga` |
| Artha → craft tier, gold bonus, Dana rule, Tamas decay from hoarding | ✅ | `Purusharthas.tamas`, `CombatService` (weapon wear) |
| Kama → agility, stamina, lotus footprints | ✅ | `Purusharthas.stats`, `client/Effects` |
| Dhanurveda: Mukta / Amukta / Muktāmukta / Yantra-mukta | ✅ 7 weapons, 12 abilities | `shared/Dhanurveda`, `CombatService` |
| Physical projectiles, wind + breath for bows, Khanda cuts shields | ✅ | `CombatService.launch` |
| Astra mantra QTE (Agneya / Varuna / Vayu), backfire on a missed rhythm | ✅ | `Dhanurveda.judge`, `CombatService`, `client/Mantra` |
| Vyuha: Padma lotus and Chakravyuha wheel | ✅ detection + buffs | `shared/Vyuha`, `VyuhaService` |
| Ayurvedic alchemy, Doshas from environmental enemies, remedy crafting | ✅ | `shared/Ayurveda`, alchemy panel |
| Yuga lifecycle changing gravity, danger, yields, wear, lighting | ✅ (1200 s per Yuga, configurable) | `shared/Yuga`, `WorldState`, `client/Effects` |
| Rta vs Anrita: world-level meter that tightens or eases the world | ✅ | `WorldState.addRta` / `chaosMult` |
| Samsara: Bardo, karmic evaluation, blessing / rebirth / Spiritual Debt | ✅ | `shared/Samsara`, `SamsaraService` |
| Debt pilgrimage (carry water uphill without jumping or being hit) | ✅ | `InteractService`, `Samsara.spill` |
| Mercy: pacify instead of kill (Dharma over annihilation) | ✅ | `EnemyService.pacify` |
| Community funds with server-wide blessings (step-well, school, rest house) | ✅ | `WorldState`, `DialogueService` |
| Moksha: Mandala puzzle, Vrata fast, letting go, transcendence + monument | ✅ | `InteractService`, `LokaService.transcend` |
| Quests & branching dialogue, Karma-aware NPCs and prices | ✅ 10 quests, 10 NPCs | `shared/QuestDefs`, `DialogueDefs` |
| Mount taming, irrigation / farmland, real estate, regional assemblies | ❌ not built | — |
| Dispute arbitration with philosophical texts, Kalari obstacle course | ❌ not built | — |
| Svarga content beyond the Herald and Maya; Patala | ❌ not built | — |
| Audio, bespoke art, custom animations | ❌ (Roblox default R15 animations, procedural props) | — |

## Layout

```
src/shared   pure game design + logic (no Roblox APIs except Color3/Vector3 in data) — unit-tested
src/server   services: world, enemies, combat, interaction, dialogue, Samsara, Vyuha, persistence
src/client   HUD, input, mantra rhythm UI, panels, dialogue, effects, lighting
tests/       logic.test.luau   (488 checks)
tools/       verify.ps1        (tests + analyzer + Rojo build)
```

Design rules baked into the structure: all gameplay rules are validated **server-side** (cooldowns, stamina,
range, mantra timing, dialogue choices, purchases); the client only renders and sends intents. Creature
overhead UI shows **health and power bands only** — never names.

## Verify

```powershell
powershell -ExecutionPolicy Bypass -File tools\verify.ps1
```

Runs (1) the logic tests in the standalone Luau interpreter, (2) `luau-lsp analyze` with the Roblox API
definitions and a Rojo sourcemap, (3) `rojo build`. Setup instructions for the tools are in the script header.

## Known risks

- **Never run in Studio.** Static analysis cannot catch engine behaviour: terraced terrain walkability,
  physics of knockback, NPC pathing, GUI layout on small screens, replication timing.
- **Avatar creation** uses `Players:CreateHumanoidModelFromDescription` (a web call) with a crude fallback
  rig; Roblox's stock animation IDs (`507766388`, `507777826`, `522635514`) are assumed to load.
- **World state is per server**: Yuga clock, Rta and enemy state are local; only community funds and the
  Maha-Loka monument list persist and merge across servers (`UpdateAsync`).
- **Terrain generation** is ~5k `FillBlock`/`FillBall` calls at server start (a few seconds).
- Balance numbers (damage, yields, Yuga length, quest rewards) are first guesses.
- Anti-exploit is limited to server validation + rate limits; no dedicated review has been done.
