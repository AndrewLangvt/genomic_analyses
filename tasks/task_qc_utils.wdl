task fastqc {
  input {
    File        read1
    File        read2
    String      read1_name = basename(basename(basename(read1, ".gz"), ".fastq"), ".fq")
    String      read2_name = basename(basename(basename(read2, ".gz"), ".fastq"), ".fq")
    String?     cpus = 2
  }
  
  command {
    # capture date and version
    date | tee DATE
    fastqc --version | grep FastQC | tee VERSION

    fastqc --outdir $PWD --threads ${cpus} ${read1} ${read2}

    unzip -p ${read1_name}_fastqc.zip */fastqc_data.txt | grep "Total Sequences" | cut -f 2 | tee READ1_SEQS
    unzip -p ${read2_name}_fastqc.zip */fastqc_data.txt | grep "Total Sequences" | cut -f 2 | tee READ2_SEQS
  }

  output {
    File       fastqc1_html = "${read1_name}_fastqc.html"
    File       fastqc1_zip = "${read1_name}_fastqc.zip"
    File       fastqc2_html = "${read2_name}_fastqc.html"
    File       fastqc2_zip = "${read2_name}_fastqc.zip"
    String     read1_seq = read_string("READ1_SEQS")
    String     read2_seq = read_string("READ2_SEQS")
    String     version = read_string("VERSION") 
    String     pipeline_date = read_string("DATE")
  }

  runtime {
    docker:       "staphb/fastqc:0.11.8"
    memory:       "4 GB"
    cpu:          2
    disks:        "local-disk 100 SSD"
    preemptible:  0      
  }
}