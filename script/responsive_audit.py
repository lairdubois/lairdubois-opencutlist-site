#!/usr/bin/env python3
"""Checks that no page overflows horizontally, from phones to desktop.

Usage : bin/dev running, then  python3 script/responsive_audit.py [base_url] [--shots DIR]
Needs Playwright (pip3 install playwright && python3 -m playwright install chromium).
Lists every element sticking out of the viewport ; exit code 1 when there is one.
--shots DIR also saves a full-page screenshot per width and page.
"""
import sys
from pathlib import Path
from playwright.sync_api import sync_playwright

WIDTHS = (320, 375, 768, 1024, 1280)
PAGES = [f"{locale}{page}" for locale in ("en", "fr") for page in ("", "/lab", "/download", "/donate")]
OVERFLOWS = """() => {
  const width = document.documentElement.clientWidth, found = [];
  for (const el of document.querySelectorAll('body *')) {
    const box = el.getBoundingClientRect();
    if (box.width && (box.right > width + 0.5 || box.left < -0.5))
      found.push(`${el.tagName.toLowerCase()}.${String(el.className).split(' ')[0]} "${el.textContent.trim().slice(0, 40)}"`);
  }
  return found;
}"""

args = [arg for arg in sys.argv[1:] if not arg.startswith("--")]
base = (args[0] if args else "http://127.0.0.1:3000").rstrip("/")
shots = Path(sys.argv[sys.argv.index("--shots") + 1]) if "--shots" in sys.argv else None
if shots:
    shots.mkdir(parents=True, exist_ok=True)

failures = 0
with sync_playwright() as playwright:
    browser = playwright.chromium.launch()
    for width in WIDTHS:
        page = browser.new_page(viewport={"width": width, "height": 800})
        for path in PAGES:
            page.goto(f"{base}/{path}")
            page.wait_for_load_state("networkidle")
            found = page.evaluate(OVERFLOWS)
            if found:
                failures += 1
                print(f"{width}px /{path} : {len(found)} overflowing", *found[:5], sep="\n  ")
            if shots:
                page.screenshot(path=shots / f"{width}_{path.replace('/', '_')}.png", full_page=True)
    browser.close()

print("no overflow" if not failures else f"{failures} page(s) overflow")
sys.exit(1 if failures else 0)
