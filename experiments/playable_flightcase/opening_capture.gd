extends SceneTree
## Captures are native GL/Mesa/Xvfb pixels, never flattened mockup art.
const UI = preload("res://experiments/playable_flightcase/opening_ui.gd")
const Group = preload("res://experiments/playable_flightcase/band_lineup.gd")
const Poster = preload("res://experiments/playable_flightcase/band_formed_poster.gd")
const IdentityPress = preload("res://experiments/playable_flightcase/band_identity_press.gd")
const Kit = preload("res://components/control_atlas/kit.gd")
const ApprovedCast = preload("res://experiments/character_cast/catalogue.gd")
const Recap = preload("res://experiments/playable_flightcase/rehearsal_recap.gd")
const RehearsalScreen = preload("res://experiments/playable_flightcase/ui.gd")
const Game = preload("res://experiments/playable_flightcase/session.gd")
const OpeningModel = preload("res://experiments/playable_flightcase/opening_state.gd")
const RecruitBase = preload("res://experiments/character_cast/vendor/recruitment_catalogue_v3.gd")
# Owner-protected passive meter PNG bytes from the verified 33f checkpoint.
const METER_SHA256 := [
 "d6f65ba3beec7a872e476383714c830b69234f190af219c9ba330d12c7a509b3",
 "5cee77d2f5c552b1e2a49916451b06c6e1974510cdc64b799cb34b4e68674770",
 "d9fb9ee0bfada2f00c20f03f54f1f3f276c69de285f5c93c454b3f8b57310c34",
 "f7c76def283b5ced820a6e7fb438d31e36b3b6d795df028204bd86f8294a33e1",
 "7909c750f2873aede2a18167b8bec01a034b804dabfb6857e27592f94487dff8",
 "798be62f2cabc0861d00a549bcb96fe6a913ff04559da200e0db104c239c8f28",
 "e779694ac1097605130127250e810518f3e4d2d0ee0432b36630377a8cd34497",
 "b1c2cf23627dbea16cd8aed671af2ccc5afe01c3162e0716b770a205b1459e04",
 "f2377576fa2cada0de19217cd4c2168c6eb1d9d04751d84edde840b05a6a4aed",
 "55af8861e00b8ff7a5dca6fed6c348529722241422b4a9b2ae4b8aeec5209688",
 "fe655bc9b7b7221f6479e8f5764db38c8f14498fc5990691e2234094d2f1be04",
]
var failures: Array[String] = []
func _init() -> void:
 call_deferred("take")
func _draw_screen(name: String,w: int,h: int) -> void:
 await process_frame
 await process_frame
 # Standard screenshots document settled notes. The dedicated ink probe must
 # capture actual partial/full phases separately; never force-complete here.
 var deadline: int = Time.get_ticks_msec()+4500
 while Time.get_ticks_msec()<deadline:
  var revealing := false
  for note in root.find_children("*","Label",true,false):
   if note.is_visible_in_tree() and note.has_method("is_revealing") and note.is_revealing():
    revealing = true
    break
  if not revealing:
   break
  await process_frame
 for note in root.find_children("*","Label",true,false):
  if note.is_visible_in_tree() and note.has_method("is_revealing") and note.is_revealing():
   failures.append("S43 note reveal did not settle within its bounded duration")
 await RenderingServer.frame_post_draw
 var img: Image = root.get_texture().get_image()
 var dest := "/tmp/c27-%s-%dx%d.png" % [name,w,h]
 if img == null or img.is_empty() or img.get_width()!=w or img.get_height()!=h:
  failures.append("invalid "+name+" image dimensions")
 elif img.save_png(dest)!=OK:
  failures.append("could not save "+dest)
# S37: native proof of source-backed saved lineup and Unicode name.
func _check_identity_press(screen: Control, component_name: String, expected_name: String, logo: String) -> void:
 var proof: Variant = screen.find_child(component_name,true,false)
 if proof==null:
  failures.append("S37 missing identity component "+component_name)
  return
 if proof.mouse_filter!=Control.MOUSE_FILTER_IGNORE or proof.focus_mode!=Control.FOCUS_NONE:
  failures.append("S37 identity artwork stole input/focus: "+component_name)
 if proof.visible_ids()!=["cast_jack","cast_zoe","cast_casey"]:
  failures.append("S37 selected group changed: "+component_name+" "+str(proof.visible_ids()))
 var full_name: Label = proof.find_child("IdentityFullName",true,false) as Label
 var mark: Label = proof.find_child("IdentityLiveMark",true,false) as Label
 if full_name==null or full_name.text!=expected_name:
  failures.append("S37 live full band name lost: "+component_name)
 if mark==null or mark.text.is_empty() or (logo=="Stamp" and not mark.text.begins_with("— ")):
  failures.append("S37 selected logo missing as live text: "+component_name)
 var paper: PanelContainer = proof.find_child("IdentityPressPaper",true,false) as PanelContainer
 if paper==null or not paper.get_theme_stylebox("panel") is StyleBoxTexture:
  failures.append("S37 identity press missing source paper: "+component_name)
 for pid in ["cast_jack","cast_zoe","cast_casey"]:
  var photo: TextureRect = proof.find_child("IdentityPortrait_"+pid,true,false) as TextureRect
  if photo==null or photo.texture==null or photo.texture.get_width()<200 or photo.texture.get_width()>260:
   failures.append("S37 portrait source mismatch: "+component_name+" / "+pid)
  elif photo.focus_mode!=Control.FOCUS_NONE or photo.mouse_filter!=Control.MOUSE_FILTER_IGNORE:
   failures.append("S37 portrait takes input: "+component_name+" / "+pid)
 if component_name!="IdentityPreviewPrint" and proof.find_children("IdentityLeadVocal","Label",true,false).size()!=1:
  failures.append("S37 noncompact identity singer count incorrect")

func click_action(button: Button) -> void:
 if button==null or button.disabled:
  failures.append("missing or disabled action")
  return
 var action_name: String = button.name
 for layout_attempt in range(5):
  if button.is_inside_tree() and button.get_global_rect().size.x>=44 and button.get_global_rect().size.y>=44:
   break
  await process_frame
 if not button.is_inside_tree() or button.get_global_rect().size.x<44 or button.get_global_rect().size.y<44:
  failures.append("action has no settled physical geometry: "+button.name)
  return
 # Real controls can sit below the first fold on 390px phones. Scroll the
 # actual in-scene ScrollContainer rather than faking a pressed signal.
 var ancestor: Node = button.get_parent()
 while ancestor != null:
  if ancestor is ScrollContainer:
   (ancestor as ScrollContainer).ensure_control_visible(button)
   await process_frame
   await process_frame
  ancestor = ancestor.get_parent()
 var point := button.get_global_rect().get_center()
 var viewport_size := root.size
 print("C30_NATIVE_ACTION ",button.name," rect=",button.get_global_rect()," point=",point," viewport=",viewport_size)
 if point.x < 0 or point.y < 0 or point.x >= viewport_size.x or point.y >= viewport_size.y:
  failures.append("action remains offscreen after scroll: "+button.name)
  return
 var press := InputEventMouseButton.new()
 press.button_index = MOUSE_BUTTON_LEFT
 press.position = point
 press.global_position = point
 press.pressed = true
 Input.parse_input_event(press)
 await process_frame
 var release := InputEventMouseButton.new()
 release.button_index = MOUSE_BUTTON_LEFT
 release.position = point
 release.global_position = point
 release.pressed = false
 Input.parse_input_event(release)
 await process_frame
 await process_frame
 await process_frame
 if not root.find_children("SessionTransition","Control",true,false).is_empty():
  await _wait_session_presentation(action_name)

func _wait_session_presentation(action_name: String) -> void:
 var overlays: Array[Node] = root.find_children("SessionTransition","Control",true,false)
 if overlays.is_empty():
  return # A rejected action must not start a presentation.
 var overlay: Control = overlays[0] as Control
 var owner_view: Control = overlay.get_parent() as Control
 var count_after: int = int(owner_view.game.career.get("action_count",0))
 var before_files: Dictionary = _recap_save_bytes()
 for frame in range(120):
  if not is_instance_valid(overlay):
   break
  if bool(overlay.get("_has_covered")):
   await _draw_screen("session_beat_"+action_name,root.size.x,root.size.y)
   break
  await process_frame
 if is_instance_valid(overlay) and str(overlay.get("focus_kind"))=="day":
  # DAY is deliberately player-held. Use real native input here rather than
  # click_action(), which would recursively enter this same wait helper.
  var acknowledge: Button = overlay.find_child("SkipSessionBeatAction",true,false) as Button
  var viewport_bounds := Rect2(Vector2.ZERO,Vector2(root.size))
  if acknowledge==null or not acknowledge.is_visible_in_tree() or not acknowledge.has_focus() or acknowledge.size.x<48 or acknowledge.size.y<48 or not viewport_bounds.encloses(acknowledge.get_global_rect()):
   failures.append("S52 held DAY lacks a visible focused48px native acknowledgment: "+action_name)
  else:
   await _recap_key(KEY_ENTER)
 for frame in range(150):
  if not is_instance_valid(overlay):
   break
  await process_frame
 if is_instance_valid(overlay) or bool(owner_view.session_busy):
  failures.append("S41 session presentation did not finish within bounded native frames: "+action_name)
 if int(owner_view.game.career.get("action_count",0))!=count_after or _recap_save_bytes()!=before_files:
  failures.append("S41 presentation changed a committed action or save bytes: "+action_name)
# Real ui_accept input, deliberately separate from the retained pointer proof.
func _recap_key(keycode: int,shift: bool=false) -> void:
 var down := InputEventKey.new()
 down.keycode = keycode
 down.physical_keycode = keycode
 down.shift_pressed = shift
 down.pressed = true
 Input.parse_input_event(down)
 await process_frame
 var up := InputEventKey.new()
 up.keycode = keycode
 up.physical_keycode = keycode
 up.shift_pressed = shift
 up.pressed = false
 Input.parse_input_event(up)
 await process_frame
 await process_frame
 await process_frame

func _recap_save_bytes() -> Dictionary:
 var state: Dictionary = {}
 for path in ["user://c26_playable_sandbox.json","user://c27_opening_draft.json","user://band_profile.json","user://tour_save.json"]:
  state[path] = FileAccess.get_file_as_bytes(path) if FileAccess.file_exists(path) else null
 return state

# Insert into the existing native capture after coordinator authorization.
# Uses its existing UI/OpeningModel preloads and native input/save helpers.
class SettingsNoDraftModel extends OpeningModel:
 func has_valid_draft() -> bool:
  return false

func _settings_panel(screen: Control) -> Control:
 var sound: Button = screen.find_child("SoundAction",true,false)
 if sound==null:
  return null
 var ancestor: Node = sound.get_parent()
 while ancestor!=null and ancestor!=screen:
  if ancestor is PanelContainer:
   return ancestor as Control
  ancestor=ancestor.get_parent()
 return null

func _settings_targets(screen: Control,w: int,h: int,opened: bool,tag: String) -> void:
 var bounds := Rect2(0,0,w,h)
 var action: Button = screen.find_child("SettingsAction",true,false)
 var sound: Button = screen.find_child("SoundAction",true,false)
 if action==null or not action.is_visible_in_tree() or action.size.x<44 or action.size.y<44 or not bounds.encloses(action.get_global_rect()):
  failures.append("S40 "+tag+" Settings target is missing, clipped or smaller than44px")
 if opened:
  var panel := _settings_panel(screen)
  if sound==null or not sound.is_visible_in_tree() or sound.size.x<44 or sound.size.y<44 or not bounds.encloses(sound.get_global_rect()):
   failures.append("S40 "+tag+" open Sound target is missing, clipped or smaller than44px")
  if panel==null or not panel.is_visible_in_tree() or not bounds.encloses(panel.get_global_rect()):
   failures.append("S40 "+tag+" open Settings panel is clipped")
  var motion: Button = screen.find_child("MotionAction",true,false)
  if motion==null or not motion.is_visible_in_tree() or motion.size.x<44 or motion.size.y<44 or not bounds.encloses(motion.get_global_rect()):
   failures.append("S41 "+tag+" Motion target is missing, clipped or smaller than44px")
 elif sound!=null and sound.is_visible_in_tree():
  failures.append("S40 "+tag+" closed Settings still exposes Sound")

func _settings_view(screen: Control) -> Dictionary:
 var view: Dictionary = {}
 for name in ["NewBandAction","ContinueAction","SettingsAction","QuitAction","SoundAction","MotionAction","NotesStyleAction","SettingsBackAction"]:
  var control: Control = screen.find_child(name,true,false)
  if control!=null:
   view[name]={"id":control.get_instance_id(),"rect":control.get_global_rect()}
 return view

func _settings_same_view(screen: Control,before: Dictionary,tag: String) -> void:
 for name in before:
  var control: Control = screen.find_child(name,true,false)
  if control==null or control.get_instance_id()!=int(before[name].id):
   failures.append("S40 "+tag+" sound input recreated menu control "+str(name))
  else:
   var prior: Rect2 = before[name].rect
   var current: Rect2 = control.get_global_rect()
   if not prior.position.is_equal_approx(current.position) or not prior.size.is_equal_approx(current.size):
    failures.append("S40 "+tag+" sound input moved menu control "+str(name))

func _settings_sound_input(screen,w: int,h: int,mouse: bool,keycode: int,tag: String) -> void:
 var sound: Button = screen.find_child("SoundAction",true,false)
 var master: int = AudioServer.get_bus_index("Master")
 if sound==null or master<0:
  failures.append("S40 "+tag+" actual Master sound control unavailable")
  return
 var before_mute: bool = AudioServer.is_bus_mute(master)
 var before: Dictionary = _settings_view(screen)
 var before_state: Dictionary = screen.setup.snapshot()
 var before_files: Dictionary = _recap_save_bytes()
 var pressed: Array[int] = [0]
 var observe: Callable = func(): pressed[0]+=1
 sound.pressed.connect(observe)
 if mouse:
  await click_action(sound)
 else:
  # Consecutive keyboard inputs must work without refocusing the button.
  if not sound.has_focus():
   failures.append("S40 "+tag+" Sound lost focus before consecutive keyboard input")
  await _recap_key(keycode)
 var current: Button = screen.find_child("SoundAction",true,false)
 var actual_mute: bool = AudioServer.is_bus_mute(master)
 if pressed[0]!=1 or actual_mute==before_mute or bool(screen.muted)!=actual_mute:
  failures.append("S40 "+tag+" genuine sound input did not toggle actual Master once")
 if current==null or current.text!=("MASTER SOUND: MUTED" if actual_mute else "MASTER SOUND: ON") or current.tooltip_text!=current.text or not current.has_focus():
  failures.append("S40 "+tag+" sound label/focus does not follow actual Master state")
 _settings_same_view(screen,before,tag)
 _settings_targets(screen,w,h,true,tag)
 if is_instance_valid(sound) and sound.pressed.is_connected(observe):
  sound.pressed.disconnect(observe)
 if screen.setup.snapshot()!=before_state or _recap_save_bytes()!=before_files:
  failures.append("S40 "+tag+" sound input changed career or save bytes")

func _check_menu_settings(screen,w: int,h: int,tag: String) -> void:
 await process_frame
 await process_frame
 var before: Dictionary = screen.setup.snapshot()
 var files: Dictionary = _recap_save_bytes()
 var orphan_before: int = int(Performance.get_monitor(Performance.OBJECT_ORPHAN_NODE_COUNT))
 var master: int = AudioServer.get_bus_index("Master")
 if master<0:
  failures.append("S40 "+tag+" Master audio bus missing")
  return
 var original_mute: bool = AudioServer.is_bus_mute(master)
 var settings: Button = screen.find_child("SettingsAction",true,false)
 if settings==null:
  failures.append("S40 "+tag+" existing Settings action missing")
  return
 var settings_id: int = settings.get_instance_id()
 _settings_targets(screen,w,h,false,tag+" initial")
 for cycle in range(2):
  settings=screen.find_child("SettingsAction",true,false)
  if settings==null:
   failures.append("S40 "+tag+" Settings action disappeared")
   break
  if cycle==0:
   await click_action(settings)
  else:
   settings.grab_focus()
   await _recap_key(KEY_ENTER)
  _settings_targets(screen,w,h,true,tag+" opened")
  var opened_settings: Button = screen.find_child("SettingsAction",true,false)
  var sound: Button = screen.find_child("SoundAction",true,false)
  if opened_settings==null or opened_settings.get_instance_id()!=settings_id:
   failures.append("S40 "+tag+" disclosure recreated Settings action")
  if sound==null or opened_settings==null:
   break
  var focused: Control = root.gui_get_focus_owner()
  if focused!=opened_settings and focused!=sound:
   failures.append("S40 "+tag+" opening disclosure lost meaningful focus")
  opened_settings.grab_focus()
  if not await _tab_to(sound,12):
   failures.append("S40 "+tag+" Tab cannot reach visible Sound action")
  if cycle==0:
   await _draw_screen("settings_"+tag+"_open",w,h)
  await _settings_sound_input(screen,w,h,cycle==0,KEY_ENTER,tag+" first input")
  if cycle==0:
   await _draw_screen("settings_"+tag+("_muted" if AudioServer.is_bus_mute(master) else "_unmuted"),w,h)
  await _settings_sound_input(screen,w,h,false,KEY_SPACE,tag+" paired restore")
  var motion: Button = screen.find_child("MotionAction",true,false)
  if motion!=null:
   var motion_view: Dictionary = _settings_view(screen)
   var prior_motion: bool = bool(screen.reduced_motion)
   await click_action(motion)
   if bool(screen.reduced_motion)==prior_motion or not motion.has_focus() or motion.text!=("TRANSITIONS: OFF" if screen.reduced_motion else "TRANSITIONS: ON"):
    failures.append("S41 "+tag+" pointer Motion toggle did not update in place")
   _settings_same_view(screen,motion_view,tag+" motion pointer")
   if cycle==0:
    await _draw_screen("settings_"+tag+"_motion_off",w,h)
   await _recap_key(KEY_SPACE)
   if bool(screen.reduced_motion)!=prior_motion or not motion.has_focus():
    failures.append("S41 "+tag+" immediate Space failed to restore Motion without retarget")
   _settings_same_view(screen,motion_view,tag+" motion keyboard")
  var notes_style: Button = screen.find_child("NotesStyleAction",true,false)
  if notes_style==null or notes_style.size.y<48 or not Rect2(0,0,w,h).encloses(notes_style.get_global_rect()):
   failures.append("S52 "+tag+" missing/clipped48px note style choice")
  else:
   var initial_notes: String = notes_style.text
   var notes_view: Dictionary = _settings_view(screen)
   await click_action(notes_style)
   if notes_style.text==initial_notes or not notes_style.has_focus():
    failures.append("S52 "+tag+" real note style toggle failed in place")
   await _recap_key(KEY_SPACE)
   if notes_style.text!=initial_notes or not notes_style.has_focus():
    failures.append("S52 "+tag+" paired note style input failed to restore")
   _settings_same_view(screen,notes_view,tag+" note style keyboard")
  var back: Button = screen.find_child("SettingsBackAction",true,false)
  if back==null or not await _tab_to(back,12):
   failures.append("S52 "+tag+" modal Tab cannot reach Back")
  if cycle==0:
   await _recap_key(KEY_ESCAPE)
  elif back!=null:
   await click_action(back)
  _settings_targets(screen,w,h,false,tag+" closed")
  settings=screen.find_child("SettingsAction",true,false)
  if settings==null or settings.get_instance_id()!=settings_id or not settings.has_focus():
   failures.append("S40 "+tag+" closing disclosure replaced/lost its Settings focus")
 await process_frame
 await process_frame
 if int(Performance.get_monitor(Performance.OBJECT_ORPHAN_NODE_COUNT))>orphan_before:
  failures.append("S40 "+tag+" repeated settings interaction leaked orphan controls")
 if screen.setup.snapshot()!=before or _recap_save_bytes()!=files:
  failures.append("S40 "+tag+" settings changed career/save bytes")
 if AudioServer.is_bus_mute(master)!=original_mute:
  failures.append("S40 "+tag+" paired sound inputs failed to restore original mute")
  AudioServer.set_bus_mute(master,original_mute)
  screen.muted=original_mute
 print("S40_SETTINGS_NATIVE ",JSON.stringify({"case":tag,"width":w,"height":h,"original_master_mute":original_mute,"settings_id":settings_id,"cycles":2}))

func _check_no_draft_settings(screen,w: int,h: int) -> void:
 var files: Dictionary = _recap_save_bytes()
 var before: Dictionary = screen.setup.snapshot()
 screen.hide()
 var fixture=UI.new()
 fixture.name="SettingsNoDraftFixture"
 fixture.setup=SettingsNoDraftModel.new()
 fixture.set_meta("qa_fixture",true)
 root.add_child(fixture)
 await process_frame
 await process_frame
 await process_frame
 # A query-only view fixture does not remove the real saved draft. Existing
 # Kit buttons may receive Tab even while disabled; only activation is gated.
 var carry: Button = fixture.find_child("ContinueAction",true,false)
 var new_band: Button = fixture.find_child("NewBandAction",true,false)
 if carry==null or not carry.disabled:
  failures.append("S40 no-draft query fixture did not disable Continue")
 elif new_band!=null:
  new_band.grab_focus()
  await _recap_key(KEY_TAB)
  if carry.has_focus():
   var disabled_before: Dictionary = fixture.setup.snapshot()
   var disabled_view: Dictionary = _settings_view(fixture)
   await _recap_key(KEY_ENTER)
   if fixture.setup.snapshot()!=disabled_before or not fixture.showing_menu or _recap_save_bytes()!=files:
    failures.append("S40 disabled Continue Enter activated or mutated a saved band")
   _settings_same_view(fixture,disabled_view,"disabled Continue Enter")
 await _check_menu_settings(fixture,w,h,"no_draft_query_fixture")
 fixture.free()
 screen.show()
 await process_frame
 await process_frame
 if screen.setup.snapshot()!=before or _recap_save_bytes()!=files:
  failures.append("S40 no-draft Settings fixture changed real career/save bytes")

# Native overwrite-dialog resize integration. Existing models/components only.
func _overwrite_dialogs(screen: Control) -> Array:
 var active: Array=[]
 for child in screen.get_children():
  if child.has_method("open_modal") and bool(child.get("is_open")):
   active.append(child)
 return active

func _overwrite_observe(dialog,seen: Array,callbacks: Array,accepted: Array) -> void:
 var id: int=dialog.get_instance_id()
 if seen.has(id):
  return
 seen.append(id)
 var track: Callable=func(yes: bool):
  callbacks[0]+=1
  accepted.append(yes)
 dialog.completed.connect(track)

func _overwrite_outside_point(button: Button,panel: Control,w: int,h: int) -> Dictionary:
 var viewport:=Rect2(0,0,w,h).grow(-1.0)
 var available: Rect2=button.get_global_rect().grow(-2.0).intersection(viewport)
 var blocked: Rect2=panel.get_global_rect()
 for fx in [0.0,0.25,0.5,0.75,1.0]:
  for fy in [0.0,0.25,0.5,0.75,1.0]:
   var point: Vector2=available.position+available.size*Vector2(fx,fy)
   if viewport.has_point(point) and button.get_global_rect().has_point(point) and not blocked.has_point(point):
    return {"available":true,"point":point}
 return {"available":false}

func _overwrite_popup_bounds(dialog,w: int,h: int) -> bool:
 var bounds:=Rect2(0,0,w,h)
 if not dialog.is_open or dialog.heading.text!="Start a new band?" or dialog.message_label.text!="This replaces your saved opening draft. This cannot be undone.":
  failures.append("S40 resized overwrite dialog lost its pending canonical warning")
  return false
 if not bounds.encloses(dialog.panel.get_global_rect()):
  failures.append("S40 resized overwrite dialog extends outside physical viewport")
  return false
 for button in [dialog.cancel_button,dialog.confirm_button]:
  if button.size.x<44 or button.size.y<44 or not bounds.encloses(button.get_global_rect()):
   failures.append("S40 resized overwrite action is clipped or smaller than44px")
   return false
 return true

func _overwrite_resize_flow(fixture,w: int,h: int) -> void:
 var original: Dictionary=fixture.setup.snapshot()
 var files: Dictionary=_recap_save_bytes()
 var alternate:=Vector2i(1280,720) if w<1000 else Vector2i(390,844)
 var targets: Array[Vector2i]=[alternate,Vector2i(w,h)]
 var current:=Vector2i(w,h)
 var prefix: String="overwrite_resize_from_%dx%d" % [w,h]
 for leg in range(2):
  var invoker: Button=fixture.find_child("NewBandAction",true,false)
  if invoker==null:
   failures.append("S40 overwrite resize fixture lost NewBand invoker")
   return
  if leg==0:
   await click_action(invoker)
  else:
   if not invoker.has_focus():
    failures.append("S40 resize cancel did not retain semantic NewBand focus for reopen")
    return
   await _recap_key(KEY_ENTER)
  var active: Array=_overwrite_dialogs(fixture)
  if active.size()!=1:
   failures.append("S40 resize flow did not open exactly one existing overwrite dialog")
   return
  var dialog=active[0]
  var callbacks: Array[int]=[0]
  var accepted: Array=[]
  var observed: Array=[]
  _overwrite_observe(dialog,observed,callbacks,accepted)
  if not _overwrite_popup_bounds(dialog,current.x,current.y):
   return
  if not dialog.cancel_button.has_focus():
   failures.append("S40 overwrite resize flow did not start with safe KeepBand focus")
   return
  await _recap_key(KEY_TAB)
  if not dialog.confirm_button.has_focus():
   failures.append("S40 overwrite modal cannot focus confirm before live resize")
   return
  current=targets[leg]
  root.size=current
  DisplayServer.window_set_size(current)
  await process_frame
  await process_frame
  await process_frame
  await process_frame
  active=_overwrite_dialogs(fixture)
  if root.size!=current or DisplayServer.window_get_size()!=current or active.size()!=1 or callbacks[0]!=0:
   failures.append("S40 actual live resize lost or implicitly completed the pending overwrite choice")
   return
  dialog=active[0]
  _overwrite_observe(dialog,observed,callbacks,accepted)
  if not _overwrite_popup_bounds(dialog,current.x,current.y):
   return
  if not dialog.confirm_button.has_focus():
   failures.append("S40 live resize lost focused Confirm")
   return
  for name in ["NewBandAction","SettingsAction"]:
   var background: Button=fixture.find_child(name,true,false)
   if background==null:
    failures.append("S40 overwrite resize fixture lost background menu target")
    return
   var route: Dictionary=_overwrite_outside_point(background,dialog.panel,current.x,current.y)
   if route.available:
    var point: Vector2=route.point
    for down in [true,false]:
     var mouse:=InputEventMouseButton.new()
     mouse.button_index=MOUSE_BUTTON_LEFT
     mouse.position=point
     mouse.global_position=point
     mouse.pressed=down
     Input.parse_input_event(mouse)
     await process_frame
    await process_frame
    await process_frame
    if _overwrite_dialogs(fixture).size()!=1 or callbacks[0]!=0 or fixture.settings_open or not dialog.confirm_button.has_focus():
     failures.append("S40 resized overwrite modal allowed background input or focus loss")
     return
   print("S40_OVERWRITE_BACKGROUND ",JSON.stringify({"from_width":w,"from_height":h,"width":current.x,"height":current.y,"target":name,"outside_point_available":route.available}))
  await _draw_screen(prefix+("_alternate" if leg==0 else "_returned"),current.x,current.y)
  await _recap_key(KEY_TAB)
  if not dialog.cancel_button.has_focus():
   failures.append("S40 resized modal Tab did not stay on KeepBand")
   return
  await _recap_key(KEY_TAB,true)
  if not dialog.confirm_button.has_focus():
   failures.append("S40 resized modal ShiftTab did not stay on Confirm")
   return
  if leg==0:
   await _recap_key(KEY_ESCAPE)
  else:
   await click_action(dialog.cancel_button)
  if callbacks[0]!=1 or accepted!=[false] or not _overwrite_dialogs(fixture).is_empty():
   failures.append("S40 resized Escape/KeepBand did not cancel exactly once")
   return
  var restored: Button=fixture.find_child("NewBandAction",true,false)
  if restored==null or not restored.is_visible_in_tree() or not restored.has_focus():
   failures.append("S40 responsive cancel did not focus the current semantic NewBand invoker")
   return
  if fixture.setup.snapshot()!=original or _recap_save_bytes()!=files:
   failures.append("S40 resize/cancel changed saved career or draft bytes")
   return
 print("S40_OVERWRITE_RESIZE ",JSON.stringify({"width":w,"height":h,"alternate":str(alternate),"callbacks_per_leg":1,"saved_state_unchanged":fixture.setup.snapshot()==original}))

func _check_overwrite_resize(screen,w: int,h: int) -> void:
 var original: Dictionary=screen.setup.snapshot()
 var files: Dictionary=_recap_save_bytes()
 var orphan_before: int=int(Performance.get_monitor(Performance.OBJECT_ORPHAN_NODE_COUNT))
 var clone:=OpeningModel.new()
 if not clone.load_draft() or not clone.has_valid_draft():
  failures.append("S40 overwrite resize fixture requires an actual valid saved draft")
  return
 screen.hide()
 var fixture=UI.new()
 fixture.setup=clone
 fixture.name="OverwriteResizeReadOnlyFixture"
 fixture.set_meta("qa_fixture","actual saved draft clone; no save writes")
 root.add_child(fixture)
 await process_frame
 await process_frame
 await process_frame
 await _overwrite_resize_flow(fixture,w,h)
 # Always restore physical dimensions and the original screen, even after a
 # failed assertion, so this focused proof cannot distort later screenshots.
 root.size=Vector2i(w,h)
 DisplayServer.window_set_size(Vector2i(w,h))
 await process_frame
 await process_frame
 fixture.free()
 screen.show()
 await process_frame
 await process_frame
 if screen.setup.snapshot()!=original or _recap_save_bytes()!=files:
  failures.append("S40 read-only resize fixture changed original career or save bytes")
 if int(Performance.get_monitor(Performance.OBJECT_ORPHAN_NODE_COUNT))>orphan_before:
  failures.append("S40 read-only overwrite resize flow leaked orphan controls")

func _check_practice_layout(screen: Control,w: int,h: int,exercise_choices: bool) -> void:
 var bounds := Rect2(0,0,w,h)
 var before: Dictionary = screen.setup.snapshot()
 var saves: Dictionary = _recap_save_bytes()
 for kind in ["tighten","connect","create"]:
  var mode: Button = screen.find_child("PracticeMode_"+kind,true,false) as Button
  if mode==null or not bounds.encloses(mode.get_global_rect()) or mode.size.x<44 or mode.size.y<44:
   failures.append("S41 free activity choice missing/clipped/too small: "+kind)
   continue
  await click_action(mode)
  var expected_action: String = {"create":"WriteAction","tighten":"RehearseAction","connect":"ClearAirAction"}[kind]
  var visible_actions: Array[String] = []
  for action_name in ["WriteAction","RehearseAction","ClearAirAction"]:
   var action: Button = screen.find_child(action_name,true,false) as Button
   if action!=null and action.is_visible_in_tree():
    visible_actions.append(action_name)
    var practice_scroll: Control = screen.find_child("PracticeScroll",true,false) as Control
    if not bounds.encloses(action.get_global_rect()) or action.size.x<44 or action.size.y<44 or (practice_scroll!=null and practice_scroll.get_global_rect().intersects(action.get_global_rect())):
     failures.append("S41 selected commit missing safe first-fold physical target: "+action_name)
  if visible_actions!=[expected_action]:
   failures.append("S41 activity must have exactly one committing action: "+kind)
  var summary: Label = screen.find_child("PracticeCommitment",true,false) as Label
  var cost: Label = screen.find_child("PracticeTimeCost",true,false) as Label
  var back: Button = screen.find_child("PracticeBackAction",true,false) as Button
  if summary==null or cost==null or summary.get_theme_font_size("font_size")<16 or cost.get_theme_font_size("font_size")<16 or not bounds.encloses(summary.get_global_rect()) or not bounds.encloses(cost.get_global_rect()) or not cost.text.contains("1 day"):
   failures.append("S41 actual selected commitment/time cost is not readable in the first fold: "+kind)
  if back==null or not bounds.encloses(back.get_global_rect()) or back.size.y<44:
   failures.append("S41 activity Back to Menu is missing/clipped/too small")
  if kind=="tighten" and cost!=null and not cost.text.contains("£15"):
   failures.append("S41 rehearsal cost is not the real £15")
  if screen.setup.snapshot()!=before or _recap_save_bytes()!=saves:
   failures.append("S41 previewing an activity changed model/day/cash/save bytes")
  await _draw_screen("practice_mode_%s_day%d" % [kind,int(screen.setup.game.career.get("tour_day",1))],w,h)
 var frame: PanelContainer = screen.find_child("PracticeFrame",true,false) as PanelContainer
 var practice_scroll: ScrollContainer = screen.find_child("PracticeScroll",true,false) as ScrollContainer
 var budget: Label = screen.find_child("BudgetLabel",true,false) as Label
 if practice_scroll==null or frame==null or budget==null:
  failures.append("S41 practice workspace missing named scroll, paper or budget")
  return
 if frame.get_global_rect().position.x<16 or frame.get_global_rect().end.x>float(w)-16 or not frame.get_theme_stylebox("panel") is StyleBoxTexture:
  failures.append("S41 source paper workspace/bleed escapes horizontal safe area")
 if not budget.text.contains("£"+str(int(screen.setup.game.career.get("cash",0)))) or not bounds.encloses(budget.get_global_rect()):
  failures.append("S41 practice cash/header is clipped or not the actual balance")
 for field_name in ["SongTitle","PracticeLeaderSelector","PracticeIdeaChoices","PracticeArrangementChoices"]:
  var field: Control = screen.find_child(field_name,true,false) as Control
  if field==null or not practice_scroll.get_global_rect().encloses(field.get_global_rect()):
   failures.append("S41 title/leader/idea/arrangement is below first fold: "+field_name)
 if not exercise_choices:
  return
 var ideas: Control = screen.find_child("PracticeIdeaChoices",true,false) as Control
 if ideas==null:
  failures.append("S41 original idea choices missing")
  return
 var owner: Node = ideas
 while owner!=null and owner.get_script()!=RehearsalScreen:
  owner = owner.get_parent()
 var buttons: Array[Node] = ideas.find_children("*","Button",true,false)
 if buttons.size()!=3 or owner==null:
  failures.append("S41 original three idea choices/owner missing")
  return
 for index in [1,2,0]:
  var button: Button = buttons[index] as Button
  var skin: StyleBox = button.get_theme_stylebox("normal")
  var text_width: float = button.get_theme_font("font").get_string_size(button.text,HORIZONTAL_ALIGNMENT_LEFT,-1,button.get_theme_font_size("font_size")).x
  if button.text!=str(["Riff","Lyric","Groove"][index]) or button.clip_text or text_width>button.size.x-skin.get_minimum_size().x+1.0:
   failures.append("S41 original idea label changed or clipped: "+button.text)
  await click_action(button)
  var selected: int = 0
  for peer in buttons:
   if (peer as Button).button_pressed: selected+=1
  if selected!=1 or not button.button_pressed or int(owner.idea_index)!=index:
   failures.append("S41 real idea input lost exclusive selection")
 var forms = screen.find_child("PracticeArrangementChoices",true,false)
 if forms==null or forms.items!=PackedStringArray(["Verse / Chorus","Slow Build","Loose Jam"]):
  failures.append("S41 compact arrangement lost original three model options")
 else:
  for index in [1,2,0]:
   await click_action(forms.next)
   var display: Label = forms.display
   var text_width: float = display.get_theme_font("font").get_string_size(display.text,HORIZONTAL_ALIGNMENT_LEFT,-1,display.get_theme_font_size("font_size")).x
   if forms.selected!=index or int(owner.form_index)!=index or display.text!=str(forms.items[index]) or display.get_theme_font_size("font_size")<16 or display.clip_text or text_width>display.size.x+1.0 or not bounds.encloses(display.get_global_rect()):
    failures.append("S41 native arrangement browsing lost actual value/readable full label")
 if screen.setup.snapshot()!=before or _recap_save_bytes()!=saves:
  failures.append("S41 choosing idea/form mutated career or save bytes")
 practice_scroll.scroll_vertical = 0
 await process_frame
 await process_frame
 print("S41_PRACTICE_LAYOUT ",JSON.stringify({"width":w,"height":h,"cash":budget.text,"choice_round_trip":true,"fixed_commit_actions":1,"free_activity_previews":3}))

func _recruit_person(pane) -> Dictionary:
 var choices: Array = pane.game.choices(str(pane.role))
 var index: int = int(pane.selected_index)
 return choices[index] if index>=0 and index<choices.size() else {}

func _check_recruit_context(pane,w: int,h: int,tag: String) -> void:
 var person := _recruit_person(pane)
 if person.is_empty():
  failures.append("S43 "+tag+" selected candidate is not canonical")
  return
 var viewport := Rect2(0,0,w,h)
 var context: Control = pane.find_child("RecruitDecisionContext",true,false)
 var dock: Control = pane.find_child("RecruitDecisionDock",true,false)
 var strength: Label = pane.find_child("RecruitStrength",true,false)
 var friction: Label = pane.find_child("RecruitFriction",true,false)
 var affordability: Label = pane.find_child("RecruitAffordability",true,false)
 var header: Label = pane.find_child("BudgetLabel",true,false)
 var candidate_name: Label = pane.find_child("RecruitCandidateName",true,false)
 var profile: ScrollContainer = pane.find_child("RecruitProfileScroll",true,false)
 var expected_identity: String = "%s  •  %s" % [str(person.name).to_upper(),str(pane.role).to_upper()]
 if candidate_name==null or candidate_name.text!=expected_identity:
  failures.append("S43 "+tag+" candidate name/role is not the full canonical identity")
 elif profile==null or candidate_name.get_global_rect().position.x<profile.get_global_rect().position.x or candidate_name.get_global_rect().end.x>profile.get_global_rect().end.x:
  failures.append("S43 "+tag+" complete candidate identity escapes profile width")
 elif str(person.id) in ["cast_maya","cast_bex","cast_sam"] and candidate_name.get_line_count()!=1:
  failures.append("S43 "+tag+" short candidate identity/long role wraps despite fixed browse allocation")
 for arrow_name in ["RecruitPreviousAction","RecruitNextAction"]:
  var arrow: Button = pane.find_child(arrow_name,true,false)
  if arrow==null or arrow.size.x<44.0 or arrow.size.x>50.0 or arrow.size.y<48.0:
   failures.append("S43 "+tag+" physical browse chevron allocation changed: "+arrow_name)
 if context==null or dock==null or strength==null or friction==null or affordability==null or header==null or profile==null:
  failures.append("S43 "+tag+" candidate dossier/decision context missing")
  return
 var recruited: bool = RecruitBase.contains(pane.game.roster,str(person.id))
 var heard: bool = recruited or bool(pane.auditioned.get(str(person.id),false))
 if strength.text!="STRENGTH  •  "+str(person.get("strength","Still developing")) or friction.text!="FRICTION  •  "+str(person.get("friction","Unknown")):
  failures.append("S43 "+tag+" complete authored audition notes changed or were truncated")
 for note in [strength,friction]:
  if note.get_theme_font_size("font_size")!=(22 if UI.NotesStyle.handwritten else 16) or note.visible!=heard or not note.has_method("is_revealing") or note.visible_characters_behavior!=TextServer.VC_CHARS_AFTER_SHAPING:
   failures.append("S43 "+tag+" original 16px authored note/reveal guard changed: "+str(note.name))
  if heard and (note.get_global_rect().position.x<profile.get_global_rect().position.x or note.get_global_rect().end.x>profile.get_global_rect().end.x):
   failures.append("S43 "+tag+" audition note escapes readable dossier width: "+str(note.name))
 if heard and strength.get_global_rect().end.y>friction.get_global_rect().position.y:
  failures.append("S43 "+tag+" complete shaped notes overlap while revealing")
 if affordability.get_theme_font_size("font_size")!=16 or not affordability.is_visible_in_tree() or not viewport.encloses(affordability.get_global_rect()) or affordability.get_global_rect().end.y>dock.get_global_rect().position.y:
  failures.append("S43 "+tag+" actual 16px affordability is hidden, clipped or overlaps the fixed dock")
 if not viewport.encloses(context.get_global_rect()) or (w>=840 and w>=h and context.size.x>762.0):
  failures.append("S43 "+tag+" decision context exceeds viewport/bounded desktop width")
 var portrait: TextureRect = pane.find_child("RecruitPortrait",true,false)
 var portrait_path: String = str(person.get("portrait_preview",""))
 if not portrait_path.is_empty() and ResourceLoader.exists(portrait_path):
  if portrait==null or portrait.texture==null or portrait.texture.resource_path!=portrait_path or portrait.focus_mode!=Control.FOCUS_NONE or portrait.mouse_filter!=Control.MOUSE_FILTER_IGNORE:
   failures.append("S43 "+tag+" original canonical portrait changed or takes input/focus")
 else:
  var archive: Label = pane.find_child("RecruitArchivePortrait",true,false) as Label
  if portrait!=null or archive==null or not archive.text.contains("No approved portrait"):
   failures.append("S43 "+tag+" archive candidate invents or hides missing portrait provenance")
 var available: int = int(pane.onboarding_state.remaining()) if pane.onboarding_state!=null else pane.game.remaining()
 var cost: int = RecruitBase.incremental_cost(pane.game.roster,person)
 var expected: String
 if recruited:
  expected = "IN YOUR BAND  •  %d TALENT AVAILABLE" % available
 elif pane.game.roster.size()>=6:
  expected = "BAND FULL  •  6/6 MEMBERS  •  %d TALENT AVAILABLE" % available
 elif cost>available:
  expected = "NEED %d MORE TALENT  •  %d AVAILABLE" % [cost-available,available]
 else:
  expected = "%d TALENT  •  %d AVAILABLE  •  %d AFTER RECRUIT" % [cost,available,available-cost]
 if affordability.text!=expected or header.text!="TALENT %d / 200" % available or not viewport.encloses(header.get_global_rect()):
  failures.append("S43 "+tag+" actual seat-fee/reservation/post-recruit forecast is incorrect")
 var action: Button = pane.find_child("RemoveAction" if recruited else "RecruitAction",true,false)
 var allowed: bool = bool(pane.onboarding_state.can_recruit(str(person.id))) if pane.onboarding_state!=null else RecruitBase.can_add(pane.game.roster,person)
 if action==null:
  failures.append("S43 "+tag+" recruit/remove decision missing")
 else:
  if action.get_parent()!=dock or action.size.x<48 or action.size.y<48 or not viewport.encloses(action.get_global_rect()) or action.disabled!=(false if recruited else (not heard or not allowed)):
   failures.append("S43 "+tag+" native decision is clipped, misplaced or bypasses audition/model guards")
  if not recruited and pane.game.roster.size()>=6 and action.text!="BAND FULL":
   failures.append("S43 "+tag+" full roster implies zero-cost recruitment")
 var audition: Button = pane.find_child("AuditionAction",true,false)
 if audition==null or audition.get_parent()!=dock or audition.size.x<48 or audition.size.y<48 or not viewport.encloses(audition.get_global_rect()):
  failures.append("S43 "+tag+" presentation-only audition is not a visible fixed48px target")
 if not pane.find_children("RoleTab_*","Button",true,false).is_empty():
  failures.append("S43 "+tag+" obsolete recruitment tabs remain")
 var covered: Array = RecruitBase.coverage(pane.game.roster)
 var progress: Array = pane.find_children("AuditionProgress_*","Label",true,false)
 var roles := ["Guitarist","Bassist","Drummer","Singer"]
 var captions := ["GUITAR","BASS","DRUMS","VOICE"]
 if progress.size()!=4:
  failures.append("S43 "+tag+" ordered four-step audition progress missing")
 else:
  for index in range(4):
   var done: bool = covered.has(roles[index]) if index<3 else (pane.onboarding_state!=null and not str(pane.onboarding_state.lead_vocal_id).is_empty())
   var expected_caption: String = ("✓ " if done else str(index+1)+" ")+str(captions[index])
   var label: Label = progress[index]
   if str(label.name)!="AuditionProgress_"+str(roles[index]) or label.text!=expected_caption or label.focus_mode!=Control.FOCUS_NONE or label.mouse_filter!=Control.MOUSE_FILTER_IGNORE:
    failures.append("S43 "+tag+" progress does not reflect original core roles/explicit voice in order")
   elif done and label.get_theme_color("font_color")!=Color("a8ddb5"):
    failures.append("S43 "+tag+" filled/assigned audition stage lost its green indicator")
   elif not done and label.get_theme_color("font_color")==Color("a8ddb5"):
    failures.append("S43 "+tag+" missing/removed stage remains green")
 if pane.find_child("StartAction",true,false)!=null:
  failures.append("S43 "+tag+" Complete Lineup is exposed outside review")
 var ready: bool = bool(pane.onboarding_state.ready()) if pane.onboarding_state!=null else pane.game.can_start()
 var next_step: Button = pane.find_child("ReviewLineupAction" if str(pane.role) in ["Singer","Keyboardist"] else "AuditionNextStepAction",true,false)
 if next_step==null or next_step.disabled!=(not ready if str(pane.role) in ["Singer","Keyboardist"] else not covered.has(str(pane.role))):
  failures.append("S43 "+tag+" explicit Next/Review bypasses actual lineup coverage/readiness")
 var stats: Array = RecruitBase.stats_for(person,str(pane.role))
 for index in range(6):
  var meter: TextureRect = pane.find_child("PassiveMeter"+str(index),true,false)
  var score: int = int(stats[index])
  var path: String = "res://components/control_atlas/art/passive_meter_flightcase_%02d.png" % score
  if meter==null or meter.texture==null or meter.texture.resource_path!=path or int(meter.get("score"))!=score or FileAccess.get_sha256(path)!=METER_SHA256[score]:
   failures.append("S43 "+tag+" original selected passive meter bytes/value changed: "+str(index))
  elif meter.focus_mode!=Control.FOCUS_NONE or meter.mouse_filter!=Control.MOUSE_FILTER_IGNORE:
   failures.append("S43 "+tag+" passive selected stat takes input/focus: "+str(index))
  elif not profile.is_ancestor_of(meter) or meter.size.x<=0 or meter.size.y<=0 or meter.get_global_rect().position.x<profile.get_global_rect().position.x or meter.get_global_rect().end.x>profile.get_global_rect().end.x:
   failures.append("S43 "+tag+" selected meter escapes readable dossier width: "+str(index))
 print("S40_RECRUIT_CONTEXT ",JSON.stringify({"case":tag,"candidate":person.id,"width":w,"height":h,"cost":cost,"available":available,"ready":ready,"copy":affordability.text,"auditioned":heard}))

func _check_recruit_profile_keyboard(pane,w: int,h: int,tag: String) -> void:
 var scroll: ScrollContainer = pane.find_child("RecruitProfileScroll",true,false)
 if scroll==null:
  failures.append("S43 "+tag+" keyboard dossier scroll missing")
  return
 var before: Dictionary = pane.onboarding_state.snapshot() if pane.onboarding_state!=null else pane.game.snapshot()
 var files: Dictionary = _recap_save_bytes()
 var bar: VScrollBar = scroll.get_v_scroll_bar()
 if not scroll.follow_focus or scroll.horizontal_scroll_mode!=ScrollContainer.SCROLL_MODE_DISABLED:
  failures.append("S43 "+tag+" dossier lost native follow-focus/vertical scrolling")
 # Every original stat remains readable within the real clip viewport. The new
 # audition card intentionally scrolls; inert meters do not become focus stops.
 for index in range(6):
  var field: Control = pane.find_child("RecruitStatRow"+str(index),true,false)
  var meter: Control = pane.find_child("PassiveMeter"+str(index),true,false)
  if field==null or meter==null:
   failures.append("S43 "+tag+" original complete stat row missing: "+str(index))
   continue
  scroll.ensure_control_visible(field)
  await process_frame
  await process_frame
  await RenderingServer.frame_post_draw
  if not scroll.get_global_rect().encloses(field.get_global_rect()) or not scroll.get_global_rect().encloses(meter.get_global_rect()):
   failures.append("S43 "+tag+" full original stat cannot be revealed in dossier viewport: "+str(index))
 for note_name in ["RecruitStrength","RecruitFriction"]:
  var note: Label = pane.find_child(note_name,true,false)
  if note!=null and note.is_visible_in_tree():
   scroll.ensure_control_visible(note)
   await process_frame
   await process_frame
   await RenderingServer.frame_post_draw
   if not scroll.get_global_rect().encloses(note.get_global_rect()) or note.get_visible_line_count()<note.get_line_count():
    failures.append("S43 "+tag+" full authored note cannot fit/read within dossier viewport: "+note_name)
 if bar.visible:
  var audition: Button = pane.find_child("AuditionAction",true,false)
  if audition!=null and not audition.disabled:
   audition.grab_focus()
  if bar.focus_mode!=Control.FOCUS_ALL or not await _tab_to(bar,32):
   failures.append("S43 "+tag+" Tab cannot reach original dossier scrollbar")
  await _recap_key(KEY_HOME)
  if scroll.scroll_vertical!=0 or not bar.has_focus():
   failures.append("S43 "+tag+" native Home did not restore profile start/focus")
  await _recap_key(KEY_END)
  if scroll.scroll_vertical!=roundi(bar.max_value-bar.page) or not bar.has_focus():
   failures.append("S43 "+tag+" native End did not reach full dossier with focus retained")
  await _recap_key(KEY_HOME)
  if scroll.scroll_vertical!=0 or not bar.has_focus():
   failures.append("S43 "+tag+" native Home did not restore dossier with focus retained")
 else:
  scroll.scroll_vertical = 0
 print("S40_RECRUIT_SCROLL ",JSON.stringify({"case":tag,"width":w,"height":h,"visible_bar":bar.visible,"maximum":roundi(bar.max_value-bar.page),"home":scroll.scroll_vertical}))
 var after: Dictionary = pane.onboarding_state.snapshot() if pane.onboarding_state!=null else pane.game.snapshot()
 if after!=before or _recap_save_bytes()!=files:
  failures.append("S43 "+tag+" readable dossier/keyboard browsing mutated original state/save bytes")

func _draw_recruit_context_fixtures(screen,w: int,h: int) -> void:
 var files: Dictionary = _recap_save_bytes()
 var original: Dictionary = screen.setup.snapshot()
 var cases := [
  {"name":"long_bex","target":"cast_bex","roster":[],"capture":true},
  {"name":"long_sam","target":"cast_sam","roster":[],"capture":true},
  {"name":"ready_trio","target":"cast_casey","roster":["cast_jack","cast_zoe","cast_casey"],"vocal":"cast_jack","capture":true},
  {"name":"fifth_cost","target":"cast_dan","roster":["cast_maya","cast_jack","cast_zoe","cast_casey"]},
  {"name":"sixth_cost","target":"cast_jack","roster":["cast_nina","cast_tom","cast_ben","cast_ellis","cast_dan"]},
  {"name":"vocal_reservation","target":"cast_nina","roster":["cast_maya","cast_jack","cast_zoe","cast_dan","cast_casey"],"vocal":"cast_jack"},
  {"name":"shortfall","target":"cast_bex","roster":["cast_maya","cast_jack","cast_zoe","cast_dan","cast_casey"]},
  {"name":"full_six","target":"cast_maya","roster":["cast_nina","cast_tom","cast_ben","cast_ellis","cast_dan","cast_jack"]},
 ]
 screen.hide()
 for entry in cases:
  var model := OpeningModel.new()
  model.screen = "recruit"
  for pid in entry.roster:
   if not model.game.recruit(pid).get("ok",false):
    failures.append("S40 invalid canonical recruitment fixture "+str(entry.name)+" "+str(pid))
  # Reachable fixture reservation; no recruit/choose_vocal/save_draft call
  # writes the player's sandbox while these read-only states are inspected.
  model.lead_vocal_id = str(entry.get("vocal",""))
  var candidate: Dictionary = model.game.person_by_id(str(entry.target))
  var fixture = RehearsalScreen.new()
  fixture.game = model.game
  fixture.onboarding_state = model
  # QA presentation fixture only: expose full already-authored notes without
  # audition animation, a resolver, a change_counter increment or a save.
  fixture.auditioned[str(entry.target)] = true
  fixture.audition_note_id = ""
  fixture.last_message = "RECRUITMENT QA FIXTURE  /  NO SAVE"
  fixture.role = str(candidate.get("primary_role",candidate.get("roles",["Singer"])[0]))
  var choices: Array = model.game.choices(fixture.role)
  fixture.selected_index = -1
  for index in range(choices.size()):
   if str(choices[index].get("id",""))==str(entry.target):
    fixture.selected_index = index
  if fixture.selected_index<0:
   failures.append("S40 recruitment fixture candidate absent from actual role "+str(entry.target))
   fixture.free()
   continue
  var before: Dictionary = model.snapshot()
  root.add_child(fixture)
  await process_frame
  await process_frame
  await process_frame
  _check_recruit_context(fixture,w,h,str(entry.name))
  if bool(entry.get("capture",false)):
   await _draw_screen("recruit_"+str(entry.name),w,h)
  if str(entry.name) in ["long_bex","long_sam"]:
   await _check_recruit_profile_keyboard(fixture,w,h,str(entry.name))
  if model.snapshot()!=before or _recap_save_bytes()!=files:
   failures.append("S40 read-only recruitment fixture changed source state/save "+str(entry.name))
  fixture.free()
  await process_frame
 screen.show()
 if screen.setup.snapshot()!=original or _recap_save_bytes()!=files:
  failures.append("S40 recruitment QA fixtures changed the real player's state/save")

func _check_recap_clarity(screen: Control,report: Dictionary,members: Array,w: int,h: int,context: String) -> void:
 var view: Dictionary = Recap.present(report,members)
 var advice: Label = screen.find_child("RecapNextMove",true,false) as Label
 var action: Button = screen.find_child("RecapToggleAction",true,false) as Button
 var scroll: ScrollContainer = screen.find_child("RehearsalResultScroll",true,false) as ScrollContainer
 var viewport := Rect2(0,0,w,h)
 if advice==null or action==null or scroll==null:
  failures.append("S40 "+context+" missing next-move advice or return dock")
  return
 if advice.text!=str(view.get("next_step","")) or advice.text.is_empty():
  failures.append("S40 "+context+" next move does not describe the actual saved outcome")
 if not advice.is_visible_in_tree() or advice.get_theme_font_size("font_size")!=16 or not viewport.encloses(advice.get_global_rect()):
  failures.append("S40 "+context+" canonical 16px next move is not visible in first fold")
 var career: Dictionary = screen.game.career if screen.get_script()==RehearsalScreen else screen.setup.game.career
 if action.text!="CONTINUE TO DAY %d  ›" % int(career.get("tour_day",1)) or action.get_global_rect().size.y<44 or not viewport.encloses(action.get_global_rect()):
  failures.append("S40 "+context+" return action is mislabeled, too small or clipped")
 var receipt: Label = screen.find_child("RecapDayReceipt",true,false) as Label
 var completed: Label = screen.find_child("RecapCompletedDay",true,false) as Label
 if receipt==null or receipt.text!=str(view.get("receipt","")) or completed==null or completed.text!=str(view.get("completed_heading","")):
  failures.append("S41 "+context+" day/cash receipt differs from the saved resolver before/after values")
 var details: Control = screen.find_child("RecapDetailedBreakdown",true,false) as Control
 var disclosure: Button = screen.find_child("RecapDetailsToggleAction",true,false) as Button
 if disclosure==null or disclosure.size.y<44 or not viewport.encloses(disclosure.get_global_rect()) or scroll.get_global_rect().intersects(disclosure.get_global_rect()):
  failures.append("S41 "+context+" full-breakdown target is not a safe fixed first-fold action")
 else:
  for target in [disclosure,action]:
   var available: float = target.size.x-target.get_theme_stylebox("normal").get_minimum_size().x
   if target.icon!=null:
    available -= target.icon.get_width()+target.get_theme_constant("h_separation")
   if target.get_theme_font("font").get_string_size(target.text,HORIZONTAL_ALIGNMENT_LEFT,-1,target.get_theme_font_size("font_size")).x>available+1.0:
    failures.append("S41 "+context+" fixed result action label is clipped: "+target.text)
 if advice.get_global_rect().end.y>action.get_global_rect().position.y or scroll.get_global_rect().intersects(advice.get_global_rect()) or scroll.get_global_rect().intersects(action.get_global_rect()):
  failures.append("S40 "+context+" next move/return action overlaps report or each other")
 if advice.focus_mode!=Control.FOCUS_NONE or advice.mouse_filter!=Control.MOUSE_FILTER_IGNORE:
  failures.append("S40 "+context+" read-only next move steals input")
 var tablet: bool = w>=600 and w<900 and h>w
 var minimum_reaction: int = 16
 var minimum_readout: int = 13 if tablet else 12
 var gallery: ScrollContainer = screen.find_child("RecapMemberGallery",true,false) as ScrollContainer
 for voice in view.get("reactions",[]):
  if not voice is Dictionary:
   continue
  var pid: String = str(voice.get("candidate_id",""))
  var caption: Label = screen.find_child("RecapMember_"+pid,true,false) as Label
  if caption==null or caption.get_theme_font_size("font_size")<minimum_reaction:
   failures.append("S40 "+context+" primary reaction is too small: "+pid)
  elif gallery!=null:
   var lower_edge: float = gallery.get_global_rect().end.y
   if gallery.get_h_scroll_bar().visible:
    lower_edge -= gallery.get_h_scroll_bar().size.y
   if caption.get_global_rect().position.y<gallery.get_global_rect().position.y or caption.get_global_rect().end.y>lower_edge+1.0:
    failures.append("S40 "+context+" readable reaction is vertically clipped: "+pid)
  if caption!=null and view.get("reactions",[]).size()<=3:
   var mood: Label = screen.find_child("RecapMood_"+pid,true,false) as Label
   if not scroll.get_global_rect().encloses(caption.get_global_rect()) or mood==null or not scroll.get_global_rect().encloses(mood.get_global_rect()):
    failures.append("S40 "+context+" primary reaction or morale is outside initial report viewport: "+pid)
  if pid=="cast_casey" and caption!=null:
   var quote: String = str(voice.get("quote",""))
   var full: Label = screen.find_child("RecapFullQuote_"+pid,true,false) as Label
   if full==null or full.text!=str(voice.get("name","Musician"))+" — “"+quote+"”":
    failures.append("S40 "+context+" complete Casey reaction changed")
   if quote.length()>32:
    var lines: PackedStringArray = caption.text.split("\n",false,1)
    if lines.size()!=2 or not lines[1].begins_with("“") or not lines[1].ends_with("…”"):
     failures.append("S40 "+context+" Casey excerpt has no clear truncation marker")
    else:
     var excerpt: String = lines[1].trim_prefix("“").trim_suffix("…”")
     if excerpt.is_empty() or not quote.begins_with(excerpt) or quote.substr(excerpt.length(),1) not in [" ",".",",","!","?"]:
      failures.append("S40 "+context+" Casey excerpt cuts a word instead of retaining a whole phrase")
 for key in ["readiness","morale","tension"]:
  var readout: Label = screen.find_child("RecapBeforeAfter_"+key,true,false) as Label
  var delta_ink: Label = screen.find_child("RecapHero_"+key,true,false) as Label
  if delta_ink==null or delta_ink.get_line_count()!=1 or scroll==null or not scroll.get_global_rect().encloses(delta_ink.get_global_rect()):
   failures.append("S52 "+context+" saved numeric delta wraps or is outside initial report: "+key)
  if readout!=null and not scroll.get_global_rect().encloses(readout.get_global_rect()):
   failures.append("S52 "+context+" saved before/after is outside initial report: "+key)
  var metric: Dictionary = report.get("metrics",{}).get(key,{})
  var expected: String = "%d → %d" % [int(metric.get("before",0)),int(metric.get("after",0))]
  if readout==null or readout.get_theme_font_size("font_size")<minimum_readout or readout.text!=expected:
   failures.append("S40 "+context+" before/after readout is too small or not source-accurate: "+key)
 print("S40_RECAP_CLARITY ",JSON.stringify({"context":context,"width":w,"height":h,"next_move":advice.text,"reaction_min":minimum_reaction,"readout_min":minimum_readout,"return_label":action.text}))

# Exercise the other two relocated actions on disposable copies of the real
# career. Expected effects come from the unchanged authoritative model; neither
# copy has an opening owner or any permission to save.
func _check_practice_dispatch(screen: Control,w: int,h: int) -> void:
 var before: Dictionary = screen.setup.snapshot()
 var saved_files: Dictionary = _recap_save_bytes()
 screen.hide()
 for action_name in ["WriteAction","ClearAirAction"]:
  var trial = Game.new()
  var expected = Game.new()
  if not trial.restore(screen.setup.game.snapshot()) or not expected.restore(screen.setup.game.snapshot()):
   failures.append("S40 practice dispatch could not copy the genuine career")
   continue
  var result: Dictionary = expected.write_session("Riff","Verse / Chorus","THE LAST BUS HOME",0) if action_name=="WriteAction" else expected.clear_air()
  if not result.get("ok",false):
   failures.append("S40 practice dispatch expected model action was invalid")
   continue
  var fixture = RehearsalScreen.new()
  fixture.game = trial
  fixture.recap_expanded = false
  fixture.last_message = "PRACTICE ACTION QA FIXTURE  /  NO SAVE"
  root.add_child(fixture)
  await process_frame
  await process_frame
  await process_frame
  if action_name=="ClearAirAction":
   await click_action(fixture.find_child("PracticeMode_connect",true,false) as Button)
  await click_action(fixture.find_child(action_name,true,false) as Button)
  if trial.snapshot()!=expected.snapshot():
   failures.append("S40 relocated practice action differed from one genuine settlement: "+action_name)
  if screen.setup.snapshot()!=before or _recap_save_bytes()!=saved_files:
   failures.append("S40 isolated practice dispatch modified player state or save files")
  print("S40_PRACTICE_DISPATCH ",JSON.stringify({"width":w,"height":h,"action":action_name,"action_count":trial.career.get("action_count",0),"matches_single_model_action":trial.snapshot()==expected.snapshot()}))
  fixture.queue_free()
  await process_frame
  await process_frame
 screen.show()

func _check_recap_keyboard(screen,w: int,h: int) -> void:
 var action: Button = screen.find_child("RecapDetailsToggleAction",true,false) as Button
 var scroll: ScrollContainer = screen.find_child("RehearsalResultScroll",true,false) as ScrollContainer
 var detail: Control = screen.find_child("RecapDetailedBreakdown",true,false) as Control
 if action==null or scroll==null or detail==null:
  failures.append("S40 keyboard disclosure controls missing")
  return
 if scroll.is_ancestor_of(action):
  scroll.ensure_control_visible(action)
 elif not Rect2(Vector2.ZERO,Vector2(root.size)).encloses(action.get_global_rect()) or action.size.y<44 or scroll.get_global_rect().intersects(action.get_global_rect()):
  failures.append("S41 fixed disclosure action is not a safe physical viewport target")
 await process_frame
 await process_frame
 action.grab_focus()
 await process_frame
 var action_id: int = action.get_instance_id()
 var scroll_id: int = scroll.get_instance_id()
 var detail_id: int = detail.get_instance_id()
 var offset: int = scroll.scroll_vertical
 var before: Dictionary = screen.setup.snapshot()
 var saved_files: Dictionary = _recap_save_bytes()
 if not action.has_focus():
  failures.append("S40 full-breakdown action cannot receive keyboard focus")
 await _recap_key(KEY_ENTER)
 var live_action: Button = screen.find_child("RecapDetailsToggleAction",true,false) as Button
 var live_scroll: ScrollContainer = screen.find_child("RehearsalResultScroll",true,false) as ScrollContainer
 var live_detail: Control = screen.find_child("RecapDetailedBreakdown",true,false) as Control
 if live_action==null or live_scroll==null or live_detail==null:
  failures.append("S40 Enter destroyed disclosure controls")
  return
 if live_action.get_instance_id()!=action_id or live_scroll.get_instance_id()!=scroll_id or live_detail.get_instance_id()!=detail_id:
  failures.append("S40 Enter rebuilt settled recap instead of revealing it in place")
 if not live_action.has_focus():
  failures.append("S40 Enter lost full-breakdown keyboard focus")
 if absi(live_scroll.scroll_vertical-offset)>1:
  failures.append("S40 Enter reset report scroll position")
 if not live_detail.visible or live_action.text!="HIDE DETAILS":
  failures.append("S40 genuine Enter did not reveal full ledger/update toggle")
 var view: Dictionary = Recap.present(screen.setup.game.career.get("last_rehearsal_outcome",{}),screen.setup.game.career.get("members",[]))
 var last_quote: Label = null
 for voice in view.get("reactions",[]):
  if not voice is Dictionary:
   continue
  var pid: String = str(voice.get("candidate_id",""))
  var full_quote: Label = live_detail.find_child("RecapFullQuote_"+pid,true,false) as Label
  var expected: String = str(voice.get("name","Musician"))+" — “"+str(voice.get("quote",""))+"”"
  if full_quote==null or full_quote.text!=expected or not full_quote.is_visible_in_tree():
   failures.append("S40 expanded ledger lost full authored reaction for "+pid)
  elif full_quote.get_theme_font_size("font_size")<16:
   failures.append("S40 full reaction text too small for "+pid)
  else:
   last_quote = full_quote
 # Actual expanded native pixels show the complete reaction that the compact
 # hero deliberately excerpts. Restore the prior reading position afterward.
 if last_quote!=null:
  live_scroll.ensure_control_visible(last_quote)
  await process_frame
  await process_frame
  await _draw_screen("rehearsal_full_reactions",w,h)
 live_scroll.scroll_vertical = offset
 await process_frame
 await process_frame
 live_action.grab_focus()
 var collapse_offset: int = live_scroll.scroll_vertical
 await _recap_key(KEY_SPACE)
 var closed_action: Button = screen.find_child("RecapDetailsToggleAction",true,false) as Button
 var closed_scroll: ScrollContainer = screen.find_child("RehearsalResultScroll",true,false) as ScrollContainer
 var closed_detail: Control = screen.find_child("RecapDetailedBreakdown",true,false) as Control
 if closed_action==null or closed_scroll==null or closed_detail==null:
  failures.append("S40 Space destroyed disclosure controls")
 else:
  if closed_action.get_instance_id()!=action_id or closed_scroll.get_instance_id()!=scroll_id or closed_detail.get_instance_id()!=detail_id:
   failures.append("S40 Space rebuilt settled recap instead of collapsing it in place")
  if not closed_action.has_focus():
   failures.append("S40 Space lost full-breakdown keyboard focus")
  if absi(closed_scroll.scroll_vertical-collapse_offset)>1:
   failures.append("S40 Space reset report scroll position")
  if closed_detail.visible or closed_action.text!="DETAILS":
   failures.append("S40 genuine Space did not collapse full ledger/update toggle")
 if screen.setup.snapshot()!=before or _recap_save_bytes()!=saved_files:
  failures.append("S40 keyboard disclosure changed settled gameplay or save bytes")
 print("S40_NATIVE_DISCLOSURE ",JSON.stringify({"width":w,"height":h,"focus_retained":closed_action!=null and closed_action.has_focus(),"scroll_before":offset,"scroll_after":closed_scroll.scroll_vertical if closed_scroll!=null else -1,"full_reactions":view.get("reactions",[]).size()}))

func _tab_to(target: Control, limit: int = 8) -> bool:
 for step in range(limit):
  if target.has_focus():
   return true
  await _recap_key(KEY_TAB)
 return target.has_focus()

# Maximum affordable real C25 roster, genuine resolver, existing report view.
# This labelled native fixture neither overwrites the player's game nor saves.
func _draw_six_member_recap(screen,w: int,h: int) -> void:
 var saved_files: Dictionary = _recap_save_bytes()
 var original_game: Dictionary = screen.setup.snapshot()
 var roster: Array[String] = ["cast_nina","cast_tom","cast_ben","cast_ellis","cast_dan","cast_jack"]
 var game = Game.new()
 for pid in roster:
  if not game.recruit(pid).get("ok",false):
   failures.append("S40 six-member fixture could not recruit actual "+pid)
 if game.spent()!=197 or not game.launch().get("ok",false):
  failures.append("S40 six-member fixture violated actual 197-talent formation")
  return
 if not game.clear_air().get("ok",false):
  failures.append("S40 six-member fixture could not resolve real band meeting")
  return
 var before: Dictionary = game.snapshot()
 var fixture = RehearsalScreen.new()
 fixture.game = game
 fixture.last_message = "SIX-MEMBER QA FIXTURE  /  197 TALENT  /  NO SAVE"
 screen.hide()
 root.add_child(fixture)
 await process_frame
 await process_frame
 await process_frame
 _check_recap_clarity(fixture,game.career.get("last_rehearsal_outcome",{}),game.career.get("members",[]),w,h,"six-member band meeting")
 var gallery: ScrollContainer = fixture.find_child("RecapMemberGallery",true,false) as ScrollContainer
 var footer: Button = fixture.find_child("RecapToggleAction",true,false) as Button
 if gallery==null or footer==null:
  failures.append("S40 six-member report/gallery fixture missing")
 else:
  var bar: HScrollBar = gallery.get_h_scroll_bar()
  var first: Control = fixture.find_child("RecapPortraitCard_"+roster[0],true,false) as Control
  var last: Control = fixture.find_child("RecapPortraitCard_"+roster[-1],true,false) as Control
  if fixture.find_children("RecapPortraitCard_*","VBoxContainer",true,false).size()!=6:
   failures.append("S40 six-member gallery dropped a selected musician")
  var browse_hint: Label = fixture.find_child("RecapBrowseHint",true,false) as Label
  if browse_hint!=null and (browse_hint.get_line_count()!=1 or browse_hint.get_global_rect().size.y>32):
   failures.append("S40 six-member browse hint collapsed into a vertical text column")
  if footer.get_global_rect().size.y<44 or footer.get_global_rect().end.y>float(h):
   failures.append("S40 six-member fixture lost first-fold Continue action")
  for pid in roster:
   var portrait: TextureRect = fixture.find_child("RecapPortrait_"+pid,true,false) as TextureRect
   var caption: Label = fixture.find_child("RecapMember_"+pid,true,false) as Label
   var stripe: ColorRect = fixture.find_child("RecapMoodStripe_"+pid,true,false) as ColorRect
   for passive in [portrait,caption,stripe]:
    if passive==null or passive.focus_mode!=Control.FOCUS_NONE or passive.mouse_filter!=Control.MOUSE_FILTER_IGNORE:
     failures.append("S40 gallery fixture made passive musician data interactive: "+pid)
   var full_quote: Label = fixture.find_child("RecapFullQuote_"+pid,true,false) as Label
   if full_quote==null or full_quote.get_theme_font_size("font_size")<16:
    failures.append("S40 six-member report lost full reaction text: "+pid)
  if bar.visible:
   if bar.focus_mode!=Control.FOCUS_ALL or first==null or last==null:
    failures.append("S40 overflowing gallery has no keyboard scrollbar/endpoint")
   else:
    footer.grab_focus()
    if not await _tab_to(bar):
     failures.append("S40 Tab cannot reach existing overflowing gallery scrollbar")
    await _recap_key(KEY_END)
    var maximum: int = roundi(bar.max_value-bar.page)
    if gallery.scroll_horizontal!=maximum or not gallery.get_global_rect().encloses(last.get_global_rect()):
     failures.append("S40 native End did not reveal final selected musician")
    await _draw_screen("rehearsal_six_members_end",w,h)
    await _recap_key(KEY_HOME)
    if gallery.scroll_horizontal!=0 or not gallery.get_global_rect().encloses(first.get_global_rect()):
     failures.append("S40 native Home did not restore first selected musician")
  else:
   footer.grab_focus()
   for step in range(8):
    await _recap_key(KEY_TAB)
    if bar.has_focus():
     failures.append("S40 hidden gallery scrollbar traps Tab when roster fits")
  await _draw_screen("rehearsal_six_members",w,h)
  var details: Button = fixture.find_child("RecapDetailsToggleAction",true,false) as Button
  var report_scroll: ScrollContainer = fixture.find_child("RehearsalResultScroll",true,false) as ScrollContainer
  var last_quote: Label = fixture.find_child("RecapFullQuote_"+roster[-1],true,false) as Label
  if details==null or report_scroll==null or last_quote==null:
   failures.append("S40 six-member ledger keyboard route missing")
  else:
   details.grab_focus()
   await _recap_key(KEY_ENTER)
   var vertical: VScrollBar = report_scroll.get_v_scroll_bar()
   if vertical.visible:
    if vertical.focus_mode!=Control.FOCUS_ALL or not await _tab_to(vertical):
     failures.append("S40 Tab cannot reach existing expanded-ledger scrollbar")
    await _recap_key(KEY_END)
    if report_scroll.scroll_vertical!=roundi(vertical.max_value-vertical.page) or not report_scroll.get_global_rect().encloses(last_quote.get_global_rect()):
     failures.append("S40 native End did not reveal final full musician reaction")
    await _draw_screen("rehearsal_six_members_ledger_end",w,h)
    await _recap_key(KEY_HOME)
    if report_scroll.scroll_vertical!=0:
     failures.append("S40 native Home did not restore ledger reading position")
   else:
    for step in range(8):
     await _recap_key(KEY_TAB)
     if vertical.has_focus():
      failures.append("S40 hidden vertical scrollbar traps Tab when ledger fits")
   details.grab_focus()
   await _recap_key(KEY_SPACE)
  print("S40_SIX_MEMBER_GALLERY ",JSON.stringify({"width":w,"height":h,"talent":game.spent(),"members":6,"overflow":bar.visible,"scroll_max":roundi(bar.max_value-bar.page),"verdict":game.career.get("last_rehearsal_outcome",{}).get("verdict","")}))
 if game.snapshot()!=before or screen.setup.snapshot()!=original_game or _recap_save_bytes()!=saved_files:
  failures.append("S40 six-member gallery fixture mutated real game or save bytes")
 fixture.free()
 screen.show()
 await process_frame
 await process_frame

# Source-honest visual-density fixture: this draws an actual Godot poster with
# five/six C25 approved preview portraits, WITHOUT mutating the real player's
# roster, spending talent, triggering milestone flags or writing a save.
func _draw_roster_cover(member_count: int,w: int,h: int) -> void:
 var people: Array = ApprovedCast.people().slice(0,member_count)
 var overlay := Control.new()
 overlay.name = "S36RosterDensityFixture"
 overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
 root.add_child(overlay)
 overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
 overlay.size = Vector2(w,h)
 var bg := TextureRect.new()
 bg.texture = load("res://components/control_atlas/art/case_surface.png")
 bg.modulate = Color(0.52,0.57,0.61)
 bg.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
 bg.stretch_mode = TextureRect.STRETCH_SCALE
 bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
 overlay.add_child(bg)
 bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
 var centre := CenterContainer.new()
 centre.mouse_filter = Control.MOUSE_FILTER_IGNORE
 overlay.add_child(centre)
 centre.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
 var frame: PanelContainer = Kit.frame("flightcase","panel")
 frame.custom_minimum_size.x = maxf(280.0,minf(760.0,float(w)-(40.0 if w < 720 else 80.0)))
 frame.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
 frame.mouse_filter = Control.MOUSE_FILTER_IGNORE
 centre.add_child(frame)
 var content := VBoxContainer.new()
 content.add_theme_constant_override("separation",8)
 frame.add_child(content)
 var poster: Variant = Poster.new()
 poster.name = "S36PosterDensity"
 content.add_child(poster)
 poster.configure(people,str(people[0].get("id","")),float(w))
 if poster.visible_ids().size()!=member_count:
  failures.append("S36 "+str(member_count)+"-person poster lost a real C25 identity")
 var note: Label = Kit.label("ROSTER LAYOUT PROOF  /  NOT A PLAYER SAVE","flightcase",12)
 note.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
 content.add_child(note)
 content.add_child(Kit.button("NAME THE BAND ›","flightcase","action"))
 content.add_child(Kit.button("BACK TO MENU","flightcase","tab"))
 await process_frame
 await process_frame
 var rect: Rect2 = frame.get_global_rect()
 if rect.position.x < -2.0 or rect.position.y < -2.0 or rect.end.x > float(w)+2.0 or rect.end.y > float(h)+2.0:
  failures.append("S36 "+str(member_count)+"-person poster overflows "+str(w)+"x"+str(h)+": "+str(rect))
 await _draw_screen("milestone1_"+str(member_count)+"members_visual",w,h)
 overlay.queue_free()
 await process_frame
 await process_frame

func take() -> void:
 var initial_orphans: int = int(Performance.get_monitor(Performance.OBJECT_ORPHAN_NODE_COUNT))
 var w := maxi(320,int(OS.get_environment("CAPTURE_WIDTH")))
 var h := maxi(480,int(OS.get_environment("CAPTURE_HEIGHT")))
 DisplayServer.window_set_size(Vector2i(w,h))
 root.size = Vector2i(w,h)
 var screen = UI.new()
 root.add_child(screen)
 screen.size = Vector2(w,h)
 # Ensure title always renders with empty draft, independent of the runner's saved state.
 screen.setup.screen = "menu"
 screen.showing_menu = true
 screen.call("_render")
 await _draw_screen("title",w,h)
 await _check_overwrite_resize(screen,w,h)
 await _check_no_draft_settings(screen,w,h)
 var new_action: Button = screen.find_child("NewBandAction",true,false)
 if new_action==null:
  failures.append("New Band button missing")
 else:
  print("C27_MENU_BUTTON rect=",new_action.get_global_rect()," viewport=",Vector2(w,h))
  await click_action(new_action)
 # The preceding native opening-state test saves a draft to this isolated sandbox.
 # New correctly requires confirmation; test the actual original C21 modal.
 await process_frame
 var confirmation: Control = null
 for node in screen.get_children():
  if node is Control and node.has_method("open_modal") and bool(node.get("is_open")):
   confirmation = node
   break
 if confirmation != null:
  print("C27_NEW_CONFIRM_REQUIRED true; real pointer confirming overwrite")
  var accept_button: Button = confirmation.get("confirm_button")
  if accept_button == null:
   failures.append("new draft confirmation button missing")
  else:
   await click_action(accept_button)
   await process_frame
 else:
  print("C27_NEW_CONFIRM_REQUIRED false, stage=",screen.setup.screen)
 if screen.setup.screen!="genre":
  failures.append("New Band did not open genre via pointer")
 else:
  await _draw_screen("genre",w,h)
 var next_action: Button = screen.find_child("GenreNextAction",true,false)
 if next_action==null:
  failures.append("Genre Next missing")
 else:
  await click_action(next_action)
 if screen.setup.screen!="recruit":
  failures.append("Genre Next did not open recruit via pointer")
 else:
  await _draw_screen("recruit",w,h)
  var meter: Control = screen.find_child("PassiveMeter0",true,false)
  if meter == null or meter.focus_mode!=Control.FOCUS_NONE or meter.mouse_filter!=Control.MOUSE_FILTER_IGNORE:
   failures.append("meter focus/input regression")

 # The selected-candidate decision must be in the first fold without scrolling.
 var first_dock: Control = screen.find_child("RecruitDecisionDock",true,false)
 var first_recruit: Button = screen.find_child("RecruitAction",true,false)
 if first_dock == null or first_recruit == null:
  failures.append("first-fold recruitment decision dock or action missing")
 else:
  var recruit_rect: Rect2 = first_recruit.get_global_rect()
  if recruit_rect.size.y < 44.0 or recruit_rect.size.x < 44.0 or recruit_rect.position.y < 0.0 or recruit_rect.position.x < 0.0 or recruit_rect.end.y > float(h) - 4.0 or recruit_rect.end.x > float(w) - 4.0:
   failures.append("recruit action clipped or below first fold: "+str(recruit_rect))
  if first_recruit.get_parent() != first_dock:
   failures.append("recruit action still trapped inside portrait scroll")
  if w >= 840 and w >= h:
   var dock_rect: Rect2 = first_dock.get_global_rect()
   if dock_rect.size.x > 762.0 or absf(dock_rect.get_center().x - float(w)*0.5) > 4.0:
    failures.append("desktop recruit dock should be centred and source-proportionate: "+str(dock_rect))

 # These are genuine ordered auditions and recruitment choices. Canonical
 # read-only fee/long-copy fixtures are drawn separately without saving.
 if screen.setup.screen=="recruit":
  # Unlike a model fixture, these are three actual user recruitment choices,
  # including changing role, browsing the cast and appointing lead vocals.
  var pane: Control = null
  for child in screen.get_children():
   if child is Control and child.has_method("_move_candidate") and child.has_method("_change_role"):
    pane = child
    break
  if pane==null:
   failures.append("real recruitment panel missing")
  else:
   _check_recruit_context(pane,w,h,"actual initial guitar audition")
   await _check_recruit_profile_keyboard(pane,w,h,"actual initial guitar audition")
   if str(pane.role)!="Guitarist" or not pane.find_children("RoleTab_*","Button",true,false).is_empty():
    failures.append("S43 genuine recruitment did not begin with ordered guitar auditions")
   for pair in [["Guitarist","cast_jack"],["Bassist","cast_zoe"],["Drummer","cast_casey"]]:
    var desired_role: String = str(pair[0])
    var desired_id: String = str(pair[1])
    if str(pane.role)!=desired_role:
     failures.append("S43 explicit audition sequence did not select "+desired_role+", observed "+str(pane.role))
     break
    var before_browse: Dictionary = screen.setup.snapshot()
    var before_browse_files: Dictionary = _recap_save_bytes()
    var choices: Array = screen.setup.game.choices(desired_role)
    var found_target := false
    for attempt in range(choices.size()):
     var index: int = int(pane.selected_index)
     if index>=0 and index<choices.size() and str(choices[index].get("id",""))==desired_id:
      found_target = true
      break
     await click_action(pane.find_child("RecruitNextAction",true,false))
     await process_frame
    if screen.setup.snapshot()!=before_browse or _recap_save_bytes()!=before_browse_files:
     failures.append("S43 genuine candidate browsing mutated model/save bytes")
    if not found_target:
     failures.append("could not browse to "+desired_id+" in "+desired_role)
     break
    _check_recruit_context(pane,w,h,"actual browsed "+desired_id)
    var invite: Button = pane.find_child("RecruitAction",true,false)
    if invite==null or not invite.disabled:
     failures.append("S43 unauditioned candidate can be invited before reading authored notes")
    var before_audition: Dictionary = screen.setup.snapshot()
    var before_audition_files: Dictionary = _recap_save_bytes()
    await click_action(pane.find_child("AuditionAction",true,false))
    await process_frame
    if screen.setup.snapshot()!=before_audition or _recap_save_bytes()!=before_audition_files:
     failures.append("S43 native audition reveal spent talent/day or wrote saves")
    _check_recruit_context(pane,w,h,"actual auditioned "+desired_id)
    var before_count: int = screen.setup.game.roster.size()
    var before_spent: int = screen.setup.game.spent()
    var before_available: int = screen.setup.remaining()
    var before_changes: int = screen.setup.change_counter
    var hire_cost: int = RecruitBase.incremental_cost(screen.setup.game.roster,_recruit_person(pane))
    await click_action(pane.find_child("RecruitAction",true,false))
    var confirmed := false
    for member in screen.setup.game.roster:
     if str(member.get("id",""))==desired_id:
      confirmed=true
    if not confirmed:
     failures.append("real recruit pointer did not hire "+desired_id)
     break
    if screen.setup.game.roster.size()!=before_count+1 or screen.setup.game.spent()!=before_spent+hire_cost or screen.setup.remaining()!=before_available-hire_cost or screen.setup.change_counter!=before_changes+1:
     failures.append("S40 real recruit did not charge/change roster exactly once: "+desired_id)
    if str(pane.role)!=desired_role:
     failures.append("S43 recruiting advanced into another spend target without explicit Next")
    _check_recruit_context(pane,w,h,"actual recruited "+desired_id)
    if desired_id=="cast_jack":
     await click_action(pane.find_child("RemoveAction",true,false))
     if screen.setup.game.roster.size()!=before_count or screen.setup.game.spent()!=before_spent or screen.setup.remaining()!=before_available or screen.setup.change_counter!=before_changes+2:
      failures.append("S40 genuine Remove did not refund the exact actual recruit once")
     _check_recruit_context(pane,w,h,"actual removed Jack")
     await click_action(pane.find_child("RecruitAction",true,false))
     if screen.setup.game.roster.size()!=before_count+1 or screen.setup.game.spent()!=before_spent+hire_cost or screen.setup.remaining()!=before_available-hire_cost or screen.setup.change_counter!=before_changes+3:
      failures.append("S40 genuine re-recruit lost the exact original cost/one-shot change")
    var before_next: Dictionary = screen.setup.snapshot()
    var before_next_files: Dictionary = _recap_save_bytes()
    await click_action(pane.find_child("AuditionNextStepAction",true,false))
    await process_frame
    var expected_next: String = "Bassist" if desired_role=="Guitarist" else ("Drummer" if desired_role=="Bassist" else "Singer")
    if str(pane.role)!=expected_next or screen.setup.snapshot()!=before_next or _recap_save_bytes()!=before_next_files:
     failures.append("S43 explicit next audition changes state/save or skips ordered "+expected_next)
   if str(pane.role)!="Singer" or not bool(pane.vocals_panel) or not screen.setup.lead_vocal_id.is_empty() or screen.setup.ready():
    failures.append("S43 core trio did not reach explicit unresolved vocal decision")
   if pane.find_child("StartAction",true,false)!=null:
    failures.append("S43 Complete Lineup is exposed before vocal choice/review")
   await _draw_screen("recruit_needs_vocals",w,h)
   var vocal_action: Button = pane.find_child("VocalAssign_cast_jack",true,false)
   var before_voice_route: Dictionary = screen.setup.snapshot()
   var before_voice_files: Dictionary = _recap_save_bytes()
   if vocal_action==null or not await _tab_to(vocal_action,32):
    failures.append("S43 genuine Tab cannot reach recruited Jack's vocal decision")
   elif not Rect2(0,0,w,h).encloses(vocal_action.get_global_rect()):
    failures.append("S43 native vocal focus does not reveal the selected bandmate")
   if screen.setup.snapshot()!=before_voice_route or _recap_save_bytes()!=before_voice_files:
    failures.append("S43 viewing/focusing original vocal choices mutated model/save")
   var before_voice_available: int = screen.setup.remaining()
   var before_voice_changes: int = screen.setup.change_counter
   var before_voice_game: Dictionary = screen.setup.game.snapshot()
   await click_action(vocal_action)
   if screen.setup.lead_vocal_id!="cast_jack" or not screen.setup.ready() or screen.setup.vocal_extra_cost()!=5 or screen.setup.remaining()!=before_voice_available-5 or screen.setup.change_counter!=before_voice_changes+1 or screen.setup.game.snapshot()!=before_voice_game:
    failures.append("S43 real instrumental vocal assignment did not reserve original5 talent exactly once")
   var loaded_voice := OpeningModel.new()
   if not loaded_voice.load_draft() or loaded_voice.snapshot()!=screen.setup.snapshot():
    failures.append("S43 native vocal choice did not roundtrip exact C27 disk state")
   if pane.find_child("StartAction",true,false)!=null:
    failures.append("S43 ready trio skipped explicit lineup review")
   var before_review: Dictionary = screen.setup.snapshot()
   var before_review_files: Dictionary = _recap_save_bytes()
   await click_action(pane.find_child("ReviewLineupAction",true,false))
   await process_frame
   if not bool(pane.lineup_review) or screen.setup.snapshot()!=before_review or _recap_save_bytes()!=before_review_files:
    failures.append("S43 native lineup review mutated actual lineup/budget/save bytes")
  var ready_action: Button = screen.find_child("StartAction",true,false)
  if ready_action == null:
   failures.append("ready lineup action not revealed in fixed decision dock")
  else:
   var ready_rect: Rect2 = ready_action.get_global_rect()
   if ready_rect.size.y < 44.0 or ready_rect.end.y > float(h) - 4.0:
    failures.append("ready lineup action clipped below first fold: "+str(ready_rect))
  await click_action(ready_action)
  if screen.setup.screen!="formed":
   failures.append("real Complete Lineup click did not reach milestone1")
  else:
   await _draw_screen("milestone1",w,h)
   for density_count in [5,6]:
    await _draw_roster_cover(density_count,w,h)
   var m1: Control = screen.find_child("MilestoneOneStage",true,false)
   var expected_width: float = minf(600.0,float(w) - (40.0 if w<720 else 80.0))
   if m1==null or m1.get_global_rect().size.x < expected_width - 2.0:
    failures.append("milestone1 retained narrow portrait composition")
   # S36: actual source-textured press/flyer treatment, never an image
   # of the whole UI. The player-selected roster is inside this native print.
   var print: Control = screen.find_child("BandFormationPoster",true,false)
   var paper: PanelContainer = screen.find_child("BandPosterPaper",true,false) as PanelContainer
   var headline: Label = screen.find_child("BandPosterHeadline",true,false) as Label
   if print==null or print.focus_mode!=Control.FOCUS_NONE or print.mouse_filter!=Control.MOUSE_FILTER_IGNORE:
    failures.append("S36 noninteractive editorial poster missing or focusable")
   if paper==null or not paper.get_theme_stylebox("panel") is StyleBoxTexture:
    failures.append("S36 printed poster missing original paper texture")
   if headline==null or headline.text!="YOU'VE GOT A BAND.":
    failures.append("S36 editorial milestone lacks exact live headline")
   var m1_button: Button = screen.find_child("MilestoneNextAction",true,false)
   if m1_button==null or m1_button.get_global_rect().end.y > float(h)-4.0 or m1_button.get_global_rect().size.y < 44.0:
    failures.append("S36 Name action obscured by first-issue poster on "+str(w)+"x"+str(h))
   # S35: exact selected IDs and the one real singer must appear in native
   # GL, not merely in the underlying deterministic model.
   var group: Variant = screen.find_child("SelectedBandLineup",true,false)
   if group==null or group.visible_ids()!=["cast_jack","cast_zoe","cast_casey"]:
    failures.append("S35 lineup did not render the real selected three member IDs")
   else:
    for pid in ["cast_jack","cast_zoe","cast_casey"]:
     var photo: TextureRect = group.find_child("LineupPortrait_"+pid,true,false) as TextureRect
     if photo==null or photo.texture==null or photo.texture.get_width()<200 or photo.texture.get_width()>260:
      failures.append("S35 source portrait missing or wrong resolution: "+pid)
     var role_label: Label = group.find_child("LineupRole_"+pid,true,false) as Label
     if role_label==null or role_label.text.is_empty():
      failures.append("S35 selected player role credit missing: "+pid)
    if group.find_children("LineupLeadVocal","Label",true,false).size()!=1:
     failures.append("S35 vocalist badge must appear exactly once")
    for child in group.find_children("*","TextureRect",true,false):
     var image: TextureRect = child as TextureRect
     if image.focus_mode!=Control.FOCUS_NONE or image.mouse_filter!=Control.MOUSE_FILTER_IGNORE:
      failures.append("S35 selected portrait gained unexpected input/focus")
   # Native 4/5/6 pure component proof uses approved IDs only. Construct
   # offscreen; never mutate the actual player roster or saved milestone.
   var all_cast: Array = ApprovedCast.people()
   if all_cast.size()!=18:
    failures.append("S35 canonical approved cast inventory is not 18")
   else:
    for count in [4,5,6]:
     var proof: Variant = Group.new()
     proof.visible = false
     screen.add_child(proof)
     var people: Array = all_cast.slice(0,count)
     var singer: String = str(people[0].get("id",""))
     proof.configure(people,singer,float(w))
     if proof.visible_ids().size()!=count:
      failures.append("S35 responsive lineup count "+str(count)+" did not match roster")
     if proof.find_children("LineupLeadVocal","Label",true,false).size()!=1:
      failures.append("S35 proof roster lead badge not unique at "+str(count))
     for person in people:
      var source_id: String = str(person.get("id",""))
      var face: TextureRect = proof.find_child("LineupPortrait_"+source_id,true,false) as TextureRect
      if face==null or face.texture==null:
       failures.append("S35 proof missing canonical preview for "+source_id)
     proof.queue_free()
   var m1_next: Button = screen.find_child("MilestoneNextAction",true,false)
   if m1_next==null or m1_next.get_global_rect().size.x<44.0:
    failures.append("milestone1 Next action lacks physical target")
 if screen.setup.screen=="formed":
  await click_action(screen.find_child("MilestoneNextAction",true,false))
  if screen.setup.screen!="name":
   failures.append("real milestone1 Next click did not reach naming")
  else:
   await _draw_screen("naming",w,h)
 if screen.setup.screen=="name":
  var suggestions: Array = screen.setup.suggested_names()
  var first_name: String = str(suggestions[0]["name"]) if not suggestions.is_empty() else ""
  var proposal_button: Button = null
  for entry in screen.find_children("*","Button",true,false):
   var b: Button = entry as Button
   if b!=null and not first_name.is_empty() and b.text.to_upper().contains(first_name.to_upper()):
    proposal_button=b
    break
  await click_action(proposal_button)
  if screen.setup.name_offer.is_empty():
   failures.append("native name proposal pointer did not register")
  else:
   await _draw_screen("name_reactions",w,h)
  var rethink: Button = screen.find_child("NameRethinkAction",true,false)
  await click_action(rethink)
  if screen.setup.name_revisions!=1 or not screen.setup.name_offer.is_empty():
   failures.append("native free rethink did not clear first proposal")
  else:
   await _draw_screen("name_rethink",w,h)
  var input_field: LineEdit = screen.find_child("FreeBandName",true,false)
  if input_field==null:
   failures.append("custom band-name text field missing")
  else:
   input_field.text = "Side Street"
   input_field.text_changed.emit("Side Street")
  await click_action(screen.find_child("NameSubmitAction",true,false))
  if screen.setup.name_offer!="Side Street":
   failures.append("custom typed name not submitted by real button")
  var lock_button: Button = screen.find_child("NameLockAction",true,false)
  await click_action(lock_button)
  if screen.setup.screen!="name_milestone":
   failures.append("real Name Lock did not reach milestone2")
  else:
   await _draw_screen("milestone2",w,h)
   var m2: Control = screen.find_child("MilestoneTwoStage",true,false)
   var expected_width: float = minf(600.0,float(w) - (40.0 if w<720 else 80.0))
   if m2==null or m2.get_global_rect().size.x < expected_width - 2.0:
    failures.append("milestone2 retained narrow portrait composition")
   _check_identity_press(screen,"NamedMilestonePrint","Side Street","Wordmark")
   var m2_next: Button = screen.find_child("NameMilestoneNextAction",true,false)
   if m2_next==null or m2_next.get_global_rect().size.x<44.0 or m2_next.get_global_rect().end.y>float(h)-4.0:
    failures.append("S37 milestone2 Next action clipped from first fold")
 if screen.setup.screen=="name_milestone":
  await click_action(screen.find_child("NameMilestoneNextAction",true,false))
  if screen.setup.screen!="identity":
   failures.append("real milestone2 Next did not reach logo/vibe")
  else:
   await _draw_screen("identity",w,h)
 if screen.setup.screen=="identity":
  var identity_stage: Control = screen.find_child("IdentityPreviewStage",true,false)
  var expected_identity_width: float = minf(600.0,float(w) - (40.0 if w<720 else 80.0))
  if identity_stage==null or identity_stage.get_global_rect().size.x < expected_identity_width-2.0:
   failures.append("logo/vibe live preview retained narrow portrait frame")
  _check_identity_press(screen,"IdentityPreviewPrint","Side Street","Wordmark")
  var stamp_button: Button = null
  for entry in screen.find_children("*","Button",true,false):
   var b: Button = entry as Button
   if b!=null and b.text.to_upper().contains("STAMP"):
    stamp_button=b
    break
  await click_action(stamp_button)
  if screen.setup.logo!="Stamp":
   failures.append("logo selection pointer did not update preview")
  else:
   await _draw_screen("identity_stamp",w,h)
   var updated_preview: Control = screen.find_child("IdentityPreviewStage",true,false)
   if updated_preview==null or updated_preview.get_global_rect().size.x < expected_identity_width-2.0:
    failures.append("logo choice changed preview geometry")
   _check_identity_press(screen,"IdentityPreviewPrint","Side Street","Stamp")
  var finish_button: Button = screen.find_child("IdentityFinishAction",true,false)
  if finish_button==null or finish_button.get_global_rect().size.y<44.0 or finish_button.get_global_rect().end.y>float(h)-4.0:
   failures.append("S37 identity Finish action below first fold")
  await click_action(screen.find_child("IdentityFinishAction",true,false))
  if screen.setup.screen!="complete":
   failures.append("real Finish Identity did not reach completed summary")
  else:
   await _draw_screen("completed_band",w,h)
 if screen.setup.screen=="complete":
  _check_identity_press(screen,"CompletedBandPrint","Side Street","Stamp")
  # A hidden native fixture proves custom Unicode & monogram without changing saves.
  var unicode_press: Variant = IdentityPress.new()
  unicode_press.visible = false
  screen.add_child(unicode_press)
  unicode_press.configure(screen.setup.game.roster,screen.setup.lead_vocal_id,"Échos 雨","Monogram",screen.setup.palette,screen.setup.vibe,float(w),"complete")
  var unicode_full: Label = unicode_press.find_child("IdentityFullName",true,false) as Label
  var unicode_mark: Label = unicode_press.find_child("IdentityLiveMark",true,false) as Label
  if unicode_full==null or unicode_full.text!="Échos 雨" or unicode_mark==null or not unicode_mark.text.contains("É"):
   failures.append("S37 live custom Unicode or monogram broken")
  unicode_press.queue_free()
  # A bounded source-backed identity stage must also bound its associated
  # real progression button at phone, portrait tablet and desktop sizes.
  var practice_button: Button = screen.find_child("StartPlayAction",true,false)
  if practice_button != null:
   var permitted_width: float = minf(780.0,float(w) - (40.0 if w < 720 else 80.0))
   if practice_button.get_global_rect().size.x > permitted_width + 1.0 or practice_button.get_global_rect().end.y>float(h)-4.0:
    failures.append("S37 completed First Practice action clipped or wider than case")
  await click_action(practice_button)
  if screen.setup.screen!="play" or screen.setup.game.phase!="play":
   failures.append("real First Practice click did not hand off gameplay")
  else:
   await _check_practice_layout(screen,w,h,true)
   await _draw_screen("practice",w,h)
 if screen.setup.screen=="play":
  var before_resume: Dictionary = screen.setup.snapshot()
  screen.call("_home")
  await process_frame
  if not screen.setup.has_valid_draft():
   failures.append("S40 actual saved-menu Settings case has no valid draft")
  await _check_menu_settings(screen,w,h,"saved_draft")
  var continue_button: Button = screen.find_child("ContinueAction",true,false)
  await click_action(continue_button)
  if screen.setup.screen!="play" or screen.setup.snapshot()!=before_resume:
   failures.append("real Continue failed to restore live gameplay without state loss")
  else:
   await _check_practice_layout(screen,w,h,false)
   await _draw_screen("resumed_practice",w,h)
  # S38: genuine pointer press of the existing Rehearse button, then
  # verify the saved causal result is restored by the real Continue menu.
  await click_action(screen.find_child("PracticeMode_tighten",true,false) as Button)
  var rehearsal_action: Button = screen.find_child("RehearseAction",true,false)
  if rehearsal_action==null:
   failures.append("S38 rehearsal control missing after actual gameplay handoff")
  else:
   var count_before: int = int(screen.setup.game.career.get("action_count",0))
   await click_action(rehearsal_action)
   var report: Dictionary = screen.setup.game.career.get("last_rehearsal_outcome",{})
   var metrics: Dictionary = report.get("metrics",{})
   if report.get("focus","")!="tighten" or int(screen.setup.game.career.get("action_count",0))!=count_before+1:
    failures.append("S38 genuine Rehearse press did not settle exactly once")
   if int(metrics.get("cash",{}).get("delta",999))!=-15 or not metrics.has("readiness") or not metrics.has("cohesion"):
    failures.append("S38 Rehearse outcome missing actual cost, readiness or social cohesion")
   # S39: the player sees the full SAME saved result, not an invented second action.
   var recap: Control = screen.find_child("RehearsalRecapPanel",true,false) as Control
   var ready_text: Label = screen.find_child("RecapMetric_readiness",true,false) as Label
   var cohesion_text: Label = screen.find_child("RecapMetric_cohesion",true,false) as Label
   var musician_text: Label = screen.find_child("RecapMember_cast_jack",true,false) as Label
   if recap==null or ready_text==null or cohesion_text==null or musician_text==null:
    failures.append("S39 actual native rehearsal recap, exact metrics or named selected musician absent")
   elif not ready_text.text.contains("28") or not musician_text.text.contains("Jack"):
    failures.append("S39 native recital does not show actual saved readiness/selected Jack")
   # S40: real first-fold, character-portrait and signed-result evidence.
   var stage_action: Button = screen.find_child("RecapToggleAction",true,false) as Button
   var score_tile: Label = screen.find_child("RecapHero_readiness",true,false) as Label
   var jack_photo: TextureRect = screen.find_child("RecapPortrait_cast_jack",true,false) as TextureRect
   var zoe_photo: TextureRect = screen.find_child("RecapPortrait_cast_zoe",true,false) as TextureRect
   var casey_photo: TextureRect = screen.find_child("RecapPortrait_cast_casey",true,false) as TextureRect
   if score_tile==null or score_tile.text!="+10":
    failures.append("S40 hero scorecard absent or not sourced from actual rehearsal +10")
   for metric_key in ["readiness","morale","tension"]:
    var tile: PanelContainer = screen.find_child("RecapHeroTile_"+metric_key,true,false) as PanelContainer
    if tile==null or not tile.get_theme_stylebox("panel") is StyleBoxTexture:
     failures.append("S40 scorecard lost its separate source-backed paper: "+metric_key)
    elif tile.mouse_filter!=Control.MOUSE_FILTER_IGNORE or tile.focus_mode!=Control.FOCUS_NONE:
     failures.append("S40 scorecard became interactive: "+metric_key)
   if jack_photo==null or zoe_photo==null or casey_photo==null:
    failures.append("S40 selected Jack Zoe Casey photographs not visible in native journal")
   elif jack_photo.texture==null or jack_photo.texture.get_width()<200:
    failures.append("S40 selected approved preview source missing or wrong resolution")
   if w>=600 and w<900 and h>w:
    var tablet_quote: Label = screen.find_child("RecapMember_cast_jack",true,false) as Label
    if tablet_quote==null or tablet_quote.get_theme_font_size("font_size")<16:
     failures.append("S40 tall-tablet reactions still use phone-sized text")
    for tablet_photo in [jack_photo,zoe_photo,casey_photo]:
     if tablet_photo==null or tablet_photo.get_global_rect().size.x<150 or tablet_photo.get_global_rect().size.x>tablet_photo.texture.get_width():
      failures.append("S40 tablet portrait is undersized or exceeds its honest source detail")
   if stage_action==null or stage_action.get_global_rect().size.y<44 or stage_action.get_global_rect().end.y>float(h)-4.0:
    failures.append("S40 real Continue Practising action not visible in first viewport")
   _check_recap_clarity(screen,report,screen.setup.game.career.get("members",[]),w,h,"three-member rehearsal")
   var detail_action: Button = screen.find_child("RecapDetailsToggleAction",true,false) as Button
   if detail_action==null:
    failures.append("S40 accessible full-breakdown control missing")
   else:
    var before_details: Dictionary = screen.setup.snapshot()
    await click_action(detail_action)
    var expanded_detail: Control = screen.find_child("RecapDetailedBreakdown",true,false) as Control
    if expanded_detail==null or not expanded_detail.visible:
     failures.append("S40 genuine detail action did not reveal all six saved measures")
    await click_action(screen.find_child("RecapDetailsToggleAction",true,false))
    var collapsed_detail: Control = screen.find_child("RecapDetailedBreakdown",true,false) as Control
    if collapsed_detail==null or collapsed_detail.visible:
     failures.append("S40 detailed ledger did not collapse")
    if screen.setup.snapshot()!=before_details:
     failures.append("S40 expanding the journal changed settled gameplay")
   await _check_recap_keyboard(screen,w,h)
   var before_ui_only: Dictionary = screen.setup.snapshot()
   var toggle_notes: Button = screen.find_child("RecapToggleAction",true,false) as Button
   if toggle_notes==null:
    failures.append("S39 real recap show/hide button absent")
   else:
    await click_action(toggle_notes)
    if screen.find_child("RehearsalRecapPanel",true,false)!=null:
     failures.append("S39 hide report failed")
    await _check_practice_layout(screen,w,h,false)
    await click_action(screen.find_child("ReopenSessionAction",true,false))
    if screen.find_child("RehearsalRecapPanel",true,false)==null:
     failures.append("S39 show report failed")
    if screen.setup.snapshot()!=before_ui_only:
     failures.append("S39 viewing notes mutated the career/settled rehearsal twice")
   await _draw_screen("rehearsal_outcome",w,h)
   var saved_after_rehearsal: Dictionary = screen.setup.snapshot()
   screen.call("_home")
   await process_frame
   await click_action(screen.find_child("ContinueAction",true,false))
   if screen.setup.screen!="play" or screen.setup.snapshot()!=saved_after_rehearsal:
    failures.append("S38 real Continue re-applied or lost the saved rehearsal")
   else:
    var saved_recap: Control = screen.find_child("RehearsalRecapPanel",true,false) as Control
    var restored_name: Label = screen.find_child("RecapMember_cast_jack",true,false) as Label
    if saved_recap==null or restored_name==null or not restored_name.text.contains("Jack"):
     failures.append("S39 saved rehearsal recap missing after genuine menu Continue")
    var restored_header: Label = screen.find_child("StatusMessage",true,false) as Label
    if restored_header==null or not restored_header.text.contains("LAST SESSION") or not restored_header.text.contains("Good progress"):
     failures.append("S39 resumed phase shows stale recruitment text instead of saved rehearsal verdict")
    _check_recap_clarity(screen,screen.setup.game.career.get("last_rehearsal_outcome",{}),screen.setup.game.career.get("members",[]),w,h,"resumed rehearsal")
    await _draw_screen("rehearsal_resumed",w,h)

 await _check_practice_dispatch(screen,w,h)
 await _draw_recruit_context_fixtures(screen,w,h)
 await _draw_six_member_recap(screen,w,h)

 # Deferred frees from the final screen transition must settle before checking
 # controls allocated along the complete recruitment/Continue journey.
 await process_frame
 await process_frame
 var remaining_orphans: int = int(Performance.get_monitor(Performance.OBJECT_ORPHAN_NODE_COUNT))
 if remaining_orphans>initial_orphans:
  failures.append("S40 journey leaked %d orphan controls" % (remaining_orphans-initial_orphans))
 print("C27_CAPTURE_RESULT ",JSON.stringify({"width":w,"height":h,"orphan_nodes_added":remaining_orphans-initial_orphans,"failures":failures}))
 quit(0 if failures.is_empty() else 1)
