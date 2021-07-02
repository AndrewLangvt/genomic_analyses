version 1.0

task zip {

  input {
    Array[File]   files
  }

  command <<<
    echo ~{sep=' ' files}
    # file_array=(~{sep=' ' files})
    # echo $(file_array)
    # mkdir ziped_files
    # for file in $file_array;do
    #   echo $file
    #   cp $file ./zipped_files
    # ls 
    # ls ./zipped_files
    # zip -r zipped_files.zip ./zipped_files
    touch test.zip
  >>>
  output {
    File    zipped_files = glob("*.zip")
  }

  runtime {
      docker:       "staphb/abricate:0.8.7"
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
