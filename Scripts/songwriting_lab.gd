extends RefCounted
# UI-only songwriting exploration. These choices never spend days or alter the save.
static func advance(control: OptionButton, steps: int = 1) -> bool:
 if control.item_count <= 1:
  return false
 var current: int = maxi(control.selected,0)
 control.select(posmod(current + steps, control.item_count))
 return true

static func remix(idea: OptionButton, form: OptionButton, title: OptionButton, leader: OptionButton) -> int:
 var changed := 0
 for control in [idea,form,title,leader]:
  if advance(control):
   changed += 1
 return changed

static func can_commit(idea: OptionButton, form: OptionButton, title: OptionButton, leader: OptionButton) -> bool:
 for control in [idea,form,title,leader]:
  if control.item_count == 0 or control.selected < 0:
   return false
 return true

# Keep A/B takes local to the writing room until a session is committed.
static func capture(idea: OptionButton, form: OptionButton, title: OptionButton, leader: OptionButton) -> Dictionary:
 if not can_commit(idea,form,title,leader):
  return {}
 return {"idea":idea.selected,"form":form.selected,"title":title.selected,"leader":leader.selected}

static func restore(take: Dictionary, idea: OptionButton, form: OptionButton, title: OptionButton, leader: OptionButton) -> bool:
 if take.is_empty():
  return false
 var controls := {"idea":idea,"form":form,"title":title,"leader":leader}
 for key in controls:
  var control: OptionButton = controls[key]
  var index := int(take.get(key,-1))
  if index < 0 or index >= control.item_count:
   return false
 for key in controls:
  var control: OptionButton = controls[key]
  control.select(int(take[key]))
 return true

static func difference(take: Dictionary, idea: OptionButton, form: OptionButton, title: OptionButton, leader: OptionButton) -> int:
 if take.is_empty():
  return 0
 var controls := {"idea":idea,"form":form,"title":title,"leader":leader}
 var changed := 0
 for key in controls:
  var control: OptionButton = controls[key]
  if control.selected != int(take.get(key,-1)):
   changed += 1
 return changed
