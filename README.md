# Computational Workflows – RNA-seq Pipeline

This repository contains the RNA-seq pipeline developed by Alexa Ischebeck and Cleo Stüber for the *Computational Workflows for Biomedical Data* course (2026).

The pipeline uses Nextflow and nf-core modules for RNA-seq quality control, preprocessing, and Salmon-based transcript quantification.


## Running the pipeline

The Nextflow pipeline is located in the `nf-core-rnaseqischebeckstueber/` subdirectory.

To run the pipeline, first navigate into this directory:

```bash
cd nf-core-rnaseqischebeckstueber
```

The pipeline can then be executed with a test profile using Nextflow:

```bash
nextflow run . -profile test,docker --outdir <results>
```
Example results generated with the pipeline are available in the [example_output](example_output/) directory.

For detailed usage instructions, parameters, and outputs, see the **[pipeline documentation](nf-core-rnaseqischebeckstueber/README.md)**.
