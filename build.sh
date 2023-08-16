#!/bin/sh

set -euf

EXEC="./fetch"
OBJ="fetch.o"
nasm -felf64 fetch.asm -o "$OBJ"
ld "$OBJ" -o "$EXEC"

if [[ $* == *run* ]]; then 
    "$EXEC"
elif [[ $* == *strace* ]]; then
    strace "$EXEC"
elif [[ $* == *valgrind* ]]; then
    valgrind "$EXEC"
fi

if [[ $* == *install* ]]; then
    install -c "$EXEC" /usr/bin
fi
