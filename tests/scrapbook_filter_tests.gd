extends SceneTree
const Scrapbook = preload("res://Scripts/scrapbook_filter.gd")
var failures := 0
func _initialize() -> void:
 var entries := [{"kind":"band","title":"Meet"},{"kind":"gig","title":"First gig"},{"kind":"milestone","title":"Chapter"},{"kind":"band","title":"Argument"}]
 _check(Scrapbook.select(entries).size() == 4,"all entries retained")
 _check(Scrapbook.select(entries,"BAND").size() == 2,"band events filtered")
 _check(Scrapbook.select(entries,"GIGS")[0]["title"] == "First gig","gig event filtered")
 _check(Scrapbook.select(entries,"MILESTONES")[0]["title"] == "Chapter","milestone filtered")
 _check(Scrapbook.select(entries,"ALL",2)[0]["title"] == "Argument","newest events first")
 _check(Scrapbook.select(entries,"OTHER").is_empty(),"invalid category safe")
 var filtered: Array = Scrapbook.select(entries)
 filtered[0]["title"] = "Changed"
 _check(entries[3]["title"] == "Argument","saved history is immutable")
 if failures == 0:
  print("SCRAPBOOK FILTER TESTS PASSED")
 quit(0 if failures == 0 else 1)
func _check(ok: bool, detail: String) -> void:
 if not ok:
  failures += 1
  push_error("SCRAPBOOK FAILURE: "+detail)
