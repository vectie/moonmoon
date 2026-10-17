import test from 'node:test'
import assert from 'node:assert/strict'
import { elevationBandState, elevationBand } from './terrain-elevation-band.js'
import { bindTerrainImport } from './terrain-import.js'
const bundle = {tile_id:'band-fixture',rows:2,cols:3,horizontal_unit:'m',coordinate_frame:'Synthetic local frame',source_digest:'sha256:synthetic',sample_count:5,nodata_count:1,minimum_elevation_m:-2,maximum_elevation_m:5,origin_kind:'corner',origin_x:0,origin_y:0,cell_size:1,nodata_value:-9999,nodata_declared:true,source_note:'Synthetic elevations; no mission authority',terrain_csv:'fixture',samples:[-2,0,null,1,5,5].map((z,index)=>({row:Math.floor(index/3),col:index%3,x:index%3+0.5,y:1.5-Math.floor(index/3),elevation_m:z}))}
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
}
function ui(data=bundle){
 const root=new Node('div');for(const name of ['open','results','status','file','tile','frame','unit','note','metres','sample','clear']){const n=new Node('div');n.setAttribute('id','terrain-import-'+name);root.appendChild(n)}
 const document={createElement:tag=>new Node(tag),createElementNS:(_,tag)=>new Node(tag),getElementById:id=>root.find(id)}
 bindTerrainImport(document,()=>JSON.stringify({ok:true,bundle:data}),()=>JSON.stringify({ok:true,bundle:data}),()=>{throw Error('No analysis needed for elevation selection')})
 return {root,get:id=>root.find(id)}
}
test('inclusive zero, negative and open bounds; unknown stays excluded',()=>{assert.deepEqual(elevationBand(bundle,elevationBandState()).indices,[0,1,3,4,5]);assert.deepEqual(elevationBand(bundle,{minimum:'0',maximum:'1'}).indices,[1,3]);assert.deepEqual(elevationBand(bundle,{minimum:'5',maximum:'5'}).indices,[4,5]);assert.deepEqual(elevationBand(bundle,{minimum:'',maximum:'-1'}).indices,[0]);assert.deepEqual(elevationBand(bundle,{minimum:'8',maximum:''}).indices,[]);assert.deepEqual(elevationBand(bundle,elevationBandState()).unknown,[2]);})
test('invalid bounds do not silently choose cells',()=>{for(const state of [{minimum:'2',maximum:'1'},{minimum:'NaN',maximum:''},{minimum:'',maximum:'Infinity'}])assert.throws(()=>elevationBand(bundle,state));})
test('mounted import UI highlights band, navigates and keeps selected exact values and bounds',async()=>{const a=ui();await a.get('terrain-import-sample').fire('click');a.get('terrain-band-minimum').value='1';await a.get('terrain-band-minimum').fire('input');assert.match(a.get('terrain-band-status').textContent,/3 of 5 known cells match; 1 unknown/);const rects=a.get('terrain-import-results').all('rect');assert.deepEqual(rects.map(n=>n.attributes.opacity),['0.3','0.3','0.3','1','1','1']);await a.get('terrain-band-next').fire('click');assert.match(a.get('terrain-import-detail').textContent,/\[1,0\]/);assert.equal(a.get('terrain-band-minimum').value,'1');assert.equal(a.get('terrain-band-previous').disabled,true);await a.get('terrain-band-next').fire('click');assert.match(a.get('terrain-import-detail').textContent,/\[1,1\]/);await a.get('terrain-band-previous').fire('click');assert.match(a.get('terrain-import-detail').textContent,/\[1,0\]/);})
test('invalid band removes highlight and disables navigation; clear and new import reset state',async()=>{const a=ui();await a.get('terrain-import-sample').fire('click');const old=a.get('terrain-band-next');a.get('terrain-band-minimum').value='9';await a.get('terrain-band-minimum').fire('input');a.get('terrain-band-maximum').value='2';await a.get('terrain-band-maximum').fire('input');assert.match(a.get('terrain-band-status').textContent,/must not exceed/);assert.equal(a.get('terrain-band-next').disabled,true);await a.get('terrain-import-clear').fire('click');await old.fire('click');assert.equal(a.get('terrain-import-results').children.length,0);await a.get('terrain-import-sample').fire('click');assert.equal(a.get('terrain-band-minimum').value,'');})
test('all unknown and degree grids remain exploratory without metric hazard computation',async()=>{for(const data of [{...bundle,samples:bundle.samples.map(c=>({...c,elevation_m:null})),sample_count:0,nodata_count:6},{...bundle,horizontal_unit:'degree'}]){const a=ui(data);await a.get('terrain-import-sample').fire('click');assert(a.get('terrain-band-status'));if(data.sample_count===0){assert.match(a.get('terrain-band-status').textContent,/0 of 0 known cells match; 6 unknown/);assert.equal(a.get('terrain-band-next').disabled,true)}}})
