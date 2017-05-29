#!/bin/bash

function error() {
    echo "$1"
    exit 1
}

echo "Running linter"
luacheck src/lua ||  error "linter failed"
echo "Running tests"
pushd src/lua 
busted ../test && popd || {
    popd
    error "tests failed"
}
