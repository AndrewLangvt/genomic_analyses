version 1.0 

import "../tasks/task_pub_repo_submission.wdl" as submission

workflow SC2_submission_files {
  input {
    String	submission_id
    String 	collection_date
    File    sequence
    File    read1
    File    read2

    String  organism = "Severe acute respiratory syndrome coronavirus 2"
    String  iso_org = "SARS-CoV-2"
    String  iso_host = "Human"
    String  iso_state = ""
    String  iso_country = "USA"
    String  iso_continent = "North America"
    String  specimen_type = ""
    String  assembly_or_consensus = "consensus"

    String  gisaid_submitter
    String  seq_platform
    String  bwa_version = ""
    String  ivar_version = ""
    String  originating_lab
    String  origLab_address
    String  BioProject
    String  submitting_lab 
    String  subLab_address 
    String  Authors

    String  passage_details="Original"
    String  gender="unknown"
    String  patient_age="unknown"
    String  patient_status="unknown"
    String  specimen_source=""
    String  outbreak=""
    String  last_vaccinated=""
    String  treatment=""
    String 	iso_county=""

    # Optional inputs/user-defined thresholds for generating submission files
    Int     number_N_threshold = 5000
    Int     number_Total_threshold = 25000
    Int     number_ATCG_gisaid = 25000
    Int     number_ATCG_genbank = 25000
  }

  call submission.sra {
    input:
      submission_id = submission_id,
      read1 = read1,
      read2 = read2
  }

  call submission.deidentify {
    input:
      submission_id = submission_id,
      sequence      = sequence
  }

  if (deidentify.number_N <= number_N_threshold) {
    if (deidentify.number_Total >= number_Total_threshold) {
      if (deidentify.number_ATCG >= number_ATCG_gisaid) {
        call submission.gisaid {
          input:
            submission_id    = submission_id,
            collection_date  = collection_date,
            sequence         = sequence,
            iso_host         = iso_host,
            iso_country      = iso_country,
            specimen_type    = specimen_type,
            gisaid_submitter = gisaid_submitter,
            iso_state        = iso_state,
            iso_continent    = iso_continent,
            seq_platform     = seq_platform,
            bwa_version      = bwa_version,
            ivar_version     = ivar_version,
            originating_lab  = originating_lab,
            origLab_address  = origLab_address,
            submitting_lab   = submitting_lab, 
            subLab_address   = subLab_address, 
            Authors          = Authors
        }
      }
      if (deidentify.number_ATCG >= number_ATCG_genbank) {
        call submission.genbank {
          input:
            submission_id   = submission_id,
            collection_date = collection_date,
            sequence        = sequence,
            organism        = organism, 
            iso_org	        = iso_org,
            iso_host        = iso_host,
            iso_country     = iso_country,
            specimen_type   = specimen_type,
            BioProject      = BioProject
        }
      }
    }
  }

  output {
    File      read1_submission   = sra.read1_submission
    File      read2_submission   = sra.read2_submission
    File      deID_assembly      = deidentify.deID_assembly
    File?     genbank_assembly   = genbank.genbank_assembly
    File?     genbank_metadata   = genbank.genbank_metadata
    File?     gisaid_assembly    = gisaid.gisaid_assembly
    File?     gisaid_metadata    = gisaid.gisaid_metadata
  }
}