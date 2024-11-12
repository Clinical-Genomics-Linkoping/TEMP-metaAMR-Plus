process RACON {
    tag "$meta.id"
    label 'process_high'

    conda "${moduleDir}/environment.yml"
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/racon:1.4.20--h9a82719_1' :
        'biocontainers/racon:1.4.20--h9a82719_1' }"

    input:
    tuple val(meta), path(reads), path(assembly), path(paf)
    val racon_round

    output:
    tuple val(meta), path("${meta.id}_racon${racon_round}_assembly.fasta.gz"), emit: improved_assembly
    path "versions.yml"                                                      , emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def args = task.ext.args ?: ''
    def prefix = task.ext.prefix ?: "${meta.id}"
    """
    echo "Debug: Starting RACON process round ${racon_round}"
    echo "Input reads: $reads"
    echo "Input assembly: $assembly"
    echo "Input PAF: $paf"

    racon \\
        -t $task.cpus \\
        $args \\
        "$reads" \\
        "$paf" \\
        "$assembly" \\
        > ${prefix}_racon${racon_round}_assembly.fasta

    echo "Debug: RACON completed. Checking output."
    ls -l

    if [ -f "${prefix}_racon${racon_round}_assembly.fasta" ]; then
        echo "Debug: ${prefix}_racon${racon_round}_assembly.fasta exists. Compressing."
        gzip -f ${prefix}_racon${racon_round}_assembly.fasta
    else
        echo "Error: ${prefix}_racon${racon_round}_assembly.fasta was not created by RACON"
        exit 1
    fi

    echo "Debug: Final directory contents:"
    ls -l

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        racon: \$(racon --version 2>&1 | sed 's/^.*v//')
    END_VERSIONS
    """
}