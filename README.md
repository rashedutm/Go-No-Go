# 🚀 Go/No-Go

*"Go/No-Go" is the real call every flight controller makes before launch. In this game, you earn it.*

**Repository:** https://github.com/rashedutm/Go-No-Go

> **NASA Space Apps Challenge 2026 — "Space Mission Design Game"**
> Solo, single-player educational game built in **Godot 4.7.2**, exported to **Web (HTML5)** so judges can play in a browser.
> **Deadline: Sunday 15 Nov 2026, 11:30 PM local time** (official cut-off is 11:59 PM — we aim 30 min early).

---

## 👥 TEAM SPLIT — START HERE

We are 3 coders, each with an AI assistant, working in parallel and merging through **GitHub**. Each person **owns different folders**, so nobody's work overwrites anyone else's (Godot scene files merge very badly).

### 🎮 The 3D vision (v2, decided Sat 14 Nov)
Less text, fewer buttons, more *doing*:
1. **3D Hangar** (design): your spacecraft stands in a hangar. Pick parts from a slim tray and they **snap onto the 3D model**. Orbit the camera around it. A few icons with bars, and hover to see numbers.
2. **Go/No-Go poll** (launch check): the four flight controllers call out **"GO!"** or **"NO-GO: battery too small"** one by one, like real NASA. You need four GOs to launch.
3. **3D launch & cruise**: the rocket lifts off, stages separate, the spacecraft unfolds its solar wings and flies to the planet (short and skippable).
4. **3D Mission Control room (first-person)**: you **walk** around a NASA-style control room. A **big wall screen** shows your spacecraft orbiting the planet live. There are **4 consoles** (Director, Power/Engineer, Science, Comms). Alarms flash, an alert pops up ("SOLAR STORM, go to the POWER console!"), you **walk to the console, press E**, and fix it before the timer runs out.
5. **Debrief**: score, stars, and "your design is like Juno."

*Why a control room and not a cockpit?* Real robotic missions (Juno, Cassini, MRO) have no crew. They are flown by flight controllers on Earth, so this keeps the game scientifically valid, which judges score.

| Member | Owns | Read these sections |
|---|---|---|
| **Member A — Lead / Integrator** (team owner) | Shared code & data, **3D Hangar** (design), **Go/No-Go poll** (launch check), title, campaign map, briefing, 3D spacecraft model builder, web export | §A, then §3–§8 |
| **Member B — Emon** | **3D Mission Control room**: first-person player, 4 consoles, live simulation, **events**, alerts | **§B2 (new tasks!)**, then §B, §6.4–§6.8, §8 |
| **Member C — Daniel** | **3D launch & cruise**, **space view** (spacecraft orbiting the planet, shown on the big screen), planets, **Debrief**, sounds, **demo video** | §C, then §6.9–§6.10, §7.6, §8 |

### 🆕 Latest changes (read this first after every `git pull`)
| When | What changed | Who it affects |
|---|---|---|
| Sat 14 Nov, late evening — Mission Control props | **Real 3D furniture in Mission Control (Member C).** The four interactive consoles and three side desks now use a CC0 sci-fi computer from Quaternius' *Modular Sci-Fi MegaKit* and an MIT office chair from Abstract_Duck's *Lowpoly Furniture Asset Pack* — both downloaded from the Godot Asset Store. Console screens show a small mission-control UI tinted to the station colour. Credits and licences are in `content/CREDITS.md`. | everyone |
| Sat 14 Nov, late evening — interactive flight | **Fly it yourself (Member C).** The launch is now **~22.5 s**: a longer ascent with extra pad smoke and an exhaust trail, the camera dollies smoothly into the cockpit, then **~8.5 s of manual asteroid-dodging flight** — steer with the **mouse** (or `A/D` / `←/→`, `W/S` / `↑/↓`), dodge varied slower rocks, watch the hull pips — before an **autopilot chase cinematic** and orbit insertion. SKIP / Space still bypasses everything. | everyone |
| Sat 14 Nov, evening — UI pass | **Global HUD restyle (Member C, approved by the team).** New notched neon panels, **Barlow Condensed** display type, **Barlow** body type and **IBM Plex Mono** telemetry. Title, campaign map, briefing, hangar HUD, Go/No-Go poll (with a proper **Flight Director comms card**), launch/cruise HUD, Mission Control HUD and the debrief were restyled. The top-right **Fullscreen / Sound buttons are now icon-only** and flush to the corner. Shared kit: `scripts/ui/neon_ui.gd`, `ui/theme.tres`, `ui/fonts/`, `ui/panels/`. No gameplay changes. | everyone |
| Sat 14 Nov, evening | Mission Control is **brighter with a soft blue tone**, the robots were removed, and **mouse-look stays on all the time**. Console panels no longer free the mouse, so choose actions with the **number keys [1] [2] …** and close with **E**. **Emon: E2 (difficulty) is rewritten with the team owner's design.** Easy = choice buttons with the recommended choice in green; Normal/Hard = fix problems **manually** with the console actions. | Emon |
| Sat 14 Nov, late afternoon | **Mission Control room decorated** (`scripts/mission_control/room_decor.gd`, `telemetry_graph.gd`): 4 live graph screens on the side walls (POWER, SCIENCE DATA, GROUND TRACK, SPACECRAFT HEALTH), a mission-clock board and a status board beside the main screen, a hologram of the destination planet with an orbiting spacecraft and a glowing floor ring, robot colleagues with scrolling telemetry, and fact posters on the back wall. **Emon: E5 and E6 are done, so skip them.** The **launch placeholder** is now a 3D countdown → liftoff → straight into Mission Control (no button), at `scenes/placeholders/launch_placeholder.tscn`. **Daniel: `scenes/launch_anim/` is empty and waiting for your real `launch_anim.tscn`, which replaces the placeholder automatically.** | Emon, Daniel |
| Sat 14 Nov, afternoon | **Sounds redone** to be soft and short. Station/part buttons no longer double-click. **Fullscreen fixed for the browser** (the page now toggles it during the real click; F11 works too). Note: fullscreen **can't** work while the game runs *embedded inside the Godot editor*. Test it in the browser build, or in Godot's *Game* tab turn off "Embed game". **Hangar camera** can't leave the room anymore, walls are see-through from outside, and the rocket was moved back so nothing blocks the spacecraft. | everyone |
| Sat 14 Nov, midday | `Sfx` sound system + Fullscreen/Sound corner buttons. **Emon: M4a–M5 were built for you, so your new tasks are in §B2.** | Emon, Daniel |
| Sat 14 Nov, morning | 3D Hangar, Go/No-Go poll, 3D title/campaign/briefing, web export preset | everyone |

### 📍 Project status
| Milestone | Status |
|---|---|
| **M1 Skeleton** | ✅ **Done.** Godot project, all `data/*.json`, the 3 autoloads (`GameData`, `MissionState`, `Sim`) and placeholder screens. The whole flow is clickable. `tests/sim_test.tscn` checks that every mission's test design is GO. |
| **M2 Design screen (2D)** | ✅ Done as a 2D version. It is the **fallback** while the 3D Hangar is built (`scenes/design/`). |
| **M2a 3D models** | ✅ **Done.** `SpacecraftModel3D.build(design)`, `deploy_wings(model, t)` and `build_rocket(vehicle_id)` (children `Stage1`, `Stage2`, `Fairing`). Preview: `godot --path . res://tests/model_preview.tscn` |
| **M2b 3D Hangar** | ✅ **Done.** `scenes/hangar/`: the spacecraft and rocket in a 3D hangar, an orbit camera (drag/wheel, it flies to each station's view), 4 station buttons with issue counts, a slim part tray with tabs, compact resource chips, and a hover tooltip with "why it matters". The briefing now opens the hangar (`go_to("hangar")`). Preview: `godot --path . res://tests/hangar_preview.tscn -- mars science` |
| **M3 Go/No-Go poll** | ✅ **Done.** `scenes/launch_check/`: a night launch pad in 3D with your rocket. The Flight Director polls Engineer → Science → Comms → Director, and each lights up GO (green) or NO-GO (red, with the reason and a **Fix it** button that opens that station in the hangar). Four GOs unlock **LAUNCH!** → `go_to("launch_anim")` (Daniel). Click or press a key to fast-forward. Preview: `godot --path . res://tests/poll_preview.tscn -- mars broken` |
| **M7 Menus in 3D** | ✅ **Done.** The **title** (Earth in 3D with an orbiting spacecraft, How to play, and Credits & NASA sources), the **campaign map** (a 3D Solar System strip you can click: Sun, Earth+Moon, Mars, Jupiter, Saturn with rings, locks and stars) and the **briefing** (big rotating planet, objective, 4 key numbers, required instruments, "Did you know?"). Planets come from `MenuPlanet.make(id)`, which **automatically uses Daniel's `scenes/space/planets/<id>.tscn` (radius 1, centered) if they exist**. Preview: `godot --path . res://tests/menu_preview.tscn -- campaign_map mars` |
| **M4a Mission Control room** | ✅ **Done (built by Member A for Emon, Sat).** `scenes/mission_control/`: a first-person 3D control room. Click to look, WASD to walk, **E** to use a console, Esc frees the mouse. The big wall screen shows the mission's planet with your spacecraft orbiting it (a `SubViewport`; it automatically switches to Daniel's `space_view.tscn` when that exists). There are 4 consoles: **POWER** (engineer), **SCIENCE**, **COMMS** (front row) and **DIRECTOR** (back right). Each has a glowing screen that **blinks red** with `set_console_alert(key, true)`. Pressing E opens a console panel (placeholder text for now). The Director has a temporary **End mission (test)** button that goes to the debrief. Preview: `godot --path . res://tests/mc_preview.tscn -- mars panel` |
| **M4b Live simulation** | ✅ **Done (built by Member A for Emon).** `scripts/mission_control/mission_sim.gd` (`MissionSim`): a day-by-day model of power (solar falls with distance², RTGs decay, eclipses vs. battery), data (instruments → memory → antenna, with overflow lost), health (aging + Jupiter radiation by vault level), reserve and a cause→effect log. The mission ends as `completed`, `power_dead`, `destroyed` or `aborted` → `MissionState.last_result` → debrief. In the room: a live HUD (day, battery, science vs. goal, health, memory), **Space** pauses, **1/2/3** set the speed (a whole mission is about 3 min at x1), consoles show live numbers, **POWER/COMMS blink red automatically** on low battery, overflow or blackout (opening the console acknowledges it), and the wall screen orbit follows the clock. Balance test: `godot --headless --path . res://tests/live_sim_test.tscn`. All 5 test designs score 2–3 stars, and broken designs fail for the right reason. |
| **M4c Console actions** | ✅ **Done (built by Member A for Emon).** Panel buttons: **POWER**: enter/leave SAFE MODE · **SCIENCE**: switch each instrument on/off (shows its power and data) · **COMMS**: buy +4 h/day antenna time ($4 M, max +8 h) · **DIRECTOR**: software fix (+15% health for $15 M), end mission now, plus the mission log. The logic lives in `MissionSim` (`set_safe_mode`, `toggle_instrument`, `buy_contact_time`, `repair`, `abort`), and every action writes a cause→effect log line for the debrief. |
| **M5 Events** | ✅ **Done (built by Member A for Emon).** `data/events.json` has **14 events**: solar storm, micrometeoroid, battery wear, stuck solar wing, Jupiter radiation spike, ground station down, memory error, budget cut, plus science chances (wildfires, lunar ice, Mars dust storm, Io volcano, Enceladus plume, comet), each filtered by destination. `scripts/events/event_system.gd` (`EventSystem`) fires one every ~18–30 s (the first after 12 s). A **red alarm light + beep** plays (it uses `audio/alarm.wav/.ogg` if Daniel adds one), a top banner shows **"Go to the POWER console! 18 s"**, and the console blinks red. The countdown **freezes once you reach the console**. You pick a choice (choices you can't afford are disabled), and no answer means the worst option. Toasts explain the outcome, including the **signal delay** ("Your command takes 43 minutes to reach the spacecraft"), the wall screen shows `solar_storm`/`damaged`/`safe_mode` status, and everything goes into the debrief log. Scoring: discoveries add `bonus × 0.5` to the total. Test: `godot --headless --path . res://tests/events_test.tscn`. Ignoring alarms is risky (Jupiter at 11% health, Saturn 1 star), and good answers reach 90–100. |
| **Emon's list (M4a–M5)** | ✅ **All done** (built by Member A). **Emon: see your new tasks in §B2.** |
| **Sound + fullscreen** | ✅ **Done (Member A).** `Sfx` autoload: 11 soft sound effects generated in code (no files or licenses needed): click (every button, automatically), snap (part added in the hangar), station change, poll beep / GO chime / NO-GO tone, alarm, fixed, mission complete jingle, fail tones, and a quiet Mission Control room hum. **Icon-only** Fullscreen and Sound buttons sit flush in the top-right corner of every screen (keys **F11** / **M**), and the mute setting is remembered. |
| **M6 Launch/cruise, space view, debrief** | ✅ **Done (Member C).** `scenes/launch_anim/launch_anim.tscn`: launch with ground billows and an exhaust trail → camera follows the ascent → smooth dolly into the cockpit → mouse/keyboard asteroid-dodging flight through varied rocks → autopilot chase cinematic → orbit insertion. `scenes/space/space_view.tscn` drives Emon's wall screen. `scenes/debrief/debrief.tscn` is the mission report. Skips with the button or **Space**. |

### 🛠️ Getting started (everyone)

**Repo:** https://github.com/rashedutm/Go-No-Go (Member A is the owner and adds the others as collaborators. Accept the email invite first.)

1. Install **Git** and **Godot 4.7.2** (standard version, not .NET).
2. Clone the repo and create **your own branch**:
   ```bash
   git clone https://github.com/rashedutm/Go-No-Go.git
   cd Go-No-Go
   git checkout -b feat/mission-control
   ```
   (Emon: `feat/mission-control` · Daniel: `feat/launch-debrief` · Member A works on `main`.)
3. Open Godot → **Import** → select `project.godot`. Press **F5** to play the current skeleton.
4. Install **Web export templates**: Godot → *Editor → Manage Export Templates → Download and Install*.
5. Daily loop: `git pull origin main` → work → `git add -A` → `git commit -m "short message"` → `git push`.
   The first push is `git push -u origin <your-branch>`. Then open a **Pull Request** to `main` on GitHub, and Member A merges it.

**Backup rule:** if any part is not merged by its checkpoint time (see §9), whoever is free builds a smaller "lite" version, and the existing 2D screens/placeholders stay as the fallback. Nobody waits on anybody: always build against the shared contract (§8.1) with `Sim.make_test_design()` as fake data.

---

### §A — Member A: Lead / Integrator

**Goal:** everything *before launch*, plus keeping `main` working.

1. ✅ M1 skeleton, ✅ M2 2D design screen (fallback).
2. **`SpacecraftModel3D`** (`scripts/shared/spacecraft_model_3d.gd`): builds a 3D spacecraft from a design using Godot primitives (bus box, solar wings, RTGs, dish, instrument boxes, vault). **Push this early.** Daniel uses it for the launch and space view, and Emon for the wall screen. → **M2a, Sat ~13:00**
3. **3D Hangar** (`scenes/hangar/`): hangar room, the spacecraft model in the middle, an orbit camera, 4 station icons, a slim part tray, a compact icon resource bar, hover tooltips. Clicking a part updates `MissionState.design` and the 3D model. Rocket choice shows the rocket standing next to it. → **M2b**
4. **Go/No-Go poll** (`scenes/launch_check/`): the 4 controllers report one by one from `Sim.launch_check()`. A failed station shows its reason and a "Fix it" button that returns to that station in the hangar. → **M3**
5. Make the title, campaign map and briefing prettier (Solar System strip with planet spheres). → **M7**
6. Merge Pull Requests, add the web export, upload to itch.io. → **M8**

**Prompt to paste into your AI:**
> "Read README.md fully. I am Member A (Lead/Integrator). Continue §A from the first unfinished step. Keep the shared contract in §8.1 stable and only touch folders I own (§8.3)."

---

### §B — Member B (Emon): 3D Mission Control room

**Goal:** the heart of the game. The player *lives* the mission here.

1. `git pull origin main`, then work on branch `feat/mission-control`. Start right away with `Sim.make_test_design("mars")` as the design.

   ✅ **Step 2 is already done** (Member A built it to save time). Start at **step 3**. What exists, so you can build on it:
   - `scenes/mission_control/mission_control.gd`: builds the room, the wall screen and the consoles. Public API: `consoles` (key → `ConsoleStation`), `set_console_alert(key, on)`, `open_console(key)`, `close_console()`, signals `console_opened(key)` / `console_closed(key)`, `wall_view` (has `set_status()` / `set_time_scale()`), `player`. **Replace `_console_body(key)` with real panels in M4c**, and replace `_end_mission_test()` with the real end of the mission in M4b.
   - `scripts/mission_control/player_fp.gd` (`FPPlayer`): first-person controller. Input actions `mc_forward/back/left/right/interact/release` are created at runtime.
   - `scripts/mission_control/console_station.gd` (`ConsoleStation`): `set_alert(bool)`, `operator_point()`.
   - `scripts/mission_control/wall_view_placeholder.gd`: the planet and orbiting spacecraft on the wall screen.
   - `scripts/mission_control/mc_build.gd` (`MCBuild`): `box()` (with collision) and `label()` helpers.
   - ✅ M4b also done: `MissionSim` state you can change from console buttons and events: `instruments_on[id]`, `safe_mode`, `extra_contact_hours`, `blackout_days`, `power_penalty` (0–1), `health`, `reserve_musd`, `science_bonus`, `battery_wh`, `storage_gb`, plus `add_log(text, cause, effect)`. ✅ M4c and ✅ M5 are also done. **Everything in §B is built.** Good polish tasks: add more events to `data/events.json` (same format), tune numbers, make the room nicer (posters, more screens), test it in the browser, and help Daniel with the debrief/launch.
2. ✅ **Room + player** (`scenes/mission_control/`): a 3D control room built from boxes/CSG (rows of desks, a big wall screen, 4 glowing consoles labeled DIRECTOR · POWER · SCIENCE · COMMS). A **first-person controller**: WASD + mouse look, `E` to use a console, `Esc` to release the mouse. Mouse capture must start on a click (browsers require it). → **M4a**
3. **Live simulation** (`scripts/mission_control/mission_sim.gd`): the tick loop from §6.7 (power, battery, eclipses, data, storage, downlink, health, mission clock, time speed). Use `Sim.summarize()`, `Sim.source_power_w()` and `Sim.downlink_rate_mbps()`, and don't re-invent the math. → **M4b**
4. **Consoles**: walking up to a console and pressing `E` opens a **small 2D panel** with only that station's gauges + 2–3 big action buttons (Science: instruments on/off · Power: safe mode · Comms: downlink priority / buy contact time · Director: spend reserve). Console screens glow **red** when they need attention. → **M4c**
5. **Events** (`data/events.json`, `scripts/events/`): ≥ 8 events from §6.8. An alert banner + alarm light + sound says which console to go to. The timer is shown on the HUD. Choices write cause→effect lines into the log. → **M5**
6. **Wall screen**: show Daniel's `space_view.tscn` inside a `SubViewport` on the big screen (use a simple placeholder sphere until it exists). Call `set_status()` on it when events happen. → **M5**
7. When the mission ends, fill `MissionState.last_result` (§8.1) and call `MissionState.go_to("debrief")`.
8. **Fallback:** if 3D walking isn't stable by **Sun 12:00**, skip walking. Use a fixed camera that clicks between the 4 consoles. That's still 3D, just simpler.

**Prompt to paste into your AI:**
> "Read README.md fully. I am Member B (Emon). Build §B: the 3D first-person Mission Control room with 4 consoles, the live mission simulation and the events system, in Godot 4.7.2 GDScript (Compatibility renderer, must run in a web browser). Use only the shared contract in §8.1 to talk to the rest of the game, use Sim.make_test_design() as fake data, and only create/edit files in the folders I own (§8.3)."

---

### §B2 — Member B (Emon): round 2 tasks (M4a–M5 are already built for you)

Everything in §B exists and works (room, walking, consoles, live simulation, buttons, 14 events). **Pull `main` first**, play a mission (Play → Fire Watch → hangar → **Load example** → poll → LAUNCH), then take these in order. Work on branch `feat/mission-control` and open a Pull Request after each one.

| # | Task | Files (yours) | Target |
|---|---|---|---|
| **E1** | **Play-test Mission Control in the browser**: export (README §8.0), then check mouse capture, WASD, E, alarms, sounds, the frame rate, and the end of a mission → debrief. Fix bugs and write anything outside your folders into `content/bugs.md`. | `scenes/mission_control/`, `scripts/mission_control/`, `scripts/events/` | Sat night |
| **E2** | **Difficulty levels: Easy / Normal / Hard (team owner's design, please follow it)**. Picker: a small reusable control in `scripts/mission_control/difficulty_picker.gd` (3 toggle buttons that set `MissionState.set_meta("difficulty", "easy"|"normal"|"hard")`). Member A places it on the briefing screen, so tell A when it's pushed. <br>**Easy** = today's behaviour: the event card shows choice buttons, and the **recommended choice is highlighted green** (add `"recommended": 0` to each event in `events.json`). Timers ×1.5, fewer events (gaps ×1.4). <br>**Normal** = **manual fixing, no choice buttons.** The alert only describes the problem and names the console. The player must **solve it with the real console actions** before the timer runs out. Add a `"fix"` field to every event, e.g. solar storm `{"safe_mode": true}` (be in SAFE MODE when the timer ends), micrometeoroid `{"action": "reroute_power"}` (new POWER button, $10 M), ground station down `{"action": "buy_contact"}` (existing COMMS button), memory error `{"action": "reformat_memory"}` (new COMMS button), budget cut `{"action": "pay_budget"}` (new DIRECTOR button), science chances `{"action": "retarget"}` (a SCIENCE button that appears only during that event). Console actions call `events.notify_action(name)`, and `EventSystem` checks the `fix` each frame: **fixed in time → the good outcome (choice 0's effects), not fixed → the bad default**. New buttons only appear while their event is active. <br>**Hard** = like Normal, plus timers ×0.7, more events (gaps ×0.75), risk chances +0.15, and the banner **does not name the console** ("Something is wrong with the power system"), so the player must work out where to go. <br>Default: Easy on Fire Watch, Normal after that. Keep `tests/events_test.tscn` passing (add a policy that performs the fixes). | `scripts/events/event_system.gd`, `data/events.json`, `scenes/mission_control/mission_control.gd`, `scripts/mission_control/difficulty_picker.gd` | Sun 11:00 |
| **E3** | **First-mission tutorial**: on Fire Watch only, show step-by-step hints in Mission Control ("Click to look around" → "Walk to the POWER console (WASD)" → "Press E" → "Watch the battery" → first event is guaranteed to be a simple one). Add a Skip button and save "tutorial_done" in `user://settings.cfg` so it shows only once. | `scenes/mission_control/`, `scripts/mission_control/tutorial.gd` | Sun 11:00 |
| **E4** | **6+ new events** in `data/events.json` (same format), with real-space ideas, for example: **Mars solar conjunction** (the Sun sits between Earth and Mars and blocks radio for ~2 weeks, a real event every ~26 months), **star tracker blinded by the Sun**, **thruster leak**, **software bug → reboot**, **Saturn ring-plane crossing**, **a partner agency offers a data relay**. Re-run `tests/events_test.tscn` so ignoring alarms stays risky and good answers stay rewarding. | `data/events.json` | Sun 12:00 |
| ~~E5~~ | ✅ **Done by Member A** (skip). ~~Room polish~~: wall posters as `Label3D` with real facts about the mission's planet, a big mission-clock board above the wall screen, blinking lights on the decorative desks, simple low-poly robot "colleagues" (capsule bodies, no human likeness needed) at the empty desks. | `scenes/mission_control/`, `scripts/mission_control/` | Sun 13:00 |
| ~~E6~~ | ✅ **Done by Member A** (skip): mission-clock and status boards plus 4 live graph screens. ~~Wall-screen overlay~~: a 2D layer inside the wall-screen `SubViewport` with the day counter, a data-downlink bar, and "SAFE MODE" / "BLACKOUT" stamps. It must keep working when Daniel's `space_view.tscn` replaces the placeholder. | `scenes/mission_control/mission_control.gd` | Sun 14:00 |
| **E7** | **Backup for Daniel**: if `scenes/debrief/debrief.tscn` is not on `main` by **Sun 15:00**, build it yourself following §C step 5 (score, stars, NASA look-alike, cause→effect lines, `MissionState.record_result`). | `scenes/debrief/` (only in this case) | Sun 15:00 |

**Prompt to paste into your AI:**
> "Read README.md fully. I am Member B (Emon). M4a–M5 are already built. Do the §B2 tasks in order, starting with E1. Godot 4.7.2 GDScript, Compatibility renderer, must run in a web browser. Use the shared contract in §8.1 (including Sfx for sounds) and only edit files in my folders (§8.3)."

---

### §C — Member C (Daniel): 3D launch, space view & debrief

**Goal:** the "wow" moments, plus the ending.

1. `git pull origin main`, then work on branch `feat/launch-debrief`. Use `Sim.make_test_design("mars")` as fake data.
2. **Planets** (`scenes/space/planets/`): Earth, Moon, Mars, Jupiter, Saturn (with rings) as spheres with colors or textures. NASA images (images.nasa.gov / Solar System textures) are allowed, with **no NASA logos**. Credit every texture in `content/CREDITS.md`. → **M6a**
3. **Space view** (`scenes/space/space_view.tscn`): the spacecraft (from `SpacecraftModel3D.build(design)`, made by Member A; use a simple box until it exists) orbiting the mission's planet, with a starfield and a slow camera. It must expose `set_status(status: String)`: `"normal"`, `"safe_mode"` (lights dim), `"solar_storm"` (orange particles), `"damaged"` (sparks), `"downlink"` (beam to Earth). Emon shows it on his wall screen. → **M6a**
4. **Launch & cruise** (`scenes/launch_anim/launch_anim.tscn`): **~22.5 s, skippable with a button/Space.** Rocket on the pad → longer liftoff with pad smoke + an exhaust trail as the camera follows the ascent → a smooth dolly into the **cockpit** → **~8.5 s of manual asteroid-dodging flight** (steer with the **mouse**, or `A/D` / `←/→`, `W/S` / `↑/↓`; hull pips, distance/autopilot HUD) through varied, slower rocks → autopilot **chase cinematic** → orbit insertion. Camera shake and countdown text ("T-3, 2, 1… LIFTOFF"). At the end, call `MissionState.go_to("mission_control")`. → **M6b**
5. **Debrief** (`scenes/debrief/debrief.tscn`): the spacecraft slowly rotating in 3D, a big score, stars that pop in one by one, 3 score bars (science, survival, budget), the **"Your mission is like Juno"** card (`Sim.find_lookalike()`), 3 cause→effect lines from `last_result.log`, and Retry/Next buttons. **You must call** `MissionState.record_result(...)` (§8.1). → **M6c**
**Original tasks (still yours, on top of the 3D work above):**

6. **Collect free icons & art** (by Sat night): spacecraft parts, planets, gauges, UI icons. Use sites with free licenses, e.g. **Kenney.nl** (CC0), **OpenGameArt.org**, **NASA image library** (images.nasa.gov — NASA images are free to use, but **no NASA logo/meatball/worm**). For every file, write the **source link + license** in `content/CREDITS.md`. Put raw files in `content/`, and Member A or you import them into `art/`.
7. **Sounds** (by Sat night): the game already has generated sounds (see `Sfx` in §8.1). Your job: a **launch rumble** for your launch scene (play it with your own `AudioStreamPlayer`), and optionally nicer replacements named exactly `click/alarm/complete/fail/go/nogo/fixed/hum.wav` (they are picked up automatically). Use **freesound.org** (CC0) or **Kenney**, put them in `audio/` and credit them in `content/CREDITS.md`.
8. **Check the facts** in §7.6 and `data/lookalikes.json` on **science.nasa.gov** (launch years, one fun fact each). Write corrections in `content/facts.md`, and Member A updates the JSON.
9. **Playtest** (Sunday afternoon): play every mission and write bugs in `content/bugs.md`, like: *"Mission 3, clicked RTG, budget went negative, nothing happened."*
10. **Make the demo** (Sunday evening): either a **video of 30 seconds or less** (record the screen with OBS or Xbox Game Bar `Win+G`, add English subtitles), **or 7 slides max** (Google Slides/Canva): Title · Team & challenge · Problem · Our game (screenshots) · How it teaches trade-offs · NASA data used · Future. Use the script in §10.1.
11. **Draft the submission text** in `content/submission.md`: project summary, description, tools used (from §10).

**Priority if time runs short:** 10 (demo) > 5 (debrief) > 3 (space view) > 4 (launch) > the rest. The demo is required for judging.

**Prompt to paste into your AI:**
> "Read README.md fully. I am Member C (Daniel). Build §C: the planets, the 3D space view with set_status(), the 3D launch & cruise sequence and the debrief screen, in Godot 4.7.2 GDScript (Compatibility renderer, must run in a web browser). Use only the shared contract in §8.1, use Sim.make_test_design() as fake data, and only create/edit files in the folders I own (§8.3)."

---

## 0. Note for AI assistants reading this file

You are helping a small team build this game for a hackathon with a hard deadline.
- **First ask (or check) which member you are working for (A, B or C) and stick to that member's section and owned folders (§8.3).** Never edit files owned by another member — create a new file in your own folder instead.
- The shared code contract (§8.1) is fixed. Don't rename its functions, fields or signals.
- Follow this README as the **source of truth** for design, data, and scope. Do not add multiplayer or features marked *Stretch* until every *Core* milestone works. 3D is in scope (see "The 3D vision"), but build with **Godot primitives/CSG and simple materials**, use **no heavy imported models**, and keep it fast in a web browser (Compatibility renderer).
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
| Design | **3D Hangar** builder: parts snap onto a 3D spacecraft (the 2D design screen stays as the fallback) |
| Launch check | **Go/No-Go poll**: 4 flight controllers call GO / NO-GO |
| After launch | **3D launch & cruise** → **first-person 3D Mission Control room** on Earth (walk to consoles, fix problems), with real-time events |
| Events | Space weather · Hardware failures · Comms/data limits · Science opportunities |
| Score | **Science returned · Budget efficiency · Mission survival** |
| Debrief | **"Your design is like this real NASA mission"** + short cause→effect lines |
| Style | Low-poly, colorful 3D (primitives) + minimal text. Show, don't tell: icons, bars, lights, sounds. |
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
4. **Design: 3D Hangar** (Member A). The four stations (§5) are icons. Parts snap onto the 3D spacecraft, and a compact icon resource bar is always visible: Budget · Mass · Power · Shadow energy · Data · Slots.
5. **Launch check: Go/No-Go poll** (Member A). Each controller reports from `Sim.launch_check()` (§6.6). A NO-GO explains *why* in one sentence and has a "Fix it" button that returns to that station.
6. **3D launch & cruise** (Daniel). 10–15 s, skippable.
7. **3D Mission Control room** (Emon). First-person, 3–5 real minutes per mission (§6.7). The wall screen shows Daniel's space view.
8. **Debrief** – score, stars, NASA look-alike card, cause→effect lines, buttons: *Redesign & retry* / *Next mission*.

---

## 4. Campaign missions

Source of truth: `data/missions.json`.

| # | Mission | Destination | Objective (science goal) | Budget | Min. lifetime | Data goal | Required instrument types | Difficulty |
|---|---|---|---|---|---|---|---|---|
| 1 | **Fire Watch** | Low Earth Orbit (500 km) | Map wildfires & forest health | $150 M | 2 yr | 12,000 Gb | imaging | ★ |
| 2 | **Moon Mapper** | Lunar orbit (50 km) | Map the surface, find water ice at the poles | $300 M | 1 yr | 12,000 Gb | imaging + spectro | ★★ |
| 3 | **Red Planet Weather** | Mars orbit | Study Mars atmosphere & dust storms | $550 M | 2 yr | 50,000 Gb | spectro | ★★★ |
| 4 | **Giant's Secret** | Jupiter orbit | Jupiter's interior, magnetic field, radiation | $900 M | 2 yr | 4,000 Gb | interior + fields | ★★★★ |
| 5 | **Ringworld** | Saturn orbit | Rings and the icy plumes of Enceladus | $1,200 M | 4 yr | 2,500 Gb | imaging + sampling | ★★★★★ |

Each mission has a balanced reference design in `Sim.make_test_design(id)` that passes the launch check (verified by `tests/sim_test.tscn`).

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
- **3D first-person room** (v2): the big wall screen shows the spacecraft orbiting the target (Daniel's `space_view`). The **HUD** is minimal: mission clock, time speed, Battery %, Data returned vs goal, Health %, Reserve $, plus an alert banner with a timer when an event is active. Detailed gauges live **on the 4 consoles**. Walk up and press `E` to open a console's small panel with its quick actions. A short **event log** sits on the Director console.
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
| **Science returned** | 50 % | `ratio = data_returned / data_goal` → `min(ratio,1) × 85 + clamp((ratio−1)/0.5, 0, 1) × 15` (goal met = 85, 1.5× goal = 100) (event discoveries add `bonus × 0.5` straight to the **total**, total max 100) |
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

## 7. Data tables

**The JSON files in `data/` are the source of truth.** Change balance there, not in code. The tables below are a summary (✓C = allowed in a CubeSat).

### 7.1 Launch vehicles — `launch_vehicles.json` (made-up names, no real brands)
| id | Name | Cost $M | LEO kg | Moon kg | Mars kg | Jupiter kg | Saturn kg |
|---|---|---|---|---|---|---|---|
| rideshare | CubeSat Rideshare | 1 | 24 | – | – | – | – |
| small | Sparrow (small launcher) | 8 | 300 | – | – | – | – |
| medium | Kestrel (medium launcher) | 70 | 15,000 | 3,500 | 2,500 | 900 | – |
| heavy | Condor (heavy-lift) | 150 | 50,000 | 14,000 | 10,000 | 4,500 | 3,500 |
| super | Titanhawk (super heavy) | 450 | 90,000 | 27,000 | 20,000 | 9,000 | 7,000 |

### 7.2 Spacecraft bus — `buses.json`
| id | Name | Cost $M | Mass kg | Base power W | Part slots (instruments + power sources) |
|---|---|---|---|---|---|
| cube | 12U CubeSat | 2 | 6 | 5 | 3 (only ✓C parts; whole CubeSat ≤ 24 kg per NASA CubeSat 101: ~1.33 kg per 1U) |
| small | Small bus | 50 | 150 | 60 | 6 |
| medium | Medium bus | 150 | 900 | 150 | 9 |
| large | Large bus | 300 | 2,000 | 250 | 12 |

### 7.3 Power, battery, shielding — `power.json` (`kind`: solar / rtg / battery / shielding)
| id | Name | Cost $M | Mass kg | Value |
|---|---|---|---|---|
| solar_cube ✓C | CubeSat solar panels | 0.5 | 2 | 40 W @1 AU |
| solar_s | Small solar array | 5 | 20 | 300 W @1 AU |
| solar_m | Medium solar array | 12 | 60 | 1,500 W @1 AU |
| solar_l | Large solar array | 30 | 150 | 5,000 W @1 AU |
| solar_xl | Giant solar wings (Juno-style) | 70 | 340 | 14,000 W @1 AU (≈ 520 W at Jupiter) |
| rtg | RTG (nuclear) | 100 | 56 | 290 W anywhere, −1.5 %/yr |
| batt_s ✓C / batt_m / batt_l | Battery | 1 / 3 / 7 | 4 / 15 / 35 | 200 / 800 / 2,000 Wh |
| shield_none ✓C / shield_med / shield_heavy | Radiation vault | 0 / 25 / 60 | 0 / 80 / 200 | level 0 / 1 / 2 (Jupiter needs ≥ 1) |

Heater load by destination (W): Earth 0 · Moon 20 · Mars 40 · Jupiter 120 · Saturn 150.

### 7.4 Instruments — `instruments.json`
| id | Name | Type | Cost $M | Mass kg | Power W | Data Gb/day | Science pts |
|---|---|---|---|---|---|---|---|
| cam_mini ✓C | Mini camera | imaging | 1 | 1.5 | 5 | 2 | 5 |
| cam_wide | Wide camera | imaging | 15 | 15 | 20 | 20 | 10 |
| cam_hires | High-resolution camera | imaging | 50 | 60 | 60 | 80 | 25 |
| ir_spec | Infrared spectrometer | spectro | 45 | 35 | 40 | 15 | 25 |
| radar | Radar sounder | radar | 70 | 90 | 150 | 40 | 30 |
| magnet ✓C | Magnetometer | fields | 8 | 5 | 5 | 0.1 | 12 |
| particle | Particle & radiation detector | fields | 15 | 10 | 10 | 0.2 | 12 |
| microwave | Microwave radiometer | interior | 60 | 50 | 40 | 2 | 30 |
| altimeter | Laser altimeter | mapping | 30 | 20 | 35 | 3 | 18 |
| dust | Dust analyzer | sampling | 25 | 15 | 15 | 0.1 | 15 |

Plain-English descriptions are in the JSON `description` field (shown as tooltips).

### 7.5 Comms & ground — `comms.json` (`kind`: antenna / storage / network)
| id | Name | Cost $M | Mass kg | Power W | Rate near Earth / Moon | Rate @1 AU (falls with distance²) |
|---|---|---|---|---|---|---|
| lga ✓C | Low-gain antenna | 2 | 3 | 15 | 1 Mbps | 0.02 Mbps |
| mga | Medium-gain antenna | 10 | 15 | 40 | 10 Mbps | 0.5 Mbps |
| hga | High-gain dish | 30 | 60 | 80 | 100 Mbps | 6 Mbps |
| stor_s ✓C / stor_m / stor_l | Storage 32 / 256 / 1,000 Gb | 1 / 3 / 8 | 1 / 3 / 6 | 2 / 5 / 10 | – | – |
| net_basic | Basic ground station | 2 /yr | – | – | 4 h contact/day | |
| net_deep | Deep-space network (3 sites) | 15 /yr | – | – | 10 h contact/day | |

Moon uses `near_rate_factor` 0.3 (weaker signal than Earth orbit). Operations cost: $10 M/yr near Earth, $30 M/yr deep space.

### 7.6 NASA look-alike matches — `lookalikes.json`
`Sim.find_lookalike()` picks the row with the same destination that shares the most `traits` (instrument ids, power kind `solar`/`rtg`, bus, antenna, shielding).
| Destination | Real mission | Key traits | Fun fact |
|---|---|---|---|
| Earth | **Landsat 9** (2021) | cameras, solar | Part of a 50-year record of Earth images. |
| Earth | **PACE** (2024) | spectrometer | Studies ocean color, plankton, clouds and aerosols. |
| Earth | **NASA CubeSat Launch Initiative** (2011–) | CubeSat, mini camera | Over 150 student/university CubeSats launched. |
| Moon | **Lunar Reconnaissance Orbiter** (2009) | cameras, altimeter, spectrometer | Has mapped the Moon in detail for over 15 years. |
| Mars | **Mars Reconnaissance Orbiter** (2005) | hi-res camera, radar, high-gain dish | More data than all earlier Mars missions combined. |
| Mars | **MAVEN** (2013) | particles, magnetometer | Studies how Mars lost its atmosphere. |
| Jupiter | **Juno** (2011) | solar, microwave, magnetometer, vault | First solar-powered spacecraft at Jupiter. |
| Jupiter | **Europa Clipper** (2024) | solar, radar, dust, heavy vault | Huge solar arrays + radiation vault to study Europa. |
| Saturn | **Cassini** (1997) | RTG, many instruments | 13 years at Saturn, "Grand Finale" dive in 2017. |

## 8. Tech plan (Godot)

- **Godot 4.7.2**, GDScript, **3D + 2D UI**, **Compatibility renderer** (required for web), resolution 1280×720 stretch (`canvas_items`, `expand`).
- 3D rules for web performance: primitives/CSG (`BoxMesh`, `CylinderMesh`, `SphereMesh`), `StandardMaterial3D` with flat colors/emission, at most one `DirectionalLight3D` with shadows, GPU particles kept small (≤ 200), no SDFGI/volumetrics. Bake CSG to meshes if it gets slow.
- **Web export** (HTML5) — requires installing **Web export templates** (Editor → Manage Export Templates). Use the *no-threads* variant for easy hosting (itch.io / GitHub Pages). ⚠️ In the Web export preset set **Resources → Filters to export non-resource files: `data/*.json`**, otherwise the game loads no data in the browser.
- Test the math anytime: `godot --headless --path . res://tests/sim_test.tscn` (prints each mission's budget/mass/power/data and `RESULT: ALL TEST DESIGNS GO`).
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

### 8.0 Web export & upload (Member A)
- `export_presets.cfg` (in the repo) has a **"Web"** preset: no threads (works on any host), includes `data/*.json`, excludes `tests/`, and outputs to `export/web/index.html` (git-ignored).
- Command-line export:
  ```bash
  godot --headless --path . --export-release "Web" export/web/index.html
  ```
- Local test (browsers can't run it from `file://`): `python -m http.server 8060 --directory export/web`, then open http://localhost:8060
- **itch.io upload:** zip the *contents* of `export/web/` (index.html at the zip root) → itch.io → *Create new project* → Kind: **HTML** → upload the zip → tick **"This file will be played in the browser"** → viewport **1280×720**, tick **Fullscreen button** → Visibility **Public**. Test the link in a private window.

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

**Extra helpers (already implemented, safe to use):**
```gdscript
MissionState.go_to(screen_key)            # "title", "campaign_map", "briefing", "design", "launch_check",
                                          # "launch_anim", "mission_control", "debrief"
                                          # mission_control/debrief fall back to scenes/placeholders/ until Member B's scenes exist
MissionState.start_mission(mission_id)    # sets current mission, fresh design if mission changed
MissionState.set_design_value(key, value) # edits design + emits design_changed
MissionState.empty_design(mission_id)
MissionState.is_unlocked(mission_id) / reset_progress()
GameData.get_missions_in_order()          # missions sorted by "order"
GameData.get_by_kind(table, kind)         # e.g. get_by_kind("power", "solar"), get_by_kind("comms", "antenna")
Sim.is_go(design) -> bool
Sim.downlink_rate_mbps(antenna, mission)  # useful for Mission Control ticks
Sim.source_power_w(source, distance_sun_au, years_elapsed)   # solar 1/d², RTG decay over time
```
`Sim.summarize()` also returns `budget_musd, launcher_capacity_kg, downlink_rate_mbps, data_goal_gb, slots_used, slots_max`.
**Debrief must call** `MissionState.record_result(mission_id, stars, score)` so the next mission unlocks (the placeholder already does).

**Sound (`Sfx` autoload, Member A, `scripts/autoload/sfx.gd`):**
```gdscript
Sfx.play("snap")                  # one-shot: click, snap, whoosh, beep, go, nogo, alarm, fixed, complete, fail
Sfx.play("go", -6.0, 1.2)         # optional volume (dB) and pitch
Sfx.start_loop("hum") / Sfx.stop_loop("hum")
Sfx.toggle_mute() / Sfx.toggle_fullscreen()
```
Every `Button` plays `click` automatically (to opt out: `button.set_meta("no_click", true)`).
**To replace a generated sound with a real one, drop a file named exactly `audio/<name>.wav` (or `.ogg`/`.mp3`) into the repo.** It is picked up automatically, with no code change. New sound names (e.g. `launch_rumble`) can be added to `Sfx.SOUNDS` by Member A, or played directly in your own scene with an `AudioStreamPlayer`.

**3D contracts (v2):**

`SpacecraftModel3D` (Member A, `scripts/shared/spacecraft_model_3d.gd`, `class_name SpacecraftModel3D`):
```gdscript
static func build(design: Dictionary) -> Node3D
#  Returns a new Node3D (about 2–4 m across, origin at the center of the bus, +Y up, -Z forward).
#  Child nodes are named so others can animate them:
#  "Bus", "SolarWings" (Node3D, its children are the wing panels), "RTGs", "Antenna", "Instruments", "Vault".
static func deploy_wings(model: Node3D, t: float) -> void   # t: 0 = folded, 1 = open (for the launch animation)
static func build_rocket(launch_vehicle_id: String) -> Node3D   # origin at base, 7–16 m tall; children "Stage1", "Stage2", "Fairing"
```

`space_view.tscn` (Daniel, `scenes/space/space_view.tscn`, root script `space_view.gd`):
```gdscript
func setup(design: Dictionary) -> void         # builds the spacecraft + the mission's planet; called once
func set_status(status: String) -> void        # "normal" | "safe_mode" | "solar_storm" | "damaged" | "downlink"
func set_time_scale(days_per_second: float) -> void   # optional: orbit speed follows the mission clock
```
Emon embeds it like this: `SubViewport` → instance `space_view.tscn` → `ViewportTexture` on the wall-screen `MeshInstance3D` material. Until Daniel's scene exists, Emon uses a placeholder sphere. Check with `ResourceLoader.exists("res://scenes/space/space_view.tscn")`.

**Design station memory:** `MissionState.set_meta("design_station", "engineer")` before `go_to("design")` (or `"hangar"`) opens that station. The Go/No-Go poll's "Fix it" button uses this.

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
| **A** | `project.godot`, `export_presets.cfg`, `scripts/autoload/`, `scripts/shared/`, `data/` (except `events.json`), `ui/`, `scenes/title/`, `scenes/campaign_map/`, `scenes/briefing/`, `scenes/design/`, `scenes/hangar/`, `scenes/launch_check/`, `scenes/placeholders/`, `scripts/ui/`, `tests/` |
| **B — Emon** | `scenes/mission_control/`, `scripts/mission_control/`, `scripts/events/`, `data/events.json` |
| **C — Daniel** | `scenes/launch_anim/`, `scenes/space/`, `scenes/debrief/`, `scripts/space/`, `audio/`, `art/`, `content/` (CREDITS.md, facts.md, bugs.md, submission.md) |

`project.godot` is Member A's only. If you need an input action (e.g. `move_forward`) or an autoload, ask Member A, **or** create input actions in code at runtime with `InputMap.add_action()` inside your own scene. `launch_anim/` moved from A to Daniel in v2. A's old placeholder `launch_anim.tscn` is Daniel's to replace.
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

| # | Milestone | Owner | Target time | Checkpoint (backup kicks in) |
|---|---|---|---|---|
| M1 | Skeleton: project, JSON data, 3 autoloads, clickable flow | A | ✅ Sat 09:00 | — |
| M2 | 2D Design screen (fallback) | A | ✅ Sat 09:30 | — |
| M2a | `SpacecraftModel3D.build()` pushed | A | **Sat 13:00** | blocks Daniel & Emon's wall screen, so it goes first |
| M2b | 3D Hangar builder | A | Sat 20:00 | **Sun 10:00** → keep 2D design screen |
| M3 | Go/No-Go poll launch check | A | Sat 23:00 | **Sun 10:00** → keep placeholder checklist |
| M4a | 3D control room + first-person walk + `E` on consoles | **Emon** | Sat 18:00 | **Sun 12:00** → fixed camera clicking between consoles |
| M4b–c | Live simulation + console panels + HUD | **Emon** | Sat night | **Sun 12:00** → Member A helps / simplifies |
| M5 | Events (≥ 8) with alerts, alarms, timers; wall screen | **Emon** | Sun 12:00 | **Sun 15:00** → ship with 3–4 events |
| M6a | Planets + space view with `set_status()` | **Daniel** | Sat 18:00 | **Sun 12:00** → wall screen shows a spinning planet only |
| M6b | 3D launch & cruise | **Daniel** | Sat night | **Sun 14:00** → keep the text placeholder |
| M6c | Debrief (3D spacecraft, stars, look-alike) | **Daniel** | Sun 12:00 | **Sun 15:00** → keep the placeholder debrief (already works) |
| C1 | Art, icons, sounds + CREDITS.md, fact check | **Daniel** | Sat night | A uses plain shapes/colors |
| M7 | Prettier title / campaign map / briefing | A | Sun afternoon | keep current |
| M8 | Merge all, web export, upload, test in private window | A | **Sun 18:00 latest** | — |
| C2 | Playtest + bugs.md | **Daniel** (+ everyone) | Sun 15:00–18:00 | — |
| M9 | Demo video (≤ 30 s) or 7 slides + submission text | **Daniel** (A reviews) | Sun 18:00–22:00 | **Sun 21:00** → A makes 7 slides from screenshots |
| E1–E7 | Emon's round 2 (browser test, difficulty, tutorial, more events, room polish, wall overlay, debrief backup) | **Emon** | Sat night → Sun 15:00 | see §B2 |
| S2 | Sandbox mode (no budget limits) | A | Stretch | — |
| S3 | Tutorial hints on Mission 1 | A | Stretch | — |

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
| 0:03–0:09 | 3D Hangar: parts snapping onto the spacecraft, bars moving | "Build a real space mission: every part costs money, mass, power and data." |
| 0:09–0:13 | Go/No-Go poll: one NO-GO → fix → four GOs | "Flight controllers tell you why your design fails, and how to fix it." |
| 0:13–0:17 | 3D launch, wings unfolding | "Launch it…" |
| 0:17–0:24 | First-person Mission Control: alarm, walk to console, fix the solar storm | "…then fly it live from Mission Control: solar storms, failing batteries, surprise discoveries." |
| 0:24–0:30 | Debrief stars + "Your mission is like Juno" | "Built with NASA data, it teaches anyone how real missions are made, from Earth to Saturn." |

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
