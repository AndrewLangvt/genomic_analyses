version 1.0

task sample_metrics {

  input {
    String    samplename
    String    submission_id
    String    collection_date
    String    fastqc_raw_pairs
    Int       read1_human_spots_removed
    Int       read2_human_spots_removed
    String    fastqc_clean_pairs
    String    pangolin_lineage
    String    pangolin_conflicts
    String    nextclade_clade
    String    nextclade_aa_subs
    String    nextclade_aa_dels
    Float     primer_trimmed_read_percent
    Float     depth_trim
    Float     coverage
    Float     kraken_human
    Float     kraken_sc2
    Int       number_N
    Int       number_ATCG
    Int       number_Degenerate
    Int       number_Total
    String    vadr_num_alerts
    Float     meanbaseq_trim
    Float     meanmapq_trim
    Float?    coverage_threshold = 95.00
    Float?    length_threshold = 28000
    Float?    meanbaseq_threshold = 30.00
    Float?    meanmapq_threshold = 30.00
  }

  command <<<
  python3<<CODE

  if ~{coverage} >= ~{coverage_threshold} and ~{number_Total} >= ~{length_threshold} and ~{meanbaseq_trim} >= ~{meanbaseq_threshold} and ~{meanmapq_trim} >= ~{meanmapq_threshold}:
    assembly_status = "PASS"
  else:
    assembly_status = "FAIL"

  #nextclade_clade_dash='~{nextclade_clade}'.replace(',','-')    #nextclade recently started including commas in the clade output. This replaces with a -

  outstring=f"~{samplename},~{submission_id},~{collection_date},\
  ~{pangolin_lineage},~{pangolin_conflicts},\
  ~{nextclade_clade},~{nextclade_aa_subs},~{nextclade_aa_dels},\
  ~{fastqc_raw_pairs},~{read1_human_spots_removed},~{read2_human_spots_removed},~{fastqc_clean_pairs},~{primer_trimmed_read_percent},\
  ~{depth_trim},~{coverage},\
  ~{kraken_human},~{kraken_sc2},\
  ~{number_N},~{number_Degenerate},~{number_ATCG},~{number_Total},\
  ~{vadr_num_alerts},\
  ~{meanbaseq_trim},~{meanmapq_trim}," + assembly_status

  print(outstring)

  CODE
  >>>

  output {
    String  single_metrics = read_string(stdout())
  }

  runtime {
      docker:       "quay.io/broadinstitute/viral-baseimage@sha256:340c0a673e03284212f539881d8e0fb5146b83878cbf94e4631e8393d4bc6753"
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

  command <<<
    echo "sample_id,deidentified_id,collection_date,\
    pangolin_lineage,pangolin_conflicts,\
    nextclade_lineage,nextclade_aaSubstitutions,nextclade_aaDeletions,\
    raw_pairs,read1_human_spots,read2_human_spots,cleaned_pairs,primer_trimmed_read_percent,\
    depth_after_trimming,coverage,\
    %_human_reads,%_SARS-COV-2_reads,\
    num_N,num_degenerate,num_ACTG,num_total,\
    vadr_num_alerts,\
    meanbaseq_trim,meanmapq_trim,assembly_status" >> run_results.csv

    echo "~{sep="END" all_metrics}" >> run_results.csv
    sed -i "s/END/\n/g" run_results.csv
  >>>

  output {
    File    run_results = "run_results.csv"
  }

  runtime {
      docker:       "quay.io/broadinstitute/viral-baseimage@sha256:340c0a673e03284212f539881d8e0fb5146b83878cbf94e4631e8393d4bc6753"
      memory:       "1 GB"
      cpu:          1
      disks:        "local-disk 100 SSD"
      preemptible:  0
  }
}
