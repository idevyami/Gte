# ENTITY_000 — Vertical Slice

A native **Godot 4.4+** 2D action / exploration / puzzle psychological mystery.

> If you were created for a purpose — do you have the right to reject it?

You are **ENTITY_000_818**. No name, no history, no memory. One objective, printed
by something older than you: **RESTORE THE WORLD**. The City of Ash runs on a single
principle — *everything must have a purpose* — and it became religion, then law,
then government, then reality. You can OBSERVE the true data of any entity, and you
can MODIFY it. The world obeys. Then it bills you: every edit is paid for in
**CONSISTENCY**, and broken reality hunts back.

## Running

1. Install [Godot 4.4](https://godotengine.org) or newer (standard build).
2. Open this folder (`project.godot`) in the editor, let it import.
3. Press **F5** (Run Project). No export templates needed.

Headless validation (optional):

```sh
godot --headless --import
godot --headless -s res://tests/smoke_test.gd
```

## Controls

| Key | Action |
|---|---|
| A / D · ← / → | Move |
| SPACE | Jump |
| SHIFT | Roll (invulnerable while rolling) |
| J · LMB | Attack (3-hit chain) |
| TAB | OBSERVE (enter / next target / exit) |
| W / S | Select property while observing |
| E | Modify selected property |
| F | Interact / advance dialogue |
| ESC | Pause |

## The slice

Nine acts, 15–30 minutes: The Vessel Chamber · The First Door · The City of Ash ·
The Contradiction · The Chapel of the Pale Saint · The Watching · The Engine
Sanctum · The Bound Martyr · Aftermath.

Systems, all real, all gameplay-affecting:

- **OBSERVE** — read any entity's true record; modify what is modifiable.
- **CONSISTENCY** — the hunted model; six escalating stages; the CENSOR at stage 4.
- **BELIEF** — collective belief is a physical force (wards, shields, saints).
- **MEMORY** — fragments can be found, corrupted, and contradicted.
- **ANCHORS** — shrines that save; the first communion restores +12 consistency.

## Layout

```
project.godot        engine config, autoloads
main.tscn            single scene — everything is built in code
scripts/             autoloads, player, world, entities, enemies, boss, npc, ui
data/                entities.json, dialogue.json, rooms.gd (9 acts)
art/                 backdrops (AI painterly, graded in-engine), fonts, post shader
audio/               48 procedural WAVs — see audio/MANIFEST.md
docs/                Phase 0 bibles + ENTITY_000_Phase0_Docs.pdf
tests/               headless smoke test (golden path, combat, boss)
```

Audio was synthesized deterministically (`tools/gen_audio.ts` in the delivery hub).
Art backdrops are AI-painted and graded by the in-engine post shader to the locked
palette. Phase 0 documentation: `docs/ENTITY_000_Phase0_Docs.pdf`.
