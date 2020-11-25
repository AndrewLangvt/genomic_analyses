import "../tasks/task_alignment.wdl" as align
import "../tasks/task_consensus_call.wdl" as consensus_call
import "../tasks/task_assembly_metrics.wdl" as assembly_metrics

workflow refbased_viral_assembly {

  input {
    String  sample_name
    File    read1_clean
    File    read2_clean 
    Array[Array[String]] workflow_params
  }

  call align.bwa {
    input:
      samplename = sample_name,
      read1 = read1_clean, 
      read2 = read2_clean
  }
  call consensus_call.primer_trim {
    input:
      samplename = sample_name,
      bamfile = bwa.sorted_bam
  }
  call consensus_call.variant_call {
    input:
      samplename = sample_name,
      bamfile = primer_trim.trim_sorted_bam
  }
  call consensus_call.consensus {
    input:
      samplename = sample_name,
      bamfile = primer_trim.trim_sorted_bam
  }
  call assembly_metrics.stats_n_coverage {
    input:
      samplename = sample_name,
      bamfile = bwa.sorted_bam
  }

  output {
    File  consensus_seq = consensus.consensus_seq
    File  sorted_bam = bwa.sorted_bam
    File  sorted_bai = bwa.sorted_bai
    File  primtrim_bam = primer_trim.trim_sorted_bam
    File  primtrim_bai = primer_trim.trim_sorted_bai
  }
}