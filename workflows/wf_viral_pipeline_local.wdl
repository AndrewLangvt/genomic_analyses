import "wf_refbased_assembly.wdl" as assembly
import "../tasks/task_amplicon_metrics.wdl" as assembly_metrics
import "../tasks/task_sample_metrics.wdl" as summary


workflow nCoV19_pipeline {
  input {
    # File inputSamplesFile
    # Array[Array[String]] inputSamples = read_tsv(inputSamplesFile)
    Array[Pair[Array[String], Pair[File,File]]] inputSamples
    Array[Array[String]] inputConfig
  }

  scatter (sample in inputSamples) {
    call assembly.refbased_viral_assembly {
      input:
        samplename = sample.left[0],
        read1_raw = sample.right.left,
        read2_raw = sample.right.right
    }

    call summary.sample_metrics {
      input:
        samplename = sample.left[0],
        pangolin_lineage = refbased_viral_assembly.pangolin_lineage,
        pangolin_aLRT = refbased_viral_assembly.pangolin_aLRT,
        pangolin_stats = refbased_viral_assembly.pangolin_stats,
        seqy_pairs = refbased_viral_assembly.seqy_pairs,
        seqy_percent = refbased_viral_assembly.seqy_percent,
        fastqc_raw1 = refbased_viral_assembly.fastqc_raw1,
        fastqc_raw2 = refbased_viral_assembly.fastqc_raw2,
        fastqc_clean1 = refbased_viral_assembly.fastqc_clean1,
        fastqc_clean2 = refbased_viral_assembly.fastqc_clean2,
        kraken_human = refbased_viral_assembly.kraken_human,
        kraken_sc2 = refbased_viral_assembly.kraken_sc2,
        variant_num = refbased_viral_assembly.variant_num,
        number_N = refbased_viral_assembly.number_N,
        number_ATCG = refbased_viral_assembly.number_ATCG,
        number_Degenerate = refbased_viral_assembly.number_Degenerate,
        number_Total = refbased_viral_assembly.number_Total,
        coverage = refbased_viral_assembly.coverage,
        depth = refbased_viral_assembly.depth,
        meanbaseq_trim = refbased_viral_assembly.meanbaseq_trim,
        meanmapq_trim = refbased_viral_assembly.meanmapq_trim,
        coverage_trim = refbased_viral_assembly.coverage_trim, 
        depth_trim = refbased_viral_assembly.depth_trim,
        amp_fail = refbased_viral_assembly.amp_fail
    }
  }

  call assembly_metrics.ampli_multicov {
  	input:
  	  bamfiles = refbased_viral_assembly.sorted_bam,
  	  baifiles = refbased_viral_assembly.sorted_bai,
  	  primtrim_bamfiles = refbased_viral_assembly.primtrim_bam,
  	  primtrim_baifiles = refbased_viral_assembly.primtrim_bai
  }

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
