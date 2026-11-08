extends "res://tests/polish_feedback_visual.gd"

func run() -> void:
 Input.emulate_mouse_from_touch=true;Input.emulate_touch_from_mouse=true
 owner=Owner.new()
 check(owner.begin_new() and owner.set_genre("Indie rock") and owner.to_recruit(),"isolated capacity fixture")
 for id in ["cast_tom","cast_ben","cast_dan","cast_ellis","cast_nina","cast_jack"]:
  if not check(owner.recruit(id).get("ok",false),"six real affordable members "+id):finish();return
 check(owner.choose_vocal("cast_nina").get("ok",false) and owner.confirm_lineup().get("ok",false),"six-member canonical ready band")
 var full_name: String="THE MIDNIGHT ÉCHO 東京 COLLECTIVE"
 check(owner.start_naming() and owner.submit_name(full_name,"Raw").get("ok",false) and owner.lock_name().get("ok",false) and owner.start_identity(),"long glyph-rich real naming route")
 await mount()
 await tap("IdentityInk_ivory");await tap("IdentityLogo_Monogram")
 var press=scene.find_child("IdentityPreviewPrint",true,false)
 check(press.visible_ids().size()==6,"six selected portrait identities")
 var full: Label=press.find_child("IdentityFullName",true,false)
 check(full!=null and full.text==full_name,"monogram retains complete name")
 var scroll: ScrollContainer=scene.find_child("IdentityPreviewScroll",true,false)
 if scroll==null:scroll=scene.find_child("IdentityChoicesScroll",true,false)
 check(scroll.get_global_rect().end.y<=scene.find_child("IdentityFinishAction",true,false).get_global_rect().position.y,"bounded preview never overlaps fixed decision dock")
 scroll.scroll_vertical=0;await settle();await capture("six-monogram-top")
 var footer: Label
 for node in press.find_children("*","Label",true,false):
  if node.text=="THE PEOPLE BEHIND THE NAME":footer=node
 scroll.ensure_control_visible(footer);await settle()
 check(scroll.get_global_rect().encloses(footer.get_global_rect()),"entire six-member poster reachable")
 await capture("six-monogram-bottom")
 await tap("IdentityFinishAction")
 check(owner.identity_complete and owner.game.roster.size()==6,"six-member final confirmation retains actual roster")
 check(owner.game.career.is_empty() or owner.game.career.get("tour_day",1)==1,"preview spends no time")
 await tap("StartPlayAction")
 finish()
