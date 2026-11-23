const { chromium } = require('playwright');
const http = require('http'); const fs = require('fs'); const path = require('path');
const root = process.argv[2], out = process.argv[3];
const types = {'.js':'text/javascript','.css':'text/css','.html':'text/html','.svg':'image/svg+xml','.woff2':'font/woff2','.woff':'font/woff'};
const srv = http.createServer((req,res)=>{ let p = decodeURIComponent(req.url.split('?')[0]); if (p==='/'||!fs.existsSync(path.join(root,p))) p='/index.html'; res.setHeader('Content-Type', types[path.extname(p)]||'application/octet-stream'); fs.createReadStream(path.join(root,p)).pipe(res);}).listen(8766, async ()=>{
  const b = await chromium.launch();
  const sizes = {'w466x678':[466,678],'w890x626':[890,626],'w1032x1376':[1032,1376],'w1376x1032':[1376,1032]};
  const routes = {discover:'/', trending:'/trending', library:'/library'};
  for (const [sn,[w,h]] of Object.entries(sizes)) {
    const ctx = await b.newContext({ viewport:{width:w,height:h}, deviceScaleFactor:1, hasTouch:true });
    const pg = await ctx.newPage();
    for (const [rn,r] of Object.entries(routes)) {
      await pg.goto('http://localhost:8766/#'+r); await pg.reload(); await pg.waitForTimeout(1800);
      await pg.screenshot({ path:`${out}/${sn}-${rn}.jpg`, type:'jpeg', quality:80 });
    }
    // expanded player
    await pg.goto('http://localhost:8766/#/'); await pg.reload(); await pg.waitForTimeout(1500);
    try { await pg.click('.transport__art, .mini__main', {timeout:3000}); await pg.waitForTimeout(1200); await pg.screenshot({ path:`${out}/${sn}-player.jpg`, type:'jpeg', quality:80 }); } catch(e) { console.log('player click failed at', sn); }
    // report which chrome is visible
    const info = await pg.evaluate(()=>{ const vis=s=>{const e=document.querySelector(s); if(!e) return 'absent'; const r=e.getBoundingClientRect(); const cs=getComputedStyle(e); return cs.display==='none'?'hidden':`${Math.round(r.width)}x${Math.round(r.height)}`}; return {bottomNav:vis('.bottom-nav'), sideNav:vis('.side-nav'), dock:vis('.dock'), transport:vis('.transport'), mini:vis('.mini')}; });
    console.log(sn, JSON.stringify(info));
    await ctx.close();
  }
  await b.close(); srv.close();
});
