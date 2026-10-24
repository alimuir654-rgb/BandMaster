extends SceneTree

const Actions = preload("res://Scripts/career_actions.gd")
const Gigs = preload("res://Scripts/uk_gig_circuit.gd")
const GearShop = preload("res://Scripts/gear_shop.gd")
const Members = preload("res://Scripts/member_management.gd")
const Opportunities = preload("res://Scripts/career_opportunities.gd")

func _initialize() -> void:
 var state := {"cash": 120, "tour_day": 5, "morale": 55, "tension": 10, "readiness": 65, "van_health": 80, "reputation": 25, "fans": 20, "songs": 0, "buzz": 0, "press": 0}
 var action: Dictionary = Actions.resolve(state, "songwrite")
 _check(action.get("ok",false) == true, "writing should succeed")
 _check(int(action["state"]["songs"]) == 1, "song count increments")
 _check(int(state["songs"]) == 0, "original state stays immutable")
 var poor := state.duplicate(true)
 poor["cash"] = 0
 _check(Actions.resolve(poor,"buy_gear").get("ok",true) == false, "poor band cannot buy equipment")
 var gig: Dictionary = Gigs.play(state,"local")
 _check(gig.get("ok",false) == true, "hometown gigs remain available")
 _check(int(gig["state"]["fans"]) > 20, "successful local gig gains fans")
 poor["van_health"] = 0
 _check(Gigs.play(poor,"local").get("ok",false) == true, "local gigs recover zero-cash zero-van")
 _check(Gigs.play(state,"london").get("ok",true) == false, "locked London gig is unavailable")
 var opportunity := state.duplicate(true)
 opportunity["opportunities_seen"] = {"demo_ready":true}
 opportunity["opportunities_resolved"] = {}
 _check(Opportunities.pending(opportunity).has("demo_ready"), "demo event is queued")
 var demo: Dictionary = Opportunities.resolve(opportunity,"demo_ready","record")
 _check(demo.get("ok",false) == true, "demo can be recorded")
 _check(not Opportunities.pending(demo["state"]).has("demo_ready"), "demo cannot repeat")
 _check(Opportunities.resolve(demo["state"],"demo_ready","record").get("ok",true) == false, "duplicate resolution rejected")
 var purchase: Dictionary = GearShop.buy(state,"amp")
 _check(purchase.get("ok",false) == true, "buy named amplifier")
 _check(purchase["state"]["owned_equipment"].has("amp"), "inventory persists in resolved state")
 _check(GearShop.buy(purchase["state"],"amp").get("ok",true) == false, "prevent repeat purchase")
 _check(GearShop.buy(poor,"pa").get("ok",true) == false, "prevent unaffordable gear")
 var approach_state := state.duplicate(true)
 var safe_gig: Dictionary = Gigs.play(approach_state,"local","tight")
 var wild_gig: Dictionary = Gigs.play(approach_state,"local","wild")
 _check(safe_gig.get("ok",false) == true and wild_gig.get("ok",false) == true, "gig approaches resolve")
 _check(Gigs.play(approach_state,"local","unrecognised").get("ok",true) == false,"invalid approach fails")
 _check(int(safe_gig["state"]["tension"]) != int(wild_gig["state"]["tension"]), "approach matters")
 var member_state := {"members":[{"name":"Sam","morale":40,"loyalty":40,"skill":30,"fatigue":20}],"relationships":{},"cash":50,"tour_day":5,"readiness":25,"tension":30}
 var coach: Dictionary = Members.resolve(member_state,0,"coach")
 _check(coach.get("ok",false) == true,"coaching succeeds")
 _check(int(coach["state"]["members"][0]["skill"]) > 30,"coaching raises skill")
 _check(int(member_state["members"][0]["skill"]) == 30,"member source stays unmodified")
 _check(Members.resolve(member_state,5,"coach").get("ok",true) == false,"invalid member blocked")
 print("CAREER REGRESSION TESTS PASSED")
 quit(0)

func _check(condition: bool, detail: String) -> void:
 if not condition:
  push_error("REGRESSION FAILURE: " + detail)
  quit(1)
