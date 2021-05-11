version 1.0 

task stats_n_coverage {

  input {
    String      samplename
    File        bamfile
    String      docker = "staphb/samtools:1.10"
    Int         mem = 8
    Int         cpus = 2
  }

  command <<<
    date | tee DATE
    samtools --version | head -n1 | tee VERSION

    samtools stats ~{bamfile} > ~{samplename}.stats.txt

    samtools coverage ~{bamfile} -m -o ~{samplename}.cov.hist
    samtools coverage ~{bamfile} -o ~{samplename}.cov.txt
    samtools flagstat ~{bamfile} > ~{samplename}.flagstat.txt

    coverage=$(cut -f 6 ~{samplename}.cov.txt | tail -n 1)
    depth=$(cut -f 7 ~{samplename}.cov.txt | tail -n 1)
    meanbaseq=$(cut -f 8 ~{samplename}.cov.txt | tail -n 1)
    meanmapq=$(cut -f 9 ~{samplename}.cov.txt | tail -n 1)

    if [ -z "$coverage" ] ; then coverage="0" ; fi
    if [ -z "$depth" ] ; then depth="0" ; fi
    if [ -z "$meanbaseq" ] ; then meanbaseq="0" ; fi
    if [ -z "$meanmapq" ] ; then meanmapq="0" ; fi

    echo $coverage | tee COVERAGE
    echo $depth | tee DEPTH 
    echo $meanbaseq | tee MEANBASEQ 
    echo $meanmapq | tee MEANMAPQ 
  >>>

  output {
    String     date = read_string("DATE")
    String     samtools_version = read_string("VERSION") 
    File       stats = "~{samplename}.stats.txt"
    File       cov_hist = "~{samplename}.cov.hist"
    File       cov_stats = "~{samplename}.cov.txt"
    File       flagstat = "~{samplename}.flagstat.txt"
    Float      coverage = read_float("COVERAGE")
    Float      depth = read_float("DEPTH")
    Float      meanbaseq = read_float("MEANBASEQ")
    Float      meanmapq = read_float("MEANMAPQ")
  }

  runtime {
    docker:       "~{docker}"
    memory:       "~{mem} GB"
    cpu:          "~{cpus}"
    disks:        "local-disk 100 SSD"
    preemptible:  0      
  }
}

