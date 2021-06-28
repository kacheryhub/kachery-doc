#!/bin/bash

set -ex

# Installation:
# npm install -g @boillodmanuel/markdown-link-check

markdown-link-check ./README.md
find ./doc -name \*.md -exec markdown-link-check {} \;