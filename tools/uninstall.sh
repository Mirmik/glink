#!/usr/bin/env bash
#coding: utf-8

set -o xtrace

source tools/variables.sh

sudo rm -r $installdir

#sudo rm -r $installdir/*
#sudo rm -r $lualibdir/*
#sudo rm -r $cclibdir/*

#sudo rmdir -p $installdir
#sudo rmdir -p $lualibdir
#sudo rmdir -p $cclibdir

sudo rm $executable
sudo rm $executableInit