# ENTITY_000 — 01 · Game Design Bible

Phase 0 documentation. Godot 4.4 vertical slice contract. This bible locks the playable feel: pillars, core loop, player kit, enemy roster, boss design, and combat feel principles. Numbers in this file are locked constants; the implementation must match them exactly.

## 1. Concept

ENTITY_000 is a 2D action/exploration/puzzle psychological mystery set in the City of Ash. The player is ENTITY_000_818: no name, no history, no memory. The first objective printed by the system is RESTORE THE WORLD. The game's central question — the question every mechanic exists to press — is: if you were created for a purpose, do you have the right to reject it?

You awaken in The Cradle, a vertical iron womb beneath the city, and climb toward The Heart of the Design. Along the way you learn to OBSERVE the world's data, to modify the properties that define it, and to pay for every alteration with a resource called Consistency — the measure of how much reality still agrees with you.

The fantasy is not power. The fantasy is jurisdiction: the slow discovery that the world is editable, and the escalating cost of editing it.

## 2. Design Pillars

| Pillar | Statement | What it forbids |
|---|---|---|
| Purpose is physics | Every system expresses the world's obsession: purpose, measurement, correction | Decorative lore that has no mechanical echo |
| Deliberate combat | Attacks are commitments; enemies telegraph; reads beat reflexes | Mashing, combo-cancelling, input strings |
| Knowledge is a resource | OBSERVE data and Consistency are spent and budgeted like HP | Free information dumps, exposition NPCs |
| Consequences are rules breaking | Manipulating reality must feel like law violation, never like random noise | Glitch filters with no meaning, random jumpscares |
| Never explain | The Design is revealed through use, contradiction, and cost | Lore lectures, codex entries that resolve mystery |

Pillar five governs all writing. The Design is both a religion and an administrative system; the slice never says which it "really" is, because that ambiguity is the product.

## 3. Core Loop

The minute-to-minute loop is a decision loop, not a grind loop:

1. **Explore** a room of the City of Ash; read it environmentally (ash, masonry, censored absences).
2. **OBSERVE** anything suspicious: the world slows, a data panel opens, entities expose id, type, state, properties, purpose, memory, belief.
3. **Decide**: accept the world as measured, or modify a property (locked=false, state=TERMINATED, purpose=ABANDON).
4. **Pay**: Consistency is spent only by manipulation, never by combat. The budget is the player's honesty.
5. **Suffer or bank**: lower Consistency escalates staged consequences (stage 4 summons THE CENSOR); ANCHOR shrines checkpoint and save.

The loop's tension is that the two currencies pull against each other: knowledge (OBSERVE, fragments, hidden data) usually costs Consistency, while survival prefers high Consistency. A player who modifies nothing is safe but blind; a player who modifies everything sees everything and is hunted.

## 4. Player Kit (Locked Numbers)

| Ability | Constant | Design intent |
|---|---|---|
| Move speed | 260 px/s | Deliberate traversal; rooms read at walking pace |
| Jump velocity | 420 | Clears 3-tile ledges, not 4; verticality is earned |
| Max HP | 100 | ~8 meaningful hits early; healing is rare and placed |
| Attack chain | 3 hits, 22 / 22 / 30 damage | Finisher rewards committing to the full string |
| Roll | 380 px/s, 0.35 s, i-frames, 0.6 s cooldown | Panic button with a price; cannot be spammed |
| Crawl | shape resize, slow move | Access to low passages; vulnerability trade |
| Coyote time | 0.12 s | Forgiveness tuned for 60 fps input |
| Jump buffer | 0.15 s | Forgiveness tuned for 60 fps input |
| OBSERVE | toggle; time dilation while open | Read the world while it moves slowly around you |

Chain rules: the third hit only chains if the second landed within the window; whiffing resets to hit one. Roll grants i-frames for its full 0.35 s duration but its 0.6 s cooldown means it cannot answer two telegraphs in a row — the player must position instead. OBSERVE does not pause the world; it dilates it, so reading a panel mid-combat is a real risk.

## 5. Enemy Roster

| Enemy | HP | Damage | Speed | Role |
|---|---|---|---|---|
| THE HOLLOW | 60 | lunge 12 | patrol 90 / stalk 150 px/s | Fundamentals teacher |
| NULL CHILDREN | 40 | touch 8 | drift; no collision | Puzzle-pressure enemy |
| THE BELIEVERS | 80 | 10 | group march | Belief mechanic carrier |
| THE CENSOR | unkillable | touch 30 | 120 (stage 4) to 200 (stage 5) px/s | Consistency predator |

**THE HOLLOW** is the absence of identity given appetite. It patrols at 90 px/s, stalks at 150 px/s when it notices you, and telegraphs a 340 px/s lunge with a 0.55 s windup: a visible crouch, a rising audio whine, then commitment. It cannot turn mid-lunge. It is perfectly readable and deeply unsettling, which is the intended teaching pair. At low Consistency it "blinks": a short teleport that breaks spacing taught earlier in the game.

**NULL CHILDREN** exist outside classification. They drift through walls, deal 8 touch damage, and are invulnerable to the attack chain. Only OBSERVE exposes their state property; setting state=TERMINATED (cost 4 Consistency each) makes them dispersible. They react to Consistency: as stages fall they drift faster and cluster. They teach that some problems cannot be fought, only edited.

**THE BELIEVERS** are collective belief made flesh. They chant in groups; three or more chanting empower each other by +25% damage each, so a trio hits at 1.75x. Their purpose can be OBSERVE-modified to ABANDON: the ritual stops and they flee. Killing them is free; editing them is not. This is the game's thesis in one enemy.

**THE CENSOR** is the correction entity and the spine of the HUNTED model. It spawns at stage 4 (Consistency 55–41) and hunts the player through rooms. It cannot be harmed; it corrects. Contact costs 30 HP. Its speed scales from 120 px/s at stage 4 to 200 px/s at stage 5. It is not a failure state — it is the world's objection made physical.

## 6. Boss: THE BOUND MARTYR

ENTITY_000_001, the first entity, bound in chains at the Reliquary. Its suffering became its purpose. 900 HP across three phases.

| Phase | HP range | Kit | Pressure |
|---|---|---|---|
| 1 | 900–600 | Chained censer swings, 18 damage | Belief shield held by 2 censer-bearer Believers |
| 2 | 600–300 | FERVOR: arena shrinks (wall of faith), dash attacks 24 damage | Consistency drain aura, 1/s within radius |
| 3 | 300–0 | Chains snap; desperate wide swings, ground slam 30 damage | OBSERVE data evolves mid-fight |

Phase 1 teaches the slice's whole grammar in one room: kill the bearers (combat) or OBSERVE-modify the censer's purpose to ABANDON (manipulation) — either drops the shield. Phase 2 turns the arena itself hostile and makes the Consistency economy visible as a combat resource drained by proximity. Phase 3 pays off the evolving OBSERVE readout: the Martyr's purpose visibly rewrites from SERVE THE DESIGN to BE REMEMBERED as it dies.

Death sequence (locked): chains snap, it thanks you, it collapses to ash, and the inscription is revealed: ENTITY_000_001 — FAILED — REPURPOSED. The monument persists into Act 9.

## 7. Combat Feel Principles

1. **Telegraph everything.** Every hostile damage source is announced by animation, silhouette, or sound at least 0.4 s before it lands. The Hollow's 0.55 s windup is the reference standard.
2. **Commit on both sides.** Player attacks and enemy attacks lock their owners in place. Dodging is a decision to spend the roll's cooldown; attacking is a decision to stand still.
3. **Reward the read, not the reflex.** Damage windows open after telegraphs resolve; the optimal answer to a lunge is a pre-positioned punish, not a reaction parry.
4. **Impact is physical.** Hits land with hitstop, screen shake scaled to damage, and swing trails; the 30-damage finisher must feel three times heavier than a 22 jab through juice alone.
5. **Risk buys knowledge.** OBSERVE stays open in combat at dilated time; reading a panel while a Hollow winds up is the game's signature risk/reward verb.
6. **No crowd-control spam.** Enemy counts stay low (2–5 active) so every encounter is legible; difficulty comes from composition and consistency pressure, not density.
7. **Damage numbers are honest.** 22 means 22. Every HUD value is real state; nothing on screen is cosmetic.

These principles make combat the argument for the game's theme: in a world where everything must justify itself, every button press is a claim of purpose, and the world answers.
