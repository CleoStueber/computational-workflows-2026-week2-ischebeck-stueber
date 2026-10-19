# nf-core/rnaseqischebeckstueber: Usage

## Introduction

The pipeline accepts single-end and paired-end RNA-seq reads in gzip-compressed FASTQ files. It requires a samplesheet (`--input`) and a matching genome FASTA and GTF annotation, supplied with `--fasta` and `--gtf` or selected using `--genome`.

RiboDetector is enabled by default. Use `--skip_ribodetector` to quantify trimmed reads without rRNA filtering.

Pipeline parameters are defined in [`nextflow_schema.json`](../nextflow_schema.json).

## Samplesheet input

Specify a comma-separated samplesheet with a header row:

```bash
--input 'samplesheet.csv'
```

### Multiple runs of the same sample

Use the same `sample` name for sequencing runs belonging to one biological sample. The pipeline concatenates their FASTQ files before preprocessing.

```csv
sample,fastq_1,fastq_2
CONTROL_REP1,AEG588A1_S1_L002_R1_001.fastq.gz,AEG588A1_S1_L002_R2_001.fastq.gz
CONTROL_REP1,AEG588A1_S1_L003_R1_001.fastq.gz,AEG588A1_S1_L003_R2_001.fastq.gz
```

Runs assigned to the same sample must have consistent read type (single-end or paired-end) and strandedness.

### Full samplesheet

The `fastq_2` column determines whether a sample is paired-end. Leave it empty, or omit it, for single-end data. The optional `strandedness` column can contain `forward`, `reverse`, `unstranded`, or `auto`.

```csv
sample,fastq_1,fastq_2,strandedness
CONTROL_REP1,control_R1.fastq.gz,control_R2.fastq.gz,auto
CONTROL_REP2,control2_R1.fastq.gz,control2_R2.fastq.gz,reverse
TREATMENT_REP1,treatment.fastq.gz,,auto
```

| Column | Required | Description |
| --- | --- | --- |
| `sample` | Yes | Sample ID without spaces; identical for runs of the same sample. |
| `fastq_1` | Yes | First read file (`.fastq.gz` or `.fq.gz`). |
| `fastq_2` | No | Second read file for paired-end data. |
| `strandedness` | No | `forward`, `reverse`, `unstranded`, or `auto`. |

If strandedness is missing, empty, or `auto`, Salmon detects the library type during quantification.

An [example samplesheet](../assets/samplesheet.csv) is included in the repository. The example paths must be replaced with real FASTQ paths.

## Running the pipeline

Run the pipeline from the repository root using Nextflow 25.10.4 or later:

```bash
nextflow run . \
    -profile docker \
    --input samplesheet.csv \
    --fasta reference.fa \
    --gtf annotation.gtf \
    --outdir results
```

Replace the file paths with your own. Instead of `--fasta` and `--gtf`, you can use a reference configured in `conf/igenomes.config`, for example `--genome GRCm38`.

The working directory contains `work/` (intermediate files), `.nextflow.log` (run log), and other Nextflow cache files. Published outputs are saved under `--outdir`.

To reuse parameters, create a YAML or JSON file and provide it with `-params-file`:

```bash
nextflow run . -profile docker -params-file params.yaml
```

```yaml
input: './samplesheet.csv'
fasta: './reference.fa'
gtf: './annotation.gtf'
outdir: './results'
```

> [!WARNING]
> Supply pipeline parameters on the command line or with `-params-file`, not with `-c`. Custom config files (`-c`) are intended for Nextflow configuration, such as resource settings.

Test the pipeline with the included small dataset:

```bash
nextflow run . -profile test,docker --outdir results_test
nextflow run . -profile test_skip_ribodetector,docker --outdir results_test_skip_ribo
```

Both test profiles use public nf-core test data. The `test_full` profile uses two mouse samples but requires FASTQ files outside the repository (see `test_samplesheet_full.csv`); it is not a standalone test.

### Updating the pipeline

For a local clone, update the code from its Git repository with:

```bash
git pull
```

### Reproducibility

Record the Git commit or release tag, input accessions, genome and annotation versions, parameter file, and software environment. The pipeline collects software versions and Nextflow execution reports under `pipeline_info/`.

Retaining `work/` and Nextflow's cache allows completed tasks to be reused with `-resume`.

## Core Nextflow arguments

> [!NOTE]
> Nextflow options use a single hyphen (`-profile`, `-resume`); pipeline parameters use two (`--input`, `--outdir`).

### `-profile`

Choose the execution environment and optional test configuration. Profiles are applied from left to right, so later profiles may override earlier settings.

- `docker`: Run tools in Docker containers.
- `conda`, `singularity`, `apptainer` (and other supported profiles): Alternative software environments.
- `test`: Small test using RiboDetector.
- `test_skip_ribodetector`: Small test without RiboDetector.
- `test_full`: Two mouse RNA-seq samples; requires external FASTQ files.

For reproducibility, a container profile such as `docker` is recommended over using software installed directly on the host.

### `-resume`

Add `-resume` to reuse cached tasks from a previous run when their inputs, commands and environment have not changed. The corresponding work files must still be available.

### `-c`

Use `-c custom.config` for custom Nextflow configuration, such as executor or resource settings. See the [nf-core configuration guide](https://nf-co.re/docs/running/configuration/nextflow-for-your-system).

## Custom configuration

### Resource requests

Default CPU, memory and time settings are defined in `conf/base.config`. Processes may retry with increased resources after certain errors. Resource limits can be adjusted for the available computer or cluster.

### Custom Containers

The pipeline uses containers or Conda environments defined by its modules. See the [nf-core guide](https://nf-co.re/docs/running/configuration/nextflow-for-your-system#update-tool-versions) before changing tool versions.

### Custom Tool Arguments

Additional module arguments can be supplied through Nextflow configuration where supported. See the [nf-core guide](https://nf-co.re/docs/running/configuration/nextflow-for-your-system#modifying-tool-arguments).

### nf-core/configs

The pipeline can load institutional profiles from [`nf-core/configs`](https://github.com/nf-core/configs). Check that the selected profile is available for your computing environment.

## Running in the background

Nextflow must remain running until the workflow completes. Use `-bg` to launch it in the background, or run it within a `tmux` or `screen` session.

## Nextflow memory requirements

If the Nextflow Java process needs a memory limit, set `NXF_OPTS` before starting the pipeline, for example:

```bash
export NXF_OPTS='-Xms1g -Xmx4g'
```

This limits Nextflow's Java heap, not the memory allocated to individual pipeline processes.
