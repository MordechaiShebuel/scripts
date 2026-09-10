#!/usr/bin/env sh

DIR_BASE=$HOME
SEARCH=$1

find "$DIR_BASE" -type f | grep "$SEARCH"
