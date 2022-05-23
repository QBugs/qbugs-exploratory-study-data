# Command Line Usage : dir containing the quantum computing platform repositories(e.g, - /mnt/c/Users/migue/OneDrive/teste)
# Usage:
#  bash compute-type-of-file.sh --dir_file_path
#  [--dir_file_path: dir containing the quantum computing platform repositories <path, e.g., ../../subjects/data/generated/bugs-in-quantum-computing-platforms.csv>]
#  [--output_file_path <path, e.g., ../data/generated/files-fix-commits.csv>]
# Requires:
# - directory containing the quantum computing platform repositories
#---------------------------------------------------------------------------------------------------------------

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" > /dev/null 2>&1 && pwd)"

# ------------------------------------------------------------------------- Args

OUTPUT_FILE_PATH="$SCRIPT_DIR/../data/generated/files-fix-commits.csv"
DIR_FILE_PATH="$DIR_FILE_PATH"

# Check whether all arguments have been initialized
[ "$DIR_FILE_PATH" != "" ]   || die "[ERROR] Missing --dir_file_path argument!"
[ "$OUTPUT_FILE_PATH" != "" ] || die "[ERROR] Missing --output_file_path argument!"
# Check whether all arguments exist
[ -s "$DIR_FILE_PATH" ]      || die "[ERROR] $DIR_FILE_PATH does not exist or it is empty!"
# Remove the output_file_path (if any) and create a new one
rm -f "$OUTPUT_FILE_PATH"
echo "fix_commit_hash,bug_id,bug_type,file_path,project_name"  > "$OUTPUT_FILE_PATH"

# ------------------------------------------------------------------------- Main

while IFS="," read -r  project_full_name project_repository_url fix_commit_hash bug_id bug_type high_level_buggy_component bug_pattern symptom complexity; do
	echo "bug_id : $bug_id"
    echo "fix_commit_hash : $fix_commit_hash"
	echo "bug_type : $bug_type"
	echo "project_repository_url : $project_repository_url"
    sub_repo=$(echo "$project_repository_url" | rev | cut -d/ -f1 | rev | cut -d. -f1) || die "[ERROR] Failed to obtain project name"
    echo "sub_repo : $sub_repo"
    sha1=$(echo "$fix_commit_hash" | tr -d '"') || die "[ERROR] Failed to obtain commit hash"
    echo $sha1 
    dir="$1/$sub_repo" || die "[ERROR] Failed to obtain a valid directory of a quantum project"
    files=$(cd $dir && git diff-tree --no-commit-id --name-only -r $sha1) || die "[ERROR] Failed to collect modified files from $fix_commit_hash!"

    while read line; do 
        echo "$sha1,$bug_id,$bug_type,$line,$sub_repo" >> "$OUTPUT_FILE_PATH" || die "[ERROR] Failed to append data to the $OUTPUT_FILE_PATH file!"
        done < <(echo "$files") 

done < <(tail -n +2 ../../subjects/data/generated/bugs-in-quantum-computing-platforms.csv)