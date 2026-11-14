# Credits and sources

## M6a — planets and space view

- **Planet, Sun, star and Saturn-ring textures:** [Solar System Scope](https://www.solarsystemscope.com/textures/), licensed under [CC BY 4.0](https://creativecommons.org/licenses/by/4.0/). Based on NASA data. Files in `art/planets/`: Earth day map, Earth clouds, Moon, Mars, Jupiter, Saturn, Saturn ring alpha, Sun and stars.
- The menu starfields (outside the space view) still use Godot primitive stars from `MenuPlanet.add_space`.
- If any texture file is missing, `scripts/space/planet_body.gd` falls back to fully procedural surfaces, so the game still runs with no art at all.
