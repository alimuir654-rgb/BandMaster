extends RefCounted
# Deterministic recording/release pipeline. Additive save keys, no external services.
const DEMO_COST := 60
const RELEASE_COST := 25
const RECORD_DAYS := 2

static func catalogue(state: Dictionary) -> Array:
 var raw = state.get("song_catalogue",[])
 return raw if raw is Array else []

static func can_record(state: Dictionary) -> Dictionary:
 var songs: Array = catalogue(state)
 if songs.size() < 2:
  return {"ok":false,"message":"Finish at least two originals before recording a demo."}
 if int(state.get("cash",0)) < DEMO_COST:
  return {"ok":false,"message":"Recording requires £%d." % DEMO_COST}
 var recordings = state.get("recordings",[])
 if recordings is Array and not recordings.is_empty() and int(recordings.back().get("source_count",0)) >= songs.size():
  return {"ok":false,"message":"Write another original before booking a new demo."}
 return {"ok":true}

static func record(state: Dictionary) -> Dictionary:
 var valid: Dictionary = can_record(state)
 if not bool(valid.get("ok",false)):
  return valid
 var next := state.duplicate(true)
 var songs: Array = catalogue(next)
 var take: Array = []
 var total := 0
 for i in range(maxi(0,songs.size()-3),songs.size()):
  if not songs[i] is Dictionary:
   continue
  var song: Dictionary = songs[i]
  var quality := clampi(int(song.get("quality",40)),0,100)
  total += quality
  take.append({"title":str(song.get("title","UNTITLED")),"quality":quality})
 if take.is_empty():
  return {"ok":false,"message":"No recorded originals are available."}
 var quality := int(round(float(total)/float(take.size())))
 var session := {"id":"demo:%d:%d" % [int(next.get("tour_day",1)),songs.size()],"day":int(next.get("tour_day",1))+RECORD_DAYS,"tracks":take,"quality":quality,"source_count":songs.size(),"released":false}
 var recordings: Array = next.get("recordings",[]).duplicate(true)
 recordings.append(session)
 next["recordings"] = recordings
 next["cash"] = int(next.get("cash",0))-DEMO_COST
 next["tour_day"] = int(next.get("tour_day",1))+RECORD_DAYS
 next["demos"] = maxi(int(next.get("demos",0)),recordings.size())
 next["readiness"] = clampi(int(next.get("readiness",50))+3,0,100)
 _journal(next,"IN THE RECORDING STUDIO","The band lays down %d tracks. The rough demo is ready to share." % take.size(),"song")
 return {"ok":true,"state":next,"message":"Recorded %d tracks in two days. Quality %d/100. £%d spent." % [take.size(),quality,DEMO_COST]}

static func release(state: Dictionary, index: int) -> Dictionary:
 var recordings = state.get("recordings",[])
 if not recordings is Array or index < 0 or index >= recordings.size():
  return {"ok":false,"message":"Select a recorded demo."}
 if not recordings[index] is Dictionary or bool(recordings[index].get("released",false)):
  return {"ok":false,"message":"That demo is already released."}
 if int(state.get("cash",0)) < RELEASE_COST:
  return {"ok":false,"message":"A local release needs £%d for artwork and distribution." % RELEASE_COST}
 var next := state.duplicate(true)
 var sessions: Array = next["recordings"]
 var demo: Dictionary = sessions[index]
 var quality := clampi(int(demo.get("quality",40)),0,100)
 var buzz := clampi(int(next.get("buzz",0)),0,100)
 var fans_gained := maxi(2,int(round(float(quality)/8.0))+int(float(buzz)/12.0))
 var press_gained := maxi(1,int(float(quality)/25.0))
 demo["released"] = true
 demo["release_day"] = int(next.get("tour_day",1))+1
 demo["fans_gained"] = fans_gained
 next["cash"] = int(next.get("cash",0))-RELEASE_COST
 next["tour_day"] = int(next.get("tour_day",1))+1
 next["fans"] = maxi(0,int(next.get("fans",0))+fans_gained)
 next["press"] = clampi(int(next.get("press",0))+press_gained,0,100)
 next["buzz"] = clampi(buzz+4,0,100)
 _journal(next,"THE FIRST RECORDINGS ARE OUT","The demo reaches local listeners. +%d fans and +%d press." % [fans_gained,press_gained],"press")
 return {"ok":true,"state":next,"message":"Demo released! +%d fans, +%d press. £%d spent." % [fans_gained,press_gained,RELEASE_COST]}

static func _journal(state: Dictionary, title: String, message: String, kind: String) -> void:
 var entries: Array = state.get("career_journal",[]).duplicate(true)
 entries.append({"id":"release:%d:%d" % [int(state.get("tour_day",1)),entries.size()],"day":int(state.get("tour_day",1)),"title":title,"text":message,"kind":kind})
 while entries.size()>80:
  entries.pop_front()
 state["career_journal"] = entries
