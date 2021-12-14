#!/usr/bin/env bash
#
# ------------------------------------------------------------------------------
# This script runs [PySmell](https://github.com/QBugs/PySmell) on a single `.py`
# file and writes PySmell's output to the provided output file.
#
# Usage:
# run-pysmell-on-file.sh
#   --file_path <path>
#   --output_file_path <path>
#   [help]
# ------------------------------------------------------------------------------

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" > /dev/null 2>&1 && pwd)"
source "$SCRIPT_DIR/utils.sh" || exit 1

# -------------------------------------------------------------------------- Env

PYSMELL_DIR="$SCRIPT_DIR/../../tools/pysmell"
[ -d "$PYSMELL_DIR" ] || die "[ERROR] $PYSMELL_DIR does not exit!"
# TODO
# Add $PYSMELL_DIR to PYTHONPATH env variable
# Sanity check
pysmell --version > /dev/null 2>&1 || die "[ERROR] Could not find/run 'pysmell' command!"

# ------------------------------------------------------------------------- Args

USAGE="Usage: ${BASH_SOURCE[0]} --file_path <path> --output_file_path <path> [help]"
if [ "$#" -ne "1" ] && [ "$#" -ne "4" ]; then
  die "$USAGE"
fi

FILE_PATH=""
OUTPUT_FILE_PATH=""

while [[ "$1" = --* ]]; do
  OPTION=$1; shift
  case $OPTION in
    (--file_path)
      FILE_PATH=$1;
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
[ "$FILE_PATH" != "" ]        || die "[ERROR] Missing --file_path argument!"
[ "$OUTPUT_FILE_PATH" != "" ] || die "[ERROR] Missing --output_file_path argument!"
# Remove the output_file_path (if any)
rm -f "$OUTPUT_FILE_PATH"

# ------------------------------------------------------------------------- Main

echo "[DEBUG] Running PySmell on $FILE_PATH"
pysmell --path-file "$FILE_PATH" "$OUTPUT_FILE_PATH" || die "[ERROR] Failed to run pysmell on $FILE_PATH!"
[ -s "$OUTPUT_FILE_PATH" ] || die "[ERROR] $OUTPUT_FILE_PATH does not exist or it is empty!"

echo "DONE!"
exit 0

# EOF
