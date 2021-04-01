# Conversion to GDS (vcf-to-gds-wf.wdl)
This script converts vcf.gz/vcf/vcf.bgz/bcf, one per chromosome, to GDS files, discarding non-genotype FORMAT fields by default (but this can be changed, see optional inputs). It then provides each variant across the files with unique variant IDs for later compatiability with PLINK, and optionally checks the resulting GDS files against their original inputs for consistency. This represents [the first "chunk" of the original pipeline](https://github.com/UW-GAC/analysis_pipeline#conversion-to-gds) minus the currently-not-recommend optional merge. Merging is still planned to be supported, but only after linkage disequilbrium (also in-progress) is calculated.  

### Required Inputs
* vcf : an *array of vcf files* in vcf, .vcf.bgz, .vcf.gz, .bcf, or any combination thereof format
* vcfgds_disk : *int* of disk space to allot for vcfToGds.R
* vcfgds_memory : *int* of memory to allot for vcfToGds.R
* uniquevars_disk
* uniquevars_memory
* checkgds_disk
* checkgds_memory  
Due to how the unique variant IDs step localizes files, uniquevars_disk should be at least double the size of your input files.

### Optional Inputs
* check_gds : *boolean* -- Run the checkGDS step. Defaults to false, because this step is computationally intense. It is **highly recommended** to skip this step on modern topmed data, as it could take literal days.
* format : *array of strings* of VCF FORMAT fields to carry over into the GDS. Default is GT, ie, non-genotype fields are discarded.

### Outputs
unique_variant_id_gds_per_chr: Array[File] of GDS files, matching the name of the input vds with ".gds" appended to the end, and with unique variant IDs across the whole genome.
