# /// script
# requires-python = ">=3.11"
# dependencies = ["pymupdf>=1.26", "pillow>=11"]
# ///
"""Convert a document to Markdown for an LLM, flag PDF pages whose text layer
cannot be trusted, and render those pages into labelled image grids to read
visually. Usage: uv run --script docread.py FILE [--out DIR] [--tables]"""
import argparse
import re
import subprocess
import sys
import tempfile
from pathlib import Path

# Fonts that position glyphs without space characters extract as one long run,
# e.g. "OK,untilwhendoIgettothink". No real word is 22+ letters long.
MERGED_WORDS = re.compile(r"[A-Za-z][A-Za-z'\",.?!]{21,}")
BROKEN_CHARS = re.compile(r"�|\(cid:\d+\)")
# Chart labels extract as bare-number lines ("44%", "$0.257"), detached from what they measure.
BARE_NUMBER_LINE = re.compile(r"^\s*[-+$]?\d[\d.,]*\s*(%|x|×|mo|s|k|m)?\s*$", re.M)
HEBREW = re.compile(r"[א-ת]")
# Final letters only end a word; in visual-order (reversed) output they start words instead.
FINAL_AT_START = re.compile(r"(?<![א-ת])[ךםןףץ][א-ת]")
FINAL_AT_END = re.compile(r"[א-ת][ךםןףץ](?![א-ת])")
TILE_W = 1000
MAX_RENDER = 60


def page_flags(text: str, images: int, drawings: int) -> list[str]:
    flags = []
    if MERGED_WORDS.search(text):
        flags.append("merged-words")
    if BROKEN_CHARS.search(text):
        flags.append("broken-chars")
    if len(BARE_NUMBER_LINE.findall(text)) >= 4:
        flags.append("chart-values")
    if len(text.strip()) < 40:
        flags.append("no-text")
    elif (images or drawings >= 15) and len(text) < 600:
        flags.append("visual")
    return flags


def is_reversed_hebrew(text: str) -> bool:
    start, end = len(FINAL_AT_START.findall(text)), len(FINAL_AT_END.findall(text))
    return start + end >= 3 and start > end


def mostly_hebrew(text: str) -> bool:
    return len(HEBREW.findall(text)) > len(re.findall(r"[A-Za-z]", text))


def to_markdown(src: Path, out: Path, tables: bool) -> Path:
    if tables:
        subprocess.run(["uv", "run", "--no-project", "--with", "docling", "docling", str(src),
                        "--to", "md", "--image-export-mode", "placeholder", "--output", str(out)],
                       check=True, capture_output=True)
        return out / f"{src.stem}.md"
    md = out / f"{src.stem}.md"
    subprocess.run(["markitdown", str(src), "-o", str(md)], check=True, capture_output=True)
    return md


def render_grids(doc, pages: list[int], out: Path) -> list[str]:
    import pymupdf
    from PIL import Image, ImageDraw

    landscape = doc[pages[0]].rect.width > doc[pages[0]].rect.height
    per_sheet = 6 if landscape else 4
    sheets = []
    for s in range(0, len(pages), per_sheet):
        chunk = pages[s:s + per_sheet]
        tiles = []
        for n in chunk:
            page = doc[n]
            pix = page.get_pixmap(matrix=pymupdf.Matrix(TILE_W / page.rect.width, TILE_W / page.rect.width))
            img = Image.frombytes("RGB", (pix.width, pix.height), pix.samples)
            draw = ImageDraw.Draw(img)
            draw.rectangle((0, 0, 110, 44), fill="black")
            draw.text((10, 8), f"p{n + 1}", fill="white", font_size=28)
            tiles.append(img)
        tile_h = max(t.height for t in tiles)
        rows = -(-len(tiles) // 2)
        sheet = Image.new("RGB", (TILE_W * 2, tile_h * rows), "white")
        for k, t in enumerate(tiles):
            sheet.paste(t, ((k % 2) * TILE_W, (k // 2) * tile_h))
        path = out / f"pages_{chunk[0] + 1:03}-{chunk[-1] + 1:03}.png"
        sheet.save(path)
        sheets.append(str(path))
    return sheets


def main() -> None:
    ap = argparse.ArgumentParser()
    ap.add_argument("file", type=Path)
    ap.add_argument("--out", type=Path)
    ap.add_argument("--tables", action="store_true", help="use Docling (slow, accurate tables)")
    a = ap.parse_args()
    out = a.out or Path(tempfile.mkdtemp(prefix="docread-"))
    out.mkdir(parents=True, exist_ok=True)

    is_pdf = a.file.suffix.lower() == ".pdf"
    if is_pdf:
        import pymupdf
        doc = pymupdf.open(a.file)
        texts = [page.get_text() for page in doc]
    if is_pdf and not a.tables and mostly_hebrew("".join(texts)):
        # markitdown (pdfminer) emits Hebrew in visual order, i.e. reversed words; pymupdf keeps reading order
        md = out / f"{a.file.stem}.md"
        md.write_text("\n\n".join(f"<!-- page {n + 1} -->\n{t}" for n, t in enumerate(texts)), encoding="utf-8")
    else:
        md = to_markdown(a.file, out, a.tables)
    print(f"markdown: {md} ({md.stat().st_size} bytes)")
    reversed_md = is_reversed_hebrew(md.read_text(encoding="utf-8", errors="replace"))
    if reversed_md:
        print("reversed-hebrew: the markdown has Hebrew words backwards; trust page images, not the markdown")
    if not is_pdf:
        print("not a PDF: no page check")
        return

    flagged: dict[int, list[str]] = {}
    for n, page in enumerate(doc):
        f = page_flags(texts[n], len(page.get_images()), len(page.get_drawings()))
        if reversed_md and HEBREW.search(texts[n]):
            f.append("reversed-hebrew")
        if f:
            flagged[n] = f
    print(f"pages: {len(doc)}, flagged: {len(flagged)}")
    by_reason: dict[str, list[int]] = {}
    for n, fs in flagged.items():
        for f in fs:
            by_reason.setdefault(f, []).append(n + 1)
    for reason, nums in by_reason.items():
        print(f"  {reason}: {nums}")
    if not flagged:
        return
    # ponytail: hard cap on rendered pages to bound tokens; add a --pages range when a long scanned doc needs all of them
    to_render = sorted(flagged)[:MAX_RENDER]
    if len(flagged) > MAX_RENDER:
        print(f"  rendering first {MAX_RENDER} flagged pages only")
    print("read these images; they override the markdown for flagged pages:")
    for s in render_grids(doc, to_render, out):
        print(f"  {s}")


def selftest() -> None:
    assert page_flags('"OK,untilwhendoIgettothink aboutit?Askmeclosertothedate."', 0, 0) == ["merged-words"]
    assert page_flags("word " * 12 + "�", 0, 0) == ["broken-chars"]
    assert page_flags("  ", 1, 0) == ["no-text"]
    assert page_flags("Always medium\nAlways high\n44%\n51%\n92%\n$0.257\n" * 20, 0, 0) == ["chart-values"]
    assert page_flags("Short slide caption that is long enough to count.", 0, 40) == ["visual"]
    assert page_flags("internationalization and github.com/a/claude-code-filetree " * 20, 1, 0) == []
    logical = 'המסמך הזה מסביר איך להתקין את הכלי ומה צריך לבדוק לפני שמתחילים לעבוד איתו'
    visual = " ".join(w[::-1] for w in logical.split()[::-1])
    assert not is_reversed_hebrew(logical)
    assert is_reversed_hebrew(visual)
    assert not is_reversed_hebrew("plain English text with no Hebrew at all")
    assert mostly_hebrew(logical + " Data backend API")
    assert not mostly_hebrew("Slide deck about Claude Code mods, " + "מה")
    print("selftest ok")


if __name__ == "__main__":
    sys.stdout.reconfigure(encoding="utf-8")
    selftest() if sys.argv[1:] == ["--selftest"] else main()
