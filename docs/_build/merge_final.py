#!/usr/bin/env python3
"""ENTITY_000 Phase 0 Docs - merge cover + body into the final single PDF."""
import os
from pypdf import PdfReader, PdfWriter

BUILD_DIR = "/home/z/entity000/docs/_build"
COVER_PDF = os.path.join(BUILD_DIR, "cover.pdf")
BODY_PDF = os.path.join(BUILD_DIR, "body.pdf")
FINAL_PDF = "/home/z/entity000/docs/ENTITY_000_Phase0_Docs.pdf"

A4_W, A4_H = 595.28, 841.89


def normalize_page_to_a4(page, force=False):
    box = page.mediabox
    w, h = float(box.width), float(box.height)
    if force or abs(w - A4_W) > 2 or abs(h - A4_H) > 2:
        page.scale_to(A4_W, A4_H)
        page.mediabox.lower_left = (0, 0)
        page.mediabox.upper_right = (A4_W, A4_H)
    return page


def main():
    writer = PdfWriter()
    cover_page = PdfReader(COVER_PDF).pages[0]
    writer.add_page(normalize_page_to_a4(cover_page, force=True))
    for page in PdfReader(BODY_PDF).pages:
        writer.add_page(normalize_page_to_a4(page))
    writer.add_metadata({
        "/Title": "ENTITY_000 Phase 0 Design Documentation",
        "/Author": "Z.ai",
        "/Creator": "Z.ai",
        "/Subject": "Seven Phase 0 design bibles for the ENTITY_000 vertical slice",
    })
    with open(FINAL_PDF, "wb") as f:
        writer.write(f)
    n = len(PdfReader(FINAL_PDF).pages)
    size = os.path.getsize(FINAL_PDF)
    print("FINAL OK ->", FINAL_PDF, "| pages:", n, "| bytes:", size)


if __name__ == "__main__":
    main()
