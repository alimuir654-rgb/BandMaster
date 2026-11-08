extends SceneTree
const Recipe=preload("res://experiments/playable_flightcase/mixing_recipe.gd")
var hash:=HashingContext.new()
var count:=0
func _init() -> void:
 hash.start(HashingContext.HASH_SHA256)
 var brief: Dictionary={"genre":"Indie rock","name_intent":"Raw","vibe":"Unpolished"}
 var recipe: Dictionary=Recipe.recipe(brief)
 if recipe.is_empty():push_error("Invalid legacy fixture");quit(1);return
 for hook in Recipe.HOOKS:
  recipe.hook=hook
  visit(recipe,0)
 print("LEGACY_RECIPE_HASH "+str(count)+" "+hash.finish().hex_encode())
 quit()
func visit(value: Dictionary,axis: int) -> void:
 if axis<Recipe.FIELDS.size():
  for choice in Recipe.VALUES[axis]:
   value[Recipe.FIELDS[axis]]=choice;visit(value,axis+1)
  return
 for stage in range(3):
  value.stage=stage
  for version in ([3,4] if value.hook=="low_riff_v1" else [4]):
   var r: Dictionary=value.duplicate(true);r.version=version
   if version==3:r.erase("voice")
   var offer: Dictionary=Recipe.offer(r,{"candidate_id":"cast_zoe","name":"Zoe","role":"Bassist"})
   var output: Array=[Recipe.valid(r),Recipe.summary(r),Recipe.written(r),Recipe.material(r),offer,Recipe.note({"candidate_id":"cast_zoe"},r,{"day":1}),Recipe._craft_from_context(r,160,3)]
   hash.update(JSON.stringify(output).to_utf8_buffer());count+=1
