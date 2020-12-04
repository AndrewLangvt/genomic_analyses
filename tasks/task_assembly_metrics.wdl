task stats_n_coverage {

  input {
    File        bamfile
    String      samplename
  }

  command{
    date | tee DATE
    samtools --version | head -n1 | tee VERSION

    samtools stats ${bamfile} > ${samplename}.stats.txt

    samtools coverage ${bamfile} -m -o ${samplename}.cov.hist
    samtools coverage ${bamfile} -o ${samplename}.cov.txt
    samtools flagstat ${bamfile} > ${samplename}.flagstat.txt

    coverage=$(cut -f 6 ${samplename}.cov.txt | tail -n 1)
    depth=$(cut -f 7 ${samplename}.cov.txt | tail -n 1)
    meanbaseq=$(cut -f 8 ${samplename}.cov.txt | tail -n 1)
    meanmapq=$(cut -f 9 ${samplename}.cov.txt | tail -n 1)

    if [ -z "$coverage" ] ; then coverage="0" ; fi
    if [ -z "$depth" ] ; then depth="0" ; fi
    if [ -z "$meanbaseq" ] ; then meanbaseq="0" ; fi
    if [ -z "$meanmapq" ] ; then meanmapq="0" ; fi

    echo $coverage | tee COVERAGE
    echo $depth | tee DEPTH 
    echo $meanbaseq | tee MEANBASEQ 
    echo $meanmapq | tee MEANMAPQ 
  }

  output {
    String     date = read_string("DATE")
    String     version = read_string("VERSION") 
    File       stats = "${samplename}.stats.txt"
    File       cov_hist = "${samplename}.cov.hist"
    File       cov_stats = "${samplename}.cov.txt"
    File       flagstat = "${samplename}.flagstat.txt"
    String     coverage = read_string("COVERAGE")
    String     depth = read_string("DEPTH")
    String     meanbaseq = read_string("MEANBASEQ")
    String     meanmapq = read_string("MEANMAPQ")
  }

  runtime {
    docker:       "staphb/samtools:1.10"
    memory:       "8 GB"
    cpu:          2
    disks:        "local-disk 100 SSD"
    preemptible:  0      
  }
}

task ampli_multicov {
  
  input {
    Array[File]  bamfiles
    Array[File]  baifiles
    Array[File]  primtrim_bamfiles
    Array[File]  primtrim_baifiles
    String?      primer_bed = "/artic-ncov2019/primer_schemes/nCoV-2019/V3/nCoV-2019.bed"
  }
  
  command{
    # date and version control
    date | tee DATE
    bedtools --version | tee VERSION
    cp ${sep=" " bamfiles} ./
    cp ${sep=" " baifiles} ./
    cp ${sep=" " primtrim_bamfiles} ./
    cp ${sep=" " primtrim_baifiles} ./

    echo "primer" $(ls *bam) | tr ' ' '\t' > multicov.txt
    bedtools multicov -bams $(ls *bam) -bed ${primer_bed} | cut -f 4,7- >> multicov.txt
  }

  output {
    String     date = read_string("DATE")
    String     version = read_string("VERSION") 
    File       amp_coverage = "multicov.txt"
  }

  runtime {
    docker:       "staphb/ivar:1.2.2_artic20200528"
    memory:       "2 GB"
    cpu:          1
    disks:        "local-disk 100 SSD"
    preemptible:  0      
  }
}
