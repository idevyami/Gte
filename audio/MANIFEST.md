# ENTITY_000 — Audio Library Manifest

Generated procedurally by `tools/gen_audio.ts` (Task 2-b, audio agent).
Format: 44100 Hz, 16-bit PCM, mono WAV. Identity: ancient + sacred + mechanical + lonely + damaged.

- **Loops** are phase-locked (base frequencies complete integer cycles per loop) and tail/head
  crossfaded (50 ms equal-power) for seamless playback. Loop points are inaudible.
- **Peak normalization:** music ≈ 0.5, ambient ≈ 0.35, sfx ≈ 0.8 (`sfx_chant_loop` is 0.3 by design —
  it is a quiet hypnotic bed layered under scenes).
- The game AudioManager loads exactly these paths relative to `res://audio/`.

**Files:** 48 &nbsp;|&nbsp; **Total duration:** 185.01 s (3m 5s)

## music/ — score layers (seamless loops unless noted)

| File | Duration | Type | Peak | Usage |
|---|---|---|---|---|
| `music/music_title.wav` | 16.00 s | loop | 0.50 | Title screen — 55/55.5 Hz drone, faint bell toll every 6 s, soft wind bed. |
| `music/music_ambient_a.wav` | 16.00 s | loop | 0.50 | Acts 1–3 exploration bed — low drone, air, distant A-minor choir pad. |
| `music/music_ambient_b.wav` | 16.00 s | loop | 0.50 | Acts 4–6 tension bed — minor-second rub (110/116.5 Hz), corrupted system blips. |
| `music/music_ambient_c.wav` | 16.00 s | loop | 0.50 | Act 7 sanctum bed — 60 Hz machine hum + harmonics, metallic clanks, ritual drone. |
| `music/music_combat.wav` | 8.00 s | loop | 0.50 | Combat layer — sparse ritual drums (~100 BPM), tension drone, metallic ticks. |
| `music/music_boss_p1.wav` | 8.00 s | loop | 0.50 | Boss phase 1 — 50 BPM ritual drums, deep stacked drone, slow bell every 4 s. |
| `music/music_boss_p2.wav` | 8.00 s | loop | 0.50 | Boss phase 2 — 75 BPM, tritone drone pair (55/77.75 Hz), chain-metal ticks. |
| `music/music_boss_p3.wav` | 8.00 s | loop | 0.50 | Boss phase 3 — 100 BPM frenzy, tanh-distorted low drone, rising noise, loud choir. |
| `music/music_aftermath.wav` | 12.00 s | loop | 0.50 | Post-battle grief — sine+fifth pad, very slow LFO, one distant bell at 6 s. |
| `music/music_death_sting.wav` | 4.00 s | one-shot | 0.50 | Player death sting — descending minor pad + low boom, decays to near-silence. |

## ambient/ — room beds (seamless loops)

| File | Duration | Type | Peak | Usage |
|---|---|---|---|---|
| `ambient/amb_wind_loop.wav` | 8.00 s | loop | 0.35 | Exterior wind — lowpassed brown noise, slow gust LFO (0.25 Hz). |
| `ambient/amb_machine_loop.wav` | 8.00 s | loop | 0.35 | Machine rooms — 60 Hz hum + 2nd/3rd harmonics, soft clank every 2 s. |
| `ambient/amb_choir_loop.wav` | 12.00 s | loop | 0.35 | Cathedral distance — very quiet airy noise bed + slow detuned sines. |
| `ambient/amb_fire_loop.wav` | 6.00 s | loop | 0.35 | Fire / braziers — soft noise bed + lowpassed crackle impulses (seam-safe). |
| `ambient/amb_void_loop.wav` | 10.00 s | loop | 0.35 | Void / liminal spaces — 40 Hz pulse, faint gated 2 kHz tone, wrongness. |

## sfx/ — interface, world, combat, entities (one-shots unless noted)

| File | Duration | Type | Peak | Usage |
|---|---|---|---|---|
| `sfx/sfx_step.wav` | 0.12 s | one-shot | 0.80 | Footstep — soft lowpassed noise tap + 70 Hz thump. |
| `sfx/sfx_jump.wav` | 0.18 s | one-shot | 0.80 | Jump — short noise breath + rising 180→260 Hz sine. |
| `sfx/sfx_land.wav` | 0.20 s | one-shot | 0.80 | Landing — 60 Hz-class thump decay + noise puff. |
| `sfx/sfx_roll.wav` | 0.25 s | one-shot | 0.80 | Dodge roll — fabric/leather noise sweep. |
| `sfx/sfx_swing_a.wav` | 0.15 s | one-shot | 0.80 | Attack swoosh A — bandpass noise rising then falling. |
| `sfx/sfx_swing_b.wav` | 0.13 s | one-shot | 0.80 | Attack swoosh B — slightly higher and faster. |
| `sfx/sfx_swing_c.wav` | 0.20 s | one-shot | 0.80 | Attack swoosh C — heavier, plus low growl. |
| `sfx/sfx_hit_light.wav` | 0.12 s | one-shot | 0.80 | Light hit — noise crack + 90 Hz thump. |
| `sfx/sfx_hit_heavy.wav` | 0.25 s | one-shot | 0.80 | Heavy hit — bigger crack + distorted 55 Hz boom. |
| `sfx/sfx_hurt.wav` | 0.25 s | one-shot | 0.80 | Player hurt — descending square-ish blip + noise. |
| `sfx/sfx_death.wav` | 1.20 s | one-shot | 0.80 | Death — low boom, descending tone, noise wash. |
| `sfx/sfx_door_open.wav` | 1.40 s | one-shot | 0.80 | Heavy door — low rumble, stone grind, final clunk. |
| `sfx/sfx_door_locked.wav` | 0.30 s | one-shot | 0.80 | Locked door — dull thunk + rattle. |
| `sfx/sfx_observe_enter.wav` | 0.40 s | one-shot | 0.80 | Observe mode enter — reversed-feel sweep up 300→900 Hz + soft glitch. |
| `sfx/sfx_observe_exit.wav` | 0.35 s | one-shot | 0.80 | Observe mode exit — sweep down 900→300 Hz + glitch. |
| `sfx/sfx_ui_move.wav` | 0.06 s | one-shot | 0.80 | UI move — 5 ms 1200 Hz sine tick. |
| `sfx/sfx_ui_confirm.wav` | 0.15 s | one-shot | 0.80 | UI confirm — two ascending blips (660, 880 Hz). |
| `sfx/sfx_ui_deny.wav` | 0.20 s | one-shot | 0.80 | UI deny — low dull double-buzz. |
| `sfx/sfx_modify.wav` | 0.40 s | one-shot | 0.80 | Property modification — bitcrushed descending data-write sequence + hum. |
| `sfx/sfx_glitch.wav` | 0.30 s | one-shot | 0.80 | Corruption — chopped bitcrushed noise bursts. |
| `sfx/sfx_correction.wav` | 0.50 s | one-shot | 0.80 | The Censor's correction — reverse swell into hard cut + glitch. Unsettling. |
| `sfx/sfx_shrine.wav` | 1.50 s | one-shot | 0.80 | Anchor shrine — soft ascending bell arpeggio (A3-C4-E4) + undertone. |
| `sfx/sfx_terminal.wav` | 0.40 s | one-shot | 0.80 | Terminal — keyclick ticks + CRT-ish hum blip. |
| `sfx/sfx_rumble.wav` | 1.60 s | one-shot | 0.80 | Deep slow rumble swell. |
| `sfx/sfx_barrier_break.wav` | 0.80 s | one-shot | 0.80 | Barrier shatter — glassy noise burst + descending sines + boom. |
| `sfx/sfx_null_warp.wav` | 0.30 s | one-shot | 0.80 | Null warp — reverse-envelope sine sweep, bitcrush, dropout. |
| `sfx/sfx_chant_loop.wav` | 4.00 s | loop | 0.30 | Ritual chant loop — male-choir-ish vowel stack, vibrato, low volume. |
| `sfx/sfx_boss_roar.wav` | 1.20 s | one-shot | 0.80 | Boss roar — distorted low saw sweep 82→46 Hz + growl noise. |
| `sfx/sfx_boss_chain.wav` | 0.50 s | one-shot | 0.80 | Boss chain — metallic jangle of short inharmonic sines + noise. |
| `sfx/sfx_boss_impact.wav` | 0.60 s | one-shot | 0.80 | Boss impact — massive thump + debris noise tail. |
| `sfx/sfx_censor.wav` | 6.00 s | one-shot | 0.80 | The Censor approach — very low pulsing 30.5/32 Hz throb + high whisper. Dread. |
| `sfx/sfx_ashfall.wav` | 3.00 s | one-shot | 0.80 | Ash settling — soft airy noise wash, gentle. |
| `sfx/sfx_reveal.wav` | 2.00 s | one-shot | 0.80 | Major discovery — low swell, one pure bell, faint choir. Awe. |

---

*Silence and space are part of the aesthetic. Sparse is intentional.*