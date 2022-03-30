#!/bin/bash

wget http://wohlsoft.ru/docs/_laboratory/_Builds/win32/SDL-Mixer-X-MSVC15-Release-Win32-SDL-2.0.12.7z -O MixerX.7z
7z e -y MixerX.7z SDL-Mixer-X/bin/SDL2_mixer_ext.dll
# SDL-Mixer-X/bin/SDL2.dll # Don't touch SDL2 yet as it's customized one

rm -fv MixerX.7z

echo "==========="
echo "   DONE!"
echo "==========="

