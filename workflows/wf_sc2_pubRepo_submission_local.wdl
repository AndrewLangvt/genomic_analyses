version 1.0 

import "wf_sc2_pubRepo_submission.wdl" as submission

struct Submission_struct {
    File      read1
    File      read2 
    String    deidentified
    File      consensus_seq
    File      read1_dehosted
    File      read2_dehosted
    String    bwa_version
    String    ivar_version_consensus
    String    collection
    String    iso_source
    String    iso_state 
    String    iso_country
    String    iso_continent 
}

workflow SC2_submission_files_local {
  input {
    Array[Submission_struct] inputsamples
    String    gisaid_submitter
    String    seq_platform
    String    originating_lab
    String    origLab_address
    String    BioProject
    String    submitting_lab 
    String    subLab_address 
    String    Authors  
  }
    
  scatter (sample in inputsamples) {
    call submission.SC2_submission_files {
      input:
        submission_id   = sample.deidentified,
        collection_date = sample.collection,
        specimen_type   = sample.iso_source,
        iso_state       = sample.iso_state,
        iso_country     = sample.iso_country,
        iso_continent   = sample.iso_continent,
        sequence        = sample.consensus_seq,
        read1           = sample.read1_dehosted,
        read2           = sample.read2_dehosted,
        bwa_version     = sample.bwa_version,
        ivar_version    = sample.ivar_version_consensus,
        gisaid_submitter= gisaid_submitter,
        seq_platform    = seq_platform,
        originating_lab = originating_lab,
        origLab_address = origLab_address,
        BioProject      = BioProject,
        submitting_lab  = submitting_lab,
        subLab_address  = subLab_address,
        Authors         = Authors
    }
  }

  output {
    Array[File]      deID_assembly      = SC2_submission_files.deID_assembly
    Array[File?]     read1_submission   = SC2_submission_files.read1_submission
    Array[File?]     read2_submission   = SC2_submission_files.read2_submission
    Array[File?]     genbank_assembly   = SC2_submission_files.genbank_assembly
    Array[File?]     gisaid_assembly    = SC2_submission_files.gisaid_assembly
    Array[File?]     genbank_metadata   = SC2_submission_files.genbank_metadata
    Array[File?]     gisaid_metadata    = SC2_submission_files.gisaid_metadata

  }
}


