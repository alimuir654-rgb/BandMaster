extends PanelContainer
## S40 read-only physical music-press recap. All values and names originate from
## the existing S38 resolver result and selected C25 cast, not new effects.
signal details_toggled
const Kit = preload("res://components/control_atlas/kit.gd")
const Cast = preload("res://experiments/character_cast/catalogue.gd")
const Recap = preload("res://experiments/playable_flightcase/rehearsal_recap.gd")
const InkNote = preload("res://experiments/playable_flightcase/ink_note.gd")
const Paper = preload("res://experiments/playable_flightcase/session_paper.gd")
const BandIcon = preload("res://experiments/playable_flightcase/art/icons/users.svg")
const JournalIcon = preload("res://experiments/playable_flightcase/art/icons/notebook-pen.svg")
const Shared = preload("res://experiments/playable_flightcase/career_components.gd")

func ink(value: String, points: int, muted: bool = false) -> Label:
 return Shared.paper_label(value,points,muted)

func configure(report: Dictionary, members: Array, mobile: bool, expanded_details: bool, tall_tablet: bool = false, short_landscape: bool = false, external_details: bool = false, fresh_notes: bool = false) -> void:
 for old in get_children():
  remove_child(old)
  old.queue_free()
 name = "RehearsalRecapPanel"
 size_flags_horizontal = Control.SIZE_EXPAND_FILL
 add_theme_stylebox_override("panel",Paper.sheet(mobile and not tall_tablet))
 var view: Dictionary = Recap.present(report,members)
 var content := VBoxContainer.new()
 content.name = "RecapEditorialBody"
 content.add_theme_constant_override("separation",4 if short_landscape else (10 if tall_tablet else (4 if mobile else 9)))
 add_child(content)
 if view.is_empty():
  content.add_child(ink("No saved session report available.",15))
  return
 var mast := ink(str(view.get("completed_heading","SESSION COMPLETE")),16,true)
 mast.name = "RecapCompletedDay"
 mast.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
 mast.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
 content.add_child(mast)
 var rule := ColorRect.new()
 rule.name = "RecapInkRule"
 rule.color = Color("69513d")
 rule.custom_minimum_size.y = 2.0
 rule.mouse_filter = Control.MOUSE_FILTER_IGNORE
 content.add_child(rule)
 var heading := ink(str(view.get("receipt","SAVED SESSION NOTES")),16,true)
 heading.name = "RecapDayReceipt"
 heading.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
 content.add_child(heading)
 var verdict := ink(str(view.get("verdict","SESSION COMPLETE")).to_upper(),28 if short_landscape else (32 if tall_tablet else (26 if mobile else 32)))
 verdict.name = "RecapVerdict"
 verdict.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
 content.add_child(verdict)
 var why: Label = InkNote.new()
 why.name = "RecapReasonNote"
 why.text = str(view.get("summary",view.get("reason","")))
 why.add_theme_font_size_override("font_size",16)
 why.add_theme_color_override("font_color",Color("695c4b"))
 if fresh_notes:
  why.visible_characters = 0
  why.set_meta("fresh_action_note",true)
 else:
  why.focus_mode = Control.FOCUS_NONE
  why.mouse_filter = Control.MOUSE_FILTER_IGNORE
 why.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
 content.add_child(why)
 var score := ink("SAVED CHANGES",16,true)
 score.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
 content.add_child(score)
 var metrics: Dictionary = {}
 for entry in view.get("metric_rows",[]):
  if entry is Dictionary:
   metrics[str(entry.get("key",""))] = entry
 var tiles: BoxContainer = VBoxContainer.new() if short_landscape else HBoxContainer.new()
 tiles.name = "RecapHeroMetrics"
 tiles.add_theme_constant_override("separation",10 if tall_tablet else (4 if mobile else 10))
 content.add_child(tiles)
 for selector in [["readiness","READINESS"],["morale","MORALE"],["tension","TENSION"]]:
  var key: String = str(selector[0])
  var item: Dictionary = metrics.get(key,{})
  var delta: int = int(item.get("delta",0))
  var tile := PanelContainer.new()
  tile.name = "RecapHeroTile_"+key
  tile.size_flags_horizontal = Control.SIZE_EXPAND_FILL
  tile.mouse_filter = Control.MOUSE_FILTER_IGNORE
  tile.focus_mode = Control.FOCUS_NONE
  tile.add_theme_stylebox_override("panel",Paper.scorecard())
  tiles.add_child(tile)
  var stack: BoxContainer = HBoxContainer.new() if short_landscape else VBoxContainer.new()
  stack.add_theme_constant_override("separation",8 if short_landscape else 1)
  tile.add_child(stack)
  var metric_copy: BoxContainer = stack
  if short_landscape:
   metric_copy=VBoxContainer.new()
   metric_copy.size_flags_horizontal=Control.SIZE_EXPAND_FILL
   metric_copy.add_theme_constant_override("separation",1)
   stack.add_child(metric_copy)
  var cap := ink(str(selector[1]).capitalize(),16,true)
  cap.autowrap_mode = TextServer.AUTOWRAP_OFF
  cap.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
  metric_copy.add_child(cap)
  var change := ink(Recap.signed_change(delta),20)
  change.name = "RecapHero_"+key
  change.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
  change.autowrap_mode = TextServer.AUTOWRAP_OFF
  if short_landscape:
   change.size_flags_horizontal=Control.SIZE_SHRINK_END
   change.vertical_alignment=VERTICAL_ALIGNMENT_CENTER
  var adverse: bool = (key=="tension" and delta>0) or (key!="tension" and delta<0)
  change.add_theme_color_override("font_color",Color("954a42") if adverse else (Color("376c58") if delta!=0 else Color("695c4b")))
  stack.add_child(change)
  var before_after := ink("%d → %d" % [int(item.get("before",0)),int(item.get("after",0))],13 if tall_tablet else 12,true)
  before_after.name = "RecapBeforeAfter_"+key
  before_after.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
  metric_copy.add_child(before_after)
 var voices: Array = view.get("reactions",[])
 var band_header := HBoxContainer.new()
 band_header.add_theme_constant_override("separation",4)
 content.add_child(band_header)
 var people_icon := TextureRect.new()
 people_icon.texture = BandIcon
 people_icon.custom_minimum_size = Vector2(20,20)
 people_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
 people_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
 people_icon.self_modulate = Color("695c4b")
 people_icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
 people_icon.focus_mode = Control.FOCUS_NONE
 band_header.add_child(people_icon)
 var band_caption := ink("FROM THE ROOM",14 if tall_tablet else (11 if mobile else 12),true)
 band_caption.size_flags_horizontal = Control.SIZE_EXPAND_FILL
 band_header.add_child(band_caption)
 if voices.size()>3 and mobile:
  var browse_hint := ink("SWIPE ›",12,true)
  browse_hint.name = "RecapBrowseHint"
  browse_hint.autowrap_mode = TextServer.AUTOWRAP_OFF
  browse_hint.size_flags_horizontal = Control.SIZE_SHRINK_END
  browse_hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
  band_header.add_child(browse_hint)
 var gallery := ScrollContainer.new()
 gallery.name = "RecapMemberGallery"
 gallery.follow_focus = true
 gallery.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
 gallery.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
 gallery.custom_minimum_size.y = 250 if tall_tablet else 210
 # The existing scrollbar is the keyboard route to offscreen bandmates.
 # Godot skips it in focus traversal when the entire roster already fits.
 gallery.get_h_scroll_bar().focus_mode = Control.FOCUS_ALL
 content.add_child(gallery)
 var strip := HBoxContainer.new()
 strip.name = "RecapPortraitRow"
 strip.alignment = BoxContainer.ALIGNMENT_CENTER
 strip.size_flags_horizontal = Control.SIZE_EXPAND_FILL
 strip.add_theme_constant_override("separation",12 if tall_tablet else (5 if mobile else 12))
 gallery.add_child(strip)
 for voice in voices:
  if not voice is Dictionary:
   continue
  var person_id: String = str(voice.get("candidate_id",""))
  var display_name: String = str(voice.get("name","Musician"))
  var card := VBoxContainer.new()
  card.name = "RecapPortraitCard_"+person_id
  card.custom_minimum_size.x = 180 if tall_tablet else (98 if mobile else 148)
  card.add_theme_constant_override("separation",2)
  strip.add_child(card)
  var source: Dictionary = Cast.by_id(person_id)
  var photo_path: String = str(source.get("portrait_preview",""))
  # This is the existing canonical legacy preview, not a substitute C25 face.
  # Other unknown identities retain an honest absent-photo state.
  if person_id=="nia_griffiths" and photo_path.is_empty():
   photo_path="res://experiments/art_material/portrait_preview/nia_griffiths_512x690.webp"
  if not photo_path.is_empty() and ResourceLoader.exists(photo_path):
   var photo := TextureRect.new()
   photo.name = "RecapPortrait_"+person_id
   photo.texture = load(photo_path)
   photo.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
   photo.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
   photo.custom_minimum_size = Vector2(156,160) if tall_tablet else Vector2(82 if mobile else 104,86 if mobile else 107)
   photo.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
   photo.mouse_filter = Control.MOUSE_FILTER_IGNORE
   photo.focus_mode = Control.FOCUS_NONE
   photo.tooltip_text = display_name+" — "+str(voice.get("quote",""))
   card.add_child(photo)
  else:
   var missing := ink("NO PHOTO",10,true)
   missing.custom_minimum_size.y = 70
   card.add_child(missing)
  var short_quote: String = str(voice.get("quote",""))
  if short_quote.length()>32:
   var excerpt: String = short_quote.substr(0,32)
   var word_break: int = excerpt.rfind(" ")
   short_quote = excerpt.substr(0,word_break if word_break>0 else 31).rstrip(" .,!?")+"…"
  var line: Label = InkNote.new()
  # A compact photo caption is printed. Full authored reactions below retain
  # the selected narrative note style; first-fold portraits/morale stay visible.
  line.set_meta("compact_note_caption",true)
  line.text = display_name+"\n“"+short_quote+"”"
  line.add_theme_font_size_override("font_size",16)
  line.add_theme_color_override("font_color",Color("29241f"))
  if fresh_notes:
   line.visible_characters = 0
   line.set_meta("fresh_action_note",true)
  else:
   line.focus_mode = Control.FOCUS_NONE
   line.mouse_filter = Control.MOUSE_FILTER_IGNORE
  line.name = "RecapMember_"+person_id
  line.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
  card.add_child(line)
  var personal_morale: int = 0
  for individual in report.get("member_changes",[]):
   if individual is Dictionary and str(individual.get("candidate_id",""))==person_id:
    personal_morale = int(individual.get("changes",{}).get("morale",{}).get("delta",0))
    break
  var morale_badge := ink("MORALE "+Recap.signed_change(personal_morale),16,true)
  morale_badge.autowrap_mode = TextServer.AUTOWRAP_OFF
  morale_badge.name = "RecapMood_"+person_id
  morale_badge.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
  morale_badge.add_theme_color_override("font_color",Color("954a42") if personal_morale<0 else (Color("376c58") if personal_morale>0 else Color("695c4b")))
  card.add_child(morale_badge)
  # Passive ink marker from the saved, signed personal morale change.
  # The existing number remains legible without colour; no new control or reward.
  var morale_ink := ColorRect.new()
  morale_ink.name = "RecapMoodStripe_"+person_id
  morale_ink.color = Color("954a42") if personal_morale < 0 else (Color("376c58") if personal_morale > 0 else Color("aa977c"))
  morale_ink.custom_minimum_size = Vector2(0.0,4.0)
  morale_ink.size_flags_horizontal = Control.SIZE_EXPAND_FILL
  morale_ink.mouse_filter = Control.MOUSE_FILTER_IGNORE
  morale_ink.focus_mode = Control.FOCUS_NONE
  card.add_child(morale_ink)
 # People lead the report. All three recorded deltas and their exact before/
 # after values follow as compact fields; the full record remains in Details.
 var people_at: int = why.get_index()
 content.move_child(band_header,people_at)
 content.move_child(gallery,people_at+1)
 if short_landscape:
  # The short-wide viewport needs a reading spread: bandmates lead on the
  # left, with all recorded deltas alongside rather than below the fold.
  var lane:=HBoxContainer.new()
  lane.name="RecapLandscapeEvidence"
  lane.add_theme_constant_override("separation",20)
  content.add_child(lane)
  content.move_child(lane,people_at)
  var people:=VBoxContainer.new()
  people.name="RecapLandscapePeople"
  people.size_flags_horizontal=Control.SIZE_EXPAND_FILL
  people.add_theme_constant_override("separation",4)
  lane.add_child(people)
  band_header.reparent(people)
  gallery.reparent(people)
  var saved:=VBoxContainer.new()
  saved.name="RecapLandscapeSavedChanges"
  saved.custom_minimum_size.x=220
  saved.add_theme_constant_override("separation",4)
  lane.add_child(saved)
  score.reparent(saved)
  tiles.reparent(saved)
 var room_copy: String = str(view.get("room_context",""))
 if not room_copy.is_empty():
  var room := ink(room_copy,16,true)
  room.name="RecapRoomContext"
  content.add_child(room)
  content.move_child(room,people_at+1 if short_landscape else people_at+2)
 if not external_details:
  var breakdown := Kit.button("HIDE FULL BREAKDOWN" if expanded_details else "FULL BREAKDOWN  ›","flightcase","tab")
  breakdown.name = "RecapDetailsToggleAction"
  breakdown.icon = JournalIcon
  breakdown.pressed.connect(func(): details_toggled.emit())
  content.add_child(breakdown)
 var detail := VBoxContainer.new()
 detail.name = "RecapDetailedBreakdown"
 detail.add_theme_constant_override("separation",3)
 detail.visible = expanded_details
 content.add_child(detail)
 detail.add_child(ink("COMPLETE SESSION LEDGER",16))
 var recorded_context := ink("This is the saved session record. The header shows your current day and cash.",16,true)
 recorded_context.name="RecapRecordedContext"
 detail.add_child(recorded_context)
 var full_reason := ink(str(view.get("reason","")),16)
 full_reason.name="RecapFullReason"
 detail.add_child(full_reason)
 for item in view.get("metric_rows",[]):
  if item is Dictionary:
   var number := ink(str(item.get("text","")),12 if mobile else 13)
   number.name = "RecapMetric_"+str(item.get("key",""))
   detail.add_child(number)
 detail.add_child(ink(str(view.get("footnote","")),10,true))
 for voice in voices:
  if voice is Dictionary:
   # Compact hero captions are excerpts. The native optional ledger keeps the
   # complete authored reaction available to touch and keyboard readers.
   var full_quote := ink(str(voice.get("name","Musician"))+" — “"+str(voice.get("quote",""))+"”",16)
   full_quote.name = "RecapFullQuote_"+str(voice.get("candidate_id",""))
   InkNote.NotesStyle.apply(full_quote)
   full_quote.add_to_group("bandmaster_notes")
   detail.add_child(full_quote)
   detail.add_child(ink(str(voice.get("name","Musician"))+": "+str(voice.get("effects","")),11,true))
 detail.add_child(ink("NEXT MOVE  /  "+str(view.get("next_step","")),11 if mobile else 13))
