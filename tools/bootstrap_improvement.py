#!/usr/bin/env python3
"""One-time C22 adoption. Never replaces an existing issue history or session."""
from __future__ import annotations
from datetime import datetime, timezone
import json
from pathlib import Path
import re
from improvement_gate import DOCS, REQUIRED_DOCS, check, digest, ensure

def write_json(path: Path, value: dict) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(json.dumps(value, indent=2, ensure_ascii=False)+'\n')

def main() -> None:
    root=Path.cwd(); docs=root/DOCS; now=datetime.now(timezone.utc).isoformat()
    lock=json.loads((root/'docs/asset_base/CONTROL_SPRINT_LOCK.json').read_text())
    ensure(lock.get('writer')=='C22-lessons-and-frame-recovery','Wrong writer')
    state_path=root/'docs/asset_base/STATE.json'; state=json.loads(state_path.read_text())
    ensure(state.get('writer') is None,'Another writer owns STATE')
    log=docs/'ISSUES.jsonl'; session_path=docs/'sessions/C22.json'
    ensure(not log.exists() and not session_path.exists(),'Adoption already performed; never reset history')
    text=(docs/'LESSONS.md').read_text()
    parts=re.split(r'^### (BM-\d+)\s*$',text,flags=re.M)
    events=[]
    for index in range(1,len(parts),2):
        identifier,body=parts[index:index+2]
        def section(start: str,end: str) -> str:
            return body.split(start,1)[1].split(end,1)[0].strip()
        observed=section('**What went wrong:**','**Prevent:**')
        prevention=section('**Prevent:**','**Proof:**')
        proof=body.split('**Proof:**',1)[1].split('\n\n',1)[0].strip()
        events.append({'event_id':'C22-history-'+identifier,'id':identifier,'event':'lesson_recorded',
          'recorded_at':now,'observation':observed,'expected':prevention,'prevention':prevention,
          'verification':proof,'evidence':'LESSONS.md#'+identifier.lower()+'; SOURCE_AUDIT.md resolves source keys',
          'severity':'P0' if identifier in ['BM-01','BM-02','BM-03','BM-35','BM-41'] else 'P1',
          'cause_confidence':'observed','owner_role':'engineering/art/controller per lesson category',
          'status':'historical_lesson_prevention_mandatory_not_claimed_newly_reproduced'})
    ensure(len(events)==46,'Unexpected lesson count')
    events.append({'event_id':'C22-owner-rejects-C21-paper','id':'BM-03','event':'recurrence',
      'recorded_at':now,'observation':'Owner reports C21 notepaper worse than C20. Source inspection confirms schematic reconstruction replaced inherited edges; prior internal cleaner verdict is superseded.',
      'expected':'Mockup-level tactile paper/cork material; preserve best existing edges and C21 functional hardening.',
      'evidence':['OWNER_FEEDBACK.md','SOURCE_AUDIT.md','experiments/frame_hardening/base_frames.py','experiments/frame_hardening/refine_paper.py'],
      'severity':'P0','cause_confidence':'observed','owner_role':'art direction and QA',
      'affected_paths':['components/control_atlas/art/frame_notepaper_*_c21.png'],
      'prevention':'Controlled target/C20/C21/candidate comparison before expanding any frame family.',
      'verification':'Actual native same-content/bounds/state captures plus protected-source regression checks.',
      'next_action':'Only after this log is committed, create one source-preserving representative panel pilot; hold if still below target.',
      'status':'open_visual_regression'})
    log.write_text(''.join(json.dumps(e,ensure_ascii=False,separators=(',',':'))+'\n' for e in events))
    raw=log.read_bytes()
    session={'schema_version':1,'id':'C22','status':'active','owner_approved':False,
      'owner_request':'Consolidate all recorded lessons and require checks/logging before future work, then restart framing; the goal is the mockups.',
      'baseline_sha':'ca73c433fadc37135e7b69ee6e222e82c5a5340d','visual_recovery_baseline':'C20; not final-art approval',
      'dominant_issue':'BM-03','lesson_ids':['BM-%02d'%i for i in range(1,47)],
      'reviewed_documents':{p:digest((root/p).read_bytes()) for p in REQUIRED_DOCS},
      'issue_log_review':{'bytes':len(raw),'sha256':digest(raw)},
      'target':{'locator':'Conversation original bandmaster_ui_frame_atlas.png (1672x941), design only; source index in SOURCE_AUDIT.md',
                'original_sha256':'5d24ec44eada22c353fc4403cfd237c4d005062743c42d173aefa4108d45f5f8','pixels_inspected':True},
      'hypothesis':'Recover convincing paper edges/depth from retained C20 source and appropriate source-backed mounting, instead of replacing construction with drawn rectangles. Keep C21 dialog hardening.',
      'controlled_comparison':'Same content, font, bounds, state, background and viewport for C20, rejected C21 and candidate panel. Reference mockup shown separately as target. Four viewport native captures; no screenshot-as-source.',
      'stop_condition':'One corrective continuation at most; if no obvious improvement toward target, retain C20 recovery baseline and mark candidate HOLD. Do not generate a new family to hide failure.',
      'protected':['22 passive meter state PNGs','36 action/tab/browse PNGs','58 Lab08 image layers and hardware logic','C21 dialog lifecycle','production saves and scenes'],
      'allowed_paths':['docs/continuous_improvement/**','docs/asset_base/STATE.json','docs/asset_base/LEDGER.md','docs/asset_base/CONTROL_SPRINT_LOCK.json','docs/asset_base/PROGRAMME_2026-10-29.md','docs/asset_base/REVIEW_INDEX.md','AGENTS.md','.agents/asset_base/WORKSTREAMS.md','.github/PULL_REQUEST_TEMPLATE.md','.github/workflows/continuous-improvement.yml','.github/workflows/frame-recovery-proof.yml','experiments/frame_recovery/**','components/control_atlas/**','tools/improvement_gate.py','tests/test_improvement_gate.py'],
      'validation_commands':['python3 -m unittest discover -s tests -p test_improvement_gate.py -v','python3 tools/improvement_gate.py check --session docs/continuous_improvement/sessions/C22.json','Existing C20/C21 native suites in Godot 4.7.2, standalone and host','Controlled frame comparison at 390x844,720x1280,1280x720,1600x900; inspect original PNGs']}
    write_json(session_path,session)
    write_json(docs/'CURRENT.json',{'schema_version':1,'session':'docs/continuous_improvement/sessions/C22.json','scope':'Lessons gate then source-preserving frame recovery','owner_approved':False,'target':'mockups','backgrounds':'deferred','characters':'deferred','meters':'protected'})
    state['latest_owner_scope']='C22: mandatory continuous-improvement checks/log FIRST, then frame recovery against mockups; no background/character work'
    state['next_single_action']='Execute committed C22 preflight; recover one representative paper panel using retained source construction and controlled native comparison.'
    state['continuous_improvement']={'entrypoint':DOCS+'/CHECK_BEFORE_WORK.md','lessons':DOCS+'/LESSONS.md','issues':DOCS+'/ISSUES.jsonl','session':DOCS+'/sessions/C22.json','owner_approved':False}
    state['c21_owner_visual_rejection']={'notepaper':'worse than before per direct owner feedback','technical_hardening':'retain','art_acceptance':'rejected','reference':'docs/continuous_improvement/OWNER_FEEDBACK.md'}
    state['owner_approved']=False; write_json(state_path,state)
    ledger=root/'docs/asset_base/LEDGER.md'
    with ledger.open('a') as stream:
        stream.write('\n\n## C22 continuous-improvement consolidation — BEFORE frame implementation\n125 tracked Markdown source records / 87 unique versions surveyed across current, main and recruitment refs, plus available 23–29 October conversation. 46 known failure/prevention entries now canonical. C21 notepaper rejection appended; older internal visual verdict is superseded, technical hardening retained. Root AGENTS and specialist instructions route all future work through current policy hashes, append-only issue log and scoped preflight. The automated gate validates records, not artistic quality or human reading; main/PR199 untouched. Local 24 positive/negative tests are repeated in adoption CI. No new framing implementation has been performed before this publication.\n')
    programme=root/'docs/asset_base/PROGRAMME_2026-10-29.md'
    original=programme.read_text()
    programme.write_text('# CURRENT ROUTING — C22 CONTINUOUS IMPROVEMENT\n\nRead AGENTS.md and docs/continuous_improvement/CHECK_BEFORE_WORK.md first. The historical timed programme below is closed. Latest direct owner scope is lessons consolidation then frame recovery against the mockups; backgrounds/characters remain deferred, meters protected. C21 paper was rejected by the owner. Do not execute the old portrait-first queue.\n\n---\n\n'+original)
    (root/'docs/asset_base/REVIEW_INDEX.md').write_text('# Current review routing\n\nRead docs/continuous_improvement/README.md and CURRENT.json. C21 notepaper visual verdict is superseded by owner rejection; engineering hardening remains valid. C22 first commits the consolidated lessons/log/checks, then records any frame-recovery evidence separately. No final owner artwork approval.\n')
    print(json.dumps(check(root,str(session_path.relative_to(root))),indent=2))
if __name__=='__main__':main()
