extends SceneTree
const Replies = preload("res://Scripts/band_conversation_replies.gd")
var failures := 0
func _initialize() -> void:
 var original := {"tour_day":8,"members":[{"name":"Alex","candidate_id":"alex","loyalty":44,"morale":53}]}
 _check(Replies.options(original,0).size()==3,"three choices")
 _check(Replies.options(original,3).is_empty(),"invalid member guarded")
 var result := Replies.respond(original,0,"support")
 _check(bool(result.get("ok",false)),"support reply succeeds")
 if bool(result.get("ok",false)):
  var after: Dictionary = result["state"]
  _check(int(after["tour_day"])==8,"no day passes")
  _check(int(after["members"][0]["loyalty"])==46,"loyalty reward applied")
  _check(int(after["members"][0]["morale"])==54,"morale reward applied")
  _check(original["members"][0]["loyalty"]==44,"original unchanged")
  _check(Replies.options(after,0).is_empty(),"daily response capped")
  _check(not bool(Replies.respond(after,0,"plan").get("ok",true)),"repeat blocked")
  after["tour_day"]=9
  _check(Replies.options(after,0).size()==3,"new day resets")
 _check(not bool(Replies.respond(original,0,"unknown").get("ok",true)),"invalid reply blocked")
 var source := FileAccess.get_file_as_string("res://Scripts/career_hub.gd")
 _check(source.contains("func _reply_to_musician("),"gameplay wired")
 _check(source.contains("BandReplies.options(_state(),speaker_index)"),"UI shows available responses")
 _check(load("res://Scenes/CareerHub.tscn") != null,"career hub imports")
 if failures==0:
  print("V113 CONVERSATION REPLIES PASSED")
 quit(0 if failures==0 else 1)
func _check(ok: bool,reason: String) -> void:
 if not ok:
  failures+=1
  push_error("V113 REPLY FAILURE: "+reason)
