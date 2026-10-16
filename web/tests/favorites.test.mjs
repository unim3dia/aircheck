import assert from 'node:assert/strict';
import {readFileSync} from 'node:fs';
import {favorites, createFavorites} from '../favorites.js';

const catalog=[
  ...Object.values(JSON.parse(readFileSync(new URL('../data/catalog.json',import.meta.url)))).flat(),
  ...JSON.parse(readFileSync(new URL('../data/catalog-2008.json',import.meta.url))),
  ...JSON.parse(readFileSync(new URL('../data/catalog-2008-rest.json',import.meta.url))),
  ...JSON.parse(readFileSync(new URL('../data/catalog-cassettes.json',import.meta.url))).items
];
assert.equal(new Set(favorites.map(item=>item.id)).size,favorites.length);
let chapters=0;
for(const item of favorites){
  assert.ok(item.chapters[item.main], `${item.id}: main event exists`);
  for(const chapter of item.chapters){
    const show=catalog.find(show=>show.id===chapter.show);
    assert.ok(show, `${chapter.show}: broadcast exists`);
    assert.ok(chapter.at>=0&&chapter.at<show.duration, `${chapter.title}: valid seek position`);
    const data=JSON.parse(readFileSync(new URL(`../data/shows/${chapter.show}.json`,import.meta.url)));
    assert.ok(data.transcript.some(line=>Math.abs(line.startTime-chapter.at)<3), `${chapter.title}: transcript anchor exists`);
    chapters++;
  }
}
const listeners={};
globalThis.document={addEventListener:(event,handler)=>{listeners[event]=handler;}};
const room=createFavorites({escape:value=>String(value),time:String,date:String,playChapter:async()=>{}});
assert.match(room.render(),/Fan favorites/);
assert.doesNotMatch(room.render(),/ff-feature|Start with a classic/);
assert.equal(favorites[0].id,'missing-gary-puppet');
assert.equal(favorites.at(-1).id,'howard-vs-sam-kinison');
assert.equal(favorites.filter(item=>item.era==='Cassette').length,6);
assert.doesNotMatch(room.render(),/favorite-search|favorite-filter|Not just a date on the dial/);
for(const item of favorites){
  const html=room.render(item.id);
  assert.ok(html.includes(item.title));
  assert.equal((html.match(/class="ff-chapter"/g)||[]).length,item.chapters.length);
  assert.match(html,/Sources & editorial notes/);
}
assert.match(room.render('missing'),/Collection not found/);
console.log(`PASS: ${favorites.length} collections, ${chapters} catalog/transcript anchors, detail rendering, unknown route.`);
