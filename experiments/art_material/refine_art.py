"""Visual correction from the first actual Godot material renders."""
from pathlib import Path
from PIL import Image, ImageOps, ImageEnhance, ImageDraw, ImageFilter
import os,json,hashlib
root=Path(os.environ['ROOT']); out=root/'assets/material'; src=Path('art-sources')
# Preserve the original photographed-style corner proportions: 83/512 -> 42/256.
p=out/'flightcase_frame.png'; frame=Image.open(p).convert('RGB')
original=Image.open(src/'bandmaster_premium_controls_lab/assets/channel_studio_idle.png').convert('RGB').crop((5,8,957,410))
left=original.crop((0,95,83,140)).resize((83,346),Image.Resampling.LANCZOS)
frame.paste(left,(0,83)); frame.paste(ImageOps.mirror(left),(429,83))
# Remove tiled centre seams by blending a mirrored material patch, not drawing noise.
patch=Image.open(out/'case_surface.png').convert('RGB')
patch=Image.blend(patch,ImageOps.mirror(patch),.5)
patch=Image.blend(patch,ImageOps.flip(patch),.5)
frame.paste(ImageEnhance.Brightness(patch).enhance(.55).resize((346,346)),(83,83))
frame.resize((256,256),Image.Resampling.LANCZOS).save(p)
patch.save(out/'case_surface.png')
# Smaller original key plus correct 9-slice insets stops stretching the bevel geometry.
key=Image.open(out/'metal_key.png').convert('RGB').resize((240,66),Image.Resampling.LANCZOS)
key.save(out/'metal_key.png')
gray=ImageOps.autocontrast(ImageOps.grayscale(key),cutoff=1).point(lambda x:int(255*(x/255)**.55))
ImageOps.colorize(gray,'#79531d','#f6d893').save(out/'amber_key.png')
# Independent page assembly: source paper, offset leaf, restrained shadow, source cork.
paper=Image.open(out/'notepaper_frame.png').convert('RGB').resize((512,512))
cork=Image.open(src/'Art/Photography/Formation/corkboard_day_pexels.webp').convert('RGB').resize((512,512))
cork=ImageEnhance.Color(cork).enhance(.45)
cork=ImageEnhance.Brightness(cork).enhance(.72)
mask=Image.new('L',(512,512));draw=ImageDraw.Draw(mask)
draw.polygon([(15,12),(130,14),(257,11),(382,14),(495,12),(497,140),(494,269),(498,390),(495,497),(366,495),(248,499),(124,496),(14,498),(16,367),(13,244),(16,114)],fill=255)
shadow=mask.filter(ImageFilter.GaussianBlur(5))
base=Image.composite(Image.new('RGB',(512,512),'#463d31'),cork,shadow)
back=ImageEnhance.Brightness(paper).enhance(.88)
backmask=Image.new('L',(512,512));ImageDraw.Draw(backmask).rectangle((19,17,501,502),fill=255)
base=Image.composite(back,base,backmask)
base=Image.composite(paper,base,mask)
base.save(out/'notepaper_frame.png')
# Separate lighting grade, clearly an environment reference rather than a person.
room=Image.open(out/'audition_room.webp').convert('RGB')
room.save(out/'audition_room_notepaper.webp',quality=94)
night=ImageEnhance.Color(room).enhance(.65)
night=ImageEnhance.Brightness(night).enhance(.75)
night.save(out/'audition_room_flightcase.webp',quality=94)
p=root/'scene/frame_demo.gd';s=p.read_text()
s=s.replace('room.texture = load("res://assets/material/audition_room.webp")','room.texture = load("res://assets/material/audition_room_%s.webp" % frame_material_kind)')
s=s.replace('caption.text = "AUDITION ROOM / ENVIRONMENT STUDY"','caption.text = "AUDITION ROOM / ENVIRONMENT STUDY"\n    caption.size_flags_vertical = Control.SIZE_EXPAND_FILL')
s=s.replace('dossier.size_flags_horizontal = Control.SIZE_EXPAND_FILL','dossier.size_flags_horizontal = Control.SIZE_EXPAND_FILL\n    dossier.size_flags_vertical = Control.SIZE_EXPAND_FILL')
s=s.replace('style.set_texture_margin_all(12)','''style.set_texture_margin_all(12)
    if name in ["metal_key", "amber_key"]:
        style.texture_margin_left = 28
        style.texture_margin_right = 28
        style.texture_margin_top = 18
        style.texture_margin_bottom = 18''')
p.write_text(s)
manifest=json.loads((root/'MATERIAL_MANIFEST.json').read_text())
for record in manifest['assets']:
    p=root/record['path']
    record['sha256']=hashlib.sha256(p.read_bytes()).hexdigest()
    with Image.open(p) as im: record['size']=list(im.size)
manifest['visual_correction']='Native first-render inspection: correct stretched frame bolts, LED edge smearing, key proportions, page depth and caption placement.'
manifest['scope']='Reusable frame/control/environment materials only. No musician portrait acceptance.'
manifest['added_material_sources']=[{'path':'assets/material/notepaper_frame.png','additional_source':'Art/Photography/Formation/corkboard_day_pexels.webp','rights':'Existing Pexels source manifest retained'}]
for kind in ['flightcase','notepaper']:
    p=out/('audition_room_'+kind+'.webp')
    manifest['assets'].append({'path':str(p.relative_to(root)),'sha256':hashlib.sha256(p.read_bytes()).hexdigest(),'source':'Art/Photography/Formation/daylight_music_room_pexels.webp','transform':'Brightness/colour grade for material palette','owner_approved':False})
(root/'MATERIAL_MANIFEST.json').write_text(json.dumps(manifest,indent=2))
