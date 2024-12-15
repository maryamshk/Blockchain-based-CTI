#!/bin/bash
# Overwrites the config files
VER=0

if [ -n "$1" ]; then
    VER=$1
fi


ORIGIN=policy
SRC=$PWD/../setup/config/five-org/$ORIGIN.$VER

echo $SRC

if [ ! -d $SRC ]; then
    echo "Version $ORIGIN.$VER not found under config!!!"
    exit
fi

cp $SRC/*.yaml $PWD/five-org

echo "Done."
