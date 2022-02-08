version 1.0

workflow amplicon_coverage {
  meta {
    description: "Takes an array of BAM & BAI files and generates amplicon coverage metrics."
  }
  input {
    Array[File]    bamfiles
    Array[File]    baifiles
    File           primer_bed
    String         docker = "staphb/ivar:1.2.2_artic20200528"
  }
  call bedtools_multicov {
    input:
      bamfiles   = bamfiles,
      baifiles   = baifiles,
      primer_bed = primer_bed,
      docker     = docker 
  }  
  output {
    File     amp_coverage = bedtools_multicov.amp_coverage
  }
}

task bedtools_multicov {
  
  input {
    Array[File]  bamfiles
    Array[File]  baifiles
    File         primer_bed 
    String       docker = "staphb/ivar:1.2.2_artic20200528"
  }
  
  command <<<
    # date and version control
    date | tee DATE
    bedtools --version | tee VERSION
    cp ~{sep=" " bamfiles} ./
    cp ~{sep=" " baifiles} ./

    echo "primer" $(ls *bam | cut -f 1 -d '.') | tr ' ' '\t' > amplicon_coverage_$(date +"%Y-%m-%d").txt
    bedtools multicov -bams $(ls *bam) -bed ~{primer_bed} | cut -f 4,7- >> amplicon_coverage_$(date +"%Y-%m-%d").txt
  >>>

  output {
    String     date = read_string("DATE")
    String     version = read_string("VERSION") 
    File       amp_coverage = select_first(glob("amplicon_coverage*txt"))
  }

  runtime {
    docker:       "~{docker}"
    memory:       "5 GB"
    cpu:          "1"
    disks:        "local-disk 100 SSD"
    preemptible:  0      
  }
}
