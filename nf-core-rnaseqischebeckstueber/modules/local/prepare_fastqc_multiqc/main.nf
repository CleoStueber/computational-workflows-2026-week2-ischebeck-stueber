process PREPARE_FASTQC_MULTIQC {
    tag "${meta.id}"
    label 'process_single'

    conda "${moduleDir}/environment.yml"
    container "${ workflow.containerEngine in ['singularity', 'apptainer'] && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/gffread:0.12.7--hdcf5f25_4' :
        'quay.io/biocontainers/gffread:0.12.7--hdcf5f25_4' }"

    input:
    tuple val(meta), val(stage), path(fastqc_zip)

    output:
    path "fastqc_${stage}", emit: reports

    script:
    """
    mkdir -p fastqc_${stage}

    for zipfile in *_fastqc.zip; do
        sample=\$(basename "\$zipfile" _fastqc.zip)

        unzip -p "\$zipfile" '*/fastqc_data.txt' > "fastqc_${stage}/\${sample}_${stage}_fastqc_data.txt"

        sed -i.bak \
            "s/^Filename\\t.*/Filename\\t\${sample}_${stage}/" \
            "fastqc_${stage}/\${sample}_${stage}_fastqc_data.txt"

        rm -f "fastqc_${stage}/\${sample}_${stage}_fastqc_data.txt.bak"
    done
    """
}