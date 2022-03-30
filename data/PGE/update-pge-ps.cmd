@echo off
set PGE_WIN32ZIP=https://wohlsoft.ru/docs/_laboratory/_Builds/win32/bin-w64/_packed/pge-project-master-win64.zip
rem ================================================================================
rem                        !!! IMPORTANT NOTE !!!
rem Before release new SMBX build, make the replica of current in-repo config pack
rem state, upload it into docs/_laboratory/config_packs/SMBX2 folder, store URL to
rem it here, then, set SMBX2_IS_RELEASE with `true` value (without quotes)
rem ================================================================================
set PGE_SMBX20PACK=http://wohlsoft.ru/docs/_laboratory/config_packs/SMBX2/SMBX2-Integration-MAGLX3-PAL.zip
set SMBX2_IS_RELEASE=false
set PGE_IS_COPY=false

echo ================================================
echo       Welcome to PGE Project update tool!
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

echo * (1/4) Downloading...

if not exist settings\NUL md settings

echo - Downloading update for PGE toolchain...
powershell -Command "(New-Object Net.WebClient).DownloadFile('%PGE_WIN32ZIP%', 'settings\pgezip.zip')"
if errorlevel 1 (
	echo Failed to download %PGE_WIN32ZIP%!
	rundll32 user32.dll,MessageBeep
	pause
	goto quitAway
)

if "%SMBX2_IS_RELEASE%"=="true" (
    echo - Downloading update for config pack...
    powershell -Command "(New-Object Net.WebClient).DownloadFile('%PGE_SMBX20PACK%', 'settings\configpack.zip')"
    if errorlevel 1 (
	    echo Failed to download %PGE_SMBX20PACK%!
	    rundll32 user32.dll,MessageBeep
	    pause
	    goto quitAway
    )
    echo - DONE!
    echo.
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
rundll32 user32.dll,MessageBeep

pause
:quitAway
