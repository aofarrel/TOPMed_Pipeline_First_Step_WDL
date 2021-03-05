
library(TopmedPipeline)
library(SeqArray)
library(SNPRelate)
sessionInfo()

args <- commandArgs(trailingOnly=T)
gds_file <- args[1]
bed_file <- args[2]
sample_include_file <- NA
variant_include_file <- NA

gds <- seqOpen(gds_file)

if (!is.na(variant_include_file)) {
    filterByFile(gds, variant_include_file)
}

if (!is.na(sample_include_file)) {
    sample.id <- getobj(sample_include_file)
    seqSetFilter(gds, sample.id=sample.id)
}

snpfile <- tempfile()
seqGDS2SNP(gds, snpfile)
seqClose(gds)

gds <- snpgdsOpen(snpfile)
snpgdsGDS2BED(gds, bed_file)
snpgdsClose(gds)

unlink(snpfile)
