#!/usr/bin/env python3
"""One controlled paper-panel recovery; retains C21 logic and original sources."""
from __future__ import annotations
import argparse, hashlib, json, shutil
from pathlib import Path
from PIL import Image, ImageEnhance, ImageFilter, ImageChops

PREFIX='res://components/control_atlas/'
def sha(p:Path)->str:return hashlib.sha256(p.read_bytes()).hexdigest()
def protected(root:Path)->dict[str,str]:
    files=[p for p in (root/'art').glob('*.png') if p.name.startswith(('control_','passive_meter_'))]
    files += [p for p in (root/'bandmaster_premium_dashboard_poc').rglob('*') if p.is_file() and p.suffix not in ['.uid','.import']]
    return {str(p.relative_to(root)):sha(p) for p in files}
def main()->None:
    ap=argparse.ArgumentParser();ap.add_argument('--source',type=Path,required=True);ap.add_argument('--out',type=Path,required=True)
    ap.add_argument('--cork',type=Path,required=True);ap.add_argument('--cork-manifest',type=Path,required=True)
    a=ap.parse_args();assert a.source.resolve()!=a.out.resolve()
    if a.out.exists():shutil.rmtree(a.out)
    shutil.copytree(a.source,a.out,ignore=shutil.ignore_patterns('.godot','proof','*.import','*.uid','*.ttf','*.otf'))
    # Exactly the published module resource prefix is rebased; no control logic changes.
    for p in a.out.rglob('*'):
        if p.suffix in ['.gd','.tscn']:p.write_text(p.read_text().replace(PREFIX,'res://'))
    (a.out/'project.godot').write_text('config_version=5\n[application]\nconfig/name="BandMaster C22 frame recovery"\nrun/main_scene="res://gallery.tscn"\n[display]\nwindow/size/viewport_width=1280\nwindow/size/viewport_height=720\n[rendering]\nrenderer/rendering_method="gl_compatibility"\n')
    before=protected(a.out);art=a.out/'art';parent=art/'frame_notepaper_previous.png'
    src=Image.open(parent).convert('RGBA');W,H=src.size
    assert (W,H)==(512,384),'Unexpected retained paper master'
    photo=json.loads(a.cork_manifest.read_text())
    source_record=next(x for x in photo['records'] if x['asset'].endswith('corkboard_day_pexels.webp'))
    assert sha(a.cork)==source_record['committed_webp_sha256'],'Cork source checksum mismatch'
    sheet=src.copy();pixels=sheet.load();texture=Image.open(art/'paper_surface.png').convert('RGBA');tex=texture.load()
    # Preserve the inherited irregular sheet boundary and offset leaf. Calm only the
    # printed double-rule inside it; this is not a replacement drawn paper silhouette.
    for y in range(H):
        for x in range(W):
            r,g,b,alpha=pixels[x,y]
            if r<40 and g<40 and b<40 and alpha<255:
                pixels[x,y]=(r,g,b,round(alpha*.56))
            elif 27<=x<W-27 and 26<=y<H-27 and (r<180 or alpha<245):
                R,G,B,_=tex[x%texture.width,y%texture.height]
                pixels[x,y]=(round(R*.88+r*.12),round(G*.88+g*.12),round(B*.88+b*.12),255)
    # Retained source silhouette defines the mount; no new geometric frame outline.
    silhouette=src.getchannel('A').point(lambda v:255 if v>=245 else 0)
    fill=Image.new('L',(W,H));fill.paste(255,(25,25,W-25,H-25))
    silhouette=ImageChops.lighter(silhouette,fill)
    board_mask=silhouette.filter(ImageFilter.MaxFilter(17))
    cork=Image.open(a.cork).convert('RGB').resize((W,H),Image.Resampling.LANCZOS)
    cork=ImageEnhance.Color(cork).enhance(.72)
    cork=ImageEnhance.Contrast(cork).enhance(.82).convert('RGBA');cork.putalpha(board_mask)
    shadow=Image.new('RGBA',(W,H),(38,29,18,0));shadow.putalpha(board_mask.point(lambda v:round(v*.20)).filter(ImageFilter.GaussianBlur(1.5)))
    candidate=Image.new('RGBA',(W,H));candidate.alpha_composite(shadow,(0,2));candidate.alpha_composite(cork)
    # Existing source edge and leaf contain the contact-depth detail.
    candidate.alpha_composite(sheet)
    target=art/'frame_notepaper_panel_c22.png';candidate.save(target)
    spec_path=a.out/'FRAME_STYLES_C21.json';spec=json.loads(spec_path.read_text())
    original=next(r.copy() for r in spec['frames'] if r['look']=='notepaper' and r['preset']=='panel')
    row=next(r for r in spec['frames'] if r['look']=='notepaper' and r['preset']=='panel')
    row.update({'file':'art/'+target.name,'size':[W,H],'nine_slice':[44,44,44,44],
       'content_insets':[40,40,40,40],'minimum_size':[160,144],'sha256':sha(target),'owner_approved':False,
       'status':'candidate_native_review_required','source_method':'Retained irregular C20 sheet edges and leaf; subdued printed rules/shadow; inherited photographed cork mount'})
    spec['c22_panel_candidate']=True;spec_path.write_text(json.dumps(spec,indent=2)+'\n')
    record={'schema_version':1,'owner_approved':False,'status':'candidate_not_final_art',
      'target_original_sha256':'5d24ec44eada22c353fc4403cfd237c4d005062743c42d173aefa4108d45f5f8',
      'target_type':'Conversation design-only frame atlas; never used as production pixels',
      'source_type':'Digital compositing of retained C20 source paper and existing Pexels cork; not new photography or image generation',
      'paper_rights':'Inherited C20 MATERIAL_MANIFEST / CC0 paper source basis; not a newly asserted paper scan',
      'source_paths_sha256':{'art/frame_notepaper_previous.png':sha(parent),'art/paper_surface.png':sha(art/'paper_surface.png'),
        'Art/Photography/Formation/corkboard_day_pexels.webp':sha(a.cork)},
      'cork_rights_record':source_record,'output':row,'prior_profile':original,'protected_originals':before,
      'construction':'Only representative panel. Preserved irregular source boundary and offset leaf. Reduced old cast-shadow alpha to56%; softened interior printed rules with the same paper material. Cork mount silhouette derives from existing sheet. No triangles/tape/fake clip drawn; no source enlargement.',
      'comparison':'C20, C21 and C22 use identical native content/bounds/background/state at four sizes; tested separately from mockup fidelity.'}
    (a.out/'FRAME_RECOVERY_C22.json').write_text(json.dumps(record,indent=2)+'\n')
    manifest=json.loads((a.out/'MANIFEST.json').read_text());manifest['c22_recovery']=record
    manifest['c21_frame_styles']=spec;(a.out/'MANIFEST.json').write_text(json.dumps(manifest,indent=2)+'\n')
    assert protected(a.out)==before,'Protected source/logic changed'
    prov=a.out/'provenance';prov.mkdir(exist_ok=True);shutil.copy2(a.cork_manifest,prov/'C22_EXISTING_PHOTO_MANIFEST.json')
    (a.out/'proof').mkdir(exist_ok=True)
    print('C22 representative panel candidate built; protected original files:',len(before))
if __name__=='__main__':main()
