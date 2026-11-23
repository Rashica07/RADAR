// Renders an SVG to PNG with Chromium (produced the app-icon PNGs). Usage: node tools/render.js <in.svg> <out.png> <width> <height>
// Needs `npm install` in tools/ (playwright) and `npx playwright install chromium`.
const { chromium } = require('playwright'); const fs=require('fs');
(async()=>{ const b=await chromium.launch(); const p=await b.newPage({viewport:{width:+process.argv[4],height:+process.argv[5]}});
await p.setContent(`<body style="margin:0;background:#101413">${fs.readFileSync(process.argv[2],'utf8').replace('<svg ','<svg style="display:block;width:100%;height:100%" ')}</body>`);
await p.screenshot({path:process.argv[3]}); await b.close(); })();
