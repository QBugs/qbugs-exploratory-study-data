# ------------------------------------------------------------------------------
# This script plots the distribution of code smells as plot
# Usage:
#   Rscript code-smells-buggy-version-as-plot.R
#     <input data file, e.g., ../data/generated/code-smell-metrics-for-buggy-data.csv>
#     <output pdf file, e.g., code-smells-buggy-version-as-plot.pdf>
# ------------------------------------------------------------------------------

source('../../utils/statistics/util.R')

# Load external packages
library('ggplot2')
library('reshape2')
library('UpSetR')
library('nortest')
library('effsize')
library('dplyr')


# ------------------------------------------------------------------------- Args

args = commandArgs(trailingOnly=TRUE)
if (length(args) != 2) {
  stop('USAGE: Rscript code-smells-buggy-version-as-plot.R <input data file, e.g., ../data/generated/code-smell-metrics-for-buggy-data.csv> <output pdf file, e.g., code-smells-buggy-version-as-plot.pdf>')
}

# Args
BUGGY_CODE_SMELLS <- args[1]
OUTPUT_FILE <- args[2]

# ------------------------------------------------------------------------- Main

# Load data
buggy_df <- load_CSV(BUGGY_CODE_SMELLS)
head(buggy_df)

## Filter data by metric values above the ones proposed in pysmell paper
tmp_df <- buggy_df[(buggy_df$code_smell_metric == 'PAR' & buggy_df$code_smell_metric_value >= 5) | (buggy_df$code_smell_metric == 'MLOC' & buggy_df$code_smell_metric_value >= 100) | (buggy_df$code_smell_metric == 'DOC' & buggy_df$code_smell_metric_value >= 3) | (buggy_df$code_smell_metric == 'NBC' & buggy_df$code_smell_metric_value >= 3) | (buggy_df$code_smell_metric == 'CLOC' & buggy_df$code_smell_metric_value >= 200) | (buggy_df$code_smell_metric == 'LMC' & buggy_df$code_smell_metric_value >= 4) | (buggy_df$code_smell_metric == 'NOC' & buggy_df$code_smell_metric_value >= 80) | (buggy_df$code_smell_metric == 'NOO' & buggy_df$code_smell_metric_value >= 6) | (buggy_df$code_smell_metric == 'TNOC' & buggy_df$code_smell_metric_value >= 46) | (buggy_df$code_smell_metric == 'LPAR' & buggy_df$code_smell_metric_value >= 1) | (buggy_df$code_smell_metric == 'TNOL' & buggy_df$code_smell_metric_value >= 1) | (buggy_df$code_smell_metric == 'CNOC' & buggy_df$code_smell_metric_value >= 49) | (buggy_df$code_smell_metric == 'NOFF' & buggy_df$code_smell_metric_value >= 1) | (buggy_df$code_smell_metric == 'CNOO' & buggy_df$code_smell_metric_value >= 10) | (buggy_df$code_smell_metric == 'LEC' & buggy_df$code_smell_metric_value >= 3) | (buggy_df$code_smell_metric == 'DNC' & buggy_df$code_smell_metric_value >= 2) | (buggy_df$code_smell_metric == 'NCT' & buggy_df$code_smell_metric_value >= 1)  , ]

## calculate corresponding code smell
compute_code_smell <- function(x) {
  result = switch(  
    x,  
    "PAR"= 'Long Parameter List',   
    "MLOC"= 'Long Method',   
    "DOC"= 'Long Scope Chaining',   
    "NBC"= 'Long Base Class List',
    "CLOC"= 'Large Class', 
    "LMC"= 'Long Message Chain',
    "NOC"= 'Long Ternary Conditional Expression',
    "NOO"= 'NA',
    "TNOC"= 'NA',
    "LPAR"= 'NA',
    "TNOL"= 'NA',
    "CNOC"= 'NA',
    "NOFF"= 'NA',
    "CNOO"= 'NA',
    "LEC"= 'Long Element Chain',
    "DNC"= 'NA',
    "NCT"= 'NA',
    
  )
  
  return(result)
}

for (row in 1:nrow(tmp_df)) { 
  tmp_df$'code_smell'[row] <- compute_code_smell(tmp_df$'code_smell_metric'[row]) 
}

### Filtering rows without code smells
code_smell_df <- tmp_df[tmp_df$code_smell != 'NA' , ]

head(code_smell_df)

# Remove any existing output file and create a new one
unlink(OUTPUT_FILE)
pdf(file=OUTPUT_FILE, family='Helvetica', width=7, height=4)
# Add a cover page to the output file
plot_label('Distributions')

# Aggregate data
code_smell_df$'count' <- 1
agg_count <- aggregate(x=count ~ project_full_name + bug_id + bug_type + code_smell, data=code_smell_df, FUN=sum)

#
# As boxplot
#

boxplot_it <- function(df, label, facets=FALSE, fill=FALSE) {
  # Identify plot
  plot_label(label)
  # Basic boxplot
  if (fill) {
    p <- ggplot(df, aes(x=code_smell, y=count, fill=bug_type))
  } else {
    p <- ggplot(df, aes(x=code_smell, y=count))
  }
  p <- p + geom_boxplot(width=0.75, position=position_dodge(width=1))
  # Change x axis label
  p <- p + scale_x_discrete(name='')
  # Change y axis label
  p <- p + scale_y_continuous(name='# Repair Action Occurrences')
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

boxplot_it(agg_count, 'Overall', facets=FALSE, fill=FALSE)
boxplot_it(agg_count, 'Classical and Quantum bugs (same plot)', facets=FALSE, fill=TRUE)
boxplot_it(agg_count, 'Classical and Quantum bugs (facets)', facets=TRUE, fill=FALSE)

### As Barplot

plot_label('Number of occurrences of each smell as a barplot')
p <- ggplot(code_smell_df, aes(x=code_smell, fill=bug_type)) + geom_bar(position=position_dodge(width=1))
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

plot_label('Number of occurrences of each component as a barplot')
p <- ggplot(code_smell_df, aes(x=code_smell, fill=bug_type)) + geom_bar(position=position_dodge(width=1))
# Change x axis label
p <- p + scale_x_discrete(name='')
# Change y axis label
p <- p + scale_y_continuous(name='# Occurrences (log10)', trans='log10')
# Use grey scale color palette
p <- p + scale_fill_manual(name='Bug type', values=c('#989898', '#cccccc'))
# Put legend's title on top and increase size of [x-y]axis labels
p <- p + theme(legend.position='top',
               axis.text.x=element_text(size=6,  hjust=0.75, vjust=0.5),
               axis.text.y=element_text(size=6,  hjust=1.0, vjust=0.0),
               axis.title.x=element_text(size=8, hjust=0.5, vjust=0.0),
               axis.title.y=element_text(size=8, hjust=0.5, vjust=0.5)
)
# Add labels over bars
p <- p + stat_count(geom='text', colour='black', size=3, aes(label=..count..), position=position_dodge(width=1.1), hjust=-0.15)
# Make it horizontal
p <- p + coord_flip()
# Print it
print(p)

plot_label('Number of bugs in which each component appears as a barplot')
p <- ggplot(aggregate(x=. ~ bug_id + bug_type + code_smell, data=code_smell_df, FUN=length), aes(x=code_smell, fill=bug_type)) + geom_bar(position=position_dodge(width=1))
# Change x axis label
p <- p + scale_x_discrete(name='')
# Change y axis label
p <- p + scale_y_continuous(name='# Bugs')
# Use grey scale color palette
p <- p + scale_fill_manual(name='Bug type', values=c('#989898', '#cccccc'))
# Put legend's title on top and increase size of [x-y]axis labels
p <- p + theme(legend.position='top',
               axis.text.x=element_text(size=6,  hjust=0.75, vjust=0.5),
               axis.text.y=element_text(size=6,  hjust=1.0, vjust=0.0),
               axis.title.x=element_text(size=8, hjust=0.5, vjust=0.0),
               axis.title.y=element_text(size=8, hjust=0.5, vjust=0.5)
)
# Add labels over bars
p <- p + stat_count(geom='text', colour='black', size=3, aes(label=..count..), position=position_dodge(width=1.1), hjust=-0.15)
# Make it horizontal
p <- p + coord_flip()
# Print it
print(p)