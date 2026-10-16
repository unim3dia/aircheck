# Fan favorites — local first edition

Not published. New routes: `#favorites` and `#favorites/<collection-id>`.

## Editorial approach

Fans use recognizable names and ask for chronology, not just the date of a broadcast. Build listening paths: a direct main-event button, then optional context. Keep the ordinary chronological archive available beside it. No vote totals, invented popularity rankings, or claims of a complete canon.

The frontend-design direction is a restrained listening-room / tape-sleeve treatment using the existing cream, charcoal, red, and serif typography. No extra player; chapter links use the existing audio element and full stream. Playback does not automatically jump between curated stops: these are full-show entry points, not bounded clips.

## Evidence consulted

- Fan demand for the setup: https://www.reddit.com/r/howardstern/comments/1kfi0zh
- Timeline questions: https://www.reddit.com/r/howardstern/comments/18pg0zh
- Contemporary Bro Fight account, May 24, 2007: https://artiefan.wordpress.com/2007/05/24/superbout-howard-stern-vs-artie-lange/
- Official dinner rundown: https://www.howardstern.com/show/2007/04/30/arties-weekend-of-on-screen-sex-rundowngallerymodel-9960/
- Official June 14 rundown: https://www.howardstern.com/show/2007/06/14/arties-costume-emotional-friend-rundowngallerymodel-9666/
- Official June 27 rundown: https://www.howardstern.com/show/2007/06/27/when-you-least-expect-itexpect-it-rundowngallerymodel-9586/

The supplied research is a lead list, not a verified index. Fan discussions disagree on some dates. Do not use them alone to establish chronology or private-life allegations.

## Current curation

Eight collections / forty-nine entry points. All timestamps were checked against the local machine transcripts. They have NOT received a full listening audit. Each collection discloses this. The Artie/Dice and Gary roast entries are anchored to the local transcripts, without claiming an independently verified historical rundown.

Gay Papa: `node web/build_gay_papa.mjs` reproducibly indexes title/spelling-variant mentions, including cross-row matches, into `gay-papa.generated.js`. Current coverage: 131 matching transcript rows, 25 broadcasts, 37 chronological groups (maximum three-minute gap between hits). Each group retains all matching timestamps for audit and adds up to 15 seconds of lead-in. Original song, covers, Sal version, stylistic remakes, and passing callbacks are included. No lyric excerpts are copied. Machine transcription can miss mentions; this is not an exhaustive audio claim. Official May 7 and October 25, 2007 rundowns corroborate the Bleeding Deacons progression; source links are included in the collection.

Second revision removes the collection search, category filters, and introductory explanatory sentence. Archive-wide search remains unchanged.

Added Mike Walker's fart (March 21, 2006 replay, explicitly not the premiere), Crazy Alice (June 15, 2006 call, also identified in the 2012 Fight Week rundown), and Artie vs. Sal/Richard (October 31 dispute and November 1 fallout). Source links live with each entry in favorites.js. The November chapter references the Wrap-Up Show but is not a standalone recording of that program.

Bro Fight: April 30 dinner is related context, not asserted to cause the fight. May 23 entry is during Jen's visit, not its exact beginning. May 24 opens at zero.

Emotional Friend: two June chapters only. Frame statements as on-air accounts, not facts about a private relationship.

Gary roast: first entry includes the handoff from the preceding interview; second enters the musical interlude.

## Expansion after review

Research Ronnie's limo, the Artie roast, and High Pitch Mike next. Verify original broadcast versus replay, then match the actual file. Do not label the September 13, 2006 apology discussion as the original famous Sal apology without verifying it. Teddy's fight belongs outside this 2006/2007 edition.

Before production: listen-audit boundaries; consider a bounded saga queue only after end times are verified; user approval required before publishing.

Checks: `node web/tests/favorites.test.mjs`; `node --check web/app.js`; `node --check web/favorites.js`.
