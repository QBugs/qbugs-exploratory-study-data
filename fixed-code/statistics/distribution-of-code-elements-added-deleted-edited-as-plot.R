# ------------------------------------------------------------------------------
# This script plots the distribution of code elements deleted, added or edited by a bugfix commit as boxplot 
#
# Usage:
#   Rscript distribution-of-code-elements-added-deleted-edited-as-plot.R
#     <input data file, e.g., ../data/generated/fixed-code-data.csv>
#     <input data file, e.g., ../../buggy-code/data/generated/buggy-code-data.csv>
#     <output pdf file, e.g., distribution-of-code-elements-added-deleted-edited-as-plot.pdf>
# ------------------------------------------------------------------------------

source('../../utils/statistics/util.R')

# Load external packages
library('reshape2')
library('data.table')

# ------------------------------------------------------------------------- Args

args = commandArgs(trailingOnly=TRUE)
if (length(args) != 3) {
  stop('USAGE: Rscript distribution-of-code-elements-added-deleted-edited-as-plot.R <input data file, e.g., ../data/generated/fixed-code-data.csv> <input data file, e.g., ../../buggy-code/data/generated/buggy-code-data.csv> <output pdf file, e.g., distribution-of-code-elements-added-deleted-edited-as-plot.pdf>')
}

# Inputs
FIXED_CODE_DATA_FILE <- args[1]
BUGGY_CODE_DATA_FILE <- args[2]
# Output
OUTPUT_FILE          <- args[3]

# ---------------------------------------------------------------------- Utility

#
# Boxplot
#
boxplot_it <- function(df, label, facets=FALSE, fill=FALSE, yAxisLabel) {
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
  p <- p + scale_y_continuous(name= yAxisLabel, trans='log10')
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

# ------------------------------------------------------------------------- Main
# Load data
FixDf <- load_CSV(FIXED_CODE_DATA_FILE)
head(FixDf)

BuggyDf <- load_CSV(BUGGY_CODE_DATA_FILE)
head(BuggyDf)

# Check which edit actions are avaiable for each dataframe

print(unique(FixDf$'edit_action'))
print(unique(BuggyDf$'edit_action'))

# Rename code element column 
names(FixDf)[names(FixDf) == 'fixed_component']   <- 'buggy_component'

# Aggregate Fix data - Count number of edit actions per fix code element per bug_id and bug_type
FixDf$'count' <- 1
fix_agg_count <- aggregate(x=count ~ bug_id + bug_type + buggy_component + edit_action, data=FixDf, FUN=sum)
head(fix_agg_count)

# Aggregate Buggy data - Count number of edit actions per fix code element per bug_id and bug_type
BuggyDf$'count' <- 1
buggy_agg_count <- aggregate(x=count ~ bug_id + bug_type + buggy_component + edit_action, data=BuggyDf, FUN=sum)
head(buggy_agg_count)

# Select only M and U edit actions in each dataframe and proceed to sum them by bug_id and bug_type
move_update_fix_data <- fix_agg_count[fix_agg_count$'edit_action' == 'U' | fix_agg_count$'edit_action' == 'M' , ]
move_update_buggy_data <- buggy_agg_count[buggy_agg_count$'edit_action' == 'U' | buggy_agg_count$'edit_action' == 'M' , ]

mergeDf <- merge(x=move_update_fix_data, y=move_update_buggy_data, by=c('bug_id', 'bug_type', 'buggy_component','edit_action'), all.x=TRUE)
mergeDf$'count' <- mergeDf$'count.x' + mergeDf$'count.y'
print('Merging...')
head(mergeDf)

# Aggregate data- summing M+U operations by bug_id, bug_type and buggy_component

merge_agg_count <- aggregate(x=count ~ bug_id + bug_type + buggy_component, data=mergeDf, FUN=sum)
head(merge_agg_count)

# Remove any existing output file and create a new one
unlink(OUTPUT_FILE)
pdf(file=OUTPUT_FILE, family='Helvetica', width=10, height=10)
# Add a cover page to the output file
plot_label('Distributions')

boxplot_it(fix_agg_count[fix_agg_count$'edit_action' == 'A', ], 'Overall', facets=FALSE, fill=FALSE, 'Number of buggy components added(log10)')
boxplot_it(fix_agg_count[fix_agg_count$'edit_action' == 'A', ], 'Classical and Quantum bugs (same plot)', facets=FALSE, fill=TRUE, 'Number of code components added(log10)')
boxplot_it(fix_agg_count[fix_agg_count$'edit_action' == 'A', ], 'Classical and Quantum bugs (facets)', facets=TRUE, fill=FALSE, 'Number of code components added(log10)')
boxplot_it(fix_agg_count[fix_agg_count$'bug_type' == 'Classical' & fix_agg_count$'edit_action' == 'A' , ], 'Classical bugs', facets=FALSE, fill=FALSE, 'Number of code components added(log10)')
boxplot_it(fix_agg_count[fix_agg_count$'bug_type' == 'Quantum' & fix_agg_count$'edit_action' == 'A', ], 'Quantum bugs', facets=FALSE, fill=FALSE, 'Number of code components added(log10)')

boxplot_it(buggy_agg_count[buggy_agg_count$'edit_action' == 'D', ], 'Overall', facets=FALSE, fill=FALSE, 'Number of buggy components added(log10)')
boxplot_it(buggy_agg_count[buggy_agg_count$'edit_action' == 'D', ], 'Classical and Quantum bugs (same plot)', facets=FALSE, fill=TRUE, 'Number of code components deleted(log10)')
boxplot_it(buggy_agg_count[buggy_agg_count$'edit_action' == 'D', ], 'Classical and Quantum bugs (facets)', facets=TRUE, fill=FALSE, 'Number of code components deleted(log10)')
boxplot_it(buggy_agg_count[buggy_agg_count$'bug_type' == 'Classical' & buggy_agg_count$'edit_action' == 'D' , ], 'Classical bugs', facets=FALSE, fill=FALSE, 'Number of code components deleted(log10)')
boxplot_it(buggy_agg_count[buggy_agg_count$'bug_type' == 'Quantum' & buggy_agg_count$'edit_action' == 'D', ], 'Quantum bugs', facets=FALSE, fill=FALSE, 'Number of code components deleted(log10)')


boxplot_it(merge_agg_count, 'Overall', facets=FALSE, fill=FALSE, 'Number of buggy components edited(log10)')
boxplot_it(merge_agg_count, 'Classical and Quantum bugs (same plot)', facets=FALSE, fill=TRUE, 'Number of code components edited(log10)')
boxplot_it(merge_agg_count, 'Classical and Quantum bugs (facets)', facets=TRUE, fill=FALSE, 'Number of code components edited(log10)')
boxplot_it(merge_agg_count[merge_agg_count$'bug_type' == 'Classical' , ], 'Classical bugs', facets=FALSE, fill=FALSE, 'Number of code components edited(log10)')
boxplot_it(merge_agg_count[merge_agg_count$'bug_type' == 'Quantum' , ], 'Quantum bugs', facets=FALSE, fill=FALSE, 'Number of code components edited(log10)')




