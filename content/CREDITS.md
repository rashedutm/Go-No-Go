# Credits and sources

## M6a — planets and space view

- **Planet, Sun, star and Saturn-ring textures:** [Solar System Scope](https://www.solarsystemscope.com/textures/), licensed under [CC BY 4.0](https://creativecommons.org/licenses/by/4.0/). Based on NASA data. Files in `art/planets/`: Earth day map, Earth clouds, Moon, Mars, Jupiter, Saturn, Saturn ring alpha, Sun and stars.
- The menu starfields (outside the space view) still use Godot primitive stars from `MenuPlanet.add_space`.
- If any texture file is missing, `scripts/space/planet_body.gd` falls back to fully procedural surfaces, so the game still runs with no art at all.

## M6b — launch sounds

- **Launch rumble:** `audio/jerryblessed-space-rocket-launch-rumble-544846.wav` (drop-in file; confirm source + license here). If the file is missing, `scenes/launch_anim/launch_anim.gd` falls back to a procedural brown-noise rumble, so the game still runs with no audio at all.

## Mission Control — 3D props

- **Computer monitor (`art/models/mission_control/computer_monitor.glb`)** — "Computer Screen" from [Kenney's Furniture Kit](https://kenney.nl/assets/furniture-kit), downloaded from [Poly Pizza](https://poly.pizza/m/V5Qo141OcB). **CC0 1.0 Universal**; licence note in `art/models/mission_control/LICENSE-Kenney-Furniture.txt`.
- **Office chair (`art/models/mission_control/chair_office.glb`)** — from [Lowpoly Furniture Asset Pack](https://store.godotengine.org/asset/abstract-duck/texture-pack/) by **Abstract_Duck**, downloaded from the Godot Asset Store. **MIT**; license text in `art/models/mission_control/LICENSE-AbstractDuck-Furniture.txt`.
- Both models were re-oriented/scaled in code to fit the Mission Control consoles. The monitor's screen is a viewport texture; no changes were made to the model itself.

## UI fonts

- **Barlow, Barlow Condensed and IBM Plex Mono** — [Google Fonts](https://fonts.google.com/), licensed under the [SIL Open Font License 1.1](https://openfontlicense.org/). License texts are in `ui/fonts/OFL-Barlow.txt`, `OFL-BarlowCondensed.txt` and `OFL-IBMPlexMono.txt`.
- **Fullscreen and sound icons** (`ui/icons/`) — [Lucide](https://lucide.dev/), ISC license.
- The neon HUD panel textures in `ui/panels/` are generated in-house — no third-party assets.
