extends SceneTree
const SongLab = preload("res://Scripts/songwriting_lab.gd")
var failures := 0
func _initialize() -> void:
 var idea := OptionButton.new()
 var form := OptionButton.new()
 var title := OptionButton.new()
 var leader := OptionButton.new()
 for value in ["Riff","Lyric","Groove"]:
  idea.add_item(value)
 for value in ["Verse / Chorus","Slow Build","Loose Jam"]:
  form.add_item(value)
 for value in ["First","Second","Third"]:
  title.add_item(value)
 leader.add_item("Jo")
 leader.add_item("Alex")
 _check(SongLab.can_commit(idea,form,title,leader),"all choices available")
 _check(SongLab.advance(idea) and idea.selected == 1,"next musical concept")
 _check(SongLab.advance(idea,2) and idea.selected == 0,"ideas wrap cleanly")
 _check(SongLab.remix(idea,form,title,leader) == 4,"remix changes all available controls")
 _check(idea.selected == 1 and form.selected == 1 and title.selected == 1 and leader.selected == 1,"remix synchronizes selection")
 var empty := OptionButton.new()
 _check(not SongLab.advance(empty),"empty control safe")
 _check(not SongLab.can_commit(idea,form,title,empty),"block incomplete songwriting")
 var source := FileAccess.get_file_as_string("res://Scripts/career_hub.gd")
 _check(source.contains("EXPERIMENT  /  NO TIME COST"),"safe experimentation advertised")
 _check(source.contains("REMIX ALL FOUR CHOICES"),"remix action visible")
 _check(source.contains("SongLab.advance(experiment_control)"),"individual experiments connected")
 _check(source.contains("refresh_preview.call()"),"preview updated")
 _check(load("res://Scenes/CareerHub.tscn") != null,"career scene parses")
 if failures==0:
  print("V78 CREATIVE LAB TESTS PASSED")
 quit(0 if failures==0 else 1)
func _check(ok: bool,why: String) -> void:
 if not ok:
  failures+=1
  push_error("V78 CREATIVE LAB FAILURE: "+why)
