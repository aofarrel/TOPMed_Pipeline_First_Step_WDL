version 1.0

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
		String output_name = "subsetted.gds"
		# runtime attr
		Int disk
		Int memory
	}
	command {
		set -eux -o pipefail
		echo "Calling R script runSubsetGds.R"
		R --vanilla --args "~{gds}" ~{output_name} < /analysis_pipeline_WDL/R/subset_gds.R
	}
	runtime {
		docker: "quay.io/aofarrel/topmed-pipeline-wdl:circleci-push"
		disks: "local-disk ${disk} SSD"
		bootDiskSizeGb: 6
		memory: "${memory} GB"
	}
	output {
		File out = "subsetted.gds"
	}
}

task runMergeGds {
	input {
		Array[File] gds_array
		String merged_name
		# runtime attr
		Int disk
		Int memory
	}
	command {
		set -eux -o pipefail
		echo "Skipping merge script..."
		#echo "Calling R script runMergeGds.R"
		#R --vanilla --args ~{sep="," gds_array} ~{merged_name} < ~{debugScript}
	}
	runtime {
		docker: "quay.io/aofarrel/topmed-pipeline-wdl:circleci-push"
		disks: "local-disk ${disk} SSD"
		bootDiskSizeGb: 6
		memory: "${memory} GB"
	}
	output {
		File out = "merged.gds"
	}
}

task runCheckMergedGds {
	input {
		Array[File] gds_array
		String merged_name
		# runtime attr
		Int disk
		Int memory
	}
	command {
		set -eux -o pipefail
		echo "Doing nothing..."
	}
	runtime {
		docker: "quay.io/aofarrel/topmed-pipeline-wdl:circleci-push"
		disks: "local-disk ${disk} SSD"
		bootDiskSizeGb: 6
		memory: "${memory} GB"
	}
}

workflow topmed {
	input {
		Array[File] gds_files

		# R scripts not already in container
		File merge_debugScript
		File checkmerged_debugScript

		# ld prune
		Boolean? ldprune_autosome_only
		Boolean? ldprune_exclude_pca_corr
		String? ldprune_genome_build
		Float? ldprune_ld_r_threshold
		Int? ldprune_ld_win_size
		Float? ldprune_maf_threshold
		Float? ldprune_missing_threshold

		# runtime attributes
		# [4] ldprune
		Int ldprune_disk
		Int ldprune_memory
		# [5] subsetGDS
		Int subsetgds_disk
		Int subsetgds_memory
		# [6] mergegds
		Int merge_disk
		Int merge_memory
		# [7] checkmergedgds
		Int checkmerge_disk
		Int checkmerge_memory

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
				disk = checkgds_disk,
				memory = checkgds_memory
		}
	}

	call runMergeGds {
		input:
			gds_array = runSubsetGds.out,
			debugScript = merge_debugScript,
			disk = merge_disk,
			memory = merge_memory
	}

	call runCheckMergedGds {
		input:
			gds_array = runSubsetGds.out,
			debugScript = checkmerged_debugScript,
			disk = checkmerged_disk,
			memory = checkmerged_memory,
	}
	meta {
		author: "Ash O'Farrell"
		email: "aofarrel@ucsc.edu"
	}
}