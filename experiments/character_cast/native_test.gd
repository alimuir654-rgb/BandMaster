extends SceneTree
const Cast = preload("res://experiments/character_cast/catalogue.gd")
const Base = preload("res://experiments/character_cast/vendor/recruitment_catalogue_v3.gd")
var checks := 0
var failures: Array[String] = []
func _init() -> void:
 call_deferred("run_tests")
func check(ok: bool, message: String) -> void:
 checks += 1
 if not ok:
  failures.append(message)
  push_error(message)
func run_tests() -> void:
 var original: Array = Base.people()
 var snapshot := JSON.stringify(original)
 var people: Array = Cast.people()
 check(people.size() == 18, "eighteen approved cast profiles")
 var ids: Array = []
 var risky := 0
 for p in people:
  var id := str(p["id"])
  check(id.begins_with("cast_") and not ids.has(id), "unique additive id " + id)
  ids.append(id)
  var role := str(p["primary_role"])
  var stats: Array = Cast.stats_for(p, role)
  check(stats.size() == 6, "six musical stats " + id)
  var total := 0
  for value in stats:
   check(float(value) == float(int(value)) and int(value) >= 1 and int(value) <= 10, "bounded stat " + id)
   total += int(value)
  check(Base.cost(p) == total and total == int(p["talent_cost"]), "canonical pricing " + id)
  check(Cast.labels_for(role).size() == 6, "canonical labels " + id)
  check(int(p["reliability"]) >= 1 and int(p["reliability"]) <= 10, "reliability range")
  check(int(p["collaboration"]) >= 1 and int(p["collaboration"]) <= 10, "collaboration range")
  var image := Image.load_from_file(str(p["portrait_preview"]))
  check(image != null and image.get_width() <= 240 and image.get_height() <= 228, "true small preview " + id)
  if p["wildcard"]:
   risky += 1
   check(Base.cost(p) >= 55 and int(p["collaboration"]) <= 3, "explicit costly wildcard")
 var genre := str(Base.genres()[0])
 var counts := [4,5,3,3,3]
 for i in range(Base.ROLE_TABS.size()):
  var candidates: Array = Cast.pool(genre, str(Base.ROLE_TABS[i]))
  check(candidates.size() == counts[i], "role distribution")
  var low := 100
  var high := 0
  for p in candidates:
   low = mini(low, Base.cost(p))
   high = maxi(high, Base.cost(p))
  check(high-low >= 12, "meaningful range within role")
 check(risky == 2, "two high-friction options")
 check(Cast.pool("not a genre", "Singer").is_empty(), "invalid genre rejected")
 check(Cast.pool(genre, "Conductor").is_empty(), "invalid role rejected")
 check(Cast.by_id("sam").is_empty(), "cast Sam does not alias canonical Sam")
 check(Cast.combined_people().size() == original.size()+18, "canonical people retained")
 check(JSON.stringify(Base.people()) == snapshot, "canonical source data unchanged")
 for wanted in ["alex", "nia_griffiths", "sam"]:
  check(Base.contains(Cast.combined_people(), wanted), "canonical identity preserved " + wanted)
 var mutable := Cast.by_id("cast_bex")
 mutable["instrument"][0] = 1
 check(int(Cast.by_id("cast_bex")["instrument"][0]) == 10, "fresh deep copies")
 var roster: Array = []
 for id in ["cast_maya", "cast_jack", "cast_zoe", "cast_dan", "cast_casey"]:
  var p := Cast.by_id(id)
  check(Base.can_add(roster, p), "affordable actual-model recruitment " + id)
  roster.append(p)
 check(Base.spent(roster) == 178, "balanced lineup costs178 incl overhead")
 check(Base.viable(roster), "actual-model viable lineup")
 check(not Base.can_add(roster, Cast.by_id("cast_jack")), "duplicates refused")
 var removed: Variant = roster.pop_back()
 check(Base.spent(roster) == 135, "remove refunds member and fifth overhead")
 check(Base.can_add(roster, removed), "removed member can return")
 roster.append(removed)
 check(Base.spent(roster) == 178, "re-add exact restoration")
 var expensive: Array = []
 for id in ["cast_sam", "cast_bex", "cast_ben", "cast_dan"]:
  expensive.append(Cast.by_id(id))
 check(not Base.can_add(expensive, Cast.by_id("cast_ellis")), "two stars five-role lineup exceeds200")
 check(Base.MAX_TALENT == 200, "budget preserved")
 var record := {"engine":Engine.get_version_info()["string"],"checks":checks,"failures":failures,"source_profiles":people.size(),"production_saves_touched":false,"personality_penalties_integrated":false}
 var file := FileAccess.open("res://cast-results.json", FileAccess.WRITE)
 file.store_string(JSON.stringify(record,"  "))
 file.close()
 print("C25_CAST_RESULT ",checks," checks / ",failures.size()," failures")
 quit(0 if failures.is_empty() else 1)
