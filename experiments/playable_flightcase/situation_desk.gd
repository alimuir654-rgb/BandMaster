extends RefCounted
## Player-recorded context, separate from the approved musical biographies.
const Core = preload("res://experiments/playable_flightcase/situation_core.gd")
const Cast = preload("res://experiments/character_cast/catalogue.gd")
const Week = preload("res://experiments/playable_flightcase/band_week.gd")
const Dates = preload("res://experiments/playable_flightcase/career_dates.gd")

static func _week(host, parent: Node, compact: bool) -> void:
 var body: VBoxContainer=host._paper(parent,compact)
 body.name="WeekAgreementPaper"
 var offer: Dictionary=Week.offer(host.game.career)
 host._copy(body,"OUR WORKING WEEK",24).name="WeekAgreementTitle"
 if not offer.ok:
  host._copy(body,str(offer.message),16).name="WeekAgreementNotice"
  return
 host._copy(body,"PROPOSED · NOT SAVED" if offer.changed else "RECORDED PATTERNS + DATES",18).name="WeekAgreementStatus"
 if not host.notice.is_empty():host._copy(body,host.notice,16).name="WeekSaveNotice"
 for row in Core.members(host.game.career):
  if row.id==host.situation_member_id and str(row.kind)!=host.situation_kind:host._copy(body,"Save your selected context below before agreeing the week, or select its recorded context again.",16).name="WeekLocalContextNotice"
 if offer.changed:
  host._copy(body,"Agree the band's writing and rehearsal evenings. These proposed work patterns are new arrangements; existing recorded circumstances stay as they are.",16)
  host._copy(body,"Career DAY 1: Monday 9 November 2026." if not Dates.inspect(host.game.career).exists else "Your saved career start date is retained.",16).name="WeekDateProposal"
 for row in offer.rows:
  host._copy(body,str(row.name)+" · "+str(row.work),18).name="WeekMember_"+str(row.id)
  host._copy(body,str(row.text),16).name="WeekPattern_"+str(row.id)
 if not offer.changed:
  host._copy(body,Dates.caption(host.game.career,int(host.game.career.tour_day)),16)
  body.add_child(host._button("VIEW OUR CALENDAR ›","WeekCalendarAction",host._navigate.bind("calendar")))

static func render(host, parent: Node, compact: bool) -> void:
 var checked: Dictionary=Core.validate(host.game.career)
 _week(host,parent,compact)
 var body: VBoxContainer=host._paper(parent,compact)
 host._copy(body,"LIFE OUTSIDE THE BAND",24)
 host._copy(body,"Record what you know. These career notes do not rewrite a musician's original biography. Personal money is not simulated.",16)
 if not checked.ok:
  host._copy(body,str(checked.message),16)
  return
 var rows: Array=Core.members(host.game.career)
 var selected: Dictionary={}
 var members:=GridContainer.new()
 members.columns=1 if compact else 3
 members.size_flags_horizontal=Control.SIZE_EXPAND_FILL
 body.add_child(members)
 for row in rows:
  if row.id==host.situation_member_id:selected=row
  var button: Button=host._button(str(row.name),"SituationMember_"+str(row.id),host._situation_pick_member.bind(str(row.id)))
  button.disabled=host.busy or not row.editable
  members.add_child(button)
 if selected.is_empty():return
 var source: Dictionary=Cast.by_id(str(selected.id))
 var portrait: String=str(source.get("portrait_preview",""))
 var profile:=HBoxContainer.new()
 profile.add_theme_constant_override("separation",12)
 body.add_child(profile)
 if not portrait.is_empty() and ResourceLoader.exists(portrait):
  var photo:=TextureRect.new()
  photo.texture=load(portrait)
  photo.custom_minimum_size=Vector2(72,76)
  photo.expand_mode=TextureRect.EXPAND_IGNORE_SIZE
  photo.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED
  photo.mouse_filter=Control.MOUSE_FILTER_IGNORE
  profile.add_child(photo)
 host._copy(profile,str(selected.name),22)
 var current: Label=host._copy(body,Core.context_text(selected,int(host.game.career.tour_day)),16)
 current.name="SituationRecordedContext"
 host._copy(body,"CHOOSE THE CONTEXT YOU WANT TO RECORD",16)
 var choices:=GridContainer.new()
 choices.columns=2
 choices.size_flags_horizontal=Control.SIZE_EXPAND_FILL
 choices.add_theme_constant_override("h_separation",6)
 choices.add_theme_constant_override("v_separation",6)
 body.add_child(choices)
 for entry in [["unknown","NOT RECORDED"],["day_job","DAY JOB"],["family_supported","FAMILY SUPPORT"],["flexible","FLEXIBLE"]]:
  var option: Button=host._button(str(entry[1]),"SituationContext_"+str(entry[0]),host._situation_pick_kind.bind(str(entry[0])))
  option.toggle_mode=true
  option.set_pressed_no_signal(host.situation_kind==entry[0])
  choices.add_child(option)
 var draft: Dictionary=selected.duplicate(true) if host.situation_kind==selected.kind else {"kind":host.situation_kind,"context":{"kind":host.situation_kind,"shift_anchor":int(host.game.career.tour_day)}}
 var description: Label=host._copy(body,Core.context_text(draft,int(host.game.career.tour_day)),16)
 description.name="SituationDraftContext"
 var save: Button=host._button("SAVE THIS CONTEXT","SituationSaveContextAction",host._situation_save)
 save.disabled=host.busy or host.situation_member_id.is_empty() or not checked.ok
 body.add_child(save)
 if not host.notice.is_empty():host._copy(body,host.notice,16).name="SituationNotice"
 var inspected: Dictionary=Core.inspect_rehearsal(host.game.career)
 if inspected.ok and not inspected.plan.is_empty():
  var plan: Label=host._copy(body,"REHEARSAL AGREEMENT • DAY %d EVENING • %s" % [int(inspected.plan.day),str(inspected.plan_status).to_upper()],16)
  plan.name="SituationPlan"
  host._copy(body,"The room fee and day are used only when you rehearse. Return on the agreed day; other activities can advance the calendar.",16)
 var core: Dictionary=checked.core
 if not core.attendance_history.is_empty():
  var latest: Dictionary=core.attendance_history[-1]
  host._copy(body,"LAST REHEARSAL • DAY %d" % int(latest.day),16)
  host._copy(body,str(latest.get("message","Attendance was recorded.")),16).name="SituationAttendanceHistory"
 if not str(source.get("story","")).is_empty():
  host._copy(body,"ORIGINAL MUSICAL BIOGRAPHY",16)
  host._copy(body,str(source.story),16).name="SituationOriginalBiography"

static func dock(host, parent: Node) -> void:
 var offer: Dictionary=Week.offer(host.game.career)
 if offer.ok and offer.changed:
  var expected: Dictionary=host.opening_owner.snapshot().duplicate(true)
  var agree: Button=host._button("AGREE OUR WEEK · FREE","WeekAgreementAction",host._agree_band_week.bind(expected),true)
  for row in Core.members(host.game.career):
   if row.id==host.situation_member_id and str(row.kind)!=host.situation_kind:agree.disabled=true
  parent.add_child(agree)
 elif offer.ok:
  var agreed: Button=host._button("WEEK AGREED","WeekAgreementAction",func():pass,true)
  agreed.disabled=true
  parent.add_child(agreed)
 parent.add_child(host._button("BACK TO BAND","SituationBackAction",host._navigate.bind("band")))
