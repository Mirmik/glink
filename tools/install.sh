#!/usr/bin/env bash
#coding: utf-8

set -o xtrace

#VARIABLES
source variables.sh

if [ -d "$installdir" ]; then
	sudo rm -r $installdir
fi

#INSTALL TEMPLATES AND TOOLS
sudo mkdir -p $installdir
sudo cp -r ./templates $installdir
sudo cp -r ./tools $installdir
sudo chmod +x $installdir/tools/copyToLocal.sh

#INSTALL LUA LIBS
sudo mkdir -p $lualibdir
sudo cp -r ./lib $lualibdir
sudo cp -r ./classes $lualibdir

#INSTALL CC LIBS
sudo mkdir -p $cclibdir
sudo cp glinkLib.so $cclibdir/glinkLib.so

sudo cp ./glinkStarter.lua $installdir
sudo cp ./glinkBase.lua $installdir
sudo cp ./glinkInit.lua $installdir

sudo cp ./executable/glink $executable
sudo sed -i 's|INSTALLDIR|'$installdir'|g' $executable
sudo chmod +x $executable

sudo cp ./executable/glink-init $executableInit
sudo sed -i 's|INSTALLDIR|'$installdir'|g' $executableInit
sudo chmod +x $executableInit
