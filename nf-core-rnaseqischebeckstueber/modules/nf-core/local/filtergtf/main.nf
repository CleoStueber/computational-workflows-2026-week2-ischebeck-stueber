process FILTER_GTF {
    tag "reference"

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