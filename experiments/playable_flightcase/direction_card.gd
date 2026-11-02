extends RefCounted
## Native, passive goal/count/pill presentation on existing paper. No saving.
const C = preload("res://experiments/playable_flightcase/career_components.gd")
const Direction = preload("res://experiments/playable_flightcase/career_direction.gd")

static func _copy(parent: Node, value: String, name: String, muted: bool = false) -> Label:
 var label: Label=C.paper_label(value,16,muted)
 label.name=name
 label.size_flags_horizontal=Control.SIZE_EXPAND_FILL
 parent.add_child(label)
 return label

static func _row(parent: Node, name: String) -> HFlowContainer:
 var row:=HFlowContainer.new()
 row.name=name
 row.mouse_filter=Control.MOUSE_FILTER_IGNORE
 row.size_flags_horizontal=Control.SIZE_EXPAND_FILL
 row.add_theme_constant_override("h_separation",6)
 row.add_theme_constant_override("v_separation",6)
 parent.add_child(row)
 return row

static func _pill(parent: Node, text: String, name: String, mood: int) -> Label:
 var panel:=PanelContainer.new()
 panel.name=name+"Housing"
 panel.mouse_filter=Control.MOUSE_FILTER_IGNORE
 panel.focus_mode=Control.FOCUS_NONE
 var stock:=StyleBoxFlat.new()
 stock.bg_color=Color("e0e9d9") if mood>0 else (Color("efddd7") if mood<0 else Color("e9e2d5"))
 stock.border_color=Color("819777") if mood>0 else (Color("b98171") if mood<0 else Color("aaa08f"))
 stock.set_border_width_all(1)
 stock.set_corner_radius_all(8)
 stock.content_margin_left=7.0
 stock.content_margin_right=7.0
 stock.content_margin_top=4.0
 stock.content_margin_bottom=4.0
 panel.add_theme_stylebox_override("panel",stock)
 parent.add_child(panel)
 var label: Label=_copy(panel,text,name)
 label.autowrap_mode=TextServer.AUTOWRAP_OFF
 label.size_flags_horizontal=Control.SIZE_SHRINK_BEGIN
 label.add_theme_color_override("font_color",Color("254d2f") if mood>0 else (Color("843c2c") if mood<0 else Color("625b50")))
 return label

static func goal(host, parent: Node, _compact: bool) -> VBoxContainer:
 var view: Dictionary=host._goal_direction()
 var cue:=VBoxContainer.new()
 cue.name="CareerGoalCue"
 cue.mouse_filter=Control.MOUSE_FILTER_PASS
 cue.size_flags_horizontal=Control.SIZE_EXPAND_FILL
 cue.add_theme_constant_override("separation",5)
 parent.add_child(cue)
 var title: Label=_copy(cue,"NEXT / "+str(view["title"]) if bool(view["ok"]) else "NEXT BAND GOAL","CareerGoalTitle",true)
 title.set_meta("chapter_id",str(view["id"]))
 if not str(host.goal_notice).is_empty() and str(host.goal_notice)!=str(view["message"]):_copy(cue,str(host.goal_notice),"CareerGoalNotice",true)
 if not view["requirements"].is_empty():
  var rows: HFlowContainer=_row(cue,"CareerGoalRequirements")
  for entry in view["requirements"]:
   var current: int=int(entry["current"])
   var target: int=int(entry["target"])
   var count: Label=_pill(rows,"%s %d/%d" % [str(entry["label"]),current,target],"CareerGoalRequirement_"+str(entry["key"]),1 if current>=target else 0)
   count.set_meta("current",current)
   count.set_meta("target",target)
 var status: String=str(view["message"]) if not bool(view["ok"]) else (str(view["description"]) if bool(view["done"]) else ("REQUIREMENTS MET" if bool(view["ready"]) else str(view["route_hint"])))
 _copy(cue,status,"CareerGoalStatus",true)
 return cue

static func pills(parent: Node, effects: Variant) -> void:
 if not effects is Dictionary:return
 var row: HFlowContainer=_row(parent,"ShowOutcomePills")
 for field in ["fans","reputation","morale","tension","readiness"]:
  var change: Variant=effects.get(field)
  if not change is Dictionary or not Direction._whole(change.get("before")) or not Direction._whole(change.get("after")) or not Direction._whole(change.get("delta"),-Direction.MAXIMUM):continue
  var before: int=int(change["before"])
  var after: int=int(change["after"])
  var delta: int=int(change["delta"])
  if delta!=after-before:continue
  var mood: int=signi(delta)*(-1 if field=="tension" else 1)
  var label: Label=_pill(row,"%s %+d" % [field.to_upper(),delta],"ShowOutcome_"+field,mood)
  label.set_meta("field",field)
  label.set_meta("before",before)
  label.set_meta("after",after)
  label.set_meta("delta",delta)
  label.set_meta("benefit_sign",mood)
  label.tooltip_text="%s %d → %d (%+d)" % [field.to_upper(),before,after,delta]
