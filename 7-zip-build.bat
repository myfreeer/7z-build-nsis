set version=7z1801
"%VS140COMNTOOLS%..\..\VC\vcvarsall.bat" amd64
appveyor DownloadFile http://www.7-zip.org/a/%version%-src.7z
7z x %version%-src.7z
C:\msys64\usr\bin\bash -lc "cd \"$APPVEYOR_BUILD_FOLDER\" && exec ./7-zip-patch.sh"
cd CPP\7zip
nmake NEW_COMPILER=1 MY_STATIC_LINK=1 CPU=AMD64
"C:\Program Files (x86)\Microsoft Visual Studio 14.0\Common7\Tools\vsvars32.bat"
nmake NEW_COMPILER=1 MY_STATIC_LINK=1
7z a -mx9 -r ..\..\%version%.7z *.dll *.exe *.efi *.sfx