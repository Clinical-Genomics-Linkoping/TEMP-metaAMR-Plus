process MERGE_TOOL_TABLES {
    tag "$sample_id"
    label 'process_low'

    conda "conda-forge::python=3.9 pandas=1.4.3"
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/pandas:1.4.3' :
        'quay.io/biocontainers/pandas:1.4.3' }"

    input:
    tuple val(sample_id), path(centrifuge_dir), path(resfinder_dir) , path(amrfinderplus_dir) , path(plasmidfinder_dir)

    output:
    path "${sample_id}_merged_summary.tsv", emit: merged
    path "versions.yml", emit: versions

    script:
    """
    python3 ${projectDir}/bin/merge_tool_tables_by_contig.py \\
        --sample ${sample_id} \\
        --centrifuge_dir ${centrifuge_dir} \\
        --resfinder_dir ${resfinder_dir} \\
        --amrfinderplus_dir ${amrfinderplus_dir} \\
        --plasmidfinder_dir ${plasmidfinder_dir} \\
        --output ${sample_id}_merged_summary.tsv

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        python: \$(python3 --version 2>&1 | sed 's/Python //')
        pandas: \$(python3 -c "import pandas as pd; print(pd.__version__)")
    END_VERSIONS
    """

    stub:
    """
    touch ${sample_id}_merged_summary.tsv
    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        python: stub
        pandas: stub
    END_VERSIONS
    """
}