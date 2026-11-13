extends RefCounted
## Authored from established musical strengths/frictions. No invented life facts.
const WANTS={
 "cast_jack":"A chorus we can remember without the recording. If we find that, I'll stop adding things to it.",
 "cast_maya":"Let me sing the lines before everyone decides they're finished. I need to hear where the words catch.",
 "cast_ellis":"A count-in we all trust, and an ending we agree before we get there.",
 "cast_zoe":"A bit of space. If the guitar fills every gap, the bass can only follow it.",
 "cast_dan":"I'd like to try the keys underneath the first verse before we decide the song needs another guitar part.",
 "cast_ryan":"One complete rough take. We can argue about it after we've heard what we actually played.",
 "cast_lily":"A take we're willing to listen back to. We keep stopping just before we learn anything.",
 "cast_marcus":"Let the quieter section stay quiet for once. It'll give the next bit somewhere to go.",
 "cast_ben":"Show me the change once, slowly. Then let me get through it without starting again every few bars.",
 "cast_freya":"I'd take a few notes out first. We don't have to prove everyone can play at the same time.",
 "cast_arjun":"Let me answer the vocal between the lines. I don't want to spend the whole song underneath it.",
 "cast_nina":"Let me find the harmony quietly with one person first. I'll bring it up when I know where it sits.",
 "cast_tom":"Play it once without me. I want to hear the gap before I decide what to put in it.",
 "cast_casey":"Give me a look before the quiet bit. I know I get carried away; I want to catch it before you have to stop us.",
 "cast_hannah":"Let's settle the ending. I can give the rest of the song more shape if I know where we're heading.",
 "cast_oscar":"One texture that sounds like this band. Not another sound we only use because it's there.",
 "cast_bex":"Tell me which bit isn't working. I'll change a part, but I need more than 'make it nicer'.",
 "cast_sam":"I want us to mean the line when we get to it. Rough is fine. Going through the motions isn't."
}
const WRITE={
 "cast_jack":"I'll bring the chorus back in, without the extra run into it.",
 "cast_maya":"I'll bring the notebook. Let me try the words over the part before we lock them in.",
 "cast_ellis":"I'll start with the count-in and keep the groove steady while you find the shape.",
 "cast_zoe":"Play me the vocal first. I'll work out where the bass can leave it some room.",
 "cast_dan":"I'll try that quieter keys part underneath the verse.",
 "cast_ryan":"Good. Let's get a rough take down before we talk it to death.",
 "cast_lily":"Then let's finish a take, even if it's scrappy. I want something we can listen back to.",
 "cast_marcus":"I'll keep the quiet section open while we work on the change.",
 "cast_ben":"Play me the changes once and I'll have something ready to work from.",
 "cast_freya":"I'll start with fewer notes. We can hear what the song still needs.",
 "cast_arjun":"I'll bring a short answer for the gap after the vocal. We can try it there first.",
 "cast_nina":"I'll bring a harmony idea. Can we try it quietly before the whole band comes in?",
 "cast_tom":"Give me one run through to listen, then I'll try the supporting part.",
 "cast_casey":"I'll mark the quieter bit before we start. If I rush it, give me the look.",
 "cast_hannah":"Let's agree the ending first. Then I'll work the bass towards it.",
 "cast_oscar":"I'll bring one sound and stick with it long enough to see if it belongs.",
 "cast_bex":"Alright. Show me the bit you want to change and we'll work from there.",
 "cast_sam":"Then let's find what the song is trying to say before we dress it up."
}

static func reply(id: String,choice: String,fallback: String) -> String:
 if choice=="listen":return str(WANTS.get(id,fallback))
 if choice=="write_together" and WRITE.has(id):
  return str(WRITE[id])+" Let's make time for the song within the next four days, with both of us there."
 if choice in ["prepare_set","agree_evening","work_it_out"] and WANTS.has(id):
  return str(WANTS[id])+" Let's try that at rehearsal within the next four days. Check when we're both free."
 return fallback
