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
    # WB-9: the record is a thing
    "wb9_01_instrument", "wb9_02_instrument_wounded",
    "wb9_03_needle_edge", "wb9_04_record_speaks",
    "wb9_05_filing", "wb9_06_objections",
    "wb9_07_ledger", "wb9_08_sealed_rows",
    "wb9_09_receipt", "wb9_10_plaque",
    # WB-10: the air itself
    "wb10_01_womb_sound_map", "wb10_02_undercity_drip_arcs",
    "wb10_03_city_far_field", "wb10_04_chapel_eleven_flames",
    "wb10_05_engine_the_heart_hums", "wb10_06_reliquary_bell_and_chains",
    # WB-11: the arrival
    "wb11_01_womb_dark", "wb11_02_womb_catching",
    "wb11_03_womb_sweep", "wb11_04_womb_awake",
    "wb11_05_chapel_catching", "wb11_06_chapel_awake",
    # WB-12: the world thins
    "wb12_01_chapel_home", "wb12_02_chapel_thinning",
    "wb12_03_chapel_thin", "wb12_04_moths_leaving",
    "wb12_05_chapel_vessel_stays_real",
    "wb12_06_undercity_home", "wb12_07_undercity_thin",
    # WB-13: the threshold
    "wb13_01_leaving_mid_fold", "wb13_02_between_inscribing",
    "wb13_03_between_risen", "wb13_04_coming_into_the_wake",
    "wb13_05_settled",
    # WB-14: the vessel's trace
    "wb14_01_ash_path", "wb14_02_ash_toe_kick",
    "wb14_03_landing_star", "wb14_04_roll_smear",
    "wb14_05_wet_glisten", "wb14_06_chapel_nap",
    "wb14_07_page_flutter", "wb14_08_engine_clean",
    # WB-15: the others' passage
    "wb15_01_two_hands", "wb15_02_the_echo",
    "wb15_03_devotion_field", "wb15_04_the_shuffle",
    "wb15_05_martyr_weight", "wb15_06_engine_clean",
    "wb15_07_the_erasure", "wb15_08_age_gradient",
    # WB-16: the ending's record
    "wb16_01_the_hollows_ending", "wb16_02_the_sprawl",
    "wb16_03_the_pool", "wb16_04_the_congregations_ending",
    "wb16_05_the_censors_leaving", "wb16_06_where_he_fell",
    "wb16_07_engine_records_nothing", "wb16_08_two_endings",
    # WB-19: the three beats (event-locked strobe stills + motion frames)
    "wb19_01_gather", "wb19_02_launch",
    "wb19_03_chain_step", "wb19_04_finisher_card",
    "wb19_05_flock_rim", "wb19_06_dash_smear",
    # WB-20: the walking flock (motion keyframe, stride-cycle filmstrip,
    # strobe stills, the labeled pair, the closed arch)
    "wb20_01_ride_in_motion", "wb20_02_the_cycle",
    "wb20_03_dip_still", "wb20_04_rise_still",
    "wb20_05_the_pair", "wb20_06_the_arch",
    # WB-21: the censer's edge (the verdict strip; the four full-res stills
    # and the lean pair are already-final JPEGs, copied below)
    "wb21_05_the_motion_verdict",
    # WB-22: the press keeps its count (the verdict strip; the five
    # full-res stills are already-final JPEGs, copied below)
    "wb22_06_the_verdict",
    # WB-23: the furniture yields (the verdict strip; the five
    # full-res stills are already-final JPEGs, copied below)
    "wb23_06_the_verdict",
    # WB-24: the corner yields (the verdict strip; the five
    # full-res stills are already-final JPEGs, copied below)
    "wb24_06_the_verdict",
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
# WB-21: the stills are already-final JPEGs (1280x720, q92) — copy straight
cp /home/z/entity000/screenshots/wb21/*.jpg "$DST"/
# WB-22: the same law — the press stills are final JPEGs
cp /home/z/entity000/screenshots/wb22/*.jpg "$DST"/
# WB-23: the same law — the grammar stills are final JPEGs
cp /home/z/entity000/screenshots/wb23/*.jpg "$DST"/
# WB-24: the same law — the corner stills are final JPEGs
cp /home/z/entity000/screenshots/wb24/*.jpg "$DST"/
ls "$DST" | wc -l
