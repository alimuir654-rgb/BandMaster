extends RefCounted
## Explicitly authored starting circumstances for new fictional bands.
## Pure data: SituationCore alone owns availability and saved consequences.
const SOURCE := "authored_starting_commitments_20261105"
const DAYS := ["MON","TUE","WED","THU","FRI","SAT","SUN"]
const ROWS := {
 "cast_maya": {
  "job_title": "Bookseller",
  "work_evenings": [
   1,
   3
  ],
  "family_evenings": [],
  "family_note": ""
 },
 "cast_dan": {
  "job_title": "Library assistant",
  "work_evenings": [
   3,
   5
  ],
  "family_evenings": [],
  "family_note": ""
 },
 "cast_ryan": {
  "job_title": "Delivery dispatcher",
  "work_evenings": [
   1,
   5
  ],
  "family_evenings": [],
  "family_note": ""
 },
 "cast_lily": {
  "job_title": "Hotel receptionist",
  "work_evenings": [
   3,
   5
  ],
  "family_evenings": [],
  "family_note": ""
 },
 "cast_ben": {
  "job_title": "Cycle-shop sales assistant",
  "work_evenings": [
   1,
   3
  ],
  "family_evenings": [],
  "family_note": ""
 },
 "cast_freya": {
  "job_title": "Garden-centre retail worker",
  "work_evenings": [
   1,
   5
  ],
  "family_evenings": [],
  "family_note": ""
 },
 "cast_nina": {
  "job_title": "Office receptionist",
  "work_evenings": [
   1,
   3
  ],
  "family_evenings": [],
  "family_note": ""
 },
 "cast_tom": {
  "job_title": "Building-maintenance assistant",
  "work_evenings": [
   3,
   5
  ],
  "family_evenings": [],
  "family_note": ""
 },
 "cast_hannah": {
  "job_title": "School office administrator",
  "work_evenings": [
   1,
   3
  ],
  "family_evenings": [
   5
  ],
  "family_note": "A regular Saturday evening helping her family."
 },
 "cast_oscar": {
  "job_title": "IT help-desk technician",
  "work_evenings": [
   1,
   5
  ],
  "family_evenings": [],
  "family_note": ""
 },
 "cast_bex": {
  "job_title": "Theatre usher",
  "work_evenings": [
   3,
   5
  ],
  "family_evenings": [],
  "family_note": ""
 },
 "cast_sam": {
  "job_title": "Catering crew member",
  "work_evenings": [
   1,
   5
  ],
  "family_evenings": [],
  "family_note": ""
 },
 "cast_jack": {
  "job_title": "Retail stockroom assistant",
  "work_evenings": [
   1
  ],
  "family_evenings": [
   5
  ],
  "family_note": "Saturday evening helping with his younger sibling."
 },
 "cast_arjun": {
  "job_title": "Print-studio assistant",
  "work_evenings": [
   1,
   3
  ],
  "family_evenings": [
   5
  ],
  "family_note": "A regular Saturday evening helping his aunt with family errands."
 },
 "cast_zoe": {
  "job_title": "Part-time print-shop assistant",
  "work_evenings": [
   3
  ],
  "family_evenings": [
   5
  ],
  "family_note": "Saturday evening helping with care in her family."
 },
 "cast_marcus": {
  "job_title": "Warehouse operative",
  "work_evenings": [
   3,
   5
  ],
  "family_evenings": [
   1
  ],
  "family_note": "Tuesday evening helping his sister with childcare."
 },
 "cast_ellis": {
  "job_title": "Cinema front-of-house assistant",
  "work_evenings": [
   5
  ],
  "family_evenings": [
   3
  ],
  "family_note": "A regular Thursday evening with family."
 },
 "cast_casey": {
  "job_title": "Café barista",
  "work_evenings": [
   5
  ],
  "family_evenings": [
   3
  ],
  "family_note": "Thursday evening helping a younger sibling with coursework."
 }
}

static func for_candidate(id: String) -> Dictionary:
 return (ROWS[id] as Dictionary).duplicate(true) if ROWS.has(id) else {}

static func words(days: Array) -> String:
 var result: PackedStringArray=[]
 for day in days:result.append(DAYS[int(day)])
 return ", ".join(result)

static func summary(id: String) -> String:
 var row: Dictionary=for_candidate(id)
 if row.is_empty():return "Availability not discussed yet."
 var result: String="WORK EVENINGS · "+words(row.work_evenings)
 if not row.family_evenings.is_empty():result+="\nFAMILY · "+words(row.family_evenings)+" · "+row.family_note
 return result
