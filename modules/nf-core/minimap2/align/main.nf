process MINIMAP2_ALIGN {
    tag "$meta.id"
    label 'process_high'

    // Note: the versions here need to match the versions used in the mulled container below and minimap2/index
    conda "${moduleDir}/environment.yml"
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/mulled-v2-66534bcbb7031a148b13e2ad42583020b9cd25c4:3161f532a5ea6f1dec9be5667c9efc2afdac6104-0' :
        'biocontainers/mulled-v2-66534bcbb7031a148b13e2ad42583020b9cd25c4:3161f532a5ea6f1dec9be5667c9efc2afdac6104-0' }"

    input:
    tuple val(meta), path(reads)
    //path reference
    path reference
    val bam_format
    val cigar_paf_format
    val cigar_bam

    output:
    tuple val(meta), path("*.paf")                       , optional: true, emit: paf
    tuple val(meta), path("*.bam")                       , optional: true, emit: bam
    path "versions.yml"                                  , emit: versions

    when:
    task.ext.when == null || task.ext.when
    
script:
def args  = task.ext.args ?: ''
def prefix = task.ext.prefix ?: "${meta.id}"
def bam_output = bam_format ? "-a | samtools sort | samtools view -@ ${task.cpus} -b -h -o ${prefix}.bam" : "-o ${prefix}.paf"
def cigar_paf = cigar_paf_format && !bam_format ? "-c" : ''
def set_cigar_bam = cigar_bam && bam_format ? "-L" : ''

"""
echo "Variables before running minimap2:"
echo "BAM Format: $bam_format"
echo "Cigar PAF Format: $cigar_paf_format"
echo "Cigar BAM: $cigar_bam"
echo "Prefix: $prefix"
echo "CPUs: $task.cpus"
echo "Args: $args"

if [[ -z "$reference" || -z "$reads" ]]; then
    echo "Error: index or reads are missing."
    exit 1
fi

echo "Running minimap2 with the following command:"

minimap2 \\
    $args \\
    -t $task.cpus \\
    "$reference" \\
    "$reads" \\
    $cigar_paf \\
    $set_cigar_bam \\
    $bam_output

cat <<-END_VERSIONS > versions.yml
"NFCORE_METAAMR:METAAMR:READS_HOSTREMOVAL:MINIMAP2_ALIGN":
    minimap2: \$(minimap2 --version 2>&1)
END_VERSIONS
"""

}

