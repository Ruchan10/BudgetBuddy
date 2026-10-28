"""Generates the Budget Buddy launcher icon as SVG + Android VectorDrawables.

Canvas is the 108x108 adaptive-icon grid; the safe zone is a 33-radius
circle around (54, 54).

Usage: python3 tool/launcher_icon.py <out_dir>, then copy the ic_launcher_*.xml
files to android/app/src/main/res/drawable/ and render legacy.svg to the
mipmap launcher_icon.png sizes and assets/images/logo.webp.
"""
import sys
from pathlib import Path

out = Path(sys.argv[1])
out.mkdir(parents=True, exist_ok=True)


def rrect(x, y, w, h, r):
    return (f"M{x + r},{y}h{w - 2 * r}a{r},{r} 0 0 1 {r},{r}v{h - 2 * r}"
            f"a{r},{r} 0 0 1 -{r},{r}h-{w - 2 * r}a{r},{r} 0 0 1 -{r},-{r}"
            f"v-{h - 2 * r}a{r},{r} 0 0 1 {r},-{r}z")


def circle(cx, cy, r):
    return (f"M{cx - r},{cy}a{r},{r} 0 1 0 {2 * r},0"
            f"a{r},{r} 0 1 0 -{2 * r},0z")


NAVY = "#0E2A5C"
SCALE, DY = 0.86, 3
SVG_T = f"translate({54 * (1 - SCALE)},{54 * (1 - SCALE) + DY}) scale({SCALE})"
GROUP = (f'    <group\n        android:pivotX="54"\n        android:pivotY="54"\n'
         f'        android:scaleX="{SCALE}"\n        android:scaleY="{SCALE}"\n'
         f'        android:translateY="{DY}">\n')
BG_TOP, BG_BOTTOM = "#3D93F7", "#1550C2"

# Back pocket, two coins, front body, clasp, face.
pocket = rrect(31, 39, 46, 18, 6)
coin_back = circle(46, 38, 8.5)
coin_back_in = circle(46, 38, 5.6)
coin = circle(61, 34, 11)
coin_in = circle(61, 34, 7.4)
body = rrect(28, 45, 50, 33, 9)
clasp = rrect(63, 53.5, 19, 15, 7.5)
clasp_dot = circle(72.5, 61, 2.6)
eye_l = circle(40.5, 58.5, 2.7)
eye_r = circle(52.5, 58.5, 2.7)
smile = "M40,64.2Q46.5,71.4 53,64.2"

# (path, fill, stroke, stroke width)
FG = [
    (pocket, "#BFD9FF", None, 0),
    (coin_back, "#F5A623", None, 0),
    (coin_back_in, "#FFC94D", None, 0),
    (coin, "#F5A623", None, 0),
    (coin_in, "#FFD45E", None, 0),
    ("M56.2,30.2a6.4,6.4 0 0 1 6.6,-2.6", None, "#FFF1C2", 1.8),
    (body, "#FFFFFF", None, 0),
    (clasp, "#E3EEFF", None, 0),
    (clasp_dot, BG_BOTTOM, None, 0),
    (eye_l, NAVY, None, 0),
    (eye_r, NAVY, None, 0),
    (smile, None, NAVY, 2.6),
]


def svg(full, size=108, crop=None):
    """full: include background. crop: (x, y, w) square viewBox."""
    vb = f"{crop[0]} {crop[1]} {crop[2]} {crop[2]}" if crop else "0 0 108 108"
    parts = [f'<svg xmlns="http://www.w3.org/2000/svg" width="{size}" '
             f'height="{size}" viewBox="{vb}">']
    if full:
        parts.append(
            '<defs><linearGradient id="bg" x1="0" y1="0" x2="0" y2="1">'
            f'<stop offset="0" stop-color="{BG_TOP}"/>'
            f'<stop offset="1" stop-color="{BG_BOTTOM}"/></linearGradient>'
            '<filter id="sh" x="-20%" y="-20%" width="140%" height="160%">'
            '<feDropShadow dx="0" dy="2" stdDeviation="2" '
            'flood-color="#0A2E73" flood-opacity="0.35"/></filter></defs>')
        if crop:
            x, y, w = crop
            parts.append(f'<path d="{rrect(18, 18, 72, 72, 72 * 0.23)}" fill="url(#bg)"/>')
        else:
            parts.append('<rect width="108" height="108" fill="url(#bg)"/>')
    parts.append('<g filter="url(#sh)">' if full else '<g>')
    parts.append(f'<g transform="{SVG_T}">')
    for d, fill, stroke, sw in FG:
        if stroke:
            parts.append(f'<path d="{d}" fill="none" stroke="{stroke}" '
                         f'stroke-width="{sw}" stroke-linecap="round"/>')
        else:
            parts.append(f'<path d="{d}" fill="{fill}"/>')
    parts.append('</g></g></svg>')
    return "".join(parts)


def vd_path(d, fill=None, stroke=None, sw=0, extra=""):
    attrs = [f'android:pathData="{d}"']
    if fill:
        attrs.append(f'android:fillColor="{fill}"')
    if stroke:
        attrs += [f'android:strokeColor="{stroke}"', f'android:strokeWidth="{sw}"',
                  'android:strokeLineCap="round"']
    return "    <path\n        " + "\n        ".join(attrs + ([extra] if extra else [])) + " />"


HEADER = ('<?xml version="1.0" encoding="utf-8"?>\n'
          '<vector xmlns:android="http://schemas.android.com/apk/res/android"{ns}\n'
          '    android:width="108dp"\n    android:height="108dp"\n'
          '    android:viewportWidth="108"\n    android:viewportHeight="108">\n')

fg = (HEADER.format(ns="") + GROUP + "\n".join(vd_path(d, f, s, w) for d, f, s, w in FG)
      + "\n    </group>\n</vector>\n")

bg = HEADER.format(ns='\n    xmlns:aapt="http://schemas.android.com/aapt"') + f"""    <path android:pathData="M0,0h108v108h-108z">
        <aapt:attr name="android:fillColor">
            <gradient
                android:type="linear"
                android:startX="54"
                android:startY="0"
                android:endX="54"
                android:endY="108">
                <item android:offset="0" android:color="{BG_TOP}" />
                <item android:offset="1" android:color="{BG_BOTTOM}" />
            </gradient>
        </aapt:attr>
    </path>
</vector>
"""

# Themed (Android 13+) icons only use alpha, so the face is cut out of the
# body with evenOdd. The smile becomes a filled crescent.
smile_fill = "M40,63.4Q46.5,72.4 53,63.4Q46.5,69.6 40,63.4z"
mono = HEADER.format(ns="") + GROUP + "\n".join([
    vd_path(pocket, "#FF000000", extra='android:fillAlpha="0.55"'),
    vd_path(coin_back + coin_back_in, "#FF000000", extra='android:fillType="evenOdd"'),
    vd_path(coin + coin_in, "#FF000000", extra='android:fillType="evenOdd"'),
    vd_path(body + clasp + eye_l + eye_r + smile_fill, "#FF000000",
            extra='android:fillType="evenOdd"'),
    vd_path(clasp_dot, "#FF000000"),
]) + "\n    </group>\n</vector>\n"

(out / "ic_launcher_foreground.xml").write_text(fg)
(out / "ic_launcher_background.xml").write_text(bg)
(out / "ic_launcher_monochrome.xml").write_text(mono)
(out / "adaptive_full.svg").write_text(svg(True))
# Legacy/in-app icon: the part a launcher mask shows, as a rounded square.
(out / "legacy.svg").write_text(svg(True, crop=(15, 15, 78)))
(out / "fg_only.svg").write_text(svg(False))
