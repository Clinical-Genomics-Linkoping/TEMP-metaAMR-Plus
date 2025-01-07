/*process DOWNLOAD_DB {
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
    which amrfinder || echo "AMRFinder not found"
    which abricate || echo "Abricate not found"
    which ${tool} || echo "${tool} not found"

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
        

        plasmidfinder)
            git clone https://bitbucket.org/genomicepidemiology/plasmidfinder_db.git ${tool}_db
            ;;
        *)
            echo "Unknown tool: $tool"
            exit 1
            ;;
    esac

    # Get version
    if [ "$tool" = "rgi" ]; then
        TOOL_VERSION=\$(docker run --rm quay.io/biocontainers/rgi:6.0.3--pyha8f3691_1 rgi main --version 2>&1 | sed 's/^.*v//')
    elif [ "$tool" = "plasmidfinder" ]; then
        TOOL_VERSION=\$(git -C ${tool}_db describe --tags --abbrev=0)
    
    else
        TOOL_VERSION=\$(${tool} --version 2>&1 | sed 's/^.*v//')
    fi

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        ${tool}: \$(${tool} --version 2>&1 | sed 's/^.*v//')
    END_VERSIONS
    """
}
*/
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
            TOOL_VERSION=\$(docker run --rm quay.io/biocontainers/rgi:6.0.3--pyha8f3691_1 rgi main --version 2>&1 | sed 's/^.*v//')
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