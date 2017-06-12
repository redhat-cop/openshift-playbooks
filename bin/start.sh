#!/bin/sh

SOURCE_DIR=/opt/jekyll

if [ ! -d "$SOURCE_DIR" ]; then
   echo "Error: Source volume not mounted or available"
   exit 1
fi

cd "$SOURCE_DIR"

bundle install
bundle exec jekyll serve --host=0.0.0.0
