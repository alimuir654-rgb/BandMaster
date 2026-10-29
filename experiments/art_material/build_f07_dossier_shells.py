"""F07 source-backed dossier shells. Two independently sized Godot nine-slice assets, no baked UI."""
import hashlib,json,os
from pathlib import Path
from PIL import Image,ImageEnhance,ImageFilter,ImageOps,ImageDraw
ROOT=Path(os.environ["ROOT"])
SRC=Path("art-sources")
MAT=ROOT/"assets/material"
def sha(p):return hashlib.sha256(p.read_bytes()).hexdigest()
def tiled(im,size):
    out=Image.new("RGB",size)
    for y in range(0,size[1],im.height):
        for x in range(0,size[0],im.width):out.paste(im,(x,y))
    return out
def nine(im,size,m=60):
    w,h=im.size;W,H=size;out=Image.new("RGBA",size)
    for a,b,c,d,A,B,C,D in [
      (0,0,m,m,0,0,m,m),(m,0,w-m,m,m,0,W-m,m),(w-m,0,w,m,W-m,0,W,m),
      (0,m,m,h-m,0,m,m,H-m),(m,m,w-m,h-m,m,m,W-m,H-m),
      (w-m,m,w,h-m,W-m,m,W,H-m),(0,h-m,m,h,0,H-m,m,H),
      (m,h-m,w-m,h,m,H-m,W-m,H),(w-m,h-m,w,h,W-m,H-m,W,H)]:
        part=im.crop((a,b,c,d))
        out.paste(part.resize((C-A,D-B),Image.Resampling.BICUBIC),(A,B))
    return out
def generate():
    W,H=900,650
    cork_path=SRC/"Art/Photography/Formation/corkboard_day_pexels.webp"
    tape_path=SRC/"Art/UI/FormationCraft/rehearsal_notebook.png"
    case_path=MAT/"dossier_sheet_flightcase.png"
    paper_path=MAT/"paper_surface.png"
    surface_path=MAT/"case_surface.png"
    cork=ImageOps.fit(Image.open(cork_path).convert("RGB"),(W,H))
    day=ImageEnhance.Brightness(ImageEnhance.Contrast(cork).enhance(.78)).enhance(1.12).convert("RGBA")
    shadow=Image.new("RGBA",(W,H));d=ImageDraw.Draw(shadow)
    d.rounded_rectangle((20,25,880,638),radius=9,fill=(28,18,12,175))
    day.alpha_composite(shadow.filter(ImageFilter.GaussianBlur(16)))
    day.alpha_composite(tiled(Image.open(paper_path).convert("RGB"),(842,592)).convert("RGBA"),(28,30))
    edge=ImageDraw.Draw(day)
    edge.rectangle((30,31,867,620),outline=(112,82,49,95),width=2)
    edge.line((52,49,846,49),fill=(255,255,255,86),width=2)
    tape=Image.open(tape_path).convert("RGBA").crop((208,0,436,43))
    tape=tape.resize((222,42),Image.Resampling.LANCZOS)
    day.alpha_composite(tape,(104,8))
    day.alpha_composite(tape.transpose(Image.Transpose.FLIP_LEFT_RIGHT),(581,10))
    paper_out=MAT/"dossier_shell_notepaper.png";day.save(paper_out)
    night=ImageEnhance.Brightness(tiled(Image.open(surface_path).convert("RGB"),(W,H)).convert("RGBA")).enhance(.72)
    night.alpha_composite(nine(Image.open(case_path).convert("RGBA"),(W,H)))
    case_out=MAT/"dossier_shell_flightcase.png";night.save(case_out)
    sources=[paper_path,cork_path,tape_path,case_path,surface_path]
    assets=[dict(path=str(p.relative_to(ROOT)),size=[W,H],sha256=sha(p),
                 content_safe=[82,72,818,568],nine_slice_margins=[65]*4,
                 owner_approved=False) for p in (paper_out,case_out)]
    (ROOT/"F07_DOSSIER_MANIFEST.json").write_text(json.dumps(dict(
        schema_version=1,kit="F07 independent materials for live native dossier",
        rights_basis="Photographed Pexels cork + ambientCG CC0 paper + owner-provided image-generated FormationCraft tape and Lab07 metal; not claimed all photographic",
        sources=[dict(path=str(p),sha256=sha(p)) for p in sources],
        assets=assets,owner_approved=False),indent=2)+"\n")
    atlas=Image.new("RGB",(900,1300))
    atlas.paste(night.convert("RGB"),(0,0));atlas.paste(day.convert("RGB"),(0,650))
    atlas.save(MAT/"f07_dossier_shell_atlas.png")
def integrate():
    path=ROOT/"scene/frame_demo.gd";s=path.read_text()
    def replace(a,b):
        nonlocal s
        assert s.count(a)==1,("Unexpected scene signature",a,s.count(a))
        s=s.replace(a,b,1)
    replace("var tablet_sheet: PanelContainer","var tablet_sheet: PanelContainer\nvar dossier_shell: PanelContainer")
    replace("    body.add_child(dossier)","""    dossier_shell = PanelContainer.new()
    dossier_shell.name = "DossierShell"
    dossier_shell.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    dossier_shell.size_flags_vertical = Control.SIZE_EXPAND_FILL
    body.add_child(dossier_shell)
    dossier_shell.add_child(dossier)""")
    replace("    tablet_sheet.visible = tablet","""    tablet_sheet.visible = tablet
    # Texture-backed inner bay is deliberately omitted on narrow views.
    var shell_style := StyleBoxEmpty.new() if narrow else _dossier_shell_style()
    dossier_shell.add_theme_stylebox_override("panel", shell_style)""")
    replace("func _portrait_mount() -> StyleBoxTexture:","""func _dossier_shell_style() -> StyleBoxTexture:
    var shell := StyleBoxTexture.new()
    shell.texture = load("res://assets/material/dossier_shell_%s.png" % frame_material_kind)
    shell.set_texture_margin_all(65)
    shell.content_margin_left = 32
    shell.content_margin_right = 32
    shell.content_margin_top = 24
    shell.content_margin_bottom = 24
    return shell

func _portrait_mount() -> StyleBoxTexture:""")
    path.write_text(s)
if __name__=="__main__":
    generate();integrate()
    print("F07 source-backed dossier shells integrated",sha(MAT/"dossier_shell_notepaper.png")[:12])
