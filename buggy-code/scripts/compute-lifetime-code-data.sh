#!/usr/bin/env bash
#
# ------------------------------------------------------------------------------
# This script computes the lifetime of all lines of code of all .py files of all
# bugs.  For each line X, the script reports the set of commits and authors that
# have modified that line, the UNIX timestamp when the line has been modified,
# and whether the modification is considered a bug-fix.
#
# Usage:
# compute-lifetime-code-data.sh
#   [--bugs_file_path <path, e.g., ../../subjects/data/generated/bugs-in-quantum-computing-platforms.csv>]
#   [--output_file_path <path, e.g., ../data/generated/code-lifetime-data.csv>]
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

USAGE="Usage: ${BASH_SOURCE[0]} [--bugs_file_path <path, e.g., ../../subjects/data/generated/bugs-in-quantum-computing-platforms.csv>] [--output_file_path <path, e.g., ../data/generated/code-lifetime-data.csv>] [help]"
if [ "$#" -ne "0" ] && [ "$#" -ne "1" ] && [ "$#" -ne "2" ] && [ "$#" -ne "4" ]; then
  die "$USAGE"
fi

BUGS_FILE_PATH="$SCRIPT_DIR/../../subjects/data/generated/bugs-in-quantum-computing-platforms.csv"
OUTPUT_FILE_PATH="$SCRIPT_DIR/../data/generated/code-lifetime-data.csv"

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
rm -f "$OUTPUT_FILE_PATH"; touch "$OUTPUT_FILE_PATH" || die "[ERROR] Failed to create $OUTPUT_FILE_PATH!"

# ------------------------------------------------------------------------- Main

jobs_dir_path="$SCRIPT_DIR/../data/generated/code-lifetime-data"
rm -rf "$jobs_dir_path"; mkdir -p "$jobs_dir_path"

jobs_file_path="$jobs_dir_path/jobs.txt"
rm -f "$jobs_file_path"

while read -r bug_id; do
  echo "timeout --signal=SIGTERM 1440m bash $SCRIPT_DIR/compute-lifetime-code-data-on-a-bug.sh --bug_id \"$bug_id\" --output_file_path \"$jobs_dir_path/$bug_id.csv\" > \"$jobs_dir_path/$bug_id.log\" 2>&1" >> "$jobs_file_path"
done < <(tail -n +2 "$BUGS_FILE_PATH" | shuf | cut -f4 -d',' | tr -d '"')

# Compute lifetime of code per bug and in parallel
parallel --progress -j $(cat /proc/cpuinfo | grep 'cpu cores' | sort -u | cut -f2 -d':' | cut -f2 -d' ') -a "$jobs_file_path"

# Aggregate data in a single CSV file
# 1. Get header
find "$jobs_dir_path" -type f -name "*.csv" | head -n1 | xargs head -n1 > "$OUTPUT_FILE_PATH"
# 2. Get data
while read -r bug_id; do
  # Sanity check log file
  [ -s "$jobs_dir_path/$bug_id.log" ] || die "[ERROR] $jobs_dir_path/$bug_id.log does not exist or it is empty!"
  grep -q "^DONE\!$" "$jobs_dir_path/$bug_id.log" || die "[ERROR] Failed to run compute-lifetime-code-data-on-a-bug.sh on $bug_id!"
  # Sanity check CSV file
  [ -s "$jobs_dir_path/$bug_id.csv" ] || die "[ERROR] $jobs_dir_path/$bug_id.csv does not exist or it is empty!"
  num_rows=$(wc -l "$jobs_dir_path/$bug_id.csv" | cut -f1 -d' ')
  [ "$num_rows" -ge "2" ] || die "[ERROR] $jobs_dir_path/$bug_id.csv only has $num_rows rows when at least two are expected!"
  # Aggregate data
  tail -n +2 "$jobs_dir_path/$bug_id.csv" >> "$OUTPUT_FILE_PATH"
done < <(tail -n +2 "$BUGS_FILE_PATH" | shuf | cut -f4 -d',' | tr -d '"')

echo "DONE!"
exit 0

# EOF
