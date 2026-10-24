extends RefCounted
const Chemistry = preload("res://Scripts/band_chemistry.gd")
# Platform-neutral, deterministic action resolver. UI and future LLM only describe outcomes.
const ACTIONS := {
    "rehearse": {"label": "BOOK REHEARSAL", "cost": 15, "days": 1, "readiness": 9, "morale": -1, "tension": 2},
    "songwrite": {"label": "WRITE A SONG", "cost": 0, "days": 1, "songs": 1, "readiness": 2, "morale": 3},
    "buy_gear": {"label": "BUY USED GEAR", "cost": 75, "days": 1, "gear": 1, "readiness": 4, "morale": 2},
    "promo": {"label": "PRINT POSTERS & PROMOTE", "cost": 25, "days": 1, "buzz": 10, "fans": 8},
    "press": {"label": "PITCH A LOCAL MAGAZINE", "cost": 10, "days": 1, "press": 9, "buzz": 3},
    "rest": {"label": "TAKE A DAY OFF", "cost": 0, "days": 1, "morale": 8, "tension": -8}
}
const KEYS := ["readiness", "morale", "tension", "songs", "gear", "buzz", "press", "fans"]

static func labels() -> Dictionary:
    return ACTIONS

static func resolve(state: Dictionary, action_id: String) -> Dictionary:
    if not ACTIONS.has(action_id):
        return {"ok": false, "message": "Unknown action"}
    if action_id == "rehearse" and state.has("members"):
        var available := 0
        for person in state.get("members",[]):
            if person is Dictionary and str(person.get("life_status","active")) == "active":
                available += 1
        if available < 2:
            return {"ok":false,"message":"A rehearsal needs two available band members. Recruit or wait for someone to return."}
    var rule: Dictionary = ACTIONS[action_id]
    var cost := int(rule.get("cost", 0))
    var cash := int(state.get("cash", 0))
    if cash < cost:
        return {"ok": false, "message": "Not enough cash for %s (£%d)." % [rule["label"], cost]}
    var next := state.duplicate(true)
    next["cash"] = cash - cost
    next["tour_day"] = maxi(1, int(next.get("tour_day", 1)) + int(rule.get("days", 1)))
    for key in KEYS:
        var upper := 100 if key in ["readiness", "morale", "tension", "buzz", "press"] else 100000
        next[key] = clampi(int(next.get(key, 0)) + int(rule.get(key, 0)), 0, upper)
    next["action_count"] = maxi(0, int(next.get("action_count", 0))) + 1
    var counters: Dictionary = next.get("action_counters", {}).duplicate(true)
    counters[action_id] = int(counters.get(action_id, 0)) + 1
    next["action_counters"] = counters
    next = Chemistry.work(next,action_id)
    var opportunity := _opportunity(next)
    var base_message := _flavour(action_id, int(counters[action_id]), str(next.get("band_name", "The band")))
    if not opportunity.is_empty():
        base_message += "\n\n" + opportunity
    return {"ok": true, "state": next, "message": base_message}

static func _opportunity(state: Dictionary) -> String:
    var seen: Dictionary = state.get("opportunities_seen", {}).duplicate(true)
    var trigger := ""
    var message := ""
    if int(state.get("press", 0)) >= 18 and int(state.get("buzz", 0)) >= 12 and not seen.has("first_feature"):
        trigger = "first_feature"
        message = "A regional music magazine offers a short profile. You're no longer entirely unknown."
    elif int(state.get("songs", 0)) >= 3 and not seen.has("demo_ready"):
        trigger = "demo_ready"
        message = "You have enough songs to start thinking about a rough demo recording."
    elif int(state.get("buzz", 0)) >= 30 and not seen.has("support_offer"):
        trigger = "support_offer"
        message = "A promoter gets in touch about a support slot at a nearby independent venue."
    elif int(state.get("tension", 0)) >= 65 and not seen.has("band_meeting"):
        trigger = "band_meeting"
        message = "The band wants a proper conversation before things boil over."
    if not trigger.is_empty():
        seen[trigger] = true
        state["opportunities_seen"] = seen
    return message

static func _flavour(action_id: String, times: int, band_name: String) -> String:
    var variants := {
        "rehearse": ["The lock-up smells of damp carpet and warm amplifiers. The set gets tighter.", "Another afternoon in the rehearsal unit. The rough edges are starting to sound deliberate."],
        "songwrite": ["Someone brings in a promising chorus on a phone recording. %s works out the rest." % band_name, "The kettle goes cold while the band argues over a middle eight. Eventually a song emerges."],
        "buy_gear": ["A second-hand listing turns into an unplanned trip across town. The kit actually works.", "An old amplifier and a questionable receipt. At least the sound is improving."],
        "promo": ["Posters go up around town, between takeaway menus and lost-cat notices.", "A few people respond to the band's flyers. Word is travelling, slowly."],
        "press": ["You send a carefully worded pitch to the local music desk.", "Another email to the regional press. This time someone might read it."],
        "rest": ["A day off prevents an argument nobody had the energy to win.", "Everyone takes a breather. The band might even enjoy one another's company tomorrow."]
    }
    var options: Array = variants.get(action_id, ["Another day in the music business."])
    return str(options[(times - 1) % options.size()])
