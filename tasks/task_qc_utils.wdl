version 1.0 

task fastqc {
  
  input {
    File        read1
    File        read2
    String      docker = "staphb/fastqc:0.11.8"
    Int         mem = 4
    Int         cpus = 2
  }
  String      read1_name = basename(basename(basename(read1, ".gz"), ".fastq"), ".fq")
  String      read2_name = basename(basename(basename(read2, ".gz"), ".fastq"), ".fq")  

  command <<<
    # capture date and version
    date | tee DATE
    fastqc --version | grep FastQC | tee VERSION

    fastqc --outdir $PWD --threads ~{cpus} ~{read1} ~{read2}

    unzip -p ~{read1_name}_fastqc.zip */fastqc_data.txt | grep "Total Sequences" | cut -f 2 | tee READ1_SEQS
    unzip -p ~{read2_name}_fastqc.zip */fastqc_data.txt | grep "Total Sequences" | cut -f 2 | tee READ2_SEQS

    READ1_SEQS=$(unzip -p ~{read1_name}_fastqc.zip */fastqc_data.txt | grep "Total Sequences" | cut -f 2 )
    READ2_SEQS=$(unzip -p ~{read2_name}_fastqc.zip */fastqc_data.txt | grep "Total Sequences" | cut -f 2 )

    if [ $READ1_SEQS == $READ2_SEQS ]; then
      read_pairs=$READ1_SEQS
    else
      read_pairs="ERROR:Unequal number of L and R reads- $READ1_SEQS and $READ2_SEQS"
    fi
    echo $read_pairs | tee READ_PAIRS
  >>>

  output {
    String  version       = read_string("VERSION") 
    String  date          = read_string("DATE")
    String  container     = docker
    File    fastqc1_html  = "~{read1_name}_fastqc.html"
    File    fastqc1_zip   = "~{read1_name}_fastqc.zip"
    File    fastqc2_html  = "~{read2_name}_fastqc.html"
    File    fastqc2_zip   = "~{read2_name}_fastqc.zip"
    Int     read1_seq     = read_string("READ1_SEQS")
    Int     read2_seq     = read_string("READ2_SEQS")
    String  read_pairs    = read_string("READ_PAIRS")

  }

  runtime {
    docker:       "~{docker}"
    memory:       "~{mem} GB"
    cpu:          "~{cpus}"
    disks:        "local-disk 100 SSD"
    preemptible:  0      
  }
}
