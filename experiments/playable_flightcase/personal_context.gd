extends RefCounted
## Newly authored background v2. No wages, schedule or attendance effects.
const VERSION := 2
const BACKGROUNDS := {
 "cast_maya":{"work":"Bookseller","outside_commitment":"Occasionally helps at a neighbourhood reading group; dates vary.","availability":"Rehearsal times still to agree."},
 "cast_dan":{"work":"Library assistant","outside_commitment":"Sometimes helps with community-event setup; dates still to discuss.","availability":"Rehearsal times still to agree."},
 "cast_ryan":{"work":"Delivery dispatcher","outside_commitment":"Occasional community-garden volunteering; dates vary.","availability":"Rehearsal times still to agree."},
 "cast_lily":{"work":"Hotel receptionist","outside_commitment":"Some late cover shifts; no rehearsal pattern agreed.","availability":"Rehearsal times still to agree."},
 "cast_ben":{"work":"Cycle-shop sales assistant","outside_commitment":"Outside commitments not discussed yet.","availability":"Rehearsal times still to agree."},
 "cast_freya":{"work":"Garden-centre retail worker","outside_commitment":"Occasional weekend market-stall work; dates vary.","availability":"Rehearsal times still to agree."},
 "cast_nina":{"work":"Office receptionist","outside_commitment":"Helps with a community newsletter around its deadlines.","availability":"Rehearsal times still to agree."},
 "cast_tom":{"work":"Building-maintenance assistant","outside_commitment":"Some early starts; working days still to discuss.","availability":"Rehearsal times still to agree."},
 "cast_casey":{"work":"Café barista","outside_commitment":"Occasional independent-show setup; dates still to discuss.","availability":"Rehearsal times still to agree."},
 "cast_hannah":{"work":"School office administrator","outside_commitment":"Outside commitments not discussed yet.","availability":"Rehearsal times still to agree."},
 "cast_oscar":{"work":"IT help-desk technician","outside_commitment":"Occasional out-of-hours cover; no fixed rota recorded.","availability":"Rehearsal times still to agree."},
 "cast_bex":{"work":"Theatre usher","outside_commitment":"Some evening performances to work around; dates still to discuss.","availability":"Rehearsal times still to agree."},
 "cast_sam":{"work":"Catering crew member","outside_commitment":"Open-mic commitments still to discuss.","availability":"Rehearsal times still to agree."},
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
