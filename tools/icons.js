const fs=require('fs'); const svgpath=require(require('fs').existsSync(require('path').join(__dirname,'npm/node_modules/svgpath'))?'./npm/node_modules/svgpath':'svgpath');
const icons=JSON.parse(fs.readFileSync(process.argv[2]));
const f=n=>{const v=Math.round(n*1000)/1000; return Number.isInteger(v)?v.toFixed(1):String(v);};
const camel=s=>s.replace(/-([a-z])/g,(_,c)=>c.toUpperCase());
function flatten(node,out){ if(!node) return; if(Array.isArray(node)){node.forEach(n=>flatten(n,out));return;}
  if(node.t==='frag'){flatten(node.p.children,out);return;} out.push(node); }
function pathCode(d){
  const p=svgpath(d).abs().unarc().unshort(); const lines=[]; let cur=[0,0];
  p.iterate((seg,_,x,y)=>{const c=seg[0];
    if(c==='M'){lines.push(`p.move(to: P(${f(seg[1])}, ${f(seg[2])}))`);}
    else if(c==='L'){lines.push(`p.addLine(to: P(${f(seg[1])}, ${f(seg[2])}))`);}
    else if(c==='H'){lines.push(`p.addLine(to: P(${f(seg[1])}, ${f(y)}))`);}
    else if(c==='V'){lines.push(`p.addLine(to: P(${f(x)}, ${f(seg[1])}))`);}
    else if(c==='C'){lines.push(`p.addCurve(to: P(${f(seg[5])}, ${f(seg[6])}), control1: P(${f(seg[1])}, ${f(seg[2])}), control2: P(${f(seg[3])}, ${f(seg[4])}))`);}
    else if(c==='Q'){lines.push(`p.addQuadCurve(to: P(${f(seg[3])}, ${f(seg[4])}), control: P(${f(seg[1])}, ${f(seg[2])}))`);}
    else if(c==='Z'){lines.push(`p.closeSubpath()`);}
    else throw new Error('cmd '+c);
  });
  return lines;
}
let cases=[], names=[];
for(const [name,node] of Object.entries(icons)){
  const els=[]; flatten(node,els); const parts=[];
  for(const el of els){ const a=el.p; let body;
    if(el.t==='path') body=pathCode(a.d);
    else if(el.t==='circle') body=[`p.addEllipse(in: CGRect(x: ${f(+a.cx-+a.r)}, y: ${f(+a.cy-+a.r)}, width: ${f(2*a.r)}, height: ${f(2*a.r)}))`];
    else if(el.t==='ellipse') body=[`p.addEllipse(in: CGRect(x: ${f(+a.cx-+a.rx)}, y: ${f(+a.cy-+a.ry)}, width: ${f(2*a.rx)}, height: ${f(2*a.ry)}))`];
    else if(el.t==='rect') body=[`p.addRoundedRect(in: CGRect(x: ${f(+a.x)}, y: ${f(+a.y)}, width: ${f(+a.width)}, height: ${f(+a.height)}), cornerSize: CGSize(width: ${f(+(a.rx||0))}, height: ${f(+(a.rx||0))}))`];
    else throw new Error(el.t);
    const fill = a.fill==='currentColor';
    const stroke = a.stroke!=='none';
    const cut = typeof a.stroke==='string' && a.stroke.startsWith('var(--icon-cut');
    parts.push(`IconPart(fill: ${fill}, stroke: ${stroke && !cut}, cut: ${cut}) { p in\n            ${body.join('\n            ')}\n        }`);
  }
  const id=camel(name); names.push([id,name]);
  cases.push(`    case .${id}:\n        return [\n        ${parts.join(',\n        ')}\n        ]`);
}
const swift=`// Generated from the RADAR Phase 01 icon set (24×24 grid, 1.75 stroke, round caps/joins).
// Regenerate with tools/icons.js — do not edit by hand.
import SwiftUI

enum RadarIconName: String, CaseIterable, Sendable {
${names.map(([id,n])=>`    case ${["repeat","default","in","is","as"].includes(id)?"`"+id+"`":id} = "${n}"`).join('\n')}
}

private func P(_ x: CGFloat, _ y: CGFloat) -> CGPoint { CGPoint(x: x, y: y) }

extension RadarIconName {
    /// Vector parts in a 24×24 coordinate space.
    var parts: [IconPart] {
        switch self {
${cases.join('\n')}
        }
    }
}
`;
fs.writeFileSync(process.argv[3],swift); console.log('ok',names.length);
