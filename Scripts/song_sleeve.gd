extends RefCounted
# Read-only, physical song sleeve shared by the writing room and finished-song
# outcome. Every name, date and writing note comes from the saved catalogue.
const UI = preload("res://Scripts/ui_theme.gd")
const NOTE_ICON := "res://Art/UI/Icons/notebook-pen.svg"

static func describe(song: Dictionary, number: int) -> Dictionary:
 var title := str(song.get("title","")).strip_edges()
 if title.is_empty():
  title = "UNTITLED"
 var credits := "WRITING CREDITS NOT RECORDED"
 var credited = song.get("credited_writers",[])
 var legacy_writers = song.get("writers",[])
 if credited is Array and not credited.is_empty():
  var names := PackedStringArray()
  for name in credited:
   if not str(name).strip_edges().is_empty():
    names.append(str(name))
  if not names.is_empty():
   credits = "CREDIT: " + ", ".join(names)
 elif not str(song.get("lead_writer","")).strip_edges().is_empty():
  credits = "LEAD WRITER: " + str(song["lead_writer"])
 elif legacy_writers is Array and not legacy_writers.is_empty():
  var names := PackedStringArray()
  for name in legacy_writers:
   if not str(name).strip_edges().is_empty():
    names.append(str(name))
  if not names.is_empty():
   credits = "WRITERS: " + ", ".join(names)
 var notes: Array[String] = []
 var sessions = song.get("writing_sessions",[])
 if sessions is Array:
  for session in sessions:
   if not session is Dictionary:
    continue
   var parts := PackedStringArray()
   var day := int(session.get("day",0))
   if day > 0:
    parts.append("DAY %d" % day)
   for key in ["leader","idea","form"]:
    var value := str(session.get(key,"")).strip_edges()
    if not value.is_empty():
     parts.append(value)
   if not parts.is_empty():
    notes.append("  /  ".join(parts))
 var day_label := "FINISH DATE NOT RECORDED"
 if int(song.get("written_day",0)) > 0:
  day_label = "FINISHED DAY %d" % int(song["written_day"])
 var quality := "QUALITY NOT RECORDED"
 if song.has("quality"):
  quality = "QUALITY %d / 100" % clampi(int(song["quality"]),0,100)
 var origin := str(song.get("origin","")).strip_edges()
 var arrangement := str(song.get("arrangement","")).strip_edges()
 return {
  "number":maxi(1,number),"title":title,"credits":credits,
  "origin":origin if not origin.is_empty() else "ORIGIN NOT RECORDED",
  "arrangement":arrangement if not arrangement.is_empty() else "ARRANGEMENT NOT RECORDED",
  "quality":quality,"day":day_label,"notes":notes
 }

static func _line(parent: Node, value: String, size: int, colour: Color) -> Label:
 var label := Label.new()
 label.text = value
 label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
 label.add_theme_font_size_override("font_size",size)
 label.add_theme_color_override("font_color",colour)
 parent.add_child(label)
 return label

static func build(parent: Node, song: Dictionary, number: int, genre_id: String = "indie") -> PanelContainer:
 var info := describe(song,number)
 var sleeve := PanelContainer.new()
 sleeve.name = "SongSleeveArtifact"
 sleeve.size_flags_horizontal = Control.SIZE_EXPAND_FILL
 var paper := UI.style(Color("#E9DDC2"),12)
 paper.border_color = Color("#B99563")
 paper.set_border_width_all(3)
 paper.set_content_margin_all(14)
 sleeve.add_theme_stylebox_override("panel",paper)
 parent.add_child(sleeve)
 var body := VBoxContainer.new()
 body.add_theme_constant_override("separation",7)
 sleeve.add_child(body)
 var mark := HBoxContainer.new()
 mark.add_theme_constant_override("separation",9)
 body.add_child(mark)
 if ResourceLoader.exists(NOTE_ICON):
  var icon := TextureRect.new()
  icon.name = "SongSleeveIcon"
  icon.texture = load(NOTE_ICON)
  icon.custom_minimum_size = Vector2(24,24)
  icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
  icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
  icon.modulate = Color("#60462E")
  mark.add_child(icon)
 var overline := _line(mark,"NEW ORIGINAL  /  SONG FINISHED  /  %02d" % int(info["number"]),13,Color("#785B39"))
 overline.size_flags_horizontal = Control.SIZE_EXPAND_FILL
 var art_path := "res://Art/Backgrounds/%s/studio.webp" % genre_id
 if not ResourceLoader.exists(art_path):
  art_path = "res://Art/Backgrounds/shared/studio.webp"
 if ResourceLoader.exists(art_path):
  var art := TextureRect.new()
  art.name = "SongSleeveArt"
  art.texture = load(art_path)
  art.custom_minimum_size.y = 145
  art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
  art.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
  art.mouse_filter = Control.MOUSE_FILTER_IGNORE
  body.add_child(art)
 _line(body,str(info["title"]).to_upper(),24,Color("#241C15"))
 _line(body,str(info["credits"]),15,Color("#60462E"))
 _line(body,str(info["origin"])+"  /  "+str(info["arrangement"]),14,Color("#5E5245"))
 _line(body,str(info["quality"])+"  ·  "+str(info["day"]),14,Color("#785B39"))
 var separator := HSeparator.new()
 body.add_child(separator)
 var notes: Array = info["notes"]
 if notes.is_empty():
  _line(body,"WRITING ROOM  /  SESSION HISTORY NOT RECORDED",14,Color("#785B39"))
 else:
  _line(body,"WRITING ROOM  /  RECORDED SESSIONS",14,Color("#785B39"))
  for note in notes:
   _line(body,str(note),14,Color("#4C4338"))
 return sleeve
