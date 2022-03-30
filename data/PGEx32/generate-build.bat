@echo off
echo Copying data...
xcopy /Y /I /E /K /H ..\PGE\configs configs
xcopy /Y /I /E /K /H ..\PGE\tools tools
copy ..\PGE\update-pge* .
echo Patching scripts...
tools\fart update-pge* "bin-w64/_packed/pge-project-master-win64.zip" "bin-w32/_packed/pge-project-dev-win32.zip"
tools\fart update-pge* "bin-w64/_packed/pge-project-master-win64.zip" "bin-w32/_packed/pge-project-master-win32.zip"
tools\fart update-pge* "PGE_IS_COPY=false" "PGE_IS_COPY=true"
call update-pge.cmd %1
