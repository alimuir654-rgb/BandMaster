extends "res://experiments/playable_flightcase/session_transition.gd"
## Reuse the verified guarded presentation, with truthful career-action copy.
## Resolution and saving are complete before this node enters the tree.
var heading_copy := "THE MUSIC SHOP"
var detail_copy := ""
var action_copy := "READ THE NOTES  ›"

func _ready() -> void:
 super._ready()
 var heading: Label = find_child("SessionBeatTitle",true,false) as Label
 var detail: Label = find_child("SessionBeatDay",true,false) as Label
 var action: Button = find_child("SkipSessionBeatAction",true,false) as Button
 if heading!=null:
  heading.text = heading_copy
 if detail!=null:
  detail.text = detail_copy
 if action!=null:
  action.text = action_copy
  action.tooltip_text = action_copy
