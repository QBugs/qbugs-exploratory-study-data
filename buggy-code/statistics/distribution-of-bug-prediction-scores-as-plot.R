# ------------------------------------------------------------------------------
# This script plots the distribution of buggy prediction scores as boxplot.
#
# Usage:
#   Rscript distribution-of-bug-prediction-scores-as-plot.R
#     <input data file, e.g., ../data/generated/code-lifetime-data.csv.gz>
#     <output pdf file, e.g., distribution-of-bug-prediction-scores-as-plot.pdf>
# ------------------------------------------------------------------------------

source('../../utils/statistics/util.R')

# Load external packages
library('reshape2')

# ------------------------------------------------------------------------- Args

args = commandArgs(trailingOnly=TRUE)
if (length(args) != 2) {
  stop('USAGE: Rscript distribution-of-bug-prediction-scores-as-plot.R <input data file, e.g., ../data/generated/code-lifetime-data.csv.gz> <output pdf file, e.g., distribution-of-bug-prediction-scores-as-plot.pdf>')
}

# Args
INPUT_FILE  <- args[1]
OUTPUT_FILE <- args[2]

# Constant values suggested in the research paper
# [An Empirical Study on the Use of Defect Prediction for Test Case Prioritization](https://ieeexplore.ieee.org/document/8730206) (see Table II)
REVISIONS_WEIGHT <- 0.6
AUTHORS_WEIGHT   <- 0.3
FIXES_WEIGHT     <- 0.1
TIME_RANGE       <- 0.0
W                <- 2 + ((1 - TIME_RANGE) * 10)

# ------------------------------------------------------------------------- Main

# Load data
df <- load_CSV_GZ(INPUT_FILE)

#
# Normalize timestamps of each commit per bug
#
cat('[INFO] Normalizing timestamps... \n')

min_max_norm <- function(x) {
  if (max(x) == min(x)) {
    return (1)
  }
  return ((x - min(x)) / (max(x) - min(x)))
}

df$'alpha' <- NA
for (bug_id in unique(df$'bug_id')) {
  mask <- df$'bug_id' == bug_id
  df$'alpha'[mask] <- min_max_norm(df$'author_commit_date'[mask])
}
# Drop 'author_commit_date' column as it is no longer required
df <- df[ , !(names(df) %in% c('author_commit_date'))]
summary(df) # FIXME remove me
head(df) # FIXME remove me

#
# Compute TWR's authors, revisions, and bug-fix commits
#
cat('[INFO] Computing TWRs authors, revisions, and bug-fix commits... \n')

# Compute TWR's authors
x_authors_twr                             <- aggregate(formula=alpha ~ bug_id + file_path + line_number + author_name, data=df, FUN=min)
x_authors_twr$'authors_twr'               <- 1 / (1 + exp(-12 * x_authors_twr$'alpha' + W))
df                                        <- merge(df, x_authors_twr, by=c('bug_id', 'file_path', 'line_number', 'author_name', 'alpha'), all.x=TRUE)
df$'authors_twr'[is.na(df$'authors_twr')] <- 0
remove(x_authors_twr)

# Compute TWR's revisions
df$'revisions_twr'                        <- 1 / (1 + exp(-12 * df$'alpha' + W))

# Compute TWR's bug-fix commits
df$'fixes_twr'[df$'bug_fix' == 0]         <- 0
df$'fixes_twr'[df$'bug_fix' == 1]         <- 1 / (1 + exp(-12 * df$'alpha'[df$'bug_fix' == 1] + W))

#
# Compute TWR's sums
#
cat('[INFO] Computing TWRs sums... \n')

df <- aggregate(formula=cbind(revisions_twr, authors_twr, fixes_twr) ~ project_full_name + bug_id + bug_type + file_path + line_number, data=df, FUN=sum)
# Rename resulting columns
names(df)[names(df) == 'revisions_twr'] <- 'sum_revisions_twr'
names(df)[names(df) == 'authors_twr']   <- 'sum_authors_twr'
names(df)[names(df) == 'fixes_twr']     <- 'sum_fixes_twr'

#
# Compute TWR's weights
#
cat('[INFO] Computing TWRs weights... \n')

df$'weight_revisions_twr' <- REVISIONS_WEIGHT * df$'sum_revisions_twr'
df$'weight_authors_twr'   <- AUTHORS_WEIGHT * df$'sum_authors_twr'
df$'weight_fixes_twr'     <- FIXES_WEIGHT * df$'sum_fixes_twr'

#
# Compute beta value and defect value
#
cat('[INFO] Computing defect values... \n')

df$'beta'   <- df$'weight_revisions_twr' + df$'weight_authors_twr' + df$'weight_fixes_twr'
df$'defect' <- 1 - exp(-df$'beta')
head(df) # FIXME remove me
summary(df$'defect')

#
# Get buggy-components per line of code from another dataframe and merge it
#
cat('[INFO] Combining data... \n')

# TODO 1. read ../data/generated/buggy-code-data.csv
# TODO 2. annotated all buggy_line_number as buggy, i.e., create a new column named 'buggy' with value 1
# TODO 3. merge it with df
# TODO 4. set the value of all NaNs (lines of code for each we have historical data but are not-buggy) in the 'buggy' column as 0

#
# Compute the distribution of bug-prediction scores overall, of buggy lines only,
# min, max, average, median position of buggy lines, and top-N
#
cat('[INFO] Compute the distribution of bug-prediction scores... \n')

# TODO

# EOF
