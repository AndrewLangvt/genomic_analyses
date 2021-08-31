version 1.0

task zip {

  input {
    String        setname = "todaysDATE"
    Array[File]   files
  }

  command <<<
    mkdir ~{setname}_zipped_files
    for file in ~{sep=' ' files}; do
      cp $file ~{setname}zipped_files
      echo $file 
    done    
    ls ~{setname}_zipped_files
    zip -r ~{setname}_zipped_files.zip ~{setname}_zipped_files
  >>>
  output {
    File    zipped_files = "~{setname}_zipped_files.zip"
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
    Array[File]  file_array1
  }
  Array[File]         file_array = flatten(file_arrays)
  call zip {
    input:
      files = file_array
  }
  output {
    File    zipped_files  = zip.zipped_files
  }
}
