#!/bin/bash
# remove -OPT:NOWIN98 flag in Build.mak
# http://www.ski-epic.com/2012_compiling_7zip_on_windows_with_visual_studio_10/index.html
sed -i '/LFLAGS = $(LFLAGS) -OPT:NOWIN98/ c\LFLAGS = $(LFLAGS)\' CPP/Build.mak

# patch NsisIn.h to enable NSIS script decompiling
# https://sourceforge.net/p/sevenzip/discussion/45797/thread/5d10a376/
# insert #define NSIS_SCRIPT before the 19th line using sed
sed -i '19 i #define NSIS_SCRIPT' CPP/7zip/Archive/Nsis/NsisIn.h
