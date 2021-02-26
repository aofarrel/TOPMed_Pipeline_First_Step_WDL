library(TopmedPipeline)
library(SeqArray)
sessionInfo()

args <- commandArgs(trailingOnly=T)
gdsfile <- args[1]
outfile <- args[2]

#argp <- add_argument(argp, "--chromosome", help="chromosome (1-24 or X,Y)", type="character")
#chr <- intToChr(argv$chromosome)

## gds file can have two parts split by chromosome identifier
#varfile <- config["variant_include_file"]
#if (!is.na(chr)) {
    #gdsfile <- insertChromString(gdsfile, chr)
    #outfile <- insertChromString(outfile, chr, err="subset_gds_file")
    #varfile <- insertChromString(varfile, chr)
#}

gds <- seqOpen(gdsfile)

sample.id <- NULL
variant.id <- NULL

seqSetFilter(gds, sample.id=sample.id, variant.id=variant.id)
seqExport(gds, outfile, fmt.var=character(), info.var=character())

seqClose(gds)