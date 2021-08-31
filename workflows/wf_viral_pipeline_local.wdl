version 1.0 

import "wf_viral_refbased_assembly.wdl" as assembly
import "../tasks/task_sample_metrics.wdl" as summary
import "wf_sc2_pubRepo_submission.wdl" as submission
import "wf_sc2_batch_submission.wdl" as submission_batch
#import "wf_mercury_batch.wdl" as submission_batch

struct Samplestruct {
    String    samplename
    File      read1
    File      read2 
    String    deidentified
    String    collection
    String    iso_source
    String    iso_state 
    String    iso_country
    String    iso_continent 
}

workflow viral_pipeline_local {
  input {
    Array[Samplestruct] inputsamples
    File      reference_genome
    File      reference_gff
    File      primer_BEDfile
    String    analyst
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
    call assembly.viral_refbased_assembly {
      input:
        samplename = sample.samplename,
        read1_raw  = sample.read1,
        read2_raw  = sample.read2,
        reference_genome = reference_genome,
        reference_gff = reference_gff,
        primer_BEDfile = primer_BEDfile,
        analyst = analyst
    }

    call summary.sample_metrics {
      input:
        samplename                  = sample.samplename,
        submission_id               = sample.deidentified,
        collection_date             = sample.collection,
        fastqc_raw_pairs            = viral_refbased_assembly.fastqc_raw_pairs,
        read1_human_spots_removed   = viral_refbased_assembly.read1_human_spots_removed,
        read2_human_spots_removed   = viral_refbased_assembly.read2_human_spots_removed,    
        fastqc_clean_pairs          = viral_refbased_assembly.fastqc_clean_pairs,
        primer_trimmed_read_percent = viral_refbased_assembly.primer_trimmed_read_percent,
        pangolin_lineage            = viral_refbased_assembly.pangolin_lineage,
        pangolin_conflicts          = viral_refbased_assembly.pangolin_conflicts,
        nextclade_clade             = viral_refbased_assembly.nextclade_clade,
        nextclade_aa_subs           = viral_refbased_assembly.nextclade_aa_subs,
        nextclade_aa_dels           = viral_refbased_assembly.nextclade_aa_dels,
        depth_trim                  = viral_refbased_assembly.depth_trim,
        coverage                    = viral_refbased_assembly.percent_reference_coverage, 
        kraken_human                = viral_refbased_assembly.kraken_human,
        kraken_sc2                  = viral_refbased_assembly.kraken_sc2,
        number_N                    = viral_refbased_assembly.number_N,
        number_ATCG                 = viral_refbased_assembly.assembly_length_unambiguous,
        number_Degenerate           = viral_refbased_assembly.number_Degenerate,
        number_Total                = viral_refbased_assembly.number_Total,
        meanbaseq_trim              = viral_refbased_assembly.meanbaseq_trim,
        meanmapq_trim               = viral_refbased_assembly.meanmapq_trim,
        vadr_num_alerts             = viral_refbased_assembly.vadr_num_alerts
    }

    if(defined(sample.deidentified)) {
      call submission.SC2_submission_files {
        input:
          submission_id   = sample.deidentified,
          collection_date = sample.collection,
          specimen_type   = sample.iso_source,
          iso_state       = sample.iso_state,
          iso_country     = sample.iso_country,
          iso_continent   = sample.iso_continent,
          sequence        = viral_refbased_assembly.consensus_seq,
          read1           = viral_refbased_assembly.read1_dehosted,
          read2           = viral_refbased_assembly.read2_dehosted,
          bwa_version     = viral_refbased_assembly.bwa_version,
          ivar_version    = viral_refbased_assembly.ivar_version_consensus,
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
    }

  call summary.merge_metrics {
    input:
      all_metrics = sample_metrics.single_metrics
  }

  # call submission_batch.batch_fasta_repo_submission { 
  #   input:
  #     genbank_single_submission_fasta = select_all(SC2_submission_files.genbank_assembly),
  #     genbank_single_submission_meta  = select_all(SC2_submission_files.genbank_metadata),
  #     gisaid_single_submission_fasta  = select_all(SC2_submission_files.gisaid_assembly),
  #     gisaid_single_submission_meta   = select_all(SC2_submission_files.gisaid_metadata),
  #     vadr_num_alerts = select_all(viral_refbased_assembly.vadr_num_alerts)
  # }

  # call submission_batch.batch_fasta_repo_submission { 
  #   input:
  #     genbank_single_submission_fasta = select_all(SC2_submission_files.genbank_assembly),
  #     genbank_single_submission_meta  = select_all(SC2_submission_files.genbank_metadata),
  #     gisaid_single_submission_fasta  = select_all(SC2_submission_files.gisaid_assembly),
  #     gisaid_single_submission_meta   = select_all(SC2_submission_files.gisaid_metadata),
  #     samplename = SC2_submission_files.sample,
  #     vadr_num_alerts = viral_refbased_assembly.vadr_num_alerts
  # }

  output {
    Array[File]  trimmed_reads    = flatten([viral_refbased_assembly.read1_clean, viral_refbased_assembly.read2_clean])
    Array[File]  kraken_report    = viral_refbased_assembly.kraken_report
    Array[File]  bams_sorted      = flatten([viral_refbased_assembly.sorted_bam, viral_refbased_assembly.sorted_bai])
    Array[File]  bams_trimmed     = flatten([viral_refbased_assembly.aligned_bam, viral_refbased_assembly.aligned_bai])
    Array[File]  genome_stats     = flatten([viral_refbased_assembly.consensus_stats, viral_refbased_assembly.cov_hist, viral_refbased_assembly.cov_stats, viral_refbased_assembly.consensus_flagstat])
    Array[File]  consensus_seq    = viral_refbased_assembly.consensus_seq
    Array[File]  pangolin         = viral_refbased_assembly.pango_lineage_report
    Array[File]  nextclade        = viral_refbased_assembly.nextclade_tsv
    File         merged_metrics   = merge_metrics.run_results
    Array[File?] vadr             = select_all(viral_refbased_assembly.vadr_alerts_list)
    Array[File]  audit_files      = viral_refbased_assembly.audit_file
    Array[File?] submission_files = flatten([SC2_submission_files.read1_submission, SC2_submission_files.read2_submission, select_all(SC2_submission_files.deID_assembly), select_all(SC2_submission_files.genbank_assembly), select_all(SC2_submission_files.genbank_metadata), select_all(SC2_submission_files.gisaid_assembly), select_all(SC2_submission_files.gisaid_metadata)])
    # Array[File]  submission_docs  = select_all([batch_fasta_repo_submission.GenBank_upload_meta, batch_fasta_repo_submission.GenBank_upload_fasta, batch_fasta_repo_submission.GISAID_upload_meta, batch_fasta_repo_submission.GISAID_upload_fasta])
  }
}