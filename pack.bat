@echo off
mkdir 7-zip-x86
mkdir 7-zip-x86\Lang
mkdir 7-zip-x64
mkdir 7-zip-x64\Lang
for /f "tokens=* eol=; delims=" %%i in (pack-7-zip-x86.txt) do if exist "%%~i" move /Y "%%~i" 7-zip-x86\
for /f "tokens=* eol=; delims=" %%i in (pack-7-zip-x64.txt) do if exist "%%~i" move /Y "%%~i" 7-zip-x64\
if exist 7-zip-x86\7-zip.dll copy 7-zip-x86\7-zip.dll 7-zip-x64\7-zip.dll
mkdir 7-zip-extra-x86
mkdir 7-zip-extra-x64
for /f "tokens=* eol=; delims=" %%i in (pack-7-zip-extra-x86.txt) do if exist "%%~i" move /Y "%%~i" 7-zip-extra-x86\
for /f "tokens=* eol=; delims=" %%i in (pack-7-zip-extra-x64.txt) do if exist "%%~i" move /Y "%%~i" 7-zip-extra-x64\
mkdir installer
cd installer
appveyor DownloadFile http://www.7-zip.org/a/%version%-x64.exe
7z x %version%-x64.exe
copy /y .\Lang\* ..\7-zip-x86\Lang\
copy /y .\Lang\* ..\7-zip-x64\Lang\
for %%i in (7-zip.chm descript.ion History.txt License.txt readme.txt) do if exist "%%~i" (
    copy /y "%%~i" ..\7-zip-x86\
    copy /y "%%~i" ..\7-zip-x64\
)
cd ..
del /f /s /q installer\*
rd /s /q installer