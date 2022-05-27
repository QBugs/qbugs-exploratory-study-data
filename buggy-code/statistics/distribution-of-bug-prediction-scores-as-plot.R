# ------------------------------------------------------------------------------
# This script plots the distribution of buggy prediction scores as boxplot and reports the ranking stats for each buggy component in a csv file
#
# Usage:
#   Rscript distribution-of-bug-prediction-scores-as-plot.R
#     <input data file, e.g., ../data/generated/code-lifetime-data.csv.gz>
#     <input data file, e.g., ../data/generated/buggy-code-data.csv>
#     <output pdf file, e.g., distribution-of-bug-prediction-scores-as-plot.pdf>
# ------------------------------------------------------------------------------

source('../../utils/statistics/util.R')

# Load external packages
library('reshape2')
library('data.table')

# ------------------------------------------------------------------------- Args

args = commandArgs(trailingOnly=TRUE)
if (length(args) != 3) {
  stop('USAGE: Rscript distribution-of-bug-prediction-scores-as-plot.R <input data file, e.g., ../data/generated/code-lifetime-data.csv.gz> <input data file, e.g., ../data/generated/buggy-code-data.csv> <output pdf file, e.g., distribution-of-bug-prediction-scores-as-plot.pdf>')
}

# Inputs
CODE_LIFETIME_DATA_FILE <- args[1]
BUGGY_CODE_DATA_FILE    <- args[2]
# Output
OUTPUT_FILE             <- args[3]

# -------------------------------------------------------------------- Constants

# Constant values suggested in the research paper
# [An Empirical Study on the Use of Defect Prediction for Test Case Prioritization](https://ieeexplore.ieee.org/document/8730206) (see Table II)
REVISIONS_WEIGHT <- 0.6
AUTHORS_WEIGHT   <- 0.3
FIXES_WEIGHT     <- 0.1
TIME_RANGE       <- 0.0
W                <- 2 + ((1 - TIME_RANGE) * 10)

# ---------------------------------------------------------------------- Utility

#
# Kernel density plot
#
kernel_plot <- function(df, aes_x='defect', xlabel='Defect score', fill=TRUE, position='') {
  if (fill) {
    if (position == '') {
      p <- ggplot(df, aes(x=get(aes_x), fill=bug_type, colour=bug_type))
    } else {
      p <- ggplot(df, aes(x=get(aes_x), after_stat(count), fill=bug_type))
    }
  } else {
    p <- ggplot(df, aes(x=get(aes_x)))
  }
  if (position == '') {
    p <- p + geom_density(alpha=0.25)
  } else {
    p <- p + geom_density(position=position)
  }
  # Set axis
  p <- p + scale_x_continuous(name=xlabel, limits=c(0,1), breaks=seq(0,1, by=0.1))
  if (position == '') {
    p <- p + scale_y_continuous(name='Density')
  } else {
    p <- p + scale_y_continuous(name='Count')
  }
  if (fill) {
    # Rename legend title
    p$labels$fill <- 'Bug type'
    p$labels$colour <- 'Bug type'
  }
  # Increase size of [x-y]axis labels
  p <- p + theme(
    axis.text.x=element_text(size=10,  hjust=0.5, vjust=0.5), # hjust=0.75 ?
    axis.text.y=element_text(size=10,  hjust=1.0, vjust=0.0),
    axis.title.x=element_text(size=12, hjust=0.5, vjust=0.0),
    axis.title.y=element_text(size=12, hjust=0.5, vjust=0.5)
  )
  # Create facets, one per type of bug
  if (fill == FALSE) {
    p <- p + facet_grid(~ bug_type)
  }
  # Print it
  print(p)
}

#
# Boxplot
#
boxplot <- function(df, aes_y='rank_best_case', ylabel='Rank', trans_y='', facets=FALSE) {
  # Basic boxplot
  if (facets) {
    p <- ggplot(df, aes(x=buggy_component, y=get(aes_y)))
  } else {
    p <- ggplot(df, aes(x=buggy_component, y=get(aes_y), fill=bug_type))
  }
  p <- p + geom_boxplot(width=0.75, position=position_dodge(width=1))
  # Change x axis label
  p <- p + scale_x_discrete(name='')
  # Change y axis label
  if (trans_y == '') {
    p <- p + scale_y_continuous(name=ylabel)
  } else {
    p <- p + scale_y_continuous(name=ylabel, trans=trans_y)
  }
  # Use grey scale color palette
  if (facets == FALSE) {
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
  if (facets) {
    p <- p + stat_summary(fun=mean, geom='point', shape=8, size=2, fill='black', color='black')
  } else {
    p <- p + stat_summary(aes(shape=bug_type), fun=mean, geom='point', size=1.5, color='black', show.legend=TRUE, position=position_dodge(width=1))
    p <- p + scale_shape_manual(name='', values=c(10, 12))
  }
  # Create facets, one per type of bug
  if (facets) {
    p <- p + facet_grid(~ bug_type)
  }
  # Print it
  print(p)
}

# ------------------------------------------------------------------------- Main

# FIXME remove me
# write.table(df, file=gzfile('/tmp/temporary-df.csv.gz'))
# df <- read.table(gzfile('/tmp/temporary-df.csv.gz'), header=TRUE, stringsAsFactors=FALSE)

# Load data
df <- load_CSV_GZ(CODE_LIFETIME_DATA_FILE)
# Exclude 'test' files
df <- df[!grepl('test', df$'file_path', ignore.case=TRUE), ]
stopifnot(nrow(df) > 0)

# Remove any existing output file and create a new one
unlink(OUTPUT_FILE)
pdf(file=OUTPUT_FILE, family='Helvetica', width=10, height=9)
# Add a cover page to the output file
plot_label('Bug-prediction data')

#
# Normalize timestamps of each commit per bug
#
cat('[INFO] Normalizing timestamps... \n')

min_max_norm <- function(x) {
  if (max(x) == min(x)) {
    return (1)
  }
  return ((x - min(x)) / (max(x) - min(x)))
}

df$'alpha' <- NA
for (bug_id in unique(df$'bug_id')) {
  mask <- df$'bug_id' == bug_id
  df$'alpha'[mask] <- min_max_norm(df$'author_commit_date'[mask])
}
# Drop 'author_commit_date' column as it is no longer required
df <- df[ , !(names(df) %in% c('author_commit_date'))]
head(df)
summary(df)

#
# Compute TWR's authors, revisions, and bug-fix commits
#
cat('[INFO] Computing TWRs authors, revisions, and bug-fix commits... \n')

# Compute TWR's authors
x_authors_twr                             <- aggregate(x=alpha ~ bug_id + file_path + line_number + author_name, data=df, FUN=min)
x_authors_twr$'authors_twr'               <- 1 / (1 + exp(-12 * x_authors_twr$'alpha' + W))
df                                        <- merge(df, x_authors_twr, by=c('bug_id', 'file_path', 'line_number', 'author_name', 'alpha'), all.x=TRUE)
df$'authors_twr'[is.na(df$'authors_twr')] <- 0
remove(x_authors_twr)

# Compute TWR's revisions
df$'revisions_twr'                        <- 1 / (1 + exp(-12 * df$'alpha' + W))

# Compute TWR's bug-fix commits
df$'fixes_twr'[df$'bug_fix' == 0]         <- 0
df$'fixes_twr'[df$'bug_fix' == 1]         <- 1 / (1 + exp(-12 * df$'alpha'[df$'bug_fix' == 1] + W))

#
# Compute TWR's sums
#
cat('[INFO] Computing TWRs sums... \n')

df <- aggregate(x=cbind(revisions_twr, authors_twr, fixes_twr) ~ project_full_name + bug_id + bug_type + file_path + line_number, data=df, FUN=sum)
# Rename resulting columns
names(df)[names(df) == 'revisions_twr'] <- 'sum_revisions_twr'
names(df)[names(df) == 'authors_twr']   <- 'sum_authors_twr'
names(df)[names(df) == 'fixes_twr']     <- 'sum_fixes_twr'

#
# Compute TWR's weights
#
cat('[INFO] Computing TWRs weights... \n')

df$'weight_revisions_twr' <- REVISIONS_WEIGHT * df$'sum_revisions_twr'
df$'weight_authors_twr'   <- AUTHORS_WEIGHT * df$'sum_authors_twr'
df$'weight_fixes_twr'     <- FIXES_WEIGHT * df$'sum_fixes_twr'

#
# Compute beta value and defect value
#
cat('[INFO] Computing defect values... \n')

df$'beta'   <- df$'weight_revisions_twr' + df$'weight_authors_twr' + df$'weight_fixes_twr'
df$'defect' <- 1 - exp(-df$'beta')
head(df)
summary(df)

#
# Get buggy-components per line of code from another dataframe and merge it
#
cat('[INFO] Combining data, i.e., all source code data with buggy code data... \n')

# Load data
buggy_code_df <- load_CSV(BUGGY_CODE_DATA_FILE)
# Annotated all rows (i.e., lines of code) as buggy, this will later allow one to
# easily identify which are buggy and which are not
buggy_code_df$'buggy' <- 1
# Rename some columns to ease merge
names(buggy_code_df)[names(buggy_code_df) == 'buggy_file_path']   <- 'file_path'
names(buggy_code_df)[names(buggy_code_df) == 'buggy_line_number'] <- 'line_number'
# Merge data
df <- merge(x=df, y=buggy_code_df, by=c('project_full_name', 'bug_id', 'bug_type', 'file_path', 'line_number'), all.x=TRUE)
# Set the value of all NaNs (i.e., lines of code for each we have historical data but are not-buggy) as 0
df$'buggy'[is.na(df$'buggy')] <- 0
head(df)
summary(df)

# Filter out bugs for which there is no buggy line, e.g., bugs that were fixed
# by only adding new code
x                        <- aggregate(x=buggy ~ bug_id, data=df, FUN=sum)
bugs_with_no_buggy_lines <- unique(x$'bug_id'[x$'buggy' == 0])
df                       <- df[df$'bug_id' %!in% bugs_with_no_buggy_lines, ]

#
# Rank each line of code according to its defect score
#

# Drop the buggy_component granularity
df_at_line_level <- unique(df[ , which(colnames(df) %in% c('project_full_name', 'bug_id', 'bug_type', 'file_path', 'line_number', 'buggy', 'defect')) ])

cat('[INFO] Print kernel density plot... \n')

plot_label('Overall distribution of defect scores\n(all lines of code)')
kernel_plot(df_at_line_level, fill=TRUE, position='')
kernel_plot(df_at_line_level, fill=TRUE, position='stack')
kernel_plot(df_at_line_level, fill=TRUE, position='fill')
plot_label('Overall distribution of defect scores\n(all lines of code)\nper type of bug')
kernel_plot(df_at_line_level, fill=FALSE, position='')

plot_label('Overall distribution of defect scores\n(only buggy lines of code)')
kernel_plot(df_at_line_level[df_at_line_level$'buggy' == 1, ], fill=TRUE, position='')
kernel_plot(df_at_line_level[df_at_line_level$'buggy' == 1, ], fill=TRUE, position='stack')
kernel_plot(df_at_line_level[df_at_line_level$'buggy' == 1, ], fill=TRUE, position='fill')
plot_label('Overall distribution of defect scores\n(only buggy lines of code)\nper type of bug')
kernel_plot(df_at_line_level[df_at_line_level$'buggy' == 1, ], fill=FALSE, position='')

cat('[INFO] Rank lines of code... \n')
# Rank lines and compute top-N
for (bug_id in unique(df_at_line_level$'bug_id')) {
  mask <- df_at_line_level$'bug_id' == bug_id

  # Best case
  df_at_line_level$'rank_best_case'[mask]        <- rank(-df_at_line_level$'defect'[mask], ties.method='min')
  df_at_line_level$'rank_best_case_top1'[mask]   <- 0
  df_at_line_level$'rank_best_case_top5'[mask]   <- 0
  df_at_line_level$'rank_best_case_top10'[mask]  <- 0
  df_at_line_level$'rank_best_case_top200'[mask] <- 0
  df_at_line_level$'rank_best_case_top1'[mask   & df_at_line_level$'buggy' == 1 & df_at_line_level$'rank_best_case' == 1]   <- 1
  df_at_line_level$'rank_best_case_top5'[mask   & df_at_line_level$'buggy' == 1 & df_at_line_level$'rank_best_case' <= 5]   <- 1
  df_at_line_level$'rank_best_case_top10'[mask  & df_at_line_level$'buggy' == 1 & df_at_line_level$'rank_best_case' <= 10]  <- 1
  df_at_line_level$'rank_best_case_top200'[mask & df_at_line_level$'buggy' == 1 & df_at_line_level$'rank_best_case' <= 200] <- 1

  # Worst case
  df_at_line_level$'rank_worst_case'[mask]        <- rank(-df_at_line_level$'defect'[mask], ties.method='max')
  df_at_line_level$'rank_worst_case_top1'[mask]   <- 0
  df_at_line_level$'rank_worst_case_top5'[mask]   <- 0
  df_at_line_level$'rank_worst_case_top10'[mask]  <- 0
  df_at_line_level$'rank_worst_case_top200'[mask] <- 0
  df_at_line_level$'rank_worst_case_top1'[mask   & df_at_line_level$'buggy' == 1 & df_at_line_level$'rank_worst_case' == 1]   <- 1
  df_at_line_level$'rank_worst_case_top5'[mask   & df_at_line_level$'buggy' == 1 & df_at_line_level$'rank_worst_case' <= 5]   <- 1
  df_at_line_level$'rank_worst_case_top10'[mask  & df_at_line_level$'buggy' == 1 & df_at_line_level$'rank_worst_case' <= 10]  <- 1
  df_at_line_level$'rank_worst_case_top200'[mask & df_at_line_level$'buggy' == 1 & df_at_line_level$'rank_worst_case' <= 200] <- 1

  # Average case
  df_at_line_level$'rank_avg_case'[mask]        <- rank(-df_at_line_level$'defect'[mask], ties.method='average')
  df_at_line_level$'rank_avg_case_top1'[mask]   <- 0
  df_at_line_level$'rank_avg_case_top5'[mask]   <- 0
  df_at_line_level$'rank_avg_case_top10'[mask]  <- 0
  df_at_line_level$'rank_avg_case_top200'[mask] <- 0
  df_at_line_level$'rank_avg_case_top1'[mask   & df_at_line_level$'buggy' == 1 & df_at_line_level$'rank_avg_case' == 1]   <- 1
  df_at_line_level$'rank_avg_case_top5'[mask   & df_at_line_level$'buggy' == 1 & df_at_line_level$'rank_avg_case' <= 5]   <- 1
  df_at_line_level$'rank_avg_case_top10'[mask  & df_at_line_level$'buggy' == 1 & df_at_line_level$'rank_avg_case' <= 10]  <- 1
  df_at_line_level$'rank_avg_case_top200'[mask & df_at_line_level$'buggy' == 1 & df_at_line_level$'rank_avg_case' <= 200] <- 1
}

#
# Rank of a buggy component is given by the rank of the correspondent component's line of code
#
cat('[INFO] Rank buggy code components... \n')

# Expand ranks to buggy_component granularity
df <- merge(x=df, y=df_at_line_level, by=c('project_full_name', 'bug_id', 'bug_type', 'file_path', 'line_number', 'buggy', 'defect'), all.x=TRUE)
head(df)
summary(df)

cat('[INFO] Print boxplot... \n')

df_min <- aggregate(x=defect ~ project_full_name + bug_id + bug_type + buggy_component, data=df[df$'buggy' == 1, ], FUN=min)  # Worst
df_max <- aggregate(x=defect ~ project_full_name + bug_id + bug_type + buggy_component, data=df[df$'buggy' == 1, ], FUN=max)  # Best
df_avg <- aggregate(x=defect ~ project_full_name + bug_id + bug_type + buggy_component, data=df[df$'buggy' == 1, ], FUN=mean) # Average

plot_label('Overall distribution of buggy components\' defect scores\n(min defect)')
boxplot(df_min, aes_y='defect', ylabel='Defect score', facets=FALSE)
boxplot(df_min, aes_y='defect', ylabel='Defect score', facets=TRUE)
plot_label('Overall distribution of buggy components\' defect scores\n(max defect)')
boxplot(df_max, aes_y='defect', ylabel='Defect score', facets=FALSE)
boxplot(df_max, aes_y='defect', ylabel='Defect score', facets=TRUE)
plot_label('Overall distribution of buggy components\' defect scores\n(avg defect)')
boxplot(df_avg, aes_y='defect', ylabel='Defect score', facets=FALSE)
boxplot(df_avg, aes_y='defect', ylabel='Defect score', facets=TRUE)

df_min <- aggregate(x=rank_best_case ~ project_full_name + bug_id + bug_type + buggy_component, data=df[df$'buggy' == 1, ], FUN=min)  # Best
df_max <- aggregate(x=rank_best_case ~ project_full_name + bug_id + bug_type + buggy_component, data=df[df$'buggy' == 1, ], FUN=max)  # Worst
df_avg <- aggregate(x=rank_best_case ~ project_full_name + bug_id + bug_type + buggy_component, data=df[df$'buggy' == 1, ], FUN=mean) # Average

plot_label('Overall distribution of buggy components\' ranks\n(min rank and min agg)')
boxplot(df_min, aes_y='rank_best_case', ylabel='Rank (best case)', trans_y='log10', facets=FALSE)
boxplot(df_min, aes_y='rank_best_case', ylabel='Rank (best case)', trans_y='log10', facets=TRUE)
plot_label('Overall distribution of buggy components\' ranks\n(min rank and max agg)')
boxplot(df_max, aes_y='rank_best_case', ylabel='Rank (best case)', trans_y='log10', facets=FALSE)
boxplot(df_max, aes_y='rank_best_case', ylabel='Rank (best case)', trans_y='log10', facets=TRUE)
plot_label('Overall distribution of buggy components\' ranks\n(min rank and avg agg)')
boxplot(df_avg, aes_y='rank_best_case', ylabel='Rank (best case)', trans_y='log10', facets=FALSE)
boxplot(df_avg, aes_y='rank_best_case', ylabel='Rank (best case)', trans_y='log10', facets=TRUE)

df_min <- aggregate(x=rank_worst_case ~ project_full_name + bug_id + bug_type + buggy_component, data=df[df$'buggy' == 1, ], FUN=min)  # Best
df_max <- aggregate(x=rank_worst_case ~ project_full_name + bug_id + bug_type + buggy_component, data=df[df$'buggy' == 1, ], FUN=max)  # Worst
df_avg <- aggregate(x=rank_worst_case ~ project_full_name + bug_id + bug_type + buggy_component, data=df[df$'buggy' == 1, ], FUN=mean) # Average

plot_label('Overall distribution of buggy components\' ranks\n(max rank and min agg)')
boxplot(df_min, aes_y='rank_worst_case', ylabel='Rank (worst case)', trans_y='log10', facets=FALSE)
boxplot(df_min, aes_y='rank_worst_case', ylabel='Rank (worst case)', trans_y='log10', facets=TRUE)
plot_label('Overall distribution of buggy components\' ranks\n(max rank and max agg)')
boxplot(df_max, aes_y='rank_worst_case', ylabel='Rank (worst case)', trans_y='log10', facets=FALSE)
boxplot(df_max, aes_y='rank_worst_case', ylabel='Rank (worst case)', trans_y='log10', facets=TRUE)
plot_label('Overall distribution of buggy components\' ranks\n(max rank and avg agg)')
boxplot(df_avg, aes_y='rank_worst_case', ylabel='Rank (worst case)', trans_y='log10', facets=FALSE)
boxplot(df_avg, aes_y='rank_worst_case', ylabel='Rank (worst case)', trans_y='log10', facets=TRUE)

df_min <- aggregate(x=rank_avg_case ~ project_full_name + bug_id + bug_type + buggy_component, data=df[df$'buggy' == 1, ], FUN=min)  # Best
df_max <- aggregate(x=rank_avg_case ~ project_full_name + bug_id + bug_type + buggy_component, data=df[df$'buggy' == 1, ], FUN=max)  # Worst
df_avg <- aggregate(x=rank_avg_case ~ project_full_name + bug_id + bug_type + buggy_component, data=df[df$'buggy' == 1, ], FUN=mean) # Average

plot_label('Overall distribution of buggy components\' ranks\n(avg rank and min agg)')
boxplot(df_min, aes_y='rank_avg_case', ylabel='Rank (avg case)', trans_y='log10', facets=FALSE)
boxplot(df_min, aes_y='rank_avg_case', ylabel='Rank (avg case)', trans_y='log10', facets=TRUE)
plot_label('Overall distribution of buggy components\' ranks\n(avg rank and max agg)')
boxplot(df_max, aes_y='rank_avg_case', ylabel='Rank (avg case)', trans_y='log10', facets=FALSE)
boxplot(df_max, aes_y='rank_avg_case', ylabel='Rank (avg case)', trans_y='log10', facets=TRUE)
plot_label('Overall distribution of buggy components\' ranks\n(avg rank and avg agg)')
boxplot(df_avg, aes_y='rank_avg_case', ylabel='Rank (avg case)', trans_y='log10', facets=FALSE)
boxplot(df_avg, aes_y='rank_avg_case', ylabel='Rank (avg case)', trans_y='log10', facets=TRUE)

cat('[INFO] Print barplots... \n')

# Number of bugs for which at least one buggy component is in top-1, top-5, top-10, top-200
df_ranks_per_bug <- aggregate(x=cbind(rank_best_case_top1, rank_best_case_top5, rank_best_case_top10, rank_best_case_top200,
                       rank_worst_case_top1, rank_worst_case_top5, rank_worst_case_top10, rank_worst_case_top200,
                       rank_avg_case_top1, rank_avg_case_top5, rank_avg_case_top10, rank_avg_case_top200) ~ project_full_name + bug_id + bug_type, data=df[df$'buggy' == 1, ], FUN=max)
df_ranks_per_bug <- melt(df_ranks_per_bug, id.vars=c('project_full_name', 'bug_id', 'bug_type'),
                                           measure.vars=c('rank_best_case_top1',  'rank_best_case_top5',  'rank_best_case_top10',  'rank_best_case_top200',
                                                          'rank_worst_case_top1', 'rank_worst_case_top5', 'rank_worst_case_top10', 'rank_worst_case_top200',
                                                          'rank_avg_case_top1',   'rank_avg_case_top5',   'rank_avg_case_top10',   'rank_avg_case_top200'))
df_ranks_per_bug <- df_ranks_per_bug[df_ranks_per_bug$'value' > 0, ]
print(df_ranks_per_bug)
summary(df_ranks_per_bug)

for (case in c('best_case', 'worst_case', 'avg_case')) {
  plot_label(paste('Number of bugs for which at least one buggy component is in\nin top-N (', case, ')', sep=''))
  # Stacked bar plot
  p <- ggplot(df_ranks_per_bug[grepl(case, df_ranks_per_bug$'variable', ignore.case=TRUE), ], aes(x=bug_type, fill=variable))
  p <- p + geom_bar(position='dodge')
  # Change x axis label
  p <- p + scale_x_discrete(name='Bug type')
  # Change y axis label
  p <- p + scale_y_continuous(name='# Bugs')
  # Move legend's title to the top and increase size of [x-y]axis labels
  p <- p + theme(legend.position='top',
                 axis.text.x=element_text(size=10,  hjust=0.75, vjust=0.5),
                 axis.text.y=element_text(size=10,  hjust=1.0, vjust=0.0),
                 axis.title.x=element_text(size=12, hjust=0.5, vjust=0.0),
                 axis.title.y=element_text(size=12, hjust=0.5, vjust=0.5)
  )
  # Remove legend title and rename labels
  p <- p + scale_fill_discrete(name='', labels=c('top-1', 'top-5', 'top-10', 'top-200'))
  # Add labels over bars
  p <- p + stat_count(geom='text', colour='black', size=3, aes(label=..count..), position=position_dodge(width=0.9), vjust=-0.50)
  # Print it
  print(p)
}

# Number of occurrences per buggy component in top-1, top-5, top-10, top-200
df_ranks_per_component <- aggregate(x=cbind(rank_best_case_top1, rank_best_case_top5, rank_best_case_top10, rank_best_case_top200,
                       rank_worst_case_top1, rank_worst_case_top5, rank_worst_case_top10, rank_worst_case_top200,
                       rank_avg_case_top1, rank_avg_case_top5, rank_avg_case_top10, rank_avg_case_top200) ~ project_full_name + bug_id + bug_type + buggy_component, data=df[df$'buggy' == 1, ], FUN=max)
df_ranks_per_component <- melt(df_ranks_per_component, id.vars=c('project_full_name', 'bug_id', 'bug_type', 'buggy_component'),
                                                       measure.vars=c('rank_best_case_top1',  'rank_best_case_top5',  'rank_best_case_top10',  'rank_best_case_top200',
                                                                     'rank_worst_case_top1', 'rank_worst_case_top5', 'rank_worst_case_top10', 'rank_worst_case_top200',
                                                                     'rank_avg_case_top1',   'rank_avg_case_top5',   'rank_avg_case_top10',   'rank_avg_case_top200'))
df_ranks_per_component <- df_ranks_per_component[df_ranks_per_component$'value' > 0, ]
head(df_ranks_per_component)
summary(df_ranks_per_component)

for (case in c('best_case', 'worst_case', 'avg_case')) {
  plot_label(paste('Number of bugs in which each buggy component\nappears in top-N (', case, ')', sep=''))
  # Stacked bar plot
  p <- ggplot(df_ranks_per_component[grepl(case, df_ranks_per_component$'variable', ignore.case=TRUE), ], aes(x=buggy_component, fill=variable))
  p <- p + geom_bar(position=position_dodge(width=1))
  # Change x axis label
  p <- p + scale_x_discrete(name='')
  # Change y axis label
  p <- p + scale_y_continuous(name='# Bugs')
  # Move legend's title to the top and increase size of [x-y]axis labels
  p <- p + theme(legend.position='top',
                 axis.text.x=element_text(size=10,  hjust=0.75, vjust=0.5),
                 axis.text.y=element_text(size=10,  hjust=1.0, vjust=0.0),
                 axis.title.x=element_text(size=12, hjust=0.5, vjust=0.0),
                 axis.title.y=element_text(size=12, hjust=0.5, vjust=0.5)
  )
  # Remove legend title and rename labels
  p <- p + scale_fill_discrete(name='', labels=c('top-1', 'top-5', 'top-10', 'top-200'))
  # Make it horizontal
  p <- p + coord_flip()
  # Add labels over bars
  p <- p + stat_count(geom='text', colour='black', size=2, aes(label=..count..), position=position_dodge(width=1), hjust=-0.10)
  # Create facets, one per type of bug
  p <- p + facet_grid(~ bug_type)
  # Print it
  print(p)
}

# Close output file
dev.off()
# Embed fonts
embed_fonts_in_a_pdf(OUTPUT_FILE)

# EOF
