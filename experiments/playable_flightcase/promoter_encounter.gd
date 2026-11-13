extends RefCounted
## Authored, read-only conversation framing. SceneCircuit owns every actual offer.
const Circuit=preload("res://experiments/playable_flightcase/scene_circuit.gd")
const Promoters=preload("res://experiments/playable_flightcase/promoter_profiles.gd")
const PITCH_WORDS={"fit":"We can open with a short set.","crowd":"We'd like to bring people to this night.","scene":"We want to be part of a shared bill."}
const ASKS={"standard":"Let's work with your usual terms.","guarantee":"Can you guarantee a little more?","guestlist":"Could we put some people on the guest list?"}

static func beat(venue: String) -> String:
 return str({"mo_farrow":"Mo slides the running order across the bar.","jules_okafor":"Jules moves a chair away from the sound desk so you can talk.","ray_malik":"Ray puts the bookings notebook down and gives you his attention."}.get(Promoters.for_venue(venue).get("id",""),"The promoter makes a moment to talk."))

static func concern(venue: String) -> String:
 return str({"mo_farrow":"I need the first band ready when the doors open. Can I count on you for that?","jules_okafor":"I want people to stay for the whole bill. What will make your band belong on this night?","ray_malik":"Tell me what you've actually got ready. We can talk about a bigger slot when there's a set to fill it."}.get(Promoters.for_venue(venue).get("id",""),"What sort of night can we put together?"))

static func aside(venue: String) -> String:
 return str({"mo_farrow":"If an amp dies, don't stand there hoping. Come and find me. And when you're done, shift your gear before you start looking for your mates.","jules_okafor":"Stay for the other bands. If their set matters to you, yours is more likely to matter to them. That's how a small night gets going.","ray_malik":"Finish when you said you'd finish. A good short set gets remembered. So does a band that uses the next band's time."}.get(Promoters.for_venue(venue).get("id",""),"Listen to the other bands and leave the room ready for them."))

static func opening(state: Dictionary,venue: String) -> String:
 var proposal: Dictionary=Circuit.proposal(state,venue,"scene","standard")
 if not proposal.get("ok",false):return str(proposal.get("message","Let's check the band's record before talking terms."))
 var context: Dictionary=proposal.bill.context
 var id: String=str(Promoters.for_venue(venue).get("id",""))
 if int(context.local_played)>0:
  return str({"mo_farrow":"Back for another one? You know the room now. Tell me what you're changing in the set.","jules_okafor":"Good to see you back. Same room, different bill. What are you bringing this time?","ray_malik":"I've seen you play here now. Where do you want to take the next set?"}.get(id,"You've played here before. What are you bringing this time?"))
 if int(context.shows)>0:
  return "You've got shows behind you, then. New room, though. "+concern(venue)
 return str({
  "mo_farrow":"I'm Mo. You've found the place, which is a start. "+concern(venue),
  "jules_okafor":"Jules. Glad you came down rather than just sending another message. "+concern(venue),
  "ray_malik":"Ray. Put your bag down. "+concern(venue)
 }.get(id,"Your first night with us? Tell me about the set you're bringing."))

static func reaction(state: Dictionary,venue: String,pitch: String) -> String:
 var proposal: Dictionary=Circuit.proposal(state,venue,pitch,"standard")
 if not proposal.get("ok",false):return str(proposal.get("message","Let's check the band's record first."))
 var context: Dictionary=proposal.bill.context
 var id: String=str(Promoters.for_venue(venue).get("id",""))
 if pitch=="fit":return str({"mo_farrow":"Good. Get the first song going, give people a reason to come in from the bar, then clear the stage. Shall we talk terms?","jules_okafor":"That could work. A short set that leaves people curious, then stay and hear the others. What terms were you thinking?","ray_malik":"Short is fine. Make it a set you can finish cleanly, not a longer one you have to cut off. What arrangement do you need?"}.get(id,"A short opening set. What terms were you thinking?"))
 if pitch=="crowd":
  return "I haven't seen that following here yet. What arrangement are you asking for?" if int(context.fans)<20 else "Let's talk about the night you could bring in. What arrangement are you asking for?"
 if int(context.supported)>0:return "The other bands have mentioned you staying around. That matters here. What terms did you have in mind?"
 return "Keep getting to know the other bands. A shared bill needs everyone. What terms did you have in mind?"

static func agreement(venue: String,proposal: Dictionary) -> String:
 var counter: bool=bool(proposal.get("counteroffer",false))
 var id: String=str(Promoters.for_venue(venue).get("id",""))
 var lead: String=str({"mo_farrow":"I can't put extra cash on this one. I can give you a place on the night.","jules_okafor":"I can't promise money that isn't there. Here's the arrangement I can offer.","ray_malik":"Not that guarantee, not yet. This is the offer I've actually got."}.get(id,"Here's what I can offer.")) if counter else str({"mo_farrow":"Right. Let's put a date against it.","jules_okafor":"Alright. Let's make it a night we can all turn up for.","ray_malik":"That works. Let's get the details right."}.get(id,"Let's put the night together."))
 return lead+"\n\n"+str(proposal.get("reply",""))
