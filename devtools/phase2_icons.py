from pathlib import Path
root=Path(__file__).resolve().parent.parent/'assets/phase2/icons'
root.mkdir(exist_ok=True)
paths={
'water':'<path d="M32 7C25 18 15 28 15 39a17 17 0 0 0 34 0C49 28 39 18 32 7Z"/><path d="M23 37c0 7 4 11 10 11"/>',
'forest':'<path d="m32 6-17 22h9L12 43h16v13h8V43h16L40 28h9Z"/>',
'mountain':'<path d="m5 51 20-33 9 16 8-15 17 32Z"/><path d="m19 28 6 7 5-7M36 30l6 6 5-7"/>',
'wildlife':'<path d="M20 49c-7-11-5-23 3-28l-3-12 11 9 12-9-2 14c10 9 10 22 0 29-6 4-16 2-21-3Z"/><path d="M26 33h1m12 0h1M29 42l4 3 4-3"/>',
'rain_power':'<path d="M17 34a11 11 0 0 1 0-22 16 16 0 0 1 28 1 10 10 0 0 1 2 21H17Z"/><path d="m20 43-3 9m16-9-3 9m16-9-3 9"/>',
'bless':'<path d="m32 5 6 20 21 7-21 7-6 20-7-20-20-7 20-7Z"/><path d="m50 6 2 6 6 2-6 2-2 6-2-6-6-2 6-2Z"/>',
'menu':'<path d="M14 19h36M14 32h36M14 45h24"/>',
'center':'<circle cx="32" cy="32" r="14"/><path d="M32 8v10m0 28v10M8 32h10m28 0h10"/>',
'plus':'<path d="M32 16v32M16 32h32"/>',
'minus':'<path d="M16 32h32"/>',
'leaf':'<path d="M13 50C6 22 27 7 53 10c3 27-12 47-40 40Z"/><path d="m13 50 27-27M26 37l-1-12m1 12 13 1"/>',
}
for name,body in paths.items():
    (root/f'{name}.svg').write_text(f'<svg xmlns="http://www.w3.org/2000/svg" width="64" height="64" viewBox="0 0 64 64"><g fill="none" stroke="#dfdbb1" stroke-width="2.7" stroke-linecap="round" stroke-linejoin="round">{body}</g></svg>')
print('Generated eleven original consistent outline icons.')
