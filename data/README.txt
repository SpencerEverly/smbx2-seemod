(Check https://docs.codehaus.moe/ for all other documentation not on this readme)

THE SPENCER EVERLY EDITION LUNALUA MOD (v1.0)

This is a mod of the original SMBX2 LunaLua architecture that fixes issues and gets updated more often than the originl SMBX2. It does many things:

- Compatibility to change the window title (Misc) and icon (loadIconImgResolved)
- Adding a loadscreen sound with loadscreen.ogg in the episode folder
- Fixes many characters and adds past and new ones (All Beta 3, 4, and future characters, additional playables from the forums, etc.)
- Fixes drawing with split screen
- Fixes multiplayer for some parts
- Adds online capibilities for online play
- Adds renaming and removing certain files using os.rename/os.remove
- And more that isn't on this list

For documentation, see below.

-------DOCUMENTATION-------

(Field types, aka things that the code does that indicates what it does)
word: Can be a number (Like 0, or 1)
bool: This, or that. which is really true or false (Think of a true or false quiz)
float: Timing and speed, I think
string: A string, which is a word or a sentence in quotes ("")
..optional: Optional argument, specific for something

----Misc----

-Level/Overworld-
Misc.playPSwitchMusic(bool) - Plays a P-Switch music indefinitely on all sections until stopped with false.
Misc.setWindowTitle("string") - Sets the window title of the SMBX game into any title.
Misc.setWindowIcon[Resolved]("string/to/file.extension") - Loads an image as an icon in the episode folder and replaces it with the window icon. Resolved can also be optionally used.
Misc.saveDataManage(slot, destination..optional, action, booltocountext, booloverwrite..optional) - A stripped down version of os.remove/os.rename that manages save files.
- slot: The slot of the save file to manage
- destination: Optional argument when using the move command.
- action: Action to call. Either create, move, or delete can be called.
- booltocountext: Whenever it's true or false to count the save slot's -ext.dat with the action.
- booloverwrite: Whenever it's true to overwrite the save when moving saves. Default is false.
Misc.episodeFileManage(file, destination, action, booloverwrite..optional) - saveFileManage, but os.remove/os.rename is locked down to only your files in the episode folder, and the manager folder located under data (For things like PFP managing if you add one).
- file: The file to manage.
- destination: Optional argument when using the move command.
- action: Action to call. Either create, move, or delete can be called.
- booloverwrite: Whenever it's true to overwrite the file when moving. Default is false.
Misc.setWindowPosition(x, y, iscentered) - Sets the main game window position to any position on the screen. iscentered is a boolean that can be true or false (Default is true)
Misc.centerWindow() - Centers the window to the center of the screen after execution.
Misc.focusWindow(bool) - Whenever to focus or unfocus the window when not focused on the game, setting bool as true or false.
Misc.openComputerFile(extension, localtoassign) - Opens up the Windows Explorer open file dialog to open a file. This only accepts certain files, which you can specify (Which is also limited).
- extension: The extension to count when opening the dialog. There's a limit to specify which files, and files like EXEs, or other dangerous-like files are unsupported.
- localtoassign: A function word to assign the file. Think of local image = Graphics.loadImage("file"), except more simplified.

-Loadscreen-
Misc.loadScreenSound(bool, isLoopable) - Whenever to enable a loadscreen sound during loading. The sound can be specified in the episode folder under "loadscreen.(musicextension)". Currently, only OGGs are supported. isLoopable can be true or false to loop the same sound during the sequence.

----Section----
If you apply Section(-1) in this version of LunaLua, it will count all sections (Saving time for using the loop "for i = 0,20 do").
---

-Level-
--Instances--
Section(number).muteMusic = bool - Whenever to mute the music or not. If muted, music from a specified section will be saved before muting, and if set to false, will restore the music back to normal from that section (Think of the same feature like the P-Switch, but it plays no music and the P-Switch isn't active. Useful for starman/megashroom as well).