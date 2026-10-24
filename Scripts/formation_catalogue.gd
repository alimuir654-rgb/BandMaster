extends RefCounted
# Data-driven band identity and recruitment; no network dependency.
const GENRES := {
 "Indie rock":{"description":"Melodies, guitars and grassroots clubs.","roles":["Singer","Guitarist","Bassist","Drummer"],"strength":"Accessible local gigs","challenge":"Standing out in a crowded scene"},
 "Punk":{"description":"Fast, direct and built for sweaty rooms.","roles":["Singer","Guitarist","Bassist","Drummer"],"strength":"Live energy","challenge":"Band tension"},
 "Post-punk":{"description":"Restless rhythms and sharp, atmospheric songwriting.","roles":["Singer","Guitarist","Bassist","Drummer","Keyboardist"],"strength":"Distinctive arrangements","challenge":"Demanding rehearsals"},
 "Britpop":{"description":"Big choruses and storytelling about ordinary life.","roles":["Singer","Guitarist","Bassist","Drummer"],"strength":"Crowd connection","challenge":"Songwriting pressure"},
 "Shoegaze":{"description":"Layers of guitar, atmosphere and noise.","roles":["Singer","Guitarist","Bassist","Drummer","Keyboardist"],"strength":"Signature sound","challenge":"Gear expense"},
 "Synth-pop":{"description":"Keys, electronics and hook-driven arrangements.","roles":["Singer","Keyboardist","Drummer","Bassist"],"strength":"Production potential","challenge":"Equipment cost"},
 "Garage rock":{"description":"Rough-edged riffs with minimal polish.","roles":["Singer","Guitarist","Bassist","Drummer"],"strength":"Quick live chemistry","challenge":"Consistency"},
 "Goth":{"description":"Dark textures and theatrical identity.","roles":["Singer","Guitarist","Bassist","Drummer","Keyboardist"],"strength":"Loyal niche audience","challenge":"Booking breadth"},
 "Prog rock":{"description":"Complex arrangements and ambitious playing.","roles":["Singer","Guitarist","Bassist","Drummer","Keyboardist"],"strength":"Musicianship","challenge":"Preparation time"},
 "Experimental":{"description":"Unpredictable sounds and unconventional lineups.","roles":["Singer","Guitarist","Keyboardist","Multi-instrumentalist"],"strength":"Musical originality","challenge":"Audience fit"},
 "Country / Americana":{"description":"Stories, harmonies and roots instruments.","roles":["Singer","Guitarist","Bassist","Drummer","Fiddler"],"strength":"Lyrical identity","challenge":"Local audience discovery"},
 "Soul / Funk":{"description":"Groove-led music with room for a big ensemble.","roles":["Singer","Bassist","Drummer","Keyboardist","Guitarist"],"strength":"Live groove","challenge":"Larger lineup costs"},
 "Metal":{"description":"Heavy riffs and specialist, passionate audiences.","roles":["Singer","Guitarist","Bassist","Drummer"],"strength":"Dedicated scene","challenge":"Technical stamina"},
 "Jazz / Fusion":{"description":"Improvisation and ensemble conversation.","roles":["Drummer","Bassist","Keyboardist","Saxophonist","Singer"],"strength":"Player chemistry","challenge":"Musical difficulty"}
}
const INFLUENCES := ["Joy Division","The Velvet Underground","The Smiths","The Clash","Talking Heads","Sonic Youth","The Cure","New Order","Pixies","Kraftwerk","ABBA","Black Sabbath","Radiohead","Pulp","Blur","Oasis","Massive Attack","Portishead","Bowie","Kate Bush","Fleetwood Mac","Nirvana","The Strokes","Arctic Monkeys","The National","Dolly Parton","Johnny Cash","Joni Mitchell","Daft Punk","Nina Simone","Prince","Amy Winehouse"]
const PALETTES := [{"name":"Amber / Charcoal","primary":"#F0B44D","secondary":"#151D28"},{"name":"Electric Blue","primary":"#73B8ED","secondary":"#142536"},{"name":"Cherry Red","primary":"#EF6972","secondary":"#291C2A"},{"name":"Mint / Ink","primary":"#7ED7BF","secondary":"#132C2D"},{"name":"Violet Night","primary":"#BF9DF3","secondary":"#251C37"}]
const LOGOS := ["WORDMARK","STAMP","MONOGRAM"]
const CANDIDATES := [
 {"id":"alex","name":"Alex Vale","role":"Singer","trait":"Creative","gender":"Non-binary","skill":58,"loyalty":61,"pitch":"Writes lyrics on train tickets. Wants a band that means something.","genres":["Indie rock","Post-punk","Britpop"],"share":1},
 {"id":"jo","name":"Jo Mercer","role":"Drummer","trait":"Reliable","gender":"Woman","skill":62,"loyalty":73,"pitch":"Solid timekeeping, always early. Has a day job to juggle.","genres":["Indie rock","Punk","Post-punk"],"share":1},
 {"id":"mick","name":"Mick Turner","role":"Guitarist","trait":"Perfectionist","gender":"Man","skill":69,"loyalty":55,"pitch":"An obsessive guitarist with a van full of pedals.","genres":["Shoegaze","Metal","Prog rock"],"share":1},
 {"id":"sam","name":"Sam Clarke","role":"Bassist","trait":"Peacemaker","gender":"Woman","skill":54,"loyalty":76,"pitch":"Finds the groove and calms arguments before they explode.","genres":["Soul / Funk","Indie rock","Jazz / Fusion"],"share":1},
 {"id":"kit","name":"Kit Morgan","role":"Keyboardist","trait":"Unreliable genius","gender":"Non-binary","skill":75,"loyalty":42,"pitch":"Brilliant synth parts, erratic attendance.","genres":["Synth-pop","Goth","Experimental"],"share":1},
 {"id":"fran","name":"Fran Price","role":"Guitarist","trait":"Chaos agent","gender":"Woman","skill":60,"loyalty":59,"pitch":"Every rehearsal is louder and less predictable with Fran.","genres":["Punk","Garage rock","Indie rock"],"share":1},
 {"id":"lee","name":"Lee Brooks","role":"Singer","trait":"Attention seeker","gender":"Man","skill":63,"loyalty":47,"pitch":"Charismatic onstage, demanding backstage.","genres":["Britpop","Soul / Funk","Goth"],"share":1},
 {"id":"rae","name":"Rae Ellis","role":"Drummer","trait":"Perfectionist","gender":"Woman","skill":72,"loyalty":55,"pitch":"Technical player who likes everyone to know the arrangement.","genres":["Metal","Jazz / Fusion","Prog rock"],"share":1},
 {"id":"dev","name":"Dev Shah","role":"Bassist","trait":"Cynic","gender":"Man","skill":66,"loyalty":52,"pitch":"Knows every basement venue. Questions every bad decision.","genres":["Post-punk","Punk","Garage rock"],"share":1},
 {"id":"ivy","name":"Ivy Hart","role":"Fiddler","trait":"Creative","gender":"Woman","skill":70,"loyalty":62,"pitch":"Brings roots melodies and an unlikely ear for harmony.","genres":["Country / Americana","Experimental"],"share":1},
 {"id":"noor","name":"Noor Farah","role":"Keyboardist","trait":"Peacemaker","gender":"Woman","skill":59,"loyalty":74,"pitch":"Warm keys and calm advice. Prefers thoughtful arrangements.","genres":["Soul / Funk","Synth-pop","Jazz / Fusion"],"share":1},
 {"id":"eli","name":"Eli Bennett","role":"Multi-instrumentalist","trait":"Unreliable genius","gender":"Man","skill":77,"loyalty":44,"pitch":"Plays anything, finishes very little without encouragement.","genres":["Experimental","Country / Americana","Shoegaze"],"share":1},
 {"id":"tash","name":"Tash King","role":"Saxophonist","trait":"People pleaser","gender":"Woman","skill":67,"loyalty":68,"pitch":"An improviser who can make two opposing musical ideas work.","genres":["Jazz / Fusion","Soul / Funk"],"share":1}
]
static func affinity(candidate: Dictionary, genre: String) -> int:
 return 2 if candidate.get("genres",[]).has(genre) else 0
static func can_recruit(roster: Array, candidate: Dictionary) -> bool:
 if roster.size() >= 6:
  return false
 for member in roster:
  if str(member.get("candidate_id","")) == str(candidate.get("id","")):
   return false
 return true
static func split_per_member(count: int) -> int:
 return int(floor(100.0 / float(maxi(1,count))))
static func viable(roster: Array) -> bool:
 if roster.size() < 2 or roster.size() > 6:
  return false
 var has_rhythm := false
 for member in roster:
  var role := str(member.get("role",""))
  if role == "Drummer" or role == "Multi-instrumentalist":
   has_rhythm = true
 return has_rhythm
static func to_member(candidate: Dictionary, index: int) -> Dictionary:
 return {"id":index,"candidate_id":str(candidate["id"]),"name":str(candidate["name"]),"role":str(candidate["role"]),"gender":str(candidate["gender"]),"trait":str(candidate["trait"]),"note":str(candidate["pitch"]),"skill":int(candidate["skill"]),"loyalty":int(candidate["loyalty"]),"morale":55,"fatigue":5}
