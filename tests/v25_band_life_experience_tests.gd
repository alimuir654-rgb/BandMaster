extends SceneTree
const Experience = preload("res://Scripts/band_life_experience.gd")
const Social = preload("res://Scripts/band_social.gd")
const Practice = preload("res://Scripts/practice_room.gd")
const Members = preload("res://Scripts/member_management.gd")
var failures := 0
func _initialize() -> void:
 var state := {"cash":120,"tour_day":3,"morale":55,"tension":25,"readiness":50,"buzz":0,"members":[{"name":"Jo","morale":55,"loyalty":55,"fatigue":75},{"name":"Alex","morale":65,"loyalty":65,"fatigue":10}],"relationships":{"0_1":50}}
 var original := JSON.stringify(state)
 var outings: Array = Experience.social_options(state)
 _check(outings.size()==3,"three social experiences")
 _check(int(outings[0]["cost"])==16 and bool(outings[0]["enabled"]),"dinner cost for active members")
 _check(str(Experience.day_context(state)["title"])=="THE BAND NEEDS BREATHING ROOM","fatigue context")
 var played: Dictionary = Social.attend(state,"dinner")
 _check(bool(played.get("ok",false)),"existing social engine works")
 if bool(played.get("ok",false)):
  _check(int(played["state"].get("tour_day",0))==4,"social action spends a day")
  _check(int(played["state"].get("relationships",{}).get("0_1",0))==55,"bond persists")
 var practices: Array = Experience.practice_options(state)
 _check(practices.size()==2,"practice paths")
 var drilled: Dictionary = Practice.resolve(state,"tighten")
 _check(bool(drilled.get("ok",false)),"practice engine unchanged")
 var choices: Array = Experience.member_options(state,0)
 _check(choices.size()==3 and int(choices[1]["cost"])==10,"member costs grounded")
 var spoken: Dictionary = Members.resolve(state,0,"chat")
 _check(bool(spoken.get("ok",false)) and int(spoken.get("state",{}).get("tour_day",0))==4,"member decision remains playable")
 _check(JSON.stringify(state)==original,"previews and actions never mutate source")
 var away := state.duplicate(true)
 away["members"][1]["life_status"]="away"
 _check(int(Experience.social_options(away)[0]["cost"])==8 and not bool(Experience.social_options(away)[0]["enabled"]),"unavailable members cannot attend")
 _check(Experience.member_options(away,1).all(func(item): return not bool(item["enabled"])),"away member choices disabled")
 if failures==0:
  print("V25 BAND LIFE EXPERIENCE TESTS PASSED")
 quit(0 if failures==0 else 1)
func _check(ok: bool, detail: String) -> void:
 if not ok:
  failures+=1
  push_error("V25 BAND LIFE FAILURE: "+detail)
