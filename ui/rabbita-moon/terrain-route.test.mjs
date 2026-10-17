import test from 'node:test'
import assert from 'node:assert/strict'
import { terrainRouteState, calculateTerrainRoute } from './terrain-route.js'
import { bindTerrainImport } from './terrain-import.js'
const bundle = {tile_id:'synthetic',rows:2,cols:3,horizontal_unit:'m',coordinate_frame:'Synthetic Cartesian frame',source_digest:'sha256:fixture',sample_count:5,nodata_count:1,minimum_elevation_m:0,maximum_elevation_m:5,origin_kind:'corner',origin_x:0,origin_y:0,cell_size:10,nodata_value:-9999,nodata_declared:true,source_note:'Synthetic fixture, not terrain truth',terrain_csv:'fixture',samples:[0,1,null,2,3,5].map((z,i)=>({row:Math.floor(i/3),col:i%3,x:i%3*10+5,y:15-Math.floor(i/3)*10,elevation_m:z}))}
class Node {
 constructor(tag){this.tag=tag;this.children=[];this.attributes={};this.listeners={};this.dataset={};this.value='';this.textContent='';this.files=[]}
 setAttribute(k,v){this.attributes[k]=v}
 appendChild(n){this.children.push(n);return n}
 replaceChildren(...n){this.children=n}
 addEventListener(k,f){(this.listeners[k]??=[]).push(f)}
 async fire(k){for(const f of this.listeners[k]??[])await f({target:this})}
 focus(){}
 find(id){return this.attributes.id===id?this:this.children.map(c=>c.find(id)).find(Boolean)}
 all(tag){return [...(this.tag===tag?[this]:[]),...this.children.flatMap(c=>c.all(tag))]}
 text(){return this.textContent+' '+this.children.map(c=>c.text()).join(' ')}
}
function response(source,sr,sc,gr,gc,grade,uphill,status='candidate-found') {
 const data=JSON.parse(source),sample=data.samples[sr*data.cols+sc]
 return JSON.stringify({ok:true,route:{contract_id:'moonmoon.terrain-route.v1',source_bundle:data,parameters:{start_row:sr,start_col:sc,goal_row:gr,goal_col:gc,max_grade_deg:grade,uphill_weight:uphill},status,summary:status==='no-path'?null:{cell_count:1,horizontal_distance_m:0,ascent_m:0,descent_m:0,max_absolute_grade_deg:0,objective_cost_m:0},path:status==='no-path'?[]:[{step:0,row:sr,col:sc,x_m:sample.x,y_m:sample.y,elevation_m:sample.elevation_m,distance_m:0,grade_deg:null}],route_digest:'sha256:route'}})
}
function ui(data=bundle,route=response){
 const root=new Node('div');for(const name of ['open','results','status','file','tile','frame','unit','note','metres','sample','clear']){const n=new Node('div');n.setAttribute('id','terrain-import-'+name);root.appendChild(n)}
 const document={createElement:tag=>new Node(tag),createElementNS:(_,tag)=>new Node(tag),getElementById:id=>root.find(id)}
 const calls=[];bindTerrainImport(document,()=>JSON.stringify({ok:true,bundle:data}),()=>JSON.stringify({ok:true,bundle:data}),()=>{throw Error('No analysis requested')},(...args)=>{calls.push(args);return route(...args)})
 return {root,calls,get:id=>root.find(id),select:async index=>{const picker=root.find('terrain-import-cell');picker.value=String(index);await picker.fire('change')}}
}
test('selection and preference validation occurs before shared route call',()=>{
 const state=terrainRouteState();let calls=0;const route=(...args)=>{calls++;return response(...args)}
 assert.throws(()=>calculateTerrainRoute(bundle,state,route),/start cell/);state.start=0;assert.throws(()=>calculateTerrainRoute(bundle,state,route),/goal cell/);state.goal=2;assert.throws(()=>calculateTerrainRoute(bundle,state,route),/NODATA/);state.goal=1;
 for(const grade of ['','NaN','90','-1']){state.grade=grade;assert.throws(()=>calculateTerrainRoute(bundle,state,route),/grade/)}state.grade='20';for(const uphill of ['','Infinity','-1']){state.uphill=uphill;assert.throws(()=>calculateTerrainRoute(bundle,state,route),/preference/)}assert.equal(calls,0);state.uphill='2';assert.equal(calculateTerrainRoute(bundle,state,route).parameters.uphill_weight,2);assert.equal(calls,1);
 assert.throws(()=>calculateTerrainRoute({...bundle,horizontal_unit:'degree'},state,route),/metre/);assert.throws(()=>calculateTerrainRoute(bundle,state,undefined),/unavailable/);
});
test('mounted import maps selected endpoints to exact callback args and route steps remain inspectable',async()=>{
 const a=ui();await a.get('terrain-import-sample').fire('click');await a.select(3);await a.get('terrain-route-start').fire('click');await a.select(5);await a.get('terrain-route-goal').fire('click');a.get('terrain-route-grade').value='35';await a.get('terrain-route-grade').fire('input');a.get('terrain-route-uphill').value='4';await a.get('terrain-route-uphill').fire('input');await a.get('terrain-route-calculate').fire('click');assert.deepEqual(a.calls[0].slice(1),[1,0,1,2,35,4]);assert.deepEqual(JSON.parse(a.calls[0][0]),bundle);assert.match(a.get('terrain-route-result').text(),/Candidate: 1 cells/);assert.equal(a.root.all('polyline').length,1);await a.get('terrain-route-steps').all('button')[0].fire('click');assert.match(a.get('terrain-import-detail').textContent,/\[1,0\]/);assert.match(a.get('terrain-route-endpoints').textContent,/Goal \[1,2\]/);assert.equal(a.get('terrain-route-grade').value,'35');assert.match(a.get('terrain-route-result').text(),/Candidate/);
});
test('changed inputs clear candidate and detached controls cannot act; swap and clear are repeatable',async()=>{
 const a=ui();await a.get('terrain-import-sample').fire('click');await a.get('terrain-route-start').fire('click');await a.select(1);await a.get('terrain-route-goal').fire('click');await a.get('terrain-route-calculate').fire('click');const oldStep=a.get('terrain-route-steps').all('button')[0];a.get('terrain-route-uphill').value='2';await a.get('terrain-route-uphill').fire('input');assert.equal(a.get('terrain-route-result').children.length,0);assert.equal(a.root.all('polyline').length,0);await oldStep.fire('click');assert.match(a.get('terrain-import-detail').textContent,/\[0,1\]/);await a.get('terrain-route-swap').fire('click');await a.get('terrain-route-calculate').fire('click');assert.deepEqual(a.calls.at(-1).slice(1),[0,1,0,0,20,2]);const stale=a.get('terrain-route-calculate');await a.get('terrain-import-clear').fire('click');await stale.fire('click');assert.equal(a.calls.length,2);await a.get('terrain-import-sample').fire('click');assert.match(a.get('terrain-route-endpoints').textContent,/Start not set; Goal not set/);await a.get('terrain-route-clear').fire('click');await a.get('terrain-route-clear').fire('click');assert.equal(a.calls.length,2);
});
test('no-path is distinct from invalid inputs and zero distance; no fabricated totals or route overlay',async()=>{
 const a=ui(bundle,(...args)=>response(...args,'no-path'));await a.get('terrain-import-sample').fire('click');await a.get('terrain-route-start').fire('click');await a.select(5);await a.get('terrain-route-goal').fire('click');await a.get('terrain-route-calculate').fire('click');assert.match(a.get('terrain-route-result').text(),/No path connects/);assert.doesNotMatch(a.get('terrain-route-result').text(),/Candidate:/);assert.equal(a.root.all('polyline').length,0);await a.select(2);await a.get('terrain-route-start').fire('click');await a.get('terrain-route-calculate').fire('click');assert.match(a.get('terrain-route-status').textContent,/NODATA/);assert.equal(a.calls.length,1);
});
test('degree grids do not expose route controls and callback errors or stale results are recoverable',async()=>{
 const degrees=ui({...bundle,horizontal_unit:'degree'});await degrees.get('terrain-import-sample').fire('click');assert.match(degrees.get('terrain-route-status').textContent,/unavailable for degree/);assert.equal(degrees.get('terrain-route-calculate'),undefined);
 for(const route of [()=>JSON.stringify({ok:false,error:'Source differs'}),(...args)=>{const r=JSON.parse(response(...args));r.route.parameters.goal_col=99;return JSON.stringify(r)}]){const a=ui(bundle,route);await a.get('terrain-import-sample').fire('click');await a.get('terrain-route-start').fire('click');await a.get('terrain-route-goal').fire('click');await a.get('terrain-route-calculate').fire('click');assert.match(a.get('terrain-route-status').textContent,/Source differs|does not match/);assert.equal(a.get('terrain-route-result').children.length,0)}
});
