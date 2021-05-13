version 1.0

import "../tasks/task_taxonID.wdl" as taxon_ID

workflow sc2_variantID {
  meta {
    description: "Runs Pangolin & Nextclade to characterize SARS-CoV-2 Genomes"
  }
  
  input {
    String  samplename
    File    fasta
  }

  call taxon_ID.pangolin2 {
    input:
      samplename = samplename,
      fasta      = fasta
  }
  call taxon_ID.nextclade_one_sample {
    input:
      genome_fasta = fasta
  }

  output {
    String  pangolin_lineage       = pangolin2.pangolin_lineage
    String  pangolin_probability   = pangolin2.pangolin_probability
    File    pango_lineage_report   = pangolin2.pango_lineage_report
    String  pangolin_version       = pangolin2.version
    String  pangoLEARN_version     = pangolin2.pangoLEARN_version

    File    nextclade_json         = nextclade_one_sample.nextclade_json
    File    auspice_json           = nextclade_one_sample.auspice_json
    File    nextclade_tsv          = nextclade_one_sample.nextclade_tsv
    String  nextclade_clade        = nextclade_one_sample.nextclade_clade
    String  nextclade_aa_subs      = nextclade_one_sample.nextclade_aa_subs
    String  nextclade_aa_dels      = nextclade_one_sample.nextclade_aa_dels
    String  nextclade_version      = nextclade_one_sample.nextclade_version
  }
}
