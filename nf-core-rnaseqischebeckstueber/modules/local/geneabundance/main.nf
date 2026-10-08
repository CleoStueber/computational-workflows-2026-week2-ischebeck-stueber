process GENE_ABUNDANCE {

    input:
    tuple val(meta), path(tpm)

    output:
    path "gene_abundance_mqc.tsv"

    script:
    """
    {
        echo "# id: gene_abundance"
        echo "# section_name: Gene abundance"
        echo "# description: Top 20 genes by TPM"
        echo "# plot_type: table"
        head -n 1 ${tpm}
        tail -n +2 ${tpm} | sort -k3,3nr | sed -n '1,20p'
    } > gene_abundance_mqc.tsv
    """
}