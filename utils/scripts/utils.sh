#!/usr/bin/env bash

UTILS_SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" > /dev/null 2>&1 && pwd)"
USER_HOME_DIR="$(cd ~ && pwd)"

export LC_ALL=en_US.UTF-8
export LANG=en_US.UTF-8
export LANGUAGE=en_US.UTF-8

PROJECTS_REPOSITORIES_DIR="$UTILS_SCRIPT_DIR/../../subjects/data/generated/repositories"

#
# Print error message to the stdout and exit.
#
die() {
  echo "$@" >&2
  exit 1
}

# EOF
