import "wf_refbased_assembly.wdl" as assembly
import "wf_read_QC_trim.wdl" as read_qc
import "../tasks/task_taxonID.wdl" as taxon_ID
import "../tasks/task_assembly_metrics.wdl" as assembly_metrics
import "../tasks/task_sample_metrics.wdl" as summary

workflow {
  input {
        # File inputSamplesFile
    # Array[Array[String]] inputSamples = read_tsv(inputSamplesFile)
    Array[Pair[Array[String], Pair[File,File]]] inputSamples
    Array[Array[String]] inputConfig
  }
  call {
    parse-json
  }
  output{
    id
    read1_clean
    read2_clean
  }
}
scatter{
  
sub-workflow viral_pipeline {
  input {
    pj.id
    pj.read1_clean
    pj.reads2

  }

  

  scatter (sample in inputSamples) {
    call read_qc.read_QC_trim {
      input:
        samplename = sample.left[0],
        read1_raw = sample.right.left,
        read2_raw = sample.right.right,
        workflow_params = inputConfig
    }
    call assembly.refbased_viral_assembly {
      input:
        samplename = sample.left[0],
        read1_clean = read_QC_trim.read1_clean,
        read2_clean = read_QC_trim.read2_clean,
        workflow_params = inputConfig
    }
    # call taxon_ID.pangolin {
    #   input:
    #     samplename = sample.left[0],
    #     fasta = refbased_viral_assembly.consensus_seq
    # }
    sub-workf summary.sample_metrics {
      input:
        samplename = sample.left[0],
        seqy_pairs = read_QC_trim.seqy_pairs,
        seqy_percent = read_QC_trim.seqy_percent,
        fastqc_raw1 = read_QC_trim.fastqc_raw1,
        fastqc_raw2 = read_QC_trim.fastqc_raw2,
        fastqc_clean1 = read_QC_trim.fastqc_clean1,
        fastqc_clean2 = read_QC_trim.fastqc_clean2,
        kraken_human = read_QC_trim.kraken_human,
        kraken_sc2 = read_QC_trim.kraken_sc2,
        variant_num = refbased_viral_assembly.variant_num,
        number_N = refbased_viral_assembly.number_N,
        number_ATCG = refbased_viral_assembly.number_ATCG,
        number_Degenerate = refbased_viral_assembly.number_Degenerate,
        number_Total = refbased_viral_assembly.number_Total,
        coverage = refbased_viral_assembly.coverage,
        depth = refbased_viral_assembly.depth,
        meanbaseq = refbased_viral_assembly.meanbaseq,
        meanmapq = refbased_viral_assembly.meanmapq,
        pangolin_lineage = "PANGOLIN_LINEAGE"
        pangolin_aLRT = "PANGOLIN_aLRT"
        pangolin_stats = "PANGOLIN_STATS"
    }
  }

  # call assembly_metrics.ampli_multicov {
  # 	input:
  # 	  bamfiles = refbased_viral_assembly.sorted_bam,
  # 	  baifiles = refbased_viral_assembly.sorted_bai,
  # 	  primtrim_bamfiles = refbased_viral_assembly.primtrim_bam,
  # 	  primtrim_baifiles = refbased_viral_assembly.primtrim_bai
  # }

  call summary.merge_metrics {
    input:
      all_metrics = sample_metrics.single_metrics
  }

  output {
    # Array[File]  consensus = refbased_viral_assembly.consensus_seq
    # File         multicov = ampli_multicov.amp_coverage
    Array[String]   indiv_metrics = sample_metrics.single_metrics
    File            merged_metrics = merge_metrics.run_results
  }
}
