task sample_metrics {

  input {
    String    samplename
    String    seqy_pairs
    String    seqy_percent
    String    fastqc_raw1
    String    fastqc_raw2
    String    fastqc_clean1
    String    fastqc_clean2
    String    kraken_human
    String    kraken_sc2
    String    variant_num
    String    number_N
    String    number_ATCG
    String    number_Degenerate
    String    number_Total
    String    coverage
    String    depth
    String    meanbaseq
    String    meanmapq
  }

  command {
    echo 
    sample_id,deidentified_id,collection_date,\
    pangolin_lineage,pangolin_aLRT,pangolin_stats,\
    fastqc_raw_reads_1,fastqc_raw_reads_2,fastqc_clean_reads_PE1,fastqc_clean_reads_PE2,\
    pairs_kept_after_cleaning,percent_kept_after_cleaning,\
    depth_before_trimming,depth_after_trimming,coverage_before_trimming,coverage_after_trimming,\
    %_human_reads,%_SARS-COV-2_reads,num_failed_amplicons,num_variants,\
    num_N,num_degenerate,num_ACTG,num_total,meanbaseq_trim,meanmapq_trim,assembly_status

    echo "${samplename},${seqy_pairs},${seqy_percent},\
    ${fastqc_raw1},${fastqc_raw2},${fastqc_clean1},${fastqc_clean2},\
    ${kraken_human},${kraken_sc2},${variant_num},\
    ${number_N},${number_ATCG},${number_Degenerate},${number_Total},\
    ${coverage},${depth},${meanbaseq},${meanmapq}" | tee SAMPLE_METRICS
  }

  output {
    String  single_metrics = read_string("SAMPLE_METRICS")
  }

  runtime {
      docker:       "staphb/seqyclean:1.10.09"
      memory:       "1 GB"
      cpu:          1
      disks:        "local-disk 100 SSD"
      preemptible:  0
  }
}

task merge_metrics {

  input {
  Array[String]   all_metrics
  }

  command {
    echo ${sep="END" all_metrics} >> run_results.csv
    sed -i "s/END/\n/g" run_results.csv
  }

  output {
    File    run_results = "run_results.csv"
  }

  runtime {
      docker:       "staphb/seqyclean:1.10.09"
      memory:       "1 GB"
      cpu:          1
      disks:        "local-disk 100 SSD"
      preemptible:  0
  }
}
