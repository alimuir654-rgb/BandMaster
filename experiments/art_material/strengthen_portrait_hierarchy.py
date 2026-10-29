"""C10: make the TWO verified provisional portraits visibly lead desktop recruitment.
A source-to-native composition correction, NOT an individual portrait-master claim.
Use existing C08 frame material and low-resolution provisional identity studies honestly.
"""
from pathlib import Path
import argparse, hashlib, json, os
from PIL import Image

ROOT=Path(os.environ["ROOT"])
MAT=ROOT/"assets/material"
SCENE=ROOT/"scene/frame_demo.gd"

def sha(p):
    return hashlib.sha256(Path(p).read_bytes()).hexdigest()

def once(s,old,new):
    assert s.count(old)==1,("C10 scene signature mismatch",old,s.count(old))
    return s.replace(old,new,1)

def install():
    assets=[]
    for kind in ("flightcase","notepaper"):
        p=MAT/("portrait_stage_"+kind+".png")
        assert p.exists(),p
        im=Image.open(p)
        assert im.size==(420,540),im.size
        assets.append({"source":str(p.relative_to(ROOT)),"size":[420,540],
                       "sha256":sha(p),"margin_px":42 if kind=="flightcase" else 36,
                       "origin":"C08 source-backed owner image-generated hardware/paper, not photographic portrait",
                       "owner_approved":False})
    s=SCENE.read_text()
    s=once(s,"var portrait_stage: CenterContainer\n",
        "var portrait_stage: CenterContainer\nvar candidate_strip: HBoxContainer\n")
    s=once(s,"    candidates.add_child(portrait_stage)\n",
        """    candidates.add_child(portrait_stage)
    candidate_strip = HBoxContainer.new()
    candidate_strip.name = "CandidateStrip"
    candidate_strip.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    candidate_strip.add_theme_constant_override("separation", 6)
    candidates.add_child(candidate_strip)
    candidates.move_child(candidate_strip, 0)
""")
    s=once(s,"    candidates.vertical = not narrow\n",
        """    candidates.vertical = not narrow
    # Two existing source-backed selector buttons share one horizontal row.
    # This releases vertical stage height for the actual candidate rather than
    # expanding metal/name bars across half a desktop screen.
    if narrow:
        candidate_strip.visible = false
        for i in candidate_buttons.size():
            if candidate_buttons[i].get_parent() != candidates:
                candidate_buttons[i].reparent(candidates)
            candidates.move_child(candidate_buttons[i], i)
    else:
        candidate_strip.visible = true
        for i in candidate_buttons.size():
            if candidate_buttons[i].get_parent() != candidate_strip:
                candidate_buttons[i].reparent(candidate_strip)
        candidates.move_child(candidate_strip, 0)
""")
    s=once(s,
        "        portrait.custom_minimum_size = Vector2(300, 330) if size.x < 1500 else Vector2(375, 465)",
        """        # Preserve the source face: taller portrait-shaped frame, no upscaling
        # of the underlying 512x690 provisional character source.
        portrait.custom_minimum_size = Vector2(385, 365) if size.x < 1500 else Vector2(500, 515)""")
    SCENE.write_text(s)
    record={
        "kit":"C10 wider editorial portrait-first native composition",
        "owner_approved":False,"art_verdict":"PARTIAL; character master source still blocked",
        "purpose":"Horizontal native candidate strip allows larger full-face portrait at >=900px without extending screen height",
        "width_breakpoint_px":900,
        "wide_stage_min": {"1280":[385,365],"1600":[500,515]},
        "native_text_and_controls":"native labels, 2 live browse selectors, 6 passive meters, action/roster retain signals",
        "narrow_layout":"unchanged for 390x844 and 720x1280",
        "source_portraits":"512x690 C05 provisional previews derived from TWO PERSON generation; NOT independently generated >=1024 masters",
        "sources":assets,
        "target_sizes":[[390,844],[720,1280],[1280,720],[1600,900]]
    }
    (ROOT/"C10_PORTRAIT_HIERARCHY_MANIFEST.json").write_text(json.dumps(record,indent=2)+"\n")
    print("C10 installed horizontal candidate rail and larger real native portrait stages")

def patch_test():
    p=ROOT/"tests/native_proof.gd";s=p.read_text()
    marker='check(scene.portrait_stage.visible == (sz.x >= 900), "Portrait stage visibility " + prefix)'
    extra=marker+'''
            check(scene.candidate_strip.visible == (sz.x >= 900), "C10 candidate strip visibility " + prefix)
            check(scene.candidate_buttons[0].get_parent() == scene.candidate_strip if sz.x >= 900 else scene.candidate_buttons[0].get_parent().name == "Candidates", "C10 candidate parent " + prefix)
            check(scene.portrait.custom_minimum_size.x >= (500 if sz.x >= 1500 else 385) if sz.x >= 900 else true, "C10 portrait minimum width " + prefix)'''
    s=once(s,marker,extra)
    p.write_text(s)
    print("C10 additional responsive native assertions installed")

if __name__=="__main__":
    parser=argparse.ArgumentParser()
    parser.add_argument("--phase",required=True,choices=("install","patch-test"))
    a=parser.parse_args()
    install() if a.phase=="install" else patch_test()
