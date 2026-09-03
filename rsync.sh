#!/bin/bash

name=crunchy
ver=$(cat VERSION)

rsync -avP -e ssh \
    $HOME/release/"$name-$ver-x86_64.iso" \
    "himadrichakra12@frs.sourceforge.net:/home/frs/project/him12crunchy/$ver/"
