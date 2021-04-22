version 1.0

# WARNING: By default, this WILL run the costly check_gds step!

import "https://raw.githubusercontent.com/aofarrel/TOPMed_Pipeline_First_Step_WDL/master/vcf-to-gds-wf.wdl" as megastepA

task md5sum {
	input {
		File report
		File truth
	}

	command <<<

	md5sum newreport.txt > sum.txt
	md5sum newtruth.txt > debugtruth.txt

	# temporarily outputting to stderr for clarity's sake
	>&2 echo "Output checksum:"
	>&2 cat sum.txt
	>&2 echo "-=-=-=-=-=-=-=-=-=-"
	>&2 echo "Truth checksum:"
	>&2 cat debugtruth.txt
	>&2 echo "-=-=-=-=-=-=-=-=-=-"
	>&2 echo "Contents of the output file:"
	>&2 cat ~{report}
	>&2 echo "-=-=-=-=-=-=-=-=-=-"
	>&2 echo "Contents of the truth file:"
	>&2 cat ~{truth}
	>&2 echo "-=-=-=-=-=-=-=-=-=-"
	>&2 cat newreport.txt
	>&2 echo "-=-=-=-=-=-=-=-=-=-"
	>&2 echo "Contents of the sorted truth file:"
	>&2 cat newtruth.txt
	>&2 echo "-=-=-=-=-=-=-=-=-=-"
	>&2 cmp --verbose sum.txt debugtruth.txt
	>&2 diff sum.txt debugtruth.txt
	>&2 diff -w sum.txt debugtruth.txt

	cat ~{truth} | md5sum --check sum.txt
	# if pass pipeline records success
	# if fail pipeline records error

	>>>

	runtime {
		docker: "python:3.8-slim"
		preemptible: 2
	}

}

workflow checker {
	input {
		Array[File] vcf_files
		Array[String] format = ["GT"]
		Boolean check_gds = true  # careful now...
		File? sample_file

		# runtime attributes
		# [1] vcf2gds
		Int vcfgds_cpu = 1
		Int vcfgds_disk
		Int vcfgds_memory = 4
		# [2] uniquevarids
		Int uniquevars_cpu = 1
		Int uniquevars_disk
		Int uniquevars_memory = 4
		# [3] checkgds
		Int checkgds_cpu = 1
		Int checkgds_disk
		Int checkgds_memory = 4
	}
	scatter(vcf_file in vcf_files) {
		call megastepA.vcf2gds {
			input:
				vcf = vcf_file,
				format = format,
				cpu = vcfgds_cpu,
				disk = vcfgds_disk,
				memory = vcfgds_memory
		}
	}
	
	call megastepA.unique_variant_id {
		input:
			gdss = megastepA.vcf2gds.gds_output,
			cpu = uniquevars_cpu,
			disk = uniquevars_disk,
			memory = uniquevars_memory
	}
	
	if(check_gds) {
		scatter(gds in megastepA.unique_variant_id.unique_variant_id_gds_per_chr) {
			call megastepA.check_gds {
				input:
					gds = gds,
					vcfs = vcf_files,
					sample = sample_file,
					cpu = checkgds_cpu,
					disk = checkgds_disk,
					memory = checkgds_memory
			}
		}
	}

	call md5sum {
		input:
				report = report.finalOut,
				truth = truth
	}

	meta {
		author: "Ash O'Farrell"
		email: "aofarrel@ucsc.edu"
		}
