#!/usr/bin/env python3
"""Build C21 from the verified C20 module. Preserve original native regressions.
Two guarded factory replacements delegate styling to maintained GDScript files.
"""
from __future__ import annotations
import argparse, shutil
from pathlib import Path

def main():
    p=argparse.ArgumentParser();p.add_argument('--source',type=Path,required=True);p.add_argument('--out',type=Path,required=True);p.add_argument('--templates',type=Path,required=True);a=p.parse_args()
    assert a.source.exists() and a.source.resolve()!=a.out.resolve()
    a.out.mkdir(parents=True,exist_ok=True)
    for src in a.source.rglob('*'):
        rel=src.relative_to(a.source)
        if not src.is_file() or any(k in rel.parts for k in ['.godot','proof','__pycache__']) or src.suffix in ['.import','.uid','.ttf','.otf']:continue
        dst=a.out/rel;dst.parent.mkdir(parents=True,exist_ok=True)
        if src.suffix in ['.gd','.tscn']:dst.write_text(src.read_text().replace('"res://components/control_atlas/','"res://'))
        else:shutil.copy2(src,dst)
    for src in a.templates.glob('*.in'):shutil.copy2(src,a.out/src.name.removesuffix('.in'))
    kit=a.out/'kit.gd';s=kit.read_text();start=s.index('static func frame(');end=s.index('static func badge(',start)
    s=s[:start]+'''static func frame(look: String, preset := "panel") -> PanelContainer:
    return load("res://frame_styles.gd").make(look, preset)
static func dialog(title: String, message: String, look := "flightcase") -> Control:
    var overlay = load("res://framed_dialog.gd").new()
    overlay.look = look
    overlay.title_text = title
    overlay.body_text = message
    return overlay
'''+s[end:]
    s=s.replace('Color("898579") if look == "notepaper"','Color("615b51") if look == "notepaper"');kit.write_text(s)
    gallery=a.out/'gallery.gd';s=gallery.read_text();start=s.index('func _frames_page()');end=s.index('func _layout()',start)
    s=s[:start]+'func _frames_page() -> void:\n    load("res://frame_examples.gd").populate(self)\n'+s[end:];gallery.write_text(s)
    (a.out/'project.godot').write_text('''config_version=5
[application]
config/name="BandMaster — Frame Styling C21"
run/main_scene="res://gallery.tscn"
[display]
window/size/viewport_width=1280
window/size/viewport_height=720
[rendering]
renderer/rendering_method="gl_compatibility"
renderer/rendering_method.mobile="gl_compatibility"
''')
    with (a.out/'README.md').open('a') as f:f.write('''\n\n## C21 frame styling and hardening\nSix distinct source-derived frame profiles in each look (twelve PNGs). Frames are decorative, non-focusable containers; live children remain native. FRAME_STYLES_C21.json defines margins, safe insets, provenance and hashes. Invalid frame look/preset values fall back to flightcase/panel; styles are per-instance.\nKit.dialog(title,message,look) creates a reusable overlay: add it to a full-rect screen, connect completed(bool), then open_modal(). Escape cancels, Tab/Shift-Tab remain inside, and previous focus is restored. Call queue_free() on completed for one-shot dialogs. No gameplay/save state is changed.\nExisting native_test.gd remains the original C20 suite; frame_test.gd adds source/style, reflow and modal input/focus checks. Art remains subject to owner review.\n''')
    print('C21 reconstructed from existing module; core controls/meters/Lab08 retained')
if __name__=='__main__':main()
