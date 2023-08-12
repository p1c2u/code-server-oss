#! /usr/bin/env bash

set -ex

# Get project root dir
ROOT="$(pwd)"

code_server () {
  $ROOT/node $ROOT/out/server-main.js $@
}

echo "Preinstalling extensions..."
for file in $(find $ROOT/extensions -name '*.vsix'); do
  echo "Installing $file"
  code_server --install-extension $file
done

echo "Starting server with args: $@"
code_server $@
