# Premium Lab 08.4 fully assembled source

This is a **pre-existing user-approved photographic hardware source** reconstructed strictly from supplied original Lab08 baseline followed by patch-only versions Lab08.2, Lab08.3 and Lab08.4.

Run: `godot --path . --scene res://bandmaster_premium_dashboard_poc/studio_controls_lab.tscn` to open the **isolated** control test bed; or `studio_dashboard.tscn` for the original integrated preview. Career saves and game UI are not modified.

Texture architecture: original isolated horizontal and vertical base/cap; fixed neutral FOCUS and BUZZ plates from Lab08.3; final 27 Focus and 23 Buzz LED overlays, final studio_control.gd and validation from Lab08.4; Lab07 transport/pad/channel textures inherited from Lab08 baseline. The older 21-piece rings from Lab08.2/08.3 have been overwritten where named, and additional indexed LEDs from Lab08.4 are present. Ring-off base plates are from Lab08.3, not the missing 08.4 ZIP.

The scripts/PNG source was statically validated locally. **Godot runtime screenshot validation and production integration are still pending.** Original visual approval applies to the reference lab controls; modified gameplay/control families need independent owner sign-off.

**Do not combine this with last week's procedural scene-world controls or push straight into main.** Record visual changes by family and preserve source-layer values. Manifest: `Art/References/PremiumHardware/Lab08_ASSEMBLY_SHA256.json`.
