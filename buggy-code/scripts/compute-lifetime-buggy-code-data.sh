#!/usr/bin/env bash
#
# ------------------------------------------------------------------------------
# This script computes the lifetime of all buggy components of all bugs.  For
# each buggy component in line of code X, the script reports the set of commits
# and authors that have modified that line, and the UNIX timestamp when the
# line has been modified.
#
# Usage:
# compute-lifetime-buggy-code-data.sh.sh
#   [--buggy_code_data_path <path, e.g., ../data/generated/buggy-code-data.csv>]
#   [--output_file_path <path, e.g., ../data/generated/buggy-code-lifetime-data.csv>]
#   [help]
#
# Requires:
# - ../../subjects/data/generated/repositories directory must exist which is created by the ../../subjects/scripts/get-repositories.sh script
# - ../data/generated/buggy-code-data.csv must exist which is created by the compute-buggy-code-data.sh script
# ------------------------------------------------------------------------------

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" > /dev/null 2>&1 && pwd)"
source "$SCRIPT_DIR/../../utils/scripts/utils.sh" || exit 1

# -------------------------------------------------------------------------- Env

# Check the projects' repositories have been cloned
[ -d "$PROJECTS_REPOSITORIES_DIR" ] || die "[ERROR] $PROJECTS_REPOSITORIES_DIR does not exist.  Did you run $SCRIPT_DIR/../../subjects/scripts/get-repositories.sh?"

# ------------------------------------------------------------------------- Args

USAGE="Usage: ${BASH_SOURCE[0]} [--buggy_code_data_path <path, e.g., ../data/generated/buggy-code-data.csv>] [--output_file_path <path, e.g., ../data/generated/buggy-code-lifetime-data.csv>] [help]"
if [ "$#" -ne "0" ] && [ "$#" -ne "1" ] && [ "$#" -ne "2" ] && [ "$#" -ne "4" ]; then
  die "$USAGE"
fi

BUGGY_CODE_DATA_PATH="$SCRIPT_DIR/../data/generated/buggy-code-data.csv"
OUTPUT_FILE_PATH="$SCRIPT_DIR/../data/generated/buggy-code-lifetime-data.csv"

while [[ "$1" = --* ]]; do
  OPTION=$1; shift
  case $OPTION in
    (--buggy_code_data_path)
      BUGGY_CODE_DATA_PATH=$1;
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
[ "$BUGGY_CODE_DATA_PATH" != "" ]  || die "[ERROR] Missing --buggy_code_data_path argument!"
[ "$OUTPUT_FILE_PATH" != "" ]      || die "[ERROR] Missing --output_file_path argument!"
# Check whether all arguments exist
[ -s "$BUGGY_CODE_DATA_PATH" ]     || die "[ERROR] $BUGS_FILE_PATH does not exist or it is empty!"
# Remove the output_file_path (if any) and create a new one
rm -f "$OUTPUT_FILE_PATH"
echo "project_full_name,fix_commit_hash,bug_id,bug_type,buggy_file_path,buggy_line_number,buggy_component,commit_hash,author_name,author_commit_date" > "$OUTPUT_FILE_PATH"

# ------------------------------------------------------------------------- Main

while read -r item; do
  project_full_name=$(echo "$item" | cut -f1 -d',' | tr -d '"')
    fix_commit_hash=$(echo "$item" | cut -f2 -d',' | tr -d '"')
             bug_id=$(echo "$item" | cut -f4 -d',' | tr -d '"')
           bug_type=$(echo "$item" | cut -f5 -d',' | tr -d '"')
    buggy_file_path=$(echo "$item" | cut -f6 -d',' | tr -d '"')
  buggy_line_number=$(echo "$item" | cut -f7 -d',' | tr -d '"')
    buggy_component=$(echo "$item" | cut -f8 -d',' | tr -d '"')

  while read -r row; do
           commit_hash=$(echo "$row" | cut -f1 -d',') # full commit hash
           author_name=$(echo "$row" | cut -f2 -d',') # author name
    author_commit_date=$(echo "$row" | cut -f3 -d',') # UNIX timestamp

    echo "$project_full_name,$fix_commit_hash,$bug_id,$bug_type,$buggy_file_path,$buggy_line_number,$buggy_component,$commit_hash,$author_name,$author_commit_date" >> "$OUTPUT_FILE_PATH"

  done < <(git --git-dir="$PROJECTS_REPOSITORIES_DIR/$project_full_name" log -L"$buggy_line_number,$buggy_line_number":"$buggy_file_path" "$fix_commit_hash" --pretty=format:"%H,%an,%at" --no-patch)

done < <(tail -n +2 "$BUGGY_CODE_DATA_PATH")

echo "DONE!"
exit 0

# EOF
