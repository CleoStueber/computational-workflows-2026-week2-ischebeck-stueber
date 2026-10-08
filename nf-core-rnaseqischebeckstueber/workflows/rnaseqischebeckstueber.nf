/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    IMPORT MODULES / SUBWORKFLOWS / FUNCTIONS
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/
include { FASTQC as FASTQC_RAW }        from '../modules/nf-core/fastqc/main'
include { FASTQC as FASTQC_TRIMMED }    from '../modules/nf-core/fastqc/main'
include { FASTP }                       from '../modules/nf-core/fastp/main'
include { RIBODETECTOR }                from '../modules/nf-core/ribodetector/main'
include { FASTQC as FASTQC_FILTERED }   from '../modules/nf-core/fastqc/main'
include { FASTQ_SUBSAMPLE_FQ_SALMON }   from '../subworkflows/nf-core/fastq_subsample_fq_salmon/main'
include { FILTER_GTF }                  from '../modules/local/filtergtf/main'
include { GFFREAD }                     from '../modules/nf-core/gffread/main' 
include { SALMON_INDEX }                from '../modules/nf-core/salmon/index/main' 
include { SALMON_QUANT }                from '../modules/nf-core/salmon/quant/main'
include { CUSTOM_TX2GENE }              from '../modules/nf-core/custom/tx2gene/main'
include { TXIMETA_TXIMPORT }            from '../modules/nf-core/tximeta/tximport/main'
include { GENE_ABUNDANCE }              from '../modules/local/geneabundance/main'
include { MULTIQC }                     from '../modules/nf-core/multiqc/main'
include { paramsSummaryMap }            from 'plugin/nf-schema'
include { paramsSummaryMultiqc }        from '../subworkflows/nf-core/utils_nfcore_pipeline'
include { softwareVersionsToYAML }      from '../subworkflows/nf-core/utils_nfcore_pipeline'
include { methodsDescriptionText; inferStrandedness } from '../subworkflows/local/utils_nfcore_rnaseqischebeckstueber_pipeline'

/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    RUN MAIN WORKFLOW
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/

workflow RNASEQISCHEBECKSTUEBER {

    take:
    ch_samplesheet // channel: samplesheet read in from --input
    multiqc_config
    multiqc_logo
    multiqc_methods_description
    outdir
    genome_fasta
    gtf 

    main:

    def ch_versions = channel.empty()
    def ch_multiqc_files = channel.empty()
    // ---------------------------- PREPROCESSING ----------------------------
    //
    // MODULE: Run FastQC_RAW
    //
    FASTQC_RAW(ch_samplesheet)
    ch_multiqc_files = ch_multiqc_files.mix(FASTQC_RAW.out.zip.map{ _meta, file -> file })

    //
    // MODULE: Trim reads with fastp
    //
    ch_fastp_input = ch_samplesheet.map { meta, reads ->
        [meta, reads, []]
    }

    FASTP(
        ch_fastp_input,
        false, // do not discard the successfully trimmed reads
        false, // do not save the failed fastp filtering reads
        false // do not merge paired ends R1 + R2
    )

    ch_multiqc_files = ch_multiqc_files.mix(
        FASTP.out.json.map { _meta, file -> file }
    )

    //
    // MODULE: Run FastQC on trimmed reads
    //
    FASTQC_TRIMMED(FASTP.out.reads)

    ch_multiqc_files = ch_multiqc_files.mix(
        FASTQC_TRIMMED.out.zip.map { _meta, file -> file }
    )

    //
    // MODULE: RiboDetector removes rRNA from trimmed reads
    //
    ch_ribo_input = FASTP.out.reads
        .join(FASTP.out.json, failOnMismatch: true, failOnDuplicate: true)
        .map { meta, reads, json ->
            def stats = new groovy.json.JsonSlurper()
                .parseText(json.text).summary.after_filtering

            def lengths = [stats.read1_mean_length, stats.read2_mean_length]
                .findAll { it != null }

            tuple(meta, reads, Math.round(lengths.sum() / lengths.size()) as int)
        }

    RIBODETECTOR(ch_ribo_input) // CHANGED INPUT!!!! [meta, trimmed FASTQ files, calculated mean read length]

    // FastQC: quality control after rRNA removal
    FASTQC_FILTERED(RIBODETECTOR.out.fastq)

    ch_multiqc_files = ch_multiqc_files.mix(
        FASTQC_FILTERED.out.zip.map { _meta, file -> file }
    )

    //
    // MODULE: Filter GTF to contigs present in genome FASTA
    //
    FILTER_GTF(
        gtf,
        genome_fasta
    )

    ch_filtered_gtf = FILTER_GTF.out.filtered_gtf

    //
    // MODULE: Generate transcript FASTA from genome FASTA + GTF
    //
    ch_gffread_input = ch_filtered_gtf.map { gtf_file ->
        tuple([id: 'reference'], gtf_file)
    }

    GFFREAD(
        ch_gffread_input,
        genome_fasta
    )

    //
    // MODULE: Build Salmon index
    //
    ch_transcript_fasta = GFFREAD.out.gffread_fasta
        .map { meta, transcript_fasta ->
            transcript_fasta
        }
        

    ch_salmon_index_input = ch_transcript_fasta
        .combine(genome_fasta)
        .map { transcript_fasta, genome_file ->
            tuple([id: 'reference'], transcript_fasta, genome_file)
        }

    SALMON_INDEX(ch_salmon_index_input)

    //
    // SUBWORKFLOW: Infer strandedness using raw FASTQ reads
    //
    ch_index_for_inference = SALMON_INDEX.out.index
        .map { meta, index -> index }

    FASTQ_SUBSAMPLE_FQ_SALMON(
        ch_samplesheet,
        genome_fasta,
        ch_transcript_fasta,
        ch_filtered_gtf,
        ch_index_for_inference,
        false
    )

    ch_stranded_reads = FASTQ_SUBSAMPLE_FQ_SALMON.out.lib_format_counts
        .join(RIBODETECTOR.out.fastq, failOnMismatch: true, failOnDuplicate: true)
        .map { meta, json, reads ->
            tuple(meta + [strandedness: inferStrandedness(json)], reads)
        }
    
    //
    // MODULE: Quantify transcripts with Salmon
    //
    ch_salmon_quant_reference = SALMON_INDEX.out.index
        .combine(ch_filtered_gtf)
        .combine(ch_transcript_fasta)
        .map { meta, index, gtf_file, transcript_fasta ->
            tuple(meta, index, gtf_file, transcript_fasta)
        }
        .first()

    SALMON_QUANT(
        ch_stranded_reads,
        ch_salmon_quant_reference
    )

    ch_multiqc_files = ch_multiqc_files.mix(
        SALMON_QUANT.out.json_info.map { _meta, file -> file }
    )

    ch_multiqc_files = ch_multiqc_files.mix(
        SALMON_QUANT.out.lib_format_counts.map { _meta, file -> file }
    )
    
    //
    // MODULE: Create transcript-to-gene mapping
    //
    ch_tx2gene_gtf = ch_filtered_gtf.map { gtf_file ->  // take filtered GTF file and attach metadata 
        tuple([id: 'reference'], gtf_file)              // CUSTOM_TX2GENE expects tuple: [meta, gtf_file]
    }

    ch_first_salmon_result = SALMON_QUANT.out.results.first() // SALMON_QUANT produces 1 result/sample; CUSTOM_TX2GENE needs 1 Salmon result to check/match transcript IDs

    CUSTOM_TX2GENE(             // create transcript-to-gene mapping table
        ch_tx2gene_gtf,         // filtered GTF
        ch_first_salmon_result, // 1 Salmon result
        'salmon',               // quantification type = salmon
        'gene_id',              // GTF attribute used for gene ID
        'gene_name'             // GTF attribute used for gene name
    )

    //
    // MODULE: Import Salmon results with tximport
    //
    ch_salmon_quants = SALMON_QUANT.out.results // SALMON_QUANT.out.results contains:[meta, salmon_result]; remove metadata, keep only Salmon result for each sample
        .map { meta, results ->
            results
        }
        .collect()                              // collect all sample-wise Salmon results into list; tximport needs all samples together to build combined matrix
        .map { results ->                       // add metadata required by TXIMETA_TXIMPORT module
            tuple([id: 'salmon'], results)
        }

    TXIMETA_TXIMPORT(               // run tximport
        ch_salmon_quants,           // all Salmon quantification results
        CUSTOM_TX2GENE.out.tx2gene, // transcript-to-gene mapping from CUSTOM_TX2GENE
        'salmon'                    // quantification type = salmon
    )

    GENE_ABUNDANCE(TXIMETA_TXIMPORT.out.tpm_gene)

    // DE Seq 2 PCA

    ch_multiqc_files = ch_multiqc_files.mix(
        GENE_ABUNDANCE.out
    )
        
    //
    // Collate and save software versions
    //
    def topic_versions = channel.topic("versions")
        .distinct()
        .branch { entry ->
            versions_file: entry instanceof Path
            versions_tuple: true
        }

    def topic_versions_string = topic_versions.versions_tuple
        .map { process, tool, version ->
            [ process[process.lastIndexOf(':')+1..-1], "  ${tool}: ${version}" ]
        }
        .groupTuple(by:0)
        .map { process, tool_versions ->
            tool_versions.unique().sort()
            "${process}:\n${tool_versions.join('\n')}"
        }

    def ch_collated_versions = softwareVersionsToYAML(ch_versions.mix(topic_versions.versions_file))
        .mix(topic_versions_string)
        .collectFile(
            storeDir: "${outdir}/pipeline_info",
            name: 'nf_core_'  +  'rnaseqischebeckstueber_software_'  + 'mqc_'  + 'versions.yml',
            sort: true,
            newLine: true
        )

    //
    // MODULE: MultiQC
    //
    ch_multiqc_files = ch_multiqc_files.mix(ch_collated_versions)
    def ch_summary_params = paramsSummaryMap(workflow, parameters_schema: "nextflow_schema.json")
    def ch_workflow_summary = channel.value(paramsSummaryMultiqc(ch_summary_params))
    ch_multiqc_files = ch_multiqc_files.mix(ch_workflow_summary.collectFile(name: 'workflow_summary_mqc.yaml'))
    def ch_multiqc_custom_methods_description = multiqc_methods_description
        ? file(multiqc_methods_description, checkIfExists: true)
        : file("${projectDir}/assets/methods_description_template.yml", checkIfExists: true)
    def ch_methods_description = channel.value(methodsDescriptionText(ch_multiqc_custom_methods_description))
    ch_multiqc_files = ch_multiqc_files.mix(ch_methods_description.collectFile(name: 'methods_description_mqc.yaml', sort: true))
    MULTIQC(
        ch_multiqc_files.flatten().collect().map { files ->
            [
                [id: 'rnaseqischebeckstueber'],
                files,
                multiqc_config
                    ? file(multiqc_config, checkIfExists: true)
                    : file("${projectDir}/assets/multiqc_config.yml", checkIfExists: true),
                multiqc_logo ? file(multiqc_logo, checkIfExists: true) : [],
                [],
                [],
            ]
        }
    )

    emit:
        multiqc_report = MULTIQC.out.report.map { _meta, report -> [report] }.toList() // channel: /path/to/multiqc_report.html
        gene_counts    = TXIMETA_TXIMPORT.out.counts_gene
        gene_tpm       = TXIMETA_TXIMPORT.out.tpm_gene
        gene_lengths   = TXIMETA_TXIMPORT.out.lengths_gene
        
        versions       = ch_versions                 // channel: [ path(versions.yml) ]
}

/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    THE END
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/
