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
}*/

process DOWNLOAD_DB {
    tag "$tool"
    label 'process_high'
    label 'error_retry'
    publishDir "${params.outdir}/databases/${tool}", mode: 'copy'


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
    which git || echo "Git not found" || exit 1
    which wget || echo "Wget not found" || exit 1
    which python3 || echo "Python3 not found" || exit 1

    mkdir -p ${tool}_db

    case $tool in
        resfinder)
            git clone https://bitbucket.org/genomicepidemiology/resfinder_db.git ${tool}_db || exit 1
            ;;
        rgi)
            wget https://card.mcmaster.ca/latest/data -O ${tool}_db.tar.gz || exit 1
            tar -xvf ${tool}_db.tar.gz -C ${tool}_db || exit 1
            ;;
        amrfinderplus)
            amrfinder_update --force_update --database ${tool}_db || exit 1
            ;;
        plasmidfinder)
            git clone https://bitbucket.org/genomicepidemiology/plasmidfinder_db.git ${tool}_db || exit 1
            cd ${tool}_db
            # Check if kma_index is installed, install it if not
            if ! which kma_index; then
                echo "kma_index not found; installing kma_index..."
                git clone https://bitbucket.org/genomicepidemiology/kma.git || exit 1
                cd kma
                make || exit 1
                cp kma_index /usr/local/bin || exit 1
                cd ..
            fi

            # Modify INSTALL.py to bypass interactive prompt
            sed -i 's/ans = input(".*Please input path to executable kma_index.*")/ans = "kma_index"/' INSTALL.py || exit 1

            # Run the installer
            python3 INSTALL.py kma_index || exit 1
            cd ..
            ;;
        *)
            echo "Unknown tool: $tool"
            exit 1
            ;;
    esac

    # Extract version information
    case $tool in
        rgi)
            TOOL_VERSION=\$(docker run --rm quay.io/biocontainers/rgi:6.0.3--pyha8f3691_1 rgi main --version 2>&1 | sed 's/^.*v//')
            ;;
        plasmidfinder)
            TOOL_VERSION=\$(git -C ${tool}_db describe --tags --abbrev=0)
            ;;
        *)
            TOOL_VERSION=\$(${tool} --version 2>&1 | sed 's/^.*v//')
            ;;
    esac

    # Save version information
    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        ${tool}: \$TOOL_VERSION
    END_VERSIONS
    """
}