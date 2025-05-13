process FILTER_READS_BY_SPECIES {
    tag "$meta.id"
    label 'process_medium'

    conda "conda-forge::python=3.8.3"
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/python:3.8.3' :
        'quay.io/biocontainers/python:3.8.3' }"

    input:
    tuple val(meta), path(centrifuge_report), path(centrifuge_results)
    val target_species

    output:
    tuple val(meta), path("*.filtered_reads.txt"), emit: filtered_read_ids
    tuple val(meta), path("*.species_summary.txt"), emit: species_summary
    path "versions.yml", emit: versions
    path "*.log", emit: log

    script:
    def args = task.ext.args ?: ''
    def prefix = task.ext.prefix ?: "${meta.id}"
    def species_arg = target_species ? "'${target_species}'" : ''
    """
    echo "Current directory: \$PWD"
    echo "Contents of current directory:"
    ls -la
    echo "PATH: \$PATH"
    which python3
    which filter_reads_by_species.py
    
    python3 \$(which filter_reads_by_species.py) \\
        ${centrifuge_report} \\
        ${centrifuge_results} \\
        ${prefix}.filtered_reads.txt \\
        ${prefix}.species_summary.txt \\
        ${species_arg} 2> ${prefix}.log

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        python: \$(python3 --version | sed 's/Python //g')
    END_VERSIONS
    """
}