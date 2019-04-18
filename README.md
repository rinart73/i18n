# i18n
Allows to localize Avorion mods easily by adding few files and just one line of code.

## Installation
1. Unpack mod archive in your Avorion folder, not in data folder
2. Open `data/scripts/lib/stringutility.lua` and add following code to the bottom of the file:
```
if not pcall(require, "mods/i18n/scripts/lib/stringutility") then eprint("[ERROR][i18n]: failed to extend stringutility.lua!") end --MOD: i18n
```

More info in the [official thread](https://www.avorion.net/forum/index.php/topic,4330) on Avorion forum