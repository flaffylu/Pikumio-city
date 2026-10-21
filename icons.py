#!/usr/bin/env python3
"""Draws the app icon and the splash screen for the Android app (no internet needed)."""
from PIL import Image, ImageDraw
import os

RES = '/home/claude/pikumio-city/android/app/src/main/res'
SKY_TOP, SKY_BOT = (28, 44, 92), (92, 150, 214)
SUN = (255, 196, 70)
HOUSE = [(24, 32, 62), (36, 48, 84), (18, 26, 52)]
ROAD = (38, 40, 50)


def scene(S, pad=0.0):
    """One square icon image of S x S pixels. pad = empty border share for adaptive icons."""
    im = Image.new('RGBA', (S, S), (0, 0, 0, 0))
    d = ImageDraw.Draw(im)
    x0 = int(S * pad)
    w = S - 2 * x0
    # sky
    for i in range(w):
        t = i / max(1, w - 1)
        c = tuple(int(a + (b - a) * t) for a, b in zip(SKY_TOP, SKY_BOT))
        d.rectangle([x0, x0 + i, x0 + w, x0 + i + 1], fill=c + (255,))
    # sun
    r = w * 0.13
    cx, cy = x0 + w * 0.72, x0 + w * 0.3
    d.ellipse([cx - r, cy - r, cx + r, cy + r], fill=SUN + (255,))
    # skyline
    bars = [(0.04, 0.42, 0.30), (0.20, 0.54, 0.22), (0.38, 0.36, 0.26), (0.58, 0.48, 0.20), (0.74, 0.40, 0.26)]
    for i, (bx, bh, bw) in enumerate(bars):
        left = x0 + w * bx
        top = x0 + w * (0.70 - bh)
        d.rectangle([left, top, left + w * bw, x0 + w * 0.74], fill=HOUSE[i % 3] + (255,))
        # windows
        gw = w * 0.035
        yy = top + w * 0.05
        while yy < x0 + w * 0.66:
            xx = left + w * 0.05
            while xx < left + w * bw - gw:
                d.rectangle([xx, yy, xx + gw * 0.7, yy + gw * 0.7], fill=(255, 214, 120, 235))
                xx += gw * 1.5
            yy += gw * 1.8
    # road with centre line
    d.rectangle([x0, x0 + w * 0.74, x0 + w, x0 + w], fill=ROAD + (255,))
    y = x0 + w * 0.87
    xx = x0 + w * 0.04
    while xx < x0 + w:
        d.rectangle([xx, y - w * 0.018, xx + w * 0.1, y + w * 0.018], fill=(245, 245, 245, 255))
        xx += w * 0.18
    # little red car
    cw, ch = w * 0.30, w * 0.12
    cx, cy = x0 + w * 0.34, x0 + w * 0.80
    d.rounded_rectangle([cx, cy, cx + cw, cy + ch], radius=ch * 0.35, fill=(226, 58, 48, 255))
    d.rounded_rectangle([cx + cw * 0.22, cy - ch * 0.55, cx + cw * 0.74, cy + ch * 0.2], radius=ch * 0.3, fill=(196, 40, 34, 255))
    d.rounded_rectangle([cx + cw * 0.28, cy - ch * 0.45, cx + cw * 0.68, cy + ch * 0.05], radius=ch * 0.2, fill=(150, 210, 240, 255))
    for fx in (0.22, 0.74):
        d.ellipse([cx + cw * fx - ch * 0.3, cy + ch * 0.68, cx + cw * fx + ch * 0.3, cy + ch * 1.28], fill=(22, 22, 26, 255))
    d.ellipse([cx + cw * 0.93, cy + ch * 0.18, cx + cw * 1.06, cy + ch * 0.5], fill=(255, 238, 170, 255))
    return im


def rounded(im, radius_share=0.22):
    S = im.size[0]
    mask = Image.new('L', (S, S), 0)
    ImageDraw.Draw(mask).rounded_rectangle([0, 0, S - 1, S - 1], radius=int(S * radius_share), fill=255)
    out = Image.new('RGBA', (S, S), (0, 0, 0, 0))
    out.paste(im, (0, 0), mask)
    return out


def circle(im):
    S = im.size[0]
    mask = Image.new('L', (S, S), 0)
    ImageDraw.Draw(mask).ellipse([0, 0, S - 1, S - 1], fill=255)
    out = Image.new('RGBA', (S, S), (0, 0, 0, 0))
    out.paste(im, (0, 0), mask)
    return out


SIZES = {'mdpi': 48, 'hdpi': 72, 'xhdpi': 96, 'xxhdpi': 144, 'xxxhdpi': 192}
for dpi, S in SIZES.items():
    base = scene(S)
    rounded(base).save(f'{RES}/mipmap-{dpi}/ic_launcher.png')
    circle(base).save(f'{RES}/mipmap-{dpi}/ic_launcher_round.png')
    # adaptive icon foreground: the system masks and zooms it, so draw smaller with a safe margin
    scene(int(S * 2.2), pad=0.22).save(f'{RES}/mipmap-{dpi}/ic_launcher_foreground.png')

# splash screens (the picture is centre-cropped, so draw generously)
SPL = {'mdpi': 320, 'hdpi': 480, 'xhdpi': 720, 'xxhdpi': 960, 'xxxhdpi': 1280}
for dpi, S in SPL.items():
    base = scene(S)
    for orient, size in (('land', (int(S * 1.6), S)), ('port', (S, int(S * 1.6)))):
        w, h = size
        canvas = Image.new('RGBA', size, (11, 14, 24, 255))
        side = max(w, h)
        img = base.resize((side, side), Image.LANCZOS)
        canvas.paste(img, ((w - side) // 2, (h - side) // 2))
        canvas.convert('RGB').save(f'{RES}/drawable-{orient}-{dpi}/splash.png')
scene(960).convert('RGB').save(f'{RES}/drawable/splash.png')
print('icons and splash screens written')
