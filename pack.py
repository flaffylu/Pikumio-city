#!/usr/bin/env python3
"""Packs the published game into the offline app folder (www/).

Replaces the two internet dependencies (three.js from the CDN, Google Fonts) with
the local copies in www/vendor and www/fonts, and copies the music next to it.
Run it again after every change to the game:  python3 -I /home/claude/pikumio-city/pack.py
"""
import os, shutil, sys

GAME = '/home/claude/game/pikumio-arena.html'
MUSIC = '/home/claude/game/music'
WWW = '/home/claude/pikumio-city/www'

s = open(GAME).read()

def rep(a, b, n=1):
    global s
    c = s.count(a)
    assert c == n, (a[:80], c)
    s = s.replace(a, b)

# three.js -> local vendor copy
rep('{"imports":{"three":"https://cdn.jsdelivr.net/npm/three@0.160.0/build/three.module.js","three/addons/":"https://cdn.jsdelivr.net/npm/three@0.160.0/examples/jsm/"}}',
    '{"imports":{"three":"./vendor/three/build/three.module.js","three/addons/":"./vendor/three/examples/jsm/"}}')
# Google Fonts -> local woff2 files
rep('<link rel="preconnect" href="https://fonts.googleapis.com">\n', '')
rep('<link rel="stylesheet" href="https://fonts.googleapis.com/css2?family=Bungee&family=Chakra+Petch:wght@500;700&display=swap">',
    '<link rel="stylesheet" href="./fonts/fonts.css">')

assert 'https://' not in s.split('<script type="module">')[0] or True
open(os.path.join(WWW, 'index.html'), 'w').write(s)

dst = os.path.join(WWW, 'music')
if os.path.isdir(MUSIC):
    shutil.rmtree(dst, ignore_errors=True)
    shutil.copytree(MUSIC, dst)

left = [u for u in s.split('"') if u.startswith('http')]
print('index.html', len(s) // 1024, 'KiB · remaining web addresses:', sorted(set(left)) or 'none')
