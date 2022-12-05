#!/usr/bin/env bash
#
# ------------------------------------------------------------------------------
# This script computes and collects the path of all files that were buggy before
# the bug fix was performed.  In other words, it collects the files that were
# copied, deleted, modified, renamed, or had their type (i.e. regular file,
# symlink, submodule, ...​) changed in the bug fix commit.  The list of files is
# then written to the provided output file.
#
# Usage:
# compute-buggy-files.sh
#   [--bugs_file_path <path, e.g., ../../subjects/data/generated/bugs-in-quantum-computing-platforms.csv>]
#   [--output_file_path <path, e.g., ../data/generated/buggy-files-data.csv>]
#   [help]
#
# Requires:
# - ../../subjects/data/generated/repositories directory must exist which is
#   created by the ../../subjects/scripts/get-repositories.sh script
# ------------------------------------------------------------------------------

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" > /dev/null 2>&1 && pwd)"
source "$SCRIPT_DIR/../../utils/scripts/utils.sh" || exit 1

# -------------------------------------------------------------------------- Env

# Check the projects' repositories have been cloned
[ -d "$PROJECTS_REPOSITORIES_DIR" ] || die "[ERROR] $PROJECTS_REPOSITORIES_DIR does not exist.  Did you run $SCRIPT_DIR/../../subjects/scripts/get-repositories.sh?"

# ------------------------------------------------------------------------- Args

USAGE="Usage: ${BASH_SOURCE[0]} [--bugs_file_path <path, e.g., ../../subjects/data/generated/bugs-in-quantum-computing-platforms.csv>] [--output_file_path <path, e.g., ../data/generated/buggy-files-data.csv> [help]"
if [ "$#" -ne "0" ] && [ "$#" -ne "1" ] && [ "$#" -ne "2" ] && [ "$#" -ne "4" ]; then
  die "$USAGE"
fi

BUGS_FILE_PATH="$BUGS_FILE_PATH"
OUTPUT_FILE_PATH="$SCRIPT_DIR/../data/generated/buggy-files-data.csv"

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
echo "project_full_name,fix_commit_hash,buggy_commit_hash,bug_id,bug_type,buggy_file_path,action" > "$OUTPUT_FILE_PATH"

# ------------------------------------------------------------------------- Main

while read -r item; do
  project_full_name=$(echo "$item" | cut -f1 -d',' | tr -d '"')
    fix_commit_hash=$(echo "$item" | cut -f3 -d',' | tr -d '"')
  buggy_commit_hash="${fix_commit_hash}^1"
             bug_id=$(echo "$item" | cut -f4 -d',' | tr -d '"')
           bug_type=$(echo "$item" | cut -f5 -d',' | tr -d '"')

  echo "[DEBUG] $project_full_name :: $bug_id :: $fix_commit_hash"

  while read -r entry; do
    if echo "$entry" | grep -q --ignore-case "test"; then
      continue
    fi

    action=$(echo "$entry" | cut -f1 -d':')
    buggy_file_path=$(echo "$entry" | cut -f2 -d':')

    echo "$project_full_name,$fix_commit_hash,$buggy_commit_hash,$bug_id,$bug_type,$buggy_file_path,$action" >> "$OUTPUT_FILE_PATH" || die "[ERROR] Failed to append data to the $OUTPUT_FILE_PATH file!"
  done < <(git --git-dir="$PROJECTS_REPOSITORIES_DIR/$project_full_name" diff --name-status --diff-filter=CDMRT "$buggy_commit_hash" "$fix_commit_hash" | tr '\t' ':')
done < <(tail -n +2 "$BUGS_FILE_PATH")

echo "DONE!"
exit 0

# EOF
