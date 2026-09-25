#!/bin/bash
# Convert the 12 visual-proof PNGs (in-engine renders) to web-friendly JPEGs
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
