#!/bin/bash
# Publishes package.json's name@version to its publishConfig registry, unless that version is already there.
set -e
name=$(node -p "require('./package.json').name")
version=$(node -p "require('./package.json').version")
registry=$(node -p "require('./package.json').publishConfig.registry")

if npm view "${name}@${version}" version --registry "$registry" >/dev/null 2>&1; then
    echo "${name}@${version} is already published, skipping"
    exit 0
fi
npm publish "$@"
