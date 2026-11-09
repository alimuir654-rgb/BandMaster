extends RefCounted
## Authored, read-only conversation framing. SceneCircuit owns every actual offer.
const Circuit=preload("res://experiments/playable_flightcase/scene_circuit.gd")

static func opening(state: Dictionary,venue: String) -> String:
 var proposal: Dictionary=Circuit.proposal(state,venue,"scene","standard")
 if not proposal.get("ok",false):return str(proposal.get("message","Let's check the band's record before talking terms."))
 var context: Dictionary=proposal.bill.context
 if int(context.local_played)>0:
  return "You've played here before. What are you looking to do this time?"
 if int(context.shows)>0:
  return "New room for you, then. Tell me what your band can bring to this night."
 return "Your first night with us? Tell me what your band can bring. We need a bill that works in this room."

static func reaction(state: Dictionary,venue: String,pitch: String) -> String:
 var proposal: Dictionary=Circuit.proposal(state,venue,pitch,"standard")
 if not proposal.get("ok",false):return str(proposal.get("message","Let's check the band's record first."))
 var context: Dictionary=proposal.bill.context
 if pitch=="fit":return "A short opening set. Leave the next band room to change over. What arrangement did you have in mind?"
 if pitch=="crowd":
  return "I haven't seen that following here yet. What arrangement are you asking for?" if int(context.fans)<20 else "Let's talk about the night you could bring in. What arrangement are you asking for?"
 if int(context.supported)>0:return "The other bands have mentioned you staying around. That matters here. What terms did you have in mind?"
 return "Keep getting to know the other bands. A shared bill needs everyone. What terms did you have in mind?"
