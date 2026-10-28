"""Source-backed material proof. No flattened screen or synthetic portraits."""
from pathlib import Path
from PIL import Image, ImageOps, ImageEnhance, ImageDraw
import os, json, hashlib, urllib.request, zipfile, io, shutil
ROOT=Path(os.environ['ROOT']); SRC=Path('art-sources')
OUT=ROOT/'assets/material'; OUT.mkdir(parents=True,exist_ok=True)
records=[]
def save(im,name,source,transform):
    p=OUT/name; im.save(p)
    records.append(dict(path=str(p.relative_to(ROOT)),sha256=hashlib.sha256(p.read_bytes()).hexdigest(),size=list(im.size),source=source,transform=transform,owner_approved=False))
def tile(im,size):
    out=Image.new('RGB',size)
    for y in range(0,size[1],im.height):
        for x in range(0,size[0],im.width): out.paste(im,(x,y))
    return out
hardware=SRC/'bandmaster_premium_controls_lab/assets/channel_studio_idle.png'
assert hashlib.sha256(hardware.read_bytes()).hexdigest()=='ac1999c27afcedffee97e1460b2f3ca5e2ec8829259f83885f73a48712dda229'
frame=Image.open(hardware).convert('RGB').crop((5,8,957,410))
w,h=frame.size; m=83
sample=Image.open(SRC/'bandmaster_premium_controls_lab/assets/transport_studio_idle.png').convert('RGB').crop((190,133,310,245))
blank=ImageEnhance.Brightness(tile(sample,(512,512))).enhance(.6)
for box,dest in [((0,0,m,m),(0,0,m,m)),((w-m,0,w,m),(512-m,0,512,m)),((0,h-m,m,h),(0,512-m,m,512)),((w-m,h-m,w,h),(512-m,512-m,512,512)),((m,0,w-m,m),(m,0,512-m,m)),((m,h-m,w-m,h),(m,512-m,512-m,512)),((0,m,m,h-m),(0,m,m,512-m)),((w-m,m,w,h-m),(512-m,m,512,512-m))]:
    x,y,a,b=dest; blank.paste(frame.crop(box).resize((a-x,b-y),Image.Resampling.LANCZOS),(x,y))
save(blank,'flightcase_frame.png',str(hardware.relative_to(SRC)),'Blank nine-slice assembly from unlettered perimeter; no GUITAR, CHANNEL or arrows')
save(tile(sample,(384,384)),'case_surface.png','bandmaster_premium_controls_lab/assets/transport_studio_idle.png','Text-free surface sample (190,133,310,245)')
keysrc=Image.open(SRC/'bandmaster_premium_controls_lab/assets/transport_studio_idle.png').convert('RGB').crop((128,70,661,333))
keysrc.paste(tile(sample,(449,179)),(42,42))
key=keysrc.resize((480,132),Image.Resampling.LANCZOS)
save(key,'metal_key.png','bandmaster_premium_controls_lab/assets/transport_studio_idle.png','Inner key rim; baked play symbol replaced by text-free material')
save(ImageOps.colorize(ImageOps.grayscale(key),'#60441e','#f6d58b'),'amber_key.png','bandmaster_premium_controls_lab/assets/transport_studio_idle.png','Warm amber grade of blank physical key')
url='https://ambientcg.com/get?file=Paper001_2K-JPG.zip'
req=urllib.request.Request(url,headers={'User-Agent':'BandMaster material proof'})
data=urllib.request.urlopen(req,timeout=45).read()
z=zipfile.ZipFile(io.BytesIO(data)); name=next(n for n in z.namelist() if n.endswith('_Color.jpg'))
paper=Image.open(io.BytesIO(z.read(name))).convert('RGB')
paper=ImageOps.colorize(ImageOps.grayscale(paper),'#aaa08b','#f3ebd9')
paper=ImageEnhance.Contrast(paper).enhance(.65)
save(paper.resize((768,768),Image.Resampling.LANCZOS),'notepaper_frame.png',url,'CC0 Paper001 material; warm grade. Source method approximation, NOT claimed photographic')
save(paper.crop((256,256,1024,1024)).resize((384,384)),'paper_surface.png',url,'Separate unruled paper material')
paperkey=paper.crop((0,0,1536,384)).resize((480,120))
ImageDraw.Draw(paperkey).line((0,119,479,119),fill='#b1a58e',width=2)
save(paperkey,'paper_key.png',url,'Paper tab with restrained lower edge')
save(ImageOps.colorize(ImageOps.grayscale(paperkey),'#9c6a23','#edc468'),'paper_amber.png',url,'Amber paper action tab')
room=SRC/'Art/Photography/Formation/daylight_music_room_pexels.webp'
shutil.copy2(room,OUT/'audition_room.webp')
records.append(dict(path='assets/material/audition_room.webp',source=str(room.relative_to(SRC)),sha256=hashlib.sha256(room.read_bytes()).hexdigest(),usage='Audition environment, NOT Alex or Nia portrait',owner_approved=False))
shutil.copy2(SRC/'Art/Photography/Formation/SOURCE_PHOTO_MANIFEST.json',OUT/'SOURCE_PHOTO_MANIFEST.json')
(ROOT/'MATERIAL_MANIFEST.json').write_text(json.dumps({'source_commit':'c084690f7ccde4625eaebf68b89ae476fd08724d','paper_license':'CC0-1.0','paper_license_url':'https://docs.ambientcg.com/license/','paper_zip_sha256':hashlib.sha256(data).hexdigest(),'hardware_origin':'owner-supplied image-generated Lab07 originals, not a claimed real photograph','owner_approved':False,'assets':records},indent=2))
p=ROOT/'scene/frame_demo.gd'; s=p.read_text()
def replace(a,b):
    global s
    assert a in s, 'Missing baseline fragment: '+a[:80]
    s=s.replace(a,b)
replace('background.texture = load("res://assets/%s_frame_1280x720.png" % frame_material_kind)','background.texture = load("res://assets/material/%s_frame.png" % frame_material_kind)')
replace('background.patch_margin_left = 108 if frame_material_kind == "notepaper" else 28','background.patch_margin_left = 24 if frame_material_kind == "notepaper" else 42')
replace('background.patch_margin_right = 28','background.patch_margin_right = 24 if frame_material_kind == "notepaper" else 42')
replace('background.patch_margin_top = 26','background.patch_margin_top = 24 if frame_material_kind == "notepaper" else 42')
replace('background.patch_margin_bottom = 28','background.patch_margin_bottom = 24 if frame_material_kind == "notepaper" else 42')
replace('var candidates := VBoxContainer.new()','var candidates := BoxContainer.new()')
replace('as VBoxContainer','as BoxContainer')
replace('candidates.custom_minimum_size = Vector2(0, 102 if narrow else 0)','candidates.vertical = not narrow\n    candidates.custom_minimum_size = Vector2(0, 60 if narrow else 0)')
replace('button.text = CANDIDATES[i].name + "  /  " + CANDIDATES[i].town','button.text = CANDIDATES[i].name + "\\n" + CANDIDATES[i].town\n        button.size_flags_horizontal = Control.SIZE_EXPAND_FILL')
replace('button.custom_minimum_size.y = 48','button.custom_minimum_size.y = 60')
replace('var missing := Label.new()\n    missing.text = "PORTRAIT MASTER MISSING\\nART GATE BLOCKED"\n    missing.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER\n    missing.vertical_alignment = VERTICAL_ALIGNMENT_CENTER\n    portrait.add_child(missing)', '''var room := TextureRect.new()
    room.texture = load("res://assets/material/audition_room.webp")
    room.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
    room.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
    room.mouse_filter = Control.MOUSE_FILTER_IGNORE
    portrait.add_child(room)
    var caption := Label.new()
    caption.text = "AUDITION ROOM / ENVIRONMENT STUDY"
    caption.add_theme_font_size_override("font_size", 12)
    caption.add_theme_color_override("font_color", Color("fff8e9"))
    caption.add_theme_color_override("font_shadow_color", Color("171717"))
    caption.add_theme_constant_override("shadow_offset_x", 1)
    caption.add_theme_constant_override("shadow_offset_y", 1)
    caption.vertical_alignment = VERTICAL_ALIGNMENT_BOTTOM
    caption.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
    caption.mouse_filter = Control.MOUSE_FILTER_IGNORE
    portrait.add_child(caption)''')
replace('(56 if narrow else 120) if frame_material_kind == "notepaper" else (28 if narrow else 65)','(24 if narrow else 44) if frame_material_kind == "notepaper" else (28 if narrow else 48)')
replace('"margin_right", 18 if narrow else 65','"margin_right", 24 if narrow else 48')
replace('"margin_top", 28 if narrow else 40','"margin_top", 30 if narrow else 42')
replace('"margin_bottom", 28 if narrow else 65','"margin_bottom", 24 if narrow else 32')
replace('portrait.custom_minimum_size.y = 135 if narrow else 220','portrait.custom_minimum_size.y = 180 if narrow else 230')
replace('16 if narrow else 22','20 if narrow else 28')
replace('10 if narrow else 15','12 if narrow else 16')
replace('details.add_theme_font_size_override("font_size", 19)','details.add_theme_font_size_override("font_size", 23)')
replace('bio.add_theme_font_size_override("font_size", 18)','bio.add_theme_font_size_override("font_size", 21)')
replace('status = Label.new()','status = Label.new()\n    status.add_theme_font_size_override("font_size", 12)')
replace('Demo catalogue · no production save writes','MATERIAL STUDY / Environment photo, not a musician portrait')
replace('"%s · %s · %d talent"','"%s  /  %d talent"')
replace('[candidate.name, candidate.role, candidate.cost]','[candidate.name, candidate.cost]')
s=s[:s.index('# Skins reuse')]+'''
func _surface(name: String, tint: Color = Color.WHITE) -> StyleBoxTexture:
    var style := StyleBoxTexture.new()
    style.texture = load("res://assets/material/" + name + ".png")
    style.set_texture_margin_all(12)
    style.content_margin_left = 12
    style.content_margin_right = 12
    style.content_margin_top = 6
    style.content_margin_bottom = 6
    style.modulate_color = tint
    return style

func _skin(tint: Color) -> StyleBoxTexture:
    return _surface("paper_surface", tint)

func _install_material_theme() -> void:
    var paper := frame_material_kind == "notepaper"
    var key := "paper_key" if paper else "metal_key"
    var gold := "paper_amber" if paper else "amber_key"
    var ink := Color("272b30") if paper else Color("f5eddb")
    var palette := Theme.new()
    palette.default_font_size = 16
    palette.set_color("font_color", "Label", ink)
    for state in ["font_color", "font_hover_color", "font_focus_color"]:
        palette.set_color(state, "Button", ink)
    palette.set_color("font_pressed_color", "Button", Color("241e16"))
    palette.set_color("font_disabled_color", "Button", Color("241e16"))
    palette.set_stylebox("normal", "Button", _surface(key))
    palette.set_stylebox("hover", "Button", _surface(key, Color(1.1, 1.1, 1.1)))
    palette.set_stylebox("pressed", "Button", _surface(gold))
    palette.set_stylebox("disabled", "Button", _surface(gold))
    var ring := _surface(gold)
    ring.draw_center = false
    ring.set_texture_margin_all(3)
    palette.set_stylebox("focus", "Button", ring)
    palette.set_stylebox("panel", "PanelContainer", _surface("paper_surface" if paper else "case_surface"))
    palette.set_stylebox("background", "ProgressBar", _surface("paper_surface", Color("beb7a8") if paper else Color("343a3d")))
    theme = palette
'''
s=s.replace('recruit_button.add_theme_stylebox_override("normal", _skin(Color("e4b35c")))','recruit_button.add_theme_stylebox_override("normal", _surface("paper_amber" if frame_material_kind == "notepaper" else "amber_key"))')
p.write_text(s)
print('Prepared',len(records),'source-backed resources; portraits remain outside this material test')
