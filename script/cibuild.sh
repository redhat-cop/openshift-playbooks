#!/bin/bash
set -e # halt script on error

bundle exec jekyll build
bundle exec htmlproof ./_site
