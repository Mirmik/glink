#!/usr/bin/env bash
#coding: utf-8

set -o xtrace

source variables.sh

sudo rm -r $installdir
sudo rm -r $lualibdir
sudo rm -r $cclibdir

sudo rm $executable
sudo rm $executableInit