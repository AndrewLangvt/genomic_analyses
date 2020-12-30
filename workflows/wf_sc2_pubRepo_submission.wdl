version 1.0 

import "../tasks/task_pub_repo_submission.wdl" as submission

workflow SC2_submission_files {
	input {
		String 		samplename
		String		submission_id
		String 		collection_date
		File 		sequence
		File 		read1
		File 		read2
		Int 		number_ATCG 
		Int 		number_ATCG_gisaid = 25000
		Int 		number_ATCG_genbank = 15000

	    String    	organism = "Severe acute respiratory syndrome coronavirus 2"
	    String    	iso_org = "SARS-CoV-2"
	    String    	iso_host = "Human"
	    String    	iso_country = "USA"
	    String    	assembly_or_consensus = "consensus"

	    # Optional inputs/user-defined thresholds for generating submission files
		Float		coverage = 100.00
		Int 		number_N = 0
		Int 		number_Total = 30000
		Float		coverage_threshold = 85.00
		Int 		number_N_threshold = 15000
		Int 		number_Total_threshold = 25000
	}

	call submission.sra {
		input:
			submission_id = submission_id,
			read1 = read1,
			read2 = read2
	}

	call submission.deidentify {
		input:
			samplename    = samplename,
			submission_id = submission_id,
			sequence      = sequence
	}

	if (coverage >= coverage_threshold) {
		if (number_N <= number_N_threshold) {
			if (number_Total >= number_Total_threshold) {
				if (number_ATCG >= number_ATCG_gisaid) {
					call submission.gisaid {
						input:
							samplename      = samplename,
							submission_id   = submission_id,
							collection_date = collection_date,
							sequence        = sequence,
							iso_host        = iso_host,
							iso_country     = iso_country
					}
				}
				if (number_ATCG >= number_ATCG_genbank) {
					call submission.genbank {
						input:
							samplename      = samplename,
							submission_id   = submission_id,
							collection_date = collection_date,
							sequence        = sequence,
							organism        = organism, 
							iso_org	        = iso_org,
							iso_host        = iso_host,
							iso_country     = iso_country
					}
				}
			}
		}
	}

	output {
	    File      read1_submission = sra.read1_submission
	    File      read2_submission = sra.read2_submission
	    File      deID_assembly    = deidentify.deID_assembly
	    File?     genbank_assembly = genbank.genbank_assembly
	    File?     gisaid_assembly  = gisaid.gisaid_assembly
	}
}


#coverage >= coverage_gisaid && number_N <= number_N_gisaid && 