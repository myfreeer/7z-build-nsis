#!/bin/bash
# patch Linker Options SUBSYSTEM to support xp
sed -i '/^MY_SUB_SYS_VER=5.02$/ c\MY_SUB_SYS_VER=5.01\' CPP/Build.mak
