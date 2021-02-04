version 1.0

task deidentify {

  input {
    String    samplename
    String    submission_id
    File      sequence

    String    docker_image = "staphb/seqyclean:1.10.09"
    Int       mem_size_gb = 3
    Int       CPUs = 1
    Int       disk_size = 100
    Int       preemptible_tries = 0
  }

  command {
    # de-identified consensus/assembly sequence
    echo ">${submission_id}" > ${submission_id}.fasta
    grep -v ">" ${sequence} >> ${submission_id}.fasta

    num_N=$( grep -v ">" ${sequence} | grep -o 'N' | wc -l )
    if [ -z "$num_N" ] ; then num_N="0" ; fi
    echo $num_N | tee NUM_N

    num_ACTG=$( grep -v ">" ${sequence} | grep -o -E "C|A|T|G" | wc -l )
    if [ -z "$num_ACTG" ] ; then num_ACTG="0" ; fi
    echo $num_ACTG | tee NUM_ACTG

    num_total=$( grep -v ">" ${sequence} | grep -o -E '[A-Z]' | wc -l )
    if [ -z "$num_total" ] ; then num_total="0" ; fi
    echo $num_total | tee NUM_TOTAL
  }

  output {
    File      deID_assembly = "${submission_id}.fasta"
    Int       number_N = read_string("NUM_N")
    Int       number_ATCG = read_string("NUM_ACTG")
    Int       number_Total = read_string("NUM_TOTAL")
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
    String?   specimen_type

    String    gisaid_submitter
    String    iso_state
    String    iso_continent
    String    seq_platform
    String    artic_pipeline_version
    String    originating_lab
    String    origLab_address
    String    submitting_lab
    String    subLab_address
    String    Authors

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


    echo submitter,fn,covv_virus_name,covv_type,covv_passage,covv_collection_date,covv_location,covv_add_location,covv_host,covv_add_host_info,covv_gender,covv_patient_age,covv_patient_status,covv_specimen,covv_outbreak,covv_last_vaccinated,covv_treatment,covv_seq_technology,covv_assembly_method,covv_coverage,covv_orig_lab,covv_orig_lab_addr,covv_provider_sample_id,covv_subm_lab,covv_subm_lab_addr,covv_subm_sample_id,covv_authors,covv_comment,comment_type >  ${samplename}.gisaidMeta.csv
    echo Submitter,FASTA filename,Virus name,Type,Passage details/history,Collection date,Location,Additional location information,Host,Additional host information,Gender,Patient age,Patient status,Specimen source,Outbreak,Last vaccinated,Treatment,Sequencing technology,Assembly method,Coverage,Originating lab,Address,Sample ID given by the sample provider,Submitting lab,Address,Sample ID given by the submitting laboratory,Authors Comment,Comment Icon >> ${samplename}.gisaidMeta.csv

    echo "'${gisaid_submitter}','gisaid_upload.fasta',hCoV-19/'${iso_country}'/'${submission_id}/$year',betacoronavirus,Original,'${collection_date}','${iso_continent} \ ${iso_country} \ ${iso_state}',,'${iso_host}',,unknown,unknown,unknown,'${specimen_type}',,,,'${seq_platform}','${artic_pipeline_version}',,'${originating_lab}','${origLab_address}',,'${submitting_lab}','${subLab_address}',,'${Authors}'" >> ${samplename}.gisaidMeta.csv

  }

  output {
    File     gisaid_assembly = "${submission_id}.gisaid.fa"
    File     gisaid_metadata = "${samplename}.gisaidMeta.csv"
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
    String    specimen_type
    String    BioProject

    String    docker_image = "staphb/seqyclean:1.10.09"
    Int       mem_size_gb = 3
    Int       CPUs = 1
    Int       disk_size = 10
    Int       preemptible_tries = 0
  }

  command {
    year=$(echo ${collection_date} | cut -f 1 -d '-')

    # removing leading Ns, folding sequencing to 75 bp wide, and adding metadata for genbank submissions
    echo ">${submission_id} [organism=${organism}][isolate=${iso_org}/${iso_host}/${iso_country}/${submission_id}/$year)][host=${iso_host}][country=${iso_country}][collection_date=${collection_date}]" > ${submission_id}.genbank.fa
    grep -v ">" ${sequence} | sed 's/^N*N//g' | fold -w 75 >> ${submission_id}.genbank.fa

    echo Sequence_ID,Organism,collection-date,country,host,isolate,isolation-source,BioProject,notes > ${samplename}.genbankMeta.csv

    echo ${submission_id},Severe acute respiratory syndrome coronavirus 2,${collection_date},${iso_country},${iso_host},${iso_org}/${iso_host}/${iso_country}/${submission_id}/$year,${specimen_type},${BioProject}, >> ${samplename}.genbankMeta.csv

  }

  output {
    File     genbank_assembly = "${submission_id}.genbank.fa"
    File     genbank_metadata = "${samplename}.genbankMeta.csv"
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
    File      reads

    String    docker_image = "staphb/seqyclean:1.10.09"
    Int       mem_size_gb = 1
    Int       CPUs = 1
    Int       disk_size = 25
    Int       preemptible_tries = 0
  }

  command {
    cp ${reads} ${submission_id}.fastq.gz
  }

  output {
    File?    reads_submission = "${submission_id}.fastq.gz"
  }

  runtime {
      docker:       docker_image
      memory:       "~{mem_size_gb} GB"
      cpu:          CPUs
      disks:        "local-disk ~{disk_size} SSD"
      preemptible:  preemptible_tries
  }
}


task compile {

  input {
    Array[File?] single_submission_fasta
    Array[File?] single_submission_meta
    String       repository
    String    docker_image = "staphb/seqyclean:1.10.09"
    Int       mem_size_gb = 1
    Int       CPUs = 1
    Int       disk_size = 25
    Int       preemptible_tries = 0
  }

  command {
  head -n -1 ~{single_submission_meta[1]} > ${repository}_upload_meta.csv
  for i in ~{sep=" " single_submission_meta}; do
      tail -n1 $i >> ${repository}_upload_meta.csv
  done

  cat ~{sep=" " single_submission_fasta} > ${repository}_upload.fasta
  }

  output {
    File    upload_meta   = "${repository}_upload_meta.csv"
    File    upload_fasta  = "${repository}_upload.fasta"

  }

  runtime {
      docker:       docker_image
      memory:       "~{mem_size_gb} GB"
      cpu:          CPUs
      disks:        "local-disk ~{disk_size} SSD"
      preemptible:  preemptible_tries
  }
}
