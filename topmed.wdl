version 1.0

# Cromwell has a bug where it cannot properly recognize certain comments as, well, comments
# Lines marked with "##goto X" are how I have to keep track of the location of certain
# commented-out things; basically putting the problematic comment in a place Cromwell does
# not parse.

task runGds {
	input {
		File vcf
		Int disk
		Int memory
		String output_file_name = basename(sub(vcf, "\\.vcf.gz$", ".gds"))
	}
	
	command {
		set -eux -o pipefail

		echo "Calling R script vcfToGds.R"

		R --vanilla --args "~{vcf}" < /analysis_pipeline_WDL/R/vcf2gds.R
	}

	runtime {
		docker: "quay.io/aofarrel/topmed-pipeline-wdl:circleci-push"
		disks: "local-disk ${disk} SSD"
		bootDiskSizeGb: 6
		memory: "${memory} GB"
	}

	output {
		File out = output_file_name
	}
}

task runUniqueVars {
	input {
		Array[File] gds
		File debugScript
		Int chr_kind = 0
		String output_file_name = "unique.gds"
	}

	command {
		set -eux -o pipefail

		echo "Doing nothing so we can move on to check_gds"

		#echo "Calling uniqueVariantIDs.R"

		#R --vanilla --args "~{sep="," gds}" ~{chr_kind} < ~{debugScript}
	}

	runtime {
		docker: "quay.io/aofarrel/topmed-pipeline-wdl:circleci-push"
	}

	output {
		##goto C
		Array[File] out = gds
	}
}
##goto C
# should be Array[File] out = output_file_name

task runCheckGds {
	input {
		File gds
		Array[File] vcfs
		File debugScript
		# there is a small chance that the vcf2gds sub made more than
		# one replacement
		String finaloption = basename(sub(gds, "\\.gds$", ".vcf.gz"))
	}

	command {
		set -eux -o pipefail

		echo "Searching for relevent VCF"

		python << CODE
		for file in ~{sep="," vcfs}:
			print(file)
		>>
		
		echo "Calling check_gds.R"

		# just pass in one VCF, hopefully the correct one
		##goto D
	}

	runtime {
		docker: "quay.io/aofarrel/topmed-pipeline-wdl:circleci-push"
	}
}
##goto D
#R --vanilla --args "~{gds}" ~{vcfs} < ~{debugScript}

task runLdPrune{
	input {

		# Array version
		##goto A

		# File version
		File gds

		# ld prune stuff
		Boolean autosome_only
		Boolean exclude_pca_corr
		String genome_build
		Float ld_r_threshold
		Int ld_win_size
		Float maf_threshold
		Float missing_threshold

		# runtime attributes
		Int disk
		Int memory

	}

	command {
		set -eux -o pipefail

		echo "Calling R script ld_pruning.R"

		# File version
		R --vanilla --args "~{gds}" ~{autosome_only} ~{exclude_pca_corr} ~{genome_build} ~{ld_r_threshold} ~{ld_win_size} ~{maf_threshold} ~{missing_threshold} < /analysis_pipeline_WDL/R/ld_pruning.R

		# Array version
		##goto B
	}

	runtime {
		docker: "quay.io/aofarrel/topmed-pipeline-wdl:circleci-push"
		disks: "local-disk ${disk} SSD"
		bootDiskSizeGb: 6
		memory: "${memory} GB"
	}

	output {
		File out = "pruned_variants.RData"
	}

}
##goto A
		#File gds
##goto B
		#R --vanilla --args ~{sep="," gds} ~{autosome_only} ~{exclude_pca_corr} ~{genome_build} ~{ld_r_threshold} ~{ld_win_size} ~{maf_threshold} ~{missing_threshold} < ~{debugScript}

task runSubsetGds {
	input {
		File gds
		String output_name
	}
	command {
		set -eux -o pipefail

		echo "Calling R script runSubsetGds.R"

		R --vanilla --args "~{gds}" ~{output_name} < /analysis_pipeline_WDL/R/subset_gds.R
	}

	runtime {
		docker: "quay.io/aofarrel/topmed-pipeline-wdl:circleci-push"
	}

	output {
		File out = "subsetted.gds"
	}

}

workflow topmed {
	input {
		Array[File] vcf_files
		Int vcfgds_disk
		Int vcfgds_memory

		# R scripts that aren't hardcoded yet
		File uniquevars_debug
		File checkgds_debug

		# ld prune
		Int ldprune_disk
		Int ldprune_memory
		Boolean? ldprune_autosome_only
		Boolean? ldprune_exclude_pca_corr
		String? ldprune_genome_build
		Float? ldprune_ld_r_threshold
		Int? ldprune_ld_win_size
		Float? ldprune_maf_threshold
		Float? ldprune_missing_threshold

		# unique var IDs
		Int uniquevars_memory
		Int uniquevars_disk
	}

	scatter(vcf_file in vcf_files) {
		call runGds {
			input:
				vcf = vcf_file,
				disk = vcfgds_disk,
				memory = vcfgds_memory
		}
	}
	
	call runUniqueVars {
		input:
			gds = runGds.out,
			debugScript = uniquevars_debug
	}
	
	scatter(gds in runUniqueVars.out) {
		call runCheckGds {
			input:
				gds = gds,
				vcfs = vcf_files,
				debugScript = checkgds_debug
		}
	}

	meta {
		author: "Ash O'Farrell"
		email: "aofarrel@ucsc.edu"
	}
}