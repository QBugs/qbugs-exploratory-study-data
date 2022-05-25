# ------------------------------------------------------------------------------
# This script plots the distribution of each type of file as UpSetR plot.
#
# Usage:
#   Rscript distribution-of-type-of-files-as-plot.R
#     <input data file, e.g., ../data/generated/edited-files.csv>
#     <output pdf file, e.g., distribution-of-type-of-files-as-plot.pdf>
# ------------------------------------------------------------------------------

source('../../utils/statistics/util.R')

# Load external packages
library('ggplot2')
library('reshape2')
library('UpSetR')
library('nortest')
library('effsize')

# ------------------------------------------------------------------------- Args

args = commandArgs(trailingOnly=TRUE)
if (length(args) != 2) {
  stop('USAGE: Rscript distribution-of-type-of-files-as-plot.R <input data file, e.g., ../data/generated/edited-files.csv> <output pdf file, e.g.,  distribution-of-type-of-files-as-plot.pdf>')
}

# Args
INPUT_FILE  <- args[1]
OUTPUT_FILE <- args[2]

# ------------------------------------------------------------------------- Main

# Load data
df <- load_CSV(INPUT_FILE)

# Set (default) type of file
df$'file_type' <- 'Unknown'
# Rules to set type of each file
df$'file_type'[grep('CODEOWNERS|Quil.g4$|.md$|.rst$', df$'file_path')]                                   <- 'Documentation File'
df$'file_type'[grep('.cfg$|.ini$|.toml$', df$'file_path')]                                               <- 'Configuration File'
df$'file_type'[grep('.cpp$|.cs$|.fs$|.h$|.hpp$|.ll$|.py$|.qisa$|.qs$', df$'file_path')]                  <- 'Source Code File'
df$'file_type'[grep('.csproj$|.fsproj$|makefile|.ps1$|Simulation.sln|Sdk.targets|.rs$', df$'file_path')] <- 'Build File'
df$'file_type'[grep('.ipynb$|.sh$', df$'file_path')]                                                     <- 'Script File'
df$'file_type'[grep('.json$|TrialResult.repr|.yaml$|.yml$', df$'file_path')]                             <- 'Data File'
df$'file_type'[grep('.txt$', df$'file_path')]                                                            <- 'Text File'

# Aggregate data
df$'count' <- 1
agg_count <- aggregate(x=count ~ bug_id + bug_type + file_type, data=df, FUN=sum)

# Remove any existing output file and create a new one
unlink(OUTPUT_FILE)
pdf(file=OUTPUT_FILE, family='Helvetica', width=7, height=4)
# Add a cover page to the output file
plot_label('Distributions')

#
# As UpSetR plot
#

for (bug_type in unique(df$'bug_type')) {
  columns <- colnames(df)

  for (keep_order in c(TRUE, FALSE)) {
    plot_label(paste('UpSetR (overall)', '\n', 'keep.order=', keep_order, '\n', bug_type, sep=''))
    a <- dcast(df[df$'bug_type' == bug_type, ], ... ~ file_type, value.var='file_type', fun.aggregate=length)
    a <- a[ , which(colnames(a) %!in% columns) ]
    p <- upset(a, sets=colnames(a), order.by=c('freq'), nintersects=50, keep.order=keep_order, set_size.show=TRUE,
               mb.ratio=c(0.40, 0.60), #point.size=3.5, line.size=1.1,
               # text.scale=c(intersection size title, intersection size tick labels, set size title, set size tick labels, set names, numbers above bars).
               text.scale=c(1, 1.2, 1, 1.2, 1.3, 1.1),
               set_size.scale_max=2500,
               mainbar.y.label='Intersection Size', sets.x.label='Set Size')
    print(p)
    
    plot_label(paste('UpSetR (agg by bug)', '\n', 'keep.order=', keep_order, '\n', bug_type, sep=''))
    a <- dcast(aggregate(x=. ~ bug_id + file_type, data=df[df$'bug_type' == bug_type, ], FUN=length),
               bug_id ~ file_type, value.var='file_type', fun.aggregate=length)
    a <- a[ , which(colnames(a) %!in% c('bug_id')) ]
    p <- upset(a, sets=colnames(a), order.by=c('freq'), nintersects=NA, keep.order=keep_order, set_size.show=TRUE,
               mb.ratio=c(0.40, 0.60), #point.size=3.5, line.size=1.1,
               # text.scale=c(intersection size title, intersection size tick labels, set size title, set size tick labels, set names, numbers above bars).
               text.scale=c(1, 1.2, 1, 1.2, 1.3, 1.1),
               set_size.scale_max=100,
               mainbar.y.label='Intersection Size', sets.x.label='Set Size')
    print(p)
  }
}

# Close output file
dev.off()
# Embed fonts
embed_fonts_in_a_pdf(OUTPUT_FILE)

# EOF
