extends RefCounted
## A display name/voice for the existing student_presenter_v1, same saved IDs.
const SPEAKER="FRANKIE · STUDENT RADIO"

static func line(data: Dictionary,title: String) -> String:
 var visit: Dictionary=data.get("visit",{})
 var phase: String=str(visit.get("phase",""))
 var answers: Dictionary=visit.get("answers",{})
 match phase:
  "arrival":return "Frankie clears a space beside the desk for your demo.\n\nCome in. Mind the cable by the chair. What have you brought us?"
  "introduction":return "I've got ‘"+title+"’ here. Imagine someone hearing your band for the first time, halfway through making their tea. Let's give them a reason to keep listening."
  "question1":return "Before we get lost in the track list: "+str(data.get("text",""))
  "reaction1":return "The songs, then. I'll give them something to listen for on the second play, not just a list of influences." if answers.get("focus")=="craft" else "Alright — the feeling of the band in a room. That's something I can introduce without reading out a biography."
  "question2":return ("We've talked about the writing. " if answers.get("focus")=="craft" else "So we've got the energy of the band. ")+str(data.get("text",""))
  "reaction2":
   if answers.get("invitation")=="invite":return "Good. A way in, not homework. ‘Bring a friend’ works whether they came for the songs or the live band."
   return "A closer listen, then. I'll leave a bit of room in the introduction rather than telling people what they're supposed to think."
  "wrap_ready":return "Right. ‘"+title+"’: "+("listen for the writing" if answers.get("focus")=="craft" else "get a feel for the band")+", then "+("bring someone else in" if answers.get("invitation")=="invite" else "take time with the record")+". That sounds like something you meant to say. Ready to wrap up?"
 return str(data.get("text",""))

static func answer(data: Dictionary) -> String:
 var visit: Dictionary=data.get("visit",{})
 var answers: Dictionary=visit.get("answers",{})
 if visit.get("phase")=="reaction1":return "The songwriting and the details in our songs." if answers.get("focus")=="craft" else "The energy we want our band to carry."
 if visit.get("phase")=="reaction2":return "Bring a friend and give our band a listen." if answers.get("invitation")=="invite" else "Listen closely and judge the craft of the record."
 return ""

static func next_line(phase: String) -> String:
 return str({"arrival":"LET'S SIT DOWN","introduction":"LET'S TALK ABOUT THE RECORD","reaction1":"AND AFTER THEY'VE HEARD IT?","reaction2":"THAT'S WHAT WE WANT TO SAY"}.get(phase,"CONTINUE"))
