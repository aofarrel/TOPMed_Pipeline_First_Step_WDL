# TOPMed Analysis Pipeline -- WDL Version

![help wanted](https://img.shields.io/badge/help-wanted-red)**WIP; not suitable for published use**![help wanted](https://img.shields.io/badge/help-wanted-red)
---
[![WDL 1.0 shield](https://img.shields.io/badge/WDL-1.0-lightgrey.svg)](https://github.com/openwdl/wdl/blob/main/versions/1.0/SPEC.md)  
This is a collection of several WDL files which attempt to implement some components of the [University of Washington TOPMed pipeline](https://github.com/UW-GAC/analysis_pipeline). Rather than running as a Python pipeline, this takes the R scripts which the Python pipeline is calling and wraps them into various WDL tasks. The original goal of this task was to provide sample preparation options for TOPMed Freeze 8 users on Terra, who previously had to work with an unoptimized Jupyter notebook, but it may have wider applications than that. Still, to that end, it is **not complete** and it should not be used for publications at this point in time.

Example files are provided in `testdata`.

The original script had arguments relating to runtime such as `ncores` and `cluster_type` that do not apply to WDL. Please familarize yourself with the [runtime attributes of WDL](https://cromwell.readthedocs.io/en/stable/RuntimeAttributes/) if you are unsure how your settings may transfer.

The current component, a_vcftogds.wdl, converts vcf.gz/vcf/vcf.bgz/bcf input into gds, gives all converted gds files unique varient IDs, and optionally checks the resulting gds files with their original vcf inputs for consistency. This represents [the first "chunk" of the original pipeline](https://github.com/UW-GAC/analysis_pipeline#conversion-to-gds) minus the currently-not-recommend optional merge. Merging is still planned to be supported, but only after linkage disequilbrium (also in-progress) is calculated.

## Bonuses
* The original script required a space to be included in input files. This is no longer necessary.
* As it works in a Docker container, it does not have any external dependencies other than the usual setup required for [WDL](https://software.broadinstitute.org/wdl/documentation/quickstart) and [Cromwell](http://cromwell.readthedocs.io/en/develop/).

## Limitations
* Functionality is not one-to-one with the UW pipeline
* Due to how Cromwell works, local runs may draw too much memory (see below)

#### Advice for running locally
If you are running on a local machine, we do not recommend running this on all 23 chromosomes, even on the provided downsampled test data. Cromwell does not support local resource mangement in the same way it does on GCS and other platforms. This can result in a sigkill or locking up Docker, especially when dealing with scattered tasks. [There is a way to reduce the number of simultaneous tasks Cromwell will run](https://github.com/broadinstitute/cromwell/blob/develop/docs/cromwell_features/HogFactors.md), but this doesn't solve every issue. Even if only running on a small number of chromosomes, it is still possible for Cromwell to lock up Docker. Luckily these lockups tend to follow a pattern and can be resolved in a few minutes -- if a task's instance(s) transfer to WaitingForReturnCode but never seem to do anything else, control-C out it, restart Docker, and try again.

# Conversion to GDS (a_vcftogds.wdl)
This script converts VCF, one per chromosome, to GDS files, discarding non-genotype FORMAT fields by default (but this can be changed, see optional inputs).  

### Required Inputs
* vcf : an *array of vcf files* in vcf, .vcf.bgz, .vcf.gz, .bcf, or any combination thereof format
* vcfgds_disk : *int* of disk space to allot for vcfToGds.R
* vcfgds_memory : *int* of memory to allot for vcfToGds.R
* uniquevars_disk
* uniquevars_memory
* checkgds_disk
* checkgds_memory
Due to how this step localizes files, uniquevars_disk should be at least double the size of your input files.

### Optional Inputs
* check_gds : *boolean* -- Run the checkGDS step. Defaults to false, because this step is computationally intense. It is **highly recommended** to skip this step on modern topmed data, as it could take literal days.
* format : *array of strings* of VCF FORMAT fields to carry over into the GDS. Default is GT, ie, non-genotype fields are discarded.

### Outputs
GDS file matching the name of the input vds with ".gds" appeneded to the end.

------

#### Author
Ash O'Farrell (aofarrel@ucsc.edu)  
Please see the original TOPMed Pipeline for contributors to the overall structure and R scripts that this WDL relies upon.
