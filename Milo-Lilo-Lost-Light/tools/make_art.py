"""Procedurally drawn original 2D game assets; requires Pillow."""
from PIL import Image, ImageDraw, ImageFilter, ImageFont
from pathlib import Path
import random, math
ROOT=Path(__file__).resolve().parents[1]
random.seed(17)
S=4

def ellipse(d,bb,fill,outline=None,width=1): d.ellipse(tuple(int(v*S) for v in bb),fill=fill,outline=outline,width=width*S)
def poly(d,pts,fill): d.polygon([(int(x*S),int(y*S)) for x,y in pts],fill=fill)
def rr(d,bb,r,fill,outline=None,width=1): d.rounded_rectangle(tuple(int(v*S) for v in bb),r*S,fill=fill,outline=outline,width=width*S)
def line(d,pts,fill,width=1): d.line([(int(x*S),int(y*S)) for x,y in pts],fill=fill,width=width*S,joint='curve')

def character(kind,pose):
    im=Image.new('RGBA',(180*S,190*S),(0,0,0,0));d=ImageDraw.Draw(im)
    bear=kind=='lilo'; base='#A7734C' if bear else '#A8B7C5'; dark='#795235' if bear else '#75899B'; inner='#DCB38C' if bear else '#F8BCC6'; scarf='#51B7BA' if bear else '#F7B344'
    # diffuse shadow
    ellipse(d,(32,171,150,184),'#33445250')
    # tail
    ellipse(d,(127,114,162,147),dark)
    # legs run positions
    delta = 10 if pose=='run1' else -10 if pose=='run2' else 0
    ellipse(d,(55+delta,140,88+delta,175),dark);ellipse(d,(100-delta,139,132-delta,175),dark)
    ellipse(d,(48+delta,163,93+delta,177),base);ellipse(d,(96-delta,162,140-delta,177),base)
    # body
    ellipse(d,(45,83,140,160),base);ellipse(d,(65,109,123,150),'#EED8BD' if bear else '#E4EDF3')
    # arms
    handrise= -28 if pose=='attack' else (-9 if pose=='jump' else 0)
    ellipse(d,(26,99+handrise,66,139+handrise),base);ellipse(d,(124,102+handrise,156,140+handrise),base)
    # scarf+ knot
    poly(d,[(56,98),(112,96),(127,111),(76,118)],scarf)
    poly(d,[(111,108),(140,117),(124,136)],scarf)
    # ears
    if bear:
        ellipse(d,(45,22,83,63),dark);ellipse(d,(109,20,148,62),dark)
        ellipse(d,(52,29,77,55),inner);ellipse(d,(117,27,142,55),inner)
    else:
        poly(d,[(63,47),(49,0),(65,3),(90,44)],dark);poly(d,[(102,46),(109,0),(124,0),(123,49)],dark)
        poly(d,[(65,38),(59,9),(69,12),(81,41)],inner);poly(d,[(107,41),(113,11),(120,10),(115,43)],inner)
    # head
    ellipse(d,(35,40,150,119),base)
    # cheek patches
    ellipse(d,(44,86,77,111),'#D5E0EA' if not bear else '#CE9B73')
    ellipse(d,(112,86,145,111),'#D5E0EA' if not bear else '#CE9B73')
    # muzzle
    ellipse(d,(68,79,122,114),'#FAE6D2' if bear else '#F8F9F7')
    # eyes, sheen
    ellipse(d,(68,68,82,89),'#2B3343');ellipse(d,(112,68,126,89),'#2B3343')
    ellipse(d,(72,71,77,76),'white');ellipse(d,(116,71,121,76),'white')
    # rosy
    ellipse(d,(48,88,64,96),'#EBA29B');ellipse(d,(131,88,145,96),'#EBA29B')
    poly(d,[(90,90),(102,90),(96,99)],'#795354' if bear else '#EF879D')
    line(d,[(96,99),(96,104),(87,107)],'#7B5560',2);line(d,[(96,104),(104,106)],'#7B5560',2)
    if not bear:
        rr(d,(87,108,95,118),2,'#FFFFFF');rr(d,(97,108,105,118),2,'#FFFFFF')
    if pose=='hurt':
        line(d,[(69,78),(78,81)],dark,2);line(d,[(114,81),(124,78)],dark,2)
    if pose=='celebrate':
        ellipse(d,(23,64,45,91),base); ellipse(d,(148,62,170,88),base)
    im=im.resize((180,190),Image.Resampling.LANCZOS)
    return im

for c in ['milo','lilo']:
    for p in ['idle','run1','run2','jump','fall','attack','hurt','celebrate']:
        character(c,p).save(ROOT/'assets'/'characters'/f'{c}_{p}.png')

def landscape(theme):
    W,H=1600,900
    themes={
        'meadow':((114,211,242),(234,249,226),'#A9DD97','#66BE84','#45946C'),
        'forest':((79,169,178),(205,240,206),'#89C6A4','#448C7A','#2E6D67'),
        'cave':((39,53,95),(96,104,153),'#6C75A9','#444B7D','#242C58'),
        'night':((19,43,97),(81,81,152),'#606CA5','#3B568E','#233A6B'),
        'lighthouse':((63,96,160),(220,177,184),'#8D8FC2','#5F77AA','#374D87')}
    top,bottom,hill1,hill2,hill3=themes[theme]
    im=Image.new('RGB',(W,H)); pix=im.load()
    for y in range(H):
        t=y/H; c=tuple(int(top[j]*(1-t)+bottom[j]*t) for j in range(3))
        for x in range(W):pix[x,y]=c
    d=ImageDraw.Draw(im,'RGBA')
    # light sun/moon
    if theme in ['night','lighthouse','cave']:
        d.ellipse((1180,80,1320,220),fill=(247,240,203,210))
        for i in range(5):
            random.seed(11+i)
            for _ in range(20):
                x=random.randint(0,W);y=random.randint(30,450);r=random.randint(1,3)
                d.ellipse((x-r,y-r,x+r,y+r),fill=(241,238,252,160))
    else:
        d.ellipse((1180,95,1350,265),fill=(255,251,201,235))
        for i in range(13):
            x=(i*219+80)%W;y=85+(i*77)%260
            d.ellipse((x,y,x+110,y+40),fill=(255,255,255,115))
            d.ellipse((x+30,y-20,x+105,y+34),fill=(255,255,255,115))
    for h,col,offset in [(560,hill1,0),(650,hill2,20),(750,hill3,80)]:
        pts=[(0,H),(0,h)]
        for x in range(0,W+70,70):pts.append((x,h-60*math.sin(x/140+offset)-32*math.sin(x/66+offset)))
        pts.append((W,H));d.polygon(pts,fill=col)
    if theme!='cave':
        for i in range(30):
            x=(i*163+79)%W;y=630+(i*31)%170;sz=28+(i*7)%38
            d.rectangle((x-6,y-10,x+6,y+sz),fill=(37,66,65,130))
            for off in (-30,0,30):d.ellipse((x+off-sz,y-sz*1.5,x+off+sz,y+sz*.3),fill=(40,98,88,130))
    else:
        for i in range(18):
            x=(i*101+38)%W;y=610+(i*13)%180
            d.polygon([(x-18,y),(x,y-100-(i*7)%60),(x+20,y)],fill=(141,185,213,90))
    return im
for t in ['meadow','forest','cave','night','lighthouse']:
    landscape(t).save(ROOT/'assets'/'environments'/f'{t}.jpg',quality=87)

# interface insignia
im=Image.new('RGBA',(256*S,256*S));d=ImageDraw.Draw(im)
ellipse(d,(12,12,244,244),'#154E73');ellipse(d,(21,21,235,235),'#54BEAE');ellipse(d,(33,33,223,223),'#A7EDE5')
for c,x in [('milo',-2),('lilo',91)]:
    char=character(c,'idle').resize((128*S,136*S),Image.Resampling.LANCZOS)
    im.alpha_composite(char,(int((14+x)*S),int(60*S)))
im=im.resize((256,256),Image.Resampling.LANCZOS);im.save(ROOT/'assets'/'ui'/'icon.png')
# icons for onscreen buttons
icons={'left':'◀','right':'▶','up':'▲','down':'▼','jump':'↑','action':'★','switch':'⇄'}
try: font=ImageFont.truetype('/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf',100)
except:font=ImageFont.load_default()
for name,letter in icons.items():
    im=Image.new('RGBA',(160,160),(0,0,0,0));d=ImageDraw.Draw(im)
    d.ellipse((7,7,153,153),fill=(14,53,77,186),outline=(233,249,243,210),width=5)
    d.ellipse((18,18,142,142),outline=(92,215,198,90),width=4)
    d.text((80,73),letter,font=font,anchor='mm',fill=(251,244,217,255))
    im.save(ROOT/'assets'/'ui'/f'{name}.png')
print('Generated original game art')
