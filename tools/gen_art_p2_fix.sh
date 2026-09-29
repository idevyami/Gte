#!/bin/bash
# VP2 fixes: no-text regeneration for 4 assets flagged by VLM QA.
RAW=/home/z/entity000/art/raw

STYLE="dark gothic horror 2D game art, hand-painted digital illustration, muted desaturated palette limited to charcoal black, ash gray, dirty stone brown, bone white, desaturated steel, restrained accents of oxidized crimson and muted antique gold, painterly brush texture, oppressive sacred decayed atmosphere, isolated on a flat solid uniform medium gray background, no gradient, no vignette, no ground shadow, absolutely no text, no letters, no words, no typography, no titles, no captions, no watermark"

gen() {
  local out="$RAW/$1.png"
  for i in 1 2 3 4 5; do
    if timeout 240 z-ai image -p "$2" -o "$out" -s "$3" >/dev/null 2>&1 && [ -s "$out" ]; then
      echo "OK $1"; sleep 12; return 0
    fi
    echo "RETRY $1 (attempt $i)"; sleep $((45 + i * 30))
  done
  echo "FAIL $1"; return 1
}

edit() {
  local out="$RAW/$1.png"; local base="$RAW/$2.png"
  for i in 1 2 3 4 5; do
    if timeout 240 bun run /home/z/my-project/tools/zedit.mjs "$3" "$base" "$out" "$4" >/dev/null 2>&1 && [ -s "$out" ]; then
      echo "OK $1"; sleep 12; return 0
    fi
    echo "RETRY $1 (attempt $i)"; sleep $((45 + i * 30))
  done
  echo "FAIL $1"; return 1
}

rm -f "$RAW/decor_bones.png" "$RAW/hollow_idle_b.png" "$RAW/believer_walk_b.png" "$RAW/believer_walk_c.png"

gen "decor_bones" "loose shallow scatter of old human bones lying on nothing, a horizontal low scatter of parch-colored bones only — a ribcage piece, two long bones, a partial skull, a jawbone, small fragments — the bones themselves form a flat low wide pile on the plain background, seen straight from the side at ground level, muted parch and bone tones, no ground, no floor, no surface, just the bones, $STYLE" "1344x768" || exit 1

HOLLOW_SAME="same creature, same style, same muted palette, same painterly style, same flat solid uniform medium gray background, same framing, absolutely no text, no letters, no words, no titles"
BELIEVER_SAME="same character, same habit, same muted palette, same painterly style, same flat solid uniform medium gray background, same side profile framing, absolutely no text, no letters, no words, no titles"

edit "hollow_idle_b" "hollow_base" "$HOLLOW_SAME: subtle breathing variant, ribcage slightly contracted, head a touch lower, limbs unchanged in place, everything else identical" "768x1344" || exit 1
edit "believer_walk_b" "believer_stand" "$BELIEVER_SAME: mid-stride shuffling walk pose, one leg forward heel down, other leg trailing behind under the habit, torso leaning slightly forward, arms swinging naturally under the sleeves, habit hem swaying with the motion" "768x1344" || exit 1
edit "believer_walk_c" "believer_stand" "$BELIEVER_SAME: opposite walking stride, the other leg forward, opposite arm forward, habit hem swept the other way, head bowed the same" "768x1344" || exit 1

echo "FIXES DONE"
