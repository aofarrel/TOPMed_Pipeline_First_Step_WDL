library(TopmedPipeline)
library(SeqVarTools)
library(SNPRelate)
sessionInfo()

args <- commandArgs(trailingOnly=T)
gdsfile <- args[1]
autosome_only <- args[2]
exclude_pca_corr <- args[3]
genome_build <- args[4]
ld_r_threshold <- args[5]
ld_win_size <- args[6]
maf_threshold <- args[7]
missing_threshold <- args[8]


#argp <- add_argument(argp, "--chromosome", help="chromosome (1-24 or X,Y)", type="character")
#chr <- intToChr(argv$chromosome)
chr <- NA

# gds file can have two parts split by chromosome identifier,
# but we're gonna hope that's not the case here!
outfile <- "pruned_variants.RData"
#varfile <- config["variant_include_file"]
if (!is.na(chr)) {
    message("Running on chromosome ", chr)
    bychrfile <- grepl(" ", gdsfile) # do we have one file per chromosome?
    gdsfile <- insertChromString(gdsfile, chr)
    outfile <- insertChromString(outfile, chr, err="out_file")
    #varfile <- insertChromString(varfile, chr)
}

gds <- seqOpen(gdsfile)

# if (!is.na(config["sample_include_file"])) {
#     sample.id <- getobj(config["sample_include_file"])
#     message("Using ", length(sample.id), " samples")
# } else {
#     sample.id <- NULL
#     message("Using all samples")
# }

# if (!is.na(varfile)) {
#     filterByFile(gds, varfile)
# }

## if we have a chromosome indicator but only one gds file, select chromosome
if (!is.na(chr) && !bychrfile) {
    filterByChrom(gds, chr)
}

filterByPass(gds)
filterBySNV(gds)
if (as.logical(exclude_pca_corr)) {
    filterByPCAcorr(gds, build=genome_build)
}

variant.id <- seqGetData(gds, "variant.id")
message("Using ", length(variant.id), " variants")

auto.only <- as.logical(autosome_only)
if (chr %in% "X" & auto.only) stop("Set autosome_only=FALSE to prune X chrom variants")
maf <- as.numeric(maf_threshold)
miss <- as.numeric(missing_threshold)
r <- as.numeric(ld_r_threshold)
win <- as.numeric(ld_win_size) * 1e6

print(auto.only)
print(maf)
print(miss)
print(r)
print(win)

set.seed(100) # make pruned SNPs reproducible

# sample.id set to NULL as we do not support sample_include_file
snpset <- snpgdsLDpruning(gds, sample.id=NULL, snp.id=variant.id,
                          autosome.only=auto.only, maf=maf, missing.rate=miss,
                          method="corr", slide.max.bp=win, ld.threshold=r,
                          num.thread=countThreads())

pruned <- unlist(snpset, use.names=FALSE)
save(pruned, file=outfile)

seqClose(gds)

# mem stats
ms <- gc()
cat(">>> Max memory: ", ms[1,6]+ms[2,6], " MB\n")
