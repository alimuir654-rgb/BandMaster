extends SceneTree
const Lab = preload("res://Scripts/songwriting_lab.gd")
var failures := 0
func _initialize() -> void:
 var a := OptionButton.new()
 var b := OptionButton.new()
 var c := OptionButton.new()
 var d := OptionButton.new()
 for control in [a,b,c,d]:
  control.add_item("Original")
  control.add_item("Alternative")
 var take := Lab.capture(a,b,c,d)
 _check(take.size()==4,"capture all four creative dimensions")
 _check(Lab.remix(a,b,c,d)==4,"change all dimensions")
 _check(Lab.difference(take,a,b,c,d)==4,"comparison counts changes")
 _check(Lab.restore(take,a,b,c,d),"restore saved take")
 _check(Lab.difference(take,a,b,c,d)==0,"restored take matches")
 var bad := take.duplicate()
 bad["leader"]=99
 a.select(1)
 _check(not Lab.restore(bad,a,b,c,d),"reject invalid take atomically")
 _check(a.selected==1,"rejected take makes no partial changes")
 var source := FileAccess.get_file_as_string("res://Scripts/career_hub.gd")
 _check(source.contains("SAVE TAKE A") and source.contains("RESTORE TAKE A"),"actions integrated")
 _check(source.contains("update_comparison.call()"),"live comparison wired")
 _check(load("res://Scenes/CareerHub.tscn")!=null,"career scene loads")
 if failures==0:
  print("V80 A-B WRITING LAB PASSED")
 quit(0 if failures==0 else 1)
func _check(ok: bool,detail: String) -> void:
 if not ok:
  failures+=1
  push_error("V80 A-B FAILURE: "+detail)
