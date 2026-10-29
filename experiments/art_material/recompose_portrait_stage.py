"""C08 portrait-first responsive proof; two source-backed physical vertical frames.
No new character claims: previews remain low-resolution and provisional.
"""
from pathlib import Path
from PIL import Image
import hashlib, json, os, argparse

ROOT=Path(os.environ["ROOT"])
MAT=ROOT/"assets/material"

def sha(p): return hashlib.sha256(Path(p).read_bytes()).hexdigest()

def once(s, a, b):
    assert s.count(a)==1, ("unexpected source signature",a[:100],s.count(a))
    return s.replace(a,b,1)

def nine(im, size, m):
    im=im.convert("RGBA")
    w,h=im.size; W,H=size
    out=Image.new("RGBA",size)
    for x0,y0,x1,y1,X0,Y0,X1,Y1 in [
        (0,0,m,m,0,0,m,m),(m,0,w-m,m,m,0,W-m,m),(w-m,0,w,m,W-m,0,W,m),
        (0,m,m,h-m,0,m,m,H-m),(m,m,w-m,h-m,m,m,W-m,H-m),
        (w-m,m,w,h-m,W-m,m,W,H-m),(0,h-m,m,h,0,H-m,m,H),
        (m,h-m,w-m,h,m,H-m,W-m,H),(w-m,h-m,w,h,W-m,H-m,W,H)]:
        part=im.crop((x0,y0,x1,y1))
        target=(X1-X0,Y1-Y0)
        if part.size!=target: part=part.resize(target,Image.Resampling.BICUBIC)
        out.paste(part,(X0,Y0))
    return out

def install():
    records=[]
    for theme in ("flightcase","notepaper"):
        src=MAT/("portrait_mount_"+theme+".png")
        dst=MAT/("portrait_stage_"+theme+".png")
        m=42 if theme=="flightcase" else 36
        nine(Image.open(src),(420,540),m).save(dst)
        records.append(dict(theme=theme,source=str(src.relative_to(ROOT)),source_sha256=sha(src),
            path=str(dst.relative_to(ROOT)),sha256=sha(dst),dimensions=[420,540],
            nine_slice_margins=[m]*4,content_safe=[m+12,m+10,420-m-12,540-m-10],
            alpha=True,rights_basis="Existing owner-supplied image-generated hardware or paper material; no claimed photography",
            owner_approved=False))
    p=ROOT/"scene/frame_demo.gd"
    s=p.read_text()
    s=once(s,"var portrait: PanelContainer\n",
        "var portrait: PanelContainer\nvar portrait_stage: CenterContainer\nvar _reflowing_portrait := false\n")
    s=once(s,"    candidates.add_child(bio)\n","""    candidates.add_child(bio)
    portrait_stage = CenterContainer.new()
    portrait_stage.name = "PortraitStage"
    portrait_stage.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    portrait_stage.size_flags_vertical = Control.SIZE_EXPAND_FILL
    candidates.add_child(portrait_stage)
""")
    s=once(s,"func _apply_layout() -> void:\n    var narrow := size.x < 900","""func _apply_layout() -> void:
    if _reflowing_portrait:
        return
    _reflowing_portrait = true
    var narrow := size.x < 900""")
    s=once(s,"    candidates.vertical = not narrow\n","""    candidates.vertical = not narrow
    var dossier := dossier_shell.get_node("Dossier") as VBoxContainer
    # Responsive REAL Godot child reparenting, not a flattened screen.
    if narrow:
        if portrait.get_parent() != dossier:
            portrait.reparent(dossier)
            dossier.move_child(portrait, 1)
        if bio.get_parent() != candidates:
            bio.reparent(candidates)
        portrait_stage.visible = false
        portrait.add_theme_stylebox_override("panel", _portrait_mount())
    else:
        portrait_stage.visible = true
        if portrait.get_parent() != portrait_stage:
            portrait.reparent(portrait_stage)
        if bio.get_parent() != dossier:
            bio.reparent(dossier)
        portrait.add_theme_stylebox_override("panel", _portrait_stage_style())
""")
    s=once(s,"    portrait.custom_minimum_size.y = 435 if tablet else (150 if narrow else 230)\n    portrait.size_flags_vertical = Control.SIZE_SHRINK_BEGIN if tablet else Control.SIZE_EXPAND_FILL","""    if narrow:
        portrait.custom_minimum_size = Vector2(160, 435 if tablet else 150)
        portrait.size_flags_horizontal = Control.SIZE_EXPAND_FILL
        portrait.size_flags_vertical = Control.SIZE_SHRINK_BEGIN if tablet else Control.SIZE_EXPAND_FILL
    else:
        portrait.custom_minimum_size = Vector2(300, 330) if size.x < 1500 else Vector2(375, 465)
        portrait.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
        portrait.size_flags_vertical = Control.SIZE_SHRINK_CENTER""")
    s=once(s,"    _apply_meter_sizes()\n    _choose_character_texture()\n\nfunc _select_role","""    _apply_meter_sizes()
    _choose_character_texture()
    _reflowing_portrait = false

func _select_role""")
    s=once(s,"func _portrait_mount() -> StyleBoxTexture:","""func _portrait_stage_style() -> StyleBoxTexture:
    var style := StyleBoxTexture.new()
    style.texture = load("res://assets/material/portrait_stage_%s.png" % frame_material_kind)
    style.set_texture_margin_all(42 if frame_material_kind == "flightcase" else 36)
    style.content_margin_left = 22 if frame_material_kind == "flightcase" else 18
    style.content_margin_right = 22 if frame_material_kind == "flightcase" else 18
    style.content_margin_top = 20
    style.content_margin_bottom = 26
    return style

func _portrait_mount() -> StyleBoxTexture:""")
    s=once(s,'    if size.x >= 900:\n        path = "res://assets/characters/%s_portrait_landscape_focalsafe_1536x430.webp" % id\n',
       """    # C08 vertical mount uses the original-proportion provisional preview;
    # source person pixels are not resampled into a fake high-res master.
""")
    p.write_text(s)
    (ROOT/"C08_PORTRAIT_STAGE_MANIFEST.json").write_text(json.dumps(dict(
        schema_version=1,kit="C08 portrait-dominant desktop arrangement",owner_approved=False,
        art_verdict="PARTIAL; 512px candidate previews from a two-person plate are NOT independent high-resolution originals",
        desktop="Vertical source portrait in physical left mount; live candidate notes and six passive meters on right",
        mobile="Unchanged established narrow portrait/stat stack",assets=records),indent=2)+"\n")
    print("C08_SOURCES",[(r["theme"],r["sha256"][:12]) for r in records])

def patch_test():
    p=ROOT/"tests/native_proof.gd";s=p.read_text()
    for name in ("alex","nia_griffiths"):
        old='(scene.character_photo.texture.resource_path.contains("'+name+'_portrait_landscape_focalsafe") if sz.x >= 900 else scene.character_photo.texture.resource_path.contains("'+name+'_portrait_provisional"))'
        new='scene.character_photo.texture.resource_path.contains("'+name+'_portrait_provisional")'
        s=once(s,old,new)
    s=once(s,'check(scene.character_photo.texture.resource_path.contains("portrait_landscape_focalsafe") == (window.size.x >= 900), "Wrong portrait source after live resize " + prefix)',
       'check(scene.character_photo.texture.resource_path.contains("portrait_provisional"), "Wrong vertical portrait after live resize " + prefix)')
    anchor='check(scene.portrait.get_theme_stylebox("panel") is StyleBoxTexture, "Source portrait bezel missing " + prefix)'
    new=anchor+'''
            check(scene.portrait_stage.visible == (sz.x >= 900), "Portrait stage visibility " + prefix)
            check(scene.portrait.get_parent() == scene.portrait_stage if sz.x >= 900 else scene.portrait.get_parent().name == "Dossier", "Portrait parent " + prefix)
            check(Rect2(Vector2.ZERO, Vector2(sz)).encloses(scene.portrait.get_global_rect()), "Portrait offscreen " + prefix)
            check(scene.bio.get_parent().name == ("Dossier" if sz.x >= 900 else "Candidates"), "Bio parent " + prefix)
            check(scene.portrait.get_global_rect().size.y >= 290 if sz.x >= 900 else true, "Portrait too small desktop " + prefix)'''
    s=once(s,anchor,new)
    p.write_text(s)
    print("C08_TEST_BINDINGS_INSTALLED")

if __name__=="__main__":
    a=argparse.ArgumentParser();a.add_argument("--phase",choices=("install","patch-test"),required=True)
    phase=a.parse_args().phase
    install() if phase=="install" else patch_test()
