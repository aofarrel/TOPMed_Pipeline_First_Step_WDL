# TOPMed Analysis Pipeline -- WDL Version

![help wanted](https://img.shields.io/badge/help-wanted-red)**WIP; not suitable for published use**![help wanted](https://img.shields.io/badge/help-wanted-red)
---
[![WDL 1.0 shield](https://img.shields.io/badge/WDL-1.0-lightgrey.svg)](https://github.com/openwdl/wdl/blob/main/versions/1.0/SPEC.md)  
This is a collection of several WDL files which attempt to implement some components of the [University of Washington TOPMed pipeline](https://github.com/UW-GAC/analysis_pipeline). Rather than running as a Python pipeline, this takes the R scripts which the Python pipeline is calling and wraps them into various WDL tasks. The original goal of this task was to provide sample preparation options for TOPMed Freeze 8 users on Terra, who previously had to work with an unoptimized Jupyter notebook, but it may have wider applications than that. Still, to that end, it is **not complete** and it should not be used for publications at this point in time.

The current components are as follows:

* a_vcftogds.wdl -- converts vcf.gz input into gds
* b_ldprune.wdl -- performs LD pruning
* topmed.wdl -- combination of the other WDLs

## Bonuses
* The original script required a space to be included in input files. This is no longer necessary.
* As it works in a Docker container, it does not have any external dependencies other than the usual setup required for [WDL](https://software.broadinstitute.org/wdl/documentation/quickstart) and [Cromwell](http://cromwell.readthedocs.io/en/develop/).

## Limitations
* Functionality is not one-to-one with the UW pipeline
* Currently this pipeline only accepts vcf.gz files
* b_ldprune.wdl may draw too much memory locally and get SIGKILLed; this is still being investigated

## General notes
Nearly all scripts require a GDS file in SeqArray format. Phenotype files should be an AnnotatedDataFrame saved in an RData file. See `?AnnotatedDataFrame` or the SeqVarTools documentation for details. Example files are provided in `testdata`.

The original verison of this pipeline allowed for running on a per-chromosome basis. At the moment this is not officially implemented, as it is expected people will be using this for a GWAS and therefore tossing a bunch of single-chromosome VCFs at it rather than trying to list out every single one.

The original script had arguments relating to runtime such as `ncores` and `cluster_type` that do not apply to WDL. Please familarize yourself with the [runtime attributes of WDL](https://cromwell.readthedocs.io/en/stable/RuntimeAttributes/) if you are unsure how your settings may transfer.

# Conversion to GDS (a_vcftogds.wdl)
This script converts VCF (one per chromosome) to GDS files, discarding non-genotype FORMAT fields.  

...and that's it. The other R scripts don't *quite* work yet!

### Required Inputs
* vcf : an *array of vcf files* in vcf, .vcf.bgz, or .vcf.gz format
* vcfgds_disk : *int* of disk space to allot for vcfToGds.R
* vcfgds_memory : *int* of memory to allot for vcfToGds.R
* uniquevars_disk
* uniquevars_memory
* checkgds_disk
* checkgds_memory

### Outputs
GDS file matching the name of the input vds with ".gds" appeneded to the end.

# LD Prune (b_ldprune.wdl)
This stage automatically takes in the GDS output of the previous step.
1. ld_pruning.R, based on [UoW ld_pruning.R](https://github.com/UW-GAC/analysis_pipeline/blob/master/R/ld_pruning.R)
2. The subset_gds.R, based on [UoW subset_gds.R](https://github.com/UW-GAC/analysis_pipeline/blob/master/R/subset_gds.R)
Merging and checking merged gds are being worked on.

### Required Inputs
* ldprune_disk : *int* of disk space to allot for ld_pruning.R
* ldprune_memory : *int* of memory to allot for ld_pruning.R
* subsetgds_disk
* subsetgds_memory
* merge_disk
* merge_memory
* checkmerged_disk
* checkmerged_memory
Note that b_ldprune.wdl also requires *Array[File]* gds_files because it doesn't run the vcf to gds conversion that topmed.wdl runs.

### Optional Inputs
| parameter | type | default value | description |
| --------- | ---- | ------------- | ------------ |
| autosome_only     | bool | FALSE | Only include autosomes in LD pruning.| 
| exclude_pca_corr  | bool | TRUE  | Exclude variants in regions with high correlation with PCs (HLA, LCT, inversions).| 
| genome_build      | str  | hg38 | Genome build, used to define correlation regions.| 
| ld_r_threshold    | float| 0.32  | r threshold for LD pruning. Default is r^2 = 0.1.| 
| ld_win_size      | int  | 10    | Sliding window size in Mb for LD pruning.| 
| maf_threshold     | float| 0.01  | Minimum MAF for variants used in LD pruning.| 
| missing_threshold | int  | 0.01  | Maximum missing call rate for variants. | 

Be aware that the default for autosome_only is the **opposite** of the default of [the pipeline this is based on](https://github.com/UW-GAC/analysis_pipeline), as it expected users will be inputing one VCF per chr, therefore if they wanted to exclude not-autosomes then they'd have excluded them from the inputs.

### Outputs
A Rdata file of the pruned variants and subsetted GDS files.

------

#### Authors
Contributing authors to the WDLs in this fork include:
* Ash O'Farrell (aofarrel@ucsc.edu)
* Tim Majarian (tmajaria@broadinstitute.org) -- original [GDStoVCF WDL](https://github.com/manning-lab/vcfToGds) that this project was originally a fork of
