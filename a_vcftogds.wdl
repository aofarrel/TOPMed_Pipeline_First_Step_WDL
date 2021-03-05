version 1.0

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

workflow a_vcftogds {
	input {
		Array[File] vcf_files

		# R scripts that aren't hardcoded yet
		File uniquevars_debug
		File checkgds_debug

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
			debugScript = uniquevars_debug,
			disk = uniquevars_disk,
			memory = uniquevars_memory
	}
	
	scatter(gds in runUniqueVars.out) {
		call runCheckGds {
			input:
				gds = gds,
				vcfs = vcf_files,
				debugScript = checkgds_debug,
				disk = checkgds_disk,
				memory = checkgds_memory
		}
	}

	meta {
		author: "Ash O'Farrell"
		email: "aofarrel@ucsc.edu"
	}
}