#!/bin/sh
echo "Running linter"
luacheck src/lua 
echo "Running tests"
pushd src/lua 
busted ../test
popd




