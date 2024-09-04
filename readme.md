# CC: Tweaked in StarfallEx
Currently only supports client-side, might be updated to allow server in the future.

## You will not be able to edit these files in game!
You must use an external editor as Garry's Mod will not let addons save files with certain extensions!

## You'll need to download CC: Tweaked and extract both `rom` and `bios.lua`

## Chat commands
* `cc.lock` - Lock inputs, causing keystrokes to go to CC: Tweaked (except for ALT)
* `cc.boot` - Boot computer, does nothing if already on.
* `cc.reboot` - Reboot computer, if off it will still turn on.
* `cc.shutdown` - Shutdown computer, does nothing if already off.
* `cc.quick` - Next chat message will be sent to CC: Tweaked
  * Note: to send special keys like `enter`, wrap it in backslashes (`\enter\`), to send a normal `\` send `\\`

### How to extract `rom` and `bios.lua`
#### (you can also rename the `.jar` to a `.zip` instead of using 7-Zip)
1. Using 7-Zip, right click your downloaded CC: Tweaked jar file and hover over 7-Zip, then click "Open Archive"
2. You should see a list of files now, double click on the `data` folder, inside `data` double click `computercraft`
3. Open the `lua` folder, you should be greeted with `bios.lua` and `rom`, select both and drag it over to the folder.
4. You should have already downloaded this repository, and extracted it into your `GarrysMod/garrysmod/data/starfall/` folder.
5. Move `bios.lua` and `rom` into `starfall/computercraft/`.
6. You should now be able to place down `computercraft/main.lua`
