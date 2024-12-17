process PLASCLASS {
    tag "$meta.id"
    label 'process_medium'
     

    conda "bioconda::plasclass=0.1.1"
    container "${workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/plasclass:0.1.1--pyhdfd78af_0' :
        'quay.io/biocontainers/plasclass:0.1.1--pyhdfd78af_0'}"

    input:
    tuple val(meta), path(fasta)

    output:
    tuple val(meta), path("*.plasclass.txt"), emit: report
    path "versions.yml"                     , emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def args = task.ext.args ?: ''
    def prefix = task.ext.prefix ?: "${meta.id}"
    """

    if [[ ${fasta} == *.gz ]]; then
        gunzip -c ${fasta} > uncompressed.fasta
        input_fasta=uncompressed.fasta
    else
        input_fasta=${fasta}
    fi

    classify_fasta.py \\
        $args \\
        -f $fasta \\
        -o ${prefix}.plasclass.txt

    
    # Save version information
    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        plasclass: \$(classify_fasta.py --version 2>&1 | grep -oP 'PlasClass \\K[0-9]+\\.[0-9]+\\.[0-9]+' || echo "unknown")
    END_VERSIONS
    """
}