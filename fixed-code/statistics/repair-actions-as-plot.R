# ------------------------------------------------------------------------------
# This script plots the distribution of repair actions as plot and generates a CSV containing the occurrences of the top30 unique repair actions.
# Usage:
#   Rscript repair-actions-as-plot.R
#     <fixed components input data file, e.g., ../data/generated/fixed-code-data.csv>
#     <buggy components input data file, e.g., ../../buggy-code/data/generated/buggy-code-data.csv>
#     <output pdf file, e.g., repair-actions-as-plot.pdf>
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
if (length(args) != 3) {
  stop('USAGE: Rscript repair-actions-as-plot.R <fixed components input data file, e.g., ../data/generated/fixed-code-data.csv> <buggy components input data file, e.g., ../../buggy-code/data/generated/buggy-code-data.csv> <output pdf file, e.g., repair-actions-as-plot.pdf>')
}

# Args
FIXED_COMPONENTS  <- args[1]
BUGGY_COMPONENTS <- args[2]
OUTPUT_FILE <- args[3]

# ------------------------------------------------------------------------- Main

# Load data
fix_df <- load_CSV(FIXED_COMPONENTS)
buggy_df <- load_CSV(BUGGY_COMPONENTS)

head(buggy_df)
head(fix_df)

## Rename columns to ease append
names(buggy_df)[names(buggy_df) == "buggy_line_number"] <- "fixed_line_number"
names(buggy_df)[names(buggy_df) == "buggy_component"] <- "fixed_component"
names(buggy_df)[names(buggy_df) == "buggy_file_path"] <- "fixed_file_path"

print('Merging component with edit action')
both_df <- rbind(fix_df , buggy_df)
both_df$edit_action[both_df$edit_action == 'U'] <- 'E'
both_df$edit_action[both_df$edit_action =='M'] <- 'E'
both_df$'component_and_edit_action' <- paste(both_df$'fixed_component',both_df$'edit_action', sep = '-')
head(both_df)

print('Group by bug_id, file, project and type and append all values into a string followed by sorting the string')
options(dplyr.summarise.inform = FALSE)
both_list_df <- both_df %>% group_by(fixed_file_path,bug_id,project_full_name,bug_type) %>% 
  summarize(component_and_edit_action = paste(sort(unique(component_and_edit_action)),collapse=","))
both_list_df$'component_and_edit_action' <- unname(sapply(both_list_df$'component_and_edit_action' , function(x) {
  paste(sort(trimws(strsplit(x[1], ',')[[1]])), collapse=',')} ))
print(both_list_df)

print(' Parsing df into bugs labelled as classical and quantum to compute unique repair actions')

quantum_df <- both_list_df[both_list_df$bug_type == 'Quantum' , ]
classical_df <- both_list_df[both_list_df$bug_type == 'Classical' , ]

print('Aggregating data by component_and_edit_action and counting occurrences of unique repair actions')

print('Quantum')

quantum_df$'count' = 1
quantum_agg_count <- aggregate(x=count ~ component_and_edit_action , data=quantum_df, FUN=sum)
quantum_agg_count <- transform(quantum_agg_count, size=nchar(as.character(component_and_edit_action)))
quantum_agg_count <- quantum_agg_count[order(-quantum_agg_count$count,quantum_agg_count$size),]
quantum_agg_count$'size' <- NULL
head(quantum_agg_count)
print(nrow(quantum_agg_count))

print('Writing top 30 repair operations for bugs labelled as Quantum to csv')
quantum_top30_df <- head(quantum_agg_count,30)
write.csv(quantum_top30_df,"quantum-repair-actions.csv", row.names = FALSE)

print('Classical')

classical_df$'count' = 1
classical_agg_count <- aggregate(x=count ~ component_and_edit_action , data=classical_df, FUN=sum)
classical_agg_count <- transform(classical_agg_count, size=nchar(as.character(component_and_edit_action)))
classical_agg_count <- classical_agg_count[order(-classical_agg_count$count,classical_agg_count$size),]
classical_agg_count$'size' <- NULL
head(classical_agg_count)
print(nrow(classical_agg_count))

print('Writing top 30 repair operations for bugs labelled as Classical to csv')
classical_top30_df <- head(classical_agg_count,30)
write.csv(classical_top30_df,"classical-repair-actions.csv", row.names = FALSE)

print('Overall')

both_list_df$'count' = 1
agg_count <- aggregate(x=count ~ component_and_edit_action , data=both_list_df, FUN=sum)
agg_count <- agg_count[order(-agg_count$count),]

print('Aggregating data by component_and_edit_action,file,bug_id and project and plot the distribution of unique repair actions per project')

agg_count_project <- aggregate(x=count ~ component_and_edit_action + project_full_name + bug_id + bug_type , data=both_list_df, FUN=sum)

# Remove any existing output file and create a new one
unlink(OUTPUT_FILE)
pdf(file=OUTPUT_FILE, family='Helvetica', width=7, height=4)
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
    p <- ggplot(df, aes(x=project_full_name, y=count, fill=bug_type))
  } else {
    p <- ggplot(df, aes(x=project_full_name, y=count))
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

boxplot_it(agg_count_project, 'Overall', facets=FALSE, fill=FALSE)
boxplot_it(agg_count_project, 'Classical and Quantum bugs (same plot)', facets=FALSE, fill=TRUE)
boxplot_it(agg_count_project, 'Classical and Quantum bugs (facets)', facets=TRUE, fill=FALSE)

print('Computing mean values')

mean_df = agg_count_project %>% group_by(project_full_name, bug_type) %>%
  summarise(mean = mean(count),
            .groups = 'drop')

print(tibble(mean_df), n=40)

### As Barplot

print('Plotting barplot for Quantum')

quantum_merge_df = merge(x=quantum_df,y=quantum_top30_df,by="component_and_edit_action")
quantum_merge_df$'wrap' = str_wrap(quantum_merge_df$'component_and_edit_action', width = 10)

plot_label('Number of bugs in which each top 30 repair action appears as a barplot')
p <- ggplot(aggregate(x=. ~ bug_id + bug_type + component_and_edit_action, data=quantum_merge_df, FUN=length), aes(x=component_and_edit_action, fill=bug_type)) + geom_bar(position=position_dodge(width=1))
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
p <- p + stat_count(geom='text', colour='black', size=1, aes(label=..count..), position=position_dodge(width=1.1), hjust=-0.15)
# Make it horizontal
p <- p + coord_flip()
# Attempt to fix long labels
p <- p + scale_x_discrete(guide = guide_axis(check.overlap = TRUE)) +  theme(axis.text.y = element_text(angle = 90))
# Print it
print(p)


print('Plotting barplot for Classical')

classical_merge_df = merge(x=classical_df,y=classical_top30_df,by="component_and_edit_action")
classical_merge_df$'wrap' = str_wrap(classical_merge_df$'component_and_edit_action', width = 10)

plot_label('Number of bugs in which each top 30 repair action appears as a barplot')
p <- ggplot(aggregate(x=. ~ bug_id + bug_type + component_and_edit_action, data=classical_merge_df, FUN=length), aes(x=component_and_edit_action, fill=bug_type)) + geom_bar(position=position_dodge(width=1))
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
p <- p + stat_count(geom='text', colour='black', size=1, aes(label=..count..), position=position_dodge(width=1.1), hjust=-0.15)
# Make it horizontal
p <- p + coord_flip()
# Attempt to fix long labels
p <- p + scale_x_discrete(guide = guide_axis(check.overlap = TRUE)) +  theme(axis.text.y = element_text(angle = 90))
# Print it
print(p)

#
# As UpSetR plot
#

# classical_df$'count' <- 1
# 
# for (bug_type in unique(classical_df$'bug_type')) {
#   columns <- colnames(df)
#   
#   for (keep_order in c(TRUE, FALSE)) {
#     plot_label(paste('UpSetR (agg by bug)', '\n', 'keep.order=', keep_order, '\n', bug_type, sep=''))
#     a <- dcast(aggregate(x=. ~ bug_id + component_and_edit_action, data=classical_df[classical_df$'bug_type' == bug_type, ], FUN=length),
#                bug_id ~ component_and_edit_action, value.var='component_and_edit_action', fun.aggregate=length)
#     a <- a[ , which(colnames(a) %!in% c('bug_id')) ]
#     p <- upset(a, sets=colnames(a), order.by=c('freq'), nintersects=NA, keep.order=keep_order, set_size.show=TRUE,
#                mb.ratio=c(0.40, 0.60), #point.size=3.5, line.size=1.1,
#                # text.scale=c(intersection size title, intersection size tick labels, set size title, set size tick labels, set names, numbers above bars).
#                text.scale=c(1, 1.2, 1, 1.2, 1.3, 1.1),
#                set_size.scale_max=100,
#                mainbar.y.label='Intersection Size', sets.x.label='Set Size',
#                themes=upset_modify_themes(
#                  list(
#                    'Intersection size'=theme(
#                      axis.text=element_text(size=1, face='bold')
#                    )
#                  )
#                )
#                
#                )
#     print(p)
#   }
# }