@echo off
set PGE_WIN32ZIP=http://codehaus.moe/builds/win32/moondust-win64/pge-project-master-win64.zip
rem ================================================================================
rem                        !!! IMPORTANT NOTE !!!
rem Before release new SMBX build, make the replica of current in-repo config pack
rem state, upload it into docs/_laboratory/config_packs/SMBX2 folder, store URL to
rem it here, then, set SMBX2_IS_RELEASE with `true` value (without quotes)
rem ================================================================================
set PGE_SMBX20PACK=http://codehaus.moe/builds/SMBX2-Integration.zip
set SMBX2_IS_RELEASE=false
set PGE_IS_COPY=false

if NOT "%1"=="--no-splash" (
    echo ================================================
    echo         Welcome to X2 Devkit update tool!
    echo ================================================
    echo     Please, close Editor, Engine, Maintainer,
    echo       and Calibrator until continue update
    echo ================================================
    echo          To quit from this utility just
    echo       close [x] this window or hit Ctrl+C
    echo.
    echo Overwise, to begin update process, just
    pause

    echo.
    echo * Preparing...
    taskkill /t /f /im pge_editor.exe > NUL 2>&1
    taskkill /t /f /im pge_engine.exe > NUL 2>&1
    taskkill /t /f /im pge_musplay.exe > NUL 2>&1
    taskkill /t /f /im pge_calibrator.exe > NUL 2>&1
    taskkill /t /f /im pge_maintainer.exe > NUL 2>&1
    taskkill /t /f /im smbx.exe > NUL 2>&1
    echo.
)

set WGETBIN=tools\wget.exe
rem Use different binary for Windows XP
for /f "tokens=4-5 delims=. " %%i in ('ver') do set VERSION=%%i.%%j
if "%version%" == "5.1" set WGETBIN=tools\wgetxp.exe
if "%version%" == "5.2" set WGETBIN=tools\wgetxp.exe

echo * (1/4) Downloading...
echo.

if not exist settings\NUL md settings

echo - Downloading update for PGE toolchain...
%WGETBIN% %PGE_WIN32ZIP% -O settings\pgezip.zip
if errorlevel 1 (
	echo Failed to download %PGE_WIN32ZIP%!
	rundll32 user32.dll,MessageBeep
	pause
	goto quitAway
)

if "%SMBX2_IS_RELEASE%"=="true" (
    echo - Downloading update for config pack...
    %WGETBIN% %PGE_SMBX20PACK% -O settings\configpack.zip
    if errorlevel 1 (
	    echo Failed to download %PGE_SMBX20PACK%!
	    rundll32 user32.dll,MessageBeep
	    pause
	    goto quitAway
    )
)

echo * (2/4) Extracting...
tools\unzip -o settings\pgezip.zip PGE_Project/* -d settings\PGE > NUL
if "%SMBX2_IS_RELEASE%"=="true" (
    tools\unzip -o settings\configpack.zip -d settings\PGE\PGE_Project\configs > NUL
)

echo * (3/4) Copying...
xcopy /E /C /Y /I settings\PGE\PGE_Project\* . > NUL
if errorlevel 1 (
	echo ======= ERROR! =======
	echo Some files can't be updated! Seems you still have opened some PGE applications
	echo Please close all of them and retry update again!
	echo ======================
	rundll32 user32.dll,MessageBeep
	pause
	goto quitAway
)

if "%PGE_IS_COPY%"=="true" (
    if exist configs\SMBX2-Integration\NUL del /Q /F /S configs\SMBX2-Integration > NUL
    xcopy /I /E /K /H ..\PGE\configs configs > NUL
)

echo * (4/4) Clean-up...
del /Q /F /S settings\pgezip.zip > NUL
if "%SMBX2_IS_RELEASE%"=="true" (
    del /Q /F /S settings\configpack.zip > NUL
)
rd /S /Q settings\PGE

rem Nuke useless themes are was added as examples
if exist "themes\Some Thing\NUL" rd /S /Q "themes\Some Thing" > NUL
if exist "themes\test\NUL" rd /S /Q "themes\test" > NUL
if exist "themes\pge_default\NUL" rd /S /Q "themes\pge_default" > NUL
if exist "themes\README.txt" del "themes\README.txt" > NUL

if exist "pge_engine.exe" (
    del "pge_engine.exe" > NUL
    del languages\engine_*.qm > NUL
)

if exist "ipc\38a_ipc_bridge.exe" (
    del "ipc\38a_ipc_bridge.exe" > NUL
)

echo.
echo Everything has been completed! ====
echo.
rundll32 user32.dll,MessageBeep
if "%1"=="--no-splash" (
    echo.
    choice /N /C NY /M "Do you want to start the Editor? [Y/N] "
    if errorlevel 2 (
        start pge_editor.exe
    )
    echo.
    exit
) else (
    pause
)
:quitAway
