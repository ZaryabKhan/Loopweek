#!/usr/bin/env python3
"""Loopweek brand mark generator.

Mark: a seven-segment open loop -- the 7 days of the week forming a loop that
returns. The leading segment after the top opening is 'today', in the app's
default accent orange #F4511E; the rest are the app ink #121212, on the app's
off-white #F2F2F2. Flat, single-accent, per the app's design system.
"""
import math, os
from PIL import Image, ImageDraw

ORANGE = (244, 81, 30)     # #F4511E  default accent
INK    = (18, 18, 18)      # #121212  dark scaffold
BG     = (242, 242, 242)   # #F2F2F2  light scaffold

SEG_SPAN = 44.0    # angular width of each day segment (deg)
GAP      = 4.0     # gap between segments (deg)
OPENING  = 28.0    # the loop opening at the top (deg)


def segments():
    segs = []
    start = 270.0 + OPENING / 2.0      # clockwise edge just past the top opening
    color = ORANGE
    for i in range(7):
        segs.append((start, start + SEG_SPAN, color))
        color = INK
        start = start + SEG_SPAN + GAP
    return segs


def draw_segment(draw, cx, cy, r_mid, thickness, a1, a2, color):
    bbox = [cx - r_mid, cy - r_mid, cx + r_mid, cy + r_mid]
    a = a1 % 360.0
    b = a2 % 360.0
    if a <= b:
        draw.arc(bbox, a, b, fill=color, width=thickness)
    else:
        draw.arc(bbox, a, 360.0, fill=color, width=thickness)
        draw.arc(bbox, 0.0, b, fill=color, width=thickness)


def render_mark(S, outer_ratio=0.30, inner_ratio=0.145, bg_fill=None):
    out_ratio = 4  # supersample for clean edges
    Hi = S * out_ratio
    if bg_fill is not None:
        img = Image.new("RGBA", (Hi, Hi), bg_fill + (255,))
    else:
        img = Image.new("RGBA", (Hi, Hi), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    cx = cy = Hi / 2.0
    r_out = Hi * outer_ratio
    r_in = Hi * inner_ratio
    r_mid = (r_out + r_in) / 2.0
    thickness = int(round(r_out - r_in))
    for (a1, a2, color) in segments():
        draw_segment(d, cx, cy, r_mid, thickness, a1, a2, color + (255,))
    img = img.resize((S, S), Image.LANCZOS)
    return img


def write(path, img):
    img.convert("RGBA").save(path)
    print("wrote", path)


def main():
    # file lives at <repo>/docs/brand/generate_logo.py -> repo is two levels up
    root = os.path.abspath(os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", ".."))
    res = os.path.join(root, "android", "app", "src", "main", "res")

    # Legacy full launcher icons (square, off-white tile)
    for name, size in [("mdpi", 48), ("hdpi", 72), ("xhdpi", 96),
                       ("xxhdpi", 144), ("xxxhdpi", 192)]:
        p = os.path.join(res, "mipmap-%s" % name, "ic_launcher.png")
        write(p, render_mark(size, bg_fill=BG))

    # Adaptive foreground / background at 432
    fg = render_mark(432, bg_fill=None)                      # transparent
    write(os.path.join(res, "mipmap-xxxhdpi", "ic_launcher_foreground.png"), fg)
    write(os.path.join(res, "mipmap-xxxhdpi", "ic_launcher_background.png"),
          Image.new("RGBA", (432, 432), BG + (255,)))

    # Brand preview sheets (docs)
    write(os.path.join(root, "docs", "brand", "logo-mark.png"),
          render_mark(1024, bg_fill=BG))
    write(os.path.join(root, "docs", "brand", "logo-mark-transparent.png"),
          render_mark(1024, bg_fill=None))


main()
