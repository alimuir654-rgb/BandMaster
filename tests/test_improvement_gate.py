"""Positive and negative tests for record enforcement; not aesthetic tests."""
from __future__ import annotations
import importlib.util
import json
import subprocess
import tempfile
import unittest
from pathlib import Path
spec=importlib.util.spec_from_file_location('gate',Path(__file__).parents[1]/'tools/improvement_gate.py')
gate=importlib.util.module_from_spec(spec);spec.loader.exec_module(gate)

class ImprovementGateTests(unittest.TestCase):
    def setUp(self):
        self.temp=tempfile.TemporaryDirectory();self.addCleanup(self.temp.cleanup)
        self.root=Path(self.temp.name);self.docs=self.root/gate.DOCS;self.docs.mkdir(parents=True)
        for name in gate.REQUIRED_DOCS: (self.root/name).write_text('Reviewed policy\n')
        event={'event':'lesson_recorded','id':'BM-03','observation':'Known paper regression'}
        (self.docs/'ISSUES.jsonl').write_text(json.dumps(event)+'\n')
        raw=(self.docs/'ISSUES.jsonl').read_bytes()
        self.session={'schema_version':1,'id':'TEST','status':'active','owner_approved':False,
          'owner_request':'Scoped test','baseline_sha':'a'*40,'dominant_issue':'BM-03',
          'hypothesis':'Preserve depth','stop_condition':'Hold if flatter',
          'reviewed_documents':{p:gate.digest((self.root/p).read_bytes()) for p in gate.REQUIRED_DOCS},
          'issue_log_review':{'bytes':len(raw),'sha256':gate.digest(raw)},'lesson_ids':['BM-03'],
          'target':{'original_sha256':'b'*64,'locator':'test fixture only','pixels_inspected':True},
          'controlled_comparison':'Same size/content/background/state','allowed_paths':['docs/**','art/paper.png'],
          'validation_commands':['unittest']}
        self.rel=gate.DOCS+'/session.json';self.save()
    def save(self): (self.root/self.rel).write_text(json.dumps(self.session))
    def check(self,**kw):self.save();return gate.check(self.root,self.rel,**kw)
    def test_valid_preflight(self):self.assertEqual(self.check()['record_gate'],'pass')
    def test_stale_policy(self):
        (self.root/gate.REQUIRED_DOCS[0]).write_text('changed')
        with self.assertRaisesRegex(gate.GateError,'Stale'):self.check()
    def test_missing_policy(self):
        (self.root/gate.REQUIRED_DOCS[1]).unlink()
        with self.assertRaisesRegex(gate.GateError,'Missing required'):self.check()
    def test_no_approval_inference(self):
        self.session['owner_approved']=True
        with self.assertRaises(gate.GateError):self.check()
    def test_unreviewed_event_blocks_continue(self):
        with (self.docs/'ISSUES.jsonl').open('a') as f:f.write(json.dumps({'event':'recurrence','event_id':'r1','id':'BM-03','observation':'again'})+'\n')
        with self.assertRaisesRegex(gate.GateError,'New issue'):self.check()
    def test_history_rewrite(self):
        p=self.docs/'ISSUES.jsonl';p.write_text(p.read_text().replace('Known','KNOWN'))
        with self.assertRaisesRegex(gate.GateError,'rewritten'):self.check()
    def test_partial_event_prefix(self):
        self.session['issue_log_review']['bytes']-=1
        with self.assertRaisesRegex(gate.GateError,'inside an event'):self.check()
    def test_duplicate_event(self):
        p=self.docs/'ISSUES.jsonl';p.write_text(p.read_text()*2)
        with self.assertRaisesRegex(gate.GateError,'Duplicate'):self.check()
    def test_malformed_json(self):
        (self.docs/'ISSUES.jsonl').write_text('{invalid}\n')
        with self.assertRaisesRegex(gate.GateError,'Invalid issue'):self.check()
    def test_missing_dominant_issue(self):
        self.session['dominant_issue']='BM-99'
        with self.assertRaises(gate.GateError):self.check()
    def test_unknown_lesson(self):
        self.session['lesson_ids']=['BM-99']
        with self.assertRaises(gate.GateError):self.check()
    def test_missing_target(self):
        self.session['target']['pixels_inspected']=False
        with self.assertRaises(gate.GateError):self.check()
    def test_invalid_target_hash(self):
        self.session['target']['original_sha256']='unknown'
        with self.assertRaises(gate.GateError):self.check()
    def test_missing_ab_contract(self):
        self.session['controlled_comparison']=''
        with self.assertRaises(gate.GateError):self.check()
    def test_unbounded_scope(self):
        self.session['allowed_paths']=['**']
        with self.assertRaises(gate.GateError):self.check()
    def test_traversal_scope(self):
        self.session['allowed_paths']=['../outside']
        with self.assertRaises(gate.GateError):self.check()
    def test_absolute_path(self):
        with self.assertRaises(gate.GateError):gate.safe_path(self.root,'/tmp/bad')
    def test_symlink_escape(self):
        (self.root/'escape').symlink_to(self.root.parent)
        with self.assertRaises(gate.GateError):gate.safe_path(self.root,'escape/outside')
    def test_closed_without_evidence(self):
        self.session['status']='closed'
        with self.assertRaisesRegex(gate.GateError,'Closeout'):self.check()
    def test_valid_closed(self):
        self.session['status']='closed';self.session['closeout']={'tested_sha':'c'*40,'evidence':['fixture'],
           'visual_verdict':'hold','next_action':'Review target','new_issue_review':'No additional failures'}
        self.assertEqual(self.check()['status'],'closed')
    def test_append_event(self):
        event={'event_id':'r1','id':'BM-03','event':'recurrence','observation':'Flatter','expected':'Depth',
           'evidence':['test fixture'],'severity':'P0','cause_confidence':'observed','prevention':'A/B',
           'verification':'Native comparison','recorded_at':'2026-10-29','owner_role':'art','affected_paths':['art/paper.png'],'next_action':'Restore'}
        p=self.root/'event.json';p.write_text(json.dumps(event));old=(self.docs/'ISSUES.jsonl').read_bytes()
        gate.append_event(self.root,p);self.assertTrue((self.docs/'ISSUES.jsonl').read_bytes().startswith(old))
        with self.assertRaisesRegex(gate.GateError,'Duplicate'):gate.append_event(self.root,p)
    def git(self,*args):
        return subprocess.check_output(['git','-C',str(self.root),*args],stderr=subprocess.DEVNULL,text=True).strip()
    def setup_git(self):
        self.git('init');self.git('config','user.email','test@example.invalid');self.git('config','user.name','Test')
        self.git('add','.');self.git('commit','-m','committed preflight');return self.git('rev-parse','HEAD')
    def test_prior_commit_required_and_scoped_diff(self):
        before=self.setup_git();(self.root/'art').mkdir();(self.root/'art/paper.png').write_bytes(b'fixture')
        self.git('add','.');self.git('commit','-m','scoped change')
        self.assertEqual(self.check(before=before,require_prior_record=True)['record_gate'],'pass')
    def test_unscoped_commit(self):
        before=self.setup_git();(self.root/'production.gd').write_text('bad scope')
        self.git('add','.');self.git('commit','-m','unscoped')
        with self.assertRaisesRegex(gate.GateError,'Unscoped'):self.check(before=before)
    def test_closed_prior_record_cannot_authorise_new_implementation(self):
        self.session['status']='closed';self.session['closeout']={'tested_sha':'c'*40,'evidence':['fixture'],
           'visual_verdict':'hold','next_action':'Review target','new_issue_review':'None'};self.save();before=self.setup_git()
        self.session['status']='active';self.save();self.git('add','.');self.git('commit','-m','not new authority')
        with self.assertRaisesRegex(gate.GateError,'already committed active'):self.check(before=before,require_prior_record=True)
if __name__=='__main__':unittest.main()
