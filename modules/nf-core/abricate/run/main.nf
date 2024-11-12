process ABRICATE_RUN {
    tag "$meta.id"
    label 'process_medium'

    conda "${moduleDir}/environment.yml"
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/abricate%3A1.0.1--ha8f3691_1':
        'biocontainers/abricate:1.0.1--ha8f3691_1' }"

    input:
    tuple val(meta), path(assembly)
    val db_name_or_path
    
    output:
    tuple val(meta), path("${meta.id}_abricate.tsv"), emit: report
    path "versions.yml"           , emit: versions

    when:
    task.ext.when == null || task.ext.when   

    script:
    def args = task.ext.args ?: ''
    def prefix = task.ext.prefix ?: "${meta.id}"
    //def datadir = databasedir ? "--datadir ${databasedir}" : ''
    //def db_option = db_name_or_path.contains('/') ? "--datadir ${db_name_or_path}" : "--db ${db_name_or_path}"
    def db_option = db_name_or_path.toString().contains('/') ? "--datadir ${db_name_or_path}" : "--db ${db_name_or_path}"
    """
    echo "Debug: Running Abricate for sample ${meta.id}"
    echo "Debug: Assembly file: ${assembly}"
    echo "Debug: Database option: ${db_option}"

    abricate $args $db_option $assembly > ${meta.id}_abricate.tsv
    echo "Debug: Abricate completed for sample ${meta.id}"
    echo "Debug: Abricate output:"
    cat ${meta.id}_abricate.tsv | head -n 5

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        abricate: \$(echo \$(abricate --version 2>&1) | sed 's/^.*abricate //' )
    END_VERSIONS
    """

    
}
