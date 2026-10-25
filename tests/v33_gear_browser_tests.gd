extends SceneTree
const Gear = preload("res://Scripts/gear_shop.gd")
var failures := 0

func _initialize() -> void:
 var source := FileAccess.get_file_as_string("res://Scripts/career_hub.gd")
 var start := source.find("func _gear() -> void:")
 var finish := source.find("func _band() -> void:",start)
 _check(start >= 0 and finish > start,"gear view exists")
 if start >= 0 and finish > start:
  var view := source.substr(start,finish-start)
  _check(view.contains("selected_gear_item = key"),"selection changes without purchase")
  _check(view.contains("if str(item[\"id\"]) != selected_gear_item:"),"only selected item expanded")
  _check(view.contains("buy.disabled = not afford"),"unaffordable purchase disabled")
  _check(view.contains("owned.has(selected_gear_item)"),"owned items cannot be rebought")
  _check(view.contains("preserve_gear_scroll = true"),"selection preserves reading position")
 _check(source.contains("preserve_roster_scroll or preserve_gear_scroll"),"scroll preservation supports both screens")
 var state := {"cash":10,"tour_day":1,"owned_equipment":[]}
 var original := JSON.stringify(state)
 _check(not bool(Gear.buy(state,"amp").get("ok",false)),"insufficient funds rejected")
 _check(JSON.stringify(state)==original,"browse and failed purchase do not mutate save")
 var scene: PackedScene = load("res://Scenes/CareerHub.tscn")
 _check(scene != null,"career scene loads")
 if failures == 0:
  print("V33 GEAR BROWSER TESTS PASSED")
 quit(0 if failures == 0 else 1)

func _check(ok: bool, detail: String) -> void:
 if not ok:
  failures += 1
  push_error("V33 GEAR BROWSER FAILURE: "+detail)
