extends RefCounted
## Deterministic bandmate naming preferences; this is fictional taste, not AI text judgement.
const INTENTS := ["Raw","Dark","Playful","Dreamy"]
const SUGGESTIONS := {
 "Indie rock":[["The Last Bus","Raw"],["Satellite Hearts","Dreamy"],["Static Summer","Playful"]],
 "Punk":[["The No Shows","Raw"],["Broken Tickets","Dark"],["Off the Clock","Playful"]],
 "Post-punk":[["Concrete Flowers","Dark"],["Late Departures","Raw"],["The Sleepwalkers","Dreamy"]],
 "Britpop":[["The Local Heroes","Playful"],["Tuesday Night","Raw"],["Paper Kingdom","Dreamy"]],
 "Shoegaze":[["Halfway to Nowhere","Dreamy"],["Quiet Collapse","Dark"],["The Feedback","Raw"]],
 "Synth-pop":[["Electric Weather","Dreamy"],["Night Service","Dark"],["Plastic Kisses","Playful"]],
 "Garage rock":[["The Side Doors","Raw"],["Cheap Motels","Playful"],["Rust & Rain","Dark"]],
 "Goth":[["Black Glass","Dark"],["Velvet Hours","Dreamy"],["The Graveyard Shift","Playful"]],
 "Prog rock":[["The Long Equation","Dreamy"],["Clockwork Tide","Dark"],["Odd Measures","Playful"]],
 "Experimental":[["Soft Machines","Dreamy"],["Unfinished Business","Playful"],["Signal Loss","Dark"]],
 "Country / Americana":[["Westbound","Raw"],["The Blue Hour","Dreamy"],["Borrowed Boots","Playful"]],
 "Soul / Funk":[["After Midnight","Dark"],["Good Company","Playful"],["The Velvet Room","Dreamy"]],
 "Metal":[["Iron Season","Dark"],["The Unbroken","Raw"],["Night Shift","Playful"]],
 "Jazz / Fusion":[["The Other Four","Playful"],["Blue Transit","Dreamy"],["Second Take","Raw"]]
}
# Individual character interests written as fiction. No appearance-to-trait inference.
# Each [loved tone, disliked tone] pair is stable across sessions.
const TASTES := {
 "cast_jack":["Raw","Playful"],"cast_maya":["Dreamy","Raw"],
 "cast_ellis":["Raw","Playful"],"cast_zoe":["Dreamy","Playful"],
 "cast_dan":["Dreamy","Dark"],"cast_ryan":["Raw","Dreamy"],
 "cast_lily":["Dark","Playful"],"cast_marcus":["Raw","Playful"],
 "cast_ben":["Raw","Playful"],"cast_freya":["Dreamy","Raw"],
 "cast_arjun":["Dark","Playful"],"cast_nina":["Playful","Dark"],
 "cast_tom":["Raw","Playful"],"cast_casey":["Raw","Dreamy"],
 "cast_hannah":["Dark","Playful"],"cast_oscar":["Dark","Raw"],
 "cast_bex":["Dark","Dreamy"],"cast_sam":["Raw","Dreamy"],
 "alex":["Raw","Playful"],"nia_griffiths":["Dreamy","Dark"]
}
const LOVE_REASONS := {
 "Raw":"Sounds like us. No messing about.",
 "Dark":"That's got some bite. I like it.",
 "Playful":"Finally a name with a bit of nerve.",
 "Dreamy":"That has a lovely, strange atmosphere."
}
const DISLIKE_REASONS := {
 "Raw":"Feels too blunt for what I'm after.",
 "Dark":"A bit bleak for our music, isn't it?",
 "Playful":"Sounds like we're not taking this seriously.",
 "Dreamy":"Bit vague. What does it actually mean?"
}
static func suggestions(genre: String) -> Array:
 var set: Array = SUGGESTIONS.get(genre,SUGGESTIONS["Indie rock"])
 var result: Array = []
 for pair in set:
  result.append({"name":str(pair[0]),"intent":str(pair[1])})
 return result

static func reactions(roster: Array,intent: String,genre: String) -> Array:
 if not INTENTS.has(intent):
  return []
 var result: Array = []
 for person in roster:
  var id: String = str(person.get("id",""))
  var tastes: Array = TASTES.get(id,["Raw","Playful"])
  var mood := "accept"
  var because := "I can work with that. Let's see it on a poster."
  if intent == str(tastes[0]):
   mood = "love"
   because = str(LOVE_REASONS[intent])
  elif intent == str(tastes[1]):
   mood = "dislike"
   because = str(DISLIKE_REASONS[intent])
  elif genre in ["Punk","Garage rock"] and intent == "Raw":
   because = "Makes sense with the rougher sound."
  elif genre in ["Shoegaze","Synth-pop"] and intent == "Dreamy":
   because = "That fits the sound we're going for."
  result.append({"id":id,"name":str(person.get("name","Musician")),
    "reaction":mood,"reason":because})
 return result
