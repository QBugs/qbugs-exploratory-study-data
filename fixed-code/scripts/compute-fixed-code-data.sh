#!/usr/bin/env bash
#
# ------------------------------------------------------------------------------
# This script computes and collects all fixed components of all bugs in the
# provided input.  The set of fixed components is then written to the provided
# output file.
#
# Usage:
# compute-fixed-code-data.sh
#   [--bugs_file_path <path, e.g., ../../subjects/data/generated/bugs-in-quantum-computing-platforms.csv>]
#   [--output_file_path <path, e.g., ../data/generated/fixed-code-data.csv>]
#   [help]
#
# Requires:
# - ../../subjects/data/generated/repositories directory must exist which is created by the ../../subjects/scripts/get-repositories.sh script
# ------------------------------------------------------------------------------

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" > /dev/null 2>&1 && pwd)"
source "$SCRIPT_DIR/../../utils/scripts/utils.sh" || exit 1

# -------------------------------------------------------------------------- Env

# Check whether JAVA_HOME exist
JAVA_HOME="$SCRIPT_DIR/../../tools/jdk-11"
[ -d "$JAVA_HOME" ] || die "$JAVA_HOME does not exist! Did you successfully run the $SCRIPT_DIR/../../tools/get-tools.sh script?"
# Set classpath
export PATH="$JAVA_HOME/bin:$PATH"
# Sanity check whether `java` is indeed available
java -version > /dev/null 2>&1 || die "[ERROR] Failed to find the java executable."

# Check whether code-components-analysis jar exist
CODE_COMPONENTS_ANALYSIS_JAR_FILE="$SCRIPT_DIR/../../tools/code-components-analysis.jar"
[ -s "$CODE_COMPONENTS_ANALYSIS_JAR_FILE" ] || die "$CODE_COMPONENTS_ANALYSIS_JAR_FILE does not exist! Did you succesfully run the $SCRIPT_DIR/../../tools/get-tools.sh script?"

# Check the projects' repositories have been cloned
[ -d "$PROJECTS_REPOSITORIES_DIR" ] || die "[ERROR] $PROJECTS_REPOSITORIES_DIR does not exist.  Did you run $SCRIPT_DIR/../../subjects/scripts/get-repositories.sh?"

# Check whether Python's env exist
PYTHON_ENV_DIR="$SCRIPT_DIR/../../tools/env"
[ -d "$PYTHON_ENV_DIR" ] || die "[ERROR] $PYTHON_ENV_DIR does not exit!  Did you run $SCRIPT_DIR/../../tools/get-tools.sh?"

# Add pythonparser to the PATH
export PATH="$SCRIPT_DIR/../../tools/pythonparser:$PATH"

# ------------------------------------------------------------------------- Args

USAGE="Usage: ${BASH_SOURCE[0]} [--bugs_file_path <path, e.g., ../../subjects/data/generated/bugs-in-quantum-computing-platforms.csv>] [--output_file_path <path, e.g., ../data/generated/fixed-code-data.csv> [help]"
if [ "$#" -ne "0" ] && [ "$#" -ne "1" ] && [ "$#" -ne "2" ] && [ "$#" -ne "4" ]; then
  die "$USAGE"
fi

BUGS_FILE_PATH="$BUGS_FILE_PATH"
OUTPUT_FILE_PATH="$SCRIPT_DIR/../data/generated/fixed-code-data.csv"

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
echo "project_full_name,fix_commit_hash,buggy_commit_hash,bug_id,bug_type,fixed_file_path,fixed_line_number,fixed_component" > "$OUTPUT_FILE_PATH"

# ------------------------------------------------------------------------- Main

EMPTY_FILE="/dev/null"

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

  while read -r row; do
    echo "[DEBUG] Git: $row"

    status=$(echo "$row" | cut -f1 -d$'\t')
    if [ "$status" == "D" ]; then
      # Deleted files in the fixed version have no fixed buggy component, as
      # the file no longer exist
      continue
    fi

    num_cols=$(echo "$row" | tr '\t' '\n' | wc -l)
    if [ "$num_cols" -eq "2" ]; then
      # For example, Added (A), Modified (M), have their type (i.e. regular file,
      # symlink, submodule, ...​) changed (T), are Unmerged (U), are Unknown (X),
      # or have had their pairing Broken (B)
      if [ "$status" == "A" ]; then
        # An added file in the fixed version has no correspondent version in the
        # buggy version
        buggy_file_path="$EMPTY_FILE"
        fixed_file_path=$(echo "$row" | cut -f2 -d$'\t')
      else
        # Otherwise, the buggy and fixed file are still in the same path
        buggy_file_path=$(echo "$row" | cut -f2 -d$'\t')
        fixed_file_path="$buggy_file_path"
      fi
    elif [ "$num_cols" -eq "3" ]; then
      # For example, Copied (C) and Renamed (R)
      buggy_file_path=$(echo "$row" | cut -f2 -d$'\t')
      fixed_file_path=$(echo "$row" | cut -f3 -d$'\t')
    else
      die "[ERROR] Unknown/Unsupported number of rows!"
    fi

    [ "$buggy_file_path" != "" ] || die "[ERROR] Path to the buggy file cannot be empty! $project_full_name :: $bug_id :: $fix_commit_hash"
    [ "$fixed_file_path" != "" ] || die "[ERROR] Path to the fixed file cannot be empty! $project_full_name :: $bug_id :: $fix_commit_hash"

    # Ignore non-python files
    if [ "$buggy_file_path" != "$EMPTY_FILE" ] && ! echo "$buggy_file_path" | grep -q ".py$"; then
      echo "[DEBUG] Buggy $buggy_file_path filed in $buggy_commit_hash..$fix_commit_hash ($project_full_name::$bug_id) ignored as it is not a python file"
      continue
    fi
    if ! echo "$fixed_file_path" | grep -q ".py$"; then
      echo "[DEBUG] Fixed $fixed_file_path filed in $buggy_commit_hash..$fix_commit_hash ($project_full_name::$bug_id) ignored as it is not a python file"
      continue
    fi

    if echo "$buggy_file_path" | grep -q --ignore-case "test" || echo "$fixed_file_path" | grep -q --ignore-case "test"; then
      # Ignore 'test' files
      echo "[DEBUG] Buggy file $buggy_file_path and fixed $fixed_file_path file in $buggy_commit_hash..$fix_commit_hash ($project_full_name::$bug_id) ignored as they might be related to tests"
      continue
    fi

    echo "[DEBUG] Buggy file $buggy_file_path and fixed $fixed_file_path file in $buggy_commit_hash..$fix_commit_hash ($project_full_name::$bug_id)"

    tmp_buggy_file="$work_dir/buggy.py"
    tmp_fixed_file="$work_dir/fixed.py"
    tmp_fixed_components_file="$work_dir/fixed-code-components.csv"
    rm -f "$tmp_buggy_file" "$tmp_fixed_file" "$tmp_fixed_components_file"

    # Get buggy file's content
    if [ "$buggy_file_path" != "$EMPTY_FILE" ]; then
      git --git-dir="$PROJECTS_REPOSITORIES_DIR/$project_full_name" show "$buggy_commit_hash:$buggy_file_path" > "$tmp_buggy_file" || die "[ERROR] Failed to collect $buggy_file_path from the buggy commit $buggy_commit_hash!"
      [ -s "$tmp_buggy_file" ] || die "[ERROR] $tmp_buggy_file does not exist or it is empty!"
    fi

    # Get fixed file's content
    git --git-dir="$PROJECTS_REPOSITORIES_DIR/$project_full_name" show "$fix_commit_hash:$fixed_file_path" > "$tmp_fixed_file" || die "[ERROR] Failed to collect $fixed_file_path from the fixed commit $fix_commit_hash!"
    [ -s "$tmp_fixed_file" ] || die "[ERROR] $tmp_fixed_file does not exist or it is empty!"

    # Process buggy and fixed code and collect fixed components
    java -jar "$CODE_COMPONENTS_ANALYSIS_JAR_FILE" \
      listFixedCodeComponents \
      --buggyFile "$tmp_buggy_file" \
      --fixedFile "$tmp_fixed_file" \
      --outputFile "$tmp_fixed_components_file" || die "[ERROR] Failed to run code-components-analysis!"
    [ -s "$tmp_fixed_components_file" ] || die "[ERROR] $tmp_fixed_components_file does not exist or it is empty!"

    # Write the fixed data computed to the output file
    while read -r fixed_components_per_fixed_line; do
      fixed_line_number=$(echo "$fixed_components_per_fixed_line" | cut -f1 -d',')
      fixed_component=$(echo "$fixed_components_per_fixed_line" | cut -f2 -d',')
      echo "$project_full_name,$fix_commit_hash,$buggy_commit_hash,$bug_id,$bug_type,$fixed_file_path,$fixed_line_number,$fixed_component" >> "$OUTPUT_FILE_PATH" || die "[ERROR] Failed to append data to the $OUTPUT_FILE_PATH file!"
    done < <(tail -n +2 "$tmp_fixed_components_file" | cut -f2,3 -d',' | sort -u)

  done < <(git --git-dir="$PROJECTS_REPOSITORIES_DIR/$project_full_name" diff --no-ext-diff --binary --name-status "$buggy_commit_hash" "$fix_commit_hash")
done < <(tail -n +2 "$BUGS_FILE_PATH")

# Deactivate virtual environment
deactivate || die "[ERROR] Failed to deactivate virtual environment!"

echo "DONE!"
exit 0

# EOF
