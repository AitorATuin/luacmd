#!/bin/bash

function error() {
    echo "$1"
    exit 1
}

busted_opts="$@"

echo "Running linter"
luacheck src/lua ||  error "linter failed"
echo "Running tests"
pushd src/lua 
busted ../test "$busted_opts" && popd || {
    popd
    error "tests failed"
}
