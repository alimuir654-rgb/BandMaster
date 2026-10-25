extends RefCounted
# Shared genre profiles. Presentation hints are separate from gameplay rules.
const DEFAULT_ID := "indie"
const PROFILES := {
 "indie":{"name":"Indie / Alternative","background":"#0B0E12","panel":"#151D28","surface":"#222E3D","accent":"#FFB020","secondary":"#E2568E","highlight":"#44D9FF","tagline":"Small rooms. Big songs."},
 "punk":{"name":"Punk / Garage","background":"#100D13","panel":"#221624","surface":"#352337","accent":"#F65D8D","secondary":"#F6CA53","highlight":"#81E6CF","tagline":"Make noise. Do it yourself."},
 "metal":{"name":"Metal / Hard Rock","background":"#0D0C10","panel":"#1C1B22","surface":"#302833","accent":"#D85F50","secondary":"#D7B988","highlight":"#B5B2C8","tagline":"Earn the stage."},
 "electronic":{"name":"Electronic / Synth","background":"#0A1020","panel":"#152139","surface":"#213451","accent":"#42D7EF","secondary":"#B26DE5","highlight":"#FFB568","tagline":"Build a new sound."}
}
static func normalize(id: String) -> String:
 return id if PROFILES.has(id) else DEFAULT_ID
static func from_save(save: Dictionary) -> Dictionary:
 var band = save.get("band",{})
 if not band is Dictionary:
  return PROFILES[DEFAULT_ID].duplicate(true)
 return PROFILES[normalize(str(band.get("genre",DEFAULT_ID)))].duplicate(true)
static func all_ids() -> Array:
 return PROFILES.keys()
