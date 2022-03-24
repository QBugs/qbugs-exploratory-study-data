#!/usr/bin/env bash
#
# ------------------------------------------------------------------------------
# This script makes a bare clone of each quantum project's git repository which
# might speedup, e.g., the analysis of the buggy/fixed code.
#
# Usage:
# get-repositories.sh
#   [--bugs_file_path <path, e.g., ../data/generated/bugs-in-quantum-computing-platforms.csv>]
#   [--output_dir_path <path, e.g., ../data/generated/repositories>]
#   [help]
# ------------------------------------------------------------------------------

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" > /dev/null 2>&1 && pwd)"
source "$SCRIPT_DIR/../../utils/scripts/utils.sh" || exit 1

# ------------------------------------------------------------------------- Args

USAGE="Usage: ${BASH_SOURCE[0]} [--bugs_file_path <path, e.g., ../data/generated/bugs-in-quantum-computing-platforms.csv>] [--output_dir_path <path, e.g., ../data/generated/repositories>] [help]"
if [ "$#" -ne "0" ] && [ "$#" -ne "1" ] && [ "$#" -ne "2" ] && [ "$#" -ne "4" ]; then
  die "$USAGE"
fi

BUGS_FILE_PATH="$BUGS_FILE_PATH"
OUTPUT_DIR_PATH="$PROJECTS_REPOSITORIES_DIR"

while [[ "$1" = --* ]]; do
  OPTION=$1; shift
  case $OPTION in
    (--bugs_file_path)
      BUGS_FILE_PATH=$1;
      shift;;
    (--output_dir_path)
      OUTPUT_DIR_PATH=$1;
      shift;;
    (--help)
      echo "$USAGE"
      exit 0
    (*)
      die "$USAGE";;
  esac
done

# Check whether all arguments have been initialized
[ "$BUGS_FILE_PATH" != "" ]  || die "[ERROR] Missing --bugs_file_path argument!"
[ "$OUTPUT_DIR_PATH" != "" ] || die "[ERROR] Missing --output_dir_path argument!"
# Check whether all arguments exist
[ -s "$BUGS_FILE_PATH" ]     || die "[ERROR] $BUGS_FILE_PATH does not exist or it is empty!"
# Remove the output_dir_path (if any)
rm -rf "$OUTPUT_DIR_PATH"

# ------------------------------------------------------------------------- Main

# Clone all project's repositories into local bare repositories
while read -r item; do
  project_full_name=$(echo "$item" | cut -f1 -d',' | tr -d '"')
  project_clone_url=$(echo "$item" | cut -f2 -d',' | tr -d '"')
  # Create directory for the repository
  work_dir="$OUTPUT_DIR_PATH/$project_full_name"
  mkdir -p "$work_dir" || die "[ERROR] Failed to create $work_dir for $project_full_name!"
  # Clone it
  git clone --bare "$project_clone_url" "$work_dir" || die "[ERROR] Failed to clone $project_clone_url to $work_dir!"
  # Runtime check
  [ -d "$work_dir" ] || die "[ERROR] $work_dir does not exist!"
done < <(tail -n +2 "$BUGS_FILE_PATH" | cut -f1,2 -d',' | sort -u)

echo "DONE!"
exit 0

# EOF
