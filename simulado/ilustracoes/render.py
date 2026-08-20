# -*- coding: utf-8 -*-
"""Renderiza SVG -> PNG 2x com Chromium e recorta no tamanho exato."""
import os, re, subprocess, sys
from PIL import Image

BASE = os.path.dirname(os.path.abspath(__file__))
CHROME = "/opt/pw-browsers/chromium-1194/chrome-linux/chrome"
SCALE = 2

HTML = ('<!doctype html><meta charset="utf-8"><style>*{{margin:0;padding:0;border:0}}'
        'html,body{{background:transparent}}svg{{display:block;width:{w}px;height:{h}px}}</style>{svg}')


def render(name):
    svg_path = os.path.join(BASE, "svg", name + ".svg")
    svg = open(svg_path, encoding="utf-8").read()
    w = int(re.search(r'width="(\d+)"', svg).group(1))
    h = int(re.search(r'height="(\d+)"', svg).group(1))
    os.makedirs(os.path.join(BASE, "tmp"), exist_ok=True)
    os.makedirs(os.path.join(BASE, "png"), exist_ok=True)
    html_path = os.path.join(BASE, "tmp", name + ".html")
    open(html_path, "w", encoding="utf-8").write(HTML.format(w=w, h=h, svg=svg))
    raw = os.path.join(BASE, "tmp", name + ".raw.png")
    subprocess.run([CHROME, "--headless", "--no-sandbox", "--disable-gpu", "--hide-scrollbars",
                    f"--force-device-scale-factor={SCALE}", "--default-background-color=00000000",
                    f"--window-size={w},{h + 300}", f"--screenshot={raw}", html_path],
                   capture_output=True)
    im = Image.open(raw).convert("RGBA")
    im = im.crop((0, 0, w * SCALE, h * SCALE))
    # achata sobre branco: o DOCX nao lida bem com PNG semitransparente
    flat = Image.new("RGB", im.size, (255, 255, 255))
    flat.paste(im, mask=im.split()[3])
    out = os.path.join(BASE, "png", name + ".png")
    flat.save(out, optimize=True)
    os.remove(raw)
    return out, im.size


if __name__ == "__main__":
    names = sys.argv[1:]
    if not names:
        names = sorted(f[:-4] for f in os.listdir(os.path.join(BASE, "svg")) if f.endswith(".svg"))
    for n in names:
        p, s = render(n)
        print("  %-16s %sx%s  %6.1f KB" % (n + ".png", s[0], s[1], os.path.getsize(p) / 1024))
