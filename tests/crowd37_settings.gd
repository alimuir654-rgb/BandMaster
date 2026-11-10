extends SceneTree
const Settings=preload("res://experiments/playable_flightcase/settings_sheet.gd")
var checks:=0
var failures: Array=[]
var width:=390
var height:=844
var output: String=""
var toggles:=0
func _init() -> void:
 for arg in OS.get_cmdline_user_args():
  if arg.begins_with("--width="):width=int(arg.trim_prefix("--width="))
  if arg.begins_with("--height="):height=int(arg.trim_prefix("--height="))
  if arg.begins_with("--output="):output=arg.trim_prefix("--output=")
 call_deferred("run")
func check(ok: bool,label: String) -> void:
 checks+=1
 if not ok:failures.append(label);push_error(label)
func settle() -> void:
 for _frame in range(5):await process_frame
 await RenderingServer.frame_post_draw
func capture(suffix: String) -> void:
 await settle()
 check(root.get_texture().get_image().save_png(output+"-"+suffix+".png")==OK,"native capture: "+suffix)
func run() -> void:
 root.size=Vector2i(width,height)
 var background:=ColorRect.new();background.color=Color("23262b");background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT);root.add_child(background)
 var invoker:=Button.new();invoker.text="SETTINGS";invoker.position=Vector2(12,12);root.add_child(invoker)
 var sheet=Settings.new();root.add_child(sheet)
 sheet.set_preferences(false,false,"DAY")
 sheet.set_audio_status("Sound is on.")
 sheet.sound_requested.connect(func():toggles+=1;sheet.set_preferences(true,false,"DAY"))
 sheet.open_sheet(invoker);await settle()
 var credits: Label=sheet.find_child("SettingsCrowdCredits",true,false)
 check(credits!=null,"installed pub source has visible Settings credit")
 if credits!=null:
  check(credits.text.contains("sandyrb") and credits.text.contains("creativecommons.org/licenses/by/4.0/") and credits.text.contains("Changes:"),"complete author/source/license/modification notice")
  check(credits.get_theme_font_size("font_size")>=14,"credit font floor retained")
 check(sheet.panel.get_global_rect().position.x>=0 and sheet.panel.get_global_rect().end.x<=width+1,"sheet horizontal enclosure")
 check(sheet.panel.get_global_rect().position.y>=0 and sheet.panel.get_global_rect().end.y<=height+1,"sheet vertical enclosure")
 check(sheet.back_button.get_global_rect().end.y<=height,"Back remains reachable")
 await capture("top")
 var press:=InputEventKey.new();press.keycode=KEY_SPACE;press.pressed=true;Input.parse_input_event(press)
 await process_frame
 var release:=InputEventKey.new();release.keycode=KEY_SPACE;release.pressed=false;Input.parse_input_event(release)
 await settle();check(toggles==1 and sheet.sound_button.text=="MASTER SOUND: OFF","native sound button exactly one request")
 sheet._options_scroll.scroll_vertical=int(sheet._options_scroll.get_v_scroll_bar().max_value);await settle()
 check(credits!=null and credits.size.x<=sheet._options.size.x+1,"credits wrap within existing scroll width")
 await capture("credits")
 var escape:=InputEventKey.new();escape.keycode=KEY_ESCAPE;escape.pressed=true;Input.parse_input_event(escape);await settle()
 check(not sheet.is_open and root.gui_get_focus_owner()==invoker,"Escape closes and restores focus")
 sheet.queue_free();invoker.queue_free();background.queue_free();await settle()
 print("CROWD37_SETTINGS "+JSON.stringify({"viewport":[width,height],"checks":checks,"failures":failures,"native_pixels":true,"physical_device":false}))
 quit(0 if failures.is_empty() else 1)
