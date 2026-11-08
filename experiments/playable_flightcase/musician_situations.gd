extends RefCounted
## Authored voices grounded in the approved cast; no new performances implied.
const OPENINGS := {
 "cast_arjun":{
  "direction":"I've got a different voicing in mind. I don't want to cover the song in ideas before we've found the part that matters.",
  "time":"I can bring an idea from the rehearsal room. Let's find an evening around work before we promise the whole band.",
  "pressure":"If I keep adding parts, tell me when the song has enough. I want a band that can hear an idea and still say no."
 },
 "cast_hannah":{
  "direction":"I've been waiting for someone else to start this conversation. I think the bass could leave more space for the song.",
  "time":"A regular evening helps. Check who's free, then let's make the time useful instead of rushing another session.",
  "pressure":"I can hold the groove, but I don't want us filling every gap because we're nervous. How are we playing the next one?"
 },
 "cast_ellis":{
  "direction":"Give me the count-in and the changes. I'd rather play a simple groove together than guess where a difficult fill is going.",
  "time":"This is my first proper band. I want to turn up prepared, so tell me which evening and what we're working on.",
  "pressure":"If we keep changing the ending, I need another pass at it. Can we settle what we're actually going to play?"
 }
}

static func opening(id: String,topic: String,fallback: String) -> String:
 return str(OPENINGS.get(id,{}).get(topic,fallback))

static func checkin(id: String,topic: String,kind: String,due: int,tired: bool) -> String:
 if topic=="time":return "We've left room through DAY %d. Check the current commitments below; if that no longer works, let's change the agreement properly." % due
 if tired:return "I'm still running low. The agreement matters, but let's look at how we actually feel when we get there."
 if kind=="write":return {"cast_arjun":"I'm thinking about the part that carries the idea, rather than adding another layer.","cast_hannah":"I've got a thought about where the bass should leave a gap. Ask me when we're in the room.","cast_ellis":"I'll bring a simple groove. Let me know where the changes land."}.get(id,"I'm keeping an idea for that evening. Let's hear each other when we're there.")
 if kind=="rest":return "A little space is useful. Let's decide the next step when we've had it."
 return opening(id,topic,"We have an evening to work towards. I'd rather follow that through than make another promise now.")

static func result(id: String,kind: String,status: String,focus: String) -> String:
 if status=="missed":return {"cast_arjun":"I kept an idea for us, but we never made the evening. Let's make the next plan one we can keep.","cast_hannah":"I'd put that evening aside. If plans change, tell me before we lose it.","cast_ellis":"I'd worked on the changes. I needed to know we weren't getting together."}.get(id,"The agreed window passed without that evening together.")
 if status=="strained":return {"cast_arjun":"Another hard pass gave me more ideas than we could settle. I needed us to listen.","cast_hannah":"We pushed on, but I was losing the feel. I needed a breather.","cast_ellis":"I kept trying the changes while I was worn out. The extra pass didn't settle them."}.get(id,"We did the evening, but the hard push was more than I had left.")
 if kind=="rest":return "That breathing room helped. Let's talk about what we can do next."
 if kind=="write":return {"cast_arjun":"You made room for an idea. Now we can decide which part actually belongs in the song.","cast_hannah":"You asked what I thought about the song. I'd like us to keep doing that.","cast_ellis":"The changes make more sense after playing the idea together."}.get(id,"We made time for the song, like we agreed.")
 if focus=="listening":return {"cast_arjun":"There was room to try an idea without burying everyone else's part.","cast_hannah":"I could hear the others across the groove. That felt like a band.","cast_ellis":"Listening across the room helped me find where the changes sit."}.get(id,"We made the evening and listened across the room.")
 return {"cast_arjun":"Keeping the part simple helped us settle the song.","cast_hannah":"The starts held together. That gives the groove somewhere to sit.","cast_ellis":"We agreed the count-in and worked on the changes. I know what to practise now."}.get(id,"You made time and followed the agreement.")
