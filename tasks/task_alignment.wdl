version 1.0 

task bwa {

  input {
    File        read1
    File        read2
    String      samplename
    File        reference_genome
    String      docker = "staphb/ivar:1.2.2_artic20200528"
    Int         mem = 8
    Int         cpus = 6

  }

  command {
    # date and version control
    date | tee DATE
    echo "BWA $(bwa 2>&1 | grep Version )" | tee BWA_VERSION
    samtools --version | head -n1 | tee SAMTOOLS_VERSION

    cp ${reference_genome} assembly.fasta
    grep -v '^>' assembly.fasta | tr -d '\n' | wc -c | tee assembly_length

    if [ "$(cat assembly_length)" != "0" ]; then

      # Index reference FASTA if provided reference is not empty 
      bwa index assembly.fasta

      # Map with BWA MEM
      bwa mem \
      -t ~{cpus} \
      assembly.fasta \
      ~{read1} ~{read2} |\
        samtools sort | samtools view -F 4 -o ~{samplename}.sorted.bam 

      # index BAMs
      samtools index ~{samplename}.sorted.bam
    else 
      exit 1
    fi 
  }

  output {
    String     date             = read_string("DATE")
    String     bwa_version      = read_string("BWA_VERSION")
    String     samtools_version = read_string("SAMTOOLS_VERSION")
    String     container        = docker
    File       sorted_bam       = "~{samplename}.sorted.bam"
    File       sorted_bai       = "~{samplename}.sorted.bam.bai"
  }

  runtime {
    docker:       "~{docker}"
    memory:       "~{mem} GB"
    cpu:          "~{cpus}"
    disks:        "local-disk 100 SSD"
    preemptible:  0      
  }
}

task mafft {
  
  input {
    Array[File]   genomes
    String        docker = "staphb/mafft:7.450"
    Int           mem = 32
    Int           cpus = 16
  }
  
  command {
    # date and version control
    date | tee DATE
    mafft_vers=$(mafft --version)
    echo Mafft $(mafft_vers) | tee VERSION

    cat ${sep=" " genomes} | sed 's/Consensus_//;s/.consensus_threshold.*//' > assemblies.fasta
    mafft --thread -~{cpus} assemblies.fasta > msa.fasta
  }

  output {
    String        date      = read_string("DATE")
    String        version   = read_string("VERSION")
    String        container = docker
    File          msa       = "msa.fasta"
  }

  runtime {
    docker:       "~{docker}"
    memory:       "~{mem} GB"
    cpu:          "~{cpus}"
    disks:        "local-disk 100 SSD"
    preemptible:  0      
  }
}



