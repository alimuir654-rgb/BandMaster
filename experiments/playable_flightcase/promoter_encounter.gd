extends RefCounted
## Authored, read-only conversation framing. SceneCircuit owns every actual offer.
const Circuit=preload("res://experiments/playable_flightcase/scene_circuit.gd")
const Promoters=preload("res://experiments/playable_flightcase/promoter_profiles.gd")

static func opening(state: Dictionary,venue: String) -> String:
 var proposal: Dictionary=Circuit.proposal(state,venue,"scene","standard")
 if not proposal.get("ok",false):return str(proposal.get("message","Let's check the band's record before talking terms."))
 var context: Dictionary=proposal.bill.context
 if int(context.local_played)>0:
  return "You've played here before. What are you looking to do this time?"
 if int(context.shows)>0:
  return "New room for you, then. Tell me what your band can bring to this night."
 var id: String=str(Promoters.for_venue(venue).get("id",""))
 return str({
  "mo_farrow":"I'm Mo. We've got three bands to fit in and an engineer who'd like to get home. Tell me about the set you're bringing.",
  "jules_okafor":"Jules. Good to meet you. Small room, close crowd — people hear everything here. What sort of night are you after?",
  "ray_malik":"Ray. Put your bag down, have a look at the room. I book the night as much as the band. What have you got ready?"
 }.get(id,"Your first night with us? Tell me about the set you're bringing."))

static func reaction(state: Dictionary,venue: String,pitch: String) -> String:
 var proposal: Dictionary=Circuit.proposal(state,venue,pitch,"standard")
 if not proposal.get("ok",false):return str(proposal.get("message","Let's check the band's record first."))
 var context: Dictionary=proposal.bill.context
 if pitch=="fit":return "A short opening set. Leave the next band room to change over. What arrangement did you have in mind?"
 if pitch=="crowd":
  return "I haven't seen that following here yet. What arrangement are you asking for?" if int(context.fans)<20 else "Let's talk about the night you could bring in. What arrangement are you asking for?"
 if int(context.supported)>0:return "The other bands have mentioned you staying around. That matters here. What terms did you have in mind?"
 return "Keep getting to know the other bands. A shared bill needs everyone. What terms did you have in mind?"
