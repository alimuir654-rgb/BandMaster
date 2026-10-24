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
