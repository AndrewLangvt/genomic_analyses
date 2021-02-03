version 1.0

import "wf_sc2_pubRepo_submission.wdl" as submission

workflow batch_fasta_repo_submission {
	input {
		Array[File?] single_submission_fasta
		Array[File?] single_submission_meta

	}

	call submission.compile {
		input:
			single_submission_fasta=single_submission_fasta,
	    single_submission_meta=single_submission_meta,
	    repository="GenBank"
	}

	output {
	    File      GenBank_upload_meta  = SC2_submission_files.deID_assembly
	    File      GenBank_upload_fasta = SC2_submission_files.read1_submission

	}
}
