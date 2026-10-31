extends RefCounted
## Pure additive accounting. No IO, clock, gameplay resolver or sales rates.
const KEY := "finance_v1"
const VERSION := 1
const LIMIT := 14
const HISTORY_LIMIT := 80
const CATEGORIES := ["Gig fees","Music sales","Merch sales","Rehearsal","Equipment","Travel","Session cover","Cancellation","Social","Other"]

static func _whole(value: Variant) -> bool:
 return (value is int or value is float) and float(value)==floor(float(value))

static func _valid(raw: Variant) -> bool:
 if not raw is Dictionary or not _whole(raw.get("version",0)) or int(raw.get("version",0))!=VERSION:
  return false
 for field in ["opening_balance","opening_day","accounted_day","broke_days","seq","closing_balance"]:
  if not raw.has(field) or not _whole(raw[field]) or int(raw[field])<0:
   return false
 if not raw.get("game_over") is bool or not _whole(raw.get("ended_day",-1)) or int(raw.get("ended_day",-1))<0 or int(raw["broke_days"])>LIMIT:
  return false
 return raw.get("totals") is Dictionary and raw.get("history") is Array

static func view(state: Dictionary) -> Dictionary:
 var cash: int = maxi(0,int(state.get("cash",0)))
 var day: int = maxi(1,int(state.get("tour_day",1)))
 var raw: Variant = state.get(KEY,{})
 var data: Dictionary
 if _valid(raw):
  data = raw.duplicate(true)
 else:
  data = raw.duplicate(true) if raw is Dictionary else {}
  var defaults := {"version":VERSION,"opening_balance":cash,"opening_day":day,"accounted_day":day,"closing_balance":cash,"broke_days":0,"game_over":false,"ended_day":0,"seq":0,"totals":{},"history":[]}
  for field in defaults:
   data[field] = defaults[field]
 var totals: Dictionary = data.get("totals",{}).duplicate(true)
 for direction in ["income","outgoing"]:
  var saved: Variant = totals.get(direction,{})
  var rows: Dictionary = saved.duplicate(true) if saved is Dictionary else {}
  for category in CATEGORIES:
   if not rows.has(category):
    rows[category] = 0
  totals[direction] = rows
 data["totals"] = totals
 return data

static func is_over(state: Dictionary) -> bool:
 var raw: Variant = state.get(KEY,{})
 if raw is Dictionary and bool(raw.get("game_over",false)):
  return true
 return bool(view(state).get("game_over",false))

static func guard(state: Dictionary) -> Dictionary:
 if is_over(state):
  return {"ok":false,"message":"The band has closed after 14 consecutive days without money. Your final accounts remain available."}
 return {"ok":true,"message":""}

static func _flow(rows: Array, direction: String, category: String, amount: int) -> void:
 if amount>0:
  rows.append({"direction":direction,"category":category,"amount":amount})

static func cashflows(before: Dictionary, after: Dictionary, action: String) -> Array:
 var rows: Array = []
 var start: int = int(before.get("cash",0))
 var finish: int = int(after.get("cash",0))
 var verb: String = action.to_lower().get_slice(":",action.count(":"))
 if verb=="perform":
  var gigs: Variant = after.get("gig_history",[])
  var old_gigs: Variant = before.get("gig_history",[])
  if gigs is Array and not gigs.is_empty() and gigs.back() is Dictionary and gigs!=old_gigs:
   var latest: Dictionary = gigs.back()
   if latest.has("fee") and _whole(latest["fee"]) and int(latest["fee"])>=0:
    var fee: int = int(latest["fee"])
    _flow(rows,"income","Gig fees",fee)
    var spent: int = start+fee-finish
    if spent>=0:
     var session: int = mini(spent,maxi(0,int(latest.get("session_fee",0))))
     _flow(rows,"outgoing","Session cover",session)
     var remaining: int = spent-session
     var travel: int = maxi(0,int(latest.get("travel_cost",0)))
     var booking: Variant = before.get("booked_show",{})
     var local: bool = booking is Dictionary and str(booking.get("venue_id",""))=="local"
     if local:
      travel = mini(start,travel)
     var room: int = maxi(0,int(latest.get("accommodation_cost",0)))
     var journey: int = mini(remaining,travel+room)
     _flow(rows,"outgoing","Travel",journey)
     _flow(rows,"outgoing","Other",remaining-journey)
    else:
     _flow(rows,"income","Other",-spent)
    return rows
 var delta: int = finish-start
 var category := "Other"
 if delta<0 and action.begins_with("social:"):
  category = "Social"
 elif verb in ["tighten","rehearse"]:
  category = "Rehearsal"
 elif verb in ["buy","service","buy_gear"]:
  category = "Equipment"
 elif verb=="cancel":
  category = "Cancellation"
 _flow(rows,"income" if delta>0 else "outgoing",category,absi(delta))
 return rows

static func _failure(before: Dictionary, message: String) -> Dictionary:
 return {"ok":false,"state":before.duplicate(true),"message":message}

static func apply(before: Dictionary, after: Dictionary, action: String, flows: Array = [], closing_balances: Array = []) -> Dictionary:
 if not _whole(before.get("cash",0)) or not _whole(after.get("cash",0)) or int(before.get("cash",0))<0 or int(after.get("cash",0))<0:
  return _failure(before,"Finance requires nonnegative whole cash balances.")
 if not _whole(before.get("tour_day",1)) or not _whole(after.get("tour_day",1)):
  return _failure(before,"Finance requires whole career days.")
 var start_day: int = int(before.get("tour_day",1))
 var end_day: int = int(after.get("tour_day",1))
 if start_day<1 or end_day<start_day:
  return _failure(before,"Finance cannot account for a reversed or invalid day.")
 if before.has(KEY) and not _valid(before[KEY]):
  return _failure(before,"The existing finance metadata needs validation before another action.")
 var old: Dictionary = view(before)
 if is_over(before):
  return _failure(before,"The band has closed. Final accounts are read-only.")
 if int(old["accounted_day"])!=start_day or int(old["closing_balance"])!=int(before.get("cash",0)):
  return _failure(before,"The saved finance checkpoint does not match this career state.")
 var incoming: Variant = after.get(KEY,{})
 # A previously accounted result is safe to present/load again. No resolver,
 # cumulative total or day counter is replayed here.
 if _valid(incoming) and int(incoming["seq"])>int(old["seq"]) and int(incoming["opening_balance"])==int(old["opening_balance"]) and int(incoming["opening_day"])==int(old["opening_day"]) and int(incoming["accounted_day"])==end_day and int(incoming["closing_balance"])==int(after.get("cash",0)):
  return {"ok":true,"state":after.duplicate(true),"message":"Already accounted."}
 if before==after and _valid(incoming):
  return {"ok":true,"state":after.duplicate(true),"message":"Already accounted."}
 var days: int = end_day-start_day
 var closes: Array = closing_balances.duplicate(true)
 if days>1 and closes.size()!=days:
  return _failure(before,"Multi-day actions require one explicit closing cash balance per completed day.")
 if days<=1 and not closes.is_empty() and closes.size()!=days:
  return _failure(before,"Closing cash schedule does not match the completed days.")
 if days==1 and closes.is_empty():
  closes.append(int(after.get("cash",0)))
 for balance in closes:
  if not _whole(balance) or int(balance)<0:
   return _failure(before,"Closing cash balances must be nonnegative whole amounts.")
 if not closes.is_empty() and int(closes.back())!=int(after.get("cash",0)):
  return _failure(before,"The final closing balance must match the actual committed cash.")
 var rows: Array = cashflows(before,after,action) if flows.is_empty() else flows.duplicate(true)
 var income := 0
 var outgoing := 0
 for row in rows:
  if not row is Dictionary or str(row.get("direction","")) not in ["income","outgoing"] or str(row.get("category","")) not in CATEGORIES or not _whole(row.get("amount",-1)) or int(row.get("amount",-1))<0:
   return _failure(before,"A cashflow needs a known direction/category and nonnegative whole amount.")
  if str(row["direction"])=="income":
   income += int(row["amount"])
  else:
   outgoing += int(row["amount"])
 if int(before.get("cash",0))+income-outgoing!=int(after.get("cash",0)):
  return _failure(before,"Cashflows do not reconcile to the actual cash balance.")
 var data: Dictionary = old.duplicate(true)
 var count: int = int(data["broke_days"])
 var ended := 0
 for i in range(closes.size()):
  count = count+1 if int(closes[i])==0 else 0
  if count>=LIMIT:
   ended = start_day+i+1
   break
 if ended>0 and ended<end_day:
  return _failure(before,"The action timeline continues beyond the band's closing day.")
 if days==0 and int(after.get("cash",0))>0:
  count=0
 data["broke_days"] = mini(count,LIMIT)
 data["game_over"] = ended>0
 data["ended_day"] = ended
 data["accounted_day"] = end_day
 data["closing_balance"] = int(after.get("cash",0))
 data["seq"] = int(data["seq"])+1
 var totals: Dictionary = data["totals"]
 for row in rows:
  var direction: String = str(row["direction"])
  var category: String = str(row["category"])
  totals[direction][category] = int(totals[direction].get(category,0))+int(row["amount"])
 data["totals"] = totals
 var history: Array = data["history"]
 history.append({"seq":data["seq"],"action":action,"day_before":start_day,"day_after":end_day,"cash_before":int(before.get("cash",0)),"cash_after":int(after.get("cash",0)),"income":income,"outgoing":outgoing,"flows":rows.duplicate(true),"closing_balances":closes.duplicate(true)})
 while history.size()>HISTORY_LIMIT:
  history.pop_front()
 data["history"] = history
 var next: Dictionary = after.duplicate(true)
 next[KEY] = data
 return {"ok":true,"state":next,"message":"Band closed after 14 consecutive broke days." if ended>0 else "Accounted."}
