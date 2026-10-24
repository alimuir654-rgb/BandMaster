extends RefCounted
# Presentation-only songwriting state. Never mutates the simulation or save.
const STEPS := ["THE SPARK", "FIND THE SOUND", "FINISH THE TRACK"]

static func view(state: Dictionary) -> Dictionary:
 var progress := clampi(int(state.get("song_draft_progress", 0)), 0, 2)
 var draft = state.get("current_song_draft", {})
 if not draft is Dictionary:
  draft = {}
 var active: bool = not draft.is_empty() and progress > 0
 var sessions := progress if active else 0
 var headline := str(draft.get("title", "YOUR NEXT ORIGINAL")) if active else "A BLANK PAGE"
 var detail := "Choose a musical idea, arrangement, working title and session leader."
 if sessions == 1:
  detail = "The idea is on tape. A second session will shape the arrangement."
 elif sessions == 2:
  detail = "Almost there. One more writing session completes this original."
 return {"headline":headline,"detail":detail,"completed":sessions,"total":3,"stage":STEPS[sessions],"active":active}
