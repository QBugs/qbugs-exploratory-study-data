# ------------------------------------------------------------------------------
# This scripts performs some fixes in the bugs dataset.
#
# Usage:
# Rscript fix-bugs-dataset.R
#   <data_file_path, e.g., ../data/generated/bugs-in-quantum-computing-platforms.csv>
#
# ------------------------------------------------------------------------------

source('../../utils/statistics/util.R')

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
names(df)[names(df) == 'id']          <- 'bug_id'
names(df)[names(df) == 'type']        <- 'bug_type'
names(df)[names(df) == 'repo']        <- 'project_full_name'
names(df)[names(df) == 'commit_hash'] <- 'fix_commit_hash'
names(df)[names(df) == 'component']   <- 'high_level_buggy_component'

# Add new columns
df$'project_repository_url' <- paste('https://github.com/', df$'project_full_name', '.git', sep='')

# Re-order columns
df <- df[, c(
  'project_full_name',
  'project_repository_url',
  'fix_commit_hash',
  'bug_id',
  'bug_type',
  'high_level_buggy_component',
  'bug_pattern',
  'symptom',
  'complexity'
)]

# Write processed data.frame to a file
write.table(df, file=DATA_FILE_PATH, append=FALSE, sep=',', row.names=FALSE)

# EOF
