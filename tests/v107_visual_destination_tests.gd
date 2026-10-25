extends SceneTree
var failures := 0

func _initialize() -> void:
 var source := FileAccess.get_file_as_string("res://Scripts/career_hub.gd")
 var first := source.find('var destinations := _card("YOUR WORLD"')
 var last := source.find('var pulse := _card("BAND PULSE"',first)
 _check(first >= 0 and last > first,"destination block available")
 if first >= 0 and last > first:
  var section := source.substr(first,last-first)
  _check(section.contains('var destination_card := PanelContainer.new()'),"cards use framed containers")
  _check(section.contains('var thumbnail := TextureRect.new()'),"cards render committed background art")
  _check(section.contains('thumbnail.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED'),"images crop cleanly")
  _check(section.contains('ResourceLoader.exists(thumb_path)'),"missing art is optional")
  _check(section.contains('tile.accessibility_name'),"destination controls remain accessible")
  _check(section.contains('tile.pressed.connect(func() -> void: _switch(target))'),"navigation remains wired")
 _check(load("res://Scenes/CareerHub.tscn") != null,"career scene imports")
 if failures == 0:
  print("V107 IMAGE DESTINATION HUB PASSED")
 quit(0 if failures == 0 else 1)

func _check(ok: bool,reason: String) -> void:
 if not ok:
  failures += 1
  push_error("V107 HUB FAILURE: "+reason)
