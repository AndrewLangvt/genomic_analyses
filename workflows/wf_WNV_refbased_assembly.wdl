version 1.0

import "../tasks/task_qc_utils.wdl" as qc_utils
import "../tasks/task_read_clean.wdl" as read_clean 
import "../tasks/task_taxonID.wdl" as taxon_ID
import "../tasks/task_alignment.wdl" as align
import "../tasks/task_consensus_call.wdl" as consensus_call
import "../tasks/task_assembly_metrics.wdl" as assembly_metrics
import "../tasks/task_ncbi.wdl" as ncbi
import "../tasks/task_qa.wdl" as qa

workflow viral_refbased_assembly {
  meta {
    description: "Reference-based consensus calling for West Nile Virus amplicon sequencing data"
  }

  input {
    String    samplename
    File      read1_raw
    File      read2_raw 
    File      reference_genome
    File      reference_gff
    File      primer_BEDfile
    String    analyst = "Unknown"
    String    ncbi_scrub_docker = "ncbi/sra-human-scrubber:1.0.2021-05-05"
    String    seqyclean_docker  = "quay.io/staphb/seqyclean@sha256:0f7d965481d936e3b17ecb130eb00183091f2c33075ee8ef792da7b89598f6ef"
    # staphb/seqyclean:1.10.09
    String    fastqc_docker     = "quay.io/staphb/fastqc@sha256:38bf27acfc4a32d4ec5ad1f1fe3b4d08850754f75bbf7f1e8121ca9a888e0968"
    #staphb/fastqc:0.11.9"
    String    kraken_docker     = "quay.io/staphb/kraken2@sha256:5b107d0141d6042a6b0ac6a5852990dc541fbff556a85eb0c321a7771200ba56"
    #staphb/kraken2:2.0.9-beta
    String    bwa_docker        = "quay.io/staphb/ivar@sha256:2d826240a6338a8e4b03f11975f69d0ef897f8508476f2f15f444cb041d88acb"
    #staphb/ivar:1.3.1
    String    ivar_docker       = "quay.io/staphb/ivar@sha256:2d826240a6338a8e4b03f11975f69d0ef897f8508476f2f15f444cb041d88acb"
    #staphb/ivar:1.3.1
    String    samtools_docker   = "quay.io/staphb/ivar@sha256:2d826240a6338a8e4b03f11975f69d0ef897f8508476f2f15f444cb041d88acb"
    #staphb/ivar:1.3.1
    String    pangolin_docker   = "quay.io/staphb/pangolin@sha256:7f68bd9b7fe71a215885ea7d4bbf90ac84aab112a4df8cbfa7773d45a0f485a9"
    #staphb/pangolin:3.1.3-pangolearn-2021-06-15
    String    nextclade_docker  = "neherlab/nextclade:0.14.4"
    String    vadr_docker       = "quay.io/staphb/vadr@sha256:1a55a8415ccdd739d87adea211ffdcdd452fc21f2df6d4984537909a60ef39d3"
    #staphb/vadr:1.2.1
    String    utiltiy_docker    = "quay.io/broadinstitute/viral-baseimage@sha256:340c0a673e03284212f539881d8e0fb5146b83878cbf94e4631e8393d4bc6753"
  }
  String reference_genome_fn = basename(reference_genome)
  String reference_gff_fn    = basename(reference_gff)
  String primer_BEDfile_fn   = basename(primer_BEDfile)

  call qa.version_capture {
    input:
  }
  call read_clean.ncbi_scrub_pe {
    input:
      samplename = samplename,
      read1      = read1_raw,
      read2      = read2_raw,
      docker     = ncbi_scrub_docker
  }  
  call read_clean.seqyclean {
    input:
      samplename = samplename,
      read1      = ncbi_scrub_pe.read1_dehosted,
      read2      = ncbi_scrub_pe.read2_dehosted,
      docker     = seqyclean_docker
  }
  call qc_utils.fastqc as fastqc_raw {
    input:
      read1  = ncbi_scrub_pe.read1_dehosted,
      read2  = ncbi_scrub_pe.read2_dehosted,
      docker = fastqc_docker
  }
  call qc_utils.fastqc as fastqc_clean {
    input:
      read1  = seqyclean.read1_clean,
      read2  = seqyclean.read2_clean,
      docker = fastqc_docker
  }
  call taxon_ID.kraken2 {
    input:
      samplename = samplename,
      read1      = seqyclean.read1_clean, 
      read2      = seqyclean.read2_clean,
      virus_name = "West Nile Virus"
      docker     = kraken_docker
  }
  call align.bwa {
    input:
      samplename       = samplename,
      read1            = seqyclean.read1_clean, 
      read2            = seqyclean.read2_clean,
      reference_genome = reference_genome
  }
  call consensus_call.primer_trim {
    input:
      samplename = samplename,
      bamfile    = bwa.sorted_bam,
      primer_BED = primer_BEDfile,
      docker     = ivar_docker
  }
  call consensus_call.variant_call {
    input:
      samplename = samplename,
      bamfile    = primer_trim.trim_sorted_bam,
      ref_genome = reference_genome,
      ref_gff    = reference_gff,
      docker     = ivar_docker
  }
  call consensus_call.consensus {
    input:
      samplename = samplename,
      bamfile    = primer_trim.trim_sorted_bam,
      ref_genome = reference_genome,
      docker     = ivar_docker
  }
  call assembly_metrics.stats_n_coverage {
    input:
      samplename = samplename,
      bamfile    = bwa.sorted_bam,
      docker     = samtools_docker
  }
  call assembly_metrics.stats_n_coverage as stats_n_coverage_primtrim {
    input:
      samplename = samplename,
      bamfile    = primer_trim.trim_sorted_bam,
      docker     = samtools_docker
  }
  call ncbi.vadr {
    input:
      genome_fasta = consensus.consensus_seq,
      assembly_length_unambiguous = consensus.number_ATCG,
      docker       = vadr_docker
  }
  call qa.audit_trail {
    input:
      analyst             = analyst,
      workflow_version    = version_capture.repo_version,
      workflow_date       = version_capture.date,

      specimen_id = samplename,
      lineage     = pangolin3.pangolin_lineage,

      reference_genome_fn = reference_genome_fn,
      reference_gff_fn    = reference_gff_fn,
      primer_BEDfile_fn   = primer_BEDfile_fn,

      fastqc_container = fastqc_raw.container,
      fastqc_version   = fastqc_raw.version,

      ncbi_scrub_container = ncbi_scrub_pe.container,

      seqyclean_container   = seqyclean.container,
      seqyclean_version     = seqyclean.version,
      seqyclean_adapterfile = seqyclean.adapterfile,

      kraken_container = kraken2.container,
      kraken_version   = kraken2.version,

      bwa_container          = bwa.container,
      align_bwa_version      = bwa.bwa_version,
      align_samtools_version = bwa.samtools_version,

      ivar_container             = consensus.container,
      primertrim_ivar_version    = primer_trim.ivar_version,
      variants_ivar_version      = variant_call.ivar_version,
      variants_samtools_version  = variant_call.samtools_version,
      consensus_ivar_version     = consensus.ivar_version,
      consensus_samtools_version = consensus.samtools_version,

      samtools_container         = stats_n_coverage.container,
      statsNcov_samtools_version = stats_n_coverage.version,

      pangolin_container  = analyst,
      pangolin_version    = analyst,
      pangoLEARN_version  = analyst,
      nextclade_container = analyst,
      nextclade_version   = analyst,
      vadr_container      = vadr.container,
      utiltiy_container   = utiltiy_docker
  }

  output {
    File    read1_dehosted = ncbi_scrub_pe.read1_dehosted
    File    read2_dehosted = ncbi_scrub_pe.read2_dehosted
    Int     read1_human_spots_removed = ncbi_scrub_pe.read1_human_spots_removed
    Int     read2_human_spots_removed = ncbi_scrub_pe.read2_human_spots_removed

    File    read1_clean        = seqyclean.read1_clean
    File    read2_clean        = seqyclean.read2_clean
    String  seqyclean_version  = seqyclean.version

    Int     fastqc_raw1        = fastqc_raw.read1_seq
    Int     fastqc_raw2        = fastqc_raw.read2_seq
    String  fastqc_raw_pairs   = fastqc_raw.read_pairs
    Int     fastqc_clean1      = fastqc_clean.read1_seq
    Int     fastqc_clean2      = fastqc_clean.read2_seq
    String  fastqc_clean_pairs = fastqc_clean.read_pairs
    String  fastqc_version     = fastqc_raw.version
   
    Float   kraken_human       = kraken2.percent_human
    Float   kraken_wnv         = kraken2.percent_virus
    String  kraken_version     = kraken2.version
    File    kraken_report      = kraken2.kraken_report

    File    sorted_bam         = bwa.sorted_bam
    File    sorted_bai         = bwa.sorted_bai
    String  bwa_version        = bwa.bwa_version
    String  sam_version        = bwa.samtools_version

    File    aligned_bam                 = primer_trim.trim_sorted_bam
    File    aligned_bai                 = primer_trim.trim_sorted_bai
    Float   primer_trimmed_read_percent = primer_trim.primer_trimmed_read_percent
    String  ivar_version_primtrim       = primer_trim.ivar_version

    File    ivar_tsv                    = variant_call.sample_variants
    String  ivar_version_variants       = variant_call.ivar_version
    String  samtools_version_variants   = variant_call.samtools_version

    File    consensus_seq               = consensus.consensus_seq
    Int     number_N                    = consensus.number_N
    Int     assembly_length_unambiguous = consensus.number_ATCG
    Int     number_Degenerate           = consensus.number_Degenerate
    Int     number_Total                = consensus.number_Total
    Float   percent_reference_coverage  = consensus.percent_reference_coverage
    String  ivar_version_consensus      = consensus.ivar_version
    String  samtools_version_consensus  = consensus.samtools_version    
    String  assembly_method             = "~{bwa.bwa_version}; ~{primer_trim.ivar_version}"

    File    consensus_stats            = stats_n_coverage.stats
    File    cov_hist                   = stats_n_coverage.cov_hist
    File    cov_stats                  = stats_n_coverage.cov_stats
    File    consensus_flagstat         = stats_n_coverage.flagstat
    Float   meanbaseq_trim             = stats_n_coverage_primtrim.meanbaseq
    Float   meanmapq_trim              = stats_n_coverage_primtrim.meanmapq
    Float   depth_trim                 = stats_n_coverage_primtrim.depth
    String  statsNcov_samtools_version = stats_n_coverage.version

    File?   vadr_alerts_list     = vadr.alerts_list
    String  vadr_num_alerts      = vadr.num_alerts

    File    audit_file           = audit_trail.audit_file
  }
}
