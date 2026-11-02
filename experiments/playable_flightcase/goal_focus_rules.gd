extends RefCounted
## A free player preference. Never claims chapters or changes gameplay values.
const Chapters = preload("res://Scripts/career_chapters.gd")
const KEY := "career_focus_v1"
const MAXIMUM := 2147483647

static func _whole(value: Variant, minimum: int=0) -> bool:
 return (value is int or value is float) and is_finite(float(value)) and float(value)==floor(float(value)) and float(value)>=float(minimum) and float(value)<=float(MAXIMUM)

static func definition(id: String) -> Dictionary:
 for chapter in Chapters.CHAPTERS:
  if chapter["id"]==id:return chapter.duplicate(true)
 return {}

static func validate(state: Dictionary) -> Dictionary:
 for field in ["songs","fans","readiness"]:
  if state.has(field) and not _whole(state[field]):return {"ok":false,"message":"The saved goal progress needs validation.","chapter_id":"","pinned":false}
 if state.has("tour_day") and not _whole(state["tour_day"],1):return {"ok":false,"message":"The saved career day needs validation.","chapter_id":"","pinned":false}
 if state.has("career_chapters_claimed") and not state["career_chapters_claimed"] is Dictionary:return {"ok":false,"message":"The saved chapter history needs validation.","chapter_id":"","pinned":false}
 if state.has("gig_history") and not state["gig_history"] is Array:return {"ok":false,"message":"The saved show history needs validation.","chapter_id":"","pinned":false}
 if state.has("action_counters"):
  if not state["action_counters"] is Dictionary:return {"ok":false,"message":"The saved preparation history needs validation.","chapter_id":"","pinned":false}
  if state["action_counters"].has("rehearse") and not _whole(state["action_counters"]["rehearse"]):return {"ok":false,"message":"The saved rehearsal count needs validation.","chapter_id":"","pinned":false}
 if not state.has(KEY):return {"ok":true,"message":"","chapter_id":"","pinned":false}
 var wrapper: Variant=state[KEY]
 if not wrapper is Dictionary or not _whole(wrapper.get("version",0),1) or int(wrapper["version"])!=1 or not wrapper.get("chapter_id") is String:return {"ok":false,"message":"The saved focus is unsupported and has been kept unchanged.","chapter_id":"","pinned":false}
 var id: String=wrapper["chapter_id"]
 if not id.is_empty() and definition(id).is_empty():return {"ok":false,"message":"The saved focus names an unsupported goal and has been kept unchanged.","chapter_id":"","pinned":false}
 return {"ok":true,"message":"","chapter_id":id,"pinned":not id.is_empty()}

static func _recorded(state: Dictionary, metric: String) -> bool:
 if metric=="rehearse":return state.has("action_counters")
 if metric=="gigs":return state.has("gig_history")
 if metric=="day":return state.has("tour_day")
 return state.has(metric)

static func view(state: Dictionary, id: String) -> Dictionary:
 var valid: Dictionary=validate(state)
 if not bool(valid["ok"]):return {"ok":false,"message":valid["message"],"id":id,"requirements":[],"ready":false,"claimed":false}
 var chapter: Dictionary=definition(id)
 if chapter.is_empty():return {"ok":false,"message":"Choose one of the existing band goals.","id":id,"requirements":[],"ready":false,"claimed":false}
 var requirements: Array=[]
 var ready: bool=true
 for key in chapter["requirements"]:
  var recorded: bool=_recorded(state,str(key))
  var target: int=int(chapter["requirements"][key])
  var current: int=Chapters._metric(state,str(key)) if recorded else 0
  requirements.append({"key":str(key),"current":mini(current,target),"target":target,"recorded":recorded})
  if not recorded or current<target:ready=false
 var claimed: bool=(state.get("career_chapters_claimed",{}) as Dictionary).has(id)
 return {"ok":true,"message":"","id":id,"title":chapter["title"],"description":chapter["description"],"requirements":requirements,"ready":ready,"claimed":claimed}

static func options(state: Dictionary) -> Dictionary:
 var valid: Dictionary=validate(state)
 var result: Dictionary={"ok":bool(valid["ok"]),"message":str(valid["message"]),"chapter_id":str(valid["chapter_id"]),"pinned":bool(valid["pinned"]),"options":[]}
 if bool(valid["ok"]):
  for chapter in Chapters.CHAPTERS:result["options"].append(view(state,str(chapter["id"])))
 return result

static func _result(state: Dictionary, ok: bool, message: String, changed: bool=false) -> Dictionary:
 var selected: Dictionary=validate(state)
 return {"ok":ok,"state":state.duplicate(true),"message":message,"changed":changed,"chapter_id":str(selected.get("chapter_id",""))}

static func choose(state: Dictionary, chapter_id: String) -> Dictionary:
 var valid: Dictionary=validate(state)
 if not bool(valid["ok"]):return _result(state,false,str(valid["message"]))
 if definition(chapter_id).is_empty():return _result(state,false,"Choose one of the existing band goals.")
 if str(valid["chapter_id"])==chapter_id:return _result(state,true,"This is already your focus.")
 if (state.get("career_chapters_claimed",{}) as Dictionary).has(chapter_id):return _result(state,false,"That chapter is already completed. Choose another focus.")
 var next: Dictionary=state.duplicate(true)
 var wrapper: Dictionary=next.get(KEY,{"version":1,"chapter_id":""}).duplicate(true)
 wrapper["chapter_id"]=chapter_id
 next[KEY]=wrapper
 return _result(next,true,"Your band focus is saved. No money or day was spent.",true)

static func change(state: Dictionary, chapter_id: String) -> Dictionary:
 return choose(state,chapter_id)

static func clear(state: Dictionary) -> Dictionary:
 var valid: Dictionary=validate(state)
 if not bool(valid["ok"]):return _result(state,false,str(valid["message"]))
 if not bool(valid["pinned"]):return _result(state,true,"The suggested goal is already active.")
 var next: Dictionary=state.duplicate(true)
 next[KEY]["chapter_id"]=""
 return _result(next,true,"The suggested goal is active again. No money or day was spent.",true)
