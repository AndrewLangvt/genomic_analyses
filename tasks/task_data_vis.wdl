version 1.0 

task cluster_render {
  
  input {
    File      cluster_samples
    File      snp_matrix
    File      ml_tree
    String    clustername = basename(basename(basename(cluster_samples)), "_cluster.tsv")
    File?     render_template 
  }
  
  command{
    # date and version control
    date | tee DATE
    Rscript --version | tee RSCRIPT_VERSION
    R --version | head -n1 | sed 's/).*/)/' | tee R_VERSION

    if [[ -z ~{render_template} ]]; then cp ${render_template} report_template.Rmd; fi
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


