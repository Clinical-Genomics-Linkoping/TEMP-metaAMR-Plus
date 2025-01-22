include { SUMMARY_REPORT } from '../../modules/local/summary_report'

workflow SUMMARY {
    take:
    ch_abricate
    ch_amrfinder
    ch_resfinder
    ch_rgi
    ch_plasmidfinder
    ch_plasclass
    ch_kaiju
    ch_centrifuge

    main:
    // Combine all inputs by meta.id
    ch_all_inputs = ch_abricate
        .join(ch_amrfinder, by: [0], remainder: true)
        .join(ch_resfinder, by: [0], remainder: true)
        .join(ch_rgi, by: [0], remainder: true)
        .join(ch_plasmidfinder, by: [0], remainder: true)
        .join(ch_plasclass, by: [0], remainder: true)
        .join(ch_kaiju, by: [0], remainder: true)
        .join(ch_centrifuge, by: [0], remainder: true)
        .map { meta, abricate, amrfinder, resfinder, rgi, plasmidfinder, plasclass, kaiju, centrifuge ->
            [meta, abricate, amrfinder, resfinder, rgi, plasmidfinder, plasclass, kaiju, centrifuge]
        }

    // Run SUMMARY_REPORT
    SUMMARY_REPORT(ch_all_inputs)

    emit:
    summary_report = SUMMARY_REPORT.out.summary_report
    versions = SUMMARY_REPORT.out.versions
}
