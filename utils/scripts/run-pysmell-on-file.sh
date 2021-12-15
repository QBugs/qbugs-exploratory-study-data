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

PYTHON_ENV_DIR="$SCRIPT_DIR/../../tools/env"
[ -d "$PYTHON_ENV_DIR" ] || die "[ERROR] $PYTHON_ENV_DIR does not exit!"
PYSMELL_DIR="$SCRIPT_DIR/../../tools/pysmell"
[ -d "$PYSMELL_DIR" ] || die "[ERROR] $PYSMELL_DIR does not exit!"

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

# Activate virtual environment
source "$SCRIPT_DIR/../../tools/env/bin/activate" || die "[ERROR] Failed to activate virtual environment!"

echo "[DEBUG] Running PySmell on $FILE_PATH"
pysmell \
  --py-file-to-analyze "$FILE_PATH" \
  --output-file "$OUTPUT_FILE_PATH" || die "[ERROR] Failed to run pysmell on $FILE_PATH!"
[ -s "$OUTPUT_FILE_PATH" ] || die "[ERROR] $OUTPUT_FILE_PATH does not exist or it is empty!"

# Deactivate virtual environment
deactivate || die "[ERROR] Failed to deactivate virtual environment!"

echo "DONE!"
exit 0

# EOF
