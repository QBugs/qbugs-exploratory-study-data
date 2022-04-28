#!/usr/bin/env bash
#
# ------------------------------------------------------------------------------
# This script computes the lifetime of all lines of code of all .py files of the
# defined bug.  For each line X, the script reports the set of commits and
# authors that have modified that line, the UNIX timestamp when the line has
# been modified, and whether the modification is considered a bug-fix.
#
# Usage:
# compute-lifetime-code-data-on-a-bug.sh
#   --bug_id <bug id, e.g., 1, or 1909-5>
#   --output_file_path <path, e.g., ../data/generated/code-lifetime-data/1.csv>
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

# Check whether bugs data set exist
BUGS_FILE_PATH="$SCRIPT_DIR/../../subjects/data/generated/bugs-in-quantum-computing-platforms.csv"
[ -s "$BUGS_FILE_PATH" ] || die "[ERROR] $BUGS_FILE_PATH does not exist or it is empty!"

# ------------------------------------------------------------------------- Args

USAGE="Usage: ${BASH_SOURCE[0]} --bug_id <bug id, e.g., 1, or 1909-5> --output_file_path <path, e.g., ../data/generated/code-lifetime-data/<bug_id>.csv> [help]"
if [ "$#" -ne "1" ] && [ "$#" -ne "4" ]; then
  die "$USAGE"
fi

BUG_ID=""
OUTPUT_FILE_PATH=""

while [[ "$1" = --* ]]; do
  OPTION=$1; shift
  case $OPTION in
    (--bug_id)
      BUG_ID=$1;
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
[ "$BUG_ID" != "" ]           || die "[ERROR] Missing --bug_id argument!"
[ "$OUTPUT_FILE_PATH" != "" ] || die "[ERROR] Missing --output_file_path argument!"

# Remove the output_file_path (if any) and create a new one
echo "project_full_name,fix_commit_hash,bug_id,bug_type,file_path,line_number,commit_hash,commit_message,author_name,author_commit_date,bug_fix" > "$OUTPUT_FILE_PATH" || die "[ERROR] Failed to create $OUTPUT_FILE_PATH file!"

# ------------------------------------------------------------------------- Main

grep -Eq "^.*,.*,.*,\"$BUG_ID\",.*" "$BUGS_FILE_PATH" || die "[ERROR] $BUG_ID not found in the $BUGS_FILE_PATH!"
             item=$(grep -E "^.*,.*,.*,\"$BUG_ID\",.*" "$BUGS_FILE_PATH")
project_full_name=$(echo "$item" | cut -f1 -d',' | tr -d '"')
  fix_commit_hash=$(echo "$item" | cut -f3 -d',' | tr -d '"')
buggy_commit_hash="${fix_commit_hash}^1"
           bug_id=$(echo "$item" | cut -f4 -d',' | tr -d '"')
         bug_type=$(echo "$item" | cut -f5 -d',' | tr -d '"')
echo "[DEBUG] $project_full_name :: $bug_id"

work_dir="/tmp/$USER-$$-$(echo $RANDOM | md5sum | cut -f1 -d' ')-$BUG_ID"
rm -rf "$work_dir"; mkdir "$work_dir"

# Get project's source code
git clone "$PROJECTS_REPOSITORIES_DIR/$project_full_name" "$work_dir" || die "[ERROR] Failed to clone project $project_full_name bug $bug_id to $work_dir!"

pushd . > /dev/null 2>&1
cd "$work_dir"
  # Checkout buggy commit
  git checkout "$buggy_commit_hash" || die "[ERROR] Failed to checkout the buggy version of project $project_full_name bug $bug_id!"

  # Collect all bug-fixing commits
  commits_file_path="$work_dir/commits.txt"
  echo "commit_hash,commit_message,author_name,author_commit_date,bug_fix" > "$commits_file_path"
  while read -r commit_hash; do
    commit_message=$(git show "$commit_hash" --pretty=format:"%B" --no-patch | sed ':a;N;$!ba;s/\n/ /g' | sed 's|,||g' | dos2unix)
    echo "[DEBUG] $project_full_name :: $bug_id :: $commit_hash :: $commit_message"

    # Is it a bug-fix commit?
    bug_fix=0
    if echo "$commit_message" | grep -Eq "refactor|typo|requirement|import|style"; then
      bug_fix=0
    elif echo "$commit_message" | grep -Eq "fix(e[ds])?|bugs?|defects?|patch|corrigidos?|close([sd])?|resolve([sd])?"; then
      bug_fix=1
    fi
    echo "[DEBUG] $project_full_name :: $bug_id :: $commit_hash $bug_fix"

    author_data=$(git show "$commit_hash" --pretty=format:"%an,%at" --no-patch)
    author_name=$(echo "$author_data" | cut -f1 -d',')
    author_commit_date=$(echo "$author_data" | cut -f2 -d',')

    echo "$commit_hash,$commit_message,$author_name,$author_commit_date,$bug_fix" >> "$commits_file_path"
  done < <(git log --pretty=format:"%H" --no-patch | sed -e '$a\')

  # Collect metadata per .py file, per line
  while read -r file_path; do
    while read -r row; do
      echo "[DEBUG] $project_full_name :: $bug_id :: $file_path :: $row"
      line_number=$(echo "$row" | cut -f1)
      line_content=$(echo "$row" | cut -f2)

      # Is it an empty line?
      if [ "$line_number" == "$line_content" ] || echo "$line_content" | grep -Eq "^\s*$"; then
        echo "[DEBUG] $project_full_name :: $bug_id :: $file_path :: $line_number :: $line_content empty line, ignored"
        continue
      fi

      # Is it a line with no code but with a comment?
      if echo "$line_content" | grep -Eq "^\s*#.*$"; then
        echo "[DEBUG] $project_full_name :: $bug_id :: $file_path :: $line_number :: $line_content no code, ignored"
        continue
      fi

      while read -r commit_hash; do
        echo "$project_full_name,$fix_commit_hash,$bug_id,$bug_type,$file_path,$line_number,"$(grep "^$commit_hash," "$commits_file_path") >> "$OUTPUT_FILE_PATH"
      done < <(git log -L"$line_number,$line_number":"$file_path" "$buggy_commit_hash" --pretty=format:"%H" --no-patch | sed -e '$a\')
    done < <(cat -n "$file_path")
  done < <(find . -type f -name "*.py" | grep -v "__init__.py" | sed 's|^./||g')
popd > /dev/null 2>&1

# Clean up, i.e., remove checkout directory
rm -rf "$work_dir"

echo "DONE!"
exit 0

# EOF
