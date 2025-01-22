process CENTRIFUGE_CENTRIFUGE {
    tag "${meta.id}"
    label 'process_high'

    conda "${moduleDir}/environment.yml"
    container "${workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container
        ? 'https://depot.galaxyproject.org/singularity/centrifuge:1.0.4.2--hdcf5f25_0'
        : 'biocontainers/centrifuge:1.0.4.2--hdcf5f25_0'}"

    input:
    tuple val(meta), path(reads)
    path db
    val save_unaligned
    val save_aligned

    output:
    tuple val(meta), path('*_centrifuge_report.txt'), emit: report
    tuple val(meta), path('*_centrifuge_results.txt'), emit: results
    tuple val(meta), path('*.{sam,tab}'), optional: true, emit: sam
    tuple val(meta), path('*.mapped.fastq{,.1,.2}.gz'), optional: true, emit: fastq_mapped
    tuple val(meta), path('*.unmapped.fastq{,.1,.2}.gz'), optional: true, emit: fastq_unmapped
    path "versions.yml", emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def args = task.ext.args ?: ''
    def prefix = task.ext.prefix ?: "${meta.id}"
    def is_fasta = reads.name.endsWith('.fasta') || reads.name.endsWith('.fasta.gz') || reads.name.endsWith('.fa') || reads.name.endsWith('.fa.gz')
    def is_gzipped = reads.name.endsWith('.gz')
    def input_command = is_gzipped ? "zcat ${reads}" : "cat ${reads}"
    def input_type = is_fasta ? "-f" : (meta.single_end ? "-U" : "-1")
    def unaligned = ''
    def aligned = ''
    if (!is_fasta) {
        if (meta.single_end) {
            unaligned = save_unaligned ? "--un-gz ${prefix}.unmapped.fastq.gz" : ''
            aligned = save_aligned ? "--al-gz ${prefix}.mapped.fastq.gz" : ''
        } else {
            unaligned = save_unaligned ? "--un-conc-gz ${prefix}.unmapped.fastq.gz" : ''
            aligned = save_aligned ? "--al-conc-gz ${prefix}.mapped.fastq.gz" : ''
        }
    }
    """
    ##  added "-no-name ._" to ensure  Mac OSX metafiles files aren't included
    db_name=`find -L ${db} -name "*.1.cf" -not -name "._*"  | sed 's/\\.1.cf\$//'`

    ##  directory for placing the pipe files in somewhere other than default /tmp
    mkdir ./temp

    ${input_command} | centrifuge \\
        -x \$db_name \\
        --temp-directory ./temp \\
        -p ${task.cpus} \\
        ${input_type} - \\
        --report-file ${prefix}_centrifuge_report.txt \\
        -S ${prefix}_centrifuge_results.txt \\
        ${unaligned} \\
        ${aligned} \\
        ${args}

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        centrifuge: \$( centrifuge --version  | sed -n 1p | sed 's/^.*centrifuge-class version //')
    END_VERSIONS
    """

    stub:
    def prefix = task.ext.prefix ?: "${meta.id}"
    """
    touch ${prefix}_centrifuge_report.txt
    touch ${prefix}_centrifuge_results.txt
    touch ${prefix}.sam
    echo | gzip -n > ${prefix}.unmapped.fastq.gz
    echo | gzip -n > ${prefix}.mapped.fastq.gz

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        centrifuge: \$( centrifuge --version  | sed -n 1p | sed 's/^.*centrifuge-class version //')
    END_VERSIONS
    """
}