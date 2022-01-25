version 1.0

workflow seq_run_report {
  meta {
    description: "Generates PDF with basic metrics from a Sequencing run."
  }

  input {
    String    terra_project
    String    workspace_name
    String    table_name
    String    id_column
    String    batch_id="BATCH_ID"
    File?     render_template
  }

  call download_entities_csv {
    input:
      terra_project  = terra_project, 
      workspace_name = workspace_name,
      table_name     = table_name,
      id_column      = id_column
  }
  
    call seqreport_render {
    input:
      seq_output      = download_entities_csv.csv_file,
      batch_ID        = batch_id,
      render_template = render_template
  }
  
  output {
    File    table_file   = download_entities_csv.csv_file
    File    analysis_doc = seqreport_render.analysis_doc
  }
}

task download_entities_csv {
  input {
    String  terra_project
    String  workspace_name
    String  table_name
    String  id_column
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
    from datetime import datetime, timezone, timedelta

    workspace_project = '~{terra_project}'
    workspace_name = '~{workspace_name}'
    table_name = '~{table_name}'
    out_fname = '~{table_name}'+f'_table_{datetime.now(timezone(timedelta(hours=-4))).strftime("%Y-%m-%d")}'+'.csv'

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
      writer = csv.DictWriter(outf, headers.keys(), delimiter=',', dialect=csv.unix_dialect, quoting=csv.QUOTE_MINIMAL)
      writer.writeheader()
      writer.writerows(rows)

    with open(out_fname, 'r') as infile:
      headers = infile.readline()
      headers_array = headers.strip().split(',')
      headers_array[0] = "specimen_id"
      with open('~{table_name}'+'.json', 'w') as outfile:
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
    memory: "8 GB"
    cpu: 4
  }
  
  output {
    File csv_file = select_first(glob("~{table_name}*.csv"))
    File json_file = "~{table_name}.json"
  }
}

task seqreport_render {

  input {
    File      seq_output
    String    batch_ID
    File?     render_template
  }

  command <<<
    # date and version control
    date | tee DATE
    R --version | head -n1 | sed 's/).*/)/' | tee R_VERSION

    cp ~{seq_output} sequencerun_data.csv
    
    sed -i 's/titan_illumina_pe_analysis_date/seq_date/;s/titan_clearlabs_analysis_date/seq_date/;s/kraken_sc2/percent_SC2_reads/' sequencerun_data.csv
    
    if [[ -f "~{render_template}" ]]; then cp ~{render_template} render_template.Rmd
    else wget -O render_template.Rmd https://raw.githubusercontent.com/bmtalbot/APHL_COVID_Genomics/main/Sars-Cov-2-Seq_Report.Rmd; fi

    R --no-save <<CODE

    tinytex::reinstall_tinytex()
    library(rmarkdown)
    library(tools)

    report <- "render_template.Rmd"

    # Render the report
    render(report, output_file='report.pdf')
    CODE

    cp report.pdf ~{batch_ID}_SARSCOV2_QC_analysis.pdf   
  >>>
  output {
    String     date = read_string("DATE")
    String     r_version = read_string("R_VERSION")
    File       analysis_doc = "${batch_ID}_SARSCOV2_QC_analysis.pdf"
    }

  runtime {
    docker:       "bmtalbot/sc2-seq-report:0.3"
    memory:       "2 GB"
    cpu:          2
    disks:        "local-disk 100 SSD"
    preemptible:  0
  }
}
