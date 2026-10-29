"""F02: reusable source-backed frame/mount assets and narrow/tablet composition.

Runs after prepare_art + refine_art + build_passive_meter_kit.
No portraits, UI composites or invented room/character photography.
"""
from pathlib import Path
from PIL import Image, ImageDraw, ImageEnhance, ImageFilter, ImageOps
import os, json, hashlib

root=Path(os.environ['ROOT']); src=Path('art-sources'); out=root/'assets/material'
out.mkdir(parents=True,exist_ok=True)
lab=src/'bandmaster_premium_controls_lab/assets/channel_studio_idle.png'
cork=src/'Art/Photography/Formation/corkboard_day_pexels.webp'
assert hashlib.sha256(lab.read_bytes()).hexdigest()=='ac1999c27afcedffee97e1460b2f3ca5e2ec8829259f83885f73a48712dda229'
assert lab.is_file() and cork.is_file()
paper=Image.open(out/'paper_surface.png').convert('RGB')
metal=Image.open(out/'flightcase_frame.png').convert('RGB')
case=Image.open(out/'case_surface.png').convert('RGB')
records=[]
source_sha={str(p.relative_to(src)):hashlib.sha256(p.read_bytes()).hexdigest() for p in (lab,cork)}
source_sha['assets/material/paper_surface.png']=hashlib.sha256((out/'paper_surface.png').read_bytes()).hexdigest()
source_sha['assets/material/flightcase_frame.png']=hashlib.sha256((out/'flightcase_frame.png').read_bytes()).hexdigest()

def save(im,name,theme,role,margin,source):
    p=out/name;im.save(p,optimize=True)
    records.append({'path':str(p.relative_to(root)), 'sha256':hashlib.sha256(p.read_bytes()).hexdigest(),
         'dimensions':list(im.size),'mode':im.mode,'theme':theme,'role':role,'source':source,
         'nine_slice_source_px':margin,'safe_content_inset_px':[18,18,18,18],
         'interactive':False,'owner_approved':False})

def nine(src_im,size,m):
    # Nine segments: corners preserve original screws; edges stretch in one axis only.
    a=src_im.convert('RGBA');w,h=a.size; tw,th=size
    l,t,r,b=m
    res=Image.new('RGBA',size,(0,0,0,0))
    parts=[((0,0,l,t),(0,0,l,t)),((w-r,0,w,t),(tw-r,0,tw,t)),
      ((0,h-b,l,h),(0,th-b,l,th)),((w-r,h-b,w,h),(tw-r,th-b,tw,th)),
      ((l,0,w-r,t),(l,0,tw-r,t)),((l,h-b,w-r,h),(l,th-b,tw-r,th)),
      ((0,t,l,h-b),(0,t,l,th-b)),((w-r,t,w,h-b),(tw-r,t,tw,th-b)),
      ((l,t,w-r,h-b),(l,t,tw-r,th-b))]
    for (x0,y0,x1,y1),(dx0,dy0,dx1,dy1) in parts:
        im=a.crop((x0,y0,x1,y1)).resize((dx1-dx0,dy1-dy0),Image.Resampling.LANCZOS)
        res.alpha_composite(im,(dx0,dy0))
    return res

# A source-backed self-contained flight-case photo bezel, not the screen backdrop.
frame=nine(metal,(512,384),(42,42,42,42))
shadow=Image.new('RGBA',(512,384),(0,0,0,0)); d=ImageDraw.Draw(shadow)
d.rounded_rectangle((39,39,472,343),radius=10,fill=(5,8,12,255),outline=(105,100,91,210),width=3)
frame.alpha_composite(shadow)
border=nine(metal,(512,384),(42,42,42,42))
mask=Image.new('L',(512,384));dr=ImageDraw.Draw(mask)
dr.rectangle((0,0,512,42),fill=255);dr.rectangle((0,342,512,384),fill=255)
dr.rectangle((0,0,42,384),fill=255);dr.rectangle((470,0,512,384),fill=255)
frame=Image.composite(border,frame,mask)
save(frame,'portrait_mount_flightcase.png','flightcase','portrait bezel',{'left':42,'top':42,'right':42,'bottom':42},'owner Lab07 image-generated metal frame')

# Paper photo mount, sourced from scanned paper, with an offset leaf and contact shadow.
sheet=Image.new('RGBA',(512,384),(0,0,0,0))
shadow=Image.new('RGBA',(512,384),(0,0,0,0));shd=ImageDraw.Draw(shadow)
shd.rounded_rectangle((18,18,501,374),radius=6,fill=(17,13,9,130))
sheet.alpha_composite(shadow.filter(ImageFilter.GaussianBlur(10)))
under=ImageOps.colorize(ImageOps.grayscale(paper),'#a89d88','#e3d7c0').resize((475,336),Image.Resampling.LANCZOS).convert('RGBA')
sheet.alpha_composite(under,(21,26))
card=ImageEnhance.Contrast(paper).enhance(.88).resize((474,344),Image.Resampling.LANCZOS).convert('RGBA')
cardmask=Image.new('L',card.size);md=ImageDraw.Draw(cardmask)
md.polygon([(2,2),(110,0),(230,2),(357,0),(471,3),(473,93),(471,210),(473,339),(358,341),(235,343),(107,341),(0,342),(2,235),(0,119)],fill=255)
card.putalpha(cardmask);sheet.alpha_composite(card,(16,16))
ink=ImageDraw.Draw(sheet)
ink.rounded_rectangle((29,27,483,350),radius=3,outline=(120,107,83,130),width=2)
ink.rounded_rectangle((36,34,477,339),radius=2,outline=(68,60,51,95),width=2)
save(sheet,'portrait_mount_notepaper.png','notepaper','paper photo contact mount',{'left':36,'top':36,'right':36,'bottom':45},'ambientCG Paper001 CC0 paper texture')

# Separate dossier inserts for tablet personnel notes, not flattened screens.
for kind in ('flightcase','notepaper'):
    W,H=640,300
    if kind=='flightcase':
        im=nine(metal,(W,H),(42,42,42,42))
        center=ImageEnhance.Brightness(case).enhance(.92).resize((W-82,H-78),Image.Resampling.LANCZOS).convert('RGBA')
        im.alpha_composite(center,(41,39))
        edge=ImageDraw.Draw(im);edge.rounded_rectangle((39,35,W-39,H-35),radius=9,outline=(113,113,112,160),width=2)
        origin='owner Lab07 image-generated metal plate + sourced case surface'
    else:
        im=Image.new('RGBA',(W,H),(0,0,0,0))
        d=ImageDraw.Draw(im);d.rounded_rectangle((12,14,W-8,H-6),radius=5,fill=(27,21,13,130))
        im=im.filter(ImageFilter.GaussianBlur(4))
        tile=paper.resize((W-35,H-34),Image.Resampling.LANCZOS).convert('RGBA')
        im.alpha_composite(tile,(14,12))
        dd=ImageDraw.Draw(im);dd.rectangle((18,16,W-25,H-26),outline=(168,151,123,120),width=2)
        origin='ambientCG Paper001 CC0 paper insert'
    save(im,'dossier_sheet_'+kind+'.png',kind,'material backing for tablet personnel notes',
         {'left':42,'top':42,'right':42,'bottom':42},origin)

atlas=Image.new('RGB',(1100,920),'#373d3e');dr=ImageDraw.Draw(atlas)
for i,rec in enumerate(records):
    im=Image.open(root/rec['path']).convert('RGBA');im.thumbnail((510,385),Image.Resampling.LANCZOS)
    x=24+(i%2)*540;y=34+(i//2)*440
    atlas.paste(im,(x,y+22),im);dr.text((x,y),rec['path'].rsplit('/',1)[-1],fill='white')
atlas.save(out/'frame_kit_atlas.png',optimize=True)
(root/'FRAME_KIT_MANIFEST.json').write_text(json.dumps({'schema_version':1,'kit':'F02 frame mounts and tablet dossier surfaces',
    'owner_approved':False,'source_type':'Lab07 owner image-generated hardware, ambientCG CC0 Paper001 paper; existing Pexels photograph provenance for cork',
    'source_sha256':source_sha,'assets':records,'atlas_sha256':hashlib.sha256((out/'frame_kit_atlas.png').read_bytes()).hexdigest(),
    'notes':'Modular material primitives, not composited screens, not musician portraits. Safe insets and paper mounts are provisional.'},indent=2))

p=root/'scene/frame_demo.gd';s=p.read_text()
def replace(old,new):
    global s
    assert old in s, ('Missing native fragment: '+old[:90])
    s=s.replace(old,new,1)
replace('var bio: Label','var bio: Label\nvar tablet_notes: Label\nvar tablet_sheet: PanelContainer')
replace('portrait = PanelContainer.new()\n    portrait.custom_minimum_size',
        'portrait = PanelContainer.new()\n    portrait.add_theme_stylebox_override("panel", _portrait_mount())\n    portrait.custom_minimum_size')
replace('    stat_panel.add_child(stat_rows)\n    var actions := HBoxContainer.new()', '''    stat_panel.add_child(stat_rows)
    tablet_sheet = PanelContainer.new()
    tablet_sheet.size_flags_vertical = Control.SIZE_EXPAND_FILL
    tablet_sheet.add_theme_stylebox_override("panel", _tablet_leaf())
    dossier.add_child(tablet_sheet)
    tablet_notes = Label.new()
    tablet_notes.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    tablet_notes.vertical_alignment = VERTICAL_ALIGNMENT_TOP
    tablet_notes.add_theme_font_size_override("font_size", 18)
    tablet_sheet.add_child(tablet_notes)
    var actions := HBoxContainer.new()''')
replace('    bio.visible = not narrow\n    root_margin.add_theme_constant_override("margin_left", (24 if narrow else 44) if frame_material_kind == "notepaper" else (28 if narrow else 48))',
'''    var tablet := size.x >= 600 and size.x < 900
    bio.visible = not narrow
    tablet_sheet.visible = tablet
    # Keep the sourced hardware corners, coil and footer physically clear of text.
    var left_inset := (34 if narrow else 44) if frame_material_kind == "notepaper" else (44 if size.x < 500 else (36 if narrow else 48))
    root_margin.add_theme_constant_override("margin_left", left_inset)''')
replace('    root_margin.add_theme_constant_override("margin_right", 24 if narrow else 48)\n    root_margin.add_theme_constant_override("margin_top", 30 if narrow else 42)\n    root_margin.add_theme_constant_override("margin_bottom", 24 if narrow else 32)',
'''    root_margin.add_theme_constant_override("margin_right", (34 if narrow else 44) if frame_material_kind == "notepaper" else (44 if size.x < 500 else (36 if narrow else 48)))
    root_margin.add_theme_constant_override("margin_top", 48 if size.x < 500 else (35 if narrow else 42))
    root_margin.add_theme_constant_override("margin_bottom", 50 if size.x < 500 else (30 if narrow else 32))''')
replace('    portrait.custom_minimum_size.y = 180 if narrow else 230',
'''    portrait.custom_minimum_size.y = 435 if tablet else (150 if narrow else 230)
    portrait.size_flags_vertical = Control.SIZE_SHRINK_BEGIN if tablet else Control.SIZE_EXPAND_FILL''')
replace('    bio.text = "PERSONNEL NOTES\\n\\n" + candidate.story',
        '    bio.text = "PERSONNEL NOTES\\n\\n" + candidate.story\n    tablet_notes.text = "PERSONNEL NOTES\\n\\n" + candidate.story')
replace('    status.text = "MATERIAL STUDY / Environment photo, not a musician portrait"',
        '    status.text = "STUDY ONLY · NO MUSICIAN PORTRAIT"')
s+='''

func _portrait_mount() -> StyleBoxTexture:
    var style := _surface("portrait_mount_" + frame_material_kind)
    style.set_texture_margin_all(42 if frame_material_kind == "flightcase" else 36)
    style.content_margin_left = 22 if frame_material_kind == "flightcase" else 18
    style.content_margin_right = 22 if frame_material_kind == "flightcase" else 18
    style.content_margin_top = 20
    style.content_margin_bottom = 20 if frame_material_kind == "flightcase" else 26
    return style

func _tablet_leaf() -> StyleBoxTexture:
    var style := _surface("dossier_sheet_" + frame_material_kind)
    style.set_texture_margin_all(42)
    style.content_margin_left = 24
    style.content_margin_right = 24
    style.content_margin_top = 20
    style.content_margin_bottom = 20
    return style
'''
# Recalibrate inert meter width to larger phone hardware safe insets.
assert 'size.x - 242.0' in s, 'Passive meter width contract changed'
s=s.replace('size.x - 242.0','size.x - 274.0',1)
p.write_text(s)
print('F02_FRAME_KIT',len(records),'independent source-backed physical plates; responsive native composition')
