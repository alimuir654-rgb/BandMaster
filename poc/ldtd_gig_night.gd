extends Control
## S05 isolated physical gig call-board, real show-day engine and one settlement.
## DAY load-in -> DUSK soundcheck -> NIGHT three song cues -> AFTERSHOW.
## No save writes, no user://, no simulated sound or fake payouts.
const Model = preload("res://Scripts/ldtd_gig_night_preview.gd")
const Circuit = preload("res://Scripts/uk_gig_circuit.gd")
const Key = preload("res://Scripts/ldtd_gig_key.gd")
const PHOTO_DAY := "res://Art/Backgrounds/shared/gear.webp"
const PHOTO_DUSK := "res://Art/Backgrounds/shared/backstage.webp"
const PHOTO_NIGHT := "res://Art/Backgrounds/shared/gigs.webp"
const BOARD := "res://Art/UI/GigCraft/showboard.svg"
const FONT_DISPLAY := "res://Art/Fonts/BarlowCondensed-SemiBold.ttf"
const FONT_BODY := "res://Art/Fonts/IBMPlexSans-Variable.ttf"
const FONT_NUMBERS := "res://Art/Fonts/IBMPlexMono-Regular.ttf"
const APPROACHES := ["tight","wild","crowd"]
const SONGS := ["OPENING","NEW ORIGINAL","LAST SONG"]
const INK := Color("#EDE5D3")
var demo_state: Dictionary = {}
var journey_step: int = 0
var phase: String = "day"
var equipment_ready: bool = false
var soundcheck_ready: bool = false
var held: bool = false
var selected_song: int = 0
var songs_played: int = 0
var encore_fired: bool = false
var settled: bool = false
var settlement_count: int = 0
var settlement: Dictionary = {}
var error_message: String = ""
var _surface: Control
var _scale: float = 1.0
var _primary: TextureButton
var _status: Label
var _stats: Label
var _keys: Dictionary = {}
var _render_pending: bool = false

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	demo_state = Model.sample_state()
	resized.connect(_on_resize)
	call_deferred("_render")

func _on_resize() -> void:
	if is_inside_tree() and not _render_pending:
		_render_pending = true
		call_deferred("_render")

func _redraw() -> void:
	if is_inside_tree() and not _render_pending:
		_render_pending = true
		call_deferred("_render")

func toggle_equipment() -> void:
	if journey_step == 0:
		equipment_ready = not equipment_ready
		_redraw()

func toggle_soundcheck() -> void:
	if journey_step == 1 and equipment_ready:
		soundcheck_ready = not soundcheck_ready
		_redraw()

func choose_approach(value: String) -> void:
	if journey_step > 2 or songs_played > 0 or settled:
		return
	var result: Dictionary = Model.choose_approach(demo_state,value)
	if bool(result.get("ok",false)):
		demo_state = result["state"]
		error_message = ""
	else:
		error_message = str(result.get("message","Invalid approach."))
	_redraw()

func select_song(index: int) -> void:
	if journey_step == 2 and index >= 0 and index < 3 and songs_played < 3:
		selected_song = index
		_redraw()

func toggle_hold() -> void:
	if journey_step == 2 and not settled:
		held = not held
		_redraw()

func can_go() -> bool:
	return journey_step == 2 and not settled and not held and equipment_ready and soundcheck_ready and songs_played < 3 and selected_song == songs_played

func fire_go() -> void:
	if not can_go():
		error_message = "HOLD / SAFE SOUND / NEXT SONG REQUIRED" if journey_step == 2 else "STAGE NOT OPEN"
		_redraw()
		return
	songs_played += 1
	selected_song = mini(2,songs_played)
	error_message = ""
	_redraw()

func can_encore() -> bool:
	return journey_step == 2 and songs_played == 3 and not held and not encore_fired and not settled

func fire_encore() -> void:
	if can_encore():
		encore_fired = true
		error_message = "ENCORE CALLED / NO EXTRA FEE OR SECOND SHOW"
		_redraw()

func advance_journey() -> void:
	error_message = ""
	match journey_step:
		0:
			if not equipment_ready:
				error_message = "SECURE THE LOAD BEFORE SOUNDCHECK"
			else:
				journey_step = 1
				phase = "dusk"
		1:
			if not soundcheck_ready:
				error_message = "CHECK THE SIGNAL BEFORE OPENING THE STAGE"
			else:
				journey_step = 2
				phase = "night"
		2:
			var result: Dictionary = Model.settle(demo_state,songs_played,equipment_ready,soundcheck_ready,held,settled)
			if not bool(result.get("ok",false)):
				error_message = str(result.get("message","The set is not finished."))
			else:
				demo_state = result["state"]
				settlement = result
				settled = true
				settlement_count += 1
				journey_step = 3
				phase = "night"
		3:
			# Aftershow is a terminal result; no implicit restart/duplicate gig.
			error_message = "AFTERSHOW COMPLETE / RETURN TO GALLERY"
	_redraw()

func _return_to_gallery() -> void:
	var dest := "res://poc/ldtd_career_scene_shell.tscn"
	if ResourceLoader.exists(dest):
		get_tree().change_scene_to_file(dest)

func _rect(node: Control,x: float,y: float,w: float,h: float) -> void:
	node.position = Vector2(x,y)
	node.size = Vector2(maxf(w,1.0),maxf(h,1.0))

func _font(path: String) -> Font:
	return load(path) as Font if ResourceLoader.exists(path) else null

func _label(parent: Node,n: String,t: String,pt: int,color: Color,role: String="body") -> Label:
	var l := Label.new()
	l.name = n
	l.text = t
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	l.focus_mode = Control.FOCUS_NONE
	l.add_theme_font_size_override("font_size",pt)
	l.add_theme_color_override("font_color",color)
	var path: String = FONT_DISPLAY if role=="display" else (FONT_NUMBERS if role=="numbers" else FONT_BODY)
	var f: Font = _font(path)
	if f != null:
		l.add_theme_font_override("font",f)
	parent.add_child(l)
	return l

func _panel(fill: Color,edge: Color) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = fill
	s.border_color = edge
	s.set_border_width_all(1)
	s.set_corner_radius_all(6)
	s.shadow_color = Color(0.0,0.0,0.0,0.29)
	s.shadow_size = 9
	s.shadow_offset = Vector2(0,3)
	return s

func _key(parent: Node,n: String,family: String,caption: String,chosen: bool,disabled: bool,
		action: Callable,x: float,y: float,w: float,h: float) -> TextureButton:
	var k = Key.new()
	k.name = n
	k.choice_id = n
	k.family = family
	k.caption = caption
	k.chosen = chosen
	k.disabled = disabled
	parent.add_child(k)
	_rect(k,x,y,w,h)
	k.key_chosen.connect(func(_id: String) -> void: action.call())
	_keys[n] = k
	return k

func _photo_path() -> String:
	return PHOTO_DAY if journey_step==0 else (PHOTO_DUSK if journey_step==1 else PHOTO_NIGHT)

func _status_line() -> String:
	if not error_message.is_empty():
		return error_message
	match journey_step:
		0: return "DAY LOAD-IN / CHECK THE CASES AND CABLES"
		1: return "DUSK SOUNDCHECK / TEST THE LIVE SIGNAL"
		2: return "NIGHT SHOW / %d OF 3 SONGS / %s" % [songs_played,"HOLD" if held else "READY"]
		_: return "SHOW SETTLED ONCE / LOCAL PREVIEW / NO SAVE WRITES"

func _render() -> void:
	_render_pending = false
	if not is_inside_tree():
		return
	for child in get_children():
		remove_child(child)
		child.queue_free()
	_keys.clear()
	var vp: Vector2 = get_viewport_rect().size
	_scale = maxf(float(DisplayServer.window_get_size().x)/maxf(vp.x,1.0),0.35)
	var w: float = vp.x*_scale
	var h: float = vp.y*_scale
	var narrow: bool = w<760.0
	var day: bool = journey_step==0
	var bg := ColorRect.new()
	bg.name = "GigPhaseBackdrop"
	bg.color = Color("#E6DDCB") if day else (Color("#3E4B4B") if journey_step==1 else Color("#0D161D"))
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(bg)
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_surface = Control.new()
	_surface.name = "GigPhysicalSurface"
	_surface.scale = Vector2.ONE/_scale
	add_child(_surface)
	_rect(_surface,0,0,w,h)

	var atmosphere := TextureRect.new()
	atmosphere.name = "SourceBackedGigAtmosphere"
	atmosphere.texture = load(_photo_path())
	atmosphere.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	atmosphere.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	atmosphere.modulate = Color(1.0,1.0,1.0,0.17) if day else (Color(0.55,0.75,0.78,0.23) if journey_step==1 else Color(0.36,0.52,0.65,0.28))
	atmosphere.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_surface.add_child(atmosphere)
	_rect(atmosphere,0,0,w,h)

	var header := Panel.new()
	header.name = "GigHeader"
	header.add_theme_stylebox_override("panel",_panel(Color("#F2E9D8") if day else Color("#1C2B32"),Color("#C3AC8B")))
	_surface.add_child(header)
	_rect(header,12,9,w-24,82)
	var head_ink: Color = Color("#26383D") if day else INK
	var brand := _label(header,"PlayerFacingTitle","LIVIN’ THE DREAM",23 if narrow else 29,head_ink,"display")
	_rect(brand,14,7,w-(148 if narrow else 205),37)
	var sub := _label(header,"GigChapter","CH. 04  /  SHOW NIGHT",13,Color("#4C6468") if day else Color("#C8D2CC"),"numbers")
	_rect(sub,14,48,w-160,25)
	_key(header,"ReturnToGallery","cue","GALLERY",false,false,_return_to_gallery,w-(126 if narrow else 161),11,100 if narrow else 130,48)

	var moments := ["DAY / LOAD-IN","DUSK / SOUND","NIGHT / STAGE","AFTERSHOW"]
	var step_gap: float = 5.0
	var step_w: float = (w-28.0-step_gap*3.0)/4.0
	for i in range(4):
		var strip := Panel.new()
		strip.name = "GigPhaseIndicator"+str(i)
		strip.mouse_filter = Control.MOUSE_FILTER_IGNORE
		strip.add_theme_stylebox_override("panel",_panel(Color("#E9D2A5") if journey_step==i else Color("#1D3038"),Color("#C4A976") if journey_step==i else Color("#4A5B60")))
		_surface.add_child(strip)
		_rect(strip,14+i*(step_w+step_gap),101,step_w,43)
		var cap := _label(strip,"GigMoment"+str(i),moments[i],11 if narrow else 14,Color("#22333A") if journey_step==i else Color("#E5DDCC"),"display")
		cap.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		cap.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		_rect(cap,4,3,step_w-8,37)

	var dock_h: float = 104.0
	var scroll := ScrollContainer.new()
	scroll.name = "GigNightScroll"
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	_surface.add_child(scroll)
	_rect(scroll,0,151,w,maxf(130.0,h-151.0-dock_h))
	var page := Control.new()
	page.name = "GigNightPage"
	scroll.add_child(page)
	var page_w: float = minf(1190.0,w-24.0)
	var left: float = (w-page_w)*0.5
	var page_h: float = 815.0 if narrow else 610.0
	_rect(page,0,0,w,page_h)
	page.custom_minimum_size = Vector2(w,page_h)
	var photo_w: float = page_w if narrow else 394.0
	var photo_h: float = 103.0 if narrow else 355.0
	var frame := Panel.new()
	frame.name = "GigRealPhotoFrame"
	frame.clip_contents = true
	frame.add_theme_stylebox_override("panel",_panel(Color("#1C2C34"),Color("#B29A76")))
	page.add_child(frame)
	_rect(frame,left,6,photo_w,photo_h)
	var photo := TextureRect.new()
	photo.name = "RepoBackedGigPhasePhoto"
	photo.texture = load(_photo_path())
	photo.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	photo.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	photo.mouse_filter = Control.MOUSE_FILTER_IGNORE
	frame.add_child(photo)
	_rect(photo,4,4,photo_w-8,photo_h-8)
	var caption := _label(frame,"GigPhotoCaption",["DAYLIGHT / LOAD-IN","DUSK / SOUNDCHECK","NIGHT / THE ROOM","NIGHT / AFTERSHOW"][journey_step],12,INK,"numbers")
	caption.add_theme_constant_override("outline_size",3)
	caption.add_theme_color_override("font_outline_color",Color("#17242B"))
	_rect(caption,12,photo_h-29,photo_w-22,23)
	if not narrow:
		var scene_note := _label(page,"StageAtmosphereNote",
			"REAL REPO SCENE IMAGE\n\nA SMALL ROOM. A LONG NIGHT.\n\nTHE SET IS THE BAND’S CHOICE.",
			17,Color("#F6EAD7") if not day else Color("#293B40"),"display")
		_rect(scene_note,left+16,379,photo_w-32,128)

	var board_x: float = left if narrow else left+413.0
	var board_y: float = 114.0 if narrow else 6.0
	var board_w: float = page_w if narrow else page_w-413.0
	var board_h: float = 595.0 if narrow else 544.0
	var material := TextureRect.new()
	material.name = "OriginalGigShowboard"
	material.texture = load(BOARD)
	material.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	material.stretch_mode = TextureRect.STRETCH_SCALE
	material.mouse_filter = Control.MOUSE_FILTER_IGNORE
	page.add_child(material)
	_rect(material,board_x,board_y,board_w,board_h)
	var board := Control.new()
	board.name = "GigNativeShowboardInk"
	page.add_child(board)
	_rect(board,board_x,board_y,board_w,board_h)
	var inner: float = board_w-32.0
	var title := _label(board,"GigBoardTitle","THE CALL SHEET" if journey_step<3 else "THE AFTERSHOW",26 if narrow else 30,INK,"display")
	_rect(title,16,11,inner,39)
	var booked: Dictionary = demo_state.get("booked_show",{})
	var last: Dictionary = demo_state.get("gig_history",[]).back() if not demo_state.get("gig_history",[]).is_empty() else {}
	var stats_text: String = "DAY %d  /  %s  /  CASH £%d" % [int(demo_state.get("tour_day",1)),str(booked.get("venue","THE LANTERN ROOM")).to_upper(),int(demo_state.get("cash",0))]
	if journey_step==3:
		stats_text = "FEE £%d  /  FANS %d  /  CASH £%d" % [int(last.get("fee",0)),int(demo_state.get("fans",0)),int(demo_state.get("cash",0))]
	_stats = _label(board,"ReadOnlyGigOutcome",stats_text,13,Color("#E4D8C1"),"numbers")
	_rect(_stats,16,51,inner,28)

	var safety := _label(board,"GigSafetyHeading","1  /  LOAD AND SIGNAL",14,INK,"display")
	_rect(safety,16,82,inner,23)
	var half: float = (inner-7.0)/2.0
	_key(board,"GigGearLatch","gear","GEAR SECURED" if equipment_ready else "SECURE GEAR",
		equipment_ready,journey_step!=0,toggle_equipment,16,106,half,57)
	_key(board,"GigSoundLatch","sound","SIGNAL CHECKED" if soundcheck_ready else "TEST SIGNAL",
		soundcheck_ready,journey_step!=1 or not equipment_ready,toggle_soundcheck,23+half,106,half,57)

	var approach_label := _label(board,"GigApproachHeading","2  /  CHOOSE THE LIVE SET",14,INK,"display")
	_rect(approach_label,16,168,inner,23)
	var selected_approach: String = str(booked.get("approach","tight"))
	var approach_w: float = (inner-10.0)/3.0
	for i in range(3):
		var approach: String = APPROACHES[i]
		_key(board,"GigApproach"+approach.capitalize(),"approach",["TIGHT SET","BIG NIGHT","WIN ROOM"][i],
			approach==selected_approach,journey_step==3 or songs_played>0,
			func() -> void: choose_approach(approach),16+i*(approach_w+5),191,approach_w,53)

	var cue_label := _label(board,"GigCueHeading","3  /  SETLIST  /  THREE ORIGINALS",14,INK,"display")
	_rect(cue_label,16,251,inner,23)
	var cue_w: float = (inner-10.0)/3.0
	for i in range(3):
		var index: int = i
		var played: bool = i<songs_played
		var name_text: String = ("✓ " if played else "")+SONGS[i]
		_key(board,"GigCue"+str(i),"cue",name_text,played or (selected_song==i and journey_step==2),
			journey_step!=2 or played or settled,func() -> void: select_song(index),
			16+i*(cue_w+5),275,cue_w,61)
	_key(board,"GigHold","hold","RELEASE HOLD" if held else "HOLD / PAUSE",
		held,journey_step!=2 or settled,toggle_hold,16,345,half,61)
	_key(board,"GigGo","go","GO / NEXT CUE" if songs_played<3 else "SET COMPLETE",
		false,not can_go(),fire_go,23+half,345,half,61)
	_key(board,"GigEncore","encore","ENCORE CALLED" if encore_fired else "OPTIONAL ENCORE",
		encore_fired,not can_encore(),fire_encore,16,416,inner,51)
	var approach_preview: Dictionary = Circuit.approach_preview(demo_state,selected_approach)
	var note_text: String = "%s / %s / %d OF 3 CUES" % [
		str(approach_preview.get("label","TIGHT SET")),str(approach_preview.get("outlook","RISKY")),songs_played]
	if journey_step==3:
		note_text = "SETTLED ONCE  /  %s" % ("GOOD ROOM" if bool(last.get("success",false)) else "TOUGH NIGHT")
	var note := _label(board,"GigConsequence",note_text,13,Color("#E5D8C3"),"numbers")
	_rect(note,16,478,inner,48)

	var dock := Panel.new()
	dock.name = "GigActionDock"
	dock.add_theme_stylebox_override("panel",_panel(Color("#F0E5D2") if day else Color("#203139"),Color("#C7A779")))
	_surface.add_child(dock)
	_rect(dock,12,h-dock_h+5,w-24,dock_h-12)
	var primary_text: String = ["OPEN SOUNDCHECK","OPEN THE STAGE","SETTLE THE SHOW","SHOW PAID / ONCE ONLY"][journey_step]
	var enabled: bool = (journey_step==0 and equipment_ready) or (journey_step==1 and soundcheck_ready) or (journey_step==2 and songs_played==3 and not held and not settled)
	var primary_w: float = minf(w-44.0,650.0)
	var primary_x: float = (w-24.0-primary_w)*0.5
	_primary = _key(dock,"GigPrimaryAction","advance",primary_text,journey_step==3,not enabled,
		advance_journey,primary_x,7,primary_w,53)
	_status = _label(dock,"GigActionStatus",_status_line(),12,
		Color("#374F51") if day else Color("#E7E0D4"),"numbers")
	_status.clip_text = true
	_rect(_status,12,65,w-48,24)
