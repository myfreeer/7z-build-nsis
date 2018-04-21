@echo off
setlocal EnableExtensions EnableDelayedExpansion
pushd "%~dp0"

:Init
if not exist "%VS140COMNTOOLS%" if exist "C:\Program Files\Microsoft Visual Studio 14.0\Common7\Tools" set "VS140COMNTOOLS=C:\Program Files\Microsoft Visual Studio 14.0\Common7\Tools\"

:CheckReq
git --version 2>nul >nul  || goto :CheckReqFail
7z i 2>nul >nul  || goto :CheckReqFail
if not exist "%VS140COMNTOOLS%" goto :CheckReqFail
goto :CheckReqSucc

:CheckReqFail
echo Check Requirement Failed.
echo Visual Studio 2015 should be installed.
echo git and 7z should be in PATH
timeout /t 5 || pause
goto :End

:CheckReqSucc

:Download_7zip
set version=7z1803
call :Download https://www.7-zip.org/a/%version%-src.7z %version%-src.7z
7z x %version%-src.7z

:Patch
if defined APPVEYOR goto :Patch_Appveyor
busybox 2>nul >nul || call :Download https://frippery.org/files/busybox/busybox.exe busybox.exe
busybox sh 7-zip-patch.sh
goto :Patch_Done

:Patch_Appveyor
C:\msys64\usr\bin\bash -lc "cd \"$APPVEYOR_BUILD_FOLDER\" && exec ./7-zip-patch.sh"

:Patch_Done

:Init_VC_LTL
git config --global core.autocrlf true
git clone https://github.com/Chuyu-Team/VC-LTL.git --depth=1
set "VC_LTL_PATH=%CD%\VC-LTL"
set DisableAdvancedSupport=true
set LTL_Mode=Light

:Env_x64
set INCLUDE=
set LIB=
set VC_LTL_Helper_Load=
set Platform=
call "%VS140COMNTOOLS%..\..\VC\vcvarsall.bat" amd64
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
nmake NEW_COMPILER=1 CPU=AMD64
cd ..\..\C\Util\7z
nmake NEW_COMPILER=1 CPU=AMD64
cd ..\7zipInstall
nmake NEW_COMPILER=1 CPU=AMD64
cd ..\7zipUninstall
nmake NEW_COMPILER=1 CPU=AMD64
cd ..\SfxSetup
nmake NEW_COMPILER=1 CPU=AMD64
nmake /F makefile_con NEW_COMPILER=1 CPU=AMD64

:Env_x86
set INCLUDE=
set LIB=
set VC_LTL_Helper_Load=
set Platform=
call "%VS140COMNTOOLS%\vsvars32.bat"
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
nmake NEW_COMPILER=1
nmake /F makefile_con NEW_COMPILER=1
cd ..\7z
nmake NEW_COMPILER=1
cd ..\7zipInstall
nmake NEW_COMPILER=1
cd ..\7zipUninstall
nmake NEW_COMPILER=1
cd ..\..
7z a -mx9 -r ..\%version%.7z *.dll *.exe *.efi *.sfx
cd ..\CPP\7zip
nmake NEW_COMPILER=1

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
7z x %version%-x64.exe
xcopy /S /G /H /R /Y /Q .\Lang ..\7-zip-x86\Lang
xcopy /S /G /H /R /Y /Q .\Lang ..\7-zip-x64\Lang
for /f "tokens=* eol=; delims=" %%i in (..\..\..\pack-7-zip-common.txt) do if exist "%%~i" copy /Y "%%~i" ..\7-zip-x86\
for /f "tokens=* eol=; delims=" %%i in (..\..\..\pack-7-zip-common.txt) do if exist "%%~i" copy /Y "%%~i" ..\7-zip-x64\
cd ..
del /f /s /q installer\* >nul
rd /s /q installer
move /Y .\7-zip-x64\7zipUninstall.exe .\7-zip-x64\Uninstall.exe
move /Y .\7-zip-x86\7zipUninstall.exe .\7-zip-x86\Uninstall.exe
7z a -mx9 -r ..\..\%version%.7z *.dll *.exe *.efi *.sfx 7-zip-x86\* 7-zip-x64\* 7-zip-extra-x86\* 7-zip-extra-x64\*
7z a -m0=lzma -mx9 ..\..\%version%-x64.7z .\7-zip-x64\*
7z a -m0=lzma -mx9 ..\..\%version%-x86.7z .\7-zip-x86\*
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