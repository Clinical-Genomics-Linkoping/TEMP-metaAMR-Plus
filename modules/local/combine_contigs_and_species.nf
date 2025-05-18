process COMBINE_CONTIGS_AND_SPECIES {
    tag "$meta.id"
    label 'process_medium'
    
    
    conda "conda-forge::python=3.8"
    container "quay.io/biocontainers/python:3.8"

    input:
    tuple val(meta), path(centrifuge_results), path(centrifuge_report)

    output:
    tuple val(meta), path("${meta.id}_contigs_species.tsv"), emit: contigs_species_table
    path "versions.yml", emit: versions
    

    script:
    """
    chmod +x ${workflow.projectDir}/bin/combine_contigs_and_species.py
    ${workflow.projectDir}/bin/combine_contigs_and_species.py ${centrifuge_results} ${centrifuge_report} ${meta.id}_contigs_species.tsv

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        python: \$(python --version | sed 's/Python //g')
    END_VERSIONS
    """
}
