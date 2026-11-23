const fs=require('fs');
const src=fs.readFileSync(process.argv[2],'utf8');
const between=(a,b)=>{const i=src.indexOf(a), k=src.indexOf(b,i); if(i<0||k<0) throw new Error('nf '+a+' '+b); return src.slice(i,k);};
// ---- data + logic
const dataCode=between('function Wn(e)','var Rr = {');
const J={jsx:(t,p)=>({t,p}),jsxs:(t,p)=>({t,p}),Fragment:'frag'};
const env=new Function('j','_', dataCode+`;return {Wn,Gn,Kn,qn,Jn,Yn,Xn,$n,er,nr,rr,Qn,wr,Tr,Er,Dr,Or,kr,Ar,jr,Mr,Nr,Pr,Fr,Ir,Lr,gr,vr,yr,br,xr,Sr};`)(J,{});
const out={
  providers:Object.values(env.Jn), countries:env.Yn, artists:env.Xn,
  tracks:env.$n.map(t=>({...t, explicit:!!t.explicit, discovery:!!t.discovery})),
  albums:env.er, playlists:env.nr, genres:env.rr,
  trendingSearches:env.Mr, defaultRecentSearches:env.Nr, defaultSaved:env.Ir, defaultRecent:env.Lr,
  stories:env.Ar().map(t=>t.id), artStyles:env.Kn, artPalettes:env.qn,
};
fs.writeFileSync(process.argv[3],JSON.stringify(out,null,1));
// ---- test vectors
const tv={};
tv.hash=['slow-orbit','track-ottobre','artist-noor','genre-House',''].map(s=>[s,env.Wn(s)]);
tv.prng=[[1,[]],[123456789,[]],[env.Wn('album-orbit'),[]]].map(([s])=>{const r=env.Gn(s);return [s,[r(),r(),r(),r(),r()]];});
tv.charts=[['GLOBAL','7d'],['IT','7d'],['NG','24h'],['JP','30d']].map(([c,w])=>({country:c,window:w,entries:env.wr(c,w,20).map(e=>({id:e.track.id,rank:e.rank,prev:e.prev,delta:e.delta}))}));
tv.movers=env.Tr('IT',6).map(e=>e.track.id);
tv.emerging=env.Er(5).map(a=>a.id); tv.rising=env.Dr(8).map(a=>a.id); tv.newReleases=env.Or(6).map(t=>t.id);
tv.search=['ott','amapiano','juno','house','xyzzy','Italy'].map(q=>{const r=env.Pr(q);return {q,tracks:r.tracks.map(x=>x.id),artists:r.artists.map(x=>x.id),albums:r.albums.map(x=>x.id),playlists:r.playlists.map(x=>x.id)};});
tv.related=['ottobre','gold-hour'].map(id=>[id,env.Fr(env.$n.find(t=>t.id===id),6).map(t=>t.id)]);
tv.spark=env.jr('noor',96);
tv.art=[['ottobre',env.vr(env.$n.find(t=>t.id==='ottobre'))],['noor',env.xr(env.Xn.find(a=>a.id==='noor'))],['italy',env.br(env.nr.find(p=>p.id==='italy-rising'))],['house',env.Sr(env.rr.find(g=>g.id==='House'))]];
fs.writeFileSync(process.argv[4],JSON.stringify(tv));
// ---- wave vectors (Oa) & blocks sort
const waveCode=between('function Oa(e, t)','function ka(');
const Oa=new Function('Gn','Wn',waveCode+';return Oa;')(env.Gn,env.Wn);
tv.wave=Oa('ottobre',72);
fs.writeFileSync(process.argv[4],JSON.stringify(tv));
// ---- icons
const iconCode=between('var qr = {','function P({');
const icons=new Function('j',iconCode.replace('var qr =','const qr =')+';return qr;')(J);
fs.writeFileSync(process.argv[5],JSON.stringify(icons));
console.log('tracks',out.tracks.length,'artists',out.artists.length,'icons',Object.keys(icons).length);
