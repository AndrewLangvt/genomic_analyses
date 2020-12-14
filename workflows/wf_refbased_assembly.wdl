import "wf_read_QC_trim.wdl" as read_qc
import "../tasks/task_alignment.wdl" as align
import "../tasks/task_consensus_call.wdl" as consensus_call
import "../tasks/task_assembly_metrics.wdl" as assembly_metrics
import "../tasks/task_taxonID.wdl" as taxon_ID
import "../tasks/task_amplicon_metrics.wdl" as amplicon_metrics

workflow refbased_viral_assembly {
  input {
    String  samplename
    File    read1_raw
    File    read2_raw 
  }

  call read_qc.read_QC_trim {
    input:
      samplename = samplename,
      read1_raw = read1_raw,
      read2_raw = read2_raw
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
  call taxon_ID.pangolin2 {
    input:
      samplename = samplename,
      fasta = consensus.consensus_seq
  }
  call amplicon_metrics.bedtools_cov {
    input:
      bamfile = bwa.sorted_bam,
      baifile = bwa.sorted_bai
  }
  output {
    File    read1_clean = read_QC_trim.read1_clean
    File    read2_clean = read_QC_trim.read2_clean
    String  fastqc_raw1 = read_QC_trim.fastqc_raw1
    String  fastqc_raw2 = read_QC_trim.fastqc_raw2
    String  fastqc_raw_pairs = read_QC_trim.fastqc_raw_pairs
    String  fastqc_version = read_QC_trim.fastqc_version

    String  seqy_pairs = read_QC_trim.seqy_pairs
    String  seqy_percent = read_QC_trim.seqy_percent
    String  fastqc_clean1 = read_QC_trim.fastqc_clean1
    String  fastqc_clean2 = read_QC_trim.fastqc_clean2
    String  fastqc_clean_pairs = read_QC_trim.fastqc_clean_pairs
    String  seqyclean_version = read_QC_trim.seqyclean_version
   
    String  kraken_human = read_QC_trim.kraken_human
    String  kraken_sc2 = read_QC_trim.kraken_sc2
    String  kraken_version = read_QC_trim.kraken_version

    File    sorted_bam = bwa.sorted_bam
    File    sorted_bai = bwa.sorted_bai
    String  bwa_version = bwa.bwa_version
    String  sam_version = bwa.sam_version

    File    primtrim_bam = primer_trim.trim_sorted_bam
    File    primtrim_bai = primer_trim.trim_sorted_bai
    String  ivar_version_primtrim = primer_trim.ivar_version
    String  samtools_version_primtrim = primer_trim.samtools_version

    String  variant_num = variant_call.variant_num
    String  ivar_version_variants = variant_call.ivar_version
    String  samtools_version_variants = variant_call.samtools_version

    File    consensus_seq = consensus.consensus_seq
    String  number_N = consensus.number_N
    String  number_ATCG = consensus.number_ATCG
    String  number_Degenerate = consensus.number_Degenerate
    String  number_Total = consensus.number_Total
    String  ivar_version_consensus = consensus.ivar_version
    String  samtools_version_consensus = consensus.samtools_version    

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
    String  samtools_version_stats = stats_n_coverage.samtools_version

    # String  pangolin_lineage = pangolin.pangolin_lineage
    # String  pangolin_aLRT = pangolin.pangolin_aLRT
    # String  pangolin_stats = pangolin.pangolin_stats
    String  pangolin_lineage = pangolin2.pangolin_lineage
    String  pangolin_aLRT = pangolin2.pangolin_aLRT
    File    lineage_report = pangolin2.lineage_report
    String  pangolin_version = pangolin2.version

    String  amp_fail = bedtools_cov.amp_fail
    File    amp_coverage = bedtools_cov.amp_coverage
    String  bedtools_version = bedtools_cov.version
  }
}