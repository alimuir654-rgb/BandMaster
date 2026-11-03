extends RefCounted
## Newly authored background v1. No wages, schedule or attendance effects.
const VERSION := 1
const BACKGROUNDS := {
 "cast_jack":{"work":"Retail stockroom assistant","outside_commitment":"Rotating shifts; asks for rehearsal dates in advance.","availability":"Rehearsal times still to agree."},
 "cast_arjun":{"work":"Print-studio assistant","outside_commitment":"Occasional evening community print workshops.","availability":"Rehearsal times still to agree."},
 "cast_zoe":{"work":"Part-time print-shop assistant","outside_commitment":"Helps organise occasional DIY shows.","availability":"Rehearsal times still to agree."},
 "cast_marcus":{"work":"Warehouse operative","outside_commitment":"Overtime can be offered at short notice.","availability":"Rehearsal times still to agree."},
 "cast_ellis":{"work":"Cinema front-of-house assistant","outside_commitment":"Some evening and weekend shifts.","availability":"Rehearsal times still to agree."}
}

static func for_candidate(id: String) -> Dictionary:
 var source: Dictionary=BACKGROUNDS.get(id,{})
 var result: Dictionary={}
 for key in ["work","outside_commitment","availability"]:
  result[key]=str(source.get(key,"Not discussed yet."))
 return result
