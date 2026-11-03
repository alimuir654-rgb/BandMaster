extends Control
const Finance = preload("res://experiments/playable_flightcase/finance_policy.gd")
const RadioVisit = preload("res://experiments/playable_flightcase/radio_visit_rules.gd")
const SafeArea = preload("res://experiments/playable_flightcase/mobile_safe_area.gd")
const SAFE_BACKDROP = preload("res://components/control_atlas/art/case_surface.png")
## C27 opening; uses existing authentic flight-case UI and controls.
const Model = preload("res://experiments/playable_flightcase/opening_state.gd")
const Recruit = preload("res://experiments/playable_flightcase/ui.gd")
const Kit = preload("res://components/control_atlas/kit.gd")
const Formation = preload("res://Scripts/formation_catalogue.gd")
const BandPoster = preload("res://experiments/playable_flightcase/band_formed_poster.gd")
const IdentityPress = preload("res://experiments/playable_flightcase/band_identity_press.gd")
const IdentityStyle = preload("res://experiments/playable_flightcase/identity_style.gd")
const BandMark = preload("res://experiments/playable_flightcase/band_mark.gd")
const InkNote = preload("res://experiments/playable_flightcase/ink_note.gd")
const GenrePress = preload("res://experiments/playable_flightcase/genre_press.gd")
const Shared = preload("res://experiments/playable_flightcase/career_components.gd")
const SettingsSheet = preload("res://experiments/playable_flightcase/settings_sheet.gd")
const NotesStyle = preload("res://experiments/playable_flightcase/notes_style.gd")
const CareerDesk = preload("res://experiments/playable_flightcase/career_desk.gd")
const LiveRules = preload("res://experiments/playable_flightcase/live_bridge.gd")
const Base = preload("res://experiments/character_cast/vendor/recruitment_catalogue_v3.gd")
const WORDMARK_CROP := Rect2i(264,95,1248,718)
const WORDMARK_SHA256 := "3cbf6a548054aaf7922073b9c447542530a1e5c109c1eace7d3fe9fb780c9899"
static var _opening_wordmark_cache: ImageTexture
var setup = Model.new()
var showing_menu := true
var settings_open := false
var muted := false
var reduced_motion := false
var notice := ""
var look := "flightcase"
var free_name: String = ""
var chosen_intent: String = "Raw"
var response: String = ""
var identity_draft: Dictionary = {}
var _identity_committing := false
var _new_band_dialog: Control
var _settings_sheet: Control
var _practice_view: Control
var _recruit_view: Control
var _career_view: Control
var _fresh_name_reactions := false
var _safe_content_rect := Rect2()
var _safe_area_poll := 0.0

func _ready() -> void:
 set_anchors_and_offsets_preset(PRESET_FULL_RECT)
 _sync_safe_area()
 get_viewport().size_changed.connect(_on_viewport_resized)
 _render()

func _sync_safe_area() -> bool:
 var next: Rect2 = SafeArea.for_root(self)
 if next==_safe_content_rect:
  return false
 _safe_content_rect = next
 offset_left = next.position.x
 offset_top = next.position.y
 offset_right = next.end.x-get_viewport_rect().end.x
 offset_bottom = next.end.y-get_viewport_rect().end.y
 set_meta("safe_content_rect",next)
 queue_redraw()
 return true

func _refresh_safe_area() -> void:
 if _sync_safe_area():
  _on_content_boundary_changed()

func _process(delta: float) -> void:
 # Safe insets can change when system bars return without a viewport resize.
 if not OS.has_feature("mobile") and not has_meta("safe_area_test_sample"):
  return
 _safe_area_poll += delta
 if _safe_area_poll>=0.25:
  _safe_area_poll = 0.0
  _refresh_safe_area()

func _draw() -> void:
 # Keep the original case material under the notch/navigation area. Meaningful
 # content and all input remain in the safe rectangle; this bleed is inert.
 if _safe_content_rect!=get_viewport_rect():
  draw_texture_rect(SAFE_BACKDROP,Rect2(-position,get_viewport_rect().size),false,Color(0.52,0.57,0.61))

func _erase() -> void:
 for old in get_children():
  # A resize rebuilds the menu behind the pending decision. Keeping the
  # original dialog in-tree preserves its focus and once-only callback.
  if is_instance_valid(_new_band_dialog) and old==_new_band_dialog:
   continue
  if is_instance_valid(_settings_sheet) and old==_settings_sheet:
   if showing_menu:
    continue
   _settings_sheet = null
   settings_open = false
  remove_child(old)
  old.queue_free()
 _practice_view = null
 _recruit_view = null
 _career_view = null

func _on_viewport_resized() -> void:
 _sync_safe_area()
 _on_content_boundary_changed()

func _on_content_boundary_changed() -> void:
 # The practice view owns its responsive reflow. Keep its pending form values
 # and presentation-only overlay alive instead of replacing the whole host.
 if not showing_menu and ((setup.screen=="play" and is_instance_valid(_practice_view)) or (setup.screen=="recruit" and is_instance_valid(_recruit_view))):
  return
 var focused: Control = get_viewport().gui_get_focus_owner()
 var semantic_name := ""
 var caret := -1
 if not is_instance_valid(_new_band_dialog) and is_instance_valid(focused) and is_ancestor_of(focused):
  semantic_name = str(focused.name)
  if focused is LineEdit:
   caret = (focused as LineEdit).caret_column
 _render()
 if not semantic_name.is_empty():
  call_deferred("_restore_boundary_focus",semantic_name,caret)

func _restore_boundary_focus(semantic_name: String, caret: int = -1) -> void:
 if not is_inside_tree() or is_instance_valid(_new_band_dialog):
  return
 var current: Control = find_child(semantic_name,true,false) as Control
 if current==null or not current.is_visible_in_tree() or current.focus_mode==Control.FOCUS_NONE:
  return
 if current is Button and (current as Button).disabled:
  return
 current.grab_focus()
 if current is LineEdit and caret>=0:
  (current as LineEdit).caret_column = mini(caret,(current as LineEdit).text.length())

func _label(s: String,size: int = 16) -> Label:
 return Shared.label(s,size,look)

func _button(s: String,fn: Callable,family: String = "action",name: String = "") -> Button:
 var b: Button = Shared.button(s,look,family)
 if not name.is_empty():
  b.name = name
 b.pressed.connect(fn)
 return b

func _identity_button(s: String,fn: Callable,family: String = "action",name: String = "") -> Button:
 var result: Button=_button(s,fn,family,name)
 # This owned editor scrolls. Preserve genuine taps and let a drag propagate
 # to its ScrollContainer, leaving the original Kit resource unchanged.
 result.mouse_filter=Control.MOUSE_FILTER_PASS
 return result

func _column() -> VBoxContainer:
 var v := VBoxContainer.new()
 v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
 v.add_theme_constant_override("separation",12)
 return v

func _wide_stage(root: VBoxContainer, max_width: float = 720.0) -> PanelContainer:
 # Existing source-backed frame, bounded for landscape and sized to the
 # physical phone/tablet safe area. Preserve nine-slice fixed hardware.
 var centre := CenterContainer.new()
 centre.size_flags_horizontal = Control.SIZE_EXPAND_FILL
 root.add_child(centre)
 var stage: PanelContainer = Kit.frame(look,"panel")
 var safe_width: float = maxf(280.0,minf(max_width,size.x - (40.0 if size.x<720 else 80.0)))
 stage.custom_minimum_size.x = safe_width
 stage.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
 centre.add_child(stage)
 return stage

func _make_shell() -> VBoxContainer:
 var bg := TextureRect.new()
 bg.texture = load("res://components/control_atlas/art/case_surface.png")
 bg.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
 bg.stretch_mode = TextureRect.STRETCH_SCALE
 bg.modulate = Color(0.52,0.57,0.61)
 bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
 bg.set_anchors_and_offsets_preset(PRESET_FULL_RECT)
 add_child(bg)
 var outer := MarginContainer.new()
 outer.set_anchors_and_offsets_preset(PRESET_FULL_RECT)
 var narrow := size.x < 720
 for side in ["left","top","right","bottom"]:
  outer.add_theme_constant_override("margin_"+side,16 if narrow else 36)
 add_child(outer)
 var col := _column()
 col.size_flags_vertical = Control.SIZE_EXPAND_FILL
 outer.add_child(col)
 return col

func _render() -> void:
 if not is_inside_tree():
  return
 _erase()
 if showing_menu or setup.screen == "menu":
  _menu()
 elif bool(setup.audition_view().get("held",false)):
  _audition_hold()
 elif setup.screen == "genre":
  _genre()
 elif setup.screen == "recruit":
  _recruit()
 elif setup.screen == "formed":
  _formed()
 elif setup.screen == "name":
  _name()
 elif setup.screen == "name_milestone":
  _milestone_two()
 elif setup.screen == "identity":
  _identity()
 elif setup.screen == "complete":
  _summary()
 elif setup.screen == "play":
  _practice()
 else:
  showing_menu = true
  _menu()
 # GUI picking follows child order, so retain the overlay above the rebuilt
 # menu for input as well as drawing, without triggering exit-tree hooks.
 if is_instance_valid(_new_band_dialog):
  move_child(_new_band_dialog,get_child_count()-1)

func _audition_hold() -> void:
 var root:=_make_shell()
 root.name="AuditionHeldShell"
 var status: Dictionary=setup.audition_view()
 root.add_child(_label("SAVED AUDITION HELD",22))
 root.add_child(_label(str(status.get("message","This saved audition needs review before the opening can continue.")),16))
 if not notice.is_empty():root.add_child(_label(notice,16))
 if status.get("ok",false) and status.get("active",false):
  root.add_child(_button("CLOSE THIS AUDITION",_close_held_audition,"action","AuditionHeldAbort"))
 root.add_child(_button("BACK TO MENU",_home,"action","AuditionHeldMenu"))

func _close_held_audition() -> void:
 var result: Dictionary=setup.audition_action("abort",setup.audition_expected())
 notice=str(result.get("message",""))
 _render()

func _opening_poster_wide() -> bool:
 return size.x >= 900.0 and size.x > size.y

func _opening_poster_gradient() -> GradientTexture2D:
 var ramp := Gradient.new()
 ramp.offsets = PackedFloat32Array([0.0,0.55,1.0])
 ramp.colors = PackedColorArray([
  Color(0.015,0.020,0.025,0.45),
  Color(0.015,0.020,0.025,0.40),
  Color(0.015,0.020,0.025,0.24)
 ])
 var texture := GradientTexture2D.new()
 texture.gradient = ramp
 texture.width = 8
 texture.height = 256
 texture.fill = GradientTexture2D.FILL_LINEAR
 texture.fill_from = Vector2(0.5,0.0)
 texture.fill_to = Vector2(0.5,1.0)
 return texture

func _opening_wordmark_texture() -> ImageTexture:
 if _opening_wordmark_cache!=null:
  return _opening_wordmark_cache
 var source: Texture2D = load("res://experiments/playable_flightcase/art/opening_wordmark.png") as Texture2D
 if source==null:
  return null
 var image: Image = source.get_image()
 if image==null or image.is_empty():
  return null
 if image.is_compressed() and image.decompress()!=OK:
  return null
 if not Rect2i(Vector2i.ZERO,image.get_size()).encloses(WORDMARK_CROP):
  return null
 # Keep the source PNG untouched. Its faint global alpha specks are excluded
 # from fitting by the measured main-ink bounds plus an 8px safety bleed.
 _opening_wordmark_cache = ImageTexture.create_from_image(image.get_region(WORDMARK_CROP))
 return _opening_wordmark_cache

func _opening_poster_hero() -> Control:
 var hero := Control.new()
 hero.name = "OpeningPosterHero"
 hero.mouse_filter = Control.MOUSE_FILTER_IGNORE
 hero.focus_mode = Control.FOCUS_NONE
 hero.clip_contents = true
 hero.size_flags_horizontal = Control.SIZE_EXPAND_FILL

 var plate := TextureRect.new()
 plate.name = "OpeningStageImage"
 plate.texture = load("res://experiments/playable_flightcase/art/opening_stage.png")
 plate.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
 plate.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
 plate.mouse_filter = Control.MOUSE_FILTER_IGNORE
 plate.focus_mode = Control.FOCUS_NONE
 plate.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
 hero.add_child(plate)

 var shade := TextureRect.new()
 shade.name = "OpeningPosterReadabilityShade"
 shade.texture = _opening_poster_gradient()
 shade.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
 shade.stretch_mode = TextureRect.STRETCH_SCALE
 shade.mouse_filter = Control.MOUSE_FILTER_IGNORE
 shade.focus_mode = Control.FOCUS_NONE
 shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
 hero.add_child(shade)

 var inset := MarginContainer.new()
 inset.name = "OpeningPosterTextInset"
 inset.mouse_filter = Control.MOUSE_FILTER_IGNORE
 inset.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
 for side in ["left","right"]:
  inset.add_theme_constant_override("margin_"+side,12 if size.x<600 else 20)
 for side in ["top","bottom"]:
  inset.add_theme_constant_override("margin_"+side,12)
 hero.add_child(inset)

 var copy := VBoxContainer.new()
 copy.name = "OpeningPosterNativeCopy"
 copy.mouse_filter = Control.MOUSE_FILTER_IGNORE
 copy.add_theme_constant_override("separation",8)
 copy.size_flags_horizontal = Control.SIZE_EXPAND_FILL
 copy.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
 inset.add_child(copy)

 var eyebrow := _label("THE MUSIC BUSINESS IS CALLING",14)
 eyebrow.name = "OpeningPosterEyebrow"
 eyebrow.autowrap_mode = TextServer.AUTOWRAP_OFF
 eyebrow.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
 copy.add_child(eyebrow)
 var brand := _label("LIVIN' THE\nDREAM",44 if size.x<600 else 56)
 brand.name = "OpeningPosterBrand"
 brand.autowrap_mode = TextServer.AUTOWRAP_OFF
 brand.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
 copy.add_child(brand)
 var wordmark_texture: ImageTexture = _opening_wordmark_texture()
 if wordmark_texture!=null:
  var wordmark := TextureRect.new()
  wordmark.name = "OpeningPosterWordmark"
  wordmark.texture = wordmark_texture
  wordmark.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
  wordmark.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
  wordmark.mouse_filter = Control.MOUSE_FILTER_IGNORE
  wordmark.focus_mode = Control.FOCUS_NONE
  wordmark.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
  wordmark.set_meta("source_crop_rect",WORDMARK_CROP)
  wordmark.set_meta("source_alpha_nonzero_rect",Rect2i(21,21,1721,866))
  wordmark.set_meta("source_sha256",WORDMARK_SHA256)
  brand.add_child(wordmark)
  # The native text, font, layout and semantic node remain intact. Only its
  # own ink is hidden; self_modulate deliberately leaves the child visible.
  brand.self_modulate.a = 0.0
 var tagline := _label("Three chords. A borrowed van.\nSomething to prove.",16)
 tagline.name = "OpeningPosterTagline"
 tagline.autowrap_mode = TextServer.AUTOWRAP_OFF
 tagline.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
 # Keep small copy readable at the stage's bright highlights. This local
 # caption matte leaves the artwork and the native lettering size intact.
 var caption_matte := PanelContainer.new()
 caption_matte.name = "OpeningPosterCaptionMatte"
 caption_matte.mouse_filter = Control.MOUSE_FILTER_IGNORE
 caption_matte.focus_mode = Control.FOCUS_NONE
 caption_matte.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
 var caption_stock := StyleBoxFlat.new()
 caption_stock.bg_color = Color(0.012,0.015,0.020,0.65)
 caption_stock.content_margin_left = 6
 caption_stock.content_margin_right = 6
 caption_stock.content_margin_top = 0
 caption_stock.content_margin_bottom = 0
 caption_matte.add_theme_stylebox_override("panel",caption_stock)
 copy.add_child(caption_matte)
 caption_matte.add_child(tagline)
 return hero

func _menu() -> void:
 var root := _make_shell()
 var spacer := Control.new()
 spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
 root.add_child(spacer)

 var wide: bool = _opening_poster_wide()
 var stage: PanelContainer = _wide_stage(root,1120.0)
 stage.name = "OpeningPosterStage"
 var layout: BoxContainer = HBoxContainer.new() if wide else VBoxContainer.new()
 layout.name = "OpeningPosterLayout"
 layout.add_theme_constant_override("separation",20 if wide else 12)
 stage.add_child(layout)

 var hero := _opening_poster_hero()
 layout.add_child(hero)
 var actions := _column()
 actions.name = "OpeningPosterActions"
 if wide:
  actions.custom_minimum_size.x = 420
  actions.size_flags_horizontal = Control.SIZE_FILL
  actions.size_flags_vertical = Control.SIZE_SHRINK_CENTER
 layout.add_child(actions)

 actions.add_child(_button("NEW BAND",_new_band,"action","NewBandAction"))
 var pair := HBoxContainer.new()
 pair.name = "OpeningSecondaryActions"
 pair.add_theme_constant_override("separation",8)
 actions.add_child(pair)
 var carry: Button = _button("CONTINUE",_continue,"action","ContinueAction")
 carry.disabled = not setup.has_valid_draft()
 carry.tooltip_text = "No valid band draft to resume." if carry.disabled else "Resume your unfinished band."
 pair.add_child(carry)
 pair.add_child(_button("SETTINGS",_toggle_settings,"tab","SettingsAction"))
 if carry.disabled:
  var reason := _label("Continue unlocks when a band draft has been saved.",13)
  reason.name = "OpeningContinueReason"
  reason.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
  actions.add_child(reason)
 if not OS.has_feature("mobile"):
  actions.add_child(_button("QUIT",func(): get_tree().quit(),"tab","QuitAction"))

 # Settings is one retained original-frame sheet. Adding note preferences must
 # not squeeze the liked poster or hide the no-draft reason on a phone.
 if not is_instance_valid(_settings_sheet):
  _settings_sheet = SettingsSheet.new()
  _settings_sheet.look = look
  _settings_sheet.sound_requested.connect(_toggle_sound)
  _settings_sheet.motion_requested.connect(_toggle_motion)
  _settings_sheet.notes_style_requested.connect(_toggle_notes_style)
  _settings_sheet.closed.connect(_settings_closed)
  add_child(_settings_sheet)
 _settings_sheet.set_preferences(muted,reduced_motion,NotesStyle.caption())
 move_child(_settings_sheet,get_child_count()-1)
 if not notice.is_empty():
  actions.add_child(_label(notice,14))

 var tail := Control.new()
 tail.size_flags_vertical = Control.SIZE_EXPAND_FILL
 root.add_child(tail)
 _opening_poster_fit_hero()
 # A deferred second measurement observes the newly constructed nested minimum
 # sizes without detaching/recreating any control or waiting arbitrary time.
 call_deferred("_opening_poster_fit_hero")

func _opening_poster_fit_hero() -> void:
 var hero: Control = find_child("OpeningPosterHero",true,false) as Control
 var actions: VBoxContainer = find_child("OpeningPosterActions",true,false) as VBoxContainer
 var stage: PanelContainer = find_child("OpeningPosterStage",true,false) as PanelContainer
 var copy: VBoxContainer = find_child("OpeningPosterNativeCopy",true,false) as VBoxContainer
 if hero==null or actions==null or stage==null or copy==null:
  return
 var shell_margin: float = 16.0 if size.x<720.0 else 36.0
 # _make_shell() has two spacer/stage gaps at12px each. Frame chrome is read
 # from the ORIGINAL style, not replaced or assumed to be zero.
 var usable: float = size.y-shell_margin*2.0-24.0
 var chrome: float = stage.get_theme_stylebox("panel").get_minimum_size().y
 var copy_floor: float = copy.get_combined_minimum_size().y+24.0
 var requested: float
 var available: float
 if _opening_poster_wide():
  # Also cover the unchanged isolated project's default1152x648 entry.
  requested = minf(520.0,maxf(300.0,size.y-176.0))
  available = usable-chrome-16.0
 else:
  var tall_tablet: bool = size.x>=600.0 and size.y>size.x
  requested = 500.0 if tall_tablet else 330.0
  available = usable-chrome-12.0-actions.get_combined_minimum_size().y
 # Never hide copy or shrink fonts to claim a fit. If an untested viewport has
 # less than copy_floor available, the native bounds check must expose that.
 hero.custom_minimum_size.y = maxf(copy_floor,minf(requested,available))

func _toggle_settings() -> void:
 if not is_instance_valid(_settings_sheet):
  return
 if settings_open:
  _settings_sheet.close_sheet()
 else:
  settings_open = true
  _settings_sheet.open_sheet(find_child("SettingsAction",true,false) as Control)

func _settings_closed() -> void:
 settings_open = false
 if showing_menu:
  var invoker: Control = find_child("SettingsAction",true,false) as Control
  if invoker!=null:
   invoker.grab_focus()

func _toggle_notes_style() -> void:
 NotesStyle.toggle(get_tree())
 if is_instance_valid(_settings_sheet):
  _settings_sheet.set_preferences(muted,reduced_motion,NotesStyle.caption())

func _new_band() -> void:
 if is_instance_valid(_new_band_dialog):
  return
 if setup.has_valid_draft():
  var dialog: Control = Kit.dialog("Start a new band?","This replaces your saved opening draft. This cannot be undone.",look)
  _new_band_dialog = dialog
  dialog.confirm_text = "REPLACE DRAFT"
  dialog.cancel_text = "KEEP BAND"
  add_child(dialog)
  dialog.completed.connect(func(yes: bool):
   _new_band_dialog = null
   if yes:
    _begin_new()
   else:
    # Responsive reflow may have replaced the original weak invoker.
    var invoker: Button = find_child("NewBandAction",true,false) as Button
    if invoker!=null and invoker.is_visible_in_tree() and not invoker.disabled:
     invoker.grab_focus()
   dialog.queue_free())
  dialog.call_deferred("open_modal")
 else:
  _begin_new()

func _begin_new() -> void:
 if not setup.begin_new():
  notice = "Couldn't save the new band draft."
  _render()
  return
 showing_menu = false
 identity_draft = {}
 free_name = ""
 settings_open = false
 notice = ""
 _render()

func _continue() -> void:
 if setup.load_draft():
  identity_draft = {}
  response = ""
  showing_menu = false
  settings_open = false
  _render()
 else:
  notice = "No valid saved draft was found."
  _render()

func _toggle_sound() -> void:
 muted = not muted
 AudioServer.set_bus_mute(0,muted)
 var action: Button = find_child("SoundAction",true,false) as Button
 if action!=null:
  action.text = "MASTER SOUND: MUTED" if muted else "MASTER SOUND: ON"
  action.tooltip_text = action.text
func _toggle_motion() -> void:
 reduced_motion = not reduced_motion
 var action: Button = find_child("MotionAction",true,false) as Button
 if action!=null:
  action.text = "TRANSITIONS: OFF" if reduced_motion else "TRANSITIONS: ON"
  action.tooltip_text = "Off shows the same results immediately in this play session."
func _home() -> void:
 showing_menu = true
 _render()

func _genre() -> void:
 var root := _make_shell()
 var heading := _label("01 / CHOOSE YOUR SOUND",24)
 root.add_child(heading)
 root.add_child(_label("Your genre sets the starting direction. It does not restrict who you may audition.",14))
 var wide: bool = size.x >= 900.0 and size.x > size.y
 var body: BoxContainer = HBoxContainer.new() if wide else VBoxContainer.new()
 body.name = "GenreWorkspace"
 body.size_flags_horizontal = Control.SIZE_EXPAND_FILL
 body.size_flags_vertical = Control.SIZE_EXPAND_FILL
 body.add_theme_constant_override("separation",18 if wide else 12)
 root.add_child(body)
 var press := GenrePress.new()
 press.configure(setup.game.genre,size)
 if wide:
  press.size_flags_vertical = Control.SIZE_EXPAND_FILL
 else:
  body.add_child(press)
 var scroll := ScrollContainer.new()
 scroll.name = "GenreIndexScroll"
 scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
 scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
 scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
 scroll.follow_focus = true
 if wide:
  scroll.custom_minimum_size.x = 316
  scroll.size_flags_horizontal = Control.SIZE_FILL
 body.add_child(scroll)
 var index := VBoxContainer.new()
 index.name = "GenreChoiceIndex"
 index.size_flags_horizontal = Control.SIZE_EXPAND_FILL
 index.add_theme_constant_override("separation",6)
 scroll.add_child(index)
 for item in Base.genres():
  var name: String = str(item)
  var button: Button = _button(("✓  " if setup.game.genre == name else "") + name.to_upper(),_choose_genre.bind(name),"tab","Genre_"+name.replace(" ","_").replace("/","_"))
  # Keep genuine button taps; let a swipe reach the owning native index.
  button.mouse_filter = Control.MOUSE_FILTER_PASS
  button.toggle_mode = true
  button.button_pressed = setup.game.genre == name
  button.text_overrun_behavior = TextServer.OVERRUN_NO_TRIMMING
  index.add_child(button)
 if wide:
  body.add_child(press)
 var footer := HBoxContainer.new()
 footer.add_theme_constant_override("separation",12)
 root.add_child(footer)
 footer.add_child(_button("‹ MENU",_home,"tab","GenreBackAction"))
 footer.add_child(_button("FIND YOUR PEOPLE ›",_to_recruit,"action","GenreNextAction"))

func _choose_genre(value: String) -> void:
 if not setup.set_genre(value):
  return
 # Genre artwork changes without replacing its native choice index. This
 # retains keyboard focus and the user's scroll position after selection.
 var press: Control = find_child("GenrePress",true,false) as Control
 if press==null:
  _render()
  return
 press.configure(setup.game.genre,size)
 for item in Base.genres():
  var name: String = str(item)
  var button: Button = find_child("Genre_"+name.replace(" ","_").replace("/","_"),true,false) as Button
  if button!=null:
   button.text = ("✓  " if setup.game.genre == name else "")+name.to_upper()
   button.set_pressed_no_signal(setup.game.genre == name)
 _reveal_focused_genre()

func _reveal_focused_genre() -> void:
 # A longer selected description changes the phone's index viewport. Native
 # follow_focus alone does not re-reveal a control whose focus never changed.
 # Wait for container reflow, then reveal the actual focused original button.
 await get_tree().process_frame
 if not is_inside_tree():
  return
 var scroll: ScrollContainer = find_child("GenreIndexScroll",true,false) as ScrollContainer
 var focused: Control = get_viewport().gui_get_focus_owner()
 if scroll!=null and focused!=null and scroll.is_ancestor_of(focused):
  scroll.ensure_control_visible(focused)
func _to_recruit() -> void:
 if setup.to_recruit():
  _render()

func _recruit() -> void:
 var child = Recruit.new()
 child.game = setup.game
 child.onboarding_state = setup
 child.reduced_motion = reduced_motion
 child.role = child.first_missing_audition_role()
 child.selected_index = child.first_audition_candidate_index(child.role)
 child.vocals_panel = child.role=="Singer"
 child.lineup_review = setup.ready()
 _recruit_view = child
 child.lineup_confirmed.connect(_on_lineup)
 child.back_requested.connect(_back_genre)
 child.menu_requested.connect(_home)
 add_child(child)
 child.set_anchors_and_offsets_preset(PRESET_FULL_RECT)

func _back_genre() -> void:
 setup.back_to_genre()
 _render()
func _on_lineup() -> void:
 _render()

func _formed() -> void:
 _cover_milestone("formation")

func _cover_milestone(kind: String) -> void:
 var root: VBoxContainer=_make_shell()
 var wide: bool=size.x>=1000.0 and size.x>size.y
 var formation: bool=kind=="formation"
 var complete: bool=kind=="complete"
 var composition: String="hero" if wide else ("tall" if size.x>=600.0 and size.y>=1000.0 else "")
 var frame: PanelContainer
 var signoff: VBoxContainer
 var holder: VBoxContainer
 var stage_name: String="MilestoneOneStage" if formation else ("ConfirmedIdentityStage" if complete else "MilestoneTwoStage")
 if wide:
  var workspace:=HBoxContainer.new()
  workspace.name=stage_name
  workspace.size_flags_horizontal=Control.SIZE_EXPAND_FILL
  workspace.size_flags_vertical=Control.SIZE_EXPAND_FILL
  workspace.add_theme_constant_override("separation",28)
  root.add_child(workspace)
  var centre:=CenterContainer.new()
  centre.size_flags_horizontal=Control.SIZE_EXPAND_FILL
  centre.size_flags_vertical=Control.SIZE_EXPAND_FILL
  workspace.add_child(centre)
  frame=Kit.frame(look,"panel")
  frame.name="FirstPressCoverFrame"
  frame.custom_minimum_size.x=clampf(size.y*0.66,380.0,560.0)
  frame.size_flags_horizontal=Control.SIZE_SHRINK_CENTER
  frame.size_flags_vertical=Control.SIZE_SHRINK_CENTER
  centre.add_child(frame)
  signoff=_column()
  signoff.custom_minimum_size.x=300.0
  signoff.size_flags_vertical=Control.SIZE_SHRINK_CENTER
  signoff.size_flags_horizontal=Control.SIZE_EXPAND_FILL
  workspace.add_child(signoff)
  var heading: Label=_label("THE FIRST LINEUP." if formation else ("THIS IS YOUR BAND." if complete else "THE NAME'S OFFICIAL."),38)
  heading.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
  heading.add_theme_font_override("font",IdentityStyle.face(IdentityStyle.defaults()))
  signoff.add_child(heading)
 else:
  if not formation:
   var heading: Label=_label("YOU'VE STARTED SOMETHING" if complete else "THE NAME'S OFFICIAL.",22)
   heading.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
   root.add_child(heading)
  holder=_scroll_body(root)
  frame=_wide_stage(holder,760.0)
  frame.name=stage_name
  signoff=root
 var content: VBoxContainer=_column()
 content.add_theme_constant_override("separation",0)
 frame.add_child(content)
 var surface_budget:=Vector2.ZERO
 if wide:
  var frame_skin: StyleBox=frame.get_theme_stylebox("panel")
  surface_budget.x=frame.custom_minimum_size.x-frame_skin.get_content_margin(SIDE_LEFT)-frame_skin.get_content_margin(SIDE_RIGHT)
  surface_budget.y=size.y-72.0-frame_skin.get_content_margin(SIDE_TOP)-frame_skin.get_content_margin(SIDE_BOTTOM)-12.0
 var poster: Control
 if formation:
  poster=BandPoster.new()
  poster.name="BandFormationPoster"
  content.add_child(poster)
 else:
  poster=IdentityPress.new()
  poster.name="CompletedBandPrint" if complete else "NamedMilestonePrint"
  content.add_child(poster)
 var fact: String=""
 if formation:
  fact="TALENT %d / 200  •  %d REMAINING"%[200-setup.remaining(),setup.remaining()]
 elif complete:
  fact=setup.game.genre+" / "+setup.vibe+"\nTALENT "+str(setup.remaining())+"  •  MORALE "+str(setup.game.career.get("morale",55))
 else:
  var delta: int=int(setup.name_delta)
  fact="Everyone's behind it. The band is ready to make it theirs." if delta==3 else ("Not everyone is convinced. You can feel some hesitation." if delta<0 else "Mixed opinions. The name gives the band something to discuss.")
 if wide:
  signoff.add_child(_label("The people are in place. Find the name next." if formation else ("A name, a look and the people behind it. Take it to the rehearsal room." if complete else "Your bandmates have had their say. Choose the look next."),18))
 var facts: Label=_label(fact,16)
 facts.horizontal_alignment=HORIZONTAL_ALIGNMENT_LEFT if wide else HORIZONTAL_ALIGNMENT_CENTER
 signoff.add_child(facts)
 if formation:
  signoff.add_child(_button("NAME THE BAND ›",_start_naming,"action","MilestoneNextAction"))
  signoff.add_child(_button("BACK TO MENU",_home,"tab","MilestoneMenuAction"))
 elif complete:
  signoff.add_child(_button("FIRST PRACTICE ›",_start_playing,"action","StartPlayAction"))
  signoff.add_child(_button("BACK TO MENU",_home,"tab","CompletedMenuAction"))
 else:
  signoff.add_child(_button("MAKE IT YOURS  /  NAME & LOOK ›",_start_identity,"action","NameMilestoneNextAction"))
  signoff.add_child(_button("BACK TO MENU",_home,"tab","NameMilestoneBackAction"))
 if not wide:
  # Budget the real remaining scroll viewport, including wrapped sign-off
  # copy and the unchanged physical actions. Only the people row flexes.
  var shell: MarginContainer=root.get_parent() as MarginContainer
  var available_width: float=size.x-shell.get_theme_constant("margin_left")-shell.get_theme_constant("margin_right")
  var available_height: float=size.y-shell.get_theme_constant("margin_top")-shell.get_theme_constant("margin_bottom")
  available_height-=float(maxi(0,root.get_child_count()-1)*root.get_theme_constant("separation"))
  for sibling in root.get_children():
   if sibling==holder.get_parent(): continue
   if sibling is Label:
    available_height-=IdentityPress.printed_height(sibling,available_width)
   elif sibling is Control:
    available_height-=sibling.get_combined_minimum_size().y
  var frame_skin: StyleBox=frame.get_theme_stylebox("panel")
  surface_budget.x=frame.custom_minimum_size.x-frame_skin.get_content_margin(SIDE_LEFT)-frame_skin.get_content_margin(SIDE_RIGHT)
  surface_budget.y=maxf(1.0,floorf(available_height-frame_skin.get_content_margin(SIDE_TOP)-frame_skin.get_content_margin(SIDE_BOTTOM)-2.0))
 if formation:
  poster.configure(setup.game.roster,setup.lead_vocal_id,size.x,composition,surface_budget)
 else:
  poster.configure(setup.game.roster,setup.lead_vocal_id,setup.name_locked,setup.logo,setup.palette,setup.vibe,size.x,"complete" if complete else "milestone",IdentityStyle.effective(setup.identity_style),composition,surface_budget)

func _scroll_body(root: VBoxContainer) -> VBoxContainer:
 var scroll := ScrollContainer.new()
 scroll.follow_focus=true
 scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
 scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
 root.add_child(scroll)
 var body: VBoxContainer = _column()
 scroll.add_child(body)
 return body

func _start_naming() -> void:
 if setup.start_naming():
  _render()

func _name() -> void:
 var root: VBoxContainer=_make_shell()
 root.add_child(_label("02 / NAME THE BAND",24))
 root.add_child(_label("A name your band can stand behind. Their reactions reflect taste, not a score.",16))
 var body: VBoxContainer=_scroll_body(root)
 body.add_child(_label("BAND NAME",16))
 var field:=LineEdit.new()
 field.name="FreeBandName"
 field.text=setup.name_offer if not setup.name_offer.is_empty() else free_name
 field.max_length=36
 field.custom_minimum_size.y=56
 field.placeholder_text="Your band name"
 field.editable=setup.name_offer.is_empty()
 field.add_theme_font_override("font",IdentityStyle.face(IdentityStyle.defaults()))
 field.add_theme_font_size_override("font_size",26)
 field.add_theme_color_override("font_color",Color("24211d"))
 field.add_theme_color_override("caret_color",Color("884714"))
 var stock:=StyleBoxTexture.new()
 stock.texture=IdentityPress.PAPER
 stock.set_texture_margin_all(8.0)
 stock.set_content_margin_all(12.0)
 field.add_theme_stylebox_override("normal",stock)
 field.add_theme_stylebox_override("read_only",stock)
 field.text_changed.connect(func(value: String):
  free_name=value
  var current: Variant=find_child("NameLiveMark",true,false)
  if current!=null: current.configure(value if not value.is_empty() else "YOUR BAND","Wordmark",IdentityStyle.defaults(),46 if size.x<720 else 64,true,true)
  var submit: Button=find_child("NameSubmitAction",true,false) as Button
  if submit!=null: submit.disabled=value.strip_edges().length()<2)
 field.text_submitted.connect(func(_value: String):
  if setup.name_offer.is_empty(): _submit_free())
 body.add_child(field)
 var proof: PanelContainer=_wide_stage(body,760.0)
 proof.name="NameLiveProof"
 var proof_words: VBoxContainer=_column()
 proof.add_child(proof_words)
 var live_mark:=BandMark.new()
 live_mark.name="NameLiveMark"
 live_mark.configure(field.text if not field.text.is_empty() else "YOUR BAND","Wordmark",IdentityStyle.defaults(),46 if size.x<720 else 64,true,true)
 proof_words.add_child(live_mark)
 if setup.name_offer.is_empty():
  body.add_child(_label("WHAT ARE YOU GOING FOR?",16))
  var intent_grid:=GridContainer.new()
  intent_grid.columns=2
  body.add_child(intent_grid)
  for raw in ["Raw","Dark","Playful","Dreamy"]:
   var tone: String=str(raw)
   intent_grid.add_child(_identity_button(("✓ " if chosen_intent==tone else "")+tone.to_upper(),_set_intent.bind(tone),"tab","NameIntent_"+tone))
  body.add_child(_label("OR TRY AN IDEA",16))
  for raw in setup.suggested_names():
   var entry: Dictionary=raw
   var title: String=str(entry["name"])
   var intent: String=str(entry["intent"])
   body.add_child(_identity_button(title+"  /  "+intent.to_upper(),_submit.bind(title,intent),"tab"))
 else:
  body.add_child(_label("WHAT THE BAND THINKS",18))
  for raw in setup.name_reactions():
   var feeling: Dictionary=raw
   var card: PanelContainer=Kit.frame(look,"ticket")
   body.add_child(card)
   var reaction: Label=InkNote.new()
   reaction.text=str(feeling["name"])+" — "+str(feeling["reaction"]).to_upper()+"\n"+str(feeling["reason"])
   reaction.add_theme_color_override("font_color",Color("eee8dd"))
   card.add_child(reaction)
   if _fresh_name_reactions: reaction.call_deferred("begin",reduced_motion)
  var rethink: Button=_identity_button("ONE MORE IDEA (FREE)",_rethink,"tab","NameRethinkAction")
  rethink.disabled=setup.name_revisions>=1
  body.add_child(rethink)
 if not response.is_empty(): body.add_child(_label(response,16))
 if setup.name_offer.is_empty():
  var submit: Button=_identity_button("ASK THE BAND",_submit_free,"action","NameSubmitAction")
  submit.disabled=free_name.strip_edges().length()<2
  root.add_child(submit)
 else:
  root.add_child(_identity_button("LOCK THE NAME ›",_lock,"action","NameLockAction"))
 root.add_child(_identity_button("BACK TO MENU",_home,"tab","NameBackAction"))
 _fresh_name_reactions=false

func _set_intent(v: String) -> void:
 chosen_intent = v
 call_deferred("_render")
func _submit_free() -> void:
 _submit(free_name,chosen_intent)
func _submit(title: String,intent: String) -> void:
 var result: Dictionary = setup.submit_name(title,intent)
 _fresh_name_reactions = bool(result.get("ok",false))
 response = str(result.get("message",""))
 _render()
func _rethink() -> void:
 var result: Dictionary = setup.rethink_name()
 response = str(result.get("message",""))
 if bool(result.get("ok",false)): free_name = ""
 _render()
func _lock() -> void:
 var result: Dictionary = setup.lock_name()
 response = str(result.get("message",""))
 _render()

func _milestone_two() -> void:
 _cover_milestone("name")

func _load_identity_draft() -> void:
 identity_draft={"logo":setup.logo,"palette":setup.palette,"vibe":setup.vibe,"style":IdentityStyle.effective(setup.identity_style)}

func _start_identity() -> void:
 if setup.start_identity():
  response=""
  _load_identity_draft()
  _render()

func _identity() -> void:
 if identity_draft.is_empty(): _load_identity_draft()
 var root: VBoxContainer=_make_shell()
 root.add_child(_label("03 / NAME & LOOK",24))
 root.add_child(_label("Make it yours. Type, ink and attitude are cosmetic; previews are free.",16))
 var wide: bool=size.x>=1100.0 and size.x>size.y
 var workspace: HBoxContainer
 if wide:
  workspace=HBoxContainer.new()
  workspace.name="IdentityWorkspace"
  workspace.size_flags_horizontal=Control.SIZE_EXPAND_FILL
  workspace.size_flags_vertical=Control.SIZE_EXPAND_FILL
  workspace.add_theme_constant_override("separation",20)
 var controls: VBoxContainer=_column()
 controls.name="IdentityChoices"
 var proof_holder:=VBoxContainer.new()
 proof_holder.name="IdentityPreviewStage"
 proof_holder.size_flags_horizontal=Control.SIZE_EXPAND_FILL
 var proof_width: float=minf(760.0,size.x-(432.0 if wide else (40.0 if size.x<720.0 else 80.0)))
 proof_holder.custom_minimum_size.x=maxf(280.0,proof_width)
 var identity_print:=IdentityPress.new()
 identity_print.name="IdentityPreviewPrint"
 if wide:
  var proof_centre:=CenterContainer.new()
  proof_centre.size_flags_horizontal=Control.SIZE_EXPAND_FILL
  proof_holder.add_child(proof_centre)
  identity_print.custom_minimum_size.x=440.0
  identity_print.size_flags_horizontal=Control.SIZE_SHRINK_CENTER
  proof_centre.add_child(identity_print)
 else:
  proof_holder.add_child(identity_print)
 var choices_scroll:=ScrollContainer.new()
 choices_scroll.follow_focus=true
 choices_scroll.name="IdentityChoicesScroll"
 choices_scroll.horizontal_scroll_mode=ScrollContainer.SCROLL_MODE_DISABLED
 choices_scroll.size_flags_vertical=Control.SIZE_EXPAND_FILL
 choices_scroll.size_flags_horizontal=Control.SIZE_EXPAND_FILL
 if wide:
  root.add_child(workspace)
  choices_scroll.custom_minimum_size.x=340.0
  choices_scroll.size_flags_horizontal=Control.SIZE_FILL
  workspace.add_child(choices_scroll)
  choices_scroll.add_child(controls)
  workspace.add_child(proof_holder)
 else:
  root.add_child(choices_scroll)
  choices_scroll.add_child(controls)
  controls.add_child(proof_holder)
 var proof_budget:=Vector2.ZERO
 if wide:
  var notice_height: float=0.0
  if not response.is_empty():
   var measuring_notice: Label=_label(response,16)
   notice_height=IdentityPress.printed_height(measuring_notice,size.x-72.0)+6.0
   measuring_notice.free()
  # Actual shell: 72margins +33title +23caption +36gaps +102footer.
  proof_budget=Vector2(440.0,maxf(120.0,size.y-266.0-notice_height))
 identity_print.configure(setup.game.roster,setup.lead_vocal_id,setup.name_locked,str(identity_draft["logo"]),str(identity_draft["palette"]),str(identity_draft["vibe"]),size.x,"preview",identity_draft["style"],"",proof_budget)
 controls.add_child(_label("TYPE DIRECTION",16))
 var type_grid:=GridContainer.new()
 type_grid.columns=2
 type_grid.add_theme_constant_override("h_separation",8)
 type_grid.add_theme_constant_override("v_separation",8)
 controls.add_child(type_grid)
 var style: Dictionary=identity_draft["style"]
 for i in range(IdentityStyle.FONTS.size()):
  var kind: String=str(IdentityStyle.FONTS[i])
  var chosen: bool=kind==style["font"]
  var face: Button=_identity_button(("✓ " if chosen else "")+str(IdentityStyle.FONT_LABELS[i]),_identity_choose.bind("font",kind),"tab","IdentityType_"+kind)
  face.toggle_mode=true
  face.set_pressed_no_signal(chosen)
  face.add_theme_font_override("font",IdentityStyle.face({"version":1,"font":kind,"ink":"ivory"}))
  face.add_theme_font_size_override("font_size",22)
  face.custom_minimum_size.y=56.0
  face.tooltip_text=str(IdentityStyle.FONT_LABELS[i])+" type direction. Free preview."
  type_grid.add_child(face)
 controls.add_child(_label("INK COLOUR",16))
 var ink_grid:=GridContainer.new()
 ink_grid.columns=2
 ink_grid.add_theme_constant_override("h_separation",8)
 ink_grid.add_theme_constant_override("v_separation",8)
 controls.add_child(ink_grid)
 for i in range(IdentityStyle.INKS.size()):
  var ink: String=str(IdentityStyle.INKS[i])
  var chosen: bool=ink==style["ink"]
  var choice: Button=_identity_button(("✓ " if chosen else "")+str(IdentityStyle.INK_LABELS[i]),_identity_choose.bind("ink",ink),"tab","IdentityInk_"+ink)
  choice.toggle_mode=true
  choice.set_pressed_no_signal(chosen)
  choice.custom_minimum_size.y=48.0
  choice.add_theme_font_size_override("font_size",16)
  var swatch:=ColorRect.new()
  swatch.name="InkSwatch"
  swatch.color=Color(str(IdentityStyle.INK_HEX[ink]))
  swatch.position=Vector2(7,10)
  swatch.size=Vector2(5,28)
  swatch.mouse_filter=Control.MOUSE_FILTER_IGNORE
  choice.add_child(swatch)
  choice.tooltip_text=str(IdentityStyle.INK_LABELS[i])+" ink. Ivory uses a dark paper proof."
  ink_grid.add_child(choice)
 controls.add_child(_label("MARK TREATMENT",16))
 var treatments:=GridContainer.new()
 treatments.columns=3
 controls.add_child(treatments)
 for raw in Model.LOGOS:
  var treatment: String=str(raw)
  var b: Button=_identity_button(("✓ " if identity_draft["logo"]==treatment else "")+treatment.to_upper(),_design.bind("logo",treatment),"tab","IdentityLogo_"+treatment)
  b.add_theme_font_size_override("font_size",14)
  treatments.add_child(b)
 controls.add_child(_label("ATTITUDE",16))
 var vibes:=GridContainer.new()
 vibes.columns=2
 controls.add_child(vibes)
 for raw in Model.VIBES:
  var value: String=str(raw)
  var b: Button=_identity_button(("✓ " if identity_draft["vibe"]==value else "")+value.to_upper(),_design.bind("vibe",value),"tab","IdentityVibe_"+value)
  b.add_theme_font_size_override("font_size",14)
  vibes.add_child(b)
 var footer:=VBoxContainer.new()
 footer.add_theme_constant_override("separation",6)
 root.add_child(footer)
 if not response.is_empty():
  var commit_notice: Label=_label(response,16)
  commit_notice.name="IdentityCommitNotice"
  footer.add_child(commit_notice)
 footer.add_child(_identity_button("APPLY LOOK & FORM THE BAND ›",_finish,"action","IdentityFinishAction"))
 footer.add_child(_identity_button("BACK TO MENU",_home,"tab","IdentityBackAction"))

func _identity_choose(family: String,value: String) -> void:
 if setup.screen!="identity" or identity_draft.is_empty(): return
 if family=="font" and not IdentityStyle.FONTS.has(value): return
 if family=="ink" and not IdentityStyle.INKS.has(value): return
 if family not in ["font","ink"]: return
 identity_draft["style"][family]=value
 _refresh_identity_preview("Identity"+("Type_" if family=="font" else "Ink_")+value)

func _refresh_identity_preview(focus_name: String) -> void:
 var old_scroll: ScrollContainer=find_child("IdentityChoicesScroll",true,false) as ScrollContainer
 var scroll_value: int=old_scroll.scroll_vertical if old_scroll!=null else 0
 _render()
 var scroll: ScrollContainer=find_child("IdentityChoicesScroll",true,false) as ScrollContainer
 if scroll!=null: scroll.set_deferred("scroll_vertical",scroll_value)
 call_deferred("_restore_boundary_focus",focus_name,-1)

func _design(family: String,value: String) -> void:
 if identity_draft.is_empty(): _load_identity_draft()
 if family=="logo" and Model.LOGOS.has(value): identity_draft["logo"]=value
 elif family=="palette" and Model.PALETTES.has(value): identity_draft["palette"]=value
 elif family=="vibe" and Model.VIBES.has(value): identity_draft["vibe"]=value
 else: return
 _refresh_identity_preview("IdentityLogo_"+value if family=="logo" else "IdentityVibe_"+value)

func _finish() -> void:
 if _identity_committing: return
 _identity_committing=true
 if identity_draft.is_empty(): _load_identity_draft()
 var result: Dictionary=setup.finish_identity(identity_draft["style"],identity_draft)
 _identity_committing=false
 response=str(result.get("message",""))
 _render()

func _summary() -> void:
 _cover_milestone("complete")

func _start_playing() -> void:
 if setup.start_playing():
  _render()
func _practice() -> void:
 var panel = Recruit.new()
 panel.game = setup.game
 panel.opening_owner = setup
 panel.reduced_motion = reduced_motion
 panel.back_requested.connect(_home)
 panel.career_requested.connect(_open_career_desk)
 add_child(panel)
 _practice_view = panel
 panel.set_anchors_and_offsets_preset(PRESET_FULL_RECT)
 if Finance.is_over(setup.game.career) or RadioVisit.locked(setup.game.career) or LiveRules.show_day(setup.game.career):
  call_deferred("_open_career_desk")

func _open_career_desk() -> void:
 if setup.screen!="play" or not is_instance_valid(_practice_view) or bool(_practice_view.get("session_busy")):
  return
 _practice_view.hide()
 if not is_instance_valid(_career_view):
  var desk = CareerDesk.new()
  desk.name = "CareerDesk"
  desk.game = setup.game
  desk.opening_owner = setup
  desk.reduced_motion = reduced_motion
  desk.practice_requested.connect(_return_from_career)
  desk.menu_requested.connect(_home)
  add_child(desk)
  _career_view = desk
 _career_view.call("open_home")
 _career_view.show()
 if Finance.is_over(setup.game.career):
  _career_view.call("_navigate","finance")
  _career_view.call_deferred("_restore_focus","CareerMenuAction")
 elif RadioVisit.locked(setup.game.career):
  _career_view.call("_navigate","recording")
  _career_view.call_deferred("_restore_focus","StudioNote")
 elif LiveRules.show_day(setup.game.career):
  _career_view.call("_navigate","gigs")
  _career_view.call_deferred("_restore_focus","LiveMainAction")
 else:
  _career_view.call_deferred("_restore_focus","CareerNav_home")

func _return_from_career(activity: String = "") -> void:
 if Finance.is_over(setup.game.career):
  if is_instance_valid(_career_view):_career_view.call("_navigate","finance")
  return
 if RadioVisit.locked(setup.game.career):
  if is_instance_valid(_career_view):_career_view.call("_navigate","recording")
  return
 if is_instance_valid(_career_view) and bool(_career_view.get("busy")):
  return
 if is_instance_valid(_career_view):
  _career_view.hide()
 if is_instance_valid(_practice_view):
  # Keep the actual pane and its pending title/setup values. Only refresh the
  # view of the shared, already-saved career after a shop action.
  _practice_view.set("recap_expanded",false)
  _practice_view.set("last_message","Back in the practice room. Choose a session.")
  if activity in ["create","tighten","connect"]:
   _practice_view.set("practice_activity",activity)
  _practice_view.show()
  _practice_view.call("_rebuild")
  _practice_view.call_deferred("_restore_practice_focus","CareerDeskAction")
