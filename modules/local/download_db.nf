process DOWNLOAD_DB {
    tag "$tool"
    label 'process_high'
    label 'error_retry'
    publishDir "${params.outdir}/databases", mode: 'copy', saveAs: { filename -> "${tool}/$filename" }

    input:
    val tool

    output:
    path "${tool}_db", emit: db
    path "${tool}_db.tar.gz", emit: rgi_archive, optional: true
    path "versions.yml", emit: versions

    script:
    """
    set -x  # Enable debug mode

    # Check tool availability
    which git || echo "Git not found"
    which wget || echo "Wget not found"
    which python3 || echo "Python3 not found"

    mkdir -p ${tool}_db
    case $tool in
        resfinder)
            git clone https://bitbucket.org/genomicepidemiology/resfinder_db.git ${tool}_db
            TOOL_VERSION=\$(cat ${tool}_db/VERSION 2>/dev/null || echo "unknown")
            ;;
        rgi)
            wget https://card.mcmaster.ca/latest/data -O ${tool}_db.tar.gz
            tar -xvf ${tool}_db.tar.gz -C ${tool}_db

            if command -v rgi >/dev/null 2>&1; then
                TOOL_VERSION=\$(rgi main --version 2>&1 | sed 's/^.*v//')
            else
                TOOL_VERSION="unknown"
            fi
            ;;
        amrfinderplus)
            amrfinder_update --force_update --database ${tool}_db
            TOOL_VERSION=\$(amrfinder --version 2>&1 | sed 's/^.*v//')
            ;;
        plasmidfinder)
            git clone https://bitbucket.org/genomicepidemiology/plasmidfinder_db.git ${tool}_db
            TOOL_VERSION=\$(git -C ${tool}_db describe --tags --abbrev=0 || echo "unknown")
            ;;
        *)
            echo "Unknown tool: $tool"
            exit 1
            ;;
    esac

    # Save version information
    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        ${tool}: \$TOOL_VERSION
    END_VERSIONS
    """
}