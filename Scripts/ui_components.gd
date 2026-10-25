extends RefCounted
# Reusable visual components for career stories, character cards and goals.
const UI = preload("res://Scripts/ui_theme.gd")

static func section(parent: Node, heading: String, description: String = "", genre_id: String = "indie") -> VBoxContainer:
 var panel := PanelContainer.new()
 var colors := UI.palette(genre_id)
 var card_style := UI.style(colors["panel"],14)
 card_style.border_color = colors["alt"].lightened(0.22)
 panel.add_theme_stylebox_override("panel",card_style)
 panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
 parent.add_child(panel)
 var body := VBoxContainer.new()
 body.add_theme_constant_override("separation",10)
 panel.add_child(body)
 if not heading.is_empty():
  var label := Label.new()
  label.text = heading.to_upper()
  label.add_theme_font_size_override("font_size",19)
  label.add_theme_color_override("font_color",colors["accent"])
  label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
  body.add_child(label)
 if not description.is_empty():
  var subtitle := Label.new()
  subtitle.text = description
  subtitle.add_theme_font_size_override("font_size",15)
  subtitle.add_theme_color_override("font_color",UI.WHITE)
  subtitle.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
  body.add_child(subtitle)
 return body

static func portrait(parent: Node, person: Dictionary) -> PanelContainer:
 var portrait_panel := PanelContainer.new()
 portrait_panel.custom_minimum_size = Vector2(78,90)
 portrait_panel.add_theme_stylebox_override("panel",UI.style(Color("#273648"),10))
 parent.add_child(portrait_panel)
 var details := VBoxContainer.new()
 details.alignment = BoxContainer.ALIGNMENT_CENTER
 portrait_panel.add_child(details)
 var initial := Label.new()
 initial.text = str(person.get("name","?")).left(1).to_upper()
 initial.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
 initial.add_theme_font_size_override("font_size",38)
 initial.add_theme_color_override("font_color",UI.AMBER)
 details.add_child(initial)
 var mark := Label.new()
 mark.text = str(person.get("role","MUSICIAN")).left(10).to_upper()
 mark.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
 mark.add_theme_font_size_override("font_size",9)
 mark.add_theme_color_override("font_color",UI.MUTED)
 mark.clip_text = true
 details.add_child(mark)
 return portrait_panel

static func story(parent: Node, moment: Dictionary) -> void:
 var row := HBoxContainer.new()
 row.add_theme_constant_override("separation",12)
 parent.add_child(row)
 var stripe := ColorRect.new()
 stripe.custom_minimum_size = Vector2(3,52)
 stripe.color = UI.AMBER
 row.add_child(stripe)
 var details := VBoxContainer.new()
 details.size_flags_horizontal = Control.SIZE_EXPAND_FILL
 details.add_theme_constant_override("separation",3)
 row.add_child(details)
 var overline := Label.new()
 overline.text = "DAY %d   /   %s" % [int(moment.get("day",1)),str(moment.get("kind","career")).to_upper()]
 overline.add_theme_font_size_override("font_size",11)
 overline.add_theme_color_override("font_color",UI.MUTED)
 details.add_child(overline)
 var title := Label.new()
 title.text = str(moment.get("title","A MOMENT IN THE STORY"))
 title.add_theme_font_size_override("font_size",17)
 title.add_theme_color_override("font_color",UI.WHITE)
 title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
 details.add_child(title)
 var description := Label.new()
 description.text = str(moment.get("text",""))
 description.add_theme_font_size_override("font_size",13)
 description.add_theme_color_override("font_color",UI.MUTED)
 description.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
 details.add_child(description)
 var rule := HSeparator.new()
 parent.add_child(rule)

static func objective(parent: Node, entry: Dictionary) -> void:
 var row := HBoxContainer.new()
 row.add_theme_constant_override("separation",12)
 parent.add_child(row)
 var current := int(entry.get("current",0))
 var target := maxi(1,int(entry.get("target",1)))
 var complete := current >= target
 var label := Label.new()
 label.text = ("✓  " if complete else "○  ")+str(entry.get("label","")).replace("_"," ").to_upper()
 label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
 label.add_theme_font_size_override("font_size",14)
 label.add_theme_color_override("font_color",UI.AMBER if complete else UI.WHITE)
 row.add_child(label)
 var count := Label.new()
 count.text = "%d / %d" % [current,target]
 count.add_theme_font_size_override("font_size",13)
 count.add_theme_color_override("font_color",UI.AMBER if complete else UI.MUTED)
 row.add_child(count)
 var progress := ProgressBar.new()
 progress.custom_minimum_size.y = 8
 UI.progress(progress)
 progress.max_value = target
 progress.value = mini(current,target)
 parent.add_child(progress)
