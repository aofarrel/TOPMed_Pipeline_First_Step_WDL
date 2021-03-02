# This project started as a fork of manning-lab/vcfToGds and contained a copy of
# this file by Tim Majarian.
# Tim's copy is here: https://github.com/manning-lab/vcfToGds/blob/master/vcfToGds.R
####################################################################################
# Adapted from:
# 	Author: topmed analysis pipeline, smgogarten
# 	Link: https://github.com/smgogarten/analysis_pipeline/blob/master/R/vcf2gds.R

library(SeqArray)

args <- commandArgs(trailingOnly=T)
vcf <- args[1]

# remove extension, can be .vcf, .vcf.gz, .vcf.bgz
gds_out <- paste0(sub(".vcf.bgz$|.vcf.gz$|.vcf$", "", basename(vcf)), " .gds")

seqVCF2GDS(vcf, gds_out, storage.option="LZMA_RA", verbose=TRUE)