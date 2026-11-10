extends SceneTree
## Focused stable pixel proof for the last short-landscape Settings capture.
const Owner=preload("res://experiments/playable_flightcase/opening_state.gd")
var scene
var owner
var checks:=0
var failures: Array=[]
var output: String=""
func _init() -> void:
 for arg in OS.get_cmdline_user_args():
  if arg.begins_with("--out="):output=arg.trim_prefix("--out=")
 call_deferred("run")
func check(ok: bool,label: String) -> void:
 checks+=1
 if not ok:failures.append(label);push_error(label)
func capture(label: String,sheet) -> void:
 await create_timer(0.25).timeout
 await RenderingServer.frame_post_draw
 check(sheet.is_open and sheet.panel.is_visible_in_tree(),"stable sheet visible "+label)
 var img: Image=root.get_texture().get_image()
 var point: Vector2=root.get_final_transform()*sheet.back_button.get_global_transform_with_canvas()*(sheet.back_button.size*Vector2(0.1,0.5))
 var color: Color=img.get_pixelv(Vector2i(point))
 check(color.r+color.g+color.b>0.8,"actual Back paper visible in readback "+label)
 check(img.save_png(output+"-"+label+".png")==OK,"actual stable screenshot "+label)
func run() -> void:
 check(FileAccess.file_exists("res://project.binary") and not FileAccess.file_exists("res://project.godot"),"actual compiled payload")
 owner=Owner.new();owner.begin_new()
 scene=load("res://experiments/playable_flightcase/opening.tscn").instantiate()
 scene.setup=owner;scene.showing_menu=true;scene.reduced_motion=true;root.add_child(scene)
 await create_timer(0.25).timeout
 var invoker: Button=scene.find_child("SettingsAction",true,false)
 check(invoker!=null,"actual main menu Settings")
 var point: Vector2=root.get_final_transform()*invoker.get_global_transform_with_canvas()*(invoker.size/2)
 for down in [true,false]:
  var event:=InputEventMouseButton.new();event.button_index=MOUSE_BUTTON_LEFT;event.pressed=down;event.position=point;event.global_position=point
  Input.parse_input_event(event);await process_frame
 var sheet=scene._settings_sheet
 await create_timer(0.25).timeout
 var identity: Label=sheet.find_child("SettingsBuildIdentity",true,false)
 var credits: Label=sheet.find_child("SettingsCrowdCredits",true,false)
 check(identity!=null and identity.text.contains("V24"),"actual V24 identity")
 check(credits!=null and credits.text.contains("sandyrb") and credits.text.contains("creativecommons.org/licenses/by/4.0/"),"actual packaged credit")
 await capture("top",sheet)
 var bar: VScrollBar=sheet._options_scroll.get_v_scroll_bar()
 sheet._options_scroll.scroll_vertical=int(maxf(0,bar.max_value-bar.page))
 await capture("credits",sheet)
 print("BUILD43_SETTINGS "+JSON.stringify({"checks":checks,"failures":failures,"viewport":str(root.size),"physical_device":false}))
 await create_timer(0.25).timeout
 scene.free();scene=null;owner=null
 await create_timer(0.2).timeout
 quit(0 if failures.is_empty() else 1)
