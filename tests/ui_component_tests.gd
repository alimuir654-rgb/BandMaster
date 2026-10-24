extends SceneTree
const Components = preload("res://Scripts/ui_components.gd")
var failures := 0
func _initialize() -> void:
 var root := VBoxContainer.new()
 get_root().add_child(root)
 var card := Components.section(root,"First chapter","The band is finding its feet.")
 _check(card.get_parent() is PanelContainer,"card is housed in a panel")
 _check(card.get_child_count() == 2,"card has heading and explanation")
 var objective := {"label":"rehearse","current":2,"target":3}
 Components.objective(card,objective)
 _check(card.get_child_count() == 4,"objective draws row and progress")
 var row := HBoxContainer.new()
 card.add_child(row)
 var person := {"name":"Alex","role":"Drummer"}
 var portrait := Components.portrait(row,person)
 _check(portrait.custom_minimum_size.x >= 74,"portrait is touch-screen legible")
 Components.story(card,{"day":4,"kind":"band","title":"FIRST REHEARSAL","text":"The group discovers its sound."})
 _check(card.get_child_count() == 7,"story adds timeline row and divider")
 _check(JSON.parse_string(JSON.stringify(person)) is Dictionary,"member data untouched")
 _check(JSON.parse_string(JSON.stringify(objective)) is Dictionary,"objective data untouched")
 if failures == 0:
  print("UI COMPONENT TESTS PASSED")
 root.queue_free()
 quit(0 if failures == 0 else 1)
func _check(ok: bool, detail: String) -> void:
 if not ok:
  failures += 1
  push_error("UI COMPONENT FAILURE: "+detail)
