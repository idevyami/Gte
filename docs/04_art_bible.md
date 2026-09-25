# ENTITY_000 — 04 · Art Bible

Phase 0 documentation. This bible locks the visual law of ENTITY_000: the palette, the post-process grade, character construction as polygon-rig silhouettes, and act-by-act environment direction. The direction is one sentence: gothic religious architecture, industrial decay, digital corruption — in that order of dominance.

## 1. Direction

Three layers compose every scene:

1. **Gothic religious architecture** — pointed arches, recessed niches, censer chains, shrines. The city believes, and its stonework is liturgy. This layer carries silhouette and composition.
2. **Industrial decay** — iron, rivets, cable runs, toll machinery, pipework sweating rust. The city administers, and its machinery is aging badly. This layer carries texture and narrative wear.
3. **Digital corruption** — cold cyan system veins, OBSERVE brackets, tearing at the frame's edge when Consistency falls. The city is maintained. This layer is the quietest and must never dominate more than 5% of any frame.

Rendering approach: procedural CanvasItem drawing — polygon rigs, masonry renderer, additive glow lighting — over a small set of painterly backdrops graded in-engine by a single post shader. Nothing glossy; every surface absorbs light like ash.

## 2. Locked Palette

| Role | Name | Hex | Usage |
|---|---|---|---|
| Base | Void black | `#050506` | Deepest shadow, letterboxing, the space between rooms |
| Base | Charcoal | `#141417` | Iron structures, background silhouettes |
| Base | Ash gray | `#6f6a5e` | Falling ash, distant stone, midground haze |
| Base | Dirty stone | `#3a3733` | Load-bearing masonry, floors, walls |
| Base | Bone white | `#d8d2c4` | Highest-value surfaces: candles, inscriptions, UI text |
| Base | Dark brown | `#4a3020` | Wood, pews, censer handles, dried blood |
| Base | Desaturated steel | `#555a5f` | Machinery, chains, toll machines |
| Accent | Deep blood red | `#7a1f1f` | Martyr's chains, damage flashes, deepest ritual cloth |
| Accent | Oxidized crimson | `#9a4a3a` | Rust, dried offerings, secondary ritual red |
| Accent | Muted gold | `#a8862f` | Halo rims, inlay lines, ANCHOR bowls, rare opulence |
| Accent | Very dark violet | `#3a2a4a` | Believer robes, Chantry glass, the sacred uncanny |
| Accent | Cold system cyan | `#4fd8e0` | OBSERVE readouts and system elements ONLY |

Palette law: the seven base tones own 95% of every frame; accents exist in bursts under 5%. Cold system cyan is reserved absolutely — the moment it appears, the frame is making a factual claim. Value structure beats hue: the game must read correctly in grayscale, with bone white reserved for what the eye should find first.

## 3. Post-Process Shader Specification

A single full-screen pass (`post.gdshader`) applied via the FX autoload. Uniforms:

| Uniform | Type | Range | Driven by |
|---|---|---|---|
| `u_grain` | float | 0.00–0.08 | Static film grain; subtle flicker over time |
| `u_vignette` | float | 0.20–0.60 | Composition; deepens during CENSOR proximity |
| `u_tear` | float | 0.00–1.00 | Consistency stage (0 at S1, rising through S2+) |
| `u_tear_time` | float | seconds | Horizontal tearing displacement band position |
| `u_observe` | float | 0.00–1.00 | OBSERVE grade blend (1.0 while panel open) |

**Effects.** Grain: animated monochrome noise, heavier in shadows. Vignette: soft elliptical falloff toward void black. Tearing: occasional horizontal displacement bands whose frequency and amplitude scale with `u_tear` — at S5+ bands coincide with `correction_spawned` events so corruption and consequence stay causally linked. Observe grade: while `u_observe` is high, the image cools and flattens (desaturation plus a slight cyan lift in midtones), signaling that the player is reading the world's data layer rather than the world.

## 4. Character Sheets (Polygon-Rig Silhouettes)

All characters are built as articulated polygon rigs — flat dark silhouettes with limited palette accents, animated by code. Readability at a glance is mandatory: each silhouette must be identifiable from its outline alone.

| Character | Construction | Palette | Animation signature |
|---|---|---|---|
| Player (ENTITY_000_818) | Lean humanoid, wrapped form, no face — a cowl void | Charcoal body, bone-white edge rim, cyan OBSERVE brackets | Precise: 3-hit chain with visible swing trails; roll is a tucked tumble; crawl flattens the rig |
| THE HOLLOW | Hunched quadruped-leaning biped, limbs too long, head a smooth blank | Dirty stone body, ash-gray limb joints | Windup crouch held 0.55 s, then a committed flat lunge; blinks collapse and rebuild the rig in two frames |
| NULL CHILDREN | Small drifting figures, edges unfinished — polygons that do not quite close | Charcoal with hairline cyan seams that flicker | No walk cycle; they drift and rotate slowly; on TERMINATED they unravel into drifting polygons |
| THE BELIEVERS | Robed kneeling or processing figures, faces hooded, hands clasped | Very dark violet robes, oxidized-crimson sash | Swaying chant loop; chant stacks raise a faint gold shimmer; ABANDON breaks the sway and they scatter |
| THE CENSOR | Tall administrative silhouette — a clerk's posture, arms too orderly, head a measuring mark | Charcoal suit, bone-white measuring line, cyan edge trace | Walks rather than lunges; corrections appear where it pauses; its restraint is the threat |
| THE BOUND MARTYR | Massive chained figure, censers as weapons, posture of worship held by iron | Deep blood red chains, oxidized crimson censers, ash-gray body | Phase 1 swings from chains; phase 2 FERVOR tightens the arena wall of faith; phase 3 chains snap and the rig becomes desperate |

Contact shadows ground every rig. The player's rig is the most articulated (the only character allowed expressive gesture), because the player is the only entity whose purpose is not yet written.

## 5. Act-by-Act Environment Direction

| Act | Space | Direction |
|---|---|---|
| 1 · The Cradle | Vertical iron womb | Womb-dark; charcoal ribs, single bone-white light from above; machinery implies birth, not warmth |
| 2 · The Ascent | Service shafts and stairwells | Movement teaching space; generous silhouettes, readable platforms, first ash fall |
| 3 · The Measured Way | Civic thoroughfare | Bureaucratic gothic: queue rails, toll machines, plaques; dirty stone with gold inlay lines |
| 4 · The Undercity | Beneath the civic layer | Damp masonry, wrong shadows, duplicated decor; census stones; Null Children drift here |
| 5 · The Chantry | Believers' hall of worship | Violet glass, candle banks, the Pale Saint relic niche; the ward barrier as a shimmer of faith |
| 6 · The Archive Loft | Records shelving, iron catwalks | Paper and dust; 817 failure records; the Penitent glimpsed between stacks; hidden platform at S6 |
| 7 · The Heart Approach | Industrial cathedral | Nave-scale machinery, cable tracery replacing stained glass; CENSOR pressure; heat and hum |
| 8 · The Reliquary | Boss arena | A shrine turned execution yard; chained Martyr center; ash at its deepest here |
| 9 · Aftermath | The same arena, after | Emptied, quiet, one persistent monument; the grade slowly clears as the question is posed |

## 6. Typography

All UI type is monospaced, technical, and damaged: system messages and OBSERVE readouts render in a terminal face with occasional dropped or duplicated glyphs at low Consistency. Titles may use a serif of funerary weight. Body text never appears in-world outside plaques and records, which are carved (serif, small-caps) rather than printed.

## 7. Forbidden Looks and References

Forbidden: childish, cute, or chibi proportions; generic neon; glossy or wet surfaces; saturated color outside the accent law; UI chrome that reads as a modern operating system; any iconography that winks at the player.

References are a quality bar only — Blasphemous, Dead Cells, Hollow Knight, Salt and Sanctuary, Darkwood, Signalis, Hyper Light Drifter — for silhouette discipline, animation readability, environmental storytelling, dread pacing, UI restraint, and color law respectively. Copying composition, motifs, or assets from any reference is prohibited; the bar they set is clarity and conviction, not style transfer.
