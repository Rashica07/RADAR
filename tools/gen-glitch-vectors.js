// Regenerates RADARTests/Fixtures/GlitchVectors.json from the JS reference (tools/glitch.js).
// Usage: node tools/gen-glitch-vectors.js <out.json>      (defaults to the committed fixture path)
// GlitchTests.testBandsMatchTheJavaScriptReference compares GlitchSpec.swift against this file.
const fs = require('fs');
const path = require('path');
const { bands } = require('./glitch');
const out = process.argv[2] || path.join(__dirname, '../RADARTests/Fixtures/GlitchVectors.json');
const height = 207, maxLength = 361 * 0.22;
const cases = [[7, 1], [1, 1], [12345, 0.5], [2166136261, 0.2]];
const data = cases.map(([seed, amount]) => ({ seed, height, amount, maxLength, bands: bands({ seed, height, amount, maxLength }) }));
fs.writeFileSync(out, JSON.stringify(data));
console.log('wrote', out, data.map((d) => d.bands.length).join(','));
