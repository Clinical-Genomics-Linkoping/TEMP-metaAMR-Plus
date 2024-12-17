process PLASCLASS_POSTPROCESS {
    tag "$meta.id"
    label 'process_low'

    input:
    tuple val(meta), path(report)

    output:
    tuple val(meta), path("${meta.id}.plasclass_classified.txt"), emit: classified
    path "versions.yml", emit: versions

    script:
    def threshold = params.plasclass_threshold ?: 0.9  // Evaluate Groovy param first
    def prefix = "${meta.id}"

    """
    # Post-process PlasClass output
    awk -v threshold=${threshold} '
    BEGIN { print "Contig_ID\\tClassification" }
    { if (\$2 >= threshold) print \$1"\\tplasmid";
      else print \$1"\\tchromosome" }
    ' ${report} > ${prefix}.plasclass_classified.txt

    # Save version information
    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        plasclass_postprocess: 1.0
    END_VERSIONS
    """
}