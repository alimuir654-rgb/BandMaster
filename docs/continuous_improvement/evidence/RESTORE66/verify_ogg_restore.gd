extends SceneTree

func pcm_digest(stream):
	var playback = stream.instantiate_playback()
	playback.start(0.0)
	var h = HashingContext.new()
	h.start(HashingContext.HASH_SHA256)
	var frames = 0
	var limit = int(ceil(stream.get_length() * AudioServer.get_mix_rate())) + 4096
	while frames < limit:
		var pcm = playback.mix_audio(1.0, 2048)
		h.update(pcm.to_byte_array())
		frames += pcm.size()
		if pcm.size() < 2048:
			break
	playback.stop()
	return {"sha256":h.finish().hex_encode(),"frames":frames,"within_bound":frames > 0 and frames < limit}

func _initialize():
	var rows = []
	var jobs = JSON.parse_string(FileAccess.get_file_as_string("res://ogg-recovery-jobs.json"))
	for job in jobs:
		var old = load(job.old)
		var restored = AudioStreamOggVorbis.load_from_file(job.restored)
		if old == null or restored == null:
			push_error("Load failure: " + job.path)
			quit(1)
			return
		var packets_equal = old.packet_sequence.get("packet_data") == restored.packet_sequence.get("packet_data")
		var granules_equal = old.packet_sequence.get("granule_positions") == restored.packet_sequence.get("granule_positions")
		var old_pcm = pcm_digest(old)
		var new_pcm = pcm_digest(restored)
		if not packets_equal or not granules_equal or old_pcm != new_pcm or not old_pcm.within_bound or old.get_length() != restored.get_length():
			print(JSON.stringify({"path":job.path,"packets_equal":packets_equal,"granules_equal":granules_equal,"old_pcm":old_pcm,"new_pcm":new_pcm,"old_seconds":old.get_length(),"new_seconds":restored.get_length(),"old_rate":old.packet_sequence.sampling_rate,"new_rate":restored.packet_sequence.sampling_rate,"mix_rate":AudioServer.get_mix_rate()}))
			push_error("Recovered audio differs: " + job.path)
			quit(2)
			return
		rows.append({"path":job.path,"packet_bytes_identical":true,"granules_identical":true,"decoded_PCM_identical":true,"decoded_PCM_sha256":old_pcm.sha256,"decoded_PCM_frames":old_pcm.frames,"seconds":old.get_length(),"mixer_rate":AudioServer.get_mix_rate()})
	var out = FileAccess.open("res://OGG_GODOT_VERIFICATION.json", FileAccess.WRITE)
	out.store_string(JSON.stringify(rows,"  ")+"\n")
	out.close()
	print("RESTORE66_OGG_GODOT " + JSON.stringify({"checked":rows.size(),"all_packet_granule_PCM_equal":true,"listening_verified":false}))
	quit(0)
