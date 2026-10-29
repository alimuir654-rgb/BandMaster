#!/usr/bin/env python3
"""C21 source-backed frame derivatives. Original controls/meters are immutable.
Uses existing Lab07 hardware and inherited paper, not mockup crops.
Relief, perforations and print rules are authored details, not photographic claims.
"""
from __future__ import annotations
import argparse, hashlib, json
from pathlib import Path
from PIL import Image, ImageDraw, ImageEnhance, ImageFilter

def sha(p): return hashlib.sha256(Path(p).read_bytes()).hexdigest()
def nine(im,size,m):
    im=im.convert('RGBA');w,h=im.size;W,H=size
    assert min(w,h,W,H)>2*m
    out=Image.new('RGBA',size);xs=[0,m,w-m,w];ys=[0,m,h-m,h];dx=[0,m,W-m,W];dy=[0,m,H-m,H]
    for y in range(3):
        for x in range(3):
            part=im.crop((xs[x],ys[y],xs[x+1],ys[y+1])).resize((dx[x+1]-dx[x],dy[y+1]-dy[y]),Image.Resampling.LANCZOS)
            out.paste(part,(dx[x],dy[y]))
    return out
def tile(im,size):
    out=Image.new('RGBA',size)
    for y in range(0,size[1],im.height):
        for x in range(0,size[0],im.width):out.paste(im,(x,y))
    return out
def shadow(layer,blur=3,alpha=55,dy=3):
    a=layer.getchannel('A').point(lambda v:round(v*alpha/255)).filter(ImageFilter.GaussianBlur(blur))
    s=Image.new('RGBA',layer.size,(17,15,12,0));s.putalpha(a)
    out=Image.new('RGBA',layer.size);out.alpha_composite(s,(0,dy));out.alpha_composite(layer);return out
def sheet(out,texture,box,radius=2,edge=(151,133,102,170)):
    x,y,X,Y=box;mask=Image.new('L',(X-x,Y-y));d=ImageDraw.Draw(mask)
    d.rounded_rectangle((0,0,X-x-1,Y-y-1),radius,fill=255)
    p=tile(texture,(X-x,Y-y));p.putalpha(mask);out.alpha_composite(p,(x,y));d=ImageDraw.Draw(out)
    d.rounded_rectangle((x,y,X-1,Y-1),radius,outline=edge,width=1)
    d.line((x+3,y+1,X-4,y+1),fill=(255,255,245,160),width=1)
def main():
    ap=argparse.ArgumentParser();ap.add_argument('--root',type=Path,required=True);a=ap.parse_args();root=a.root;art=root/'art'
    originals={str(p.relative_to(root)):sha(p) for p in art.glob('*.png') if p.name.startswith(('control_','passive_meter_'))}
    src={n:Image.open(art/n).convert('RGBA') for n in ['paper_surface.png','case_surface.png','frame_flightcase_previous.png','frame_notepaper_previous.png','frame_flightcase_inset.png']}
    paper=src['paper_surface.png'];case=src['case_surface.png']
    hardware=src['frame_flightcase_previous.png'].resize((256,192),Image.Resampling.LANCZOS)
    metal=src['frame_flightcase_previous.png'].crop((45,9,465,27))
    presets={'panel':(448,300),'inset':(384,156),'portrait':(300,380),'ticket':(384,128),'header':(448,100),'modal':(448,300)}
    margins={'panel':[28,32,28,28],'inset':[22,22,22,22],'portrait':[32,38,32,42],'ticket':[40,30,30,30],'header':[36,30,36,26],'modal':[32,48,32,32]}
    content={'panel':[28,34,28,28],'inset':[24,24,24,24],'portrait':[34,40,34,44],'ticket':[42,18,30,18],'header':[38,24,38,20],'modal':[34,48,34,30]}
    records=[]
    for look in ['flightcase','notepaper']:
      for kind,(W,H) in presets.items():
        out=Image.new('RGBA',(W,H));d=ImageDraw.Draw(out)
        if look=='flightcase':
          if kind in ['panel','modal']:
            out=nine(hardware,(W,H),22)
            out.alpha_composite(tile(ImageEnhance.Brightness(case).enhance(.78),(W-44,H-44)),(22,22))
            d=ImageDraw.Draw(out);d.rounded_rectangle((22,22,W-23,H-23),3,outline=(74,79,78,255),width=1)
            if kind=='modal':
              out.alpha_composite(metal.resize((W-68,15),Image.Resampling.LANCZOS),(34,24))
              d.line((34,40,W-35,40),fill=(213,161,77,210),width=2)
          elif kind=='portrait':
            out=nine(hardware,(W,H),22)
            out.alpha_composite(tile(ImageEnhance.Brightness(case).enhance(.55),(W-52,H-58)),(26,26))
            d=ImageDraw.Draw(out);d.rectangle((27,27,W-28,H-32),outline=(10,12,14,255),width=3)
            d.line((34,H-29,W-35,H-29),fill=(157,126,81,255),width=2)
          elif kind=='inset':
            out=nine(src['frame_flightcase_inset.png'],(W,H),18)
            out.alpha_composite(tile(ImageEnhance.Brightness(case).enhance(.62),(W-32,H-30)),(16,15))
            d=ImageDraw.Draw(out);d.rounded_rectangle((15,14,W-16,H-15),4,outline=(72,77,78,255),width=1)
          else:
            sheet(out,ImageEnhance.Brightness(case).enhance(.9),(5,5,W-5,H-6),7,(103,108,107,255))
            d=ImageDraw.Draw(out);d.rounded_rectangle((9,9,W-10,H-11),5,outline=(21,25,27,255),width=2)
            if kind=='header':
              for x in [12,W-24]:out.alpha_composite(hardware.crop((8,8,20,20)),(x,13))
              d.line((34,14,W-35,14),fill=(187,145,78,220),width=2)
            else:
              out.alpha_composite(metal.resize((13,H-24),Image.Resampling.LANCZOS),(12,12))
              for y in range(15,H-15,8):d.line((32,y,32,y+3),fill=(135,139,131,220))
            out=shadow(out,2,48,2)
        else:
          if kind in ['panel','modal']:
            sheet(out,ImageEnhance.Brightness(paper).enhance(.91),(10,12,W-6,H-7))
            sheet(out,paper,(6,6,W-11,H-12));d=ImageDraw.Draw(out)
            d.line((24,27,W-29,27),fill=(143,124,92,95),width=1)
            if kind=='modal':
              fold=ImageEnhance.Color(tile(paper,(W-64,19))).enhance(.5);fold=ImageEnhance.Brightness(fold).enhance(.88)
              out.alpha_composite(fold,(28,10));d.line((28,30,W-37,30),fill=(158,116,57,170),width=2)
          elif kind=='portrait':
            sheet(out,ImageEnhance.Brightness(paper).enhance(.92),(9,9,W-7,H-6))
            sheet(out,ImageEnhance.Brightness(paper).enhance(1.02),(5,5,W-12,H-12))
            d=ImageDraw.Draw(out);d.rectangle((24,26,W-31,H-36),outline=(149,133,106,150),width=1)
            for pts in [[(18,18),(41,18),(18,41)],[(W-25,18),(W-48,18),(W-25,41)],[(18,H-26),(41,H-26),(18,H-49)],[(W-25,H-26),(W-48,H-26),(W-25,H-49)]]:
              d.polygon(pts,fill=(187,166,128,255));d.line(pts[:2],fill=(228,214,187,255),width=1)
          elif kind=='inset':
            sheet(out,paper,(5,5,W-6,H-7),2);d=ImageDraw.Draw(out)
            d.line((17,12,17,H-14),fill=(170,103,83,85),width=1);d.line((24,H-16,W-18,H-16),fill=(135,133,118,70),width=1)
          elif kind=='ticket':
            sheet(out,ImageEnhance.Color(paper).enhance(1.15),(5,5,W-6,H-7),2);d=ImageDraw.Draw(out)
            for y in range(11,H-10,7):d.line((29,y,29,y+2),fill=(149,121,76,150),width=1)
            for x in [5,W-6]:
              for y in [20,H-22]:d.ellipse((x-4,y-4,x+4,y+4),fill=(0,0,0,0))
            d.line((40,12,W-17,12),fill=(178,143,88,110),width=1)
          else:
            sheet(out,ImageEnhance.Brightness(paper).enhance(.95),(6,6,W-7,H-8));d=ImageDraw.Draw(out)
            d.line((22,H-18,W-23,H-18),fill=(143,113,72,130),width=1)
            for x in [10,W-30]:
              tape=ImageEnhance.Brightness(ImageEnhance.Color(paper.crop((0,0,18,26))).enhance(1.5)).enhance(.88)
              out.alpha_composite(tape,(x,3))
          out=shadow(out,2,43,2)
        filename=f'frame_{look}_{kind}_c21.png';p=art/filename;out.save(p);m=margins[kind];c=content[kind]
        records.append({'look':look,'preset':kind,'file':'art/'+filename,'size':[W,H],'mode':'RGBA','nine_slice':m,'content_insets':c,'minimum_size':[max(m[0]+m[2]+1,c[0]+c[2]+48),max(m[1]+m[3]+1,c[1]+c[3]+24)],'sha256':sha(p),'owner_approved':False})
    assert all(sha(root/path)==h for path,h in originals.items()),'Protected artwork changed'
    spec={'schema_version':1,'source_type':'Source-backed digital material compositing; NOT newly photographed hardware or generator output','rights':'Inherited C20 source basis: owner-supplied Lab07/Lab08 image-generated hardware; retained CC0 paper manifest. No additional licence asserted.','source_hashes':{n:sha(art/n) for n in src},'protected_originals':originals,'owner_approved':False,'frames':records}
    (root/'FRAME_STYLES_C21.json').write_text(json.dumps(spec,indent=2)+'\n')
    base=json.loads((root/'MANIFEST.json').read_text());base['c21_frame_styles']=spec;base['frame_presets']=list(presets);(root/'MANIFEST.json').write_text(json.dumps(base,indent=2)+'\n')
    print('C21:',len(records),'distinct source-backed frame textures;',len(originals),'original controls/meter files unchanged')
if __name__=='__main__':main()
