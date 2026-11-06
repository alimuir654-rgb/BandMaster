#!/usr/bin/env python3
from pathlib import Path
from hashlib import sha256
import json
root=Path(__file__).resolve().parents[1]
manifest=json.loads((root/'Art'/'References'/'PremiumHardware'/'Lab08_ASSEMBLY_SHA256.json').read_text())
for rel,meta in manifest['files'].items():
 p=root/rel
 assert p.is_file(),f'Missing {rel}'
 assert sha256(p.read_bytes()).hexdigest()==meta['sha256'],f'Hash mismatch {rel}'
print(f"PASS Lab08.4 assembly: {len(manifest['files'])} source files match layered manifest; order exact")
