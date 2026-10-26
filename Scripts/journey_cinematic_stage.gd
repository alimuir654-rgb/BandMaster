extends RefCounted
# Shared photo-first composition for both authored journeys. Decorative only:
# all progression, save state and economy remain in their original controllers.

static func add_hero(parent: Node, photo_path: String, scene_name: String, beat: String, accent: Color, height: float) -> Control:
 var hero := Control.new()
 hero.name = "JourneyCinematicHero"
 hero.custom_minimum_size = Vector2(0,height)
 hero.size_flags_horizontal = Control.SIZE_EXPAND_FILL
 hero.clip_contents = true
 parent.add_child(hero)
 if ResourceLoader.exists(photo_path):
  var photo := TextureRect.new()
  photo.name = "JourneyHeroPhoto"
  photo.texture = load(photo_path)
  photo.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
  photo.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
  photo.mouse_filter = Control.MOUSE_FILTER_IGNORE
  hero.add_child(photo)
  photo.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
 else:
  var fallback := ColorRect.new()
  fallback.color = Color("#18212A")
  fallback.mouse_filter = Control.MOUSE_FILTER_IGNORE
  hero.add_child(fallback)
  fallback.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
 var wash := ColorRect.new()
 wash.name = "JourneyHeroWash"
 wash.color = Color(0.015,0.025,0.035,0.12)
 wash.mouse_filter = Control.MOUSE_FILTER_IGNORE
 hero.add_child(wash)
 wash.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
 var shade := ColorRect.new()
 shade.name = "JourneyHeroLowerThird"
 shade.color = Color(0.015,0.025,0.035,0.88)
 shade.mouse_filter = Control.MOUSE_FILTER_IGNORE
 hero.add_child(shade)
 shade.anchor_top = 0.67
 shade.anchor_bottom = 1.0
 shade.anchor_right = 1.0
 var inset := MarginContainer.new()
 inset.name = "JourneyHeroCaption"
 inset.mouse_filter = Control.MOUSE_FILTER_IGNORE
 hero.add_child(inset)
 inset.anchor_top = 0.66
 inset.anchor_bottom = 1.0
 inset.anchor_right = 1.0
 inset.add_theme_constant_override("margin_left",18)
 inset.add_theme_constant_override("margin_right",18)
 inset.add_theme_constant_override("margin_top",8)
 inset.add_theme_constant_override("margin_bottom",13)
 var column := VBoxContainer.new()
 column.alignment = BoxContainer.ALIGNMENT_END
 column.add_theme_constant_override("separation",4)
 inset.add_child(column)
 var kicker := Label.new()
 kicker.text = scene_name
 kicker.add_theme_font_size_override("font_size",13)
 kicker.add_theme_color_override("font_color",accent)
 column.add_child(kicker)
 var headline := Label.new()
 headline.text = beat
 headline.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
 headline.add_theme_font_size_override("font_size",25)
 headline.add_theme_color_override("font_color",Color("#F7F4ED"))
 column.add_child(headline)
 return hero
