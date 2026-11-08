extends RefCounted
## Separate blank material source, never a flattened game screen. Original PNG
## and creation basis are retained beside the scene in art/PROVENANCE.json.
const Paper = preload("res://experiments/playable_flightcase/art/session_paper.png")
static var paper_texture: ImageTexture

static func sheet(compact: bool) -> StyleBoxTexture:
 var poster=preload("res://experiments/playable_flightcase/poster_components.gd")
 var sheet: StyleBoxTexture=poster.stock(poster.PAPER,18 if compact else 26)
 sheet.content_margin_top=28;sheet.content_margin_bottom=32
 return sheet

static func legacy_sheet(compact: bool) -> StyleBoxTexture:
 if paper_texture == null:
  var image := Paper.get_image()
  image.resize(384,288,Image.INTERPOLATE_LANCZOS)
  paper_texture = ImageTexture.create_from_image(image)
 var stock := StyleBoxTexture.new()
 stock.texture = paper_texture
 stock.set_texture_margin_all(32)
 stock.texture_margin_bottom = 40
 # The source includes a transparent safety border. Let that border bleed
 # outside the layout box so live text remains inside the actual paper face.
 stock.set_expand_margin_all(16)
 stock.content_margin_left = 18 if compact else 26
 stock.content_margin_right = 18 if compact else 26
 stock.content_margin_top = 28
 stock.content_margin_bottom = 32
 return stock

static func scorecard() -> StyleBoxTexture:
 if paper_texture == null:
  legacy_sheet(false)
 var stock := StyleBoxTexture.new()
 stock.texture = paper_texture
 # Printed score fields use the quiet interior of the same independent paper
 # source. No raised bevel/shadow: these are results, not editable keys.
 stock.region_rect = Rect2(64,48,256,160)
 stock.set_texture_margin_all(6)
 stock.modulate_color = Color("ede4d3")
 stock.set_content_margin_all(8)
 return stock
