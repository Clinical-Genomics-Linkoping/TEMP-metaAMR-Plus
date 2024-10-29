process SAMTOOLS_VIEW {
    tag "$meta.id"
    label 'process_low'

    conda "${moduleDir}/environment.yml"
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/samtools:1.21--h50ea8bc_0' :
        'biocontainers/samtools:1.21--h50ea8bc_0' }"

    //publishDir "${params.outdir}/${task.process.replaceAll(":","_")}", mode: 'copy', overwrite: true
    publishDir "${params.outdir}/analysis_ready_fastqs", mode: 'copy', overwrite: true
    input:
    tuple val(meta), path(input), path(index)
    tuple val(meta2), path(fasta)
    path qname

    output:
    
    tuple val(meta), path("${prefix}.bam"),                                    emit: samtools_bam,              optional: true
    tuple val(meta), path("${prefix}.cram"),                                   emit: cram,             optional: true
    tuple val(meta), path("${prefix}.sam"),                                    emit: sam,              optional: true
    tuple val(meta), path("${prefix}.${file_type}.bai"),                       emit: bai,              optional: true
    tuple val(meta), path("${prefix}.${file_type}.csi"),                       emit: csi,              optional: true
    tuple val(meta), path("${prefix}.${file_type}.crai"),                      emit: crai,             optional: true
    tuple val(meta), path("${prefix}.unselected.${file_type}"),                emit: unselected,       optional: true
    tuple val(meta), path("${prefix}.unselected.${file_type}.{bai,csi,crsi}"), emit: unselected_index, optional: true    
    path  "versions.yml",                                                      emit: versions
    tuple val(meta), path("*.fastq.gz") , emit: fastq

    when:
    task.ext.when == null || task.ext.when

    script:
    def args = task.ext.args ?: '-f 4'
    def args2 = task.ext.args2 ?: ''
    def prefix = task.ext.prefix ?: (meta.id ? "${meta.id}_unmapped" : "default_prefix")
    def reference = fasta ? "--reference ${fasta}" : ""
    def readnames = qname ? "--qname-file ${qname}" : ""
    def file_type = args.contains("--output-fmt sam") ? "sam" :
                args.contains("--output-fmt bam") ? "bam" :
                args.contains("--output-fmt cram") ? "cram" : 
                input.getExtension() 
    
 
    if ("$input" == "${prefix}.${file_type}") error "Input and output names are the same, use \"task.ext.prefix\" to disambiguate!"
    
    """
    samtools \\
        view \\
        --threads ${task.cpus-1} \\
        ${reference} \\
        ${readnames} \\
        $args \\
        -o ${prefix}.${file_type} \\
        $input \\
        $args2

    samtools \\
        fastq \\
        $args \\
        --threads ${task.cpus-1} \\
        ${input} > ${prefix}.fastq.gz

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        samtools: \$(echo \$(samtools --version 2>&1) | sed 's/^.*samtools //; s/Using.*\$//')
    END_VERSIONS
    """
 
}
