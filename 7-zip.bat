"C:\Program Files (x86)\Microsoft Visual Studio 14.0\Common7\Tools\vsvars32.bat"
appveyor DownloadFile http://www.7-zip.org/a/7z1801-src.7z
7z x 7z1801-src.7z
C:\msys64\usr\bin\bash -lc "cd \"$APPVEYOR_BUILD_FOLDER\" && exec ./7-zip-patch.sh"
cd CPP
nmake NEW_COMPILER=1 MY_STATIC_LINK=1