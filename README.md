# 🚀 Go/No-Go

*"Go/No-Go" is the real call every flight controller makes before launch. In this game, you earn it.*

**Repository:** https://github.com/rashedutm/Go-No-Go

> **NASA Space Apps Challenge 2026 — "Space Mission Design Game"**
> Solo, single-player educational game built in **Godot 4.7.2**, exported to **Web (HTML5)** so judges can play in a browser.
> **Deadline: Sunday 15 Nov 2026, 11:30 PM local time** (official cut-off is 11:59 PM — we aim 30 min early).

---

## 👥 TEAM SPLIT — START HERE

We are 3 people working in parallel and merging through **GitHub**. Each person **owns different folders**, so our work never overwrites each other's (Godot scene files merge very badly).

| Member | Has AI? | Owns | Read these sections |
|---|---|---|---|
| **Member A — Lead / Integrator** (team owner) | Claude | Project setup, shared code, **Design phase**, campaign map, Web export & upload | §A below, then §3–§8 |
| **Member B — Mission Control dev** | Claude Pro | **Live Mission Control**, **Events**, **Debrief** | §B below, then §6.7–§6.10, §7.6, §8 |
| **Member C — Content, Art & Pitch** | No AI needed | Art & sound collection, playtesting, **demo video/slides**, submission text | §C below |

### 🛠️ Getting started (everyone)

**Repo:** https://github.com/rashedutm/Go-No-Go (Member A is the owner and adds the others as collaborators. Accept the email invite first.)

**Members A & B (coders):**
1. Install **Git** and **Godot 4.7.2** (standard version, not .NET).
2. Clone:
   ```bash
   git clone https://github.com/rashedutm/Go-No-Go.git
   cd Go-No-Go
   ```
3. Member B only: create your branch:
   ```bash
   git checkout -b feat/mission-control
   ```
4. Open Godot → **Import** → select `project.godot` in the cloned folder (exists after Member A's first push, M1).
5. Install **Web export templates**: Godot → *Editor → Manage Export Templates → Download and Install*.
6. Daily loop: `git pull` → work → `git add -A` → `git commit -m "short message"` → `git push`.
   Member B pushes with `git push -u origin feat/mission-control` the first time, then opens a Pull Request on GitHub.

**Member C (no coding):** open https://github.com/rashedutm/Go-No-Go in the browser → go into the `content/` folder → **Add file → Upload files** → write a short message → **Commit changes**. That's it.

**Backup rule:** if any part is not merged by its checkpoint time (see §9), Member A (or whoever is free) takes it over in a smaller "lite" version. Nobody waits on anybody — always build against the shared contract (§8.1) with fake data if the real part isn't ready.

---

### §A — Member A: Lead / Integrator

**Goal:** the skeleton everyone builds on, plus the whole *before-launch* half of the game.

1. **First 1–2 hours (blocks others — do this first, push immediately):**
   - Create the Godot 4.7.2 project in the repo root, `.gitignore` (§8.2), folder layout (§8), shared `Theme`.
   - Write all `data/*.json` files from §7.
   - Write the three autoloads exactly as in the contract (§8.1): `GameData`, `MissionState`, `Sim`.
   - Make an empty scene for every screen with a "Next" button so the full flow (§3) is clickable end-to-end.
   - Push to `main` and tell Member B "skeleton is up".
2. Build **Title**, **Campaign map**, **Briefing**, **Design (4 stations)** + resource bar, **Launch check** (M2, M3, M7).
3. Merge Member B's branch, fix integration issues.
4. Add Member C's art/sounds as they arrive.
5. **Web export + upload** (M8) and test in a private browser window.

**Prompt to paste into your AI:**
> "Read README.md fully. I am Member A (Lead/Integrator). Start with §A step 1: create the Godot 4.7.2 project skeleton, the JSON data files from §7, and the three autoloads exactly matching the contract in §8.1. Only touch folders I own (§8.3)."

---

### §B — Member B: Mission Control developer

**Goal:** the *after-launch* half — the exciting live part and the ending.

1. Clone the repo. **Don't wait for Member A**: start in your own folders with a **fake design** (`Sim.make_test_design()` from §8.1 — if it doesn't exist yet, create a local copy of that dictionary inside your scene for testing).
2. Build **Live Mission Control** scene (`scenes/mission_control/`) — ticking simulation, gauges, quick actions, time speed controls (§6.7). → M4
3. Build the **Events system** (`scripts/events/`, `data/events.json`) — at least 8 events from §6.8 with choice cards and timers. → M5
4. Build the **Debrief** scene (`scenes/debrief/`) — score, stars, NASA look-alike, cause→effect lines, retry/next buttons (§6.9, §6.10, §7.6). → M6
5. Work on branch `feat/mission-control`, push often, open a Pull Request to `main` after each milestone.
6. **Only read from** `MissionState` / `GameData` / `Sim` — never edit those files. If you need a new shared function, ask Member A (or add it in your own script).

**Prompt to paste into your AI:**
> "Read README.md fully. I am Member B (Mission Control developer). Build §B: the Live Mission Control scene, events system and debrief, in Godot 4.7.2 GDScript. Use the shared contract in §8.1 as the only interface to the rest of the game, use a fake test design until the real one exists, and only create/edit files in the folders I own (§8.3)."

---

### §C — Member C: Content, Art & Pitch (no AI or coding needed)

Small tasks, but each one really matters for the **Presentation** score. Put everything in the repo folder `content/` (upload via the GitHub website: *Add file → Upload files*) or send to Member A.

1. **Collect free icons & art** (by Sat night): spacecraft parts, planets, gauges, UI icons. Use sites with free licenses, e.g. **Kenney.nl** (CC0), **OpenGameArt.org**, **NASA image library** (images.nasa.gov — NASA images are free to use, but **no NASA logo/meatball/worm**). For every file, write the **source link + license** in `content/CREDITS.md`.
2. **Collect 3–5 sounds** (by Sat night): button click, alarm beep, launch rumble, success jingle — from **freesound.org** (CC0) or **Kenney**. Add to `CREDITS.md`.
3. **Check the facts** in §7.6 on **science.nasa.gov** (launch years, one fun fact each). Fix any mistakes in `content/facts.md`.
4. **Suggest game names** (5 ideas) in the team chat — we pick one.
5. **Playtest** (Sunday afternoon): play every mission, write bugs in `content/bugs.md` like: *"Mission 3, clicked RTG, budget went negative, nothing happened."*
6. **Make the demo** (Sunday evening): either a **video of 30 seconds or less** (record the screen with OBS or Xbox Game Bar `Win+G`, add English subtitles), **or 7 slides max** (Google Slides/Canva): Title · Team & challenge · Problem · Our game (screenshots) · How it teaches trade-offs · NASA data used · Future. Use the script in §10.1.
7. **Draft the submission text** in `content/submission.md`: project summary, description, tools used (from §10).

---

## 0. Note for AI assistants reading this file

You are helping a small team build this game for a hackathon with a hard deadline.
- **First ask (or check) which member you are working for (A, B or C) and stick to that member's section and owned folders (§8.3).** Never edit files owned by another member — create a new file in your own folder instead.
- The shared code contract (§8.1) is fixed. Don't rename its functions, fields or signals.
- Follow this README as the **source of truth** for design, data, and scope. Do not add multiplayer, 3D, or features marked *Stretch* until every *Core* milestone works.
- Engine: **Godot 4.7.2, GDScript only** (no C#, no plugins that block Web export).
- Keep all game numbers in **`data/*.json`** files (tables in §7), never hard-coded in scripts, so designers can tune balance without touching code.
- Every system must explain itself to the player in **plain English** (the target player is a beginner student).
- Code files must start with a one-line header comment: `# Part of Go/No-Go — written with AI assistance (Space Apps 2026).` (required AI disclosure, see §11).

---

## 1. The challenge (summary)

From the official challenge statement: *create an interactive game that lets participants design, manage, and simulate a complete space mission while making engineering decisions, managing limited resources, and evaluating how each choice shapes mission success.*

Judges score 1–5 on: **Impact · Creativity · Validity** (scientifically sound, usable) **· Relevance** (NASA data/resources used as a core part) **· Presentation**.

## 2. Our concept in one paragraph

The player is the **whole mission team** of a robotic space mission. They travel a **campaign across the Solar System — Earth orbit → Moon → Mars → Jupiter → Saturn**. For each mission they read a science objective, then design the spacecraft by switching between **four role stations** (Mission Director, Spacecraft Engineer, Science Lead, Comms & Ops). Every part costs **mass, power, money and data**. After passing a **launch check**, the mission goes into **LIVE MISSION CONTROL**: time runs, batteries drain in eclipses, data piles up waiting for downlink, and **events** hit — solar storms, failing hardware, communication blackouts, surprise discoveries — that the player must answer quickly. At the end, a **debrief** scores science returned, budget efficiency and survival, and reveals **which real NASA mission their design resembles**.

**Core lesson:** there is no single perfect design — every choice helps one thing and hurts another, and the farther you go from the Sun, the harder power and communication become.

### Design pillars
1. **Every choice has a visible consequence** (bars move instantly when a part is added).
2. **Real physics, simple words** (sunlight falls with distance², signals take minutes to arrive from Mars).
3. **Learn by failing** — failing is fast, explained, and you can redesign and relaunch.
4. **Friendly mission-control look** — real dashboards and gauges drawn in a clean, colorful cartoon style.

### Decisions already made (do not reopen)
| Topic | Decision |
|---|---|
| Players | **Solo only.** No multiplayer. One player controls all 4 role stations. |
| Destinations | Whole Solar System, unlocked as a **campaign** |
| After launch | **Live mission control** with real-time events |
| Events | Space weather · Hardware failures · Comms/data limits · Science opportunities |
| Score | **Science returned · Budget efficiency · Mission survival** |
| Debrief | **"Your design is like this real NASA mission"** + short cause→effect lines |
| Style | Mission-control dashboard × friendly cartoon |
| Name | **Go/No-Go** (repo: `rashedutm/Go-No-Go`). The title screen explains the term in one line. |

---

## 3. Game flow

```
Title ─► Campaign Map ─► Mission Briefing ─► DESIGN (4 stations) ─► Launch Check
                ▲                                    ▲                    │ fail → back to Design (with reasons)
                │                                    │                    ▼ pass
                │                                    └── Redesign ◄── Launch animation
                │                                                         ▼
                └──────── unlock next ◄── DEBRIEF ◄── LIVE MISSION CONTROL
```

1. **Title** – Play / How to play / Credits & references.
2. **Campaign map** – Solar System strip; locked planets greyed. A mission unlocks when the previous one earns ≥ 1 star.
3. **Mission briefing** – objective, science goal (data to return), budget, minimum lifetime, a "Did you know?" fact.
4. **Design** – four tabs/stations (§5). A **resource bar** is always visible at the top: Budget · Mass · Power balance · Data balance · Schedule.
5. **Launch check** – automatic checklist (§6.6). Each failed item explains *why* in one sentence and which station fixes it.
6. **Launch animation** – short 2D cartoon launch + cruise to target (skippable).
7. **Live mission control** – 3–5 real minutes per mission (§6.7).
8. **Debrief** – score, stars, NASA look-alike card, cause→effect lines, buttons: *Redesign & retry* / *Next mission*.

---

## 4. Campaign missions

| # | Mission | Destination | Objective (science goal) | Budget | Min. lifetime | Data goal | Difficulty |
|---|---|---|---|---|---|---|---|
| 1 | **Fire Watch** | Low Earth Orbit (500 km) | Map wildfires & vegetation | $150 M | 2 yr | 500 Gb | ★ |
| 2 | **Moon Mapper** | Lunar orbit (50 km) | Map the surface, look for water ice at the poles | $350 M | 1 yr | 300 Gb | ★★ |
| 3 | **Red Planet Weather** | Mars orbit | Study Mars atmosphere & dust storms | $600 M | 2 yr | 200 Gb | ★★★ |
| 4 | **Giant's Secret** | Jupiter orbit | Study Jupiter's interior, magnetic field, radiation | $1,100 M | 2 yr | 40 Gb | ★★★★ |
| 5 | **Ringworld** | Saturn orbit | Study rings and moons (Titan, Enceladus) | $1,500 M | 4 yr | 30 Gb | ★★★★★ |

Each mission also lists **required instrument types** (at least one must be carried) — see `missions.json` in §7.

---

## 5. The four role stations (design phase)

The solo player clicks between stations. Each station shows its parts as **cards** with icons and the four stat chips: 💰 cost · ⚖️ mass · ⚡ power · 💾 data. Hovering a card shows a one-sentence plain-English explanation.

### 5.1 Mission Director 🧑‍✈️
- Chooses **launch vehicle** (capacity vs. cost).
- Sees total **budget**, keeps a **reserve** (unspent money can be used during live events to fix problems; leftover reserve adds to Budget score).
- Picks **mission duration target** (longer = more science, more operations cost & wear).

### 5.2 Spacecraft Engineer 🔧
- **Bus size** (structure/frame): Small / Medium / Large — sets max slots for parts.
- **Power source**: Solar arrays (S/M/L/XL) or **RTG** (nuclear; expensive, works anywhere).
- **Battery** size (survive eclipses & peak loads).
- **Radiation shielding** level (needed at Jupiter).
- **Propulsion**: propellant for orbit insertion is calculated automatically from mass (§6.3).

### 5.3 Science Lead 🔬
- Picks **instruments** (each: cost, mass, power, data per day, science value, type).
- Must carry the mission's required instrument type(s).

### 5.4 Comms & Ops 📡
- **Antenna**: Low-gain / Medium-gain / High-gain dish (data rate vs. mass & power).
- **Onboard data storage** (Gb).
- **Ground network**: Basic (few contacts/day) or Deep Space Network-style 3-site network (contacts all day, more expensive).

---

## 6. Systems & formulas (simplified but physically honest)

All values come from the JSON tables in §7. Distances in AU (Earth–Sun = 1 AU).

### 6.1 Budget
`total_cost = launch_vehicle + bus + power + battery + shielding + instruments + antenna + storage + ground_network × years + ops_cost_per_year × years`
Must be ≤ mission budget. Unspent money = **reserve**.

### 6.2 Mass
`dry_mass = bus + power + battery + shielding + instruments + antenna + storage`

### 6.3 Propellant (rocket equation — real, simple)
`propellant = dry_mass × (exp(Δv / (Isp × 9.81)) − 1)` with `Isp = 320 s`.
Orbit-insertion Δv per destination (m/s): Earth LEO 0 · Moon 900 · Mars 1000 · Jupiter 900 · Saturn 650.
`wet_mass = dry_mass + propellant`.
*Teaching line:* "Heavier spacecraft need more fuel to brake into orbit — and fuel is heavy too!"

### 6.4 Power
- Solar output at destination: `P_solar = P_rated_at_1AU / (distance_AU²)`.
  Mars 1.52 AU → 43 %; Jupiter 5.2 AU → 3.7 %; Saturn 9.5 AU → 1.1 %.
- RTG: constant output, loses ~1.5 %/year.
- `power_load = bus_base_load + Σ instrument_power + antenna_power(when transmitting) + heater_load(destination)`.
- **Power balance** must be ≥ 0 in sunlight. In **eclipse** (LEO: 35 of every 95 min; Moon: 47 of 113 min; others: rare) the **battery** must cover `power_load × eclipse_time`.
*Teaching line:* "At Saturn the Sun is 90× dimmer than at Earth. That's why Cassini used a nuclear power source."

### 6.5 Data & communications
- Data produced per day: `Σ instrument_data_per_day`.
- Downlink per day: `antenna_rate_at_1AU × network_factor × (1 / distance_from_Earth_AU²) × contact_hours_per_day` (capped at the antenna's max rate). Distances from Earth: LEO/Moon use fixed near-Earth rates.
- If produced > downlinked, storage fills up; when full, new science is **lost**.
- **Signal delay** (shown on screen): Moon 1.3 s · Mars 3–22 min · Jupiter 33–53 min · Saturn 68–84 min. At Mars and beyond, live commands arrive after a visible delay (compressed in game time).

### 6.6 Launch check (all must pass)
| Check | Rule | Fix hint shown |
|---|---|---|
| Fits the rocket | `wet_mass ≤ launcher_capacity[destination]` | "Choose a bigger rocket or remove mass." |
| Rocket can reach target | launcher supports destination | "This rocket can't escape Earth's gravity." |
| Within budget | `total_cost ≤ budget` | "Remove parts or choose cheaper ones." |
| Power positive | sunlight balance ≥ 0 | "Add solar area, switch to RTG, or remove power-hungry instruments." |
| Survives eclipse | battery ≥ eclipse energy | "Bigger battery." |
| Science goal reachable | `downlink × lifetime ≥ data_goal` (estimate) | "Better antenna, bigger network, or more storage." |
| Required instrument | mission's required type is carried | "Science Lead must add a ___." |
| Radiation (Jupiter only) | shielding ≥ Medium | "Jupiter's radiation will fry unshielded electronics." |

### 6.7 Live Mission Control
- Screen layout: center = cartoon spacecraft orbiting the target; left = gauges (Battery %, Power in/out, Storage %, Data returned vs goal, Health %, Fuel, Reserve $); right = **event log**; bottom = 4 station buttons with quick actions.
- **Time compression:** total mission plays in ~3–5 real minutes (e.g. 1 s ≈ 4 days). Player can pause, ×1, ×2.
- **Each tick:** generate power → charge/drain battery → instruments add data to storage → downlink when a ground contact is active → wear reduces health slightly.
- **Quick actions** (always available):
  - Science: toggle each instrument on/off.
  - Engineer: **Safe mode** (instruments off, power saved, no science).
  - Comms: downlink priority / switch antenna mode.
  - Director: spend reserve on repairs or extra ground-station time.
- **Events** fire every ~20–40 real seconds (weighted by destination). Each shows a card with 2–3 choices and a 10–15 s timer (pausing allowed on Easy). Missing the timer = default (usually worst) outcome.
- **Mission ends** when lifetime reached, health = 0, or battery dead too long.

### 6.8 Events (examples — full list in `events.json`)
| Category | Event | Choices → consequences |
|---|---|---|
| Space weather | **Solar storm** | Safe mode (lose 3 days science) / Keep working (risk −25 % health, lower with shielding) |
| Space weather | **Micrometeoroid hit** | Spend $20 M reserve to reroute systems / Accept −15 % power |
| Hardware | **Battery degrading** | Turn off one instrument / Accept shorter eclipse survival |
| Hardware | **Stuck solar panel** | Engineering fix ($15 M, 70 % success) / Live with −30 % solar |
| Comms | **Ground station offline** | Buy extra contact time ($10 M) / Store data and hope storage holds |
| Comms | **Storage almost full** | Delete low-value data / Pause instruments |
| Science | **Volcano / dust storm / plume spotted!** | Point instruments now (+bonus science, −battery) / Ignore |
| Science | **Comet flyby** | Retarget (+science, −fuel) / Ignore |

Each outcome writes a cause→effect line into the log, reused in the debrief.

### 6.9 Scoring
| Component | Weight | Formula |
|---|---|---|
| **Science returned** | 50 % | `min(data_returned / data_goal, 1.5) / 1.5 × 100` (bonus for over-delivery) + event science bonuses |
| **Mission survival** | 30 % | `min(actual_lifetime / target_lifetime, 1) × 100` |
| **Budget efficiency** | 20 % | `(reserve_left / budget) × 200`, capped at 100 |

Stars: ★ ≥ 40 · ★★ ≥ 65 · ★★★ ≥ 85. A mission with 0 stars = failed (explained in debrief).

### 6.10 Debrief
1. Big score, stars, the 3 component bars.
2. **"Your mission is like…"** card — the closest real NASA mission (§7.6) with a short fun fact and launch year.
3. **3 cause→effect lines** pulled from the run (e.g. "Your battery was too small for Earth's shadow → 18 % of orbits ran on low power → less science.")
4. Buttons: **Redesign & retry** (design is kept) · **Next mission**.
5. Local high score per mission (saved with `ConfigFile` in `user://`).

---

## 7. Data tables (put these in `data/*.json`)

Numbers are simplified and rounded for gameplay, but chosen to be in realistic proportion.

### 7.1 Launch vehicles (generic names — do not use real company logos/brands)
| id | Name | Cost $M | LEO kg | Moon kg | Mars kg | Jupiter kg | Saturn kg |
|---|---|---|---|---|---|---|---|
| small | Sparrow (small launcher) | 10 | 300 | – | – | – | – |
| medium | Kestrel (medium launcher) | 70 | 15,000 | 3,500 | 2,500 | 900 | – |
| heavy | Heavy-lift | 150 | 50,000 | 14,000 | 10,000 | 4,500 | 3,500 |
| super | Super heavy | 400 | 90,000 | 27,000 | 20,000 | 9,000 | 7,000 |
| rideshare | CubeSat rideshare | 2 | 50 | – | – | – | – |

### 7.2 Spacecraft bus
| id | Name | Cost $M | Mass kg | Base power W | Part slots |
|---|---|---|---|---|---|
| cube | 12U CubeSat | 3 | 24 | 10 | 3 |
| small | Small bus | 40 | 300 | 120 | 6 |
| medium | Medium bus | 90 | 900 | 300 | 9 |
| large | Large bus | 180 | 2,000 | 500 | 12 |

(12U CubeSat max mass ~24 kg follows NASA CubeSat 101: ~1.33 kg per 1U.)

### 7.3 Power, battery, shielding
| id | Name | Cost $M | Mass kg | Output W @1 AU | Notes |
|---|---|---|---|---|---|
| solar_s | Small solar array | 5 | 20 | 300 | |
| solar_m | Medium solar array | 12 | 60 | 1,500 | |
| solar_l | Large solar array | 30 | 150 | 5,000 | |
| solar_xl | Giant solar wings | 70 | 340 | 14,000 | Juno-style, only realistic option for solar at Jupiter |
| rtg | RTG (nuclear) | 120 | 45 | 110 constant | Does not depend on sunlight, −1.5 %/yr |
| batt_s / m / l | Battery 200 / 800 / 2,000 Wh | 1 / 3 / 7 | 4 / 15 / 35 | – | |
| shield_none / med / heavy | Radiation shielding | 0 / 25 / 60 | 0 / 80 / 200 | – | Jupiter needs ≥ med |

Heater load by destination (W): Earth 0 · Moon 20 · Mars 40 · Jupiter 120 · Saturn 150.

### 7.4 Instruments
| id | Name | Type | Cost $M | Mass kg | Power W | Data Gb/day | Science pts | Plain-English description |
|---|---|---|---|---|---|---|---|---|
| cam_wide | Wide camera | imaging | 8 | 15 | 20 | 1.5 | 10 | Takes color pictures of large areas. |
| cam_hires | High-resolution camera | imaging | 25 | 60 | 60 | 4.0 | 25 | Sees small details — makes lots of data. |
| ir_spec | Infrared spectrometer | spectro | 30 | 35 | 40 | 1.0 | 25 | Detects heat & what surfaces are made of (e.g. water ice). |
| radar | Radar sounder | radar | 40 | 90 | 150 | 2.0 | 30 | Sees under the surface and through clouds/dust. |
| magnet | Magnetometer | fields | 6 | 5 | 5 | 0.05 | 12 | Measures magnetic fields — tells us about the inside of planets. |
| particle | Particle & radiation detector | fields | 10 | 10 | 10 | 0.1 | 12 | Measures charged particles and radiation. |
| microwave | Microwave radiometer | interior | 35 | 50 | 40 | 0.3 | 30 | Looks deep into giant-planet atmospheres. |
| altimeter | Laser altimeter | mapping | 18 | 20 | 35 | 0.5 | 18 | Measures height of mountains and craters. |
| dust | Dust analyzer | sampling | 15 | 15 | 15 | 0.05 | 15 | Catches & analyses dust and plume particles. |

### 7.5 Comms & ground
| id | Name | Cost $M | Mass kg | Power W | Max rate (Mbps @1 AU) |
|---|---|---|---|---|---|
| lga | Low-gain antenna | 2 | 3 | 15 | 0.05 |
| mga | Medium-gain antenna | 10 | 15 | 40 | 1 |
| hga | High-gain dish | 30 | 60 | 80 | 20 |
| stor_s / m / l | Storage 32 / 256 / 1,000 Gb | 1 / 3 / 8 | 1 / 3 / 6 | 2 / 5 / 10 | – |
| net_basic | Basic ground network | 3/yr | – | – | 4 h contact/day |
| net_deep | 3-site deep-space network | 12/yr | – | – | 16 h contact/day |

Operations cost: $8 M/year near Earth, $20 M/year deep space.

### 7.6 NASA look-alike matches (debrief)
Pick the entry with the same destination whose traits best match the player's design.
| Destination | Real mission | Match trait | Fun fact (keep wording short) |
|---|---|---|---|
| Earth | **Landsat 9** (2021) | cameras/imaging | Part of a 50-year record of Earth images. |
| Earth | **PACE** (2024) | spectrometer | Studies ocean color, tiny plankton and aerosols. |
| Moon | **Lunar Reconnaissance Orbiter** (2009) | cameras + altimeter | Has mapped the Moon in detail for over 15 years. |
| Mars | **Mars Reconnaissance Orbiter** (2005) | hi-res camera + radar | Has sent back more data than all earlier Mars missions combined. |
| Mars | **MAVEN** (2013) | particle/fields | Studies how Mars lost its atmosphere to space. |
| Jupiter | **Juno** (2011) | solar + microwave/magnet | First solar-powered spacecraft to operate at Jupiter. |
| Jupiter | **Europa Clipper** (2024) | radar + shielding | Uses huge solar arrays and a radiation vault to study icy Europa. |
| Saturn | **Cassini** (1997) | RTG + many instruments | Orbited Saturn for 13 years and ended with a "Grand Finale" dive in 2017. |

---

## 8. Tech plan (Godot)

- **Godot 4.7.2**, GDScript, 2D only, resolution 1280×720 stretch (`canvas_items`, `expand`).
- **Web export** (HTML5) — requires installing **Web export templates** (Editor → Manage Export Templates). Use the *no-threads* variant for easy hosting (itch.io / GitHub Pages).
- Autoloads (singletons):
  - `GameData` — loads all `data/*.json` at startup.
  - `MissionState` — current mission, current design, campaign progress, save/load.
  - `Sim` — design calculations (§6.1–6.6) as **pure functions** (easy to test).
- Folder layout:
```
res://
  data/          launch_vehicles.json, buses.json, power.json, instruments.json,
                 comms.json, missions.json, events.json, lookalikes.json
  scenes/        title/, campaign_map/, briefing/, design/, launch_check/,
                 launch_anim/, mission_control/, debrief/
  scripts/       autoload/ (game_data.gd, mission_state.gd, sim.gd), ui/
  ui/            theme.tres, fonts/, icons/
  art/           spacecraft/, planets/, backgrounds/  (AI-generated art must carry a small visible "AI-generated" watermark)
  audio/
```
- UI: Godot `Control` nodes + one shared `Theme` (rounded panels, bright accent colors, dark-navy background).
- Tooltips everywhere: each card's `description` field from JSON.

### 8.1 Shared code contract (fixed — this is how A's and B's parts talk to each other)

All three are **autoloads** (Project Settings → Globals), written by Member A. Member B only *reads/calls* them.

**`GameData`** (`scripts/autoload/game_data.gd`)
```gdscript
func get_table(table_name: String) -> Array          # e.g. "instruments" → Array of Dictionary
func get_item(table_name: String, id: String) -> Dictionary
func get_mission(mission_id: String) -> Dictionary
```
Tables = file names in `data/` without `.json`: `launch_vehicles, buses, power, instruments, comms, missions, events, lookalikes`.
Every item has at least: `id, name, description` plus its numeric fields (names from §7, snake_case: `cost_musd, mass_kg, power_w, data_gb_day, science_pts, type`).

`missions.json` item fields:
`id, name, destination, distance_sun_au, distance_earth_au, budget_musd, min_years, data_goal_gb, required_types (Array), delta_v_ms, eclipse_period_min, eclipse_shadow_min, heater_w, ops_cost_musd_year, needs_shielding (bool), signal_delay_min, fact`.

**`MissionState`** (`scripts/autoload/mission_state.gd`)
```gdscript
signal design_changed
var current_mission_id: String = "earth"
var design: Dictionary = {}        # format below — written by the Design screen
var last_result: Dictionary = {}   # format below — written by Mission Control, read by Debrief
var campaign: Dictionary = {"unlocked": ["earth"], "stars": {}, "best_score": {}}
func save_progress() -> void       # ConfigFile at user://save.cfg
func load_progress() -> void
func record_result(mission_id: String, stars: int, score: int) -> void   # updates campaign + unlocks next
```
`design` format:
```gdscript
{
  "mission_id": "mars",
  "launch_vehicle": "heavy",
  "bus": "medium",
  "power": ["solar_l"],              # one or more power ids
  "battery": "batt_m",
  "shielding": "shield_none",
  "instruments": ["cam_hires", "radar"],
  "antenna": "hga",
  "storage": "stor_m",
  "network": "net_deep",
  "target_years": 2.0
}
```
`last_result` format:
```gdscript
{
  "mission_id": "mars",
  "end_reason": "completed",         # "completed" | "power_dead" | "destroyed" | "aborted"
  "data_returned_gb": 180.0,
  "data_goal_gb": 200.0,
  "science_bonus": 10,               # points from science-opportunity events
  "lifetime_years": 2.0,
  "target_years": 2.0,
  "reserve_left_musd": 45.0,
  "budget_musd": 600.0,
  "log": [ {"day": 120, "text": "Solar storm! You chose Safe Mode.", "cause": "Solar storm", "effect": "3 days of science lost"} ]
}
```

**`Sim`** (`scripts/autoload/sim.gd`) — pure functions, no scene access:
```gdscript
func summarize(design: Dictionary) -> Dictionary
#  → {total_cost_musd, reserve_musd, dry_mass_kg, propellant_kg, wet_mass_kg,
#     power_gen_w, power_load_w, power_balance_w, battery_wh, eclipse_need_wh,
#     data_per_day_gb, downlink_per_day_gb, storage_gb, est_total_data_gb, signal_delay_min}
func launch_check(design: Dictionary) -> Array
#  → Array of {"id": "fits_rocket", "passed": bool, "message": String, "fix_station": "director"|"engineer"|"science"|"comms"}
func score(result: Dictionary) -> Dictionary
#  → {"science": int, "survival": int, "budget": int, "total": int, "stars": int}   (§6.9)
func find_lookalike(design: Dictionary) -> Dictionary   # one row of lookalikes.json (§7.6)
func make_test_design(mission_id: String = "mars") -> Dictionary   # a valid design for testing
```

**Scene flow:** each screen changes scene with `get_tree().change_scene_to_file(path)`. Paths:
`res://scenes/title/title.tscn`, `campaign_map/campaign_map.tscn`, `briefing/briefing.tscn`, `design/design.tscn`, `launch_check/launch_check.tscn`, `launch_anim/launch_anim.tscn`, **`mission_control/mission_control.tscn`**, **`debrief/debrief.tscn`**.
Launch animation → Mission Control → (writes `MissionState.last_result`) → Debrief → "Retry" goes to `design.tscn` (design kept), "Next" goes to `campaign_map.tscn`.

### 8.2 `.gitignore` (repo root)
```
.godot/
*.tmp
export/
.DS_Store
Thumbs.db
```
Commit `*.import` and `*.uid` files (Godot 4 needs them).

### 8.3 Folder ownership (only edit what you own)
| Owner | Folders / files |
|---|---|
| **A** | `project.godot`, `export_presets.cfg`, `scripts/autoload/`, `data/` (except `events.json`), `ui/`, `scenes/title/`, `scenes/campaign_map/`, `scenes/briefing/`, `scenes/design/`, `scenes/launch_check/`, `scenes/launch_anim/` |
| **B** | `scenes/mission_control/`, `scenes/debrief/`, `scripts/events/`, `data/events.json`, `scripts/mission_control/` |
| **C** | `content/` (CREDITS.md, facts.md, bugs.md, submission.md, raw art & sounds) |
| A imports C's files into | `art/`, `audio/` |

### 8.4 Git rules
- `main` must always open and run in Godot.
- Member A works on `main` (or `feat/design`); Member B on `feat/mission-control`; Member C uploads only into `content/`.
- `git pull` **before** you start working, commit **small and often**, push at least every 1–2 hours.
- Member B opens a **Pull Request** to `main` after M4, M5, M6. Member A merges.
- Never commit the `.godot/` folder. Never edit a `.tscn` someone else owns.
- If a merge conflict happens in a `.tscn` file: keep the owner's version.

---

## 9. Build milestones (Core first, Stretch only if time)

| # | Milestone | Owner | Core / Stretch | Target time | Checkpoint (backup kicks in) |
|---|---|---|---|---|---|
| M1 | Project skeleton, theme, JSON data, 3 autoloads, clickable flow | A | Core | Sat 14 Nov, +2 h | — (everything depends on it) |
| M2 | Design screen (4 stations) + live resource bar | A | Core | Sat evening | — |
| M3 | Launch check with explanations | A | Core | Sat night | — |
| M4 | Live Mission Control: ticking sim, gauges, quick actions | **B** | Core | Sun morning | **Sun 12:00** → A builds "lite" version: sim + gauges only, no quick actions |
| M5 | Events system (≥ 8 events) | **B** | Core | Sun midday | **Sun 15:00** → ship with 3–4 events or none |
| M6 | Debrief: score, stars, NASA look-alike, cause→effect | **B** | Core | Sun early afternoon | **Sun 15:00** → A builds simple results screen using `Sim.score()` |
| M7 | Campaign map, 5 missions, save progress | A | Core | Sun afternoon | ship with 3 missions if short on time |
| M8 | Web export + upload to itch.io / GitHub Pages, test in private window | A | Core | **Sun 18:00 latest** | — |
| M9 | Demo video (≤ 30 s) or 7 slides + submission text | **C** (A reviews) | Core | Sun 18:00–22:00 | **Sun 21:00** → A makes 7 slides from screenshots |
| C1 | Art, icons, sounds + CREDITS.md | **C** | Core | Sat night | A uses plain Godot shapes/colors |
| C2 | Playtest + bugs.md | **C** | Core | Sun 15:00–18:00 | — |
| S1 | Launch & cruise animation, sound | A or B | Stretch | — | — |
| S2 | Difficulty levels (Easy: no timers, more budget) | B | Stretch | — | — |
| S3 | Sandbox mode (no budget limits) | A | Stretch | — | — |
| S4 | Tutorial overlay on Mission 1 | A | Stretch | — | — |

**Rules:**
- If behind schedule at M8 time, stop features and export what works.
- **Final submit target: Sun 23:30.** Member A (team owner) clicks *Submit for Judging*; it can be re-submitted, so submit an early version by ~20:00 too.
- Post a short update in the team chat at every checkpoint ("M4 done / M4 late").

---

## 10. Submission checklist (from the official Project Submission Guide)

- [ ] Project name
- [ ] High-level summary (what, how it addresses the challenge, why it matters)
- [ ] **Demo link** — video **≤ 30 seconds** (English or English subtitles) **or ≤ 7 slides**. Exceeding limits = not eligible for global judging.
- [ ] **Final project link** — public, no login (itch.io/GitHub Pages web build + GitHub repo)
- [ ] Detailed description (what it does, how it works, tools: Godot 4.7.2, GDScript, …)
- [ ] Use of AI described (see §11)
- [ ] NASA data/resources used (see §12) — at least one required
- [ ] References — all code, text, images, fonts, sounds, even if free/open source
- [ ] Everything in English; no images/voices of people under 18
- [ ] All team members on the team page, same event; tick both boxes; **Submit for Judging** before 11:59 PM local (our target 11:30 PM)

### 10.1 30-second demo video script (Member C)
| Time | Show on screen | Say / subtitle |
|---|---|---|
| 0:00–0:03 | Title screen | "Hi, we're team ___, and this is Go/No-Go for the Space Mission Design Game challenge." |
| 0:03–0:08 | Design screen, adding parts, bars moving | "Design a real space mission: every part costs money, mass, power and data." |
| 0:08–0:14 | Launch check failing → fixing → passing | "The launch check tells you why your design fails — and how to fix it." |
| 0:14–0:22 | Live Mission Control, a solar storm event | "Then fly it live: solar storms, failing batteries, and surprise discoveries." |
| 0:22–0:30 | Debrief with NASA look-alike card, Solar System map | "Built with NASA data, it teaches anyone how real missions are made — from Earth to Saturn." |

## 11. AI usage disclosure

AI tools (Claude by Anthropic, and others as used by team members) assisted with research, game design polishing, code generation, and documentation. Per the rules:
- Code: header comment in each file + note in this README and the submission.
- Images/video made with AI: **visible watermark** "AI-generated".
- No NASA logos, flags, or mission insignia in any generated content.

## 12. NASA data & resources used

- **NASA CubeSat 101** — CubeSat sizes and mass per unit (1U ≈ 10 cm, ≤ 1.33 kg), launch cost reference (~$300k for a 3U to LEO), mission phases and early-operations timeline (antenna deploy, beacon, checkout).
- **NASA "Design and Develop Science Missions"** (SmallSat Institute webinar, 2025) — the four mission segments (Launch, Space, Ground, User) mapped to our four role stations; the need → concept → requirements → design → build → implement process used in our game flow; requirements that are measurable and verified (our launch check).
- **NASA Mission Design Lab** — trade-study mindset (compare architectures, cost & risk).
- **NASA Webb "Build It Yourself" game** — inspiration for objective-driven choices and "similar real mission" results.
- Real NASA missions referenced in debrief: Landsat 9, PACE, LRO, MRO, MAVEN, Juno, Europa Clipper, Cassini (facts from science.nasa.gov).

## 13. References

- Challenge: https://www.spaceappschallenge.org/2026/challenges/ (Space Mission Design Game)
- Project Submission Guide: https://www.spaceappschallenge.org/resources/project-submission-guide/
- Judging & Awards Guide: https://www.spaceappschallenge.org/resources/judging-awards-guide/
- Design and Develop Science Missions: https://www.nasa.gov/wp-content/uploads/2025/04/250323-design-and-develop-science-mission.pdf
- CubeSat 101: https://www3.nasa.gov/sites/default/files/atoms/files/nasa_csli_cubesat_101_508.pdf
- GMAT: https://software.nasa.gov/software/GSC-19468-1
- Concept Maturity Levels (JPL): https://dataverse.jpl.nasa.gov/dataset.xhtml?persistentId=hdl:2014/44299
- Mission Design Lab: https://etd.gsfc.nasa.gov/capabilities/integrated-design-center/mission-design-lab/
- NASA Mission Viz: https://nasa.github.io/mission-viz/
- Webb "Build It Yourself": https://science.nasa.gov/mission/webb/game-build-it-yourself/
- CSA Digital Games and Activities: https://www.asc-csa.gc.ca/eng/youth-educators/digital-games-and-activities.asp
- Godot Engine 4.7 (MIT license): https://godotengine.org
