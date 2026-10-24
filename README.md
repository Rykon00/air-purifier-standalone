# Air Purifier (Standalone)

Factorio mod: the **Krastorio 2 air purifier** as a standalone building for vanilla Factorio, with a configurable
absorption radius. No Krastorio 2 or Space Age required.

Mod portal: https://mods.factorio.com/mod/air-purifier-standalone

## Features

- **Air purifier** (2x2, 75 kW): removes pollution from all chunks within a configurable radius while it has power
  and a filter.
- **Configurable radius** (startup setting, in tiles, default 64): every chunk whose center lies inside the circle is
  cleaned, the purifier's own chunk always. Pollution is taken proportionally, so the dirtiest chunks get cleaned
  fastest.
- **Configurable absorption** (map setting, default 50 pollution/min per purifier, like K2).
- **Radius visualization** when placing or selecting a purifier.
- **Radius on the map/minimap**, toggleable per player via a shortcut bar button or `SHIFT + ALT + P`.

## Recipes (vanilla ingredients)

- **Air purifier:** 10 steel plate, 4 advanced circuits, 20 plastic bars, 1 engine unit
- **Pollution filter** (chemical plant): 2 steel plate, 2 plastic bars, 5 coal
- **Restore used filter** (chemical plant): used filter, 2 coal, 50 water
- A filter lasts 480 s; there is a 10% chance it is destroyed.
- Unlocked by **Air purification** (red, green and blue science).

## Compatibility

- Not compatible with Krastorio 2 (it already contains the air purifier).
- Prototype names are kept identical to Krastorio 2 (`kr-air-purifier`, `kr-pollution-filter`, ...), so mods made for
  the K2 purifier may work.

## Credits and license

Code, graphics and sound are taken from [Krastorio 2](https://mods.factorio.com/mod/Krastorio2) and
[Krastorio 2 Assets](https://mods.factorio.com/mod/Krastorio2Assets) by Linver, Krastor and raiguard, licensed under
**LGPL-3.0** (sounds under MIT). This mod is therefore also released under LGPL-3.0, see [LICENSE](LICENSE); the
sound license is in [sound/LICENSE-MIT.txt](sound/LICENSE-MIT.txt). All credit for the original building goes to the
Krastorio 2 team.
