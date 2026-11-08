extends RefCounted
## S63 free gear presentation. Prices/ownership are native data, not baked art.
const C = preload("res://experiments/playable_flightcase/career_components.gd")
const Kit = preload("res://components/control_atlas/kit.gd")
const Catalog = preload("res://experiments/playable_flightcase/gear_catalog.gd")
const SHEET_PATH := "res://experiments/playable_flightcase/art/gear_display.png"
const PROVENANCE_PATH := "res://experiments/playable_flightcase/art/GEAR_DISPLAY_PROVENANCE.json"
const REGIONS := {
 "shop_guitar_new":[108,103,184,471],
 "shop_bass_new":[445,106,165,467],
 "shop_cymbals_new":[729,238,291,337],
 "drums":[1076,274,346,293],
 "amp":[43,690,303,312],
 "mics":[388,720,295,279],
 "pedals":[715,770,349,214],
 "pa":[1089,727,335,266]
}
static var _sheet: Texture2D

static func image(item_id: String, height: float) -> TextureRect:
 var picture := TextureRect.new()
 picture.name = "GearArt_"+item_id
 picture.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
 picture.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
 picture.custom_minimum_size.y = maxf(1.0,height)
 picture.size_flags_horizontal = Control.SIZE_EXPAND_FILL
 picture.mouse_filter = Control.MOUSE_FILTER_IGNORE
 picture.focus_mode = Control.FOCUS_NONE
 picture.set_meta("gear_item_id",item_id)
 picture.set_meta("source",SHEET_PATH)
 picture.set_meta("region_provenance",PROVENANCE_PATH)
 if not REGIONS.has(item_id): return picture
 if _sheet==null and ResourceLoader.exists(SHEET_PATH):
  _sheet = load(SHEET_PATH) as Texture2D
 if _sheet==null: return picture
 var raw: Array = REGIONS[item_id]
 var region := Rect2(float(raw[0]),float(raw[1]),float(raw[2]),float(raw[3]))
 var atlas := AtlasTexture.new()
 atlas.atlas = _sheet
 atlas.region = region
 atlas.filter_clip = true
 picture.texture = atlas
 picture.set_meta("source_region",region)
 picture.set_meta("shared_origin_product_plate",true)
 return picture

static func _copy(host, parent: Node, value: String, points: int=16, muted: bool=false, node_name: String="") -> Label:
 var label: Label = host._copy(parent,value,points,muted)
 if not node_name.is_empty(): label.name = node_name
 label.mouse_filter = Control.MOUSE_FILTER_IGNORE
 label.focus_mode = Control.FOCUS_NONE
 return label

static func inventory(host, parent: Node, compact: bool) -> void:
 var body: VBoxContainer = host._paper(parent,compact)
 body.name = "GearOwnedInventory"
 _copy(host,body,"YOUR OWNED EQUIPMENT",20)
 var raw_owned: Variant = host.game.career.get("owned_equipment",[])
 var owned: Array = raw_owned if raw_owned is Array else []
 if owned.is_empty():
  _copy(host,body,"No shop purchases yet. The band's personal instruments are not tracked here.",16,true,"GearInventoryEmpty")
  return
 for raw_id in owned:
  var item_id: String = str(raw_id)
  var item: Dictionary = Catalog.item_for(item_id)
  var entry: VBoxContainer = host._box(4)
  entry.name = "GearOwned_"+item_id
  entry.mouse_filter = Control.MOUSE_FILTER_PASS
  body.add_child(entry)
  var row := HBoxContainer.new()
  row.add_theme_constant_override("separation",10)
  row.mouse_filter = Control.MOUSE_FILTER_PASS
  entry.add_child(row)
  if REGIONS.has(item_id):
   var picture: TextureRect = image(item_id,88.0)
   picture.name = "GearOwnedArt_"+item_id
   picture.custom_minimum_size.x = 92.0
   picture.size_flags_horizontal = Control.SIZE_FILL
   row.add_child(picture)
  var facts: VBoxContainer = host._box(3)
  facts.mouse_filter = Control.MOUSE_FILTER_PASS
  row.add_child(facts)
  _copy(host,facts,str(item.get("name",item_id)),16,false,"GearOwnedName_"+item_id)
  var record: Dictionary = Catalog.record(host.game.career,item_id)
  var condition: int = int(record.get("condition",-1))
  _copy(host,facts,"CONDITION / "+("UNKNOWN" if condition<0 else "%d / 100" % condition),16,true,"GearOwnedCondition_"+item_id)
  var holder: int = Catalog.holder_index(host.game.career,record)
  var members: Array = host.game.career.get("members",[])
  var holder_name: String = str(members[holder].get("name","Musician")) if holder>=0 else "SHARED ROAD CASE"
  _copy(host,facts,"CARRIED BY / "+holder_name,16,true,"GearOwnedHolder_"+item_id)
  _copy(host,entry,str(record.get("provenance","History not recorded")),16,true,"GearOwnedProvenance_"+item_id)

static func _fit_catalogue(grid: GridContainer, offers: Array, word_width: float, inset: float) -> void:
 if not is_instance_valid(grid) or not grid.is_inside_tree() or grid.size.x<=0.0:return
 # The original housing reserves12px per side. A narrow two-column card
 # cannot safely contain RECONDITIONED at the original16px font size.
 var text_minimum: float=ceilf(word_width)+2.0
 var two_column_inner: float=(grid.size.x-float(grid.get_theme_constant("h_separation")))*0.5-2.0*inset
 var horizontal: bool=two_column_inner<text_minimum
 var art_width: float=minf(92.0,maxf(48.0,grid.size.x-2.0*inset-10.0-text_minimum)) if horizontal else 0.0
 var signature:=Vector2(1.0 if horizontal else 2.0,art_width)
 if grid.get_meta("offer_layout",Vector2(-1,-1))==signature:return
 grid.set_meta("offer_layout",signature)
 grid.columns=1 if horizontal else 2
 for entry in offers:
  var tile: Button=entry["tile"]
  var contents: GridContainer=entry["contents"]
  var picture: TextureRect=entry["picture"]
  var facts: VBoxContainer=entry["facts"]
  var margin: MarginContainer=entry["margin"]
  contents.columns=2 if horizontal else 1
  tile.custom_minimum_size.y=140.0 if horizontal else 248.0
  picture.custom_minimum_size.x=art_width
  picture.size_flags_horizontal=Control.SIZE_FILL if horizontal else Control.SIZE_EXPAND_FILL
  facts.custom_minimum_size.x=text_minimum if horizontal else 0.0
  facts.size_flags_vertical=Control.SIZE_SHRINK_CENTER if horizontal else Control.SIZE_FILL
  for side in ["left","right"]:margin.add_theme_constant_override("margin_"+side,roundi(inset))
  for label in [entry["title"],entry["price"]]:
   (label as Label).horizontal_alignment=HORIZONTAL_ALIGNMENT_LEFT if horizontal else HORIZONTAL_ALIGNMENT_CENTER
  tile.set_meta("offer_horizontal",horizontal)
  tile.set_meta("safe_word_width",text_minimum)

static func catalogue(host, parent: Node, compact: bool) -> void:
 inventory(host,parent,compact)
 var body: VBoxContainer = host._paper(parent,compact)
 body.name = "GearIllustratedCatalogue"
 _copy(host,body,"THE MUSIC SHOP",22)
 _copy(host,body,"Choose an item to inspect. Browsing is free.",16,true)
 var grid := GridContainer.new()
 grid.name = "GearOfferGrid"
 grid.columns = 2
 grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
 grid.mouse_filter = Control.MOUSE_FILTER_PASS
 grid.add_theme_constant_override("h_separation",8)
 grid.add_theme_constant_override("v_separation",10)
 body.add_child(grid)
 var raw_owned: Variant = host.game.career.get("owned_equipment",[])
 var owned: Array = raw_owned if raw_owned is Array else []
 var offers: Array=[]
 var longest_word: float=0.0
 var safe_inset: float=8.0
 for raw in Catalog.items():
  var item: Dictionary = raw
  var item_id: String = str(item.get("id",""))
  if item_id.is_empty(): continue
  var is_owned: bool = owned.has(item_id)
  var name: String = str(item.get("name",item_id))
  var status: String = "OWNED" if is_owned else "£%d / %s" % [int(item.get("price",0)),str(item.get("stock","SECOND-HAND"))]
  var tile: Button = C.button("","flightcase","tab",true)
  tile.name = "GearChoice_"+item_id
  # Reserve art plus two wrapped native16 copy rows. Button children do not
  # automatically contribute their minimum size to the parent Button.
  tile.custom_minimum_size = Vector2(130,248)
  tile.size_flags_horizontal = Control.SIZE_EXPAND_FILL
  tile.mouse_filter = Control.MOUSE_FILTER_PASS
  tile.disabled = bool(host.busy)
  tile.set_pressed_no_signal(str(host.selected_item)==item_id)
  tile.tooltip_text = name+" / "+status+". Inspect only; no purchase."
  tile.set_meta("gear_item_id",item_id)
  tile.set_meta("inspect_only",true)
  tile.pressed.connect(host._choose_item.bind(item_id))
  var housing: StyleBox=tile.get_theme_stylebox("normal")
  safe_inset=maxf(safe_inset,maxf(housing.get_content_margin(SIDE_LEFT),housing.get_content_margin(SIDE_RIGHT)))
  grid.add_child(tile)
  var margin := MarginContainer.new()
  margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
  margin.mouse_filter = Control.MOUSE_FILTER_IGNORE
  for side in ["left","right","top","bottom"]:
   margin.add_theme_constant_override("margin_"+side,8)
  tile.add_child(margin)
  var contents := GridContainer.new()
  contents.columns=1
  contents.mouse_filter = Control.MOUSE_FILTER_IGNORE
  contents.add_theme_constant_override("h_separation",10)
  contents.add_theme_constant_override("v_separation",4)
  margin.add_child(contents)
  var picture: TextureRect = image(item_id,108.0)
  picture.name = "GearOfferArt_"+item_id
  contents.add_child(picture)
  var facts:=VBoxContainer.new()
  facts.size_flags_horizontal=Control.SIZE_EXPAND_FILL
  facts.mouse_filter=Control.MOUSE_FILTER_IGNORE
  facts.add_theme_constant_override("separation",4)
  contents.add_child(facts)
  var title: Label = C.paper_label(("✓ " if str(host.selected_item)==item_id else "")+name,16)
  title.name = "GearOfferName_"+item_id
  title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
  title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
  title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
  title.mouse_filter = Control.MOUSE_FILTER_IGNORE
  title.focus_mode = Control.FOCUS_NONE
  facts.add_child(title)
  var price: Label = C.paper_label(status,16)
  price.name = "GearOfferStatus_"+item_id
  price.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
  price.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
  price.size_flags_horizontal = Control.SIZE_EXPAND_FILL
  price.mouse_filter = Control.MOUSE_FILTER_IGNORE
  price.focus_mode = Control.FOCUS_NONE
  facts.add_child(price)
  for label in [title,price]:
   var font: Font=(label as Label).get_theme_font("font")
   var points: int=(label as Label).get_theme_font_size("font_size")
   for word in (label as Label).text.split(" ",false):
    longest_word=maxf(longest_word,font.get_string_size(word,HORIZONTAL_ALIGNMENT_LEFT,-1,points).x)
  offers.append({"tile":tile,"contents":contents,"picture":picture,"facts":facts,"margin":margin,"title":title,"price":price})
 # No suspended instance method: a freed/replaced catalogue is ignored before
 # passing any typed node arguments to the responsive layout helper.
 var fit: Callable=func():
  if is_instance_valid(grid) and grid.is_inside_tree():_fit_catalogue(grid,offers,longest_word,safe_inset)
 grid.resized.connect(fit)
 fit.call_deferred()
