#!/usr/bin/env bash

export DYNAMIC_ISLAND_DIR
DYNAMIC_ISLAND_DIR=$(
    cd "$(dirname "${BASH_SOURCE[0]}")" || exit
    pwd -P
)

# run helper program
ISLANDHELPER=git.crissnb.islandhelper
killall islandhelper
make -C "$DYNAMIC_ISLAND_DIR"/helper/
"$DYNAMIC_ISLAND_DIR"/helper/islandhelper "$ISLANDHELPER" &
