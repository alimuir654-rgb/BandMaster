extends RefCounted
## Separate blank material source, never a flattened game screen. Original PNG
## and creation basis are retained beside the scene in art/PROVENANCE.json.
const Paper = preload("res://experiments/playable_flightcase/art/session_paper.png")
const Inset = preload("res://components/control_atlas/art/frame_notepaper_inset.png")
static var paper_texture: ImageTexture
static var inset_texture: ImageTexture

static func sheet(compact: bool) -> StyleBoxTexture:
 if paper_texture == null:
  var image := Paper.get_image()
  image.resize(384,288,Image.INTERPOLATE_LANCZOS)
  paper_texture = ImageTexture.create_from_image(image)
 var stock := StyleBoxTexture.new()
 stock.texture = paper_texture
 stock.set_texture_margin_all(32)
 stock.texture_margin_bottom = 40
 stock.content_margin_left = 18 if compact else 26
 stock.content_margin_right = 18 if compact else 26
 stock.content_margin_top = 28
 stock.content_margin_bottom = 32
 return stock

static func scorecard() -> StyleBoxTexture:
 if inset_texture == null:
  var image := Inset.get_image()
  image.resize(96,48,Image.INTERPOLATE_LANCZOS)
  inset_texture = ImageTexture.create_from_image(image)
 var stock := StyleBoxTexture.new()
 stock.texture = inset_texture
 stock.set_texture_margin_all(10)
 stock.texture_margin_bottom = 12
 stock.set_content_margin_all(8)
 return stock
