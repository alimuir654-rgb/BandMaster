extends SceneTree
var failed := 0
func _initialize() -> void:
 var path := "res://addons/woldui/components/wold_button/wold_button.tscn"
 _check(ResourceLoader.exists(path),"WoldUI component exists")
 var asset = load(path)
 _check(asset is PackedScene,"WoldUI button scene loads")
 if asset is PackedScene:
  var button = asset.instantiate()
  _check(button is Button,"native Godot button inheritance")
  _check(button is WoldButton,"WoldUI style component")
  button.free()
 var showcase = load("res://Scenes/WoldUIShowcase.tscn")
 _check(showcase is PackedScene,"landscape showcase imports")
 if showcase is PackedScene:
  var workspace = showcase.instantiate()
  _check(workspace is Control,"showcase root valid")
  workspace.free()
 if failed == 0:
  print("WOLDUI FOUNDATION TESTS PASSED")
 quit(0 if failed == 0 else 1)
func _check(ok: bool,detail: String) -> void:
 if not ok:
  failed += 1
  push_error("WOLDUI FOUNDATION FAILURE: "+detail)
