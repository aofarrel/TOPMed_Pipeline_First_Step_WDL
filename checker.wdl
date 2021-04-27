version 1.0

# WARNING: By default, this WILL run the costly check_gds step!

import "https://raw.githubusercontent.com/aofarrel/TOPMed_Pipeline_First_Step_WDL/master/vcf-to-gds-wf.wdl" as megastepA


task investigate_container {
	command <<<

	#cat /etc/hostname
	# this doesn't help, it doesnt have tags
	# also calling same image in diff task gives diff hostname
	# surely there is some way to compare containers???
	# or at least see if container being used is also the latest??
	# might not really be worth it tho

	>>>

	runtime {
		docker: "python:3.8-slim"
		preemptible: 2
	}
}

task md5sum {
	input {
		File gds_test
		File gds_truth
	}

	command <<<

	md5sum ~{gds_test} > sum.txt
	echo "$(cut -f1 -d' ' sum.txt)" ~{gds_truth} | md5sum --check 

	>>>

	runtime {
		docker: "python:3.8-slim"
		preemptible: 2
	}

}

workflow checker {
	input {
		# just for testing
		File gds_test
		File gds_truth

		Array[File] vcf_files
		Array[String] format = ["GT"]
		Boolean check_gds = true  # careful now...

		# runtime attributes
		# [1] vcf2gds
		Int vcfgds_cpu = 1
		Int vcfgds_disk = 60
		Int vcfgds_memory = 4
		# [2] uniquevarids
		Int uniquevars_cpu = 1
		Int uniquevars_disk = 60
		Int uniquevars_memory = 4
		# [3] checkgds
		Int checkgds_cpu = 1
		Int checkgds_disk = 60
		Int checkgds_memory = 4

		# checker-specific
		File? truth_info
	}

	call investigate_container

	call md5sum {
		input:
				gds_test = gds_test,
				gds_truth = gds_truth
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
			gdss = vcf2gds.gds_output,
			cpu = uniquevars_cpu,
			disk = uniquevars_disk,
			memory = uniquevars_memory
	}
	
	if(check_gds) {
		scatter(gds in unique_variant_id.unique_variant_id_gds_per_chr) {
			call megastepA.check_gds {
				input:
					gds = gds,
					vcfs = vcf_files,
					cpu = checkgds_cpu,
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