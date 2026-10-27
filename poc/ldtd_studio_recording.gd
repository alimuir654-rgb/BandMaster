extends Control
## S06 isolated studio: photographed hardware, authentic Recording.record/release.
## Monitor settings are audition-only; game outcome meters are read-only.
const Model = preload("res://Scripts/ldtd_studio_recording_preview.gd")
const Fader = preload("res://Scripts/premium_photographic_fader.gd")
const Meter = preload("res://Scripts/premium_photographic_meter.gd")
const Transport = preload("res://Scripts/premium_transport_key.gd")
const Rotary = preload("res://Scripts/ldtd_songwriting_rotary.gd")
const Key = preload("res://Scripts/ldtd_studio_key.gd")
const PHOTO_DAY := "res://Art/Photography/Formation/daylight_music_room_pexels.webp"
const PHOTO_NIGHT := "res://Art/Backgrounds/shared/backstage.webp"
const CHASSIS := "res://Art/UI/StudioCraft/console_chassis.svg"
const FONT_DISPLAY := "res://Art/Fonts/BarlowCondensed-SemiBold.ttf"
const FONT_BODY := "res://Art/Fonts/IBMPlexSans-Variable.ttf"
const FONT_NUMBERS := "res://Art/Fonts/IBMPlexMono-Regular.ttf"
const LIGHT := Color("#F2E8D5")
const DARK := Color("#1D313A")
var demo_state: Dictionary = {}
var stage: String = "ready"
var phase: String = "day"
var transport_armed: bool = false
var monitor_guitar: float = 56.0
var monitor_vocal: float = 61.0
var headphone_focus: float = 53.0
var record_count: int = 0
var release_count: int = 0
var last_message: String = "Arm the studio deck, then record two original songs."
var _surface: Control
var _scale: float = 1.0
var _primary: TextureButton
var _stats: Label
var _status: Label
var _keys: Dictionary = {}
var _controls: Dictionary = {}
var _render_pending: bool = false

func _ready() -> void:
	demo_state = Model.sample_state()
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	resized.connect(_on_resize)
	call_deferred("_render")

func _on_resize() -> void:
	_redraw()

func _redraw() -> void:
	if not _render_pending and is_inside_tree():
		_render_pending = true
		call_deferred("_render")

func set_monitor_level(kind: String, value: float) -> void:
	if stage != "ready":
		return
	if kind == "guitar":
		monitor_guitar = clampf(value,0.0,100.0)
	elif kind == "vocal":
		monitor_vocal = clampf(value,0.0,100.0)
	elif kind == "headphones":
		headphone_focus = clampf(value,0.0,100.0)
	else:
		return
	# Monitor-only input never changes readiness, quality, cash or saved state.
	var label: Label = find_child("StudioMonitorReadout",true,false)
	if label != null:
		label.text = "MONITOR ONLY  /  GTR %d  VOX %d  PHONES %d" % [int(monitor_guitar),int(monitor_vocal),int(headphone_focus)]

func arm_transport(armed: bool) -> void:
	if stage != "ready":
		return
	transport_armed = armed
	_redraw()

func record_demo() -> void:
	if stage != "ready" or not transport_armed or record_count > 0:
		return
	var result: Dictionary = Model.preview_record(demo_state)
	if not bool(result.get("ok",false)):
		last_message = str(result.get("message","Recording unavailable."))
		_redraw()
		return
	demo_state = result["state"]
	stage = "recorded"
	phase = "dusk"
	record_count += 1
	transport_armed = false
	last_message = str(result.get("message","Demo recorded."))
	_redraw()

func release_demo() -> void:
	if stage != "recorded" or release_count > 0:
		return
	var sessions: Array = demo_state.get("recordings",[])
	if sessions.is_empty():
		return
	var result: Dictionary = Model.preview_release(demo_state,sessions.size()-1)
	if not bool(result.get("ok",false)):
		last_message = str(result.get("message","Release unavailable."))
		_redraw()
		return
	demo_state = result["state"]
	stage = "released"
	phase = "night"
	release_count += 1
	last_message = str(result.get("message","Demo released."))
	_redraw()

func _primary_action() -> void:
	if stage == "ready":
		record_demo()
	elif stage == "recorded":
		release_demo()

func _return_to_gallery() -> void:
	var dest: String = "res://poc/ldtd_career_scene_shell.tscn"
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
	s.shadow_color = Color(0.0,0.0,0.0,0.27)
	s.shadow_size = 9
	s.shadow_offset = Vector2(0,3)
	return s

func _key(parent: Node,n: String,family: String,caption: String,chosen: bool,locked: bool,
		action: Callable,x: float,y: float,w: float,h: float) -> TextureButton:
	var k = Key.new()
	k.name = n
	k.choice_id = n
	k.family = family
	k.caption = caption
	k.chosen = chosen
	k.disabled = locked
	parent.add_child(k)
	_rect(k,x,y,w,h)
	k.key_chosen.connect(func(_id: String) -> void: action.call())
	_keys[n] = k
	return k

func _fader(parent: Node,n: String,kind: String,value: float,x: float,y: float,w: float,h: float) -> void:
	var f = Fader.new()
	f.name = n
	f.orientation = "horizontal"
	f.value = value
	f.disabled = stage != "ready"
	parent.add_child(f)
	_rect(f,x,y,w,h)
	f.value_changed.connect(func(next: float) -> void: set_monitor_level(kind,next))
	# Lab05's photographic source says READINESS above its rail. Cover that
	# fixed source word with a small native metal role plate; these are MONITOR
	# faders and must never imply the player can drag a career stat.
	var plate := ColorRect.new()
	plate.name = n+"RolePlate"
	plate.color = Color("#16252D")
	plate.mouse_filter = Control.MOUSE_FILTER_IGNORE
	plate.z_index = 4
	parent.add_child(plate)
	_rect(plate,x+24.0,y+5.0,minf(w-45.0,160.0),22.0)
	var role := _label(parent,n+"NativeRole","GUITAR MONITOR" if kind=="guitar" else "VOCAL MONITOR",
		12,Color("#F1DFC1"),"display")
	role.z_index = 5
	role.clip_text = true
	_rect(role,x+28.0,y+6.0,minf(w-52.0,154.0),21.0)
	_controls[n] = f

func _render() -> void:
	_render_pending = false
	if not is_inside_tree():
		return
	for child in get_children():
		remove_child(child)
		child.queue_free()
	_keys.clear()
	_controls.clear()
	var vp: Vector2 = get_viewport_rect().size
	_scale = maxf(float(DisplayServer.window_get_size().x)/maxf(vp.x,1.0),0.35)
	var w: float = vp.x*_scale
	var h: float = vp.y*_scale
	var narrow: bool = w<760.0
	var day: bool = phase=="day"
	var ink: Color = DARK if day else LIGHT

	var bg := ColorRect.new()
	bg.name = "StudioPhaseBackdrop"
	bg.color = Color("#E8E0D1") if day else (Color("#37474A") if phase=="dusk" else Color("#0D171E"))
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(bg)
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_surface = Control.new()
	_surface.name = "StudioPhysicalSurface"
	_surface.scale = Vector2.ONE/_scale
	add_child(_surface)
	_rect(_surface,0,0,w,h)

	var ambience := TextureRect.new()
	ambience.name = "SourceBackedStudioAtmosphere"
	ambience.texture = load(PHOTO_DAY if day else PHOTO_NIGHT)
	ambience.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	ambience.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	ambience.modulate = Color(1,1,1,0.22) if day else Color(0.65,0.76,0.79,0.24)
	ambience.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_surface.add_child(ambience)
	_rect(ambience,0,0,w,h)

	var header := Panel.new()
	header.name = "StudioHeader"
	header.add_theme_stylebox_override("panel",_panel(Color("#F5EBDC") if day else Color("#1A2B32"),Color("#C6B493")))
	_surface.add_child(header)
	_rect(header,12,9,w-24,82)
	var title := _label(header,"PlayerFacingTitle","LIVIN’ THE DREAM",23 if narrow else 29,ink,"display")
	_rect(title,14,7,w-(148 if narrow else 205),37)
	var chapter := _label(header,"StudioChapter","CH. 05  /  THE RECORDING ROOM",13,Color("#53696C") if day else Color("#C7D4CF"),"numbers")
	_rect(chapter,14,48,w-160,25)
	_key(header,"ReturnToGallery","nav","GALLERY",false,false,_return_to_gallery,w-(126 if narrow else 161),11,100 if narrow else 130,48)

	var phases := ["DAY / RECORD","DUSK / MIX","NIGHT / RELEASE"]
	var gap: float = 6.0
	var step_w: float = (w-28.0-2.0*gap)/3.0
	var selected_phase: int = ["ready","recorded","released"].find(stage)
	for i in range(3):
		var strip := Panel.new()
		strip.name = "StudioPhaseIndicator"+str(i)
		strip.mouse_filter = Control.MOUSE_FILTER_IGNORE
		strip.add_theme_stylebox_override("panel",_panel(Color("#E6D2A7") if selected_phase==i else Color("#20323A"),Color("#B89A64") if selected_phase==i else Color("#56676D")))
		_surface.add_child(strip)
		_rect(strip,14+i*(step_w+gap),101,step_w,43)
		# Native sibling captions remain visible above panel texture.
		var caption_text: String = ["DAY","DUSK","NIGHT"][i] if narrow else phases[i]
		var cap := _label(_surface,"StudioMoment"+str(i),caption_text,
			15,Color("#24343A") if selected_phase==i else LIGHT,"display")
		cap.z_index = 12
		cap.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		cap.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		cap.clip_text = true
		_rect(cap,17+i*(step_w+gap),105,step_w-6,34)

	var dock_h: float = 104.0
	var scroll := ScrollContainer.new()
	scroll.name = "StudioScroll"
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	_surface.add_child(scroll)
	_rect(scroll,0,151,w,maxf(130.0,h-151.0-dock_h))
	var page := Control.new()
	page.name = "StudioPage"
	scroll.add_child(page)
	var page_w: float = minf(1210.0,w-24.0)
	var left: float = (w-page_w)*0.5
	var page_h: float = 870.0 if narrow else 610.0
	_rect(page,0,0,w,page_h)
	page.custom_minimum_size = Vector2(w,page_h)
	var photo_w: float = page_w if narrow else 360.0
	var photo_h: float = 105.0 if narrow else 315.0
	var frame := Panel.new()
	frame.name = "StudioPhotoFrame"
	frame.clip_contents = true
	frame.add_theme_stylebox_override("panel",_panel(Color("#D6C8B0"),Color("#BDA782")))
	page.add_child(frame)
	_rect(frame,left,5,photo_w,photo_h)
	var photo := TextureRect.new()
	photo.name = "SourceBackedStudioPhasePhoto"
	photo.texture = load(PHOTO_DAY if day else PHOTO_NIGHT)
	photo.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	photo.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	photo.mouse_filter = Control.MOUSE_FILTER_IGNORE
	frame.add_child(photo)
	_rect(photo,4,4,photo_w-8,photo_h-8)
	var photo_caption := _label(frame,"StudioPhotoCaption",
		"DAYLIGHT / MUSIC ROOM" if day else ("DUSK / REHEARSAL" if phase=="dusk" else "NIGHT / BACKSTAGE"),
		12,LIGHT,"numbers")
	photo_caption.add_theme_constant_override("outline_size",3)
	photo_caption.add_theme_color_override("font_outline_color",Color("#14242B"))
	_rect(photo_caption,12,photo_h-27,photo_w-24,23)

	if not narrow:
		var side_note := _label(page,"StudioPhotoSideNote",
			"THE SESSION\n\nTWO ORIGINALS\nTWO DAYS TO TRACK\n\nMONITOR THE ROOM.\nTHE SONGS DECIDE QUALITY.",
			19,Color("#283E43") if day else LIGHT,"display")
		_rect(side_note,left+16,335,photo_w-25,175)

	var chassis_x: float = left if narrow else left+380.0
	var chassis_y: float = 118.0 if narrow else 5.0
	var chassis_w: float = page_w if narrow else page_w-380.0
	var chassis_h: float = 690.0 if narrow else 565.0
	var chassis := TextureRect.new()
	chassis.name = "AuthoredStudioMetalChassis"
	chassis.texture = load(CHASSIS)
	chassis.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	chassis.stretch_mode = TextureRect.STRETCH_SCALE
	chassis.mouse_filter = Control.MOUSE_FILTER_IGNORE
	page.add_child(chassis)
	_rect(chassis,chassis_x,chassis_y,chassis_w,chassis_h)
	var desk := Control.new()
	desk.name = "NativeStudioConsole"
	page.add_child(desk)
	_rect(desk,chassis_x,chassis_y,chassis_w,chassis_h)
	var inner: float = chassis_w-36.0
	var heading := _label(desk,"StudioConsoleHeading","THE CONTROL ROOM",25 if narrow else 30,LIGHT,"display")
	_rect(heading,26,14,inner-16,38)
	var summary: String = "DAY %d  /  £%d  /  2 ORIGINALS" % [int(demo_state.get("tour_day",0)),int(demo_state.get("cash",0))]
	if stage!="ready":
		var sessions: Array = demo_state.get("recordings",[])
		var take: Dictionary = sessions.back() if not sessions.is_empty() else {}
		summary = "DAY %d  /  DEMO %d/100  /  £%d" % [int(demo_state.get("tour_day",0)),int(take.get("quality",0)),int(demo_state.get("cash",0))]
	_stats = _label(desk,"ReadOnlyStudioOutcome",summary,13,Color("#E7D8B9"),"numbers")
	_rect(_stats,24,55,inner,25)

	var transport_x: float = 19.0
	var transport_y: float = 86.0
	var transport_w: float = inner-4.0 if narrow else 245.0
	var transport_h: float = 114.0 if narrow else 126.0
	var transport = Transport.new()
	transport.name = "PhotographicStudioTransport"
	transport.finish = "studio"
	desk.add_child(transport)
	_rect(transport,transport_x,transport_y,transport_w,transport_h)
	transport.transport_armed.connect(arm_transport)
	transport.set_armed_from_model(transport_armed)
	if stage!="ready":
		transport.set_locked(true)
	_controls["transport"] = transport

	var fader_x: float = 16.0 if narrow else 285.0
	var fader_w: float = inner-2.0 if narrow else minf(330.0,chassis_w-460.0)
	var fader_y: float = 211.0 if narrow else 90.0
	var fader_h: float = 91.0 if narrow else 111.0
	_fader(desk,"PhotographicGuitarFader","guitar",monitor_guitar,fader_x,fader_y,fader_w,fader_h)
	_fader(desk,"PhotographicVocalFader","vocal",monitor_vocal,fader_x,fader_y+99.0 if narrow else fader_y+130.0,fader_w,fader_h)
		var rotary = Rotary.new()
	rotary.name = "Lab084StudioFocusRotary"
	rotary.control_kind = "focus"
	rotary.read_only = stage!="ready"
	rotary.level = headphone_focus
	desk.add_child(rotary)
	_rect(rotary,17,415 if narrow else 260,127 if narrow else 153,126 if narrow else 151)
	rotary.level_changed.connect(func(next: float) -> void: set_monitor_level("headphones",next))
	_controls["rotary"] = rotary
	var meter = Meter.new()
	meter.name = "ReadOnlyPhotographicReadinessMeter"
	meter.reading = float(demo_state.get("buzz",0))
	desk.add_child(meter)
	_rect(meter,chassis_w-113.0 if narrow else chassis_w-150.0,415 if narrow else 96,
		90 if narrow else 114,185 if narrow else 286)
	_controls["meter"] = meter
	var meter_label := _label(desk,"MeterRole","BUZZ / OUTPUT ONLY",12,Color("#E9D6B3"),"numbers")
	_rect(meter_label,chassis_w-176.0 if narrow else chassis_w-181.0,601 if narrow else 391,
		155,26)
	var monitor := _label(desk,"StudioMonitorReadout",
		"MONITOR ONLY  /  GTR %d  VOX %d  PHONES %d" % [int(monitor_guitar),int(monitor_vocal),int(headphone_focus)],
		12,Color("#E7D8B9"),"numbers")
	_rect(monitor,16,548 if narrow else 433,inner,40)
	var detail: String = "RECORD / £60 / TWO DAYS  /  READINESS %d" % int(demo_state.get("readiness",0)) if stage=="ready" else ("DEMO READY / RELEASE £25 / ONE DAY" if stage=="recorded" else "LOCAL RELEASE OUT / NO SECOND CHARGE")
	var consequence := _label(desk,"StudioRealConsequence",detail,14,LIGHT,"display")
	_rect(consequence,16,619 if narrow else 477,inner,46)

	var dock := Panel.new()
	dock.name = "StudioActionDock"
	dock.add_theme_stylebox_override("panel",_panel(Color("#F0E4CF") if day else Color("#20323A"),Color("#C1A477")))
	_surface.add_child(dock)
	_rect(dock,12,h-dock_h+5,w-24,dock_h-12)
	var ready: bool = stage=="ready" and transport_armed and bool(Model.can_record(demo_state).get("ok",false))
	var can_release: bool = stage=="recorded" and bool(Model.preview_release(demo_state,demo_state.get("recordings",[]).size()-1).get("ok",false))
	var text_value: String = "ARM DECK TO RECORD  /  £60" if not ready else "RECORD TWO-DAY DEMO  /  £60"
	if stage=="recorded":
		text_value = "RELEASE DEMO  /  £25  /  1 DAY"
	elif stage=="released":
		text_value = "RELEASE COMPLETE  /  ONCE ONLY"
	var primary_w: float = minf(w-44.0,650.0)
	_primary = _key(dock,"StudioPrimaryAction","nav",text_value,stage=="released",
		not (ready or can_release),_primary_action,(w-24.0-primary_w)*0.5,7,primary_w,53)
	var footer_text: String = last_message
	if narrow:
		footer_text = "ARM DECK  /  RECORD TWO ORIGINALS" if stage=="ready" else (
			"DEMO READY  /  RELEASE FOR £25" if stage=="recorded" else
			"DEMO OUT  /  +%d FANS  /  +%d PRESS" % [int(demo_state.get("fans",0))-18,int(demo_state.get("press",0))-3])
	_status = _label(dock,"StudioActionStatus",footer_text,14,
		Color("#203B41") if day else LIGHT,"numbers")
	_status.clip_text = true
	_rect(_status,12,65,w-48,24)
