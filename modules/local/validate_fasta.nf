process VALIDATE_FASTA {
    tag "$meta.id"
    label 'process_low'

    input:
    tuple val(meta), path(fasta)

    output:
    tuple val(meta), path("${meta.id}_validated.fasta"), emit: validated_fasta
    path "versions.yml", emit: versions

    script:
    def input_file = "${meta.id}_input.fasta"
    """
    # Validate that the input FASTA file exists
    if [ ! -f "${fasta}" ]; then
        echo "Error: FASTA input file does not exist or is missing" >&2
        exit 1
    fi

    # Check if the file is gzipped and decompress if necessary
    if [[ "${fasta}" == *.gz ]]; then
        gunzip -c "${fasta}" > "${input_file}"
    else
        cp "${fasta}" "${input_file}"
    fi

    # Debugging output
    echo "Contents of input file (before processing):"
    head -n 10 "${input_file}"

    # Sanitize headers
    awk '/^>/ {print ">contig_" ++i} !/^>/ {print}' "${input_file}" > "${meta.id}_validated.fasta"

    # Validate that the sanitized FASTA starts with '>'
    if [[ ! -s "${meta.id}_validated.fasta" ]] || [[ "\$(head -c 1 "${meta.id}_validated.fasta")" != ">" ]]; then
        echo "Error: Invalid FASTA file after validation" >&2
        exit 1
    fi

    echo "Contents of validated FASTA file:"
    head -n 10 "${meta.id}_validated.fasta"

    # Record software version
    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        bash: \$(bash --version | head -n 1 | awk '{print \$4}')
    END_VERSIONS
    """
}