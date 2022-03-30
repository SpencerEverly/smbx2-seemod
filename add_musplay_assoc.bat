@echo off
setlocal
cd /d %~dp0

set PGE_MusPlay_exeFile=%cd%\data\PGE\pge_musplay.exe
set PGE_MusPlay_EXE="\"%PGE_MusPlay_exeFile%\" \"%%1\""

rem "Also add music files"
echo.
echo.
echo.
echo =========================================================================
echo                       !!!!!!!!!ATTENTION!!!!!!!!!
echo =========================================================================
echo    This script will associate some music formats you will choose with
echo    a small PGE MusPlay music player.
echo    It's a tiny music player which allows you to verify the music loops
echo    and playback behavior like in the SMBX2 game, but without running
echo    a game itself. Or play music files are can't be played by regular
echo    player like chiptunes for NES, SNES, Sega MegaDrive/Genesis, etc.
echo.
echo    This player is NOT intended to be a standard player.
echo    Use it for special cases only to verify music playback before
echo    including it into a game.
echo =========================================================================
echo         Do you want to associate music files with PGE MusPlay?
echo =========================================================================
echo   1 - Associate everything (except well-known: WAV, MP3, OGG, FLAC, etc.)
echo   2 - Associate everything (also except MIDI files: mid, midi, kar, rmi)
echo   3 - Associate chiptunes only (gbs, hes, nsf, nsfe, spc, vgm, vgz, etc.)
echo.
echo   4 - QUIT SCRIPT and Don't associate any music files
echo =========================================================================
choice /C 1234 /M "Choose a variant: "
echo.

if errorlevel 4 (
    echo Skipping file associations...
    goto quitWithNothing
)

if errorlevel 3 (
    @echo on
    for %%d in (cmf gbs gym hes imf mus nsf nsfe spc vgm vgz xmi) do (
        reg add "HKEY_CURRENT_USER\Software\Classes\.%%d" /f /v "" /t REG_SZ /d "PGEWohlstand.MusicFile"
    )
    @echo off
    goto ssss
)

if errorlevel 2 (
    @echo on
    for %%d in (669 amf apun ay cmf dsm far gbs gdm gym hes imf it kss med mus mod mptm mtm nsf nsfe okt s3m sap spc stm stx ult uni vgm vgz xm xmi) do (
        reg add "HKEY_CURRENT_USER\Software\Classes\.%%d" /f /v "" /t REG_SZ /d "PGEWohlstand.MusicFile"
    )
    @echo off
    goto ssss
)

if errorlevel 1 (
    @echo on
    for %%d in (669 amf apun ay cmf dsm far gbs gdm gym hes imf it kar kss med mid midi mus mod mptm mtm nsf nsfe okt rmi s3m sap spc stm stx ult uni vgm vgz xm xmi) do (
        reg add "HKEY_CURRENT_USER\Software\Classes\.%%d" /f /v "" /t REG_SZ /d "PGEWohlstand.MusicFile"
    )
    @echo off
    goto ssss
)
:ssss

@echo on
@rem "Music file entry to PGE MusPlay"
reg add "HKEY_CURRENT_USER\Software\Classes\PGEWohlstand.MusicFile" /f /v "" /t REG_SZ /d "PGE-MusPlay Music File"
reg add "HKEY_CURRENT_USER\Software\Classes\PGEWohlstand.MusicFile\DefaultIcon" /f /v "" /t REG_SZ /d "\"%PGE_MusPlay_exeFile%\",1"
reg add "HKEY_CURRENT_USER\Software\Classes\PGEWohlstand.MusicFile\Shell" /f
reg add "HKEY_CURRENT_USER\Software\Classes\PGEWohlstand.MusicFile\Shell\Open" /f
reg add "HKEY_CURRENT_USER\Software\Classes\PGEWohlstand.MusicFile\Shell\Open\command" /f /v "" /t REG_SZ /d %PGE_MusPlay_EXE%
@echo off

echo.
echo.
echo ========================================================================
echo                   Done associating with PGE MusPlayer!
echo                         Press any key to close...
echo ========================================================================
pause > NUL

:quitWithNothing
