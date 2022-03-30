This folder contains templates for various configuration files usable in SMBX2.
Copy the template you need over to the appropriate folder and modify it to suit your needs.
For all of them, if there is an "n" in the filename after a dash, it needs to be replaced with the index you would like the file to apply to.
All files include most if not all configuration options for the file. If you experience unexpected results, it might be a good idea to remove some that you don't use.
Here's what each of them does:

ach-n.ini:
Configuration file for an achievement. Achievements will show up on the launcher and can be triggered through events or lua.

background2-n.txt:
Configuration file for a parallaxing background. The index corresponds to the number used in the editor, not the number used by the image.

background-n.ini:
Configuration file for background objects in the editor. Does not affect their in-game behaviour.

background-n.txt:
Configuration file for background objects in the game. While the ini-file configures the editor appearance, this one changes its actual behaviour in the game.

block-n.ini:
See background-n.ini, but for blocks.

block-n.lua:
Sample lua file for blocks. Automatically loaded. The variable BLOCK_ID is automatically configured based on the index. Use IDs between 751 and 1000 to ensure no overlap with basegame elements. Comments explain the function of each individual segment.

block-n.txt:
See background-n.txt, but for blocks.

Dummy.png:
Sample image file to copy over and replace with whatever you need. Most ini files in this folder refer to Dummy.png by default.

example.lua:
A (mostly) empty library file to copy over and modify.

music.ini:
Configuration file for replacing music on a per-episode or per-level basis.

npc-n.ini:
See background-n.ini, but for NPCs.

npc-n.lua:
See block-n.lua, but for NPCs.

npc-n.txt:
See background-n.txt, but for NPCs.

particles_example.ini:
Sample configuration for a particle system. Not automatically loaded by the game, must be further configured through lunalua.

ribbon_example.ini:
Sample configuration file for a ribbon particle system. Similar to particles_example.ini.

sounds.ini:
Configuration file for replacing sound effects on a per-episode or per-level basis, though this is never really necessary, as sound effects can be replaced in the same way as custom graphics.

standard.frag:
Basic fragment shader to copy over and modify, for effects that occur per-pixel.

standard.vert:
Basic vertex shader to copy over and modify, for effects that occur per-vertex.