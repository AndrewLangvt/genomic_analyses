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
  }
}
#   call assembly_metrics.ampli_multicov {
#     input:
#       bamfiles = bwa.sorted_bam,
#       baifiles = bwa.sorted_bai,
#       primtrim_bamfiles = primer_trim.trim_sorted_bam,
#       primtrim_baifiles = primer_trim.trim_sorted_bai
#   }
# }
   
# task sampleIDs {
#   String      samplename
#   String      submission_id 
#   String      collection

#   command {
#     echo ${collection} | tee COLLECTIONDATE
#     echo ${submission_id} | tee SUBMISSION_ID
#     echo ${samplename} | tee SAMPLENAME
#   }

#   output { 
#     String    collectiondate=read_string("COLLECTIONDATE")
#     String    submissionID=read_string("SUBMISSION_ID")
#     String    sample=read_string("SAMPLENAME")
#   }

#   runtime {
#       docker:       "staphb/seqyclean:1.10.09"
#       memory:       "8 GB"
#       cpu:          2
#       disks:        "local-disk 100 SSD"
#       preemptible:  0
#   }  
# }

# task {
#   File        something
#   String      samplename

#   command{
#     # date and version control
#     date | tee DATE
#     toolanme --version | tee VERSION

#   }

#   output {
#     String     date = read_string("DATE")
#     String     version = read_string("VERSION") 
#   }

#   runtime {
#     docker:       "staphb/seqyclean:1.10.09"
#     memory:       "8 GB"
#     cpu:          2
#     disks:        "local-disk 100 SSD"
#     preemptible:  0      
#   }
# }

#  seqyclean
#  bwa
#  ivar_trim
#  samtools_sort
#  ivar_variants
#  ivar_consensus
#  fastqc
#  samtools_stats
#  samtools_coverage
#  samtools_flagstat
#  kraken2 - > sub metaphlan? 
#  bedtools
#  summary
#  combine_summary
#  file_submission
#  multifasta


