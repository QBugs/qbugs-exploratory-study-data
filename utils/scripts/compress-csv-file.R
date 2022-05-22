# ------------------------------------------------------------------------------
# Compress (using gzip) a given CSV file.
#
# Usage:
# Rscript compress-csv-file.R <input file> <output file>
#
# ------------------------------------------------------------------------------

library('data.table') # install.packages('data.table')

args = commandArgs(trailingOnly=TRUE)
if (length(args) < 2) {
  stop("USAGE: compress-csv-file.R <input file> <output file>")
}

# Args
INPUT_FILE  <- args[1]
OUTPUT_FILE <- args[2]

cat("Loading data... ", date(), "\n", sep="")
df <- read.csv(INPUT_FILE, header=TRUE, stringsAsFactors=FALSE)

cat("Data is loaded. Starting compressing it... ", date(), "\n", sep="")
write.table(df, file=gzfile(OUTPUT_FILE))

cat("Data is compressed and saved. Starting reading it back... ", date(), "\n", sep="")
x <- read.table(gzfile(OUTPUT_FILE), header=TRUE, stringsAsFactors=FALSE)

cat("Data read back. DONE! ", date(), "\n", sep="")
quit(status=0)

# EOF
