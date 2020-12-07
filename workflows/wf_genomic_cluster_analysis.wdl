import "../tasks/task_alignment.wdl" as align
import "../tasks/task_phylo.wdl" as phylo
import "../tasks/task_data_vis.wdl" as vis

workflow genomic_cluster_analysis {

  input {
    Array[File]   genomes
    File          cluster_samples
    File?         render_template = "/cluster_report_template.Rmd"
  }

  call align.mafft {
    input:
      genomes = genomes
  }
  call phylo.snp_dists {
    input:
      cluster_samples = cluster_samples,
      alignment = mafft.msa
  }
  call phylo.iqtree {
    input:
      cluster_samples = cluster_samples,
      alignment = mafft.msa      
  }
  call vis.cluster_render {
    input:
      cluster_samples = cluster_samples,
      snp_matrix = snp_dists.snp_matrix,
      ml_tree = iqtree.ml_tree,
      render_template = render_template
  }
  
  output {
    File      analysis_doc = cluster_render.analysis_doc
    File      snp_list =cluster_render.snp_list
  }
}



