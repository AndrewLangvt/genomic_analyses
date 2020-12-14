version 1.0 

task snp_dists {
  
  input {
    File      alignment
    File      cluster_samples
    String    clustername = basename(basename(basename(cluster_samples)), "_cluster.tsv")
  }
  
  command{
    # date and version control
    date | tee DATE
    snp-dists -v | tee VERSION

    snp-dists ${alignment} > ${clustername}_$(date +%m%d%y)_snp_distance_matrix.tsv
  }

  output {
    String     date = read_string("DATE")
    String     version = read_string("VERSION") 
    File       snp_matrix = select_first(glob("*snp_distance_matrix.tsv"))
  }

  runtime {
    docker:       "staphb/snp-dists:0.6.2"
    memory:       "2 GB"
    cpu:          2
    disks:        "local-disk 100 SSD"
    preemptible:  0      
  }
}

task iqtree {
  
  input {
    File      alignment
    File      cluster_samples
    String    clustername = basename(basename(basename(cluster_samples)), "_cluster.tsv")
    String?   iqtree_model = "GTR+G4"
    String?   iqtree_bootstraps = 1000
  }
  
  command{
    # date and version control
    date | tee DATE
    iqtree --version | grep version | sed 's/.*version/version/;s/ for Linux.*//' | tee VERSION

    numGenomes=`grep -o '>' ${alignment} | wc -l`
    if [ $numGenomes -gt 3 ]
    then
      cp ${alignment} msa.fasta
      iqtree -nt AUTO -s msa.fasta -m ${iqtree_model} -bb ${iqtree_bootstraps}
      cp msa.fasta.contree ${clustername}_$(date +%m%d%y)_msa.tree
    fi
  }

  output {
    String     date = read_string("DATE")
    String     version = read_string("VERSION") 
    File       ml_tree = select_first(glob("*_msa.tree"))
  }

  runtime {
    docker:       "staphb/iqtree:1.6.7"
    memory:       "8 GB"
    cpu:          4
    disks:        "local-disk 100 SSD"
    preemptible:  0      
  }
}
