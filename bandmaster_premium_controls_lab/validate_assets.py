"""Static asset and scene checks. Does NOT substitute for Godot runtime tests."""
from pathlib import Path
from PIL import Image, ImageChops, ImageStat

root = Path(__file__).resolve().parent
assets = root / "assets"
scene = (root / "premium_controls_lab.tscn").read_text()
script = (root / "premium_controls_lab.gd").read_text()
assert 'res://bandmaster_premium_controls_lab/premium_controls_lab.gd' in scene
assert 'texture_pressed = load(prefix + "active.png")' in script
assert 'focus_entered.connect' in script
assert 'func _layout()' in script
assert 'FileAccess' not in script and 'user://' not in script

for family in ("transport", "pad", "channel"):
    for theme in ("studio", "electronic", "punk"):
        faces = {}
        for state in ("idle", "hover", "pressed", "active", "disabled"):
            p = assets / f"{family}_{theme}_{state}.png"
            assert p.exists(), p
            with Image.open(p) as im:
                im.verify()
            faces[state] = Image.open(p).convert("RGB")
        shape = faces["active"].size
        assert all(f.size == shape for f in faces.values())
        # Core acceptance: selected differs visibly from idle (not just a name).
        stat = ImageStat.Stat(ImageChops.difference(faces["active"], faces["idle"]))
        assert sum(stat.mean) / 3 > 4.0, (family, theme, stat.mean)
        assert ImageChops.difference(faces["active"], faces["disabled"]).getbbox()
print("OK: 45 state textures validated; 3 genres; 3 control families; scene wiring and save isolation")
