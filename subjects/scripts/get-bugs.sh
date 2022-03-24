#!/usr/bin/env bash
#
# ------------------------------------------------------------------------------
# This script collects the set of annotated bugs from the
# [Bugs-Quantum-Computing-Platforms](https://github.com/MattePalte/Bugs-Quantum-Computing-Platforms)
# repository and performs some additional fixes.
#
# Usage:
# get-bugs.sh
#   [--output_file_path <path, e.g., ../data/generated/bugs-in-quantum-computing-platforms.csv>]
#   [help]
# ------------------------------------------------------------------------------

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" > /dev/null 2>&1 && pwd)"
source "$SCRIPT_DIR/../../utils/scripts/utils.sh" || exit 1

# ------------------------------------------------------------------------- Args

USAGE="Usage: ${BASH_SOURCE[0]} [--output_file_path <path, e.g., ../data/generated/bugs-in-quantum-computing-platforms.csv>] [help]"
if [ "$#" -ne "0" ] && [ "$#" -ne "1" ] && [ "$#" -ne "2" ]; then
  die "$USAGE"
fi

OUTPUT_FILE_PATH="$BUGS_FILE_PATH"

while [[ "$1" = --* ]]; do
  OPTION=$1; shift
  case $OPTION in
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
[ "$OUTPUT_FILE_PATH" != "" ] || die "[ERROR] Missing --output_file_path argument!"
# Remove the output_file_path (if any)
rm -f "$OUTPUT_FILE_PATH"

# ------------------------------------------------------------------------- Main

COMMIT_HASH="e4176f64e1fbb3d9b6591bc6ccbb6edeaf17af95"

#
# Get set of bugs
#

wget -O "$OUTPUT_FILE_PATH" "https://raw.githubusercontent.com/MattePalte/Bugs-Quantum-Computing-Platforms/$COMMIT_HASH/artifacts/annotation_bugs.csv" || die "[ERROR] Failed to get the 'annotation_bugs.csv' file from the https://raw.githubusercontent.com/MattePalte/Bugs-Quantum-Computing-Platforms repository!"
[ -s "$OUTPUT_FILE_PATH" ] || die "[ERROR] $OUTPUT_FILE_PATH does not exist or it is empty!"

#
# Fix the CSV file
#

# Fix bug ids
sed -i 's|^"75,5"|75-5|'     "$OUTPUT_FILE_PATH" || die "[ERROR] Failed to fix bug id '75,5'!"
sed -i 's|^"1814,5"|1814-5|' "$OUTPUT_FILE_PATH" || die "[ERROR] Failed to fix bug id '1814,5'!"
sed -i 's|^"1854,5"|1854-5|' "$OUTPUT_FILE_PATH" || die "[ERROR] Failed to fix bug id '1854,5'!"
sed -i 's|^"1900,5"|1900-5|' "$OUTPUT_FILE_PATH" || die "[ERROR] Failed to fix bug id '1900,5'!"
sed -i 's|^"1909,5"|1909-5|' "$OUTPUT_FILE_PATH" || die "[ERROR] Failed to fix bug id '1909,5'!"

# And perform few more fixes, i.e., select relevant columns and filter out bugs
# that have not been considered real bugs but false positives
Rscript "$SCRIPT_DIR/fix-bugs-dataset.R" "$OUTPUT_FILE_PATH" || die "[ERROR] Failed to run $SCRIPT_DIR/fix-bugs-dataset.R!"

echo "DONE!"
exit 0

# EOF
