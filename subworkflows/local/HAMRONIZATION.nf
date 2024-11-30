include { HAMRONIZATION_ABRICATE } from '../../modules/nf-core/hamronization/abricate/main'
include { HAMRONIZATION_AMRFINDERPLUS } from '../../modules/nf-core/hamronization/amrfinderplus/main'
include { HAMRONIZATION_RGI } from '../../modules/nf-core/hamronization/rgi/main'
include { HAMRONIZATION_SUMMARIZE } from '../../modules/nf-core/hamronization/summarize/main'

workflow HAMRONIZATION {
    take:
    ch_abricate       // channel: [ val(meta), path(abricate_report) ]
    ch_amrfinderplus  // channel: [ val(meta), path(amrfinderplus_report) ]
    ch_rgi            // channel: [ val(meta), path(rgi_report) ]

    main:
    ch_versions = Channel.empty()
    ch_harmonized = Channel.empty()

    // Harmonize ABRICATE results
    HAMRONIZATION_ABRICATE ( 
        ch_abricate.filter { it[1] != null }, 
        'tsv',
        params.abricate_version,
        params.abricate_db_version
    )
    ch_harmonized = ch_harmonized.mix(HAMRONIZATION_ABRICATE.out.tsv.map { meta, report -> [meta, report, 'abricate'] })
    ch_versions = ch_versions.mix(HAMRONIZATION_ABRICATE.out.versions)

    // Harmonize AMRFinderPlus results
    HAMRONIZATION_AMRFINDERPLUS ( 
        ch_amrfinderplus.filter { it[1] != null }, 
        'tsv',
        params.amrfinderplus_version,
        params.amrfinderplus_db_version
    )
    ch_harmonized = ch_harmonized.mix(HAMRONIZATION_AMRFINDERPLUS.out.tsv.map { meta, report -> [meta, report, 'amrfinder'] })
    ch_versions = ch_versions.mix(HAMRONIZATION_AMRFINDERPLUS.out.versions)

    // Harmonize RGI results
    HAMRONIZATION_RGI ( 
        ch_rgi.filter { it[1] != null }, 
        'tsv',
        params.rgi_version,
        params.card_version
    )
    ch_harmonized = ch_harmonized.mix(HAMRONIZATION_RGI.out.tsv.map { meta, report -> [meta, report, 'rgi'] })
    ch_versions = ch_versions.mix(HAMRONIZATION_RGI.out.versions)

    // Prepare reports for summarization
    ch_reports_to_summarize = ch_harmonized
        .map { meta, report, tool -> 
            def newName = "${meta.id}_${tool}_harmonized.tsv"
            return [meta, report.copyTo(newName)]
        }
        .map { meta, report -> report }
        .collect()

    // Summarize harmonized results
    HAMRONIZATION_SUMMARIZE ( 
        ch_reports_to_summarize,
        params.arg_hamronization_summarizeformat
    )

    ch_summary = HAMRONIZATION_SUMMARIZE.out.tsv
    ch_versions = ch_versions.mix(HAMRONIZATION_SUMMARIZE.out.versions)

    emit:
    summary = ch_summary
    versions = ch_versions
}