import sys
from fontTools.ttLib import TTFont
from fontTools.varLib import instancer
A=sys.argv[1]+'/assets/'; OUT=sys.argv[2]
def rename(f, family, style, ps):
    n=f['name']
    for rec in list(n.names):
        if rec.nameID in (1,2,3,4,6,16,17,25): n.removeNames(nameID=rec.nameID)
    for pid,eid,lid in ((3,1,0x409),(1,0,0)):
        n.setName(family,1,pid,eid,lid); n.setName(style,2,pid,eid,lid)
        n.setName(f'{family} {style}',4,pid,eid,lid); n.setName(ps,6,pid,eid,lid); n.setName(ps,3,pid,eid,lid)
def var(src, family, psbase, weights):
    for w,style in weights:
        f=TTFont(A+src); f.flavor=None
        inst=instancer.instantiateVariableFont(f,{'wght':w})
        for t in ('STAT',):
            if t in inst: del inst[t]
        inst['OS/2'].usWeightClass=w
        rename(inst,family,style,f'{psbase}-{style}')
        inst.save(f'{OUT}/{psbase}-{style}.ttf'); print(psbase,style)
var('inter-latin-wght-normal-Dx4kXJAl.woff2','Inter','Inter',[(400,'Regular'),(500,'Medium'),(600,'SemiBold'),(700,'Bold')])
var('space-grotesk-latin-wght-normal-BhU9QXUp.woff2','Space Grotesk','SpaceGrotesk',[(500,'Medium'),(600,'SemiBold'),(700,'Bold')])
for w,style,src in [(700,'Bold','big-shoulders-display-latin-700-normal-KM2fueoL.woff2'),(800,'ExtraBold','big-shoulders-display-latin-800-normal-DDUD9Xuh.woff2'),(900,'Black','big-shoulders-display-latin-900-normal-CW8trzgu.woff2')]:
    f=TTFont(A+src); f.flavor=None
    rename(f,'Big Shoulders Display',style,f'BigShouldersDisplay-{style}')
    f.save(f'{OUT}/BigShouldersDisplay-{style}.ttf'); print('BSD',style)
