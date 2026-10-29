"""Verify native evidence, then package the isolated candidate without fonts/caches."""
from pathlib import Path
from PIL import Image
import hashlib,json,zipfile
def sha(p):return hashlib.sha256(Path(p).read_bytes()).hexdigest()
root=Path('frame-proof-c24');host=Path('host-proof-c24/components/control_atlas')
summary={'owner_approved':False,'projects':[]}
for project in [root,host]:
    checks=[]
    for name,count in [('results.json',48),('frame-results.json',16),('stress-results.json',8),('dossier-results.json',12)]:
        p=project/'proof'/name;r=json.loads(p.read_text());assert not r['failures'] and len(r['screenshots'])==count
        for item in r['screenshots']:
            image=project/'proof'/item['file']
            with Image.open(image) as im:assert list(im.size)==item['size'];im.verify()
            item['sha256']=sha(image)
        p.write_text(json.dumps(r,indent=2)+'\n');checks.append({'suite':name,'assertions':r['assertions'],'captures':count,'failures':0})
    summary['projects'].append({'path':str(project),'suites':checks})
m=json.loads((root/'C24_DOSSIER_MANIFEST.json').read_text())
for path,digest in m['protected_originals'].items():assert sha(root/path)==digest,path
summary['protected_existing_files']=len(m['protected_originals'])
(root/'proof/VERIFICATION_SUMMARY.json').write_text(json.dumps(summary,indent=2)+'\n')
with zipfile.ZipFile('BandMaster_C24_Testable_Dossier.zip','w',zipfile.ZIP_DEFLATED) as z:
    for p in root.rglob('*'):
        if p.is_file() and not any(x in p.parts for x in ['.godot','proof','__pycache__']) and p.suffix not in ['.ttf','.otf','.import','.uid']:
            z.write(p,Path('BandMaster_C24_Dossier')/p.relative_to(root))
with zipfile.ZipFile('BandMaster_C24_Dossier_Layers.zip','w',zipfile.ZIP_DEFLATED) as z:
    for p in (root/'art/c24').glob('*.png'):z.write(p,Path('art')/p.name)
    for name in ['C24_DOSSIER_MANIFEST.json','C24_README.md','dossier_frame.gd']:z.write(root/name,name)
print(json.dumps(summary,indent=2))
