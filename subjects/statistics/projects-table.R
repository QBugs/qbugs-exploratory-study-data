# ------------------------------------------------------------------------------
# This scripts generates a projects' table summary.
#
# Usage:
# Rscript projects-table.R <tex_file_path, e.g., projects.tex>
#
# ------------------------------------------------------------------------------

source('util.R')

args = commandArgs(trailingOnly=TRUE)
if (length(args) < 1) {
  stop('USAGE: projects-table.R <tex_file_path, e.g., projects.tex>')
}

OUTPUT_FILE_PATH <- args[1]

# Load data
df <- load_CSV('../data/generated/bugs-in-quantum-computing-platforms.csv')
df <- set_programming_languages(df)

unlink(OUTPUT_FILE_PATH)
sink(OUTPUT_FILE_PATH, append=FALSE, split=TRUE)

cat('\\begin{tabular}{@{\\extracolsep{\\fill}} llrrr} \\toprule\n', sep='')
cat('\\multicolumn{1}{c}{Project} & \\multicolumn{1}{c}{Language} & \\multicolumn{1}{c}{\\# Bugs} & \\multicolumn{1}{c}{\\# Classical} & \\multicolumn{1}{c}{\\# Quantum} \\\\\n\\midrule\n', sep='')

# Per project
for (project_full_name in sort(unique(df$'project_full_name'))) {
  mask <- df$'project_full_name' == project_full_name
  cat(project_full_name, ' & ',
      replace_string(replace_string(unique(df$'languages'[mask]), '#', '\\\\#'), ' ', ', '), ' & ',
      nrow(df[mask, ]), ' & ',
      nrow(df[mask & df$'bug_type' == 'Classical', ]), ' & ',
      nrow(df[mask & df$'bug_type' == 'Quantum', ]), ' \\\\\n', sep='')
}
# Total
cat('\\midrule\n', sep='')
cat('\\textit{Total} &  & ', nrow(df), ' & ', nrow(df[df$'bug_type' == 'Classical', ]), ' & ', nrow(df[df$'bug_type' == 'Quantum', ]), ' \\\\\n', sep='')

cat('\\bottomrule\n', sep='')
cat('\\end{tabular}\n', sep='')

sink()

# EOF
