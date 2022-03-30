@echo off
setlocal
cd /d %~dp0

set PGE_Editor_exeFile=%cd%\data\PGE\pge_editor.exe
set PGE_Editor_EXE="\"%PGE_Editor_exeFile%\" \"%%1\""
set LunaTester_EXE="\"%cd%\data\LunaLoader.exe\" --testLevel=\"%%1\""

@echo on

@rem "Deleting old broken registry branches to avoid conflicts (if they are exist)"
reg delete "HKEY_CURRENT_USER\Software\Microsoft\Windows\CurrentVersion\Explorer\FileExts\.lvl" /f
reg delete "HKEY_CURRENT_USER\Software\Microsoft\Windows\CurrentVersion\Explorer\FileExts\.lvlx" /f
reg delete "HKEY_CURRENT_USER\Software\Classes\lvl_auto_file" /f

@rem "PGE-X Level file entry"
reg add "HKEY_CURRENT_USER\Software\Classes\PGEWohlstand.Level" /f /v "" /t REG_SZ /d "PGE Level file"
reg add "HKEY_CURRENT_USER\Software\Classes\PGEWohlstand.Level\DefaultIcon" /f /v "" /t REG_SZ /d "\"%PGE_Editor_exeFile%\",1"
reg add "HKEY_CURRENT_USER\Software\Classes\PGEWohlstand.Level\Shell" /f
reg add "HKEY_CURRENT_USER\Software\Classes\PGEWohlstand.Level\Shell\Open" /f
reg add "HKEY_CURRENT_USER\Software\Classes\PGEWohlstand.Level\Shell\Open\command" /f /v "" /t REG_SZ /d %LunaTester_EXE%
reg add "HKEY_CURRENT_USER\Software\Classes\PGEWohlstand.Level\Shell\Edit" /f
reg add "HKEY_CURRENT_USER\Software\Classes\PGEWohlstand.Level\Shell\Edit\command" /f /v "" /t REG_SZ /d %PGE_Editor_EXE%

@rem "PGE-X World map file entry"
reg add "HKEY_CURRENT_USER\Software\Classes\PGEWohlstand.World" /f /v "" /t REG_SZ /d "PGE World Map"
reg add "HKEY_CURRENT_USER\Software\Classes\PGEWohlstand.World\DefaultIcon" /f /v "" /t REG_SZ /d "\"%PGE_Editor_exeFile%\",2"
reg add "HKEY_CURRENT_USER\Software\Classes\PGEWohlstand.World\Shell" /f
reg add "HKEY_CURRENT_USER\Software\Classes\PGEWohlstand.World\Shell\Open" /f
reg add "HKEY_CURRENT_USER\Software\Classes\PGEWohlstand.World\Shell\Open\command" /f /v "" /t REG_SZ /d %PGE_Editor_EXE%

@rem "SMBX64 or SMBX-38A Level file entry"
reg add "HKEY_CURRENT_USER\Software\Classes\SMBX64.Level" /f /v "" /t REG_SZ /d "SMBX64/38A Level file"
reg add "HKEY_CURRENT_USER\Software\Classes\SMBX64.Level\DefaultIcon" /f /v "" /t REG_SZ /d "\"%PGE_Editor_exeFile%\",3"
reg add "HKEY_CURRENT_USER\Software\Classes\SMBX64.Level\Shell" /f
reg add "HKEY_CURRENT_USER\Software\Classes\SMBX64.Level\Shell\Open" /f
reg add "HKEY_CURRENT_USER\Software\Classes\SMBX64.Level\Shell\Open\command" /f /v "" /t REG_SZ /d %LunaTester_EXE%
reg add "HKEY_CURRENT_USER\Software\Classes\SMBX64.Level\Shell\Edit" /f
reg add "HKEY_CURRENT_USER\Software\Classes\SMBX64.Level\Shell\Edit\command" /f /v "" /t REG_SZ /d %PGE_Editor_EXE%

@rem "SMBX64 or SMBX-38A World map file entry"
reg add "HKEY_CURRENT_USER\Software\Classes\SMBX64.World" /f /v "" /t REG_SZ /d "SMBX64/38A World Map"
reg add "HKEY_CURRENT_USER\Software\Classes\SMBX64.World\DefaultIcon" /f /v "" /t REG_SZ /d "\"%PGE_Editor_exeFile%\",4"
reg add "HKEY_CURRENT_USER\Software\Classes\SMBX64.World\Shell" /f
reg add "HKEY_CURRENT_USER\Software\Classes\SMBX64.World\Shell\Open" /f
reg add "HKEY_CURRENT_USER\Software\Classes\SMBX64.World\Shell\Open\command" /f /v "" /t REG_SZ /d %PGE_Editor_EXE%

@rem "Then, mark filename extensions with specified file type entries"
reg add "HKEY_CURRENT_USER\Software\Classes\.lvlx" /f /v "" /t REG_SZ /d "PGEWohlstand.Level"
reg add "HKEY_CURRENT_USER\Software\Classes\.wldx" /f /v "" /t REG_SZ /d "PGEWohlstand.World"
reg add "HKEY_CURRENT_USER\Software\Classes\.lvl" /f /v "" /t REG_SZ /d "SMBX64.Level"
reg add "HKEY_CURRENT_USER\Software\Classes\.wld" /f /v "" /t REG_SZ /d "SMBX64.World"

@echo off


echo.
echo.
echo ========================================================================
echo                   Done associating with LunaLoader!
echo                         Press any key to close...
echo ========================================================================
pause > NUL

