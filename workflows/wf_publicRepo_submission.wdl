version 1.0 
import "../tasks/task_pub_repo_submission.wdl" as submission

workflow submission_files {
	input {
		String 		samplename
		String		submission_id
		String 		collection_date
		File 		sequence
		File 		read1
		File 		read2
	}

	call submission.deidentify {
		input:
			samplename = samplename,
			submission_id = submission_id,
			collection_date = collection_date,
			sequence = sequence,
			read1 = read1,
			read2 = read2
	}

	output {
	    File      read1_submission = deidentify.read1_submission
	    File      read2_submission = deidentify.read2_submission
	    File      deID_assembly = deidentify.deID_assembly
	    File?     genbank_assembly = deidentify.genbank_assembly
	    File?     gisaid_assembly = deidentify.gisaid_assembly
	}
}


