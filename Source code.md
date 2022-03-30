# Source code for SMBX2 components

Super Mario Bros. X2 has built from many components that developed at different
repositories. All lua-coded backend and the library of the game is represented
in the source code form at the game pacakge directly.


## LunaLua
The most of game backend developed as the LunaLua extension library

https://github.com/WohlSoft/LunaLua



## LuaJIT
The lua scripting library with the JIT compilation support, modified

https://gitlab.com/Bluenaxela/luajit-lunalua


## LuaBIND
The C++ lua binding library that simplifies the binding of C++ objects into lua.

https://github.com/WohlSoft/LunaLua/tree/master/LunaDll/libs/luabind-src


## Super Mario Bros. X 1.3 Engine
The copy of the Mario fan game using as a base to run the game. The original
build made in October 2010 is being used to guarantee the same binary
compatibility.

https://github.com/smbx/smbx-legacy-source



## Moondust Project (a.k.a. PGE Project)
The Editor and Tools as a development kit for SMBX2 is used from the
Moondust Project directly.

https://github.com/WohlSoft/PGE-Project



## SMBX2 Launcher
The Launcher for SMBX2 is developing at the same repository as the LunaLua
library itself

https://github.com/WohlSoft/LunaLua/tree/master/LunadllNewLauncher



## The MixerX audio library
The audio backend library used in the game to play sounds and music.

https://github.com/WohlSoft/SDL-Mixer-X



## SDL2 library
The flexible interfaces library used for the audio output used by MixerX, and
for the extended game controllers support.

https://github.com/libsdl-org/SDL

