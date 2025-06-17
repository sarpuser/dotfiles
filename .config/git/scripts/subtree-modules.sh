#!/bin/bash

# Git Module Management Script
# Manages git subtree modules in a modules/ directory

set -e  # Exit on any error

MODULES_DIR="modules"
MODULES_CONFIG_FILE="$MODULES_DIR/.modules"

# Function to create modules directory if it doesn't exist
createModulesDirIfNeeded() {
    if [ ! -d "$MODULES_DIR" ]; then
        mkdir -p "$MODULES_DIR"
        echo "Created $MODULES_DIR directory"
    fi
}

# Function to check if module URL already exists in config
checkModuleUrlExists() {
    local moduleUrl
    moduleUrl="$1"

    if [ -f "$MODULES_CONFIG_FILE" ]; then
        # Check if any line contains this URL
        if grep -q "=$moduleUrl$" "$MODULES_CONFIG_FILE"; then
            # Return the module name that uses this URL
            grep "=$moduleUrl$" "$MODULES_CONFIG_FILE" | cut -d'=' -f1
            return 0
        fi
    fi
    return 1
}

# Function to check if module name already exists
checkModuleNameExists() {
    local moduleName
    moduleName="$1"

    if [ -f "$MODULES_CONFIG_FILE" ]; then
        if grep -q "^$moduleName=" "$MODULES_CONFIG_FILE"; then
            return 0  # Name exists
        fi
    fi
    return 1  # Name doesn't exist
}

# Function to extract repository name from URL
extractRepoNameFromUrl() {
    local moduleUrl
    moduleUrl="$1"
    # Remove .git suffix if present, then get the last part of the path
    echo "$moduleUrl" | sed 's/\.git$//' | sed 's|.*/||'
}

# Function to add module entry to .modules file
addModuleToConfigFile() {
    local moduleName
    local moduleUrl
    moduleName="$1"
    moduleUrl="$2"

    createModulesDirIfNeeded
    echo "$moduleName=$moduleUrl" >> "$MODULES_CONFIG_FILE"
}

# Function to remove module entry from .modules file
removeModuleFromConfigFile() {
    local moduleName
    moduleName="$1"

    if [ -f "$MODULES_CONFIG_FILE" ]; then
        # Create temporary file without the module line
        grep -v "^$moduleName=" "$MODULES_CONFIG_FILE" > "$MODULES_CONFIG_FILE.tmp" || true
        mv "$MODULES_CONFIG_FILE.tmp" "$MODULES_CONFIG_FILE"
    fi
}

# Function to get module URL from .modules file
getModuleUrlFromConfig() {
    local moduleName
    moduleName="$1"

    if [ -f "$MODULES_CONFIG_FILE" ]; then
        # Handle both new format (with |) and legacy format (just URL)
        local configLine
        configLine=$(grep "^$moduleName=" "$MODULES_CONFIG_FILE" | head -1)
        if [ -n "$configLine" ]; then
            # Extract just the URL part (before the |)
            echo "$configLine" | cut -d'=' -f2- | cut -d'|' -f1
        fi
    fi
}

# Function to get all module names from .modules file
getAllModuleNamesFromConfig() {
    if [ -f "$MODULES_CONFIG_FILE" ]; then
        cut -d'=' -f1 "$MODULES_CONFIG_FILE"
    fi
}

# Function to add a new module
addModule() {
    local moduleUrl
    local customName
    local repoName
    local moduleSubtreePath
    local moduleName
    local existingModuleName

    # Parse arguments for flags
    while [[ $# -gt 0 ]]; do
        case $1 in
            --name)
                customName="$2"
                shift 2
                ;;
            *)
                if [ -z "$moduleUrl" ]; then
                    moduleUrl="$1"
                else
                    echo "Error: Unexpected argument '$1'"
                    exit 1
                fi
                shift
                ;;
        esac
    done

    if [ -z "$moduleUrl" ]; then
        echo "Error: Module URL is required"
        exit 1
    fi

    repoName=$(extractRepoNameFromUrl "$moduleUrl")

    # Determine module name (use custom name if provided, otherwise repo name)
    if [ -n "$customName" ]; then
        moduleName="$customName"
    else
        moduleName="$repoName"
    fi

    moduleSubtreePath="$MODULES_DIR/$moduleName"

    # Check if this URL is already installed under a different name
    if existingModuleName=$(checkModuleUrlExists "$moduleUrl"); then
        echo "Error: This module URL is already installed as '$existingModuleName'"
        echo "Use 'git module rm $existingModuleName' first if you want to reinstall with a different name"
        exit 1
    fi

    # Check if the module name already exists
    if checkModuleNameExists "$moduleName"; then
        echo "Error: Module name '$moduleName' already exists"
        if [ -n "$customName" ]; then
            echo "Choose a different name with --name <different_name>"
        else
            echo "Use --name <custom_name> to install with a different name"
        fi
        exit 1
    fi

    # Check if the directory already exists
    if [ -d "$moduleSubtreePath" ]; then
        echo "Error: Directory '$moduleSubtreePath' already exists"
        echo "Remove it first or use a different name with --name <different_name>"
        exit 1
    fi

    createModulesDirIfNeeded

    echo "Adding module '$moduleName'..."

    # Add subtree - pulls the entire repository
    git subtree add --prefix="$moduleSubtreePath" "$moduleUrl" main --squash

    # Store module config
    addModuleToConfigFile "$moduleName" "$moduleUrl"

    echo "Successfully added module '$moduleName' from $moduleUrl"
}

# Function to show module status
showModuleStatus() {
    local moduleNames=("$@")

    # If no modules specified, get all modules
    if [ ${#moduleNames[@]} -eq 0 ]; then
        while IFS= read -r moduleName; do
            moduleNames+=("$moduleName")
        done < <(getAllModuleNamesFromConfig)
    fi

    if [ ${#moduleNames[@]} -eq 0 ]; then
        echo "No modules found"
        return
    fi

    local hasNewCommits=false
    local firstModule=true

    for moduleName in "${moduleNames[@]}"; do
        local moduleSubtreePath
        local lastMergeCommit
        local newCommitsCount
        local allCommitsCount

        moduleSubtreePath="$MODULES_DIR/$moduleName"

        if [ ! -d "$moduleSubtreePath" ]; then
            echo "Warning: Module directory '$moduleSubtreePath' not found"
            continue
        fi

        # Find the last merge commit for this module
        lastMergeCommit=$(git log --grep="Merge commit.*$moduleSubtreePath" --pretty=format:"%H" -n 1)

        if [ -n "$lastMergeCommit" ]; then
            # Get commits after the merge commit
            newCommitsCount=$(git log --oneline "$lastMergeCommit..HEAD" -- "$moduleSubtreePath" | wc -l)

            if [ "$newCommitsCount" -gt 0 ]; then
                if [ "$firstModule" = true ]; then
                    echo "New commits since last subtree merge:"
                    echo ""
                    firstModule=false
                fi
                hasNewCommits=true
                echo -e "\033[1;36m=== $moduleName ===\033[0m"
                git log --graph --pretty=format:'%Cred%h%Creset -%C(yellow)%d%Creset %s %Cgreen(%cr) %C(bold blue)<%an>%Creset' --abbrev-commit "$lastMergeCommit..HEAD" -- "$moduleSubtreePath"
                echo ""
            fi
        else
            # No merge commit found, show all commits
            allCommitsCount=$(git log --oneline HEAD -- "$moduleSubtreePath" | wc -l)
            if [ "$allCommitsCount" -gt 0 ]; then
                if [ "$firstModule" = true ]; then
                    echo "New commits since last subtree merge:"
                    echo ""
                    firstModule=false
                fi
                hasNewCommits=true
                echo -e "\033[1;36m===$moduleName===\033[0m"
                git log --graph --pretty=format:'%Cred%h%Creset -%C(yellow)%d%Creset %s %Cgreen(%cr) %C(bold blue)<%an>%Creset' --abbrev-commit HEAD -- "$moduleSubtreePath"
                echo ""
            fi
        fi
    done

    if [ "$hasNewCommits" = false ]; then
        echo "No new commits in modules"
    else
        echo "To push changes upstream to a module, use: git module push <module_name>"
    fi
}

# Function to pull module updates
pullModules() {
    local moduleNames=("$@")

    # If no modules specified, get all modules
    if [ ${#moduleNames[@]} -eq 0 ]; then
        while IFS= read -r moduleName; do
            moduleNames+=("$moduleName")
        done < <(getAllModuleNamesFromConfig)
    fi

    for moduleName in "${moduleNames[@]}"; do
        local moduleUrl
        local moduleSubtreePath

        moduleUrl=$(getModuleUrlFromConfig "$moduleName")
        moduleSubtreePath="$MODULES_DIR/$moduleName"

        if [ -z "$moduleUrl" ]; then
            echo "Error: Module '$moduleName' not found in config"
            continue
        fi

        if [ ! -d "$moduleSubtreePath" ]; then
            echo "Error: Module directory '$moduleSubtreePath' not found"
            continue
        fi

        echo "Pulling updates for module '$moduleName'..."
        git subtree pull --prefix="$moduleSubtreePath" "$moduleUrl" main --squash
    done
}

# Function to push module changes
pushModules() {
    local moduleNames=("$@")

    # If no modules specified, get all modules
    if [ ${#moduleNames[@]} -eq 0 ]; then
        while IFS= read -r moduleName; do
            moduleNames+=("$moduleName")
        done < <(getAllModuleNamesFromConfig)
    fi

    for moduleName in "${moduleNames[@]}"; do
        local moduleUrl
        local moduleSubtreePath

        moduleUrl=$(getModuleUrlFromConfig "$moduleName")
        moduleSubtreePath="$MODULES_DIR/$moduleName"

        if [ -z "$moduleUrl" ]; then
            echo "Error: Module '$moduleName' not found in config"
            continue
        fi

        if [ ! -d "$moduleSubtreePath" ]; then
            echo "Error: Module directory '$moduleSubtreePath' not found"
            continue
        fi

        echo "Pushing changes for module '$moduleName'..."
        git subtree push --prefix="$moduleSubtreePath" "$moduleUrl" main
    done
}

# Function to remove modules
removeModules() {
    local moduleNames=("$@")

    if [ ${#moduleNames[@]} -eq 0 ]; then
        echo "Error: At least one module name is required"
        exit 1
    fi

    for moduleName in "${moduleNames[@]}"; do
        local moduleSubtreePath

        moduleSubtreePath="$MODULES_DIR/$moduleName"

        # Remove directory
        if [ -d "$moduleSubtreePath" ]; then
            rm -rf "$moduleSubtreePath"
            echo "Removed module directory '$moduleSubtreePath'"
        else
            echo "Warning: Module directory '$moduleSubtreePath' not found"
        fi

        # Remove from config file
        removeModuleFromConfigFile "$moduleName"
        echo "Removed module '$moduleName' from config"
    done

    # Check if this was the last module and clean up if so
    if [ -f "$MODULES_CONFIG_FILE" ]; then
        local remainingModulesCount
        remainingModulesCount=$(wc -l < "$MODULES_CONFIG_FILE" 2>/dev/null || echo "0")

        # If config file is empty or only contains blank lines
        if [ "$remainingModulesCount" -eq 0 ] || [ ! -s "$MODULES_CONFIG_FILE" ]; then
            echo "No modules remaining, cleaning up..."

            # Remove .modules file
            rm -f "$MODULES_CONFIG_FILE"
            echo "Removed .modules file"

            # Remove modules directory if it's empty
            if [ -d "$MODULES_DIR" ] && [ -z "$(ls -A "$MODULES_DIR" 2>/dev/null)" ]; then
                rmdir "$MODULES_DIR"
                echo "Removed empty modules directory"
            fi
        fi
    fi
}

# Main command dispatcher
case "$1" in
    add)
        shift
        addModule "$@"
        ;;
    status)
        shift
        showModuleStatus "$@"
        ;;
    pull)
        shift
        pullModules "$@"
        ;;
    push)
        shift
        pushModules "$@"
        ;;
    rm)
        shift
        removeModules "$@"
        ;;
    *)
        echo "Usage: git module <command> [args...]"
        echo "Commands:"
        echo "  add <module_url> [--name <n>]      Add a new module"
        echo "  status [module_name...]    Show module status"
        echo "  pull [module_name...]      Pull module updates"
        echo "  push [module_name...]      Push module changes"
        echo "  rm <module_name...>        Remove modules"
        exit 1
        ;;
esac