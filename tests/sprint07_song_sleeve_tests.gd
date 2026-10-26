extends SceneTree
const Sleeve = preload("res://Scripts/song_sleeve.gd")
var failures := 0

func _initialize() -> void:
 call_deferred("_run")

func _run() -> void:
 var legacy := {"title":"EARLY DAYS","writers":["Alex","Sam"]}
 var before := JSON.stringify(legacy)
 var old: Dictionary = Sleeve.describe(legacy,1)
 _check(old["credits"] == "WRITERS: Alex, Sam","legacy writer credits retained")
 _check(old["notes"].is_empty(),"missing writing sessions are not invented")
 _check(old["day"] == "FINISH DATE NOT RECORDED","missing completion date is explicit")
 _check(old["quality"] == "QUALITY NOT RECORDED","missing quality is explicit")
 _check(JSON.stringify(legacy) == before,"presentation never mutates legacy song")
 var song := {
  "title":"NEON ON THE PLATFORM","lead_writer":"Lee",
  "credited_writers":["Lee","Jo"],"origin":"Riff","arrangement":"Slow Build",
  "quality":78,"written_day":9,
  "writing_sessions":[{"day":3,"leader":"Jo","idea":"Riff","form":"Loose Jam"},{"day":6,"leader":"Lee","idea":"Lyric","form":"Slow Build"}]
 }
 before = JSON.stringify(song)
 var info: Dictionary = Sleeve.describe(song,2)
 _check(info["title"] == "NEON ON THE PLATFORM" and info["number"] == 2,"real title and sequence")
 _check(info["credits"] == "CREDIT: Lee, Jo","resolved credit displayed over lead writer")
 _check(info["notes"].size() == 2 and str(info["notes"][0]).contains("DAY 3") and str(info["notes"][1]).contains("Lee"),"only recorded sessions displayed")
 _check(info["quality"] == "QUALITY 78 / 100" and info["day"] == "FINISHED DAY 9","recorded quality and finish day")
 _check(JSON.stringify(song) == before,"presentation never mutates finished song")
 var root := Control.new()
 get_root().add_child(root)
 var artifact := Sleeve.build(root,song,2,"indie")
 await process_frame
 _check(artifact.name == "SongSleeveArtifact","reusable sleeve built")
 _check(artifact.find_child("SongSleeveIcon",true,false) != null,"licensed Lucide notebook icon used")
 _check(artifact.find_child("SongSleeveArt",true,false) != null,"existing studio artwork used, not missing photos")
 _check(_has_text(artifact,"NEON ON THE PLATFORM") and _has_text(artifact,"CREDIT: Lee, Jo"),"live catalogue text in artifact")
 root.free()
 if failures == 0:
  print("SPRINT 07 SONG SLEEVE TESTS PASSED")
 quit(0 if failures == 0 else 1)

func _has_text(root: Node, needle: String) -> bool:
 if root is Label and str(root.text).contains(needle):
  return true
 for child in root.get_children():
  if _has_text(child,needle):
   return true
 return false

func _check(ok: bool, why: String) -> void:
 if not ok:
  failures += 1
  push_error("SPRINT 07 SLEEVE FAILURE: "+why)
