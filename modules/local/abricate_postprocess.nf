process ABRICATE_POSTPROCESS {
    tag "$meta.id"
    label 'process_low'

    conda "conda-forge::python=3.9 pandas=1.4.3"
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/pandas:1.4.3' :
        'quay.io/biocontainers/pandas:1.4.3' }"

    input:
    tuple val(meta), path(harmonized_abricate)

    output:
    tuple val(meta), path("${meta.id}_abricate_summary.tsv"), emit: summary
    path "versions.yml", emit: versions

    script:
    """
    python3 ${projectDir}/bin/postprocess_abricate.py \\
        --input ${harmonized_abricate} \\
        --output ${meta.id}_abricate_summary.tsv

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        python: \$(python3 --version 2>&1 | sed 's/Python //')
        pandas: \$(python3 -c "import pandas as pd; print(pd.__version__)")
    END_VERSIONS
    """

    stub:
    """
    touch ${meta.id}_abricate_summary.tsv
    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        python: stub
        pandas: stub
    END_VERSIONS
    """
}