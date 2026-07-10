# Airhcheck

Airhcheck is a personal, native iOS listening room for a year of long-form radio. It turns an undifferentiated 826-hour Internet Archive item into a calendar, a searchable transcript, and a visual story index whose entries seek the player to the exact conversation.

## Product promise

Open on a date, understand what happened, tap a story, and keep listening with the screen locked.

## Audience and tone

The first user is a devoted listener revisiting the first Sirius year. The interface should feel intimate, literate, slightly mischievous, and obsessively organized. It should honor radio craft without copying official Stern or SiriusXM trade dress.

## Core journeys

- As a listener, I can browse twelve months and select a broadcast date.
- As a listener, I can start a stream and continue through lock screen, headphones, Control Center, and other apps.
- As a listener, I can resume every show where I stopped and see overall listening progress.
- As a researcher, I can search people, teams, phrases, and topics across titles and transcripts, then jump to the matching second.
- As a reader, I can follow a synchronized transcript and tap any passage to seek.
- As a curious listener, I can scan an editorial story map before committing to a four- or five-hour show.

## Visual system

- **Direction:** soft editorial radio.
- **Palette:** warm paper, near-black ink, oxidized red, faded peach, pale signal blue.
- **Typography:** New York for editorial headlines and dates; SF Pro Rounded for controls and metadata; monospaced numerals for timecode.
- **Composition:** oversized date fields, offset story modules, restrained soft depth, no generic podcast-card grid.
- **Motion:** a tuning line breathes only while audio plays; content reveals in a short stagger; transcript movement follows playback but yields immediately to manual scrolling and Reduce Motion.

## Content and rights boundary

The configured Internet Archive item exposes recordings but supplies no `licenseurl` or `rights` metadata. Availability is not proof of public-domain status. The app therefore stores only source URLs and user-generated analysis, labels the source, and makes no public-domain or redistribution claim. Publication in the App Store should wait for rights review.

## Vertical-slice acceptance criteria

1. Real archive metadata produces a correctly ordered 2006 calendar despite the `04-20-96` source typo.
2. A real MP3 begins streaming and lock-screen metadata/transport controls are registered.
3. One show can display timestamped transcript segments and editorial topics.
4. Search returns topic and transcript hits with deterministic jump times.
5. Playback position survives app relaunch.
6. Unit tests pass and an iPhone simulator build succeeds.
