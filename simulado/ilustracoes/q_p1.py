# -*- coding: utf-8 -*-
"""Questoes 1 a 3 — poema 'Chuva na cidade'."""
import sys, os
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from common import *

W, H = 960, 360
BG = "#EEF2F4"


def drop_char(cx, cy, s=1.0, pose="drum", body="#8FC0DA", edge="#5A8FAE"):
    """Personagem gota. Corpo: ponta em y=-62, base do arco em y=+64 (apoio no chao)."""
    g = [f'<g transform="translate({cx},{cy}) scale({s})">']
    g.append(f'<path d="M 0 -62 C 26 -24 42 0 42 22 A 42 42 0 0 1 -42 22 C -42 0 -26 -24 0 -62 Z" '
             f'fill="{body}" stroke="{edge}" stroke-width="4.5"/>')
    g.append(f'<ellipse cx="-16" cy="10" rx="10" ry="15" fill="#FFFFFF" opacity="0.5"/>')

    if pose == "drum":
        g.append(f'<path d="M -38 14 q -32 8 -36 34" stroke="{body}" stroke-width="15" fill="none" stroke-linecap="round"/>')
        g.append(f'<path d="M 38 12 q 34 -2 42 22" stroke="{body}" stroke-width="15" fill="none" stroke-linecap="round"/>')
        g.append(f'<circle cx="-76" cy="50" r="13" fill="{edge}"/>')
        g.append(f'<circle cx="82" cy="36" r="13" fill="{edge}"/>')

    elif pose == "sit":
        # pernas cruzadas, desenhadas abaixo da linha mais larga do corpo
        g.append(f'<path d="M -68 62 q 34 22 70 0" stroke="{body}" stroke-width="21" fill="none" stroke-linecap="round"/>')
        g.append(f'<ellipse cx="-70" cy="63" rx="17" ry="12" fill="{edge}"/>')
        g.append(f'<path d="M 68 66 q -34 22 -70 0" stroke="{body}" stroke-width="21" fill="none" stroke-linecap="round"/>')
        g.append(f'<ellipse cx="70" cy="67" rx="17" ry="12" fill="{edge}"/>')
        # bracos relaxados, maos sobre os joelhos
        g.append(f'<path d="M 36 14 q 26 20 20 36" stroke="{body}" stroke-width="15" fill="none" stroke-linecap="round"/>')
        g.append(f'<circle cx="54" cy="52" r="12" fill="{edge}"/>')
        g.append(f'<path d="M -36 14 q -26 20 -20 36" stroke="{body}" stroke-width="15" fill="none" stroke-linecap="round"/>')
        g.append(f'<circle cx="-54" cy="52" r="12" fill="{edge}"/>')

    g.append(face(0, 0, 1.0, blush="#E79A9A"))
    g.append('</g>')
    return "".join(g)


b = [f'<rect width="{W}" height="{H}" fill="{BG}"/>']
b.append(f'<rect x="0" y="0" width="{W}" height="{H}" fill="url(#skyGrad)" opacity="0.55"/>')

# painel esquerdo -------------------------------------------------- tamborila
b.append(panel(20, 18, 448, 324, fill="#F7F4EC"))
b.append(f'<g clip-path="url(#clipL)">')
b.append(f'<rect x="22" y="20" width="444" height="320" fill="#DCE7EE"/>')
b.append(rain(3, 34, 20, 470, 10, 300, 34, 3.5, 0.5, "#FFFFFF"))
# telhado
b.append(f'<path d="M 40 264 L 244 152 L 448 264 Z" fill="#B4674C"/>')
b.append(f'<path d="M 244 152 L 448 264 L 244 264 Z" fill="#8E4E38" opacity="0.3"/>')
for i in range(1, 4):
    t = i / 4.0
    b.append(f'<line x1="{40+204*t:.0f}" y1="{264-112*t:.0f}" x2="{448-204*t:.0f}" y2="{264-112*t:.0f}" '
             f'stroke="#7E4531" stroke-width="3.5" opacity="0.4"/>')
b.append(f'<rect x="34" y="258" width="420" height="14" rx="7" fill="#7E4531"/>')
b.append(f'<rect x="60" y="272" width="368" height="68" fill="#EDE2CD"/>')
# marcas de batida no telhado
for (mx, my) in [(150, 214), (196, 190), (300, 196), (346, 220)]:
    b.append(f'<g opacity="0.85"><path d="M {mx-16} {my-12} l -9 -12 M {mx} {my-18} l 0 -15 M {mx+16} {my-12} l 9 -12" '
             f'stroke="#FFF3D6" stroke-width="4.5" stroke-linecap="round"/></g>')
b.append(drop_char(244, 148, 0.92, "drum"))
b.append('</g>')
b.append(verse_tag(66, 36, "verso 2 — tamborila no telhado", size=23))

# painel direito -------------------------------------------------- senta
b.append(panel(492, 18, 448, 324, fill="#F7F4EC"))
b.append(f'<g clip-path="url(#clipR)">')
b.append(f'<rect x="494" y="20" width="444" height="320" fill="#DCE7EE"/>')
b.append(rain(5, 20, 494, 940, 10, 240, 30, 3, 0.35, "#FFFFFF"))
b.append(f'<rect x="494" y="266" width="444" height="76" fill="#8FA3B0"/>')
b.append(f'<rect x="494" y="262" width="444" height="10" rx="5" fill="#6E8494" opacity="0.7"/>')
for (px, py, pr) in [(556, 286, 50), (886, 292, 44)]:
    b.append(f'<ellipse cx="{px}" cy="{py}" rx="{pr}" ry="{pr*0.26:.0f}" fill="#7C93A3"/>')
    for k in (0.62,):
        b.append(f'<ellipse cx="{px}" cy="{py}" rx="{pr*k:.0f}" ry="{pr*0.26*k:.0f}" fill="none" '
                 f'stroke="#CFDDE5" stroke-width="3" opacity="0.8"/>')
b.append(drop_char(664, 212, 1.0, "sit"))
for (px, py, pr) in [(800, 332, 70), (546, 336, 58)]:
    b.append(f'<ellipse cx="{px}" cy="{py}" rx="{pr}" ry="{pr*0.24:.0f}" fill="#7C93A3"/>')
    for k in (0.66, 0.4):
        b.append(f'<ellipse cx="{px}" cy="{py}" rx="{pr*k:.0f}" ry="{pr*0.24*k:.0f}" fill="none" '
                 f'stroke="#CFDDE5" stroke-width="3" opacity="0.85"/>')
b.append('</g>')
b.append(verse_tag(548, 36, "verso 10 — senta no chão", size=23))

defs_extra = ('<clipPath id="clipL"><rect x="22" y="20" width="444" height="320" rx="18"/></clipPath>'
              '<clipPath id="clipR"><rect x="494" y="20" width="444" height="320" rx="18"/></clipPath>')

write("q01", svg("q01", W, H, "\n".join(b), bg=BG, defs_extra=defs_extra))
print("q01 ok")
