"""Original metal-rimmed vector controls; no third-party game textures."""
from pathlib import Path
p=Path(__file__).resolve().parents[1]/'assets/ui_classic';p.mkdir(exist_ok=True)
paths={
 'sword':'M13 41L37 12L43 9L42 17L19 44M13 32L29 45M12 40L7 46M10 43L15 48',
 'attack':'M10 13L15 14L42 42M42 13L37 14L10 42M8 35L21 47M35 47L47 35',
 'shield':'M27 9L42 16L40 32Q37 42 27 47Q17 42 14 32L12 16Z M27 13V42',
 'hero':'M20 23V15Q27 7 34 15V23L30 29H24Z M13 43V34L22 29L27 35L32 29L41 34V43Z',
 'bag':'M17 16H37L42 44H12Z M21 17V13Q27 8 33 13V17 M14 25H40 M24 27H30V33H24Z',
 'quest':'M17 10H39V45H14V13Z M21 19H33 M21 26H33 M21 33H29',
 'map':'M10 16L20 11L34 16L44 11V41L34 46L20 41L10 46Z M20 12V40 M34 17V45',
 'menu':'M15 17H39 M15 27H39 M15 37H39 M11 17H12 M11 27H12 M11 37H12',
 'hammer':'M13 19L23 9L39 21L29 31Z M28 29L14 46 M11 43L17 48',
 'workers':'M17 23A6 7 0 1 0 0-14A6 7 0 1 0 0 14 M37 23A6 7 0 1 0 0-14A6 7 0 1 0 0 14 M6 43V34Q17 25 27 34V43 M28 31Q37 26 47 34V43',
 'gift':'M11 25H43V44H11Z M9 18H45V26H9Z M27 18V44 M27 18Q10 18 16 10Q22 7 27 18Q32 7 38 10Q44 18 27 18',
 'crown':'M11 18L19 26L27 12L35 26L43 18L39 40H15Z M16 35H38',
 'forge':'M9 27H44L36 34H29V41H35V45H17V41H23V34H17Z M18 17H35 M21 12H32',
 'fire':'M27 8Q40 24 36 28Q43 24 43 32Q43 46 27 47Q10 46 12 32Q12 25 21 18Q20 30 27 30Q32 24 27 8Z',
 'ice':'M27 9V45 M11 18L43 36 M11 36L43 18 M22 13L27 18L32 13 M22 41L27 36L32 41',
 'bolt':'M31 8L14 30H25L21 47L41 23H29Z',
 'potion':'M22 10H32V21L39 34Q44 45 27 46Q10 45 15 34L22 21Z M19 32H35 M22 15H32',
 'dodge':'M9 27H36 M28 16L41 27L28 38 M9 19H19 M9 35H19',
 'hand':'M18 31V16Q21 13 23 17V29V11Q26 8 28 12V29V14Q31 11 33 15V30V20Q36 17 38 21V35L32 45H20L11 32Q10 26 15 29Z',
 'caravan':'M11 19H40V36H11Z M15 36A5 5 0 1 0 0 10A5 5 0 1 0 0-10 M36 36A5 5 0 1 0 0 10A5 5 0 1 0 0-10 M8 14H14',
}
for name,path in paths.items():
 color='#78b8e3' if name in ['ice','bolt','dodge'] else '#e6a15c' if name in ['fire','attack','potion'] else '#ded1a5'
 svg=f'''<svg xmlns="http://www.w3.org/2000/svg" width="56" height="56" viewBox="0 0 56 56"><defs><radialGradient id="b"><stop stop-color="#3c5154"/><stop offset="1" stop-color="#101817"/></radialGradient><linearGradient id="r" x2="0" y2="1"><stop stop-color="#e5d5a3"/><stop offset=".5" stop-color="#77765d"/><stop offset="1" stop-color="#b5a16b"/></linearGradient></defs><circle cx="28" cy="28" r="26" fill="url(#r)" stroke="#131b18"/><circle cx="28" cy="28" r="23" fill="url(#b)" stroke="#b9bb9e"/><path d="{path}" fill="none" stroke="#000" stroke-width="4" stroke-linejoin="round" transform="translate(1 1)"/><path d="{path}" fill="none" stroke="{color}" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"/></svg>'''
 (p/f'{name}.svg').write_text(svg,encoding='utf8')
print(f'{len(paths)} original vector controls generated')
