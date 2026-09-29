#!/usr/bin/env python3
"""ENTITY_000 Phase 0 Docs - body PDF builder (ReportLab / Report route).

Builds the 7-bible body PDF with:
  - TocDocTemplate + multiBuild (clickable auto-TOC)
  - front matter roman numerals, body arabic reset (fcp hint loop)
  - cascade palette (seed 7, minimal mode) - no hand-picked colors
  - markdown parsing: headings, tables, code fences, lists, quotes, hr
"""
import os
import re
import sys
import hashlib

PDF_SKILL_DIR = "/home/z/my-project/skills/pdf"
_scripts = os.path.join(PDF_SKILL_DIR, "scripts")
if _scripts not in sys.path:
    sys.path.insert(0, _scripts)

from reportlab.lib.pagesizes import A4
from reportlab.lib import colors
from reportlab.lib.enums import TA_JUSTIFY, TA_LEFT, TA_CENTER
from reportlab.lib.styles import ParagraphStyle
from reportlab.pdfbase import pdfmetrics
from reportlab.pdfbase.ttfonts import TTFont
from reportlab.pdfbase.pdfmetrics import registerFontFamily, stringWidth
from reportlab.platypus import (SimpleDocTemplate, Paragraph, Spacer, PageBreak,
                                Table, TableStyle, KeepTogether, CondPageBreak,
                                HRFlowable, XPreformatted)
from reportlab.platypus.tableofcontents import TableOfContents

DOCS_DIR = "/home/z/entity000/docs"
BUILD_DIR = os.path.join(DOCS_DIR, "_build")
BODY_PDF = os.path.join(BUILD_DIR, "body.pdf")

CHAPTER_FILES = [
    ("01_game_design_bible.md", "Game Design Bible"),
    ("02_world_lore_bible.md", "World & Lore Bible"),
    ("03_systems_bible.md", "Systems Bible"),
    ("04_art_bible.md", "Art Bible"),
    ("05_narrative_theology_bible.md", "Narrative & Theology Bible"),
    ("06_technical_architecture.md", "Technical Architecture"),
    ("07_vertical_slice_spec.md", "Vertical Slice Specification"),
]

DOC_TITLE = "ENTITY_000 " + chr(8212) + " Phase 0 Design Documentation"
DOC_AUTHOR = "ENTITY_000 Build Team"
EMDASH = chr(8212)
MIDDOT = chr(183)
BULLET = chr(8226)
NBSP = chr(160)

# ---------------------------------------------------------------- fonts
FONT_DIR = "/usr/share/fonts"
pdfmetrics.registerFont(TTFont("FreeSerif", FONT_DIR + "/truetype/freefont/FreeSerif.ttf"))
pdfmetrics.registerFont(TTFont("FreeSerif-Bold", FONT_DIR + "/truetype/freefont/FreeSerifBold.ttf"))
pdfmetrics.registerFont(TTFont("FreeSerif-Italic", FONT_DIR + "/truetype/freefont/FreeSerifItalic.ttf"))
pdfmetrics.registerFont(TTFont("FreeSerif-BoldItalic", FONT_DIR + "/truetype/freefont/FreeSerifBoldItalic.ttf"))
pdfmetrics.registerFont(TTFont("NotoSerifSC", FONT_DIR + "/truetype/noto-serif-sc/NotoSerifSC-Regular.ttf"))
pdfmetrics.registerFont(TTFont("NotoSerifSC-Bold", FONT_DIR + "/truetype/noto-serif-sc/NotoSerifSC-Bold.ttf"))
pdfmetrics.registerFont(TTFont("DejaVuSans", FONT_DIR + "/truetype/dejavu/DejaVuSansMono.ttf"))
pdfmetrics.registerFont(TTFont("SarasaMonoSC", FONT_DIR + "/truetype/chinese/SarasaMonoSC-Regular.ttf"))
registerFontFamily("FreeSerif", normal="FreeSerif", bold="FreeSerif-Bold",
                   italic="FreeSerif-Italic", boldItalic="FreeSerif-BoldItalic")
registerFontFamily("NotoSerifSC", normal="NotoSerifSC", bold="NotoSerifSC-Bold")
registerFontFamily("DejaVuSans", normal="DejaVuSans", bold="DejaVuSans")

from pdf import install_font_fallback  # noqa: E402
install_font_fallback()

# ------------------------------------------------- cascade palette (seed 7)
PAGE_BG = colors.HexColor("#f1f0ef")
SECTION_BG = colors.HexColor("#f2f1f0")
CARD_BG = colors.HexColor("#e8e7e4")
TABLE_STRIPE = colors.HexColor("#eeedeb")
HEADER_FILL = colors.HexColor("#504933")
COVER_BLOCK = colors.HexColor("#867b5a")
BORDER = colors.HexColor("#cfcab8")
ICON = colors.HexColor("#8c7e52")
ACCENT = colors.HexColor("#87702a")
ACCENT_2 = colors.HexColor("#3a95b4")
TEXT_PRIMARY = colors.HexColor("#1c1c1a")
TEXT_MUTED = colors.HexColor("#78766f")

TABLE_HEADER_COLOR = HEADER_FILL
TABLE_HEADER_TEXT = colors.white
TABLE_ROW_EVEN = colors.white
TABLE_ROW_ODD = TABLE_STRIPE

# ---------------------------------------------------------------- geometry
PAGE_W, PAGE_H = A4
MARGIN = 66.0
TOP_MARGIN = 76.0
BOTTOM_MARGIN = 64.0
AVAIL_W = PAGE_W - 2 * MARGIN
AVAIL_H = PAGE_H - TOP_MARGIN - BOTTOM_MARGIN
H1_ORPHAN = AVAIL_H * 0.25
MAX_KEEP_HEIGHT = PAGE_H * 0.4

# ---------------------------------------------------------------- styles
S = {}
S["body"] = ParagraphStyle("Body", fontName="FreeSerif", fontSize=10.5,
                           leading=16.5, alignment=TA_JUSTIFY,
                           textColor=TEXT_PRIMARY, spaceBefore=0, spaceAfter=7)
S["intro"] = ParagraphStyle("Intro", parent=S["body"], fontName="FreeSerif-Italic",
                            textColor=TEXT_MUTED, spaceAfter=10)
S["h1"] = ParagraphStyle("H1", fontName="FreeSerif", fontSize=19, leading=24,
                         alignment=TA_LEFT, textColor=TEXT_PRIMARY,
                         spaceBefore=6, spaceAfter=2)
S["h1kick"] = ParagraphStyle("H1Kick", fontName="FreeSerif", fontSize=9.5,
                             leading=13, textColor=ACCENT, spaceBefore=18,
                             spaceAfter=3)
S["h2"] = ParagraphStyle("H2", fontName="FreeSerif", fontSize=14, leading=18,
                         textColor=HEADER_FILL, spaceBefore=14, spaceAfter=6)
S["h3"] = ParagraphStyle("H3", fontName="FreeSerif", fontSize=11.5, leading=15,
                         textColor=TEXT_PRIMARY, spaceBefore=10, spaceAfter=4)
S["bullet"] = ParagraphStyle("Bullet", parent=S["body"], leftIndent=16,
                             bulletIndent=4, spaceAfter=4, alignment=TA_LEFT,
                             bulletFontName="FreeSerif", bulletFontSize=10.5)
S["numbered"] = ParagraphStyle("Numbered", parent=S["body"], leftIndent=20,
                               bulletIndent=4, spaceAfter=4, alignment=TA_LEFT,
                               bulletFontName="FreeSerif", bulletFontSize=10.5)
S["quote"] = ParagraphStyle("Quote", fontName="FreeSerif-Italic", fontSize=11,
                            leading=17, textColor=TEXT_PRIMARY, leftIndent=10,
                            alignment=TA_LEFT)
S["code"] = ParagraphStyle("Code", fontName="DejaVuSans", fontSize=8,
                           leading=11, textColor=TEXT_PRIMARY, alignment=TA_LEFT)
S["cell"] = ParagraphStyle("Cell", fontName="FreeSerif", fontSize=9,
                           leading=12, textColor=TEXT_PRIMARY, alignment=TA_LEFT)
S["cellhead"] = ParagraphStyle("CellHead", fontName="FreeSerif", fontSize=9,
                               leading=12, textColor=colors.white, alignment=TA_CENTER)
S["tocTitle"] = ParagraphStyle("TocTitle", fontName="FreeSerif", fontSize=19,
                               leading=24, textColor=TEXT_PRIMARY, spaceAfter=14)
S["toc0"] = ParagraphStyle("TOC0", fontName="FreeSerif", fontSize=11.5,
                           leading=20, textColor=TEXT_PRIMARY, leftIndent=0)
S["toc1"] = ParagraphStyle("TOC1", fontName="FreeSerif", fontSize=9.5,
                           leading=15, textColor=TEXT_MUTED, leftIndent=18)

# ---------------------------------------------------------------- helpers
AMP = chr(38)


def esc(text):
    t = text.replace(AMP, AMP + "amp;")
    t = t.replace("<", AMP + "lt;")
    t = t.replace(">", AMP + "gt;")
    return t


def nbsp_dash(t):
    t = t.replace(" " + EMDASH + " ", NBSP + EMDASH + " ")
    t = t.replace(" " + EMDASH, NBSP + EMDASH)
    return t


def inline(t):
    t = esc(t)
    t = re.sub(r"`([^`]+)`",
               r"<font face='DejaVuSans' size='8.5'>" + r"\1" + "</font>", t)
    t = re.sub(r"\*\*([^*]+)\*\*", r"<b>" + r"\1" + "</b>", t)
    t = re.sub(r"(?<!\w)\*([^*\n]+)\*(?!\w)", r"<i>" + r"\1" + "</i>", t)
    return nbsp_dash(t)


def strip_md(t):
    t = re.sub(r"`([^`]+)`", r"\1", t)
    t = re.sub(r"\*\*([^*]+)\*\*", r"\1", t)
    t = re.sub(r"(?<!\w)\*([^*\n]+)\*(?!\w)", r"\1", t)
    return t


def add_heading(text, style, level=0, first_chapter=False):
    key = "h_" + hashlib.md5((str(level) + text).encode()).hexdigest()[:8]
    p = Paragraph('<a name="' + key + '"/>' + inline(text), style)
    p.bookmark_name = key
    p.bookmark_level = level
    p.bookmark_text = strip_md(text).replace(NBSP, " ")
    p.bookmark_key = key
    p.is_first_chapter = first_chapter
    return p


def safe_keep_together(elements):
    total_h = 0
    for el in elements:
        w, h = el.wrap(AVAIL_W, AVAIL_H)
        total_h += h
    if total_h <= MAX_KEEP_HEIGHT:
        return [KeepTogether(elements)]
    elif len(elements) >= 2:
        return [KeepTogether(elements[:2])] + list(elements[2:])
    return list(elements)


def calculate_col_widths(rows, font, size, available_width, min_col=34):
    n_cols = max(len(r) for r in rows)
    max_widths = [0.0] * n_cols
    for row in rows:
        for i in range(n_cols):
            cell = row[i] if i < len(row) else ""
            txt = strip_md(str(cell))
            w = stringWidth(txt, font, size) + 14
            max_widths[i] = max(max_widths[i], w)
    total_natural = sum(max_widths)
    if total_natural <= 0:
        return [available_width / n_cols] * n_cols
    if total_natural <= available_width:
        extra = available_width - total_natural
        return [w + extra * (w / total_natural) for w in max_widths]
    col_widths = []
    for w in max_widths:
        allocated = max(min_col, available_width * (w / total_natural))
        col_widths.append(allocated)
    scale = available_width / sum(col_widths)
    return [w * scale for w in col_widths]


def build_table(rows):
    header = rows[0]
    body_rows = rows[1:]
    n_cols = len(header)
    data = []
    head_cells = [Paragraph("<b>" + inline(c) + "</b>", S["cellhead"]) for c in header]
    data.append(head_cells)
    for r in body_rows:
        r = list(r) + [""] * (n_cols - len(r))
        data.append([Paragraph(inline(c), S["cell"]) for c in r])
    cell_rows = [[strip_md(str(c)) for c in row] for row in rows]
    widths = calculate_col_widths(cell_rows, "FreeSerif", 9, AVAIL_W)
    tbl = Table(data, colWidths=widths, repeatRows=1, hAlign="CENTER")
    style = [
        ("BACKGROUND", (0, 0), (-1, 0), TABLE_HEADER_COLOR),
        ("TEXTCOLOR", (0, 0), (-1, 0), TABLE_HEADER_TEXT),
        ("GRID", (0, 0), (-1, -1), 0.5, BORDER),
        ("VALIGN", (0, 0), (-1, -1), "MIDDLE"),
        ("LEFTPADDING", (0, 0), (-1, -1), 7),
        ("RIGHTPADDING", (0, 0), (-1, -1), 7),
        ("TOPPADDING", (0, 0), (-1, -1), 5),
        ("BOTTOMPADDING", (0, 0), (-1, -1), 5),
    ]
    for i in range(1, len(data)):
        bg = TABLE_ROW_EVEN if i % 2 == 1 else TABLE_ROW_ODD
        style.append(("BACKGROUND", (0, i), (-1, i), bg))
    tbl.setStyle(TableStyle(style))
    return tbl


def build_code_block(lines):
    text = nbsp_dash(chr(10).join(lines))
    pre = XPreformatted(esc(text), S["code"])
    box = Table([[pre]], colWidths=[AVAIL_W])
    box.setStyle(TableStyle([
        ("BACKGROUND", (0, 0), (-1, -1), CARD_BG),
        ("LINEBEFORE", (0, 0), (0, -1), 2, ACCENT),
        ("LEFTPADDING", (0, 0), (-1, -1), 10),
        ("RIGHTPADDING", (0, 0), (-1, -1), 10),
        ("TOPPADDING", (0, 0), (-1, -1), 8),
        ("BOTTOMPADDING", (0, 0), (-1, -1), 8),
    ]))
    return box


def build_quote(text):
    p = Paragraph(inline(text), S["quote"])
    box = Table([[p]], colWidths=[AVAIL_W - 24])
    box.setStyle(TableStyle([
        ("BACKGROUND", (0, 0), (-1, -1), SECTION_BG),
        ("LINEBEFORE", (0, 0), (0, -1), 2, ACCENT),
        ("LEFTPADDING", (0, 0), (-1, -1), 12),
        ("RIGHTPADDING", (0, 0), (-1, -1), 10),
        ("TOPPADDING", (0, 0), (-1, -1), 8),
        ("BOTTOMPADDING", (0, 0), (-1, -1), 8),
    ]))
    box.hAlign = "CENTER"
    return box


# ---------------------------------------------------------------- parsing
def parse_blocks(lines):
    blocks = []
    i = 0
    n = len(lines)
    while i < n:
        line = lines[i]
        stripped = line.strip()
        if not stripped:
            i += 1
            continue
        if stripped.startswith("```"):
            code = []
            i += 1
            while i < n and not lines[i].strip().startswith("```"):
                code.append(lines[i].rstrip())
                i += 1
            i += 1
            blocks.append(("code", code))
            continue
        m = re.match(r"^(#{1,4})\s+(.*)$", stripped)
        if m:
            blocks.append(("h" + str(len(m.group(1))), m.group(2)))
            i += 1
            continue
        if stripped.startswith("|"):
            tbl = []
            while i < n and lines[i].strip().startswith("|"):
                row = lines[i].strip()
                if not re.match(r"^\|[\s\-:|]+\|$", row):
                    cells = [c.strip() for c in row.strip("|").split("|")]
                    tbl.append(cells)
                i += 1
            if tbl:
                blocks.append(("table", tbl))
            continue
        if re.match(r"^[-*]\s+", stripped):
            items = []
            while i < n and re.match(r"^[-*]\s+", lines[i].strip()):
                items.append(re.sub(r"^[-*]\s+", "", lines[i].strip()))
                i += 1
            blocks.append(("bullets", items))
            continue
        if re.match(r"^\d+\.\s+", stripped):
            items = []
            while i < n and re.match(r"^\d+\.\s+", lines[i].strip()):
                items.append(re.sub(r"^\d+\.\s+", "", lines[i].strip()))
                i += 1
            blocks.append(("numbered", items))
            continue
        if stripped.startswith(">"):
            quote = []
            while i < n and lines[i].strip().startswith(">"):
                quote.append(lines[i].strip().lstrip(">").strip())
                i += 1
            blocks.append(("quote", " ".join([q for q in quote if q])))
            continue
        if re.match(r"^-{3,}$", stripped):
            blocks.append(("hr", None))
            i += 1
            continue
        para = [stripped]
        i += 1
        while i < n and lines[i].strip() and not re.match(
                r"^(#{1,4}\s|[-*]\s|\d+\.\s|\||>|```|-{3,}$)", lines[i].strip()):
            para.append(lines[i].strip())
            i += 1
        blocks.append(("para", " ".join(para)))
    return blocks


def chapter_flowables(chapter_no, title, blocks, first_chapter):
    flows = []
    kicker = "CHAPTER " + str(chapter_no) + MIDDOT + " PHASE 0"
    head_txt = "Chapter " + str(chapter_no) + NBSP + EMDASH + " " + title
    h1 = add_heading(head_txt, S["h1"], level=0, first_chapter=first_chapter)
    rule = HRFlowable(width="100%", color=ACCENT, thickness=1.4,
                      spaceBefore=2, spaceAfter=10)
    lead = [Paragraph(kicker, S["h1kick"]), h1, rule]
    if not first_chapter:
        flows.append(CondPageBreak(H1_ORPHAN))
    first_para = None
    rest = list(blocks)
    if rest and rest[0][0] == "para":
        first_para = Paragraph(inline(rest[0][1]), S["intro"])
        rest = rest[1:]
    if first_para is not None:
        flows.extend(safe_keep_together(lead + [first_para]))
    else:
        flows.extend(safe_keep_together(lead))
    for kind, payload in rest:
        if kind == "h2":
            flows.append(CondPageBreak(60))
            h2 = add_heading(payload, S["h2"], level=1)
            flows.append(h2)
        elif kind == "h3":
            flows.append(Paragraph(inline(payload), S["h3"]))
        elif kind == "para":
            flows.append(Paragraph(inline(payload), S["body"]))
        elif kind == "bullets":
            for it in payload:
                flows.append(Paragraph(inline(it), S["bullet"], bulletText=BULLET))
            flows.append(Spacer(1, 4))
        elif kind == "numbered":
            for idx, it in enumerate(payload, 1):
                flows.append(Paragraph(inline(it), S["numbered"],
                                       bulletText=str(idx) + "."))
            flows.append(Spacer(1, 4))
        elif kind == "table":
            tbl = build_table(payload)
            flows.append(Spacer(1, 6))
            if len(payload) <= 9:
                flows.extend(safe_keep_together([tbl]))
            else:
                flows.append(tbl)
            flows.append(Spacer(1, 10))
        elif kind == "code":
            box = build_code_block(payload)
            flows.append(Spacer(1, 4))
            if len(payload) <= 14:
                flows.extend(safe_keep_together([box]))
            else:
                flows.append(box)
            flows.append(Spacer(1, 8))
        elif kind == "quote":
            flows.append(Spacer(1, 4))
            flows.append(build_quote(payload))
            flows.append(Spacer(1, 8))
        elif kind == "hr":
            flows.append(HRFlowable(width="100%", color=BORDER, thickness=0.7,
                                    spaceBefore=6, spaceAfter=10))
    return flows


def make_story():
    story = []
    story.append(Paragraph("Table of Contents", S["tocTitle"]))
    toc = TableOfContents()
    toc.levelStyles = [S["toc0"], S["toc1"]]
    toc.dotsMinLevel = 0
    story.append(toc)
    story.append(PageBreak())
    for idx, (fname, title) in enumerate(CHAPTER_FILES, 1):
        path = os.path.join(DOCS_DIR, fname)
        with open(path, encoding="utf-8") as f:
            lines = f.read().splitlines()
        blocks = parse_blocks(lines)
        if blocks and blocks[0][0] == "h1":
            blocks = blocks[1:]
        story.extend(chapter_flowables(idx, title, blocks, first_chapter=(idx == 1)))
    return story


# ---------------------------------------------------------------- template
ROMAN = {1: "i", 2: "ii", 3: "iii", 4: "iv", 5: "v", 6: "vi", 7: "vii",
         8: "viii", 9: "ix", 10: "x", 11: "xi", 12: "xii"}


def page_label(page, fcp):
    if fcp and page >= fcp:
        return str(page - fcp + 1)
    return ROMAN.get(page, str(page))


def make_on_page(fcp_getter):
    def on_page(canvas, doc):
        canvas.saveState()
        canvas.setFont("FreeSerif", 7.5)
        canvas.setFillColor(TEXT_MUTED)
        canvas.drawString(MARGIN, PAGE_H - 44, DOC_TITLE)
        canvas.setStrokeColor(ACCENT)
        canvas.setLineWidth(1.2)
        canvas.line(MARGIN, PAGE_H - 51, PAGE_W - MARGIN, PAGE_H - 51)
        canvas.setStrokeColor(BORDER)
        canvas.setLineWidth(0.5)
        canvas.line(MARGIN, 47, PAGE_W - MARGIN, 47)
        canvas.setFont("FreeSerif", 7.5)
        canvas.setFillColor(TEXT_MUTED)
        canvas.drawString(MARGIN, 35, DOC_AUTHOR)
        canvas.drawRightString(PAGE_W - MARGIN, 35, page_label(doc.page, fcp_getter(doc)))
        canvas.restoreState()
    return on_page


class TocDocTemplate(SimpleDocTemplate):
    def __init__(self, *a, **kw):
        SimpleDocTemplate.__init__(self, *a, **kw)
        self.fcp_hint = None
        self.actual_fcp = None

    def afterFlowable(self, flowable):
        if hasattr(flowable, "bookmark_name"):
            level = getattr(flowable, "bookmark_level", 0)
            text = getattr(flowable, "bookmark_text", "")
            key = getattr(flowable, "bookmark_key", "")
            label = self.page
            if self.fcp_hint and self.page >= self.fcp_hint:
                label = self.page - self.fcp_hint + 1
            self.notify("TOCEntry", (level, text, label, key))
            if getattr(flowable, "is_first_chapter", False):
                self.actual_fcp = self.page


def build_once(fcp_hint):
    doc = TocDocTemplate(
        BODY_PDF, pagesize=A4,
        leftMargin=MARGIN, rightMargin=MARGIN,
        topMargin=TOP_MARGIN, bottomMargin=BOTTOM_MARGIN,
        title=DOC_TITLE, author="Z.ai", creator="Z.ai",
        subject="Phase 0 design documentation for ENTITY_000 (seven bibles)",
    )
    doc.fcp_hint = fcp_hint
    doc.actual_fcp = None
    on_page = make_on_page(lambda d: d.fcp_hint)
    doc.multiBuild(make_story(), onFirstPage=on_page, onLaterPages=on_page)
    return doc.actual_fcp or fcp_hint


def main():
    print("Chapter numbering plan (front matter unnumbered):")
    print("| Outline | Type    | Chapter | Title |")
    print("|---|---|---|---|")
    print("| 1 | cover   | " + chr(8212) + " | Cover (merged separately) |")
    print("| 2 | toc     | " + chr(8212) + " | Table of Contents (roman i..iii) |")
    for i, (_, t) in enumerate(CHAPTER_FILES, 1):
        print("| " + str(2 + i) + " | content | " + str(i) + " | " + t + " |")
    hint = 4
    for attempt in range(6):
        actual = build_once(hint)
        print("pass " + str(attempt + 1) + ": fcp_hint=" + str(hint) +
              " actual_first_content_page=" + str(actual))
        if actual == hint:
            break
        hint = actual
    print("BODY OK ->", BODY_PDF)


if __name__ == "__main__":
    main()
