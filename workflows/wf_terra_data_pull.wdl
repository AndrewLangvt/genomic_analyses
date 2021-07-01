version 1.0

task zip {

  input {
    Array[File]   files
  }

  command <<<
    mkdir ziped_files
    cp ~{sep=" " files} ./zipped_files
    ls 
    ls ./zipped_files
    zip -r $(date +%Y-%m-%d)_zipped_files.zip ./zipped_files
  >>>
  output {
    File    zipped_files = glob("*.zip")
  }

  runtime {
      docker:       "quay.io/broadinstitute/viral-baseimage@sha256:340c0a673e03284212f539881d8e0fb5146b83878cbf94e4631e8393d4bc6753"
      memory:       "1 GB"
      cpu:          1
      disks:        "local-disk 100 SSD"
      preemptible:  0
  }
}


workflow terra_data_pull {
    input {
        Array[File] first_fileset
        Array[File]? second_fileset
    }
    call zip {
        input:
            files = first_fileset
    }
    output {
        File    zipped_files  = zip.zipped_files
    }
}
