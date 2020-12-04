import "wf_refbased_assembly.wdl" as assembly
import "wf_read_QC_trim.wdl" as read_qc

workflow QC_assemble_viral {
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
    File     read1_clean = read_QC_trim.read1_clean
    File     read2_clean = read_QC_trim.read2_clean
    String   seqy_pairs = read_QC_trim.seqy_pairs
    String   seqy_percent = read_QC_trim.seqy_percent
    String   fastqc_raw1 = read_QC_trim.fastqc_raw1
    String   fastqc_raw2 = read_QC_trim.fastqc_raw2
    String   fastqc_trim1 = read_QC_trim.fastqc_clean1
    String   fastqc_trim2 = read_QC_trim.fastqc_clean2
    String   kraken_human = read_QC_trim.kraken_human
    String   kraken_sc2 = read_QC_trim.kraken_sc2

    String   coverage = refbased_viral_assembly.coverage
    String   depth = refbased_viral_assembly.depth
    String   meanbaseq = refbased_viral_assembly.meanbaseq
    String   meanmapq = refbased_viral_assembly.meanmapq
    String   variant_num = refbased_viral_assembly.variant_num
    File     consensus_seq = refbased_viral_assembly.consensus_seq
    String   number_N = refbased_viral_assembly.number_N
    String   number_ATCG = refbased_viral_assembly.number_ATCG
    String   number_Degenerate = refbased_viral_assembly.number_Degenerate
    String   number_Total = refbased_viral_assembly.number_Total
    File     sorted_bamfiles = refbased_viral_assembly.sorted_bam
    File     sorted_baifiles = refbased_viral_assembly.sorted_bai
    File     primertrim_bamfiles = refbased_viral_assembly.primtrim_bam
    File     primertrim_baifiles = refbased_viral_assembly.primtrim_bai
  }
}