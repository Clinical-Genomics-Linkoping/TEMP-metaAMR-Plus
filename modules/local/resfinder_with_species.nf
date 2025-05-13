process RESFINDER_WITH_SPECIES {
    tag "$meta.id"
    label 'process_medium'
    conda "bioconda::resfinder"
    container 'biocontainers/resfinder:4.1.11--hdfd78af_0'

    input:
    tuple val(meta), path(reads), path(species_info), path(db)

    output:
    tuple val(meta), path("${meta.id}.resfinder_results.txt"), emit: amr_results
    path "versions.yml", emit: versions

    script:
    def prefix = task.ext.prefix ?: "${meta.id}"
    def input_cmd = reads.name.toLowerCase().endsWith(".fq") || reads.name.toLowerCase().endsWith(".fastq") || reads.name.toLowerCase().endsWith(".fastq.gz")
        ? "-ifq ${reads}"
        : "-ifa ${reads}"

    """
    echo "Running ResFinder with the following parameters:"
    echo "Input: ${input_cmd}"
    echo "Database: ${db}"
    echo "Output directory: ."

    run_resfinder.py \\
        -acq \\
        ${input_cmd} \\
        -db_res ${db} \\
        -db_point ${db} \\
        -o . \\
        -l 0.6 \\
        -t 0.8

    echo "ResFinder execution completed. Checking for output file."

    resfinder_output=\$(ls *ResFinder_results_tab.txt)
    if [ -z "\$resfinder_output" ]; then
        echo "Error: ResFinder output file not found" >&2
        exit 1
    fi
    echo "Found ResFinder output file: \$resfinder_output"

    echo "Running associate_amr_with_species.py"
    associate_amr_with_species.py \$resfinder_output ${species_info} > ${meta.id}.resfinder_results.txt

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        python: \$(python --version | sed 's/Python //g')
        resfinder: \$(run_resfinder.py --version | sed 's/run_resfinder.py //')
    END_VERSIONS
    """
}