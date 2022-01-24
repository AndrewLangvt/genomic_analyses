version 1.0

workflow seq_run_report {
  meta {
    description: "Generates PDF with basic metrics from a Sequencing run."
  }

  input {
    File          metrics_file
    String        batch_id="BATCH_ID"
    File?         render_template
  }

  call seqreport_render {
    input:
      seq_output      = metrics_file,
      batch_ID        = facility,
      render_template = render_template
  }

  output {
    File      analysis_doc = seqreport_render.analysis_doc
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

    cp ~{seq_output} ###INSERT THE BATCH OUTPUT HERE?
    
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
    docker:       ### EDIT
    memory:       "2 GB"
    cpu:          2
    disks:        "local-disk 100 SSD"
    preemptible:  0
  }
}
