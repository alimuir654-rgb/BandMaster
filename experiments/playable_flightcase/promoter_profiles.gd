extends RefCounted
## Fictional venue contacts. Presentation only; original booking rules own terms.
const ART="res://experiments/playable_flightcase/art/feedback47/promoters.png"
const PEOPLE={
 "mo_farrow":{"id":"mo_farrow","name":"Mo Farrow","role":"Independent promoter","detail":"Runs the door, makes the tea, remembers who helped load out.","region":Rect2(0,0,512,760)},
 "jules_okafor":{"id":"jules_okafor","name":"Jules Okafor","role":"DIY night organiser","detail":"Builds mixed bills and gives new bands a proper soundcheck.","region":Rect2(512,0,512,760)},
 "ray_malik":{"id":"ray_malik","name":"Ray Malik","role":"Club booker","detail":"Years behind the bar. A dry welcome and a close ear for the set.","region":Rect2(1024,0,512,760)}
}
const ROOMS={"local":"mo_farrow","bristol":"mo_farrow","cardiff":"jules_okafor","birmingham":"jules_okafor","manchester":"ray_malik","london":"ray_malik"}

static func for_venue(venue: String) -> Dictionary:
 return PEOPLE.get(ROOMS.get(venue,""),{}).duplicate(true)

static func portrait(venue: String) -> Texture2D:
 var p: Dictionary=for_venue(venue)
 if p.is_empty():return null
 var atlas:=AtlasTexture.new();atlas.atlas=load(ART);atlas.region=p.region;atlas.filter_clip=true
 return atlas
