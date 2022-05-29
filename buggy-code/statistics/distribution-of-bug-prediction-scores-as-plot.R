# ------------------------------------------------------------------------------
# This script plots the distribution of buggy prediction scores as boxplot and reports the ranking stats for each buggy component in a csv file
#
# Usage:
#   Rscript distribution-of-bug-prediction-scores-as-plot.R
#     <input data file, e.g., ../data/generated/code-lifetime-data.csv.gz>
#     <output pdf file, e.g., distribution-of-bug-prediction-scores-as-plot.pdf>
#     <output csv file, e.g., ranking-stats.csv>
# ------------------------------------------------------------------------------

source('../../utils/statistics/util.R')

# Load external packages
library('reshape2')
library(dplyr)
library(xtable)

# ------------------------------------------------------------------------- Args

args = commandArgs(trailingOnly=TRUE)
if (length(args) != 3) {
  stop('USAGE: Rscript distribution-of-bug-prediction-scores-as-plot.R <input data file, e.g., ../data/generated/code-lifetime-data.csv.gz> <output pdf file, e.g., distribution-of-bug-prediction-scores-as-plot.pdf>  <output csv file, e.g., ranking-stats.csv>')
}

# Args
INPUT_FILE  <- args[1]
OUTPUT_FILE <- args[2]
OUTPUT_FILE_2 <- args[3]

# Constant values suggested in the research paper
# [An Empirical Study on the Use of Defect Prediction for Test Case Prioritization](https://ieeexplore.ieee.org/document/8730206) (see Table II)
REVISIONS_WEIGHT <- 0.6
AUTHORS_WEIGHT   <- 0.3
FIXES_WEIGHT     <- 0.1
TIME_RANGE       <- 0.0
W                <- 2 + ((1 - TIME_RANGE) * 10)

# ------------------------------------------------------------------------- Main

# Load data
df <- load_CSV_GZ(INPUT_FILE)

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
summary(df) # FIXME remove me
head(df) # FIXME remove me

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
head(df) # FIXME remove me
summary(df$'defect')


#
# Get buggy-components per line of code from another dataframe and merge it
#
cat('[INFO] Combining data... \n')

# TODO 1. read ../data/generated/buggy-code-data.csv
# TODO 2. annotated all buggy_line_number as buggy, i.e., create a new column named 'buggy' with value 1
# TODO 3. merge it with df
# TODO 4. set the value of all NaNs (lines of code for each we have historical data but are not-buggy) in the 'buggy' column as 0


buggyComponents <- read.csv(file = '../data/generated/buggy-code-data.csv', sep = ',')
buggyComponents['buggy'] = c(1)
names(buggyComponents)[names(buggyComponents) == 'buggy_file_path'] <- 'file_path'
names(buggyComponents)[names(buggyComponents) == 'buggy_line_number'] <- 'line_number'
mergedDf <- merge(x = buggyComponents,y = df, by=c("file_path","bug_id","line_number"), all.y=TRUE)
mergedDf['buggy'][is.na(mergedDf['buggy'])] <- 0
mergedDf['defect'][is.na(mergedDf['defect'])] <- 0

#head(mergedDf)
unique_component <- unique(mergedDf$'buggy_component')
print(unique_component)
teste <- subset(mergedDf, buggy_component == 'fstring_string',
                           select=c(bug_id, file_path, line_number, defect)) 
head(teste, n = 17L)


### parse rows by bug_id to do rankings, appending data using iteration into an emptydf with ranking column to then merge with main dataframe
unique_id <- unique(mergedDf$'bug_id')
print(unique_id)
appendDf <- data.frame()

for(val in unique_id){
  
  tryCatch(
    expr = {
      print(val)
    
      newdata <- subset(mergedDf, bug_id == val,
                        select=c(bug_id, file_path, line_number, defect))
      newdata <- newdata[order(-newdata$'defect'),]
      row.names(newdata) <- NULL
      newdata['ranking'] = match(-newdata$'defect', sort(unique(-newdata$'defect')))
      print(colnames(newdata))
      print(colnames(mergedDf))
    
      appendDf <- rbind(appendDf, newdata)
      print(nrow(newdata))
      print(ncol(newdata))
      print(nrow(mergedDf))
      print(ncol(mergedDf))
      #print(appendDf)
    },
  
    error = function(e){
      message('Caught an error!Defect object not detected')
      print(e)
    }

)
  
}

finalDf <- merge(x = appendDf,y = mergedDf, by=c("file_path","bug_id","line_number"), all.y=TRUE)
#print('writing to csv')
## writing to csv file just for debugging purposes
#write.csv(finalDf,"ranking.csv", row.names = FALSE)



#
# Compute the distribution of bug-prediction scores overall, of buggy lines only,
# min, max, average, median position of buggy lines, and top-N and transpose the data into a latex table
#
cat('[INFO] Compute ranking stats and save into csv file... \n')

stats <- aggregate(finalDf$'ranking', list(finalDf$'buggy_component'),  FUN = function(x) c(mean = round(mean(x), digits = 1), median = round(median(x), digits = 1), max = round(max(x), digits = 1), min = round(min(x), digits = 1), top1 = round(sum(x <= 1), digits = 1), top10 = round(sum( x <= 10), digits =1), top200 = round(sum( x <= 200), digits = 1) )) 
print(stats)
write.csv(stats,OUTPUT_FILE_2 , row.names = FALSE)
#stats <- knitr::kable(stats, format = 'latex')
#writeLines(stats, 'ranking-stats-per-buggy-component.tex')

cat('[INFO] Compute distribution of bug-prediction scores and export output into a pdf file... \n')

# Remove any existing output file and create a new one
unlink(OUTPUT_FILE)
pdf(file=OUTPUT_FILE, family='Helvetica', width=10, height=9)
# Add a cover page to the output file
plot_label('Distributions')

#
# As boxplot
#

boxplot_it <- function(mergedDf, label, facets=FALSE, fill=FALSE) {
  # Identify plot
  plot_label(label)
  # Basic boxplot
  mergedDf=subset(mergedDf, !is.na(buggy_component))
  if (fill) {
    p <- ggplot(mergedDf, aes(x=buggy_component, y=defect, fill=bug_type.y))
  } else {
    p <- ggplot(mergedDf, aes(x=buggy_component, y=defect))
  }
  p <- p + geom_boxplot(width=3, position=position_dodge(width=5), varwidth = TRUE)
  # Change x axis label
  p <- p + scale_x_discrete(name='')
  # Change y axis label
  p <- p + scale_y_continuous(name='Defect Probability Scores')
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
    p <- p + stat_summary(aes(shape=bug_type.y), fun=mean, geom='point', size=1.5, color='black', show.legend=TRUE, position=position_dodge(width=1))
    p <- p + scale_shape_manual(name='', values=c(10, 12))
  } else {
    p <- p + stat_summary(fun=mean, geom='point', shape=8, size=2, fill='black', color='black')
  }
  # Create facets, one per type of bug
  if (facets) {
    p <- p + facet_grid(~ bug_type.y)
  }
  # Print it
  print(p)
}

boxplot_it(mergedDf, 'Overall', facets=FALSE, fill=FALSE)
boxplot_it(mergedDf, 'Classical and Quantum bugs (same plot)', facets=FALSE, fill=TRUE)
boxplot_it(mergedDf, 'Classical and Quantum bugs (facets)', facets=TRUE, fill=FALSE)
boxplot_it(mergedDf[mergedDf$'bug_type.y' == 'Classical', ], 'Classical bugs', facets=FALSE, fill=FALSE)
boxplot_it(mergedDf[mergedDf$'bug_type.y' == 'Quantum', ], 'Quantum bugs', facets=FALSE, fill=FALSE)

# Close output file
dev.off()
# Embed fonts
embed_fonts_in_a_pdf(OUTPUT_FILE)

# EOF
