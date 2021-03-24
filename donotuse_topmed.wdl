version 1.0

# --vcf2gds--
# [1] vcf2gds.R
#	* fully implemented
# [2] unique_variant_ids.R
#	* partially implemented
# [3] check_gds.R
#	* partially implemented
# --ldpruning--
# [4] ld_pruning.R
#	* fully implemented
# [5] subset_gds.R
#	* fully implemented
# [6] merge_gds.R
#	* partially implemented
# [7] check_merged_gds.R
#	* skeleton
# --king--
# [8] gds2bed.R
#	* skeleton
# [9] plink --make-bed
#	* skeleton
# [10] king --ibdseg
#	* skeleton
# [11] kinship_plots.R
#	* skeleton
# [12] king_to_matrix.R
#	* skeleton
#
# Add'l notes:
# Cromwell has a bug where it cannot properly recognize certain comments as, well, comments
# Lines marked with "##goto X" are how I have to keep track of the location of certain
# commented-out things; basically putting the problematic comment in a place Cromwell does
# not parse.

# -----------------------------------------------------
# ------------------------vcf2gds----------------------
# -----------------------------------------------------

# [1] runGDS -- converts a VCF file into a GDS file
task runGds {
	input {
		File vcf
		String output_file_name = basename(sub(vcf, "\\.vcf.gz$", ".gds"))
		# runtime attributes
		Int disk
		Int memory
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

# [2] uniqueVars -- attempts to give unique variant IDS
task runUniqueVars {
	input {
		Array[File] gds
		File debugScript
		Int chr_kind = 0
		String output_file_name = "unique.gds"
		# runtime attr
		Int disk
		Int memory

		File debugScript
	}
	command {
		set -eux -o pipefail
		echo "Doing nothing..."
		#echo "Calling uniqueVariantIDs.R"
		#R --vanilla --args "~{sep="," gds}" ~{chr_kind} < ~{debugScript}
	}
	runtime {
		docker: "quay.io/aofarrel/topmed-pipeline-wdl:circleci-push"
		disks: "local-disk ${disk} SSD"
		bootDiskSizeGb: 6
		memory: "${memory} GB"
	}
	output {
		##goto C
		Array[File] out = gds
	}
}
##goto C
# should be Array[File] out = output_file_name

# [3] checkGDS - check a GDS file against its supposed VCF input
task runCheckGds {
	input {
		File gds
		Array[File] vcfs
		# there is a small chance that the vcf2gds sub made more than
		# one replacement but we're gonna hope that's not the case
		String gzvcf = basename(sub(gds, "\\.gds$", ".vcf.gz"))
		# runtime attr
		Int disk
		Int memory

		File debugScript
	}

	command <<<
		# triple carrot syntax is required for this command section
		set -eux -o pipefail
		echo "Searching for VCF"
		# doing this in python is probably not ideal
		# in fact, this whole block is pretty cursed
		python << CODE
		import os
		py_vcfarray = ['~{sep="','" vcfs}']
		for py_file in py_vcfarray:
			py_base = os.path.basename(py_file)
			if(py_base == "~{gzvcf}"):
				print("Yep!")
				f = open("correctvcf.txt", "a")
				f.write(py_file)
				f.close()
				exit()
		exit(1)  # if we don't find a VCF, fail
		CODE

		READFILENAME=$(head correctvcf.txt)
		#echo "Calling check_gds.R"
		#R --vanilla --args "~{gds}" ${READFILENAME} < ~{debugScript}
		echo "Doing nothing else..."
	>>>

	runtime {
		docker: "quay.io/aofarrel/topmed-pipeline-wdl:circleci-push"
		disks: "local-disk ${disk} SSD"
		bootDiskSizeGb: 6
		memory: "${memory} GB"
	}
}

# -----------------------------------------------------
# ------------------------ldprune----------------------
# -----------------------------------------------------

# [4] ldprune -- perform LD pruning
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

# [5] subsetGds
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

# [6] merge_gds
task runMergeGds {
	input {
		Array[File] gds_array
		String merged_name = "merged.gds"
		# runtime attr
		Int disk
		Int memory

		File debugScript
	}
	command {
		set -eux -o pipefail
		echo "Doing nothing..."

		#echo "Calling R script runMergeGds.R"
		#R --vanilla --args ~{sep="," gds_array} ~{merged_name} < ~{debugScript}
	}
	runtime {
		docker: "quay.io/aofarrel/topmed-pipeline-wdl:circleci-push"
		disks: "local-disk ${disk} SSD"
		bootDiskSizeGb: 6
		memory: "${memory} GB"
	}
}
# output should be File out = "merged.gds"

# [7] check_merged_gds
task runCheckMergedGds {
	input {
		Array[File] gds_array
		# runtime attr
		Int disk
		Int memory

		File debugScript
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

# -----------------------------------------------------
# -------------------------king------------------------
# -----------------------------------------------------

# [8] gds2bed
task runGdsToBed {
	input {
		File gds
		String bed
		# runtime attr
		Int disk
		Int memory

		File debugScript
	}
	command {
		set -eux -o pipefail
		echo "Calling R script gds2bed.R"
		R --vanilla --args ~{gds} ~{bed} < ~{debugScript}
	}
	runtime {
		docker: "quay.io/aofarrel/topmed-pipeline-wdl:circleci-push"
		disks: "local-disk ${disk} SSD"
		bootDiskSizeGb: 6
		memory: "${memory} GB"
	}
	output {
		File out = bed
	}
}

# [9] plink
task runPLINK {
	input {
		File bed
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

# [10] KING
task runKING {
	input {
		File bed
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

# [11] kinship plots
task runKinship {
	input {
		File bed
		# runtime attr
		Int disk
		Int memory

		File debugScript
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

# [12] kingtomatrix
task runMatrix {
	input {
		File bed
		# runtime attr
		Int disk
		Int memory

		File debugScript
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
		Array[File] vcf_files

		# a singular GDS file for the KING scripts
		# this should be removed once debugging is complete
 		File debug_singularGDS

 		String gdstobed_bed_filename

		# R scripts not already in container
		File uniquevars_debugScript
		File checkgds_debugScript
		File merge_debugScript
		File checkmerged_debugScript
		File gdstobed_debugScript
		File kinship_debugScript
		File matrix_debugScript

		# ld prune
		Boolean? ldprune_autosome_only
		Boolean? ldprune_exclude_pca_corr
		String? ldprune_genome_build
		Float? ldprune_ld_r_threshold
		Int? ldprune_ld_win_size
		Float? ldprune_maf_threshold
		Float? ldprune_missing_threshold

		# runtime attributes
		# [1] vcf2gds
		Int vcfgds_disk
		Int vcfgds_memory
		# [2] uniquevarids
		Int uniquevars_disk
		Int uniquevars_memory
		# [3] checkgds
		Int checkgds_disk
		Int checkgds_memory
		# [4] ldprune
		Int ldprune_disk
		Int ldprune_memory
		# [5] subsetGDS
		Int subsetgds_disk
		Int subsetgds_memory
		# [6] mergeGDS
		Int merge_disk
		Int merge_memory
		# [7] subsetGDS
		Int checkmerged_disk
		Int checkmerged_memory
		# [8] gdstobed
		Int gdstobed_disk
		Int gdstobed_memory
		# [9] PLINK
		Int plink_disk
		Int plink_memory
		# [10] KING
		Int king_disk
		Int king_memory
		# [11] kinship
		Int kinship_disk
		Int kinship_memory
		# [12] matrix
		Int matrix_disk
		Int matrix_memory
	}

# -----------------------------------------------------
# ------------------------vcf2gds----------------------
# -----------------------------------------------------
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
			debugScript = uniquevars_debugScript,
			disk = uniquevars_disk,
			memory = uniquevars_memory
	}
	
	scatter(gds in runUniqueVars.out) {
		call runCheckGds {
			input:
				gds = gds,
				vcfs = vcf_files,
				debugScript = checkgds_debugScript,
				disk = checkgds_disk,
				memory = checkgds_memory
		}
	}

# -----------------------------------------------------
# ------------------------ldprune----------------------
# -----------------------------------------------------
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
				disk = subsetgds_disk,
				memory = subsetgds_memory
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
# -----------------------------------------------------
# -------------------------king------------------------
# -----------------------------------------------------

# Currently this part of the pipeline has bogus inputs
# 	call runGdsToBed {
# 		input:
# 			gds = debug_singularGDS,
# 			bed = gdstobed_bed_filename,
# 			debugScript = gdstobed_debugScript,
# 			disk = gdstobed_disk,
# 			memory = gdstobed_memory
# 	}

# 	call runPLINK {
# 		input:
# 			bed = runGdsToBed.out,
# 			disk = plink_disk,
# 			memory = plink_memory
# 	}

# 	call runKING {
# 		input:
# 			bed = runPLINK.out,
# 			disk = king_disk,
# 			memory = king_memory
# 	}

# 	call runKinship {
# 		input:
# 			bed = runSubsetGds.out, #very bogus
# 			debugScript = kinship_debugScript,
# 			disk = kinship_disk,
# 			memory = kinship_memory,
# 	}

# 	call runMatrix {
# 		input:
# 			bed = runSubsetGds.out, #very bogus
# 			debugScript = matrix_debugScript,
# 			disk = matrix_disk,
# 			memory = matrix_memory,
# 	}

	meta {
		author: "Ash O'Farrell"
		email: "aofarrel@ucsc.edu"
	}
}