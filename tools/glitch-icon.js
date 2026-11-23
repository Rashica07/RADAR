// Renders the glitched alternate app icon + its in-app preview, and parity fixtures.
// Usage: node tools/glitch-icon.js <seed> <out.svg>
const fs = require('fs');
const { SYMBOL, SYM_W, SYM_H } = require('./brand');
const { bands, TRAIL_COPIES, trailAlpha } = require('./glitch');
const seed = +process.argv[2], out = process.argv[3];
const MINT = '#79E2C0', BG = '#101413';
const s = 1024 * 0.64 / SYM_W;
const tx = 512 - SYM_W * s / 2 + 34, ty = 512 - SYM_H * s / 2 + 8;
const bs = bands({ seed, height: SYM_H, amount: 1, maxLength: SYM_W * 0.22 });
let defs = `<g id="m" fill="${MINT}"><path d="${SYMBOL.outer}"/><path d="${SYMBOL.signal}"/><path d="${SYMBOL.core}"/><path d="${SYMBOL.leg}"/></g>`;
let body = '';
bs.forEach((b, i) => {
  if (b.length <= 0.5) return;
  defs += `<clipPath id="c${i}"><rect x="-400" y="${b.y.toFixed(2)}" width="1200" height="${b.h.toFixed(2)}"/></clipPath>`;
  let g = '';
  for (let k = 1; k <= TRAIL_COPIES; k++) g += `<use href="#m" x="${(-b.length * k / TRAIL_COPIES).toFixed(2)}" opacity="${trailAlpha(k).toFixed(3)}"/>`;
  if (b.length > SYM_W * 0.12) g += `<use href="#m" x="${(b.length * 0.1).toFixed(2)}" opacity="0.6"/>`;
  body += `<g clip-path="url(#c${i})">${g}</g>`;
});
fs.writeFileSync(out, `<svg xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink" viewBox="0 0 1024 1024" width="1024" height="1024"><rect width="1024" height="1024" fill="${BG}"/><g transform="translate(${tx.toFixed(2)} ${ty.toFixed(2)}) scale(${s.toFixed(4)})"><defs>${defs}</defs>${body}<use href="#m"/></g></svg>\n`);
