#!/usr/bin/env bash
#
# ------------------------------------------------------------------------------
# This script computes and collects all chunk headers of all bugs in the
# provided input.  The set of chunks is then written to the provided
# output file.
#
# Usage:
# compute-chunk-data.sh
#   [--bugs_file_path <path, e.g., ../../subjects/data/generated/bugs-in-quantum-computing-platforms.csv>]
#   [--output_file_path <path, e.g., ../data/generated/chunk-data.csv>]
#   [help]
#
# Requires:
# - ../../subjects/data/generated/repositories directory must exist which is created by the ../../subjects/scripts/get-repositories.sh script
# ------------------------------------------------------------------------------

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" > /dev/null 2>&1 && pwd)"
source "$SCRIPT_DIR/../../utils/scripts/utils.sh" || exit 1

# -------------------------------------------------------------------------- Env
# Check the projects' repositories have been cloned
[ -d "$PROJECTS_REPOSITORIES_DIR" ] || die "[ERROR] $PROJECTS_REPOSITORIES_DIR does not exist.  Did you run $SCRIPT_DIR/../../subjects/scripts/get-repositories.sh?"
# ------------------------------------------------------------------------- Args

USAGE="Usage: ${BASH_SOURCE[0]} [--bugs_file_path <path, e.g., ../../subjects/data/generated/bugs-in-quantum-computing-platforms.csv>] [--output_file_path <path, e.g., ../data/generated/fixed-code-data.csv> [help]"
if [ "$#" -ne "0" ] && [ "$#" -ne "1" ] && [ "$#" -ne "2" ] && [ "$#" -ne "4" ]; then
  die "$USAGE"
fi

BUGS_FILE_PATH="$BUGS_FILE_PATH"
OUTPUT_FILE_PATH="$SCRIPT_DIR/../data/generated/chunk-data.csv"

while [[ "$1" = --* ]]; do
  OPTION=$1; shift
  case $OPTION in
    (--bugs_file_path)
      BUGS_FILE_PATH=$1;
      shift;;
    (--output_file_path)
      OUTPUT_FILE_PATH=$1;
      shift;;
    (--help)
      echo "$USAGE"
      exit 0
    (*)
      die "$USAGE";;
  esac
done

# Check whether all arguments have been initialized
[ "$BUGS_FILE_PATH" != "" ]   || die "[ERROR] Missing --bugs_file_path argument!"
[ "$OUTPUT_FILE_PATH" != "" ] || die "[ERROR] Missing --output_file_path argument!"
# Check whether all arguments exist
[ -s "$BUGS_FILE_PATH" ]      || die "[ERROR] $BUGS_FILE_PATH does not exist or it is empty!"
# Remove the output_file_path (if any) and create a new one
rm -f "$OUTPUT_FILE_PATH"
echo "project_full_name;fix_commit_hash;buggy_commit_hash;bug_id;bug_type;fixed_file_path;chunk_header" > "$OUTPUT_FILE_PATH"

# ------------------------------------------------------------------------- Main

while read -r item; do
  project_full_name=$(echo "$item" | cut -f1 -d',' | tr -d '"')
    fix_commit_hash=$(echo "$item" | cut -f3 -d',' | tr -d '"')
  buggy_commit_hash="${fix_commit_hash}^1"
             bug_id=$(echo "$item" | cut -f4 -d',' | tr -d '"')
           bug_type=$(echo "$item" | cut -f5 -d',' | tr -d '"')

  echo "[DEBUG] $project_full_name :: $bug_id :: $fix_commit_hash :: $buggy_commit_hash "

  while read -r file_path; do
    file_path=$(echo "$file_path")
    echo "[DEBUG] $file_path"
    while read -r chunk_header; do
      chunk_header=$(echo "$chunk_header")
      echo "[DEBUG] $chunk_header"
      echo "$project_full_name;$fix_commit_hash;$buggy_commit_hash;$bug_id;$bug_type;$file_path;$chunk_header" >> "$OUTPUT_FILE_PATH" || die "[ERROR] Failed to append data to the $OUTPUT_FILE_PATH file!"
    done < <(git --git-dir="$PROJECTS_REPOSITORIES_DIR/$project_full_name" diff "$buggy_commit_hash" "$fix_commit_hash" -- "$file_path" | grep '^\@\@')
  done < <(git --git-dir="$PROJECTS_REPOSITORIES_DIR/$project_full_name" diff "$buggy_commit_hash" "$fix_commit_hash" --name-only)
done < <(tail -n +2 "$BUGS_FILE_PATH")

echo "DONE!"
exit 0

# EOF