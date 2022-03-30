#!/bin/bash

# Prints a line with text in middle
# Syntax:
#   printLine <string> <color of text in ANSI format> <color of line>
function printLine()
{
    lineLength=64
    Str=$1
    StrLen=${#Str}
    BeginAt=$(( ($lineLength/2) - ($StrLen/2) ))

    lineColor=$3
    textColor=$2

    if [[ "$lineColor" != "" ]]; then
    printf ${lineColor}; fi

    for((i=0; i < $lineLength; i++))
    do
        if (($i == $BeginAt))
        then
            if [[ "$textColor" != "" ]]; then
            printf ${textColor}; fi
        fi

        if (($i == $BeginAt + $StrLen))
        then
            if [[ "$lineColor" != "" ]]; then
            printf ${lineColor}; fi
        fi

        if (( $i >= $BeginAt && $i < $BeginAt + $StrLen ))
        then
            printf "${Str:$(($i-$BeginAt)):1}"
        else
            printf "="
        fi
    done
    printf "\E[0m"
    printf "\n"
}

function errorofbuild()
{
    printLine "AN ERROR OCCURRED!" "\E[0;41;37m" "\E[0;31m"
    cd ${bak}
    exit 1
}

function checkState()
{
    if [[ ! $? -eq 0 ]]
    then
        if [[ "$1" != "" ]]; then
            echo "ERROR: $1"
        fi
        errorofbuild
    fi
}

echo "== SMBX2 Configure for non-Windows platforms =="

SMBX2_HOME=$PWD/../data

SED_CMD=sed

if [[ "$OSTYPE" == "msys"* ]]; then
    echo "Windows platform doesn't needs anything to done by this script. You can use it directly as is!"
    exit 1;
elif [[ "$OSTYPE" == "darwin"* ]]; then
    PGE_HOME="$HOME/Library/Application Support/PGE Project"
    SED_CMD=gsed
else
    PGE_HOME="$HOME/.PGE_Project"
fi

if [[ ! -d "$PGE_HOME/configs" ]]; then
    mkdir -p "$PGE_HOME/configs"
fi

echo "-- Found PGE Project home directory: $PGE_HOME"

echo "-- Checking Wine version"
wine --version
checkState "wine is not found! Wine is required for work of SMBX2 on a non-Windows platform."
echo "-- Checking WineTricks version"
winetricks --version
checkState "winetricks is not found! WineTricks is required to install dependencies required for work of SMBX2."

echo "== Installing Wine-side dependencies"
echo "-- VB6 Runtime"
winetricks vb6run
checkState "Fail to install vb6run by winetricks"
echo "-- Quartz"
winetricks quartz
checkState "Fail to install quartz by winetricks"
echo "-- Direct3D"
winetricks d3dx10_43
checkState "Fail to install d3dx10_43 by winetricks"

if [[ -d "$PGE_HOME/configs/SMBX2-Integration" ]];
then
    printLine "!!WARNING!!" "\E[0;41;37m" "\E[0;31m"
    echo "SMBX2 config pack is already installed: $PGE_HOME/configs/SMBX2-Integration"
    echo "It will be replaced, all files in the folder WILL BE REMOVED."
    printLine "!!WARNING!!" "\E[0;41;37m" "\E[0;31m"
    echo -n "  Continue? [y/n]: "
    read -n 1 CONFIG_PACK_REPLACE
    echo -e "\n"
    if [[ "$CONFIG_PACK_REPLACE" != "y" ]]; then
        echo "Aborted!"
        exit 2;
    fi
    echo "-- Removing old config pack..."
    rm -Rf "$PGE_HOME/configs/SMBX2-Integration"
fi

echo "-- Copying SMBX2 config pack..."
cp -a "${SMBX2_HOME}/PGE/configs/SMBX2-Integration" "${PGE_HOME}/configs"
checkState

echo "-- Patching SMBX2 config pack..."
${SED_CMD} -i "s|application-path = \.\.|application-path = ${SMBX2_HOME}|gi" "${PGE_HOME}/configs/SMBX2-Integration/main.ini"
checkState
${SED_CMD} -i "s|config_name = \"SMBX2\"|config_name = \"SMBX2 \[Wine-Integration\]\"|gi" "${PGE_HOME}/configs/SMBX2-Integration/main.ini"
checkState
${SED_CMD} -i "s|extra-settings=\"../../../|extra-settings = \"${SMBX2_HOME}/|gi" "${PGE_HOME}/configs/SMBX2-Integration/lvl_blocks.ini"
checkState
${SED_CMD} -i "s|extra-settings=\"../../../|extra-settings = \"${SMBX2_HOME}/|gi" "${PGE_HOME}/configs/SMBX2-Integration/lvl_bgo.ini"
checkState
${SED_CMD} -i "s|extra-settings=\"../../../|extra-settings = \"${SMBX2_HOME}/|gi" "${PGE_HOME}/configs/SMBX2-Integration/lvl_npc.ini"
checkState

printLine "DONE!" "\E[0;42;37m" "\E[0;32m"
echo -e " - To play a game, start \"wine SMBX2.exe\" in the root of SMBX2 folder,"
echo -e "   or alternatively, start \"wine LunaLoader.exe\" from the 'data' folder if launcher won't start."
echo -e " - To use Editor, start Linux/macOS native PGE Editor and choose the"
echo -e "   \"SMBX2 [Wine-Integration]\" config pack to start creating for SMBX2!"

