#!/bin/sh
echo "Running linter"
luacheck src/lua || exit 1
echo "Running tests"
pushd src/lua 
busted ../test
popd




