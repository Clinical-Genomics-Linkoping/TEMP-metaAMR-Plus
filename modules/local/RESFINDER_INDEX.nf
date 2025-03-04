process RESFINDER_INDEX {
    tag "resfinder_index"
    label 'process_medium'

    conda "${moduleDir}/environment.yml"
    container "${workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/resfinder:4.1.11--hdfd78af_0' :
        'biocontainers/resfinder:4.1.11--hdfd78af_0'}"

    input:
    path(db)

    output:
    path("${db}/*"), emit: indexed_db

    script:
    """
    cd $db

    # Check if indexing is needed
    if ls *.length.b 1> /dev/null 2>&1; then
        echo "ResFinder database is already indexed. Skipping indexing step."
    else
        echo "Indexing ResFinder database with KMA..."
        for file in *.fsa; do
            base=\$(basename "\$file" .fsa)
            echo "Indexing \$base..."
            kma index -i "\$file" -o "\$base"
        done
        echo "Indexing complete."
    fi
    """
}
