extends RefCounted
# Practice-room choices are authoritative simulation rules, independent of AI.
const Actions = preload("res://Scripts/career_actions.gd")
const FOCUSES = {
    "tighten": {"label":"DRILL THE LIVE SET","action":"rehearse","description":"Tighten the performance. Disciplined musicians thrive, restless ones tire."},
    "create": {"label":"WRITE TOGETHER","action":"songwrite","description":"Work on an original. Creative bandmates thrive on new ideas."},
    "connect": {"label":"CLEAR THE AIR","action":"rest","description":"Resolve differences and strengthen trust before the next show."}
}

static func resolve(state: Dictionary, focus: String) -> Dictionary:
    if not FOCUSES.has(focus):
        return {"ok":false,"message":"Unknown rehearsal focus."}
    var rule: Dictionary = FOCUSES[focus]
    var draft_before := maxi(0,int(state.get("song_draft_progress",0)))
    var composing := focus == "create"
    var finishing := composing and draft_before >= 2
    # First two writing sessions advance one day and improve a work-in-progress;
    # the third completes the original through the existing song resolver.
    var simulated_action := "rest" if composing and not finishing else str(rule["action"])
    var result: Dictionary = Actions.resolve(state,simulated_action)
    if not bool(result.get("ok",false)):
        return result
    var updated: Dictionary = result["state"]
    if composing:
        updated["song_draft_progress"] = 0 if finishing else draft_before + 1
        var counters: Dictionary = updated.get("action_counters",{}).duplicate(true)
        if not finishing:
            counters["rest"] = maxi(0,int(counters.get("rest",0))-1)
            counters["song_draft"] = int(counters.get("song_draft",0))+1
            updated["action_counters"] = counters
            updated["morale"] = clampi(int(state.get("morale",50))+1,0,100)
            updated["tension"] = clampi(int(state.get("tension",0))+1,0,100)
            updated["readiness"] = clampi(int(state.get("readiness",0))+2,0,100)
    var members: Array = updated.get("members",[])
    var active_indices: Array = []
    for i in range(members.size()):
        if not members[i] is Dictionary:
            continue
        var person: Dictionary = members[i]
        if str(person.get("life_status","active")) != "active":
            continue
        active_indices.append(i)
        var trait_name: String = str(person.get("trait","")).to_lower()
        var mood: int = 0
        if focus == "tighten":
            if trait_name.contains("perfectionist") or trait_name.contains("control freak") or trait_name.contains("reliable"):
                mood = 3
            elif trait_name.contains("restless") or trait_name.contains("chaos") or trait_name.contains("unreliable"):
                mood = -3
        elif focus == "create":
            if trait_name.contains("creative") or trait_name.contains("genius") or trait_name.contains("chaos"):
                mood = 4
            elif trait_name.contains("perfectionist") or trait_name.contains("control freak"):
                mood = -1
        elif focus == "connect":
            mood = 3
            person["loyalty"] = clampi(int(person.get("loyalty",60))+3,0,100)
        person["morale"] = clampi(int(person.get("morale",55))+mood,0,100)
    if focus == "connect" and active_indices.size() >= 2:
        var relations: Dictionary = updated.get("relationships",{}).duplicate(true)
        for a in range(active_indices.size()):
            for b in range(a+1,active_indices.size()):
                var first_index: int = int(active_indices[a])
                var second_index: int = int(active_indices[b])
                var pair_key: String = "%d_%d" % [mini(first_index,second_index),maxi(first_index,second_index)]
                relations[pair_key] = clampi(int(relations.get(pair_key,50))+6,0,100)
        updated["relationships"] = relations
        updated["tension"] = clampi(int(updated.get("tension",0))-5,0,100)
    var narrative: String = "The live set sounds sharper, but not everyone enjoys another drill."
    if focus == "create":
        narrative = "A new original takes shape in the rehearsal room (%d/3 writing sessions)." % int(3 if finishing else draft_before+1)
    elif focus == "connect":
        narrative = "A proper conversation brings the band closer together."
    var journal: Array = updated.get("career_journal",[]).duplicate(true)
    journal.append({"id":"room:%s:%d" % [focus,int(updated.get("tour_day",1))],"day":int(updated.get("tour_day",1)),"title":str(rule["label"]),"text":narrative,"kind":"band"})
    while journal.size() > 80:
        journal.pop_front()
    updated["career_journal"] = journal
    result["state"] = updated
    result["message"] = narrative
    return result
