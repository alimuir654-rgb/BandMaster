extends "res://tests/character_consequence_visual.gd"
## Reopen an exact isolated final-flow save; no new gameplay settlement.
func run() -> void:
 owner=Owner.new()
 if not check(not output.is_empty() and owner.load_draft(),"load saved actual completed new flow"):finish_new();return
 var saved: Dictionary=owner.snapshot();var disk: PackedByteArray=FileAccess.get_file_as_bytes(Owner.SAVE_PATH)
 scene=load("res://experiments/playable_flightcase/opening.tscn").instantiate();scene.setup=owner;scene.showing_menu=false;scene.reduced_motion=true;scene._career_landing=true;root.add_child(scene);await settle()
 scene._return_from_career("tighten");await settle()
 var practice: Control=scene._practice_view
 var target: Button=scene.find_child("RehearsalIntent_focus_listening",true,false)
 await reveal(target);target.grab_focus();await settle()
 for down in [true,false]:
  var event:=InputEventKey.new();event.keycode=KEY_SPACE;event.pressed=down;Input.parse_input_event(event);await process_frame
 await settle()
 check(practice.rehearsal_direction.focus=="listening" and target.button_pressed,"native keyboard selects latched rehearsal choice")
 var body: ScrollContainer=practice.find_child("PracticeScroll",true,false)
 var offset: int=body.scroll_vertical
 await tap("RehearsalIntent_focus_listening")
 check(target.is_inside_tree() and body.scroll_vertical==offset,"repeat local choice retains view and scroll")
 await capture("practice-keyboard")
 practice.recap_expanded=true;practice._rebuild();await settle()
 await tap("RecapDetailsToggleAction")
 var reason: Label=scene.find_child("RecapFullReason",true,false)
 check(reason!=null and reason.is_visible_in_tree() and reason.text.contains("audition"),"full saved reason contains genuine remembered audition")
 await reveal(reason);await capture("saved-promise-details")
 # Saved report is long. Move through it using ordinary native wheel input.
 var scroll: ScrollContainer=practice.find_child("SessionReportScroll",true,false)
 if scroll==null:
  for node in practice.find_children("*","ScrollContainer",true,false):
   if node.is_visible_in_tree():scroll=node;break
 if scroll!=null:
  var point: Vector2=root.get_final_transform()*scroll.get_global_transform_with_canvas()*(scroll.size/2)
  for _tick in range(4):
   var wheel:=InputEventMouseButton.new();wheel.button_index=MOUSE_BUTTON_WHEEL_DOWN;wheel.pressed=true;wheel.position=point;wheel.global_position=point;Input.parse_input_event(wheel)
  await settle();await capture("saved-promise-details-scrolled")
 check(owner.snapshot()==saved and FileAccess.get_file_as_bytes(Owner.SAVE_PATH)==disk,"keyboard and report navigation do not resolve or save")
 finish_new()
