version 1.0

task zip {

  input {
    String        setname = "todaysDATE"
    Array[File]   file_array
  }

  command <<<
    mkdir zipped_files
    for file in ~{sep=' ' files}; do
      cp $file zipped_files
      echo $file 
      ls zipped_files
    done    
    ls zipped_files
    zip -r zipped_files.zip zipped_files
  >>>
  output {
    File    zipped_files = "zipped_files.zip"
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
    Array[Array[File]]  files
    Array[File]         file_array = flatten(files)
  }
  call zip {
    input:
      files = flatened_files
  }
  output {
    File    zipped_files  = zip.zipped_files
  }
}
