# -*- coding: utf-8 -*-
"""Monta uma folha de contato para revisar varias ilustracoes de uma vez."""
import os, sys
from PIL import Image, ImageDraw

BASE = os.path.dirname(os.path.abspath(__file__))
names = sys.argv[1:]
COLW, PAD = 900, 18
thumbs = []
for n in names:
    im = Image.open(os.path.join(BASE, "png", n + ".png")).convert("RGB")
    h = int(im.height * COLW / im.width)
    thumbs.append((n, im.resize((COLW, h), Image.LANCZOS)))

Wt = COLW + PAD * 2
Ht = sum(t.height + 30 for _, t in thumbs) + PAD * 2
sheet = Image.new("RGB", (Wt, Ht), (250, 248, 244))
d = ImageDraw.Draw(sheet)
y = PAD
for n, t in thumbs:
    d.text((PAD, y + 6), n, fill=(40, 40, 40))
    y += 26
    sheet.paste(t, (PAD, y))
    y += t.height + 4
out = os.path.join(BASE, "sheet.png")
sheet.save(out)
print(out, sheet.size)
