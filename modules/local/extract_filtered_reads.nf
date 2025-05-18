process EXTRACT_FILTERED_READS {
    tag "$meta.id"
    label 'process_medium'

    conda "bioconda::seqtk=1.3"
    container "quay.io/biocontainers/seqtk:1.3--h5bf99c6_3"

    input:
    tuple val(meta), path(read_ids), path(original_reads)

    output:
    tuple val(meta), path("*.filtered.fastq.gz"), emit: filtered_reads
    path "versions.yml", emit: versions

    script:
    def prefix = task.ext.prefix ?: "${meta.id}"
    """
    seqtk subseq ${original_reads} <(cut -f1 ${read_ids}) | gzip > ${prefix}.filtered.fastq.gz

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        seqtk: \$(seqtk 2>&1 | grep Version | sed 's/.*Version: //')
    END_VERSIONS
    """
}