import "../tasks/task_qc_utils.wdl" as qc_utils
import "../tasks/task_read_clean.wdl" as read_clean 
import "../tasks/task_taxonID.wdl" as taxonID

workflow read_QC_trim {
  input {
    String  sample_name
    File    read1_raw
    File    read2_raw 
    Array[Array[String]] workflow_params
  }

  call read_clean.seqyclean {
    input:
      samplename = sample_name,
      read1 = read1_raw,
      read2 = read2_raw,
      adapters = workflow_params[0][1]
  }
  call qc_utils.fastqc as fastqc_raw {
    input:
      read1 = read1_raw,
      read2 = read2_raw,
  }
  call qc_utils.fastqc as fastqc_clean {
    input:
      read1 = seqyclean.read1_clean,
      read2 = seqyclean.read2_clean
  }
  call taxonID.kraken2 {
    input:
      samplename = sample_name,
      read1 = seqyclean.read1_clean, 
      read2 = seqyclean.read2_clean
  }

  output {
  	File 	read1_clean = seqyclean.read1_clean
  	File 	read2_clean = seqyclean.read2_clean
  }
}
