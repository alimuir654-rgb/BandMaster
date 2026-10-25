extends Control
# Visual acceptance lab: standalone, non-invasive WoldUI migration proving icons,
# buttons, a management dashboard, and a landscape workspace.
const ButtonScene = preload("res://addons/woldui/components/wold_button/wold_button.tscn")

func _ready() -> void:
 set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
 var bg := ColorRect.new()
 bg.color = Color("#0B101C")
 bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
 add_child(bg)
 var shell := HBoxContainer.new()
 shell.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
 shell.add_theme_constant_override("separation",12)
 add_child(shell)
 var rail := VBoxContainer.new()
 rail.custom_minimum_size.x = 96
 rail.add_theme_constant_override("separation",8)
 shell.add_child(rail)
 for entry in [{"label":"HOME","icon":"house"},{"label":"BAND","icon":"users"},{"label":"STUDIO","icon":"music"},{"label":"GIGS","icon":"ticket"},{"label":"GEAR","icon":"guitar"}]:
  var item := ButtonScene.instantiate()
  item.text = str(entry["label"])
  item.icon_start = str(entry["icon"])
  item.custom_minimum_size.y = 60
  item.shape = WoldButton.Shape.SECONDARY
  rail.add_child(item)
 var workspace := VBoxContainer.new()
 workspace.size_flags_horizontal = Control.SIZE_EXPAND_FILL
 workspace.add_theme_constant_override("separation",14)
 shell.add_child(workspace)
 var headline := Label.new()
 headline.text = "BANDMASTER  /  THE WRITING ROOM"
 headline.add_theme_font_size_override("font_size",25)
 workspace.add_child(headline)
 var status := Label.new()
 status.text = "DAY 12     CASH £120     FANS 54     CHEMISTRY 74"
 workspace.add_child(status)
 var nav := HBoxContainer.new()
 nav.add_theme_constant_override("separation",12)
 workspace.add_child(nav)
 for item_data in [{"text":"START A SONG","icon":"music-2","primary":true},{"text":"REHEARSE","icon":"audio-lines","primary":false},{"text":"BANDMATES","icon":"users","primary":false}]:
  var button := ButtonScene.instantiate()
  button.text = str(item_data["text"])
  button.icon_start = str(item_data["icon"])
  button.icon_end = "arrow-right"
  button.shape = WoldButton.Shape.PRIMARY if bool(item_data["primary"]) else WoldButton.Shape.SECONDARY
  button.custom_minimum_size.y = 64
  nav.add_child(button)
 var panel := PanelContainer.new()
 panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
 workspace.add_child(panel)
 var text := Label.new()
 text.text = "CURRENT ORIGINAL   •   NO WAY HOME\n\nIDEA   →   SHAPE   →   FINISH\n\nWork in progress. Explore and compare takes."
 text.add_theme_font_size_override("font_size",21)
 panel.add_child(text)
