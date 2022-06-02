# ------------------------------------------------------------------------------
# This script plots the distribution of chunks coded by a bugfix commit as well as the total number of code elements  
# and which code elements can be found within each chunk as boxplot.
#
# Usage:
#   Rscript distribution-of-chunks-and-chunk-code-elements-as-plot.R
#     <input data file, e.g., ../data/generated/fixed-code-data.csv>
#     <output pdf file, e.g., distribution-of-chunks-and-chunk-code-elements-as-plot.pdf>
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
  stop('USAGE:  Rscript distribution-of-chunks-and-chunk-code-elements-as-plot.R <input data file, e.g., ../data/generated/fixed-code-data.csv> <output pdf file, e.g., distribution-of-chunks-and-chunk-code-elements-as-plot.pdf>')
}

# Inputs
FIXED_CODE_DATA_FILE <- args[1]
# Output
OUTPUT_FILE          <- args[2]

# ---------------------------------------------------------------------- Utility

#
# Boxplot
#
boxplot_it_chunk <- function(df, label, facets=FALSE, fill=FALSE, yAxisLabel) {
  # Identify plot
  plot_label(label)
  # Basic boxplot
  if (fill) {
    p <- ggplot(df, aes(x=bug_id, y=chunk_size, fill=bug_type))
  } else {
    p <- ggplot(df, aes(x=bug_id, y=chunk_size))
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
                 axis.text.x=element_text(size=5,  hjust=0.75, vjust=0.5),
                 axis.text.y=element_text(size=5,  hjust=1.0, vjust=0.0),
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

boxplot_it_chunk_code_element_count <- function(df, label, facets=FALSE, fill=FALSE, yAxisLabel) {
  # Identify plot
  plot_label(label)
  # Basic boxplot
  if (fill) {
    p <- ggplot(df, aes(x=chunk_ID, y=count, fill=bug_type))
  } else {
    p <- ggplot(df, aes(x=chunk_ID, y=count))
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

# Create new df
chunkDf <- data.frame(matrix(ncol = 8, nrow = 0))
x <- c("project_full_name", "fix_commit_hash", "bug_id","bug_type","fixed_file_path","begin_chunk","end_chunk","chunk_size")
colnames(chunkDf) <- x
head(chunkDf)

## Function to calculate chunks for a given df and add to a new df

chunkFunc <- function(df){
chunkCounter = 1
appendDf <- data.frame(matrix(ncol = 8, nrow = 0))
x <- c("project_full_name", "fix_commit_hash", "bug_id","bug_type","fixed_file_path","begin_chunk","end_chunk","chunk_size")
colnames(appendDf) <- x

  for(i in 1:nrow(df)){
    
    if(dim(df)[1] == 0){
      return(appendDf)
    }
    
    if(chunkCounter == 1){
      begin_chunk = df[i, "fixed_line_number"]
    }
    
    if(!is.na(df[i + 1, "fixed_line_number"])){
      
    if(df[i + 1, "fixed_line_number"] - df[i, "fixed_line_number"] == 1){
      chunkCounter = chunkCounter +1
    }
    
    else{
      end_chunk = df[i, "fixed_line_number"]
      appendDf[nrow(appendDf) + 1,] <- list(df[i, "project_full_name"],df[i, "fix_commit_hash"], df[i, "bug_id"],df[i, "bug_type"],df[i, "fixed_file_path"],begin_chunk,end_chunk,chunkCounter)
      chunkCounter = 1
     }
    }
    else{
      end_chunk = df[i, "fixed_line_number"]
      appendDf[nrow(appendDf) + 1,] <- list(df[i, "project_full_name"],df[i, "fix_commit_hash"], df[i, "bug_id"],df[i, "bug_type"],df[i, "fixed_file_path"],begin_chunk,end_chunk,chunkCounter)
      chunkCounter = 1
    }
  }
  return(appendDf)
}

# Test function with sample data

#testData <- FixDf[FixDf$'fix_commit_hash' == 'ec1b4ce759f1fb8ba0242dd6c4a309fa1b586666' & FixDf$'bug_id' == 1 & FixDf$'fixed_file_path' == 'qiskit_ignis/tomography/fitters/cvx_fit.py' , ]
#testData = testData[!duplicated(testData$'fixed_line_number'),]
#testDf <- chunkFunc(testData)
#print('Test Df')
#head(testDf)

# Group dataframe by bug_id and fixed_file_path and apply chunkFunc

groupDf <- split(FixDf, list(FixDf$'bug_id',FixDf$'fixed_file_path'))

for(i in groupDf){
  i = i[!duplicated(i$'fixed_line_number'),]
  tmpDf <- chunkFunc(i)
  chunkDf <- rbind(chunkDf, tmpDf)
  
}

## Add auto incremented ID

chunkDf$'chunk_ID' <- 1:nrow(chunkDf)

cat('[INFO] Outputting chunkDf... \n')
head(chunkDf, n = 10L)

## testing the data with previous data sample to check whether the results are the same
#testData <- chunkDf[chunkDf$'project_full_name' == 'ec1b4ce759f1fb8ba0242dd6c4a309fa1b586666' & chunkDf$'bug_id' == 1 & chunkDf$'fixed_file_path' == 'qiskit_ignis/tomography/fitters/cvx_fit.py' , ]
#head(testData)

cat('[INFO] Calculating total number of code elements per chunk \n')

codeElementChunkDf <- sqldf("SELECT a.fixed_component,a.project_full_name,a.bug_id, a.bug_type, a.fixed_line_number, a.fixed_file_path, b.chunk_ID, b.end_chunk, b.begin_chunk, b.chunk_size
                             FROM chunkDf as b
                             LEFT JOIN FixDf as a
                             ON a.fix_commit_hash = b.fix_commit_hash AND a.fixed_file_path = b.fixed_file_path
                             WHERE a.fixed_line_number <= b.end_chunk AND a.fixed_line_number >= b.begin_chunk
                             ")

codeElementChunkDf$'count' <- 1
codeElementChunkDf_agg <- aggregate(x= count ~ chunk_ID + bug_id + bug_type , data=codeElementChunkDf, FUN=sum)
head(codeElementChunkDf_agg)
 
cat('[INFO] Plotting chunk distribution and code elements per chunk \n')

# Remove any existing output file and create a new one
unlink(OUTPUT_FILE)
pdf(file=OUTPUT_FILE, family='Helvetica', width=10, height=10)
# Add a cover page to the output file
plot_label('Distributions')

##Plotting chunk distribution

boxplot_it_chunk(chunkDf, 'Overall', facets=FALSE, fill=FALSE, 'Chunk Size')
boxplot_it_chunk(chunkDf, 'Classical and Quantum bugs (same plot)', facets=FALSE, fill=TRUE, 'Chunk Size')
boxplot_it_chunk(chunkDf, 'Classical and Quantum bugs (facets)', facets=TRUE, fill=FALSE, 'Chunk Size')
boxplot_it_chunk(chunkDf[chunkDf$'bug_type' == 'Classical' , ], 'Classical bugs', facets=FALSE, fill=FALSE, 'Chunk Size')
boxplot_it_chunk(chunkDf[chunkDf$'bug_type' == 'Quantum' , ], 'Quantum bugs', facets=FALSE, fill=FALSE, 'Chunk Size')

## Plotting fix code element distribution per chunk

boxplot_it_chunk_code_element_count(codeElementChunkDf_agg, 'Overall', facets=FALSE, fill=FALSE, 'Fix Code Element Occurrence')
boxplot_it_chunk_code_element_count(codeElementChunkDf_agg, 'Classical and Quantum bugs (same plot)', facets=FALSE, fill=TRUE, 'Fix Code Element Occurrence')
boxplot_it_chunk_code_element_count(codeElementChunkDf_agg, 'Classical and Quantum bugs (facets)', facets=TRUE, fill=FALSE, 'Fix Code Element Occurrence')
boxplot_it_chunk_code_element_count(codeElementChunkDf_agg[codeElementChunkDf_agg$'bug_type' == 'Classical' , ], 'Classical bugs', facets=FALSE, fill=FALSE, 'Fix Code Element Occurrence')
boxplot_it_chunk_code_element_count(codeElementChunkDf_agg[codeElementChunkDf_agg$'bug_type' == 'Quantum' , ], 'Quantum bugs', facets=FALSE, fill=FALSE, 'Fix Code Element Occurrence')



