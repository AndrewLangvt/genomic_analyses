task sample_metrics {

  input {
    String    samplename
    String    submission_id
    String    collection_date
    String    pangolin_lineage
    String    pangolin_aLRT
    String    fastqc_raw_pairs
    String    seqy_pairs
    String    seqy_percent
    String    kraken_human
    String    kraken_sc2
    String    variant_num
    String    number_N
    String    number_ATCG
    String    number_Degenerate
    String    number_Total
    String    coverage
    String    depth
    String    meanbaseq_trim
    String    meanmapq_trim
    String    coverage_trim
    String    depth_trim
    String    amp_fail
  }

  command {
    echo "sample_id,deidentified_id,collection_date,\
    pangolin_lineage,pangolin_probability,\
    fastqc_raw_pairs,pairs_after_cleaning,percent_kept_after_cleaning,\
    depth_before_trimming,depth_after_trimming,coverage_before_trimming,coverage_after_trimming,\
    %_human_reads,%_SARS-COV-2_reads,num_failed_amplicons,num_variants,\
    num_N,num_degenerate,num_ACTG,num_total,meanbaseq_trim,meanmapq_trim,assembly_status"

    echo "${samplename},${submission_id},${collection_date},\
    ${pangolin_lineage},${pangolin_aLRT},\
    ${fastqc_raw_pairs},${seqy_pairs},${seqy_percent},\
    ${depth},${depth_trim},${coverage},${coverage_trim},\
    ${kraken_human},${kraken_sc2},${amp_fail},${variant_num},\
    ${number_N},${number_Degenerate},${number_ATCG},${number_Total},\
    ${meanbaseq_trim},${meanmapq_trim},ASSEMBLY_STATUS" | tee SAMPLE_METRICS
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
    echo "sample_id,deidentified_id,collection_date,\
    pangolin_lineage,pangolin_aLRT,pangolin_stats,\
    raw_pairs,pairs_after_cleaning,percent_kept_after_cleaning,\
    depth_before_trimming,depth_after_trimming,coverage_before_trimming,coverage_after_trimming,\
    %_human_reads,%_SARS-COV-2_reads,num_failed_amplicons,num_variants,\
    num_N,num_degenerate,num_ACTG,num_total,\
    meanbaseq_trim,meanmapq_trim,assembly_status" >> run_results.csv

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
