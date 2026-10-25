extends SceneTree
const Incident = preload("res://Scripts/gig_backstage_incident.gd")
var failures := 0
func _initialize() -> void:
 var state := {"tour_day":15,"gig_night_phase":"soundcheck","booked_show":{"day":15,"venue_id":"local"},"members":[{"name":"Sam","role":"Bassist","fatigue":75,"morale":55}],"morale":60,"readiness":85}
 var context := Incident.incident(state)
 _check(context.get("name","")=="Sam","tired bassist triggers incident")
 _check(context.get("options",[]).size()==3,"three distinct interventions")
 var result := Incident.resolve(state,"rest")
 _check(bool(result.get("ok",false)),"support decision succeeds")
 if bool(result.get("ok",false)):
  var after: Dictionary = result["state"]
  _check(after["tour_day"]==15,"incident does not spend day")
  _check(after["members"][0]["fatigue"]==63,"rest lowers fatigue")
  _check(after["morale"]==64,"support raises morale")
  _check(Incident.incident(after).is_empty(),"cannot repeat same booking")
  _check(not bool(Incident.resolve(after,"push").get("ok",true)),"duplicate blocked")
 _check(state["members"][0]["fatigue"]==75,"input not mutated")
 _check(not bool(Incident.resolve(state,"invalid").get("ok",true)),"invalid reply rejected")
 var source := FileAccess.get_file_as_string("res://Scripts/career_hub.gd")
 _check(source.contains("indicator.autowrap_mode = TextServer.AUTOWRAP_OFF"),"countdown stays horizontal")
 _check(source.contains("BackstageIncident.incident(_state())"),"soundcheck incident present")
 _check(source.contains('source.begins_with("gig:")'),"stage image only for gigs")
 _check(source.contains('tween_property(stage_image,"modulate:a",1.0,0.8)'),"stage image fades in")
 _check(load("res://Scenes/CareerHub.tscn") != null,"career scene imports")
 if failures==0:
  print("V117 GIG FEEDBACK PASSED")
 quit(0 if failures==0 else 1)
func _check(ok: bool,reason: String) -> void:
 if not ok:
  failures+=1
  push_error("V117 FAILURE: "+reason)
