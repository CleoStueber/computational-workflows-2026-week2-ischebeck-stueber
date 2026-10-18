# nf-core/rnaseqischebeckstueber: Output

## Introduction

This document describes the output produced by the pipeline. Most of the plots are taken from the MultiQC report, which summarises results at the end of the pipeline.

The directories listed below will be created in the results directory after the pipeline has finished. All paths are relative to the top-level results directory.

In addition to quality control reports, the pipeline produces trimmed and rRNA-filtered reads, Salmon quantification results, and gene- and transcript-level expression matrices for downstream analysis.

## Pipeline overview

The pipeline is built using [Nextflow](https://www.nextflow.io/) and processes data using the following steps:

- [CAT_FASTQ](#cat_fastq) - Merge FASTQ files belonging to the same sample
- [FastQC](#fastqc) - Quality control of raw, trimmed and rRNA-filtered reads
- [fastp](#fastp) - Adapter trimming and read quality filtering
- [RiboDetector](#ribodetector) - Identification and removal of rRNA reads
- [Reference preparation](#reference-preparation) - Prepare the reference annotation, transcript sequences and Salmon index
- [Salmon](#salmon) - Transcript quantification and automatic library-type detection when needed
- [tximport](#tximport) - Combine quantification results into expression matrices
- [Gene abundance](#gene-abundance) - Summary of the 20 genes with the highest mean TPM
- [MultiQC](#multiqc) - Aggregate report describing results and QC from the whole pipeline
- [Pipeline information](#pipeline-information) - Report metrics generated during workflow execution

### CAT_FASTQ

<details markdown="1">
<summary>Output files</summary>

- `cat_fastq/`
  - `*.merged.fastq.gz`: Merged FASTQ files for each sample.

</details>

CAT_FASTQ combines FASTQ files belonging to the same sample before further processing.

### FastQC

<details markdown="1">
<summary>Output files</summary>

- `fastqc_raw/`: Quality reports for raw reads
- `fastqc_trimmed/`: Quality reports after trimming
- `fastqc_filtered/`: Quality reports after rRNA removal
  - `*_fastqc.html`: FastQC report containing quality metrics
  - `*_fastqc.zip`: Zip archive containing the FastQC report, tab-delimited data file and plot images

</details>
[FastQC](http://www.bioinformatics.babraham.ac.uk/projects/fastqc/) gives general quality metrics about your sequenced reads. It provides information about the quality score distribution across your reads, per base sequence content (%A/T/G/C), adapter contamination and overrepresented sequences. For further reading and documentation see the [FastQC help pages](http://www.bioinformatics.babraham.ac.uk/projects/fastqc/Help/).

### fastp

<details markdown="1">
<summary>Output files</summary>

- `fastp/`
  - `*.fastp.fastq.gz`: Trimmed and quality-filtered reads.
  - `*.fastp.html`: HTML quality report.
  - `*.fastp.json`: Quality statistics.
  - `*.fastp.log`: Processing log.

</details>

[fastp](https://github.com/OpenGene/fastp) performs adapter trimming and quality filtering of sequencing reads.

### RiboDetector

<details markdown="1">
<summary>Output files</summary>

- `ribodetector/`
  - `*.nonrna*.fastq.gz`: Reads remaining after rRNA filtering.
  - `*.log`: Processing log.

</details>

[RiboDetector](https://github.com/hzi-bifo/RiboDetector) identifies and removes predicted ribosomal RNA reads before quantification.

### Reference preparation

<details markdown="1">
<summary>Output files</summary>

- `filter_gtf/`
  - `filtered.gtf`: Filtered gene annotation.
- `gffread/`
  - `reference.fasta`: Extracted transcript sequences.
- `salmon_index/`
  - `salmon/`: Salmon index files.
- `custom_tx2gene/`
  - `reference.tx2gene.tsv`: Transcript-to-gene mapping.

</details>

The reference annotation is filtered and transcript sequences are extracted using Gffread. These sequences are used to generate a Salmon index for quantification.

### Salmon

<details markdown="1">
<summary>Output files</summary>

- `salmon_quant/`
  - `<sample>/quant.sf`: Transcript-level abundance estimates.
  - `<sample>/quant.genes.sf`: Gene-level abundance estimates.
  - `<sample>/aux_info/`: Additional quantification statistics.
  - `<sample>/logs/`: Execution logs.
  - `<sample>/lib_format_counts.json`: Counts of reads matching different library orientations.
  - `<sample>/aux_info/meta_info.json`: Quantification statistics and detected library type.

</details>

[Salmon](https://combine-lab.github.io/salmon/) estimates transcript and gene abundance from the processed sequencing reads.

If library strandedness is missing, empty, or set to `auto`, Salmon automatically detects the library type during quantification using `--libType A`. Otherwise, the specified library type is used.

### tximport

<details markdown="1">
<summary>Output files</summary>

- `tximeta_tximport/`
  - `salmon.gene_counts.tsv`: Gene-level counts.
  - `salmon.gene_tpm.tsv`: Gene-level TPM values.
  - `salmon.gene_lengths.tsv`: Estimated gene lengths.
  - `salmon.transcript_counts.tsv`: Transcript-level counts.
  - `salmon.transcript_tpm.tsv`: Transcript-level TPM values.
  - `salmon.transcript_lengths.tsv`: Transcript lengths.
  - `salmon.tx2gene_augmented.tsv`: Transcript-to-gene mapping.
  - `salmon.gene_counts_scaled.tsv`: Scaled gene counts.
  - `salmon.gene_counts_length_scaled.tsv`: Length-scaled gene counts.

</details>

[tximport](https://bioconductor.org/packages/tximport/) combines Salmon quantification results into gene- and transcript-level expression matrices for downstream analysis.

### Gene abundance

<details markdown="1">
<summary>Output files</summary>

- `gene_abundance/`
  - `gene_abundance_mqc.tsv`: Gene abundance summary used by MultiQC.

</details>

This step identifies the 20 genes with the highest mean TPM across samples and includes the results in the MultiQC report.


### MultiQC

<details markdown="1">
<summary>Output files</summary>

- `multiqc/`
  - `multiqc_report.html`: a standalone HTML file that can be viewed in your web browser.
  - `multiqc_data/`: directory containing parsed statistics from the different tools used in the pipeline.

</details>

[MultiQC](http://multiqc.info) is a visualization tool that generates a single HTML report summarising all samples in your project. Most of the pipeline QC results are visualised in the report and further statistics are available in the report data directory.

Results generated by MultiQC collate pipeline QC from supported tools e.g. FastQC. The pipeline has special steps which also allow the software versions to be reported in the MultiQC output for future traceability. For more information about how to use MultiQC reports, see <http://multiqc.info>.


### Pipeline information

<details markdown="1">
<summary>Output files</summary>

- `pipeline_info/`
  - `execution_report_*.html`: Execution performance and resource usage.
  - `execution_timeline_*.html`: Timeline of process execution.
  - `execution_trace_*.txt`: Per-task execution statistics.
  - `pipeline_dag_*.html`: Workflow dependency graph.
  - `params_*.json`: Parameters used during execution.
  - `nf_core_rnaseqischebeckstueber_software_mqc_versions.yml`: Software versions collected by the pipeline.
  - `pipeline_report.html` and `pipeline_report.txt`: Optional completion summaries generated when email reporting is configured.

</details>

[Nextflow](https://docs.seqera.io/platform-cloud/reports/overview) provides excellent functionality for generating various reports relevant to the running and execution of the pipeline. This will allow you to troubleshoot errors with the running of the pipeline, and also provide you with other information such as launch commands, run times and resource usage.
