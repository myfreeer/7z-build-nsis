# 7z-build-nsis
7-zip build script with nsis script decompiling using ms visual studio

This build can unpack nsis script, eg. `[NSIS].nsi` or `[LICENSE].txt` from nsis installer.
This feature is disable in official versions since `15.05`,
after which official versions are only able to unpack files from installer.

Notice: Only executables depending on `7z.dll` can unpack nsis packages,
`7zcl`, `7za`, `7zr` would not unpack nsis package, like official ones.

## Badges
[![Build status](https://ci.appveyor.com/api/projects/status/6uusps0bn00akik9?svg=true)](https://ci.appveyor.com/project/myfreeer/7z-build-nsis)
[![Downloads](https://img.shields.io/github/downloads/myfreeer/7z-build-nsis/total.svg)](https://github.com/myfreeer/7z-build-nsis/releases)
[![Latest Release](https://img.shields.io/github/downloads/myfreeer/7z-build-nsis/latest/total.svg)](https://github.com/myfreeer/7z-build-nsis/releases/latest)
[![Latest Release](https://img.shields.io/github/release/myfreeer/7z-build-nsis.svg)](https://github.com/myfreeer/7z-build-nsis/releases/latest)
[![GitHub license](https://img.shields.io/github/license/myfreeer/7z-build-nsis.svg)](LICENSE) 

## Prerequisites
* Visual Studio 2015 or 2017
* `7z.exe` in `PATH` or current folder.
* Internet accessible (with powershell `Net.WebClient`).

## Usage
Clone this repo and run `7-zip-build.bat`

## Credits
* <https://www.7-zip.org>
* <https://github.com/Chuyu-Team/VC-LTL>
* <https://sourceforge.net/p/sevenzip/discussion/45797/thread/5d10a376/>