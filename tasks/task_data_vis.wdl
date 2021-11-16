version 1.0

task cluster_render {

  input {
    File      snp_matrix
    File      ml_tree
    String    cluster_name
    String    facility=""
    String    timezone="America/New_York"
    File?     render_template
  }

  command <<<
    # date and version control
    date | tee DATE
    R --version | head -n1 | sed 's/).*/)/' | tee R_VERSION

    cp ~{snp_matrix} snp_matrix.tsv
    cp ~{ml_tree} ml_tree.tree

    if [[ -f "~{render_template}" ]]; then cp ~{render_template} render_template.Rmd
    else wget -O render_template.Rmd https://raw.githubusercontent.com/MASPHL/templates/v1.0/cluster_report_template.Rmd; fi

    sed -i "s/Genomic\ Analysis/~{facility}\ Genomic\ Analysis/" render_template.Rmd
    grep "Genomic Analysis" render_template.Rmd
 
    R --no-save <<CODE

    library(rmarkdown)
    library(tools)

    snp_mat <- read.table("snp_matrix.tsv", header = T, check.names = FALSE, sep = "\t", row.names = 1)
    nwk <- "ml_tree.tree"
    report <- "render_template.Rmd"

    # Modify SNP matrix to pairwise list
    pairwise <- t(combn(colnames(snp_mat), 2))
    pairwise_list <- data.frame(pairwise, dist=snp_mat[pairwise])
    rownames(pairwise_list) <- NULL
    colnames(pairwise_list) <- c("Sample1","Sample2","Distance")
    write.csv(pairwise_list, 'pairwise_snp_list.csv', row.names = FALSE, quote = FALSE)

    # Render the report
    render(report, output_file='report.pdf')
    CODE

    ~{default='' 'export TZ=' + timezone}
        
    cp pairwise_snp_list.csv ~{cluster_name}_pairwise_snp_list_$(date +"%Y-%m-%d").csv
    cp report.pdf ~{cluster_name}_cluster_analysis_$(date +"%Y-%m-%d").pdf
    cp SNP_heatmap.png ~{cluster_name}_SNP_heatmap.png      
  >>>
  output {
    String     date = read_string("DATE")
    String     r_version = read_string("R_VERSION")
    File       analysis_doc = select_first(glob("*_cluster_analysis*pdf"))
    File       snp_heatmap = select_first(glob("*_SNP_heatmap*png"))
    File       snp_list = select_first(glob("*_pairwise_snp_list*csv"))
  }

  runtime {
    docker:       "staphb/cluster-report-env:1.0"
    memory:       "2 GB"
    cpu:          2
    disks:        "local-disk 100 SSD"
    preemptible:  0
  }
}
