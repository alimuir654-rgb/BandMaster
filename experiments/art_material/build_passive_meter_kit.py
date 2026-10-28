"""Source-based, wholly passive RAG meter family for the isolated two-material Godot proof.

Owner-supplied image-generated Lab07 and Lab08 original rasters are NOT claimed
to be real photography. Native labels/costs and all interactions stay in GDScript.
"""
from pathlib import Path
from PIL import Image, ImageDraw, ImageEnhance
import os, json, hashlib

root=Path(os.environ['ROOT'])
src=Path('art-sources')
out=root/'assets/material'
out.mkdir(parents=True,exist_ok=True)
lab07=src/'bandmaster_premium_controls_lab/assets/signal_reference_reference.png'
lab08=src/'bandmaster_premium_dashboard_poc/assets/horizontal_base.png'
assert lab07.is_file() and lab08.is_file(), 'Missing original Lab07/08 source'
source_sha={str(p.relative_to(src)):hashlib.sha256(p.read_bytes()).hexdigest() for p in (lab07,lab08)}
assert source_sha[str(lab07.relative_to(src))]=='ebd0b79fa8b4bc9bdd2b69ad93af5976f7324dffa589e72d15e67fd2bed20646'
assert source_sha[str(lab08.relative_to(src))]=='06a9f12df4cca5777cd29f359ae688259ba85010283c178591750c3c4bee8d96'
led=Image.open(lab07).convert('RGB')
rail=Image.open(lab08).convert('RGBA').crop((110,107,732,169)).resize((420,42),Image.Resampling.LANCZOS)
samples={'red':led.crop((61,230,97,246)),'amber':led.crop((61,153,97,170)),'green':led.crop((61,94,97,110))}
off=led.crop((61,38,97,53))
records=[]
for kind in ('flightcase','notepaper'):
    surface=Image.open(out/('paper_surface.png' if kind=='notepaper' else 'case_surface.png')).convert('RGBA')
    for value in range(11):
        img=Image.new('RGBA',(436,54),(0,0,0,0))
        img.alpha_composite(surface.resize((436,54),Image.Resampling.LANCZOS))
        d=ImageDraw.Draw(img)
        if kind=='notepaper':
            d.rounded_rectangle((3,2,433,51),radius=8,fill=(38,44,46,255),outline=(116,99,71,255),width=3)
        else:
            d.rounded_rectangle((3,2,433,51),radius=8,fill=(13,18,23,255),outline=(105,111,112,255),width=2)
        img.alpha_composite(rail,(8,6))
        for i in range(10):
            x=28+i*38
            colour='red' if i<3 else ('amber' if i<6 else 'green')
            cell=(samples[colour] if i<value else off).resize((30,22),Image.Resampling.LANCZOS).convert('RGBA')
            cell=ImageEnhance.Brightness(cell).enhance((1.04 if kind=='flightcase' else .93) if i<value else .55)
            img.alpha_composite(cell,(x,16))
            ImageDraw.Draw(img).line((x-2,17,x-2,37),fill=(7,10,12,192),width=2)
        ImageDraw.Draw(img).rounded_rectangle((11,7,425,46),radius=6,outline=(7,9,11,180),width=2)
        name=f'passive_meter_{kind}_{value:02d}.png'
        dest=out/name;img.save(dest,optimize=True)
        records.append({'path':str(dest.relative_to(root)), 'sha256':hashlib.sha256(dest.read_bytes()).hexdigest(),
                        'width':436,'height':54,'mode':'RGBA','theme':kind,'value':value,'interactive':False,'focusable':False})
assert len(records)==22 and len({r['sha256'] for r in records})==22
for kind in ('flightcase','notepaper'):
    assert (out/f'passive_meter_{kind}_00.png').read_bytes() != (out/f'passive_meter_{kind}_01.png').read_bytes()
atlas=Image.new('RGB',(1000,680),'#242a2d')
draw=ImageDraw.Draw(atlas)
for row,kind in enumerate(('flightcase','notepaper')):
    draw.text((22,19+row*335),kind.upper()+' / 0  3  5  7  10',fill='white')
    for j,value in enumerate((0,3,5,7,10)):
        sprite=Image.open(out/f'passive_meter_{kind}_{value:02d}.png').convert('RGBA')
        x=23+(j%2)*490;y=58+row*335+(j//2)*85
        atlas.paste(sprite,(x,y),sprite)
        draw.text((x+445,y+14),str(value),fill='#d4d7db')
atlas.save(out/'passive_meter_atlas.png',optimize=True)
manifest={'schema_version':1,'owner_approved':False,'source_type':'owner-supplied image-generated artwork, not original photography',
 'source_sha256':source_sha,'crops':{'rail':[110,107,732,169],'red':[61,230,97,246],
 'amber':[61,153,97,170],'green':[61,94,97,110],'off':[61,38,97,53]},
 'assets':records,'atlas_sha256':hashlib.sha256((out/'passive_meter_atlas.png').read_bytes()).hexdigest(),
 'interaction_contract':'Read-only TextureRect, mouse ignored, keyboard focus NONE, native labels and values',
 'colour_contract':'0 dark; 1-3 red; 4-6 amber; 7-10 green. No coloured emission at zero.',
 'scaling':'LED array not sliced; image is 436x54. Validate actual 390,720,1280,1600 displays.'}
(root/'PASSIVE_METER_MANIFEST.json').write_text(json.dumps(manifest,indent=2))
p=root/'scene/frame_demo.gd'
s=p.read_text()
old="""        var meter := ProgressBar.new()
        meter.min_value = 0
        meter.max_value = 10
        meter.value = candidate.stats[i]
        meter.show_percentage = false
        var shade := Color("6eaa69") if int(candidate.stats[i]) >= 8 else (Color("d6a243") if int(candidate.stats[i]) >= 5 else Color("b85c55"))
        meter.add_theme_stylebox_override("fill", _skin(shade))
        meter.mouse_filter = Control.MOUSE_FILTER_IGNORE
        meter.focus_mode = Control.FOCUS_NONE
        meter.size_flags_horizontal = Control.SIZE_EXPAND_FILL
        meter.custom_minimum_size.y = 19
        line.add_child(meter)"""
new="""        var meter := TextureRect.new()
        meter.name = "ReadOnlyMeter"
        meter.texture = load("res://assets/material/passive_meter_%s_%02d.png" % [frame_material_kind, int(candidate.stats[i])])
        meter.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
        meter.stretch_mode = TextureRect.STRETCH_SCALE
        meter.mouse_filter = Control.MOUSE_FILTER_IGNORE
        meter.focus_mode = Control.FOCUS_NONE
        meter.size_flags_horizontal = Control.SIZE_EXPAND_FILL
        meter.custom_minimum_size.y = 22
        meter.set_meta("source_kit", "lab07_lab08_passive_meter")
        line.add_child(meter)"""
assert old in s,'Baseline native meter fragment changed'
s=s.replace(old,new,1)
assert '    roster_button.text = "ROSTER" if narrow else "VIEW ROSTER"' in s
s=s.replace('    roster_button.text = "ROSTER" if narrow else "VIEW ROSTER"',
'''    roster_button.text = "ROSTER" if narrow else "VIEW ROSTER"
    _apply_meter_sizes()''',1)
assert '    _update_budget()\n    recruit_button.add_theme_stylebox_override' in s
s=s.replace('    _update_budget()\n    recruit_button.add_theme_stylebox_override',
'''    _apply_meter_sizes()
    _update_budget()
    recruit_button.add_theme_stylebox_override''',1)
s+="""

func _apply_meter_sizes() -> void:
    # Keep physical ten-cell source proportions consistent across all resolutions.
    var target_height := 22.0 if size.x < 500 else (34.0 if size.x < 900 else (28.0 if size.x < 1500 else 38.0))
    var target_width := (maxf(140.0, size.x - 242.0) if size.x < 500 else minf(340.0, size.x * 0.43))
    for row in stat_rows.get_children():
        var meter := row.get_node_or_null("ReadOnlyMeter") as TextureRect
        if meter:
            meter.custom_minimum_size = Vector2(target_width, target_height)
            meter.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
"""
p.write_text(s)
print('PASSIVE_RAG_SOURCE_KIT',len(records),'native meter sprites; no portrait substitute')
