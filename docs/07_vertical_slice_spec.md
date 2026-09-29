# ENTITY_000 — 07 · Vertical Slice Specification

Phase 0 documentation. This bible is the acceptance contract for the 9-act vertical slice: beat-by-beat act structure, the Consistency budget ledger, enemy and boss stat sheets, acceptance criteria, and the content inventory. Everything numeric here is locked and matches the Systems Bible.

## 1. Scope

The slice delivers the golden path from awakening to the ending question: 9 acts, 15–30 minutes for a first-time player, with optional manipulation extending skilled or exhaustive runs. All five mechanic pillars must be functional and demonstrable in a single run: OBSERVE, property modification, Consistency (HUNTED model), belief, and memory fragments.

## 2. Acts, Beat by Beat

| Act | Room | Beats | Systems taught |
|---|---|---|---|
| 1 | The Vessel Chamber | Awakening in the iron womb; the system prints OBJECTIVE: RESTORE THE WORLD; climb toward the single light; exit up the shaft | Movement; no combat; no OBSERVE yet — sight is not issued |
| 2 | The First Door | A dead TERMINAL_019 installs OBSERVE; the DOOR_029 tollgate blocks passage; its plaque states it has opened for no one; the record says 14,207 | OBSERVE; first property modification: locked=false, −6; the first ANCHOR; S1 begins |
| 3 | The City of Ash | Procession street with faceless statues; first dialogue with MEASURER OREN stamping the fading; the first HOLLOW patrols | Dialogue; telegraphed combat; the plaque-vs-readout contradiction is planted |
| 4 | The Contradiction | Null Children drift through walls; DOOR_114 requires reconciling plaque and readout (fix, −5); census stones count Chamber 114 twice; an optional toll gate (break the machine, −8, or roll beneath it) | Null Children; contradiction as mechanic; optional spending begins |
| 5 | The Chapel of the Pale Saint | Believers chant a ward into existence; the Pale Saint relic; the candle rail; the ward admits the relic bearer or one who has joined the ritual — or collapses when the chant stops (ABANDON, −8) | Belief mechanics; three real solutions; carrying belief |
| 6 | The Watching | The Archive: 817 failed records; the Penitent appears between stacks; the discrepancy ledger (fix, −5); a record station where you may read yourself; a hidden platform for stage 6 players | Fragments; the Penitent; reading your own record; hidden content gating |
| 7 | The Engine Sanctum | An industrial cathedral of cable-tracery and heat; THE HEART OF THE DESIGN works; three rotors must be aligned in the sequence hidden in their OBSERVE memory; CENSOR pressure applies to stage 4+ players | The alignment puzzle via OBSERVE; escalation; environment-as-boss |
| 8 | The Reliquary | THE BOUND MARTYR fight, three phases; the belief shield held by two censer bearers (kill them or rewrite the censer's purpose to ABANDON, −8); death sequence: chains snap, it thanks you, it collapses to ash, the inscription is revealed | All systems converge on one entity's record |
| 9 | Aftermath | The monument persists; the count is revealed (817 predecessors failed; you are ENTITY_000_818); the restored world may not include you; the game prints the question and stops | The ending; no new mechanics |

Pacing targets: Acts 1–3 about 8 minutes, Acts 4–6 about 12, Acts 7–9 about 8; a rushed golden path completes in about 15, a first exploratory run in 25–30.

## 3. Consistency Budget Ledger

Costs are locked (door unlock 6; toll machine break 8; Null Child termination 4; contradiction fix 5; hidden reveal 0 at stage 6). The ledger is the cumulative floor if the player manipulates everything available:

| Act | Manipulation | Cost | Cumulative spent | Consistency after | Stage |
|---|---|---|---|---|---|
| 3 | DOOR_029 locked=false (golden path) | 6 | 6 | 94 | S1 |
| 4 | Contradiction door fix (golden path) | 5 | 11 | 89 | S1 |
| 4 | Null Child terminations, Undercity clusters (x8) | 32 | 43 | 57 | S3 |
| 4 | Toll machine break, Undercity checkpoint | 8 | 51 | 49 | S4 |
| 5 | Toll machine break, Chantry collection gate | 8 | 59 | 41 | S4 |
| 5 | Side-chapel door unlock, Chantry | 6 | 65 | 35 | S5 |
| 6 | Archive stacks door unlock | 6 | 71 | 29 | S5 |
| 6 | Archive record contradiction fix | 5 | 76 | 24 | S5 |
| 6 | Archive annex door unlock | 6 | 82 | 18 | S6 |
| 6 | Hidden platform reveal (passive) | 0 | 82 | 18 | S6 |
| 7 | Maintenance gate unlock | 6 | 88 | 12 | S6 |
| 7 | Null Child terminations, approach drift (x2) | 8 | 96 | 4 | S6 |

Stages are evaluated after every individual spend, so sequential terminations pass through every intermediate stage and its staged consequences. Player archetypes against the ledger:

| Player | Behavior | At boss (start of Act 8) |
|---|---|---|
| Minimal | Golden path manipulations only (11 spent) | 89, S1 |
| Typical | Golden path plus a few optional edits (30–40 spent) | 60–70, S3 |
| Heavy | Most optional edits (60–70 spent) | 30s, S5, actively hunted |
| Exhaustive | Everything available (96 spent) | 4, S6; hidden platform seen in Act 6 |

Boss Phase 2's FERVOR drain aura (1 Consistency per second within radius) applies after this table and can push any archetype one stage lower during the fight; it is the only combat-adjacent Consistency loss in the game, justified diegetically as the Martyr's own reality manipulation.

## 4. Enemy Stat Sheets

| Enemy | HP | Damage | Speeds | Special |
|---|---|---|---|---|
| THE HOLLOW | 60 | lunge 12 | patrol 90, stalk 150, lunge 340 px/s | 0.55 s telegraph; blink teleport at low Consistency |
| NULL CHILDREN | 40 | touch 8 | drift; no collision | Invulnerable until OBSERVE state=TERMINATED (4); reacts to Consistency |
| THE BELIEVERS | 80 | 10 | group march | 3+ chanting: +25% damage each; purpose=ABANDON ends ritual |
| THE CENSOR | unkillable | touch 30 | 120 px/s at S4, 200 px/s at S5 | Spawns at stage 4; cannot be harmed; corrects |

## 5. Boss Stat Sheet: THE BOUND MARTYR

ENTITY_000_001. 900 HP. Arena: the Reliquary. Phase transitions at 600 and 300 HP, routed through `property_modified` on the boss entity.

| Phase | HP range | Attacks | Arena state | OBSERVE data |
|---|---|---|---|---|
| 1 | 900–600 | Chained censer swings, 18 damage | Belief shield held by 2 censer-bearer Believers; kill them or modify the censer purpose to ABANDON (8) | purpose: SERVE THE DESIGN |
| 2 | 600–300 | Dash attacks, 24 damage | FERVOR: arena shrinks as a wall of faith; consistency drain aura, 1/s within radius | purpose: SERVE THE DESIGN |
| 3 | 300–0 | Desperate wide swings; ground slam, 30 damage | Chains snap; full arena | purpose rewrites to BE REMEMBERED |

Death sequence (locked): chains snap, the Martyr thanks you, it collapses to ash, and the inscription is revealed: ENTITY_000_001 — FAILED — REPURPOSED. The monument persists into Act 9.

## 6. Acceptance Criteria

Done means all of the following pass:

1. **Playable end to end:** a first-time player finishes Acts 1–9 in 15–30 minutes on the golden path; no soft-locks anywhere, including the Archive Loft after optional edits.
2. **Every UI value is real:** HP, Consistency, stage, damage numbers, OBSERVE readouts, and MEMORY index render live state; nothing on screen is decorative.
3. **Golden path verified by script:** walk, dialogue, first OBSERVE, DOOR_029 locked=false (Consistency 94), door opens, room transition, contradiction fix, boss kill, death sequence, ending question — all under simulated input.
4. **All nine rooms boot standalone** with zero parse or runtime errors on editor import.
5. **The five pillars are demonstrable in one run:** OBSERVE, modification with costs, staged Consistency consequences, belief (ward and shield), and at least one fragment.
6. **Boss integrity:** three phases with correct thresholds and damage values; shield drops by either method; the purpose field visibly evolves in phase 3.
7. **Save/load round trip** at an ANCHOR restores room, position, HP, Consistency, flags, fragments, and property overrides exactly.
8. **Audio correctness:** every played file resolves to a path listed in `audio/MANIFEST.md`; consistency-driven lowpass and pitch degradation audibly track stages.
9. **Art law:** screenshots of all nine acts pass review against the Art Bible; system cyan appears only in system elements.
10. **Performance:** 60 fps at 1280 x 720 on integrated graphics through the heaviest room (Act 7).

## 7. Content Inventory

| Category | Count | Notes |
|---|---|---|
| Rooms | 9 | Data-driven; one per act |
| Entity definitions | 40+ | `data/entities.json`; schema per Systems Bible |
| Enemy types | 4 | Hollow, Null Children, Believers, Censor |
| Boss | 1 | The Bound Martyr, 3 phases, scripted death |
| EventBus signals | 21 | Locked spine, payloads per Systems Bible |
| Audio files | 48 | 10 music, 5 ambient, 33 SFX; manifest authoritative |
| Backdrops | 8 | Painterly, graded in-engine |
| Post shader | 1 | Grain, vignette, tearing, observe grade |
| Character rigs | 6 | Player, Hollow, Null Child, Believer, Censor, Martyr |
| Save slots | 1 | ANCHOR-only writes |
| Fragments | 8–12 | MEMORY index; zero required on golden path |
| Deliberate contradictions | 4 | Two fixable, two permanent |
| Documentation | 8 | Seven bibles plus this compiled PDF |

Out of scope: a full memory system, multiple endings, difficulty modes, localization, and resolution of any withheld lore item listed in the Narrative & Theology Bible.
