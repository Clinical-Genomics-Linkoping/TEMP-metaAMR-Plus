process PLASMIDFINDER_RUN {
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
    tuple val(meta), path("*_plasmidfinder.json"), emit: json, optional: true
    tuple val(meta), path("*_plasmidfinder.txt"), emit: txt, optional: true
    tuple val(meta), path("*_plasmidfinder.tsv"), emit: tsv, optional: true
    tuple val(meta), path("*_hit_in_genome_seq.fsa"), emit: genome_seq, optional: true
    tuple val(meta), path("*_plasmid_seqs.fsa"), emit: plasmid_seq, optional: true
    path "versions.yml", emit: versions

    script:
    def args = task.ext.args ?: ''
    def prefix = task.ext.prefix ?: "${meta.id}"
    if (!prefix) {
        prefix = "sample"
    }

    """
    set -e
    

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

    
    cp data.json ${prefix}_plasmidfinder.json || echo "Warning: data.json not found"
    cp results.txt ${prefix}_plasmidfinder.txt || echo "Warning: results.txt not found"
    cp results_tab.tsv ${prefix}_plasmidfinder.tsv || echo "Warning: results_tab.tsv not found"
    cp Hit_in_genome_seq.fsa ${prefix}_hit_in_genome_seq.fsa || echo "Warning: Hit_in_genome_seq.fsa not found"
    cp Plasmid_seqs.fsa ${prefix}_plasmid_seqs.fsa || echo "Warning: Plasmid_seqs.fsa not found"

    # List directory contents 
    ls -l

    # Get PlasmidFinder version and sanitize it
    PLASMIDFINDER_VERSION=\$(plasmidfinder.py --version 2>&1 | sed 's/^.*PlasmidFinder //' | tr -d '\\n' | tr -d '\\r' || echo "unknown")
    

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        plasmidfinder: "\${PLASMIDFINDER_VERSION}"
    END_VERSIONS

    
    """
}