# ------------------------------------------------------------------------------
# This script plots the distribution of buggy components as boxplot.
#
# Usage:
#   Rscript distribution-of-buggy-components-as-plot.R
#     <input data file, e.g., ../data/generated/buggy-code-data.csv>
#     <output pdf file, e.g., distribution-of-buggy-components-as-plot.pdf>
# ------------------------------------------------------------------------------

source('../../utils/statistics/util.R')

# Load external packages
library('ggplot2')
library('reshape2')

# ------------------------------------------------------------------------- Args

args = commandArgs(trailingOnly=TRUE)
if (length(args) != 2) {
  stop('USAGE: Rscript distribution-of-buggy-components-as-plot.R <input data file, e.g., ../data/generated/buggy-code-data.csv> <output pdf file, e.g., distribution-of-buggy-components-as-plot.pdf>')
}

# Args
INPUT_FILE  <- args[1]
OUTPUT_FILE <- args[2]

# ------------------------------------------------------------------------- Main

# Load data
df <- load_CSV(INPUT_FILE)

# Aggregate data
df$'count' <- 1
agg_count <- aggregate(formula=count ~ project_full_name + bug_id + bug_type + buggy_component, data=df, FUN=sum)

# Remove any existing output file and create a new one
unlink(OUTPUT_FILE)
pdf(file=OUTPUT_FILE, family='Helvetica', width=10, height=9)
# Add a cover page to the output file
plot_label('Distributions')

#
# As boxplot
#

boxplot_it <- function(df, label, facets=FALSE, fill=FALSE) {
  # Identify plot
  plot_label(label)
  # Basic boxplot
  if (fill) {
    p <- ggplot(df, aes(x=buggy_component, y=count, fill=bug_type))
  } else {
    p <- ggplot(df, aes(x=buggy_component, y=count))
  }
  p <- p + geom_boxplot(width=0.75, position=position_dodge(width=1))
  # Change x axis label
  p <- p + scale_x_discrete(name='')
  # Change y axis label
  p <- p + scale_y_continuous(name='# Occurrences (log10)', trans='log10')
  # Use grey scale color palette
  if (fill) {
    p <- p + scale_fill_manual(name='Bug type', values=c('#989898', '#cccccc'))
  }
  # Remove legend's title and increase size of [x-y]axis labels
  p <- p + theme(legend.position='top',
    axis.text.x=element_text(size=10,  hjust=0.75, vjust=0.5),
    axis.text.y=element_text(size=10,  hjust=1.0, vjust=0.0),
    axis.title.x=element_text(size=12, hjust=0.5, vjust=0.0),
    axis.title.y=element_text(size=12, hjust=0.5, vjust=0.5)
  )
  # Make it horizontal
  p <- p + coord_flip()
  # Add mean points
  # p <- p + stat_summary(fun=mean, geom='point', shape=8, size=2, fill='black', color='black')
  # Create facets, one per type of bug
  if (facets) {
    p <- p + facet_grid(~ bug_type)
  }
  # Print it
  print(p)
}

boxplot_it(agg_count, 'Overall', facets=FALSE, fill=FALSE)
boxplot_it(agg_count, 'Classical and Quantum bugs (same plot)', facets=FALSE, fill=TRUE)
boxplot_it(agg_count, 'Classical and Quantum bugs (facets)', facets=TRUE, fill=FALSE)
boxplot_it(agg_count[agg_count$'bug_type' == 'Classical', ], 'Classical bugs', facets=FALSE, fill=FALSE)
boxplot_it(agg_count[agg_count$'bug_type' == 'Quantum', ], 'Quantum bugs', facets=FALSE, fill=FALSE)

#
# As barplot
#

plot_label('Classical and Quantum bugs (same plot) as a barplot')
p <- ggplot(df, aes(x=buggy_component, fill=bug_type)) + geom_bar(position=position_dodge(width=1))
# Change x axis label
p <- p + scale_x_discrete(name='')
# Change y axis label
p <- p + scale_y_continuous(name='# Occurrences (log10)', trans='log10')
# Use grey scale color palette
p <- p + scale_fill_manual(name='Bug type', values=c('#989898', '#cccccc'))
# Put legend's title on top and increase size of [x-y]axis labels
p <- p + theme(legend.position='top',
  axis.text.x=element_text(size=10,  hjust=0.75, vjust=0.5),
  axis.text.y=element_text(size=10,  hjust=1.0, vjust=0.0),
  axis.title.x=element_text(size=12, hjust=0.5, vjust=0.0),
  axis.title.y=element_text(size=12, hjust=0.5, vjust=0.5)
)
# Add labels over bars
p <- p + stat_count(geom='text', colour='black', size=3, aes(label=..count..), position=position_dodge(width=1.1), hjust=-0.15)
# Make it horizontal
p <- p + coord_flip()
# Print it
print(p)

# Close output file
dev.off()
# Embed fonts
embed_fonts_in_a_pdf(OUTPUT_FILE)

# EOF
