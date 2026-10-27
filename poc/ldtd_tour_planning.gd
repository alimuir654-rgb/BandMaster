extends Control
## S04 isolated, playable itinerary and van loading. Real Calendar.book on local
## state; no user://, production saves, gig settlement or invented distances.
const Model = preload("res://Scripts/ldtd_tour_planning_preview.gd")
const Itinerary = preload("res://Scripts/tour_itinerary.gd")
const Circuit = preload("res://Scripts/uk_gig_circuit.gd")
const Ticket = preload("res://Scripts/ldtd_tour_ticket.gd")
const PHASES := ["day", "dusk", "night"]
const CORK := "res://Art/Photography/Formation/corkboard_day_pexels.webp"
const PHOTO := "res://Art/Backgrounds/shared/gear.webp"
const SHEET := "res://Art/UI/TourCraft/itinerary_sheet.svg"
const MAP := "res://Art/UI/TourCraft/route_map.svg"
const FONT_DISPLAY := "res://Art/Fonts/BarlowCondensed-SemiBold.ttf"
const FONT_BODY := "res://Art/Fonts/IBMPlexSans-Variable.ttf"
const FONT_NUMBERS := "res://Art/Fonts/IBMPlexMono-Regular.ttf"
const INK := Color("#26383C")
const CREAM := Color("#F8F0DF")

var local_state: Dictionary = {}
var phase: String = "day"
var stage: String = "planning"
var venue_id: String = "bristol"
var plan_id: String = Itinerary.DRIVE
var van_secured: bool = false
var commits: int = 0
var last_message: String = "Choose the venue and journey, then secure the load."
var _surface: Control
var _scale: float = 1.0
var _primary: TextureButton
var _status: Label
var _stats: Label
var _choice_buttons: Dictionary = {}
var _render_pending: bool = false

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	local_state = Model.sample_state()
	resized.connect(_on_resize)
	call_deferred("_render")

func _on_resize() -> void:
	if is_inside_tree() and not _render_pending:
		_render_pending = true
		call_deferred("_render")

func set_phase(next: String) -> void:
	if PHASES.has(next):
		phase = next
		call_deferred("_render")

func choose_venue(next: String) -> void:
	if stage == "planning" and Model.VENUES.has(next):
		venue_id = next
		# Keep the chosen plan only when the new venue actually offers it.
		if Itinerary.preview(local_state, venue_id, plan_id).is_empty():
			plan_id = Itinerary.DRIVE
		call_deferred("_render")

func choose_plan(next: String) -> void:
	if stage == "planning" and not Itinerary.preview(local_state, venue_id, next).is_empty():
		plan_id = next
		call_deferred("_render")

func toggle_load() -> void:
	if stage == "planning":
		van_secured = not van_secured
		call_deferred("_render")

func plan_preview() -> Dictionary:
	if stage != "planning":
		return {"ok":false,"message":"This booking is already confirmed."}
	return Model.preview(local_state, venue_id, plan_id, van_secured)

func commit_plan() -> void:
	if stage != "planning":
		return
	var result: Dictionary = Model.commit(local_state, venue_id, plan_id, van_secured)
	if not bool(result.get("ok",false)):
		last_message = str(result.get("message","Route unavailable."))
		if is_instance_valid(_status):
			_status.text = last_message
		return
	local_state = result["state"]
	commits += 1
	stage = "confirmed"
	last_message = str(result["message"])
	call_deferred("_render")

func _return_to_gallery() -> void:
	var dest := "res://poc/ldtd_career_scene_shell.tscn"
	if ResourceLoader.exists(dest):
		get_tree().change_scene_to_file(dest)

func _rect(node: Control, x: float, y: float, w: float, h: float) -> void:
	node.position = Vector2(x, y)
	node.size = Vector2(maxf(1.0,w), maxf(1.0,h))

func _font(path: String) -> Font:
	return load(path) as Font if ResourceLoader.exists(path) else null

func _label(parent: Node, node_name: String, caption: String, pt: int, tint: Color, role: String = "body") -> Label:
	var label := Label.new()
	label.name = node_name
	label.text = caption
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.focus_mode = Control.FOCUS_NONE
	label.add_theme_font_size_override("font_size",pt)
	label.add_theme_color_override("font_color",tint)
	var path: String = FONT_DISPLAY if role == "display" else (FONT_NUMBERS if role == "numbers" else FONT_BODY)
	var font: Font = _font(path)
	if font != null:
		label.add_theme_font_override("font",font)
	parent.add_child(label)
	return label

func _panel(fill: Color, border: Color) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = fill
	sb.border_color = border
	sb.set_border_width_all(1)
	sb.set_corner_radius_all(5)
	sb.shadow_color = Color(0.06,0.04,0.02,0.22)
	sb.shadow_size = 7
	sb.shadow_offset = Vector2(0,3)
	return sb

func _ticket(parent: Node, key: String, family: String, caption: String, chosen: bool,
		disabled: bool, action: Callable, x: float, y: float, w: float, h: float) -> TextureButton:
	var ticket = Ticket.new()
	ticket.name = key
	ticket.choice_id = key
	ticket.family = family
	ticket.caption = caption
	ticket.chosen = chosen
	ticket.disabled = disabled
	parent.add_child(ticket)
	_rect(ticket,x,y,w,h)
	ticket.ticket_chosen.connect(func(_id: String) -> void: action.call())
	_choice_buttons[key] = ticket
	return ticket

func _render() -> void:
	_render_pending = false
	if not is_inside_tree():
		return
	for child in get_children():
		remove_child(child)
		child.queue_free()
	_choice_buttons.clear()
	var vp: Vector2 = get_viewport_rect().size
	_scale = maxf(float(DisplayServer.window_get_size().x)/maxf(vp.x,1.0),0.35)
	var w: float = vp.x*_scale
	var h: float = vp.y*_scale
	var narrow: bool = w < 760.0
	var ink: Color = INK if phase == "day" else CREAM
	var quiet: Color = Color("#4D6365") if phase == "day" else Color("#CAD0CC")

	var background := ColorRect.new()
	background.name = "TourBackdrop"
	background.color = Color("#F0E6D6") if phase == "day" else (Color("#33494E") if phase == "dusk" else Color("#142027"))
	background.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(background)
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_surface = Control.new()
	_surface.name = "TourPhysicalSurface"
	_surface.scale = Vector2.ONE/_scale
	add_child(_surface)
	_rect(_surface,0,0,w,h)

	var board := TextureRect.new()
	board.name = "PhotographedTourCork"
	board.texture = load(CORK)
	board.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	board.stretch_mode = TextureRect.STRETCH_SCALE
	board.mouse_filter = Control.MOUSE_FILTER_IGNORE
	board.modulate = Color.WHITE if phase == "day" else (Color("#A6ACAB") if phase == "dusk" else Color("#5B6B70"))
	if phase == "day":
		var grade := Shader.new()
		grade.code = """
shader_type canvas_item;
void fragment() {
	vec4 source = texture(TEXTURE, UV);
	float lum = dot(source.rgb, vec3(0.2126, 0.7152, 0.0722));
	float daylight = pow(clamp(lum,0.0,1.0),0.62);
	float value = mix(0.74,0.94,daylight);
	COLOR = vec4(clamp(vec3(value*1.03,value*0.97,value*0.84)+(source.rgb-vec3(lum))*0.14,0.0,1.0),source.a);
}
"""
		var material := ShaderMaterial.new()
		material.shader = grade
		board.material = material
	_surface.add_child(board)
	_rect(board,0,0,w,h)

	var header := Panel.new()
	header.name = "TourHeader"
	header.add_theme_stylebox_override("panel",_panel(CREAM if phase == "day" else Color("#20333B"),Color("#B9A381")))
	_surface.add_child(header)
	_rect(header,12,9,w-24,83)
	var brand := _label(header,"PlayerFacingTitle","LIVIN’ THE DREAM",23 if narrow else 28,ink,"display")
	_rect(brand,14,8,w-(145 if narrow else 205),37)
	var sub := _label(header,"TourChapter","CH. 03  /  THE ROAD BOOK",13,quiet,"numbers")
	_rect(sub,14,49,w-165,25)
	_ticket(header,"ReturnToGallery","venue","GALLERY",false,false,_return_to_gallery,
		w-(125 if narrow else 160),11,99 if narrow else 130,48)

	for i in range(PHASES.size()):
		var time: String = PHASES[i]
		_ticket(_surface,"Phase"+time.capitalize(),"venue",time.to_upper(),phase==time,false,
			func() -> void: set_phase(time),14+i*96,101,89,46)

	var dock_h: float = 104.0
	var scroll := ScrollContainer.new()
	scroll.name = "TourPlanningScroll"
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	_surface.add_child(scroll)
	_rect(scroll,0,151,w,maxf(130.0,h-151.0-dock_h))
	var page := Control.new()
	page.name = "TourPlanningPage"
	scroll.add_child(page)
	var page_w: float = minf(1180.0,w-24.0)
	var left: float = (w-page_w)*0.5
	var page_h: float = 810.0 if narrow else 640.0
	_rect(page,0,0,w,page_h)
	page.custom_minimum_size = Vector2(w,page_h)

	var photo_w: float = page_w if narrow else 380.0
	var photo_h: float = 99.0 if narrow else 318.0
	var photo_frame := Panel.new()
	photo_frame.name = "TourPhotoFrame"
	photo_frame.clip_contents = true
	photo_frame.add_theme_stylebox_override("panel",_panel(Color("#E3D5BA"),Color("#8F826E")))
	page.add_child(photo_frame)
	_rect(photo_frame,left,7,photo_w,photo_h)
	var photo := TextureRect.new()
	photo.name = "RepoBackedTourHomePhoto"
	photo.texture = load(PHOTO)
	photo.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	photo.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	photo.modulate = Color("#FFF6E3") if phase == "day" else (Color("#91A8B0") if phase == "dusk" else Color("#536A77"))
	photo.mouse_filter = Control.MOUSE_FILTER_IGNORE
	photo_frame.add_child(photo)
	_rect(photo,4,4,photo_w-8,photo_h-8)
	var photo_tag := _label(photo_frame,"TourPhotoCaption","GEAR CHECK  /  BEFORE THE ROAD",12,Color("#F9F2E4"),"numbers")
	photo_tag.add_theme_constant_override("outline_size",3)
	photo_tag.add_theme_color_override("font_outline_color",Color("#16262C"))
	_rect(photo_tag,12,photo_h-27,photo_w-24,23)
	if not narrow:
		var map_frame := TextureRect.new()
		map_frame.name = "AuthoredRouteSketch"
		map_frame.texture = load(MAP)
		map_frame.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		map_frame.stretch_mode = TextureRect.STRETCH_SCALE
		map_frame.mouse_filter = Control.MOUSE_FILTER_IGNORE
		page.add_child(map_frame)
		_rect(map_frame,left+5,333,photo_w-10,215)
		var sketch_caption := _label(page,"RouteSketchCaption","ROUTE SKETCH  /  NOT TO SCALE",13,ink,"numbers")
		_rect(sketch_caption,left+15,551,photo_w-20,24)

	var paper_x: float = left if narrow else left+399.0
	var paper_y: float = 111.0 if narrow else 7.0
	var paper_w: float = page_w if narrow else page_w-399.0
	var paper_h: float = 607.0 if narrow else 577.0
	var paper_material := TextureRect.new()
	paper_material.name = "OriginalClippedItinerarySheet"
	paper_material.texture = load(SHEET)
	paper_material.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	paper_material.stretch_mode = TextureRect.STRETCH_SCALE
	paper_material.mouse_filter = Control.MOUSE_FILTER_IGNORE
	page.add_child(paper_material)
	_rect(paper_material,paper_x,paper_y,paper_w,paper_h)
	var paper := Control.new()
	paper.name = "TourNativeItineraryInk"
	page.add_child(paper)
	_rect(paper,paper_x,paper_y,paper_w,paper_h)
	var inner: float = paper_w-34.0
	var heading := _label(paper,"TourItineraryHeading","BOOK THE ROAD" if stage=="planning" else "SHOW ON THE CALENDAR",
		26 if narrow else 30,INK,"display")
	_rect(heading,16,11,inner,36)
	var booked: Dictionary = local_state.get("booked_show",{})
	_stats = _label(paper,"ReadOnlyTourStats","DAY %d   /   CASH £%d   /   VAN %d%%" % [
		int(local_state.get("tour_day",1)),int(local_state.get("cash",0)),int(local_state.get("van_health",0))],
		13,Color("#4F6265"),"numbers")
	_rect(_stats,16,45,inner,25)
	var venue_label := _label(paper,"VenueChoiceHeading","1  /  PICK A ROOM",14,INK,"display")
	_rect(venue_label,16,76,inner,23)
	var gap: float = 5.0
	var venue_w: float = (inner-gap*2.0)/3.0
	for i in range(Model.VENUES.size()):
		var venue: String = str(Model.VENUES[i])
		var venue_data: Dictionary = Circuit.get_venue(venue)
		var available: bool = not Model.options(local_state,venue).is_empty() or stage=="confirmed"
		_ticket(paper,"Venue"+venue.capitalize(),"venue",str(venue_data.get("city",venue)).to_upper(),
			venue==venue_id,stage=="confirmed" or not available,
			func() -> void: choose_venue(venue),16+i*(venue_w+gap),101,venue_w,53)

	var route_label := _label(paper,"JourneyChoiceHeading","2  /  CHOOSE THE JOURNEY",14,INK,"display")
	_rect(route_label,16,160,inner,22)
	var options: Array = Itinerary.choices(local_state,venue_id)
	for i in range(options.size()):
		var option: Dictionary = options[i]
		var id: String = str(option["id"])
		var caption: String = ("DRIVE HOME" if id==Itinerary.DRIVE else "STAY OVER") + (
			"  /  £%d\nVAN -%d  /  FATIGUE %s%d" % [
				int(option["total_cost"]),int(option["van_wear"]),
				"+" if int(option["fatigue_delta"])>=0 else "",int(option["fatigue_delta"])])
		_ticket(paper,"Journey"+id,"route",caption,id==plan_id,
			stage=="confirmed" or not bool(option["available"]),
			func() -> void: choose_plan(id),16,184+i*75,inner,70)
	var load_label := _label(paper,"LoadChoiceHeading","3  /  CHECK THE VAN AND GEAR",14,INK,"display")
	_rect(load_label,16,341,inner,23)
	var gear_condition: int = int(local_state.get("gear_records",{}).get("amp",{}).get("condition",-1))
	_ticket(paper,"SecureVanLoad","seal",
		("LOAD SECURED  /  AMP %d%%" if van_secured else "SECURE THE LOAD  /  AMP %d%%") % gear_condition,
		van_secured,stage=="confirmed",toggle_load,16,365,inner,55)

	var selected_plan: Dictionary = Itinerary.preview(local_state,venue_id,plan_id)
	var selected_venue: Dictionary = Circuit.get_venue(venue_id)
	var preview: Dictionary = plan_preview()
	var cost_copy: String = "CHOOSE A JOURNEY TO SEE ITS TERMS."
	if not selected_plan.is_empty():
		cost_copy = "%s  /  %s\nTRAVEL £%d  +  ROOM £%d  =  £%d  /  VAN WEAR %d" % [
			str(selected_venue.get("venue","")),str(selected_venue.get("city","")),
			int(selected_plan["travel_cost"]),int(selected_plan["accommodation_cost"]),
			int(selected_plan["total_cost"]),int(selected_plan["van_wear"])]
	var consequence := _label(paper,"RouteConsequence",cost_copy,14,Color("#324D4E"),"body")
	_rect(consequence,16,433,inner,59)
	var line: String = "DAY %d / BOOKED. NO PAYMENT YET." % int(booked.get("day",0)) if stage=="confirmed" else (
		"READY TO RESERVE / NO PAYMENT UNTIL SHOW" if bool(preview.get("ok",false)) else
		str(preview.get("message","Choose your route.")))
	var note := _label(paper,"BookingRuleNote",line,13,Color("#5B5445"),"numbers")
	_rect(note,16,501,inner,46)

	# Always-visible fixed stamp: booking reserves a date but never settles a gig.
	var dock := Panel.new()
	dock.name = "TourActionDock"
	dock.add_theme_stylebox_override("panel",_panel(CREAM if phase=="day" else Color("#23383F"),Color("#B9A17D")))
	_surface.add_child(dock)
	_rect(dock,12,h-dock_h+5,w-24,dock_h-12)
	var stamp_w: float = minf(w-44.0,650.0)
	var stamp_x: float = (w-24.0-stamp_w)*0.5
	_primary = _ticket(dock,"TourConfirmBooking","commit",
		"CONFIRM THE ROUTE  /  NO PAYMENT" if stage=="planning" else "BOOKING CONFIRMED  /  DAY %d" % int(booked.get("day",0)),
		stage=="confirmed",stage!="planning" or not bool(preview.get("ok",false)),
		commit_plan,stamp_x,7,stamp_w,54)
	_status = _label(dock,"TourBookingStatus",
		("BOOKED / £0 SPENT / DAY %d" % int(booked.get("day",0))) if stage=="confirmed" else (
		"CHECK VAN + ROUTE  /  DAY %d  /  NO SAVE WRITES" % int(local_state.get("tour_day",1)) if narrow else last_message),
		13,quiet,"numbers")
	_status.clip_text = true
	_rect(_status,13,65,w-49,24)
