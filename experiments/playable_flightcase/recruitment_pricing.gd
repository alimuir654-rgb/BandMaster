extends RefCounted
## Optional new-band policy. Empty policy preserves every legacy quote.
const Base=preload("res://experiments/character_cast/vendor/recruitment_catalogue_v3.gd")
const KEY="talent_policy"
const CURRENT="look31_v1"
const QUOTES={"cast_tom":30,"cast_jack":50,"cast_ryan":65,"cast_arjun":80,"cast_bex":100,"cast_ben":30,"cast_zoe":65,"cast_hannah":100,"cast_ellis":30,"cast_casey":65,"cast_marcus":100,"cast_nina":20,"cast_maya":35,"cast_lily":65,"cast_sam":100,"cast_dan":20,"cast_freya":50,"cast_oscar":80}

static func valid(policy: Variant) -> bool:
 return policy is String and policy in ["",CURRENT]

static func cost(person: Dictionary,policy: String="") -> int:
 if policy=="":return Base.cost(person)
 if policy!=CURRENT:return Base.MAX_TALENT+1
 if QUOTES.has(str(person.get("id",""))):return int(QUOTES[str(person.id)])
 # Legacy/vendor candidates have a deterministic priced fallback, never free.
 return maxi(30,ceili(float(Base.cost(person))*1.7/5.0)*5)

static func spent(roster: Array,policy: String="") -> int:
 if policy=="":return Base.spent(roster)
 var total: int=0
 for person in roster:total+=cost(person,policy)
 return total+(6 if roster.size()>=5 else 0)+(12 if roster.size()>=6 else 0)

static func incremental(roster: Array,person: Dictionary,policy: String="") -> int:
 if roster.size()>=6 or Base.contains(roster,str(person.get("id",""))):return 0
 var trial: Array=roster.duplicate(true);trial.append(person)
 return spent(trial,policy)-spent(roster,policy)

static func can_add(roster: Array,person: Dictionary,policy: String="") -> bool:
 return valid(policy) and roster.size()<6 and not Base.contains(roster,str(person.get("id",""))) and spent(roster,policy)+incremental(roster,person,policy)<=Base.MAX_TALENT

static func viable(roster: Array,policy: String="") -> bool:
 if not valid(policy) or roster.size()<3 or roster.size()>6 or spent(roster,policy)>Base.MAX_TALENT:return false
 var roles: Array=Base.coverage(roster)
 return roles.has("Singer") and (roles.has("Guitarist") or roles.has("Keyboardist")) and roles.has("Bassist") and roles.has("Drummer")
