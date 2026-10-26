extends SceneTree
# Authored credit dispute only when real songwriting sessions identify two contributors.
const Drama = preload("res://Scripts/band_drama.gd")
const Songbook = preload("res://Scripts/songbook_presentation.gd")
var failures := 0

func _initialize() -> void:
 var state := _fixture()
 var original := JSON.stringify(state)
 var cases: Array = Drama.pair_pending(state)
 _check(cases.size() == 1,"actual co-written song creates one priority case")
 if cases.is_empty():
  quit(1)
  return
 var incident: Dictionary = cases[0]
 _check(str(incident.get("kind","")) == "song_credit","song credit incident selected")
 _check(str(incident.get("intro","")).contains("NEON ON THE PLATFORM"),"song title comes from real catalogue")
 _check(str(incident.get("first","")) == "Lee" and str(incident.get("second","")) == "Jo","real lead writer speaks first even when roster order reversed")
 _check(int(incident.get("first_index",-1)) == 1 and int(incident.get("second_index",-1)) == 0,"actual roster indices preserved")
 _check(not bool(Drama.resolve_pair(state,str(incident["id"]),"made-up").get("ok",true)),"invalid choice cannot spend a day")
 var shared: Dictionary = Drama.resolve_pair(state,str(incident["id"]),"share")
 _check(bool(shared.get("ok",false)),"shared credit resolves")
 if not bool(shared.get("ok",false)):
  quit(1)
  return
 var next: Dictionary = shared["state"]
 _check(int(next.get("tour_day",0)) == 8,"credit conversation costs one day")
 _check(int(next["relationships"]["0_1"]) == 50,"specific pair trust improves")
 _check(int(next["relationships"]["0_2"]) == 85,"unrelated pair unaffected")
 _check(int(next["members"][0]["loyalty"]) == 65 and int(next["members"][1]["loyalty"]) == 63,"individual consequences follow lead and contributor roles")
 _check(str(next["song_catalogue"][0].get("lead_writer","")) == "Lee","original session lead remains documented")
 _check(next["song_catalogue"][0].get("credited_writers",[]) == ["Lee","Jo"],"song now credits both actual contributors")
 _check(str(next["song_catalogue"][0].get("credit_resolution",{}).get("choice","")) == "share","song records choice")
 _check(str(next["career_journal"].back().get("song_title","")) == "NEON ON THE PLATFORM","keepsake records real song")
 _check(next["career_journal"].back().get("credited_writers",[]) == ["Lee","Jo"],"keepsake matches official credit")
 _check(str(Songbook.entries(next)[0]["writer"]) == "CREDIT: Lee, Jo","songbook displays actual updated credit")
 _check(JSON.stringify(state) == original,"input state immutable")
 _check(not bool(Drama.resolve_pair(next,str(incident["id"]),"lead").get("ok",true)),"cannot reverse settled credit for reward")
 var persisted = JSON.parse_string(JSON.stringify(next))
 _check(persisted is Dictionary and persisted["song_catalogue"][0].get("credited_writers",[]) == ["Lee","Jo"],"JSON reload retains credits")
 if persisted is Dictionary:
  _check(not bool(Drama.resolve_pair(persisted,str(incident["id"]),"share").get("ok",true)),"reload blocks duplicate payout")
 var sole := Drama.resolve_pair(state,str(incident["id"]),"lead")
 _check(bool(sole.get("ok",false)),"lead-only choice resolves")
 if bool(sole.get("ok",false)):
  _check(sole["state"]["song_catalogue"][0].get("credited_writers",[]) == ["Lee"],"lead-only choice writes one credit")
  _check(int(sole["state"]["relationships"]["0_1"]) == 28,"lead-only choice strains pair trust")
 var old := _fixture()
 old.erase("song_catalogue")
 _check(Drama.pair_pending(old).is_empty(),"old save with no song history invents no credit case")
 var missing := _fixture()
 missing["song_catalogue"][0].erase("writing_sessions")
 _check(Drama.pair_pending(missing).is_empty(),"song without writing provenance invents no collaborator")
 var same := _fixture()
 same["song_catalogue"][0]["writing_sessions"] = [{"leader":"Lee","day":3}]
 _check(Drama.pair_pending(same).is_empty(),"solo-written song cannot trigger shared-credit case")
 var unavailable := _fixture()
 unavailable["members"][0]["life_status"] = "unavailable"
 _check(Drama.pair_pending(unavailable).is_empty(),"inactive collaborator cannot enter dispute")
 var already := _fixture()
 already["song_catalogue"][0]["credit_resolution"] = {"choice":"share"}
 _check(Drama.pair_pending(already).is_empty(),"already settled song cannot repeat")
 var next_song := next.duplicate(true)
 next_song["song_catalogue"].append({"title":"THE NEXT SONG","lead_writer":"Lee","writing_sessions":[{"leader":"Jo","day":8},{"leader":"Lee","day":9}]})
 _check(not Drama.pair_pending(next_song).is_empty() and str(Drama.pair_pending(next_song)[0]["id"]) != str(incident["id"]),"same musicians can resolve a different real song")
 var legacy := _fixture()
 legacy["members"][0].erase("candidate_id")
 legacy["members"][1].erase("candidate_id")
 _check(not Drama.pair_pending(legacy).is_empty(),"legacy member IDs use existing safe fallback")
 if failures == 0:
  print("SPRINT 05 SONG CREDIT TESTS PASSED")
 quit(0 if failures == 0 else 1)

func _fixture() -> Dictionary:
 return {
  "tour_day":7,"cash":180,"songs":1,"tension":22,"morale":55,"readiness":60,
  "members":[
   {"name":"Jo","candidate_id":"jo-001","role":"Guitarist","life_status":"active","fatigue":18,"loyalty":60,"morale":60},
   {"name":"Lee","candidate_id":"lee-002","role":"Drummer","life_status":"active","fatigue":15,"loyalty":60,"morale":60},
   {"name":"Kit","candidate_id":"kit-003","role":"Vocalist","life_status":"active","fatigue":12,"loyalty":70,"morale":68}
  ],
  "relationships":{"0_1":38,"0_2":85,"1_2":84},
  "song_catalogue":[{"title":"NEON ON THE PLATFORM","lead_writer":"Lee","quality":72,"arrangement":"Slow Build","writing_sessions":[{"leader":"Jo","day":3},{"leader":"Lee","day":4}]}],
  "band_drama_resolved":{},"career_journal":[]
 }

func _check(ok: bool,reason: String) -> void:
 if not ok:
  failures += 1
  push_error("SONG CREDIT FAILURE: "+reason)
