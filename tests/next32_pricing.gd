extends SceneTree
const Owner=preload("res://experiments/playable_flightcase/opening_state.gd")
const Game=preload("res://experiments/playable_flightcase/session.gd")
const Pricing=preload("res://experiments/playable_flightcase/recruitment_pricing.gd")
const Encounter=preload("res://experiments/playable_flightcase/audition_encounter.gd")
var checks:=0
var failures: Array=[]
func _init() -> void:call_deferred("run")
func check(ok: bool,label: String) -> bool:
 checks+=1
 if not ok:failures.append(label);push_error(label)
 return ok
func fresh(legacy: bool=false):
 var owner=Owner.new()
 check(owner.begin_new() and owner.set_genre("Indie rock") and owner.to_recruit(),"new recruit entry")
 if legacy:
  var raw: Dictionary=owner.snapshot();raw.game.erase(Pricing.KEY)
  check(owner.restore(raw) and owner.save_draft(),"genuine missing-policy legacy entry")
 return owner
func finish_band(owner,voice: String) -> bool:
 return owner.choose_vocal(voice).ok and owner.confirm_lineup(true).ok and owner.submit_name("QA BUDGET BAND","Raw").ok and owner.lock_name(true).ok and owner.set_identity("Wordmark","Amber / Charcoal","Unpolished") and owner.finish_identity().ok and owner.start_playing()
func run() -> void:
 for trio in [["cast_bex","cast_ben","cast_casey"],["cast_ryan","cast_hannah","cast_ellis"],["cast_tom","cast_zoe","cast_marcus"]]:
  var o=fresh()
  for id in trio:check(o.recruit(id).ok,"recruit exact 200 tradeoff "+id)
  var expected: int=195
  check(o.game.spent()==expected and finish_band(o,trio[0]) and o.remaining()==0,"exact 200 including instrumental voice")
  var copy=Owner.new();check(copy.load_draft() and copy.snapshot()==o.snapshot(),"exact 200 formation strict reload")
 var top=fresh()
 check(top.recruit("cast_bex").ok and top.recruit("cast_hannah").ok,"two standout musicians can use budget")
 var unchanged: Dictionary=top.snapshot()
 check(not top.recruit("cast_marcus").ok and top.snapshot()==unchanged,"all-top third rejected without change")
 var six=fresh()
 for id in ["cast_ellis","cast_dan","cast_ben","cast_freya","cast_nina","cast_tom"]:check(six.recruit(id).ok,"new 198 six-person real recruitment "+id)
 check(six.game.spent()==198 and finish_band(six,"cast_nina"),"198 six-person passes actual launch despite legacy 204")
 var reloaded=Owner.new();check(reloaded.load_draft() and six.game._restore_integral_numbers(reloaded.snapshot())==six.game._restore_integral_numbers(six.snapshot()),"198 six-person full semantic disk roundtrip (JSON integral floats normalized)")
 # A missing policy remains missing across recruitment, active audition, receipt and save/reload.
 var old=fresh(true)
 check(not old.snapshot().game.has(Pricing.KEY),"legacy serialization absent marker")
 check(old.begin_audition("cast_jack","Guitarist",true).ok,"legacy canonical audition")
 var active: Dictionary=old.snapshot()
 var copy=Owner.new();check(copy.restore(active) and copy.snapshot()==active and not Encounter.validate(active).held,"legacy active fingerprint unchanged")
 check(old.audition_action("request",old.audition_expected(),"own_part").ok and old.resolve_audition_response("invite",old.audition_expected()).ok,"legacy original invite pipeline")
 check(old.game.spent()==33 and old.remaining()==167,"legacy Jack charged original33")
 var receipt: Dictionary=old.snapshot()
 check(copy.restore(receipt) and copy.snapshot()==receipt and not Encounter.validate(receipt).held,"legacy completed receipt untouched")
 check(old.recruit("cast_zoe").ok and old.recruit("cast_casey").ok and finish_band(old,"cast_jack"),"legacy formed unchanged")
 check(not old.snapshot().game.has(Pricing.KEY) and old.remaining()==88,"legacy final talent unchanged")
 var stable: Dictionary=old.snapshot()
 for invalid in ["future",4,null]:
  var raw: Dictionary=stable.duplicate(true);raw.game[Pricing.KEY]=invalid
  check(not old.restore(raw) and old.snapshot()==stable,"unknown policy safely rejected")
 var blocker: String=ProjectSettings.globalize_path(Owner.SAVE_PATH+".identity-tmp")
 check(DirAccess.make_dir_recursive_absolute(blocker)==OK,"inject new-game save failure")
 check(not old.begin_new() and old.snapshot()==stable and not old.snapshot().game.has(Pricing.KEY),"failed new game restores legacy absent policy")
 check(DirAccess.remove_absolute(blocker)==OK,"remove isolated failure blocker")
 var current=fresh()
 check(current.begin_audition("cast_jack","Guitarist",true).ok and current.audition_action("request",current.audition_expected(),"own_part").ok,"new policy canonical audition")
 check(DirAccess.make_dir_recursive_absolute(blocker)==OK,"inject invite save failure")
 unchanged=current.snapshot()
 check(not current.resolve_audition_response("invite",current.audition_expected()).ok and current.snapshot()==unchanged,"new quote receipt failure atomic")
 check(DirAccess.remove_absolute(blocker)==OK,"remove invite blocker")
 check(current.resolve_audition_response("invite",current.audition_expected()).ok and current.game.spent()==50,"new invite charges50")
 check(not Encounter.validate(current.snapshot()).held,"new actual receipt validates")
 var token: Dictionary=current.audition_expected();unchanged=current.snapshot()
 check(not current.resolve_audition_response("invite",token).ok and current.snapshot()==unchanged,"no repeat invite charge")
 check(current.recruit("cast_ben").ok and current.game.spent()==80 and current.remove_member("cast_jack").ok and current.game.spent()==30,"refund uses same versioned policy")
 var g=Game.new()
 check(not g.snapshot().has(Pricing.KEY),"direct legacy Session unchanged")
 for id in ["alex","nia_griffiths"]:
  var person: Dictionary=g.person_by_id(id)
  check(not person.is_empty() and Pricing.cost(person,Pricing.CURRENT)>0,"vendor priced fallback "+id)
 print("NEXT32_PRICING "+JSON.stringify({"checks":checks,"failures":failures}))
 quit(0 if failures.is_empty() else 1)
