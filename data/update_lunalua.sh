#!/bin/bash

wget http://wohlsoft.ru/docs/_laboratory/_Builds/win32/LunaLUA-bin.zip -O Luna.zip
7z e -y Luna.zip LunaDll.dll LunaDll.pdb glew32.dll

rm -fv Luna.zip

echo "==========="
echo "   DONE!"
echo "==========="

