extends RefCounted
# Pure songwriting guidance; preview never mutates the career save.
const STEPS := ["THE SPARK", "FIND THE SOUND", "FINISH THE TRACK"]
const STAGE_PROMPTS := [
 "Find a hook worth returning to. Your first session captures the initial idea.",
 "Your band has a starting point. Rework the arrangement or stay with the original sound.",
 "Make the final call: refine the title, pick the lead, and finish the song."
]
const IDEA_NOTES := {
 "Riff":"Guitar-driven hook; good for an immediate live identity.",
 "Lyric":"Words first; give the chorus something to say.",
 "Groove":"Rhythm first; let the band lock in together."
}
const FORM_NOTES := {
 "Verse / Chorus":"An accessible structure that earns a small completion bonus.",
 "Slow Build":"Start restrained, then build towards the finale.",
 "Loose Jam":"Keep the spontaneous rehearsal-room energy."
}

static func view(state: Dictionary) -> Dictionary:
 var progress := clampi(int(state.get("song_draft_progress",0)),0,2)
 var draft = state.get("current_song_draft",{})
 if not draft is Dictionary:
  draft = {}
 var active: bool = not draft.is_empty() and progress > 0
 var sessions := progress if active else 0
 var headline := str(draft.get("title","YOUR NEXT ORIGINAL")) if active else "A BLANK PAGE"
 var detail: String = str(STAGE_PROMPTS[sessions])
 var history: Array = draft.get("sessions",[]) if draft.get("sessions",[]) is Array else []
 return {"headline":headline,"detail":detail,"completed":sessions,"total":3,"stage":STEPS[sessions],"active":active,"history":history.duplicate(true)}

static func preview(idea: String, form: String, title: String, leader: String) -> Dictionary:
 return {
  "title":title if not title.is_empty() else "UNTITLED",
  "identity":str(IDEA_NOTES.get(idea,"Find your starting point.")),
  "arrangement":str(FORM_NOTES.get(form,"Choose an arrangement.")),
  "leader":"SESSION LEAD  /  "+(leader if not leader.is_empty() else "NO MUSICIAN AVAILABLE")
 }
