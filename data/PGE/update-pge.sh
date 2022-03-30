#!/bin/bash
PGE_WIN32ZIP="https://wohlsoft.ru/docs/_laboratory/_Builds/win32/bin-w64/_packed/pge-project-master-win64.zip"
# ================================================================================
#                         !!! IMPORTANT NOTE !!!
# Before release new SMBX build, make the replica of current in-repo config pack
# state, upload it into docs/_laboratory/config_packs/SMBX2 folder, store URL to
# it here, then, set SMBX2_IS_RELEASE with `true` value (without quotes)
# ================================================================================
PGE_SMBX20PACK="https://wohlsoft.ru/docs/_laboratory/config_packs/SMBX2/SMBX2-Integration-MAGLX3-PAL.zip"
SMBX2_IS_RELEASE=false
PGE_IS_COPY=false

echo "================================================"
echo "      Welcome to PGE Project update tool!"
echo "================================================"
echo "    Please, close Editor, Engine, Maintainer,"
echo "      and Calibrator until continue update"
echo "================================================"
echo "         To quit from this utility just"
echo "      close [x] this window or hit Ctrl+C"
echo ""
echo "Overwise, to begin update process, just"
echo "press any key..."
read -n 1


echo ""
echo ""
echo "* (1/4) Downloading..."
echo ""

if [ ! -d settings ]; then
    mkdir settings
fi

echo "- Downloading update for PGE toolchain..."
wget ${PGE_WIN32ZIP} -O "settings/pgezip.zip"
if [[ "$?" != "0" ]]; then
	echo "Failed to download ${PGE_WIN32ZIP}!"

	echo "Press any key to quit..."
	read -n 1
	exit 1
fi

if $SMBX2_IS_RELEASE; then
    echo "- Downloading update for config pack..."
    wget ${PGE_SMBX20PACK} -O "settings/configpack.zip"
    if [[ "$?" != "0" ]]; then
	    echo "Failed to download ${PGE_SMBX20PACK}!"

	    echo "Press any key to quit..."
	    read -n 1
	    exit 1
    fi
fi

echo "* (2/4) Extracting..."
unzip -o "settings/pgezip.zip" "PGE_Project/*" -d settings/PGE > /dev/null
if $SMBX2_IS_RELEASE; then
    unzip -o settings/configpack.zip -d settings/PGE/PGE_Project/configs > /dev/null
fi

echo "* (3/4) Copying..."
find settings/PGE/PGE_Project/ -name "*.exe" -exec chmod 755 {} \;
cp -a settings/PGE/PGE_Project/* .
if [[ "$?" != "0" ]]; then
	echo "======= ERROR! ======="
	echo "Some files can't be updated! Seems you still have opened some PGE applications"
	echo "Please close all of them and retry update again!"
	echo "======================"

	echo "Press any key to quit..."
	read -n 1
	exit 1
fi

if [[ "${PGE_IS_COPY}" == "true" ]]; then
    if [[ -d configs/SMBX2-Integration ]]; then
        rm -Rf configs/SMBX2-Integration
    fi
    cp -a ../PGE/configs .
fi

echo "* (4/4) Clean-up..."
rm settings/pgezip.zip
if $SMBX2_IS_RELEASE; then
    rm settings/configpack.zip
fi
rm -Rf settings/PGE

# Nuke useless themes are was added as examples
if [ -d "themes/Some Thing" ]; then rm -Rf "themes/Some Thing"; fi
if [ -d "themes/test" ]; then rm -Rf "themes/test"; fi
if [ -d "themes/pge_default" ]; then rm -Rf "themes/pge_default"; fi
if [ -f "themes/README.txt" ]; then rm "themes/README.txt"; fi

if [ -f "pge_engine.exe" ]; then
    rm "pge_engine.exe";
    rm -f "languages/engine_"*".qm"
fi

if [ -f "ipc/38a_ipc_bridge.exe" ]; then
    rm "ipc/38a_ipc_bridge.exe";
fi

echo ""
echo "Everything has been completed! ===="

echo "Press any key to quit..."
read -n 1

exit 0
