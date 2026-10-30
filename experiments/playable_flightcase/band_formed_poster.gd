extends VBoxContainer
## S36: a small printed music-feature moment composed from ACTUAL saved
## S35 preview portraits. Paper is an existing textured source; the people,
## captions and count remain native data, not a flattened screenshot.
const Kit = preload("res://components/control_atlas/kit.gd")
const Group = preload("res://experiments/playable_flightcase/band_lineup.gd")
const PAPER = preload("res://components/control_atlas/art/paper_surface.png")

var member_ids: Array[String] = []

func _ink(value: String, points: int, subdued: bool = false) -> Label:
 var label: Label = Kit.label(value,"notepaper",points)
 label.add_theme_color_override("font_color",Color("61564a") if subdued else Color("28231e"))
 label.mouse_filter = Control.MOUSE_FILTER_IGNORE
 label.focus_mode = Control.FOCUS_NONE
 return label

func configure(roster: Array, lead_id: String, viewport_width: float) -> void:
 for old in get_children():
  remove_child(old)
  old.queue_free()
 mouse_filter = Control.MOUSE_FILTER_IGNORE
 focus_mode = Control.FOCUS_NONE
 size_flags_horizontal = Control.SIZE_EXPAND_FILL
 add_theme_constant_override("separation",0)
 var narrow: bool = viewport_width < 720.0
 var tiny: bool = viewport_width < 480.0
 var magazine := PanelContainer.new()
 magazine.name = "BandPosterPaper"
 magazine.size_flags_horizontal = Control.SIZE_EXPAND_FILL
 magazine.mouse_filter = Control.MOUSE_FILTER_IGNORE
 magazine.focus_mode = Control.FOCUS_NONE
 var print_stock := StyleBoxTexture.new()
 print_stock.texture = PAPER
 print_stock.set_texture_margin_all(8.0)
 print_stock.set_content_margin_all(12.0 if narrow else 16.0)
 magazine.add_theme_stylebox_override("panel",print_stock)
 add_child(magazine)
 var content := VBoxContainer.new()
 content.name = "BandPosterEditorial"
 content.add_theme_constant_override("separation",5 if tiny else 8)
 content.mouse_filter = Control.MOUSE_FILTER_IGNORE
 magazine.add_child(content)
 var masthead := HBoxContainer.new()
 masthead.name = "BandPosterMasthead"
 masthead.add_theme_constant_override("separation",4)
 masthead.mouse_filter = Control.MOUSE_FILTER_IGNORE
 content.add_child(masthead)
 var publication: Label = _ink("LIVIN' THE DREAM",10 if tiny else 12)
 publication.size_flags_horizontal = Control.SIZE_EXPAND_FILL
 masthead.add_child(publication)
 var issue: Label = _ink("FIRST PRESS  /  001",9 if tiny else 11,true)
 issue.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
 masthead.add_child(issue)
 var rule := ColorRect.new()
 rule.name = "BandPosterInkRule"
 rule.color = Color("625142")
 rule.custom_minimum_size.y = 2.0
 rule.mouse_filter = Control.MOUSE_FILTER_IGNORE
 content.add_child(rule)
 var kicker: Label = _ink("THE FIRST LINEUP   /   UNSIGNED",10 if tiny else 11,true)
 kicker.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
 content.add_child(kicker)
 var headline: Label = _ink("YOU'VE GOT A BAND.",25 if tiny else (30 if narrow else 36))
 headline.name = "BandPosterHeadline"
 headline.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
 headline.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
 content.add_child(headline)
 var deck: Label = _ink("The people are in place. The name comes next.",12 if tiny else 14)
 deck.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
 deck.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
 content.add_child(deck)
 var photograph := PanelContainer.new()
 photograph.name = "BandPosterPhotoMatte"
 photograph.size_flags_horizontal = Control.SIZE_EXPAND_FILL
 photograph.mouse_filter = Control.MOUSE_FILTER_IGNORE
 photograph.focus_mode = Control.FOCUS_NONE
 var ink_matte := StyleBoxFlat.new()
 ink_matte.bg_color = Color("201e1b")
 ink_matte.border_color = Color("82705c")
 ink_matte.set_border_width_all(1)
 ink_matte.set_content_margin_all(5.0)
 photograph.add_theme_stylebox_override("panel",ink_matte)
 content.add_child(photograph)
 var lineup: Variant = Group.new()
 lineup.name = "SelectedBandLineup"
 photograph.add_child(lineup)
 # Outer metal stage margins (56), print-stock insets (24/32) and photo mat
 # insets (10). This must fit in 390px without expanding its source frame.
 var stage_width: float = minf(760.0, viewport_width-(40.0 if narrow else 80.0))
 var room: float = maxf(210.0,stage_width-56.0-(24.0 if narrow else 32.0)-10.0)
 lineup.configure(roster,lead_id,viewport_width,room)
 member_ids=lineup.visible_ids()
 var footer := HBoxContainer.new()
 footer.name = "BandPosterEditionFooter"
 footer.add_theme_constant_override("separation",4)
 footer.mouse_filter = Control.MOUSE_FILTER_IGNORE
 content.add_child(footer)
 var credit: Label = _ink("FOUNDING LINEUP  /  %d MEMBERS" % member_ids.size(),9 if tiny else 11,true)
 credit.size_flags_horizontal = Control.SIZE_EXPAND_FILL
 footer.add_child(credit)
 var smallmark: Label = _ink("EST. TODAY",9 if tiny else 11,true)
 smallmark.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
 footer.add_child(smallmark)

func visible_ids() -> Array[String]:
 return member_ids.duplicate()
