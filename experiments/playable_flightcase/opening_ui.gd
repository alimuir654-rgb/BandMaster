extends Control
const Finance = preload("res://experiments/playable_flightcase/finance_policy.gd")
const SafeArea = preload("res://experiments/playable_flightcase/mobile_safe_area.gd")
const SAFE_BACKDROP = preload("res://components/control_atlas/art/case_surface.png")
## C27 opening; uses existing authentic flight-case UI and controls.
const Model = preload("res://experiments/playable_flightcase/opening_state.gd")
const Recruit = preload("res://experiments/playable_flightcase/ui.gd")
const Kit = preload("res://components/control_atlas/kit.gd")
const Formation = preload("res://Scripts/formation_catalogue.gd")
const BandPoster = preload("res://experiments/playable_flightcase/band_formed_poster.gd")
const IdentityPress = preload("res://experiments/playable_flightcase/band_identity_press.gd")
const InkNote = preload("res://experiments/playable_flightcase/ink_note.gd")
const GenrePress = preload("res://experiments/playable_flightcase/genre_press.gd")
const Shared = preload("res://experiments/playable_flightcase/career_components.gd")
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
var _new_band_dialog: Control
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

 # This frame/control subtree is created once for this menu view. Its visibility
 # and hero size change in place; Sound/Motion still update their own labels.
 var settings: PanelContainer = Kit.frame(look,"panel")
 settings.name = "MenuSettingsPanel"
 settings.visible = settings_open
 actions.add_child(settings)
 var setting_column := _column()
 settings.add_child(setting_column)
 setting_column.add_child(_label("SETTINGS",18))
 var sound: Button = _button("MASTER SOUND: MUTED" if muted else "MASTER SOUND: ON",_toggle_sound,"tab","SoundAction")
 setting_column.add_child(sound)
 var motion: Button = _button("TRANSITIONS: OFF" if reduced_motion else "TRANSITIONS: ON",_toggle_motion,"tab","MotionAction")
 setting_column.add_child(motion)
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
  requested = (340.0 if settings_open else 500.0) if tall_tablet else (196.0 if settings_open else 330.0)
  available = usable-chrome-12.0-actions.get_combined_minimum_size().y
 # Never hide copy or shrink fonts to claim a fit. If an untested viewport has
 # less than copy_floor available, the native bounds check must expose that.
 hero.custom_minimum_size.y = maxf(copy_floor,minf(requested,available))

func _toggle_settings() -> void:
 var panel: Control = find_child("MenuSettingsPanel",true,false) as Control
 if panel==null:
  return
 settings_open = not settings_open
 panel.visible = settings_open
 _opening_poster_fit_hero()
 call_deferred("_opening_poster_fit_hero")

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
 settings_open = false
 notice = ""
 _render()

func _continue() -> void:
 if setup.load_draft():
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
 add_child(child)
 child.set_anchors_and_offsets_preset(PRESET_FULL_RECT)

func _back_genre() -> void:
 setup.back_to_genre()
 _render()
func _on_lineup() -> void:
 _render()

func _formed() -> void:
 var root := _make_shell()
 var headroom := Control.new()
 headroom.size_flags_vertical = Control.SIZE_EXPAND_FILL
 root.add_child(headroom)
 var panel: PanelContainer = _wide_stage(root,760.0)
 panel.name = "MilestoneOneStage"
 var column := _column()
 column.add_theme_constant_override("separation",8 if size.x < 480 else 10)
 panel.add_child(column)
 var poster: Variant = BandPoster.new()
 poster.name = "BandFormationPoster"
 column.add_child(poster)
 poster.configure(setup.game.roster,setup.lead_vocal_id,size.x)
 var budget := _label("TALENT %d / 200  •  %d REMAINING" % [200-setup.remaining(),setup.remaining()],13 if size.x<480 else 15)
 budget.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
 column.add_child(budget)
 column.add_child(_button("NAME THE BAND ›",_start_naming,"action","MilestoneNextAction"))
 column.add_child(_button("BACK TO MENU",_home,"tab","MilestoneMenuAction"))
 var footroom := Control.new()
 footroom.size_flags_vertical = Control.SIZE_EXPAND_FILL
 root.add_child(footroom)

func _scroll_body(root: VBoxContainer) -> VBoxContainer:
 var scroll := ScrollContainer.new()
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
 var root: VBoxContainer = _make_shell()
 root.add_child(_label("02 / NAME THE BAND",24))
 root.add_child(_label("This is about your bandmates' taste, not an objective judgement of your name.",14))
 var body: VBoxContainer = _scroll_body(root)
 body.add_child(_label("THREE IDEAS",18))
 for entry in setup.suggested_names():
  var suggestion: Dictionary = entry
  var title: String = str(suggestion["name"])
  var intent: String = str(suggestion["intent"])
  var option: Button = _button(title+"  /  "+intent.to_upper(),_submit.bind(title,intent),"tab")
  option.disabled = not setup.name_offer.is_empty()
  body.add_child(option)
 body.add_child(_label("OR WRITE YOUR OWN",18))
 var field := LineEdit.new()
 field.name = "FreeBandName"
 field.text = free_name
 field.max_length = 36
 field.custom_minimum_size.y = 48
 field.placeholder_text = "Band name (2–36 characters)"
 field.text_changed.connect(func(v: String): free_name=v)
 body.add_child(field)
 body.add_child(_label("WHAT ARE YOU GOING FOR?",14))
 var intent_grid := GridContainer.new()
 intent_grid.columns = 2
 body.add_child(intent_grid)
 for value in ["Raw","Dark","Playful","Dreamy"]:
  var tone: String = value
  var btn: Button = _button(("✓ " if chosen_intent==tone else "")+tone.to_upper(),_set_intent.bind(tone),"tab")
  btn.disabled = not setup.name_offer.is_empty()
  intent_grid.add_child(btn)
 var submit: Button = _button("ASK THE BAND",_submit_free,"action","NameSubmitAction")
 submit.disabled = not setup.name_offer.is_empty()
 body.add_child(submit)
 if not response.is_empty():
  body.add_child(_label(response,14))
 if not setup.name_offer.is_empty():
  body.add_child(_label("BAND REACTIONS  /  "+setup.name_offer.to_upper(),18))
  for opinion in setup.name_reactions():
   var feeling: Dictionary = opinion
   var card: PanelContainer = Kit.frame(look,"ticket")
   body.add_child(card)
   var reaction: Label = InkNote.new()
   reaction.text = str(feeling["name"])+" — "+str(feeling["reaction"]).to_upper()+"\n"+str(feeling["reason"])
   reaction.add_theme_font_size_override("font_size",16)
   reaction.add_theme_color_override("font_color",Color("eee8dd"))
   card.add_child(reaction)
   if _fresh_name_reactions:
    reaction.call_deferred("begin",reduced_motion)
  var rethink: Button = _button("ONE MORE IDEA (FREE)",_rethink,"tab","NameRethinkAction")
  rethink.disabled = setup.name_revisions>=1
  body.add_child(rethink)
  body.add_child(_button("LOCK THE NAME ›",_lock,"action","NameLockAction"))
 body.add_child(_button("BACK TO MENU",_home,"tab"))
 _fresh_name_reactions = false

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
 free_name = ""
 _render()
func _lock() -> void:
 var result: Dictionary = setup.lock_name()
 response = str(result.get("message",""))
 _render()

func _milestone_two() -> void:
 var root: VBoxContainer = _make_shell()
 var headroom := Control.new()
 headroom.size_flags_vertical = Control.SIZE_EXPAND_FILL
 root.add_child(headroom)
 var card: PanelContainer = _wide_stage(root,700.0)
 card.name = "MilestoneTwoStage"
 var body: VBoxContainer = _column()
 card.add_child(body)
 var eyebrow := _label("MILESTONE 02  /  THE NAME",14)
 eyebrow.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
 body.add_child(eyebrow)
 var heading := _label("THE NAME'S OFFICIAL.",22 if size.x>=720 else 18)
 heading.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
 body.add_child(heading)
 var named_cover: Variant = IdentityPress.new()
 named_cover.name = "NamedMilestonePrint"
 body.add_child(named_cover)
 named_cover.configure(setup.game.roster,setup.lead_vocal_id,setup.name_locked,setup.logo,setup.palette,setup.vibe,size.x,"milestone")
 var delta: int = int(setup.name_delta)
 var reaction := _label("+3 band morale: everyone's behind it." if delta==3 else ("−2 band morale: not everyone's convinced." if delta<0 else "Mixed opinions. One band. No morale change."),15)
 reaction.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
 body.add_child(reaction)
 var settlement := _label("The name is locked. Its consequence is counted once.",13)
 settlement.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
 body.add_child(settlement)
 body.add_child(_button("LOGO & VIBE ›",_start_identity,"action","NameMilestoneNextAction"))
 body.add_child(_button("BACK TO MENU",_home,"tab"))
 var footroom := Control.new()
 footroom.size_flags_vertical = Control.SIZE_EXPAND_FILL
 root.add_child(footroom)
func _start_identity() -> void:
 if setup.start_identity():
  _render()

func _identity() -> void:
 var root: VBoxContainer = _make_shell()
 root.add_child(_label("03 / THE LOOK",24))
 root.add_child(_label("Choose a wordmark, palette and attitude. These choices are cosmetic.",14))
 var body: VBoxContainer = _scroll_body(root)
 # An identity is a poster-width mark, not a portrait-card thumbnail.
 # Reuse the verified bounded original flight-case nine-slice panel.
 var preview: PanelContainer = _wide_stage(body,760.0)
 preview.name = "IdentityPreviewStage"
 var content: VBoxContainer = _column()
 preview.add_child(content)
 # Native live ink, selected C25 previews; no prerendered band-specific art.
 var identity_print: Variant = IdentityPress.new()
 identity_print.name = "IdentityPreviewPrint"
 content.add_child(identity_print)
 identity_print.configure(setup.game.roster,setup.lead_vocal_id,setup.name_locked,setup.logo,setup.palette,setup.vibe,size.x,"preview")
 for family in ["logo","palette","vibe"]:
  body.add_child(_label(family.to_upper(),17))
  var options: Array = Model.LOGOS if family=="logo" else (Model.PALETTES if family=="palette" else Model.VIBES)
  var selected: String = setup.logo if family=="logo" else (setup.palette if family=="palette" else setup.vibe)
  var buttons := GridContainer.new()
  buttons.columns=2 if size.x<720 else 3
  body.add_child(buttons)
  for item in options:
   var value: String = str(item)
   buttons.add_child(_button(("✓ " if value==selected else "")+value.to_upper(),_design.bind(family,value),"tab"))
 # The live design choices may scroll on a 1280x720 landscape screen.
 # Keep the decision control in the shell, not in the scrolling choice list.
 if not response.is_empty():
  body.add_child(_label(response,14))
 body.add_child(_button("BACK TO MENU",_home,"tab"))
 var action_holder := CenterContainer.new()
 action_holder.size_flags_horizontal = Control.SIZE_EXPAND_FILL
 root.add_child(action_holder)
 var finish: Button = _button("FINISH THE BAND ›",_finish,"action","IdentityFinishAction")
 finish.tooltip_text = "Save this band identity and continue to the completed lineup."
 finish.custom_minimum_size.x = maxf(280.0,minf(760.0,size.x - (40.0 if size.x<720 else 80.0)))
 finish.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
 action_holder.add_child(finish)
func _design(family: String,value: String) -> void:
 var mark: String = value if family=="logo" else setup.logo
 var palette: String = value if family=="palette" else setup.palette
 var vibe: String = value if family=="vibe" else setup.vibe
 setup.set_identity(mark,palette,vibe)
 call_deferred("_render")
func _finish() -> void:
 var result: Dictionary = setup.finish_identity()
 response = str(result.get("message",""))
 _render()

func _summary() -> void:
 var root: VBoxContainer = _make_shell()
 var summary_title: Label = _label("YOU'VE STARTED SOMETHING",24)
 summary_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
 root.add_child(summary_title)
 var body: VBoxContainer = _scroll_body(root)
 var card: PanelContainer = _wide_stage(body,760.0)
 var info: VBoxContainer = _column()
 card.add_child(info)
 var finished_print: Variant = IdentityPress.new()
 finished_print.name = "CompletedBandPrint"
 info.add_child(finished_print)
 finished_print.configure(setup.game.roster,setup.lead_vocal_id,setup.name_locked,setup.logo,setup.palette,setup.vibe,size.x,"complete")
 info.add_child(_label(setup.game.genre+"  /  "+setup.vibe+"  /  "+setup.logo,14))
 var roster_grid := GridContainer.new()
 roster_grid.columns = 2 if size.x >= 840 else 1
 roster_grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
 roster_grid.add_theme_constant_override("h_separation",24)
 roster_grid.add_theme_constant_override("v_separation",6)
 info.add_child(roster_grid)
 for p in setup.game.roster:
  roster_grid.add_child(_label(str(p["name"])+(" — LEAD VOCALS" if str(p["id"])==setup.lead_vocal_id else " — "+str(p.get("primary_role","Musician"))),14))
 info.add_child(_label("TALENT REMAINING  "+str(setup.remaining()),16))
 info.add_child(_label("STARTING MORALE  "+str(setup.game.career.get("morale",55)),16))
 var action_holder := CenterContainer.new()
 action_holder.size_flags_horizontal = Control.SIZE_EXPAND_FILL
 body.add_child(action_holder)
 var action_column: VBoxContainer = _column()
 var safe_width: float = maxf(280.0,minf(760.0,size.x - (40.0 if size.x<720 else 80.0)))
 action_column.custom_minimum_size.x = safe_width
 action_column.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
 action_holder.add_child(action_column)
 action_column.add_child(_button("FIRST PRACTICE ›",_start_playing,"action","StartPlayAction"))
 action_column.add_child(_button("BACK TO MENU",_home,"tab"))
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
 if Finance.is_over(setup.game.career) or LiveRules.show_day(setup.game.career):
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
 elif LiveRules.show_day(setup.game.career):
  _career_view.call("_navigate","gigs")
  _career_view.call_deferred("_restore_focus","LiveMainAction")
 else:
  _career_view.call_deferred("_restore_focus","CareerNav_home")

func _return_from_career(activity: String = "") -> void:
 if Finance.is_over(setup.game.career):
  if is_instance_valid(_career_view):_career_view.call("_navigate","finance")
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
