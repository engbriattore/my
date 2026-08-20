# -*- coding: utf-8 -*-
"""Ilustracoes dos poemas 2, 3 e 4."""
import sys, os, math
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from common import *

W, H = 1200, 560

# =============================================================== POEMA 2 relogio
b = []
b.append(f'<rect width="{W}" height="{H}" fill="#E8DCC6"/>')
# parede com friso
b.append(f'<rect x="0" y="0" width="{W}" height="418" fill="#E3D5BC"/>')
for x in range(0, W, 60):
    b.append(f'<rect x="{x}" y="0" width="28" height="418" fill="#DCCDB0" opacity="0.45"/>')
b.append(f'<rect x="0" y="410" width="{W}" height="18" fill="#B9A484"/>')
b.append(f'<rect x="0" y="428" width="{W}" height="{H-428}" fill="#C6A882"/>')
for x in range(-120, W + 200, 150):
    b.append(f'<path d="M {x} 428 L {x+110} {H} " stroke="#B2946E" stroke-width="4" opacity="0.5"/>')
b.append(f'<rect x="0" y="428" width="{W}" height="10" fill="#A98B66"/>')

# quadro na parede
b.append(f'<g><rect x="120" y="112" width="188" height="150" rx="6" fill="#B9895F"/>'
         f'<rect x="134" y="126" width="160" height="122" rx="3" fill="#DCE7EA"/>'
         f'<path d="M 134 220 L 186 168 L 226 208 L 258 180 L 294 220 Z" fill="#8CB07B"/>'
         f'<circle cx="266" cy="152" r="18" fill="#E9B95F"/></g>')

# mesinha lateral com abajur
b.append(f'<g><rect x="912" y="316" width="212" height="16" rx="8" fill="#9C7550"/>'
         f'<rect x="928" y="332" width="14" height="96" fill="#8A6544"/>'
         f'<rect x="1094" y="332" width="14" height="96" fill="#8A6544"/>'
         f'<path d="M 972 316 L 992 246 L 1064 246 L 1084 316 Z" fill="#E7C079" stroke="#C79E52" stroke-width="4"/>'
         f'<rect x="1022" y="316" width="12" height="0" fill="#8A6544"/>'
         f'<ellipse cx="1028" cy="330" rx="170" ry="120" fill="url(#glow)" opacity="0.55"/></g>')

# ---- relogio de parede antigo
cx, cy = 600, 250
b.append(f'<g>')
b.append(f'<ellipse cx="{cx}" cy="{cy+206}" rx="150" ry="20" fill="#B49770" opacity="0.35"/>')
# caixa de madeira
b.append(f'<path d="M {cx-124} {cy-64} q 0 -128 124 -128 q 124 0 124 128 L {cx+124} {cy+188} '
         f'q 0 26 -26 26 L {cx-98} {cy+214} q -26 0 -26 -26 Z" fill="#8E6039"/>')
b.append(f'<path d="M {cx-104} {cy-64} q 0 -110 104 -110 q 104 0 104 110 L {cx+104} {cy+180} '
         f'q 0 14 -16 14 L {cx-88} {cy+194} q -16 0 -16 -14 Z" fill="#A9764A"/>')
b.append(f'<rect x="{cx-92}" y="{cy+22}" width="184" height="156" rx="10" fill="#7C5232"/>')
b.append(f'<rect x="{cx-78}" y="{cy+32}" width="156" height="136" rx="8" fill="#C9DCE2" opacity="0.55"/>')
# pendulo
b.append(f'<line x1="{cx}" y1="{cy+34}" x2="{cx+26}" y2="{cy+124}" stroke="#C9A45E" stroke-width="7"/>')
b.append(f'<circle cx="{cx+29}" cy="{cy+136}" r="27" fill="#E0B65F" stroke="#B78D3C" stroke-width="5"/>')
b.append(f'<circle cx="{cx+29}" cy="{cy+136}" r="13" fill="#C99B45"/>')
# mostrador
b.append(f'<circle cx="{cx}" cy="{cy-56}" r="106" fill="#7C5232"/>')
b.append(f'<circle cx="{cx}" cy="{cy-56}" r="94" fill="#F6EFDF" stroke="#C9A45E" stroke-width="6"/>')
for i in range(12):
    a = math.radians(i * 30 - 90)
    r1, r2 = 78, (62 if i % 3 == 0 else 70)
    wdt = 7 if i % 3 == 0 else 4
    b.append(f'<line x1="{cx+r1*math.cos(a):.1f}" y1="{cy-56+r1*math.sin(a):.1f}" '
             f'x2="{cx+r2*math.cos(a):.1f}" y2="{cy-56+r2*math.sin(a):.1f}" stroke="#5C4326" stroke-width="{wdt}" stroke-linecap="round"/>')
b.append(f'<line x1="{cx}" y1="{cy-56}" x2="{cx+40}" y2="{cy-100}" stroke="#3E2E1C" stroke-width="9" stroke-linecap="round"/>')
b.append(f'<line x1="{cx}" y1="{cy-56}" x2="{cx-14}" y2="{cy+14}" stroke="#3E2E1C" stroke-width="6.5" stroke-linecap="round"/>')
b.append(f'<circle cx="{cx}" cy="{cy-56}" r="9" fill="#3E2E1C"/>')
# topo decorado
b.append(f'<circle cx="{cx}" cy="{cy-196}" r="14" fill="#C9A45E"/>')
b.append('</g>')

write("poema2", svg("poema2", W, H, "\n".join(b), bg="#E3D5BC"))

# ================================================================ POEMA 3 mar
b = []
b.append(f'<rect width="{W}" height="{H}" fill="url(#dawnGrad)"/>')
# sol nascendo a direita
b.append(f'<circle cx="920" cy="262" r="230" fill="url(#glow)" opacity="0.8"/>')
b.append(f'<circle cx="920" cy="262" r="72" fill="#F3C173"/>')
b.append(f'<circle cx="920" cy="262" r="72" fill="#F7D79B" opacity="0.5"/>')
for c in [(200, 96, 0.85, "#F2DFC8"), (470, 66, 0.65, "#EFE1CD"), (1080, 110, 0.7, "#F2DFC8")]:
    b.append(cloud(c[0], c[1], c[2], c[3], 0.7))
# horizonte
b.append(f'<rect x="0" y="288" width="{W}" height="{H-288}" fill="url(#seaGrad)"/>')
b.append(f'<rect x="0" y="286" width="{W}" height="6" fill="#8FB6CB" opacity="0.8"/>')
# reflexo do sol na agua
for i, y in enumerate(range(296, 420, 16)):
    wdt = 150 - i * 12
    b.append(f'<rect x="{920-wdt/2:.0f}" y="{y}" width="{wdt}" height="7" rx="3.5" fill="#F6D9A4" opacity="{0.55-i*0.05:.2f}"/>')
# faixas de ondas
bands = [(300, "#5E90AE", 0.55), (330, "#6E9FBB", 0.6), (366, "#79A9C4", 0.65)]
for (y, col, op) in bands:
    d = f'M -20 {y} '
    for x in range(-20, W + 80, 80):
        d += f'q 20 -10 40 0 q 20 10 40 0 '
    b.append(f'<path d="{d}" stroke="{col}" stroke-width="5" fill="none" opacity="{op}"/>')
# ondas maiores
b.append(f'<path d="M -20 404 q 120 -34 250 -6 q 130 28 260 0 q 130 -28 260 0 q 130 28 260 -6 q 130 -34 210 -4 L 1220 {H} L -20 {H} Z" fill="#4E7F9E"/>')
b.append(f'<path d="M -20 436 q 130 -30 260 -4 q 130 26 260 0 q 130 -26 260 0 q 130 26 280 -6 L 1220 {H} L -20 {H} Z" fill="#5E90AE"/>')
# areia + espuma
b.append(f'<path d="M -20 486 q 150 -22 320 -6 q 170 16 330 -2 q 160 -18 320 0 q 160 18 270 6 L 1220 {H} L -20 {H} Z" fill="#E9D9B9"/>')
b.append(f'<path d="M -20 486 q 150 -22 320 -6 q 170 16 330 -2 q 160 -18 320 0 q 160 18 270 6 L 1220 500 q -160 12 -280 -2 q -160 -18 -320 0 q -160 18 -330 2 q -170 -16 -320 6 Z" fill="#FBF6EA" opacity="0.9"/>')
for (sx, sy, sr) in [(180, 522, 26), (420, 534, 20), (760, 520, 24), (1010, 538, 18), (600, 546, 16)]:
    b.append(f'<circle cx="{sx}" cy="{sy}" r="{sr}" fill="#FFFFFF" opacity="0.45"/>')
    b.append(f'<circle cx="{sx+sr*0.7:.0f}" cy="{sy+6}" r="{sr*0.6:.0f}" fill="#FFFFFF" opacity="0.35"/>')
# conchinhas
b.append(f'<g transform="translate(300,540)"><path d="M 0 0 q -22 -26 0 -30 q 22 4 0 30 Z" fill="#E7C7B4"/>'
         f'<path d="M 0 0 L -8 -26 M 0 0 L 0 -30 M 0 0 L 8 -26" stroke="#CBA header" stroke-width="0"/></g>'.replace(' header', ''))

write("poema3", svg("poema3", W, H, "\n".join(b), bg="#EFE1CD"))

# ============================================================ POEMA 4 sertao
b = []
b.append(f'<defs></defs>')
b.append(f'<rect width="{W}" height="{H}" fill="#EBD6AE"/>')
b.append(f'<rect x="0" y="0" width="{W}" height="320" fill="#E4D0A8"/>')
b.append(f'<linearGradient id="sertaoSky" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#CFE0E6"/>'
         f'<stop offset="1" stop-color="#F0DEBB"/></linearGradient>')
b.append(f'<rect x="0" y="0" width="{W}" height="322" fill="url(#sertaoSky)"/>')
# sol forte
b.append(f'<circle cx="252" cy="112" r="180" fill="url(#glow)" opacity="0.75"/>')
b.append(f'<circle cx="252" cy="112" r="60" fill="#F0C463"/>')
# serra ao fundo
b.append(f'<path d="M -20 322 L 150 232 L 268 296 L 420 210 L 560 300 L 700 244 L 850 306 L 1000 236 L 1220 320 Z" fill="#C4A98A" opacity="0.75"/>')
b.append(f'<path d="M -20 322 L 210 268 L 380 312 L 600 262 L 800 318 L 1010 276 L 1220 322 Z" fill="#B79771" opacity="0.8"/>')
# chao rachado
b.append(f'<rect x="0" y="316" width="{W}" height="{H-316}" fill="url(#dryGrad)"/>')
cracks = [(-20, 380, [(120, 372), (210, 392), (330, 380), (470, 398), (610, 384), (760, 400), (900, 386), (1050, 402), (1220, 390)]),
          (-20, 452, [(140, 444), (280, 462), (420, 448), (560, 468), (700, 452), (840, 470), (980, 454), (1220, 466)]),
          (-20, 524, [(160, 516), (320, 534), (480, 520), (640, 538), (800, 524), (960, 540), (1220, 528)])]
for (sx, sy, pts) in cracks:
    d = f'M {sx} {sy} ' + " ".join(f'L {p[0]} {p[1]}' for p in pts)
    b.append(f'<path d="{d}" stroke="#9A6A47" stroke-width="4" fill="none" opacity="0.65"/>')
for (x, y1, y2) in [(180, 380, 452), (430, 384, 448), (700, 386, 452), (960, 388, 456),
                    (300, 452, 524), (580, 456, 520), (880, 458, 526), (1090, 460, 528)]:
    b.append(f'<path d="M {x} {y1} L {x+18} {(y1+y2)//2} L {x-8} {y2}" stroke="#9A6A47" stroke-width="3.5" fill="none" opacity="0.55"/>')

# poeira levada pelo vento
for (yy, op, sc) in [(352, 0.5, 1.0), (398, 0.4, 1.25), (300, 0.35, 0.8)]:
    b.append(f'<g opacity="{op}"><path d="M 640 {yy} q 120 -26 250 -4 q 120 22 250 -10" stroke="#D8BE96" '
             f'stroke-width="{14*sc:.0f}" fill="none" stroke-linecap="round"/></g>')
import random
rr = random.Random(7)
for _ in range(70):
    x = rr.uniform(540, 1200); y = rr.uniform(280, 470)
    r = rr.uniform(2.5, 7)
    b.append(f'<circle cx="{x:.0f}" cy="{y:.0f}" r="{r:.1f}" fill="#C9A97E" opacity="{rr.uniform(0.25,0.6):.2f}"/>')
b.append(f'<path d="M 560 330 q 140 -30 280 -6" stroke="#EBD9BC" stroke-width="7" fill="none" opacity="0.7" stroke-linecap="round"/>')
b.append(f'<path d="M 620 372 q 150 -26 300 -2" stroke="#EBD9BC" stroke-width="6" fill="none" opacity="0.55" stroke-linecap="round"/>')

# mandacaru ao fundo
b.append(f'<g transform="translate(1050,318)"><path d="M -12 0 L -12 -110 q 0 -18 12 -18 q 12 0 12 18 L 12 0 Z" fill="#6F8F5E"/>'
         f'<path d="M -12 -60 q -30 0 -30 -34 l 0 -22 q 0 -12 10 -12 q 10 0 10 12 l 0 20 q 0 18 10 18 Z" fill="#7D9E6A"/>'
         f'<path d="M 12 -74 q 30 0 30 -32 l 0 -18 q 0 -12 10 -12 q 10 0 10 12 l 0 20 q 0 42 -50 42 Z" fill="#7D9E6A"/></g>')

# plantinha brotando no primeiro plano
b.append(f'<g transform="translate(320,470)">'
         f'<ellipse cx="0" cy="34" rx="86" ry="20" fill="#B98B5E" opacity="0.35"/>'
         f'<path d="M 0 34 q -6 -50 -2 -78" stroke="#6F8F5E" stroke-width="9" fill="none" stroke-linecap="round"/>'
         f'<path d="M -2 -18 q -44 -14 -52 -50 q 42 -4 54 40 Z" fill="#8CB07B"/>'
         f'<path d="M 2 -30 q 44 -18 54 -52 q -44 -2 -56 44 Z" fill="#9CBE89"/>'
         f'<path d="M -1 -6 q -34 6 -46 34 q 34 6 48 -26 Z" fill="#7D9E6A"/></g>')

write("poema4", svg("poema4", W, H, "\n".join(b), bg="#E4D0A8"))
print("poemas 2-4 ok")
