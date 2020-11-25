task bwa {

  input {
    File        read1
    File        read2
    String      samplename
    File?       reference_genome="/artic-ncov2019/primer_schemes/nCoV-2019/V3/nCoV-2019.reference.fasta"
    String?     cpus=6
  }

  command {
    # date and version control
    date | tee DATE
    echo "BWA $(bwa 2>&1 | grep Version )" | tee BWA_VERSION
    samtools --version | head -n1 | tee SAMTOOLS_VERSION

    # Map with BWA MEM
    bwa mem \
    -t ${cpus} \
    ${reference_genome} \
    ${read1} ${read2} |\
      samtools sort | samtools view -F 4 -o ${samplename}.sorted.bam 

    # index BAMs
    samtools index ${samplename}.sorted.bam
  }

  output {
    String     bwa_version = read_string("BWA_VERSION")
    String     sam_version = read_string("SAMTOOLS_VERSION")
    File       sorted_bam = "${samplename}.sorted.bam"
    File       sorted_bai = "${samplename}.sorted.bam.bai"
  }

  runtime {
    docker:       "staphb/ivar:1.2.2_artic20200528"
    memory:       "8 GB"
    cpu:          2
    disks:        "local-disk 100 SSD"
    preemptible:  0      
  }
}
