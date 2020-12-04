workflow genomic_cluster_analysis {

  input {
    Array[File]   genomes
    File          cluster_samples
  }

  call mafft {
    input:
      genomes = genomes
  }
  call snp_dists {
    input:
      cluster_samples = cluster_samples,
      alignment = mafft.msa
  }
  call iqtree {
    input:
      cluster_samples = cluster_samples,
      alignment = mafft.msa      
  }
  # call render {
  #   input:
  #     cluster_samples = cluster_samples,
  #     snp_matrix = snp_dists.snp_matrix,
  #     ml_tree = iqtree.ml_tree
  # }
  
  # output {
  #   File      analysis_doc = render.analysis_doc
  # }
}


task mafft {
  
  input {
    Array[File]  genomes
  }
  
  command{
    # date and version control
    date | tee DATE
    mafft_vers=$(mafft --version)
    echo Mafft $(mafft_vers) | tee VERSION

    cat ${sep=" " genomes} | sed 's/Consensus_//;s/.consensus_threshold.*//' > assemblies.fasta
    mafft --thread -16 assemblies.fasta > $(date +%m%d%y)_msa.fasta
  }

  output {
    String     date = read_string("DATE")
    String     version = read_string("VERSION") 
    File       msa = select_first(glob("*_msa.fasta"))
  }

  runtime {
    docker:       "staphb/mafft:7.450"
    memory:       "32 GB"
    cpu:          16
    disks:        "local-disk 100 SSD"
    preemptible:  0      
  }
}

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
    if [ $numGenomes -gt 4 ]
    then
      iqtree -nt AUTO -s ${alignment} -m ${iqtree_model} -bb ${iqtree_bootstraps}
      cp $(date +%m%d%y)_msa.fasta.contree ${clustername}_$(date +%m%d%y)_msa.tree
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

task render {
  
  input {
    File      cluster_samples
    File      snp_matrix
    File      ml_tree
    String    clustername = basename(basename(basename(cluster_samples)), "_cluster.tsv")
    File?     template = "/cluster_report_template.Rmd"
  }
  
  command{
    # date and version control
    date | tee DATE
    Rscript --version | tee RSCRIPT_VERSION
    R --version | head -n1 | sed 's/).*/)/' | tee R_VERSION


    cp ${template} report_template.Rmd
    Rscript --verbose /report_render.R ${snp_matrix} ${ml_tree} ${cluster_samples} report_template.Rmd .
    cp report.pdf ${clustername}_$(date +%m%d%y)_cluster_analysis.pdf
    cp SNP_heatmap.png ${clustername}_$(date +%m%d%y)_SNP_heatmap.png
    cp pairwise_snp_list.csv ${clustername}_$(date +%m%d%y)_pairwise_snp_list.csv
  }

  output {
    String     date = read_string("DATE")
    String     rscript_version = read_string("RSCRIPT_VERSION") 
    String     r_version = read_string("R_VERSION") 
    File       analysis_doc = select_first(glob("*_cluster_analysis.pdf"))
    File       snp_heatmap = select_first(glob("*_SNP_heatmap.png"))
    File       snp_list = select_first(glob("*_pairwise_snp_list.csv"))
  }

  runtime {
    docker:       "andrewlangvt/cluster_report_ma:1"
    memory:       "2 GB"
    cpu:          2
    disks:        "local-disk 100 SSD"
    preemptible:  0      
  }
}

