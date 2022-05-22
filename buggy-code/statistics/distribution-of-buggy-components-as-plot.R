# ------------------------------------------------------------------------------
# This script plots the distribution of buggy components as boxplot, barplot, and
# UpSetR plot.
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
library('UpSetR')
library('nortest')
library('effsize')

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
agg_count <- aggregate(x=count ~ project_full_name + bug_id + bug_type + buggy_component, data=df, FUN=sum)

# Remove any existing output file and create a new one
unlink(OUTPUT_FILE)
pdf(file=OUTPUT_FILE, family='Helvetica', width=10, height=10)
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

#
# As UpSetR plot
#

for (bug_type in unique(df$'bug_type')) {
  columns <- colnames(df)

  for (keep_order in c(TRUE, FALSE)) {
    plot_label(paste('UpSetR (overall)', '\n', 'keep.order=', keep_order, '\n', bug_type, sep=''))
    a <- dcast(df[df$'bug_type' == bug_type, ], ... ~ buggy_component, value.var='buggy_component', fun.aggregate=length)
    a <- a[ , which(colnames(a) %!in% columns) ]
    p <- upset(a, sets=colnames(a), order.by=c('freq'), nintersects=50, keep.order=keep_order, set_size.show=TRUE,
               mb.ratio=c(0.40, 0.60), #point.size=3.5, line.size=1.1,
               # text.scale=c(intersection size title, intersection size tick labels, set size title, set size tick labels, set names, numbers above bars).
               text.scale=c(1, 1.2, 1, 1.2, 1.3, 1.1),
               set_size.scale_max=2500,
               mainbar.y.label='Intersection Size', sets.x.label='Set Size')
    print(p)

    plot_label(paste('UpSetR (agg by bug)', '\n', 'keep.order=', keep_order, '\n', bug_type, sep=''))
    a <- dcast(aggregate(x=. ~ bug_id + buggy_component, data=df[df$'bug_type' == bug_type, ], FUN=length),
               bug_id ~ buggy_component, value.var='buggy_component', fun.aggregate=length)
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

#
# Perform statistical analysis
#

plot_label('Statistical analysis')

# Check for normality, as histogram plots
plot_label('Check for normality, as histogram plots')
plot_label('Histogram (overall)')
ggplot(agg_count, aes(x=count)) + geom_histogram()
hist(agg_count$'count', breaks=100)
plot_label('Histogram (per bug type)')
ggplot(agg_count, aes(x=count))+ geom_histogram() + facet_grid(bug_type ~ .)
hist(agg_count$'count'[agg_count$'bug_type' == 'Classical'], breaks=100)
hist(agg_count$'count'[agg_count$'bug_type' == 'Quantum'], breaks=100)

# Check for normality, as Quantile-Quantile plots
plot_label('Check for normality, as Quantile-Quantile plots')
plot_label('Quantile-Quantile (overall)')
qqnorm(agg_count$'count')
qqline(agg_count$'count', col='red')
plot_label('Quantile-Quantile (classical)')
qqnorm(agg_count$'count'[agg_count$'bug_type' == 'Classical'])
qqline(agg_count$'count'[agg_count$'bug_type' == 'Classical'], col='red')
plot_label('Quantile-Quantile (quantum)')
qqnorm(agg_count$'count'[agg_count$'bug_type' == 'Quantum'])
qqline(agg_count$'count'[agg_count$'bug_type' == 'Quantum'], col='red')

# Check for normality, as Shapiro-Wilk's test
plot_label('Check for normality, as Shapiro-Wilk test')

x <- shapiro.test(agg_count$'count')
plot_label(paste(
  'Shapiro-Wilk test (overall)',
  '\n', 'p-value: ', x$'p.value',
  '\n', 'w: ', x$'statistic',
  sep=''))

x <- shapiro.test(agg_count$'count'[agg_count$'bug_type' == 'Classical'])
plot_label(paste(
  'Shapiro-Wilk test (classical)',
  '\n', 'p-value: ', x$'p.value',
  '\n', 'w: ', x$'statistic',
  sep=''))

x <- shapiro.test(agg_count$'count'[agg_count$'bug_type' == 'Quantum'])
plot_label(paste(
  'Shapiro-Wilk test (quantum)',
  '\n', 'p-value: ', x$'p.value',
  '\n', 'w: ', x$'statistic',
  sep=''))

# Check for normality, as Anderson-Darling's test
plot_label('Check for normality, as Anderson-Darling test')

x <- ad.test(agg_count$'count')
plot_label(paste(
  'Anderson-Darling test (overall)',
  '\n', 'p-value: ', x$'p.value',
  '\n', 'w: ', x$'statistic',
  sep=''))

x <- ad.test(agg_count$'count'[agg_count$'bug_type' == 'Classical'])
plot_label(paste(
  'Anderson-Darling test (classical)',
  '\n', 'p-value: ', x$'p.value',
  '\n', 'w: ', x$'statistic',
  sep=''))

x <- ad.test(agg_count$'count'[agg_count$'bug_type' == 'Quantum'])
plot_label(paste(
  'Anderson-Darling test (quantum)',
  '\n', 'p-value: ', x$'p.value',
  '\n', 'w: ', x$'statistic',
  sep=''))

# Kruskal-Wallis non-parametric test
x <- kruskal.test(bug_type ~ count, data=agg_count)
plot_label(paste(
  'Kruskal-Wallis non-parametric test (overall)',
  '\n', 'p-value: ', x$'p.value',
  '\n', 'df: ', x$'parameter',
  '\n', 'chi-squared: ', x$'statistic',
  sep=''))

# Cohen's d effect size
x <- cohen.d(agg_count$'count'[agg_count$'bug_type' == 'Classical'], agg_count$'count'[agg_count$'bug_type' == 'Quantum'], paired=FALSE, conf.level=0.99)
plot_label(paste(
  'Cohen\'s d effect size',
  '\n', 'estimate: ', x$'estimate',
  '\n', 'magnitude: ', x$'magnitude',
  '\n', 'conf.int (lower): ', x$'conf.int'[1],
  '\n', 'conf.int (upper): ', x$'conf.int'[2],
  '\n', 'conf.level: ', x$'conf.level',
  sep=''))

x <- kruskal.test(buggy_component ~ count, data=agg_count[agg_count$'bug_type' == 'Classical', ])
plot_label(paste(
  'Kruskal-Wallis non-parametric test (classical)',
  '\n', 'p-value: ', x$'p.value',
  '\n', 'df: ', x$'parameter',
  '\n', 'chi-squared: ', x$'statistic',
  sep=''))

x <- kruskal.test(buggy_component ~ count, data=agg_count[agg_count$'bug_type' == 'Quantum', ])
plot_label(paste(
  'Kruskal-Wallis non-parametric test (quantum)',
  '\n', 'p-value: ', x$'p.value',
  '\n', 'df: ', x$'parameter',
  '\n', 'chi-squared: ', x$'statistic',
  sep=''))

# Close output file
dev.off()
# Embed fonts
embed_fonts_in_a_pdf(OUTPUT_FILE)

# EOF
