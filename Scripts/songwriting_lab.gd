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
