set 7z_version=7z1801
"C:\Program Files (x86)\Microsoft Visual Studio 14.0\Common7\Tools\vsvars32.bat"
appveyor DownloadFile http://www.7-zip.org/a/%7z_version%-src.7z
7z x %7z_version%-src.7z
C:\msys64\usr\bin\bash -lc "cd \"$APPVEYOR_BUILD_FOLDER\" && exec ./7-zip-patch.sh"
cd CPP\7zip
nmake NEW_COMPILER=1 MY_STATIC_LINK=1 CPU=AMD64
7z a -mx9 -r ..\..\%7z_version%-x64.7z *.dll *.exe *.efi *.sfx
nmake NEW_COMPILER=1 MY_STATIC_LINK=1
7z a -mx9 -r ..\..\%7z_version%-x86.7z *.dll *.exe *.efi *.sfx