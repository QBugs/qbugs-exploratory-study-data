# ------------------------------------------------------------------------------
# This script plots the distribution of buggy components' lifetime as boxplot.
#
# Usage:
#   Rscript distribution-of-buggy-components-lifetime-as-plot.R
#     <buggy components input data file, e.g., ../data/generated/buggy-code-data.csv>
#     <bug reports input data file, e.g., ../data/issues-data.csv>
#     <output pdf file, e.g., distribution-of-buggy-components-lifetime-as-plot.pdf>
# ------------------------------------------------------------------------------

source('../../utils/statistics/util.R')

# Load external packages
library('ggplot2')
library('reshape2')

# ------------------------------------------------------------------------- Args

args = commandArgs(trailingOnly=TRUE)
if (length(args) != 3) {
  stop('USAGE: Rscript distribution-of-buggy-components-lifetime-as-plot.R <buggy components input data file, e.g., ../data/generated/buggy-code-data.csv> <bug reports input data file, e.g., ../data/issues-data.csv> <output pdf file, e.g., distribution-of-buggy-components-lifetime-as-plot.pdf>')
}

# Args
BUGGY_COMPONENTS_INPUT_FILE <- args[1]
BUG_REPORTS_INPUT_FILE      <- args[2]
OUTPUT_FILE                 <- args[3]

# ------------------------------------------------------------------------- Main

# Load data
df <- load_CSV(BUGGY_COMPONENTS_INPUT_FILE)
df_bug_reports <- load_CSV(BUG_REPORTS_INPUT_FILE)

df <- merge(df, df_bug_reports)
df$'seconds' <- df$'fix_timestamp' - df$'issue_timestamp'
stopifnot(min(df$'seconds') > 0) # Runtime sanity check
df$'minutes' <- df$'seconds' / 60
df$'hours'   <- df$'minutes' / 60
df$'days'    <- df$'hours'   / 24

# Remove any existing output file and create a new one
unlink(OUTPUT_FILE)
pdf(file=OUTPUT_FILE, family='Helvetica', width=10, height=9)
# Add a cover page to the output file
plot_label('Distributions')

#
# As boxplot
#

boxplot_it <- function(df, yaxis='', label='', facets=FALSE, fill=FALSE) {
  # Identify plot
  plot_label(label)
  # Basic boxplot
  if (fill) {
    p <- ggplot(df, aes_string(x='buggy_component', y=yaxis, fill='bug_type'))
  } else {
    p <- ggplot(df, aes_string(x='buggy_component', y=yaxis))
  }
  p <- p + geom_boxplot(width=0.75, position=position_dodge(width=1))
  # Change x axis label
  p <- p + scale_x_discrete(name='')
  # Change y axis label
  p <- p + scale_y_continuous(name=paste(yaxis, ' (log2)', sep=''), trans='log2')
  # Use grey scale color palette
  if (fill) {
    p <- p + scale_fill_manual(name='Bug type', values=c('#989898', '#cccccc'))
  }
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
  if (fill) {
    p <- p + stat_summary(aes(shape=bug_type), fun=mean, geom='point', size=1.5, color='black', show.legend=TRUE, position=position_dodge(width=1))
    p <- p + scale_shape_manual(name='', values=c(10, 12))
  } else {
    p <- p + stat_summary(fun=mean, geom='point', shape=8, size=2, fill='black', color='black')
  }
  # Create facets, one per type of bug
  if (facets) {
    p <- p + facet_grid(~ bug_type)
  }
  # Print it
  print(p)
}

for (yaxis in c('seconds', 'minutes', 'hours', 'days')) {
  boxplot_it(df, yaxis, 'Overall', facets=FALSE, fill=FALSE)
  boxplot_it(df, yaxis, paste('Classical and Quantum bugs (same plot)', '\n', yaxis, sep=''), facets=FALSE, fill=TRUE)
  boxplot_it(df, yaxis, paste('Classical and Quantum bugs (facets)', '\n', yaxis, sep=''), facets=TRUE, fill=FALSE)
  boxplot_it(df[df$'bug_type' == 'Classical', ], yaxis, paste('Classical bugs', '\n', yaxis, sep=''), facets=FALSE, fill=FALSE)
  boxplot_it(df[df$'bug_type' == 'Quantum', ], yaxis, paste('Quantum bugs', '\n', yaxis, sep=''), facets=FALSE, fill=FALSE)
}

# Close output file
dev.off()
# Embed fonts
embed_fonts_in_a_pdf(OUTPUT_FILE)

# EOF
