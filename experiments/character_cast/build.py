#!/usr/bin/env python3
"""Import exact approved casting art and author additive fictional recruitment data.
No production scenes, existing character records or saves are modified.
"""
import hashlib, itertools, json, pathlib, urllib.request
from PIL import Image
ROOT=pathlib.Path(__file__).resolve().parents[2]
OUT=ROOT/'Art/References/ApprovedCast20261029'
DATA=ROOT/'Data/CharacterCast'
SHA='52968f3fd0d2cc9b1b477088421921b771a30e62445bd2ad88b87929f809327f'
# Scores, histories and personalities are authored fiction, not inferred from faces.
ROWS=[
('jack','Jack','Guitarist',[6,6,5,6,4,6],8,8,'Steady','Sheffield','First committed band after playing rhythm guitar with friends.','Steady supporting parts; listens to the singer.','Needs encouragement to suggest new parts.'),
('maya','Maya','Singer',[7,6,6,7,6,4],8,8,'Thoughtful','Bristol','Open-mic singer with a first notebook of songs.','Warm melodic instinct and encouraging rehearsals.','Lyrics and stage confidence need development.'),
('ellis','Ellis','Drummer',[5,6,4,5,4,6],9,8,'Dependable','Leeds','First proper band after learning with college friends.','Prepared, consistent simple grooves.','Fast fills and unfamiliar time signatures need practice.'),
('zoe','Zoe','Bassist',[6,7,6,7,5,6],7,7,'Independent','Glasgow','DIY-show regular building basslines around the vocal.','Punchy hooks without filling every gap.','Can dig in when asked to simplify a favourite part.'),
('dan','Dan','Keyboardist',[5,5,6,5,5,3],8,8,'Thoughtful','Manchester','Bedroom demo-maker trying a first live band.','Useful textures and patient listening.','Live patch changes and stage presence are untested.'),
('ryan','Ryan','Guitarist',[6,7,7,8,6,5],9,9,'Steady','Cardiff','Acoustic songwriter moving into an electric band.','Timing, feel and space for other players.','Less comfortable with flashy high-speed leads.'),
('lily','Lily','Singer',[8,7,8,8,8,5],7,6,'Driven','Liverpool','Strong live voice from small local support slots.','Distinctive tone and convincing delivery.','Pushes for immediate takes when others need preparation.'),
('marcus','Marcus','Drummer',[8,8,6,9,7,7],9,9,'Dependable','Birmingham','Experienced in local funk and rock projects, not a touring veteran.','Pocket, listening and adapting to others.','Dislikes last-minute set changes without a run-through.'),
('ben','Ben','Bassist',[5,5,4,5,4,5],8,8,'Steady','Nottingham','New bassist moving over from bedroom guitar.','Affordable, enthusiastic and receptive to feedback.','Can lose the groove during unfamiliar runs.'),
('freya','Freya','Keyboardist',[6,7,8,7,7,5],8,7,'Creative','Brighton','Home recordings made with a second-hand keyboard.','Inventive harmonies and atmospheric arrangements.','Needs a clear brief to avoid endless sound experiments.'),
('arjun','Arjun','Guitarist',[8,7,9,8,8,6],8,8,'Creative','Leicester','Rehearsal-room guitarist with a broad listening habit.','Original voicings and versatile supporting parts.','Sometimes overcomplicates a direct song.'),
('nina','Nina','Singer',[6,5,6,4,7,3],9,9,'Dependable','Newcastle','First band after singing with friends and at open mics.','Warmth, patience and a good ear for harmony.','Quiet on stage; original lyrics still developing.'),
('tom','Tom','Guitarist',[5,5,5,5,4,4],8,9,'Thoughtful','Bristol','Bedroom player learning how a band fits together.','Listens well and improves with specific feedback.','Needs preparation before exposed lead parts.'),
('casey','Casey','Drummer',[6,6,7,5,5,8],7,6,'Restless','Sheffield','Small punk shows shaped an energetic but rough style.','Energy and imaginative accents.','Can rush quiet passages when excited.'),
('hannah','Hannah','Bassist',[7,8,6,9,8,6],9,8,'Steady','Reading','Small soul and indie sets with several groups of friends.','Feel, timing and economical choices.','Waits for others to start creative discussion.'),
('oscar','Oscar','Keyboardist',[9,8,7,8,9,6],8,7,'Perfectionist','Bath','Technically trained player starting to write with a band.','Harmony, versatility and fast arrangement learning.','Needs reminding when a simple part is enough.'),
('bex','Bex','Guitarist',[10,9,10,9,8,10],5,2,'Combative','Leeds','Fictional wildcard: gifted DIY guitarist whose last two bands ended over creative arguments.','Exceptional technique, original riffs and fearless presence.','Challenges arrangements publicly and resists compromise; talent does not excuse poor teamwork.'),
('sam','Sam','Singer',[9,10,9,10,8,9],3,3,'Unpredictable','Manchester','Fictional wildcard: magnetic open-mic frontperson with songs stronger than rehearsal habits.','Unusual phrasing, striking lyrics and room-filling presence.','Late preparation and defensiveness under pressure undermine trust; needs clear boundaries.')]
ROLES=['Singer','Guitarist','Bassist','Keyboardist','Drummer']
VOCAL=['Tone','Originality','Character','Presence','Soulfulness','Lyricism']
INSTRUMENT=['Technique','Timing','Originality','Feel','Versatility','Presence']
XS=[(14,254),(279,505),(530,758),(786,1008),(1036,1266),(1290,1520)]
YS=[(16,242),(351,579),(693,921)]
AGES=[22,23,21,24,22,26,25,27,21,24,26,22,21,23,26,27,25,24]
def digest(raw): return hashlib.sha256(raw).hexdigest()
def main():
 OUT.mkdir(parents=True,exist_ok=True);(OUT/'previews').mkdir(exist_ok=True);DATA.mkdir(parents=True,exist_ok=True)
 source=OUT/'approved_cast_reference.png'
 if not source.exists():
  transfer=json.loads((DATA/'source_transfer.json').read_text())
  assert transfer['sha256']==SHA
  url=transfer['url'];assert url.startswith('https://') and '.oaiusercontent.com/' in url
  print('::add-mask::'+url,flush=True)
  with urllib.request.urlopen(url,timeout=45) as response: raw=response.read(5000001)
  assert len(raw)<5000000 and digest(raw)==SHA,'Unexpected source bytes; refuse import'
  source.write_bytes(raw)
 assert digest(source.read_bytes())==SHA
 image=Image.open(source);assert image.size==(1536,1024) and image.format=='PNG'
 people=[];images=[]
 for i,row in enumerate(ROWS):
  slug,name,role,stats,reliability,collaboration,personality,town,story,strength,friction=row
  cid='cast_'+slug;x0,x1=XS[i%6];y0,y1=YS[i//6];box=[x0,y0,x1,y1]
  preview=OUT/'previews'/(cid+'.png');image.crop(box).save(preview)
  person=dict(id=cid,name=name,gender='Not specified',age=AGES[i],town=town,roles=[role],primary_role=role,
   vocal=stats if role=='Singer' else [],instrument=stats if role!='Singer' else [],talent_cost=sum(stats),
   reliability=reliability,collaboration=collaboration,personality=personality,
   trouble='High' if slug in ('bex','sam') else ('Low' if min(reliability,collaboration)>=8 else 'Medium'),
   wildcard=slug in ('bex','sam'),bands=1 if slug not in ('bex','sam') else 2,experience_years=2+i%5,
   story=story,strength=strength,friction=friction,ambition='Build an original band and earn a first proper following.',
   rehearsal_risk={'missed_preparation':max(0,7-reliability),'creative_friction':max(0,7-collaboration)},
   portrait_preview='res://Art/References/ApprovedCast20261029/previews/'+cid+'.png',source_card_index=i,preview_crop=box,
   portrait_stage='approved_contact_sheet_preview_not_production_master')
  people.append(person)
  images.append({'id':cid,'file':str(preview.relative_to(ROOT)),'dimensions':[x1-x0,y1-y0],'crop':box,'sha256':digest(preview.read_bytes()),'upscaled':False,'production_master':False})
 data={'schema_version':1,'cast_id':'approved-natural-cast-2026-10-29','source_sha256':SHA,'source_dimensions':[1536,1024],
  'source_type':'AI-generated fictional casting contact sheet','approval':{'casting_reference':True,'individual_production_masters':False,'game_balance':False},
  'role_order':ROLES,'stats_scale':[1,10],'vocal_labels':VOCAL,'instrument_labels':INSTRUMENT,
  'behaviour_labels':{'reliability':'1 unreliable to 10 dependable','collaboration':'1 resistant to compromise to 10 cooperative'},
  'balance_note':'Authored fictional design scores, not measured traits. Music cost uses existing catalogue sum; unchanged 200 talent and fifth-member overhead. No trouble discount. Musical Character is separate from cooperation.',
  'integration_note':'Additive adapter only. Existing canonical IDs and saves unchanged. rehearsal_risk is exposed data, not an already integrated penalty in existing gameplay.','people':people}
 (DATA/'approved_cast_2026-10-29.json').write_text(json.dumps(data,indent=2)+'\n')
 manifest={'schema_version':1,'source':{'file':str(source.relative_to(ROOT)),'sha256':SHA,'dimensions':[1536,1024],'type':'Chat image-generated fictional reference','generator_id':'a047c285-dc09-4cde-aaf4-5c3f5c1b5a9e','rights_basis':'Owner-directed generation and explicit permission to import this output; no CC0, real-photography, model-release or exclusive-copyright claim.'},'owner_approved_reference':True,'owner_approved_production_masters':False,'derivatives':images,'usage':'Reference and small casting previews only. Baked card text/icons excluded. Do not use whole collage as interface, enlarge crops into claimed high-resolution masters or silently recast existing canonical characters.'}
 (OUT/'MANIFEST.json').write_text(json.dumps(manifest,indent=2)+'\n')
 (OUT/'README.md').write_text('# Approved cast reference / preview derivatives\n\nThe owner approved this generated fictional cast and authorised import. The original is a 1536x1024 contact sheet, NOT eighteen independent portrait masters. Eighteen unscaled, label-free crops are retained solely for casting previews. They are 222-240 pixels wide; do not enlarge them into full-screen character art. See MANIFEST.json for source hashes, crop rectangles and rights limitations.\n\nScores and behaviours are separate authored game data in Data/CharacterCast. No personality has been inferred from an image. Production scenes and existing Alex/Nia identities are unchanged.\n')
 affordable=[]
 for band in itertools.product(*[[p for p in people if p['primary_role']==r] for r in ROLES]):
  cost=sum(p['talent_cost'] for p in band)+6
  if cost<=200:affordable.append((cost,[p['id']for p in band]))
 assert len(people)==18 and len({p['id']for p in people})==18
 assert len({p['primary_role']for p in people})==5
 assert all(len(p['vocal']or p['instrument'])==6 and all(type(v)==int and 1<=v<=10 for v in (p['vocal']or p['instrument'])) for p in people)
 assert all(max(p['talent_cost']for p in people if p['primary_role']==r)-min(p['talent_cost']for p in people if p['primary_role']==r)>=12 for r in ROLES)
 assert len({x['sha256']for x in images})==18
 assert len(affordable)==274 and min(x[0]for x in affordable)==152
 lines=['# Approved cast: provisional gameplay scores','', 'All music scores are 1-10. Cost is the sum of six scores under existing rules. Behaviour is authored separately, never inferred from appearance. The 200-talent budget and +6 overhead for five members are unchanged.','', '| Role | Character | Six music scores | Talent cost | Reliability /10 | Collaboration /10 | Profile |','|---|---|---|---:|---:|---:|---|']
 for role in ROLES:
  for p in sorted((p for p in people if p['primary_role']==role),key=lambda p:p['talent_cost']):
   lines.append('| '+role+' | '+p['name']+' | '+', '.join(map(str,p['vocal']or p['instrument']))+' | '+str(p['talent_cost'])+' | '+str(p['reliability'])+' | '+str(p['collaboration'])+' | '+('High-talent wildcard' if p['wildcard'] else p['personality'])+' |')
 lines+=['','Vocal order: '+', '.join(VOCAL)+'.','Instrument order: '+', '.join(INSTRUMENT)+'.','', '**Bex:** 56 talent, collaboration 2/10, reliability 5/10. Outstanding guitarist who resists compromise.','**Sam:** 55 talent, collaboration 3/10, reliability 3/10. Exceptional singer with preparation and trust risks. This is cast_sam, NOT canonical sam/Sam Clarke.','', 'Balance check: 274 of 540 one-per-role lineups fit 200 talent, cheapest 152 including the five-member overhead. Maya + Jack + Zoe + Dan + Casey costs 178; Sam + Tom + Ben + Dan + Ellis costs 176; Nina + Bex + Ben + Dan + Ellis costs 180. Five-role Bex AND Sam plus the cheapest others costs 204: a deliberate trade-off, not two automatic picks.','', 'These are initial design values, not a completed balance playtest. Reliability/friction descriptors are available to the overnight playable adapter but are not claimed active in the existing career systems.','', 'Canonical recruitment data, controls, portraits, main and production saves remain unchanged. See experiments/character_cast/catalogue.gd for an opt-in adapter.']
 (DATA/'SCORES.md').write_text('\n'.join(lines)+'\n')
 (DATA/'VALIDATION.json').write_text(json.dumps({'people':18,'roles':{r:sum(p['primary_role']==r for p in people)for r in ROLES},'unique_preview_hashes':18,'affordable_five_role_lineups':len(affordable),'total_five_role_lineups':540,'minimum_five_role_cost':152,'source_sha256':SHA,'production_masters':False},indent=2)+'\n')
 print('Approved source verified; 18 unique preview derivatives; 274/540 affordable five-role lineups.')
if __name__=='__main__':main()
