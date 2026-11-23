// RADAR glitch band generator — the "speed smear" from the brand sheet.
// MUST stay in sync with RADAR/DesignSystem/Brand/GlitchSpec.swift (checked by GlitchParityTests).
//
// The glitch is a set of horizontal bands. Inside each band the artwork is smeared to the
// left: copies shifted by up to `length`, fading out. Bands near the top bar and the bottom
// leg of the symbol get the longest trails, exactly like the sheet.
function rng(seed) {
  let t = seed >>> 0;
  return () => {
    t = (t + 1831565813) >>> 0;
    let e = t;
    e = Math.imul(e ^ (e >>> 15), e | 1);
    e ^= e + Math.imul(e ^ (e >>> 7), e | 61);
    return ((e ^ (e >>> 14)) >>> 0) / 4294967296;
  };
}
const bump = (x, c, s) => Math.exp(-(((x - c) / s) ** 2));

function bands({ seed, height, amount, maxLength }) {
  const r = rng(seed);
  const out = [];
  let y = 0;
  while (y < height) {
    const h = 1.5 + r() * 5.5;
    const r1 = r(), r2 = r();
    const yn = (y + h / 2) / height;
    const w = 0.10 + 0.90 * Math.max(bump(yn, 0.20, 0.13), bump(yn, 0.93, 0.12));
    const active = r1 < 0.10 + 0.75 * w;
    const length = active ? amount * maxLength * w * (0.25 + 0.75 * r2) : 0;
    out.push({ y, h: Math.min(h, height - y), length });
    y += h;
  }
  return out;
}
const TRAIL_COPIES = 8;
const trailAlpha = (k) => Math.pow(1 - k / TRAIL_COPIES, 0.8) * 0.95;
module.exports = { rng, bands, TRAIL_COPIES, trailAlpha };
