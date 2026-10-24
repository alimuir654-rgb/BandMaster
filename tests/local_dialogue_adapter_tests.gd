extends SceneTree
const Adapter = preload("res://Scripts/local_dialogue_adapter.gd")
var failures := 0
func _initialize() -> void:
 var state := {"tour_day":12,"members":[{"name":"Jo","role":"Guitarist","trait":"Creative","morale":55,"loyalty":70,"fatigue":20}],"cash":99,"career_journal":[{"title":"First gig","day":4},{"title":"New song","day":6}]}
 var payload: Dictionary = Adapter.request_payload(state,0)
 _check(payload.get("stream",true) == false,"stream disabled")
 _check(payload.has("messages") and payload["messages"].size() == 2,"bounded prompt created")
 _check(not JSON.stringify(payload).contains("99"),"sensitive cash excluded")
 _check(Adapter.request_payload(state,8).is_empty(),"unknown musician rejected")
 var good := JSON.stringify({"message":{"content":JSON.stringify({"dialogue":"I'd like to rehearse that chorus."})}})
 _check(Adapter.validated_text(good) == "I'd like to rehearse that chorus.","valid dialogue extracted")
 var invalid := JSON.stringify({"message":{"content":JSON.stringify({"dialogue":"http://example.org"})}})
 _check(Adapter.validated_text(invalid).is_empty(),"URLs rejected")
 _check(Adapter.validated_text("{}").is_empty(),"missing fields rejected")
 _check(Adapter.validated_text("bad json").is_empty(),"bad json rejected")
 var too_long := JSON.stringify({"message":{"content":JSON.stringify({"dialogue":"a".repeat(400)})}})
 _check(Adapter.validated_text(too_long).is_empty(),"long text rejected")
 _check(state["members"][0]["loyalty"] == 70,"source remains unchanged")
 if failures == 0:
  print("LOCAL DIALOGUE ADAPTER TESTS PASSED")
 quit(0 if failures == 0 else 1)
func _check(ok: bool, description: String) -> void:
 if not ok:
  failures += 1
  push_error("LOCAL DIALOGUE FAILURE: "+description)
