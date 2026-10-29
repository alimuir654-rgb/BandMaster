"""U03 tactile input sprite kit: source-backed Lab07 six-state controls.
Owner's image-generated Lab07 textures are not claimed to be photographs.
No baked UI text, characters or gameplay values; native Godot buttons remain live.
"""
from pathlib import Path
from PIL import Image, ImageOps, ImageDraw, ImageFilter
import json, os, hashlib

root=Path(os.environ["ROOT"])
src=Path("art-sources/bandmaster_premium_controls_lab/assets")
out=root/"assets/material"
out.mkdir(parents=True,exist_ok=True)
states=("idle","hover","pressed","active","disabled")
families={
    "action":dict(source="transport_studio",crop=(124,78,666,347),blank=(307,117,476,309),size=(480,148),margins=[31,29,31,29],safe=[56,34,424,114]),
    "tab":dict(source="pad_studio",crop=(14,9,532,398),blank=(172,177,375,292),size=(200,132),margins=[27,26,27,26],safe=[35,30,165,105]),
    "browse":dict(source="channel_studio",crop=(291,105,678,271),blank=(366,152,605,241),size=(382,126),margins=[31,25,31,25],safe=[46,30,336,98])
}
def checksum(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()
def erase_embedded_words(im,rect):
    """Reconstruct original metal beneath the baked sample glyph from adjacent metal."""
    x,y,x2,y2=rect
    w,h=x2-x,y2-y
    l=im.crop((x-30,y,x-6,y2)).resize((w,h),Image.Resampling.BICUBIC)
    r=im.crop((x2+6,y,x2+30,y2)).resize((w,h),Image.Resampling.BICUBIC)
    fill=Image.blend(l,r,.5).filter(ImageFilter.GaussianBlur(1.4))
    mask=Image.new("L",(w,h))
    ImageDraw.Draw(mask).rectangle((4,4,w-5,h-5),fill=255)
    mask=mask.filter(ImageFilter.GaussianBlur(8))
    im=im.copy()
    im.paste(fill,(x,y),mask)
    return im
def sprite(surface,theme,size,state,family,original):
    w,h=size
    result=Image.new("RGBA",size)
    if theme=="notepaper":
        paper=ImageOps.fit(Image.open(out/"paper_surface.png").convert("RGBA"),size,method=Image.Resampling.LANCZOS)
        paper.putalpha(255)
        result.alpha_composite(paper)
        shadow=Image.new("RGBA",size)
        ImageDraw.Draw(shadow).rounded_rectangle((9,9,w-9,h-8),radius=16,fill=(12,12,12,140))
        result.alpha_composite(shadow.filter(ImageFilter.GaussianBlur(5)))
        inset=(7,6,w-7,h-7)
    else:
        inset=(3,2,w-3,h-3)
    metal=surface.resize((inset[2]-inset[0],inset[3]-inset[1]),Image.Resampling.LANCZOS)
    mask=Image.new("L",metal.size)
    ImageDraw.Draw(mask).rounded_rectangle((0,0,metal.width-1,metal.height-1),radius=13,fill=255)
    metal.putalpha(mask)
    result.alpha_composite(metal,(inset[0],inset[1]))
    if family in ("action","browse"):
        # Source's own state-dependent LED strips; no fake signal/zero state.
        box=(67,138,109,289) if family=="action" else (46,164,75,258)
        led=original.crop(box).resize((12,round(h*.55)),Image.Resampling.LANCZOS).convert("RGBA")
        if state=="disabled":
            led=ImageOps.grayscale(led).convert("RGBA")
        y=(h-led.height)//2
        result.alpha_composite(led,(10,y))
        result.alpha_composite(ImageOps.mirror(led),(w-22,y))
    if state=="focus":
        ImageDraw.Draw(result).rounded_rectangle((2,2,w-3,h-3),radius=14,outline=(247,210,142,250),width=3)
    return result

records=[]
sources={}
for family,cfg in families.items():
    for state in (*states,"focus"):
        actual="hover" if state=="focus" else state
        path=src/(cfg["source"]+"_"+actual+".png")
        assert path.is_file(),"Missing source: "+str(path)
        sources[str(path.relative_to(Path("art-sources")))]=checksum(path)
        original=Image.open(path).convert("RGB")
        surface=erase_embedded_words(original,cfg["blank"]).crop(cfg["crop"])
        for theme in ("flightcase","notepaper"):
            image=sprite(surface,theme,cfg["size"],state,family,original)
            target=out/f"control_{family}_{theme}_{state}.png"
            image.save(target,optimize=True)
            records.append(dict(path=str(target.relative_to(root)),sha256=checksum(target),
                source=str(path.relative_to(Path("art-sources"))),theme=theme,family=family,state=state,
                size=list(image.size),mode="RGBA",nine_slice_LTRB=cfg["margins"],
                content_safe_rect=cfg["safe"],interactive=True,focusable=True))
assert len(records)==36
assert len({x["sha256"] for x in records})==36
atlas=Image.new("RGB",(1120,1090),"#2b3032")
draw=ImageDraw.Draw(atlas)
for fi,family in enumerate(families):
    for ti,theme in enumerate(("flightcase","notepaper")):
        y=14+fi*352+ti*174
        draw.text((20,y),family.upper()+" / "+theme.upper(),fill="white")
        for i,state in enumerate((*states,"focus")):
            image=Image.open(out/f"control_{family}_{theme}_{state}.png").convert("RGBA")
            image.thumbnail((170,110),Image.Resampling.LANCZOS)
            x=18+i*183
            atlas.paste(image,(x,y+32),image)
            draw.text((x+4,y+149),state,fill="#d8cbb2")
atlas.save(out/"direct_control_atlas.png",optimize=True)
manifest=dict(schema_version=1,owner_approved=False,
    kit="U03 tactile action / tab / candidate-browse source states",
    rights_basis="Original owner-provided image-generated Lab07 artwork; not real hardware photography",
    source_sha256=sources,assets=records,atlas_sha256=checksum(out/"direct_control_atlas.png"),
    states=["idle","hover","pressed","active/selected","disabled","keyboard focus"],
    semantic_contract="Selected uses Button.toggle_mode + set_pressed_no_signal; selected is NOT disabled. Native text, focus and input remain live.",
    separation="Meters remain separate passive TextureRects, mouse-ignore and unfocusable; no fader/rotary revalidation claimed")
(root/"DIRECT_CONTROL_MANIFEST.json").write_text(json.dumps(manifest,indent=2))

p=root/"scene/frame_demo.gd"
s=p.read_text()
def replace(old,new):
    global s
    assert s.count(old)==1,"Native source fragment changed: "+old[:100]
    s=s.replace(old,new,1)
replace('        tab.focus_mode = Control.FOCUS_ALL\n        tab.pressed.connect',
        '        tab.focus_mode = Control.FOCUS_ALL\n        tab.toggle_mode = true\n        _style_tactile_button(tab, "tab")\n        tab.pressed.connect')
replace('        button.focus_mode = Control.FOCUS_ALL\n        button.pressed.connect',
        '        button.focus_mode = Control.FOCUS_ALL\n        button.toggle_mode = true\n        _style_tactile_button(button, "browse")\n        button.pressed.connect')
replace('    recruit_button.pressed.connect(_recruit_or_remove)',
        '    _style_tactile_button(recruit_button, "action")\n    recruit_button.add_theme_stylebox_override("normal", _control_style("action", "active"))\n    recruit_button.pressed.connect(_recruit_or_remove)')
replace('    roster_button.text = "ROSTER"\n    roster_button.pressed.connect',
        '    roster_button.text = "ROSTER"\n    _style_tactile_button(roster_button, "action")\n    roster_button.pressed.connect')
replace('        tabs[i].disabled = i == index',
        '        tabs[i].set_pressed_no_signal(i == index)  # selected != disabled')
replace('        candidate_buttons[i].disabled = i == index',
        '        candidate_buttons[i].set_pressed_no_signal(i == index)  # selected != disabled')
replace('    recruit_button.add_theme_stylebox_override("normal", _surface("paper_amber" if frame_material_kind == "notepaper" else "amber_key"))',
        '    # Native action has source-backed normal, hover, pressed and disabled variants.')
replace('    recruit_button.add_theme_color_override("font_color", Color("22252a"))',
        '    recruit_button.add_theme_color_override("font_color", Color("f5ecda"))')
s+='''
func _control_style(family: String, state: String) -> StyleBoxTexture:
    var style := StyleBoxTexture.new()
    style.texture = load("res://assets/material/control_%s_%s_%s.png" % [family, frame_material_kind, state])
    style.set_texture_margin_all(20)
    style.content_margin_left = 8
    style.content_margin_right = 8
    style.content_margin_top = 7
    style.content_margin_bottom = 7
    return style

func _style_tactile_button(button: Button, family: String) -> void:
    # All six states are separate source-backed sprites, not tinted flat rectangles.
    button.add_theme_stylebox_override("normal", _control_style(family, "idle"))
    button.add_theme_stylebox_override("hover", _control_style(family, "hover"))
    button.add_theme_stylebox_override("pressed", _control_style(family, "active"))
    button.add_theme_stylebox_override("hover_pressed", _control_style(family, "active"))
    button.add_theme_stylebox_override("disabled", _control_style(family, "disabled"))
    var focus_skin := _control_style(family, "focus")
    focus_skin.draw_center = false
    button.add_theme_stylebox_override("focus", focus_skin)
    for state in ["font_color", "font_hover_color", "font_pressed_color", "font_hover_pressed_color", "font_focus_color"]:
        button.add_theme_color_override(state, Color("f5ead3"))
    button.add_theme_color_override("font_disabled_color", Color("b8afa3"))
    button.set_meta("source_kit", "U03_Lab07_Tactile")
'''
p.write_text(s)
print("U03_DIRECT_CONTROLS",len(records),"sprites,",len(sources),"original source states")
