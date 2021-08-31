version 1.0

task version_capture {
  input {
    String? timezone
  }
  meta {
    volatile: true
  }
  command {
    Repo_Version="v1.0"
    ~{default='' 'export TZ=' + timezone}
    date +"%Y-%m-%d" > TODAY
    echo $Repo_Version > REPO_VERSION
  }
  output {
    String date = read_string("TODAY")
    String repo_version = read_string("REPO_VERSION")
  }
  runtime {
    memory: "1 GB"
    cpu: 1
    docker: "quay.io/broadinstitute/viral-baseimage@sha256:340c0a673e03284212f539881d8e0fb5146b83878cbf94e4631e8393d4bc6753"
    disks: "local-disk 10 HDD"
    dx_instance_type: "mem1_ssd1_v2_x2" 
  }
}

task audit_trail {

  input {
    String    analyst
    String    workflow_version
    String    workflow_date

    String    specimen_id
    String    lineage

    String    reference_genome_fn
    String    reference_gff_fn
    String    primer_BEDfile_fn

    String    fastqc_container
    String    fastqc_version

    String    ncbi_scrub_container

    String    seqyclean_container
    String    seqyclean_version
    String    seqyclean_adapterfile

    String    kraken_container
    String    kraken_version

    String    bwa_container
    String    align_bwa_version
    String    align_samtools_version

    String    ivar_container
    String    primertrim_ivar_version
    String    variants_ivar_version
    String    variants_samtools_version
    String    consensus_ivar_version
    String    consensus_samtools_version

    String    samtools_container
    String    statsNcov_samtools_version

    String    pangolin_container
    String    pangolin_version
    String    pangoLEARN_version

    String    nextclade_container
    String    nextclade_version

    String    vadr_container

    String    utiltiy_container
  }
  command <<<
    python3 <<CODE
    import json

    with open('~{specimen_id}_audit.json', 'w', encoding='utf-8') as auditf:
      samp_trail = {
        "specimen_id": "~{specimen_id}",
        "lineage": "~{lineage}",
        "analyst": "~{analyst}",
        "workflow_version": "~{workflow_version}",
        "workflow_date": "~{workflow_date}",
        "workflow_version": "~{workflow_version}",
        "reference_genome_fn": "~{reference_genome_fn}",
        "reference_gff_fn": "~{reference_gff_fn}",
        "primer_BEDfile_fn": "~{primer_BEDfile_fn}",
        "fastqc_container": "~{fastqc_container}",
        "fastqc_version": "~{fastqc_version}",
        "ncbi_scrub_container": "~{ncbi_scrub_container}",
        "seqyclean_container": "~{seqyclean_container}",
        "seqyclean_version": "~{seqyclean_version}",
        "seqyclean_adapterfile": "~{seqyclean_adapterfile}",
        "kraken_container": "~{kraken_container}",
        "kraken_version": "~{kraken_version}",
        "bwa_container": "~{bwa_container}",
        "align_bwa_version": "~{align_bwa_version}",
        "align_samtools_version": "~{align_samtools_version}",
        "ivar_container": "~{ivar_container}",
        "primertrim_ivar_version": "~{primertrim_ivar_version}",
        "variants_ivar_version": "~{variants_ivar_version}",
        "variants_samtools_version": "~{variants_samtools_version}",
        "consensus_ivar_version": "~{consensus_ivar_version}",
        "consensus_samtools_version": "~{consensus_samtools_version}",
        "samtools_container": "~{samtools_container}",
        "statsNcov_samtools_version": "~{statsNcov_samtools_version}",
        "pangolin_container": "~{pangolin_container}",
        "pangolin_version": "~{pangolin_version}",
        "pangoLEARN_version": "~{pangoLEARN_version}",
        "nextclade_container": "~{nextclade_container}",
        "nextclade_version": "~{nextclade_version}",
        "vadr_container": "~{vadr_container}",
        "utiltiy_container": "~{utiltiy_container}"
      }
      auditf.write(json.dumps(samp_trail, indent = 4))
    auditf.close()
    CODE
  >>>

  output {
    File    audit_file = "~{specimen_id}_audit.json"
  }

  runtime {
      docker:       "quay.io/broadinstitute/viral-baseimage@sha256:340c0a673e03284212f539881d8e0fb5146b83878cbf94e4631e8393d4bc6753"
      memory:       "1 GB"
      cpu:          1
      disks:        "local-disk 100 SSD"
      preemptible:  0
  }
}
