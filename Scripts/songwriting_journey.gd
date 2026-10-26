extends Control
# Four-place songwriting journey. Only the final commit spends a day; existing
# Practice.compose remains the authoritative engine and legacy editor fallback.
const UI = preload("res://Scripts/ui_theme.gd")
const Workshop = preload("res://Scripts/song_workshop.gd")
const Studio = preload("res://Scripts/song_studio_presentation.gd")
const Practice = preload("res://Scripts/practice_room.gd")
const Fade = preload("res://Scripts/journey_fade.gd")
const Photos = preload("res://Scripts/journey_photo.gd")
const Cinematic = preload("res://Scripts/journey_cinematic_stage.gd")
const Portrait = preload("res://Scripts/member_portrait.gd")
const PHASES := ["THE SPARK","FIND THE SOUND","IN THE ROOM","THE SONGSHEET"]
const ART := ["01-spark.svg","02-vibe.svg","03-jam.svg","04-sleeve.svg"]
const COLORS := [Color("#32201D"),Color("#0C293A"),Color("#371D2B"),Color("#463525")]
const ACCENTS := [Color("#F3C58D"),Color("#86E5D7"),Color("#F4A9B0"),Color("#F0D1A0")]
const VIBES := ["Restless and raw","Dreamy and spacious","Urgent and loud","Warm and intimate"]
var source_state: Dictionary = {}
var genre_id := "indie"
var commit_callback: Callable
var notes_callback: Callable
var stage := 0
var idea := "Riff"
var form := "Verse / Chorus"
var title := ""
var concept := ""
var vibe := "Restless and raw"
var lead_index := -1
var lead_choices: Array = []
var reduced_motion := false
var transitioning := false
var commit_locked := false
var stage_root: Control
var fade_layer: ColorRect

func open(state: Dictionary, selected_genre: String, on_commit: Callable, on_notes: Callable) -> void:
 source_state = state.duplicate(true)
 genre_id = selected_genre
 commit_callback = on_commit
 notes_callback = on_notes
 name = "SongwritingJourney"
 mouse_filter = Control.MOUSE_FILTER_STOP
 var catalogue: Dictionary = Workshop.options(source_state)
 var draft = source_state.get("current_song_draft",{})
 if not draft is Dictionary:
  draft = {}
 idea = str(draft.get("idea",Workshop.IDEAS[0]))
 form = str(draft.get("form",Workshop.FORMS[0]))
 title = str(draft.get("title",catalogue["titles"][0] if not catalogue["titles"].is_empty() else ""))
 concept = str(draft.get("lyrical_concept",""))
 vibe = str(draft.get("vibe",VIBES[0]))
 lead_choices = catalogue["leads"]
 if not lead_choices.is_empty():
  lead_index = int(lead_choices[0]["index"])
  for person in lead_choices:
   if str(person["name"]) == str(draft.get("leader","")):
    lead_index = int(person["index"])
 var saved_notes = source_state.get("song_journey_notes",{})
 if saved_notes is Dictionary and not saved_notes.is_empty() and int(saved_notes.get("session_progress",-1)) == int(source_state.get("song_draft_progress",0)) and str(saved_notes.get("draft_title","")) == str(draft.get("title","")):
  idea = str(saved_notes.get("idea",idea))
  form = str(saved_notes.get("form",form))
  title = str(saved_notes.get("title",title))
  concept = str(saved_notes.get("concept",concept))
  vibe = str(saved_notes.get("vibe",vibe))
  lead_index = int(saved_notes.get("lead_index",lead_index))
  stage = clampi(int(saved_notes.get("step",0)),0,3)
 stage_root = Control.new()
 stage_root.name = "JourneySceneRoot"
 add_child(stage_root)
 stage_root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
 fade_layer = ColorRect.new()
 fade_layer.name = "JourneyFade"
 fade_layer.color = Color(0,0,0,0)
 fade_layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
 add_child(fade_layer)
 fade_layer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
 _render_stage()

func _text(parent: Node, value: String, size: int, colour: Color) -> Label:
 var label := Label.new()
 label.text = value
 label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
 label.add_theme_font_size_override("font_size",maxi(size,16))
 label.add_theme_color_override("font_color",colour)
 parent.add_child(label)
 return label

func _tone_button(button: Button, primary: bool) -> void:
 var accent: Color = ACCENTS[stage]
 var base: Color = Color("#18232D")
 var fill: Color = accent if primary else base
 var foreground: Color = Color("#202128") if primary else Color("#FFF5E6")
 var normal := UI._button_surface(fill,primary)
 normal.border_color = accent if primary else Color("#51606D")
 button.add_theme_stylebox_override("normal",normal)
 button.add_theme_stylebox_override("hover",UI._button_surface(fill.lightened(0.11),primary))
 button.add_theme_stylebox_override("pressed",UI._button_surface(fill.darkened(0.12),primary))
 var focus := UI.flat(Color.TRANSPARENT,9)
 focus.border_color = accent
 focus.set_border_width_all(3)
 button.add_theme_stylebox_override("focus",focus)
 for key in ["font_color","font_hover_color","font_pressed_color","font_focus_color","font_hover_pressed_color"]:
  button.add_theme_color_override(key,foreground)

func _tone_selector(select: OptionButton) -> void:
 var surface := UI._button_surface(Color("#17222C"),false)
 surface.border_color = ACCENTS[stage]
 surface.border_width_bottom = 1
 select.add_theme_stylebox_override("normal",surface)
 select.add_theme_stylebox_override("hover",UI._button_surface(Color("#283846"),false))
 select.add_theme_color_override("font_color",Color("#FFF5E6"))
 select.add_theme_color_override("font_hover_color",Color("#FFF5E6"))
 var focus := UI.flat(Color.TRANSPARENT,8)
 focus.border_color = ACCENTS[stage]
 focus.set_border_width_all(2)
 select.add_theme_stylebox_override("focus",focus)

func _selector(parent: Node, heading: String, values: Array, chosen: int, control_name: String) -> OptionButton:
 _text(parent,heading,14,ACCENTS[stage])
 var select := OptionButton.new()
 select.name = control_name
 select.custom_minimum_size.y = 56
 select.size_flags_horizontal = Control.SIZE_EXPAND_FILL
 for value in values:
  select.add_item(str(value))
 if not values.is_empty():
  select.select(clampi(chosen,0,values.size()-1))
 else:
  select.disabled = true
 _tone_selector(select)
 parent.add_child(select)
 return select

# Tactile creative decisions replace dropdown-first presentation. The hidden
# OptionButton remains the authoritative selected value for save/test parity.
func _choice_deck(parent: Node, select: OptionButton, values: Array, prefix: String) -> void:
 select.hide()
 var deck := GridContainer.new()
 deck.name = prefix+"Deck"
 deck.columns = 2 if get_viewport_rect().size.x < 960.0 else 3
 deck.size_flags_horizontal = Control.SIZE_EXPAND_FILL
 deck.add_theme_constant_override("h_separation",9)
 deck.add_theme_constant_override("v_separation",9)
 parent.add_child(deck)
 var chips: Array[Button] = []
 for index in range(values.size()):
  var chip := UI.themed_button(str(values[index]).to_upper(),genre_id,false)
  chip.name = prefix+"Choice%02d" % index
  chip.custom_minimum_size.y = 82
  chip.toggle_mode = true
  chip.button_pressed = index == select.selected
  chip.add_theme_font_size_override("font_size",16)
  chip.add_theme_stylebox_override("normal",UI._button_surface(Color("#21313C"),false))
  var active := UI._button_surface(ACCENTS[stage],true)
  active.border_color = ACCENTS[stage]
  chip.add_theme_stylebox_override("pressed",active)
  chip.add_theme_color_override("font_pressed_color",Color("#15212A"))
  chip.add_theme_color_override("font_hover_pressed_color",Color("#15212A"))
  deck.add_child(chip)
  chips.append(chip)
  var selected_index := index
  var selected_chip := chip
  chip.pressed.connect(func() -> void:
   select.select(selected_index)
   select.item_selected.emit(selected_index)
   for other in chips:
    other.button_pressed = other == selected_chip
  )

func _text_input(parent: Node, heading: String, value: String, control_name: String, max_chars: int) -> LineEdit:
 _text(parent,heading,14,ACCENTS[stage])
 var field := LineEdit.new()
 field.name = control_name
 field.text = value
 field.max_length = max_chars
 field.custom_minimum_size.y = 56
 field.add_theme_stylebox_override("normal",UI._button_surface(Color("#E8E6DF"),false))
 field.add_theme_color_override("font_color",Color("#231E1B"))
 field.add_theme_color_override("font_placeholder_color",Color("#62574E"))
 parent.add_child(field)
 return field

func _render_stage() -> void:
 if not is_instance_valid(stage_root):
  return
 for child in stage_root.get_children():
  stage_root.remove_child(child)
  child.queue_free()
 var backdrop := ColorRect.new()
 backdrop.color = COLORS[stage]
 stage_root.add_child(backdrop)
 backdrop.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
 # The whole room changes tone, not merely a small illustration in a card.
 var art_path: String = Photos.scene_or_fallback("songwriting",stage,1280.0,"res://Art/Journeys/Songwriting/"+str(ART[stage]))
 var ambient_path: String = Photos.scene_or_fallback("songwriting",stage,get_viewport_rect().size.x,art_path)
 if ResourceLoader.exists(ambient_path):
  var ambient := TextureRect.new()
  ambient.name = "JourneyAmbientArt"
  ambient.texture = load(ambient_path)
  ambient.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
  ambient.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
  ambient.modulate = Color(1,1,1,0.37)
  ambient.mouse_filter = Control.MOUSE_FILTER_IGNORE
  stage_root.add_child(ambient)
  ambient.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
 var margins := MarginContainer.new()
 margins.name = "JourneyMargins"
 stage_root.add_child(margins)
 margins.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
 var gutter := 14 if get_viewport_rect().size.x < 600 else 32
 for key in ["margin_left","margin_right"]:
  margins.add_theme_constant_override(key,gutter)
 margins.add_theme_constant_override("margin_top",14)
 margins.add_theme_constant_override("margin_bottom",18)
 var layout := VBoxContainer.new()
 layout.add_theme_constant_override("separation",12)
 margins.add_child(layout)
 _text(layout,"SONGWRITING  /  %02d OF 04  /  SESSION %d OF 3" % [stage+1,clampi(int(source_state.get("song_draft_progress",0)),0,2)+1],13,ACCENTS[stage])
 _text(layout,PHASES[stage],30,Color("#FFF5E6"))
 var scroller := ScrollContainer.new()
 scroller.name = "JourneyScroll"
 scroller.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
 scroller.size_flags_vertical = Control.SIZE_EXPAND_FILL
 layout.add_child(scroller)
 var centered := CenterContainer.new()
 centered.size_flags_horizontal = Control.SIZE_EXPAND_FILL
 scroller.add_child(centered)
 var body := VBoxContainer.new()
 var cinematic_split := get_viewport_rect().size.x >= 960.0
 body.custom_minimum_size.x = maxf(280.0,get_viewport_rect().size.x-2.0*gutter-14.0) if cinematic_split else minf(760.0,maxf(280.0,get_viewport_rect().size.x-2.0*gutter-14.0))
 body.add_theme_constant_override("separation",13)
 centered.add_child(body)
 # Wide displays use a cinematic two-plane composition: environment on the
 # left, readable decisions on the right. Phones keep the linear story.
 var scene_planes: BoxContainer = HBoxContainer.new() if cinematic_split else VBoxContainer.new()
 scene_planes.name = "JourneyScenePlanes"
 scene_planes.add_theme_constant_override("separation",24 if cinematic_split else 12)
 body.add_child(scene_planes)
 var hero_height := 460.0 if get_viewport_rect().size.x < 600.0 else (780.0 if cinematic_split else 430.0)
 Cinematic.add_hero(scene_planes,art_path,"WRITING SESSION  /  %02d" % (stage+1),PHASES[stage],ACCENTS[stage],hero_height)
 # Choices are a readable foreground dock; the image carries the atmosphere.
 var story_panel := PanelContainer.new()
 story_panel.name = "JourneyStoryPanel"
 story_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
 if cinematic_split:
  story_panel.custom_minimum_size.y = 650
 var panel_tone := UI.flat(Color("#101923"),8)
 panel_tone.set_content_margin_all(18)
 panel_tone.border_color = Color("#42505D")
 panel_tone.border_width_top = 2
 story_panel.add_theme_stylebox_override("panel",panel_tone)
 scene_planes.add_child(story_panel)
 var story_holder: Node = story_panel
 var story := VBoxContainer.new()
 story.name = "JourneyStory"
 story.size_flags_horizontal = Control.SIZE_EXPAND_FILL
 story.add_theme_constant_override("separation",12)
 story_holder.add_child(story)
 match stage:
  0:
   _text(story,"A song begins with a thought you cannot shake. What starts the writing?",18,Color("#FFF5E6"))
   var idea_choice := _selector(story,"WHERE DOES THE IDEA BEGIN?",Workshop.IDEAS,Workshop.IDEAS.find(idea),"JourneyIdeaChoice")
   _choice_deck(story,idea_choice,Workshop.IDEAS,"Idea")
   _text_input(story,"LYRICAL CONCEPT  /  THE THING YOU WANT TO SAY",concept,"JourneyConceptInput",90).placeholder_text = "An empty station, a last chance, a promise..."
   _text_input(story,"WORKING TITLE",title,"JourneyTitleInput",48).placeholder_text = "Give this original a name"
  1:
   _text(story,"Now find its emotional temperature. Let the room change around the sound.",18,Color("#FFF5E6"))
   var mood_choice := _selector(story,"THE GENERAL VIBE",VIBES,VIBES.find(vibe),"JourneyVibeChoice")
   _choice_deck(story,mood_choice,VIBES,"Vibe")
   var mood_story := _text(story,_vibe_line(vibe),16,Color("#D7E4E7"))
   mood_story.name = "JourneyVibeReaction"
   mood_choice.item_selected.connect(func(index: int) -> void:
    mood_story.text = _vibe_line(mood_choice.get_item_text(index))
   )
   var form_choice := _selector(story,"THE SONG'S SHAPE  /  AFFECTS THE FINISHED TRACK",Workshop.FORMS,Workshop.FORMS.find(form),"JourneyFormChoice")
   _choice_deck(story,form_choice,Workshop.FORMS,"Form")
   var form_note := _text(story,str(Studio.FORM_NOTES.get(form,"Choose a structure.")),14,Color("#D7E4E7"))
   form_choice.item_selected.connect(func(index: int) -> void:
    form_note.text = str(Studio.FORM_NOTES.get(form_choice.get_item_text(index),"Choose a structure."))
   )
  2:
   _text(story,"The band comes into focus. Someone has to lead this session.",18,Color("#FFF5E6"))
   var catalogue: Dictionary = Workshop.options(source_state)
   lead_choices = catalogue["leads"]
   var names: Array = []
   var selected := 0
   for index in range(lead_choices.size()):
    var person: Dictionary = lead_choices[index]
    names.append(str(person["name"])+"  /  "+str(person["trait"]))
    if int(person["index"]) == lead_index:
     selected = index
   var lead_select := _selector(story,"WHO LEADS THE JAM?",names,selected,"JourneyLeadChoice")
   if not lead_choices.is_empty():
    var voice_row := HBoxContainer.new()
    voice_row.name = "JourneyBandmateMoment"
    voice_row.add_theme_constant_override("separation",16)
    story.add_child(voice_row)
    var portrait := Portrait.new()
    portrait.name = "JourneyLeadPortrait"
    portrait.custom_minimum_size = Vector2(104,128)
    voice_row.add_child(portrait)
    var voice := _text(voice_row,"",16,Color("#F7D4D7"))
    voice.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    var show_lead := func(index: int) -> void:
     if index >= 0 and index < lead_choices.size():
      var person: Dictionary = lead_choices[index]
      portrait.set_character(str(person.get("candidate_id",person.get("name",""))),str(person.get("name","Musician")),genre_id)
      voice.text = str(person.get("name","Musician"))+"  /  "+_lead_line(person)
    show_lead.call(selected)
    lead_select.item_selected.connect(show_lead)
   var studio: Dictionary = Studio.view(source_state)
   _text(story,"%d OF 3 WRITING SESSIONS ALREADY RECORDED" % int(studio["completed"]),15,ACCENTS[stage])
   for session in studio["history"]:
    if session is Dictionary:
     _text(story,"DAY %d  /  %s  /  %s" % [int(session.get("day",0)),str(session.get("leader","")),str(session.get("form",""))],14,Color("#F7D4D7"))
  3:
   _text(story,"One last look before the tape rolls. The next decision spends ONE day.",18,Color("#FFF5E6"))
   var paper := PanelContainer.new()
   var paper_style := UI.style(Color("#E9DDC2"),10)
   paper_style.border_color = Color("#B99563")
   paper_style.set_border_width_all(3)
   paper.add_theme_stylebox_override("panel",paper_style)
   story.add_child(paper)
   var summary := VBoxContainer.new()
   summary.add_theme_constant_override("separation",10)
   paper.add_child(summary)
   _text(summary,title.strip_edges().to_upper() if not title.strip_edges().is_empty() else "UNTITLED",24,Color("#241C15"))
   _text(summary,"CONCEPT  /  "+(concept if not concept.is_empty() else "Not specified"),14,Color("#60462E"))
   _text(summary,"STARTING POINT  /  "+idea,14,Color("#60462E"))
   _text(summary,"VIBE  /  "+vibe,14,Color("#60462E"))
   _text(summary,"ARRANGEMENT  /  "+form,14,Color("#60462E"))
   var leader_name := "NO AVAILABLE MUSICIAN"
   for person in lead_choices:
    if int(person["index"]) == lead_index:
     leader_name = str(person["name"])
   _text(summary,"SESSION LEAD  /  "+leader_name,14,Color("#60462E"))
   _text(summary,"This is a session preview, not a finished song. The real sleeve appears after session three.",13,Color("#785B39"))
 var status := _text(layout,"",14,Color("#FFD9C0"))
 status.name = "JourneyStatus"
 var footer := HBoxContainer.new()
 footer.name = "JourneyFooter"
 footer.add_theme_constant_override("separation",9)
 layout.add_child(footer)
 var back := UI.themed_button("CLOSE" if stage == 0 else "‹  BACK",genre_id,false)
 back.name = "JourneyBack"
 _tone_button(back,false)
 back.custom_minimum_size.y = 82
 footer.add_child(back)
 back.pressed.connect(func() -> void:
  if stage == 0:
   if not transitioning:
    _capture_stage()
    _persist_notes(stage)
    queue_free()
  else:
   _go(stage-1)
 )
 var next_text: String = ["FIND THE SOUND  ›","ENTER THE ROOM  ›","REVIEW SONGSHEET  ›","COMMIT SESSION  /  1 DAY"][stage]
 var next := UI.themed_button(next_text,genre_id,true)
 next.name = "JourneyNext"
 _tone_button(next,true)
 next.custom_minimum_size.y = 82
 next.disabled = stage == 2 and lead_choices.is_empty()
 footer.add_child(next)
 next.pressed.connect(func() -> void:
  if stage == 3:
   _commit()
  else:
   _go(stage+1)
 )
 var motion := UI.themed_button("REDUCE MOTION: "+("ON" if reduced_motion else "OFF"),genre_id,false)
 motion.name = "JourneyMotionToggle"
 _tone_button(motion,false)
 motion.custom_minimum_size.y = 70
 motion.add_theme_font_size_override("font_size",11)
 layout.add_child(motion)
 motion.pressed.connect(func() -> void:
  reduced_motion = not reduced_motion
  motion.text = "REDUCE MOTION: "+("ON" if reduced_motion else "OFF")
 )

func _vibe_line(selected: String) -> String:
 match selected:
  "Restless and raw":
   return "The amp hums. Nobody wants a polished first take."
  "Dreamy and spacious":
   return "Leave space between the notes; let the room do some of the singing."
  "Urgent and loud":
   return "The drummer counts in fast. This one wants to be heard."
  "Warm and intimate":
   return "Pull the microphones close. Keep the imperfections that feel human."
 return "The band listens for a sound worth following."

func _lead_line(person: Dictionary) -> String:
 var trait_name := str(person.get("trait","")).to_lower()
 if trait_name.contains("creative") or trait_name.contains("genius"):
  return "Give me a little space. I think there's a hook in here."
 if trait_name.contains("reliable") or trait_name.contains("perfection"):
  return "Let's count it in properly and get a clean take."
 if trait_name.contains("ambitious"):
  return "I want this one to sound like it belongs on a record."
 return "I'll start us off. Let's see where the band takes it."

func _capture_stage() -> void:
 var choice := stage_root.find_child("JourneyIdeaChoice",true,false) as OptionButton
 if choice != null and choice.selected >= 0:
  idea = choice.get_item_text(choice.selected)
 var entry := stage_root.find_child("JourneyConceptInput",true,false) as LineEdit
 if entry != null:
  concept = entry.text.strip_edges()
 entry = stage_root.find_child("JourneyTitleInput",true,false) as LineEdit
 if entry != null:
  title = entry.text.strip_edges()
 choice = stage_root.find_child("JourneyVibeChoice",true,false) as OptionButton
 if choice != null and choice.selected >= 0:
  vibe = choice.get_item_text(choice.selected)
 choice = stage_root.find_child("JourneyFormChoice",true,false) as OptionButton
 if choice != null and choice.selected >= 0:
  form = choice.get_item_text(choice.selected)
 choice = stage_root.find_child("JourneyLeadChoice",true,false) as OptionButton
 if choice != null and choice.selected >= 0 and choice.selected < lead_choices.size():
  lead_index = int(lead_choices[choice.selected]["index"])

func _persist_notes(next_step: int) -> void:
 if not notes_callback.is_valid():
  return
 var draft = source_state.get("current_song_draft",{})
 if not draft is Dictionary:
  draft = {}
 notes_callback.call({
  "step":next_step,"session_progress":int(source_state.get("song_draft_progress",0)),
  "draft_title":str(draft.get("title","")),"idea":idea,"form":form,
  "title":title,"concept":concept,"vibe":vibe,"lead_index":lead_index
 })

func _go(destination: int) -> void:
 if transitioning or commit_locked or destination < 0 or destination >= PHASES.size():
  return
 _capture_stage()
 _persist_notes(destination)
 transitioning = true
 Fade.play(fade_layer,Callable(self,"_set_stage").bind(destination),Callable(self,"_transition_complete"),reduced_motion)

func _set_stage(destination: int) -> void:
 stage = destination
 _render_stage()

func _transition_complete() -> void:
 transitioning = false
 var primary := stage_root.find_child("JourneyNext",true,false) as BaseButton
 if primary != null:
  primary.grab_focus()

func _commit() -> void:
 if commit_locked or transitioning:
  return
 _capture_stage()
 _persist_notes(stage)
 var validation: Dictionary = Workshop.develop(source_state,idea,form,title,lead_index,concept,vibe)
 if not bool(validation.get("ok",false)):
  var status := stage_root.find_child("JourneyStatus",true,false) as Label
  if status != null:
   status.text = str(validation.get("message","Review the choices before committing."))
  return
 commit_locked = true
 var result: Dictionary = Practice.compose(source_state,idea,form,title,lead_index,concept,vibe)
 if not bool(result.get("ok",false)):
  commit_locked = false
  var status := stage_root.find_child("JourneyStatus",true,false) as Label
  if status != null:
   status.text = str(result.get("message","Session unavailable."))
  return
 commit_callback.call(result)
