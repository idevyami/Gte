#!/bin/bash
# ENTITY_000 — Visual Reconstruction Pass 2: painted decor + animation frames
# 8 painted decor kinds (column, machine, banner, statue, arch, mural, censer,
# bones — 75 of ~105 decor placements) + 5 supplemental enemy animation frames
# (hollow idle/lunge, believers walk x2, null child idle).
# Raw outputs land in art/raw/; art_pipeline.py processes them afterwards.

RAW=/home/z/entity000/art/raw
mkdir -p "$RAW"

# ---- shared style anchor --------------------------------------------------
STYLE="dark gothic horror 2D game art, hand-painted digital illustration, muted desaturated palette limited to charcoal black, ash gray, dirty stone brown, bone white, desaturated steel, restrained accents of oxidized crimson and muted antique gold, painterly brush texture, oppressive sacred decayed atmosphere, isolated on a flat solid uniform medium gray background, no gradient, no vignette, no ground shadow, no text, no watermark, no letters"

gen() { # $1 name  $2 prompt  $3 size
  local out="$RAW/$1.png"
  if [ -s "$out" ]; then echo "SKIP $1"; return 0; fi
  for i in 1 2 3 4 5; do
    if timeout 240 z-ai image -p "$2" -o "$out" -s "$3" >/dev/null 2>&1 && [ -s "$out" ]; then
      echo "OK $1"; sleep 12; return 0
    fi
    echo "RETRY $1 (attempt $i)"; sleep $((45 + i * 30))
  done
  echo "FAIL $1"; return 1
}

edit() { # $1 name  $2 base  $3 edit-prompt  $4 size
  local out="$RAW/$1.png"; local base="$RAW/$2.png"
  if [ -s "$out" ]; then echo "SKIP $1"; return 0; fi
  for i in 1 2 3 4 5; do
    if timeout 240 bun run /home/z/my-project/tools/zedit.mjs "$3" "$base" "$out" "$4" >/dev/null 2>&1 && [ -s "$out" ]; then
      echo "OK $1"; sleep 12; return 0
    fi
    echo "RETRY $1 (attempt $i)"; sleep $((45 + i * 30))
  done
  echo "FAIL $1"; return 1
}

case "$1" in
""|all) DECOR=1; ANIM=1 ;;
decor) DECOR=1 ;;
anim) ANIM=1 ;;
esac

# ============================================================ DECOR (P2-A)
if [ -n "$DECOR" ]; then

# COLUMN — most used decor (18). Plain shaft so code 3-slicing (capital /
# stretched shaft / base) stays seamless at any height 380..520.
gen "decor_column" "single tall gothic stone column, full column from capital to base in frame, plain unadorned slightly tapered rectangular shaft of weathered dirty brown-gray stone with subtle chisel marks, simple carved square capital at top, plain wide square plinth base at bottom, vertical, centered, fills frame top to bottom, $STYLE" "768x1344" || exit 1

# MACHINE — reliquary engine (10). Body only; live gauges drawn in code on top.
gen "decor_machine" "dark industrial gothic reliquary machine, tall box-shaped iron and stone apparatus like a cabinet-sized shrine-engine, riveted desaturated steel panels with dirty stone corner posts, one round porthole window very dark inside, small pipes and valves on the sides, front face mostly flat and uncluttered, ominous sacred machinery, centered, $STYLE" "768x1344" || exit 1

# BANNER — hanging ritual cloth (10). Crimson; violet variant via code modulate.
gen "decor_banner" "vertical hanging ritual cloth banner, long narrow tattered drape of heavy oxidized crimson fabric with frayed lower edge and a single faded gold thread border, a small abstract stitched eye-sigil emblem in muted parchment tones near the top third, cloth hangs straight down from a thin dark rod at the very top, flat frontal view, centered, $STYLE" "768x1344" || exit 1

# STATUE — kneeling penitent statue (6). Mirrored by seed in code.
gen "decor_statue" "small kneeling stone statue of a hooded penitent figure carved from dirty brown-gray weathered stone, hooded head bowed low, hands pressed together in prayer, kneeling with knees on a simple stone plinth, rough carved texture with cracks and chips, muted solemn sacred mood, full statue with plinth in frame, centered, $STYLE" "768x1344" || exit 1

# ARCH — gothic arch band (8). Center hollow (bg-colored) so cutout keeps the ring.
gen "decor_arch" "gothic pointed stone arch band, only the curved arch ring itself made of weathered dirty brown-gray stone blocks with a carved keystone at the apex, the area inside the arch curve is plain flat medium gray matching the background completely, no wall behind the arch, arch band seen straight on, centered, fills the frame width, $STYLE" "1344x768" || exit 1

# MURAL — faded wall painting (2). The eleven saints in procession.
gen "decor_mural" "faded gothic wall mural painting on old cracked plaster, a procession of eleven small hooded saint figures walking in a single horizontal line carrying reliquaries and lanterns, dim antique gold halos above their heads, pigments worn and desaturated, browns bone whites and muted gold on dark plaster, wide horizontal composition, flat frontal view, centered, $STYLE" "1344x768" || exit 1

# CENSER — hanging golden censer (2). Swings via code rotation at the pivot.
gen "decor_censer" "hanging ritual censer, small antique gold incense burner shaped like a covered cup with pierced lids and three thin chains converging upward to a single hanging ring at the top of the frame, dark smoke stains on the metal, vertical composition with the chains rising to the very top edge, centered, $STYLE" "768x1344" || exit 1

# BONES — scattered remains decal (11). Stamped scaled by width in code.
gen "decor_bones" "scattered pile of old bones on flat ground, a loose shallow scatter of parch-colored human bones, a ribcage piece, long bones, fragments of a skull, jawbone, all lying flat in a low wide horizontal pile, seen straight from the side at ground level, muted parch and bone tones, centered, $STYLE" "1344x768" || exit 1

fi

# ============================================================ ANIM (P2-B)
if [ -n "$ANIM" ]; then

HOLLOW_SAME="same creature, same style, same muted palette, same painterly style, same flat solid uniform medium gray background, same framing"
BELIEVER_SAME="same character, same habit, same muted palette, same painterly style, same flat solid uniform medium gray background, same side profile framing"
NULL_SAME="same entity, same glitch artifacts, same muted palette, same painterly style, same flat solid uniform medium gray background, same framing"

# HOLLOW — idle breathing variant + lunge full extension (2nd frames).
edit "hollow_idle_b" "hollow_base" "$HOLLOW_SAME: subtle breathing variant, ribcage slightly contracted, head a touch lower, limbs unchanged in place, everything else identical" "768x1344" || exit 1
edit "hollow_lunge_b" "hollow_lunge" "$HOLLOW_SAME: full-extension follow-through of the lunge, body stretched to its longest, limbs trailing taut behind the jaw, forward momentum at its peak, everything else identical" "768x1344" || exit 1

# BELIEVERS — walk shuffle cycle (3 new frames around the base stand).
edit "believer_walk_b" "believer_stand" "$BELIEVER_SAME: mid-stride shuffling walk pose, one leg forward heel down, other leg trailing behind under the habit, torso leaning slightly forward, arms swinging naturally under the sleeves, habit hem swaying with the motion" "768x1344" || exit 1
edit "believer_walk_c" "believer_stand" "$BELIEVER_SAME: opposite walking stride, the other leg forward, opposite arm forward, habit hem swept the other way, head bowed the same" "768x1344" || exit 1

# NULL CHILDREN — glitch-flicker variant (2nd idle frame).
edit "nullchild_b" "nullchild_base" "$NULL_SAME: glitch-flicker variant, silhouette slightly offset from itself with a faint cyan-echoed double edge, one small part of the figure desynchronized and displaced a few pixels, overall shape still recognizable as the same entity" "768x1344" || exit 1

fi

echo "GEN_P2 DONE"
