version 1.0

task ncbi_scrub_pe {
  input {
    File        read1
    File        read2
    String      samplename
    String      docker = "ncbi/sra-human-scrubber:1.0.2021-05-05"
  }
  command <<<
    # date and version control
    date | tee DATE

    # unzip fwd file as scrub tool does not take in .gz fastq files
    if [[ "~{read1}" == *.gz ]]
    then
      gunzip -c ~{read1} > r1.fastq
      read1_unzip=r1.fastq
    else
      read1_unzip=~{read1}
    fi

    # dehost reads
    /opt/scrubber/scripts/scrub.sh -n ${read1_unzip} |& tail -n1 | awk -F" " '{print $1}' > FWD_SPOTS_REMOVED

    # gzip dehosted reads
    gzip ${read1_unzip}.clean -c > ~{samplename}_R1_dehosted.fastq.gz

    # do the same on read
    # unzip file if necessary
    if [[ "~{read2}" == *.gz ]]
    then
      gunzip -c ~{read2} > r2.fastq
      read2_unzip=r2.fastq
    else
      read2_unzip=~{read2}
    fi

    # dehost reads
    /opt/scrubber/scripts/scrub.sh -n ${read2_unzip} |& tail -n1 | awk -F" " '{print $1}' > REV_SPOTS_REMOVED

    # gzip dehosted reads
    gzip ${read2_unzip}.clean -c > ~{samplename}_R2_dehosted.fastq.gz 
  >>>

  output {
    String  date              = read_string("DATE")
    String  container         = docker
    File    read1_dehosted    = "~{samplename}_R1_dehosted.fastq.gz"
    File    read2_dehosted    = "~{samplename}_R2_dehosted.fastq.gz"
    Int     read1_human_spots_removed = read_int("FWD_SPOTS_REMOVED")
    Int     read2_human_spots_removed = read_int("REV_SPOTS_REMOVED")
  }

  runtime {
      docker:       "~{docker}"
      memory:       "8 GB"
      cpu:          4
      disks:        "local-disk 100 SSD"
      preemptible:  0
  }
}

task seqyclean {
  input {
    File        read1
    File        read2
    String      samplename
    File?       adapters
    Int         seqyclean_minlen = 25
    String      seqyclean_qual = "20 20"
    Boolean     compress = true
    Boolean     seqyclean_dup = false
    Boolean     seqyclean_no_adapter_trim = false
    String      docker = "staphb/seqyclean:1.10.09"
    Int         mem = 8
    Int         cpus = 8
  }
  command <<<
    # date and version control
    date | tee DATE
    echo "Seqyclean $(seqyclean -h | grep Version)" | tee VERSION

    # allows user to input alternate adapterfile if desired 
    if ! [ -z ~{adapters} ]; then
      adapters_fn=$(basename ~{adapters})
      cp ~{adapters} $adapters_fn
      adapter_file=$(echo $adapters_fn)
      echo $adapters_fn > ADAPTERS
    else
      adapter_file=$(echo /Adapters_plus_PhiX_174.fasta)
      echo Adapters_plus_PhiX_174.fasta > ADAPTERS
    fi

    seqyclean \
    -minlen ~{seqyclean_minlen} \
    -qual ~{seqyclean_qual} \
    -c $adapter_file \
    ~{true="-dup" false="" seqyclean_dup} \
    ~{true="-no_adapter_trim" false="" seqyclean_no_adapter_trim} \
    ~{true="-gz" false="" compress} \
    -t ~{cpus} \
    -1 ~{read1} \
    -2 ~{read2} \
    -o ~{samplename}

    # Capture metrics for summary file
    cut -f 58 ~{samplename}_SummaryStatistics.tsv | grep -v "PairsKept" | head -n 1 | tee PAIRS_KEPT
    cut -f 59 ~{samplename}_SummaryStatistics.tsv | grep -v "Perc_Kept" | head -n 1 | tee PERCENT_KEPT
  >>>

  output {
    String     date          = read_string("DATE")
    String     version       = read_string("VERSION")
    String     container     = docker 
    File       read1_clean   = "${samplename}_PE1.fastq.gz"
    File       read2_clean   = "${samplename}_PE2.fastq.gz"
    String     adapterfile   = read_string("ADAPTERS")
    Int        seqy_pairs    = read_string("PAIRS_KEPT")
    Float      seqy_percent  = read_string("PERCENT_KEPT")
  }

  runtime {
      docker:       "~{docker}"
      memory:       "~{mem} GB"
      cpu:          "~{cpus}"
      disks:        "local-disk 100 SSD"
      preemptible:  0
  }
}
