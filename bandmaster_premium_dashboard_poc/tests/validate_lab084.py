"""Lab08.4 image and source validation. Does not claim Godot runtime testing."""
from pathlib import Path
from PIL import Image
import numpy as np, hashlib
ROOT=Path(__file__).resolve().parents[1]
A=ROOT/'assets'
s=(ROOT/'studio_control.gd').read_text()
assert 'FOCUS_SEGMENTS: int = 27' in s and 'BUZZ_SEGMENTS: int = 23' in s
assert 'range(expected_segments)' in s and 'range(lit_count)' in s
for kind,count,centre in [('focus',27,(215,221)),('buzz',23,(220,218))]:
    base=Image.open(A/f'{kind}_ring_off.png').convert('RGBA')
    state=[]; hashes=set()
    yy,xx=np.mgrid[:base.height,:base.width]
    radial=np.hypot(xx-centre[0],yy-centre[1])
    for i in range(count):
        p=A/f'{kind}_led_{i:02d}.png'
        assert p.exists(),p
        layer=Image.open(p).convert('RGBA')
        assert layer.size==base.size
        alpha=np.asarray(layer)[:,:,3]
        assert (alpha>100).sum()>40,(kind,i)
        assert (alpha[radial<112]>80).sum()==0,(kind,i,'spill onto knob')
        assert (alpha[radial>160]>100).sum()==0,(kind,i,'spill beyond indicator arc')
        sha=hashlib.sha256(p.read_bytes()).hexdigest()
        assert sha not in hashes,(kind,i,'duplicate LED')
        hashes.add(sha);state.append(layer)
    compositions=[]
    for pct in (0,50,100):
        pic=base.copy()
        for layer in state[:round(count*pct/100)]:pic.alpha_composite(layer)
        compositions.append(np.asarray(pic.convert('RGB'),dtype=np.float32))
    delta1=np.abs(compositions[1]-compositions[0]).sum()
    delta2=np.abs(compositions[2]-compositions[1]).sum()
    assert delta1>10000 and delta2>10000,(kind,delta1,delta2)
    print('PASS',kind,count,'aligned indicators; no knob or bezel spill; 0/50/100 distinct')
print('PASS Lab08.4 static controls')
