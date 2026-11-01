extends SceneTree
## Independent numeric oracles for physical cutouts, stretch and window origin.
const Safe = preload("res://experiments/playable_flightcase/mobile_safe_area.gd")
var checks := 0
var failures: Array[String] = []

func check(actual: Rect2, expected: Rect2, label: String) -> void:
 checks += 1
 if not actual.is_equal_approx(expected):
  failures.append(label+": "+str(actual)+" expected "+str(expected))

func _init() -> void:
 var full := Rect2(0,0,390,844)
 check(Safe.content_rect(full,Rect2(0,48,390,762),Transform2D.IDENTITY),Rect2(0,48,390,762),"portrait camera and navigation bar")
 var doubled := Transform2D(Vector2(2,0),Vector2(0,2),Vector2(80,120))
 check(Safe.content_rect(full,Rect2(80,216,780,1524),doubled),Rect2(0,48,390,762),"translated doubled-density physical screen")
 var already_inset := Transform2D(Vector2(2,0),Vector2(0,2),Vector2(80,216))
 check(Safe.content_rect(Rect2(0,0,390,762),Rect2(80,216,780,1524),already_inset),Rect2(0,0,390,762),"OS-inset window does not receive the notch twice")
 check(Safe.content_rect(Rect2(0,0,1280,720),Rect2(44,0,1212,696),Transform2D.IDENTITY),Rect2(44,0,1212,696),"landscape side cutout and bottom navigation")
 var rotated := Transform2D(Vector2(0,1),Vector2(-1,0),Vector2(900,10))
 check(Safe.content_rect(full,Rect2(84,18,792,370),rotated),Rect2(8,24,370,792),"rotated physical display mapping")
 check(Safe.content_rect(full,Rect2(0.5,48.2,389,760.3),Transform2D.IDENTITY),Rect2(1,49,388,759),"fractional edges round toward safe content")
 check(Safe.content_rect(full,Rect2(-100,-100,2000,2000),Transform2D.IDENTITY),full,"display safe area larger than window is clipped")
 check(Safe.content_rect(full,Rect2(),Transform2D.IDENTITY),full,"missing OS safe sample keeps usable viewport")
 check(Safe.content_rect(full,Rect2(800,0,390,844),Transform2D.IDENTITY),full,"disjoint display sample cannot collapse interface")
 check(Safe.content_rect(full,Rect2(0,40,390,770),Transform2D(Vector2.ZERO,Vector2.ZERO,Vector2.ZERO)),full,"singular transform fallback")
 check(Safe.content_rect(full,Rect2(0,40,-3,770),Transform2D.IDENTITY),full,"invalid negative safe size fallback")
 check(Safe.content_rect(Rect2(10,20,390,844),Rect2(22,58,352,770),Transform2D.IDENTITY),Rect2(22,58,352,770),"nonzero viewport origin is retained")
 print("S51_MOBILE_MATH_RESULT ",JSON.stringify({"checks":checks,"failures":failures,"pass":failures.is_empty()}))
 quit(0 if failures.is_empty() else 1)
