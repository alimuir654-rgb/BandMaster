extends SceneTree
const Catalogue = preload("res://Scripts/formation_catalogue.gd")
var failures := 0
func _initialize() -> void:
 _check(Catalogue.GENRES.size() >= 12,"expanded genres")
 _check(Catalogue.INFLUENCES.size() >= 25,"expanded influences")
 _check(Catalogue.CANDIDATES.size() >= 10,"candidate pool")
 var recruits: Array = []
 for id in ["alex","jo","sam"]:
  for candidate in Catalogue.CANDIDATES:
   if candidate["id"] == id:
    _check(Catalogue.can_recruit(recruits,candidate),"candidate can join")
    recruits.append(Catalogue.to_member(candidate,recruits.size()))
 _check(Catalogue.viable(recruits),"band with rhythm section is viable")
 _check(Catalogue.split_per_member(3) == 33,"three-way split")
 _check(Catalogue.affinity(Catalogue.CANDIDATES[1],"Indie rock") > 0,"genre affinity")
 _check(not Catalogue.can_recruit(recruits,Catalogue.CANDIDATES[0]),"duplicate candidate rejected")
 var no_drums: Array = [Catalogue.to_member(Catalogue.CANDIDATES[0],0),Catalogue.to_member(Catalogue.CANDIDATES[2],1)]
 _check(not Catalogue.viable(no_drums),"rhythm requirement")
 var saved := {"name":"My Band","genre":"Punk","influence":"The Clash","members":recruits,"palette":Catalogue.PALETTES[0],"logo_style":"STAMP"}
 var roundtrip = JSON.parse_string(JSON.stringify(saved))
 _check(roundtrip is Dictionary and roundtrip["members"].size()==3,"formation saves as JSON")
 if failures == 0:
  print("V24 FORMATION CATALOGUE TESTS PASSED")
 quit(0 if failures == 0 else 1)
func _check(ok: bool, detail: String) -> void:
 if not ok:
  failures += 1
  push_error("V24 FORMATION FAILURE: "+detail)
