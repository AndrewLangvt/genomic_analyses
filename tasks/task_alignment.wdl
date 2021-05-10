version 1.0 

task bwa {

  input {
    File        read1
    File        read2
    String      samplename
    File        reference_genome
    Int         cpus = 6
    String      docker = "staphb/ivar:1.2.2_artic20200528"
  }

  command {
    # date and version control
    date | tee DATE
    echo "BWA $(bwa 2>&1 | grep Version )" | tee BWA_VERSION
    samtools --version | head -n1 | tee SAMTOOLS_VERSION

    cp ${reference_genome} assembly.fasta
    grep -v '^>' assembly.fasta | tr -d '\n' | wc -c | tee assembly_length

    if [ "$(cat assembly_length)" != "0" ]; then

      # Index referenge FASTA if provided reference is not empty 
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
    String     bwa_version = read_string("BWA_VERSION")
    String     sam_version = read_string("SAMTOOLS_VERSION")
    File       sorted_bam = "~{samplename}.sorted.bam"
    File       sorted_bai = "~{samplename}.sorted.bam.bai"
  }

  runtime {
    docker:       "~{docker}"
    memory:       "8 GB"
    cpu:          "~{cpus}"
    disks:        "local-disk 100 SSD"
    preemptible:  0      
  }
}

task mafft {
  
  input {
    Array[File]   genomes
    Int           cpus = 16
    String        docker = "staphb/mafft:7.450"
  }
  
  command {
    # date and version control
    date | tee DATE
    mafft_vers=$(mafft --version)
    echo Mafft $(mafft_vers) | tee VERSION

    cat ~{sep=" " genomes} > assemblies.fasta
    mafft --thread -~{cpus} assemblies.fasta > msa.fasta
  }

  output {
    String        date = read_string("DATE")
    String        version = read_string("VERSION")
    File          msa = "msa.fasta"
  }

  runtime {
    docker:       "~{docker}"
    memory:       "32 GB"
    cpu:          "~{cpus}"
    disks:        "local-disk 100 SSD"
    preemptible:  0      
  }
}

