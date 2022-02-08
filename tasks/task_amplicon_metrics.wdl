version 1.0 

task bedtools_cov {
  
  input {
    String     samplename
    File       bamfile
    File       baifile
    File       primer_bed
    Int        fail_threshold = 20
    String     docker = "staphb/ivar:1.2.2_artic20200528"
    Int        mem = 8
    Int        cpus = 2

  }
  
  command <<<
    # date and version control
    date | tee DATE
    bedtools --version | tee VERSION
    cp ~{bamfile} ./
    cp ~{baifile} ./

    bedtools coverage -a ~{primer_bed} -b $(ls *bam) > ~{samplename}_amplicon_coverage.txt
    bedtools coverage -a ~{primer_bed} -b $(ls *bam) | cut -f 6 | awk '{if ( $1 < ~{fail_threshold} ) print $0 }' | wc -l | tee AMP_FAIL
  >>>

  output {
    String     date = read_string("DATE")
    String     version = read_string("VERSION") 
    Int        amp_fail = read_string("AMP_FAIL")
    File       amp_coverage = "~{samplename}_amplicon_coverage.txt"
  }

  runtime {
    docker:       "~{docker}"
    memory:       "~{mem} GB"
    cpu:          "~{cpus}"
    disks:        "local-disk 100 SSD"
    preemptible:  0      
  }
}

task bedtools_multicov {
  
  input {
    Array[File]  bamfiles
    Array[File]  baifiles
    File         primer_bed 
    String       docker = "staphb/ivar:1.2.2_artic20200528"
    Int          mem = 2
    Int          cpus = 1

  }
  
  command <<<
    # date and version control
    date | tee DATE
    bedtools --version | tee VERSION
    cp ~{sep=" " bamfiles} ./
    cp ~{sep=" " baifiles} ./

    echo "primer" $(ls *bam) | tr ' ' '\t' > multicov.txt
    bedtools multicov -bams $(ls *bam) -bed ~{primer_bed} | cut -f 4,6- >> multicov.txt
  >>>

  output {
    String     date = read_string("DATE")
    String     version = read_string("VERSION") 
    File       amp_coverage = "multicov.txt"
  }

  runtime {
    docker:       "~{docker}"
    memory:       "~{mem} GB"
    cpu:          "~{cpus}"
    disks:        "local-disk 100 SSD"
    preemptible:  0      
  }
}
