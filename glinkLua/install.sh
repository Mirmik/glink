#!/usr/bin/env bash
#coding: utf-8

#VARIABLES
executable=/usr/local/bin/glink
executableInit=/usr/local/bin/glink-init
installdir=/usr/share/glinklua/

if [ -d "$installdir" ]; then
	sudo rm -r $installdir
fi

sudo mkdir -p $installdir
sudo cp -r ./lib $installdir
sudo cp -r ./classes $installdir
sudo cp -r ./templates $installdir

sudo cp -r ./tools $installdir
sudo chmod +x $installdir/tools/copyToLocal.sh

sudo cp ./glinkStarter.lua $installdir
sudo cp ./glinkBase.lua $installdir
sudo cp ./glinkInit.lua $installdir

sudo cp ./glink $executable
sudo sed -i 's|INSTALLDIR|'$installdir'|g' $executable
sudo chmod +x $executable

sudo cp ./glink-init $executableInit
sudo sed -i 's|INSTALLDIR|'$installdir'|g' $executableInit
sudo chmod +x $executableInit

make
sudo cp glinkLib.so /usr/local/lib/lua/5.3/glinkLib.so