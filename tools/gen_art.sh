#!/bin/bash
# ENTITY_000 — Visual Reconstruction Pass: AI source art generation
# Raw outputs land in art/raw/ (git/godot-ignored via .gdignore).
# Each character = 1 canonical base generation + pose EDITS from that base
# (identity consistency), all post-processed later by tools/art_pipeline.py.

RAW=/home/z/entity000/art/raw
mkdir -p "$RAW"

# ---- shared style anchor (unifies every asset) ---------------------------
# NOTE: all character art is generated on a FLAT UNIFORM GRAY background —
# dark-on-dark AI output cannot be segmented reliably (gradient + noise);
# flat gray makes the cutout deterministic. Palette is re-locked in-engine.
STYLE="dark gothic horror 2D game art, hand-painted digital illustration, muted desaturated palette limited to charcoal black, ash gray, dirty stone brown, bone white, desaturated steel, restrained accents of oxidized crimson and muted antique gold, painterly brush texture, oppressive sacred decayed atmosphere, full body in frame from head to feet, side profile view facing right, character centered, isolated on a flat solid uniform medium gray background, no gradient, no vignette, no ground shadow, no text, no watermark"

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
""|all) PLAYER=1; MARTYR=1; ENEMIES=1; ENV=1 ;;
player) PLAYER=1 ;;
martyr) MARTYR=1 ;;
enemies) ENEMIES=1 ;;
env) ENV=1 ;;
esac

# ============================================================ PLAYER (P0)
if [ -n "$PLAYER" ]; then
PLAYER_DESC="2D game character art of ENTITY_000: a mysterious manufactured humanoid vessel, slender androgynous figure with grounded realistic human proportions, wearing a layered charcoal-black hooded ritual shroud reaching below the knees with a tattered ash-gray hem, deep hood revealing a smooth bone-white featureless faceplate with two tiny cold cyan points of light for eyes, thin faint cyan stencil marks etched along one forearm like serial numbers, ash-gray cloth bindings wrapping forearms and shins, holding a short ritual straight blade low at its side, bone-white blade with dull antique-gold crossguard. Restrained empty design, the character does not look like a conventional hero, strong readable silhouette, believable anatomy"
SAME="same character, same outfit, same muted palette, same painterly style, same flat solid uniform medium gray background, same side profile framing facing right"

gen "player_idle_a" "$PLAYER_DESC, standing still in a neutral idle stance, weight even, shroud hanging straight, blade held low pointing down at its side, $STYLE" "768x1344" || exit 1

edit "player_idle_b" "player_idle_a" "$SAME: subtle breathing variant, chest slightly lifted, shoulders a touch lower, hem of the shroud shifted one inch, cyan eye lights unchanged, everything else identical" "768x1344"
edit "player_walk_a" "player_idle_a" "$SAME: mid-stride walking pose, front leg extended forward with heel striking, back leg trailing behind, torso leaning slightly forward, shroud hem swept backward with the motion, arms in natural walk swing, blade still held low in the rear hand" "768x1344"
edit "player_walk_b" "player_idle_a" "$SAME: passing pose mid-walk, legs crossing close together under the body, one knee slightly raised, torso upright, shroud hanging almost straight, arms at mid swing" "768x1344"
edit "player_walk_c" "player_idle_a" "$SAME: opposite walking stride, the other leg extended forward, opposite arm forward, shroud hem swept the other way, blade arm forward" "768x1344"
edit "player_jump" "player_idle_a" "$SAME: rising jump pose, knees tucked up, blade arm trailing down and back, shroud flared upward and behind, body angled upward with lift-off energy" "768x1344"
edit "player_fall" "player_idle_a" "$SAME: falling pose while descending, legs extended down and slightly forward, arms spread slightly for balance, shroud billowing upward, body angled slightly back, weightless" "768x1344"
edit "player_atk_windup" "player_idle_a" "$SAME: attack anticipation pose, weight shifted onto the back leg, torso coiled backward, blade raised behind the shoulder pointing up and back, front arm extended forward for balance, shroud whipping back" "768x1344"
edit "player_atk_1" "player_idle_a" "$SAME: horizontal slash follow-through, lunging forward low, blade fully extended horizontally ahead after the cut, torso leaned into the strike, shroud trailing far behind, front foot planted hard" "768x1344"
edit "player_atk_2" "player_idle_a" "$SAME: rising diagonal upslash follow-through, blade swung upward in front, body twisted with the momentum, back heel lifting off the ground, shroud swirling" "768x1344"
edit "player_atk_3" "player_idle_a" "$SAME: heavy overhead slam follow-through, blade brought straight down in front having just struck the ground, body hunched over the impact point, weight fully forward, shroud cascading over the back" "768x1344"
edit "player_hurt" "player_idle_a" "$SAME: staggered hurt pose, knocked off balance backward, torso recoiling, one arm flung out for balance, head tilted back, shroud flaring forward, blade loose in the other hand" "768x1344"
edit "player_death_a" "player_idle_a" "$SAME: collapsing pose, knees buckling inward, body folding forward and sinking toward the ground, blade dropping from the loosening hand, shroud pooling around the legs" "768x1344"
edit "player_death_b" "player_idle_a" "$SAME: fallen pose, lying collapsed on its side on the ground motionless, shroud draped over the body, the blade resting on the ground beside the outstretched hand" "768x1344"
edit "player_interact" "player_idle_a" "$SAME: reaching interaction pose, standing upright, free arm extended forward with an open wrapped palm, head slightly inclined toward the thing it reaches toward, blade held low behind" "768x1344"
edit "player_observe" "player_idle_a" "$SAME: perfect stillness observation pose, standing very upright and motionless, head lifted slightly, the two cyan eye lights glowing noticeably brighter, thin cyan light lines flickering along the etched forearm marks, shroud hanging dead straight" "768x1344"
edit "player_roll" "player_idle_a" "$SAME: tucked roll pose, body compacted into a tight ball mid forward somersault, limbs tucked under the shroud which wraps around them, rotating forward momentum" "768x1344"
fi

# ====================================================== BOUND MARTYR (P0)
if [ -n "$MARTYR" ]; then
MARTYR_DESC="2D game boss character art of THE BOUND MARTYR: a colossal suffering penitent giant, three heads taller than a man, emaciated powerful body wrapped in a rotted dark-brown penitent sackcloth, hooded bowed head, face hidden in darkness except one dim bone-white glow, a large broken golden halo floating cracked above the hood, heavy rusted chains and manacles binding the torso and arms running off to both sides, deep oxidized-crimson seams of light splitting the skin across the chest and arms like stigmata of machinery, one arm ending in a heavy swinging censer flail of dark iron with a glowing ember core"
MSAME="same boss character, same sackcloth and chains, same broken golden halo, same muted palette, same painterly style, same flat solid uniform medium gray background, same side profile framing facing right, full body in frame"

gen "martyr_p1" "$MARTYR_DESC, phase one bound suffering stance: body hunched and dragged forward under the weight of the chains, shambling posture, censer flail hanging low, $STYLE" "768x1344" || exit 1

edit "martyr_p1_atk" "martyr_p1" "$MSAME: wide sweeping attack with the censer flail, arm and flail fully extended horizontally ahead after the swing, body twisted into the strike, chains pulled taut and lifting, sackcloth whipping" "768x1344"
edit "martyr_p2" "martyr_p1" "$MSAME: phase two fervor stance, chains glowing with ember heat, the crimson seams across the body burning brighter, posture risen and aggressive leaning forward, halo burning with intensified gold light, censer flail raised mid-height" "768x1344"
edit "martyr_p3" "martyr_p1" "$MSAME: phase three unchained desperation, the chains snapped and hanging broken from the wrists, sackcloth torn ragged, halo cracked and dimmed to dark violet, body lunging forward low and fast like a freed animal, censer flail cocked back to strike" "768x1344"
edit "martyr_p2_atk" "martyr_p2" "$MSAME: wide fervor attack with the burning censer flail, arm and flail fully extended horizontally ahead after the swing, ember chains trailing sparks, body twisted into the strike" "768x1344"
edit "martyr_p3_atk" "martyr_p3" "$MSAME: desperate unchained leaping attack mid-air, body launched low and forward, censer flail overhead about to crash down, broken chains whipping behind" "768x1344"
edit "martyr_death" "martyr_p1" "$MSAME: dying collapse, sinking to its knees, head bowed in gratitude and release, the last chains snapping and falling away, halo fading, censer flail dropped to the ground, body beginning to come apart into drifting ash" "768x1344"
fi

# ============================================== ENEMIES + NPC (P1 / P2)
if [ -n "$ENEMIES" ]; then

gen "hollow_base" "2D game enemy character art of THE HOLLOW: a failed emptied human whose purpose was removed, leaving a distorted remainder, unnaturally elongated gaunt body with wrong proportions, ash-gray cracked desiccated skin like old plaster, a perfectly circular hollow hole through the chest where a heart should be, arms too long hanging past the knees, smooth featureless tilted head with a single dark sunken eye, tattered burial shawl around the waist, standing in an uneasy broken stance, $STYLE" "768x1344" || exit 1
edit "hollow_telegraph" "hollow_base" "same creature, same palette, same painterly style, same flat solid uniform medium gray background, same side profile facing right: crouched attack windup leaning far back with coiled tension, long arms dragging behind, chest hollow gaping, head lowered" "768x1344"
edit "hollow_lunge" "hollow_base" "same creature, same palette, same painterly style, same flat solid uniform medium gray background, same side profile facing right: full desperate lunge stretched horizontally forward through the air, arms reaching ahead, legs trailing, burial shawl streaming behind" "768x1344"

gen "censor_base" "2D game enemy character art of THE CENSOR: reality correction given a body, an impossible authoritative entity shaped like a walking vertical redaction bar, a tall narrow monolith of matte absolute black that erases the space it occupies, a single horizontal band of bone-white parchment strikethrough crossing where a face would be, thin scanning line of crimson light crossing the body, faint cold-cyan glitch afterimage edges flickering along its outline, ritual sigils etched faintly near its base, standing impossibly still and vertical, dark gothic horror 2D game art, hand-painted digital illustration, muted desaturated palette of charcoal, bone white and desaturated steel with restrained crimson and cold cyan accents, painterly brush texture, full body in frame, side profile view facing right, character centered, isolated on a flat solid uniform medium gray background, no ground shadow, no text, no watermark" "768x1344" || exit 1

gen "believer_kneel" "2D game enemy character art of A BELIEVER: an institutional religious functionary of a purpose-faith civilization, kneeling in permanent chant, body wrapped in a heavy dark violet-brown standard-issue ritual robe with a gold measuring-line insignia stitched down the front, deep hood completely hiding the face in shadow, both hands holding a small hanging iron censer swung forward on a short chain with a dim ember glow and a thin thread of smoke, social uniformity, obedient posture, $STYLE" "768x1344" || exit 1
edit "believer_stand" "believer_kneel" "same character, same robe and hood, same censer, same palette, same painterly style, same flat solid uniform medium gray background, same side profile facing right: now standing and walking forward mid-stride, censer held at hip level, robe hem swinging with the step" "768x1344"
edit "believer_strike" "believer_kneel" "same character, same robe and hood, same censer, same palette, same painterly style, same flat solid uniform medium gray background, same side profile facing right: aggressive strike pose, arm swung wide with the censer flail extended after a horizontal blow, robe flaring, body committed forward" "768x1344"

gen "penitent_base" "2D game character art of THE PENITENT: a tall ancient figure predating the player, wrapped head to toe in a ragged bone-white burial shroud stained with old ash and dark residue, the hood completely empty with only darkness inside, roped bindings of dark cord crossing the chest and arms marking centuries of self-inflicted penance, one hand barely visible holding a small closed black ledger bound shut with cord, posture aged tired and slightly stooped, it flickers faintly like something not fully real, $STYLE" "768x1344" || exit 1

gen "oren_base" "2D game character art of MEASURER OREN: an institutional clerk-priest, medium build, standing behind an unseen desk, dark slate-violet heavy clerical robe with a faded gold measuring-line stole of office down the front, flat wide-brimmed measuring cap, the face hidden by a large round brass measuring lens on an armature where eyes would be with a faint cyan glow in the glass, one hand holding a heavy lead stamp mid-motion over a thick ledger, patient bureaucratic demeanor, $STYLE" "768x1344" || exit 1

gen "nullchild_base" "2D game enemy character art of A NULL CHILD: an unfiled child-like entity outside classification, a small pale unfinished figure of bone-white skin with an incomplete face like a filing error, two eye gaps that do not align, one arm ending in a smooth stump where the record stopped, lower body dissolving into unfinished sketchy static like an unrendered asset, faint cold-cyan glitch offset ghosting beside it, disturbing incomplete identity, $STYLE" "768x1344" || exit 1
fi

# ============================================== ENVIRONMENT / PROPS (P2/P3)
if [ -n "$ENV" ]; then
gen "tex_stone" "seamless tileable texture of ancient dark gothic stone masonry wall, heavy eroded ashlar blocks with deep mortar gaps, cracks, soot stains and ash residue, dirty stone gray-brown desaturated palette, painterly hand-painted game texture, flat even lighting, tileable on all edges, no text, no watermark" "1024x1024" || exit 1
gen "tex_metal" "seamless tileable texture of ancient dark riveted iron industrial plating, heavy oxidized steel plates with rivet rows, rust streaks, engraved faded ritual glyph lines between plates, desaturated steel and dark brown palette, painterly hand-painted game texture, flat even lighting, tileable on all edges, no text, no watermark" "1024x1024" || exit 1
gen "prop_door" "2D game prop art of a heavy manufactured iron ritual door set into a gothic stone frame, tall arched double door of dark riveted iron covered in faded gold measuring-line sigils and a single large crimson wax seal stamped across the seam, closed, seen straight on from the front, painterly hand-painted, muted palette of charcoal, desaturated steel, bone and muted gold accents, isolated on a flat solid uniform medium gray background, no text, no watermark" "864x1152" || exit 1
gen "prop_anchor" "2D game prop art of an ANCHOR shrine: a small wayside gothic reliquary shrine of dark iron and stone, a narrow pointed reliquary cabinet with a dim gold votive flame burning inside behind a small barred window, ash caked at its base, a single kneeling rail in front, ritual measuring-line sigils etched on the panels, painterly hand-painted, muted palette, isolated on a flat solid uniform medium gray background, no text, no watermark" "864x1152" || exit 1
gen "prop_terminal" "2D game prop art of an ancient archive terminal: an altar-like record machine of dark iron and aged brass integrated into gothic architecture, a slanted reading surface with a single large round cold-cyan glowing lens, punch-card slots, levers and dials, ritual engravings, cables running down into the base, painterly hand-painted, muted palette with cold cyan glow accent, isolated on a flat solid uniform medium gray background, no text, no watermark" "864x1152" || exit 1
fi

echo "PHASE DONE: $1"
