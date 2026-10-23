"""Export the development milestone, preserving older APKs and exact package preset bytes."""
from pathlib import Path
import os,subprocess,argparse
root=Path(__file__).resolve().parents[1]
parser=argparse.ArgumentParser();parser.add_argument('--qa',action='store_true');parser.add_argument('--milestone',choices=['C','D-critical','E1','E2B'],default='C');args=parser.parse_args()
preset=root/'export_presets.cfg';original=preset.read_bytes()
env=os.environ.copy();env['JAVA_HOME']=str(root/'tools/jdk/jdk-17.0.20.1+1')
try:
    if args.qa:preset.write_bytes(original.replace(b'org.littlegod.livinguniverse"',b'org.littlegod.livinguniverse.betaqa"'))
    dest=root/('builds/android/LittleGod-0.8.5-milestone-'+args.milestone+('-qa' if args.qa else '')+'-debug.apk')
    subprocess.run([str(root/'tools/godot/Godot_v4.7.2-stable_win64_console.exe'),'--headless','--path',str(root),'--export-debug','Android',str(dest)],env=env,check=True)
finally:preset.write_bytes(original)
