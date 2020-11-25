task primer_trim {
  input {
    File        bamfile
    String      samplename
    String?     primer_bed = "/artic-ncov2019/primer_schemes/nCoV-2019/V3/nCoV-2019.bed"
    Boolean?    keep_primer_reads=true
  }

  command {
    # date and version control
    date | tee DATE
    ivar version | head -n1 | tee IVAR_VERSION
    samtools --version | head -n1 | tee SAMTOOLS_VERSION

    # trimming primers
    ivar trim \
    ${true="-e" false="" keep_primer_reads} \
    -i ${bamfile} \
    -b ${primer_bed} \
    -p ${samplename}.primertrim

    # sorting and indexing the trimmed bams
    samtools sort \
    ${bamfile} \
    -o ${samplename}.primertrim.sorted.bam 

    samtools index ${samplename}.primertrim.sorted.bam
  }

  output {
    File      trimmed_bam = "${samplename}.primertrim.bam"
    File 	    trim_sorted_bam = "${samplename}.primertrim.sorted.bam"
    File 	    trim_sorted_bai = "${samplename}.primertrim.sorted.bam.bai"
    String    ivar_version = read_string("IVAR_VERSION") 
    String 	  samtools_version = read_string("SAMTOOLS_VERSION")
    String    pipeline_date = read_string("DATE")
  }

  runtime {
    docker:       "staphb/ivar:1.2.2_artic20200528"
    memory:       "8 GB"
    cpu:          2
    disks:        "local-disk 100 SSD"
    preemptible:  0      
  }
}

task variant_call {
  input {
    File        bamfile
    String      samplename
    String? 	  ref_genome = "/artic-ncov2019/primer_schemes/nCoV-2019/V3/nCoV-2019.reference.fasta"
    String? 	  ref_gff = "/reference/GCF_009858895.2_ASM985889v3_genomic.gff"
    Boolean?    count_orphans = true
    String?     max_depth = "600000"
    Boolean?    disable_baq = true
    String?     min_bq = "0"
    String?     min_qual = "20"
    String?     min_freq = "0.6"
    String?     min_depth = "10"
  }

  command {
    # date and version control
    date | tee DATE
    ivar version | head -n1 | tee IVAR_VERSION
    samtools --version | head -n1 | tee SAMTOOLS_VERSION

    # call variants
    samtools mpileup \
    ${true = "--count-orphans" false = "" count_orphans} \
    -d ${max_depth} \
    ${true = "--no-BAQ" false = "" disable_baq} \
    -Q ${min_bq} \
    --reference ${ref_genome} \
    ${bamfile} | \
    ivar variants \
    -p ${samplename}.variants \
    -q ${min_qual} \
    -t ${min_freq} \
    -m ${min_depth} \
    -r ${ref_genome} \
    -g ${ref_gff}

    variants_num=$(grep "TRUE" ${samplename}.variants.tsv | wc -l)
    if [ -z "$variants_num" ] ; then variants_num="0" ; fi
    echo $variants_num | tee VARIANT_NUM
	}

  output {
 	  String 		variant_num = read_string("VARIANT_NUM")
 	  File  		sample_variants = "${samplename}.variants.tsv"
    String    ivar_version = read_string("IVAR_VERSION") 
    String    samtools_version = read_string("SAMTOOLS_VERSION")
    String    pipeline_date = read_string("DATE")	
  }

  runtime {
    docker:       "staphb/ivar:1.2.2_artic20200528"
    memory:       "8 GB"
    cpu:          2
    disks:        "local-disk 100 SSD"
    preemptible:  0      
  }
}

task consensus {
  input {
    File        bamfile
    String      samplename
    String?     ref_genome = "/artic-ncov2019/primer_schemes/nCoV-2019/V3/nCoV-2019.reference.fasta"
    String?     ref_gff = "/reference/GCF_009858895.2_ASM985889v3_genomic.gff"
    Boolean?    count_orphans = true
    String?     max_depth = "600000"
    Boolean?    disable_baq = true
    String?     min_bq = "0"
    String?     min_qual = "20"
    String?     min_freq = "0.6"
    String?     min_depth = "10"
    String?     char_unknown = "N"
  }
  
  command {
    # date and version control
    date | tee DATE
    ivar version | head -n1 | tee IVAR_VERSION
    samtools --version | head -n1 | tee SAMTOOLS_VERSION

    # call consensus
    samtools mpileup \
    ${true = "--count-orphans" false = "" count_orphans} \
    -d ${max_depth} \
    ${true = "--no-BAQ" false = "" disable_baq} \
    -Q ${min_bq} \
    --reference ${ref_genome} \
    ${bamfile} | \
    ivar consensus \
    -p ${samplename}.consensus \
    -q ${min_qual} \
    -t ${min_freq} \
    -m ${min_depth} \
    -n ${char_unknown}

    num_N=$(grep -o 'N' ${samplename}.consensus.fa | grep -v ">" | wc -l )
    if [ -z "$num_N" ] ; then num_N="0" ; fi
    echo $num_N | tee NUM_N

    num_ACTG=$(grep -o -E "C|A|T|G" ${samplename}.consensus.fa | grep -v ">" | wc -l )
    if [ -z "$num_ACTG" ] ; then num_ACTG="0" ; fi
    echo $num_ACTG | tee NUM_ACTG

    num_degenerate=$(grep -o -E "B|D|E|F|H|I|J|K|L|M|O|P|Q|R|S|U|V|W|X|Y|Z" ${samplename}.consensus.fa | grep -v ">" | wc -l )
    if [ -z "$num_degenerate" ] ; then num_degenerate="0" ; fi
    echo $num_degenerate | tee NUM_DEGENERATE

    num_total=$(( $num_N + $num_degenerate + $num_ACTG ))
    echo $num_total | tee NUM_TOTAL
  }

  output {
    File      consensus_seq = "${samplename}.consensus.fa"
    String    number_N = read_string("NUM_N")
    String    number_ATCG = read_string("NUM_ACTG")
    String    number_Degenerate = read_string("NUM_DEGENERATE")
    String    number_Total = read_string("NUM_TOTAL")
    String    ivar_version = read_string("IVAR_VERSION") 
    String    samtools_version = read_string("SAMTOOLS_VERSION")
    String    pipeline_date = read_string("DATE")
  }

  runtime {
    docker:       "staphb/ivar:1.2.2_artic20200528"
    memory:       "8 GB"
    cpu:          2
    disks:        "local-disk 100 SSD"
    preemptible:  0      
  }
}

