# -*- coding: utf-8 -*-
"""docx-js escreve os filhos de <w:pBdr> como top, bottom, left, right.

O schema exige top, left, bottom, right, between, bar. Reordena sem tocar
em mais nada do pacote.
"""
import re, shutil, sys, zipfile

ORDER = ["top", "left", "bottom", "right", "between", "bar"]
path = sys.argv[1]


def fix(xml):
    def repl(m):
        inner = m.group(1)
        parts = re.findall(r'<w:(?:top|left|bottom|right|between|bar)\b[^>]*/>', inner)
        parts.sort(key=lambda p: ORDER.index(re.match(r'<w:(\w+)', p).group(1)))
        return "<w:pBdr>" + "".join(parts) + "</w:pBdr>"
    return re.sub(r'<w:pBdr>(.*?)</w:pBdr>', repl, xml, flags=re.S)


tmp = path + ".tmp"
with zipfile.ZipFile(path) as zin, zipfile.ZipFile(tmp, "w", zipfile.ZIP_DEFLATED) as zout:
    for item in zin.infolist():
        data = zin.read(item.filename)
        if item.filename == "word/document.xml":
            data = fix(data.decode("utf-8")).encode("utf-8")
        zout.writestr(item, data)
shutil.move(tmp, path)
print("pBdr reordenado em", path)
