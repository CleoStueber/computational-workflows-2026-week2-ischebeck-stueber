# nf-core/rnaseqischebeckstueber: Output

## Introduction

This document describes the output produced by the pipeline. Most QC results are summarised in the MultiQC report generated at the end of the run.

The directories below are created in the results directory specified with `--outdir`. All paths are relative to this directory.

The pipeline produces processed reads, Salmon quantification results, and gene- and transcript-level expression matrices. rRNA-filtered reads are only produced when RiboDetector is enabled.

## Pipeline overview

The pipeline is built using [Nextflow](https://www.nextflow.io/) and processes data using the following steps:

- [CAT_FASTQ](#cat_fastq) - Merge FASTQ files from the same sample
- [FastQC](#fastqc) - Quality control of raw and processed reads
- [fastp](#fastp) - Adapter trimming and quality filtering
- [RiboDetector](#ribodetector) - Optional rRNA removal
- [Reference preparation](#reference-preparation) - Prepare transcripts and the Salmon index
- [Salmon](#salmon) - Transcript and gene quantification
- [tximport](#tximport) - Generate expression matrices
- [Gene abundance](#gene-abundance) - Report the top 20 genes by mean TPM
- [MultiQC](#multiqc) - Summarise QC results
- [Pipeline information](#pipeline-information) - Record run parameters and execution statistics

### CAT_FASTQ

<details markdown="1">
<summary>Output files</summary>

- `cat_fastq/`
  - `*.merged.fastq.gz`: Merged FASTQ files for each sample.

</details>

CAT_FASTQ combines reads from multiple sequencing runs belonging to the same sample.

### FastQC

<details markdown="1">
<summary>Output files</summary>

- `fastqc_raw/`: QC reports before trimming.
- `fastqc_trimmed/`: QC reports after trimming.
- `fastqc_filtered/`: QC reports after rRNA removal (if enabled).

Each directory contains:

- `*_fastqc.html`: HTML quality report.
- `*_fastqc.zip`: Report data and plots.

</details>

[FastQC](https://www.bioinformatics.babraham.ac.uk/projects/fastqc/) reports read quality, sequence composition, adapter content and overrepresented sequences. The `fastqc_filtered/` directory is absent when `--skip_ribodetector` is used.

### fastp

<details markdown="1">
<summary>Output files</summary>

- `fastp/`
  - `*.fastp.fastq.gz`: Trimmed and filtered reads.
  - `*.fastp.html`: HTML quality report.
  - `*.fastp.json`: Quality statistics.
  - `*.fastp.log`: Processing log.

</details>

[fastp](https://github.com/OpenGene/fastp) trims adapters and filters low-quality reads.

### RiboDetector

<details markdown="1">
<summary>Output files</summary>

- `ribodetector/`
  - `*.nonrna*.fastq.gz`: Reads retained after rRNA removal.
  - `*.log`: Processing log.

</details>

[RiboDetector](https://github.com/hzi-bifo/RiboDetector) removes predicted rRNA reads before quantification. This step is enabled by default and can be disabled with `--skip_ribodetector`. When skipped, Salmon uses the fastp output directly.

### Reference preparation

<details markdown="1">
<summary>Output files</summary>

- `filter_gtf/`
  - `filtered.gtf`: Annotation filtered to retain records on contigs present in the reference FASTA that contain a `transcript_id` attribute, along with GTF comment lines.
- `gffread/`
  - `reference.fasta`: Extracted transcript sequences.
- `salmon_index/`
  - `salmon/`: Salmon index.
- `custom_tx2gene/`
  - `reference.tx2gene.tsv`: Transcript-to-gene mapping.

</details>

The pipeline filters the GTF annotation, extracts transcript sequences using [Gffread](https://github.com/gpertea/gffread) and builds a Salmon index.

### Salmon

<details markdown="1">
<summary>Output files</summary>

- `salmon_quant/`
  - `<sample>/quant.sf`: Transcript abundance estimates.
  - `<sample>/quant.genes.sf`: Gene abundance estimates.
  - `<sample>/aux_info/`: Additional quantification statistics.
  - `<sample>/logs/`: Salmon logs.
  - `<sample>/lib_format_counts.json`: Library orientation counts.
  - `<sample>/aux_info/meta_info.json`: Mapping statistics and library-type information.

</details>

[Salmon](https://salmon.readthedocs.io/) quantifies transcripts from processed reads. When strandedness is omitted or set to `auto`, Salmon detects the library type automatically.

### tximport

<details markdown="1">
<summary>Output files</summary>

- `tximeta_tximport/`
  - `salmon.gene_counts.tsv`: Estimated gene counts.
  - `salmon.gene_tpm.tsv`: Gene TPM values.
  - `salmon.gene_lengths.tsv`: Estimated gene lengths.
  - `salmon.gene_counts_scaled.tsv`: Scaled gene counts.
  - `salmon.gene_counts_length_scaled.tsv`: Length-scaled gene counts.
  - `salmon.transcript_counts.tsv`: Estimated transcript counts.
  - `salmon.transcript_tpm.tsv`: Transcript TPM values.
  - `salmon.transcript_lengths.tsv`: Transcript lengths.
  - `salmon.tx2gene_augmented.tsv`: Transcript-to-gene mapping.

</details>

[tximport](https://bioconductor.org/packages/tximport/) combines the Salmon results into expression matrices for downstream analysis.

### Gene abundance

<details markdown="1">
<summary>Output files</summary>

- `gene_abundance/`
  - `gene_abundance_mqc.tsv`: Table used in the MultiQC report.

</details>

This table lists the 20 genes with the highest mean TPM across samples.

### MultiQC

<details markdown="1">
<summary>Output files</summary>

- `multiqc/`
  - `multiqc_report.html`: Combined HTML report.
  - `multiqc_data/`: Collected report data.
  - `multiqc_plots/`: Exported plots, if generated.

</details>

[MultiQC](https://multiqc.info/) combines FastQC, fastp and Salmon results with software versions and the gene abundance table.

### Pipeline information

<details markdown="1">
<summary>Output files</summary>

- `pipeline_info/`
  - `execution_report_*.html`: Resource usage and execution performance.
  - `execution_timeline_*.html`: Task execution timeline.
  - `execution_trace_*.txt`: Per-task execution statistics.
  - `pipeline_dag_*.html`: Workflow dependency graph.
  - `params_*.json`: Parameters used for the run.
  - `nf_core_rnaseqischebeckstueber_software_mqc_versions.yml`: Software versions.
  - `pipeline_report.html` and `pipeline_report.txt`: Completion summaries, when email reporting is configured.

</details>

[Nextflow](https://www.nextflow.io/docs/latest/reports.html) generates execution reports for tracking runtime, resource use and workflow progress.
