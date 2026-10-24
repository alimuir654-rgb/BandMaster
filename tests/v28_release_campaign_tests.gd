extends SceneTree
const Campaigns = preload("res://Scripts/release_campaigns.gd")
const Recording = preload("res://Scripts/recording_career.gd")
var failures := 0

func _initialize() -> void:
 var state := {"cash":250,"tour_day":10,"fans":12,"reputation":10,"press":3,"buzz":14,"readiness":70,"song_catalogue":[{"title":"A","quality":70},{"title":"B","quality":85}],"career_journal":[]}
 var record: Dictionary = Recording.record(state)
 _check(bool(record.get("ok",false)),"recording integration")
 if bool(record.get("ok",false)):
  var unreleased: Dictionary = record["state"]
  _check(Campaigns.options(unreleased,0).is_empty(),"no campaign before release")
  var released: Dictionary = Recording.release(unreleased,0)
  _check(bool(released.get("ok",false)),"release integration")
  if bool(released.get("ok",false)):
   var live: Dictionary = released["state"]
   var before := JSON.stringify(live)
   var options: Array = Campaigns.options(live,0)
   _check(options.size()==3,"three distinct campaigns")
   _check(bool(options[0]["enabled"]) and not bool(options[2]["enabled"]),"press gating")
   _check(JSON.stringify(live)==before,"previews do not mutate")
   var result: Dictionary = Campaigns.launch(live,0,"radio")
   _check(bool(result.get("ok",false)),"radio campaign")
   if bool(result.get("ok",false)):
    var after: Dictionary = result["state"]
    _check(int(after["tour_day"])==int(live["tour_day"])+1,"campaign consumes day")
    _check(int(after["cash"])==int(live["cash"])-20,"campaign expense")
    _check(int(after["fans"])>int(live["fans"]),"campaign gains fans")
    _check(not bool(Campaigns.launch(after,0,"radio").get("ok",false)),"one use per release")
    _check(bool(Campaigns.launch(after,0,"launch_show").get("ok",false)),"other campaigns still allowed")
    _check(JSON.parse_string(JSON.stringify(after)) is Dictionary,"campaign JSON save")
 _check(Campaigns.options({},0).is_empty(),"legacy saves without releases")
 _check(not bool(Campaigns.launch({},0,"radio").get("ok",false)),"invalid release rejected")
 _check(Campaigns.next_milestone({"fans":0,"reputation":0})["name"]=="LOCAL FOLLOWING","first career tier")
 _check(Campaigns.next_milestone({"fans":999,"reputation":99})["name"]=="ESTABLISHED CIRCUIT","end career tier")
 if failures==0:
  print("V28 RELEASE CAMPAIGN TESTS PASSED")
 quit(0 if failures==0 else 1)

func _check(ok: bool, description: String) -> void:
 if not ok:
  failures+=1
  push_error("V28 CAMPAIGN FAILURE: "+description)
