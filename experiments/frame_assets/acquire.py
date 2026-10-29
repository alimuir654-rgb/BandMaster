"""Acquire exactly two CC0 source models; no catalogue renders or runtime downloads."""
from pathlib import Path, PurePosixPath
from urllib.request import Request, urlopen
from urllib.parse import urlparse
import hashlib, json, time
ROOT=Path('c24-sources');ROOT.mkdir(exist_ok=True)
HEADERS={'User-Agent':'BandMaster-CC0-Frame-Proof/1.0 (offline art evaluation; github.com/alimuir654-rgb/BandMaster)'}
def get(url):
    for attempt in range(3):
        try:
            with urlopen(Request(url,headers=HEADERS),timeout=45) as r:return r.read()
        except Exception:
            if attempt==2:raise
            time.sleep(2)
def candidates(obj,path=()):
    if not isinstance(obj,dict):return
    if 'url' in obj and str(obj['url']).split('?')[0].endswith('.gltf'):yield path,obj
    for k,v in obj.items():
        if k!='include':yield from candidates(v,path+(k,))
manifest={'source_type':'Original Poly Haven CC0 glTF models and dependent textures; NOT website preview renders','license':'CC0-1.0','license_url':'https://polyhaven.com/license','owner_approved':False,'assets':[]}
for name in ['clipboard','office_notepads']:
    folder=ROOT/name;folder.mkdir(exist_ok=True)
    raw=get('https://api.polyhaven.com/files/'+name);(folder/'files-api.json').write_bytes(raw)
    data=json.loads(raw);opts=list(candidates(data));assert opts,(name,list(data))
    path,model=next(((p,v) for p,v in opts if '2k' in p),opts[0])
    records=[]
    def download(entry,relative):
        p=PurePosixPath(relative);assert not p.is_absolute() and '..' not in p.parts
        dest=folder/p;dest.parent.mkdir(parents=True,exist_ok=True)
        content=get(entry['url']);dest.write_bytes(content)
        if entry.get('md5'):assert hashlib.md5(content).hexdigest()==entry['md5']
        records.append({'path':str(p),'url':entry['url'],'bytes':len(content),'sha256':hashlib.sha256(content).hexdigest()})
    filename=Path(urlparse(model['url']).path).name;download(model,filename)
    for relative,entry in model.get('include',{}).items():download(entry,relative)
    gltf=json.loads((folder/filename).read_text())
    for entry in gltf.get('buffers',[])+gltf.get('images',[]):
        uri=entry.get('uri','')
        if uri and not uri.startswith('data:'):assert (folder/uri).is_file(),(name,'missing',uri)
    manifest['assets'].append({'id':name,'page':'https://polyhaven.com/a/'+name,'format_path':path,'model':str(folder/filename),'files':records})
(ROOT/'SOURCE_MANIFEST.json').write_text(json.dumps(manifest,indent=2)+'\n')
print(json.dumps(manifest,indent=2))
