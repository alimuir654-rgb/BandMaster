extends "res://experiments/playable_flightcase/gig_soundscape.gd"
## Test-only silent stream for lifecycle assertions. Never a shipping crowd sound.
var use_synthetic_effect:=false
func _allowed() -> bool:
 if not is_inside_tree() or not _context.is_valid():return false
 var view: Dictionary=_context.call();var master: int=AudioServer.get_bus_index("Master")
 return view.get("allowed",false) and view.get("identity","")==event_id and not event_id.is_empty() and not _source_token.is_empty() and view.get("source_token","")==_source_token and master>=0 and not AudioServer.is_bus_mute(master)
func _effect_stream(kind: String) -> AudioStream:
 if not use_synthetic_effect:return super._effect_stream(kind)
 var stream:=AudioStreamWAV.new();stream.format=AudioStreamWAV.FORMAT_16_BITS;stream.mix_rate=48000;stream.stereo=true
 var silent:=PackedByteArray();silent.resize(192000);stream.data=silent
 return stream
