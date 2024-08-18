@echo off
setlocal EnableExtensions EnableDelayedExpansion
pushd "%~dp0"
set "Build_Root=%~dp0"

:Init
rem 7-zip version
rem https://www.7-zip.org/
set version=7z2408
rem https://github.com/mcmilk/7-Zip-zstd
set zstd_version=22.01-v1.5.5-R3

rem VC-LTL version
rem https://github.com/Chuyu-Team/VC-LTL5
set "VC_LTL_Ver=5.0.9"

:VS_Version
if defined APPVEYOR_BUILD_WORKER_IMAGE (
  if "%APPVEYOR_BUILD_WORKER_IMAGE%" == "Visual Studio 2022" (
    call "C:\Program Files\Microsoft Visual Studio\2022\Community\Common7\Tools\VsDevCmd.bat"
  )
  if "%APPVEYOR_BUILD_WORKER_IMAGE%" == "Visual Studio 2019" (
    call "C:\Program Files (x86)\Microsoft Visual Studio\2019\Community\Common7\Tools\VsDevCmd.bat"
  )
  if "%APPVEYOR_BUILD_WORKER_IMAGE%" == "Visual Studio 2017" (
    call "C:\Program Files (x86)\Microsoft Visual Studio\2017\Community\Common7\Tools\VsDevCmd.bat"
  )
)
if "%VisualStudioVersion%" == "14.0" goto :VS2015
if "%VisualStudioVersion%" == "15.0" goto :VS2017
if "%VisualStudioVersion%" == "16.0" goto :VS2019
if "%VisualStudioVersion%" == "17.0" goto :VS2022
if exist "%VSAPPIDDIR%\..\..\VC\Auxiliary\Build\vcvarsall.bat" == "15.0" goto :VS2017
if exist "%VS140COMNTOOLS%" goto :VS2015

:VS2022
if defined APPVEYOR call :Appveyor_Clean_Path_VS2019
set "VS=VS2022"
if exist "%VSINSTALLDIR%" if exist "%VSINSTALLDIR%\VC\Auxiliary\Build\vcvarsall.bat" (
  set "vcvarsall_bat=%VSINSTALLDIR%\VC\Auxiliary\Build\vcvarsall.bat"
  goto :CheckReq
)
if not exist "%VS170COMNTOOLS%" (
  if exist "C:\Program Files\Microsoft Visual Studio\2022\Community\Common7\Tools" (
    set "VS170COMNTOOLS=C:\Program Files\Microsoft Visual Studio\2022\Community\Common7\Tools\"
  )
  if exist "C:\Program Files\Microsoft Visual Studio\2022\Enterprise\Common7\Tools" (
    set "VS170COMNTOOLS=C:\Program Files\Microsoft Visual Studio\2022\Enterprise\Common7\Tools\"
  )
)
set "vcvarsall_bat=%VS170COMNTOOLS%..\..\VC\Auxiliary\Build\vcvarsall.bat"
if exist "%vcvarsall_bat%" goto :CheckReq

:VS2019
if defined APPVEYOR call :Appveyor_Clean_Path_VS2019
set "VS=VS2019"
if exist "%VSINSTALLDIR%" if exist "%VSINSTALLDIR%\VC\Auxiliary\Build\vcvarsall.bat" (
  set "vcvarsall_bat=%VSINSTALLDIR%\VC\Auxiliary\Build\vcvarsall.bat"
  goto :CheckReq
)
if not exist "%VS160COMNTOOLS%" (
  if exist "C:\Program Files (x86)\Microsoft Visual Studio\2019\Community\Common7\Tools" (
    set "VS160COMNTOOLS=C:\Program Files (x86)\Microsoft Visual Studio\2019\Community\Common7\Tools\"
  )
  if exist "C:\Program Files (x86)\Microsoft Visual Studio\2019\Enterprise\Common7\Tools" (
    set "VS160COMNTOOLS=C:\Program Files (x86)\Microsoft Visual Studio\2019\Enterprise\Common7\Tools\"
  )
)
set "vcvarsall_bat=%VS160COMNTOOLS%..\..\VC\Auxiliary\Build\vcvarsall.bat"
if exist "%vcvarsall_bat%" goto :CheckReq

:VS2017
set "VS=VS2017"
if exist "%VSAPPIDDIR%" if exist "%VSAPPIDDIR%\..\..\VC\Auxiliary\Build\vcvarsall.bat" (
set "vcvarsall_bat=%VSAPPIDDIR%\..\..\VC\Auxiliary\Build\vcvarsall.bat"
goto :CheckReq
)
if not exist "%VS150COMNTOOLS%" if exist "C:\Program Files (x86)\Microsoft Visual Studio\2017\Community\Common7\Tools" set "VS150COMNTOOLS=C:\Program Files (x86)\Microsoft Visual Studio\2017\Community\Common7\Tools\"
set "vcvarsall_bat=%VS150COMNTOOLS%..\..\VC\Auxiliary\Build\vcvarsall.bat"
goto :CheckReq

:VS2015
set "VS=VS2015"
if not exist "%VS140COMNTOOLS%" if exist "C:\Program Files\Microsoft Visual Studio 14.0\Common7\Tools" set "VS140COMNTOOLS=C:\Program Files\Microsoft Visual Studio 14.0\Common7\Tools\"
set "vcvarsall_bat=%VS140COMNTOOLS%..\..\VC\vcvarsall.bat"
goto :CheckReq

:CheckReq
for /f "tokens=* delims=" %%i in ('where 7z') do set "_7z=%%i"
if not defined _7z set _7z=7z
"%_7z%" i 2>nul >nul || goto :CheckReqFail
if not exist "%vcvarsall_bat%" goto :CheckReqFail
goto :CheckReqSucc

:CheckReqFail
echo Prerequisites Check Failed.
echo Visual Studio 2022 or 2019 or 2017 or 2015 should be installed,
echo or try to run this script from "Developer Command Prompt".
echo 7z should be in PATH or current folder.
timeout /t 5 || pause
goto :End

:CheckReqSucc

:Download_7zip
if "%src%" == "zstd" goto :Download_7zip_zstd
call :Download https://www.7-zip.org/a/%version%-src.7z %version%-src.7z
"%_7z%" x %version%-src.7z
goto :Patch

:Download_7zip_zstd
call :Download https://github.com/mcmilk/7-Zip-zstd/archive/v%zstd_version%.zip %zstd_version%.zip
"%_7z%" x "%zstd_version%.zip"
if exist "7-Zip-zstd-%zstd_version%" (
  cd "7-Zip-zstd-%zstd_version%"
) else (
  echo "source not found"
  exit /b 1
)
set "Build_Root=%CD%"
set "APPVEYOR_BUILD_FOLDER=%CD%"
copy ..\7-zip-patch.sh 7-zip-patch.sh
copy ..\7-zip-patch-xp.sh 7-zip-patch-xp.sh
goto :Patch

:Patch
call :Do_Shell_Exec 7-zip-patch.sh

:Init_VC_LTL
set "VC_LTL_File_Name=VC-LTL-%VC_LTL_Ver%-Binary.7z"
set "VC_LTL_URL=https://github.com/Chuyu-Team/VC-LTL5/releases/download/v%VC_LTL_Ver%/%VC_LTL_File_Name%"
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
set WindowsTargetPlatformMinVersion=6.0.6000.0
set CleanImport=true
set INCLUDE=
set LIB=
set VC_LTL_Helper_Load=
set Platform=
call "%vcvarsall_bat%" amd64
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
if "%src%" == "zstd" (
  call :Build_CPP_ZSTD /S NEW_COMPILER=1 MY_STATIC_LINK=1 CPU=AMD64 PLATFORM=x64
) else (
pushd CPP\7zip
nmake /S NEW_COMPILER=1 MY_STATIC_LINK=1 CPU=AMD64 PLATFORM=x64
popd
)

pushd C\Util\7z
nmake /S NEW_COMPILER=1 MY_STATIC_LINK=1 CPU=AMD64 PLATFORM=x64
popd

pushd C\Util\7zipInstall
nmake /S NEW_COMPILER=1 MY_STATIC_LINK=1 CPU=AMD64 PLATFORM=x64
popd

pushd C\Util\7zipUninstall
nmake /S NEW_COMPILER=1 MY_STATIC_LINK=1 CPU=AMD64 PLATFORM=x64
popd

pushd C\Util\SfxSetup
nmake /S NEW_COMPILER=1 MY_STATIC_LINK=1 CPU=AMD64 PLATFORM=x64
nmake /S /F makefile_con MY_STATIC_LINK=1 NEW_COMPILER=1 CPU=AMD64 PLATFORM=x64
popd

:Env_x86
set WindowsTargetPlatformMinVersion=5.1.2600.0
set CleanImport=true
set INCLUDE=
set LIB=
set VC_LTL_Helper_Load=
set Platform=
set SupportWinXP=true
call "%vcvarsall_bat%" x86
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
if "%src%" == "zstd" (
  call :Build_CPP_ZSTD /S NEW_COMPILER=1 MY_STATIC_LINK=1 SUB_SYS_VER=5.01
) else (
pushd CPP\7zip
nmake /S NEW_COMPILER=1 MY_STATIC_LINK=1 SUB_SYS_VER=5.01
popd
)
pushd C\Util\7z
nmake /S NEW_COMPILER=1 MY_STATIC_LINK=1 SUB_SYS_VER=5.01
popd

pushd C\Util\7zipInstall
nmake /S NEW_COMPILER=1 MY_STATIC_LINK=1 SUB_SYS_VER=5.01
popd

pushd C\Util\7zipUninstall
nmake /S NEW_COMPILER=1 MY_STATIC_LINK=1 SUB_SYS_VER=5.01
popd

pushd C\Util\SfxSetup
nmake /S NEW_COMPILER=1 MY_STATIC_LINK=1 SUB_SYS_VER=5.01
nmake /S /F makefile_con MY_STATIC_LINK=1 NEW_COMPILER=1 SUB_SYS_VER=5.01
popd

:Package
REM C Utils
pushd C\
"%_7z%" a -mx9 -r ..\%version%.7z *.dll *.exe *.efi *.sfx
popd
if "%src%" == "zstd"  copy ..\*.txt .
REM 7-zip extra
pushd CPP\7zip
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
popd
copy /b .\C\Util\7zipInstall\x64\7zipInstall.exe /b + %version%-x64.7z /b %version%-x64.exe
if exist .\C\Util\7zipInstall\x86\7zipInstall.exe copy /b .\C\Util\7zipInstall\x86\7zipInstall.exe /b + %version%-x86.7z /b %version%-x86.exe
if exist .\C\Util\7zipInstall\O\7zipInstall.exe copy /b .\C\Util\7zipInstall\O\7zipInstall.exe /b + %version%-x86.7z /b %version%-x86.exe

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
busybox.exe 2>nul >nul || call :Download https://frippery.org/files/busybox/busybox.exe busybox.exe
busybox.exe sh "%Build_Root%\%1"
goto :Do_Shell_Exec_End

:Do_Shell_Exec_Appveyor
C:\msys64\usr\bin\bash -lc "cd \"$APPVEYOR_BUILD_FOLDER\" && exec ./%1"

:Do_Shell_Exec_End
exit /b %ERRORLEVEL%

:Build_CPP_ZSTD
set "OPTS=%*"
pushd CPP\7zip\Bundles\Format7zExtract
nmake %OPTS%
popd

pushd CPP\7zip\Bundles\Format7z
nmake %OPTS%
popd

pushd CPP\7zip\Bundles\Format7zF
nmake %OPTS%
popd

pushd CPP\7zip\UI\FileManager
nmake %OPTS%
popd

pushd CPP\7zip\UI\GUI
nmake %OPTS%
popd

pushd CPP\7zip\UI\Explorer
nmake %OPTS%
popd

pushd CPP\7zip\Bundles\SFXWin
nmake %OPTS%
popd

pushd CPP\7zip\Bundles\Codec_brotli
nmake %OPTS%
popd

pushd CPP\7zip\Bundles\Codec_lizard
nmake %OPTS%
popd

pushd CPP\7zip\Bundles\Codec_lz4
nmake %OPTS%
popd

pushd CPP\7zip\Bundles\Codec_lz5
nmake %OPTS%
popd

pushd CPP\7zip\Bundles\Codec_zstd
nmake %OPTS%
popd

pushd CPP\7zip\Bundles\Codec_flzma2
nmake %OPTS%
popd

pushd CPP\7zip\UI\Console
nmake %OPTS%
popd

pushd CPP\7zip\Bundles\SFXCon
nmake %OPTS%
popd

pushd CPP\7zip\Bundles\Alone
nmake %OPTS%
popd

exit /b

:Appveyor_Clean_Path_VS2019
set "PATH=C:\Windows\system32;C:\Windows;C:\Windows\System32\Wbem;C:\Windows\System32\WindowsPowerShell\v1.0\;C:\Program Files\7-Zip;C:\Program Files\AppVeyor\BuildAgent\"
exit /b
