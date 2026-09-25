#!/bin/bash
# ENTITY_000 — Visual Reconstruction Pass 3: animation enrichment for the
# four remaining single-frame characters. All frames are image-EDITS of the
# approved VP-1 raws (identity-preserving), landing in art/raw/:
#   censor_b / censor_c  -> 3-frame uncanny idle loop for THE CENSOR
#   penitent_b           -> 2-frame flicker/breath for THE PENITENT
#   oren_b               -> 2-frame stamp/verify for MEASURER OREN
#   nullchild_c          -> 3rd glitch variant for NULL CHILDREN

RAW=/home/z/entity000/art/raw
mkdir -p "$RAW"

SAME="same character, same palette, same muted desaturated colors, same painterly style, same flat solid uniform medium gray background, no gradient, no vignette, no ground shadow, no text, no watermark, no letters, full body in frame, side profile view facing right, character centered"

edit() { # $1 name  $2 base  $3 edit-prompt
  local out="$RAW/$1.png"; local base="$RAW/$2.png"
  if [ -s "$out" ]; then echo "SKIP $1"; return 0; fi
  for i in 1 2 3 4 5; do
    if timeout 240 bun run /home/z/my-project/tools/zedit.mjs "$3" "$base" "$out" "768x1344" >/dev/null 2>&1 && [ -s "$out" ]; then
      echo "OK $1"; sleep 12; return 0
    fi
    echo "RETRY $1 (attempt $i)"; sleep $((45 + i * 30))
  done
  echo "FAIL $1"; return 1
}

case "$1" in
""|all) CENSOR=1; PENITENT=1; OREN=1; NULLCHILD=1 ;;
censor) CENSOR=1 ;;
penitent) PENITENT=1 ;;
oren) OREN=1 ;;
nullchild) NULLCHILD=1 ;;
*) echo "usage: $0 [all|censor|penitent|oren|nullchild]"; exit 2 ;;
esac

if [ -n "$CENSOR" ]; then
  edit "censor_b" "censor_base" "same walking vertical redaction bar entity, same tall narrow monolith of matte absolute black, same horizontal band of bone-white parchment strikethrough where a face would be, $SAME: now the whole body leaning slightly forward and subtly stretched a little taller, the thin horizontal scanning line of crimson light crossing lower near the middle of the body, the faint cold-cyan glitch afterimage edges trailing behind the body on the left side, ritual sigils near the base unchanged" || exit 1
  edit "censor_c" "censor_base" "same walking vertical redaction bar entity, same tall narrow monolith of matte absolute black, same horizontal band of bone-white parchment strikethrough where a face would be, $SAME: now the body leaning slightly backward and subtly compressed a little shorter, the thin horizontal scanning line of crimson light crossing high near the top of the body, the faint cold-cyan glitch afterimage edges offset to the front on the right side, ritual sigils near the base glowing faintly brighter" || exit 1
fi

if [ -n "$PENITENT" ]; then
  edit "penitent_b" "penitent_base" "same ancient figure wrapped head to toe in a ragged bone-white burial shroud, same roped bindings of dark cord crossing the chest, same closed black ledger held in one barely visible hand, $SAME: now caught mid-flicker like something not fully real, the whole figure slightly desaturated and phase-shifted with a faint cold-cyan ghost offset along the right edge of the silhouette, the darkness inside the hood deeper, posture one breath lower and more stooped" || exit 1
fi

if [ -n "$OREN" ]; then
  edit "oren_b" "oren_base" "same institutional clerk-priest, same dark slate-violet heavy clerical robe with the faded gold measuring-line stole, same flat wide-brimmed measuring cap, same large round brass measuring lens on an armature in front of the face with a faint cyan glow, same thick ledger, $SAME: now with the heavy lead stamp pressed flat down onto the ledger page, the measuring lens tilted slightly downward as if verifying a measurement, patient bureaucratic demeanor" || exit 1
fi

if [ -n "$NULLCHILD" ]; then
  edit "nullchild_c" "nullchild_base" "same unfiled child-like entity, same small pale unfinished figure of bone-white skin, same incomplete face like a filing error, same smooth stump where one arm stopped, same lower body dissolving into unfinished sketchy static, $SAME: now with the faint cold-cyan glitch offset ghosting larger on the left side, the misaligned eye gaps redrawn slightly differently like a re-attempted filing error, one eye gap nearly closed" || exit 1
fi

echo "P3 GENERATION COMPLETE"
