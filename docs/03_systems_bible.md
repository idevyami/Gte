# ENTITY_000 — 03 · Systems Bible

Phase 0 documentation. This bible is the systems contract: the full OBSERVE specification, the entity schema with examples, the property modification flow, the complete Consistency model, belief and memory mechanics, the save schema, combat constants, and the exact 21-signal EventBus spine. All numbers here are locked.

## 1. OBSERVE Mode

OBSERVE is the game's signature verb: a toggle that dilates time and opens the world's data layer.

**Behavior.** Toggling OBSERVE (dedicated key) slows the world (time dilation; the factor is an implementation tuning value, not a locked constant) and overlays the scene with world-space brackets on observable entities. Cycling targets selects one entity; a data panel renders its record. Closing OBSERVE restores time. OBSERVE never pauses: reading under pressure is intended play.

**Readout fields.** The panel renders, in order: `ID`, `TYPE`, `STATE`, `PROPERTIES` (each row: name, value, type; plus `MODIFIABLE` and `COST` when applicable), `MEMORY`, `BELIEF`, `PURPOSE`. Property rows gated by `hidden_until` display as `SEALED` until their condition is satisfied, then resolve into real values — a sealed row becoming legible is itself a narrative event (the Archive records unseal at low Consistency).

**Visibility rules.** System styling (cold cyan) is reserved for OBSERVE readouts and system messages; no other UI may use it. OBSERVE brackets render in world space so their position teaches entity extents (the Null Child's brackets are slightly wrong — they drift off the sprite, foreshadowing its lack of classification).

## 2. Entity Schema

All entities are data-driven from `data/entities.json`. The schema is fixed:

```
id            unique string identifier
type          entity archetype (door, hollow, null_child, believer, censor,
              boss, npc, anchor, prop, toll_machine, ...)
state         current lifecycle state
properties[]  name, value, type, modifiable, cost, hidden_until
memory        one-line record of what the entity remembers
belief        0-100; strength of collective belief invested in it
purpose       its registered purpose; the field the world enforces
flags[]       gameplay flags (toll_gate, censored, ritual, ...)
```

**Example 1 — a door (Act 3, the first modification):**

```json
{
  "id": "DOOR_029",
  "type": "door",
  "state": "LOCKED",
  "properties": [
    {"name": "locked", "value": true, "type": "bool",
     "modifiable": true, "cost": 6, "hidden_until": null},
    {"name": "material", "value": "iron", "type": "string",
     "modifiable": false, "cost": 0, "hidden_until": null},
    {"name": "openings", "value": 41, "type": "int",
     "modifiable": false, "cost": 0, "hidden_until": "observe_active"}
  ],
  "memory": "Opened for the toll collector. Opened for the Penitent. Not for you.",
  "belief": 0,
  "purpose": "CONTROL PASSAGE",
  "flags": ["toll_gate"]
}
```

**Example 2 — a Null Child (modification as the only weapon):**

```json
{
  "id": "NULL_CHILD_014",
  "type": "null_child",
  "state": "UNCLASSIFIED",
  "properties": [
    {"name": "state", "value": "UNCLASSIFIED", "type": "enum",
     "modifiable": true, "cost": 4, "hidden_until": "observe_active"},
    {"name": "collision", "value": false, "type": "bool",
     "modifiable": false, "cost": 0, "hidden_until": null}
  ],
  "memory": "A name was being assigned when the process stopped.",
  "belief": 0,
  "purpose": "PENDING",
  "flags": ["drifts_walls", "reacts_to_consistency"]
}
```

## 3. Property Modification Flow

1. OBSERVE the target and select a property row where `modifiable` is true.
2. The panel previews the change and its `cost` in Consistency.
3. Confirm. Gates checked: `modifiable`, `cost` affordable, `hidden_until` satisfied.
4. `consistency_spent` fires; Consistency decreases by `cost`.
5. `property_modified` fires with old and new values.
6. The world responds to the new value: `locked=false` opens the door; `state=TERMINATED` makes a Null Child dispersible; `purpose=ABANDON` ends a Believer ritual.
7. The override is recorded in `property_overrides` and persists through save/load.

Boss phases route through `property_modified` on the boss entity — the fight's phase transitions are, diegetically, edits to ENTITY_000_001's record. Purpose rewrites on ritual objects (the Martyr's censer) use the ritual-object cost class: 8 Consistency.

## 4. Consistency (HUNTED Model)

Consistency starts at 100 and is spent ONLY by reality manipulation — never by combat, damage, or death. It is the player's standing with the world's record of itself.

**Stages:**

| Stage | Range | World consequence |
|---|---|---|
| S1 | 86–100 | Subtle abnormalities: distant sounds, brief flickers |
| S2 | 71–85 | Environmental inconsistencies: decor displaced or duplicated, wrong shadows |
| S3 | 56–70 | NPC awareness: dialogue changes; they notice you noticing |
| S4 | 41–55 | THE CENSOR spawns and hunts; enemy behavior changes |
| S5 | 21–40 | Reality actively hunts: corrections spawn near the player, geometry tears |
| S6 | 0–20 | Hidden structures become accessible |

**Locked costs:**

| Manipulation | Cost |
|---|---|
| Door unlock | 6 |
| Toll machine break | 8 |
| Null Child termination | 4 |
| Contradiction fix | 5 |
| Hidden reveal | 0 (passive at S6) |

**Consequence design law.** Every staged effect must read as a broken rule, never random noise: a shadow facing the wrong way, a census stone counting a room twice, an NPC mid-sentence noticing you. Stage transitions are announced by a system message in cold cyan — the world filing its objection. Designed budget: a typical player reaches the boss at 60–70; heavy manipulators reach the 30s and unlock S5/S6 hidden content.

## 5. Belief Mechanics

Belief is the counterforce to Consistency: collective belief makes things real regardless of records.

- **THE PALE SAINT** (Act 5) is a relic that exists purely because enough people believed; its `belief` field is the highest in the slice. Carrying it lets the player pass the Chantry's ward barrier, which is held by chant, not geometry.
- **Ritual wards** are barriers whose `belief` is supplied by chanting Believers. Dispersing or ABANDON-ing the chanters drains the ward. Walls of faith cannot be attacked; they must be disbelieved or walked around.
- **The censer shield** (Act 8) is held by 2 censer-bearer Believers; killing them or modifying the censer's purpose to ABANDON drops it.
- **Believers empower each other:** 3+ chanting grant each +25% damage each. `belief_changed` fires as chant stacks change.

Belief and Consistency are the game's two metaphysics: the record's truth and the crowd's truth. The Design honors both, in that order — until it does not.

## 6. Memory Fragments

Memory is established through fragments, not through a full memory system (out of scope for the slice). A fragment is earned from: environmental clues (the plaque, the census stone), entity data (OBSERVE memory fields), one meaningful interaction (the Measurer who remembers Vellum Street), and one contradiction (the records against the mural). Collected fragments populate the MEMORY index in the pause menu. Fragment count is a completion vector, never a gate: the golden path requires zero fragments.

## 7. Save Schema

Saving happens only at ANCHOR shrines (Acts 2, 5, and 8). Each anchor's first communion restores +12 Consistency — but THE DESIGN does not reassure the deeply inconsistent: below 60, restoration is withheld and the anchor only records. One slot, written to `user://save.json`:

```json
{
  "room": "act_03_measured_way",
  "position": {"x": 412, "y": 288},
  "hp": 84,
  "consistency": 68,
  "flags": {"met_measurer": true, "pale_saint_carried": false},
  "fragments": ["frag_plaque_029", "frag_vellum_street"],
  "property_overrides": {"DOOR_029": {"locked": false}}
}
```

`property_overrides` reapplies all modifications on load: the world remembers what you changed. Consistency and its stage are reconstructed from the saved value; the CENSOR's hunt state resumes if stage 4+.

## 8. Combat Constants (Locked)

| Constant | Value |
|---|---|
| Move speed | 260 px/s |
| Jump velocity | 420 |
| Max HP | 100 |
| Attack chain damage | 22 / 22 / 30 |
| Roll speed / duration / cooldown | 380 px/s / 0.35 s / 0.6 s |
| Coyote time / jump buffer | 0.12 s / 0.15 s |
| Hollow lunge | 340 px/s, 0.55 s windup, 12 damage |
| Believer empowerment | +25% damage per chanter at 3+ |
| Censor speed | 120 px/s (S4) to 200 px/s (S5); touch 30 |
| Martyr totals | 900 HP; 18 / 24 / 30 damage by phase |

## 9. EventBus: The 21-Signal Spine (Exact)

All cross-system communication routes through the EventBus autoload. No new signals in Phase 0; no direct coupling between gameplay systems.

| # | Signal | Payload |
|---|---|---|
| 1 | `player_health_changed` | `hp: int, max_hp: int, source: String` |
| 2 | `player_died` | `room: String, position: Vector2` |
| 3 | `player_respawned` | `room: String, position: Vector2, from_anchor: bool` |
| 4 | `consistency_changed` | `consistency: int, previous: int` |
| 5 | `consistency_stage_changed` | `stage: int, stage_name: String` |
| 6 | `consistency_spent` | `amount: int, reason: String, consistency: int` |
| 7 | `correction_spawned` | `room: String, position: Vector2, target: String` |
| 8 | `entity_registered` | `entity_id: String, type: String` |
| 9 | `entity_unregistered` | `entity_id: String` |
| 10 | `observe_toggled` | `active: bool` |
| 11 | `observe_target_changed` | `entity_id: String (empty when cleared)` |
| 12 | `property_modified` | `entity_id: String, property: String, old_value, new_value, cost: int` |
| 13 | `room_entered` | `room: String, from: String` |
| 14 | `room_exited` | `room: String, to: String` |
| 15 | `dialogue_started` | `dialogue_id: String, speaker: String` |
| 16 | `dialogue_finished` | `dialogue_id: String` |
| 17 | `flag_set` | `flag: String, value: Variant` |
| 18 | `fragment_found` | `fragment_id: String, index: int` |
| 19 | `belief_changed` | `entity_id: String, belief: int, source: String` |
| 20 | `anchor_used` | `anchor_id: String, room: String` |
| 21 | `boss_defeated` | `boss_id: String, final_phase: int` |

The spine is frozen: no additions, no removals, no renames in Phase 0. Boss phase transitions route through `property_modified` on the boss entity, so no dedicated boss-phase signal exists by design.
