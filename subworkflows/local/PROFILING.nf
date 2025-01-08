include { KAIJU_KAIJU } from '../../modules/nf-core/kaiju/kaiju/main'
include { CENTRIFUGE_CENTRIFUGE } from '../../modules/nf-core/centrifuge/centrifuge/main'
include { CENTRIFUGE_KREPORT } from '../../modules/nf-core/centrifuge/kreport/main'
include { KAIJU_KAIJU2KRONA } from '../../modules/nf-core/kaiju/kaiju2krona/main'
include { KRONA_KTIMPORTTEXT as KRONA_KAIJU } from '../../modules/nf-core/krona/ktimporttext/main'
include { KRONA_KTIMPORTTEXT as KRONA_CENTRIFUGE } from '../../modules/nf-core/krona/ktimporttext/main'


workflow PROFILING {
    take:
    reads_ch     // channel: [ val(meta), [ reads ] ]
    databases_ch // channel: [ val(db_meta), path(db) ]

    main:
    ch_versions = Channel.empty()
    ch_raw_classifications = Channel.empty()
    ch_raw_profiles = Channel.empty()

    // Prepare input for both FASTQ and FASTA compatibility
    ch_profiling_input = reads_ch.map { meta, reads -> 
        def input_reads = reads.flatten()  // Flatten the list of reads
        [meta, input_reads]
    }
    // Run Kaiju
    if (params.run_kaiju) {
        ch_kaiju_db = databases_ch.filter { it[0].tool == 'kaiju' }.map { it[1] }
        ch_kaiju_input = reads_ch
            .combine(ch_kaiju_db)
            .map { meta, reads, db -> 
                [meta, reads.flatten(), db]  // Flatten the reads list
            }

        ch_kaiju_input.view { "Kaiju input: $it" }

        KAIJU_KAIJU(
            ch_kaiju_input.map { meta, reads, db -> [meta, reads] },
            ch_kaiju_input.map { meta, reads, db -> db }.unique()
        )
        ch_versions = ch_versions.mix(KAIJU_KAIJU.out.versions)
        ch_raw_classifications = ch_raw_classifications.mix(KAIJU_KAIJU.out.results)

        KAIJU_KAIJU2KRONA(
            KAIJU_KAIJU.out.results,
            ch_kaiju_db
           
        )

        KRONA_KAIJU(
            //KAIJU_KAIJU2KRONA.out.txt,
            KAIJU_KAIJU2KRONA.out.txt.map { meta, txt -> 
                def new_meta = meta + [tool: 'kaiju']
                [new_meta, txt]
            }
            

        )

    }
    // Run Centrifuge
    if (params.run_centrifuge) {
        ch_centrifuge_db = databases_ch.filter { it[0].tool == 'centrifuge' }.map { it[1] }
        ch_centrifuge_input = reads_ch
            .combine(ch_centrifuge_db)
            .map { meta, reads, db -> 
                [meta, reads[0], db]  // Take the first (and only) element of reads
            }

        ch_centrifuge_input.view { "Centrifuge input: $it" }

        CENTRIFUGE_CENTRIFUGE(
            ch_centrifuge_input.map { meta, reads, db -> [meta, reads] },
            ch_centrifuge_input.map { meta, reads, db -> db }.unique(),
            params.save_centrifuge_unclassified,
            params.save_centrifuge_classified
        )
        ch_versions = ch_versions.mix(CENTRIFUGE_CENTRIFUGE.out.versions)
        ch_raw_classifications = ch_raw_classifications.mix(CENTRIFUGE_CENTRIFUGE.out.results)
     
        KRONA_CENTRIFUGE(
            //CENTRIFUGE_CENTRIFUGE.out.results,
            CENTRIFUGE_CENTRIFUGE.out.results.map { meta, txt -> 
                def new_meta = meta + [tool: 'centrifuge']
                [new_meta, txt]
            }
           
        )

    }

    ch_krona_html = Channel.empty()
    ch_krona_html = ch_krona_html.mix(KRONA_KAIJU.out.html.ifEmpty([]))
    ch_krona_html = ch_krona_html.mix(KRONA_CENTRIFUGE.out.html.ifEmpty([]))

    // Emit Outputs
    emit:
    raw_classifications = ch_raw_classifications
    raw_profiles = ch_raw_profiles
    versions = ch_versions
    krona_html = ch_krona_html
}