# R repository
repository="http://cran.us.r-project.org"
# Install packages
install.packages('this.path', repos=repository)
install.packages('data.table', repos=repository)
install.packages('stringr', repos=repository)
install.packages('ggplot2', repos=repository)
install.packages('extrafont', repos=repository)
install.packages('testthat', repos=repository)
# Load libraries (aka runtime sanity check)
library('this.path')
library('data.table')
library('stringr')
library('ggplot2')
library('extrafont')
library('testthat')
# Exit
quit(save="no", status=0)
