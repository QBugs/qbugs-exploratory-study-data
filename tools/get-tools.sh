#!/usr/bin/env bash
#
# ------------------------------------------------------------------------------
# This script downloads and/or sets up the following tools:
#   - [PySmell](https://github.com/QBugs/PySmell)
#   - [R](https://www.r-project.org)
#
# Usage:
# get-tools.sh
#
# ------------------------------------------------------------------------------

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" > /dev/null 2>&1 && pwd)"
source "$SCRIPT_DIR/../utils/scripts/utils.sh" || exit 1

# ------------------------------------------------------------------------- Deps

# Check whether 'wget' is available
wget --version > /dev/null 2>&1 || die "[ERROR] Could not find 'wget' to download all dependencies. Please install 'wget' and re-run the script."

# Check whether 'git' is available
git --version > /dev/null 2>&1 || die "[ERROR] Could not find 'git' to clone git repositories. Please install 'git' and re-run the script."

# Check whether 'Rscript' is available
Rscript --version > /dev/null 2>&1 || die "[ERROR] Could not find 'Rscript' to perform, e.g., statistical analysis. Please install 'Rscript' and re-run the script."

# ------------------------------------------------------------------------- Util

#
# Get PySmell
#
echo ""
echo "Setting up PySmell..."

PYSMELL_DIR_PATH="$SCRIPT_DIR/pysmell"

# Remove any previous file and directory
rm -rf "$PYSMELL_DIR_PATH"

git clone https://github.com/QBugs/PySmell.git "$PYSMELL_DIR_PATH"
if [ "$?" -ne "0" ] || [ ! -d "$PYSMELL_DIR_PATH" ]; then
  die "[ERROR] Clone of 'PySmell' failed!"
fi

pushd . > /dev/null 2>&1
cd "$PYSMELL_DIR_PATH"
  # Switch to lastest commit
  git checkout f5e9673a3d1b97f8376b7f3884ca0bee5545e1fd || die "[ERROR] Commit 'f5e9673a3d1b97f8376b7f3884ca0bee5545e1fd' not found!"
popd > /dev/null 2>&1

#
# R packages
#

echo ""
echo "Setting up R..."

Rscript "$SCRIPT_DIR/get-libraries.R" || die "[ERROR] Failed to install/load all required R packages!"

echo ""
echo "DONE! All tools have been successfully prepared."

# EOF
