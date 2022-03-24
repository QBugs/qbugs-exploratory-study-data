#!/usr/bin/env bash
#
# ------------------------------------------------------------------------------
# This script computes and collects all buggy components of all bugs in the
# provided input.  The set of buggy components is then written to the provided
# output file.
#
# Usage:
# compute-buggy-code-data.sh
#   [--bugs_file_path <path, e.g., ../../subjects/data/generated/bugs-in-quantum-computing-platforms.csv>]
#   [--output_file_path <path, e.g., ../data/generated/buggy-code-data.csv>]
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

PYTHON_ENV_DIR="$SCRIPT_DIR/../../tools/env"
[ -d "$PYTHON_ENV_DIR" ] || die "[ERROR] $PYTHON_ENV_DIR does not exit!  Did you run $SCRIPT_DIR/../../tools/get-tools.sh?"

# ------------------------------------------------------------------------- Args

USAGE="Usage: ${BASH_SOURCE[0]} [--bugs_file_path <path, e.g., ../../subjects/data/generated/bugs-in-quantum-computing-platforms.csv>] [--output_file_path <path, e.g., ../data/generated/buggy-code-data.csv> [help]"
if [ "$#" -ne "0" ] && [ "$#" -ne "1" ] && [ "$#" -ne "2" ] && [ "$#" -ne "4" ]; then
  die "$USAGE"
fi

BUGS_FILE_PATH="$BUGS_FILE_PATH"
OUTPUT_FILE_PATH="$SCRIPT_DIR/../data/generated/buggy-code-data.csv"

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
[ -s "$BUGS_FILE_PATH" ]     || die "[ERROR] $BUGS_FILE_PATH does not exist or it is empty!"
# Remove the output_file_path (if any) and create a new one
rm -f "$OUTPUT_FILE_PATH"
echo "project_full_name,buggy_commit_hash,bug_id,bug_type,buggy_file_path,buggy_line_number,buggy_component" > "$OUTPUT_FILE_PATH"

# ------------------------------------------------------------------------- Main

# Activate python virtual environment
source "$SCRIPT_DIR/../../tools/env/bin/activate" || die "[ERROR] Failed to activate virtual environment!"

TMP_DIR="/tmp/$USER-$$-$(echo $RANDOM | md5sum | cut -f1 -d' ')"
rm -rf "$TMP_DIR"; mkdir "$TMP_DIR"

while read -r item; do
  project_full_name=$(echo "$item" | cut -f1 -d',' | tr -d '"')
    fix_commit_hash=$(echo "$item" | cut -f3 -d',' | tr -d '"')
  buggy_commit_hash="${fix_commit_hash}^1"
             bug_id=$(echo "$item" | cut -f4 -d',' | tr -d '"')
           bug_type=$(echo "$item" | cut -f5 -d',' | tr -d '"')

  work_dir="$TMP_DIR/$project_full_name-$bug_id"
  rm -rf "$work_dir"; mkdir -p "$work_dir"

  # Get list of buggy .py files and process each one
  while read -r buggy_file_path; do
    echo "[DEBUG] $buggy_file_path in $buggy_commit_hash..$fix_commit_hash"

    tmp_buggy_file="$work_dir/$buggy_file_path"
    tmp_buggy_line_numbers_file="$tmp_buggy_file.buggy-line-numbers"
    tmp_buggy_components_file="$tmp_buggy_file.buggy-components-per-line-number"
    rm -f "$tmp_buggy_file" "$tmp_buggy_line_numbers_file" "$tmp_buggy_components_file"

    # Get buggy file's content
    mkdir -p $(echo "$tmp_buggy_file" | rev | cut -f2- -d'/' | rev)
    git --git-dir="$PROJECTS_REPOSITORIES_DIR/$project_full_name" show "$buggy_commit_hash:$buggy_file_path" > "$tmp_buggy_file"

    # Get lines' numbers that were buggy
    while read -r row; do
      # Is it a range of lines?
      if echo "$row" | grep -q ","; then
        start_line=$(echo "$row" | cut -f1 -d',')
         num_lines=$(echo "$row" | cut -f2 -d',')
          end_line=$(echo "$start_line + $num_lines - 1" | bc)
        seq "$start_line" "$end_line" >> "$tmp_buggy_line_numbers_file"
      else
        echo "$row" >> "$tmp_buggy_line_numbers_file"
      fi
    done < <(git --git-dir="$PROJECTS_REPOSITORIES_DIR/$project_full_name" diff --no-ext-diff --binary --unified=0 "$fix_commit_hash" "$buggy_commit_hash" -- "$buggy_file_path" | grep -Po '^\+\+\+ ./\K.*|^@@ -[0-9]+(,[0-9]+)? \+\K[0-9]+(,[0-9]+)?(?= @@)' | tail -n +2)

    # Process buggy file and collect buggy components per buggy line of code
    python "$SCRIPT_DIR/compute-buggy-elements.py" \
      --buggy-file-path "$tmp_buggy_file" \
      --buggy-lines-file-path "$tmp_buggy_line_numbers_file" \
      --output-file "$tmp_buggy_components_file" || die "[ERROR] Failed to execute compute-buggy-elements.py!"
    [ -s "$tmp_buggy_components_file" ] || die "[ERROR] $tmp_buggy_components_file does not exist or it is empty!"

    # Write to the output file the buggy data computed
    while read -r buggy_components_per_buggy_line; do
      buggy_line_number=$(echo "$buggy_components_per_buggy_line" | cut -f1 -d',')
      buggy_component=$(echo "$buggy_components_per_buggy_line" | cut -f2 -d',')
      echo "$project_full_name,$buggy_commit_hash,$bug_id,$bug_type,$buggy_file_path,$buggy_line_number,$buggy_component" >> "$OUTPUT_FILE_PATH" || die "[ERROR] Failed to append data to the $OUTPUT_FILE_PATH file!"
    done < <(tail -n +2 "$tmp_buggy_components_file")
  done < <(git --git-dir="$PROJECTS_REPOSITORIES_DIR/$project_full_name" diff --no-ext-diff --binary --name-only "$buggy_commit_hash" "$fix_commit_hash" | grep ".py$")
done < <(tail -n +2 "$BUGS_FILE_PATH")

# Deactivate virtual environment
deactivate || die "[ERROR] Failed to deactivate virtual environment!"

# Compress output file
gzip -v "$OUTPUT_FILE_PATH" || die "[ERROR] Failed to compress the output file ($OUTPUT_FILE_PATH) into $OUTPUT_FILE_PATH.gz!"

echo "DONE!"
exit 0

# EOF
