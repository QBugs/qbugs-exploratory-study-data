# ------------------------------------------------------------------------------
# This scripts performs some fixes in the bugs dataset.
#
# Usage:
# Rscript fix-bugs-dataset.R
#   <data_file_path, e.g., ../data/generated/bugs-in-quantum-computing-platforms.csv>
#
# ------------------------------------------------------------------------------

library('this.path') # install.packages('this.path')
source(paste(this.dir(), '/../statistics/util.R', sep=''))

args = commandArgs(trailingOnly=TRUE)
if (length(args) < 1) {
  stop('USAGE: fix-bugs-dataset.R <data_file_path, e.g., ../data/generated/bugs-in-quantum-computing-platforms.csv>')
}

# Load data
DATA_FILE_PATH <- args[1]
df <- read.csv(DATA_FILE_PATH, header=TRUE, stringsAsFactors=FALSE) # id,real,type,repo,commit_hash,component,symptom,bug_pattern,complexity,comment,localization

# Filter out false-positives
df <- df[df$'real' != 'fp', ]

# Select relevant columns
df <- df[, names(df) %in% c('id', 'type', 'repo', 'commit_hash', 'component', 'symptom', 'bug_pattern', 'complexity')]

# Rename columns
names(df)[names(df) == 'repo']        <- 'project_full_name'
names(df)[names(df) == 'commit_hash'] <- 'fix_commit_hash'

# Add new columns
df$'project_clone_url' <- paste('https://github.com/', df$'project_full_name', '.git', sep='')

# Write processed data.frame to a file
write.table(df, file=DATA_FILE_PATH)

# EOF
