# Adapted from TOPMed analysis pipeline

library(SeqArray)
library(TopmedPipeline)
sessionInfo()

args <- commandArgs(trailingOnly=T)
gds_file <- args[1]
chr_kind <- args[2]

# Some TOPMed projects include Y chromosome in their files
# Not sure if this will work on such files; for now this part
# is more of a scaffold

if (chr_kind == 0) {
    chrtype <- "1 2 3 4 5 6 7 8 9 10 11 12 13 14 15 16 17 18 19 20 21 22 X"
}
if (chr_kind == 1) {
    chrtype <- "Y"
}

## gds file has two parts split by chromosome identifier

chr <- strsplit(chrtype, " ", fixed=TRUE)[[1]]
######################## debug zone ########################
# insertChromString() results in downstream file not found
# so we'll remove it
############################################################
#gds.files <- sapply(chr, function(c) insertChromString(unname(gds_file), c, "gds_file"))
gds.files <- gds_file
gds.list <- lapply(gds.files, seqOpen, readonly=FALSE)

######################## debug zone ########################
## exit gracefully if we only have one file
## this might be a bad idea; 1000 genomes files can throw issues with plink
#if (length(gds.list) == 1) {
    #message("Only one GDS file; no changes needed. Exiting gracefully.")
    #q(save="no", status=0)
#}

# due to how scattering in WDL works, the above will always
# exit gracefully if left uncommented. later on in we use
# PLINK, which throws a fit if variant IDs are not unique,
# so we probably cannot allow for this to be uncommented.
############################################################

## get total number of variants
var.length <- sapply(gds.list, function(x) {
    objdesp.gdsn(index.gdsn(x, "variant.id"))$dim
})
seqClose(gds.list[[1]])

######################## debug zone ########################
# we crash in the following line
#
# id.new[[c]] <- (last.id + 1):(last.id + var.length[c])
#
# Error in (last.id + 1):(last.id + var.length[c]) : NA/NaN argument
#
# It is var.length(c) that is NA and causing this error
######################## debug zone ########################

id.new <- list(1:var.length[1])
message("var.length[1]")
message(var.length[1])
message("length(chr)")
message(length(chr))
for (c in 2:length(chr)) {
    message("c")
    message(c)
    id.prev <- id.new[[c-1]]
    last.id <- id.prev[length(id.prev)]
    #message("id.prev")
    #message(id.prev)
    message("last.id")
    message(last.id)
    message("var.length[c]")
    message(var.length[c])
    id.new[[c]] <- (last.id + 1):(last.id + var.length[c]) # crash because var.length[c] is NA
    stopifnot(length(id.new[[c]]) == var.length[c])
}
######################## debug zone ########################
# if we comment out the crashing section above, this crashes
# at seqClose(gds.list[[c]]) due to subscript out of bounds
######################## debug zone ########################


for (c in 2:length(chr)) {
    node <- index.gdsn(gds.list[[c]], "variant.id")
    desc <- objdesp.gdsn(node)
    stopifnot(desc$dim == length(id.new[[c]]))
    compress <- desc$compress
    compression.gdsn(node, "")
    write.gdsn(node, id.new[[c]])
    compression.gdsn(node, compress)
    seqClose(gds.list[[c]])
}

# mem stats
ms <- gc()
cat(">>> Max memory: ", ms[1,6]+ms[2,6], " MB\n")