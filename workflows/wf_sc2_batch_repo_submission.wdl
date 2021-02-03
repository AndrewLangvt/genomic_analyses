version 1.0

import "wf_sc2_pubRepo_submission.wdl" as submission

workflow batch_fasta_repo_submission {
	input {
		Array[File?] genbank_single_submission_fasta
		Array[File?] genbank_single_submission_meta
		Array[File?] gisaid_single_submission_fasta
		Array[File?] gisaid_single_submission_meta

	}

	call submission.compile as genbank_compile{
		input:
			single_submission_fasta=genbank_single_submission_fasta,
	    		single_submission_meta=genbank_single_submission_meta,
	    		repository="GenBank"
	}
	call submission.compile as gisaid_compile{
		input:
			single_submission_fasta=gisaid_single_submission_fasta,
	  		single_submission_meta=gisaid_single_submission_meta,
	    		repository="GISAID"
	}
	

	output {
	    File      GenBank_upload_meta  = genbank_compile.upload_meta
	    File      GenBank_upload_fasta = genbank_compile.upload_fasta
	    File      GISIAD_upload_meta  = gisaid_compile.upload_meta
	    File      GISAID_upload_fasta = gisaid_compile.upload_fasta

	}
}
