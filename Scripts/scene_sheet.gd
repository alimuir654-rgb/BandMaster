extends RefCounted
# Reusable accessible, image-optional decision sheet for future dialogue, venue and milestone scenes.
# This class builds presentation only: authoritative actions remain with the caller.
const UI = preload("res://Scripts/ui_theme.gd")

static func build(parent: Control, heading: String, description: String, image_path: String = "", genre_id: String = "indie") -> Dictionary:
 var shade := ColorRect.new()
 shade.name = "SceneSheet"
 shade.color = Color(0.04,0.05,0.075,0.97)
 shade.mouse_filter = Control.MOUSE_FILTER_STOP
 parent.add_child(shade)
 shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
 var scroll := ScrollContainer.new()
 scroll.name = "SceneSheetScroll"
 shade.add_child(scroll)
 scroll.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
 scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
 var center := CenterContainer.new()
 center.size_flags_horizontal = Control.SIZE_EXPAND_FILL
 center.size_flags_vertical = Control.SIZE_EXPAND_FILL
 scroll.add_child(center)
 var panel := PanelContainer.new()
 panel.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
 panel.custom_minimum_size.x = maxf(0.0,minf(640.0,parent.get_viewport_rect().size.x-32.0))
 panel.add_theme_stylebox_override("panel",UI.style(Color("#24252C"),15))
 center.add_child(panel)
 var body := VBoxContainer.new()
 body.name = "SceneSheetBody"
 body.add_theme_constant_override("separation",12)
 panel.add_child(body)
 var title := Label.new()
 title.text = heading
 title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
 title.add_theme_font_size_override("font_size",24)
 title.add_theme_color_override("font_color",UI.WHITE)
 body.add_child(title)
 if ResourceLoader.exists(image_path):
  var art := TextureRect.new()
  art.name = "SceneSheetArt"
  art.texture = load(image_path)
  art.custom_minimum_size.y = 175
  art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
  art.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
  art.mouse_filter = Control.MOUSE_FILTER_IGNORE
  body.add_child(art)
 var copy := Label.new()
 copy.text = description
 copy.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
 copy.add_theme_font_size_override("font_size",15)
 copy.add_theme_color_override("font_color",UI.MUTED)
 body.add_child(copy)
 var actions := VBoxContainer.new()
 actions.name = "SceneSheetActions"
 actions.add_theme_constant_override("separation",8)
 body.add_child(actions)
 return {"overlay":shade,"body":body,"actions":actions}

static func add_choice(sheet: Dictionary, label: String, callback: Callable, primary: bool = false, genre_id: String = "indie") -> BaseButton:
 var actions: VBoxContainer = sheet["actions"]
 var button := UI.themed_button(label,genre_id,primary)
 button.custom_minimum_size.y = 52
 button.focus_mode = Control.FOCUS_ALL
 actions.add_child(button)
 button.pressed.connect(callback)
 return button

static func dismiss(sheet: Dictionary) -> void:
 var overlay: Control = sheet.get("overlay")
 if is_instance_valid(overlay):
  overlay.queue_free()
