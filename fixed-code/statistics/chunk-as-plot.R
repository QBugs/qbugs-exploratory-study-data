# ------------------------------------------------------------------------------
# This script plots the distribution of number of chunks and chunk size as plot.
# Usage:
#   Rscript chunk-as-plot.R
#     <chunk data file, e.g., ../data/generated/chunk-data.csv>
#     <output pdf file, e.g., chunk-as-plot.pdf>
# ------------------------------------------------------------------------------

source('../../utils/statistics/util.R')

# Load external packages
library('ggplot2')
library('reshape2')
library('UpSetR')
library('nortest')
library('effsize')
library('dplyr')
library('tidyr')


# ------------------------------------------------------------------------- Args

args = commandArgs(trailingOnly=TRUE)
if (length(args) != 2) {
  stop('USAGE: Rscript chunk-as-plot.R <chunk input data file, e.g., ../data/generated/chunk-data.csv> <output pdf file, e.g., chunk-as-plot.pdf>')
}

# Args
CHUNK_DATA  <- args[1]
OUTPUT_FILE <- args[2]

# ---------------------------------------------------------------------- Utility

#
# Boxplot for chunk_size
#

boxplot_it <- function(df, label, facets=FALSE, fill=FALSE) {
  # Identify plot
  plot_label(label)
  # Basic boxplot
  if (fill) {
    p <- ggplot(df, aes(x=bug_type, y=chunk_size, fill=bug_type))
  } else {
    p <- ggplot(df, aes(x=bug_type, y=chunk_size))
  }
  p <- p + geom_boxplot(width=0.75, position=position_dodge(width=1))
  # Change x axis label
  p <- p + scale_x_discrete(name='')
  # Change y axis label
  p <- p + scale_y_continuous(name='Chunk Size Distribution', trans='log10')
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
# Boxplot for chunk_size for project
#

boxplot_it_2 <- function(df, label, facets=FALSE, fill=FALSE) {
  # Identify plot
  plot_label(label)
  # Basic boxplot
  if (fill) {
    p <- ggplot(df, aes(x=project_full_name, y=chunk_size, fill=bug_type))
  } else {
    p <- ggplot(df, aes(x=project_full_name, y=chunk_size))
  }
  p <- p + geom_boxplot(width=0.75, position=position_dodge(width=1))
  # Change x axis label
  p <- p + scale_x_discrete(name='')
  # Change y axis label
  p <- p + scale_y_continuous(name='Chunk Size Distribution', trans='log10')
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

boxplot_it_3 <- function(df, label, facets=FALSE, fill=FALSE) {
  # Identify plot
  plot_label(label)
  # Basic boxplot
  if (fill) {
    p <- ggplot(df, aes(x=bug_type, y=count, fill=bug_type))
  } else {
    p <- ggplot(df, aes(x=bug_type, y=count))
  }
  p <- p + geom_boxplot(width=0.75, position=position_dodge(width=1))
  # Change x axis label
  p <- p + scale_x_discrete(name='')
  # Change y axis label
  p <- p + scale_y_continuous(name='Chunk Occurrence Distribution', trans='log10')
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
# Boxplot for chunk_size for project
#

boxplot_it_4 <- function(df, label, facets=FALSE, fill=FALSE) {
  # Identify plot
  plot_label(label)
  # Basic boxplot
  if (fill) {
    p <- ggplot(df, aes(x=project_full_name, y=count, fill=bug_type))
  } else {
    p <- ggplot(df, aes(x=project_full_name, y=count))
  }
  p <- p + geom_boxplot(width=0.75, position=position_dodge(width=1))
  # Change x axis label
  p <- p + scale_x_discrete(name='')
  # Change y axis label
  p <- p + scale_y_continuous(name='Chunk Occurrence Distribution', trans='log10')
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
chunk_df <- read.csv(CHUNK_DATA,  sep = ";", quote = "")


#Calculating chunk size
chunk_df$'chunk_size_green' <- gsub(".*,","",gsub("@.*","",substring(chunk_df$'chunk_header',3)))
chunk_df$'chunk_size_red' <- str_match(gsub("@.*","",substring(chunk_df$'chunk_header',3)),",\\s*(.*?)\\s* ")[,2]
chunk_df$'chunk_size_green'<- as.numeric(chunk_df$'chunk_size_green')
chunk_df$'chunk_size_red' <- as.numeric(chunk_df$'chunk_size_red')
chunk_df$'chunk_size' <- chunk_df$'chunk_size_red' + chunk_df$'chunk_size_green'
head(chunk_df)
chunk_df <- chunk_df[!chunk_df$'bug_type'=="",]
chunk_df <- na.omit(chunk_df)


cat('[INFO] Plotting chunk size distribution \n')

# Remove any existing output file and create a new one
unlink(OUTPUT_FILE)
pdf(file=OUTPUT_FILE, family='Helvetica', width=10, height=10)
# Add a cover page to the output file
plot_label('Distributions')

boxplot_it(chunk_df, 'Classical and Quantum bugs', facets=FALSE, fill=FALSE)
boxplot_it(chunk_df, 'Classical and Quantum bugs (same plot)', facets=FALSE, fill=TRUE)
boxplot_it(chunk_df, 'Classical and Quantum bugs (facets)', facets=TRUE, fill=FALSE)

boxplot_it_2(chunk_df, 'Overall', facets=FALSE, fill=FALSE)
boxplot_it_2(chunk_df, 'Classical and Quantum bugs (same plot)', facets=FALSE, fill=TRUE)
boxplot_it_2(chunk_df, 'Classical and Quantum bugs (facets)', facets=TRUE, fill=FALSE)
boxplot_it_2(chunk_df[chunk_df$'bug_type' == 'Classical' , ], 'Classical bugs', facets=FALSE, fill=FALSE)
boxplot_it_2(chunk_df[chunk_df$'bug_type' == 'Quantum' , ], 'Quantum bugs', facets=FALSE, fill=FALSE)

print('Computing mean values')

mean_df = chunk_df %>% group_by(bug_type) %>%
  summarise(mean = mean(chunk_size),
            .groups = 'drop')

print(tibble(mean_df), n=40)

mean_df_project = chunk_df %>% group_by(project_full_name,bug_type) %>%
  summarise(mean = mean(chunk_size),
            .groups = 'drop')

print(tibble(mean_df_project), n=40)

# Aggregate data
chunk_df$'count' <- 1
agg_count <- aggregate(x=count ~ project_full_name + bug_id + bug_type + fixed_file_path, data=chunk_df, FUN=sum)

print('Computing mean values for aggregated data')

mean_df = agg_count %>% group_by(bug_type) %>%
  summarise(mean = mean(count),
            .groups = 'drop')

print(tibble(mean_df), n=40)

mean_df_project = agg_count %>% group_by(project_full_name,bug_type) %>%
  summarise(mean = mean(count),
            .groups = 'drop')

print(tibble(mean_df_project), n=40)

boxplot_it_3(agg_count, 'Classical and Quantum bugs', facets=FALSE, fill=FALSE)
boxplot_it_3(agg_count, 'Classical and Quantum bugs (same plot)', facets=FALSE, fill=TRUE)
boxplot_it_3(agg_count, 'Classical and Quantum bugs (facets)', facets=TRUE, fill=FALSE)
boxplot_it_4(agg_count, 'Overall', facets=FALSE, fill=FALSE)
boxplot_it_4(agg_count, 'Classical and Quantum bugs (same plot)', facets=FALSE, fill=TRUE)
boxplot_it_4(agg_count, 'Classical and Quantum bugs (facets)', facets=TRUE, fill=FALSE)
boxplot_it_4(agg_count[agg_count$'bug_type' == 'Classical' , ], 'Classical bugs', facets=FALSE, fill=FALSE)
boxplot_it_4(agg_count[agg_count$'bug_type' == 'Quantum' , ], 'Quantum bugs', facets=FALSE, fill=FALSE)



