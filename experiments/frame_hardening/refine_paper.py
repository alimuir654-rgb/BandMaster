"""One evidence-led C21 paper finish. Never alters protected source images."""
from pathlib import Path
import hashlib, json
from PIL import Image, ImageDraw, ImageOps, ImageStat

def sha(p): return hashlib.sha256(Path(p).read_bytes()).hexdigest()
def finish(root: Path) -> None:
    spec=json.loads((root/'FRAME_STYLES_C21.json').read_text())
    raw=Image.open(root/'art/paper_surface.png').convert('L')
    mean=ImageStat.Stat(raw).mean[0]
    grain=raw.point(lambda v:max(0,min(255,round(225+(v-mean)*5))))
    fibre=ImageOps.colorize(grain,(118,95,57),(248,243,224)).convert('RGBA')
    tab=ImageOps.colorize(grain,(118,82,37),(228,206,169)).convert('RGBA')
    for record in spec['frames']:
        if record['look']!='notepaper':continue
        p=root/record['file'];im=Image.open(p).convert('RGBA');before=sha(p)
        # Preserve existing edges, drawn rules and alpha; replace only calm paper pixels.
        px=im.load();f=fibre.load();w,h=im.size
        for y in range(h):
            for x in range(w):
                r,g,b,a=px[x,y]
                if a==255 and r>219 and g>212 and b>199:
                    R,G,B,_=f[x%fibre.width,y%fibre.height]
                    px[x,y]=(R,G,B,a)
        if record['preset']=='modal':
            strip=tab.resize((w-64,19),Image.Resampling.LANCZOS)
            im.alpha_composite(strip,(28,10));d=ImageDraw.Draw(im)
            d.line((28,10,w-37,10),fill=(247,233,204,230),width=1)
            d.line((28,29,w-37,29),fill=(156,120,65,170),width=1)
        elif record['preset']=='header':
            for x in [10,w-30]:im.alpha_composite(tab.crop((0,0,18,26)),(x,3))
        elif record['preset']=='portrait':
            for pts in [[(18,18),(41,18),(18,41)],[(w-25,18),(w-48,18),(w-25,41)],[(18,h-26),(41,h-26),(18,h-49)],[(w-25,h-26),(w-48,h-26),(w-25,h-49)]]:
                mask=Image.new('L',im.size);ImageDraw.Draw(mask).polygon(pts,fill=255)
                detail=tab.resize(im.size);detail.putalpha(mask);im.alpha_composite(detail)
        im.save(p);record['pre_finish_sha256']=before;record['sha256']=sha(p)
        record['finish']='Retained paper-fibre luminance contrast and warm contact-stock tint; fixed source-derived tabs; no new photographic claim.'
    spec['paper_finish']='Native review correction: reduce uniformly grey paper parts while retaining quiet readable faces and light shadows.'
    assert all(sha(root/path)==digest for path,digest in spec['protected_originals'].items())
    (root/'FRAME_STYLES_C21.json').write_text(json.dumps(spec,indent=2)+'\n')
    p=root/'MANIFEST.json';manifest=json.loads(p.read_text());manifest['c21_frame_styles']=spec;p.write_text(json.dumps(manifest,indent=2)+'\n')
    print('C21 paper finish: six derivative textures; all original source/control/meter bytes retained')
