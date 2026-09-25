# ENTITY_000 — 06 · Technical Architecture

Phase 0 documentation. This bible is the engineering contract: platform constraints, the five autoloads and their responsibilities, the EntityData pipeline, room data format, save schema, the signal spine, directory layout, and performance budgets.

## 1. Platform

| Item | Value |
|---|---|
| Engine | Godot 4.4+ |
| Language | GDScript |
| Renderer | `gl_compatibility` |
| Resolution | 1280 x 720, fixed |
| Scene strategy | Code-first scene construction; a single `main.tscn` |
| Data strategy | Data-driven entities (`data/entities.json`); rooms as data |
| Target | 60 fps on integrated graphics at 1280 x 720 |

Code-first means the room graph, entities, UI, and effects are constructed in GDScript at runtime rather than authored as many scene files. Authoring stays in two places: JSON data and the single entry scene. This keeps the 9-act slice auditable — a room is a record, not a file hierarchy.

## 2. Autoloads (5, Locked)

| Autoload | Responsibilities |
|---|---|
| `EventBus` | Owns the 21-signal spine; the only channel for cross-system communication |
| `GameState` | Consistency value and HUNTED stage machine; corrections; flags; save/load; input map |
| `EntityDB` | Loads `data/entities.json`; templates; instantiates and holds the live entity registry |
| `AudioManager` | Music states, ambient layers, SFX pool, chant channel; consistency-driven bus lowpass and pitch degradation |
| `FX` | Screen shake, hitstop, and the post-process CanvasLayer (grain, vignette, tearing, observe grade) |

No gameplay system may reach into another system directly; all coupling routes through `EventBus` signals. `GameState` is the single authority on Consistency — nothing else may decrement it — and the only writer of `user://save.json`.

Autoload order is fixed and load-bearing: `EventBus` first (it must exist before anything emits), then `EntityDB` (data before world), then `GameState`, `AudioManager`, and `FX`. Ownership is equally strict: the bus routes but never decides; the database stores but never simulates; game state arbitrates but never draws; audio and FX present but never mutate gameplay values. Any feature that cannot be located inside exactly one of these five homes does not belong in the slice.

## 3. EntityData Flow

The pipeline from data to world response is fixed and one-directional:

```
data/entities.json
        |
        v
   EntityDB (load + templates)
        |
        v
   instantiate on room build --> entity_registered
        |
        v
   live registry (room-local, typed EntityData)
        |
        v
   OBSERVE panel (readout; target cycling)
        |
        v
   modification (gates: modifiable, cost, hidden_until)
        |
        v
   consistency_spent -> property_modified
        |
        v
   world response (door opens; state=TERMINATED; purpose=ABANDON)
        |
        v
   property_overrides recorded -> save/load reapplies
```

`EntityData` is a typed runtime record: `id`, `type`, `state`, `properties` (each with `name`, `value`, `type`, `modifiable`, `cost`, `hidden_until`), `memory`, `belief`, `purpose`, `flags`. `hidden_until` conditions are evaluated statically against GameState (for example, a records shelf that unseals at Consistency stage 3+). Boss phase transitions are `property_modified` events on the boss entity — the Reliquary fight is, mechanically, the player watching ENTITY_000_001's record being rewritten.

## 4. Room Data Format

Rooms are data. A room record declares geometry, contents, and transitions:

```json
{
  "id": "act_03_measured_way",
  "display": "THE MEASURED WAY",
  "bounds": {"w": 3840, "h": 720},
  "floors":   [{"x": 0, "y": 640, "w": 3840}],
  "platforms":[{"x": 900, "y": 480, "w": 160}],
  "walls":    [{"x": 0, "y": 0, "w": 32, "h": 720}],
  "spawns":   {"player": {"x": 120, "y": 600}},
  "entities": ["DOOR_029", "TOLL_003", "MEASURER_01", "HOLLOW_02"],
  "anchors":  [{"id": "ANCHOR_A3", "x": 1840, "y": 640}],
  "triggers": [{"id": "trg_first_hollow", "x": 700, "w": 80, "once": true}],
  "exits":    [{"x": 3808, "to": "act_04_undercity", "spawn": "left"}],
  "ambient":  "amb_undercity",
  "music":    "mus_measured",
  "backdrop": "bd_measured_way"
}
```

The room builder constructs collision, spawns entities from EntityDB templates, wires triggers and exits, and requests audio from `AudioManager`. Transitions emit `room_exited` then `room_entered`; the registry is rebuilt per room so OBSERVE cycling only ever sees current-room entities.

## 5. Save Schema

Single slot, written at ANCHOR use only:

```json
{
  "room": "act_05_chantry",
  "position": {"x": 640, "y": 512},
  "hp": 71,
  "consistency": 49,
  "flags": {"ward_passed": true},
  "fragments": ["frag_plaque_029"],
  "property_overrides": {"DOOR_029": {"locked": false}}
}
```

Load path: read JSON, rebuild room, re-apply `property_overrides` through EntityDB, recompute Consistency stage, restore fragments and flags, emit `player_respawned`. Death without an ANCHOR restores the last save; death is never a Consistency event.

## 6. Signal Spine (Reference)

The exact 21-signal spine with payloads is locked in the Systems Bible (03, section 9): `player_health_changed`, `player_died`, `player_respawned`, `consistency_changed`, `consistency_stage_changed`, `consistency_spent`, `correction_spawned`, `entity_registered`, `entity_unregistered`, `observe_toggled`, `observe_target_changed`, `property_modified`, `room_entered`, `room_exited`, `dialogue_started`, `dialogue_finished`, `flag_set`, `fragment_found`, `belief_changed`, `anchor_used`, `boss_defeated`. Architecture rules: no signal additions in Phase 0; every payload is a plain dictionary; `EventBus` performs no logic — it routes.

## 7. Directory Layout

```
entity000/
  project.godot
  main.tscn
  data/
    entities.json          entity definitions (schema in 03)
    rooms.json             9 act rooms as data
  scripts/
    autoloads/             event_bus.gd, game_state.gd, entity_db.gd,
                           audio_manager.gd, fx.gd
    player/                movement, combat chain, roll/crawl, observe
    entities/              hollow, null_child, believer, censor, boss
    world/                 room builder, masonry + decor renderers, parallax
    ui/                    HUD, observe panel, dialogue, menus
    post/                  post.gdshader
  art/                     painterly backdrops (graded in-engine)
  audio/
    music/ ambient/ sfx/   procedural WAV library
    MANIFEST.md            authoritative file list, durations, usage
  docs/                    the seven bibles + Phase 0 PDF
```

The audio library is 48 procedural WAVs (10 music, 5 ambient, 33 SFX) authored to the audio identity: ancient, sacred, mechanical, lonely, damaged. `audio/MANIFEST.md` is the authoritative per-file list; code must reference paths exactly as the manifest records them.

## 8. Audio Bus Architecture

`AudioManager` exposes music states (title, exploration per act stratum, combat, boss phases), ambient layers (wind, machinery, chant beds), a pooled SFX voice allocator, and a dedicated chant channel for Believer groups. Consistency drives degradation across the master bus: as stages fall, a lowpass filter closes and playback pitch drifts downward, so the mix itself decays with the world's record of the player. Bus graph: Master, Music, Ambient, SFX, Chant.

## 9. Corrections and Runtime Validation

The correction system is owned by GameState: at stage 4+ it may spawn correction events near the player (`correction_spawned`), each a small localized reality edit — a duplicated decor piece resolving, a seam tearing in geometry — rendered by FX as a tear band. Corrections are never lethal by themselves; their job is to keep the HUNTED model legible: the world is visibly spending effort on you.

Validation strategy for development: headless Godot runs boot each room from the room data and assert that the registry builds, entities resolve against EntityDB templates, and every exit references an existing room. Scripted input simulations drive the golden path, a combat exchange, and the boss fight through phase 3. Screenshots rendered under a virtual display are reviewed against the Art Bible palette law. Any assert failure, parse error, or unresolved audio path fails the build; the slice ships only from a clean validation pass.

## 10. Performance Constraints

| Budget | Constraint |
|---|---|
| Frame | 16.6 ms; gl_compatibility; no per-frame allocations in gameplay loops |
| Post pass | One full-screen shader; uniform updates only on state change |
| Entities | 2–5 active enemies; pooled projectiles and particles |
| Audio | Preloaded WAVs; zero runtime synthesis; pooled voices with early cull |
| Rooms | Single room resident; transition tears down the previous registry |
| Draw | Batched CanvasItem polygons; backdrops are single textured layers with parallax, not tile fields |
| Save | Anchor-only writes; JSON under 16 KB |

Validation gates for the slice: zero parse errors on editor import; every room boots standalone; the golden path completes under scripted input; screenshots of all nine acts verified against the Art Bible. Acceptance criteria for the full slice live in the Vertical Slice Specification (07).
