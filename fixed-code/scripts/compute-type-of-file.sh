# Command Line Usage : bash compute-type-of-file.sh dir containing the quantum computing platform repositories(e.g - /mnt/c/Users/migue/OneDrive/Ambiente\ de\ Trabalho/teste)

# Add headers for csv file
echo "fix_commit_hash,bug_id,bug_type,file_path,project_name" > ../data/generated/type-of-file.csv; \

while IFS="," read -r  project_full_name project_repository_url fix_commit_hash bug_id bug_type high_level_buggy_component bug_pattern symptom complexity
do
	echo "bug_id : $bug_id"
    echo "fix_commit_hash : $fix_commit_hash"
	echo "bug_type : $bug_type"
	echo "project_repository_url : $project_repository_url"
    sub_repo=$(echo "$project_repository_url" | rev | cut -d/ -f1 | rev | cut -d. -f1)
    echo "sub_repo : $sub_repo"
    sha1=$(echo "$fix_commit_hash" | tr -d '"')
    echo $sha1 

    dir="$1/$sub_repo"
    echo "dir is : $dir"
    ( cd $dir && git checkout -f $sha1)
    files=$(cd $dir && git diff-tree --no-commit-id --name-only -r $sha1)
    echo "teste : $files"

    while read line
    do 
    echo "$sha1,$bug_id,$bug_type,$line,$sub_repo" >> ../data/generated/type-of-file.csv

    done < <(echo "$files") 



done < <(tail -n +2 ../../subjects/data/generated/bugs-in-quantum-computing-platforms.csv)