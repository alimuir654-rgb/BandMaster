extends PanelContainer
## S40 read-only physical music-press recap. All values and names originate from
## the existing S38 resolver result and selected C25 cast, not new effects.
signal details_toggled
const Kit = preload("res://components/control_atlas/kit.gd")
const Cast = preload("res://experiments/character_cast/catalogue.gd")
const Recap = preload("res://experiments/playable_flightcase/rehearsal_recap.gd")
const PAPER = preload("res://components/control_atlas/art/paper_surface.png")

func ink(value: String, points: int, muted: bool = false) -> Label:
 var label: Label = Kit.label(value,"notepaper",points)
 label.add_theme_color_override("font_color",Color("695c4b") if muted else Color("29241f"))
 label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
 label.mouse_filter = Control.MOUSE_FILTER_IGNORE
 label.focus_mode = Control.FOCUS_NONE
 return label

func configure(report: Dictionary, members: Array, mobile: bool, expanded_details: bool) -> void:
 for old in get_children():
  remove_child(old)
  old.queue_free()
 name = "RehearsalRecapPanel"
 size_flags_horizontal = Control.SIZE_EXPAND_FILL
 var stock := StyleBoxTexture.new()
 stock.texture = PAPER
 stock.set_texture_margin_all(8.0)
 stock.set_content_margin_all(10.0 if mobile else 18.0)
 add_theme_stylebox_override("panel",stock)
 var view: Dictionary = Recap.present(report,members)
 var content := VBoxContainer.new()
 content.name = "RecapEditorialBody"
 content.add_theme_constant_override("separation",5 if mobile else 9)
 add_child(content)
 if view.is_empty():
  content.add_child(ink("No saved session report available.",15))
  return
 var mast := ink("LIVIN' THE DREAM   /   THE SESSION FILES",10 if mobile else 12,true)
 mast.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
 mast.autowrap_mode = TextServer.AUTOWRAP_OFF
 content.add_child(mast)
 var rule := ColorRect.new()
 rule.name = "RecapInkRule"
 rule.color = Color("69513d")
 rule.custom_minimum_size.y = 2.0
 rule.mouse_filter = Control.MOUSE_FILTER_IGNORE
 content.add_child(rule)
 var heading := ink(str(view.get("heading","SESSION")),11 if mobile else 13,true)
 heading.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
 content.add_child(heading)
 var verdict := ink(str(view.get("verdict","SESSION COMPLETE")).to_upper(),27 if mobile else 37)
 verdict.name = "RecapVerdict"
 verdict.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
 content.add_child(verdict)
 var why := ink(str(view.get("reason","")),12 if mobile else 14,true)
 why.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
 content.add_child(why)
 var score := ink("THE SCORECARD",11 if mobile else 12,true)
 score.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
 content.add_child(score)
 var metrics: Dictionary = {}
 for entry in view.get("metric_rows",[]):
  if entry is Dictionary:
   metrics[str(entry.get("key",""))] = entry
 var tiles := HBoxContainer.new()
 tiles.name = "RecapHeroMetrics"
 tiles.add_theme_constant_override("separation",4 if mobile else 10)
 content.add_child(tiles)
 for selector in [["readiness","SET"],["morale","MORALE"],["tension","TENSION"]]:
  var key: String = str(selector[0])
  var item: Dictionary = metrics.get(key,{})
  var delta: int = int(item.get("delta",0))
  var tile := PanelContainer.new()
  tile.name = "RecapHeroTile_"+key
  tile.size_flags_horizontal = Control.SIZE_EXPAND_FILL
  var style := StyleBoxFlat.new()
  style.bg_color = Color("e9ddca")
  style.border_color = Color("ae987b")
  style.set_border_width_all(1)
  style.set_content_margin_all(5.0 if mobile else 10.0)
  tile.add_theme_stylebox_override("panel",style)
  tiles.add_child(tile)
  var stack := VBoxContainer.new()
  stack.add_theme_constant_override("separation",1)
  tile.add_child(stack)
  var cap := ink(str(selector[1]),10 if mobile else 12,true)
  cap.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
  stack.add_child(cap)
  var change := ink(Recap.signed_change(delta),27 if mobile else 34)
  change.name = "RecapHero_"+key
  change.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
  var adverse: bool = (key=="tension" and delta>0) or (key!="tension" and delta<0)
  change.add_theme_color_override("font_color",Color("954a42") if adverse else (Color("376c58") if delta!=0 else Color("695c4b")))
  stack.add_child(change)
  var before_after := ink("%d → %d" % [int(item.get("before",0)),int(item.get("after",0))],9 if mobile else 11,true)
  before_after.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
  stack.add_child(before_after)
 var voices: Array = view.get("reactions",[])
 var band_header := HBoxContainer.new()
 band_header.add_theme_constant_override("separation",4)
 content.add_child(band_header)
 var band_caption := ink("FROM THE ROOM",11 if mobile else 12,true)
 band_caption.size_flags_horizontal = Control.SIZE_EXPAND_FILL
 band_header.add_child(band_caption)
 if voices.size()>3 and mobile:
  band_header.add_child(ink("SWIPE ›",9,true))
 var gallery := ScrollContainer.new()
 gallery.name = "RecapMemberGallery"
 gallery.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
 gallery.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
 gallery.custom_minimum_size.y = 168 if mobile else 188
 content.add_child(gallery)
 var strip := HBoxContainer.new()
 strip.name = "RecapPortraitRow"
 strip.alignment = BoxContainer.ALIGNMENT_CENTER
 strip.size_flags_horizontal = Control.SIZE_EXPAND_FILL
 strip.add_theme_constant_override("separation",5 if mobile else 12)
 gallery.add_child(strip)
 for voice in voices:
  if not voice is Dictionary:
   continue
  var person_id: String = str(voice.get("candidate_id",""))
  var display_name: String = str(voice.get("name","Musician"))
  var card := VBoxContainer.new()
  card.name = "RecapPortraitCard_"+person_id
  card.custom_minimum_size.x = 98 if mobile else 148
  card.add_theme_constant_override("separation",2)
  strip.add_child(card)
  var source: Dictionary = Cast.by_id(person_id)
  var photo_path: String = str(source.get("portrait_preview",""))
  if not photo_path.is_empty() and ResourceLoader.exists(photo_path):
   var photo := TextureRect.new()
   photo.name = "RecapPortrait_"+person_id
   photo.texture = load(photo_path)
   photo.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
   photo.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
   photo.custom_minimum_size = Vector2(68 if mobile else 88,72 if mobile else 91)
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
   short_quote = short_quote.substr(0,31).rstrip(" .")+"…"
  var line := ink(display_name+"\n“"+short_quote+"”",10 if mobile else 12)
  line.name = "RecapMember_"+person_id
  line.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
  card.add_child(line)
  var personal_morale: int = 0
  for individual in report.get("member_changes",[]):
   if individual is Dictionary and str(individual.get("candidate_id",""))==person_id:
    personal_morale = int(individual.get("changes",{}).get("morale",{}).get("delta",0))
    break
  var morale_badge := ink("MORALE "+Recap.signed_change(personal_morale),9 if mobile else 10,true)
  morale_badge.name = "RecapMood_"+person_id
  morale_badge.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
  morale_badge.add_theme_color_override("font_color",Color("954a42") if personal_morale<0 else (Color("376c58") if personal_morale>0 else Color("695c4b")))
  card.add_child(morale_badge)
 var breakdown := Kit.button("HIDE FULL BREAKDOWN" if expanded_details else "FULL BREAKDOWN  ›","flightcase","tab")
 breakdown.name = "RecapDetailsToggleAction"
 breakdown.pressed.connect(func(): details_toggled.emit())
 content.add_child(breakdown)
 var detail := VBoxContainer.new()
 detail.name = "RecapDetailedBreakdown"
 detail.add_theme_constant_override("separation",3)
 detail.visible = expanded_details
 content.add_child(detail)
 detail.add_child(ink("COMPLETE SESSION LEDGER",12))
 for item in view.get("metric_rows",[]):
  if item is Dictionary:
   var number := ink(str(item.get("text","")),12 if mobile else 13)
   number.name = "RecapMetric_"+str(item.get("key",""))
   detail.add_child(number)
 detail.add_child(ink(str(view.get("footnote","")),10,true))
 for voice in voices:
  if voice is Dictionary:
   detail.add_child(ink(str(voice.get("name","Musician"))+": "+str(voice.get("effects","")),11,true))
 detail.add_child(ink("NEXT MOVE  /  "+str(view.get("next_step","")),11 if mobile else 13))
