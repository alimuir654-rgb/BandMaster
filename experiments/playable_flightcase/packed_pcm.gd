extends RefCounted
## Lossless transport only. Return the original 48kHz stereo PCM16 interface.
## A present corrupt package fails closed; never silently use another recording.
const SUFFIX := ".pcmz"
const MAX_FRAMES := 48000*30

static func exists(path: String) -> bool:
 return FileAccess.file_exists(path+SUFFIX) or ResourceLoader.exists(path)

static func stream(path: String,frames: int,expected_pcm: String,expected_source: String="") -> AudioStreamWAV:
 if not FileAccess.file_exists(path+SUFFIX):return load(path) as AudioStreamWAV
 return decode(FileAccess.get_file_as_bytes(path+SUFFIX),frames,expected_pcm,expected_source)

static func decode(blob: PackedByteArray,frames: int,expected_pcm: String,expected_source: String="") -> AudioStreamWAV:
 if frames<=0 or frames>MAX_FRAMES or blob.size()<113 or blob.size()>MAX_FRAMES*4+4096:return null
 if blob.slice(0,4).get_string_from_ascii()!="BMP1" or blob.decode_u32(4)!=frames or blob.decode_u32(8)!=48000 or blob.decode_u16(12)!=2 or blob.decode_u16(14)!=1:return null
 if expected_pcm.length()!=64 or blob.slice(16,48).hex_encode()!=expected_pcm:return null
 if not expected_source.is_empty() and (expected_source.length()!=64 or blob.slice(80,112).hex_encode()!=expected_source):return null
 var payload: PackedByteArray=blob.slice(112)
 var hash:=HashingContext.new();hash.start(HashingContext.HASH_SHA256);hash.update(payload)
 if hash.finish()!=blob.slice(48,80):return null
 var lanes: PackedByteArray=payload.decompress(frames*4,FileAccess.COMPRESSION_DEFLATE)
 if lanes.size()!=frames*4:return null
 var pcm:=PackedByteArray();pcm.resize(frames*4)
 var left:=0;var right:=0;var count:=frames*2
 for frame in range(frames):
  var i:=frame*2
  left=(left+int(lanes[i])+(int(lanes[count+i])<<8))&65535
  right=(right+int(lanes[i+1])+(int(lanes[count+i+1])<<8))&65535
  pcm.encode_u16(frame*4,left);pcm.encode_u16(frame*4+2,right)
 hash.start(HashingContext.HASH_SHA256);hash.update(pcm)
 if hash.finish().hex_encode()!=expected_pcm:return null
 var wav:=AudioStreamWAV.new();wav.format=AudioStreamWAV.FORMAT_16_BITS
 wav.mix_rate=48000;wav.stereo=true;wav.loop_mode=AudioStreamWAV.LOOP_DISABLED;wav.data=pcm
 return wav
