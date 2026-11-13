extends SceneTree
const Pcm=preload("res://experiments/playable_flightcase/packed_pcm.gd")
var checks:=0
var failures: Array=[]
func _init() -> void:call_deferred("run")
func check(ok: bool,label: String) -> void:
 checks+=1
 if not ok:failures.append(label);push_error(label)
func run() -> void:
 var report: Variant=JSON.parse_string(FileAccess.get_file_as_string("res://pilot51-pcm-inventory.json"))
 var timings: Array=[]
 for row in report:
  var start:=Time.get_ticks_usec()
  var wav: AudioStreamWAV=Pcm.stream(str(row.path),int(row.frames),str(row.pcm_sha256))
  timings.append((Time.get_ticks_usec()-start)/1000.0)
  check(wav!=null,"exact PCM restored "+str(row.path))
  if wav==null:continue
  check(wav.data.size()==int(row.frames)*4 and wav.mix_rate==48000 and wav.stereo and wav.loop_mode==0,"full original timing/stereo/no loop "+str(row.path))
 var row: Dictionary=report[0]
 var blob:=FileAccess.get_file_as_bytes(str(row.path)+Pcm.SUFFIX)
 check(Pcm.decode(blob,int(row.frames)+1,str(row.pcm_sha256))==null,"wrong length refused")
 check(Pcm.decode(blob,int(row.frames),"0".repeat(64))==null,"wrong original PCM identity refused")
 check(Pcm.decode(blob.slice(0,79),int(row.frames),str(row.pcm_sha256))==null,"truncated header refused")
 check(Pcm.decode(blob,int(row.frames),str(row.pcm_sha256),"0".repeat(64))==null,"wrong original WAV container refused")
 var changed:=blob.duplicate();changed[112]^=1
 check(Pcm.decode(changed,int(row.frames),str(row.pcm_sha256))==null,"changed compressed payload refused")
 changed=blob.duplicate();changed.encode_u32(8,44100)
 check(Pcm.decode(changed,int(row.frames),str(row.pcm_sha256))==null,"wrong sample rate refused")
 changed=blob.duplicate();changed.encode_u16(12,1)
 check(Pcm.decode(changed,int(row.frames),str(row.pcm_sha256))==null,"wrong channel count refused")
 check(Pcm.decode(blob,48000*31,str(row.pcm_sha256))==null,"unbounded allocation refused")
 timings.sort()
 print("PILOT51_PCM "+JSON.stringify({"checks":checks,"failures":failures,"files":report.size(),"median_ms":timings[timings.size()/2],"max_ms":timings[-1],"exact_original_PCM":true,"physical_Android":false}))
 quit(0 if failures.is_empty() else 1)
