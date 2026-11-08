extends "res://tests/recorded_steady_visual.gd"
## Actual opening scene/modal journey, always with isolated user data.
const Poster=preload("res://experiments/playable_flightcase/poster_components.gd")

func inside(control: Control) -> bool:
 return control.get_viewport_rect().encloses(control.get_global_rect())

func printed(button: Button) -> bool:
 var style: StyleBox=button.get_theme_stylebox("normal")
 return style is StyleBoxTexture and style.region_rect.size==Vector2(384,384)

func escape() -> void:
 var key:=InputEventKey.new();key.keycode=KEY_ESCAPE;key.pressed=true
 Input.parse_input_event(key)
 await process_frame

func run() -> void:
 if not check(not output.is_empty() and fixture(),"isolated genuine formation"):quit(1);return
 var saved: Dictionary=owner.snapshot()
 var disk: PackedByteArray=FileAccess.get_file_as_bytes(Owner.SAVE_PATH)
 var scene=load("res://experiments/playable_flightcase/opening.tscn").instantiate()
 scene.setup=owner;scene.showing_menu=true;scene.reduced_motion=true
 root.add_child(scene)
 await create_timer(0.2).timeout
 check(printed(scene.find_child("NewBandAction",true,false)),"title retains printed action")
 await capture("title")
 var settings_action: Button=scene.find_child("SettingsAction",true,false)
 settings_action.grab_focus();settings_action.pressed.emit()
 await process_frame
 var settings: Control=scene._settings_sheet
 check(settings.is_open and inside(settings.panel) and inside(settings.back_button),"settings fits safe viewport")
 check(printed(settings.sound_button) and printed(settings.back_button),"settings uses printed buttons")
 check(settings._title.get_theme_font("font")==Poster.DISPLAY,"settings uses poster heading")
 var build: int=int(ProjectSettings.get_setting("application/config/build_number",0))
 if build>0:check(settings.find_child("SettingsBuildIdentity",true,false).text.contains("V"+str(build)),"settings shows exact build")
 await capture("settings")
 await escape()
 check(not settings.is_open and root.gui_get_focus_owner()==settings_action,"Escape closes settings and restores invoker")
 check(owner.snapshot()==saved and FileAccess.get_file_as_bytes(Owner.SAVE_PATH)==disk,"settings/navigation preserve owner and disk")
 var new_action: Button=scene.find_child("NewBandAction",true,false)
 new_action.grab_focus();new_action.pressed.emit()
 await create_timer(0.1).timeout
 var confirm: Control=scene._new_band_dialog
 check(is_instance_valid(confirm) and confirm.is_open and inside(confirm.panel),"new-band confirmation fits")
 check(printed(confirm.cancel_button) and printed(confirm.confirm_button),"new-band confirmation printed")
 await capture("new-band-confirm")
 await escape()
 check(not is_instance_valid(scene._new_band_dialog) and owner.snapshot()==saved,"cancel replacement preserves draft")
 check(root.gui_get_focus_owner()==new_action,"replacement cancel restores invoker")
 scene._continue();await create_timer(0.2).timeout
 var career: Control=scene._career_view
 check(is_instance_valid(career),"continue enters existing career")
 var menu: Button=career.find_child("CareerMenuAction",true,false)
 menu.grab_focus();menu.pressed.emit();await process_frame
 var pause: Control=career._live_dialog
 check(pause.is_open and inside(pause.panel),"career pause fits")
 check(printed(pause.cancel_button) and printed(pause.confirm_button),"career pause printed")
 check(pause.heading.get_theme_font("font")==Poster.DISPLAY,"career pause heading matches")
 await capture("career-pause")
 await escape()
 check(not is_instance_valid(career._live_dialog),"career Escape resumes")
 await process_frame
 check(root.gui_get_focus_owner()==menu,"career pause restores invoker")
 var dialog=load("res://experiments/playable_flightcase/career_components.gd").dialog("MODAL GUARD","Long copy remains scrollable. ".repeat(90))
 var results: Array=[];dialog.completed.connect(func(value: bool):results.append(value))
 scene.add_child(dialog);dialog.open_modal()
 await capture("long-copy")
 print("LONG_COPY_GEOMETRY "+str(dialog.panel.get_global_rect())+" "+str(dialog.confirm_button.get_global_rect())+" viewport="+str(root.size))
 check(inside(dialog.panel) and inside(dialog.confirm_button),"long-copy modal bounded")
 dialog._finish(false);dialog._finish(true)
 check(results==[false],"modal completion remains once-only")
 dialog.queue_free();await process_frame
 var recipe: Dictionary=Recipe.recipe(Sound.read(owner.game.career))
 check(owner.begin_workbench("Poster follow-up",0,owner.workbench_expected(),recipe).ok,"enter real existing workbench")
 scene._career_landing=false;scene._render();await create_timer(0.2).timeout
 var desk: Control=scene.find_child("MixingDesk",true,false)
 check(desk!=null,"existing workbench mounted")
 for field in ["tone","pace","energy","originality"]:
  var label_style: StyleBoxTexture=desk._controls[field]._caption_stock
  check(label_style.region_rect.size==Vector2(384,384),"printed caption "+field)
 desk.find_child("MixingRecorded_0",true,false).pressed.emit()
 await capture("writing-labels")
 desk._hear.pressed.emit()
 check(desk._audio.playing,"retained recorded audio starts")
 desk.find_child("MixingPauseButton",true,false).pressed.emit()
 check(not desk._audio.playing and is_instance_valid(desk._dialog),"writing pause stops audio")
 await capture("writing-pause")
 desk._close_dialog()
 print("POSTER_FEEDBACK "+JSON.stringify({"viewport":str(root.size),"checks":checks,"failures":failures,"build":build,"actual_entry":"opening.tscn","physical_device":false}))
 scene.queue_free();await process_frame
 quit(0 if failures.is_empty() else 1)
