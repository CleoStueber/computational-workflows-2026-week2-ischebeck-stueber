# nf-core/rnaseqischebeckstueber: Changelog

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/)
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## v1.0.0 - 2026-10-22

Initial release of the RNA-seq workflow, created with the [nf-core](https://nf-co.re/) template.

### `Added`
- Read quality assessment with FastQC.
- Adapter trimming and quality filtering with fastp.
- Optional ribosomal RNA removal with RiboDetector.
- Transcript quantification using Salmon.
- Gene-level abundance estimation using tximport.
- Quality control reporting with MultiQC.
- Docker-based execution profiles.
- Test configurations with and without RiboDetector.
- Documentation of pipeline usage, parameters, and outputs.

### `Fixed`

### `Dependencies`

### `Deprecated`
