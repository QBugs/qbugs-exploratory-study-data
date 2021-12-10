#!/usr/bin/env bash

UTILS_SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" > /dev/null 2>&1 && pwd)"
USER_HOME_DIR="$(cd ~ && pwd)"

export LC_ALL=en_US.UTF-8
export LANG=en_US.UTF-8
export LANGUAGE=en_US.UTF-8

#
# Print error message to the stdout and exit.
#
die() {
  echo "$@" >&2
  exit 1
}

# EOF
