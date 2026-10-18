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
    if [[ "${fasta}" == *.gz ]]; then
        gzip -cd "${fasta}" > input.fasta
    else
        cp "${fasta}" input.fasta
    fi

    if [[ "${gtf}" == *.gz ]]; then
        gzip -cd "${gtf}" > input.gtf
    else
        cp "${gtf}" input.gtf
    fi

    awk '/^>/ {print substr(\$1, 2)}' input.fasta > fasta_contigs.txt

    awk 'NR==FNR {keep[\$1]; next} /^#/ || ((\$1 in keep) && /transcript_id "[^"]+"/)' \
        fasta_contigs.txt input.gtf > filtered.gtf

    test -s filtered.gtf
    """

}