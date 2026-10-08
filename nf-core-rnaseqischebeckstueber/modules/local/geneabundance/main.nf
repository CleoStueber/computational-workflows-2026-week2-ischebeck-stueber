process GENE_ABUNDANCE {
    conda "${moduleDir}/environment.yml"
    container "${ workflow.containerEngine in ['singularity', 'apptainer'] && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/gawk:5.3.0' :
        'quay.io/biocontainers/gawk:5.3.0' }"
    
    input:
    tuple val(meta), path(tpm)

    output:
    path "gene_abundance_mqc.tsv"

    script:
    """
    {
        echo "# id: gene_abundance"
        echo "# section_name: Gene abundance"
        echo "# description: Top 20 genes by mean TPM across all samples"
        echo "# plot_type: table"

        printf 'gene_id\\tmean_TPM\\n'

        awk 'BEGIN {FS=OFS="\\t"}
            NR==1 {
                first_sample = (\$2=="gene_name" ? 3 : 2)
                next
            }
            NF>=first_sample {
                sum=0
                for(i=first_sample; i<=NF; i++) sum+=\$i
                print \$1, sum/(NF-first_sample+1)
            }' ${tpm} | sort -k2,2nr | sed -n '1,20p'

    } > gene_abundance_mqc.tsv
    """
}