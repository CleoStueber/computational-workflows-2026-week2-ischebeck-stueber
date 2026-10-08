process FILTER_GTF {
    tag "reference"

    conda "${moduleDir}/environment.yml"
    container "${ workflow.containerEngine in ['singularity', 'apptainer'] && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/gawk:5.3.0' :
        'quay.io/biocontainers/gawk:5.3.0' }"
    
    input:
    path gtf
    path fasta

    output:
    path "filtered.gtf", emit: filtered_gtf

    script:
    """
    grep '^>' ${fasta} \
        | sed 's/^>//' \
        | cut -d ' ' -f1 \
        > fasta_contigs.txt

    awk 'NR==FNR {keep[\$1]; next} /^#/ || (\$1 in keep)' \
        fasta_contigs.txt \
        ${gtf} \
        > filtered.gtf
    """
}