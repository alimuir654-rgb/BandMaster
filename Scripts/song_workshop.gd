extends RefCounted
const Chemistry = preload("res://Scripts/song_chemistry.gd")
# Lightweight, deterministic creative workshop. No AI needed for game rules.
const IDEAS := ["Riff","Lyric","Groove"]
const FORMS := ["Verse / Chorus","Slow Build","Loose Jam"]
const TITLES := ["AFTER THE LAST BUS","NEON AT CLOSING TIME","RAIN ON THE PLATFORM","THE LAST TRAIN","SOMETHING TO PROVE","NO WAY HOME","FRIDAY AGAIN","OUTSIDE THE VENUE"]
static func options(state: Dictionary) -> Dictionary:
 var roster: Array = state.get("members",[])
 var leads: Array = []
 for i in range(roster.size()):
  if roster[i] is Dictionary and str(roster[i].get("life_status","active")) == "active":
   leads.append({"index":i,"name":str(roster[i].get("name","Musician")),"trait":str(roster[i].get("trait",""))})
 return {"ideas":IDEAS,"forms":FORMS,"titles":TITLES,"leads":leads}

static func develop(state: Dictionary, idea: String, form: String, title: String, leader_index: int) -> Dictionary:
 if not IDEAS.has(idea) or not FORMS.has(form):
  return {"ok":false,"message":"Choose a valid idea and arrangement."}
 var clean_title := title.strip_edges().to_upper()
 if clean_title.length() < 3 or clean_title.length() > 48 or clean_title.contains("\n"):
  return {"ok":false,"message":"Give the song a title between 3 and 48 characters."}
 for entry in state.get("song_catalogue",[]):
  if entry is Dictionary and str(entry.get("title","")).strip_edges().to_upper() == clean_title:
   return {"ok":false,"message":"You already have a song called "+clean_title+". Give this one its own name before using a day."}

 var roster: Array = state.get("members",[])
 if leader_index < 0 or leader_index >= roster.size() or not roster[leader_index] is Dictionary:
  return {"ok":false,"message":"Choose a musician to lead the jam."}
 var leader: Dictionary = roster[leader_index]
 if str(leader.get("life_status","active")) != "active":
  return {"ok":false,"message":"That musician is not available today."}
 var next := state.duplicate(true)
 var progress := clampi(int(next.get("song_draft_progress",0)),0,2)
 var draft: Dictionary = next.get("current_song_draft",{}).duplicate(true)
 if progress == 0 or draft.is_empty():
  draft = {"idea":idea,"form":form,"title":clean_title,"leader":str(leader.get("name","Musician")),"sessions":[]}
 else:
  draft["idea"] = idea
  draft["form"] = form
  draft["title"] = clean_title
  draft["leader"] = str(leader.get("name","Musician"))
 var sessions: Array = draft.get("sessions",[]).duplicate(true)
 sessions.append({"day":int(next.get("tour_day",1)),"idea":idea,"form":form,"leader":str(leader.get("name","Musician"))})
 draft["sessions"] = sessions
 next["current_song_draft"] = draft
 var response: Dictionary = {"ok":true,"state":next,"message":"%s brings a %s idea. The band tries a %s arrangement." % [str(leader.get("name","Musician")),idea.to_lower(),form.to_lower()]}
 return response

static func finish(state: Dictionary) -> Dictionary:
 var next := state.duplicate(true)
 var draft: Dictionary = next.get("current_song_draft",{})
 if draft.is_empty():
  return next
 var songs: Array = next.get("song_catalogue",[]).duplicate(true)
 if songs.is_empty():
  return next
 var last: Dictionary = songs[songs.size()-1]
 last["title"] = str(draft.get("title",last.get("title","UNTITLED")))
 last["lead_writer"] = str(draft.get("leader",""))
 last["origin"] = str(draft.get("idea",""))
 last["arrangement"] = str(draft.get("form",""))
 last["writing_sessions"] = draft.get("sessions",[]).duplicate(true)
 var bonus := 3 if str(draft.get("form","")) == "Verse / Chorus" else (2 if str(draft.get("form","")) == "Slow Build" else 1)
 var chemistry: Dictionary = Chemistry.calculate(next)
 last["chemistry_bonus"] = int(chemistry["bonus"])
 last["chemistry_score"] = int(chemistry["score"])
 last["quality"] = clampi(int(last.get("quality",40))+bonus+int(chemistry["bonus"]),1,100)
 next["song_catalogue"] = songs
 next["current_song_draft"] = {}
 return next
