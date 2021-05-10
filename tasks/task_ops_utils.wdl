version 1.0


task get_single_file {
  input {
    String      file_URL
    String      fname = basename(file_URL)
    String      docker="theiagen/utility:1.0"
  }

  command {
    wget ~{file_URL} -O "~{fname}"
  }

  output {
    File       outfile = "~{fname}"
  }

  runtime {
    docker:       "~{docker}"
    memory:       "8 GB"
    cpu:          1
    disks:        "local-disk 100 SSD"
    preemptible:  0
  }
}

task get_ref_files {
  input {
    String      ref_genome_URL
    String      ref_genome_fname = basename(ref_genome_URL)
    String      ref_gff_URL
    String      ref_gff_fname = basename(ref_gff_URL)
    String      docker="theiagen/utility:1.0"
  }

  command {
    wget ~{ref_genome_URL} -O "~{ref_genome_fname}"
    wget ~{ref_gff_URL} -O "~{ref_gff_fname}"
  }

  output {
    File       ref_genome         = "~{ref_genome_fname}"
    File       ref_gff            = "~{ref_gff_fname}"
  }

  runtime {
    docker:       "~{docker}"
    memory:       "8 GB"
    cpu:          1
    disks:        "local-disk 100 SSD"
    preemptible:  0
  }
}
