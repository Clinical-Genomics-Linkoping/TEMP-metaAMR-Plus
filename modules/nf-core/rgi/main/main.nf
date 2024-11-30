
process RGI_MAIN {
    tag "$meta.id"
    label 'process_medium'

    conda "${moduleDir}/environment.yml"
    container "${workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/rgi:6.0.3--pyha8f3691_1' :
        'biocontainers/rgi:6.0.3--pyha8f3691_1'}"

    input:
    tuple val(meta), path(fasta)
    path(card)
    path(wildcard)

    output:
    tuple val(meta), path("${prefix}.json"), emit: json
    tuple val(meta), path("${prefix}.txt"), emit: tsv
    tuple val(meta), path("${prefix}_temp/"), emit: tmp
    path "versions.yml", emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def args = task.ext.args ?: '' // Customizes the command for `rgi load`
    def args2 = task.ext.args ?: '' // Customizes the command for `rgi main`
    prefix = task.ext.prefix ?: "${meta.id}"
    def load_wildcard = ""

    // Conditional addition of wildcard arguments
    if (wildcard) {
        load_wildcard = """
            --wildcard_annotation ${wildcard}/wildcard_database_v\$DB_VERSION.fasta \\
            --wildcard_annotation_all_models ${wildcard}/wildcard_database_v\$DB_VERSION\\_all.fasta \\
            --wildcard_index ${wildcard}/wildcard/index-for-model-sequences.txt \\
            --amr_kmers ${wildcard}/wildcard/all_amr_61mers.txt \\
            --kmer_database ${wildcard}/wildcard/61_kmer_db.json \\
            --kmer_size 61
        """
    }

    """
    # Extract database version
    DB_VERSION=\$(basename ${card}/card.json | sed "s/card.json/v1.0/")

    # Load RGI database (only if not already loaded)
    if [ ! -f "${card}/.rgi_loaded" ]; then
        rgi load \\
            $args \\
            --card_json ${card}/card.json \\
            --debug --local \\
            --card_annotation ${card}/nucleotide_fasta_protein_homolog_model.fasta \\
            --card_annotation_all_models ${card}/protein_fasta_protein_homolog_model.fasta \\
            $load_wildcard
        touch "${card}/.rgi_loaded"
    fi

    # Run RGI main
    rgi main \\
        $args2 \\
        --num_threads ${task.cpus} \\
        --output_file ${prefix} \\
        --input_sequence ${fasta}

    # Move output files to temp directory
    mkdir -p ${prefix}_temp/
    for FILE in *.xml *.fsa *.draft *.potentialGenes *{variant,rrna,protein,predictedGenes,overexpression,homolog}.json; do 
        [[ -e \$FILE ]] && mv \$FILE ${prefix}_temp/
    done

    # Record RGI version
    RGI_VERSION=\$(rgi main --version)

    # Save version info
    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        rgi: \${RGI_VERSION}
        rgi-database: \${DB_VERSION}
    END_VERSIONS
    """

    stub:
    """
    mkdir -p ${prefix}_temp
    touch ${prefix}.json
    touch ${prefix}.txt

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        rgi: stub_version
        rgi-database: stub_version
    END_VERSIONS
    """
}