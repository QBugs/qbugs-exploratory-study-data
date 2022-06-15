# ------------------------------------------------------------------------------
# This script plots the distribution test cases updated by a bugfix commit as well as the total number of bugs with 0, 1 and >1 test cases
#
# Usage:
#   Rscript distribution-of-test-cases-as-plot.R
#     <input data file, e.g., ../data/number-test-cases.csv>
#     <output pdf file, e.g., distribution-of-test-cases-as-plot.pdf>
# ------------------------------------------------------------------------------

source('../../utils/statistics/util.R')

# Load external packages
library('reshape2')
library('data.table')
library('sqldf')
library('plyr')

# ------------------------------------------------------------------------- Args

args = commandArgs(trailingOnly=TRUE)
if (length(args) != 2) {
  stop('USAGE:  distribution-of-test-cases-as-plot.R <input data file, e.g., ../data/number-test-cases.csv> <output pdf file, e.g., distribution-of-test-cases-as-plot.pdf>')
}

# Inputs
TEST_CASES_DATA_FILE <- args[1]
# Output
OUTPUT_FILE          <- args[2]

# ---------------------------------------------------------------------- Utility

#
# Boxplot
#

boxplot_it <- function(df, label, facets=FALSE, fill=FALSE) {
  # Identify plot
  plot_label(label)
  # Basic boxplot
  if (fill) {
    p <- ggplot(df, aes(x=bug_type, y=number_test_cases, fill=bug_type))
  } else {
    p <- ggplot(df, aes(x=bug_type, y=number_test_cases))
  }
  p <- p + geom_boxplot(width=0.75, position=position_dodge(width=1))
  # Change x axis label
  p <- p + scale_x_discrete(name='')
  # Change y axis label
  p <- p + scale_y_continuous(name='Test Case Distribution')
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

#
# Boxplot for project
#

boxplot_it_2 <- function(df, label, facets=FALSE, fill=FALSE) {
  # Identify plot
  plot_label(label)
  # Basic boxplot
  if (fill) {
    p <- ggplot(df, aes(x=project_full_name, y=number_test_cases, fill=bug_type))
  } else {
    p <- ggplot(df, aes(x=project_full_name, y=number_test_cases))
  }
  p <- p + geom_boxplot(width=0.75, position=position_dodge(width=1))
  # Change x axis label
  p <- p + scale_x_discrete(name='')
  # Change y axis label
  p <- p + scale_y_continuous(name='Test Case Distribution')
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
CasesDf <- load_CSV(TEST_CASES_DATA_FILE)
head(CasesDf)

cat('[INFO] Plotting test case distribution \n')

# Remove any existing output file and create a new one
unlink(OUTPUT_FILE)
pdf(file=OUTPUT_FILE, family='Helvetica', width=10, height=10)
# Add a cover page to the output file
plot_label('Distributions')

boxplot_it(CasesDf, 'Classical and Quantum bugs', facets=FALSE, fill=FALSE)
boxplot_it(CasesDf, 'Classical and Quantum bugs (same plot)', facets=FALSE, fill=TRUE)
boxplot_it(CasesDf, 'Classical and Quantum bugs (facets)', facets=TRUE, fill=FALSE)

boxplot_it_2(CasesDf, 'Overall', facets=FALSE, fill=FALSE)
boxplot_it_2(CasesDf, 'Classical and Quantum bugs (same plot)', facets=FALSE, fill=TRUE)
boxplot_it_2(CasesDf, 'Classical and Quantum bugs (facets)', facets=TRUE, fill=FALSE)
boxplot_it_2(CasesDf[CasesDf$'bug_type' == 'Classical' , ], 'Classical bugs', facets=FALSE, fill=FALSE)
boxplot_it_2(CasesDf[CasesDf$'bug_type' == 'Quantum' , ], 'Quantum bugs', facets=FALSE, fill=FALSE)

cat('[INFO] Computing number of bugs whose test cases are 0, 1 and >1\n')

Zero <- nrow(CasesDf[CasesDf$number_test_cases == 0,]['number_test_cases'])
One <- nrow(CasesDf[CasesDf$number_test_cases == 1,]['number_test_cases'])
HigherThanOne <- nrow(CasesDf[CasesDf$number_test_cases > 1 ,]['number_test_cases'])

tmpDf <- dat <- cbind(Zero,One,HigherThanOne)

head(tmpDf)


