# -*- coding: utf-8 -*-
"""Sistema visual compartilhado das ilustracoes do simulado adaptado.

Paleta de baixa saturacao / tons neutros e quentes: a pesquisa sobre design
sensorialmente amigavel indica que cores muito vibrantes e contrastes duros
sobrecarregam parte dos alunos autistas.
"""

INK       = "#22303C"
INK_SOFT  = "#55636E"
CREAM     = "#F5F1E8"
CREAM_D   = "#EAE2D2"
PAPER     = "#FBF8F2"
BORDER    = "#C9C1AE"

SKY_1     = "#DCE9F0"
SKY_2     = "#B4D0DF"
SKY_3     = "#8FB6CB"
BLUE      = "#6E9FBB"
BLUE_D    = "#456F8C"
BLUE_DD   = "#2E4F66"

TEAL      = "#7FB0A5"
TEAL_D    = "#57887E"

GREEN     = "#8CB07B"
GREEN_D   = "#628556"
GREEN_DD  = "#43603B"

SAND      = "#E9D9B9"
SAND_D    = "#D4BE96"
SAND_DD   = "#B79E73"

CLAY      = "#C98A66"
CLAY_D    = "#A96A4B"
RUST      = "#9A5A40"
BRICK     = "#B4674C"

GOLD      = "#E9B95F"
GOLD_D    = "#CB9633"
AMBER     = "#DFA23F"

ROSE      = "#D7A3A0"
ROSE_D    = "#B87F7C"
LILAC     = "#A296BE"
PLUM      = "#6C6087"

GRAY      = "#BCB2A0"
GRAY_D    = "#918875"
GRAY_DD   = "#6B6355"

SKIN      = "#E8C39E"
SKIN_D    = "#C99C74"
HAIR      = "#4A3A2E"

FONT = "Liberation Sans, Arial, DejaVu Sans, sans-serif"


def defs(extra=""):
    """Gradientes e filtros reutilizados por todas as cenas."""
    return f'''<defs>
  <linearGradient id="skyGrad" x1="0" y1="0" x2="0" y2="1">
    <stop offset="0" stop-color="{SKY_1}"/><stop offset="1" stop-color="{SKY_2}"/>
  </linearGradient>
  <linearGradient id="nightGrad" x1="0" y1="0" x2="0" y2="1">
    <stop offset="0" stop-color="#2E3B52"/><stop offset="0.6" stop-color="#42536E"/><stop offset="1" stop-color="#5A6A85"/>
  </linearGradient>
  <linearGradient id="dawnGrad" x1="0" y1="0" x2="0" y2="1">
    <stop offset="0" stop-color="#EBD9C2"/><stop offset="0.45" stop-color="#EFCDA4"/><stop offset="1" stop-color="#D9E2E4"/>
  </linearGradient>
  <linearGradient id="seaGrad" x1="0" y1="0" x2="0" y2="1">
    <stop offset="0" stop-color="{BLUE}"/><stop offset="1" stop-color="{BLUE_D}"/>
  </linearGradient>
  <linearGradient id="earthGrad" x1="0" y1="0" x2="0" y2="1">
    <stop offset="0" stop-color="{CLAY}"/><stop offset="1" stop-color="{RUST}"/>
  </linearGradient>
  <linearGradient id="dryGrad" x1="0" y1="0" x2="0" y2="1">
    <stop offset="0" stop-color="#E0C79C"/><stop offset="1" stop-color="{CLAY_D}"/>
  </linearGradient>
  <linearGradient id="paperGrad" x1="0" y1="0" x2="0" y2="1">
    <stop offset="0" stop-color="{PAPER}"/><stop offset="1" stop-color="{CREAM_D}"/>
  </linearGradient>
  <radialGradient id="glow" cx="0.5" cy="0.5" r="0.5">
    <stop offset="0" stop-color="#FFF3D0" stop-opacity="0.95"/>
    <stop offset="0.55" stop-color="#FFE7A8" stop-opacity="0.45"/>
    <stop offset="1" stop-color="#FFE7A8" stop-opacity="0"/>
  </radialGradient>
  <radialGradient id="moonGlow" cx="0.5" cy="0.5" r="0.5">
    <stop offset="0" stop-color="#F4F0E2" stop-opacity="0.85"/>
    <stop offset="0.5" stop-color="#E4E8E2" stop-opacity="0.30"/>
    <stop offset="1" stop-color="#E4E8E2" stop-opacity="0"/>
  </radialGradient>
  <linearGradient id="silver" x1="0" y1="0" x2="0" y2="1">
    <stop offset="0" stop-color="#EFEFE6"/><stop offset="1" stop-color="#C4C8C2"/>
  </linearGradient>
  <filter id="soft" x="-25%" y="-25%" width="150%" height="150%">
    <feGaussianBlur stdDeviation="7"/>
  </filter>
  <filter id="soft2" x="-25%" y="-25%" width="150%" height="150%">
    <feGaussianBlur stdDeviation="2.5"/>
  </filter>
  <filter id="blurFast" x="-25%" y="-25%" width="150%" height="150%">
    <feGaussianBlur stdDeviation="6.5"/>
  </filter>
{extra}
</defs>'''


def svg(name, w, h, body, bg=CREAM, defs_extra="", frame=True):
    """Monta um SVG completo com moldura arredondada consistente."""
    fr = ""
    if frame:
        fr = (f'<rect x="3" y="3" width="{w-6}" height="{h-6}" rx="26" ry="26" '
              f'fill="none" stroke="{BORDER}" stroke-width="4"/>')
    return f'''<svg xmlns="http://www.w3.org/2000/svg" width="{w}" height="{h}" viewBox="0 0 {w} {h}" font-family="{FONT}">
{defs(defs_extra)}
<clipPath id="frameClip"><rect x="5" y="5" width="{w-10}" height="{h-10}" rx="24" ry="24"/></clipPath>
<rect width="{w}" height="{h}" rx="28" ry="28" fill="{bg}"/>
<g clip-path="url(#frameClip)">
{body}
</g>
{fr}
</svg>'''


def label(x, y, text, size=30, color=INK, weight="bold", anchor="middle", opacity=1.0):
    return (f'<text x="{x}" y="{y}" font-size="{size}" font-weight="{weight}" fill="{color}" '
            f'text-anchor="{anchor}" opacity="{opacity}">{text}</text>')


def chip(x, y, w, h, text, fill=PAPER, stroke=BORDER, color=INK, size=26):
    """Etiqueta arredondada usada para nomear o que a imagem mostra."""
    return (f'<g><rect x="{x}" y="{y}" width="{w}" height="{h}" rx="{h/2}" ry="{h/2}" '
            f'fill="{fill}" stroke="{stroke}" stroke-width="3"/>'
            f'{label(x + w/2, y + h/2 + size*0.35, text, size=size, color=color)}</g>')


def write(name, content):
    import os
    base = os.path.dirname(os.path.abspath(__file__))
    path = os.path.join(base, "svg", name + ".svg")
    with open(path, "w", encoding="utf-8") as f:
        f.write(content)
    return path


# ---------------------------------------------------------------- primitivas

def cloud(cx, cy, s=1.0, fill="#FFFFFF", op=0.85):
    return (f'<g transform="translate({cx},{cy}) scale({s})" opacity="{op}" fill="{fill}">'
            f'<ellipse cx="0" cy="6" rx="96" ry="30"/>'
            f'<ellipse cx="-42" cy="-10" rx="52" ry="34"/>'
            f'<ellipse cx="18" cy="-20" rx="62" ry="40"/>'
            f'<ellipse cx="66" cy="-2" rx="44" ry="28"/></g>')


def rain(seed, n, x0, x1, y0, y1, ln, wd, op, col="#E6EEF2", slant=-0.42):
    import random as _r
    rr = _r.Random(seed)
    out = []
    for _ in range(n):
        x = rr.uniform(x0, x1); y = rr.uniform(y0, y1)
        out.append(f'<line x1="{x:.0f}" y1="{y:.0f}" x2="{x + ln*slant:.0f}" y2="{y+ln:.0f}" '
                   f'stroke="{col}" stroke-width="{wd}" stroke-linecap="round" opacity="{op}"/>')
    return "".join(out)


def drop(cx, cy, s=1.0, fill="#8FC0DA", stroke="#5F93B0"):
    """Gota d'agua com brilho — usada como personagem nas cenas de chuva."""
    return (f'<g transform="translate({cx},{cy}) scale({s})">'
            f'<path d="M 0 -46 C 22 -16 34 2 34 18 A 34 34 0 0 1 -34 18 C -34 2 -22 -16 0 -46 Z" '
            f'fill="{fill}" stroke="{stroke}" stroke-width="4"/>'
            f'<ellipse cx="-11" cy="10" rx="8" ry="12" fill="#FFFFFF" opacity="0.55"/></g>')


def face(cx, cy, s=1.0, eye="#22303C", look=0, smile=True, blush=None):
    """Rostinho simples e amigavel (olhos + sorriso) para objetos personificados."""
    m = (f'<path d="M -13 8 q 13 13 26 0" stroke="{eye}" stroke-width="4" fill="none" stroke-linecap="round"/>'
         if smile else
         f'<path d="M -12 12 q 12 -9 24 0" stroke="{eye}" stroke-width="4" fill="none" stroke-linecap="round"/>')
    bl = ""
    if blush:
        bl = (f'<ellipse cx="-26" cy="4" rx="9" ry="6" fill="{blush}" opacity="0.55"/>'
              f'<ellipse cx="26" cy="4" rx="9" ry="6" fill="{blush}" opacity="0.55"/>')
    return (f'<g transform="translate({cx},{cy}) scale({s})">{bl}'
            f'<ellipse cx="-13" cy="-8" rx="6" ry="8" fill="{eye}"/>'
            f'<ellipse cx="13" cy="-8" rx="6" ry="8" fill="{eye}"/>'
            f'<circle cx="{-13+look+2}" cy="-11" r="2.2" fill="#FFFFFF"/>'
            f'<circle cx="{13+look+2}" cy="-11" r="2.2" fill="#FFFFFF"/>'
            f'{m}</g>')


def arm(x1, y1, x2, y2, w=11, col=SKIN, cap="round"):
    return f'<line x1="{x1}" y1="{y1}" x2="{x2}" y2="{y2}" stroke="{col}" stroke-width="{w}" stroke-linecap="{cap}"/>'


def sparkle(cx, cy, r=14, col="#FFF6DA", op=0.9):
    return (f'<path d="M {cx} {cy-r} Q {cx+r*0.22} {cy-r*0.22} {cx+r} {cy} '
            f'Q {cx+r*0.22} {cy+r*0.22} {cx} {cy+r} '
            f'Q {cx-r*0.22} {cy+r*0.22} {cx-r} {cy} '
            f'Q {cx-r*0.22} {cy-r*0.22} {cx} {cy-r} Z" fill="{col}" opacity="{op}"/>')


def arrow(x1, y1, x2, y2, col=INK_SOFT, w=6, head=17, dash=None):
    import math
    a = math.atan2(y2 - y1, x2 - x1)
    bx, by = x2 - head * 0.92 * math.cos(a), y2 - head * 0.92 * math.sin(a)
    d = f' stroke-dasharray="{dash}"' if dash else ""
    return (f'<line x1="{x1}" y1="{y1}" x2="{bx:.1f}" y2="{by:.1f}" stroke="{col}" stroke-width="{w}" '
            f'stroke-linecap="round"{d}/>'
            f'<path d="M {x2} {y2} L {x2 - head*math.cos(a-0.42):.1f} {y2 - head*math.sin(a-0.42):.1f} '
            f'L {x2 - head*math.cos(a+0.42):.1f} {y2 - head*math.sin(a+0.42):.1f} Z" fill="{col}"/>')


def bubble(x, y, w, h, text, size=30, fill=PAPER, stroke=INK_SOFT, color=INK, tail="bl", lines=None):
    """Balao de fala com rabicho."""
    lines = lines or [text]
    t = ""
    if tail == "bl":
        t = f'<path d="M {x+34} {y+h} l 0 34 l 40 -34 Z" fill="{fill}" stroke="{stroke}" stroke-width="4"/>'
    elif tail == "br":
        t = f'<path d="M {x+w-74} {y+h} l 40 34 l 0 -34 Z" fill="{fill}" stroke="{stroke}" stroke-width="4"/>'
    ty = y + h/2 - (len(lines)-1)*size*0.62 + size*0.34
    txt = "".join(label(x + w/2, ty + i*size*1.24, ln, size=size, color=color) for i, ln in enumerate(lines))
    return (f'<g>{t}<rect x="{x}" y="{y}" width="{w}" height="{h}" rx="{min(h/2,34)}" fill="{fill}" '
            f'stroke="{stroke}" stroke-width="4"/>'
            f'<path d="M {x+34} {y+h} l 0 30 l 36 -30" fill="{fill}" stroke="none"/>{txt}</g>')


def panel(x, y, w, h, fill=PAPER, stroke=BORDER, r=20, sw=3.5, op=1.0):
    return (f'<rect x="{x}" y="{y}" width="{w}" height="{h}" rx="{r}" ry="{r}" fill="{fill}" '
            f'stroke="{stroke}" stroke-width="{sw}" opacity="{op}"/>')


def verse_tag(x, y, text, w=None, size=25, fill="#EDE4D2", color=INK):
    """Etiqueta que cita o verso do poema — nunca a resposta."""
    w = w or (len(text) * size * 0.54 + 40)
    return chip(x, y, w, size * 1.85, text, fill=fill, stroke=BORDER, color=color, size=size)


def tree(cx, cy, s=1.0, trunk=RUST, leaf=GREEN, leaf_d=GREEN_D):
    return (f'<g transform="translate({cx},{cy}) scale({s})">'
            f'<path d="M -9 0 L -6 -70 L 6 -70 L 9 0 Z" fill="{trunk}"/>'
            f'<path d="M -6 -46 l -22 -18" stroke="{trunk}" stroke-width="7" stroke-linecap="round"/>'
            f'<path d="M 6 -54 l 24 -16" stroke="{trunk}" stroke-width="7" stroke-linecap="round"/>'
            f'<ellipse cx="0" cy="-88" rx="56" ry="44" fill="{leaf}"/>'
            f'<ellipse cx="-32" cy="-72" rx="34" ry="28" fill="{leaf_d}" opacity="0.75"/>'
            f'<ellipse cx="28" cy="-70" rx="30" ry="25" fill="{leaf_d}" opacity="0.6"/>'
            f'<ellipse cx="8" cy="-104" rx="34" ry="26" fill="{leaf}" opacity="0.9"/></g>')
