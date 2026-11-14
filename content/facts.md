# Fact check — lookalikes.json & README §7.6

Checked Sat 14 Nov 2026 against NASA mission pages (Member C, Daniel).
**Owner note:** `data/lookalikes.json` is Member A's file — please apply the three updates
marked **[UPDATE]** below. Everything else already checks out.

## ✅ Verified as-is

| Mission | Launch year | Source |
|---|---|---|
| Landsat 9 | 2021 — Sept 27, 2021 | https://science.nasa.gov/mission/landsat-9/ |
| PACE | 2024 — Feb 8, 2024 | https://science.nasa.gov/mission/pace/ |
| LRO | 2009 — June 18, 2009 | https://science.nasa.gov/mission/lro/ |
| MRO | 2005 — Aug 12, 2005 (orbit Mar 10, 2006) | https://science.nasa.gov/mission/mars-reconnaissance-orbiter/ |
| MAVEN | 2013 — Nov 18, 2013 | https://science.nasa.gov/mission/maven/ |
| Juno | 2011 — Aug 5, 2011 (orbit July 4, 2016) | https://science.nasa.gov/mission/juno/ |
| Europa Clipper | 2024 — Oct 14, 2024 (Falcon Heavy, KSC) | https://science.nasa.gov/mission/europa-clipper/ |
| Cassini | 1997 — Oct 15, 1997 | https://science.nasa.gov/mission/cassini/ |

Bonus check: every `traits` id in `lookalikes.json` maps to a real id in
`instruments.json` / `power.json` / `buses.json` / `comms.json` — `Sim.find_lookalike()`
has no broken references.

## **[UPDATE]** — suggested JSON changes

### 1. `cubesats` (fact is out of date — NASA's own count moved on)
- Old: *"Since 2011, NASA has launched over 150 small CubeSats built by students and universities."*
- New: *"Since 2011, NASA has helped more than 180 student-built CubeSats reach orbit."*
- Source: NASA CSLI page says "As of October 2026, CSLI has selected 228 CubeSat missions, including more than 180 that have launched."
  https://nasa.gov/kennedy/launch-services-program/cubesat-launch-initiative/

### 2. `lro` (stale "15 years"; cooler fact available)
- Old: *"Has mapped the Moon in detail for over 15 years."*
- New: *"Its camera is sharp enough to photograph the Apollo landing sites — rover tracks and astronaut trails are still visible from orbit."*
- Source: NASA's LRO Apollo landing-site imagery releases (2009–2011):
  https://science.nasa.gov/science-news/science-at-nasa/2009/17jul_lroc
  https://nasa.gov/home/hqnews/2011/sep/HQ_11-289_LRO_Images.html

### 3. `maven` (the mission has now ended — worth reflecting)
- Old: *"Studies how Mars lost most of its atmosphere to space."*
- New: *"Watched Mars lose its atmosphere to space for 12 years before going silent in 2025."*
- Source: MAVEN page — "End of Mission Declared June 3, 2026, after contact had been lost since Dec. 6, 2025. Mission Duration 12 years, 6 months, 16 days."
  https://science.nasa.gov/mission/maven/

## ⚠️ One claim I could not verify on the current page

### `mro` — *"More data than all earlier Mars missions combined."*
This is a widely used NASA/JPL line, but it is **not on** https://science.nasa.gov/mission/mars-reconnaissance-orbiter/
today. Two verified alternatives from that page:
- *"Its HiRISE camera is the largest camera ever flown on a planetary mission."*
- *"It works as a relay station — an 'interplanetary internet' — that sends data home for other Mars spacecraft."*

Member A's call: keep the old line, or switch to the HiRISE one (easiest to defend to judges).

## 💡 Optional richer facts (only if A wants punchier wording)

- **landsat9:** with Landsat 8 in orbit, the two satellites photograph every place on Earth every 8 days.
- **juno:** also the first spacecraft to orbit an outer planet from pole to pole.
- **clipper:** its solar wings span about 100 feet — the length of a basketball court — and Europa's hidden ocean may hold twice as much water as all Earth's oceans combined.
- **cassini:** the Saturn system was Cassini's home for 13 years, ending with the 2017 "Grand Finale" dive.
