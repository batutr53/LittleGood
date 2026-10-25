"""Retain only evidence actually produced by the verification tools."""
from pathlib import Path
import json
r=Path(__file__).resolve().parents[1];out=r/'docs/benchmarks/rpg';out.mkdir(parents=True,exist_ok=True)
def checks(path,prefix):
    line=next(line for line in (r/path).read_text(encoding='utf8').splitlines() if line.startswith(prefix))
    return json.loads(line[len(prefix):])
progression=checks('builds/rpg-progression-final.log','RPG_CHECKS ')
combat=checks('builds/rpg-combat-final.log','RPG_COMBAT_CHECKS ')
interactions=checks('builds/rpg-interactions-final.log','RPG_UI_INTERACTIONS ')
ui=json.loads((r/'builds/ui-rebirth/rendered.json').read_text())
baseline=json.loads((r/'builds/phase085e3/verification.json').read_text())
android=json.loads((r/'builds/rpg-android/result.json').read_text())
apk=json.loads((r/'builds/rpg-apk.json').read_text())
research=json.loads((r/'docs/research/item-detail-audit.json').read_text(encoding='utf8'))
result={'date':'2026-10-25','milestone_complete':False,'retained':baseline,'progression':progression,'class_combat':combat,'ui_interactions':interactions,'ui_check_count':len(ui['checks']),'ui_all_passed':ui['all_passed'],'android':android,'apk':apk,'research':research['detail_audit'],'online_live_verified':False,'online_blocker':'Windows App Control 0x800711C7 prevents loading built API DLL','directional_equipment_animation_complete':False}
(out/'verification.json').write_text(json.dumps(result,ensure_ascii=False,indent=2),encoding='utf8')
assert all(progression.values()) and all(combat.values()) and all(interactions.values()) and ui['all_passed'] and baseline['all_passed'] and android['all_passed'] and android['player_files_preserved']
print('Evidence saved: '+str(out/'verification.json'))
