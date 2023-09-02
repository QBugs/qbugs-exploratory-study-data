# ------------------------------------------------------------------------------
# This script plots the distribution of each type of file.
#
# Usage:
#   Rscript distribution-of-buggy-files.R
#     <input data file, e.g., ../data/generated/buggy-files-data.csv>
#     <output tables directory, e.g., tables/>
#     <output figures directory, e.g., figures/>
# ------------------------------------------------------------------------------

source('../../utils/statistics/util.R')

# Load external packages
library('reshape2')
library('UpSetR')
library('effsize')

# ------------------------------------------------------------------------- Args

args = commandArgs(trailingOnly=TRUE)
if (length(args) != 3) {
  stop('USAGE: Rscript distribution-of-buggy-files-as-plot.R <input data file, e.g., ../data/generated/buggy-files-data.csv> <output tables directory, e.g., tables/> <output figures directory, e.g., figures/>')
}

# Args
INPUT_FILE         <- args[1]
OUTPUT_TABLES_DIR  <- args[2]
OUTPUT_FIGURES_DIR <- args[3]

# ------------------------------------------------------------------------- Main

# Load data
df <- load_CSV(INPUT_FILE)

# Set (default) type of file
df$'file_type' <- 'Unknown'
# Rules to set type of each file
df$'file_type'[grep('.txt$', df$'buggy_file_path')]                                                            <- 'Text File'
df$'file_type'[grep('CODEOWNERS|Quil.g4$|.md$|.rst$', df$'buggy_file_path')]                                   <- 'Documentation File'
df$'file_type'[grep('.cfg$|.ini$|.toml$', df$'buggy_file_path')]                                               <- 'Configuration File'
df$'file_type'[grep('.cpp$|.cs$|.cc$|.cu$|.fs$|.h$|.hpp$|.ll$|.py$|.qisa$|.qs$|.ipynb', df$'buggy_file_path')] <- 'Source Code File'
df$'file_type'[grep('.csproj$|.fsproj$|makefile|.ps1$|Simulation.sln|Sdk.targets|.rs$|requirements.txt', df$'buggy_file_path')] <- 'Build File'
df$'file_type'[grep('.sh$', df$'buggy_file_path')]                                                             <- 'Script File'
df$'file_type'[grep('.json$|TrialResult.repr|.yaml$|.yml$', df$'buggy_file_path')]                             <- 'Data File'

# Aggregate data
df$'count' <- 1
agg_count <- aggregate(x=count ~ bug_id + bug_type + file_type, data=df, FUN=sum)

#
# As latex table
#

# Set and init tex file
output_tex_file <- paste0(OUTPUT_TABLES_DIR, '/distribution-of-buggy-files.tex')
unlink(output_tex_file)
sink(output_tex_file, append=FALSE, split=TRUE)

# Header
cat('\\begin{tabular}{@{\\extracolsep{\\fill}} l rrr rrr rr} \\toprule\n', sep='')
for (bug_type in unique(agg_count$'bug_type')) {
  cat(' & \\multicolumn{3}{c}{', bug_type, '}', sep='')
}
cat(' \\\\\n', sep='')
cat('Type', sep='')
for (bug_type in unique(agg_count$'bug_type')) {
  cat(' & Max & Min & Mean', sep='')
}
cat(" & \\textit{p}-value ($\\tilde{\\chi}^2$) & Cohen's d (magnitude) \\\\\n", sep='')
cat('\\midrule\n', sep='')

for (file_type in unique(agg_count$'file_type')) {
  file_type_mask <- agg_count$'file_type' == file_type
  cat(file_type, sep='')

  for (bug_type in unique(agg_count$'bug_type')) {
    bug_type_mask <- agg_count$'bug_type' == bug_type

    a <- agg_count[file_type_mask & bug_type_mask, ]

    max_value    <- '---'
    min_value    <- '---'
    mean_value   <- '---'
    ci_min_value <- '---'
    # ci_max_value <- '---'

    if (nrow(a) > 0) {
      max_value    <- sum(a$'count')
      min_value    <- min(a$'count')
      mean_value   <- sprintf('%.2f', round(mean(a$'count'), 2))
      # ci_values    <- get_ci(a$'count')
      # ci_min_value <- sprintf('%.2f', round(ci_values[1], 2))
      # ci_max_value <- sprintf('%.2f', round(ci_values[2], 2))
    }

    cat(' & ', max_value, sep='')
    cat(' & ', min_value, sep='')
    cat(' & ', mean_value, sep='')
    # cat(' & [', ci_min_value, ', ', ci_max_value, ']', sep='')
  }

  # Kruskal-Wallis non-parametric test
  x <- kruskal.test(bug_type ~ count, data=agg_count[file_type_mask, ])
  if (is.na(x$'statistic') || is.nan(x$'statistic')) {
    cat(' & ---', sep='')
  } else {
    cat(' & ', sprintf('%.2f', round(x$'p.value', 2)), ' (', sprintf('%.2f', round(x$'statistic', 2)), ')', sep='')
  }
  # Cohen's d effect size
  x <- cohen.d(agg_count$'count'[file_type_mask & agg_count$'bug_type' == 'Classical'], agg_count$'count'[file_type_mask & agg_count$'bug_type' == 'Quantum'], paired=FALSE, conf.level=0.95)
  if (is.na(x$'estimate') || is.nan(x$'estimate')) {
    cat(' & ---', sep='')
  } else {
    cat(' & ', sprintf('%.2f', round(x$'estimate', 2)), ' (', paste0(x$'magnitude'), ')', sep='')
  }

  cat(' \\\\', '\n', sep='')
}

# Table's footer
cat('\\bottomrule', '\n', sep='')
cat('\\end{tabular}', '\n', sep='')
sink()

#
# As boxplot
#

# Remove any existing output file and create a new one
output_pdf_file <- paste0(OUTPUT_FIGURES_DIR, '/distribution-of-buggy-files.pdf')
unlink(output_pdf_file)
pdf(file=output_pdf_file, family='Helvetica', width=7, height=4)
# Add a cover page to the output file
plot_label('Distributions of buggy files')

# Create plot
p <- ggplot(agg_count, aes(x=file_type, y=count, fill=bug_type))
p <- p + geom_boxplot(width=0.75, position=position_dodge(width=1))
# Rename legend title
p$labels$fill <- 'Bug type'
p$labels$colour <- 'Bug type'
# Change x axis label
p <- p + scale_x_discrete(name='')
# Change y axis label and scale
p <- p + scale_y_continuous(name='Number of occurrences (log2 scale)', trans='log2')
# Move legend's title to the top and increase size of [x-y]axis labels
p <- p + theme(legend.position='top',
               axis.text.x=element_text(size=10,  hjust=0.75, vjust=0.5),
               axis.text.y=element_text(size=10,  hjust=1.0, vjust=0.0),
               axis.title.x=element_text(size=12, hjust=0.5, vjust=0.0),
               axis.title.y=element_text(size=12, hjust=0.5, vjust=0.5)
)
# Make it horizontal
p <- p + coord_flip()
# Add mean points
p <- p + stat_summary(aes(shape=bug_type), fun=mean, geom='point', size=1.5, color='black', show.legend=TRUE, position=position_dodge(width=1))
p <- p + scale_shape_manual(name='', values=c(10, 12))
# Print it
print(p)

#
# As UpSetR plot
#

for (bug_type in unique(df$'bug_type')) {
  columns <- colnames(df)

  for (keep_order in c(TRUE, FALSE)) {
    plot_label(paste('UpSetR (agg by bug)', '\n', 'keep.order=', keep_order, '\n', bug_type, sep=''))
    a <- dcast(aggregate(x=. ~ bug_id + file_type, data=df[df$'bug_type' == bug_type, ], FUN=length),
               bug_id ~ file_type, value.var='file_type', fun.aggregate=length)
    a <- a[ , which(colnames(a) %!in% c('bug_id')) ]
    p <- upset(a, sets=colnames(a), order.by=c('freq'), nintersects=NA, keep.order=keep_order, set_size.show=TRUE,
               mb.ratio=c(0.40, 0.60), #point.size=3.5, line.size=1.1,
               # text.scale=c(intersection size title, intersection size tick labels, set size title, set size tick labels, set names, numbers above bars).
               text.scale=c(1, 1.2, 1, 1.2, 1.3, 1.1),
               set_size.scale_max=223, # max number of bugs
               mainbar.y.label='Intersection Size', sets.x.label='Set Size')
    print(p)
  }
}

# Close output file
dev.off()
# Embed fonts
embed_fonts_in_a_pdf(output_pdf_file)

# EOF
