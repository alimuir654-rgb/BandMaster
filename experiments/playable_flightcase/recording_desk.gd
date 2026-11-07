extends RefCounted
## S54 SCRATCH UI helper. Root is sole source writer/engine runner.
## All browsing/ordering/modes are FREE DRAFT ONLY. Pure previews never apply state.
const Poster=preload("res://experiments/playable_flightcase/poster_components.gd")
const Cover=preload("res://experiments/playable_flightcase/demo_cover.gd")
const Rules = preload("res://experiments/playable_flightcase/recording_rules.gd")
const Ink = preload("res://experiments/playable_flightcase/ink_note.gd")
const Promotion = preload("res://experiments/playable_flightcase/promotion_rules.gd")
const GearArt = preload("res://experiments/playable_flightcase/gear_press.gd")
const RadioVisit = preload("res://experiments/playable_flightcase/radio_visit_rules.gd")
const RadioDesk = preload("res://experiments/playable_flightcase/radio_visit_desk.gd")

static func _key(id: String) -> String:
 return id.replace(":","_").replace("/","_").replace(" ","_")

static func _copy(host, parent: Node, value: String, name: String="", points: int=16, muted: bool=false) -> Label:
 var label: Label=host._copy(parent,value,points,muted)
 if not name.is_empty(): label.name=name
 return label

static func _note(parent: Node, value: String, name: String="", interactive: bool=false, fresh: bool=false) -> Label:
 var note: Label=Ink.new()
 note.text=value
 note.add_theme_color_override("font_color",Color("29241f"))
 if not name.is_empty(): note.name=name
 if not interactive:
  note.focus_mode=Control.FOCUS_NONE
  note.mouse_filter=Control.MOUSE_FILTER_IGNORE
 if fresh: note.visible_characters=0
 parent.add_child(note)
 # Existing Ink._ready applies Caveat22/clear16 after caller setup.
 return note

static func _button(host, parent: Node, value: String, name: String, action: Callable, primary: bool=false, enabled: bool=true) -> Button:
 var button: Button=host._button(value,name,action,primary)
 button.disabled=bool(host.busy) or not enabled
 parent.add_child(button)
 return button

static func _columns(host, parent: Node, compact: bool) -> Array:
 if compact: return [parent,parent]
 var row:=HBoxContainer.new()
 row.add_theme_constant_override("separation",24)
 row.size_flags_horizontal=Control.SIZE_EXPAND_FILL
 parent.add_child(row)
 var tracks: VBoxContainer=host._box(12)
 tracks.size_flags_stretch_ratio=1.4
 row.add_child(tracks)
 var facts: VBoxContainer=host._box(10)
 facts.size_flags_stretch_ratio=1.0
 row.add_child(facts)
 return [tracks,facts]

static func _editable(host) -> bool:
 # Retained static Callables must never read a freed host or own another route.
 if not is_instance_valid(host): return false
 if not host.is_inside_tree() or not host.is_visible_in_tree() or str(host.page)!="recording": return false
 return not bool(host.busy) and not bool(host.receipt_open) and not is_instance_valid(host._live_dialog) and not RadioVisit.locked(host.game.career)

static func _find_song(songs: Array, id: String) -> Dictionary:
 for raw in songs:
  if raw is Dictionary and str(raw.get("id",""))==id: return raw
 return {}

static func render(host, parent: Node, compact: bool) -> void:
 if str(host.recording_mode)=="visit" or RadioVisit.locked(host.game.career):
  RadioDesk.render(host,parent,compact)
  return
 if str(host.recording_mode)=="radio":
  _radio(host,parent,compact)
  return
 if str(host.recording_mode)=="archive":
  _archive(host,parent,compact)
  return
 var state: Dictionary=host.game.career
 var songs: Array=Rules.songs(state)
 var body: VBoxContainer=host._paper(parent,compact)
 _copy(host,body,"CUT A DEMO","RecordingHeading",26)
 _copy(host,body,"THREE ORIGINALS → RECORD → RELEASE → LOCAL RADIO","DemoRadioPath",16)
 _copy(host,body,"Choose two or three finished originals. Recording uses £60 and 2 days; release uses £25 and 1 day. A released demo opens the local-radio pitch.","DemoRadioCosts",16)
 _copy(host,body,"%d OF 3 TRACKS SELECTED" % host.recording_ids.size(),"RecordingCount",16)
 if not str(host.notice).is_empty(): _copy(host,body,str(host.notice),"RecordingNotice")
 var columns: Array=_columns(host,body,compact)
 var tracks: Node=columns[0]
 var facts: Node=columns[1]
 if songs.is_empty():
  var raw: Variant=state.get("song_catalogue",[])
  var message: String="Finish at least two originals in the Songbook before selecting a demo."
  var valid: Dictionary=Rules.validate(state)
  if not bool(valid.get("ok",false)):
   message=str(valid.get("message","The saved song catalogue needs attention before selecting tracks."))
  elif raw is Array and not raw.is_empty():
   message="No originals with saved song IDs are available for this track selection. Existing recordings remain in the archive; legacy song details stay in the Songbook."
  _copy(host,tracks,message,"RecordingNoSelectableSongs")
 else:
  _selection(host,tracks,songs)
 _brief(host,facts,state)

static func _selection(host, parent: Node, songs: Array) -> void:
 var ids: Array=host.recording_ids
 if not ids.is_empty():_copy(host,parent,"YOUR TRACK ORDER","RecordingOrderHeading",20)
 for index in range(ids.size()):
  var id: String=str(ids[index])
  var song: Dictionary=_find_song(songs,id)
  if song.is_empty():
   _copy(host,parent,"%d. SELECTED TRACK UNAVAILABLE" % (index+1),"RecordingMissing_"+_key(id),20)
   _button(host,parent,"REMOVE UNAVAILABLE TRACK","RecordingSong_"+_key(id),toggle.bind(host,id))
  else:
   _selectable_track(host,parent,song,index,ids.size())
 var available: Array=[]
 for song in songs:
  if not ids.has(str(song["id"])): available.append(song)
 if not available.is_empty():
  _copy(host,parent,"AVAILABLE ORIGINALS","RecordingAvailableHeading",20)
  if ids.size()>=3: _copy(host,parent,"Remove a selected track before adding another.","RecordingSelectionLimit",16,true)
  for song in available: _selectable_track(host,parent,song,-1,ids.size())

static func _song_facts(host, parent: Node, song: Dictionary, key: String) -> void:
 var view: Dictionary=Rules.describe_song(song)
 _copy(host,parent,str(view["credits"]),"RecordingCredits_"+key)
 _copy(host,parent,"IDEA / "+str(view["origin"])+"\nFORM / "+str(view["arrangement"]),"RecordingCreative_"+key,16,true)
 _copy(host,parent,str(view["quality"])+"  •  "+str(view["day"]),"RecordingQuality_"+key,16,true)
 var history: Array=view["notes"]
 var history_text: String="WRITING HISTORY NOT RECORDED" if history.is_empty() else "WRITING HISTORY\n"+"\n".join(PackedStringArray(history))
 _copy(host,parent,history_text,"RecordingHistory_"+key,16,true)

static func _selectable_track(host, parent: Node, song: Dictionary, selected_index: int, selected_count: int) -> void:
 var id: String=str(song["id"])
 var key: String=_key(id)
 var block: VBoxContainer=host._box(6)
 block.name="RecordingTrack_"+key
 parent.add_child(block)
 var title: String=("%d. " % (selected_index+1) if selected_index>=0 else "")+str(song["title"])
 # Full48-character title is a native wrapped label; action captions stay short.
 _copy(host,block,title,"RecordingTitle_"+key,20)
 var facts: Dictionary=Rules.describe_song(song)
 _copy(host,block,str(facts["credits"]),"RecordingCredits_"+key)
 _copy(host,block,str(facts["arrangement"])+"  •  "+str(facts["quality"]),"RecordingSelectFacts_"+key,16,true)
 var selected: bool=selected_index>=0
 var select: Button=_button(host,block,"REMOVE FROM DEMO" if selected else "ADD TO DEMO","RecordingSong_"+key,toggle.bind(host,id),false,selected or selected_count<3)
 select.set_meta("song_id",id)
 select.toggle_mode=true
 select.set_pressed_no_signal(selected)
 if selected:
  var moves:=HBoxContainer.new()
  moves.add_theme_constant_override("separation",8)
  block.add_child(moves)
  _button(host,moves,"UP","RecordingUp_"+key,move.bind(host,id,-1),false,selected_index>0)
  _button(host,moves,"DOWN","RecordingDown_"+key,move.bind(host,id,1),false,selected_index<selected_count-1)

static func _brief(host, parent: Node, state: Dictionary) -> void:
 _copy(host,parent,"THE SESSION BRIEF","RecordingBriefHeading",20)
 _note(parent,"Your songs, in your order. Put the demo on record.","RecordingIntroNote")
 _copy(host,parent,"RECORDING / £60 UPFRONT\nTIME / 2 DAYS","RecordingCostFacts")
 var preview: Dictionary=Rules.preview(state,host.recording_ids.duplicate())
 if bool(preview.get("ok",false)):
  var after: Dictionary=preview["state"]
  _copy(host,parent,"AFTER SESSION / £%d\nDAY %d → %d" % [int(after.get("cash",0)),int(state.get("tour_day",1)),int(after.get("tour_day",1))],"RecordingAfterFacts")
 else:
  _copy(host,parent,str(preview.get("message","Choose two or three tracks.")),"RecordingBriefEligibility")
 _copy(host,parent,"The displayed after-session cash includes the existing daily accounts.","RecordingAccountsNote",16,true)
 _copy(host,parent,"Demo quality follows the selected songs.","RecordingQualityBasis",16,true)

static func dock(host, parent: Node, _compact: bool) -> void:
 if str(host.recording_mode)=="visit" or RadioVisit.locked(host.game.career):
  RadioDesk.dock(host,parent,_compact)
  return
 if str(host.recording_mode)=="radio":
  _radio_dock(host,parent)
  return
 if str(host.recording_mode)=="archive":
  _button(host,parent,"CHOOSE TRACKS","RecordingSelectAction",mode.bind(host,"select"),true)
  _button(host,parent,"BACK TO SONGBOOK","RecordingBackSongsAction",host._navigate.bind("songs"))
  return
 var state: Dictionary=host.game.career
 var preview: Dictionary=Rules.preview(state,host.recording_ids.duplicate())
 var commitment: String="£60  •  2 DAYS  •  %d TRACKS" % host.recording_ids.size()
 if bool(preview.get("ok",false)):
  var after: Dictionary=preview["state"]
  commitment+="\n£%d → £%d  •  DAY %d → %d" % [int(state.get("cash",0)),int(after.get("cash",0)),int(state.get("tour_day",1)),int(after.get("tour_day",1))]
 var label: Label=_copy(host,parent,commitment,"RecordingCommitment")
 label.add_theme_color_override("font_color",Color("efe9da"))
 if not bool(preview.get("ok",false)):
  var reason: Label=_copy(host,parent,str(preview.get("message","Choose two or three tracks.")),"RecordingEligibility")
  reason.add_theme_color_override("font_color",Color("f0c78b"))
 _button(host,parent,"RECORD SELECTED  •  £60","RecordingMainAction",commit.bind(host,"record"),true,bool(preview.get("ok",false)))
 var free:=HBoxContainer.new()
 free.add_theme_constant_override("separation",8)
 parent.add_child(free)
 _button(host,free,"ARCHIVE","RecordingArchiveAction",mode.bind(host,"archive"))
 _button(host,free,"BACK TO SONGBOOK","RecordingBackSongsAction",host._navigate.bind("songs"))

static func _archive(host, parent: Node, compact: bool) -> void:
 var state: Dictionary=host.game.career
 var sessions: Array=Rules.sessions(state)
 var heading: VBoxContainer=host._paper(parent,compact)
 _copy(host,heading,"YOUR RECORDINGS","RecordingArchiveHeading",26)
 if not str(host.notice).is_empty(): _copy(host,heading,str(host.notice),"RecordingNotice")
 _copy(host,heading,"Saved tracks and local releases.","RecordingArchiveIntroduction",16,true)
 _copy(host,heading,"Your record, in your order. Saved sketches can be heard in the Songbook.","RecordingArchiveAudio",16,true)
 if sessions.is_empty():
  var raw: Variant=state.get("recordings",[])
  var valid: Dictionary=Rules.validate(state)
  var message: String="No saved demos yet. Choose two or three originals to make one."
  if not bool(valid.get("ok",false)):
   message=str(valid.get("message","The saved recording history needs attention before it can be shown."))
  elif raw is Array and not raw.is_empty():
   message="The saved recording history needs attention before it can be shown."
  _copy(host,heading,message,"RecordingArchiveEmpty")
  return
 # Rules.sessions is ALL safe raw Dictionary rows in original order, or[].
 # Thus this index is the ACTUAL archive index, including ID-less legacy rows.
 for index in range(sessions.size()):
  var body: VBoxContainer=host._paper(parent,compact)
  body.name="RecordingSession_"+str(index)
  _session(host,body,sessions[index],compact,index,true)

static func _session(host, parent: Node, session: Dictionary, compact: bool, index: int, release_action: bool) -> void:
 var linked: bool=session.get("song_links_v1",null) is Dictionary
 var list: Array=session.get("tracks",[])
 var hero:=HBoxContainer.new();hero.size_flags_horizontal=Control.SIZE_EXPAND_FILL;hero.add_theme_constant_override("separation",18);parent.add_child(hero)
 var sleeve:=VBoxContainer.new();sleeve.size_flags_horizontal=Control.SIZE_EXPAND_FILL;hero.add_child(sleeve)
 var band: Label=Poster.label(str(host.game.career.get("band_name","YOUR BAND")).to_upper(),34);band.name="DemoSleeveBand_"+str(index);sleeve.add_child(band)
 var art:=Cover.new();art.name="DemoSleeveArt_"+str(index);art.identity=str(session.get("id","legacy:"+str(index)))+":"+str(host.game.career.get("band_name",""));art.set_meta("recording_id",str(session.get("id","")));sleeve.add_child(art)
 var heading: String="DEBUT DEMO" if index==0 else "DEMO %d" % (index+1)
 _copy(host,sleeve,heading,"RecordingSessionHeading_"+str(index),30)
 _copy(host,sleeve,"DAY %d · %d TRACKS" % [int(session["day"]),list.size()] if session.has("day") else "DATE NOT RECORDED · %d TRACKS" % list.size(),"DemoSleeveDate_"+str(index),18)
 var tracks: Node=parent
 if not compact:
  var track_box: VBoxContainer=host._box(10);hero.add_child(track_box);tracks=track_box
 if list.is_empty():_copy(host,tracks,"TRACK DETAILS NOT RECORDED","RecordingMissingTracks_"+str(index),18,true)
 for track_index in range(list.size()):
  var track: Dictionary=list[track_index]
  _copy(host,tracks,"%02d  %s" % [track_index+1,str(track.get("title","UNTITLED"))],"RecordingSavedTitle_%d_%d" % [index,track_index],24)
 _session_facts(host,parent,session,index,release_action)
 var details:=VBoxContainer.new();details.name="DemoTrackDetails_"+str(index);details.visible=false;details.size_flags_horizontal=Control.SIZE_EXPAND_FILL
 var toggle: Button=_button(host,parent,"TRACK NOTES  +","DemoTrackNotes_"+str(index),func():
  if not _editable(host) or not is_instance_valid(details):return
  details.visible=not details.visible)
 toggle.toggle_mode=true
 toggle.toggled.connect(func(open: bool):
  if is_instance_valid(toggle):toggle.text="TRACK NOTES  −" if open else "TRACK NOTES  +")
 parent.add_child(details)
 _copy(host,details,"SAVED SONG LINKS" if linked else "LEGACY RECORDING · SONG LINKS NOT RECORDED","RecordingLinkStatus_"+str(index),18,true)
 var snapshots: Array=(session["song_links_v1"] as Dictionary).get("snapshots",[]) if linked else []
 for track_index in range(list.size()):
  var track: Dictionary=list[track_index]
  _copy(host,details,str(track.get("title","UNTITLED")),"RecordingDetailTitle_%d_%d" % [index,track_index],22)
  _copy(host,details,"QUALITY %d / 100" % int(track["quality"]) if track.has("quality") else "TRACK QUALITY NOT RECORDED","RecordingSavedQuality_%d_%d" % [index,track_index],18,true)
  if linked and track_index<snapshots.size():_song_facts(host,details,snapshots[track_index],"saved_%d_%d" % [index,track_index])
  else:_copy(host,details,"Writing credits, song ID and session history were not saved with this legacy track.","RecordingLegacyTrack_%d_%d" % [index,track_index],18,true)

static func _session_facts(host, facts: Node, session: Dictionary, index: int, release_action: bool) -> void:
 _copy(host,facts,"SESSION QUALITY %d / 100" % int(session["quality"]) if session.has("quality") else "SESSION QUALITY NOT RECORDED","RecordingSavedSessionQuality_"+str(index))
 if bool(session.get("released",false)):
  _copy(host,facts,"RELEASED LOCALLY"+(" • DAY %d" % int(session["release_day"]) if session.has("release_day") else ""),"RecordingReleaseStatus_"+str(index))
  if session.has("fans_gained"): _copy(host,facts,"SAVED RELEASE REACH / +%d FANS" % int(session["fans_gained"]),"RecordingSavedFans_"+str(index))
 else:
  _copy(host,facts,"LOCAL RELEASE NOT YET SAVED","RecordingReleaseStatus_"+str(index))
 if release_action and not bool(session.get("released",false)):
  var id: String=str(session.get("id",""))
  var fingerprint: String=Rules.fingerprint(session)
  var preview: Dictionary=Rules.preview_release(host.game.career,id,fingerprint,index)
  _copy(host,facts,"LOCAL RELEASE / £25 • 1 DAY","RecordingReleaseTerms_"+str(index))
  if bool(preview.get("ok",false)):
   var after: Dictionary=preview["state"]
   _copy(host,facts,"AFTER RELEASE / £%d\nDAY %d → %d" % [int(after.get("cash",0)),int(host.game.career.get("tour_day",1)),int(after.get("tour_day",1))],"RecordingReleaseAfter_"+str(index))
  else: _copy(host,facts,str(preview.get("message","This release is unavailable.")),"RecordingReleaseReason_"+str(index))
  var action: Button=_button(host,facts,"RELEASE LOCALLY  •  £25","RecordingRelease_"+str(index),commit.bind(host,"release",id,fingerprint,index),true,bool(preview.get("ok",false)))
  action.set_meta("recording_id",id)
  action.set_meta("recording_index",index)
  action.set_meta("recording_fingerprint",fingerprint)
 if release_action and bool(session.get("released",false)):
  var id: String=str(session.get("id",""))
  var fingerprint: String=Rules.fingerprint(session)
  var selected: Dictionary=Promotion.selection(host.game.career,id,fingerprint,index)
  var completed: bool=bool(selected.get("completed",false))
  _copy(host,facts,"RADIO CAMPAIGN COMPLETE" if completed else "LOCAL RADIO / £20 • 1 DAY","RecordingRadioStatus_"+str(index))
  var action: Button=_button(host,facts,"SAVED RADIO NOTES" if completed else "LOCAL RADIO  ›","RecordingRadio_"+str(index),open_radio.bind(host,id,fingerprint,index),false,bool(selected.get("ok",false)))
  action.set_meta("recording_id",id)
  action.set_meta("recording_index",index)
  action.set_meta("recording_fingerprint",fingerprint)
  if not bool(selected.get("ok",false)):_copy(host,facts,str(selected.get("message","Review the saved demo.")),"RecordingRadioReason_"+str(index))

static func focus_name(host) -> String:
 if str(host.recording_mode)=="visit" or RadioVisit.locked(host.game.career):return "StudioNote"
 return "PromotionBackAction" if str(host.recording_mode)=="radio" else ("RecordingSelectAction" if str(host.recording_mode)=="archive" else "RecordingMainAction")

static func _radio_selection(host) -> Dictionary:
 var chosen: Dictionary=host.promotion_selection
 return Promotion.selection(host.game.career,str(chosen.get("id","")),str(chosen.get("fingerprint","")),int(chosen.get("index",-1)))

static func _radio_preview(host) -> Dictionary:
 var chosen: Dictionary=host.promotion_selection
 return Promotion.preview(host.game.career,str(chosen.get("id","")),str(chosen.get("fingerprint","")),int(chosen.get("index",-1)))

static func _radio_metrics(host, parent: Node, before: Dictionary, after: Dictionary) -> void:
 var rows: PackedStringArray=[]
 for field in ["fans","press","buzz"]:
  rows.append("%s  %d → %d" % [field.to_upper(),int(before.get(field,0)),int(after.get(field,0))])
 var compact: bool=host.size.x<840 or host.size.x<host.size.y
 _copy(host,parent,(rows[0]+"  •  "+rows[1]+"\n"+rows[2]) if compact else "\n".join(rows),"PromotionPreview")

static func _radio_summary(before: Dictionary, after: Dictionary) -> String:
 return "%d new listeners found your band." % (int(after.get("fans",0))-int(before.get("fans",0)))

static func _radio_hero(host, parent: Node, compact: bool, summary: String, fresh: bool=false) -> void:
 var row:=HBoxContainer.new()
 row.name="PromotionHero"
 row.add_theme_constant_override("separation",12)
 row.mouse_filter=Control.MOUSE_FILTER_PASS
 parent.add_child(row)
 var picture: TextureRect=GearArt.image("mics",128.0 if compact else 160.0)
 picture.name="PromotionHeroArt"
 picture.custom_minimum_size.x=128.0 if compact else 180.0
 picture.size_flags_horizontal=Control.SIZE_FILL
 row.add_child(picture)
 var words: VBoxContainer=host._box(4)
 words.size_flags_vertical=Control.SIZE_SHRINK_CENTER
 row.add_child(words)
 _note(words,summary,"CareerReceiptNote" if fresh else "PromotionSummaryNote",fresh,fresh and bool(host._fresh_receipt))

static func _radio_pills(host, parent: Node, before: Dictionary, after: Dictionary, projected: bool) -> void:
 _copy(host,parent,"PROJECTED RESPONSE" if projected else "SAVED RESPONSE","PromotionProjectionHeading",16,true)
 var grid:=GridContainer.new()
 grid.name="PromotionDeltaPills"
 grid.columns=3
 grid.size_flags_horizontal=Control.SIZE_SHRINK_BEGIN
 grid.add_theme_constant_override("h_separation",6)
 grid.mouse_filter=Control.MOUSE_FILTER_IGNORE
 parent.add_child(grid)
 for field in ["fans","press","buzz"]:
  var delta: int=int(after.get(field,0))-int(before.get(field,0))
  var panel:=PanelContainer.new()
  panel.name="PromotionPill_"+field
  panel.size_flags_horizontal=Control.SIZE_EXPAND_FILL
  panel.mouse_filter=Control.MOUSE_FILTER_IGNORE
  panel.focus_mode=Control.FOCUS_NONE
  var stock:=StyleBoxFlat.new()
  stock.bg_color=Color("e0e9d9") if delta>0 else (Color("efddd7") if delta<0 else Color("e9e2d5"))
  stock.border_color=Color("819777") if delta>0 else (Color("b98171") if delta<0 else Color("aaa08f"))
  stock.set_border_width_all(1)
  stock.set_corner_radius_all(8)
  stock.content_margin_left=6.0
  stock.content_margin_right=6.0
  stock.content_margin_top=7.0
  stock.content_margin_bottom=7.0
  panel.add_theme_stylebox_override("panel",stock)
  grid.add_child(panel)
  var label: Label=_copy(host,panel,"%s %s%d" % [field.to_upper(),"+" if delta>=0 else "",delta],"PromotionDelta_"+field,16)
  label.autowrap_mode=TextServer.AUTOWRAP_OFF
  label.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
  label.add_theme_color_override("font_color",Color("254d2f") if delta>0 else (Color("843c2c") if delta<0 else Color("625b50")))
  label.mouse_filter=Control.MOUSE_FILTER_IGNORE
  label.focus_mode=Control.FOCUS_NONE
  label.set_meta("field",field)
  label.set_meta("before",int(before.get(field,0)))
  label.set_meta("after",int(after.get(field,0)))
  label.set_meta("delta",delta)

static func _toggle_radio_details(host, body: Control, key: String, receipt_context: bool) -> void:
 if not is_instance_valid(host) or not is_instance_valid(body):return
 if not body.is_inside_tree():return
 var button: Button=body.get_parent().get_node_or_null("PromotionDetailsAction") as Button
 if button==null:return
 if not host.is_inside_tree() or not host.is_visible_in_tree() or bool(host.busy) or is_instance_valid(host._live_dialog):return
 if str(host.page)!="recording":return
 if receipt_context:
  if not bool(host.receipt_open) or str(host.receipt.get("verb",""))!="radio":return
 elif bool(host.receipt_open) or str(host.recording_mode)!="radio":return
 body.visible=not body.visible
 host.set_meta(key,body.visible)
 button.text="HIDE DETAILS" if body.visible else "DETAILS  ›"
 button.set_pressed_no_signal(body.visible)

static func _radio_details(host, parent: Node, session: Dictionary, context: String) -> VBoxContainer:
 var key: String="radio_details_"+context+"_"+Rules.fingerprint(session)
 var opened: bool=bool(host.get_meta(key)) if host.has_meta(key) else false
 var body: VBoxContainer=host._box(10)
 body.name="PromotionDetailsBody"
 body.mouse_filter=Control.MOUSE_FILTER_PASS
 body.visible=opened
 # No page rerender, model resolver, save, focus replacement or hidden-note
 # animation: the native48px disclosure changes this one existing container.
 var button: Button=_button(host,parent,"HIDE DETAILS" if opened else "DETAILS  ›","PromotionDetailsAction",_toggle_radio_details.bind(host,body,key,context=="receipt"))
 button.toggle_mode=true
 button.set_pressed_no_signal(opened)
 parent.add_child(body)
 return body

static func _radio(host, parent: Node, compact: bool) -> void:
 RadioDesk.render(host,parent,compact)

static func _radio_dock(host, parent: Node) -> void:
 RadioDesk.dock(host,parent,host.size.x<840 or host.size.x<host.size.y)

static func open_radio(host, id: String, fingerprint: String, index: int) -> void:
 if not _editable(host) or str(host.recording_mode)!="archive":return
 var selected: Dictionary=Promotion.selection(host.game.career,id,fingerprint,index)
 if not bool(selected.get("ok",false)):
  host.notice=str(selected.get("message","Choose a saved released demo."))
  _rerender(host,"RecordingRadio_"+str(index))
  return
 host.promotion_selection={"id":id,"fingerprint":fingerprint,"index":index}
 host.recording_mode="radio"
 host.notice=""
 _rerender(host,"PromotionBackAction" if bool(selected["completed"]) else "PromotionMainAction",true)

static func _radio_receipt(host, parent: Node, compact: bool) -> void:
 var body: VBoxContainer=host._paper(parent,compact)
 var saved: Dictionary=host.receipt
 var session: Dictionary=saved.get("session",{})
 var campaigns: Dictionary=session.get("campaigns",{})
 var radio: Dictionary=campaigns.get("radio",{})
 var response: Dictionary=radio.get("receipt_v1",{})
 _copy(host,body,"RADIO RESPONSE","PromotionHeading",26)
 var summary: String=_radio_summary(response["before"],response["after"]) if not response.is_empty() else "Your local-radio pitch is saved."
 _radio_hero(host,body,compact,summary,true)
 if not response.is_empty():_radio_pills(host,body,response["before"],response["after"],false)
 var details: VBoxContainer=_radio_details(host,body,session,"receipt")
 _copy(host,details,"THE RADIO RESPONSE","RecordingReceiptHeading",16,true)
 _copy(host,details,str(saved.get("title","LOCAL RADIO RESPONSE")),"RecordingReceiptTitle",26)
 _copy(host,details,"DAY %d → %d\n£%d → £%d" % [int(saved.get("day_before",1)),int(saved.get("day_after",1)),int(saved.get("cash_before",0)),int(saved.get("cash_after",0))],"RecordingReceiptFacts")
 _note(details,str(saved.get("text","Saved.")),"PromotionFullResponse")
 for change in saved.get("changes",[]):
  _copy(host,details,"%s  %d → %d" % [str(change["label"]),int(change["before"]),int(change["after"])],"RecordingReceiptChange_"+str(change["label"]))
 if not session.is_empty():_session(host,details,session,compact,-1,false)
 _copy(host,details,"Your record, in your order. Saved sketches can be heard in the Songbook.","RecordingReceiptAudio",16,true)

static func receipt(host, parent: Node, compact: bool) -> void:
 if str(host.receipt.get("verb",""))=="radio":
  RadioDesk.receipt(host,parent,compact)
  return
 var body: VBoxContainer=host._paper(parent,compact)
 var saved: Dictionary=host.receipt
 _copy(host,body,"THE RADIO RESPONSE" if str(saved.get("verb",""))=="radio" else "THE RECORDING JOURNAL","RecordingReceiptHeading",16,true)
 _copy(host,body,str(saved.get("title","DEMO SAVED")),"RecordingReceiptTitle",26)
 _copy(host,body,"DAY %d → %d\n£%d → £%d" % [int(saved.get("day_before",1)),int(saved.get("day_after",1)),int(saved.get("cash_before",0)),int(saved.get("cash_after",0))],"RecordingReceiptFacts")
 _note(body,str(saved.get("text","Saved.")),"CareerReceiptNote",true,bool(host._fresh_receipt))
 for change in saved.get("changes",[]):
  _copy(host,body,"%s  %d → %d" % [str(change["label"]),int(change["before"]),int(change["after"])],"RecordingReceiptChange_"+str(change["label"]))
 var session: Dictionary=saved.get("session",{})
 if not session.is_empty(): _session(host,body,session,compact,-1,false)
 _copy(host,body,"Your record, in your order. Saved sketches can be heard in the Songbook.","RecordingReceiptAudio",16,true)

static func _rerender(host, focus: String, reset_scroll: bool=false) -> void:
 host._pending_focus=focus
 if reset_scroll:
  host._scroll_position=0
  if is_instance_valid(host._scroll): host._scroll.scroll_vertical=0
 host._render()

static func toggle(host, id: String) -> void:
 if not _editable(host) or str(host.recording_mode)!="select": return
 var ids: Array=host.recording_ids.duplicate()
 if ids.has(id): ids.erase(id)
 else:
  if ids.size()>=3 or _find_song(Rules.songs(host.game.career),id).is_empty(): return
  ids.append(id)
 host.recording_ids=ids
 host.notice=""
 _rerender(host,"RecordingSong_"+_key(id))

static func move(host, id: String, delta: int) -> void:
 if not _editable(host) or str(host.recording_mode)!="select" or delta not in [-1,1]: return
 var ids: Array=host.recording_ids.duplicate()
 var index: int=ids.find(id)
 var next: int=index+delta
 if index<0 or next<0 or next>=ids.size(): return
 ids[index]=ids[next]
 ids[next]=id
 host.recording_ids=ids
 host.notice=""
 _rerender(host,"RecordingSong_"+_key(id))

static func mode(host, value: String) -> void:
 if not _editable(host) or value not in ["select","archive"]: return
 host.recording_mode=value
 host.notice=""
 _rerender(host,"RecordingSelectAction" if value=="archive" else "RecordingMainAction",true)

static func commit(host, verb: String, id: String="", expected_fingerprint: String="", expected_index: int=-1) -> void:
 # The former instant radio callable is never a paid visit shortcut.
 if verb=="radio":return
 if not _editable(host): return
 if host.game==null or host.opening_owner==null: return
 if verb=="record" and str(host.recording_mode)!="select": return
 if verb=="release" and str(host.recording_mode)!="archive": return
 if verb=="radio":
  if str(host.recording_mode)!="radio":return
  var chosen: Dictionary=host.promotion_selection
  if str(chosen.get("id",""))!=id or str(chosen.get("fingerprint",""))!=expected_fingerprint or int(chosen.get("index",-1))!=expected_index:return
 if not bool(host._finance_guard()): return
 # OWN INPUT BEFORE synchronous pure dispatch; success leaves busy until root Beat.
 host.busy=true
 var before: Dictionary=host.game.career.duplicate(true)
 var candidate: Dictionary=before.duplicate(true)
 var result: Dictionary
 if verb=="record": result=Rules.record(candidate,host.recording_ids.duplicate())
 elif verb=="release": result=Rules.release(candidate,id,expected_fingerprint,expected_index)
 elif verb=="radio": result=Promotion.launch(candidate,id,expected_fingerprint,expected_index)
 else: result={"ok":false,"message":"Unknown recording action."}
 if not bool(result.get("ok",false)) or not result.get("state",null) is Dictionary:
  host.busy=false
  host.notice=str(result.get("message","This recording action is unavailable."))
  host._render()
  return
 # Rules already applied Finance exactly once. Never account this again here.
 host.game.career=result["state"]
 if not bool(host.opening_owner.save_draft()):
  host.game.career=before
  host.busy=false
  host.notice="The recording change could not be saved. Your previous band state is retained."
  host._render()
  return
 host.notice=""
 host._recording_present(result,before,verb)
