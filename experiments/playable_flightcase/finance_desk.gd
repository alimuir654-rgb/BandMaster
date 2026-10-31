extends RefCounted
## Read-only finance presentation. The owning desk controls navigation and saves.
const C = preload("res://experiments/playable_flightcase/career_components.gd")
const Finance = preload("res://experiments/playable_flightcase/finance_policy.gd")
const INCOME := ["Gig fees","Music sales","Merch sales"]
const OUTGOING := ["Rehearsal","Equipment","Travel","Session cover","Cancellation","Social","Other"]

static func _copy(host, parent: Node, value: String, name: String = "", points: int = 16, muted: bool = false) -> Label:
 var label: Label = host._copy(parent,value,points,muted)
 if not name.is_empty():
  label.name=name
 return label

static func _row(host, parent: Node, title: String, amount: int, name: String) -> void:
 var row := HBoxContainer.new()
 row.size_flags_horizontal=Control.SIZE_EXPAND_FILL
 row.add_theme_constant_override("separation",8)
 parent.add_child(row)
 var caption: Label = _copy(host,row,title)
 caption.size_flags_horizontal=Control.SIZE_EXPAND_FILL
 var money: Label = _copy(host,row,"£%d" % amount,name)
 money.autowrap_mode=TextServer.AUTOWRAP_OFF
 money.size_flags_horizontal=Control.SIZE_SHRINK_END
 money.horizontal_alignment=HORIZONTAL_ALIGNMENT_RIGHT

static func _total(values: Dictionary) -> int:
 var amount := 0
 for value in values.values():
  amount += int(value)
 return amount

static func _action_title(action: String) -> String:
 var verb: String = action.get_slice(":",action.count(":"))
 var titles := {
  "tighten":"REHEARSAL","rehearse":"REHEARSAL","create":"WRITING SESSION","connect":"TIME WITH THE BAND",
  "buy":"EQUIPMENT PURCHASE","service":"EQUIPMENT SERVICE","assign":"EQUIPMENT ASSIGNMENT",
  "book":"SHOW BOOKING","advance":"VENUE ARRIVAL","soundcheck":"SOUNDCHECK","incident":"BACKSTAGE DECISION",
  "perform":"LIVE SHOW","cancel":"SHOW CANCELLATION","expire":"MISSED SHOW",
  "record":"RECORDING SESSION","release":"RELEASE","campaign":"PROMOTION"
 }
 return str(titles.get(verb,"CAREER TRANSACTION"))

static func render(host, parent: Node, compact: bool) -> void:
 var state: Dictionary = host.game.career
 var account: Dictionary = Finance.view(state)
 var terminal: bool = Finance.is_over(state)
 var cash: int = maxi(0,int(state.get("cash",0)))
 var broke: int = int(account.get("broke_days",0))
 var remaining: int = maxi(0,Finance.LIMIT-broke)
 var summary: VBoxContainer = host._paper(parent,compact)
 summary.name="FinanceSummary"
 _copy(host,summary,"BAND HAS FOLDED" if terminal else "THE BAND ACCOUNTS","FinanceTitle",26)
 _copy(host,summary,"FINAL CASH BALANCE" if terminal else "CURRENT CASH","FinanceBalanceHeading",16,true)
 _copy(host,summary,"£%d" % cash,"FinanceBalance",32)
 var overview: Dictionary = account.get("totals",{})
 _copy(host,summary,"INCOME £%d  •  OUTGOINGS £%d" % [_total(overview.get("income",{})),_total(overview.get("outgoing",{}))],"FinanceOverview")
 var status: String
 if terminal:
  status="The band closed on day %d after 14 consecutive completed days closing at £0. These are your final accounts." % int(account.get("ended_day",0))
 elif cash==0:
  status="£0 remaining. %d of 14 consecutive completed days have closed without money. %d more completed day%s at £0 will end the band." % [broke,remaining,"" if remaining==1 else "s"]
 elif broke>0:
  status="Cash is available. The next saved account will reflect this balance; %d completed zero-cash day%s are currently recorded." % [broke,"" if broke==1 else "s"]
 else:
  status="Cash is available. No consecutive completed zero-cash days are recorded."
 _copy(host,summary,status,"FinanceStatus")
 _copy(host,summary,"The band folds after 14 consecutive completed career days closing at £0. Days closing with money reset the count. Browsing and choices that spend no time do not add days.","FinanceSurvivalRule")
 _copy(host,summary,"Tracking starts on day %d with £%d. Earlier income and spending were not recorded here and have not been reconstructed." % [int(account.get("opening_day",1)),int(account.get("opening_balance",0))],"FinanceTrackingNote",16,true)
 if terminal:
  _copy(host,summary,"FINAL ACCOUNTS  /  READ ONLY","FinanceReadOnly",16,true)
 var totals: Dictionary = account.get("totals",{})
 var income: Dictionary = totals.get("income",{})
 var outgoing: Dictionary = totals.get("outgoing",{})
 var incoming: VBoxContainer = host._paper(parent,compact)
 incoming.name="FinanceIncome"
 _copy(host,incoming,"INCOME SINCE TRACKING BEGAN","FinanceIncomeHeading",20)
 for category in INCOME:
  _row(host,incoming,category,int(income.get(category,0)),"FinanceIncome_"+str(category).replace(" ","_"))
 # Other categories are not expected income sources in this bounded build.
 # Preserve a genuinely recorded amount rather than hiding it or inventing it.
 for category in income.keys():
  if category not in INCOME and int(income[category])!=0:
   _row(host,incoming,str(category),int(income[category]),"FinanceIncome_"+str(category).replace(" ","_"))
 _row(host,incoming,"TOTAL INCOME",_total(income),"FinanceIncomeTotal")
 _copy(host,incoming,"Music and merchandise sales are not active in this build. Their accounts show recorded amounts only; no sales or rates are assumed.","FinanceInactiveSales",16,true)
 var spending: VBoxContainer = host._paper(parent,compact)
 spending.name="FinanceOutgoings"
 _copy(host,spending,"OUTGOINGS SINCE TRACKING BEGAN","FinanceOutgoingHeading",20)
 for category in OUTGOING:
  _row(host,spending,category,int(outgoing.get(category,0)),"FinanceOutgoing_"+str(category).replace(" ","_"))
 for category in outgoing.keys():
  if category not in OUTGOING and int(outgoing[category])!=0:
   _row(host,spending,str(category),int(outgoing[category]),"FinanceOutgoing_"+str(category).replace(" ","_"))
 _row(host,spending,"TOTAL OUTGOINGS",_total(outgoing),"FinanceOutgoingTotal")
 _copy(host,spending,"OPENING £%d  +  INCOME £%d  −  OUTGOINGS £%d  =  ACCOUNTED £%d" % [int(account.get("opening_balance",0)),_total(income),_total(outgoing),int(account.get("closing_balance",cash))],"FinanceReconciliation",16,true)
 var history_body: VBoxContainer = host._paper(parent,compact)
 history_body.name="FinanceHistorySheet"
 _copy(host,history_body,"RECENT SAVED TRANSACTIONS","FinanceTransactionsHeading",20)
 _copy(host,history_body,"Totals include all tracked transactions. The journal retains the latest %d, shown newest first." % Finance.HISTORY_LIMIT,"FinanceHistoryNote",16,true)
 var transactions := VBoxContainer.new()
 transactions.name="FinanceTransactions"
 transactions.size_flags_horizontal=Control.SIZE_EXPAND_FILL
 transactions.add_theme_constant_override("separation",16)
 history_body.add_child(transactions)
 var history: Array = account.get("history",[])
 if history.is_empty():
  _copy(host,transactions,"No transactions recorded yet.","FinanceEmptyTransactions")
 for index in range(history.size()-1,-1,-1):
  if not history[index] is Dictionary:
   continue
  var record: Dictionary = history[index]
  var entry := VBoxContainer.new()
  entry.name="FinanceTransaction_"+str(record.get("seq",index+1))
  entry.size_flags_horizontal=Control.SIZE_EXPAND_FILL
  entry.add_theme_constant_override("separation",4)
  transactions.add_child(entry)
  _copy(host,entry,"DAY %d → %d  /  %s" % [int(record.get("day_before",1)),int(record.get("day_after",1)),_action_title(str(record.get("action","")))],"",16,true)
  _copy(host,entry,"BALANCE £%d → £%d" % [int(record.get("cash_before",0)),int(record.get("cash_after",0))])
  _copy(host,entry,"IN £%d  •  OUT £%d" % [int(record.get("income",0)),int(record.get("outgoing",0))])
  for raw in record.get("flows",[]):
   if not raw is Dictionary:
    continue
   var flow: Dictionary = raw
   var sign: String = "+" if str(flow.get("direction",""))=="income" else "−"
   _copy(host,entry,"%s  %s£%d" % [str(flow.get("category","Other")),sign,int(flow.get("amount",0))])
