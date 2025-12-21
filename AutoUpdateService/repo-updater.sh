#!/bin/bash

# exit the script on any error
set -euo pipefail

REPO_URL="git@github.com:JoseBritto/DeploymentScripts.git"
BRANCH="master"
REPO_DIR="./sample/repo"
COMMIT_FILE="./sample/commit"
ON_CHANGE_SCRIPT="./sample/script.sh"
ON_CHANGE_SCRIPT_WORKDIR="./sample"

if [[ -z "$REPO_URL" ]]; then
  echo "Error: ssh repo url is required."
  exit 1
fi

if [[ ! -d "$REPO_DIR/.git" ]]; then
  echo "Cloning via SSH: $REPO_URL -> $REPO_DIR"
  rm -rf "$REPO_DIR"
  git clone --branch "$BRANCH" "$REPO_URL" "$REPO_DIR"
else
  echo "Pulling latest on $BRANCH in $REPO_DIR"
  git -C "$REPO_DIR" remote set-url origin "$REPO_URL" >/dev/null 2>&1 || true
  git -C "$REPO_DIR" checkout -q "$BRANCH" 2>/dev/null || git -C "$REPO_DIR" checkout -q -B "$BRANCH"
  # Pull latest from origin/BRANCH and overwrite any local changes
  git -C "$REPO_DIR" reset  --hard "origin/$BRANCH"
fi

NEW_COMMIT="$(git -C "$REPO_DIR" rev-parse HEAD)"
OLD_COMMIT=""
if [[ -f "$COMMIT_FILE" ]]; then
  OLD_COMMIT="$(cat "$COMMIT_FILE" 2>/dev/null || true)"
fi

echo "Current:  $NEW_COMMIT"
echo "Previous: ${OLD_COMMIT:-<none>}"


if [[ "$NEW_COMMIT" != "$OLD_COMMIT" ]]; then
  mkdir -p "$(dirname "$COMMIT_FILE")" 2>/dev/null || true
  echo "$NEW_COMMIT" > "$COMMIT_FILE"
  echo "Change detected. Running: $ON_CHANGE_SCRIPT"

  if [[ ! -x "$ON_CHANGE_SCRIPT" ]]; then
    echo "Error: on-change script not found or not executable: $ON_CHANGE_SCRIPT"
    echo "Fix if it already exists: chmod +x \"$ON_CHANGE_SCRIPT\""
    exit 2
  fi

  TARGET_SCRIPT_PATH="$(realpath -m "$ON_CHANGE_SCRIPT")"
  ( cd "$ON_CHANGE_SCRIPT_WORKDIR" && "$TARGET_SCRIPT_PATH")
else
  echo "No change detected. Nothing to do."
fi