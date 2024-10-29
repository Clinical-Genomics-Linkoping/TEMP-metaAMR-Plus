process SAMTOOLS_FASTQ {
    tag "$meta.id"
    label 'process_low'

    conda "${moduleDir}/environment.yml"
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/samtools:1.21--h50ea8bc_0' :
        'biocontainers/samtools:1.21--h50ea8bc_0' }"

    input:
    //tuple val(meta), path(input)
    tuple val(meta), path(input)
    val(interleave)
    
    output:
    tuple val(meta), path("${prefix}.fastq.gz") , optional: true, emit: fastq
    tuple val(meta), path("${prefix}_singleton.fastq.gz"), optional: true, emit: singleton
    tuple val(meta), path("${prefix}_other.fastq.gz") , optional: true, emit: other
    path "versions.yml", emit: versions
    
    /*output:
    
    tuple val(meta), path("*_{1,2}.fastq.gz")      , optional:true, emit: fastq
    tuple val(meta), path("*_interleaved.fastq")   , optional:true, emit: interleaved
    tuple val(meta), path("*_singleton.fastq.gz")  , optional:true, emit: singleton
    tuple val(meta), path("*_other.fastq.gz")      , optional:true, emit: other
    path  "versions.yml"                           , emit: versions
*/
    when: true
    
    //task.ext.when == null || task.ext.when
    

    script:
    def args = task.ext.args ?: ''
    def prefix = task.ext.prefix ?: "${meta.id}"
    
    """
    echo "Received BAM file for FASTQ conversion: ${input}"
    samtools \\
        fastq \\
        $args \\
        --threads ${task.cpus-1} \\
        -0 ${prefix}_other.fastq.gz \\
        ${input}
        

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        samtools: \$(echo \$(samtools --version 2>&1) | sed 's/^.*samtools //; s/Using.*\$//')
    END_VERSIONS
    """

    
}
