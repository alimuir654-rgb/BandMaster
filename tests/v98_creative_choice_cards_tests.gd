extends SceneTree
const Lab = preload("res://Scripts/songwriting_lab.gd")
var failures := 0
func _initialize() -> void:
 var options := OptionButton.new()
 for label in ["Riff","Lyrics","Groove"]:
  options.add_item(label)
 _check(Lab.advance(options,1) and options.selected == 1,"forward creative choice")
 _check(Lab.advance(options,-1) and options.selected == 0,"backward creative choice")
 _check(Lab.advance(options,-1) and options.selected == 2,"wrap backward")
 options.free()
 var source := FileAccess.get_file_as_string("res://Scripts/career_hub.gd")
 var a := source.find("func _actions() -> void:")
 var b := source.find("func _recording_studio() -> void:",a)
 _check(a>=0 and b>a,"writing room")
 if a>=0 and b>a:
  var studio := source.substr(a,b-a)
  _check(studio.contains("selector_grid.visible = false"),"desktop dropdowns replaced")
  _check(studio.contains("creative_grid.columns = 2"),"landscape direct-choice grid")
  _check(studio.contains("lab.move_child(creative_grid,2)"),"choices lead experiment workbench")
  _check(studio.contains("experiment_grid.visible = false"),"duplicate desktop controls removed")
  _check(studio.contains("SongLab.advance(selector_control,-1)"),"back choice")
  _check(studio.contains("SongLab.advance(selector_control,1)"),"forward choice")
  _check(studio.contains("refresh_preview.call()"),"live preview")
  _check(studio.contains("update_comparison.call()"),"saved-take comparison")
  _check(studio.contains("COMMIT TO THIS SONG"),"day-spending CTA retained")
 _check(load("res://Scenes/CareerHub.tscn") != null,"career scene imports")
 if failures==0:
  print("V98 CREATIVE CHOICE CARDS PASSED")
 quit(0 if failures==0 else 1)
func _check(ok: bool,reason: String) -> void:
 if not ok:
  failures+=1
  push_error("V98 CHOICES FAILURE: "+reason)
