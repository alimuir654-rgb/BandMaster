"""F16 12:00 dossier + U17/U18 13:00 day action source-correction; no new families.

The 1600x900 native C15 day screen showed a very tall mostly blank paper
dossier, and the night dossier clustered high against an empty lower bay.
Keep the C15 portraits, all six read-only meters, native controls and smaller
layouts unchanged. Only centre/cap the existing wide dossier as a deliberate
physical note card alongside the existing portrait stage.
"""
import argparse
import hashlib
import json
import os
from pathlib import Path
from PIL import Image, ImageDraw, ImageFilter, ImageOps

ROOT = Path(os.environ["ROOT"])
SCENE = ROOT / "scene/frame_demo.gd"
MANIFEST = ROOT / "F16_WIDE_DOSSIER_MANIFEST.json"


def sha(path):
    return hashlib.sha256(Path(path).read_bytes()).hexdigest()


def replace_once(s, old, new):
    assert s.count(old) == 1, ("F16 unique source anchor missing", old[:110], s.count(old))
    return s.replace(old, new, 1)


def install():
    mat = ROOT / "assets/material"
    meters_before = {p.name: sha(p) for p in mat.glob("passive_meter_*.png")}

    # U18: U17 proved typography alone was insufficient in REAL 390/1280
    # captures: dark text still merges with the original low-value enamel.
    # Change technique once, and brighten ONLY the existing six DAY action
    # faces using their original source luminance. Preserve metal relief, rails,
    # LEDs, source alpha, NIGHT controls and all six passive RAG instruments.
    night_before = {p.name:sha(p) for p in mat.glob("control_*_flightcase_*.png")}
    palette = {
        "idle":((196,181,151),(252,240,214)),
        "hover":((213,197,162),(255,251,230)),
        "pressed":((169,149,117),(233,210,177)),
        "active":((201,161,93),(250,226,177)),
        "disabled":((183,181,174),(230,225,213)),
        "focus":((214,199,171),(255,249,223)),
    }
    source_history=[]
    u09_path=ROOT/"U09_DAY_ENAMEL_MANIFEST.json"
    u09_data=json.loads(u09_path.read_text())
    direct_path=ROOT/"DIRECT_CONTROL_MANIFEST.json"
    direct_data=json.loads(direct_path.read_text())
    u18_atlas=Image.new("RGB",(960,6*160),"#e4dccc")
    for i,(state,(lo,hi)) in enumerate(palette.items()):
        path=mat/("control_action_notepaper_"+state+".png")
        assert path.is_file(),path
        old_hash=sha(path)
        old=Image.open(path).convert("RGBA")
        w,h=old.size
        assert (w,h)==(480,148),(state,w,h)
        mask=Image.new("L",(w,h),0)
        ImageDraw.Draw(mask).rounded_rectangle((round(w*.095),round(h*.32),
            round(w*.905),round(h*.71)),radius=17,fill=255)
        mask=mask.filter(ImageFilter.GaussianBlur(5))
        face=ImageOps.colorize(ImageOps.grayscale(old),black=lo,white=hi).convert("RGBA")
        new=Image.composite(face,old,mask)
        new.putalpha(old.getchannel("A"))
        new.save(path,optimize=True)
        new_hash=sha(path)
        assert old_hash!=new_hash,(state,"U18 ineffective source technique")
        u18_atlas.paste(old.convert("RGB"),(0,i*160))
        u18_atlas.paste(new.convert("RGB"),(480,i*160))
        source_history.append({"path":str(path.relative_to(ROOT)),"state":state,
            "sha256_before":old_hash,"sha256_after":new_hash,"dimensions":[w,h],
            "alpha":"original retained","nine_slice_LTRB":[31,29,31,29],
            "content_safe_rect":[56,34,424,114],
            "rights_basis":"Owner-supplied image-generated Lab07 + U09 original grade; no new licensed source",
            "transform":"masked, feathered source luminance to warm ivory/ochre paper-metal face; original perimeter and LED untouched",
            "owner_approved":False})
        direct_entries=[entry for entry in direct_data["assets"] if entry["path"]==str(path.relative_to(ROOT))]
        assert len(direct_entries)==1 and direct_entries[0]["sha256"]==old_hash
        direct_entries[0]["U18_previous_sha256"]=old_hash
        direct_entries[0]["sha256"]=new_hash
        direct_entries[0]["U18_face_refined"]=True
        history_entries=[entry for entry in u09_data["assets"] if entry["path"]==str(path.relative_to(ROOT))]
        assert len(history_entries)==1 and history_entries[0]["sha256_after"]==old_hash
        history_entries[0]["U18_current_sha256"]=new_hash
        history_entries[0]["U18_note"]="Superseded by U18 luminance-refined day action; U09 after hash is historical"
    assert night_before=={p.name:sha(p) for p in mat.glob("control_*_flightcase_*.png")}
    assert meters_before=={p.name:sha(p) for p in mat.glob("passive_meter_*.png")}
    atlas_path=mat/"u18_day_action_face_atlas.png"
    u18_atlas.save(atlas_path,optimize=True)
    direct_data["U18_day_action_correction"]="Only six day action faces source-backed brightened; 23 RAG and NIGHT bytes unchanged"
    direct_path.write_text(json.dumps(direct_data,indent=2)+"\n")
    u09_data["U18_day_action_superseded"]=True
    u09_path.write_text(json.dumps(u09_data,indent=2)+"\n")
    assert len(meters_before) >= 22, "Owner-liked passive meter kit missing"
    source_panels = []
    for theme in ("notepaper", "flightcase"):
        for family in ("dossier_shell", "portrait_stage"):
            path = mat / (family + "_" + theme + ".png")
            assert path.is_file(), path
            with Image.open(path) as im:
                dims = list(im.size)
            margin = 65 if family == "dossier_shell" else (36 if theme == "notepaper" else 42)
            source_panels.append({
                "path": str(path.relative_to(ROOT)),
                "sha256": sha(path),
                "dimensions": dims,
                "alpha": True,
                "nine_slice_margins_px": [margin] * 4,
                "safe_content_rect_px": [margin + 10, margin + 10, dims[0] - margin - 10, dims[1] - margin - 10],
                "states": "passive non-focus visual panel; input comes from separate native buttons",
                "source_rights_basis": "Existing F07 dossier and C08 portrait stage, source-backed owner-supplied image-generated Lab07 flightcase hardware / ambientCG CC0 Paper001; source manifests retained.",
                "owner_approved": False,
            })
    s = SCENE.read_text()
    anchor = '    heading.add_theme_font_size_override("font_size", 20 if narrow else 28)\n'
    change = '''    # F16: the wide desk now has one compact, vertically balanced native
    # paper/metal dossier beside the portrait. No new image or control family.
    # At smaller widths retain exactly the verified C15 placement.
    if size.x >= 1500:
        dossier_shell.size_flags_vertical = Control.SIZE_SHRINK_CENTER
        dossier_shell.custom_minimum_size.y = 530
    else:
        dossier_shell.size_flags_vertical = Control.SIZE_EXPAND_FILL
        dossier_shell.custom_minimum_size.y = 0
'''
    s = replace_once(s, anchor, change + anchor)

    # U17 13:00: correction of actually observed day RECRUIT/ROSTER label
    # crowding in F16 native PNGs. This does NOT add a source-art family.
    # Source-backed hardware sprites and six passive RAG meters are unchanged.
    s = replace_once(s,
        '    roster_button.text = "ROSTER" if narrow else "VIEW ROSTER"\n',
        '''    roster_button.text = "ROSTER"
    roster_button.tooltip_text = "View current roster"
    if frame_material_kind == "notepaper":
        recruit_button.add_theme_font_size_override("font_size", 18 if size.x < 500 else 21)
        roster_button.add_theme_font_size_override("font_size", 17 if size.x < 500 else 20)
''')
    s = replace_once(s,
        '    recruit_button.add_theme_color_override("font_color", Color("332719") if frame_material_kind == "notepaper" else Color("f5ecda"))\n',
        '    recruit_button.add_theme_color_override("font_color", Color("19140f") if frame_material_kind == "notepaper" else Color("f5ecda"))\n')
    s = replace_once(s,
        '    button.set_meta("source_kit", "U03_Lab07_Tactile")\n',
        '''    if family == "action" and frame_material_kind == "notepaper":
        for state in ["font_color", "font_hover_color", "font_pressed_color", "font_hover_pressed_color", "font_focus_color"]:
            button.add_theme_color_override(state, Color("19140f"))
        button.add_theme_color_override("font_outline_color", Color("fbe9bd"))
        button.add_theme_constant_override("outline_size", 1)
    button.set_meta("source_kit", "U03_Lab07_Tactile")
''')
    SCENE.write_text(s)
    assert meters_before == {p.name: sha(p) for p in mat.glob("passive_meter_*.png")}, "Passive meter source mutation"
    u17_actions = []
    for state in ("idle","hover","pressed","active","disabled","focus"):
        path = mat / ("control_action_notepaper_" + state + ".png")
        assert path.exists(), path
        with Image.open(path) as im:
            dims = list(im.size)
        u17_actions.append({
            "path": str(path.relative_to(ROOT)), "sha256":sha(path),
            "dimensions":dims,"state":state,
            "nine_slice_margins_px":[20,20,20,20],
            "text_safe_frac":[0.11,0.23,0.89,0.77],
            "source_rights_basis":"Owner-supplied image-generated Lab07 source, original U09 enamel grading; no new licence",
            "owner_approved":False})
    MANIFEST.write_text(json.dumps({
        "kit": "F16 compact wide native dossier; no new asset family",
        "status": "native proof pending; not owner-approved",
        "owner_approved": False,
        "source_scene": "scene/frame_demo.gd",
        "source_art_change": False,
        "U17_13h_native_action_correction": "390x844 and 1280x720 DAY action labels insufficiently readable. Compact ROSTER + tooltip, 18/17px small and 21/20px larger native type, DAY dark ink and 1px warm keyline; NIGHT source unchanged.",
        "U17_unchanged_action_source_components": u17_actions,
        "U18_day_action_refined_source":source_history,
        "U18_atlas_path":str(atlas_path.relative_to(ROOT)),
        "U18_atlas_sha256":sha(atlas_path),
        "U18_no_meter_changes":True,
        "U18_night_control_sha256":night_before,
        "component_improvement": "1600x900 source-backed dossier shrinks to its 530px minimum and vertically centres; unchanged at 390x844, 720x1280 and 1280x720",
        "source_art_sources": source_panels,
        "read_only_meter_sha256": meters_before,
        "read_only_meter_semantics": "Six RAG bars retain mouse IGNORE and focus NONE, no regeneration",
        "canonical_portraits": "C15 512x690 original-size paired-origin previews remain provisional; no independently generated >=1024 masters",
        "target_viewports": [[390,844], [720,1280], [1280,720], [1600,900]],
    }, indent=2) + "\n")
    print("F16 installed 1600x900 compact dossier; panels reused; 23 meters unchanged")


def patch_test():
    path = ROOT / "tests/native_proof.gd"
    s = path.read_text()
    anchor = '            check(scene.portrait_stage.visible == (sz.x >= 900), "Portrait stage visibility " + prefix)\n'
    extra = '''            check(scene.dossier_shell.size_flags_vertical == Control.SIZE_SHRINK_CENTER if sz.x >= 1500 else scene.dossier_shell.size_flags_vertical == Control.SIZE_EXPAND_FILL, "F16 adaptive wide dossier sizing " + prefix)
            check(scene.dossier_shell.get_global_rect().size.y <= 605 if sz.x >= 1500 else true, "F16 too much empty widescreen dossier " + prefix)
            check(abs(scene.dossier_shell.get_global_rect().get_center().y - scene.portrait.get_global_rect().get_center().y) <= 145 if sz.x >= 1500 else true, "F16 dossier and portrait not balanced " + prefix)
            check(scene.dossier_shell.get_global_rect().end.y < scene.actions_bar.get_global_rect().position.y if sz.x >= 1500 else true, "F16 dossier collides with action rail " + prefix)
            check(scene.bio.get_global_rect().end.y < scene.dossier_shell.get_global_rect().end.y - 38 if sz.x >= 1500 and kind == "notepaper" else true, "F16 editorial notes too near paper bottom " + prefix)
'''
    s = replace_once(s, anchor, anchor + extra)

    # U17 validated in native Godot, not an image-only change.
    anchor = '            check(scene.recruit_button.get_meta("source_kit", "") == "U03_Lab07_Tactile", "Direct control skin not bound " + prefix)\n'
    s = replace_once(s, anchor, anchor + '''            check(scene.roster_button.text == "ROSTER" and scene.roster_button.tooltip_text == "View current roster", "U17 roster concise label and tooltip " + prefix)
            if kind == "notepaper":
                check(scene.recruit_button.get_theme_font_size("font_size") == (18 if sz.x < 500 else 21), "U17 action font " + prefix)
                check(scene.roster_button.get_theme_font_size("font_size") == (17 if sz.x < 500 else 20), "U17 roster font " + prefix)
                check(scene.recruit_button.get_theme_color("font_color").r < 0.14, "U17 action ink " + prefix)
                check(scene.recruit_button.get_theme_constant("outline_size") == 1, "U17 text keyline " + prefix)
                check(scene.recruit_button.get_theme_stylebox("focus") is StyleBoxTexture, "U17 focus material " + prefix)
''')
    anchor = '            await shot(window, prefix + "-recruited")\n'
    s = replace_once(s, anchor, anchor + '''            scene.roster_button.pressed.emit()
            check(scene.status.text.contains("Nia Griffiths"), "U17 roster not listing selected recruit " + prefix)
            check(scene.talent == 155 and scene.roster.size() == 1, "U17 roster press mutated budget " + prefix)
''')
    anchor = '            await shot(window, prefix + "-focus")\n'
    s = replace_once(s, anchor, anchor + '''            scene.roster_button.pressed.emit()
            check(scene.status.text.contains("empty") and scene.talent == 200, "U17 refund/roster mismatch " + prefix)
''')
    path.write_text(s)
    print("F16 native width, vertical balance, action separation assertions installed")


if __name__ == "__main__":
    parser = argparse.ArgumentParser()
    parser.add_argument("--phase", choices=("install", "patch-test"), required=True)
    options = parser.parse_args()
    install() if options.phase == "install" else patch_test()
