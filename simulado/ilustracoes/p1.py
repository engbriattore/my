# -*- coding: utf-8 -*-
import sys, os, random
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from common import *

W, H = 1200, 560
random.seed(11)

extra = '''
  <linearGradient id="rainSky" x1="0" y1="0" x2="0" y2="1">
    <stop offset="0" stop-color="#9FB2C0"/><stop offset="0.55" stop-color="#BCC9D2"/><stop offset="1" stop-color="#D5DCE0"/>
  </linearGradient>
  <linearGradient id="roofG" x1="0" y1="0" x2="0" y2="1">
    <stop offset="0" stop-color="#B4674C"/><stop offset="1" stop-color="#8E4E38"/>
  </linearGradient>
  <linearGradient id="wetG" x1="0" y1="0" x2="0" y2="1">
    <stop offset="0" stop-color="#8FA3B0"/><stop offset="1" stop-color="#6E8494"/>
  </linearGradient>
  <linearGradient id="winG" x1="0" y1="0" x2="0" y2="1">
    <stop offset="0" stop-color="#FBE0A4"/><stop offset="1" stop-color="#E9BE६6"/>
  </linearGradient>
'''.replace("६", "6")

b = []
# ---- ceu chuvoso
b.append(f'<rect width="{W}" height="{H}" fill="url(#rainSky)"/>')
# nuvens suaves
for (cx, cy, s, o) in [(180,80,1.25,.55),(520,52,1.0,.42),(880,92,1.4,.5),(1120,60,0.9,.38)]:
    b.append(f'<g transform="translate({cx},{cy}) scale({s})" opacity="{o}">'
             f'<ellipse cx="0" cy="0" rx="120" ry="38" fill="#8FA3B4"/>'
             f'<ellipse cx="-52" cy="-14" rx="62" ry="34" fill="#8FA3B4"/>'
             f'<ellipse cx="44" cy="-20" rx="72" ry="38" fill="#9DB0BF"/></g>')

# ---- cidade ao fundo (silhuetas em camadas)
far = [(-20,300,120,180),(110,268,86,212),(206,320,104,160),(320,282,92,198),
       (700,296,110,184),(820,262,96,218),(926,318,120,162),(1056,280,100,200),(1156,310,90,170)]
for (x,y,w,h) in far:
    b.append(f'<rect x="{x}" y="{y}" width="{w}" height="{h}" rx="6" fill="#93A6B4" opacity="0.55"/>')
    for r in range(3):
        for c in range(3):
            wx = x + 16 + c*(w-32)/3
            wy = y + 22 + r*34
            if wy < y + h - 30:
                b.append(f'<rect x="{wx}" y="{wy}" width="14" height="18" rx="3" fill="#B7C6D0" opacity="0.7"/>')

mid = [(60,330,150,150),(250,352,130,128),(880,340,150,140),(1040,360,140,120)]
for (x,y,w,h) in mid:
    b.append(f'<rect x="{x}" y="{y}" width="{w}" height="{h}" rx="6" fill="#7C8F9E" opacity="0.75"/>')

# ---- casa principal (centro)
hx, hy = 400, 250
b.append(f'<g>')
# corpo
b.append(f'<rect x="{hx}" y="{hy+70}" width="400" height="200" rx="8" fill="#E6D9C2"/>')
b.append(f'<rect x="{hx}" y="{hy+70}" width="400" height="200" rx="8" fill="#D5C5AB" opacity="0.5" '
         f'clip-path="none" transform="translate(0,0)" style="mix-blend-mode:normal"/>')
b.append(f'<rect x="{hx}" y="{hy+70}" width="400" height="200" rx="8" fill="#EDE2CD"/>')
b.append(f'<rect x="{hx+300}" y="{hy+70}" width="100" height="200" fill="#DCCDB4" opacity="0.75"/>')
# telhado
b.append(f'<path d="M {hx-46} {hy+78} L {hx+200} {hy-38} L {hx+446} {hy+78} Z" fill="url(#roofG)"/>')
b.append(f'<path d="M {hx+200} {hy-38} L {hx+446} {hy+78} L {hx+200} {hy+78} Z" fill="#7E4531" opacity="0.35"/>')
# telhas (linhas)
for i in range(1, 5):
    t = i/5.0
    x1 = hx-46 + (200+46)*t; y1 = hy+78 - (78+38)*t
    x2 = hx+446 - (446-200)*t; y2 = hy+78 - (78+38)*t
    b.append(f'<line x1="{x1:.0f}" y1="{y1:.0f}" x2="{x2:.0f}" y2="{y2:.0f}" stroke="#7E4531" stroke-width="3" opacity="0.35"/>')
b.append(f'<rect x="{hx-52}" y="{hy+72}" width="504" height="16" rx="8" fill="#7E4531"/>')
# chamine
b.append(f'<rect x="{hx+296}" y="{hy-26}" width="46" height="72" rx="6" fill="#A55E44"/>')
b.append(f'<rect x="{hx+288}" y="{hy-38}" width="62" height="18" rx="6" fill="#8E4E38"/>')
# janela iluminada
b.append(f'<rect x="{hx+56}" y="{hy+112}" width="120" height="104" rx="8" fill="#FBE0A4" stroke="#A98A55" stroke-width="5"/>')
b.append(f'<line x1="{hx+116}" y1="{hy+112}" x2="{hx+116}" y2="{hy+216}" stroke="#A98A55" stroke-width="5"/>')
b.append(f'<line x1="{hx+56}" y1="{hy+164}" x2="{hx+176}" y2="{hy+164}" stroke="#A98A55" stroke-width="5"/>')
b.append(f'<ellipse cx="{hx+116}" cy="{hy+164}" rx="130" ry="110" fill="url(#glow)" opacity="0.55"/>')
# porta
b.append(f'<rect x="{hx+230}" y="{hy+150}" width="86" height="120" rx="6" fill="#8E6A4E"/>')
b.append(f'<rect x="{hx+238}" y="{hy+160}" width="70" height="46" rx="4" fill="#7A5A42"/>')
b.append(f'<circle cx="{hx+302}" cy="{hy+212}" r="6" fill="#E0C07A"/>')
b.append('</g>')

# ---- poste
b.append(f'<g><rect x="920" y="240" width="12" height="220" rx="6" fill="{GRAY_DD}"/>'
         f'<path d="M 926 244 q 0 -30 34 -30" stroke="{GRAY_DD}" stroke-width="12" fill="none" stroke-linecap="round"/>'
         f'<ellipse cx="962" cy="228" rx="26" ry="18" fill="#F0DCA8" stroke="{GRAY_DD}" stroke-width="5"/>'
         f'<ellipse cx="962" cy="250" rx="90" ry="70" fill="url(#glow)" opacity="0.5"/></g>')

# ---- rua molhada
b.append(f'<rect x="0" y="440" width="{W}" height="{H-440}" fill="url(#wetG)"/>')
b.append(f'<rect x="0" y="436" width="{W}" height="12" rx="6" fill="#5F7484" opacity="0.6"/>')
# reflexos verticais
for (rx, rw, rc, ro) in [(hx+116,118,"#F2D69A",0.35),(962,60,"#F0DCA8",0.3),(hx+270,70,"#C9B294",0.18)]:
    b.append(f'<rect x="{rx-rw/2:.0f}" y="444" width="{rw}" height="{H-444}" fill="{rc}" opacity="{ro}"/>')

# pocas com ondas circulares
for (px, py, pr) in [(200,500,96),(560,522,120),(900,494,84),(1080,528,104),(370,540,80)]:
    b.append(f'<ellipse cx="{px}" cy="{py}" rx="{pr}" ry="{pr*0.30:.0f}" fill="#7C93A3" opacity="0.85"/>')
    for k in (0.72, 0.48, 0.26):
        b.append(f'<ellipse cx="{px}" cy="{py}" rx="{pr*k:.0f}" ry="{pr*0.30*k:.0f}" fill="none" '
                 f'stroke="#CBD9E1" stroke-width="3.5" opacity="{0.75-k*0.35:.2f}"/>')
    b.append(f'<circle cx="{px}" cy="{py}" r="5" fill="#E4EDF2" opacity="0.9"/>')

# ---- chuva na diagonal (varias camadas de profundidade)
def rain(n, x0, x1, y0, y1, ln, wd, op, col="#E6EEF2"):
    out = []
    for _ in range(n):
        x = random.uniform(x0, x1); y = random.uniform(y0, y1)
        out.append(f'<line x1="{x:.0f}" y1="{y:.0f}" x2="{x-ln*0.42:.0f}" y2="{y+ln:.0f}" '
                   f'stroke="{col}" stroke-width="{wd}" stroke-linecap="round" opacity="{op}"/>')
    return "".join(out)

b.append(rain(120, -60, W+60, -40, H, 30, 3, 0.35, "#C6D5DE"))
b.append(rain(90,  -60, W+60, -40, H, 44, 4, 0.55, "#DCE7ED"))
b.append(rain(45,  -60, W+60, -40, H, 66, 5.5, 0.75, "#F0F5F7"))

# respingos no chao
for _ in range(26):
    x = random.uniform(20, W-20); y = random.uniform(452, H-14)
    b.append(f'<ellipse cx="{x:.0f}" cy="{y:.0f}" rx="9" ry="3" fill="none" stroke="#D6E3EA" stroke-width="2.5" opacity="0.6"/>')

open(os.path.join(os.path.dirname(os.path.abspath(__file__)), "svg", "poema1.svg"), "w", encoding="utf-8").write(
    svg("poema1", W, H, "\n".join(b), bg="#BCC9D2", defs_extra=extra))
print("ok")
