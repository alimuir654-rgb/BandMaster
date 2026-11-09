extends "res://tests/gig_navigation_visual.gd"

func capture(label: String) -> void:
 await super.capture(label)
 if not is_instance_valid(scene):return
 var rows: Array=[]
 for key in ["BookingPromoterHeading","BookingReviewVenue","BookingRoomIllustration","BookingPromoterReply"]:
  var node: Control=scene.find_child(key,true,false)
  if node==null:continue
  var chain: Array=[];var parent: Node=node
  while parent is Control:
   chain.append({"type":parent.get_class(),"name":str(parent.name),"rect":str(parent.get_global_rect()),"visible":parent.is_visible_in_tree(),"modulate":str(parent.modulate),"clip":parent.clip_contents,"minimum":str(parent.get_combined_minimum_size())})
   parent=parent.get_parent()
  rows.append({"key":key,"chain":chain})
 print("PRESENCE_TRACE "+JSON.stringify({"phase":label,"nodes":rows}))
