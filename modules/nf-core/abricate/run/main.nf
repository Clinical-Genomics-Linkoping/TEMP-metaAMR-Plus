
process ABRICATE_RUN {
    tag "$meta.id"
    label 'process_medium'

    conda "${moduleDir}/environment.yml"
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/abricate%3A1.0.1--ha8f3691_1':
        'biocontainers/abricate:1.0.1--ha8f3691_1' }"

    input:
    tuple val(meta), path(assembly)
    val db_name
    /*
    output:
    tuple val(meta), path("${meta.id}_abricate.tsv"), emit: report
    path "versions.yml"           , emit: versions
*/

    output:
    tuple val(meta), path("${meta.id}_abricate.tsv"), emit: report
    tuple val(meta), val("abricate"), emit: format
    tuple val(meta), val("abricate-1.0.1"), emit: software_version
    tuple val(meta), val(db_name), emit: reference_db_version
    path "versions.yml", emit: versions

    when:
    task.ext.when == null || task.ext.when   

    script:
    def args = task.ext.args ?: ''
    def prefix = task.ext.prefix ?: "${meta.id}"
    
    """
    
    abricate \\
        $args \\
        --db ${db_name} \\
        --minid ${params.abricate_minid} \\
        --mincov ${params.abricate_mincov} \\
        ${assembly} > ${prefix}_abricate.tsv


    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        abricate: \$(echo \$(abricate --version 2>&1) | sed 's/^.*abricate //' )
    END_VERSIONS
    """

    
}