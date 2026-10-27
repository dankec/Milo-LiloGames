/* Run: node tests/tajna_sume.test.cjs. No browser or packages required.
   Execute the real game simulation in a minimal DOM/canvas harness. */
const {readFileSync}=require('node:fs');
const vm=require('node:vm');
const assert=require('node:assert/strict');
const source=readFileSync(require('node:path').join(__dirname,'../milo_lilo_tajna_sume.html'),'utf8').match(/<script>([\s\S]*?)<\/script>/)[1];
const events={},elements=new Map(),storage=new Map();
function element(id){if(!elements.has(id))elements.set(id,{id,textContent:'',innerHTML:'',hidden:false,style:{},dataset:{},listeners:{},classList:{add(){},remove(){},toggle(){}},addEventListener(k,f){this.listeners[k]=f},setAttribute(){},querySelector(){return null},querySelectorAll(){return[]},focus(){}});return elements.get(id)}
const noop=()=>{};
const ctx=new Proxy({createLinearGradient:()=>({addColorStop:noop}),createRadialGradient:()=>({addColorStop:noop})},{get(t,k){return k in t?t[k]:noop},set(t,k,v){t[k]=v;return true}});
element('game').getContext=()=>ctx;
const touchButtons=['left','right','up','down','attack','jump'].map(k=>{const b=element('touch-'+k);b.dataset.key=k;b.setPointerCapture=noop;return b});
const sandbox={console,Math,performance:{now:()=>0},requestAnimationFrame:noop,document:{getElementById:element,querySelectorAll:s=>s==='[data-key]'?touchButtons:[],addEventListener:(k,f)=>events['document:'+k]=f},localStorage:{getItem:k=>storage.get(k)||null,setItem:(k,v)=>storage.set(k,v)}};
sandbox.window={addEventListener:(k,f)=>events['window:'+k]=f};
vm.createContext(sandbox);
const hooks=`globalThis.test={setup,step,draw,jump,swap,shoot,pause,closeModal,enterPhase,goHome,damage,reward,finish,loadSave,updateHUD,
 get state(){return state},get hero(){return hero},get enemies(){return enemies},get pickups(){return pickups},get cards(){return cards},get crates(){return crates},get platforms(){return platforms},get mode(){return mode},get saved(){return saved},get keys(){return keys},get shots(){return shots},
 key:(key,value)=>keys[key]=value,claim:()=>modalAction?.(),setMode:m=>mode=m,clearEnemies:()=>enemies=[]};`;
vm.runInContext(source.replace(/\}\)\(\);\s*$/,hooks+'})();'),sandbox);
const t=sandbox.test;
let passed=0;
function test(name,f){t.setup();t.clearEnemies();f();passed++;console.log('PASS',name)}
function ticks(seconds){for(let i=0;i<Math.round(seconds*60);i++)t.step(1/60)}
function ground(x=70){t.hero.x=x;t.hero.y=400;t.hero.vy=0;t.hero.grounded=true;t.hero.jumps=0}
test('Title and live scene render without errors',()=>{t.draw();assert.equal(t.mode,'playing');assert.equal(element('house-chip').hidden,true)});
test('One-way landing, double jump and no third jump',()=>{ground();t.jump();assert(t.hero.vy<0);ticks(.1);t.jump();assert.equal(t.hero.jumps,2);const v=t.hero.vy;t.jump();assert.equal(t.hero.vy,v);ticks(1.2);assert.equal(t.hero.y,400);assert(t.hero.grounded)});
test('Coyote time allows a jump just after stepping off a platform',()=>{ground();t.hero.grounded=false;t.hero.coyote=.08;t.jump();assert(t.hero.vy<0);assert.equal(t.hero.jumps,1)});
test('Rabbit and bear can jump onto the first mystery platform',()=>{for(const type of ['rabbit','bear']){t.setup();t.clearEnemies();t.swap(type);ground(265);t.jump();ticks(.65);assert.equal(t.hero.y,311);assert(t.hero.grounded)}});
test('A ladder can be climbed and descended from its top',()=>{ground(548);t.key('up',true);ticks(1.2);assert.equal(t.hero.y,234);t.key('up',false);t.key('down',true);ticks(.5);assert(t.hero.y>290);t.key('down',false)});
test('Jumping away from a ladder preserves the upward impulse',()=>{ground(548);t.key('up',true);ticks(.3);t.jump();const y=t.hero.y;t.step(1/60);assert(t.hero.y<y);assert(t.hero.vy<-300)});
test('Bear moves crates; rabbit cannot walk through them',()=>{ground(850);t.key('right',true);ticks(.4);assert.equal(t.crates[0].x,890);assert(t.hero.x+t.hero.w<=890.01);t.swap('bear');ticks(.4);assert(t.crates[0].x>900);t.key('right',false)});
test('Swapping characters does not refill health',()=>{t.state.hp=1;t.swap('bear');t.state.invulnerable=0;t.damage();assert.equal(t.state.bonusHp,0);t.swap('rabbit');t.swap('bear');assert.equal(t.state.hp,1);assert.equal(t.state.bonusHp,0)});
test('Reward modal freezes the timer and grants full shield on claim',()=>{t.reward(t.cards[0]);const time=t.state.time;ticks(3);assert.equal(t.state.time,time);t.claim();assert.equal(t.mode,'playing');assert.equal(t.state.shield,18)});
test('Coins persist; missing storage permission never stops gameplay',()=>{ground(160);t.step(1/60);assert(t.state.coins>0);const n=t.saved.wallet;sandbox.localStorage.setItem=()=>{throw Error('denied')};ground(260);t.step(1/60);assert(t.saved.wallet>=n);sandbox.localStorage.setItem=(k,v)=>storage.set(k,v)});
test('Pause and hidden-tab events stop the countdown and clear input',()=>{t.key('right',true);events['window:blur']();assert.equal(t.mode,'paused');assert(!t.keys.right);const time=t.state.time;ticks(5);assert.equal(t.state.time,time);t.closeModal();ticks(.2);assert(t.state.time<time)});
test('Berries replace coins and strengthen the house; distant hero returns safely',()=>{ground();t.enterPhase('berries');assert(t.pickups.every(p=>p.kind==='berry'));t.state.berries=12;t.enterPhase('night');assert.equal(t.state.houseMax,148);assert(Math.abs(t.hero.x-3690)<120);assert.equal(element('house-chip').hidden,false)});
test('Failed defence retries the current wave with full house health',()=>{t.enterPhase('night');t.state.wave=1;t.state.elapsed=37;t.state.house=-1;t.step(1/60);assert.equal(t.state.elapsed,30);assert.equal(t.state.house,t.state.houseMax);assert.equal(t.mode,'playing')});
test('Night attacks defeat zombies and all three waves reach morning',()=>{t.enterPhase('night');ground(3690-95);t.key('attack',true);ticks(90.1);assert.equal(t.mode,'won');assert(t.state.nightKills>0);assert(t.saved.unlocked.includes('boomerang'));assert(t.saved.rounds>0)});
test('Bumerang unlock survives restarting the next adventure',()=>{t.finish();t.setup();assert(t.state.available.includes('boomerang'));assert.equal(t.state.phase,'day')});
test('Corrupted save data is bounded and unknown unlocks are rejected',()=>{storage.set('milo-lilo-forest-v1',JSON.stringify({wallet:-99,rounds:Infinity,best:'oops',unlocked:['laser'],hats:['unknown'],hat:'unknown'}));const s=t.loadSave();assert.equal(s.wallet,0);assert.equal(s.rounds,0);assert.equal(s.hat,'none');assert.deepEqual(Array.from(s.unlocked),['acorn']);storage.clear()});
test('Two simultaneous touch pointers support movement plus jump; cancellation releases input',()=>{const right=touchButtons[1],jump=touchButtons[5];right.listeners.pointerdown({preventDefault:noop,pointerId:1});jump.listeners.pointerdown({preventDefault:noop,pointerId:2});assert(t.keys.right&&t.keys.jump);ground();t.step(1/60);assert(t.hero.x>70&&t.hero.vy<0);right.listeners.pointercancel({pointerId:1});jump.listeners.lostpointercapture({pointerId:2});assert(!t.keys.right&&!t.keys.jump)});
test('Natural day → berry → night transitions do not skip phases',()=>{t.state.time=.005;t.step(1/60);assert.equal(t.state.phase,'berries');t.state.time=.005;t.step(1/60);assert.equal(t.state.phase,'night');t.draw()});
console.log(`\n${passed} simulation checks passed.`);
