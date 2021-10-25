version 1.0

workflow terra_table_to_csv {
    
    input {
      String	gcs_uri
      String	outname
      String	date_string
      String	id_column
    }

    call download_entities_csv {
      input:
        outname=outname,
        id_column=id_column
    }
  
}

task download_entities_csv {
  input {
    String  terra_project
    String  workspace_name
    String  table_name
    String  id_column
    String  outname
    String  docker = "schaluvadi/pathogen-genomic-surveillance:api-wdl"
  }

  meta {
    volatile: true
  }

  command <<<
    python3<<CODE
    import csv
    import json
    import collections

    from firecloud import api as fapi

    workspace_project = '~{terra_project}'
    workspace_name = '~{workspace_name}'
    table_name = '~{table_name}'
    out_fname = '~{outname}'+'.csv'

    table = json.loads(fapi.get_entities(workspace_project, workspace_name, table_name).text)
    headers = collections.OrderedDict()
    rows = []
    headers[table_name + "_id"] = 0
    for row in table:
      outrow = row['attributes']
      for x in outrow.keys():
        headers[x] = 0
        if type(outrow[x]) == dict and set(outrow[x].keys()) == set(('itemsType', 'items')):
          outrow[x] = outrow[x]['items']
      outrow[table_name + "_id"] = row['name']
      rows.append(outrow)

    with open(out_fname, 'wt') as outf:
      writer = csv.DictWriter(outf, headers.keys(), delimiter='\t', dialect=csv.unix_dialect, quoting=csv.QUOTE_MINIMAL)
      writer.writeheader()
      writer.writerows(rows)

    with open(out_fname, 'r') as infile:
      headers = infile.readline()
      headers_array = headers.strip().split('\t')
      headers_array[0] = "specimen_id"
      with open('~{outname}'+'.json', 'w') as outfile:
        for line in infile:
          outfile.write('{')
          line_array=line.strip().split('\t')
          for x,y in zip(headers_array, line_array):
            if x == "nextclade_aa_dels" or x == "nextclade_aa_subs":
              y = y.replace("|", ",")
            if y == "NA":
              y = ""
            if y == "required_for_submission":
              y = ""
            if "Uneven pairs:" in y:
              y = ""
            if x == "County":
              pass
            else:  
              outfile.write('"'+x+'"'+':'+'"'+y+'"'+',')
          outfile.write('"notes":""}'+'\n')
      
    CODE
  >>>
  
  runtime {
    docker: docker
    memory: "16 GB"
    cpu: 4
  }
  
  output {
    File csv_file = "~{outname}.csv"
    File json_file = "~{outname}.json"
  }
}


task gcs_copy {
  input {
    File		infile
    File		infile_json
    String      gcs_uri_prefix
    String		date_string
  }
  
  meta {
    volatile: true
  }
  
  command <<<
    set -e
    gsutil -m cp ~{infile} ~{gcs_uri_prefix+"backup/"+date_string+"/"}
    gsutil -m cp ~{infile_json} ~{gcs_uri_prefix} 
  >>>
  
  output {
    File logs = stdout()
  }
  runtime {
    docker: "quay.io/broadinstitute/viral-baseimage:0.1.20"
    memory: "32 GB"
    cpu: 8
    disks:        "local-disk 500 SSD"
  }
}

