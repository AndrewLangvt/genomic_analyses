import "wf_read_QC_trim.wdl" as read_qc
import "../tasks/task_alignment.wdl" as align
import "../tasks/task_consensus_call.wdl" as consensus_call
import "../tasks/task_assembly_metrics.wdl" as assembly_metrics
import "../tasks/task_taxonID.wdl" as taxon_ID

workflow refbased_viral_assembly {

  input {
    String  samplename
    File    read1_raw
    File    read2_raw 
    Array[Array[String]] workflow_params
  }

  call read_qc.read_QC_trim {
    input:
      samplename = samplename,
      read1_raw = read1_raw,
      read2_raw = read2_raw,
      workflow_params = workflow_params
  }
  call align.bwa {
    input:
      samplename = samplename,
      read1 = read_QC_trim.read1_clean, 
      read2 = read_QC_trim.read2_clean
  }
  call consensus_call.primer_trim {
    input:
      samplename = samplename,
      bamfile = bwa.sorted_bam
  }
  call consensus_call.variant_call {
    input:
      samplename = samplename,
      bamfile = primer_trim.trim_sorted_bam
  }
  call consensus_call.consensus {
    input:
      samplename = samplename,
      bamfile = primer_trim.trim_sorted_bam
  }
  call assembly_metrics.stats_n_coverage {
    input:
      samplename = samplename,
      bamfile = bwa.sorted_bam
  }
  call assembly_metrics.stats_n_coverage as stats_n_coverage_primtrim {
    input:
      samplename = samplename,
      bamfile = primer_trim.trim_sorted_bam
  } 
  call taxon_ID.pangolin {
    input:
      samplename = samplename,
      fasta = consensus.consensus_seq
  }
  output {
    File     read1_clean = read_QC_trim.read1_clean
    File     read2_clean = read_QC_trim.read2_clean
    String   seqy_pairs = read_QC_trim.seqy_pairs
    String   seqy_percent = read_QC_trim.seqy_percent
    String   fastqc_raw1 = read_QC_trim.fastqc_raw1
    String   fastqc_raw2 = read_QC_trim.fastqc_raw2
    String   fastqc_clean1 = read_QC_trim.fastqc_clean1
    String   fastqc_clean2 = read_QC_trim.fastqc_clean2
    String   kraken_human = read_QC_trim.kraken_human
    String   kraken_sc2 = read_QC_trim.kraken_sc2

    File    sorted_bam = bwa.sorted_bam
    File    sorted_bai = bwa.sorted_bai
    File    primtrim_bam = primer_trim.trim_sorted_bam
    File    primtrim_bai = primer_trim.trim_sorted_bai
    String  variant_num = variant_call.variant_num
    File    consensus_seq = consensus.consensus_seq
    String  number_N = consensus.number_N
    String  number_ATCG = consensus.number_ATCG
    String  number_Degenerate = consensus.number_Degenerate
    String  number_Total = consensus.number_Total
    # File    consensus_stats = stats_n_coverage.stats
    # File    cov_hist = stats_n_coverage.cov_hist
    # File    cov_stats = stats_n_coverage.cov_stats
    # File    consensus_flagstat = stats_n_coverage.flagstat
    String  coverage = stats_n_coverage.coverage
    String  depth = stats_n_coverage.depth
    String  meanbaseq_trim = stats_n_coverage_primtrim.meanbaseq
    String  meanmapq_trim = stats_n_coverage_primtrim.meanmapq
    String  coverage_trim = stats_n_coverage_primtrim.coverage
    String  depth_trim = stats_n_coverage_primtrim.depth


    String  pangolin_lineage = pangolin.pangolin_lineage
    String  pangolin_aLRT = pangolin.pangolin_aLRT
    String  pangolin_stats = pangolin.pangolin_stats
    File    lineage_report = pangolin.lineage_report
  }
}