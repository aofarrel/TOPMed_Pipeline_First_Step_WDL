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
		String output_file_name = basename(sub(vcf, "\\.vcf.gz$", " .gds"))
		File debug
	}
	
	command {
		set -eux -o pipefail

		echo "Calling R script vcfToGds.R"

		R --vanilla --args "~{vcf}" < ~{debug}
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
		R --vanilla --args ~{gds} ~{autosome_only} ~{exclude_pca_corr} ~{genome_build} ~{ld_r_threshold} ~{ld_win_size} ~{maf_threshold} ~{missing_threshold} < /analysis_pipeline_WDL/R/ld_pruning.R

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

		R --vanilla --args ~{gds} ~{output_name} < /analysis_pipeline_WDL/R/subset_gds.R
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

		File debug
		File uniquevars_debug
		File checkgds_debug

		# ld prune stuff
		Int ldprune_disk
		Int ldprune_memory
		
		Boolean? ldprune_autosome_only
		Boolean? ldprune_exclude_pca_corr
		String? ldprune_genome_build
		Float? ldprune_ld_r_threshold
		Int? ldprune_ld_win_size
		Float? ldprune_maf_threshold
		Float? ldprune_missing_threshold
	}

	scatter(vcf_file in vcf_files) {
		call runGds {
			input:
				vcf = vcf_file,
				disk = vcfgds_disk,
				memory = vcfgds_memory,
				debug = debug
		}
		call runUniqueVars {
			input:
				gds = runGds.out,
				debugScript = uniquevars_debug
		}
		call runCheckGds {
			input:
				gds = runUniqueVars.out,
				vcf = vcf_file,
				debugScript = checkgds_debug
		}
	}

	scatter(gds_file in runGds.out) { # Comment out for array version
		call runLdPrune {
			input:
				gds = gds_file, # File version
				#gds = runGds.out, # Array version
				disk = ldprune_disk,
				memory = ldprune_memory,
				autosome_only = select_first([ldprune_autosome_only, false]),
				exclude_pca_corr = select_first([ldprune_exclude_pca_corr, true]),
				genome_build = select_first([ldprune_genome_build, "hg38"]),
				ld_r_threshold = select_first([ldprune_ld_r_threshold, 0.32]),
				ld_win_size = select_first([ldprune_ld_win_size, 10]),
				maf_threshold = select_first([ldprune_maf_threshold, 0.01]),
				missing_threshold = select_first([ldprune_missing_threshold, 0.01])
		}
	} 

	scatter(gds_file in runGds.out) {
		call runSubsetGds {
			input:
				gds = gds_file,
				output_name = "subsetted.gds"
		}
	}

	meta {
		author: "Ash O'Farrell"
		email: "aofarrel@ucsc.edu"
	}
}