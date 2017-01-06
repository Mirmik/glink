#!/usr/bin/env bash
#coding: utf-8

installdir=/usr/share/glinklua/

mkdir -p glink
cp -r $installdir/classes glink/
cp -r $installdir/lib glink/
cp $installdir/glinkBase.lua glink/

echo "glink" > .glinkDirectory