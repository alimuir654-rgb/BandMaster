extends RefCounted
## Device audio preference only. Never reads or writes a band/game save.
const PATH := "user://audio_preferences.json"
const MAX_BYTES := 65536

static func _result(muted: bool, persisted: bool, writable: bool, message: String, data: Dictionary = {}) -> Dictionary:
 return {"muted":muted,"persisted":persisted,"writable":writable,"message":message,"data":data}

static func read_settings() -> Dictionary:
 if not FileAccess.file_exists(PATH):
  return _result(false,false,true,"Your audio choice will be remembered on this device.",{"schema_version":1,"muted":false})
 var file:=FileAccess.open(PATH,FileAccess.READ)
 if file==null or file.get_length()>MAX_BYTES:
  return _result(true,false,false,"Saved audio setting unreadable: sound is off this session.")
 var raw: String=file.get_as_text()
 file.close()
 var parser:=JSON.new()
 if parser.parse(raw)!=OK or not parser.data is Dictionary:
  return _result(true,false,false,"Saved audio setting unreadable: sound is off this session.")
 var data: Dictionary=parser.data
 var version: Variant=data.get("schema_version")
 if not typeof(version) in [TYPE_INT,TYPE_FLOAT] or version!=1:
  return _result(true,false,false,"Newer audio setting kept: sound is off this session.")
 if not data.get("muted") is bool:
  return _result(true,false,false,"Saved audio setting unreadable: sound is off this session.")
 return _result(bool(data["muted"]),true,true,"Audio choice remembered on this device.",data)

static func write_muted(muted: bool) -> Dictionary:
 var previous:=read_settings()
 if not previous["writable"]:
  return _result(muted,false,false,"Not saved: applies to this session only.")
 var data: Dictionary=previous["data"].duplicate(true)
 data["schema_version"]=1
 data["muted"]=muted
 var temporary: String=PATH+".tmp"
 var file:=FileAccess.open(temporary,FileAccess.WRITE)
 if file==null:
  return _result(muted,false,true,"Not saved: applies to this session only.")
 file.store_string(JSON.stringify(data,"\t",true,true)+"\n")
 file.flush()
 var error: int=file.get_error()
 file.close()
 if error!=OK or DirAccess.rename_absolute(ProjectSettings.globalize_path(temporary),ProjectSettings.globalize_path(PATH))!=OK:
  return _result(muted,false,true,"Not saved: applies to this session only.")
 return _result(muted,true,true,"Audio choice remembered on this device.",data)
