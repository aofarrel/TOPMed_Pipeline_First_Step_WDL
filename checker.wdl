version 1.0

# WARNING: By default, this WILL run the costly check_gds step!

import "https://raw.githubusercontent.com/aofarrel/TOPMed_Pipeline_First_Step_WDL/master/vcf-to-gds-wf.wdl" as megastepA

task md5sum {
	input {
		File gds_test
		Array[File] gds_truth
		File truth_info
	}

	command <<<
	echo "Information about these truth files:"
	head -n 3 "~{truth_info}"
	echo "The container version refers to the container used in applicable tasks in the WDL and is the important value here."
	echo "If container versions are equivalent, there should be no difference in GDS output between a local run and a run on Terra."
	md5sum ~{gds_test} > sum.txt

	bash_truth=$(gds_truth sep=" ")
	echo $bash_truth
	for i in "${bash_truth[@]}"
	do
		echo $i
	done
	#echo "$(cut -f1 -d' ' sum.txt)" ~{gds_truth} | md5sum --check 

	>>>

	runtime {
		docker: "python:3.8-slim"
		preemptible: 2
	}

}

workflow checker {
	input {
		# just for testing
		Array[File] gds_tests
		Array[File] gds_truths

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
		File truth_info
	}

	#scatter(gds_test in unique_variant_id.unique_variant_id_gds_per_chr) {
	scatter(gds in gds_tests) {
		call md5sum {
			input:
				gds_test = gds,
				gds_truth = gds_truths,
				truth_info = truth_info
		}
	}

	#scatter(vcf_file in vcf_files) {
	#	call megastepA.vcf2gds {
	#		input:
	#			vcf = vcf_file,
	#			format = format,
	#			cpu = vcfgds_cpu,
	#			disk = vcfgds_disk,
	#			memory = vcfgds_memory
	#	}
	#}
	
	#call megastepA.unique_variant_id {
	#	input:
	#		gdss = vcf2gds.gds_output,
	#		cpu = uniquevars_cpu,
	#		disk = uniquevars_disk,
	#		memory = uniquevars_memory
	#}
	
	#if(check_gds) {
	#	scatter(gds in unique_variant_id.unique_variant_id_gds_per_chr) {
	#		call megastepA.check_gds {
	#			input:
	#				gds = gds,
	#				vcfs = vcf_files,
	#				cpu = checkgds_cpu,
	#				disk = checkgds_disk,
	#				memory = checkgds_memory
	#		}
	#	}
	#}


	meta {
		author: "Ash O'Farrell"
		email: "aofarrel@ucsc.edu"
	}
}