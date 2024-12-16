/*process PLASMIDFINDER {
    tag "$meta.id"
    label 'process_low'

    conda "${moduleDir}/environment.yml"
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/plasmidfinder:2.1.6--py310hdfd78af_1':
        'biocontainers/plasmidfinder:2.1.6--py310hdfd78af_1' }"

    input:
    tuple val(meta), path(seqs)
    path plasmidfinder_db

    output:
    tuple val(meta), path("*.json")                 , emit: json
    tuple val(meta), path("*.txt")                  , emit: txt
    tuple val(meta), path("*.tsv")                  , emit: tsv
    tuple val(meta), path("*-hit_in_genome_seq.fsa"), emit: genome_seq
    tuple val(meta), path("*-plasmid_seqs.fsa")     , emit: plasmid_seq
    path "versions.yml"                             , emit: versions

    script:
    def args = task.ext.args ?: ''
    def prefix = task.ext.prefix ?: "${meta.id}"

    """
    plasmidfinder.py \\
        $args \\
        -i $seqs \\
        -o ./ \\
        -p $plasmidfinder_db \\
        -x

    # Rename hard-coded outputs with prefix to avoid name collisions
    mv data.json ${prefix}.json || true
    mv results.txt ${prefix}.txt || true
    mv results_tab.tsv ${prefix}.tsv || true
    mv Hit_in_genome_seq.fsa ${prefix}-hit_in_genome_seq.fsa || true
    mv Plasmid_seqs.fsa ${prefix}-plasmid_seqs.fsa || true

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        plasmidfinder: \$(plasmidfinder.py --version 2>&1 | sed 's/^.*plasmidfinder //')
    END_VERSIONS
    """
}*/
process PLASMIDFINDER {
    tag "$meta.id"
    label 'process_low'

    conda "${moduleDir}/environment.yml"
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/plasmidfinder:2.1.6--py310hdfd78af_1':
        'biocontainers/plasmidfinder:2.1.6--py310hdfd78af_1' }"

    input:
    tuple val(meta), path(seqs)
    path plasmidfinder_db

    output:
    tuple val(meta), path("*.json")                 , emit: json
    tuple val(meta), path("*.txt")                  , emit: txt
    tuple val(meta), path("*.tsv")                  , emit: tsv
    tuple val(meta), path("*-hit_in_genome_seq.fsa"), emit: genome_seq, optional: true
    tuple val(meta), path("*-plasmid_seqs.fsa")     , emit: plasmid_seq, optional: true
    path "versions.yml"                             , emit: versions

    script:
    def args = task.ext.args ?: ''
    def prefix = task.ext.prefix ?: "${meta.id}"

    """
    echo "Debug: Input sequence file: $seqs"
    echo "Debug: PlasmidFinder database path: $plasmidfinder_db"
    echo "Debug: Output prefix: $prefix"

    if [ ! -f "$seqs" ]; then
        echo "Error: Input sequence file does not exist: $seqs" >&2
        exit 1
    fi

    if [ ! -d "$plasmidfinder_db" ]; then
        echo "Error: PlasmidFinder database directory does not exist: $plasmidfinder_db" >&2
        exit 1
    fi

    plasmidfinder.py \\
        $args \\
        -i $seqs \\
        -o ./ \\
        -p $plasmidfinder_db \\
        -x

    echo "Debug: PlasmidFinder command completed"

    # Rename hard-coded outputs with prefix to avoid name collisions
    mv data.json ${prefix}.json || echo "Warning: data.json not found"
    mv results.txt ${prefix}.txt || echo "Warning: results.txt not found"
    mv results_tab.tsv ${prefix}.tsv || echo "Warning: results_tab.tsv not found"
    mv Hit_in_genome_seq.fsa ${prefix}-hit_in_genome_seq.fsa || echo "Warning: Hit_in_genome_seq.fsa not found"
    mv Plasmid_seqs.fsa ${prefix}-plasmid_seqs.fsa || echo "Warning: Plasmid_seqs.fsa not found"

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        plasmidfinder: \$(plasmidfinder.py --version 2>&1 | grep -oP '\\d+\\.\\d+\\.\\d+' || echo "unknown")
    END_VERSIONS
    """
}