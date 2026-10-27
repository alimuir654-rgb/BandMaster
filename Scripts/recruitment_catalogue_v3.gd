extends RefCounted
## Isolated V3 recruiting data/rules. No saves, no RNG and no network calls.
const Formation = preload("res://Scripts/formation_catalogue.gd")
const ROLE_TABS := ["Singer", "Guitarist", "Bassist", "Keyboardist", "Drummer"]
const ATTRIBUTE_NAMES := ["Tone", "Originality", "Character", "Presence", "Soulfulness", "Lyricism"]
const INSTRUMENT_NAMES := ["Technique", "Timing", "Originality", "Feel", "Versatility", "Presence"]
const MAX_TALENT := 200

static func genres() -> Array:
 return Formation.GENRES.keys()

static func _person(id: String, name: String, gender: String, age: int, town: String, roles: Array, voice: Array, seed: int, bands: int, years: int, personality: String, story: String, strength: String, friction: String, ambition: String) -> Dictionary:
 var instrumental: Array = []
 for i in range(6):
  instrumental.append(2 + ((seed * (i + 3) + i * 17 + (seed / 3)) % 9))
 return {
  "id":id, "name":name, "gender":gender, "age":age, "town":town,
  "roles":roles, "vocal":voice, "instrument":instrumental,
  "bands":bands, "experience_years":years, "personality":personality,
  "story":story, "strength":strength, "friction":friction, "ambition":ambition,
  "trouble": ("High" if personality in ["Combative","Unpredictable","Tempramental"] else ("Low" if personality in ["Dependable","Thoughtful","Steady"] else "Medium"))
 }

static func people() -> Array:
 return [
  _person("erin_walsh","Erin Walsh","Woman",24,"Bristol",["Singer","Guitarist"],[8,7,6,8,8,6],39,3,8,"Driven","Played tiny venues up and down the M4. Strong melodic instinct but insists on rewriting finished choruses.","Distinctive vocal phrasing and rhythm guitar","Can dominate creative decisions","Wants to make a record, not just play covers"),
  _person("josh_bennett","Josh Bennett","Man",22,"Sheffield",["Singer"],[7,5,8,9,4,4],20,1,4,"Charismatic","Used to front a lively covers band. Excellent at winning a room but has little experience writing his own songs.","Huge live energy","Needs help with lyrics and melody","Wants a band that gets people moving"),
  _person("aisha_khan","Aisha Khan","Woman",27,"Manchester",["Singer","Keyboardist"],[9,8,7,5,9,9],41,2,10,"Thoughtful","Writes at the piano after work and has been the quiet creative centre of two previous bands.","Soulful songs and inventive harmonies","Stage nerves; takes time to trust new people","Wants creative control and proper rehearsal time"),
  _person("tom_hargreaves","Tom Hargreaves","Man",25,"Leeds",["Singer","Drummer"],[5,7,8,7,6,4],23,4,8,"Unpredictable","Sings while playing drums and makes ambitious arrangements sound spontaneous. Often arrives with three new ideas.","Unusual rhythms and a strong point of view","Can be a troublemaker under pressure","Wants to escape routine bar gigs"),
  _person("nia_griffiths","Nia Griffiths","Woman",23,"Cardiff",["Singer"],[8,6,9,6,9,7],17,1,5,"Dependable","Spent years singing in choirs and only recently joined a rock group. The others trusted her to keep everyone together.","Rich tone and patient collaboration","Still learning how to command a loud stage","Wants to write songs with people she respects"),
  _person("dan_mercer","Dan Mercer","Man",29,"Nottingham",["Singer","Bassist"],[6,8,7,7,5,8],31,5,12,"Combative","Former punk frontman who now writes sharper, quieter songs. Five previous bands and a reputation for arguments.","Lyrical detail and bass-led hooks","Can pick fights about arrangements","Wants one band that finally lasts"),
  _person("rowan_price","Rowan Price","Non-binary",26,"Brighton",["Singer","Guitarist"],[7,9,6,5,7,9],27,2,9,"Independent","Makes home demos full of unusual chord changes and poetic stories. Harder to read socially than musically.","Original material and thoughtful words","Hesitates to commit to rehearsals","Wants room to experiment"),
  _person("leila_ahmed","Leila Ahmed","Woman",21,"Birmingham",["Singer"],[6,7,8,9,7,5],14,0,3,"Restless","Open-mic regular, never held down by another band's habits. Fiercely ambitious and still figuring out her own voice.","Electric presence and fresh ideas","Little experience of band compromise","Wants to play to a full room"),
  _person("martha_reed","Martha Reed","Woman",28,"Liverpool",["Guitarist"],[],9,3,11,"Perfectionist","Spent years learning unusual tunings and repairing battered amplifiers.","Inventive chord work","Can overwork a simple song","Wants a serious writing partnership"),
  _person("callum_byrne","Callum Byrne","Man",24,"Newcastle",["Guitarist"],[],12,2,7,"Steady","A reliable rhythm guitarist who knows how to listen before adding more notes.","Dependable live playing","Rarely volunteers new ideas","Wants the camaraderie of a committed band"),
  _person("sophie_clarke","Sophie Clarke","Woman",22,"Leeds",["Guitarist"],[],15,1,5,"Restless","Learnt guitar from recording favourite riffs in her bedroom.","Fast, fearless riffs","Gets bored by slow progress","Wants loud gigs and a tight rhythm section"),
  _person("ben_wilson","Ben Wilson","Man",31,"Cardiff",["Guitarist"],[],18,5,14,"Dependable","An experienced session guitarist, comfortable filling musical gaps.","Versatile arrangements","Not keen on late nights","Wants interesting songs and consistent rehearsals"),
  _person("poppy_hughes","Poppy Hughes","Woman",25,"Bristol",["Guitarist"],[],21,2,6,"Independent","Builds dreamy guitar textures with a second-hand pedalboard.","Atmosphere and originality","Prefers detail to showmanship","Wants a band open to experimentation"),
  _person("owen_parker","Owen Parker","Man",23,"Glasgow",["Guitarist"],[],24,1,5,"Charismatic","Bluesy lead player with a knack for memorable hooks.","Expressive solos","Sometimes plays over the singer","Wants to make people listen"),
  _person("ruby_evans","Ruby Evans","Woman",27,"Sheffield",["Guitarist"],[],27,4,10,"Combative","Tough, technically excellent and not shy about saying when a song needs work.","Precision and high standards","Arguments about tempo and tone","Wants a band that can keep up"),
  _person("owen_ellis","Owen Ellis","Man",26,"Bristol",["Bassist"],[],13,3,8,"Steady","Knows every basement venue and quietly anchors the groove.","Reliable basslines","Reluctant to take musical risks","Wants regular gigs with decent people"),
  _person("imogen_davies","Imogen Davies","Woman",24,"Cardiff",["Bassist"],[],16,1,5,"Restless","Learned bass in a local funk band and loves unusual time signatures.","Inventive low-end parts","Can complicate simple arrangements","Wants freedom to push the music"),
  _person("michael_fraser","Michael Fraser","Man",30,"Glasgow",["Bassist"],[],19,5,13,"Dependable","A thoughtful player who has survived plenty of lineup changes.","Musical patience","Not naturally adventurous","Wants stability and worthwhile songs"),
  _person("grace_fisher","Grace Fisher","Woman",21,"Manchester",["Bassist"],[],22,0,3,"Driven","Young player with sharp instincts and few bad habits.","Fast improvement and new ideas","Limited stage experience","Wants her first proper band"),
  _person("ash_paterson","Ash Paterson","Non-binary",28,"Edinburgh",["Bassist"],[],25,3,9,"Independent","Builds sub-heavy parts with a small collection of old effects.","Distinctive tone and atmosphere","Hard to pin down socially","Wants to work with unusual music"),
  _person("liam_foster","Liam Foster","Man",25,"Nottingham",["Bassist"],[],28,2,7,"Combative","Aggressive bass player whose previous bands liked the sound more than the arguments.","Drive and presence","Short temper in rehearsals","Wants to prove himself"),
  _person("hannah_cole","Hannah Cole","Woman",29,"Liverpool",["Bassist"],[],34,4,12,"Thoughtful","Rooted in soul and jazz, with a measured way of improving arrangements.","Feel and musical empathy","Prefers well-prepared rehearsals","Wants long-term collaborators"),
  _person("mia_turner","Mia Turner","Woman",24,"Birmingham",["Keyboardist"],[],29,2,7,"Creative","Turns ordinary pop chords into unfamiliar textures.","Arrangement imagination","Always asks for more studio time","Wants to find a fresh sound"),
  _person("jack_doherty","Jack Doherty","Man",32,"Belfast",["Keyboardist"],[],32,5,14,"Dependable","A pub pianist who can accompany almost anybody.","Fluent playing and patience","Less confident writing original material","Wants a band of his own"),
  _person("hollie_cooper","Hollie Cooper","Woman",27,"Leeds",["Keyboardist"],[],35,3,10,"Independent","Plays antique synths with a collection of homemade patches.","Memorable electronic textures","Finicky about equipment","Wants to make a strange but accessible record"),
  _person("adam_kelly","Adam Kelly","Man",23,"Glasgow",["Keyboardist"],[],38,1,5,"Restless","A self-taught producer who needs other musicians to challenge him.","Rhythm and sound design","Distracted by new gear","Wants to play outside the bedroom"),
  _person("yasmin_ali","Yasmin Ali","Woman",26,"Manchester",["Keyboardist"],[],43,2,9,"Thoughtful","Combines piano technique with modern studio sounds.","Warm chords and subtle hooks","Quiet in group decisions","Wants a collaborative songwriting home"),
  _person("fred_mason","Fred Mason","Man",30,"Bristol",["Keyboardist"],[],46,4,12,"Perfectionist","Former theatre player who can arrange a song on the spot.","Strong harmonic understanding","Pushes everyone hard at practice","Wants more creative freedom"),
  _person("eve_mclean","Eve McLean","Woman",22,"Edinburgh",["Keyboardist"],[],49,0,4,"Charismatic","Brings stage energy and bold synth melodies.","Live presence and confidence","Little band experience","Wants to tour as soon as possible"),
  _person("isla_mitchell","Isla Mitchell","Woman",25,"Bristol",["Drummer"],[],33,2,8,"Dependable","Excellent timekeeper who always arrives knowing the set.","Trustworthy groove","Not much tolerance for disorganisation","Wants good songs and reliable friends"),
  _person("harry_wright","Harry Wright","Man",23,"Leeds",["Drummer"],[],36,1,5,"Restless","A fast drummer from short-lived punk bands.","Energy and aggression","Can rush a slower song","Wants a packed small venue"),
  _person("faye_morgan","Faye Morgan","Woman",29,"Sheffield",["Drummer"],[],42,4,12,"Perfectionist","Studied jazz and knows how to anchor strange rhythms.","Technical confidence","Gets impatient with sloppy players","Wants challenging music"),
  _person("jamie_mcbride","Jamie McBride","Man",27,"Belfast",["Drummer"],[],45,3,9,"Steady","A laid-back kit player who makes rehearsals feel easy.","Consistent timing and teamwork","Rarely pushes for new arrangements","Wants a band that stays together"),
  _person("chloe_barker","Chloe Barker","Woman",21,"Cardiff",["Drummer"],[],48,0,3,"Driven","Learnt by playing along to records and never stops practising.","Raw talent and commitment","Almost no gig experience","Wants a first proper stage"),
  _person("peter_smith","Peter Smith","Man",31,"Nottingham",["Drummer"],[],51,5,14,"Combative","Experienced drummer who has been fired from as many bands as he left.","Power and live authority","Arguments about money and timing","Wants one last serious shot"),
  _person("elle_harris","Elle Harris","Woman",26,"Manchester",["Drummer"],[],54,2,8,"Creative","Inventive drummer who hears unusual accents and spaces.","Dynamic arrangements","Needs room for experimentation","Wants to make a recording people remember")
 ]

static func pool(genre: String, role: String) -> Array:
 if not ROLE_TABS.has(role) or not genres().has(genre):
  return []
 var candidates: Array = []
 for p in people():
  if (p["roles"] as Array).has(role):
   candidates.append(p)
 if candidates.size() < 6:
  return []
 var offset := (genres().find(genre) * 3 + ROLE_TABS.find(role)) % candidates.size()
 var result: Array = []
 for i in range(6):
  result.append(candidates[(offset + i) % candidates.size()].duplicate(true))
 return result

static func stats_for(person: Dictionary, role: String) -> Array:
 return (person["vocal"] as Array).duplicate() if role == "Singer" else (person["instrument"] as Array).duplicate()

static func labels_for(role: String) -> Array:
 return ATTRIBUTE_NAMES.duplicate() if role == "Singer" else INSTRUMENT_NAMES.duplicate()

static func cost(person: Dictionary) -> int:
 var voice_cost := 0
 var instrument_cost := 0
 for v in person["vocal"]:
  voice_cost += int(v)
 for v in person["instrument"]:
  instrument_cost += int(v)
 return maxi(voice_cost,instrument_cost) + (8 if (person["roles"] as Array).size() > 1 else 0)

static func spent(roster: Array) -> int:
 var total := 0
 for p in roster:
  total += cost(p)
 if roster.size() >= 5:
  total += 6
 if roster.size() >= 6:
  total += 12
 return total

static func contains(roster: Array, person_id: String) -> bool:
 for p in roster:
  if str(p.get("id","")) == person_id:
   return true
 return false

static func can_add(roster: Array, person: Dictionary) -> bool:
 if roster.size() >= 6 or contains(roster,str(person.get("id",""))):
  return false
 var trial := roster.duplicate(true)
 trial.append(person)
 return spent(trial) <= MAX_TALENT

static func coverage(roster: Array) -> Array:
 var roles: Array = []
 for p in roster:
  for role in p["roles"]:
   if not roles.has(role):
    roles.append(role)
 return roles

static func viable(roster: Array) -> bool:
 if roster.size() < 3 or roster.size() > 6 or spent(roster) > MAX_TALENT:
  return false
 var roles := coverage(roster)
 return roles.has("Singer") and (roles.has("Guitarist") or roles.has("Keyboardist")) and roles.has("Bassist") and roles.has("Drummer")

static func missing(roster: Array) -> String:
 var roles := coverage(roster)
 var parts: Array[String] = []
 if not roles.has("Singer"):
  parts.append("vocals")
 if not roles.has("Guitarist") and not roles.has("Keyboardist"):
  parts.append("guitar or keys")
 if not roles.has("Bassist"):
  parts.append("bass")
 if not roles.has("Drummer"):
  parts.append("drums")
 if roster.size() < 3:
  parts.append("at least 3 people")
 return ", ".join(parts)

static func portrait_id(person: Dictionary) -> String:
 # Existing four licensed source assets use these stable historical IDs.
 var matched: Dictionary = {
  "erin_walsh":"alex", "isla_mitchell":"jo", "hannah_cole":"sam", "liam_foster":"dev"
 }
 return str(matched.get(str(person["id"]),person["id"]))
