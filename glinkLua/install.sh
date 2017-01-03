#!/usr/bin/env bash
#coding: utf-8

#VARIABLES
executable=/usr/local/bin/glink
installdir=/usr/share/glinklua/

sudo mkdir -p $installdir
sudo cp -r ./lib $installdir
sudo cp -r ./classes $installdir
sudo cp ./glinkBase.lua $installdir

sudo cp ./glink $executable
sudo sed -i 's|INSTALLDIR|'$installdir'|g' $executable
sudo chmod +x $executable