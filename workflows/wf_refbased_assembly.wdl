import "../tasks/task_alignment.wdl" as align
import "../tasks/task_consensus_call.wdl" as consensus_call
import "../tasks/task_assembly_metrics.wdl" as assembly_metrics

workflow refbased_viral_assembly {

  input {
    String  samplename
    File    read1_clean
    File    read2_clean 
    Array[Array[String]] workflow_params
  }

  call align.bwa {
    input:
      samplename = samplename,
      read1 = read1_clean, 
      read2 = read2_clean
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

  output {
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
    String  meanbaseq = stats_n_coverage.meanbaseq
    String  meanmapq = stats_n_coverage.meanmapq
  }
}