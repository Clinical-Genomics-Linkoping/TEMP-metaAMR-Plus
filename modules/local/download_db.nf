process DOWNLOAD_DB {
    tag "$tool"
    label 'process_high'
    label 'error_retry'
    //publishDir "${params.outdir}/databases/${tool}", mode: 'copy'
    publishDir "${params.outdir}/databases", mode: 'copy', saveAs: { filename -> "${tool}/$filename" }

    input:
    val tool

    output:
    path "${tool}_db", emit: db
    path "${tool}_db.tar.gz", emit: rgi_archive, optional: true
    path "versions.yml", emit: versions

    script:
    """
    mkdir -p ${tool}_db
    case $tool in
        resfinder)
            git clone https://bitbucket.org/genomicepidemiology/resfinder_db.git ${tool}_db
            ;;
        rgi)
            wget https://card.mcmaster.ca/latest/data -O ${tool}_db.tar.gz
            tar -xvf ${tool}_db.tar.gz -C ${tool}_db
            
            ;;
        amrfinderplus)
            amrfinder_update --force_update --database ${tool}_db
            ;;
        abricate)
            abricate --setupdb
            cp -r \$HOME/.local/share/abricate/* ${tool}_db/
            ;;
        *)
            echo "Unknown tool: $tool"
            exit 1
            ;;
    esac
    # Get version
    if [ "$tool" = "rgi" ]; then
        TOOL_VERSION=\$(docker run --rm quay.io/biocontainers/rgi:6.0.3--pyha8f3691_1 rgi main --version 2>&1 | sed 's/^.*v//')
    else
        TOOL_VERSION=\$(${tool} --version 2>&1 | sed 's/^.*v//')
    fi

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        ${tool}: \$(${tool} --version 2>&1 | sed 's/^.*v//')
    END_VERSIONS
    """
}
