version 1.0

task deidentify {

  input {
    String    samplename
    String    submission_id
    File      sequence
    String    assembly_or_consensus = "consensus"

    String    docker_image = "staphb/seqyclean:1.10.09"
    Int       mem_size_gb = 3
    Int       CPUs = 1
    Int       disk_size = 100
    Int       preemptible_tries = 0
  }

  command {
    # de-identified consensus/assembly sequence
    echo ">${submission_id}" > ${submission_id}.${assembly_or_consensus}.fa
    grep -v ">" ${sequence} >> ${submission_id}.${assembly_or_consensus}.fa
  }

  output {
    File      deID_assembly = "${submission_id}.${assembly_or_consensus}.fa"
  }

  runtime {
      docker:       docker_image
      memory:       "~{mem_size_gb} GB"
      cpu:          CPUs
      disks:        "local-disk ~{disk_size} SSD"
      preemptible:  preemptible_tries
  }
}

task gisaid {

  input {
    String    samplename
    String    submission_id
    String    collection_date
    File      sequence
    String    iso_host
    String    iso_country

    String    docker_image = "staphb/seqyclean:1.10.09"
    Int       mem_size_gb = 3
    Int       CPUs = 1
    Int       disk_size = 10
    Int       preemptible_tries = 0
  }

  command {
    # de-identified consensus/assembly sequence
    year=$(echo ${collection_date} | cut -f 1 -d '-')
    echo ">hCoV-19/${iso_country}/${submission_id}/$year" > ${submission_id}.gisaid.fa
    grep -v ">" ${sequence} >> ${submission_id}.gisaid.fa
  }

  output {
    File     gisaid_assembly = "${submission_id}.gisaid.fa"
  }

  runtime {
      docker:       docker_image
      memory:       "~{mem_size_gb} GB"
      cpu:          CPUs
      disks:        "local-disk ~{disk_size} SSD"
      preemptible:  preemptible_tries
  }
}

task genbank {

  input {
    String    samplename
    String    submission_id
    String    collection_date
    File      sequence
    String    organism
    String    iso_org
    String    iso_host
    String    iso_country

    String    docker_image = "staphb/seqyclean:1.10.09"
    Int       mem_size_gb = 3
    Int       CPUs = 1
    Int       disk_size = 10
    Int       preemptible_tries = 0
  }

  command {
    year=$(echo ${collection_date} | cut -f 1 -d '-')

    # removing leading Ns, folding sequencing to 75 bp wide, and adding metadata for genbank submissions
    echo ">${submission_id} [organism=${organism}][isolate=${iso_org}/${iso_host}/${iso_country}/${submission_id}/$(date +%Y)][host=${iso_host}][country=${iso_country}][collection_date=${collection_date}]" > ${submission_id}.genbank.fa
    grep -v ">" ${sequence} | sed 's/^N*N//g' | fold -w 75 >> ${submission_id}.genbank.fa
  }

  output {
    File     genbank_assembly = "${submission_id}.genbank.fa"
  }

  runtime {
      docker:       docker_image
      memory:       "~{mem_size_gb} GB"
      cpu:          CPUs
      disks:        "local-disk ~{disk_size} SSD"
      preemptible:  preemptible_tries
  }
}

task sra {

  input {
    String    submission_id
    File      read

    String    docker_image = "staphb/seqyclean:1.10.09"
    Int       mem_size_gb = 1
    Int       CPUs = 1
    Int       disk_size = 25
    Int       preemptible_tries = 0
  }

  command {
    cp ${read} ${submission_id}.fastq.gz
  }

  output {
    File     read_submission = "${submission_id}.fastq.gz"
  }

  runtime {
      docker:       docker_image
      memory:       "~{mem_size_gb} GB"
      cpu:          CPUs
      disks:        "local-disk ~{disk_size} SSD"
      preemptible:  preemptible_tries
  }
}
