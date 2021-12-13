# ------------------------------------------------------------------------------
# This scripts generates a projects' table summary.
#
# Usage:
# Rscript projects-table.R <tex_file_path, e.g., projects.tex>
#
# ------------------------------------------------------------------------------

library('this.path') # install.packages('this.path')
source(paste(this.dir(), '/util.R', sep=''))

args = commandArgs(trailingOnly=TRUE)
if (length(args) < 1) {
  stop('USAGE: projects-table.R <tex_file_path, e.g., projects.tex>')
}

OUTPUT_FILE_PATH <- args[1]

# Load data
DATA_FILE_PATH <- paste(this.dir(), '/../data/generated/bugs-in-quantum-computing-platforms.csv', sep='')
df <- set_programming_languages(read.table(DATA_FILE_PATH, header=TRUE, stringsAsFactors=FALSE))

unlink(OUTPUT_FILE_PATH)
sink(OUTPUT_FILE_PATH, append=FALSE, split=TRUE)

cat('\\begin{tabular}{@{\\extracolsep{\\fill}} llrrr} \\toprule\n', sep='')
cat('\\multicolumn{1}{c}{Project} & \\multicolumn{1}{c}{Language} & \\multicolumn{1}{c}{\\# Bugs} & \\multicolumn{1}{c}{\\# Classical} & \\multicolumn{1}{c}{\\# Quantum} \\\\\n\\midrule\n', sep='')

for (project_full_name in sort(unique(df$'project_full_name'))) {
  mask <- df$'project_full_name' == project_full_name
  cat(project_full_name, ' & ',
      replace_string(replace_string(unique(df$'languages'[mask]), '#', '\\\\#'), ' ', ', '), ' & ',
      nrow(df[mask, ]), ' & ',
      nrow(df[mask & df$'type' == 'Classical', ]), ' & ',
      nrow(df[mask & df$'type' == 'Quantum', ]), ' \\\\\n', sep='')
}

cat('\\bottomrule\n', sep='')
cat('\\end{tabular}\n', sep='')

sink()

# EOF
