task deID_assmebly {

  input {
    String    samplename
    String    submission_id
    String    collection_date
    File      sequence 
    File      read1
    File      read2
    String?   assembly_vs_consensus = "consensus"
    String?   organism = "Severe acute respiratory syndrome coronavirus 2"
    String?   iso_org = "SARS-CoV-2"
    String?   iso_host = "Human"
    String?   iso_country = "USA"
    Int?      max_Ns = 4000
    Int?      min_length = 28000
    Int?      min_ACTG = 28000
  }

  command {
    # de-identified consensus/assembly sequence
    echo ">${submission_id}" > ${submission_id}.${assembly_vs_consensus}.fa
    grep -v ">" ${sequence} >> ${submission_id}.${assembly_vs_consensus}.fa

    num_N=$( grep -v ">" ${samplename}.consensus.fa | grep -o 'N' | wc -l )
    if [ -z "$num_N" ] ; then num_N="0" ; fi

    num_ACTG=$(grep -v ">" ${samplename}.consensus.fa | grep -o -E "C|A|T|G" | wc -l)
    if [ -z "$num_ACTG" ] ; then num_ACTG="0" ; fi

    num_total=$( grep -v ">" ${samplename}.consensus.fa | grep -o -E '[A-Z]' | wc -l )
    if [ -z "$num_total" ] ; then num_total="0" ; fi

    if [ $num_N -lt ${max_Ns} ] && [ $num_total -gt ${min_length} ]
    then
      # removing leading Ns, folding sequencing to 75 bp wide, and adding metadata for genbank submissions
      echo ">${submission_id} [organism=${organism}][isolate=${iso_org}/${iso_host}/${iso_country}/${submission_id}/$(date +&Y)][host=${iso_host}][country=${iso_country}][collection_date=${collection_date}]" > ${submission_id}.genbank.fa
      grep -v ">" ${sequence} | sed 's/^N*N//g' | fold -w 75 >> ${submission_id}.genbank.fa
      if [ $num_ACTG -gt ${min_ACTG} ]
      then
        cp ${submission_id}.${assembly_vs_consensus}.fa ${submission_id}.gisaid.fa
        echo "${samplename} had $num_n Ns and is part of the genbank and gisaid submission fasta"
      else
        echo "${samplename} had $num_n Ns and is part of the genbank submission fasta, but not gisaid"
      fi
    else
      echo "${samplename} had $num_n Ns and is not part of the genbank or the gisaid submission fasta"
    fi

    # copying fastq files and changing the file name
    cp ${read1} ${submission_id}.R1.fastq.gz 
    cp ${read2} ${submission_id}.R2.fastq.gz 

  }

  output {
    File      read1_submission = "${submission_id}.R1.fastq.gz"
    File      read2_submission = "${submission_id}.R1.fastq.gz"
    File      deID_assembly = "${submission_id}.${assembly_vs_consensus}.fa"
    File?     genbank_assembly = "${submission_id}.genbank.fa"
    File?     gisaid_assembly = "${submission_id}.gisaid.fa"
  }

  runtime {
      docker:       "staphb/seqyclean:1.10.09"
      memory:       "1 GB"
      cpu:          1
      disks:        "local-disk 100 SSD"
      preemptible:  0
  }
}