library(TopmedPipeline)
library(SeqArray)
sessionInfo()

args <- commandArgs(trailingOnly=T)
gdsfile <- args[1]
merged_gds_file <- args[2]

## gds file has two parts split by chromosome identifier
#gdsfile <- config["gds_file"]
#chr <- strsplit("1 2 3 4 5 6 7 8 9 10 11 12 13 14 15 16 17 18 19 20 21 22 X", " ", fixed=TRUE)[[1]]
#files <- sapply(chr, function(c) insertChromString(gdsfile, c, "gds_file"))

## write to the scratch disk of each node
gdsfile.tmp <- tempfile()
message("gds temporarily located at ", gdsfile.tmp)

## merge genotypes only (no other format or info fields)
seqMerge(gdsfile, gdsfile.tmp, fmt.var=character(), info.var=character(), storage.option="LZMA_RA")

## copy it
file.copy(gdsfile.tmp, merged_gds_file)
## remove the tmp file
file.remove(gdsfile.tmp)