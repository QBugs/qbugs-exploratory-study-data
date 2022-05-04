# ------------------------------------------------------------------------------
# This script plots the distribution of buggy components' lifetime as boxplot.
#
# Usage:
#   Rscript distribution-of-buggy-components-lifetime-as-plot.R
#     <input data file, e.g., ../data/generated/buggy-code-lifetime-data.csv>
#     <output pdf file, e.g., distribution-of-buggy-components-lifetime-as-plot.pdf>
# ------------------------------------------------------------------------------

source('../../utils/statistics/util.R')

# Load external packages
library('ggplot2')
library('reshape2')

# ------------------------------------------------------------------------- Args

args = commandArgs(trailingOnly=TRUE)
if (length(args) != 2) {
  stop('USAGE: Rscript distribution-of-buggy-components-lifetime-as-plot.R <input data file, e.g., ../data/generated/buggy-code-lifetime-data.csv> <output pdf file, e.g., distribution-of-buggy-components-lifetime-as-plot.pdf>')
}

# Args
INPUT_FILE  <- args[1]
OUTPUT_FILE <- args[2]

# ------------------------------------------------------------------------- Main

# Load data
df <- load_CSV(INPUT_FILE)

#
# Pre-process data, i.e., compute
#  * number of different authors that modified each buggy component on each buggy line
#  * number of times each buggy component has been modified
#  * seconds between the buggy and fixed version
#
# TODO: I am certain there might be a better way to achieve the following using
# aggregate and filters.
df_proc <- data.frame()
for (bug_id in unique(df$'bug_id')) {
  bug_id_mask <- df$'bug_id' == bug_id

  for (bug_type in unique(df$'bug_type'[bug_id_mask])) {
    bug_type_mask <- df$'bug_type' == bug_type

    for (buggy_file_path in unique(df$'buggy_file_path'[bug_id_mask & bug_type_mask])) {
      buggy_file_path_mask <- df$'buggy_file_path' == buggy_file_path

      for (buggy_line_number in unique(df$'buggy_line_number'[bug_id_mask & bug_type_mask & buggy_file_path_mask])) {
        buggy_line_number_mask <- df$'buggy_line_number' == buggy_line_number

        for (buggy_component in unique(df$'buggy_component'[bug_id_mask & bug_type_mask & buggy_file_path_mask & buggy_line_number_mask])) {
          buggy_component_mask <- df$'buggy_component' == buggy_component

          x <- df[bug_id_mask & bug_type_mask & buggy_file_path_mask & buggy_line_number_mask & buggy_component_mask, ]
          stopifnot(nrow(x) >= 2)

          row <- data.frame(
            bug_id=bug_id,
            bug_type=bug_type,
            # buggy_file_path=buggy_file_path,
            # buggy_line_number=buggy_line_number,
            buggy_component=buggy_component,
            number_of_authors=length(unique(x$'author_name')),
            number_of_modifications=nrow(x),
            time_to_fix=ceiling((x$'author_commit_date'[1] - x$'author_commit_date'[2]) / 3600.0)
          )
          df_proc <- rbind(df_proc, row)
        }
      }
    }
  }
}

agg_mean <- aggregate(x=. ~ bug_id + bug_type + buggy_component, data=df_proc, FUN=mean)
print(head(agg_mean)) # Debug

# Reshape data
agg_mean_long <- melt(data=agg_mean,
                      id.vars=c('bug_id', 'bug_type', 'buggy_component'),
                      variable.name='var',
                      value.name='value')
# Convert vars column to character so it could be renamed without the known
# "invalid factor level, NA generated" error
agg_mean_long$'var' <- as.character(agg_mean_long$'var')
# Pretty print vars
agg_mean_long$'var'[agg_mean_long$'var' == 'number_of_authors'] <- '# Authors'
agg_mean_long$'var'[agg_mean_long$'var' == 'number_of_modifications'] <- '# Modifications'
agg_mean_long$'var'[agg_mean_long$'var' == 'time_to_fix'] <- 'Time to fix (hours)'
# Make vars factors
agg_mean_long$'var' <- as.factor(agg_mean_long$'var')

print(head(agg_mean_long)) # Debug

# Remove any existing output file and create a new one
unlink(OUTPUT_FILE)
pdf(file=OUTPUT_FILE, family='Helvetica', width=10, height=9)
# Add a cover page to the output file
plot_label('Distributions')

#
# As boxplot
#

boxplot_it <- function(df, label='', fill=FALSE) {
  # Identify plot
  plot_label(label)
  # Basic boxplot
  if (fill) {
    p <- ggplot(df, aes(x=buggy_component, y=value, fill=bug_type))
  } else {
    p <- ggplot(df, aes(x=buggy_component, y=value))
  }
  p <- p + geom_boxplot(width=0.75, position=position_dodge(width=1))
  # Change x axis label
  p <- p + scale_x_discrete(name='')
  # Change y axis label
  p <- p + scale_y_continuous(name='(log2)', trans='log2')
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
  # p <- p + stat_summary(fun=mean, geom='point', shape=8, size=2, fill='black', color='black')
  # Create facets, one per variable (i.e., number_of_authors, number_of_modifications, time_to_fix)
  p <- p + facet_grid(~ var, scales='free_x')
  # Print it
  print(p)
}

boxplot_it(agg_mean_long, 'Overall', fill=FALSE)
boxplot_it(agg_mean_long, 'Overall (per bug type)', fill=TRUE)
boxplot_it(agg_mean_long[agg_mean_long$'bug_type' == 'Classical', ], 'Classical bugs', fill=FALSE)
boxplot_it(agg_mean_long[agg_mean_long$'bug_type' == 'Quantum', ], 'Quantum bugs', fill=FALSE)

# Close output file
dev.off()
# Embed fonts
embed_fonts_in_a_pdf(OUTPUT_FILE)

# EOF
