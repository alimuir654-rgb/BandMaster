extends RefCounted
# Responsive sizing rules shared by CareerHub's scroll body and navigation.
const COMPACT_WIDTH := 560.0
static func is_compact(width: float) -> bool:
 return width < COMPACT_WIDTH
static func columns(width: float) -> int:
 return 3 if is_compact(width) else 6
static func footer_height(width: float) -> float:
 return 174.0 if is_compact(width) else 104.0
static func content_inset(width: float) -> float:
 return footer_height(width) + 10.0

# UX layout rules: keep action navigation readable and reduce image-first scrolling.
static func hero_height(width: float) -> float:
 return 152.0 if is_compact(width) else 210.0

static func destination_columns(width: float) -> int:
 return 1 if width < 380.0 else 2

static func nav_label(tab: String) -> String:
 match tab:
  "ACTIONS": return "STUDIO"
  "SCENE": return "CAREER"
  _: return tab

static func nav_hint(tab: String) -> String:
 match tab:
  "HOME": return "Overview and next move"
  "GIGS": return "Book, prepare and play"
  "GEAR": return "Buy and repair equipment"
  "BAND": return "People and relationships"
  "ACTIONS": return "Write, rehearse and connect"
  "SCENE": return "Releases, publicity and history"
  _: return tab

# Responsive layout tokens used for legibility across small phones and tablets.
static func content_gutter(width: float) -> int:
 return 8 if width < 380.0 else (12 if is_compact(width) else 20)

static func body_scale(width: float) -> int:
 return 12 if width < 380.0 else 14

static func studio_banner_height(width: float) -> float:
 return 116.0 if width < 380.0 else (148.0 if is_compact(width) else 184.0)

static func member_portrait_size(width: float) -> Vector2:
 return Vector2(64,82) if width < 380.0 else Vector2(88,108)

static func member_name_font_size(width: float) -> int:
 return 18 if width < 380.0 else 24
