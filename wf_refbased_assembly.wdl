import "tasks/task_read_clean.wdl" as read_clean 
import "tasks/task_alignment.wdl" as align
import "tasks/task_consensus_call.wdl" as consensus_call
import "tasks/task_qc_utils.wdl" as qc_utils
import "tasks/task_assembly_metrics.wdl" as assembly_metrics
import "tasks/task_taxonID.wdl" as taxonID

workflow refbased_viral_assembly {

  # File inputSamplesF
  # File inputConfigF
  # Array[Pair[Array[String], Pair[File,File]]] inputSamples = inputSamplesF
  # Array[Array[String]] inputConfig = inputConfigF
  input {
    Array[Pair[Array[String], Pair[File,File]]] inputSamples
    Array[Array[String]] inputConfig
  }

  scatter (sample in inputSamples) {
    # call sampleIDs {
    #   input:
    #     samplename = sample.left[0],
    #     submission_id = sample.left[1],
    #     collection = sample.left[2]
    # }
    call read_clean.seqyclean {
      input:
        samplename = sample.left[0],
        read1 = sample.right.left,
        read2 = sample.right.right,
        adapters = inputConfig[0][1]
    }
    call align.bwa {
      input:
        samplename = sample.left[0],
        read1 = seqyclean.read1_clean, 
        read2 = seqyclean.read2_clean
    }
    call consensus_call.primer_trim {
      input:
        samplename = sample.left[0],
        bamfile = bwa.sorted_bam
    }
    call consensus_call.variant_call {
      input:
        samplename = sample.left[0],
        bamfile = primer_trim.trim_sorted_bam
    }
    call consensus_call.consensus {
      input:
        samplename = sample.left[0],
        bamfile = primer_trim.trim_sorted_bam
    }
    call qc_utils.fastqc as fastqc_raw {
      input:
        read1 = sample.right.left,
        read2 = sample.right.right
    }
    call qc_utils.fastqc as fastqc_clean {
      input:
        read1 = seqyclean.read1_clean,
        read2 = seqyclean.read2_clean
    }
    call assembly_metrics.stats_n_coverage {
      input:
        samplename = sample.left[0],
        bamfile = bwa.sorted_bam
    }
    call taxonID.kraken2 {
      input:
        samplename = sample.left[0],
        read1 = seqyclean.read1_clean, 
        read2 = seqyclean.read2_clean
    }
  }
  call assembly_metrics.ampli_multicov {
    input:
      bamfiles = bwa.sorted_bam,
      baifiles = bwa.sorted_bai,
      primtrim_bamfiles = primer_trim.trim_sorted_bam,
      primtrim_baifiles = primer_trim.trim_sorted_bai
  }
}
   
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


