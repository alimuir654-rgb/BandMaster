extends RefCounted
const Poster=preload("res://experiments/playable_flightcase/poster_components.gd")
## Native, passive goal/count/pill presentation on existing paper. No saving.
const C = preload("res://experiments/playable_flightcase/career_components.gd")
const Direction = preload("res://experiments/playable_flightcase/career_direction.gd")
const Focus = preload("res://experiments/playable_flightcase/goal_focus_rules.gd")
const ICON_MANIFEST := "res://experiments/playable_flightcase/art/owner_approved_revisions_v2.json"
const FOCUS_ICONS := {"find_sound":"practice","first_crowd":"gigs","local_noise":"songs","earn_stripes":"gigs","first_month":"calendar"}

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
 var stock: StyleBoxTexture=Poster.control_stock(Poster.PAPER,6)
 panel.add_theme_stylebox_override("panel",stock)
 parent.add_child(panel)
 var label: Label=_copy(panel,text,name)
 label.autowrap_mode=TextServer.AUTOWRAP_OFF
 label.size_flags_horizontal=Control.SIZE_SHRINK_BEGIN
 label.add_theme_color_override("font_color",Poster.INK)
 return label

static func goal(host, parent: Node, _compact: bool) -> VBoxContainer:
 var view: Dictionary=host._goal_direction()
 var cue:=VBoxContainer.new()
 cue.name="CareerGoalCue"
 cue.mouse_filter=Control.MOUSE_FILTER_PASS
 cue.size_flags_horizontal=Control.SIZE_EXPAND_FILL
 cue.add_theme_constant_override("separation",5)
 parent.add_child(cue)
 var prefix: String="YOUR FOCUS / " if bool(view.get("pinned",false)) else "NEXT / "
 var title: Label=_copy(cue,prefix+str(view["title"]) if bool(view["ok"]) else "NEXT BAND GOAL","CareerGoalTitle",true)
 title.set_meta("chapter_id",str(view["id"]))
 if not str(host.goal_notice).is_empty() and str(host.goal_notice)!=str(view["message"]):_copy(cue,str(host.goal_notice),"CareerGoalNotice",true)
 if not view["requirements"].is_empty():
  var rows: HFlowContainer=_row(cue,"CareerGoalRequirements")
  for entry in view["requirements"]:
   var current: int=int(entry["current"])
   var target: int=int(entry["target"])
   var recorded: bool=bool(entry.get("recorded",true))
   var value: String="%s %d/%d" % [str(entry["label"]),current,target] if recorded else str(entry["label"])+" / NOT RECORDED"
   var count: Label=_pill(rows,value,"CareerGoalRequirement_"+str(entry["key"]),1 if recorded and current>=target else 0)
   count.set_meta("current",current)
   count.set_meta("target",target)
   count.set_meta("recorded",recorded)
 var status: String=str(view["message"]) if not bool(view["ok"]) else (str(view["description"]) if bool(view["done"]) else ("REQUIREMENTS MET" if bool(view["ready"]) else str(view["route_hint"])))
 _copy(cue,status,"CareerGoalStatus",true)
 var choose: Button=host._button("CHANGE FOCUS" if bool(view.get("pinned",false)) else "CHOOSE YOUR FOCUS","GoalFocusOpenAction",host._goal_focus_open.bind(int(host._render_generation)))
 choose.disabled=bool(host.busy)
 cue.add_child(choose)
 return cue

static func chooser(host, parent: Node, compact: bool) -> void:
 var body: VBoxContainer=host._paper(parent,compact)
 _copy(body,"CHOOSE YOUR BAND'S FOCUS","GoalFocusHeading")
 _copy(body,"Choose what the band works towards. Free to change; no day is spent.","GoalFocusExplanation",true)
 if not str(host.goal_notice).is_empty():_copy(body,str(host.goal_notice),"GoalFocusNotice",true)
 var choices: Dictionary=Focus.options(host.game.career)
 if not bool(choices["ok"]):
  _copy(body,str(choices["message"]),"GoalFocusHeld",true)
  return
 var icons: Dictionary={}
 if FileAccess.file_exists(ICON_MANIFEST):
  var parsed: Variant=JSON.parse_string(FileAccess.get_file_as_string(ICON_MANIFEST))
  if parsed is Dictionary:icons=parsed.get("icons",{})
 if not str(host._focus_draft).is_empty():
  var selected: Dictionary=Focus.definition(str(host._focus_draft))
  _copy(body,str(selected.get("description","")),"GoalFocusSelectedDescription",true)
 for option in choices["options"]:
  var id: String=str(option["id"])
  var box: VBoxContainer=host._box(5)
  body.add_child(box)
  var button: Button=host._button("","GoalFocusChoice_"+id,host._goal_focus_select.bind(id,int(host._focus_picker_epoch),int(host._render_generation)))
  button.tooltip_text=str(option["title"])+" · "+str(option["description"])
  button.toggle_mode=true
  button.set_pressed_no_signal(host._focus_draft==id)
  button.disabled=bool(host.busy) or (bool(option["claimed"]) and str(choices["chapter_id"])!=id)
  box.add_child(button)
  var margin:=MarginContainer.new()
  margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
  margin.mouse_filter=Control.MOUSE_FILTER_IGNORE
  for side in ["left","right"]:margin.add_theme_constant_override("margin_"+side,10)
  for side in ["top","bottom"]:margin.add_theme_constant_override("margin_"+side,6)
  button.add_child(margin)
  var identity:=HBoxContainer.new()
  identity.add_theme_constant_override("separation",8)
  identity.mouse_filter=Control.MOUSE_FILTER_IGNORE
  margin.add_child(identity)
  var icon:=TextureRect.new()
  icon.name="GoalFocusIcon_"+id
  icon.custom_minimum_size=Vector2(32,32)
  icon.expand_mode=TextureRect.EXPAND_IGNORE_SIZE
  icon.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED
  icon.mouse_filter=Control.MOUSE_FILTER_IGNORE
  icon.focus_mode=Control.FOCUS_NONE
  var source: Dictionary=icons.get(str(FOCUS_ICONS[id]),{})
  var region: Array=source.get("region",[])
  var texture: String=str(source.get("texture",""))
  if region.size()==4 and ResourceLoader.exists(texture):
   var atlas:=AtlasTexture.new()
   atlas.atlas=load(texture) as Texture2D
   atlas.region=Rect2(float(region[0]),float(region[1]),float(region[2]),float(region[3]))
   atlas.filter_clip=true
   icon.texture=atlas
   icon.set_meta("source",texture)
   icon.set_meta("source_region",atlas.region)
  identity.add_child(icon)
  var title: Label=C.label(str(option["title"]),16)
  title.name="GoalFocusTitle_"+id
  title.mouse_filter=Control.MOUSE_FILTER_IGNORE
  title.focus_mode=Control.FOCUS_NONE
  title.vertical_alignment=VERTICAL_ALIGNMENT_CENTER
  identity.add_child(title)
  var row: HFlowContainer=_row(box,"GoalFocusProgress_"+id)
  for entry in option["requirements"]:
   var key: String=str(entry["key"])
   var recorded: bool=bool(entry["recorded"])
   var current: int=int(entry["current"])
   var target: int=int(entry["target"])
   var text: String="%s %d/%d" % [str(Direction.LABELS.get(key,key.capitalize())),current,target] if recorded else str(Direction.LABELS.get(key,key.capitalize()))+" / NOT RECORDED"
   var count: Label=_pill(row,text,"GoalFocusRequirement_"+id+"_"+key,1 if recorded and current>=target else 0)
   count.set_meta("current",current)
   count.set_meta("target",target)
   count.set_meta("recorded",recorded)
  if bool(option["claimed"]):_copy(box,"COMPLETED CHAPTER","GoalFocusCompleted_"+id,true)
  elif bool(option["ready"]):_copy(box,"REQUIREMENTS MET · NO REWARD CLAIMED HERE","GoalFocusReady_"+id,true)

static func chooser_dock(host, parent: Node) -> void:
 var valid: Dictionary=Focus.validate(host.game.career)
 var commitment: Label=C.label("CHOOSE OR CHANGE  •  FREE / 0 DAYS",16)
 commitment.name="GoalFocusCommitment"
 parent.add_child(commitment)
 var commit: Button=host._button("SAVE THIS FOCUS","GoalFocusCommitAction",host._goal_focus_commit.bind(false,int(host._focus_picker_epoch),int(host._render_generation)),true)
 commit.disabled=bool(host.busy) or not bool(valid["ok"]) or str(host._focus_draft).is_empty()
 parent.add_child(commit)
 var clear: Button=host._button("RETURN TO SUGGESTED GOAL","GoalFocusClearAction",host._goal_focus_commit.bind(true,int(host._focus_picker_epoch),int(host._render_generation)))
 clear.disabled=bool(host.busy) or not bool(valid["ok"])
 parent.add_child(clear)
 var back: Button=host._button("BACK WITHOUT CHANGES","GoalFocusBackAction",host._goal_focus_back.bind(int(host._focus_picker_epoch),int(host._render_generation)))
 parent.add_child(back)

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
