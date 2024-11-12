include { DOWNLOAD_DB as RESFINDER_DB_DOWNLOAD } from '../modules/local/download_db'
include { DOWNLOAD_DB as RGI_DB_DOWNLOAD } from '../modules/local/download_db'
include { DOWNLOAD_DB as AMRFINDERPLUS_DB_DOWNLOAD } from '../modules/local/download_db'
include { DOWNLOAD_DB as ABRICATE_DB_DOWNLOAD } from '../modules/local/download_db'

def prepare_db(tool, db_path, download_flag, default_db = null) {
    if (db_path) {
        return Channel.fromPath(db_path)
    } else if (download_flag) {
        return Channel.of(tool)
    } else if (default_db) {
        return Channel.of(default_db)
    } else {
        return Channel.empty()
    }
}


workflow PREPARE_TOOL_DBS {
    main:
    ch_resfinder_db = params.download_resfinder_db ? Channel.of('resfinder') : Channel.empty()
    //ch_resfinder_db = prepare_db('resfinder', params.resfinder_db, params.download_resfinder_db)
    ch_rgi_db = prepare_db('rgi', params.rgi_db, params.download_rgi_db)
    ch_amrfinderplus_db = prepare_db('amrfinderplus', params.amrfinderplus_db, params.download_amrfinderplus_db)
    //ch_abricate_db = prepare_db('abricate', params.abricate_db_path, params.download_abricate_db, params.abricate_db)
    ch_abricate_db = params.abricate_db ? Channel.of(params.abricate_db) : Channel.empty()
    // Process ResFinder DB
    
    ch_resfinder_db_downloaded = ch_resfinder_db.branch {
        to_download: it == 'resfinder'
        ready: true
    }
    ch_resfinder_db_downloaded.to_download | RESFINDER_DB_DOWNLOAD
    ch_resfinder_db_final = ch_resfinder_db_downloaded.ready.mix(RESFINDER_DB_DOWNLOAD.out.db).first()

    // Process RGI DB
    ch_rgi_db_downloaded = ch_rgi_db.branch {
        to_download: it == 'rgi'
        ready: true
    }
    ch_rgi_db_downloaded.to_download | RGI_DB_DOWNLOAD
    ch_rgi_db_final = ch_rgi_db_downloaded.ready.mix(RGI_DB_DOWNLOAD.out.db)

    // Process AMRFinderPlus DB
    ch_amrfinderplus_db_downloaded = ch_amrfinderplus_db.branch {
        to_download: it == 'amrfinderplus'
        ready: true
    }
    ch_amrfinderplus_db_downloaded.to_download | AMRFINDERPLUS_DB_DOWNLOAD
    ch_amrfinderplus_db_final = ch_amrfinderplus_db_downloaded.ready.mix(AMRFINDERPLUS_DB_DOWNLOAD.out.db)


    // Process Abricate DB
    ch_abricate_db_downloaded = ch_abricate_db.branch {
        to_download: it == 'abricate'
        ready: true
    }
    ch_abricate_db_downloaded.to_download | ABRICATE_DB_DOWNLOAD
    ch_abricate_db_final = ch_abricate_db_downloaded.ready.mix(ABRICATE_DB_DOWNLOAD.out.db).first()
    
   
    emit:
    resfinder_db     = ch_resfinder_db_final
    rgi_db           = ch_rgi_db_final
    amrfinderplus_db = ch_amrfinderplus_db_final
    abricate_db      = ch_abricate_db_final
}
