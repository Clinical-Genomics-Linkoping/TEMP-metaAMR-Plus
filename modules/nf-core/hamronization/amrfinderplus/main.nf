process HAMRONIZATION_AMRFINDERPLUS {
    tag "$meta.id"
    label 'process_single'
    errorStrategy 'ignore'

    conda "${moduleDir}/environment.yml"
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/hamronization:1.1.4--pyhdfd78af_0':
        'biocontainers/hamronization:1.1.4--pyhdfd78af_0' }"

    input:
    tuple val(meta), path(report)
    val(format)
    val(software_version)
    val(reference_db_version)

    output:
    tuple val(meta), path("*.json"), optional: true, emit: json
    tuple val(meta), path("*.tsv") , optional: true, emit: tsv
    path "versions.yml"            , emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def args = task.ext.args ?: ''
    def prefix = task.ext.prefix ?: "${meta.id}_amrfinderplus"
    def software_version_arg = software_version ? "--analysis_software_version ${software_version}" : '--analysis_software_version unknown'
    def reference_db_version_arg = reference_db_version ? "--reference_database_version ${reference_db_version}" : '--reference_database_version unknown'

    """
    if [ -s "${report}" ]; then
        hamronize \\
            amrfinderplus \\
            ${report} \\
            $args \\
            --format ${format} \\
            ${software_version_arg} \\
            ${reference_db_version_arg} \\
            --input_file_name ${meta.id} \\
            > ${prefix}.${format}
    else
        echo "Input file ${report} is empty. Skipping hamronization."
        touch ${prefix}.${format}
    fi

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        hamronization: \$(echo \$(hamronize --version 2>&1) | cut -f 2 -d ' ' )
    END_VERSIONS
    """

    stub:
    def prefix = task.ext.prefix ?: "${meta.id}"
    """
    touch ${prefix}.tsv
    touch ${prefix}.json

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        hamronization: \$(echo \$(hamronize --version 2>&1) | cut -f 2 -d ' ' )
    END_VERSIONS
    """
}
