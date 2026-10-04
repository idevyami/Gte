#!/bin/bash
# Convert the visual-proof PNGs (in-engine renders) to web-friendly JPEGs
# for the delivery hub gallery.
set -e
SRC=/home/z/entity000/screenshots
DST=/home/z/my-project/public/screenshots
mkdir -p "$DST"
python3 - << 'EOF'
import os
from PIL import Image
src = "/home/z/entity000/screenshots"
dst = "/home/z/my-project/public/screenshots"
os.makedirs(dst, exist_ok=True)
names = [
    "01_player_gameplay", "02_hollow", "03_believers", "04_censor",
    "05_martyr_p1", "06_martyr_p2", "07_martyr_p3", "08_penitent",
    "09_city_of_ash", "10_chapel", "11_archive", "12_engine_sanctum",
    "13_colonnade", "14_sanctuary", "15_machines",
    "16_measurer_oren", "17_null_children",
    "18_room_card", "19_boss_intro", "20_atmosphere",
    "21_depth", "22_options",
    "23_records",
    "24_inscription", "25_reading", "25b_reading_full", "26_city_map",
    "27_district_stamp", "28_archive_records", "29_margin_note",
    # WB-4: the living city
    "wb4_01_city_procession", "wb4_02_barge_birds", "wb4_03_telegraph_ring",
    "wb4_04a_anticipation", "wb4_04b_strike", "wb4_04c_follow_through",
    "wb4_05a_roll_tumble", "wb4_06a_oren_bow", "wb4_06b_oren_counter",
    "wb4_07_chapel_gallery", "wb4_08_kneel_breath", "wb4_09a_engine_gang",
    "wb4_10_aftermath_mourners", "wb4_11_anchor_ceremony", "wb4_12_observe_zoom",
    # WB-5: the closest walls
    "wb5_00_city_no_fg", "wb5_01_city_closest_walls",
    "wb5_02a_slide_mid", "wb5_02b_slide_late",
    "wb5_03_womb_sky_band", "wb5_04_undercity_grates",
    "wb5_05_null_walk", "wb5_06_chapel_censer",
    "wb5_07_archive_pages", "wb5_08_engine_gantry",
    "wb5_09_reliquary_arena", "wb5_10_aftermath_rubble",
    "wb5_11_censor_unfurl", "wb5_12_censor_reach",
    # WB-6: the ground you walk on
    "wb6_00_climb_before", "wb6_01_climb_ledges", "wb6_01b_on_the_ledge",
    "wb6_03_shadow_airborne", "wb6_04_chapel_carpet",
    "wb6_05_undercity_damp", "wb6_06_archive_pages",
    "wb6_07_engine_plates", "wb6_08_heart_dried",
    "wb6_09_reliquary_inlay", "wb6_10_aftermath_broken",
    # WB-7: the performers
    "wb7_01_hollow_walk", "wb7_02_hollow_walk_late",
    "wb7_03_strike_woundcard", "wb7_05a_death_stun",
    "wb7_05b_death_buckle", "wb7_05c_death_goingdown",
    "wb7_05d_death_prone", "wb7_05e_death_dissolve",
    "wb7_06_oren_talk", "wb7_06b_oren_idle",
    "wb7_07_believers_prayer", "wb7_08_boss_sway",
    "wb7_08b_boss_sway_late", "wb7_09_presence_pools",
    "wb7_10_readability", "wb7_11_readability_lit",
    # WB-8: the world responds
    "wb8_01_the_marriage", "wb8_02_ground_answers_fire",
    "wb8_03_focal_shaft", "wb8_04a_moths_settled",
    "wb8_04b_moths_scattered", "wb8_05a_vermin_patrol",
    "wb8_05b_vermin_flee", "wb8_06_ripple",
    "wb8_07_posted_law", "wb8_08_reliquary_goldline",
]
for n in names:
    p = os.path.join(src, n + ".png")
    if not os.path.isfile(p):
        print("missing:", n)
        continue
    im = Image.open(p).convert("RGB")
    if im.size != (1280, 720):
        im = im.resize((1280, 720), Image.LANCZOS)
    im.save(os.path.join(dst, n + ".jpg"), quality=86, optimize=True)
    print("ok:", n, im.size)
EOF
echo "CONVERT DONE"
ls -la "$DST" | head -16
