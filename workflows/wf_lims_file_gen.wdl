version 1.0

workflow sphl_lims_file_gen {
  meta {
    description: "Takes output from Theiagens Titan_ClearLabs and Titan_Illumina_PE and aggregates for LIMS integration"
  }
  input {
    Array[String]    samplename
    Array[String]    batchid
    Array[String]    seqdate
    Array[String]    assembly_status
    Array[Int]       fastqc_raw
    Array[Int]       fastqc_clean
    Array[Float]     kraken_human
    Array[Float]     kraken_sc2
    Array[Float]     kraken_human_dehosted
    Array[Float]     kraken_sc2_dehosted
    Array[Int]       number_N
    Array[Int]       assembly_length_unambiguous
    Array[Int]       number_Degenerate
    Array[Int]       number_Total
    Array[Float]     percent_reference_coverage
    Array[Float]     meanbaseq_trim
    Array[Float]     meanmapq_trim
    Array[Float]     assembly_mean_coverage
    Array[String]    pango_lineage
    Array[String]    pangolin_conflicts
    Array[String]    pango_version
    Array[String]    nextclade_aa_subs
    Array[String]    nextclade_aa_dels
    Array[String]    nextclade_clade
    Array[String]    lineage_to_maven
    String           organism = "SARS-CoV 2"
    String           test = "SARS-CoV-2 Sequencing"
    String           utiltiy_docker  = "quay.io/broadinstitute/viral-baseimage@sha256:340c0a673e03284212f539881d8e0fb5146b83878cbf94e4631e8393d4bc6753"
  }
  call lims_file_gen {
    input:
      samplename       = samplename,
      assembly_status  = assembly_status, 
      tool_lineage     = pango_lineage,
      lineage_to_maven = lineage_to_maven,
      pango_version    = pango_version,
      organism         = organism,
      test             = test,
      docker           = utiltiy_docker
  }  
  call run_results_file_gen {
    input:
      samplename                  = samplename,
      batchid                     = batchid,
      seqdate                     = seqdate,
      assembly_status             = assembly_status,
      pango_lineage               = pango_lineage,
      fastqc_raw                  = fastqc_raw,
      fastqc_clean                = fastqc_clean,
      kraken_human                = kraken_human,
      kraken_sc2                  = kraken_sc2,
      kraken_human_dehosted       = kraken_human_dehosted, 
      kraken_sc2_dehosted         = kraken_sc2_dehosted,
      number_N                    = number_N,
      assembly_length_unambiguous = assembly_length_unambiguous,
      number_Degenerate           = number_Degenerate,
      number_Total                = number_Total,
      percent_reference_coverage  = percent_reference_coverage,
      meanbaseq_trim              = meanbaseq_trim,
      meanmapq_trim               = meanmapq_trim,
      assembly_mean_coverage      = assembly_mean_coverage,
      pangolin_conflicts          = pangolin_conflicts,
      nextclade_aa_subs           = nextclade_aa_subs,
      nextclade_aa_dels           = nextclade_aa_dels,
      nextclade_clade             = nextclade_clade,
      pango_version               = pango_version,
      docker                      = utiltiy_docker
  }
  output {
    File      btb_lims_file = lims_file_gen.lims_file
    File      run_results_file = run_results_file_gen.results_file
  }
}

task lims_file_gen {
  input {
    Array[String]    samplename
    Array[String]    assembly_status
    Array[String]    tool_lineage
    Array[String]    lineage_to_maven
    Array[String]    pango_version
    String           organism
    String           test
    String           docker
  }
  command <<<
    python3 <<CODE
    samplename_array=['~{sep="','" samplename}']
    samplename_array_len=len(samplename_array)
    assembly_status_array=['~{sep="','" assembly_status}']
    assembly_status_array_len=len(assembly_status_array)
    tool_lineage_array=['~{sep="','" tool_lineage}']
    tool_lineage_array_len=len(tool_lineage_array)
    lineage_maven_array=['~{sep="','" lineage_to_maven}']
    lineage_maven_array_len=len(lineage_maven_array)
    pango_version_array=['~{sep="','" pango_version}']
    pango_version_array_len=len(pango_version_array)

    from datetime import datetime, timezone, timedelta
    outfile = open(f'{datetime.now(timezone(timedelta(hours=-4))).strftime("%Y-%m-%d")}.lims_file.csv', 'w')
    if samplename_array_len == assembly_status_array_len == tool_lineage_array_len == lineage_maven_array_len == pango_version_array_len:
      outfile.write('sample_id,assembly_status,tool_lineage,lineage_to_maven,pango_version,organism,test\n')
      index = 0
      print(f'Index:{index}\tSamplename:{samplename_array_len}')
      while index < samplename_array_len:
        print(f'Processing for index {index}')
        name = samplename_array[index]
        status = assembly_status_array[index]
        lineage = tool_lineage_array[index]
        lineage_maven = lineage_maven_array[index]
        pango = pango_version_array[index]
        outfile.write(f'{name},{status},{lineage},{lineage_maven},{pango},~{organism},~{test}\n')
        index += 1
    else: 
      print(f'Input arrays are of unequal length. (Samplename:{samplename_array_len}, Status:{assembly_status_array_len}, Tool Lineage:{tool_lineage_array_len})')
      outfile.write(f'Input arrays are of unequal length. (Samplename:{samplename_array_len}, Status:{assembly_status_array_len}, Tool Lineage:{tool_lineage_array_len})')
    CODE
  >>>
  output {
    File    lims_file = select_first(glob('*lims_file.csv'))
  }
  runtime {
    docker: docker
    memory: "1 GB"
    cpu: 1
  }
}


task run_results_file_gen {
  input {
    Array[String]    samplename
    Array[String]    batchid
    Array[String]    seqdate
    Array[String]    assembly_status
    Array[String]    pango_lineage
    Array[Int]       fastqc_raw
    Array[Int]       fastqc_clean
    Array[Float]     kraken_human
    Array[Float]     kraken_sc2
    Array[Float]     kraken_human_dehosted
    Array[Float]     kraken_sc2_dehosted
    Array[Int]       number_N
    Array[Int]       assembly_length_unambiguous
    Array[Int]       number_Degenerate
    Array[Int]       number_Total
    Array[Float]     percent_reference_coverage
    Array[Float]     meanbaseq_trim
    Array[Float]     meanmapq_trim
    Array[Float]     assembly_mean_coverage
    Array[String]    pangolin_conflicts
    Array[String]    nextclade_aa_subs
    Array[String]    nextclade_aa_dels
    Array[String]    nextclade_clade
    Array[String]    pango_version
    String           docker
  }
  command <<<
    python3 <<CODE
    samplename_array=['~{sep="','" samplename}']
    batchid_array=['~{sep="','" batchid}']
    seq_date_array=['~{sep="','" seqdate}']
    assembly_status_array=['~{sep="','" assembly_status}']
    pango_lineage_array=['~{sep="','" pango_lineage}']
    fastqc_raw_array=['~{sep="','" fastqc_raw}']
    fastqc_clean_array=['~{sep="','" fastqc_clean}']
    kraken_human_array=['~{sep="','" kraken_human}']
    kraken_sc2_array=['~{sep="','" kraken_sc2}']
    kraken_human_dehosted_array=['~{sep="','" kraken_human_dehosted}']
    kraken_sc2_dehosted_array=['~{sep="','" kraken_sc2_dehosted}']
    number_N_array=['~{sep="','" number_N}']
    assembly_length_unambiguous_array=['~{sep="','" assembly_length_unambiguous}']
    number_Degenerate_array=['~{sep="','" number_Degenerate}']
    number_Total_array=['~{sep="','" number_Total}']
    percent_reference_coverage_array=['~{sep="','" percent_reference_coverage}']
    meanbaseq_trim_array=['~{sep="','" meanbaseq_trim}']
    meanmapq_trim_array=['~{sep="','" meanmapq_trim}']
    assembly_mean_coverage_array=['~{sep="','" assembly_mean_coverage}']
    pangolin_conflicts_array=['~{sep="','" pangolin_conflicts}']
    nextclade_aa_subs_array=['~{sep="','" nextclade_aa_subs}']
    nextclade_aa_dels_array=['~{sep="','" nextclade_aa_dels}']
    nextclade_clade_array=['~{sep="','" nextclade_clade}']
    pango_version_array=['~{sep="','" pango_version}']

    fields = [batchid_array,assembly_status_array,pango_lineage_array,fastqc_raw_array,fastqc_clean_array,kraken_human_array,kraken_sc2_array,kraken_human_dehosted_array,kraken_sc2_dehosted_array,number_N_array,assembly_length_unambiguous_array,number_Degenerate_array,number_Total_array,percent_reference_coverage_array,meanbaseq_trim_array,meanmapq_trim_array,assembly_mean_coverage_array,pangolin_conflicts_array,nextclade_aa_subs_array,nextclade_aa_dels_array,nextclade_clade_array,pango_version_array]

    # count number of elements in each list. If not all equal, will not populate into table. 
    unequal = 0
    print(f'samplename_array : {len(samplename_array)}')
    for field in fields:
      print(f'{len(field)} : {field}')
      if len(field) != len(samplename_array):
        unequal += 1

    print(f'Number unequal to samplename_array {unequal}')
    from datetime import datetime, timezone, timedelta
    outfile = open(f'{datetime.now(timezone(timedelta(hours=-4))).strftime("%Y-%m-%d")}.run_results.csv', 'w')
    if unequal == 0:
      outfile.write('sample_id,batch_id,seq_date,assembly_status,pangolin_lineage,pangolin_conflict,pangolin_version,nextclade_lineage,AA_substitutions,AA_deletions,fastqc_raw_reads,fastqc_clean_reads,mean_depth,percent_reference_coverage,%_human_reads,%_SARS-COV-2_reads,dehosted_%human,dehosted_%SC2,num_N,num_degenerate,num_ACTG,num_total,meanbaseq_trim,meanmapq_trim\n')

      index = 0
      while index < len(samplename_array):
        samplename = samplename_array[index]
        batchid = batchid_array[index]
        seq_date = seq_date_array[index]
        assembly_status = assembly_status_array[index]
        pango_lineage = pango_lineage_array[index]
        fastqc_raw = fastqc_raw_array[index]
        fastqc_clean = fastqc_clean_array[index]
        kraken_human = kraken_human_array[index]
        kraken_sc2 = kraken_sc2_array[index]
        kraken_human_dehosted = kraken_human_dehosted_array[index]
        kraken_sc2_dehosted = kraken_sc2_dehosted_array[index]
        number_N = number_N_array[index]
        assembly_length_unambiguous = assembly_length_unambiguous_array[index]
        number_Degenerate = number_Degenerate_array[index]
        number_Total = number_Total_array[index]
        percent_reference_coverage = percent_reference_coverage_array[index]
        meanbaseq_trim = meanbaseq_trim_array[index]
        meanmapq_trim = meanmapq_trim_array[index]
        assembly_mean_coverage = assembly_mean_coverage_array[index]
        pangolin_conflicts = pangolin_conflicts_array[index]
        nextclade_aa_subs = nextclade_aa_subs_array[index].replace(',','|')
        nextclade_aa_dels = nextclade_aa_dels_array[index].replace(',','|')
        nextclade_clade = nextclade_clade_array[index]
        pango_version = pango_version_array[index]
        outfile.write(f'{samplename},{batchid},{seq_date},{assembly_status},{pango_lineage},{pangolin_conflicts},{pango_version},{nextclade_clade},{nextclade_aa_subs},{nextclade_aa_dels},{fastqc_raw},{fastqc_clean},{assembly_mean_coverage},{percent_reference_coverage},{kraken_human},{kraken_sc2},{kraken_human_dehosted},{kraken_sc2_dehosted},{number_N},{number_Degenerate},{assembly_length_unambiguous},{number_Total},{meanbaseq_trim},{meanmapq_trim}\n')
        index += 1
    else: 
      print(f'Input arrays are of unequal length.')
      outfile.write(f'Input arrays are of unequal length.\n')
      outfile.write(f'{len(samplename_array)}:\t{samplename_array}')
      for field in fields:
        outfile.write(f'{len(field)}:\t{field}\n')
    CODE
  >>>
  output {
    File    results_file = select_first(glob('*run_results.csv'))
  }
  runtime {
    docker: docker
    memory: "1 GB"
    cpu: 1
  }
}

