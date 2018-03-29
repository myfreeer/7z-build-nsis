@echo off
setlocal EnableExtensions EnableDelayedExpansion
pushd "%~dp0"
set version=7z1803
call "%VS140COMNTOOLS%..\..\VC\vcvarsall.bat" amd64
git clone https://github.com/Chuyu-Team/VC-LTL.git --depth=1
set BITS=x64
set "PATH=%VC_LTL_PATH%;%VC_LTL_PATH%\VC\14.0.24210\include;%VC_LTL_PATH%\%BITS%;%VC_LTL_PATH%\VC\14.0.24210\lib\%BITS%;%PATH%"
set "INCLUDE=%VC_LTL_PATH%\VC\14.0.24210\include;%INCLUDE%"
set "LIB=%VC_LTL_PATH%\%BITS%;%VC_LTL_PATH%\VC\14.0.24210\lib\%BITS%;%VC_LTL_PATH%\ucrt\10.0.10240.0\lib\%BITS%;%LIB%"
appveyor DownloadFile https://www.7-zip.org/a/%version%-src.7z
7z x %version%-src.7z
C:\msys64\usr\bin\bash -lc "cd \"$APPVEYOR_BUILD_FOLDER\" && exec ./7-zip-patch.sh"
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
call "C:\Program Files (x86)\Microsoft Visual Studio 14.0\Common7\Tools\vsvars32.bat"
set BITS=x86
set "PATH=%VC_LTL_PATH%;%VC_LTL_PATH%\VC\14.0.24210\include;%VC_LTL_PATH%\%BITS%;%VC_LTL_PATH%\VC\14.0.24210\lib\%BITS%;%PATH%"
set "INCLUDE=%VC_LTL_PATH%\VC\14.0.24210\include;%INCLUDE%"
set "LIB=%VC_LTL_PATH%\%BITS%;%VC_LTL_PATH%\VC\14.0.24210\lib\%BITS%;%VC_LTL_PATH%\ucrt\10.0.10240.0\lib\%BITS%;%LIB%"
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
mkdir 7-zip-x86
mkdir 7-zip-x86\Lang
mkdir 7-zip-x64
mkdir 7-zip-x64\Lang
for /f "tokens=* eol=; delims=" %%i in (..\..\pack-7-zip-x86.txt) do if exist "%%~i" move /Y "%%~i" 7-zip-x86\
for /f "tokens=* eol=; delims=" %%i in (..\..\pack-7-zip-x64.txt) do if exist "%%~i" move /Y "%%~i" 7-zip-x64\
if exist 7-zip-x86\7-zip.dll copy 7-zip-x86\7-zip.dll 7-zip-x64\7-zip32.dll
mkdir 7-zip-extra-x86
mkdir 7-zip-extra-x64
for /f "tokens=* eol=; delims=" %%i in (..\..\pack-7-zip-extra-x86.txt) do if exist "%%~i" move /Y "%%~i" 7-zip-extra-x86\
for /f "tokens=* eol=; delims=" %%i in (..\..\pack-7-zip-extra-x64.txt) do if exist "%%~i" move /Y "%%~i" 7-zip-extra-x64\
mkdir installer
cd installer
appveyor DownloadFile https://www.7-zip.org/a/%version%-x64.exe
7z x %version%-x64.exe
xcopy /S /G /H /R /Y /D .\Lang ..\7-zip-x86\Lang
xcopy /S /G /H /R /Y /D .\Lang ..\7-zip-x64\Lang
copy /y "7-zip.chm" ..\7-zip-x86\
copy /y "7-zip.chm" ..\7-zip-x64\
copy /y "descript.ion" ..\7-zip-x86\
copy /y "descript.ion" ..\7-zip-x64\
copy /y "History.txt" ..\7-zip-x86\
copy /y "History.txt" ..\7-zip-x64\
copy /y "License.txt" ..\7-zip-x86\
copy /y "License.txt" ..\7-zip-x64\
copy /y "readme.txt" ..\7-zip-x86\
copy /y "readme.txt" ..\7-zip-x64\
cd ..
del /f /s /q installer\*
rd /s /q installer
move /Y .\7-zip-x64\7zipUninstall.exe .\7-zip-x64\Uninstall.exe
move /Y .\7-zip-x86\7zipUninstall.exe .\7-zip-x86\Uninstall.exe
7z a -mx9 -r ..\..\%version%.7z *.dll *.exe *.efi *.sfx 7-zip-x86\* 7-zip-x64\* 7-zip-extra-x86\* 7-zip-extra-x64\*
7z a -m0=lzma -mx9 ..\..\%version%-x64.7z .\7-zip-x64\*
7z a -m0=lzma -mx9 ..\..\%version%-x86.7z .\7-zip-x86\*
cd ..\..
copy /b .\C\Util\7zipInstall\AMD64\7zipInstall.exe /b + %version%-x64.7z /b %version%-x64.exe
copy /b .\C\Util\7zipInstall\O\7zipInstall.exe /b + %version%-x86.7z /b %version%-x86.exe