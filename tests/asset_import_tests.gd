extends SceneTree
var failures := 0
func _initialize() -> void:
 var icons := ["ticket","calendar-days","map-pin","route","truck","bed-double","wrench","wallet","notebook-pen","users","message-circle","heart-handshake","guitar","mic","award","circle-alert","arrow-left","arrow-right","check","x","sliders-horizontal"]
 for name in icons:
  var path := "res://Art/UI/Icons/"+name+".svg"
  _check(FileAccess.file_exists(path),"missing Lucide icon "+name)
  _check(load(path)!=null,"unimportable Lucide icon "+name)
 for name in ["paper-note","corkboard","gig-ticket"]:
  var path := "res://Art/UI/Textures/"+name+".svg"
  _check(FileAccess.file_exists(path),"missing texture "+name)
  _check(load(path)!=null,"unimportable texture "+name)
 _check(FileAccess.file_exists("res://Art/UI/Icons/LUCIDE_LICENSE.txt"),"icon license included")
 if failures == 0: print("ART ASSETS IMPORT PASSED")
 quit(0 if failures == 0 else 1)
func _check(ok: bool,why: String) -> void:
 if not ok:
  failures += 1
  push_error("ART ASSET FAILURE: "+why)
