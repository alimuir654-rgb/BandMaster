extends RefCounted
# Pure UI summary. Never changes member data or a career save.
static func overview(members: Array) -> Dictionary:
 var active := 0
 var total_morale := 0
 var total_loyalty := 0
 var exhausted := 0
 for item in members:
  if not item is Dictionary:
   continue
  if str(item.get("life_status","active")) != "active":
   continue
  active += 1
  total_morale += clampi(int(item.get("morale",55)),0,100)
  total_loyalty += clampi(int(item.get("loyalty",60)),0,100)
  if int(item.get("fatigue",0)) >= 70:
   exhausted += 1
 var morale := int(round(float(total_morale)/float(active))) if active > 0 else 0
 var loyalty := int(round(float(total_loyalty)/float(active))) if active > 0 else 0
 var mood := "NO ACTIVE MEMBERS"
 if active > 0:
  mood = "RUNNING ON EMPTY" if exhausted > 0 else ("ON EDGE" if morale < 40 or loyalty < 40 else ("FINDING OUR FEET" if morale < 70 else "IN SYNC"))
 return {"active":active,"morale":morale,"loyalty":loyalty,"exhausted":exhausted,"mood":mood}

static func member_note(member: Dictionary) -> String:
 if str(member.get("life_status","active")) != "active":
  return "AWAY FROM THE BAND"
 if int(member.get("fatigue",0)) >= 70:
  return "NEEDS A BREAK"
 if int(member.get("morale",55)) < 40:
  return "LOW SPIRITS"
 if int(member.get("loyalty",60)) < 40:
  return "QUESTIONING THE FUTURE"
 if int(member.get("skill",45)) >= 75:
  return "A CONFIDENT PERFORMER"
 return "FINDING THEIR GROOVE"
