/*process SUMMARIZE_BY_CONTIG {
    tag "$meta.id"
    label 'process_low'

    conda "conda-forge::python=3.9 pandas=1.4.3"
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/pandas:1.4.3' :
        'quay.io/biocontainers/pandas:1.4.3' }"

    input:
    tuple val(meta), path(input_dir)
    val tools

    output:
    tuple val(meta), path("*_summary.tsv"), emit: summary
    path "versions.yml"                   , emit: versions

    script:
    def args = task.ext.args ?: ''
    def prefix = task.ext.prefix ?: "${meta.id}"
    """
    summarize_by_contig.py \\
        --sample ${prefix} \\
        --tools ${tools} \\
        --input-dir ${input_dir} \\
        --output ${prefix}_summary.tsv \\
        $args

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        python: \$(python --version | sed 's/Python //g')
        pandas: \$(python -c "import pandas; print(pandas.__version__)")
    END_VERSIONS
    """
}*/
process SUMMARIZE_BY_CONTIG {
    tag "$meta.id"
    label 'process_low'

    conda "conda-forge::python=3.9 pandas=1.4.3"
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/pandas:1.4.3' :
        'quay.io/biocontainers/pandas:1.4.3' }"

    publishDir "${params.summary_outdir}", mode: 'copy'

    input:
    tuple val(meta), path(input_files)
    val tools

    output:
    tuple val(meta), path("${prefix}_summary.tsv"), emit: summary
    path "versions.yml"                           , emit: versions

    script:
    def args = task.ext.args ?: ''
    prefix = task.ext.prefix ?: "${meta.id}"
    """
    summarize_by_contig.py \\
        --sample ${prefix} \\
        --tools ${tools} \\
        --input-dir . \\
        --output ${prefix}_summary.tsv \\
        $args

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        python: \$(python --version | sed 's/Python //g')
        pandas: \$(python -c "import pandas; print(pandas.__version__)")
    END_VERSIONS
    """

    stub:
    prefix = task.ext.prefix ?: "${meta.id}"
    """
    touch ${prefix}_summary.tsv
    
    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        python: \$(python --version | sed 's/Python //g')
        pandas: \$(python -c "import pandas; print(pandas.__version__)")
    END_VERSIONS
    """
}
