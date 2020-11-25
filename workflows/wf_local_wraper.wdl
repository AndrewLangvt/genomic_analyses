import "wf_refbased_assembly.wdl" as assembly
import "wf_read_QC_trim.wdl" as read_qc

workflow local_deployment {
  input {
    Array[Pair[Array[String], Pair[File,File]]] inputSamples
    Array[Array[String]] inputConfig
  }
  scatter (sample_info in inputSamples) {
	call read_qc.read_QC_trim {
	  input:
	    sample_name = sample_info.left[0],
	    left_read = sample_info.right.left,
	    right_read = sample_info.right.right,
	    workflow_params = inputConfig
	}
	call assembly.refbased_viral_assembly {
	  input:
	    sample_name = sample_info.left[0],
	    read1_clean = read_QC_trim.read1_clean,
	    read2_clean = read_QC_trim.read2_clean,
	    workflow_params = inputConfig
	}
  }
}
