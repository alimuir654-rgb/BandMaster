"""C14: physically grounded two-look casting stage and restrained native interaction.
Original room photograph is ENVIRONMENT ONLY, not a person. No new game logic,
no meter changes, no character source upgrade claim, no production saves.
"""
from pathlib import Path
from PIL import Image, ImageOps, ImageEnhance, ImageFilter
import argparse, hashlib, json, os

ROOT=Path(os.environ["ROOT"])
OUT=ROOT/"assets/material"
SRC=OUT/"audition_room.webp"

def sha(path):
    return hashlib.sha256(Path(path).read_bytes()).hexdigest()

def replace_once(text, before, after):
    count=text.count(before)
    assert count==1, ("C14 expected exact scene anchor", before[:100], count)
    return text.replace(before,after,1)

def install():
    # Reuse the EXISTING Pexels rehearsal-room environmental source. There
    # are no sourced people and no fake musician identity in these backplates.
    assert SRC.exists(),SRC
    meter_before={p.name:sha(p) for p in OUT.glob("passive_meter_*.png")}
    assert len(meter_before)>=22,"Owner-liked meter source kit missing"
    room=ImageOps.fit(Image.open(SRC).convert("RGB"),(1200,900),
                      method=Image.Resampling.LANCZOS,centering=(.50,.50))
    records=[]
    for kind in ("flightcase","notepaper"):
        backdrop=room.filter(ImageFilter.GaussianBlur(2.1 if kind=="flightcase" else 3.0))
        backdrop=ImageEnhance.Color(backdrop).enhance(.44 if kind=="flightcase" else .58)
        backdrop=ImageEnhance.Contrast(backdrop).enhance(1.13 if kind=="flightcase" else .84)
        matte=Image.new("RGB",backdrop.size,"#111b21" if kind=="flightcase" else "#d9c6a4")
        backdrop=Image.blend(backdrop,matte,.57 if kind=="flightcase" else .64)
        # Material-specific directional vignette. The centre stays a quiet,
        # source-backed rehearsal environment behind the independent portrait.
        veil=Image.new("L",(1200,900))
        px=veil.load()
        for y in range(900):
            for x in range(1200):
                edge=min(1.0,((x/1200-.50)**2/.40+(y/900-.50)**2/.48))
                px[x,y]=min(160,max(0,round(edge*(130 if kind=="flightcase" else 74))))
        over=Image.new("RGB",backdrop.size,"#060e14" if kind=="flightcase" else "#ddc9a9")
        backdrop=Image.composite(over,backdrop,veil)
        path=OUT/("c14_environment_"+kind+".webp")
        backdrop.save(path,format="WEBP",quality=91,method=5)
        records.append({"path":str(path.relative_to(ROOT)),"sha256":sha(path),
                        "dimensions":[1200,900],"material":kind,"alpha":False,
                        "source":str(SRC.relative_to(ROOT)),"source_sha256":sha(SRC),
                        "rights":"Existing Pexels environmental photo manifest, retained; not a character photo",
                        "usage":"Separate photographic atmosphere BEHIND native framed portrait, not a full UI screen",
                        "content_safe":"Central quiet area (x=130..1070,y=120..800)",
                        "owner_approved":False})
    # No new API, texture or sprite touches the read-only meters.
    assert meter_before=={p.name:sha(p) for p in OUT.glob("passive_meter_*.png")}
    scene=ROOT/"scene/frame_demo.gd"
    s=scene.read_text()
    s=replace_once(s,"var portrait_stage: CenterContainer\n",
        "var portrait_stage: CenterContainer\nvar scene_atmosphere: TextureRect\nvar _selection_tween: Tween\n")
    s=replace_once(s,'    portrait_stage.name = "PortraitStage"\n',
        '''    portrait_stage.name = "PortraitStage"
    scene_atmosphere = TextureRect.new()
    scene_atmosphere.name = "SourceBackedAtmosphere"
    scene_atmosphere.texture = load("res://assets/material/c14_environment_%s.webp" % frame_material_kind)
    scene_atmosphere.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
    scene_atmosphere.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
    scene_atmosphere.mouse_filter = Control.MOUSE_FILTER_IGNORE
    scene_atmosphere.focus_mode = Control.FOCUS_NONE
    scene_atmosphere.modulate.a = 0.74 if frame_material_kind == "flightcase" else 0.55
    portrait_stage.add_child(scene_atmosphere)
''')
    s=replace_once(s,"        candidate_strip.visible = true\n",
        """        candidate_strip.visible = true
        # Independent environmental framing at each native landscape size;
        # the source portrait remains a separate interactive-safe panel.
        scene_atmosphere.custom_minimum_size = Vector2(445, 400) if size.x < 1500 else Vector2(570, 530)
""")
    s=replace_once(s,"        button.pressed.connect(_select.bind(i))",
                   "        button.pressed.connect(_select_live.bind(i))")
    s=replace_once(s,"func _select(index: int) -> void:",
        '''func _select_live(index: int) -> void:
    # Only real user presses animate. Deterministic setup/tests that call
    # _select directly retain stable native screenshot timing and model state.
    _select(index)
    if _selection_tween and _selection_tween.is_running():
        _selection_tween.kill()
    portrait.offset_transform_enabled = true
    portrait.offset_transform_visual_only = true
    portrait.offset_transform_pivot_ratio = Vector2(0.5, 0.5)
    portrait.offset_transform_position = Vector2(0, 7)
    portrait.modulate.a = 0.82
    _selection_tween = create_tween().set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
    _selection_tween.tween_property(portrait, "offset_transform_position", Vector2.ZERO, 0.23)
    _selection_tween.parallel().tween_property(portrait, "modulate:a", 1.0, 0.23)

func _select(index: int) -> void:''')
    s=replace_once(s,"    recruit_button.pressed.connect(_recruit_or_remove)",
                   "    recruit_button.pressed.connect(_recruit_live)")
    s=replace_once(s,"func _recruit_or_remove() -> void:",
        '''func _recruit_live() -> void:
    _recruit_or_remove()
    # Physical key depression, without changing the player-editable budget
    # rules or allowing a passive stat meter to receive user input.
    recruit_button.offset_transform_enabled = true
    recruit_button.offset_transform_visual_only = true
    recruit_button.offset_transform_pivot_ratio = Vector2(0.5, 0.5)
    recruit_button.offset_transform_scale = Vector2(0.966, 0.966)
    var motion := create_tween().set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
    motion.tween_property(recruit_button, "offset_transform_scale", Vector2.ONE, 0.15)

func _recruit_or_remove() -> void:''')
    scene.write_text(s)
    (ROOT/"C14_AMBIENT_RECRUITMENT_MANIFEST.json").write_text(json.dumps({
        "kit":"C14 source-backed environmental casting stages + native input-micro-motion",
        "owner_quote":"The progress here is reasonable. Keep it going till 4pm. I'm hoping for more progress and bigger ambition whilst retaining the quality. The meters look good.",
        "owner_approved":False,"art_verdict":"PRELIMINARY; musician originals remain too corporate",
        "meter_baseline_unchanged":meter_before,"meter_semantics":"Six RAG stats remain mouse IGNORE and focus NONE",
        "source_portraits":"C13 independent licensed synthetic 1024px portraits; these are still not credible indie-musician originals",
        "interaction":"User-initiated native candidate browse and recruit/remove motion only; no new economy or save mutations",
        "viewport_target":[[390,844],[720,1280],[1280,720],[1600,900]],
        "assets":records},indent=2)+"\n")
    print("C14 installed",len(records),"real-photo environmental backplates, native motion; owner-liked meters unchanged")

def patch_test():
    p=ROOT/"tests/native_proof.gd"
    s=p.read_text()
    marker='check(scene.stat_rows.get_child_count() == 6, "Wrong attribute count " + prefix)'
    addition=marker+'''
            check(scene.scene_atmosphere != null and scene.scene_atmosphere.texture != null, "C14 source environment missing " + prefix)
            check(scene.scene_atmosphere.mouse_filter == Control.MOUSE_FILTER_IGNORE and scene.scene_atmosphere.focus_mode == Control.FOCUS_NONE, "C14 atmosphere intercepts input " + prefix)
            check(scene.scene_atmosphere.get_parent() == scene.portrait_stage, "C14 scene atmosphere misplaced " + prefix)
            check(scene.scene_atmosphere.visible if sz.x >= 900 else not scene.portrait_stage.visible, "C14 scene responsive stage " + prefix)'''
    s=replace_once(s,marker,addition)
    p.write_text(s)
    print("C14 source/semantics/responsive native assertions installed")

if __name__=="__main__":
    a=argparse.ArgumentParser()
    a.add_argument("--phase",required=True,choices=("install","patch-test"))
    args=a.parse_args()
    install() if args.phase=="install" else patch_test()
