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
    path "versions.yml", emit: versions

    script:
    """
    mkdir -p ${tool}_db
    case $tool in
        resfinder)
            git clone https://bitbucket.org/genomicepidemiology/resfinder_db.git ${tool}_db
            ;;
        rgi)
            wget -O ${tool}_db.tar.gz https://card.mcmaster.ca/latest/data
            tar -xzvf ${tool}_db.tar.gz -C ${tool}_db
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

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        ${tool}: \$(${tool} --version 2>&1 | sed 's/^.*v//')
    END_VERSIONS
    """
}
