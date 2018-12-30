@echo off
setlocal EnableExtensions EnableDelayedExpansion
pushd "%~dp0"
set "Build_Root=%~dp0"

:Init
if not exist "%VS150COMNTOOLS%" if exist "C:\Program Files (x86)\Microsoft Visual Studio\2017\Community\Common7\Tools" set "VS150COMNTOOLS=C:\Program Files (x86)\Microsoft Visual Studio\2017\Community\Common7\Tools"

:CheckReq
for /f "tokens=* delims=" %%i in ('where 7z') do set "_7z=%%i"
if not defined _7z set _7z=7z
"%_7z%" i 2>nul >nul || goto :CheckReqFail
if not exist "%VS150COMNTOOLS%" goto :CheckReqFail
goto :CheckReqSucc

:CheckReqFail
echo Requirement Check Failed.
echo Visual Studio 2017 should be installed,
echo 7z should be in PATH or current folder.
timeout /t 5 || pause
goto :End

:CheckReqSucc

:Download_7zip
set version=7z1805
call :Download https://www.7-zip.org/a/%version%-src.7z %version%-src.7z
"%_7z%" x %version%-src.7z

:Patch
call :Do_Shell_Exec 7-zip-patch.sh

:Init_VC_LTL
set "VC_LTL_Ver=4.0.0.26"
set "VC_LTL_File_Name=VC-LTL-%VC_LTL_Ver%-Binary-VS2017.7z"
set "VC_LTL_URL=https://github.com/Chuyu-Team/VC-LTL/releases/download/%VC_LTL_Ver%/%VC_LTL_File_Name%"
set "VC_LTL_Dir=VC-LTL"
mkdir "%VC_LTL_Dir%"
cd "%VC_LTL_Dir%"
call :Download "%VC_LTL_URL%" VC_LTL.7z
"%_7z%" x VC_LTL.7z
cd ..
set "VC_LTL_PATH=%CD%\%VC_LTL_Dir%"
set DisableAdvancedSupport=true
set LTL_Mode=Light

:Env_x64
set INCLUDE=
set LIB=
set VC_LTL_Helper_Load=
set Platform=
call "%VS150COMNTOOLS%..\..\VC\Auxiliary\Build\vcvarsall.bat" amd64
call "%VC_LTL_PATH%\VC-LTL helper for nmake.cmd"
@echo off

echo ----------------
echo PATH=
echo %PATH%
echo ----------------
echo INCLUDE=
echo %INCLUDE%
echo ----------------
echo LIB=
echo %LIB%
echo ----------------

:Build_x64
cd CPP\7zip
nmake /S NEW_COMPILER=1 MY_STATIC_LINK=1 CPU=AMD64
cd ..\..\C\Util\7z
nmake /S NEW_COMPILER=1 MY_STATIC_LINK=1 CPU=AMD64
cd ..\7zipInstall
nmake /S NEW_COMPILER=1 MY_STATIC_LINK=1 CPU=AMD64
cd ..\7zipUninstall
nmake /S NEW_COMPILER=1 MY_STATIC_LINK=1 CPU=AMD64
cd ..\SfxSetup
nmake /S NEW_COMPILER=1 MY_STATIC_LINK=1 CPU=AMD64
nmake /S /F makefile_con MY_STATIC_LINK=1 NEW_COMPILER=1 CPU=AMD64

:Env_x86
set INCLUDE=
set LIB=
set VC_LTL_Helper_Load=
set Platform=
set SupportWinXP=true
call "%VS150COMNTOOLS%..\..\VC\Auxiliary\Build\vsvars32.bat"
rem Extra patch for xp
call :Do_Shell_Exec 7-zip-patch-xp.sh
call "%VC_LTL_PATH%\VC-LTL helper for nmake.cmd"
@echo off

echo ----------------
echo PATH=
echo %PATH%
echo ----------------
echo INCLUDE=
echo %INCLUDE%
echo ----------------
echo LIB=
echo %LIB%
echo ----------------

:Build_x86
nmake /S NEW_COMPILER=1 MY_STATIC_LINK=1 SUB_SYS_VER=5.01
nmake /S /F makefile_con NEW_COMPILER=1 MY_STATIC_LINK=1 SUB_SYS_VER=5.01
cd ..\7z
nmake /S NEW_COMPILER=1 MY_STATIC_LINK=1 SUB_SYS_VER=5.01
cd ..\7zipInstall
nmake /S NEW_COMPILER=1 MY_STATIC_LINK=1 SUB_SYS_VER=5.01
cd ..\7zipUninstall
nmake /S NEW_COMPILER=1 MY_STATIC_LINK=1 SUB_SYS_VER=5.01
cd ..\..
"%_7z%" a -mx9 -r ..\%version%.7z *.dll *.exe *.efi *.sfx
cd ..\CPP\7zip
nmake /S NEW_COMPILER=1 MY_STATIC_LINK=1 SUB_SYS_VER=5.01

:Package
REM 7-zip extra
mkdir 7-zip-extra-x86
mkdir 7-zip-extra-x64
for /f "tokens=* eol=; delims=" %%i in (..\..\pack-7-zip-extra-x86.txt) do if exist "%%~i" move /Y "%%~i" 7-zip-extra-x86\
for /f "tokens=* eol=; delims=" %%i in (..\..\pack-7-zip-extra-x64.txt) do if exist "%%~i" move /Y "%%~i" 7-zip-extra-x64\
REM 7-zip
mkdir 7-zip-x86
mkdir 7-zip-x86\Lang
mkdir 7-zip-x64
mkdir 7-zip-x64\Lang
for /f "tokens=* eol=; delims=" %%i in (..\..\pack-7-zip-x86.txt) do if exist "%%~i" move /Y "%%~i" 7-zip-x86\
for /f "tokens=* eol=; delims=" %%i in (..\..\pack-7-zip-x64.txt) do if exist "%%~i" move /Y "%%~i" 7-zip-x64\
if exist 7-zip-x86\7-zip.dll copy 7-zip-x86\7-zip.dll 7-zip-x64\7-zip32.dll
mkdir installer
cd installer
call :Download https://www.7-zip.org/a/%version%-x64.exe %version%-x64.exe
"%_7z%" x %version%-x64.exe
xcopy /S /G /H /R /Y /Q .\Lang ..\7-zip-x86\Lang
xcopy /S /G /H /R /Y /Q .\Lang ..\7-zip-x64\Lang
for /f "tokens=* eol=; delims=" %%i in (..\..\..\pack-7-zip-common.txt) do if exist "%%~i" copy /Y "%%~i" ..\7-zip-x86\
for /f "tokens=* eol=; delims=" %%i in (..\..\..\pack-7-zip-common.txt) do if exist "%%~i" copy /Y "%%~i" ..\7-zip-x64\
cd ..
del /f /s /q installer\* >nul
rd /s /q installer
move /Y .\7-zip-x64\7zipUninstall.exe .\7-zip-x64\Uninstall.exe
move /Y .\7-zip-x86\7zipUninstall.exe .\7-zip-x86\Uninstall.exe
"%_7z%" a -mx9 -r ..\..\%version%.7z *.dll *.exe *.efi *.sfx 7-zip-x86\* 7-zip-x64\* 7-zip-extra-x86\* 7-zip-extra-x64\*
"%_7z%" a -m0=lzma -mx9 ..\..\%version%-x64.7z .\7-zip-x64\*
"%_7z%" a -m0=lzma -mx9 ..\..\%version%-x86.7z .\7-zip-x86\*
cd ..\..
copy /b .\C\Util\7zipInstall\AMD64\7zipInstall.exe /b + %version%-x64.7z /b %version%-x64.exe
copy /b .\C\Util\7zipInstall\O\7zipInstall.exe /b + %version%-x86.7z /b %version%-x86.exe

:Upload
if not defined APPVEYOR goto :End
appveyor PushArtifact %version%-x64.exe
appveyor PushArtifact %version%-x86.exe
appveyor PushArtifact %version%.7z

:End
exit /b

:Download
REM call :Download URL FileName
if defined APPVEYOR goto :Download_Appveyor
powershell -noprofile -command "(New-Object Net.WebClient).DownloadFile('%~1', '%~2')"
exit /b %ERRORLEVEL%

:Download_Appveyor
appveyor DownloadFile "%~1" -FileName "%~2"
exit /b %ERRORLEVEL%

:Do_Shell_Exec
if defined APPVEYOR goto :Do_Shell_Exec_Appveyor
busybox 2>nul >nul || call :Download https://frippery.org/files/busybox/busybox.exe busybox.exe
busybox sh "%Build_Root%\%1"
goto :Do_Shell_Exec_End

:Do_Shell_Exec_Appveyor
C:\msys64\usr\bin\bash -lc "cd \"$APPVEYOR_BUILD_FOLDER\" && exec ./%1"

:Do_Shell_Exec_End
exit /b %ERRORLEVEL%
