extends RefCounted
# Follow-up promotion for recorded, released demos. Each campaign can run once per release.
const CAMPAIGNS := {
 "radio":{"label":"PITCH LOCAL RADIO","cost":20,"days":1,"min_press":0,"press":9,"buzz":6,"fans":5,"description":"Send the recording to regional radio and independent DJs."},
 "launch_show":{"label":"PLAY A RELEASE PARTY","cost":35,"days":1,"min_press":0,"press":2,"buzz":12,"fans":12,"description":"Host an intimate launch night for new and existing fans."},
 "regional":{"label":"REGIONAL PRESS PUSH","cost":50,"days":2,"min_press":12,"press":13,"buzz":9,"fans":10,"description":"A coordinated press campaign aimed beyond your hometown."}
}
const ORDER := ["radio","launch_show","regional"]

static func options(state: Dictionary, index: int) -> Array:
 var releases = state.get("recordings",[])
 if not releases is Array or index < 0 or index >= releases.size() or not releases[index] is Dictionary:
  return []
 var release: Dictionary = releases[index]
 if not bool(release.get("released",false)):
  return []
 var used: Dictionary = release.get("campaigns",{})
 var choices: Array = []
 for id in ORDER:
  var rule: Dictionary = CAMPAIGNS[id]
  var affordable := int(state.get("cash",0)) >= int(rule["cost"])
  var qualified := int(state.get("press",0)) >= int(rule["min_press"])
  choices.append({"id":id,"label":str(rule["label"]),"description":str(rule["description"]),"cost":int(rule["cost"]),"days":int(rule["days"]),"enabled":affordable and qualified and not used.has(id),"completed":used.has(id),"reason":"ALREADY RUN" if used.has(id) else ("NEED %d PRESS" % int(rule["min_press"]) if not qualified else ("NEED £%d" % int(rule["cost"]) if not affordable else ""))})
 return choices

static func launch(state: Dictionary, index: int, campaign_id: String) -> Dictionary:
 if not CAMPAIGNS.has(campaign_id):
  return {"ok":false,"message":"Unknown promotional campaign."}
 var candidates: Array = options(state,index)
 if candidates.is_empty():
  return {"ok":false,"message":"Release a recorded demo before promoting it."}
 var allowed := false
 for offer in candidates:
  if str(offer["id"]) == campaign_id:
   allowed = bool(offer["enabled"])
   break
 if not allowed:
  return {"ok":false,"message":"That campaign is unavailable or already complete."}
 var next := state.duplicate(true)
 var recordings: Array = next["recordings"]
 var demo: Dictionary = recordings[index]
 var rule: Dictionary = CAMPAIGNS[campaign_id]
 var quality := clampi(int(demo.get("quality",40)),0,100)
 var quality_bonus := int(float(quality)/20.0)
 var fans_gain := int(rule["fans"])+quality_bonus
 next["cash"] = int(next.get("cash",0))-int(rule["cost"])
 next["tour_day"] = int(next.get("tour_day",1))+int(rule["days"])
 next["press"] = clampi(int(next.get("press",0))+int(rule["press"]),0,100)
 next["buzz"] = clampi(int(next.get("buzz",0))+int(rule["buzz"]),0,100)
 next["fans"] = maxi(0,int(next.get("fans",0))+fans_gain)
 var campaigns: Dictionary = demo.get("campaigns",{}).duplicate(true)
 campaigns[campaign_id] = {"day":int(next["tour_day"]),"fans":fans_gain}
 demo["campaigns"] = campaigns
 var journal: Array = next.get("career_journal",[]).duplicate(true)
 journal.append({"id":"campaign:%s:%s" % [str(demo.get("id",index)),campaign_id],"day":int(next["tour_day"]),"title":str(rule["label"]),"text":"%s %d new listeners found the band." % [str(rule["description"]),fans_gain],"kind":"press"})
 while journal.size() > 80:
  journal.pop_front()
 next["career_journal"] = journal
 return {"ok":true,"state":next,"message":"%s complete. +%d fans, +%d press, +%d buzz." % [str(rule["label"]),fans_gain,int(rule["press"]),int(rule["buzz"])]}

static func next_milestone(state: Dictionary) -> Dictionary:
 var fans := int(state.get("fans",0))
 var rep := int(state.get("reputation",0))
 for milestone in [{"fans":25,"rep":10,"name":"LOCAL FOLLOWING"},{"fans":75,"rep":30,"name":"REGIONAL INTEREST"},{"fans":150,"rep":55,"name":"BREAKING OUT"}]:
  if fans < int(milestone["fans"]) or rep < int(milestone["rep"]):
   return {"name":milestone["name"],"fans":fans,"target_fans":milestone["fans"],"reputation":rep,"target_rep":milestone["rep"]}
 return {"name":"ESTABLISHED CIRCUIT","fans":fans,"target_fans":fans,"reputation":rep,"target_rep":rep}
