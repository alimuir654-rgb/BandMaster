extends RefCounted
# Deterministic, offline event engine. All outcomes are validated here, not by prose generation.
const ORDER := ["band_meeting", "demo_ready", "first_feature", "support_offer"]
const EVENTS := {
    "band_meeting": {
        "title": "A BAND MEETING",
        "intro": "Tension has been brewing in the rehearsal room. Someone calls a meeting before the next argument turns into a split.",
        "choices": [
            {"id": "talk", "label": "HEAR EVERYONE OUT", "cost": 0, "days": 1, "morale": 8, "tension": -22, "reputation": 0, "text": "Over tea in the kitchen, everyone gets a turn. It isn't perfect, but the band survives the conversation."},
            {"id": "push", "label": "PUSH THROUGH", "cost": 0, "days": 1, "morale": -10, "tension": 14, "reputation": 0, "text": "You insist on pressing ahead. Rehearsal continues, but the atmosphere gets noticeably colder."}
        ]},
    "demo_ready": {
        "title": "THE FIRST DEMO",
        "intro": "You've written enough songs to make a demo. A local studio has a free afternoon.",
        "choices": [
            {"id": "record", "label": "RECORD THE DEMO — £55", "cost": 55, "days": 1, "demos": 1, "buzz": 8, "reputation": 4, "text": "A scruffy but convincing recording emerges from a backstreet studio. You finally have something to send out."},
            {"id": "hold", "label": "WAIT UNTIL YOU CAN AFFORD IT", "cost": 0, "days": 0, "text": "You keep the songs ready and save the studio's number for another day."}
        ]},
    "first_feature": {
        "title": "A LOCAL MUSIC FEATURE",
        "intro": "A regional magazine offers a short interview. They want a story, not just a list of influences.",
        "choices": [
            {"id": "open", "label": "TELL THEM THE WHOLE STORY", "cost": 0, "days": 1, "buzz": 12, "fans": 15, "tension": 5, "text": "The feature is charmingly frank. People notice; a bandmate thinks you may have overshared."},
            {"id": "careful", "label": "KEEP IT PROFESSIONAL", "cost": 0, "days": 1, "buzz": 6, "fans": 7, "morale": 3, "text": "It's a modest, positive profile. The band agrees you came across well."}
        ]},
    "support_offer": {
        "title": "A SUPPORT SLOT",
        "intro": "An independent venue offers you an opening slot for a touring act. It means a late drive and an early soundcheck.",
        "choices": [
            {"id": "take", "label": "TAKE THE GIG", "cost": 20, "days": 2, "cash_gain": 65, "fans": 18, "reputation": 7, "van_health": -8, "morale": -3, "text": "A cramped stage, a borrowed bass amp and a decent crowd. You make a few converts and even come home with petrol money."},
            {"id": "decline", "label": "DECLINE POLITELY", "cost": 0, "days": 0, "morale": 2, "text": "The promoter understands. They'll keep you in mind if another slot comes up."}
        ]}
}

static func pending(state: Dictionary) -> Array:
    var seen: Dictionary = state.get("opportunities_seen", {})
    var completed: Dictionary = state.get("opportunities_resolved", {})
    var available: Array = []
    for key in ORDER:
        if seen.has(key) and not completed.has(key):
            available.append(key)
    return available

static func get_event(event_id: String) -> Dictionary:
    return EVENTS.get(event_id, {})

static func resolve(state: Dictionary, event_id: String, choice_id: String) -> Dictionary:
    var event: Dictionary = EVENTS.get(event_id, {})
    if event.is_empty() or not pending(state).has(event_id):
        return {"ok": false, "message": "This opportunity is not available."}
    for choice in event.get("choices", []):
        if str(choice.get("id", "")) != choice_id:
            continue
        var cost := int(choice.get("cost", 0))
        if int(state.get("cash", 0)) < cost:
            return {"ok": false, "message": "You need £%d for this choice." % cost}
        var next := state.duplicate(true)
        next["cash"] = maxi(0, int(next.get("cash", 0)) - cost + int(choice.get("cash_gain", 0)))
        next["tour_day"] = maxi(1, int(next.get("tour_day", 1)) + int(choice.get("days", 0)))
        for key in ["morale", "tension", "reputation", "readiness", "van_health", "buzz", "press", "fans", "demos"]:
            var cap := 100 if key in ["morale", "tension", "reputation", "readiness", "van_health", "buzz", "press"] else 100000
            next[key] = clampi(int(next.get(key, 0)) + int(choice.get(key, 0)), 0, cap)
        var resolved: Dictionary = next.get("opportunities_resolved", {}).duplicate(true)
        resolved[event_id] = choice_id
        next["opportunities_resolved"] = resolved
        return {"ok": true, "state": next, "message": str(choice.get("text", ""))}
    return {"ok": false, "message": "Invalid choice."}
