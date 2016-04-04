#!/bin/bash
set -e

bundle exec jekyll build
bundle exec htmlproofer ./_site