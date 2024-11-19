

process RESFINDER_RUN {
    tag "$meta.id"
    label 'process_medium'
   

    conda "${moduleDir}/environment.yml"
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/resfinder:4.1.11--hdfd78af_0':
        'biocontainers/resfinder:4.1.11--hdfd78af_0' }"

    input:
    tuple val(meta), path(fastq), path(fasta)
    path db
    val args

    output:
    tuple val(meta), path("${meta.id}_resfinder_output/*.json"), emit: json
    tuple val(meta), path("${meta.id}_resfinder_output/*.fsa"), emit: fsa
    tuple val(meta), path("${meta.id}_resfinder_output/*.txt"), emit: txt
    tuple val(meta), path("${meta.id}_resfinder_output/*"), emit: all_outputs
    path "versions.yml", emit: versions


    script:
    prefix = task.ext.prefix ?: "${meta.id}"
    def input_data = fastq ? "-ifq ${fastq[0]} ${fastq[1]}" : "-ifa ${fasta}"
    def decompress_cmd = fasta.toString().endsWith('.gz') ? "gunzip -c ${fasta} > decompressed.fasta" : "cp ${fasta} decompressed.fasta"
    def fasta_input = "decompressed.fasta"
    """
    echo "Processing sample: ${meta.id}"
    ${decompress_cmd}
    
    echo "Debug: Running ResFinder command:"
    echo "run_resfinder.py -acq -ifa ${fasta_input} -db_res $db -db_point $db -o ${prefix}_resfinder_output $args"
    
    run_resfinder.py \\
        -acq \\
        -ifa ${fasta_input} \\
        -db_res $db \\
        -db_point $db \\
        -o ${prefix}_resfinder_output \\
        $args
    
    echo "Debug: ResFinder completed for ${meta.id}"
    echo "Debug: Output files:"
    ls -l ${prefix}_resfinder_output/
    
    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        resfinder: \$(run_resfinder.py --version 2>&1 | sed 's/^.*ResFinder //')
    END_VERSIONS
    """
}