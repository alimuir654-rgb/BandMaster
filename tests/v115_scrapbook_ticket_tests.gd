extends SceneTree
var failures := 0
func _initialize() -> void:
 var source := FileAccess.get_file_as_string("res://Scripts/career_hub.gd")
 _check(source.contains("func _scrapbook_gig_ticket(parent: Node, moment: Dictionary) -> void:"),"ticket visual component")
 _check(source.contains('if str(clipping["kind"]) == "gig":'),"only gigs use ticket design")
 _check(source.contains('image_path = "res://Art/Backgrounds/shared/gigs.webp"'),"fallback is available")
 _check(source.contains('int(moment.get("day",1))'),"date from real journal")
 _check(source.contains('str(moment.get("title","A NIGHT TO REMEMBER"))'),"ticket headline from journal")
 _check(source.contains('str(moment.get("text",""))'),"original journal copy preserved")
 _check(load("res://Scenes/CareerHub.tscn") != null,"career scene loads")
 if failures==0:
  print("V115 SCRAPBOOK TICKETS PASSED")
 quit(0 if failures==0 else 1)
func _check(ok: bool,reason: String) -> void:
 if not ok:
  failures+=1
  push_error("V115 SCRAPBOOK FAILURE: "+reason)
