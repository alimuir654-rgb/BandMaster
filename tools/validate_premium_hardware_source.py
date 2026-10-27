#!/usr/bin/env python3
"""Validate Lab05/07/08.4 hardware reference intake from project root, standard library only."""
from pathlib import Path
from hashlib import sha256
from collections import Counter
import json, struct, sys
ROOT=Path(__file__).resolve().parents[1]
M=ROOT/'Art/References/PremiumHardware/SOURCE_SHA256_MANIFEST.json'
manifest=json.loads(M.read_text(encoding='utf-8'))
errors=[]
for rel,meta in manifest['paths'].items():
 p=ROOT/rel
 if not p.is_file():errors.append(f'missing: {rel}');continue
 data=p.read_bytes()
 if sha256(data).hexdigest()!=meta['sha256']:errors.append(f'hash mismatch: {rel}')
 if p.suffix.lower()=='.png':
  if data[:8]!=b'\x89PNG\r\n\x1a\n' or data[12:16]!=b'IHDR':errors.append(f'PNG header malformed: {rel}')
  else:
   w,h=struct.unpack('>II',data[16:24])
   if not w or not h:errors.append(f'bad PNG dimensions: {rel}')
root=ROOT/'Art/References/PremiumHardware/Lab08_4_FixOnly/bandmaster_premium_dashboard_poc/assets'
for name,n in [('focus',27),('buzz',23)]:
 actual={p.name for p in root.glob(name+'_led_*.png')}
 want={f'{name}_led_{k:02d}.png' for k in range(n)}
 if actual!=want:errors.append(f'{name} led set missing/extra: {sorted(actual^want)}')
# Lab 08 base plates are NOT included in this patch; expected absence not an error.
assert not (root/'focus_ring_off.png').exists() and not (root/'buzz_ring_off.png').exists(), 'This importer is patch-only; neutral base plates unexpectedly included'
for f in ['premium_controls_lab.gd','premium_controls_lab.tscn']:
 if not (ROOT/'bandmaster_premium_controls_lab'/f).is_file():errors.append('Lab07 testbed missing '+f)
if errors:
 for e in errors:print('ERROR:',e)
 sys.exit(1)
print('OK:',len(manifest['paths']),'source files hash/Png checked; Lab07 lab present; Lab08.4 focus 27 + buzz 23 patch layers verified')
print('P0 remaining: Lab08 original neutral ring base plates and its standalone scenes are not in these fix-only archives')
