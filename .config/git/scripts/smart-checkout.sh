#!/bin/bash

# If creating new branch with -b
if [[ "$1" == "-b" ]]; then
    current_branch=$(git rev-parse --abbrev-ref HEAD)

    # Check if current branch is main or a feature/fix/infra branch
    if [[ $current_branch != 'dev' ]]; then
        echo "WARNING: Cannot create new branch from $current_branch"
        echo "Checking out dev first"
        git checkout dev
    fi

    git fetch origin

    # Check if local dev is behind remote dev
    local_behind_remote=$(git rev-list --count HEAD..origin/dev)
    if [ $local_behind_remote -gt 0 ]; then
        echo "Local dev is behind remote dev. Pulling from dev..."
        git pull
    fi
fi

# Perform the checkout
git checkout "$@"