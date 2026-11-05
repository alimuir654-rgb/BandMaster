extends RefCounted
## Optional, player-agreed fictional career chronology. Never uses the wall clock.
const KEY := "career_clock_v1"
const DAY_ONE := "2026-11-09"
const SOURCE := "player_agreed_start"
const MAX_DISPLAY_DAY := 365000
const WEEKDAYS := ["MONDAY","TUESDAY","WEDNESDAY","THURSDAY","FRIDAY","SATURDAY","SUNDAY"]
const MONTHS := ["JANUARY","FEBRUARY","MARCH","APRIL","MAY","JUNE","JULY","AUGUST","SEPTEMBER","OCTOBER","NOVEMBER","DECEMBER"]

static func inspect(career: Dictionary) -> Dictionary:
 if not career.has(KEY):return {"ok":true,"exists":false,"message":"Agree a start date to put this career on the calendar."}
 var raw: Variant=career[KEY]
 var fail: Dictionary={"ok":false,"exists":true,"message":"This saved calendar needs a compatible version. Its original dates are retained."}
 if not raw is Dictionary or typeof(raw.get("version"))!=TYPE_INT or raw.version!=1 or typeof(raw.get("source"))!=TYPE_STRING or raw.source!=SOURCE or typeof(raw.get("day_one"))!=TYPE_STRING:return fail
 var parts: PackedStringArray=str(raw.day_one).split("-")
 if parts.size()!=3 or parts[0].length()!=4 or parts[1].length()!=2 or parts[2].length()!=2:return fail
 for value in parts:
  if not value.is_valid_int():return fail
 var year: int=int(parts[0]);var month: int=int(parts[1]);var day: int=int(parts[2])
 if year<1900 or year>2099 or month<1 or month>12 or day<1 or day>31:return fail
 if str(raw.day_one)!="%04d-%02d-%02d"%[year,month,day]:return fail
 var month_days: Array=[31,29 if year%4==0 and (year%100!=0 or year%400==0) else 28,31,30,31,30,31,31,30,31,30,31]
 if day>int(month_days[month-1]):return fail
 var stamp: int=Time.get_unix_time_from_datetime_dict({"year":year,"month":month,"day":day,"hour":0,"minute":0,"second":0})
 var back: Dictionary=Time.get_datetime_dict_from_unix_time(stamp)
 if int(back.year)!=year or int(back.month)!=month or int(back.day)!=day or int(back.weekday)!=1:return fail
 return {"ok":true,"exists":true,"origin":stamp,"day_one":str(raw.day_one),"message":""}

static func initial() -> Dictionary:
 return {"version":1,"day_one":DAY_ONE,"source":SOURCE}

static func info(career: Dictionary, career_day: int) -> Dictionary:
 var checked: Dictionary=inspect(career)
 if not checked.ok or not checked.exists or career_day<1 or career_day>MAX_DISPLAY_DAY:return {}
 var raw: Dictionary=Time.get_datetime_dict_from_unix_time(int(checked.origin)+(career_day-1)*86400)
 var weekday: int=(int(raw.weekday)+6)%7
 return {"day":career_day,"year":int(raw.year),"month":int(raw.month),"date":int(raw.day),"weekday":weekday,"weekday_name":WEEKDAYS[weekday],"month_name":MONTHS[int(raw.month)-1],"iso":"%04d-%02d-%02d"%[int(raw.year),int(raw.month),int(raw.day)]}

static func caption(career: Dictionary, career_day: int) -> String:
 var value: Dictionary=info(career,career_day)
 if value.is_empty():return "DAY %d"%career_day
 return "%s %d %s %d · DAY %d"%[value.weekday_name,int(value.date),value.month_name,int(value.year),career_day]

static func month_cursor(career: Dictionary, cursor: int, direction: int) -> int:
 var value: Dictionary=info(career,cursor)
 var checked: Dictionary=inspect(career)
 if value.is_empty() or not checked.ok or not checked.exists:return cursor
 var index: int=int(value.year)*12+int(value.month)-1+direction
 var year: int=int(index/12);var month: int=index%12+1
 var stamp: int=Time.get_unix_time_from_datetime_dict({"year":year,"month":month,"day":1,"hour":0,"minute":0,"second":0})
 return clampi(int((stamp-int(checked.origin))/86400)+1,1,MAX_DISPLAY_DAY)

static func cells(career: Dictionary, cursor: int, mode: String) -> Array:
 var value: Dictionary=info(career,cursor)
 var checked: Dictionary=inspect(career)
 if value.is_empty() or not checked.ok or not checked.exists:return []
 var first: int=cursor-int(value.weekday)
 var count: int=7
 if mode=="month":
  var month_start: int=cursor-int(value.date)+1
  var stamp: int=int(checked.origin)+(month_start-1)*86400
  var raw: Dictionary=Time.get_datetime_dict_from_unix_time(stamp)
  first=month_start-(int(raw.weekday)+6)%7
  count=42
 var result: Array=[]
 for offset in range(count):
  var number: int=first+offset
  var stamp: int=int(checked.origin)+(number-1)*86400
  var raw: Dictionary=Time.get_datetime_dict_from_unix_time(stamp)
  result.append({"day":number,"date":int(raw.day),"month":int(raw.month),"in_month":int(raw.month)==int(value.month),"supported":number>=1 and number<=MAX_DISPLAY_DAY})
 return result
