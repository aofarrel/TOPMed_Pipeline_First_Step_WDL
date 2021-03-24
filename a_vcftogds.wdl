version 1.0

# [1] vcf2gds -- converts a VCF file into a GDS file
task vcf2gds {
	input {
		File vcf
		String output_file_name = basename(sub(vcf, "\\.vcf.gz$", ".gds"))
		Array[String] format # vcf formats to keep
		# runtime attributes
		Int disk
		Int memory
	}
	command {
		set -eux -o pipefail

		# Generate config used by the R script
		# Must be done in this task or else this task will fail to find the inputs
		# regardless of whether we save full path or use os.path.basename

		echo "Generating config file"
		python << CODE
		import os
		f = open("megastep_A.config", "a")
		f.write("outprefix test\nvcf_file ")
		f.write("~{vcf}")
		f.write("\nformat ")
		for py_formattokeep in ['~{sep="','" format}']:
			f.write(py_formattokeep)
		f.write("\ngds_file '~{output_file_name}'\n")
		f.write("merged_gds_file 'merged.gds'")
		f.close()
		exit()
		CODE

		# Call R script to actually do the conversion
		set -eux -o pipefail
		echo "Calling R script vcfToGds.R"
		Rscript /usr/local/analysis_pipeline/R/vcf2gds.R "megastep_A.config"
	}
	runtime {
		docker: "uwgac/topmed-master:2.8.1"
		disks: "local-disk ${disk} SSD"
		bootDiskSizeGb: 6
		memory: "${memory} GB"
	}
	output {
		File out = output_file_name
	}
}

# [2] uniqueVars -- attempts to give unique variant IDS
task unique_variant_id {
	input {
		Array[File] gdss
		Array[String] chrs
		# runtime attr
		Int disk
		Int memory
	}
	command <<<
		set -eux -o pipefail

		echo "Copying inputs into the workdir"
		BASH_FILES=(~{sep=" " gdss})
		for BASH_FILE in ${BASH_FILES[@]};
		do
			cp ${BASH_FILE} .
		done

		# generate config used by the R script
		# must be done in this task or else this task will fail to find the inputs
		# regardless of whether we save full path or use os.path.basename
		echo "Generating config file"
		python << CODE
		import os
		py_gdsarrayfull = ['~{sep="','" gdss}']
		py_chrarray = ['~{sep="','" chrs}']

		# diff backends feed in files differently so we need to sort due to later assumption
		py_gdsarray = []
		for fullpath in py_gdsarrayfull:
			py_gdsarray.append(os.path.basename(fullpath))
		py_gdsarray.sort()

		f = open("unique_variant_ids.config", "a") # yeah yeah yeah this should be with open() I know
		f.write("chromosomes ")
		f.write("'")
		for py_chr in py_chrarray:
			f.write(py_chr)
			f.write(" ")
		f.write("'")
		f.write("\nvcf_file this_is_a_bogus_name.vcf")
		f.write("\ngds_file ")
		py_listicle = []

		print(py_gdsarray)

		if ( 22 <= len(py_gdsarray) <= 25):

			if(len(os.path.basename(py_gdsarray[0])) == len(os.path.basename(py_gdsarray[11]))):
				for charA, charB in zip(os.path.basename(py_gdsarray[0]), os.path.basename(py_gdsarray[11])):
					if charA == charB:
						py_listicle.append(charA)
					else:
						py_listicle.append(" ")

			else:
				# this shouldn't happen and is kind of a crapshoot
				for charA, charB in zip(os.path.basename(py_gdsarray[0]), os.path.basename(py_gdsarray[1])):
					if charA == charB:
						py_listicle.append(charA)
					else:
						py_listicle.append(" ")

		else:
			# cross-our-fingers-situation - do not error as this may be a test run on <22 chrs
			print("WARNING: Very weird number of chromosomes detected. This pipeline is only designed for human chr1-22+X.")
			print("Attempting %s and %s" % (os.path.basename(py_gdsarray[0]), os.path.basename(py_gdsarray[1])))
			for charA, charB in zip(os.path.basename(py_gdsarray[0]), os.path.basename(py_gdsarray[1])):
				print(charA)
				print(charB)
				print("--")
				if charA == charB:
					py_listicle.append(charA)
				else:
					py_listicle.append(" ")
		
		py_name = "".join(py_listicle)
		f.write("'")
		f.write(py_name)
		f.write("'")
		f.write("\nmerged_gds_file 'merged.gds'\n")
		f.close()
		exit()
		CODE
		echo "Calling uniqueVariantIDs.R"
		Rscript /usr/local/analysis_pipeline/R/unique_variant_ids.R unique_variant_ids.config
	>>>
	runtime {
		docker: "uwgac/topmed-master:2.8.1"
		disks: "local-disk ${disk} SSD"
		bootDiskSizeGb: 6
		memory: "${memory} GB"
	}
	output {
		Array[File] out = glob("*.gds")
	}
}

# [3] checkGDS - check a GDS file against its supposed VCF input
task check_gds {
	input {
		File gds
		Array[File] vcfs
		String gzvcf = basename(sub(gds, "\\.gds$", ".vcf.gz"))
		# runtime attr
		Int disk
		Int memory
	}

	command <<<
		# triple carrot syntax is required for this command section
		set -eux -o pipefail

		echo "Searching for VCF and generating config file"
		# this whole block is hella cursed as config needs spaces in filenames
		python << CODE
		import os
		py_vcfarray = ['~{sep="','" vcfs}']
		for py_file in py_vcfarray:
			py_base = os.path.basename(py_file)
			if(py_base == "~{gzvcf}"):
				f = open("checkgds.config", "a")
				f.write("vcf_file ")

				# write VCF file
				py_thisVcfSplitOnChr = py_file.split("chr")
				if(unicode(str(py_thisVcfSplitOnChr[1][1])).isnumeric()):
					# chr10 and above
					py_thisVcfWithSpace = "".join([
						py_thisVcfSplitOnChr[0],
						"chr ",
						py_thisVcfSplitOnChr[1][2:]])
					py_thisChr = py_thisVcfSplitOnChr[1][0:2]
				else:
					# chr9 and below + chrX
					py_thisVcfWithSpace = "".join([
						py_thisVcfSplitOnChr[0],
						"chr ",
						py_thisVcfSplitOnChr[1][1:]])
					py_thisChr = py_thisVcfSplitOnChr[1][0:1]
				f.write("'")
				f.write(py_thisVcfWithSpace)
				f.write("'")
				
				# write GDS file
				f.write("\ngds_file ")
				py_thisGdsSplitOnChr = "~{gds}".split("chr")
				if(unicode(str(py_thisGdsSplitOnChr[1][1])).isnumeric()):
					# chr10 and above
					print("10 and above")
					print(py_thisGdsSplitOnChr)
					py_thisGdsWithSpace = "".join([
						py_thisGdsSplitOnChr[0],
						"chr ",
						py_thisGdsSplitOnChr[1][2:]])
					py_thisChr = py_thisGdsSplitOnChr[1][0:2]
				else:
					# chr9 and below + chrX
					print("9 and below + x")
					py_thisGdsWithSpace = "".join([
						py_thisGdsSplitOnChr[0],
						"chr ",
						py_thisGdsSplitOnChr[1][1:]])
					py_thisChr = py_thisGdsSplitOnChr[1][0:1]
				f.write("'")
				f.write(py_thisGdsWithSpace)
				f.write("'")

				f.close()

				# write chromosome number, to be read in bash
				g = open("chr_number", "a")
				g.write(str(py_thisChr)) # may already be str if chrX
				exit()

		print("Failed to find a matching VCF for GDS file: ~{gds}")
		exit(1)  # if we don't find a matching VCF, fail
		CODE

		echo "Setting chromosome number"
		BASH_CHR=$(<chr_number)
		echo "${BASH_CHR}"

		echo "Calling check_gds.R"
		Rscript /usr/local/analysis_pipeline/R/check_gds.R checkgds.config --chromosome ${BASH_CHR}
	>>>

	runtime {
		docker: "uwgac/topmed-master:2.8.1"
		disks: "local-disk ${disk} SSD"
		bootDiskSizeGb: 6
		memory: "${memory} GB"
	}
}

workflow a_vcftogds {
	input {
		Array[File] vcf_files
		Array[String] chrs = [1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20,21,22,"X"]
		Array[String] format = ["GT"]
		Boolean check_gds = false

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
		call vcf2gds {
			input:
				vcf = vcf_file,
				format = format,
				disk = vcfgds_disk,
				memory = vcfgds_memory
		}
	}
	
	call unique_variant_id {
		input:
			gdss = vcf2gds.out,
			chrs = chrs,
			disk = uniquevars_disk,
			memory = uniquevars_memory
	}
	
	if(check_gds) {
		scatter(gds in unique_variant_id.out) {
			call check_gds {
				input:
					gds = gds,
					vcfs = vcf_files,
					disk = checkgds_disk,
					memory = checkgds_memory
			}
		}
	}

	meta {
		author: "Ash O'Farrell"
		email: "aofarrel@ucsc.edu"
	}
}
