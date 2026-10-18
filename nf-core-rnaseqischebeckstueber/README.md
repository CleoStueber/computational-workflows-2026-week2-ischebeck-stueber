<h1>
  <picture>
    <source media="(prefers-color-scheme: dark)" srcset="docs/images/nf-core-rnaseqischebeckstueber_logo_dark.png">
    <img alt="nf-core/rnaseqischebeckstueber" src="docs/images/nf-core-rnaseqischebeckstueber_logo_light.png">
  </picture>
</h1>

[![Open in GitHub Codespaces](https://img.shields.io/badge/Open_In_GitHub_Codespaces-black?labelColor=grey&logo=github)](https://github.com/codespaces/new/nf-core/rnaseqischebeckstueber)
[![GitHub Actions CI Status](https://github.com/nf-core/rnaseqischebeckstueber/actions/workflows/nf-test.yml/badge.svg)](https://github.com/nf-core/rnaseqischebeckstueber/actions/workflows/nf-test.yml)
[![GitHub Actions Linting Status](https://github.com/nf-core/rnaseqischebeckstueber/actions/workflows/linting.yml/badge.svg)](https://github.com/nf-core/rnaseqischebeckstueber/actions/workflows/linting.yml)
[![AWS CI](https://img.shields.io/badge/CI%20tests-full%20size-FF9900?labelColor=000000&logo=Amazon%20AWS)](https://nf-co.re/rnaseqischebeckstueber/results)
[![Cite with Zenodo](http://img.shields.io/badge/DOI-10.5281/zenodo.XXXXXXX-1073c8?labelColor=000000)](https://doi.org/10.5281/zenodo.XXXXXXX)
[![nf-test](https://img.shields.io/badge/unit_tests-nf--test-337ab7.svg)](https://www.nf-test.com)

[![Nextflow](https://img.shields.io/badge/version-%E2%89%A525.10.4-green?style=flat&logo=nextflow&logoColor=white&color=%230DC09D&link=https%3A%2F%2Fnextflow.io)](https://www.nextflow.io/)
[![nf-core template version](https://img.shields.io/badge/nf--core_template-4.1.0-green?style=flat&logo=nfcore&logoColor=white&color=%2324B064&link=https%3A%2F%2Fnf-co.re)](https://github.com/nf-core/tools/releases/tag/4.1.0)
[![run with conda](http://img.shields.io/badge/run%20with-conda-3EB049?labelColor=000000&logo=anaconda)](https://docs.conda.io/en/latest/)
[![run with docker](https://img.shields.io/badge/run%20with-docker-0db7ed?labelColor=000000&logo=docker)](https://www.docker.com/)
[![run with singularity](https://img.shields.io/badge/run%20with-singularity-1d355c.svg?labelColor=000000)](https://sylabs.io/docs/)
[![Launch on Seqera Platform](https://img.shields.io/badge/Launch%20%F0%9F%9A%80-Seqera%20Platform-%234256e7)](https://cloud.seqera.io/launch?pipeline=https://github.com/nf-core/rnaseqischebeckstueber)

[![Get help on Slack](http://img.shields.io/badge/slack-nf--core%20%23rnaseqischebeckstueber-4A154B?labelColor=000000&logo=slack)](https://nfcore.slack.com/channels/rnaseqischebeckstueber)
[![Follow on Bluesky](https://img.shields.io/badge/bluesky-%40nf__core-1185fe?labelColor=000000&logo=bluesky)](https://bsky.app/profile/nf-co.re)
[![Follow on Mastodon](https://img.shields.io/badge/mastodon-nf__core-6364ff?labelColor=FFFFFF&logo=mastodon)](https://mstdn.science/@nf_core)
[![Watch on YouTube](http://img.shields.io/badge/youtube-nf--core-FF0000?labelColor=000000&logo=youtube)](https://www.youtube.com/c/nf-core)

## Introduction

This RNA-seq pipeline was developed using [Nextflow](https://www.nextflow.io/) and the [nf-core](https://nf-co.re/) pipeline template. It processes single-end and paired-end RNA-seq FASTQ reads, performs quality control and preprocessing, removes ribosomal RNA reads, and quantifies transcript abundance using Salmon. It then generates transcript- and gene-level expression matrices using tximport/tximeta.

The pipeline produces QC reports, expression matrices, and a MultiQC report containing a table of the 20 genes with the highest mean TPM across samples. It does not currently perform differential expression analysis.

## Pipeline overview

The metro map below provides a schematic overview of our custom RNA-seq pipeline, illustrating read preprocessing, quality control, reference preparation, Salmon-based transcript quantification, gene-level expression analysis, and MultiQC reporting.

![RNA-seq pipeline metro map](metro_horizontal_final.svg)

The visualization was generated using `nf-metro`. The corresponding source file is available in [`metro_horizontal.mmd`](metro_horizontal.mmd).

## Pipeline steps

1. Concatenate FASTQ files belonging to the same sample using `CAT_FASTQ`.
2. Check raw reads with [FastQC](https://www.bioinformatics.babraham.ac.uk/projects/fastqc/).
3. Trim adapters and low-quality bases using [fastp](https://github.com/OpenGene/fastp).
4. Run FastQC on trimmed reads.
5. Remove rRNA reads using [RiboDetector](https://github.com/hzi-bifo/RiboDetector).
6. Run FastQC on rRNA-filtered reads.
7. Prepare the reference by filtering the GTF annotation, extracting transcript sequences with [GFFRead](https://github.com/gpertea/gffread), and building a Salmon index.
8. Quantify transcript abundance using [Salmon](https://salmon.readthedocs.io/). Library strandedness is automatically detected by Salmon if not specified.
9. Generate transcript- and gene-level expression matrices using [tximport](https://bioconductor.org/packages/tximport/) / [tximeta](https://bioconductor.org/packages/tximeta/).
10. Calculate the 20 genes with the highest mean TPM across samples (`GENE_ABUNDANCE`).
11. Combine QC results, pipeline parameters, software versions, and the gene abundance summary in [MultiQC](https://multiqc.info/).

## Usage

### Requirements

- Nextflow 25.10.4 or later, subject to the version requirement in `nextflow.config`.
- A supported software environment, such as Docker.
- A samplesheet with FASTQ inputs, and a matching genome FASTA and GTF annotation.

### Input samplesheet

The samplesheet is a CSV file containing sample names and paths to gzip-compressed FASTQ files.

Paired-end example (`samplesheet.csv`):

```csv
sample,fastq_1,fastq_2
sample1,data/sample1_R1.fastq.gz,data/sample1_R2.fastq.gz
sample2,data/sample2_R1.fastq.gz,data/sample2_R2.fastq.gz
```

Single-end example:

```csv
sample,fastq_1
sample1,data/sample1.fastq.gz
sample2,data/sample2.fastq.gz
```

- `sample`: sample name without spaces.
- `fastq_1`: required path to the first FASTQ file.
- `fastq_2`: optional path to the second FASTQ file for paired-end data.
- `strandedness`: optional column with `forward`, `reverse`, `unstranded`, or `auto`. If omitted, left empty, or set to `auto`, Salmon automatically detects the library type during quantification.

Files must end in `.fastq.gz` or `.fq.gz`. Multiple rows can have the same sample name when reads from more than one run belong to the same sample.

A genome FASTA (`--fasta`) and a matching GTF annotation (`--gtf`) are also required. Use an uncompressed FASTA file with the current implementation of `FILTER_GTF`. Alternatively, `--genome` can select a reference configured in `conf/igenomes.config`.

### Run the pipeline

From the root of the cloned repository:

```bash
nextflow run . \
  -profile docker \
  --input samplesheet.csv \
  --fasta reference.fa \
  --gtf annotation.gtf \
  --outdir results
```

Replace the example paths with your files. To resume a previous run, add `-resume`; this reuses successfully completed tasks when their cache and work files are still available.

### Run the included test

The repository contains a small test dataset configured in `conf/test.config`. Run it from the repository root with:

```bash
nextflow run . -profile test,docker --outdir test_results
```

The test profile uses small public FASTQ files and reference files from the nf-core test datasets. It tests pipeline execution but is not a substitute for analysis of a full experimental dataset.

For more information, see [usage documentation](docs/usage.md).


## Pipeline output

Results are saved under the directory specified with `--outdir`. The main outputs are:

- **Quality control and preprocessing:** FastQC reports for raw, trimmed, and rRNA-filtered reads; fastp statistics; and RiboDetector-filtered reads.
- **Reference preparation:** filtered GTF annotation, transcript FASTA, Salmon index, and transcript-to-gene mapping.
- **Transcript quantification:** Salmon quantification files, mapping statistics, and library-type information for each sample.
- **Transcript expression matrices:** `*.transcript_counts.tsv`, `*.transcript_tpm.tsv`, and `*.transcript_lengths.tsv`.
- **Gene expression matrices:** `*.gene_counts.tsv`, `*.gene_tpm.tsv`, `*.gene_lengths.tsv`, `*.gene_counts_length_scaled.tsv`, and `*.gene_counts_scaled.tsv`.
- **Gene abundance summary:** `gene_abundance_mqc.tsv`, containing the 20 genes with the highest mean TPM across samples.
- **MultiQC:** `multiqc/multiqc_report.html`, combining quality metrics and the gene abundance summary.
- **Execution information:** reports, timeline, trace, workflow DAG, parameters, and software-version information in `pipeline_info/`.

The expression matrices are produced using tximport/tximeta. Output subdirectories correspond to process names; examples include `fastqc_raw/`, `fastp/`, `ribodetector/`, `salmon_quant/`, and `tximeta_tximport/`.

For details on the outputs, see [output documentation](docs/output.md).

## Credits

Developed by **Alexa Ischebeck** and **Cleo Stüber** for the *Computational Workflows for Biomedical Data* course (2026), using the nf-core pipeline template and existing nf-core modules.

## Contributions and Support

If you would like to contribute to this pipeline, please see the [contributing guidelines](docs/CONTRIBUTING.md).

## Citations

> **The nf-core framework for community-curated bioinformatics pipelines.**
>
> Philip Ewels, Alexander Peltzer, Sven Fillinger, Harshil Patel, Johannes Alneberg, Andreas Wilm, Maxime Ulysse Garcia, Paolo Di Tommaso & Sven Nahnsen.
>
> _Nat Biotechnol._ 2020 Feb 13. doi: [10.1038/s41587-020-0439-x](https://dx.doi.org/10.1038/s41587-020-0439-x).
