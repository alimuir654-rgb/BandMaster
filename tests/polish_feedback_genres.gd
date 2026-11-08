extends "res://tests/polish_feedback_visual.gd"
const Base=preload("res://experiments/character_cast/vendor/recruitment_catalogue_v3.gd")

func run() -> void:
 owner=Owner.new();check(owner.begin_new(),"isolated genre fixture")
 await mount()
 for genre in Base.genres():
  await tap("Genre_"+str(genre).replace(" ","_").replace("/","_"))
  var press=scene.find_child("GenrePress",true,false)
  check(press.get_meta("genre")==genre,"actual selected genre "+genre)
  var cue: Label=press.find_child("GenreListeningCue",true,false)
  check(cue!=null and not cue.text.is_empty(),"authored listening cue "+genre)
  var image: TextureRect=press.find_child("GenreArtwork",true,false) as TextureRect
  check(image!=null and image.texture!=null,"registered real genre illustration "+genre)
  var next: Button=scene.find_child("GenreNextAction",true,false)
  check(next.get_viewport_rect().encloses(next.get_global_rect()),"fixed decision visible "+genre)
  var saved: Dictionary=owner.snapshot()
  if genre=="Indie rock":
   await tap("GenreHearA");check(press._audio.playing,"recorded idea plays")
   await tap("GenreStopRecorded")
  elif genre in ["Punk","Post-punk"]:
   check(not press._audio.playing,"genre selection never autoplays "+genre)
   await tap("AuditionAudioPlay");check(press._audio.playing,"original registered genre player "+genre)
   await tap("AuditionAudioStop")
  else:
   check(press.find_child("GenreAudioUnavailable",true,false)!=null and press._audio==null,"honest sound brief without invented audio "+genre)
  check(owner.snapshot()==saved,"listening remains free "+genre)
  if genre in ["Indie rock","Punk","Post-punk","Shoegaze"]:await capture("genre-"+genre.replace(" ","-"))
 finish()
