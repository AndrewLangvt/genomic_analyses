task kraken2 {
  input {
  	File        read1
	  File 		    read2
	  String      samplename
	  String?     kraken2_db = "/kraken2-db"
    Int?        cpus=4
  }

  command{
    # date and version control
    date | tee DATE
    kraken2 --version | head -n1 | tee VERSION

    kraken2 --paired \
      --classified-out cseqs#.fq \
      --threads ${cpus} \
      --db ${kraken2_db} \
      ${read1} ${read2} \
      --report ${samplename}_kraken2_report.txt

    percentage_human=$(grep "Homo sapiens" ${samplename}_kraken2_report.txt | cut -f 1)
     # | tee PERCENT_HUMAN
    percentage_sc2=$(grep "Severe acute respiratory syndrome coronavirus 2" ${samplename}_kraken2_report.txt | cut -f1 )
     # | tee PERCENT_COV
    if [ -z "$percentage_human" ] ; then percentage_human="0" ; fi
    if [ -z "$percentage_sc2" ] ; then percentage_sc2="0" ; fi
    echo $percentage_human | tee PERCENT_HUMAN
    echo $percentage_sc2 | tee PERCENT_SC2
  }

  output {
    String     date = read_string("DATE")
    String     version = read_string("VERSION") 
    File 	     kraken_out = "${samplename}_kraken2_report.txt"
    String 	   percent_human = read_string("PERCENT_HUMAN")
    String 	   percent_sc2 = read_string("PERCENT_SC2")
  }

  runtime {
    docker:       "staphb/kraken2:2.0.8-beta_hv"
    memory:       "8 GB"
    cpu:          4
    disks:        "local-disk 100 SSD"
    preemptible:  0      
  }
}

task pangolin {
  input {
    File        fasta
    String      samplename
    Int?        cpus=40
  }

  command{
    # date and version control
    date | tee DATE
    pangolin --version | head -n1 | tee VERSION

    pangolin --threads ${cpus} --outdir ${samplename} ${fasta}
    pangolin_lineage=$(tail -n 1 ${samplename}/lineage_report.csv | cut -f 2 -d "," | grep -v "lineage")

    while [ -z "$pangolin_lineage" ]
    do
      pangolin --threads ${cpus} --outdir ${samplename} ${fasta}
      pangolin_lineage=$(tail -n 1 ${samplename}/lineage_report.csv | cut -f 2 -d "," | grep -v "lineage")
    done

    pangolin_aLRT=$(tail -n 1 ${samplename}/lineage_report.csv | cut -f 3 -d "," )
    pangolin_stats=$(tail -n 1 ${samplename}/lineage_report.csv | cut -f 4 -d "," )
    mv ${samplename}/lineage_report.csv ${samplename}_lineage.csv
    
    echo $pangolin_lineage | tee PANGOLIN_LINEAGE
    echo $pangolin_aLRT | tee PANGOLIN_aLRT
    echo $pangolin_stats | tee PANGOLIN_STATS
  }

  output {
    String     date = read_string("DATE")
    String     version = read_string("VERSION") 
    String     pangolin_lineage = read_string("PANGOLIN_LINEAGE")
    String     pangolin_aLRT = read_string("PANGOLIN_aLRT")
    String     pangolin_stats = read_string("PANGOLIN_STATS")
    File       lineage_report = "${samplename}_lineage.csv"
  }

  runtime {
    docker:       "staphb/pangolin:1.1.14"
    memory:       "8 GB"
    cpu:          40
    disks:        "local-disk 100 SSD"
    preemptible:  0      
  }
}

task pangolin2 {
  input {
    File        fasta
    String      samplename
    Int?        cpus=40
  }

  command{
    # date and version control
    date | tee DATE
    pangolin --version | head -n1 | tee VERSION

    pangolin --threads ${cpus} --outdir ${samplename} ${fasta}
    pangolin_lineage=$(tail -n 1 ${samplename}/lineage_report.csv | cut -f 2 -d "," | grep -v "lineage")

    while [ -z "$pangolin_lineage" ]
    do
      pangolin --threads ${cpus} --outdir ${samplename} ${fasta}
      pangolin_lineage=$(tail -n 1 ${samplename}/lineage_report.csv | cut -f 2 -d "," | grep -v "lineage")
    done

    PANGOLIN_PROBABILITY=$(tail -n 1 ${samplename}/lineage_report.csv | cut -f 3 -d "," )
    mv ${samplename}/lineage_report.csv ${samplename}_lineage.csv
    
    echo $pangolin_lineage | tee PANGOLIN_LINEAGE
    echo $pangolin_probability | tee PANGOLIN_PROBABILITY
  }

  output {
    String     date = read_string("DATE")
    String     version = read_string("VERSION") 
    String     pangolin_lineage = read_string("PANGOLIN_LINEAGE")
    String     pangolin_aLRT = read_string("PANGOLIN_PROBABILITY")
    File       lineage_report = "${samplename}_lineage.csv"
  }

  runtime {
    docker:       "staphb/pangolin:2.0.5"
    memory:       "8 GB"
    cpu:          40
    disks:        "local-disk 100 SSD"
    preemptible:  0      
  }
}




