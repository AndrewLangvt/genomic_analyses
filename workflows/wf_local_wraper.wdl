import "wf_viral_pipeline.wdl" as viral_pipe
import "../tasks/task_assembly_metrics.wdl" as assembly_metrics

workflow local_deployment {
  input {
    Array[Pair[Array[String], Pair[File,File]]] inputSamples
    Array[Array[String]] inputConfig
  }
  scatter (sample_info in inputSamples) {
	call viral_pipe.QC_n_assemble as viral_pipeline {
	  input:
	    sample_name = sample_info.left[0],
	    read1_raw = sample_info.right.left,
	    read2_raw = sample_info.right.right,
	    workflow_config = inputConfig
	}
  }

  call assembly_metrics.ampli_multicov {
  	input:
  	  bamfiles = viral_pipeline.sorted_bamfiles,
  	  baifiles = viral_pipeline.sorted_baifiles,
  	  primtrim_bamfiles = viral_pipeline.primertrim_bamfiles,
  	  primtrim_baifiles = viral_pipeline.primertrim_baifiles
  }
}
