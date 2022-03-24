# ------------------------------------------------------------------------------
# This script print out a latex table with the number of bugs in which each
# buggy component appears at least once.
#
# Usage:
#   Rscript num-bugs-per-buggy-component-as-table.R
#     <input data file, e.g., ../data/generated/buggy-code-data.csv>
#     <output tex file, e.g., num-bugs-per-buggy-component.tex>
# ------------------------------------------------------------------------------

source('../../utils/statistics/util.R')

# Load external packages
library('ggplot2')
library('reshape2')

# ------------------------------------------------------------------------- Args

args = commandArgs(trailingOnly=TRUE)
if (length(args) != 2) {
  stop('USAGE: Rscript num-bugs-per-buggy-component-as-table.R <input data file, e.g., ../data/generated/buggy-code-data.csv> <output tex file, e.g., num-bugs-per-buggy-component.tex>')
}

# Args
INPUT_FILE  <- args[1]
OUTPUT_FILE <- args[2]

# ------------------------------------------------------------------------- Main

# Load data
df <- load_CSV(INPUT_FILE)

# Aggregate data
df$'count' <- 1
df <- aggregate(formula=count ~ bug_id + bug_type + buggy_component, data=df, FUN=sum)
df$'count' <- 1
df <- aggregate(formula=count ~ bug_type + buggy_component, data=df, FUN=sum)

# Remove the output file if any
unlink(OUTPUT_FILE)
sink(OUTPUT_FILE, append=FALSE, split=TRUE)

# Write down the table header
cat('\\begin{tabular}{@{\\extracolsep{\\fill}} lrr} \\toprule\n', sep='')
cat('\\multicolumn{1}{c}{Buggy Component} & \\multicolumn{1}{c}{\\# Classical Bugs} & \\multicolumn{1}{c}{\\# Quantum Bugs} \\\\ \n', sep='')
cat('\\midrule \n', sep='')

for (buggy_component in sort(unique(df$'buggy_component'))) {
  # Print out buggy component name
  cat(buggy_component, sep='')
  # Per bug type
  for (bug_type in c('Classical', 'Quantum')) {
    if (nrow(df[df$'buggy_component' == buggy_component & df$'bug_type' == bug_type, ]) == 0) {
      count <- 0
    } else {
      count <- df$'count'[df$'buggy_component' == buggy_component & df$'bug_type' == bug_type]
    }
    cat(' & ', count, sep='')
  }
  # New line
  cat(' \\\\ \n', sep='')
}

# Footer
cat('\\bottomrule\n', sep='')
cat('\\end{tabular}\n', sep='')

# Flush data
sink()

# EOF
