"use client";

import { useEffect, useRef, useState, type ReactNode } from "react";
import { AnimatePresence, MotionConfig, motion } from "framer-motion";
import { toast } from "sonner";
import { Badge } from "@/components/ui/badge";
import { Button } from "@/components/ui/button";
import {
  Card,
  CardContent,
  CardDescription,
  CardHeader,
  CardTitle,
} from "@/components/ui/card";
import { Tabs, TabsContent, TabsList, TabsTrigger } from "@/components/ui/tabs";
import {
  Table,
  TableBody,
  TableCell,
  TableHead,
  TableHeader,
  TableRow,
} from "@/components/ui/table";
import {
  AlertTriangle,
  ArrowDown,
  ArrowDownToLine,
  Eye,
  EyeOff,
  FileText,
  FolderArchive,
  Ghost,
  HeartCrack,
  Loader2,
  Lock,
  MessagesSquare,
  MonitorPlay,
  RotateCcw,
  ScanEye,
  Send,
  Users,
  X,
} from "lucide-react";

/* ---------------------------------------------------------------------------
 * ENTITY_000 — delivery hub page styles (scoped via e0- prefix)
 * ------------------------------------------------------------------------- */

const PAGE_STYLES = `
.e0-serif { font-family: var(--font-serif-display), Georgia, 'Times New Roman', serif; }

@keyframes e0-flicker-a {
  0%, 84.9%, 92.1%, 100% { opacity: 0; transform: none; clip-path: inset(0 0 0 0); }
  85%   { opacity: 0.55; transform: translate(-4px, 1px); clip-path: inset(8% 0 58% 0); }
  87%   { opacity: 0.25; transform: translate(3px, -1px); clip-path: inset(62% 0 6% 0); }
  89%   { opacity: 0.45; transform: translate(-2px, 0);   clip-path: inset(34% 0 42% 0); }
  91%   { opacity: 0.18; transform: translate(2px, 1px);  clip-path: inset(70% 0 4% 0); }
}
@keyframes e0-flicker-b {
  0%, 55.9%, 61.1%, 100% { opacity: 0; transform: none; clip-path: inset(0 0 0 0); }
  56%   { opacity: 0.30; transform: translate(3px, -1px); clip-path: inset(48% 0 22% 0); }
  58%   { opacity: 0.14; transform: translate(-3px, 0);   clip-path: inset(12% 0 66% 0); }
  60%   { opacity: 0.26; transform: translate(1px, 1px);  clip-path: inset(76% 0 2% 0); }
}
.e0-glitch { position: absolute; inset: 0; pointer-events: none; user-select: none; }
.e0-glitch--crimson { color: #83322b; animation: e0-flicker-a 9.5s linear infinite; }
.e0-glitch--cyan    { color: #7fd8d8; animation: e0-flicker-b 14s linear   infinite; }

.e0-scroll { scrollbar-width: thin; scrollbar-color: #4a463f #0d0d0f; }
.e0-scroll::-webkit-scrollbar { width: 8px; height: 8px; }
.e0-scroll::-webkit-scrollbar-track { background: #0d0d0f; }
.e0-scroll::-webkit-scrollbar-thumb { background: #2b2b2e; border-radius: 2px; }
.e0-scroll::-webkit-scrollbar-thumb:hover { background: #4a463f; }

@media (prefers-reduced-motion: reduce) {
  .e0-glitch--crimson, .e0-glitch--cyan { animation: none; opacity: 0; }
}

/* The Archivist chat */
@keyframes e0-ink-dot {
  0%, 60%, 100% { transform: translateY(0); opacity: 0.35; }
  30% { transform: translateY(-3px); opacity: 1; }
}
.e0-ink-dot { animation: e0-ink-dot 1.1s ease-in-out infinite; }
.e0-ink-dot:nth-child(2) { animation-delay: 0.18s; }
.e0-ink-dot:nth-child(3) { animation-delay: 0.36s; }
@keyframes e0-archivist-beckon {
  0%, 100% { box-shadow: 0 0 0 0 rgba(176, 141, 62, 0); }
  50% { box-shadow: 0 0 0 7px rgba(176, 141, 62, 0.14); }
}
.e0-archivist-beckon { animation: e0-archivist-beckon 2.6s ease-in-out infinite; }
@media (prefers-reduced-motion: reduce) {
  .e0-ink-dot, .e0-archivist-beckon { animation: none; }
}
`;

/* ---------------------------------------------------------------------------
 * Data
 * ------------------------------------------------------------------------- */

const HERO_BADGES = [
  "NATIVE GODOT 4.4+",
  "GDSCRIPT",
  "VERTICAL SLICE",
  "15–30 MIN",
] as const;

const ACTS = [
  {
    n: 1,
    name: "THE VESSEL CHAMBER",
    desc: "Awakening. No name, no history. Only: RESTORE THE WORLD.",
  },
  {
    n: 2,
    name: "THE FIRST DOOR",
    desc: "A dead terminal installs OBSERVE. You break your first rule.",
  },
  {
    n: 3,
    name: "THE CITY OF ASH",
    desc: "Procession street. Faceless statues. The Hollow.",
  },
  {
    n: 4,
    name: "THE CONTRADICTION",
    desc: "A corridor that is wrong. Null Children.",
  },
  {
    n: 5,
    name: "THE CHAPEL OF THE PALE SAINT",
    desc: "Believers chant a ward into existence. Belief is physics.",
  },
  {
    n: 6,
    name: "THE WATCHING",
    desc: "The system addresses you directly. Corrections. The Archive.",
  },
  {
    n: 7,
    name: "THE ENGINE SANCTUM",
    desc: "Where religion and machinery are indistinguishable. The Alignment Puzzle.",
  },
  {
    n: 8,
    name: "THE BOUND MARTYR",
    desc: "Suffering became purpose.",
  },
  {
    n: 9,
    name: "AFTERMATH",
    desc: "A question, not an answer.",
  },
] as const;

const FUNDAMENTALS = [
  {
    name: "PURPOSE",
    quote: "Everything that exists must have a purpose — the law of the City of Ash.",
  },
  {
    name: "BELIEF",
    quote:
      "Collective belief is a physical force. Wards, blessings, and shields exist only while they are believed.",
  },
  {
    name: "MEMORY",
    quote: "Memory can be found, corrupted, and contradicted.",
  },
  {
    name: "IDENTITY",
    quote: "ENTITY_000_818. You are not the first.",
  },
  {
    name: "CONSISTENCY",
    quote: "Reality manipulation is power. Broken reality hunts back.",
  },
] as const;

const CONSISTENCY_STAGES = [
  {
    range: "100–86",
    stage: "WHISPERS",
    danger: 0,
    response: "Doubt at the edge of hearing. The world suspects nothing — yet.",
  },
  {
    range: "85–71",
    stage: "ENVIRONMENTAL INCONSISTENCIES",
    danger: 0,
    response:
      "Architecture repeats. A block slips out of true. Small wrongs accumulate.",
  },
  {
    range: "70–56",
    stage: "NPC AWARENESS",
    danger: 1,
    response:
      "They notice you noticing. Oren feels the audit. The system keeps records about you.",
  },
  {
    range: "55–41",
    stage: "THE CENSOR HUNTS YOU",
    danger: 2,
    response:
      "Correction takes form. It does not chase. It arrives — and it cannot be fought.",
  },
  {
    range: "40–21",
    stage: "REALITY ACTIVELY HUNTS",
    danger: 2,
    response:
      "Corrections spawn near you. Geometry tears. The city files its objections in person.",
  },
  {
    range: "≤ 20",
    stage: "HIDDEN STRUCTURES",
    danger: 2,
    response:
      "The City shows its seams. Unlisted structures become visible. Reality tears along the old folds.",
  },
] as const;

/* ---------------------------------------------------------------------------
 * Visual reconstruction proofs (17 gameplay renders) + visual pass 2 (painted
 * decor) + visual pass 3 (animation enrichment)
 * ------------------------------------------------------------------------- */

type ProofStatus = "FINAL" | "IMPROVED PROCEDURAL" | "TEMPORARY" | "PLACEHOLDER";

const PROOF_STATUS_STYLE: Record<ProofStatus, string> = {
  FINAL: "border-[#b08d3e]/60 text-[#b08d3e]",
  "IMPROVED PROCEDURAL": "border-[#a89f8c]/60 text-[#a89f8c]",
  TEMPORARY: "border-[#83322b]/70 text-[#83322b]",
  PLACEHOLDER: "border-[#4a463f] text-[#857d6c]",
};

const VISUAL_PROOFS: {
  file: string;
  num: string;
  title: string;
  caption: string;
  status: ProofStatus;
}[] = [
  {
    file: "01_player_gameplay",
    num: "01",
    title: "ENTITY_000_818 — the vessel",
    caption:
      "Painted sprite rig: idle / walk / jump / fall / 3-hit chain / roll / hurt / death / interact / observe.",
    status: "FINAL",
  },
  {
    file: "02_hollow",
    num: "02",
    title: "THE HOLLOW",
    caption:
      "The emptied remainder — patrol, stalk, telegraphed lunge; two-frame breathing idle.",
    status: "FINAL",
  },
  {
    file: "03_believers",
    num: "03",
    title: "THE BELIEVERS",
    caption:
      "Institutional functionaries of the purpose-faith — now with a four-frame shuffling walk cycle.",
    status: "FINAL",
  },
  {
    file: "04_censor",
    num: "04",
    title: "THE CENSOR",
    caption:
      "Reality correction given a body. It does not chase. It arrives. Three-frame uncanny sway.",
    status: "FINAL",
  },
  {
    file: "05_martyr_p1",
    num: "05",
    title: "THE BOUND MARTYR — PHASE I",
    caption: "Bound sweeps behind a belief shield of chanting censer-bearers.",
    status: "FINAL",
  },
  {
    file: "06_martyr_p2",
    num: "06",
    title: "THE BOUND MARTYR — PHASE II",
    caption: "FERVOR: the arena contracts, the seams burn, consistency drains.",
    status: "FINAL",
  },
  {
    file: "07_martyr_p3",
    num: "07",
    title: "THE BOUND MARTYR — PHASE III",
    caption: "Unchained. The halo dims to violet. He no longer believes.",
    status: "FINAL",
  },
  {
    file: "08_penitent",
    num: "08",
    title: "THE PENITENT",
    caption:
      "It existed before you. It remembers what you do not. Two-frame ghost flicker.",
    status: "FINAL",
  },
  {
    file: "09_city_of_ash",
    num: "09",
    title: "THE CITY OF ASH",
    caption: "Act III — the procession street under permanent ashfall.",
    status: "FINAL",
  },
  {
    file: "10_chapel",
    num: "10",
    title: "THE CHAPEL OF THE PALE SAINT",
    caption: "Act V — belief made architecture, ward made light.",
    status: "FINAL",
  },
  {
    file: "11_archive",
    num: "11",
    title: "THE ARCHIVE",
    caption: "Act VI — the watching stacks, the contradiction kept on file.",
    status: "FINAL",
  },
  {
    file: "12_engine_sanctum",
    num: "12",
    title: "THE ENGINE SANCTUM",
    caption: "Act VII — the Heart of the Design. Grown, not built.",
    status: "FINAL",
  },
  {
    file: "13_colonnade",
    num: "13",
    title: "THE COLONNADE",
    caption:
      "Visual pass 2 — painted columns assembled from capital / shaft / plinth strips; any height, one texture.",
    status: "FINAL",
  },
  {
    file: "14_sanctuary",
    num: "14",
    title: "THE SANCTUARY",
    caption:
      "Visual pass 2 — hanging censer, framed mural of the eleven saints, kneeling penitent statue. Grounded with contact shadows.",
    status: "FINAL",
  },
  {
    file: "15_machines",
    num: "15",
    title: "THE RELIQUARY ENGINES",
    caption:
      "Visual pass 2 — painted machine bodies with live procedural instrumentation (cycling gauges, fault lights) over them.",
    status: "FINAL",
  },
  {
    file: "16_measurer_oren",
    num: "16",
    title: "MEASURER OREN",
    caption:
      "Visual pass 3 — the clerk-priest of the queue. Two-frame bureaucratic micro-bow over his ledger.",
    status: "FINAL",
  },
  {
    file: "17_null_children",
    num: "17",
    title: "THE NULL CHILDREN",
    caption:
      "Visual pass 3 — unfiled children outside classification. Three-frame glitch flicker, VHS slice displacement.",
    status: "FINAL",
  },
  {
    file: "18_room_card",
    num: "18",
    title: "ACT ENTRY CARD",
    caption:
      "Presentation pass — every act opens with a cinematic serif title card; system lines and the objective wait their turn.",
    status: "FINAL",
  },
  {
    file: "19_boss_intro",
    num: "19",
    title: "THE MARTYR NAMED",
    caption:
      "Presentation pass — the boss reveal: letterbox bars, glitched serif designation, roar and ash burst.",
    status: "FINAL",
  },
  {
    file: "20_atmosphere",
    num: "20",
    title: "THE AIR ITSELF",
    caption:
      "Presentation pass — living atmosphere: foreground ashfall, drifting dust motes, floor mist, rubble-dressed floors.",
    status: "FINAL",
  },
  {
    file: "21_depth",
    num: "21",
    title: "THE MIDDLE DISTANCE",
    caption:
      "Comfort & depth pass — a mid-ground silhouette plane (rooftops, poles, monoliths) parallaxing at half camera speed between the painted backdrop and the play floor.",
    status: "FINAL",
  },
  {
    file: "22_options",
    num: "22",
    title: "WHAT THE VESSEL MAY KEEP",
    caption:
      "Comfort & depth pass — the options overlay: master/music/ambience/effects volumes, screen shake, gamepad vibration, dialogue ticks, artwork mode, save erasure — persisted to user://settings.json.",
    status: "FINAL",
  },
  {
    file: "23_records",
    num: "23",
    title: "THE RECORD KEEPS WHAT YOU READ",
    caption:
      "Control & records pass — the pause codex: every entity OBSERVE has landed on becomes a permanent record (designation, type, memory line), tabbed with the fragment index, scrollable, persisted through saves.",
    status: "FINAL",
  },,
  {
    file: "wb4_01_city_procession",
    num: "24",
    title: "THE FAR PROCESSION",
    caption:
      "Funeral wagon and lantern-puller cross the backdrop's own street line; pilgrim lines bear a bier; ash-wraith birds leave motion wakes. The far city lives.",
    status: "FINAL",
  },
  {
    file: "wb4_03_telegraph_ring",
    num: "25",
    title: "THE GOLDEN SEAL",
    caption:
      "Enemy wind-ups now carry a tightening ring with cardinal ticks — the wound card lands once per strike; combat reads across the room.",
    status: "FINAL",
  },
  {
    file: "wb4_04b_strike",
    num: "26",
    title: "THE STRIKE, MEASURED",
    caption:
      "Attack anticipation squash releases into overshoot — 70ms of wind-up weight before the blade commits.",
    status: "FINAL",
  },
  {
    file: "wb4_05a_roll_tumble",
    num: "27",
    title: "THE ROLL, TRULY TUMBLING",
    caption:
      "A 4-frame pivot about the ball of the foot replaces a sliding sprite swap — the engraved line survives the rotation.",
    status: "FINAL",
  },
  {
    file: "wb4_06a_oren_bow",
    num: "28",
    title: "OREN BOWS",
    caption:
      "The Measurer's 4-frame bow cycle — the counter-swing of a body that has greeted ten thousand vessels.",
    status: "FINAL",
  },
  {
    file: "wb4_08_kneel_breath",
    num: "29",
    title: "BELIEVERS BREATHE",
    caption:
      "Prayer breath and a six-walk for the faithful — the chapel's congregation is alive between attacks.",
    status: "FINAL",
  },
  {
    file: "wb4_11_anchor_ceremony",
    num: "30",
    title: "ANCHOR COMMUNION",
    caption:
      "Saving at an anchor now performs: double golden floor ripple, rising record-glyph motes — a ceremony, not a menu.",
    status: "FINAL",
  },
  {
    file: "wb4_12_observe_zoom",
    num: "31",
    title: "THE LENS LEANS IN",
    caption:
      "Camera zoom punch on OBSERVE (1.07) and death loom (1.14), eased release — the frame itself is now directed.",
    status: "FINAL",
  },
  {
    file: "wb5_01_city_closest_walls",
    num: "32",
    title: "THE CLOSEST WALLS",
    caption:
      "A foreground plane at 1.28x camera speed — shingles, rags, censers, page curtains — the missing front slice of the depth sandwich.",
    status: "FINAL",
  },
  {
    file: "wb5_02b_slide_late",
    num: "33",
    title: "FOREGROUND SLIDES",
    caption:
      "Near-camera silhouettes pass at their own speed: chain sway, cable sag-breath, rag flutter, sign creak — never a frozen stamp.",
    status: "FINAL",
  },
  {
    file: "wb5_03_womb_sky_band",
    num: "34",
    title: "THE WOMB'S CABLES",
    caption:
      "Per-district foreground recipes: womb cables and shrouds hang above, capped by the act1 sky-band law.",
    status: "FINAL",
  },
  {
    file: "wb5_04_undercity_grates",
    num: "35",
    title: "UNDERCITY GRATES",
    caption:
      "Iron grates and dead lamps pass close in the dark — placement is law: no hang over doors, anchors, NPCs or the boss arena.",
    status: "FINAL",
  },
  {
    file: "wb5_07_archive_pages",
    num: "36",
    title: "ARCHIVE PAGE-FALL",
    caption:
      "Falling page fields and shelf-ends drift at the near plane; parchment rims keep the engraved hand.",
    status: "FINAL",
  },
  {
    file: "wb5_11_censor_unfurl",
    num: "37",
    title: "THE CENSOR UNFURLS",
    caption:
      "Arrival is a 4-frame vertical unfurl about the feet anchor with fading cyan assembly ghosts — and a shed-record page trail.",
    status: "FINAL",
  },
  {
    file: "wb5_05_null_walk",
    num: "38",
    title: "NULL CHILDREN GLITCH-STEP",
    caption:
      "A 4-frame lean/pass cycle with alternating phase ghosts; velocity drives the pose switch — broken things move wrongly.",
    status: "FINAL",
  },
  {
    file: "wb5_09_reliquary_arena",
    num: "39",
    title: "RELIQUARY, CAGE-CLEAR",
    caption:
      "The arena stays clear at ±430px; ghost-defocus halos stop the near plane from hard-cutting the eye.",
    status: "FINAL",
  },
  {
    file: "wb6_01_climb_ledges",
    num: "40",
    title: "THE INVISIBLE STAIR, RENDERED",
    caption:
      "Every climb platform in the game was collision-only — black voids where ledges should be. Now: block bodies, dressed tops, corbel brackets mounting each slab to the wall.",
    status: "FINAL",
  },
  {
    file: "wb6_01b_on_the_ledge",
    num: "41",
    title: "STANDING ON MASONRY",
    caption:
      "The act1 ascent is a staircase you can finally SEE — the audit's 'black voids' were the missing ledges.",
    status: "FINAL",
  },
  {
    file: "wb6_04_chapel_carpet",
    num: "42",
    title: "THE WOVEN RUNNER",
    caption:
      "Chapel floor: crimson runner with studded double gold borders, thread bands, mosaic tessera edges, threadbare spots worn by knees.",
    status: "FINAL",
  },
  {
    file: "wb6_05_undercity_damp",
    num: "43",
    title: "UNDERCITY DAMP",
    caption:
      "Damp stains, slotted drainage grates with a wet slot catching the light, moss in the joints — the water table is real.",
    status: "FINAL",
  },
  {
    file: "wb6_06_archive_pages",
    num: "44",
    title: "THE FALLEN RECORDS",
    caption:
      "Bright parchment pages with catching edges, filed lines, folded corners, spilled stacks and ink stains underfoot.",
    status: "FINAL",
  },
  {
    file: "wb6_07_engine_plates",
    num: "45",
    title: "ENGINE PLATING",
    caption:
      "Steel plate ground with hazard chevrons and oil sheen; bolted base plates anchor the machines.",
    status: "FINAL",
  },
  {
    file: "wb6_08_heart_dried",
    num: "46",
    title: "THE HEART, DRIED",
    caption:
      "Chamber re-graded to dried-blood crimson with an inner violet-cold core pulse — desaturation as anatomy.",
    status: "FINAL",
  },
  {
    file: "wb6_09_reliquary_inlay",
    num: "47",
    title: "RELIQUARY SWEEP-POLISH",
    caption:
      "Swept-pale polish with gold seam inlays — a floor maintained by belief.",
    status: "FINAL",
  },
  {
    file: "wb6_10_aftermath_broken",
    num: "48",
    title: "AFTERMATH, CRACKED",
    caption:
      "Cracked slabs, dark ember-flecked ash drifts, rubble — the ground remembers what happened here.",
    status: "FINAL",
  },
  {
    file: "wb7_01_hollow_walk",
    num: "49",
    title: "THE HOLLOW WALKS",
    caption:
      "The game's most-fought enemy PATROLLED BY SLIDING no more: bold stride law (±8 leg-band shear on a 43px body), bob, counter-swing arms, forward lean.",
    status: "FINAL",
  },
  {
    file: "wb7_03_strike_woundcard",
    num: "50",
    title: "THE WOUND CARD",
    caption:
      "Three bone-white arcs opening into the push direction, hot core flash, spark ticks, crimson verdict ring on the chain finisher.",
    status: "FINAL",
  },
  {
    file: "wb7_05c_death_goingdown",
    num: "51",
    title: "DEATH IS A PERFORMANCE",
    caption:
      "True rotation about the feet — stun, buckle, going-down, prone. NO squash-scaling; the engraved line survives. The corpse keeps the killing blow's momentum.",
    status: "FINAL",
  },
  {
    file: "wb7_06_oren_talk",
    num: "52",
    title: "OREN SPEAKS",
    caption:
      "Head band bob and torso lean accents on a body that never leaves its post — dialogue is physical.",
    status: "FINAL",
  },
  {
    file: "wb7_07_believers_prayer",
    num: "53",
    title: "THE CONGREGATION",
    caption:
      "Kneel breath deepens through the phases; hurt recoils; death is knees, slump, still.",
    status: "FINAL",
  },
  {
    file: "wb7_08_boss_sway",
    num: "54",
    title: "THE MARTYR STRAINS",
    caption:
      "Sway about the hanging point with strain SAG scaled about the top — feet rise as the weight wins. The halo never clips.",
    status: "FINAL",
  },
  {
    file: "wb7_09_presence_pools",
    num: "55",
    title: "PRESENCE",
    caption:
      "Every actor stands in its own tinted pool; the vessel carries a bone-gold aura breathing above every world layer — the protagonist is the brightest local focal, measured.",
    status: "FINAL",
  },
  {
    file: "wb7_10_readability",
    num: "56",
    title: "READABILITY, MEASURED",
    caption:
      "Player zone +37% brightness vs background: rim .56, aura, pool, lift — four separation mechanisms, zoom-confirmed.",
    status: "FINAL",
  },
  {
    file: "wb8_01_the_marriage",
    num: "57",
    title: "THE WALL-FLOOR MARRIAGE",
    caption:
      "Every wall now carries a footing course of facing stones — projecting cornice lip, wall AO above, chipped corners, district trim.",
    status: "FINAL",
  },
  {
    file: "wb8_02_ground_answers_fire",
    num: "58",
    title: "THE GROUND ANSWERS FIRE",
    caption:
      "A real production bug found by audit: floor light pools were buried under the floor slabs. Now: wide dancing pools that wobble with each flame, hot cores, sheen lines, cone smears.",
    status: "FINAL",
  },
  {
    file: "wb8_03_focal_shaft",
    num: "59",
    title: "FOCAL SHAFTS",
    caption:
      "God-ray presets for the dark districts — wide, slanted, strong cold grate-light below; pale ash-sky gaps between roofs above.",
    status: "FINAL",
  },
  {
    file: "wb8_04a_moths_settled",
    num: "60",
    title: "MOTHS, SETTLED",
    caption:
      "Lazy Lissajous orbits around every living flame, wing-triangle flutter, 2-4 per flame by flicker.",
    status: "FINAL",
  },
  {
    file: "wb8_04b_moths_scattered",
    num: "61",
    title: "MOTHS, SCATTERED",
    caption:
      "The flock BURSTS from a passing body and resettles as the air stills — the world notices you.",
    status: "FINAL",
  },
  {
    file: "wb8_05b_vermin_flee",
    num: "62",
    title: "ASH-VERMIN FLEE",
    caption:
      "Bone-pale rats with crimson eye-glints patrol the back edge; within 150px they flee — body stretched, tail arched, legs blurred.",
    status: "FINAL",
  },
  {
    file: "wb8_06_ripple",
    num: "63",
    title: "THE WEEP SPOTS",
    caption:
      "Boots landing in the undercity's weep spots raise expanding double ripples with a soft water-glow and bright droplets.",
    status: "FINAL",
  },
  {
    file: "wb8_07_posted_law",
    num: "64",
    title: "THE POSTED LAW",
    caption:
      "Law reads as a posted THING: aged parchment face, torn bottom, iron nails with rust weeping, crimson wax seal, rain streaks, hang-tilt.",
    status: "FINAL",
  },
  {
    file: "wb8_08_reliquary_goldline",
    num: "65",
    title: "RELIQUARY GOLD SEAM",
    caption:
      "Archways open into deep shadowed interiors with light breathing inside; statues re-carved as dark weathered stone with gold-leaf accents.",
    status: "FINAL",
  },
  {
    file: "wb8_05a_vermin_patrol",
    num: "66",
    title: "A CARVED UNIVERSE",
    caption:
      "Final district audit: city A / chapel A- / archive A- / reliquary B / aftermath A- / undercity A / womb B+ — 'the world feels CARVED rather than pasted'.",
    status: "FINAL",
  },
  {
    file: "wb9_01_instrument",
    num: "67",
    title: "THE VESSEL INSTRUMENT",
    caption:
      "The HUD is now a brass instrument cluster: beveled housing, brushed strokes, corner screws, an engraved maker's line — manufactured by the Census Division.",
    status: "FINAL",
  },
  {
    file: "wb9_02_instrument_wounded",
    num: "68",
    title: "THE GLASS CRACKS",
    caption:
      "Integrity lives in a glass tube: bone-bright fluid, meniscus, rising bubbles, crimson drain-lag — and the glass WEBS when the vessel fails.",
    status: "FINAL",
  },
  {
    file: "wb9_03_needle_edge",
    num: "69",
    title: "THE NEEDLE AT THE EDGE",
    caption:
      "Consistency reads off a needle dial — engraved arc, end stops, hub screw. At S5 the hand trembles and the verdict LIT brightens: a diegetic instrument never fails to inform.",
    status: "FINAL",
  },
  {
    file: "wb9_04_record_speaks",
    num: "70",
    title: "THE CENSUS RECORD SPEAKS",
    caption:
      "Dialogue arrives on a hung parchment sheet: grain, aged edges, filing holes, torn bottom; the speaker's seal is PRESSED into wax as it seats; the line is written in dark ink over ledger ruling.",
    status: "FINAL",
  },
  {
    file: "wb9_05_filing",
    num: "71",
    title: "FILE [F]",
    caption:
      "The record's last line holds a clerk's stamp — FILE [F] — a hair askew like a hand-struck die. Dialogue is a document, not a subtitle.",
    status: "FINAL",
  },
  {
    file: "wb9_06_objections",
    num: "72",
    title: "STAMPED CITATIONS",
    caption:
      "System messages STRIKE in as paper slips: the die lands at 1.4x and settles with a wobble, each slip torn, grain-ruled, a hair askew; danger citations carry a pressed crimson fragment.",
    status: "FINAL",
  },
  {
    file: "wb9_07_ledger",
    num: "73",
    title: "THE LEDGER",
    caption:
      "The OBSERVE readout is a page of the census record book: parchment stock, punched filing holes, ruled fields — no dot-leader mush, values in dark archival ink.",
    status: "FINAL",
  },
  {
    file: "wb9_08_sealed_rows",
    num: "74",
    title: "SEALED UNDER WAX",
    caption:
      "Hidden properties hide under PRESSED WAX — one seal per sealed row, count pinned to data. Reality thinning cracks them open.",
    status: "FINAL",
  },
  {
    file: "wb9_09_receipt",
    num: "75",
    title: "THE RECEIPT",
    caption:
      "A modification answer is FILED loudly: a bright chit, heavy ink, a ruling under each line — '> MODIFY → locked=false / ACK. THE WORLD OBEYS. / CONSISTENCY −6'.",
    status: "FINAL",
  },
  {
    file: "wb9_10_plaque",
    num: "76",
    title: "THE PLAQUE",
    caption:
      "The interact prompt is census property: a brass plaque, an engraved key-cap die, the verb etched in metal, a riveted serial tag — INQ property answers to whoever holds the key.",
    status: "FINAL",
  },
  {
    file: "wb10_01_womb_sound_map",
    num: "77",
    title: "THE SOUND MAP, WOMB",
    caption:
      "THE AIR ITSELF — the aural atmosphere pass. A new SoundScape hangs positional emitters on every noise-making element the craft passes placed; the debug map shows breathing gold halos inside faint 640px hearing rings.",
    status: "FINAL",
  },
  {
    file: "wb10_02_undercity_drip_arcs",
    num: "78",
    title: "THE DRIP VOICES",
    caption:
      "Every undercity damp spot keeps its own drip voice; cyan countdown arcs are the timed voices (bells, chains, gusts) on their own seeded clocks — sound placed on the elements, not in a bed.",
    status: "FINAL",
  },
  {
    file: "wb10_03_city_far_field",
    num: "79",
    title: "THE FAR FIELD SPEAKS RARELY",
    caption:
      "Per-district far-field palettes — distant bell tolls, wind gusts, choir swells, far machine clanks with echo — on a bounded no-hurry scheduler. The city is heard, never crowded.",
    status: "FINAL",
  },
  {
    file: "wb10_04_chapel_eleven_flames",
    num: "80",
    title: "ELEVEN FLAMES SPEAK",
    caption:
      "Braziers, candles, candelabra, censers and chandeliers crackle from their own flames (warm-light dedupe law: 110px); VLM-accepted placement 'highly accurate' at B+.",
    status: "FINAL",
  },
  {
    file: "wb10_05_engine_the_heart_hums",
    num: "81",
    title: "THE HEART HUMS",
    caption:
      "Machines, rotors and the great heart hum from their bolts; vents hiss at their mouths. The room's air is now a stack of up to three beds (A primary / B secondary / C deep).",
    status: "FINAL",
  },
  {
    file: "wb10_06_reliquary_bell_and_chains",
    num: "82",
    title: "THE BELL AND THE CHAINS",
    caption:
      "Bells toll and chains creak on their own seeded timers in the reliquary; the dread law rises with the HUNTED stages while the world's air muffles faster than the score — the whispers stay sharp.",
    status: "FINAL",
  },
  {
    file: "wb11_01_womb_dark",
    num: "83",
    title: "BORN DARK",
    caption:
      "THE ARRIVAL — no space is born pre-lit. On first visit the room waits as dying embers (0.16); the air is absent, the grade held dark. The womb is the first room the player ever sees.",
    status: "FINAL",
  },
  {
    file: "wb11_02_womb_catching",
    num: "84",
    title: "THE CATCH",
    caption:
      "Sources gutter in their last 0.12s as the catch gathers, then FLARE to 1.5x and settle to presence — ordered by distance from the vessel's entry plus seeded jitter, so the ground answers the flame in the same breath.",
    status: "FINAL",
  },
  {
    file: "wb11_03_womb_sweep",
    num: "85",
    title: "THE SWEEP",
    caption:
      "The ignition crosses the room near-first — floor pools, fixture wicks and cone smears ride the same factor; the room's matter thickens into existence (motes, mist, ashfall on smoothstep).",
    status: "FINAL",
  },
  {
    file: "wb11_04_womb_awake",
    num: "86",
    title: "SETTLED PRESENCE",
    caption:
      "The room exhaled: the world grade breathes to full presence across the span, the lens eases home from its 1.05 first-glance lean. On a revisit the wake is quick (0.45s) — the city remembers the vessel.",
    status: "FINAL",
  },
  {
    file: "wb11_05_chapel_catching",
    num: "87",
    title: "THE CHAPEL CATCHES, ONE BY ONE",
    caption:
      "The chapel mid-wake: VLM verdict — the progression 'reads one-by-one'. No voice sounds before its place has caught: tick gates hold every bell and chain until its light lives.",
    status: "FINAL",
  },
  {
    file: "wb11_06_chapel_awake",
    num: "88",
    title: "THE CHAPEL, SETTLED",
    caption:
      "Full presence after the sweep: emitters risen from 16dB under their place, beds swelled at the arrival's own pace. Session memory only — each new vessel's rooms wake anew.",
    status: "FINAL",
  },
  {
    file: "wb12_01_chapel_home",
    num: "89",
    title: "HOME",
    caption:
      "THE WORLD THINS — the core mechanic now reaches the world's own renderers. The chapel at stage zero: flames convinced, moths settled, the grade whole.",
    status: "FINAL",
  },
  {
    file: "wb12_02_chapel_thinning",
    num: "90",
    title: "THINNING",
    caption:
      "A smoothed thinning k drifts through its stage targets (0 / .25 / .45 / .70 / 1.0) — never a switch. Every source loses CONVICTION (max −32%, floor 0.68: the play space stays legible).",
    status: "FINAL",
  },
  {
    file: "wb12_03_chapel_thin",
    num: "91",
    title: "FULL THIN",
    caption:
      "Past the 0.55 gate a flame sometimes MISSES A BEAT — a deterministic ~0.31s gutter while its neighbours hold; machine veins only ever dim. Fire gutters, districts fail differently.",
    status: "FINAL",
  },
  {
    file: "wb12_04_moths_leaving",
    num: "92",
    title: "THE EXODUS",
    caption:
      "Every moth carries a staggered nerve (0.25–0.70); past its threshold it flies ONE decisive exit — up-and-out, wings +45%, fading over 1.1s — a wave, never a pop. They RETURN when the world re-asserts.",
    status: "FINAL",
  },
  {
    file: "wb12_05_chapel_vessel_stays_real",
    num: "93",
    title: "THE VESSEL STAYS REAL",
    caption:
      "Scenery luminance drains −10% and 12% toward gray as reality fails — while the vessel, never in the graded set, stays real. The lens fails last: chromatic aberration grows with the thinning.",
    status: "FINAL",
  },
  {
    file: "wb12_06_undercity_home",
    num: "94",
    title: "UNDERCITY, HOME",
    caption:
      "The damp quarter at stage zero — its own weather, its drip voices, the graded whole.",
    status: "FINAL",
  },
  {
    file: "wb12_07_undercity_thin",
    num: "95",
    title: "UNDERCITY, THIN",
    caption:
      "The same quarter thinned: motes dim and slow, the ground haze gathers, the foreground ash falls heavier and straighter — all pure statics of the one thinning value, bidirectional.",
    status: "FINAL",
  },
  {
    file: "wb13_01_leaving_mid_fold",
    num: "96",
    title: "THE LEAVING",
    caption:
      "THE THRESHOLD — the crossing between acts is no longer nothing. The world folds to black (0.9s) while the vessel KEEPS WALKING: three footsteps sound in the dark on the departing district's own floor material, each a little further away.",
    status: "FINAL",
  },
  {
    file: "wb13_02_between_inscribing",
    num: "97",
    title: "THE BETWEEN",
    caption:
      "Full black holds (0.95s) while the census voice INSCRIBES one lore rubric glyph by glyph — letter-spacing easing open as the record's hand widens into certainty, each landing glyph trailing a faint gold echo.",
    status: "FINAL",
  },
  {
    file: "wb13_03_between_risen",
    num: "98",
    title: "THE RUBRIC RISEN",
    caption:
      "The rubric complete: a CENSUS · I → II filing mark, a diamond, a gold rule that grows outward, corner brackets framing the dark page — and exactly ONE distant herald of the arriving space sounds through it.",
    status: "FINAL",
  },
  {
    file: "wb13_04_coming_into_the_wake",
    num: "99",
    title: "THE COMING",
    caption:
      "The fade opens (0.65s) into the new room's own arrival wake — the threshold hands the lens to WB-11's choreography. You hear where you are going before you see it.",
    status: "FINAL",
  },
  {
    file: "wb13_05_settled",
    num: "100",
    title: "SETTLED ACROSS",
    caption:
      "The record does not repeat itself: only the first crossing of a GOLDEN edge is deep — a crossing already in the record is the plain quick fade, and a teleport is not a passage. Eight rubrics, lore-pinned to the readables.",
    status: "FINAL",
  },
  {
    file: "wb14_01_ash_path",
    num: "101",
    title: "THE ASH REMEMBERS",
    caption:
      "THE VESSEL'S TRACE — every floor the vessel crosses records him in its own material. Ash (act3/act9): dark compressions that HOLD 62% of their life then leave.",
    status: "FINAL",
  },
  {
    file: "wb14_02_ash_toe_kick",
    num: "102",
    title: "TOE-KICK PILES",
    caption:
      "Toe-kick piles where the trailing boot pushed; soles are ROUNDED capsules (ball + heel — an impression, never a rectangle), each print staggering and rotating into the direction of travel.",
    status: "FINAL",
  },
  {
    file: "wb14_03_landing_star",
    num: "103",
    title: "THE LANDING'S WITNESS",
    caption:
      "A hard fall leaves both soles pressed into a wide impact bruise with flung clods on bent, hash-seeded chaotic flights — varied lengths, fading alpha ends, stray flecks; never evenly-spaced spokes.",
    status: "FINAL",
  },
  {
    file: "wb14_04_roll_smear",
    num: "104",
    title: "THE ROLL WRITES ONE DRAG",
    caption:
      "The roll writes ONE CONTINUOUS DRAG on roll end — an irregular wash, pressed blotches where the body met the stone (wandering pressure and vertical drift — a tumble, not a slide), a kicked-up pile at the tail.",
    status: "FINAL",
  },
  {
    file: "wb14_05_wet_glisten",
    num: "105",
    title: "WET GLISTEN",
    caption:
      "Wet floors (act2/act4): prints that Glisten bright at the leading edge while young, then DRY to a faint shadow by 55% of life, then leave — the two-mark visibility law: a dark impression wrapped in a bright displaced-material rim.",
    status: "FINAL",
  },
  {
    file: "wb14_06_chapel_nap",
    num: "106",
    title: "THE RUNNER'S NAP",
    caption:
      "Carpet (act5): the runner's nap presses LIGHTER — matte flattened grain that recovers continuously as the room forgets the walker. Inverted marks: light core, dark grain.",
    status: "FINAL",
  },
  {
    file: "wb14_07_page_flutter",
    num: "107",
    title: "THE BOOT THROUGH THE PAGE",
    caption:
      "The archive's spilled records become live litter — a boot through a page kicks it a-flutter: a bright tumbling sheet with its catching edge and a ruled line, ~1s arc, page_rustle at −14dB.",
    status: "FINAL",
  },
  {
    file: "wb14_08_engine_clean",
    num: "108",
    title: "THE ENGINE RECORDS NOTHING",
    caption:
      "Act7's floor is maintained clean; it does not need to count — the census already owns the count. Dust settles subtly (act1/6/8); the ring is a bounded 96-deep path, not a ledger.",
    status: "FINAL",
  },
  {
    file: "wb15_01_two_hands",
    num: "109",
    title: "TWO GAITS, ONE FLOOR",
    caption:
      "THE OTHERS' PASSAGE — the world's memory is not one-sided. Every creature that walks writes the floor in the language of its body: the sole (anatomy), the weight (conviction), the stride, and the variance of the walk.",
    status: "FINAL",
  },
  {
    file: "wb15_02_the_echo",
    num: "110",
    title: "THE HOLLOW'S ECHO",
    caption:
      "Its print IS the vessel's own sole — pressed at 62% conviction, stepped at a METRONOME (variance zero: the same step every step). A copy of a gait, not a gait — what the census left when it took the man out of the walk.",
    status: "FINAL",
  },
  {
    file: "wb15_03_devotion_field",
    num: "111",
    title: "THE KNEE-PRESS STATION",
    caption:
      "Entering chant presses two paired knee ovals and the hem's drag into the runner — a station the vessel never saw kneel is born OLD (pre-aged 6–9s: the devotion predates his arrival; the room was already written before he walked it).",
    status: "FINAL",
  },
  {
    file: "wb15_04_the_shuffle",
    num: "112",
    title: "THE BELIEVER'S SHUFFLE",
    caption:
      "Robed, soft-shod — one narrow rounded mass (cloth, not leather), short quick 24px strides with living irregularity. Harm one and all answer — in cloth.",
    status: "FINAL",
  },
  {
    file: "wb15_05_martyr_weight",
    num: "113",
    title: "THE MARTYR'S WEIGHT",
    caption:
      "The heaviest thing that walks the aftermath — 135% conviction, a wide stance, and every leap lands a wide impact bruise beside its FX.",
    status: "FINAL",
  },
  {
    file: "wb15_06_engine_clean",
    num: "114",
    title: "NOT EVEN FOR ITS OWN",
    caption:
      "Hollows patrol the maintained plating and leave no mark — the engine records nothing, even for its own. The null children drift through walls; the default gait is EMPTY.",
    status: "FINAL",
  },
  {
    file: "wb15_07_the_erasure",
    num: "115",
    title: "THE CENSOR ERASES",
    caption:
      "It does not write itself into the census — its passage blanks a 60px column through whatever was written. It is the correction the census makes.",
    status: "FINAL",
  },
  {
    file: "wb15_08_age_gradient",
    num: "116",
    title: "FRESH READS DARKER",
    caption:
      "Aging stays a pure function, so a fresh trail reads darker than an old one — the floor is information, dread from legibility. One bounded 96-deep ring, whatever walks it.",
    status: "FINAL",
  },
  {
    file: "wb16_01_the_hollows_ending",
    num: "117",
    title: "THE HOLLOW'S ENDING",
    caption:
      "THE ENDING'S RECORD — the census counts even what it strikes out. A body that ends on a floor is the heaviest thing the floor can hold: an ORGANIC SPRAWL in the walker's own weight.",
    status: "FINAL",
  },
  {
    file: "wb16_02_the_sprawl",
    num: "118",
    title: "THE SPRAWL",
    caption:
      "The churn where the feet fought the floor before the weight went; the torso's settled mass — three overlapping soft presses; the head's smaller mass past the leading end; extremity streaks bent and fading where the limbs slid.",
    status: "FINAL",
  },
  {
    file: "wb16_03_the_pool",
    num: "119",
    title: "THE WET POOL",
    caption:
      "The wet pool reads dark and damp while young — a concentrated reflected streak and a sharp catch-light arc at the wettest lip — then dries to a mineral ghost.",
    status: "FINAL",
  },
  {
    file: "wb16_04_the_congregations_ending",
    num: "120",
    title: "THE CONGREGATION'S ENDING",
    caption:
      "Believers end in cloth — the soft-shod mass pressed flat where the devotion stopped. The runner's pressed nap rises slowest of all: ten strides' lives and the press still holds.",
    status: "FINAL",
  },
  {
    file: "wb16_05_the_censors_leaving",
    num: "121",
    title: "THE CORRECTION LEAVES",
    caption:
      "Even the Censor's ending blanks the column where it stood — wider than its passage swept, through prints AND through endings. What survives survives outside the correction.",
    status: "FINAL",
  },
  {
    file: "wb16_06_where_he_fell",
    num: "122",
    title: "WHERE HE FELL",
    caption:
      "The vessel's own death is kept: the fall stamps, his last strides FREEZE mid-path, and the stain files in a session registry — the rebuilt floor wears it when he walks back, born AGED (the crossing back took time), capped at six stains per room.",
    status: "FINAL",
  },
  {
    file: "wb16_07_engine_records_nothing",
    num: "123",
    title: "NOT EVEN ITS DEAD",
    caption:
      "The maintained plating stays pristine under a dissolving body. The null children's deaths write nothing — the drifters were never the floor's to record.",
    status: "FINAL",
  },
  {
    file: "wb16_08_two_endings",
    num: "124",
    title: "THE FLOOR IS NOT A GRAVEYARD",
    caption:
      "The path forgets (the bounded ring, weathering prints) but the ending holds — a separate bounded ledger (the last 8 endings) on the same canvas, drawn UNDER the path so the living walk over the dead.",
    status: "FINAL",
  },
  {
    file: "wb18_01_telegraph",
    num: "125",
    title: "THE WARNING READS FIRST",
    caption:
      "THE FIST THAT LANDS — the motion experience pass. The hollow's telegraph line widened 2px → 4.5px crimson with a hot bone-white core; the body pulses to 0.95 crimson. Re-audit: telegraph 2 → 8.",
    status: "FINAL",
  },
  {
    file: "wb18_02_roll_ghosts",
    num: "126",
    title: "THE ROLL IS A DECISION",
    caption:
      "Three fading afterimage ghosts trail the tumble (45ms path sampling) plus a white flash at the slip's first instant — the re-audit called it 'a gold-standard 2D roll'. Roll 6 → 9.",
    status: "FINAL",
  },
  {
    file: "wb18_03_chain_verdict",
    num: "127",
    title: "THE CHAIN SPEAKS IN ARCS",
    caption:
      "The wound card speaks louder and in three sentences — arc widths 3.4 → 5.4, doubled crimson finisher ring, and each chain hit carries its own arc attitude (high diagonal / flat cut / wide overhead). Hit weight 3 → 8.",
    status: "FINAL",
  },
  {
    file: "wb18_04_phase_break",
    num: "128",
    title: "THE PHASE BREAK",
    caption:
      "The punctuation escalates — hitstop 0.05/0.09 → 0.07/0.115, shake 2/2/4 → 2.2/3.2/5.0, rumble lifted; the hurt read lasts: flash 0.18 → 0.26 burning whiter, knockback 230/−150.",
    status: "FINAL",
  },
  {
    file: "wb18_05_dash_charge",
    num: "129",
    title: "THE CHARGE SPEAKS",
    caption:
      "The boss's dash windup scatters sparks at the feet every 140ms while the halo pulls toward crimson and beats faster, spent clean on launch. Dash crouch 'barely readable' → SEEN.",
    status: "FINAL",
  },
  {
    file: "wb18_06_congregation",
    num: "130",
    title: "THE COUNTER-HIT",
    caption:
      "The believers' windup ring reads before the strike; harm one and all answer — counter-hit 5 → 8 in the honest re-audit of logged clips.",
    status: "FINAL",
  },
  {
    file: "wb19_01_gather",
    num: "131",
    title: "THE GATHER",
    caption:
      "THE THREE BEATS — every hit now carries its own clock. The jump gathers: a 45ms compression before the leave (the squash channel renders it), proven by event-locked strobe stills.",
    status: "FINAL",
  },
  {
    file: "wb19_02_launch",
    num: "132",
    title: "THE LEAVE",
    caption:
      "The gather answered by a launch stretch (0.20 tall, decaying over 0.22s) — the kit's reach untouched: same launch, same arc; the gather only buys the read.",
    status: "FINAL",
  },
  {
    file: "wb19_03_chain_step",
    num: "133",
    title: "THE STEP-THROUGH",
    caption:
      "The cut STEPS THROUGH its strike — a 320px/s surge spent by friction inside the swing; the rear boot kicks dust and the body drops into the push. The jab snaps, the cut gathers, the finisher gathers longest (115ms).",
    status: "FINAL",
  },
  {
    file: "wb19_04_finisher_card",
    num: "134",
    title: "THE FINISHER'S CARD",
    caption:
      "The finisher gathers longest (115ms windup, 0.30s life, 0.44s recovery) and its wound card answers the weight — event-logged: every clip's hits, steps and ghost counts are in the log.",
    status: "FINAL",
  },
  {
    file: "wb19_05_flock_rim",
    num: "135",
    title: "THE FLOCK KEEPS ITS EDGES",
    caption:
      "Converging believers once bled into one dark mass — each robe now catches a thin censer-warm rim (1.6px, breathing per-body, no two pulse in step) plus a light pool at the feet that pulses with the shuffle.",
    status: "FINAL",
  },
  {
    file: "wb19_06_dash_smear",
    num: "136",
    title: "THE DASH SPENDS ITS IMAGE",
    caption:
      "The martyr's lunge trails crimson-stained body ghosts and the halo's ring (40ms sampling, aging out in 0.2s so the smear settles into the recovery); the stop has weight — a skid, a stop-squash, the chains' jingle.",
    status: "FINAL",
  },
  {
    file: "wb20_01_ride_in_motion",
    num: "137",
    title: "THE RIDE IN MOTION",
    caption:
      "THE WALKING FLOCK — the weight pass. The torso answers its legs: a 1.3px vertical dip as each footfall's weight is accepted. Honest audit: WEIGHT 8/10 — 'mass settling and lifting... not gliding'.",
    status: "FINAL",
  },
  {
    file: "wb20_02_the_cycle",
    num: "138",
    title: "THE SIX-STROBE STRIDE",
    caption:
      "The painted walk's own six frames at true strobes — the tree pauses at the phase crossing (no staging): hem flat on the stone at 0/2/5, the swing's lifted leg at 3-4, the body itself rising 2px at 1/4.",
    status: "FINAL",
  },
  {
    file: "wb20_03_dip_still",
    num: "139",
    title: "THE DIP",
    caption:
      "A strobe-locked still at the logged phase — the ride at its deepest 1.30px, the dip landing on all 20 logged footfall contacts. TRUE FRAMES, captured at frame_post_draw.",
    status: "FINAL",
  },
  {
    file: "wb20_04_rise_still",
    num: "140",
    title: "THE RISE",
    caption:
      "The same stride a quarter-cycle later — the ride at −1.30px, the mass lifting into the next step. The still pairs: the head/shoulder line 'measurably higher' in the rise.",
    status: "FINAL",
  },
  {
    file: "wb20_05_the_pair",
    num: "141",
    title: "THE PAIR",
    caption:
      "Two independent dip/rise pairs side by side — 'a visible bobbing motion', leg pose and robe folds answering the stride. The flock reads 9/10: no two figures share the same walk phase.",
    status: "FINAL",
  },
  {
    file: "wb20_06_the_arch",
    num: "142",
    title: "THE BOWTIE, CLOSED",
    caption:
      "A dormant bug found and fixed by the pass: the procedural arch's inner arc ran UNREVERSED — the band self-intersected into a bowtie the renderer silently refused to triangulate (390 errors/min in fallback mode, dormant since the fallback decor was written).",
    status: "FINAL",
  },
  {
    file: "wb21_01_the_edge",
    num: "143",
    title: "THE CENSER'S EDGE",
    caption:
      "WB-21 THE READABILITY PASS — the honest audit's value-collapse finding closed on the EDGE, the way the vessel's own deep-room read was closed in WB-17. The fourth rim bake lifts the congregation's censer-gold edge from 0.44 to 0.70 (edge luminance 139 vs body 31, margin 108) and a warm self-lift (1.15/1.10/0.98) lifts the robe's folds out of the black void.",
    status: "FINAL",
  },
  {
    file: "wb21_02a_lean_right",
    num: "144",
    title: "THE LEAN, RIGHT",
    caption:
      "The audit's facing finding (2/10: 'no head orientation or shoulder asymmetry to indicate forward') — the body's axis now tilts 1.8° toward its walk, relaxing upright off it. Measured live: +1.80° walking right.",
    status: "FINAL",
  },
  {
    file: "wb21_02b_lean_left",
    num: "145",
    title: "THE LEAN, LEFT",
    caption:
      "The same body, the player crossed to the other side: −1.80°, mirrored with facing. The rig leans too (the torso shifts, the legs stay planted) and the corpse settles upright — it does not lean.",
    status: "FINAL",
  },
  {
    file: "wb21_03_the_pools",
    num: "146",
    title: "THE CENSER ALWAYS BURNS",
    caption:
      "The ground pool decoupled from the crowd: the lamp the body carries pools its light whether the flock presses or the body stands alone (base 0.10 breathing slow with the chant's sway, per-body phase; the press only adds, up to 0.30). Walking, the pool brightens at each footfall — the censer swings with the stride.",
    status: "FINAL",
  },
  {
    file: "wb21_04_the_warm_robe",
    num: "147",
    title: "THE ROBE ANSWERS THE CENSER",
    caption:
      "The audit called the robes' interior 'a black void' — the warm self-lift answers the gold the body carries, and the folds read as draped cloth ('voluminous draped objects rather than flat cutouts', 5/10 interior, was void). The between-bodies rim strengthens 0.24 → 0.32 where the flock presses together.",
    status: "FINAL",
  },
  {
    file: "wb21_05_the_motion_verdict",
    num: "148",
    title: "THE RE-AUDIT'S VERDICT",
    caption:
      "Three frames across the convergence, post-pass. The honest re-audit (same anti-confabulation prompts, logged clips): SILHOUETTE SEPARATION 3 → 6 ('7 distinct figures... the halo carves each believer out of the gloom'), FACING 2 → 4 ('the tilt tells the player these things are advancing'), the pools 'make them feel like physical entities interacting with the floor rather than floating sprites'. Legs remain cloth-hidden by design — the hem is the stride.",
    status: "FINAL",
  },
  {
    file: "wb22_01_the_press",
    num: "149",
    title: "THE PRESS KEEPS ITS COUNT",
    caption:
      "WB-22 THE CLUSTER PASS — the honest audit's baseline was devastating and logged: five converged bodies at minimum pairwise gap 0.0 px for seven straight seconds, and the auditor read the stacked column as empty space. The jostle: each living body holds ~a robe's width and shoulder room (34 px), the windup is planted but not rooted, the strike carries through the crowd. Re-audit: 5 of 5 traced, separate threats — 'the silhouettes of five individual figures remain discernible'.",
    status: "FINAL",
  },
  {
    file: "wb22_02_the_press_walks",
    num: "150",
    title: "THE LINE HOLDS",
    caption:
      "The vessel retreats and the pressing line follows as a count: median gap 34 px through the kite (baseline: 1.3 px). The churn's transients stay transients — a strike landing among the press parts over a few frames; no merge persists (lawed: no thin run longer than 24 physics frames).",
    status: "FINAL",
  },
  {
    file: "wb22_03_the_depth",
    num: "151",
    title: "THE DEPTH READ",
    caption:
      "The queued flock at the chapel's busiest wall — the great arch, the altar, the candelabra. The audit's finding here names the honest open tier: against architecture this busy the mass still reads as ornament ('twisted brass') — the figure-ground grammar at the reliquary is the next pass's subject.",
    status: "FINAL",
  },
  {
    file: "wb22_04_the_barge",
    num: "152",
    title: "THE BARGE",
    caption:
      "A staged back-rank strike into the formed press: the lunge is exempt from the jostle — it carries THROUGH the crowd (65 px crossed, lawed ≥ 40), and the flock parts around the striker's path. The press is a crowd, not a wall.",
    status: "FINAL",
  },
  {
    file: "wb22_05_the_air",
    num: "153",
    title: "THE AIR THE CENSERS FILL",
    caption:
      "The play plane's own incense: a soft breathing band at the height of the bodies that swing the lamps (peak 0.20, filtered-gradient texture — the lights pass's law), drawn behind every actor and cleared before the floor line so the crafted surface keeps its voice. Pixel-measured: the background at the body band reads 21% deeper. The re-audit credited it: 'clear atmospheric depth... effectively pushes the back wall away'.",
    status: "FINAL",
  },
  {
    file: "wb22_06_the_verdict",
    num: "154",
    title: "THE RE-AUDIT'S VERDICT",
    caption:
      "Three frames across the pass. Cluster count 0-1 → 5 of 5 ('individual hoods... jagged peaks'); the walking line's median gap 1.3 → 34 px; the air measurable and credited. Honest open tier: the busiest wall's figure-vs-architecture grammar — the mass reads as ornament there still; the press is a shadow edged in censer-gold, and at the reliquary the reliquary competes.",
    status: "FINAL",
  },
  {
    file: "wb23_01_the_wall",
    num: "155",
    title: "THE WALL, AGAIN",
    caption:
      "The same staging as WB-22's depth read — the flock pressed at the reliquary's busiest wall (great arch, chandelier, candles). The grammar pass's before/after pair: the audit now traces 5 of 5 bodies and credits the separation to silhouette and posture; no person-vs-architecture ambiguity remains at the wall.",
    status: "FINAL",
  },
  {
    file: "wb23_02_the_grammar",
    num: "156",
    title: "THE GRAMMAR AT THE CANDELABRA",
    caption:
      "The worst collision of the baseline: a body-sized brass stand among the bodies, which parsed as 'a pile of gears and pipes'. The brass now sits down (metal one step darker, halos at 0.68) and the stand reads as furniture — the honest open tier: the far-right corner still competes, the next pass's subject.",
    status: "FINAL",
  },
  {
    file: "wb23_03_the_air",
    num: "157",
    title: "THE KNEEL ROWS UNDER THICKER AIR",
    caption:
      "The congregation at rest under the thickened incense band (0.20 -> 0.26): the baseline read a far-right kneel row as 'a carved bas-relief or ornamental border'. The audit now traces 4+ kneeling bodies at 6/10 — better, and honestly not yet people at distance.",
    status: "FINAL",
  },
  {
    file: "wb23_04_the_walk",
    num: "158",
    title: "THE WALK ALONG THE WALL",
    caption:
      "The kite along the reliquary: the vessel retreats past the arch and the candelabra, the flock presses after him. Five bodies traced in motion, 6/10 — a clustered mass of converging pursuers, which at a press is partly the truth of the thing.",
    status: "FINAL",
  },
  {
    file: "wb23_05_the_arc",
    num: "159",
    title: "THE SHOULDER ARC",
    caption:
      "The pass's grammar finding, up close: a CLOSED uniform gold ring around a near-black robe parses as a wheel or medallion — the audit read the pressed flock as 'ornate golden wheels'. The rim is now an ARC over crown and shoulders (the lamp catches the crown, the robe falls away dark), the fifth bake is top-lit (crown 0.70 / flanks 0.46 / hem 0.28), and the hood keeps a small warm glint where a face would catch the censer's light.",
    status: "FINAL",
  },
  {
    file: "wb23_06_the_verdict",
    num: "160",
    title: "THE RE-AUDIT'S VERDICT",
    caption:
      "The busy wall, before and after. 1 of 5 figures -> 5 of 5; clarity 2/10 -> 7/10; 'reads primarily as an empty ornate interior' -> no ambiguity. The furniture yields (halos 0.68, brass darker, the altar glow lifts off the body band at a softer voice), the ring breaks, the bake is top-lit, the hood keeps its face. Honest open tier: the ward corner and the kneel rows at distance.",
    status: "FINAL",
  },
  {
    file: "wb24_01_the_corner",
    num: "161",
    title: "THE CORNER, PRESSED",
    caption:
      "WB-23's open tier closed: the press forms at the ward's foot, between the mural, the banner and the column. The baseline traced 2 of 5 bodies here with the ward's light a sourceless disc. The grammar now holds — the shoulder arcs and the breathing glints carry the count, the second chandelier wheel sits off the arch's jamb, the mural hangs smaller and deeper. Honest tier: the dead-end pile at its tightest churn still reads 2-3 of 5.",
    status: "FINAL",
  },
  {
    file: "wb24_02_the_rest",
    num: "162",
    title: "THE CORNER AT REST",
    caption:
      "The congregation kneeling in the corner's frame — the candelabra between the rows, the banner above, the painted procession and the ward behind. The far kneeler the baseline called AMBIGUOUS now holds its silhouette against the deeper air, and the chandelier that read as 'a statue in the upper background' carries its wheel's wide glow, a drop finial and a five-link hang.",
    status: "FINAL",
  },
  {
    file: "wb24_03_the_rows",
    num: "163",
    title: "THE DISTANT ROWS BREATHE",
    caption:
      "The kneel rows at the frame's far side — the baseline leaned gargoyle ('could be mistaken for carved statues at a quick glance'). The painted congregation regains the rising chant marks the fallback rig always had: per-body gold exhaling above each hood, never two in step. The audit now reads the rows as LIVING PEOPLE at 7/10 and sorts the statues out on its own.",
    status: "FINAL",
  },
  {
    file: "wb24_04_the_approach",
    num: "164",
    title: "THE APPROACH",
    caption:
      "The walk into the corner as the player actually meets it: the vessel advances from the relic toward the ward and the corner assembles around him — the press at his heels, the mural's panel on the right reading as a painting, not a crowd. Distinct silhouettes with heads and shoulders that clearly read as people, 7/10 at the worst moment.",
    status: "FINAL",
  },
  {
    file: "wb24_05_the_live_ward",
    num: "165",
    title: "THE LIVE WARD",
    caption:
      "The pass's core finding: the ward's belief was computed from a chanters array that NOTHING ever fed — the barrier silently collapsed on the room's first frame, every visit since it shipped. The flock is wired now: belief 100, the shimmer a curtain with soft wings and a breathing crown. The audit reads 'a barrier or curtain of light... a magical seal', six figures traced at 8/10.",
    status: "FINAL",
  },
  {
    file: "wb24_06_the_verdict",
    num: "166",
    title: "THE RE-AUDIT'S VERDICT",
    caption:
      "The corner, before and after. The ward: invisible on room entry (belief 0, no barrier at all) -> the curtain of belief at full chant. The pressed corner: a sourceless light disc and 2 of 5 traced -> 'a pool of divine light' and the grammar holding. Honest open tier: the dead-end pile at its tightest, and the chantry jamb's pale-saint read — the room is literally named for one.",
    status: "FINAL",
  },
  {
    file: "wb25_01_pile_tightest",
    num: "167",
    title: "THE PILE, TIGHTEST",
    caption:
      "WB-24's open tier closed. The instrument logged the dead-end press's churn for nine seconds: median gap 8px, a quarter of the run below 1px, and three bodies parked at the exact same x — pinned against the ward's edge, their windup plants landed mid-overlap. The press shoves the vessel into the barrier and the whole flock converges on one point; the audit traced the merged trio at 3/10 separation.",
    status: "FINAL",
  },
  {
    file: "wb25_02_pile_settled",
    num: "168",
    title: "THE SETTLED LINE",
    caption:
      "The same corner after the fix. The windup's plant now waits for a robe's width of its own ground — walkers that cannot fit the strike window QUEUE behind it — and the packed line creeps instead of transmitting its full walk down the chain. The corner's median standing gap: 25.8px, the line breathing to 60px at its widest. The audit traces 5 of 5: 'individual hoods and shoulder lines can be distinguished'.",
    status: "FINAL",
  },
  {
    file: "wb25_03_jamb_chantry_side",
    num: "169",
    title: "THE SAINT, FROM THE CHANTRY",
    caption:
      "WB-24's other open tier, diagnosed. Every camera slice traced 'a tall pale statue of a robed woman with open hands' — attributed to the chantry jamb, but pixel forensics found the jamb nearly invisible (46 vs the wall's 44). The phantom is the BACKDROP'S OWN PAINTED SAINT — the room's namesake, tiled to ~511px on the far plane, her body columns outshining everything in the room's upper air (peak 95 vs the believers' lit hoods at 75).",
    status: "FINAL",
  },
  {
    file: "wb25_04_jamb_relic_light",
    num: "170",
    title: "THE SAINT AT HER ALTAR",
    caption:
      "Dead-on with the relic's light on her — the baseline audit's 'primary light-colored focal point in the center of the dark scene'. The dim is a feathered multiply over her statue and pedestal alone (a banked tool, lawed): her zone mean 91 -> 63, the candelabras flanking her untouched at 75. She reads as stone the moment the light stops insisting — 'its texture clearly identifies it as stone'.",
    status: "FINAL",
  },
  {
    file: "wb25_05_jamb_wheel_side",
    num: "171",
    title: "THE SAINT FROM THE WHEEL SIDE",
    caption:
      "The worst slice, after. She keeps her silhouette, her pose, her altar — the chapel keeps its namesake — but she sits a step deeper in the room's air: her peak now level with the jamb tops and the column crowns (63 vs 60-64), no longer the focal giant. The grammar law holds: the room's brightest presences are its bodies and its relic.",
    status: "FINAL",
  },
  {
    file: "wb25_06_the_verdict",
    num: "172",
    title: "THE RE-AUDIT'S VERDICT",
    caption:
      "Both tiers, before and after (git-stash renders of the true pre-fix state). The pile: median 8px merged -> 25.8px counted, 3 of 5 -> 5 of 5 traced. The saint: peak 95 focal giant -> 63, one voice among the architecture. Honest open tier: the queue's middle pair still huddles in transit snapshots; the strike's slam deposits bodies at the ward edge through the line (transient, count-preserving); the saint still reads 'significantly taller' — she is a giant statue in her own chapel, thematically locked.",
    status: "FINAL",
  },
  {
    file: "gp1_01_title",
    num: "173",
    title: "THE ARRIVAL FRAME",
    caption:
      "THE LAST FRAME opened where no audit had ever looked: the frames the player arrives at and leaves on. The boot title as truly rendered — the city backdrop breathing under its ash, the designation and its census sub-line, the plate-framed menu, the full control map at the frame's foot. The audit reads the typographic hierarchy at 8/10 with every menu item and footer line traced; the control map gained one notch of presence (11px, lifted alpha) after the audit leaned in to read it.",
    status: "FINAL",
  },
  {
    file: "gp1_03_death_card",
    num: "174",
    title: "THE VERDICT GETS ITS GROUND",
    caption:
      "A true staged death — a real take_damage through the full flow: the card, the looming lens, the stain, the respawn. The death card's small designation used to hang as BARE TYPE over busy architecture — the audit read the martyr's roofline THROUGH 'ENTITY_000_818 · THE RECORD RESTORES WHAT IT LOSES'. The room card's own feathered plate now backs the center verdict the same way; the audit reads the card at 9/10 with both lines fully legible.",
    status: "FINAL",
  },
  {
    file: "gp1_04_monument",
    num: "175",
    title: "THE LIST GOES DOWN",
    caption:
      "The climax, clean. The monument read in the aftermath district — the SYSTEM's cold ledger on the census sheet: 'ENTITY_000_817 — FAILED. ENTITY_000_816 — FAILED. THE LIST GOES DOWN, NOT UP.' The baseline audit caught the room's AFTERMATH title card sitting ON this dialogue (a card still holding its fade after the death-respawn re-entry); the record now outranks the marquee — a card dissolves the moment a sheet rises. The moment reads at 9/10.",
    status: "FINAL",
  },
  {
    file: "gp1_05_end_touched_nothing",
    num: "176",
    title: "THE SETTLEMENT — TOUCHED NOTHING",
    caption:
      "The run's final frame, arrived at by the true path — the real monument dialogue finishing, the real stats of the run. The question in serif, the census line above it, the ledger of every number the city kept. The verdict 'YOU TOUCHED NOTHING. THE CITY REMEMBERS THAT TOO.' now holds its own row — it used to print 1.6px under the [F] prompt, two lines through each other. The audit transcribes every line exactly and reads the layout at 9/10.",
    status: "FINAL",
  },
  {
    file: "gp1_06_end_spent_deeply",
    num: "177",
    title: "THE SETTLEMENT — SPENT DEEPLY",
    caption:
      "The deep spender's settlement: consistency held at 38 through the run, 47 spent across nine edits, the seams' verdict in crimson — 'YOU SPENT DEEPLY. THE SEAMS SHOWED YOU THEIR SECRETS.' All three judgment variants staged and audited (touched-nothing, spent-deeply, all-four-fragments); each verdict 12px and near-full crimson on its own row, each transcribed exactly by the re-audit.",
    status: "FINAL",
  },
  {
    file: "gp1_07_end_listened",
    num: "178",
    title: "THE SETTLEMENT — LISTENED",
    caption:
      "The listener's settlement: all four fragments recovered, consistency held above the deep-spend line — 'YOU LISTENED. THAT WAS NEVER REQUIRED OF YOU.' The rarest verdict in the slice, and the one the whole design bends toward: the vessel that spent its run reading instead of editing. TIME IN THE CITY, DEATHS, DISSIPATED — every number on the ledger is one the city actually kept.",
    status: "FINAL",
  },
  {
    file: "gp1_verdict_death",
    num: "179",
    title: "THE RE-AUDIT'S VERDICT — THE CARD",
    caption:
      "The death card, before and after (git-stash renders of the true pre-fix state). BEFORE: the small designation as bare type, the architecture reading through it, the audit misreading the designation itself. AFTER: the feathered plate holds the ground under both lines — the verdict reads as a struck plate, not floating text.",
    status: "FINAL",
  },
  {
    file: "gp1_verdict_end",
    num: "180",
    title: "THE RE-AUDIT'S VERDICT — THE LAST FRAME",
    caption:
      "The settlement's bottom block, before and after. BEFORE: the crimson judgment printed 1.6px under the gray [F] prompt — two baselines through each other, the audit fusing them into one garbled line. AFTER: verdict, prompt and credit each on their own row with lawed separation (>=16px between verdict and prompt); every judgment variant transcribed exactly.",
    status: "FINAL",
  },
  {
    file: "gp1_verdict_monument",
    num: "181",
    title: "THE RE-AUDIT'S VERDICT — THE RECORD OUTRANKS THE MARQUEE",
    caption:
      "The climax, before and after. BEFORE: the room's AFTERMATH card still holding its fade sits directly on the census sheet — the audit read the title through the SYSTEM's list, clarity 6/10. AFTER: the card dissolves the moment the dialogue rises (a yield lawed in the suite), the list reads whole — 9/10.",
    status: "FINAL",
  },
  {
    file: "gp2_01_census",
    num: "182",
    title: "THE CENSUS COUNTS ITS STRUCK",
    caption:
      "THE RECORD SPEAKS read the city's own words as published text for the first time. The census stele in the Contradiction lists four inhabitants — MARROW 71%, LOAVES 54%, PSALM 12%, KETTLE 9% — and its stamp claimed FOUR of the above struck, while the observed record still spoke of 'the struck names... shallower than the living ones'. Four of four leaves no living ones: the stamp now strikes two — the two lowest definitions — and 'give it a year' regains its menace. The 71% the ward integrity echoes stays a living man.",
    status: "FINAL",
  },
  {
    file: "gp2_02_law_obs",
    num: "183",
    title: "THE RECORD'S MEMORY, WHOLE",
    caption:
      "The pass's deepest finding was not a typo: the observe ledger's single-line economy ellipsized every MEMORY row at ~29 characters — and 34 of the record's own memories run longer. The gold-leaf law's record used to read 'gold leaf, chapel grade. the…' and stop. The value now wraps onto ruled lines (hanging indent at the value column, at most four, the census ellipsis surviving only past the cap) — and the street it names is PROCESSION street, as the boundary stone, the measurer and the zone stamp all spell it.",
    status: "FINAL",
  },
  {
    file: "gp2_04_cradle",
    num: "184",
    title: "THE SCREAMING CRADLE, HEARD",
    caption:
      "The longest memory in the record — 74 characters — sits two strides from the vessel's own cradle in the iron womb, and the ledger never showed more than its first breath: 'eleven opened early. one of…'. The whole line is legible now: 'eleven opened early. one of them is still screaming, quietly, in the wall.' — wrapped across three ruled lines on the live ledger page, verified on the real observe flow, the vessel standing where the player stands at birth.",
    status: "FINAL",
  },
  {
    file: "gp2_strip_census",
    num: "185",
    title: "THE RE-AUDIT'S VERDICT — THE CENSUS",
    caption:
      "The census stele, before and after (git-stash renders of the true pre-fix state). BEFORE: 'FOUR OF THE ABOVE HAVE BEEN STRUCK' over a list of four — the stamp arithmetically erasing the very inhabitants its own observed record calls living. AFTER: TWO struck, TWO living, the striking hand as steady as ever.",
    status: "FINAL",
  },
  {
    file: "gp2_strip_memory",
    num: "186",
    title: "THE RE-AUDIT'S VERDICT — THE MEMORY LAYER",
    caption:
      "The observe ledger, before and after. BEFORE: one ruled line and a census ellipsis — 29 characters of 74, the record's richest text layer hidden behind its own economy. AFTER: the whole memory on wrapped ruled lines. The same fix opens all 34 long memories in the record — every entity and inscription memory is now lawed to survive the wrap without loss.",
    status: "FINAL",
  },
  {
    file: "gp2_strip_wording",
    num: "187",
    title: "THE RE-AUDIT'S VERDICT — THE WORDS",
    caption:
      "The mural notice, before and after. BEFORE: 'NOTICE — MURAL, CHANTY WALL', a spelling that exists nowhere else in the record — the chant owns the wall, and the chant is never 'chanty'. AFTER: CHANT WALL, agreed with every other line that names it. The suite now laws the corpus: no ghost spelling, no renamed street, no string published dirty.",
    status: "FINAL",
  },
  {
    file: "gp3_01_plaque_pad",
    num: "188",
    title: "THE PLAQUE KNOWS ITS HAND",
    caption:
      "THE SECOND HAND — the gamepad experience pass. The pad was always playable (every action bound) but the world spoke only the keyboard's names: this brass plaque told a pad-holding player to press F by a key that would not answer to it. The hand that last spoke now owns the labels — here the pad spoke last, and the keycap carries its own A. The same pass found the pause was a veil, not a hold: the world ran behind it (a probe walked the vessel 260px in a one-second paused hold — enemies struck, the boss's aura drained while the record stood still); the world is PAUSABLE now, and the suite laws the freeze.",
    status: "FINAL",
  },
  {
    file: "gp3_02_plaque_kb",
    num: "189",
    title: "THE SAME PLAQUE, THE OTHER HAND",
    caption:
      "The same anchor, the same plaque, one frame later — but the keyboard spoke last, and the cap carries F. One button, two names, each true to the hand that holds it. The re-voicing is lawed across every surface: the dialogue's FILE stamp, the reading sheet's close hint, the observe ledger's margins, the options and map footers, and the census's own system messages — a pad player reads [Y] where the record used to insist on [TAB].",
    status: "FINAL",
  },
  {
    file: "gp3_03_dialogue_pad",
    num: "190",
    title: "THE SHEET FILES UNDER THE PAD",
    caption:
      "The dialogue sheet's continue mark — FILE [A] when the pad holds the vessel, FILE [F] when the keyboard does. The pad's one A button also carries both JUMP and INTERACT; the title always promised 'A JUMP/INTERACT', but the code fired both at once — a hop with every communion, a reading sheet popping mid-leap, and the door's −6 consistency spent by accident. Standing at a record, the press now FILES: the same event that answers the interact is silenced as a jump, and the vessel does not leap off the step it took.",
    status: "FINAL",
  },
  {
    file: "gp3_04_reading_pad",
    num: "191",
    title: "EVERY SHEET CLOSES THE SAME WAY",
    caption:
      "The reading panel's footer under the pad's hand: A / Y — CLOSE. The bilingual standalone README now teaches the pad's whole map too — it never mentioned that X attacks, so a pad player could not learn how to fight from the only documentation in the zip. The suite pins the pad's truth end to end: the tracker, the re-marked funnel, the shared-A silence at the anchor and the leap away from it, the README's four lines, and the pause that now actually holds the world — 889 checks.",
    status: "FINAL",
  },
];

function ProofShot({ proof }: { proof: (typeof VISUAL_PROOFS)[number] }) {
  const [failed, setFailed] = useState(false);
  return (
    <figure className="group overflow-hidden rounded-md border border-[#2b2b2e] bg-[#0d0d0f]">
      <div className="relative aspect-video w-full overflow-hidden">
        {failed ? (
          <div className="absolute inset-0 flex items-center justify-center bg-[#141416]">
            <span className="font-mono text-[10px] uppercase tracking-[0.3em] text-[#4a463f]">
              RENDER PENDING
            </span>
          </div>
        ) : (
          <img
            src={`/screenshots/${proof.file}.jpg`}
            alt={`${proof.title} — in-engine gameplay render`}
            loading="lazy"
            onError={() => setFailed(true)}
            className="absolute inset-0 h-full w-full object-cover transition-transform duration-700 group-hover:scale-[1.03]"
          />
        )}
        <span className="absolute left-3 top-3 rounded-sm border border-[#2b2b2e] bg-[#070708]/85 px-2 py-1 font-mono text-[10px] tracking-[0.2em] text-[#cfc8b8]">
          {proof.num}
        </span>
      </div>
      <figcaption className="space-y-2.5 p-4">
        <div className="flex items-start justify-between gap-3">
          <h3 className="font-mono text-xs uppercase tracking-[0.18em] leading-relaxed text-[#cfc8b8]">
            {proof.title}
          </h3>
          <span
            className={`shrink-0 rounded-sm border px-2 py-1 font-mono text-[9px] uppercase tracking-[0.14em] ${PROOF_STATUS_STYLE[proof.status]}`}
          >
            {proof.status}
          </span>
        </div>
        <p className="text-xs leading-relaxed text-[#a89f8c]">{proof.caption}</p>
      </figcaption>
    </figure>
  );
}

const BESTIARY = [
  {
    name: "THE HOLLOW",
    cls: "CLASS: NULL",
    icon: EyeOff,
    desc: "The absence of identity, walking the procession street. It wants yours.",
  },
  {
    name: "NULL CHILDREN",
    cls: "CLASS: UNFILED",
    icon: Ghost,
    desc: "Outside classification. Un-hittable — until reality itself is broken.",
  },
  {
    name: "THE BELIEVERS",
    cls: "CLASS: COLLECTIVE",
    icon: Users,
    desc: "The group is the mechanic. Harm one and the ward weakens; the chant is the creature.",
  },
  {
    name: "THE CENSOR",
    cls: "CLASS: CORRECTION",
    icon: ScanEye,
    desc: "The system’s answer to your edits. It cannot be fought — only survived.",
  },
  {
    name: "THE BOUND MARTYR",
    cls: "ENTITY_000_001",
    icon: HeartCrack,
    desc: "Mini-boss. Belief-shielded, three phases, dies grateful.",
  },
  {
    name: "THE PENITENT",
    cls: "CLASS: WITHHELD",
    icon: Eye,
    desc: "Knows what you did.",
  },
] as const;

const CONTROLS = [
  { binding: "A / D  ·  ← / →", pad: "STICK / D-PAD", action: "MOVE" },
  { binding: "SPACE", pad: "A", action: "JUMP" },
  { binding: "SHIFT", pad: "B", action: "ROLL" },
  { binding: "J  ·  LMB", pad: "X", action: "ATTACK" },
  { binding: "TAB", pad: "Y", action: "OBSERVE" },
  { binding: "W / S", pad: "STICK ↑ / ↓", action: "SELECT PROPERTY" },
  { binding: "E", pad: "RB", action: "MODIFY" },
  { binding: "F", pad: "A", action: "INTERACT" },
  { binding: "ESC", pad: "START", action: "PAUSE" },
] as const;

const PALETTE = [
  { name: "VOID", hex: "#070708" },
  { name: "CHARCOAL", hex: "#141416" },
  { name: "ASH", hex: "#2b2b2e" },
  { name: "DIRTY STONE", hex: "#4a463f" },
  { name: "BONE", hex: "#cfc8b8" },
  { name: "PARCH", hex: "#a89f8c" },
  { name: "BLOOD", hex: "#6d1a22" },
  { name: "CRIMSON", hex: "#83322b" },
  { name: "GOLD", hex: "#b08d3e" },
  { name: "VIOLET", hex: "#3b2f4a" },
  { name: "SYSTEM CYAN", hex: "#7fd8d8" },
] as const;

const MEMORY_FRAGMENTS = [
  {
    id: "FRAGMENT 01",
    title: "THE LITURGY OF THE MARTYR",
    state: "INTEGRITY 100%",
    note: "“He gave himself gladly.”",
    tone: "ok" as const,
  },
  {
    id: "FRAGMENT 02",
    title: "ARCHIVE LOG 7-11",
    state: "CORRUPTED",
    note: "entity_000_001 did not… [UNREADABLE]",
    tone: "bad" as const,
  },
  {
    id: "FRAGMENT 03",
    title: "MEASURER FIELD NOTE",
    state: "INTEGRITY 88%",
    note: "“Do not tell them what the engine eats.”",
    tone: "ok" as const,
  },
  {
    id: "FRAGMENT 04",
    title: "YOUR OWN DESIGNATION",
    state: "CONTRADICTED",
    note: "ENTITY_000_818. You are not the first.",
    tone: "bad" as const,
  },
];

/* ---------------------------------------------------------------------------
 * Small building blocks
 * ------------------------------------------------------------------------- */

function Reveal({
  children,
  delay = 0,
  className,
}: {
  children: ReactNode;
  delay?: number;
  className?: string;
}) {
  return (
    <motion.div
      initial={{ opacity: 0, y: 14 }}
      whileInView={{ opacity: 1, y: 0 }}
      viewport={{ once: true, margin: "-60px" }}
      transition={{ duration: 0.55, delay, ease: [0.21, 0.47, 0.32, 0.98] }}
      className={className}
    >
      {children}
    </motion.div>
  );
}

function SectionHeading({
  index,
  kicker,
  title,
  description,
}: {
  index: string;
  kicker: string;
  title: string;
  description?: string;
}) {
  return (
    <Reveal className="mb-8 space-y-3 sm:mb-10">
      <p className="font-mono text-[11px] uppercase tracking-[0.3em] text-[#b08d3e]">
        {index} / {kicker}
      </p>
      <h2 className="e0-serif text-3xl font-semibold leading-tight text-[#cfc8b8] sm:text-4xl">
        {title}
      </h2>
      {description ? (
        <p className="max-w-2xl text-sm leading-relaxed text-[#a89f8c]">
          {description}
        </p>
      ) : null}
    </Reveal>
  );
}

function Section({
  id,
  children,
  last = false,
  className,
}: {
  id?: string;
  children: ReactNode;
  last?: boolean;
  className?: string;
}) {
  return (
    <section
      id={id}
      className={`border-[#2b2b2e]/60 ${last ? "" : "border-b"} ${className ?? ""}`}
    >
      <div className="mx-auto max-w-6xl px-4 py-16 sm:px-6 sm:py-20">{children}</div>
    </section>
  );
}

function GlitchTitle() {
  return (
    <h1
      aria-label="ENTITY_000"
      className="relative select-none font-mono text-[clamp(2.75rem,10.5vw,7.5rem)] font-bold leading-none tracking-tight text-[#cfc8b8]"
    >
      <span aria-hidden="true" className="e0-glitch e0-glitch--crimson">
        ENTITY_000
      </span>
      <span aria-hidden="true" className="e0-glitch e0-glitch--cyan">
        ENTITY_000
      </span>
      <span className="relative">ENTITY_000</span>
    </h1>
  );
}

/* ---------------------------------------------------------------------------
 * Download logic
 * ------------------------------------------------------------------------- */

type DownloadType = "project" | "docs";
type DocsStatus = "checking" | "ready" | "compiling";

function formatBytes(bytes: number): string {
  if (bytes >= 1024 * 1024) return `${(bytes / (1024 * 1024)).toFixed(1)} MB`;
  return `${Math.max(1, Math.round(bytes / 1024))} KB`;
}

const FALLBACK_NAMES: Record<DownloadType, string> = {
  project: "ENTITY_000_Godot_Project.zip",
  docs: "ENTITY_000_Phase0_Docs.pdf",
};

/* ---------------------------------------------------------------------------
 * Page
 * ------------------------------------------------------------------------- */

/* ---------------------------------------------------------------------------
 * The Archivist — the Bureau's records keeper (AI chat, backend /api/chat)
 * ------------------------------------------------------------------------- */

type ArchivistMessage = { role: "user" | "assistant"; content: string };

const ARCHIVIST_STORAGE_KEY = "e0_archivist_thread_v1";
const ARCHIVIST_MAX_STORED = 30; // keep the scroll lean; the API caps at 24 anyway

function loadArchivistThread(): ArchivistMessage[] {
  try {
    const raw = window.localStorage.getItem(ARCHIVIST_STORAGE_KEY);
    if (!raw) return [ARCHIVIST_GREETING];
    const parsed = JSON.parse(raw) as ArchivistMessage[];
    if (!Array.isArray(parsed)) return [ARCHIVIST_GREETING];
    const clean = parsed.filter(
      (m) =>
        m &&
        (m.role === "user" || m.role === "assistant") &&
        typeof m.content === "string" &&
        m.content.trim().length > 0,
    );
    return clean.length > 0 ? clean.slice(-ARCHIVIST_MAX_STORED) : [ARCHIVIST_GREETING];
  } catch {
    return [ARCHIVIST_GREETING];
  }
}

function saveArchivistThread(messages: ArchivistMessage[]): void {
  try {
    window.localStorage.setItem(
      ARCHIVIST_STORAGE_KEY,
      JSON.stringify(messages.slice(-ARCHIVIST_MAX_STORED)),
    );
  } catch {
    /* storage unavailable (private mode etc.) — the chat still works in-memory */
  }
}

/* Display-only scrub: the Archivist is prompted for plain text, but any
   stray markdown (**bold**, #headers, `code`) must never reach the bubble
   as literal symbols. */
function scrubArchivistText(text: string): string {
  return text
    .replace(/\*\*(.+?)\*\*/gu, "$1")
    .replace(/^#{1,4}\s+/gmu, "")
    .replace(/`([^`]+)`/gu, "$1");
}

const ARCHIVIST_GREETING: ArchivistMessage = {
  role: "assistant",
  content:
    "You have reached the Bureau's records. I am the Archivist — ask me about the game, the controls, or the way forward.\nبه بایگانیِ اداره رسیدی. من بایگانی‌بانم — دربارهٔ بازی، کنترل‌ها یا مسیرِ جلو بپرس.",
};

const ARCHIVIST_PROMPTS: { label: string; question: string }[] = [
  { label: "CONTROLS · کنترل‌ها", question: "کنترل‌های بازی چی هستن؟" },
  { label: "THE GAME · خود بازی", question: "ENTITY_000 درباره‌ی چیه؟" },
  { label: "A HINT · راهنمایی", question: "یه راهنمایی بده — نمی‌دونم باید برم کجا." },
  { label: "DOWNLOAD · دانلود", question: "بازی رو از کجا دانلود کنم؟" },
];

export default function Home() {
  const [busy, setBusy] = useState<DownloadType | null>(null);
  const [docsStatus, setDocsStatus] = useState<DocsStatus>("checking");
  const [projectBytes, setProjectBytes] = useState<number | null>(null);

  const [chatOpen, setChatOpen] = useState(false);
  const [chatSeen, setChatSeen] = useState(false);
  const [chatMessages, setChatMessages] = useState<ArchivistMessage[]>([
    ARCHIVIST_GREETING,
  ]);
  const [chatRestored, setChatRestored] = useState(false);
  const [chatInput, setChatInput] = useState("");
  const [chatBusy, setChatBusy] = useState(false);
  const chatScrollRef = useRef<HTMLDivElement>(null);
  const chatInputRef = useRef<HTMLTextAreaElement>(null);

  /* Hydrate the persisted thread after mount (SSR-safe) and mark the
     launcher as seen for returning visitors. */
  useEffect(() => {
    const stored = loadArchivistThread();
    if (stored.length > 1) setChatMessages(stored);
    try {
      setChatSeen(window.localStorage.getItem(ARCHIVIST_STORAGE_KEY) !== null);
    } catch {
      /* ignore */
    }
    setChatRestored(true);
  }, []);

  /* Persist every settled exchange (typing placeholder never saved).
     A thread that holds nothing but the greeting IS an empty thread —
     remove the key so "clear" survives reloads and the launcher's beckon
     pulse correctly returns for a fresh visitor. */
  useEffect(() => {
    if (!chatRestored) return;
    const settled = chatMessages.filter((m) => m.content.trim().length > 0);
    if (settled.length > 1) {
      saveArchivistThread(settled);
    } else {
      try {
        window.localStorage.removeItem(ARCHIVIST_STORAGE_KEY);
      } catch {
        /* ignore */
      }
    }
  }, [chatMessages, chatRestored]);

  useEffect(() => {
    if (chatOpen) chatInputRef.current?.focus();
  }, [chatOpen]);

  useEffect(() => {
    const el = chatScrollRef.current;
    if (el) el.scrollTop = el.scrollHeight;
  }, [chatMessages, chatBusy, chatOpen]);

  useEffect(() => {
    if (!chatOpen) return;
    const onKey = (e: KeyboardEvent) => {
      if (e.key === "Escape") setChatOpen(false);
    };
    window.addEventListener("keydown", onKey);
    return () => window.removeEventListener("keydown", onKey);
  }, [chatOpen]);

  async function askArchivist(raw: string) {
    const text = raw.trim();
    if (!text || chatBusy) return;
    const history: ArchivistMessage[] = [
      ...chatMessages.filter((m) => m.content),
      { role: "user", content: text },
    ];
    setChatMessages([...history, { role: "assistant", content: "" }]);
    setChatInput("");
    if (chatInputRef.current) chatInputRef.current.style.height = "auto";
    setChatBusy(true);

    let assistantText = "";
    const paint = () => {
      setChatMessages([
        ...history,
        { role: "assistant", content: assistantText },
      ]);
    };

    /* Preferred path: consume the server's SSE stream, painting each delta. */
    try {
      const res = await fetch("/api/chat", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({
          messages: history.slice(-24).map((m) => ({
            role: m.role,
            content: m.content,
          })),
        }),
      });
      if (!res.ok || !res.body) throw new Error(`status ${res.status}`);

      const reader = res.body.getReader();
      const decoder = new TextDecoder();
      let carry = "";
      for (;;) {
        const { done, value } = await reader.read();
        if (done) break;
        carry += decoder.decode(value, { stream: true });
        const events = carry.split("\n\n");
        carry = events.pop() ?? "";
        for (const evt of events) {
          const line = evt.trim();
          if (!line.startsWith("data:")) continue;
          let parsed: { delta?: string; done?: boolean; error?: string };
          try {
            parsed = JSON.parse(line.slice(5).trim());
          } catch {
            continue;
          }
          if (parsed.error === "fallback") throw new Error("fallback");
          if (parsed.delta) {
            assistantText += parsed.delta;
            paint();
          }
        }
      }
      if (assistantText.trim().length === 0) throw new Error("empty stream");
    } catch {
      /* Buffered fallback: one JSON round-trip, no streaming. */
      let ok = false;
      try {
        const res = await fetch("/api/chat?buffered=1", {
          method: "POST",
          headers: { "Content-Type": "application/json" },
          body: JSON.stringify({
            messages: history.slice(-24).map((m) => ({
              role: m.role,
              content: m.content,
            })),
          }),
        });
        if (res.ok) {
          const data = (await res.json()) as { reply?: string };
          const reply = data.reply?.trim();
          if (reply) {
            assistantText = reply;
            ok = true;
          }
        }
      } catch {
        /* fall through to the error toast */
      }
      if (!ok) {
        setChatMessages(history);
        toast.error("The Archivist is unreachable.", {
          description:
            "The line to the records went dead — try again in a moment.",
        });
        setChatBusy(false);
        return;
      }
    }

    setChatMessages([...history, { role: "assistant", content: assistantText }]);
    setChatBusy(false);
  }

  function resetArchivist() {
    setChatMessages([ARCHIVIST_GREETING]);
    setChatInput("");
    if (chatInputRef.current) chatInputRef.current.style.height = "auto";
    try {
      window.localStorage.removeItem(ARCHIVIST_STORAGE_KEY);
    } catch {
      /* ignore */
    }
  }

  useEffect(() => {
    let cancelled = false;

    (async () => {
      try {
        const res = await fetch("/api/download?type=docs", { method: "HEAD" });
        if (!cancelled) setDocsStatus(res.ok ? "ready" : "compiling");
      } catch {
        if (!cancelled) setDocsStatus("compiling");
      }
      try {
        const res = await fetch("/api/download?type=project", { method: "HEAD" });
        const len = res.headers.get("content-length");
        if (!cancelled) setProjectBytes(len ? Number(len) : null);
      } catch {
        /* size hint stays generic */
      }
    })();

    return () => {
      cancelled = true;
    };
  }, []);

  async function triggerDownload(type: DownloadType) {
    setBusy(type);
    try {
      const res = await fetch(`/api/download?type=${type}`);

      if (!res.ok) {
        if (type === "docs" && res.status === 404) {
          setDocsStatus("compiling");
          toast("Documentation is still compiling — try again shortly.", {
            description: "The Phase 0 PDF is being assembled on the server.",
          });
        } else {
          toast.error("Download failed.", {
            description: `The delivery endpoint responded with status ${res.status}.`,
          });
        }
        return;
      }

      const disposition = res.headers.get("content-disposition") ?? "";
      const match = disposition.match(/filename="?([^";]+)"?/i);
      const filename = match?.[1] ?? FALLBACK_NAMES[type];

      const blob = await res.blob();
      const url = URL.createObjectURL(blob);
      const anchor = document.createElement("a");
      anchor.href = url;
      anchor.download = filename;
      document.body.appendChild(anchor);
      anchor.click();
      anchor.remove();
      window.setTimeout(() => URL.revokeObjectURL(url), 5000);

      if (type === "docs") setDocsStatus("ready");
      toast.success(filename, { description: "Download started." });
    } catch {
      toast.error("Download failed.", {
        description: "The delivery endpoint could not be reached.",
      });
    } finally {
      setBusy(null);
    }
  }

  const projectSizeHint =
    projectBytes !== null ? `PACKED ${formatBytes(projectBytes)}` : "PACKED ≈ tens of MB";

  return (
    <MotionConfig reducedMotion="user">
      <style>{PAGE_STYLES}</style>

      <div className="flex min-h-screen flex-col bg-[#070708] text-[#cfc8b8]">
        {/* ----------------------------------------------------------------- */
        /* Site header                                                        */
        /* ---------------------------------------------------------------- */}
        <header className="sticky top-0 z-40 border-b border-[#2b2b2e]/70 bg-[#070708]/90 backdrop-blur-sm">
          <div className="mx-auto flex h-16 max-w-6xl items-center justify-between gap-4 px-4 sm:px-6">
            <div className="flex min-w-0 items-center gap-3">
              <span className="truncate font-mono text-sm font-bold tracking-[0.3em] text-[#cfc8b8]">
                ENTITY_000
              </span>
              <span className="hidden items-center gap-1.5 rounded-sm border border-[#2b2b2e] px-2 py-1 font-mono text-[10px] uppercase tracking-[0.18em] text-[#7fd8d8]/80 sm:inline-flex">
                <span aria-hidden="true" className="h-1.5 w-1.5 rounded-full bg-[#7fd8d8]/70" />
                BUILD 889 / VERTICAL SLICE
              </span>
            </div>
            <nav aria-label="Page sections">
              <a
                href="#proofs"
                className="inline-flex h-11 items-center gap-2 rounded-sm px-2 font-mono text-[11px] uppercase tracking-[0.22em] text-[#a89f8c] transition-colors hover:text-[#cfc8b8] focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-[#b08d3e]"
              >
                PROOFS
              </a>
              <a
                href="#deliverables"
                className="inline-flex h-11 items-center gap-2 rounded-sm px-2 font-mono text-[11px] uppercase tracking-[0.22em] text-[#a89f8c] transition-colors hover:text-[#cfc8b8] focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-[#b08d3e]"
              >
                DOWNLOAD
                <ArrowDown className="size-3.5" aria-hidden="true" />
              </a>
            </nav>
          </div>
        </header>

        <main className="flex-1">
          {/* --------------------------------------------------------------- */
            /* Hero                                                              */
          /* ---------------------------------------------------------------- */}
          <section className="border-b border-[#2b2b2e]/60">
            <div className="mx-auto max-w-6xl px-4 py-20 sm:px-6 sm:py-28 lg:py-32">
              <motion.div
                initial={{ opacity: 0, y: 18 }}
                animate={{ opacity: 1, y: 0 }}
                transition={{ duration: 0.7, ease: [0.21, 0.47, 0.32, 0.98] }}
              >
                <GlitchTitle />

                <p className="e0-serif mt-6 max-w-2xl text-xl italic leading-relaxed text-[#a89f8c] sm:text-2xl lg:text-3xl">
                  “If you were created for a purpose, do you have the right to reject
                  it?”
                </p>

                <p className="mt-5 font-mono text-[10px] uppercase tracking-[0.24em] leading-relaxed text-[#a89f8c]/80 sm:text-xs">
                  A 2D action-exploration-puzzle psychological mystery.
                  <span className="text-[#857d6c]"> · </span>
                  A native Godot 4.4 project.
                </p>

                <ul className="mt-8 flex flex-wrap gap-2" aria-label="Project badges">
                  {HERO_BADGES.map((badge) => (
                    <li key={badge}>
                      <Badge
                        variant="outline"
                        className="rounded-sm border-[#2b2b2e] bg-[#141416] px-3 py-1.5 font-mono text-[10px] uppercase tracking-[0.18em] text-[#a89f8c]"
                      >
                        {badge}
                      </Badge>
                    </li>
                  ))}
                </ul>
              </motion.div>
            </div>
          </section>

          {/* --------------------------------------------------------------- */
            /* Delivery notice                                                   */
          /* ---------------------------------------------------------------- */}
          <section aria-labelledby="delivery-notice" className="border-b border-[#2b2b2e]/60">
            <div className="mx-auto max-w-6xl px-4 py-8 sm:px-6">
              <Reveal>
                <div className="flex gap-4 rounded-md border border-[#83322b]/50 bg-[#6d1a22]/[0.08] p-4 sm:p-5">
                  <AlertTriangle
                    className="mt-0.5 size-5 shrink-0 text-[#83322b]"
                    aria-hidden="true"
                  />
                  <div className="space-y-1.5">
                    <h2
                      id="delivery-notice"
                      className="font-mono text-[11px] uppercase tracking-[0.28em] text-[#83322b]"
                    >
                      Delivery notice
                    </h2>
                    <p className="text-sm leading-relaxed text-[#a89f8c]">
                      This page is documentation and delivery only.{" "}
                      <span className="text-[#cfc8b8]">
                        ENTITY_000 runs as a native desktop game inside the Godot
                        4.4+ engine.
                      </span>{" "}
                      Take a standalone build below — no Godot, no installation —
                      or the full project source. There is no browser version by
                      design.
                    </p>
                  </div>
                </div>
              </Reveal>
            </div>
          </section>

          {/* --------------------------------------------------------------- */
            /* Deliverables / downloads                                          */
          /* ---------------------------------------------------------------- */}
          <Section id="deliverables" index="01" className="scroll-mt-20">
            <SectionHeading
              index="01"
              kicker="DELIVERABLES"
              title="Take the artifact with you"
              description="Two files leave this page: the playable Godot project and the Phase 0 documentation set. Everything else is reading material."
            />

            <div className="grid gap-4 md:grid-cols-2 md:gap-6">
              {/* The standalone builds — what a player actually runs */}
              <Reveal delay={0.05}>
                <Card className="h-full gap-4 rounded-md border-[#2b2b2e] bg-[#141416] py-6 transition-colors hover:border-[#4a463f]">
                  <CardHeader className="px-6">
                    <div className="flex items-center justify-between gap-3">
                      <CardTitle className="font-mono text-base uppercase tracking-[0.22em] text-[#cfc8b8]">
                        STANDALONE BUILDS
                      </CardTitle>
                      <MonitorPlay
                        className="size-5 shrink-0 text-[#b08d3e]"
                        aria-hidden="true"
                      />
                    </div>
                    <CardDescription className="font-mono text-[10px] uppercase tracking-[0.22em] text-[#857d6c]">
                      WINDOWS X64 · LINUX X64 · RUN AND PLAY
                    </CardDescription>
                  </CardHeader>
                  <CardContent className="space-y-4 px-6">
                    <p className="text-sm leading-relaxed text-[#a89f8c]">
                      The playable game itself, exported from the current head —
                      rebuilt after the WB-26 playability pass with a real
                      input-driven playthrough of the full golden path (title to
                      ending, one honest death at the martyr, zero assists).
                    </p>
                    <ul className="space-y-1.5 font-mono text-[11px] leading-relaxed text-[#a89f8c]/90">
                      <li className="flex gap-2">
                        <span aria-hidden="true" className="text-[#b08d3e]">›</span>
                        WB-26 fixes inside: the rotor sequence (the game was
                        unwinnable), the toll settlement, whole-vessel respawns,
                        wounds that cross doors, the martyr&apos;s sealing chains.
                      </li>
                      <li className="flex gap-2">
                        <span aria-hidden="true" className="text-[#b08d3e]">›</span>
                        Unsigned indie download — if your OS warns, choose{" "}
                        <span className="text-[#cfc8b8]">keep</span>.
                      </li>
                    </ul>
                  </CardContent>
                  <div className="flex flex-col gap-2 px-4 sm:flex-row sm:gap-3 sm:px-6">
                    <a
                      href="/ENTITY_000_Windows_x64.zip"
                      download
                      aria-label="Download the ENTITY_000 Windows x64 standalone build"
                      className="inline-flex h-11 flex-1 items-center justify-center gap-2 rounded-sm border border-[#b08d3e]/50 bg-[#b08d3e]/10 px-6 font-mono text-[11px] uppercase tracking-[0.22em] text-[#b08d3e] transition-colors hover:border-[#b08d3e] hover:bg-[#b08d3e]/20"
                    >
                      <ArrowDownToLine aria-hidden="true" />
                      WINDOWS .ZIP
                    </a>
                    <a
                      href="/ENTITY_000_Linux_x64.zip"
                      download
                      aria-label="Download the ENTITY_000 Linux x64 standalone build"
                      className="inline-flex h-11 flex-1 items-center justify-center gap-2 rounded-sm border border-[#b08d3e]/50 bg-[#b08d3e]/10 px-6 font-mono text-[11px] uppercase tracking-[0.22em] text-[#b08d3e] transition-colors hover:border-[#b08d3e] hover:bg-[#b08d3e]/20"
                    >
                      <ArrowDownToLine aria-hidden="true" />
                      LINUX .ZIP
                    </a>
                  </div>
                </Card>
              </Reveal>

              {/* The Godot project */}
              <Reveal delay={0.05}>
                <Card className="h-full gap-4 rounded-md border-[#2b2b2e] bg-[#141416] py-6 transition-colors hover:border-[#4a463f]">
                  <CardHeader className="px-6">
                    <div className="flex items-center justify-between gap-3">
                      <CardTitle className="font-mono text-base uppercase tracking-[0.22em] text-[#cfc8b8]">
                        THE GODOT PROJECT
                      </CardTitle>
                      <FolderArchive
                        className="size-5 shrink-0 text-[#b08d3e]"
                        aria-hidden="true"
                      />
                    </div>
                    <CardDescription className="font-mono text-[10px] uppercase tracking-[0.22em] text-[#857d6c]">
                      SOURCE · GDSCRIPT · ART · AUDIO · DATA
                    </CardDescription>
                  </CardHeader>
                  <CardContent className="space-y-4 px-6">
                    <p className="text-sm leading-relaxed text-[#a89f8c]">
                      The complete vertical slice: code-first GDScript scenes,
                      synthesized audio, AI-generated painterly backdrops graded
                      by an in-engine post shader, and the data bibles that drive
                      the world.
                    </p>
                    <ul className="space-y-1.5 font-mono text-[11px] leading-relaxed text-[#a89f8c]/90">
                      <li className="flex gap-2">
                        <span aria-hidden="true" className="text-[#b08d3e]">›</span>
                        Requires Godot 4.4+. Extract, open{" "}
                        <code className="text-[#cfc8b8]">project.godot</code>, press{" "}
                        <code className="text-[#cfc8b8]">F5</code>.
                      </li>
                      <li className="flex gap-2">
                        <span aria-hidden="true" className="text-[#b08d3e]">›</span>
                        {projectSizeHint} · the{" "}
                        <code className="text-[#cfc8b8]">.godot/</code> import cache
                        is rebuilt on first launch.
                      </li>
                    </ul>
                  </CardContent>
                  <div className="px-6">
                    <Button
                      onClick={() => triggerDownload("project")}
                      disabled={busy === "project"}
                      aria-label="Download the ENTITY_000 Godot project archive"
                      className="h-11 w-full rounded-sm border border-[#b08d3e]/50 bg-[#b08d3e]/10 px-6 font-mono text-[11px] uppercase tracking-[0.22em] text-[#b08d3e] transition-colors hover:border-[#b08d3e] hover:bg-[#b08d3e]/20 sm:w-auto"
                    >
                      {busy === "project" ? (
                        <Loader2 className="animate-spin" aria-hidden="true" />
                      ) : (
                        <ArrowDownToLine aria-hidden="true" />
                      )}
                      {busy === "project" ? "PACKING…" : "DOWNLOAD .ZIP"}
                    </Button>
                  </div>
                </Card>
              </Reveal>

              {/* Phase 0 documentation */}
              <Reveal delay={0.12}>
                <Card className="h-full gap-4 rounded-md border-[#2b2b2e] bg-[#141416] py-6 transition-colors hover:border-[#4a463f]">
                  <CardHeader className="px-6">
                    <div className="flex items-center justify-between gap-3">
                      <CardTitle className="font-mono text-base uppercase tracking-[0.22em] text-[#cfc8b8]">
                        PHASE 0 DOCUMENTATION
                      </CardTitle>
                      <FileText
                        className="size-5 shrink-0 text-[#b08d3e]"
                        aria-hidden="true"
                      />
                    </div>
                    <CardDescription className="font-mono text-[10px] uppercase tracking-[0.22em] text-[#857d6c]">
                      PDF · SEVEN BOOKS · ONE DOCUMENT
                    </CardDescription>
                  </CardHeader>
                  <CardContent className="space-y-4 px-6">
                    <p className="text-sm leading-relaxed text-[#a89f8c]">
                      Game Design, World/Lore, Systems, Art, Narrative/Theology,
                      Technical Architecture, and the Vertical Slice Specification —
                      the full design bible behind the build.
                    </p>
                    <p
                      className="flex items-center gap-2 font-mono text-[11px] uppercase tracking-[0.18em]"
                      aria-live="polite"
                    >
                      <span
                        aria-hidden="true"
                        className={`h-1.5 w-1.5 rounded-full ${
                          docsStatus === "ready"
                            ? "bg-[#b08d3e]"
                            : docsStatus === "compiling"
                              ? "bg-[#83322b] animate-pulse"
                              : "bg-[#4a463f]"
                        }`}
                      />
                      <span
                        className={
                          docsStatus === "ready"
                            ? "text-[#a89f8c]"
                            : docsStatus === "compiling"
                              ? "text-[#83322b]"
                              : "text-[#857d6c]"
                        }
                      >
                        {docsStatus === "ready"
                          ? "PDF detected — ready"
                          : docsStatus === "compiling"
                            ? "Documentation is still compiling"
                            : "Checking for document…"}
                      </span>
                    </p>
                  </CardContent>
                  <div className="px-6">
                    <Button
                      onClick={() => triggerDownload("docs")}
                      disabled={busy === "docs"}
                      aria-label="Download the Phase 0 documentation PDF"
                      className="h-11 w-full rounded-sm border border-[#b08d3e]/50 bg-[#b08d3e]/10 px-6 font-mono text-[11px] uppercase tracking-[0.22em] text-[#b08d3e] transition-colors hover:border-[#b08d3e] hover:bg-[#b08d3e]/20 sm:w-auto"
                    >
                      {busy === "docs" ? (
                        <Loader2 className="animate-spin" aria-hidden="true" />
                      ) : (
                        <ArrowDownToLine aria-hidden="true" />
                      )}
                      {busy === "docs" ? "FETCHING…" : "DOWNLOAD PDF"}
                    </Button>
                  </div>
                </Card>
              </Reveal>
            </div>
          </Section>

          {/* --------------------------------------------------------------- */
            /* The vertical slice                                                */
          /* ---------------------------------------------------------------- */}
          <Section index="02">
            <SectionHeading
              index="02"
              kicker="THE VERTICAL SLICE"
              title="Nine acts, one question"
              description="A single continuous descent — from blank awakening to an ending that refuses to answer."
            />

            <Reveal>
              <div className="overflow-hidden rounded-md border border-[#2b2b2e] bg-[#141416]">
                <div className="flex items-center justify-between border-b border-[#2b2b2e] px-4 py-3 sm:px-5">
                  <p className="font-mono text-[10px] uppercase tracking-[0.28em] text-[#a89f8c]">
                    SLICE RECORD — 9 ACTS
                  </p>
                  <p className="font-mono text-[10px] uppercase tracking-[0.28em] text-[#857d6c]">
                    15–30 MIN
                  </p>
                </div>
                <ol className="e0-scroll max-h-96 overflow-y-auto">
                  {ACTS.map((act) => (
                    <li
                      key={act.n}
                      className="grid grid-cols-[3.25rem_1fr] gap-4 border-b border-[#2b2b2e]/60 px-4 py-4 last:border-b-0 sm:px-5"
                    >
                      <span
                        className="pt-1 font-mono text-xs tracking-[0.2em] text-[#b08d3e]"
                        aria-hidden="true"
                      >
                        {String(act.n).padStart(2, "0")}
                      </span>
                      <div>
                        <h3 className="e0-serif text-lg font-semibold leading-snug text-[#cfc8b8]">
                          <span className="sr-only">Act {act.n}: </span>
                          {act.name}
                        </h3>
                        <p className="mt-1 text-sm leading-relaxed text-[#a89f8c]">
                          {act.desc}
                        </p>
                      </div>
                    </li>
                  ))}
                </ol>
              </div>
            </Reveal>
          </Section>

          {/* --------------------------------------------------------------- */
            /* The five fundamentals                                             */
          /* ---------------------------------------------------------------- */}
          <Section index="03">
            <SectionHeading
              index="03"
              kicker="THE FIVE FUNDAMENTALS"
              title="The laws the City runs on"
              description="Every mechanic in the slice is one of five laws taken literally."
            />

            <div className="grid gap-4 sm:grid-cols-2 lg:grid-cols-3">
              {FUNDAMENTALS.map((f, i) => (
                <Reveal key={f.name} delay={i * 0.05}>
                  <Card className="h-full gap-3 rounded-md border-[#2b2b2e] bg-[#141416] py-5 transition-colors hover:border-[#4a463f]">
                    <CardHeader className="px-5">
                      <p className="font-mono text-[10px] tracking-[0.3em] text-[#857d6c]">
                        {String(i + 1).padStart(2, "0")}
                      </p>
                      <CardTitle className="font-mono text-sm uppercase tracking-[0.28em] text-[#cfc8b8]">
                        {f.name}
                      </CardTitle>
                    </CardHeader>
                    <CardContent className="px-5">
                      <p className="e0-serif text-base italic leading-relaxed text-[#a89f8c]">
                        “{f.quote}”
                      </p>
                    </CardContent>
                  </Card>
                </Reveal>
              ))}

              {/* quiet system note to close the grid */}
              <Reveal delay={0.25}>
                <div
                  aria-hidden="true"
                  className="flex h-full flex-col items-start justify-between gap-4 rounded-md border border-dashed border-[#2b2b2e] bg-transparent p-5"
                >
                  <Lock className="size-4 text-[#857d6c]" />
                  <p className="font-mono text-[11px] leading-relaxed tracking-[0.14em] text-[#857d6c]">
                    {"// there is a sixth fundamental."}
                    <br />
                    {"// it is withheld."}
                  </p>
                </div>
              </Reveal>
            </div>
          </Section>

          {/* --------------------------------------------------------------- */
            /* Systems deep-dive                                                */
          /* ---------------------------------------------------------------- */}
          <Section index="04">
            <SectionHeading
              index="04"
              kicker="SYSTEMS DEEP-DIVE"
              title="How the world pushes back"
              description="Four interlocking systems turn reading the world into the game itself."
            />

            <Reveal>
              <Tabs defaultValue="observe" className="gap-6">
                <TabsList className="h-auto w-full grid-cols-2 gap-1 rounded-md border border-[#2b2b2e] bg-[#141416] p-1 sm:inline-flex sm:w-auto">
                  <TabsTrigger
                    value="observe"
                    className="h-11 rounded-sm font-mono text-[11px] uppercase tracking-[0.18em] text-[#a89f8c] data-[state=active]:bg-[#2b2b2e] data-[state=active]:text-[#cfc8b8] sm:h-9"
                  >
                    OBSERVE
                  </TabsTrigger>
                  <TabsTrigger
                    value="consistency"
                    className="h-11 rounded-sm font-mono text-[11px] uppercase tracking-[0.18em] text-[#a89f8c] data-[state=active]:bg-[#2b2b2e] data-[state=active]:text-[#cfc8b8] sm:h-9"
                  >
                    CONSISTENCY
                  </TabsTrigger>
                  <TabsTrigger
                    value="belief"
                    className="h-11 rounded-sm font-mono text-[11px] uppercase tracking-[0.18em] text-[#a89f8c] data-[state=active]:bg-[#2b2b2e] data-[state=active]:text-[#cfc8b8] sm:h-9"
                  >
                    BELIEF
                  </TabsTrigger>
                  <TabsTrigger
                    value="memory"
                    className="h-11 rounded-sm font-mono text-[11px] uppercase tracking-[0.18em] text-[#a89f8c] data-[state=active]:bg-[#2b2b2e] data-[state=active]:text-[#cfc8b8] sm:h-9"
                  >
                    MEMORY
                  </TabsTrigger>
                </TabsList>

                {/* OBSERVE ------------------------------------------------- */}
                <TabsContent value="observe">
                  <div className="space-y-5 rounded-md border border-[#2b2b2e] bg-[#141416] p-5 sm:p-6">
                    <p className="text-sm leading-relaxed text-[#a89f8c]">
                      Enter{" "}
                      <span className="font-mono text-[#7fd8d8]/90">OBSERVE</span> to
                      read any entity’s true data — ID, TYPE, STATE, PROPERTIES,
                      PURPOSE. Modify what is modifiable:{" "}
                      <code className="rounded-sm bg-[#0d0d0f] px-1.5 py-0.5 font-mono text-xs text-[#b08d3e]">
                        locked=false
                      </code>{" "}
                      opens the door. The world obeys. Then it bills you.
                    </p>

                    <div className="overflow-hidden rounded-md border border-[#2b2b2e] bg-[#0d0d0f]">
                      <p className="border-b border-[#2b2b2e] px-4 py-2 font-mono text-[10px] uppercase tracking-[0.28em] text-[#857d6c]">
                        OBSERVE READOUT — SAMPLE
                      </p>
                      <div className="e0-scroll space-y-0 overflow-x-auto px-4 py-4 font-mono text-xs leading-6 text-[#a89f8c]">
                        <p>
                          <span className="text-[#7fd8d8]/90">{">"} OBSERVE</span>
                          {" — TARGET: DOOR_029"}
                        </p>
                        <p>{"  ID.......... ENTITY_0142"}</p>
                        <p>{"  TYPE........ DOOR"}</p>
                        <p>{"  STATE....... SEALED"}</p>
                        <p>
                          {"  PROPERTIES.. "}
                          <span className="text-[#b08d3e]">locked=true</span>
                          {" · material=stone · warded=false"}
                        </p>
                        <p>{"  PURPOSE..... “Remain closed.”"}</p>
                        <p className="pt-4">
                          <span className="text-[#7fd8d8]/90">{">"} MODIFY</span>
                          {" → "}
                          <span className="text-[#b08d3e]">locked=false</span>
                        </p>
                        <p>{"  ............ ACK. THE DOOR OPENS."}</p>
                        <p>
                          {"  ............ "}
                          <span className="text-[#83322b]">CONSISTENCY −6.</span>
                        </p>
                      </div>
                    </div>

                    <p className="font-mono text-[11px] leading-relaxed text-[#857d6c]">
                      Every edit is paid for in consistency. See the hunted model →
                    </p>
                  </div>
                </TabsContent>

                {/* CONSISTENCY --------------------------------------------- */}
                <TabsContent value="consistency">
                  <div className="space-y-5 rounded-md border border-[#2b2b2e] bg-[#141416] p-5 sm:p-6">
                    <p className="text-sm leading-relaxed text-[#a89f8c]">
                      Consistency is the price of power. It drains with every edit you
                      make to reality — and the world notices in stages.
                    </p>

                    <div className="overflow-hidden rounded-md border border-[#2b2b2e]">
                      <Table>
                        <TableHeader>
                          <TableRow className="border-[#2b2b2e] bg-[#0d0d0f] hover:bg-[#0d0d0f]">
                            <TableHead className="font-mono text-[10px] uppercase tracking-[0.22em] text-[#857d6c]">
                              Consistency
                            </TableHead>
                            <TableHead className="font-mono text-[10px] uppercase tracking-[0.22em] text-[#857d6c]">
                              Stage
                            </TableHead>
                            <TableHead className="font-mono text-[10px] uppercase tracking-[0.22em] text-[#857d6c]">
                              Reality’s response
                            </TableHead>
                          </TableRow>
                        </TableHeader>
                        <TableBody>
                          {CONSISTENCY_STAGES.map((row) => (
                            <TableRow
                              key={row.range}
                              className="border-[#2b2b2e]/60 hover:bg-[#0d0d0f]"
                            >
                              <TableCell className="whitespace-nowrap font-mono text-xs text-[#cfc8b8]">
                                {row.range}
                              </TableCell>
                              <TableCell
                                className={`font-mono text-[11px] uppercase tracking-[0.16em] ${
                                  row.danger === 2
                                    ? "text-[#83322b]"
                                    : row.danger === 1
                                      ? "text-[#b08d3e]"
                                      : "text-[#a89f8c]"
                                }`}
                              >
                                {row.stage}
                              </TableCell>
                              <TableCell className="text-sm leading-relaxed text-[#a89f8c]">
                                {row.response}
                              </TableCell>
                            </TableRow>
                          ))}
                        </TableBody>
                      </Table>
                    </div>

                    <p className="text-sm leading-relaxed text-[#a89f8c]">
                      <span className="font-mono text-xs uppercase tracking-[0.2em] text-[#cfc8b8]">
                        ANCHORS
                      </span>{" "}
                      restore{" "}
                      <span className="font-mono text-xs text-[#b08d3e]">+12</span>{" "}
                      consistency. They are also your save shrines — spend them
                      wisely, and never while something is walking toward you.
                    </p>
                  </div>
                </TabsContent>

                {/* BELIEF -------------------------------------------------- */}
                <TabsContent value="belief">
                  <div className="space-y-5 rounded-md border border-[#2b2b2e] bg-[#141416] p-5 sm:p-6">
                    <p className="text-sm leading-relaxed text-[#a89f8c]">
                      Chanters are not scenery. Every believer who chants feeds the
                      ward’s belief gauge; the ward exists only while the gauge holds.
                      Stop the chant — stop the physics.
                    </p>

                    <div className="rounded-md border border-[#2b2b2e] bg-[#0d0d0f] p-4">
                      <div className="flex items-center justify-between gap-4">
                        <p className="font-mono text-[10px] uppercase tracking-[0.24em] text-[#857d6c]">
                          WARD INTEGRITY
                        </p>
                        <p className="font-mono text-[10px] uppercase tracking-[0.24em] text-[#a89f8c]">
                          71% · HELD BY 12 CHANTERS
                        </p>
                      </div>
                      <div
                        className="mt-3 flex gap-1"
                        role="img"
                        aria-label="Ward belief gauge at 71 percent, held by twelve chanters"
                      >
                        {Array.from({ length: 12 }, (_, i) => (
                          <span
                            key={i}
                            aria-hidden="true"
                            className={`h-3 flex-1 rounded-[1px] ${
                              i < 8 ? "bg-[#b08d3e]/80" : "bg-[#2b2b2e]"
                            }`}
                          />
                        ))}
                      </div>
                    </div>

                    <p className="text-sm leading-relaxed text-[#a89f8c]">
                      The altar choice: accept the Pale Saint’s blessing —{" "}
                      <span className="font-mono text-xs text-[#b08d3e]">+1 max HP</span>
                      , permanent — or shatter the reliquary and empower the world’s
                      belief instead. The City remembers either way.
                    </p>
                  </div>
                </TabsContent>

                {/* MEMORY -------------------------------------------------- */}
                <TabsContent value="memory">
                  <div className="space-y-5 rounded-md border border-[#2b2b2e] bg-[#141416] p-5 sm:p-6">
                    <p className="text-sm leading-relaxed text-[#a89f8c]">
                      Memory fragments are found in the world and indexed in the
                      pause menu — where they can be read, corrupted, and
                      contradicted. The liturgy says the Martyr volunteered. The
                      archive log says otherwise. Both are in your inventory now.
                    </p>

                    <div className="overflow-hidden rounded-md border border-[#2b2b2e] bg-[#0d0d0f]">
                      <p className="border-b border-[#2b2b2e] px-4 py-2 font-mono text-[10px] uppercase tracking-[0.28em] text-[#857d6c]">
                        MEMORY INDEX — PAUSE MENU
                      </p>
                      <ul className="e0-scroll max-h-48 overflow-y-auto">
                        {MEMORY_FRAGMENTS.map((fragment) => (
                          <li
                            key={fragment.id}
                            className="space-y-1 border-b border-[#2b2b2e]/60 px-4 py-3 last:border-b-0"
                          >
                            <div className="flex flex-wrap items-center justify-between gap-2">
                              <p className="font-mono text-xs text-[#cfc8b8]">
                                {fragment.id}
                                <span className="text-[#857d6c]"> — </span>
                                {fragment.title}
                              </p>
                              <p
                                className={`font-mono text-[10px] uppercase tracking-[0.18em] ${
                                  fragment.tone === "bad"
                                    ? "text-[#83322b]"
                                    : "text-[#857d6c]"
                                }`}
                              >
                                {fragment.state}
                              </p>
                            </div>
                            <p className="e0-serif text-sm italic text-[#a89f8c]">
                              {fragment.note}
                            </p>
                          </li>
                        ))}
                      </ul>
                    </div>
                  </div>
                </TabsContent>
              </Tabs>
            </Reveal>
          </Section>

          {/* --------------------------------------------------------------- */
            /* Bestiary                                                          */
          /* ---------------------------------------------------------------- */}
          <Section index="05">
            <SectionHeading
              index="05"
              kicker="BESTIARY"
              title="What walks the City of Ash"
              description="Not all of it can be fought. Some of it should not be read."
            />

            <div className="grid gap-4 sm:grid-cols-2 lg:grid-cols-3">
              {BESTIARY.map((entry, i) => (
                <Reveal key={entry.name} delay={i * 0.05}>
                  <Card className="h-full gap-3 rounded-md border-[#2b2b2e] bg-[#141416] py-5 transition-colors hover:border-[#4a463f]">
                    <CardHeader className="px-5">
                      <div className="flex items-center justify-between gap-3">
                        <CardTitle className="font-mono text-sm uppercase tracking-[0.22em] text-[#cfc8b8]">
                          {entry.name}
                        </CardTitle>
                        <entry.icon
                          className="size-4 shrink-0 text-[#857d6c]"
                          aria-hidden="true"
                        />
                      </div>
                      <p className="font-mono text-[10px] uppercase tracking-[0.24em] text-[#83322b]">
                        {entry.cls}
                      </p>
                    </CardHeader>
                    <CardContent className="px-5">
                      <p className="text-sm leading-relaxed text-[#a89f8c]">
                        {entry.desc}
                      </p>
                    </CardContent>
                  </Card>
                </Reveal>
              ))}
            </div>
          </Section>

          <Section id="proofs" index="06">
            <SectionHeading
              index="06"
              kicker="VISUAL PROOFS"
              title="The reconstruction pass, on the record"
              description="Real in-engine gameplay renders from the running game (1280×720 viewport). The visual reconstruction pass, then five world-building passes: THE LIVING CITY (far processions, measured strikes, ceremonies), THE CLOSEST WALLS (the foreground plane at 1.28x), THE GROUND YOU WALK ON (rendered climb ledges, per-district floorcraft, contact shadows), THE PERFORMERS (walk laws, wound cards, death as rotation, presence pools), THE WORLD RESPONDS (skirting stones, the ground answering fire, focal shafts, moths, vermin, ripples, posted law) — and THE RECORD IS A THING: the diegetic interface pass, where the HUD becomes a brass instrument, dialogue a hung parchment census record, system messages stamped citations, the OBSERVE readout a ruled ledger page with rows sealed under wax. Then the world kept deepening: THE AIR ITSELF (a positional sound stage on every element — flames that crackle, hearts that hum, bells that toll on their own seeded clocks), THE ARRIVAL (no space is born pre-lit — every room wakes near-first, flares and settles; revisits are quick because the city remembers), THE WORLD THINS (the core mechanic reaches the world's own renderers — flames lose conviction and miss beats, moths leave, the vessel stays real as the grade drains), THE THRESHOLD (the crossing between acts is a three-beat rite — the leaving, the inscribed rubric in the dark, the coming), THE VESSEL'S TRACE (every floor records the walker in its own material — ash holds, wet glistens, carpet presses lighter, the engine records nothing), THE OTHERS' PASSAGE (every creature writes the floor in the language of its body — the hollow's metronome echo, the believer's shuffle, the censor's erasure), THE ENDING'S RECORD (the floor keeps a bounded ledger of endings — organic sprawls, frozen last strides, where he fell), THE EXPERIENCE PASS (everything that already exists made truer — third rim bake, woven materials, tiled stone, the map's ink spline), THE FIST THAT LANDS (the motion experience pass — telegraphs read first, the roll is a decision, the chain speaks in arcs), THE THREE BEATS (every hit its own clock — the gather, the step-through, the dash's spent image), THE WALKING FLOCK (the weight pass — the body rides its stride, each walker out of step), THE CENSER'S EDGE (the readability pass — the fourth rim bake lifts the congregation's gold edge, the robe answers its censer in warm light, the body leans into its walk, the pool burns at every footfall), THE PRESS KEEPS ITS COUNT (the cluster pass — the honest audit found five converged bodies stacked at 0.0 px gap for seven straight seconds, reading as empty space; the jostle now holds a robe's width and shoulder room between every living body, the strike carries through the crowd, and the chapel fills with its own incense at the bodies' height so the architecture sits one step deeper), and THE FURNITURE YIELDS (the figure-vs-architecture grammar pass — the audit traced 1 of 5 bodies at the busiest wall and read the mass as 'twisted brass ornament'; the rim's closed gold ring broke into a shoulder arc, the fifth rim bake went top-lit so light catches the crown while the robe falls away dark, the hood keeps a warm glint where a face would catch the censer's light, the flame-holders' halos and brass sat down, and the altar glow lifted off the body band at a softer voice — the same wall now traces 5 of 5 at 7/10), and THE CORNER YIELDS (the corner pass — the ward's belief was computed from a chanters array that nothing ever fed, so the barrier silently collapsed on the room's first frame every visit since it shipped; the flock is wired now and the ward LIVES — a curtain of belief with soft wings and a breathing crown that the audit reads as 'a magical seal', while the painted procession hangs smaller and deeper in the room's air, the chandelier's wax dims and its glow spreads wide like the wheel it is, the arches sit one step deeper, the painted congregation exhales its rising chant-marks again, and the distant rows read as living people at 7/10 with the statues sorted out on their own), and THE PILE KEEPS ITS COUNT (the dead-end pass — the cornered press's settled line sat at 12-21px gaps because the windup planted walkers MID-OVERLAP and the packed queue transmitted its full walk down the chain into the backs ahead; the plant now waits for a robe's width of its own ground and the packed line creeps, so the corner's median standing gap is 25.8px and the audit traces 5 of 5 — while the 'chantry jamb's pale saint' the audits kept tracing turned out to be the backdrop's own painted namesake, tiled to giant scale and outshining even the believers' lit hoods; she keeps her silhouette, her pose and her altar, dimmed to the architecture's own voice), and THE PLAYER'S OWN HANDS (the playability pass — a virtual player walked the full golden path with real key events, title to ending, and the game broke six honest ways: the rotor sequence wrote into a read-only const tree so THE GAME WAS UNWINNABLE, the toll settlement charged its price and never opened, every door was a full heal, death restored a hurt save's hp forever with no healing anywhere, the boss fight could be walked around entirely, and the test suite's own saves haunted the next session's CONTINUE — all six eradicated, each under its own regression law, and the playthrough now completes unassisted with one honest death at the martyr), and THE LAST FRAME (the ending-surface pass — the frames the player arrives at and leaves on had never been audited: the settlement's crimson verdict was printing 1.6px under the [F] prompt, two lines through each other on the run's final beat; the death card's small line hung as bare type over the architecture with the roofline reading through it; and a room card still holding its fade would sit on top of a dialogue sheet — the AFTERMATH card printed through the monument's ending lines. The verdict, the prompt and the credit now hold their own rows, the death card rides the same feathered plate the room card always had, and the record outranks the marquee — a card dissolves the moment dialogue rises), and THE RECORD SPEAKS (the text-integrity pass — the city's own words had never been proofread as published text: the census stele struck FOUR of the four inhabitants its own observed record still called living, the mural notice named a 'CHANTY WALL' that exists nowhere else in the record, the gold-leaf law's street was abbreviated into a different street, and — deepest — the observe ledger's single-line economy was ellipsizing every MEMORY row at ~29 characters, hiding most of the record's richest text layer behind its own economy: 34 of the record's memories run longer, and the screaming cradle two strides from the vessel's birth read 'eleven opened early. one of…'. The memory now wraps onto ruled lines — hanging indent, at most four, the census ellipsis surviving only past the cap — and the suite laws the whole corpus: every entity and inscription memory survives the wrap without loss, and no string publishes with a ghost spelling, a renamed street or dirty typography), and THE SECOND HAND (the gamepad experience pass — the pad was always playable but the world spoke only the keyboard's names: a plaque that said F to a hand holding A, census messages that insisted on [TAB] for a stick that answers Y. The hand that last spoke now owns every label — the plaque's keycap, the dialogue's FILE stamp, the reading sheet's close hint, the observe margins, the options and map footers, the system messages themselves. The pass also found the pause was never a hold — the world ran behind the veil, a probe walking the vessel 260px in a one-second paused hold while enemies struck and the boss's aura drained; the world is PAUSABLE now. And the pad's one A button, which the title always promised as 'A JUMP/INTERACT', fired both at once — a hop with every communion and the door's −6 consistency spent by accident; standing at a record the press now files, and the vessel does not leap. The bilingual README teaches the pad's whole map at last — including that X attacks). Every render is from the live game under a virtual display; every pass was VLM-audited before shipping. Procedural rigs remain in the build as a debug fallback (F9 in game)."
            />
            <div className="grid gap-4 sm:grid-cols-2 lg:grid-cols-3">
              {VISUAL_PROOFS.map((proof) => (
                <Reveal key={proof.file}>
                  <ProofShot proof={proof} />
                </Reveal>
              ))}
            </div>
          </Section>

          {/* --------------------------------------------------------------- */
            /* Controls                                                          */
          /* ---------------------------------------------------------------- */}
          <Section index="07">
            <SectionHeading
              index="07"
              kicker="CONTROLS"
              title="Hands on the vessel"
              description="One verbs set for a body you did not choose. Keyboard and gamepad are first-class — full pad navigation, vibration scaled from the options screen, external hands announced in the system log."
            />

            <Reveal>
              <div className="grid gap-x-8 rounded-md border border-[#2b2b2e] bg-[#141416] p-2 sm:grid-cols-2 sm:p-4">
                {CONTROLS.map((control) => (
                  <div
                    key={control.action}
                    className="flex items-center justify-between gap-4 border-b border-[#2b2b2e]/60 px-3 py-3 last:border-b-0 sm:last:border-b sm:[&:nth-last-child(2)]:border-b-0"
                  >
                    <span className="flex items-center gap-2">
                      <kbd className="rounded-sm border border-[#2b2b2e] bg-[#0d0d0f] px-2.5 py-1.5 font-mono text-[11px] tracking-[0.08em] text-[#cfc8b8]">
                        {control.binding}
                      </kbd>
                      <span className="font-mono text-[10px] tracking-[0.08em] text-[#4a463f]">/</span>
                      <kbd className="rounded-sm border border-[#3b2f4a] bg-[#0d0d0f] px-2.5 py-1.5 font-mono text-[11px] tracking-[0.08em] text-[#a89f8c]">
                        {control.pad}
                      </kbd>
                    </span>
                    <span className="font-mono text-[10px] uppercase tracking-[0.24em] text-[#a89f8c]">
                      {control.action}
                    </span>
                  </div>
                ))}
              </div>
            </Reveal>
          </Section>

          {/* --------------------------------------------------------------- */
            /* Palette                                                           */
          /* ---------------------------------------------------------------- */}
          <Section index="08" last>
            <SectionHeading
              index="08"
              kicker="PALETTE"
              title="The color of a burned world"
              description="Ash, bone, blood, and one system color the world was never meant to show."
            />

            <Reveal>
              <div className="grid grid-cols-4 gap-2 sm:grid-cols-6 lg:grid-cols-11">
                {PALETTE.map((swatch) => (
                  <figure key={swatch.hex} className="space-y-2">
                    <div
                      role="img"
                      aria-label={`${swatch.name} color swatch, hex ${swatch.hex}`}
                      className="h-12 w-full rounded-sm border border-[#2b2b2e]"
                      style={{ backgroundColor: swatch.hex }}
                    />
                    <figcaption className="font-mono text-[9px] uppercase leading-relaxed tracking-[0.08em]">
                      <span className="block text-[#cfc8b8]">{swatch.name}</span>
                      <span className="block text-[#857d6c]">{swatch.hex}</span>
                    </figcaption>
                  </figure>
                ))}
              </div>
            </Reveal>
          </Section>
        </main>

        {/* ----------------------------------------------------------------- */
          /* Footer (sticky to viewport bottom)                                 */
        /* ---------------------------------------------------------------- */}
        <footer className="mt-auto border-t border-[#2b2b2e] pb-[env(safe-area-inset-bottom)]">
          <div className="mx-auto flex max-w-6xl flex-col gap-3 px-4 py-8 sm:flex-row sm:items-center sm:justify-between sm:px-6">
            <p className="e0-serif text-base italic text-[#a89f8c]">
              ENTITY_000 — a game first, a system second, a mystery throughout.
            </p>
            <p className="font-mono text-[10px] uppercase tracking-[0.24em] text-[#857d6c]">
              NATIVE GODOT 4.4+ · GDSCRIPT · VERTICAL SLICE · 2026
            </p>
          </div>
        </footer>

        {/* ----------------------------------------------------------------- */
          /* The Archivist — the Bureau's records keeper answers (fixed)      */
        /* ---------------------------------------------------------------- */}
        <AnimatePresence>
          {chatOpen && (
            <motion.section
              key="archivist-panel"
              role="dialog"
              aria-label="The Archivist — ask about ENTITY_000"
              initial={{ opacity: 0, y: 16, scale: 0.98 }}
              animate={{ opacity: 1, y: 0, scale: 1 }}
              exit={{ opacity: 0, y: 16, scale: 0.98 }}
              transition={{ duration: 0.18, ease: "easeOut" }}
              className="fixed inset-x-3 bottom-[calc(1.25rem+env(safe-area-inset-bottom))] z-50 flex h-[min(68vh,540px)] flex-col overflow-hidden rounded-md border border-[#3a352c] bg-[#111113]/95 shadow-2xl shadow-black/60 backdrop-blur sm:inset-x-auto sm:right-6 sm:w-[400px]"
            >
              <header className="flex items-center justify-between gap-3 border-b border-[#2b2b2e] bg-[#141416] px-4 py-3">
                <div className="flex min-w-0 items-center gap-3">
                  <span className="relative flex size-2 shrink-0">
                    <span className="absolute inline-flex h-full w-full animate-ping rounded-full bg-[#b08d3e] opacity-60" />
                    <span className="relative inline-flex size-2 rounded-full bg-[#b08d3e]" />
                  </span>
                  <div className="min-w-0">
                    <p className="font-mono text-[11px] uppercase tracking-[0.22em] text-[#cfc8b8]">
                      THE ARCHIVIST
                    </p>
                    <p className="truncate font-mono text-[9px] uppercase tracking-[0.18em] text-[#857d6c]">
                      بایگانی‌بان · BUREAU OF THE COUNT
                    </p>
                  </div>
                </div>
                <div className="flex items-center gap-1">
                  <button
                    type="button"
                    onClick={resetArchivist}
                    aria-label="Clear the conversation"
                    className="flex size-9 items-center justify-center rounded-sm text-[#857d6c] transition-colors hover:bg-[#1e1e21] hover:text-[#cfc8b8]"
                  >
                    <RotateCcw className="size-4" aria-hidden="true" />
                  </button>
                  <button
                    type="button"
                    onClick={() => setChatOpen(false)}
                    aria-label="Close the Archivist"
                    className="flex size-9 items-center justify-center rounded-sm text-[#857d6c] transition-colors hover:bg-[#1e1e21] hover:text-[#cfc8b8]"
                  >
                    <X className="size-4" aria-hidden="true" />
                  </button>
                </div>
              </header>

              <div
                ref={chatScrollRef}
                aria-live="polite"
                aria-label="Conversation with the Archivist"
                className="e0-scroll flex-1 space-y-3 overflow-y-auto px-4 py-4"
              >
                {chatMessages.map((m, i) => {
                  const isTyping =
                    m.role === "assistant" &&
                    m.content === "" &&
                    i === chatMessages.length - 1 &&
                    chatBusy;
                  return (
                    <div
                      key={i}
                      dir="auto"
                      className={`flex flex-col ${
                        m.role === "user" ? "items-end" : "items-start"
                      }`}
                    >
                      {isTyping ? (
                        <div
                          className="flex items-center gap-1.5 rounded-sm border border-[#2b2b2e] bg-[#18181b] px-3.5 py-3"
                          aria-label="The Archivist is writing"
                        >
                          <span className="e0-ink-dot size-1.5 rounded-full bg-[#b08d3e]" />
                          <span className="e0-ink-dot size-1.5 rounded-full bg-[#b08d3e]" />
                          <span className="e0-ink-dot size-1.5 rounded-full bg-[#b08d3e]" />
                        </div>
                      ) : (
                        <div
                          className={`max-w-[88%] whitespace-pre-wrap rounded-sm border px-3.5 py-2.5 text-[13px] leading-relaxed ${
                            m.role === "user"
                              ? "border-[#b08d3e]/40 bg-[#b08d3e]/10 text-[#e8dfc8]"
                              : "border-[#2b2b2e] bg-[#18181b] text-[#cfc8b8]"
                          }`}
                        >
                          {m.role === "user"
                            ? m.content
                            : scrubArchivistText(m.content)}
                        </div>
                      )}
                    </div>
                  );
                })}
                {chatMessages.length <= 1 && !chatBusy && (
                  <div className="flex flex-wrap gap-2 pt-1">
                    {ARCHIVIST_PROMPTS.map((p) => (
                      <button
                        key={p.label}
                        type="button"
                        onClick={() => askArchivist(p.question)}
                        className="rounded-sm border border-[#3a352c] bg-transparent px-2.5 py-1.5 font-mono text-[10px] uppercase tracking-[0.12em] text-[#a89f8c] transition-colors hover:border-[#b08d3e]/60 hover:text-[#cfc8b8]"
                      >
                        {p.label}
                      </button>
                    ))}
                  </div>
                )}
              </div>

              <form
                onSubmit={(e) => {
                  e.preventDefault();
                  askArchivist(chatInput);
                }}
                className="border-t border-[#2b2b2e] bg-[#141416] p-3"
              >
                <div className="flex items-end gap-2">
                  <label htmlFor="archivist-input" className="sr-only">
                    Ask the Archivist
                  </label>
                  <textarea
                    id="archivist-input"
                    ref={chatInputRef}
                    rows={1}
                    dir="auto"
                    value={chatInput}
                    onChange={(e) => {
                      setChatInput(e.target.value);
                      e.target.style.height = "auto";
                      e.target.style.height = `${Math.min(e.target.scrollHeight, 112)}px`;
                    }}
                    onKeyDown={(e) => {
                      if (e.key === "Enter" && !e.shiftKey) {
                        e.preventDefault();
                        askArchivist(chatInput);
                      }
                    }}
                    placeholder="Write to the records… / بنویس…"
                    maxLength={600}
                    className="e0-scroll max-h-28 min-h-11 flex-1 resize-none rounded-sm border border-[#2b2b2e] bg-[#0d0d0f] px-3 py-2.5 text-base leading-relaxed text-[#e8dfc8] placeholder:text-[#5c574c] focus:border-[#b08d3e]/60 focus:outline-none sm:text-[13px]"
                  />
                  <button
                    type="submit"
                    disabled={chatBusy || !chatInput.trim()}
                    aria-label="Send message to the Archivist"
                    className="flex size-11 shrink-0 items-center justify-center rounded-sm border border-[#b08d3e]/50 bg-[#b08d3e]/10 text-[#b08d3e] transition-colors hover:border-[#b08d3e] hover:bg-[#b08d3e]/20 disabled:cursor-not-allowed disabled:opacity-40"
                  >
                    {chatBusy ? (
                      <Loader2 className="size-4 animate-spin" aria-hidden="true" />
                    ) : (
                      <Send className="size-4" aria-hidden="true" />
                    )}
                  </button>
                </div>
              </form>
            </motion.section>
          )}
        </AnimatePresence>

        <AnimatePresence>
          {!chatOpen && (
            <motion.button
              key="archivist-button"
              type="button"
              onClick={() => {
                setChatOpen(true);
                setChatSeen(true);
              }}
              initial={{ opacity: 0, y: 12 }}
              animate={{ opacity: 1, y: 0 }}
              exit={{ opacity: 0, y: 12 }}
              transition={{ duration: 0.18 }}
              aria-label="Ask the Archivist about ENTITY_000"
              className={`fixed bottom-[calc(1.25rem+env(safe-area-inset-bottom))] right-4 z-50 flex h-12 items-center gap-2.5 rounded-sm border border-[#b08d3e]/60 bg-[#141416]/95 px-4 font-mono text-[11px] uppercase tracking-[0.18em] text-[#b08d3e] shadow-lg shadow-black/50 backdrop-blur transition-colors hover:border-[#b08d3e] hover:bg-[#1a1712] sm:right-6 ${
                chatSeen ? "" : "e0-archivist-beckon"
              }`}
            >
              <MessagesSquare className="size-4 shrink-0" aria-hidden="true" />
              <span className="hidden sm:inline">ASK THE ARCHIVIST</span>
              <span className="sm:hidden">ARCHIVIST</span>
            </motion.button>
          )}
        </AnimatePresence>
      </div>
    </MotionConfig>
  );
}
