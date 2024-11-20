process EXTRACT_RGI_DB {
    input:
    path rgi_db_archive

    output:
    path "rgi_db", emit: rgi_db

    script:
    """
    mkdir rgi_db
    tar -xvf $rgi_db_archive -C rgi_db
    """
}
