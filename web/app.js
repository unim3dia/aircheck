const $ = selector => document.querySelector(selector);
const months = ['JAN','FEB','MAR','APR','MAY','JUN','JUL','AUG','SEP','OCT','NOV','DEC'];
const state = { catalog:null, year:'2006', month:1, show:null, data:null, tab:'segments', time:0, activeSegment:null, search:'' };
const indexes = {};
const time = seconds => { seconds=Math.max(0,Math.floor(seconds||0)); return `${Math.floor(seconds/3600)}:${String(Math.floor(seconds%3600/60)).padStart(2,'0')}:${String(seconds%60).padStart(2,'0')}` };
const duration = seconds => `${Math.floor(seconds/3600)} hr ${Math.floor(seconds%3600/60)} min`;
const title = show => show.topics?.[0]?.title || 'Archive broadcast';
const allShows = () => Object.values(state.catalog || {}).flat();
const yearShows = () => state.catalog?.[state.year] || [];
const route = () => location.hash.replace(/^#/,'').split('/');
const go = value => { location.hash=value };
const showRoute = (id, seconds=0) => go(`show/${id}/${Math.floor(seconds)}`);
const esc = value => String(value || '').replace(/[&<>"']/g, char => ({'&':'&amp;','<':'&lt;','>':'&gt;','"':'&quot;',"'":'&#039;'}[char]));

function setYear(year) { state.year=year; state.month=1; go('home'); }
function card(show) { const date=new Date(`${show.date}T00:00:00Z`); return `<button class="show" data-show="${show.id}"><div class="date">${String(date.getUTCDate()).padStart(2,'0')}<small>${date.toLocaleDateString('en',{weekday:'short'}).toUpperCase()}</small></div><div><strong>${esc(title(show))}</strong><p>${duration(show.duration)}</p></div><span class="arrow">›</span></button>`; }

function library() {
  const list=yearShows().filter(show => new Date(`${show.date}T00:00:00Z`).getUTCMonth()+1===state.month);
  $('#app').innerHTML=`<div class="shell"><aside class="rail"><p class="kicker">${state.year==='2006'?'THE FIRST SATELLITE YEAR':'SATELLITE YEAR TWO'}</p><img src="assets/howard1.png" alt="Howard Stern at the microphone"><p class="rail-copy">A listener’s shelf for the long broadcasts. Stream the tape, follow the conversation, and pick up where you left off.</p></aside><section class="library"><header class="library-head"><div><p class="kicker">THE BROADCAST SHELF</p><h1>${months[state.month-1]} ${state.year}</h1></div><div class="archive-choice" aria-label="Archive year"><button data-year="2006" class="${state.year==='2006'?'active':''}">2006</button><button data-year="2007" class="${state.year==='2007'?'active':''}">2007</button></div></header><nav class="months">${months.map((month,index)=>`<button data-month="${index+1}" class="${state.month===index+1?'active':''}">${month}</button>`).join('')}</nav><p class="note">${list.length} broadcasts · choose a date to open the tape.</p><div class="show-grid">${list.map(card).join('')}</div></section></div>`;
}

async function detail(id, at=0) {
  const show=allShows().find(item=>item.id===id); if(!show) return go('home');
  state.show=show;
  state.data=show.transcriptAvailable ? await fetch(`data/shows/${id}.json`).then(response=>response.json()) : {topics:show.topics,transcript:[]};
  state.time=at; state.activeSegment=null; renderDetail(); syncTranscript();
}
function renderDetail() {
  const show=state.show, data=state.data;
  $('#app').innerHTML=`<article class="detail"><button class="text-back" id="show-back">← Back to broadcasts</button><header class="show-hero"><div><p class="kicker">${show.date}</p><h1>${esc(title(show))}</h1><p>${duration(show.duration)}</p><button class="hero-play" data-play="0">▶ ${$('#audio').paused || $('#audio').src !== show.url ? 'Start listening' : 'Pause listening'}</button></div><img src="assets/howard2.png" alt="Howard Stern in studio"></header><div class="tabs"><button data-tab="segments" class="${state.tab==='segments'?'active':''}">Segments</button><button data-tab="transcript" class="${state.tab==='transcript'?'active':''}">Transcript</button></div><section class="tab-content">${state.tab==='segments' ? segments(data.topics) : transcript(data.transcript)}</section></article>`;
}
function segments(items) { return `<div class="topics">${items.map(topic=>`<button class="topic" data-play="${topic.startTime}"><time>${time(topic.startTime)}</time><h2>${esc(topic.title)}</h2><p>${esc(topic.summary)}</p></button>`).join('')}</div>`; }
function transcript(items) { return items.length ? `<div class="transcript"><p class="transcript-note">The line currently on air is highlighted as you listen.</p>${items.map((segment,index)=>`<button class="segment" data-segment="${index}" data-play="${segment.startTime}"><time>${time(segment.startTime)}</time><span>${esc(segment.text)}</span></button>`).join('')}</div>` : '<p class="empty">Transcript is not available for this broadcast.</p>'; }

function updatePlayer() {
  const audio=$('#audio'); if(!state.show) return;
  $('#bottom-player').hidden=false;
  $('#player-title strong').textContent=title(state.show);
  $('#player-date').textContent=`${state.show.date} · ON AIR`;
  const active=state.data?.transcript?.find((segment,index) => audio.currentTime >= segment.startTime && audio.currentTime < (state.data.transcript[index+1]?.startTime ?? Infinity));
  const topic=state.data?.topics?.find((item,index) => audio.currentTime >= item.startTime && audio.currentTime < (state.data.topics[index+1]?.startTime ?? Infinity));
  $('#player-segment').textContent=active?.text || topic?.title || `Listening from ${time(audio.currentTime)}`;
  const progress=$('#progress'), maximum=Math.max(1, audio.duration || state.show.duration || 1), value=audio.currentTime || 0;
  progress.max=maximum; progress.value=value;
  const position=`${Math.min(100,Math.max(0,value / maximum * 100))}%`;
  progress.style.setProperty('--playhead-position', position);
  $('#mic-playhead').style.setProperty('--playhead-position', position);
  $('#player-time').textContent=`${time(value)} / ${time(maximum)}`;
  const toggle=$('#toggle-button'); toggle.textContent=audio.paused?'▶ Play':'Ⅱ Pause'; toggle.setAttribute('aria-label', audio.paused?'Play current broadcast':'Pause current broadcast');
  $('#player-toggle').textContent=audio.paused?'▶':'Ⅱ'; $('#player-toggle').setAttribute('aria-label',audio.paused?'Play current broadcast':'Pause current broadcast');
}
function play(show, at=0) {
  state.show=show; state.time=at;
  const audio=$('#audio');
  if(audio.src !== new URL(show.url, location.href).href) audio.src=show.url;
  audio.currentTime=at; audio.play(); updatePlayer(); syncTranscript();
}
function toggleShowPlayback() {
  const audio=$('#audio'); if(!state.show) return;
  if(audio.src !== new URL(state.show.url, location.href).href) return play(state.show, 0);
  audio.paused ? audio.play() : audio.pause(); updatePlayer(); renderDetail();
}
function syncTranscript() {
  if(!state.data?.transcript?.length || state.show?.id !== route()[1]) return;
  const now=$('#audio').currentTime || state.time || 0;
  let index=state.data.transcript.findIndex((segment,index) => now >= segment.startTime && now < (state.data.transcript[index+1]?.startTime ?? Infinity));
  if(index<0 || index===state.activeSegment) return;
  document.querySelector('.segment.active')?.classList.remove('active');
  const row=document.querySelector(`[data-segment="${index}"]`); row?.classList.add('active');
  if(state.tab==='transcript' && row && state.activeSegment !== null) row.scrollIntoView({block:'center',behavior:'smooth'});
  state.activeSegment=index;
}
async function random() {
  const candidates=allShows().filter(show=>show.transcriptAvailable); const show=candidates[Math.floor(Math.random()*candidates.length)];
  const data=await fetch(`data/shows/${show.id}.json`).then(response=>response.json()); const pieces=data.topics.length?data.topics:data.transcript; const pick=pieces[Math.floor(Math.random()*pieces.length)];
  play(show,pick.startTime); showRoute(show.id,pick.startTime);
}

async function loadIndexes() {
  await Promise.all(['2006','2007'].map(async year => { if(!indexes[year]) indexes[year]=await fetch(`data/search-${year}.json`).then(response=>response.json()); }));
}
async function search(query) {
  state.search=query.trim(); if(state.search.length<3) { if(route()[0]==='search') go('home'); return; }
  $('#app').innerHTML='<div class="searching">Searching the transcript library…</div>';
  await loadIndexes();
  const words=[...new Set((state.search.toLowerCase().match(/[a-z0-9][a-z0-9']{2,}/g)||[]))];
  const hits=[]; const seen=new Set();
  for(const index of Object.values(indexes)) for(const word of words) for(const [id,start] of (index[word]||[])) { const key=`${id}-${start}`; if(!seen.has(key)) { seen.add(key); hits.push({id,start}); } }
  const showById=new Map(allShows().map(show=>[show.id,show]));
  $('#app').innerHTML=`<section class="search-results"><p class="kicker">ARCHIVE SEARCH</p><h1>“${esc(state.search)}”</h1><p class="note">${hits.length ? 'Transcript and segment matches — choose one to tune in.' : 'No indexed matches yet. Try a name, topic, or phrase of three or more letters.'}</p><div class="results">${hits.slice(0,80).map(hit=>{const show=showById.get(hit.id);return show?`<button class="search-result" data-search-show="${hit.id}" data-search-time="${hit.start}"><span>${show.date}</span><strong>${esc(title(show))}</strong><em>Jump to ${time(hit.start)}</em></button>`:''}).join('')}</div></section>`;
}
async function render() { const current=route(); if(current[0]==='show') { await detail(current[1],Number(current[2]||0)); if(Number(current[2]||0)&&state.show) play(state.show,Number(current[2])); } else if(current[0]==='search') await search(decodeURIComponent(current.slice(1).join('/'))); else library(); }

document.addEventListener('click', event => {
  const year=event.target.closest('[data-year]'), month=event.target.closest('[data-month]'), show=event.target.closest('[data-show]'), playButton=event.target.closest('[data-play]'), tab=event.target.closest('[data-tab]'), result=event.target.closest('[data-search-show]');
  if(year) setYear(year.dataset.year); else if(month) {state.month=+month.dataset.month; library()} else if(show) showRoute(show.dataset.show); else if(result) showRoute(result.dataset.searchShow,result.dataset.searchTime); else if(playButton && state.show) { if(playButton.classList.contains('hero-play')) toggleShowPlayback(); else play(state.show,+playButton.dataset.play); } else if(tab) {state.tab=tab.dataset.tab; renderDetail(); syncTranscript();} else if(event.target.closest('#show-back')) history.back();
});
$('#home-button').onclick=()=>go('home'); $('#back-button').onclick=()=>history.back(); $('#random-button').onclick=random;
$('#toggle-button').onclick=()=>toggleShowPlayback();
$('#player-toggle').onclick=()=>toggleShowPlayback();
$('#player-title').onclick=()=>state.show&&showRoute(state.show.id,$('#audio').currentTime);
$('#skip-back').onclick=()=>$('#audio').currentTime=Math.max(0,$('#audio').currentTime-15); $('#skip-forward').onclick=()=>$('#audio').currentTime+=15;
$('#progress').oninput=event=>{ $('#audio').currentTime=Number(event.target.value); updatePlayer(); syncTranscript(); };
$('#volume').oninput=event=>{ const value=Number(event.target.value); $('#audio').volume=value; $('#volume-dial').style.setProperty('--volume-turn',`${-135+270*value}deg`); };
let searchTimer; $('#global-search').oninput=event=>{ clearTimeout(searchTimer); const query=event.target.value; searchTimer=setTimeout(()=>{ if(query.trim().length>=3) go(`search/${encodeURIComponent(query.trim())}`); else if(route()[0]==='search') go('home'); },220); };
$('#audio').ontimeupdate=()=>{ updatePlayer(); syncTranscript(); }; $('#audio').onloadedmetadata=updatePlayer; $('#audio').onplay=()=>{updatePlayer(); if(route()[0]==='show') renderDetail()}; $('#audio').onpause=()=>{updatePlayer(); if(route()[0]==='show') renderDetail()};
window.onhashchange=render;
fetch('data/catalog.json').then(response=>response.json()).then(data=>{state.catalog=data;render()});
