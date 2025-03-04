include { DOWNLOAD_DB as RESFINDER_DB_DOWNLOAD } from '../modules/local/download_db'
include { DOWNLOAD_DB as RGI_DB_DOWNLOAD } from '../modules/local/download_db'
include { DOWNLOAD_DB as AMRFINDERPLUS_DB_DOWNLOAD } from '../modules/local/download_db'
include { RESFINDER_INDEX } from '../modules/local/RESFINDER_INDEX'
include { DOWNLOAD_DB as ABRICATE_DB_DOWNLOAD } from '../modules/local/download_db'
include { AMRFINDERPLUS_UPDATE } from '../modules/nf-core/amrfinderplus/update/main'
include { GUNZIP } from '../modules/nf-core/gunzip/main'
include { DOWNLOAD_DB as PLASMIDFINDER_DB_DOWNLOAD } from '../modules/local/download_db'

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
    // Create channels for each database
    ch_resfinder_db = params.download_resfinder_db ? Channel.of('resfinder') : Channel.empty()
    ch_rgi_db = prepare_db('rgi', params.rgi_db, params.download_rgi_db)
    ch_amrfinderplus_db = prepare_db('amrfinderplus', params.amrfinderplus_db, params.download_amrfinderplus_db)
    ch_plasmidfinder_db = prepare_db('plasmidfinder', params.plasmidfinder_db, params.download_plasmidfinder_db)

    // Debug: Print tool names for each channel
    ch_resfinder_db.view { "ResFinder tool: $it" }
    ch_rgi_db.view { "RGI tool: $it" }
    ch_amrfinderplus_db.view { "AMRFinderPlus tool: $it" }
    ch_plasmidfinder_db.view { "PlasmidFinder tool: $it" }

    /*// Process ResFinder DB
    ch_resfinder_db_downloaded = ch_resfinder_db.branch {
        to_download: it == 'resfinder'
        ready: true
    }
    ch_resfinder_db_downloaded.to_download | RESFINDER_DB_DOWNLOAD
    ch_resfinder_db_final = ch_resfinder_db_downloaded.ready.mix(RESFINDER_DB_DOWNLOAD.out.db).first()
*/
     // Process ResFinder DB with indexing
    
    // Process ResFinder DB with indexing
    ch_resfinder_db_downloaded = ch_resfinder_db.branch {
        to_download: it == 'resfinder'
        ready: true
    }
    ch_resfinder_db_downloaded.to_download | RESFINDER_DB_DOWNLOAD

// Automatically run indexing after database download
    ch_indexed_resfinder_db = RESFINDER_INDEX(RESFINDER_DB_DOWNLOAD.out.db)
        .map { db_files -> file(db_files[0]).parent }

// Ensure ResFinder gets the indexed DB
    ch_resfinder_db_final = ch_resfinder_db_downloaded.ready.mix(ch_indexed_resfinder_db).first()




    // Process RGI DB
    RGI_DB_DOWNLOAD(ch_rgi_db)
    ch_rgi_db_final = RGI_DB_DOWNLOAD.out.db

    // Process AMRFinderPlus DB
    ch_amrfinderplus_db_downloaded = ch_amrfinderplus_db.branch {
        to_download: it == 'amrfinderplus'
        ready: true
    }
    if (params.download_amrfinderplus_db) {
        AMRFINDERPLUS_UPDATE()
        ch_amrfinderplus_db_final = AMRFINDERPLUS_UPDATE.out.db
    } else {
        ch_amrfinderplus_db_final = ch_amrfinderplus_db_downloaded.ready
    }

    // Process PlasmidFinder DB
    ch_plasmidfinder_db_downloaded = ch_plasmidfinder_db.branch {
        to_download: it == 'plasmidfinder'
        ready: true
    }
    ch_plasmidfinder_db_downloaded.to_download | PLASMIDFINDER_DB_DOWNLOAD
    ch_plasmidfinder_db_final = ch_plasmidfinder_db_downloaded.ready.mix(PLASMIDFINDER_DB_DOWNLOAD.out.db).first()

    // Debug: Print final paths for all databases
    ch_resfinder_db_final.view { "Final ResFinder DB Path: $it" }
    ch_rgi_db_final.view { "Final RGI DB Path: $it" }
    ch_amrfinderplus_db_final.view { "Final AMRFinderPlus DB Path: $it" }
    ch_plasmidfinder_db_final.view { "Final PlasmidFinder DB Path: $it" }

    emit:
    resfinder_db     = ch_resfinder_db_final
    rgi_db           = ch_rgi_db_final
    amrfinderplus_db = ch_amrfinderplus_db_final
    plasmidfinder_db = ch_plasmidfinder_db_final
}
    
    
