version 1.0 

import "wf_sc2_pubRepo_submission.wdl" as submission
import "../tasks/task_pub_repo_submission.wdl" as pubrepo

workflow SC2_submission_files_local {
	input {
		Array[Pair[Array[String], Array[File]]]	inputdata
        String   organism = "Severe acute respiratory syndrome coronavirus 2"
        String   iso_org = "SARS-CoV-2"
        String   iso_host = "Human"
        String   iso_country = "USA"
        String   specimen_type = ""
        String   assembly_or_consensus = "consensus"
        String   gisaid_submitter
        String   iso_state
        String   iso_continent
        String   seq_platform
        String   bwa_version = "bwa"
        String   ivar_version = "ivar"
        String   originating_lab
        String   origLab_address
        String   BioProject
        String   submitting_lab
        String   subLab_address
        String   Authors
	}
    
    scatter (sample in inputdata) {
		call submission.SC2_submission_files {
			input:
				samplename      = sample.left[0],
				submission_id   = sample.left[1],
				collection_date = sample.left[2],
				sequence        = sample.right[0],
				read1           = sample.right[1],
				read2           = sample.right[2],
				organism = organism,
				iso_org = iso_org,
				iso_host = iso_host,
				iso_country = iso_country,
				specimen_type = specimen_type,
				assembly_or_consensus = assembly_or_consensus,
				gisaid_submitter = gisaid_submitter,
				iso_state = iso_state,
				iso_continent = iso_continent,
				seq_platform = seq_platform,
				bwa_version = bwa_version,
				ivar_version = ivar_version,
				originating_lab = originating_lab,
				origLab_address = origLab_address,
				BioProject = BioProject,
				submitting_lab = submitting_lab,
				subLab_address = subLab_address,
				Authors = Authors		
		}
    }

    call pubrepo.compile as genbank_compile {
    	input:
    	    single_submission_meta  = SC2_submission_files.genbank_metadata,
    	    single_submission_fasta = SC2_submission_files.genbank_assembly,
    	    repository              = "genbank"
    }
    call pubrepo.compile as gisaid_compile {
    	input:
    	    single_submission_meta  = SC2_submission_files.gisaid_metadata,
    	    single_submission_fasta = SC2_submission_files.gisaid_assembly,
    	    repository              = "gisaid"
    }
	output {
	    Array[File]      deID_assembly      = SC2_submission_files.deID_assembly
	    Array[File?]     read1_submission   = SC2_submission_files.read1_submission
	    Array[File?]     read2_submission   = SC2_submission_files.read2_submission
	    Array[File?]     SE_read_submission = SC2_submission_files.SE_read_submission
	    Array[File?]     genbank_assembly   = SC2_submission_files.genbank_assembly
	    Array[File?]     gisaid_assembly    = SC2_submission_files.gisaid_assembly
	    Array[File?]     genbank_metadata   = SC2_submission_files.genbank_metadata
	    Array[File?]     gisaid_metadata    = SC2_submission_files.gisaid_metadata

	    File             genbank_upload_meta  = genbank_compile.upload_meta
	    File             genbank_upload_fasta = genbank_compile.upload_fasta
	    File             gisaid_upload_meta   = gisaid_compile.upload_meta
	    File             gisaid_upload_fasta  = gisaid_compile.upload_fasta	}
}


