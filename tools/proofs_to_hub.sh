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
