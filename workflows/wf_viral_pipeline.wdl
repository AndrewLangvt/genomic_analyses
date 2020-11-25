import "wf_refbased_assembly.wdl" as assembly
import "wf_read_QC_trim.wdl" as read_qc
import "../tasks/task_assembly_metrics.wdl"

workflow QC_n_assemble {
  input {
    String  sample_name
    File    read1_raw
    File    read2_raw 
    Array[Array[String]] workflow_config
  }

  call read_qc.read_QC_trim {
    input:
      sample_name = sample_name,
      read1_raw = read1_raw,
      read2_raw = read2_raw,
      workflow_params = workflow_config
  }
  call assembly.refbased_viral_assembly {
    input:
      sample_name = sample_name,
      read1_clean = read_QC_trim.read1_clean,
      read2_clean = read_QC_trim.read2_clean,
      workflow_params = workflow_config
  }

  output {
  	File	consensus_seq = refbased_viral_assembly.consensus_seq
  	File 	sorted_bamfiles = refbased_viral_assembly.sorted_bam
  	File 	sorted_baifiles = refbased_viral_assembly.sorted_bai
  	File 	primertrim_bamfiles = refbased_viral_assembly.primtrim_bam
  	File 	primertrim_baifiles = refbased_viral_assembly.primtrim_bai
  }
}