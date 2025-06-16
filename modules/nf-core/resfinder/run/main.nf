process RESFINDER_RUN {
    tag "$meta.id"
    label 'process_medium'

    conda "${moduleDir}/environment.yml"
    container "${workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/resfinder:4.1.11--hdfd78af_0' :
        'biocontainers/resfinder:4.1.11--hdfd78af_0'}"

    input:
    tuple val(meta), path(reads), path(assembly), path(db), val(args)

    output:
    tuple val(meta), path("${meta.id}/${meta.id}-ResFinder_results_table.txt"), emit: table
    tuple val(meta), path("${meta.id}/${meta.id}-*.json"), emit: json
    tuple val(meta), path("${meta.id}/${meta.id}-*.fsa"), emit: fsa
    tuple val(meta), path("${meta.id}/${meta.id}-*.txt"), emit: txt
    tuple val(meta), path("${meta.id}/${meta.id}-*"), emit: all_outputs
    path "versions.yml", emit: versions

    script:
    def prefix = task.ext.prefix ?: "${meta.id}"

    // Ensure correct input handling: Decompress assembly 
    def decompressed_assembly = assembly.toString().endsWith('.gz') ? "decompressed_${meta.id}.fasta" : assembly
    def decompress_cmd = assembly.toString().endsWith('.gz') ? "gunzip -c ${assembly} > ${decompressed_assembly}" : ""

    // Define the correct input command for ResFinder
    def input_cmd = reads ? "-ifq ${reads}" : "-ifa ${decompressed_assembly}"
    def extra_args = args ?: ""

    """
    # Decompress assembly if needed
    ${decompress_cmd}

    # Run ResFinder
    run_resfinder.py \\
        -acq \\
        ${input_cmd} \\
        -db_res ${db} \\
        -db_point ${db} \\
        -o ${meta.id} \\
        ${extra_args}

    # Rename outputs with the sample ID prefix
    cd ${meta.id}
    for file in *; do
        if [ -f "\$file" ]; then
            mv "\$file" "${meta.id}-\$file"
        fi
    done

    if [ -d "resfinder_blast" ]; then
        mv resfinder_blast ${meta.id}-resfinder_blast
    fi
    cd ..

    # Generate the versions file
    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        resfinder: \$(run_resfinder.py --version 2>&1 | sed 's/^.*ResFinder //')
    END_VERSIONS
    """
}