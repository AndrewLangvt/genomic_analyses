version 1.0

import "../tasks/task_alignment.wdl" as align
import "../tasks/task_phylo.wdl" as phylo
import "../tasks/task_data_vis.wdl" as vis

workflow genomic_cluster_analysis {
  meta {
    description: "Generates PDF for SNP matrix and Phylogenetic Tree."
  }

  input {
    Array[File]   genomes
    String        cluster_name="Cluster_Analysis"
    File          specimen_status
    File?         render_template
  }

  call align.mafft {
    input:
      genomes = genomes
  }
  call phylo.snp_dists {
    input:
      cluster_name    = cluster_name,
      alignment       = mafft.msa
  }
  call phylo.iqtree {
    input:
      cluster_name    = cluster_name,
      alignment       = mafft.msa
  }
  call vis.cluster_render {
    input:
      cluster_name    = cluster_name,
      snp_matrix      = snp_dists.snp_matrix,
      ml_tree         = iqtree.ml_tree,
      specimen_status = specimen_status,
      render_template = render_template
  }

  output {
    File      analysis_doc = cluster_render.analysis_doc
    File      snp_list     = cluster_render.snp_list
    File      snp_heatmap  = cluster_render.snp_heatmap
    File      ml_tree      = iqtree.ml_tree
    File      msa          = mafft.msa
    File      snp_matrix   = snp_dists.snp_matrix
  }
}
