version 1.0 

import "wf_viral_refbased_assembly.wdl" as assembly
import "../tasks/task_amplicon_metrics.wdl" as assembly_metrics
import "../tasks/task_sample_metrics.wdl" as summary
import "wf_sc2_pubRepo_submission.wdl" as submission

workflow nCoV19_pipeline {
  input {
    Array[Pair[Array[String], Pair[File,File]]] inputSamples
    String    ref_genome_URL
    String    ref_gff_URL
    String    primer_BED_URL
    String    primer_PCR_BED_URL
    String    gisaid_submitter
    String    iso_state
    String    iso_continent 
    String    seq_platform
    String    originating_lab
    String    origLab_address
    String    BioProject
    String    submitting_lab 
    String    subLab_address 
    String    Authors    
  }

  scatter (sample in inputSamples) {
    call assembly.viral_refbased_assembly {
      input:
        samplename = sample.left[0],
        read1_raw  = sample.right.left,
        read2_raw  = sample.right.right,
        ref_genome_URL = ref_genome_URL,
        ref_gff_URL = ref_gff_URL,
        primer_BED_URL = primer_BED_URL,
        primer_PCR_BED_URL = primer_PCR_BED_URL
    }

    call summary.sample_metrics {
      input:
        samplename                  = sample.left[0],
        submission_id               = sample.left[1],
        collection_date             = sample.left[2],
        fastqc_raw_pairs            = viral_refbased_assembly.fastqc_raw_pairs,
        fastqc_clean_pairs          = viral_refbased_assembly.fastqc_clean_pairs,
        primer_trimmed_read_percent = viral_refbased_assembly.primer_trimmed_read_percent,
        pangolin_lineage            = viral_refbased_assembly.pangolin_lineage,
        pangolin_probability        = viral_refbased_assembly.pangolin_probability,
        nextclade_clade             = viral_refbased_assembly.nextclade_clade,
        nextclade_aa_subs           = viral_refbased_assembly.nextclade_aa_subs,
        nextclade_aa_dels           = viral_refbased_assembly.nextclade_aa_dels,
#        fastqc_raw_pairs            = viral_refbased_assembly.fastqc_raw_pairs,
#        seqy_pairs                  = viral_refbased_assembly.seqy_pairs,
#        seqy_percent                = viral_refbased_assembly.seqy_percent,
        kraken_human                = viral_refbased_assembly.kraken_human,
        kraken_sc2                  = viral_refbased_assembly.kraken_sc2,
        variant_num                 = viral_refbased_assembly.variant_num,
        number_N                    = viral_refbased_assembly.number_N,
        number_ATCG                 = viral_refbased_assembly.assembly_length_unambiguous,
        number_Degenerate           = viral_refbased_assembly.number_Degenerate,
        number_Total                = viral_refbased_assembly.number_Total,
#        coverage                    = viral_refbased_assembly.coverage,
#        depth                       = viral_refbased_assembly.depth,
        meanbaseq_trim              = viral_refbased_assembly.meanbaseq_trim,
        meanmapq_trim               = viral_refbased_assembly.meanmapq_trim,
        coverage_trim               = viral_refbased_assembly.coverage_trim, 
        depth_trim                  = viral_refbased_assembly.depth_trim,
        amp_fail                    = viral_refbased_assembly.amp_fail
    }

    call submission.SC2_submission_files {
      input:
        samplename      = sample.left[0],
        submission_id   = sample.left[1],
        collection_date = sample.left[2],
        sequence        = viral_refbased_assembly.consensus_seq,
        read1           = sample.right.left, 
        read2           = sample.right.right,
        coverage        = viral_refbased_assembly.coverage_trim,
        bwa_version     = viral_refbased_assembly.bwa_version,
        ivar_version    = viral_refbased_assembly.ivar_version_consensus,
        gisaid_submitter= gisaid_submitter,
        iso_state       = iso_state,
        iso_continent   = iso_continent,
        seq_platform    = seq_platform,
        originating_lab = originating_lab,
        origLab_address = origLab_address,
        BioProject      = BioProject,
        submitting_lab  = submitting_lab,
        subLab_address  = subLab_address,
        Authors         = Authors     
    }
  }

  call summary.merge_metrics {
    input:
      all_metrics = sample_metrics.single_metrics
  }

  output {
    Array[File]    read1_clean          = viral_refbased_assembly.read1_clean
    Array[File]    read2_clean          = viral_refbased_assembly.read2_clean
    Array[File]    kraken_report        = viral_refbased_assembly.kraken_report
    Array[File]    sorted_bam           = viral_refbased_assembly.sorted_bam
    Array[File]    sorted_bai           = viral_refbased_assembly.sorted_bai
    Array[File]    aligned_bam          = viral_refbased_assembly.aligned_bam
    Array[File]    aligned_bai          = viral_refbased_assembly.aligned_bai
    Array[File]    consensus_seq        = viral_refbased_assembly.consensus_seq
    Array[File]    samtools_stats       = viral_refbased_assembly.consensus_stats
    Array[File]    cov_hist             = viral_refbased_assembly.cov_hist
    Array[File]    cov_stats            = viral_refbased_assembly.cov_stats
    Array[File]    samtools_flagstat    = viral_refbased_assembly.consensus_flagstat
    Array[File]    pango_lineage_report = viral_refbased_assembly.pango_lineage_report
    Array[File]    amp_coverage         = viral_refbased_assembly.amp_coverage
    File           merged_metrics       = merge_metrics.run_results

    Array[File?]   read1_submission     = SC2_submission_files.read1_submission
    Array[File?]   read2_submission     = SC2_submission_files.read2_submission
    Array[File]    deID_assembly        = SC2_submission_files.deID_assembly
    Array[File?]   genbank_assembly     = SC2_submission_files.genbank_assembly
    Array[File?]   genbank_metadata     = SC2_submission_files.genbank_metadata
    Array[File?]   gisaid_assembly      = SC2_submission_files.gisaid_assembly
    Array[File?]   gisaid_metadata      = SC2_submission_files.gisaid_metadata
  }
}
